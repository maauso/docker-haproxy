/consul-template -log-level=warn -max-stale=10m -exec-splay=5s -wait=10s:11s -reload-signal="SIGHUP" -template "haproxy.cfg.ctmpl:haproxy.cfg" -exec "./run.sh" -consul-addr ${CONSUL_SERVER}


#max-stale
#This is the maximum interval to allow "stale" data. By default, only the Consul leader will respond to queries; so this option allows any follower to respond to a query

#dedup 
#Consul Template uses leader election on a per-template basis to have only a single node perform the queries. Results are shared among other instances rendering the same template by passing compressed data through the Consul K/V store.

#exec-splay
#This is a random splay to wait before killing the command, splay value to prevent all child processes from reloading at the same time

#wait
#This is the `minimum(:maximum)` to wait before rendering a new template

