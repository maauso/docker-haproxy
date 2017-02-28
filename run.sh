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

kill () {
  echo "Tenemos el killl!!!!"
  iptables -w -I INPUT -p tcp --dport 7070 -j REJECT 2>/dev/null;
  echo "esperamos 5 segundos"
  sleep 5
  echo ""
  kill ${PIDFILE}
  wait ${PIDFILE} ; iptables -w -D INPUT -p tcp --dport 7070 -j REJECT 2>/dev/null;
}

reload() {
  echo "Reloading haproxy `date +'%D %T'`"
  (
    flock 200
    #Check configuration file before to reload process
    haproxy -f /haproxy.cfg -c
    if [ $? -eq 0 ]
    then
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
    else
    echo "The configuration file is wrong, `date +'%D %T'`"
    echo "$(cat /haproxy.cfg)"   
    fi
  ) 200>/var/run/haproxy/lock
}

mkdir -p /var/state/haproxy
mkdir -p /var/run/haproxy

reload

trap reload SIGHUP
trap kill SIGTERM
while true; do /bin/sleep 0.5; done
