FROM maauso/docker-consul-template:0.18.1

LABEL authors="Miguel Ángel Ausó m.auso.p@gmail.com"
LABEL description="HaProxy images integrate with Consul using consul template"
LABEL version="1.7.2"


#HaProxy options
ENV HAPROXY_MAXCONN_GLOBAL=50000
ENV HAPROXY_SPREAD_CHECKS=5
ENV HAPROXY_MAX_SPREAD_CHECKS=15000
ENV HAPROXY_SPREAD-CHECKS=5
ENV HAPROXY_RETRIES=3
ENV HAPROXY_BACKLOG=10000
ENV HAPROXY_MAXCONN=10000
ENV HAPROXY_TIMEOUT_CONNECT=3s
ENV HAPROXY_TIMEOUT_CLIENT=30s
ENV HAPROXY_TIMEOUT_SERVER=30s
ENV HAPROXY_TIMEOUT_HTTP_KEEP_ALIVE=1s
ENV HAPROXY_TIMEOUT_HTTP_REQUEST=15s
ENV HAPROXY_TIMEOUT_QUEUE=30s
ENV LOCAL_SYSLOG=127.0.0.1:514
## HAProxy CONFIGURE
COPY haproxy.cfg.ctmpl /haproxy.cfg.ctmpl
# runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        iptables \
        openssl \
        procps \
        python3 \
        runit \
        socat \
    && rm -rf /var/lib/apt/lists/*

#Build Haproxy
COPY build-haproxy.sh \
    /haproxy/
RUN chmod 755 /haproxy/build-haproxy.sh

RUN apt-get update && apt-get install -y --no-install-recommends gcc libc6-dev libffi-dev libpcre3-dev libreadline-dev libssl-dev zlib1g-dev make wget \
  && rm -rf /var/lib/apt/lists/* \
  && /haproxy/build-haproxy.sh \
  && apt-get purge -y --auto-remove $buildDeps

COPY *.lua /haproxy/

COPY run.sh /run.sh
RUN chmod 755 /run.sh \
    && mkdir -p /var/state/haproxy/ \
    && mkdir -p /var/run/haproxy/

#Script star with consul-template and haproxy
#COPY consul-template-start.sh /consul-template-start.sh
#CMD ["/bin/sh" , "/consul-template-start.sh"]
COPY config.conf /config.conf
CMD ["/consul-template" , "-config=/config.conf" ]
