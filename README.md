# HaProxy container - with Zero-Downtime Reloads and consul-template
Docker container for HAProxy with consul-template, zero-downtime reloads and **consul-template** using (maauso/docker-consul-template)
https://github.com/maauso/docker-consul-template
## Zero-Downtime Reloads
When HAProxy reloads using its 'graceful reload' feature, there's a tiny amount of time where a number of packets might be dropped in the process. This is well documented elsewhere around the internet. This container uses the 'drop syn packets' technique to mitigate that. There are more sophisticated techniques available which lead to lower delays on a restart. If you'd like to implement one of those (for example, a variation of [the Yelp qdisc technique](http://engineeringblog.yelp.com/2015/04/true-zero-downtime-haproxy-reloads.html) that works for incoming traffic or the [unbounce IP tableflip technique](http://inside.unbounce.com/product-dev/haproxy-reloads/)) in this container

**Run container**
```bash
sudo docker run --dns=10.2.9.100 -p8080:8080 -p7070:7070  -e CONSUL_SERVER="$CONSUL_SERVER" maauso/haproxy:1.7.1
```

# HAPROXY Configure options
## Global variables that we can use it

```bash
HAPROXY_MAXCONN_GLOBAL=50000
```
```bash
HAPROXY_SPREAD_CHECKS=5
```
```bash
HAPROXY_MAX_SPREAD_CHECKS=15000
```
```bash
HAPROXY_SPREAD-CHECKS=5
```
***This variable doesn't have default value***

```bash
HAPROXY_DOM=maauso.com
```

## Default variables that we can use it
```bash
HAPROXY_RETRIES=3
```
```bash
HAPROXY_BACKLOG=10000
```
```bash
HAPROXY_MAXCONN=10000
```
```bash
HAPROXY_TIMEOUT_CONNECT=3s
```
```bash
HAPROXY_TIMEOUT_CLIENT=30s
```
```bash
HAPROXY_TIMEOUT_SERVER=30s
```
```bash
HAPROXY_TIMEOUT_HTTP_KEEP_ALIVE=1s
```
```bash
HAPROXY_TIMEOUT_HTTP_REQUEST=15s
```
```bash
HAPROXY_TIMEOUT_QUEUE=30s
```

## How to configure your application to work with HaProxy?

Consul-Service-Name

```bash
SERVICE_NAME=www
```
It'll be Frontend / Backend name and DNS name before global domain, for exemple If we use `apache url will be www.maauso.com
Frontend like

```bash
frontend app_http_in
  bind *:8080
  mode http
  acl host_www.maauso.com hdr(host) -i www.maauso.com
  use_backend www.maauso.com if host_wwww.maauso.com
```

You should use Consul Tags to configure it, consul-template only add services that have the follow tag

```json
"SERVICE_8080_TAGS": "haproxy.enable=true"
```

Availables SERVICE_TAGS, you can change some backend options with :

```bash
HAPROXY.ENABLE=true
```
```bash
HAPROXY.PROTOCOL=http
```
```bash
HAPROXY.BACKEND.BALANCE=roundrobin
```
```bash
HAPROXY.BACKEND.MAXCONN=10000
```

In the end the backend will be

```bash
backend www.maauso.com
  balance roundrobin
  mode http
  option forwardfor
  option tcp-check
  default-server inter 10s fall 1
  http-request set-header X-Forwarded-Port %[dst_port]
  http-request add-header X-Forwarded-Proto https if { ssl_fc }
```


## How to run HaProxy in Marathon

```json
{
  "id": "/services/haproxy-app",
  "cmd": null,
  "cpus": 0.1,
  "mem": 128,
  "disk": 0,
  "instances": 1,
  "constraints": [
    [
      "dc",
      "CLUSTER",
      "aws9"
    ]
  ],
  "container": {
    "type": "DOCKER",
    "volumes": [],
    "docker": {
      "image": "maauso/haproxy:1.7.1",
      "network": "HOST",
      "portMappings": null,
      "privileged": true,
      "parameters": [
        {
          "key": "publish",
          "value": "7070:7070"
        }
      ],
      "forcePullImage": true
    }
  },
  "env": {
    "SERVICE_8080_NAME": "lb-app",
    "CONSUL_SERVER": "127.0.0.1:8500",
    "SERVICE_7070_NAME": "lb-app"
  },
  "healthChecks": [
    {
      "protocol": "COMMAND",
      "command": {
        "value": "/bin/bash -c \\\"</dev/tcp/$HOST/$PORT1\\\""
      },
      "gracePeriodSeconds": 300,
      "intervalSeconds": 60,
      "timeoutSeconds": 20,
      "maxConsecutiveFailures": 3,
      "ignoreHttp1xx": false
    }
  ],
  "portDefinitions": [
    {
      "port": 8080,
      "protocol": "tcp",
      "labels": {}
    },
    {
      "port": 7070,
      "protocol": "tcp",
      "labels": {}
    }
  ],
  "backoffFactor": 1.5,
  "maxLaunchDelaySeconds": 60,
  "upgradeStrategy": {
    "minimumHealthCapacity": 0.75,
    "maximumOverCapacity": 0
  },
  "requirePorts": true
}
```
