# Create an HAProxy container that will dynamically rewrite its config
# when backends are added and removed.
FROM ubuntu:14.04

#
# Install os packages
#

# Install supervisor and haproxy
RUN apt-get update 
RUN apt-get upgrade -y
RUN apt-get install -y \
        python-setuptools \
        haproxy

#
# Install and configure `supervisord`
#

RUN \
    easy_install supervisor

ADD \
    supervisord/supervisord.conf \
    /etc/supervisord.conf

#
# Install and configure confd
#

ADD \
    confd/confd \
    /usr/bin/confd

RUN \
    chmod +x /usr/bin/confd && \
    mkdir -p /etc/confd/conf.d && \
    mkdir -p /etc/confd/templates

ADD \  
    haproxy/haproxy.cfg.template \
    /etc/confd/templates/haproxy.cfg.template

ADD \  
    haproxy/haproxy.toml.template \
    /etc/confd/conf.d/haproxy.toml.template

ADD \
    haproxy/confd.sh \
    /usr/bin/confd.sh

RUN \
    chmod +x /usr/bin/confd.sh

ENTRYPOINT /usr/local/bin/supervisord -c /etc/supervisord.conf
