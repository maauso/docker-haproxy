/consul-template -log-level=debug -dedup -exec-splay=5s -wait=10s:11s -reload-signal="SIGHUP" -template "haproxy.cfg.ctmpl:haproxy.cfg" -exec "./run.sh" -consul ${CONSUL_SERVER}
#${CONSUL_SERVER}
