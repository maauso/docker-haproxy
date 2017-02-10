#!/bin/bash
exec 2>&1
export PIDFILE="/tmp/haproxy.pid"

addFirewallRules() {
  IFS=',' read -ra ADDR <<< "$PORTS"
  for i in "${ADDR[@]}"; do
    iptables -w -I INPUT -p tcp --dport $i --syn -j DROP
  done
}

removeFirewallRules() {
  IFS=',' read -ra ADDR <<< "$PORTS"
  for i in "${ADDR[@]}"; do
    while iptables -w -D INPUT -p tcp --dport $i --syn -j DROP 2>/dev/null; do :; done
  done
}

shutdown () {
  echo "it get SIGTERM TRAP!"
  echo "iptables -w -I INPUT -p tcp --dport $PORT_7070 --syn -j DROP"
  iptables -w -I INPUT -p tcp --dport $PORT_7070 --syn -j DROP
  sleep 10
  wait ${PIDFILE} ; iptables -w -D INPUT -p tcp --dport $PORT_7070 -j DROP
}

reload() {
  echo "Reloading haproxy `date +'%D %T'`"
  (
    flock 200

    # Begin to drop SYN packets with firewall rules
    addFirewallRules

    # Wait to settle
    sleep 0.1

    # Save the current HAProxy state
    socat /var/run/haproxy/socket - <<< "show servers state" > /var/state/haproxy/global

    # Trigger reload
    LATEST_HAPROXY_PID=$(cat $PIDFILE)
    haproxy -p $PIDFILE -f /haproxy.cfg -D -sf $LATEST_HAPROXY_PID 200>&-
    if [ -n "${HAPROXY_RELOAD_SIGTERM_DELAY-}" ]; then
      sleep $HAPROXY_RELOAD_SIGTERM_DELAY && kill $LATEST_HAPROXY_PID 200>&- 2>/dev/null &
    fi

    # Remove the firewall rules
    removeFirewallRules

    # Need to wait 1s to prevent TCP SYN exponential backoff
    sleep 1
  ) 200>/var/run/haproxy/lock
}

mkdir -p /var/state/haproxy
mkdir -p /var/run/haproxy

reload

trap reload SIGHUP
trap shutdown SIGTERM
while true; do sleep 0.5; done
