/consul-template -log-level=warn -dedup -exec-splay=5s -wait=10s:11s -reload-signal="SIGHUP" -template "haproxy.cfg.ctmpl:haproxy.cfg" -exec "./run.sh" -consul ${CONSUL_SERVER}
#${CONSUL_SERVER}
