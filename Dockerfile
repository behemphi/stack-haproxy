# Create an HAProxy container that will dynamically rewrite its config
# when backends are added and removed.
FROM gliderlabs/alpine

#
# Install the parts: supervisord, confd, haproxy
#

# Install supervisor and haproxy
RUN apk-install \
    supervisor \
    haproxy

#
# Install consul-template
#

ADD \
    https://github.com/hashicorp/consul-template/releases/download/v0.10.0/consul-template_0.10.0_linux_amd64.tar.gz \
    /tmp/consul-template_0.10.0_linux_amd64.tar.gz

RUN tar zxf /tmp/consul-template_0.10.0_linux_amd64.tar.gz  -C /tmp
RUN mv /tmp/consul-template_0.10.0_linux_amd64/consul-template /usr/bin/consul-template
RUN chmod +x /usr/bin/consul-template
RUN mkdir -p /etc/consul-template/template.d

#
# Configure supervisord
#

ADD \
    supervisord/supervisord.conf \
    /etc/supervisord.conf

#
# Configure haproxy
#

ADD \  
    haproxy/haproxy.cfg.template \
    /etc/consul-template/template.d/haproxy.cfg.template

ENTRYPOINT /usr/bin/supervisord -c /etc/supervisord.conf
