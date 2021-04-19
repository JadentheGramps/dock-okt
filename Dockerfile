#getting base image
FROM ubuntu as builder

WORKDIR /temp
ADD OktaRadiusAgentSetup-${vers}.rpm /temp
RUN yum -y install glibc32 \
    && rpm2cpio OktaRadiusAgentSetup-${vers}.rpm | cpio -idmv \
    && rpm -qp --scripts OktaRadiusAgentSetup-${vers}.rpm \
    && cp ./opt/okta/ragent/user/config/radius/config.properties ./opt/okta/ragent/user/config/radius/blank-config.properties \
    && tar -czf OktaRadius-${vers}.tgz ./etc ./opt

FROM ubuntu as final
ENV vers 2.9.3
COPY --from=builder /temp/OktaRadius-${vers}.tgz /
RUN yum -y install sudo \
    && groupadd OktaRadiusService \
    && /sbin/useradd -m -r -g OktaRadiusService -s /sbin/nologin OktaRadiusService \
    && cd / \
    && tar -xf /OktaRadius-${vers}.tgz \
    && rm /OktaRadius-${vers}.tgz \
    && chmod -R 755 /opt/okta \
    && chown -R OktaRadiusService:OktaRadiusService /opt/okta \
    && sed -i 's/\$OKTA_CFG_FILE \&>\/dev\/null \&/\$OKTA_CFG_FILE/g' /etc/init.d/ragent
