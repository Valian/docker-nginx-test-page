# docker-nginx-test-page
![build](https://img.shields.io/docker/build/valian/nginx-test-page.svg)

Smallest possible Nginx (OpenResty) image for testing load-balancing inside Docker cluster. I've created it because I wanted to stress-test `Docker Swarm` networking, and analyse results using ELK stack. It should work just fine with other orchestrators, like `Kubernetes`.

# Preview

```bash
>> curl localhost
HOSTNAME=ef25379f3352
IP=12.122.122.12

>> curl localhost/recurse?count=5
12.122.122.12    04ac8923b523    Count 5
12.122.122.12    04ac8923b523    Count 4
12.122.122.12    04ac8923b523    Count 3
12.122.122.12    04ac8923b523    Count 2
12.122.122.12    04ac8923b523    Count 1
12.122.122.12    04ac8923b523    Count 0
# EXTERNAL-IP,   CONTAINER-ID,   COUNTER

# when we want to test load-balancing on a cluster:
# first, deploy this image with multiple replicas as a service, e.g. "nginx-test"
# second, make recurse request passing hostname as a target
>> curl 'cluster-ip/recurse?count=5&host=nginx-test/recurse'
12.122.122.15    f8f0e76d6e78    Count 5
12.122.122.12    04ac8923b523    Count 4
12.122.122.15    f8f0e76d6e78    Count 3
12.122.122.12    04ac8923b523    Count 2
12.122.122.15    f8f0e76d6e78    Count 1
12.122.122.12    04ac8923b523    Count 0

```

# Features
* Allows for creating **recursive requests between containers**, merging all responses
* Logging in JSON format, ready to be shipped to e.g. `logstash`
* No configuration
* Small
* High performance

# Usage

Basic example
```bash
>> docker run --rm -it -p 80:80 valian/nginx-test-page

# in another terminal
>> curl localhost
HOSTNAME=ef25379f3352
IP=12.122.122.12

# You can try to restart container multiple times, you will always get proper containerID and public IP address.
# Not let's recurse
>> curl localhost/recurse?count=100
12.122.122.12    04ac8923b523    Count 100
12.122.122.12    04ac8923b523    Count 99
12.122.122.12    04ac8923b523    Count 98
...
12.122.122.12    04ac8923b523    Count 2
12.122.122.12    04ac8923b523    Count 1
12.122.122.12    04ac8923b523    Count 0

# Container made 100 requests to himself, because there's only one container running and there's no load balancing. 
```

Example using scaling in `docker-compose`:
```bash
# download docker-compose.yml from this repository
>> wget https://raw.githubusercontent.com/Valian/docker-nginx-test-page/master/docker-compose.yml

# run with 10 copies of a nginx-test container
>> docker-compose up --scale nginx-test=10

# in another terminal (we're using docker-compose run, because we can't scale services with open ports)
# notice different container IDs
>> docker-compose run --rm nginx-test curl 'nginx-test:80/recurse?count=100&host=nginx-test/recurse'
12.122.122.12    04ac8923b523    Count 100
12.122.122.12    2ca5192d79d9    Count 99
12.122.122.12    04ac8923b523    Count 98
...
12.122.122.12    c2be082a760c    Count 2
12.122.122.12    2ca5192d79d9    Count 1
12.122.122.12    c2be082a760c    Count 0
```

You can do pretty the same on a `Docker Swarm` or a `Kubernetes` cluster, to easily generate thousands of requests across containers. For example, each request to `recurse?count=100` generates 100 requests between containers.

# Implementation

This image is build on top of [OpenResty](https://openresty.org/en/), nginx with lua support. It's extremaly fast. This image uses capabilities of OpenResty to make recursive requests directly from nginx to nginx, without any other server. For more details, look into `nginx.conf` file. 

# Limitations

Very high values of `count` parameter may cause dropping connections, because it basically creates "chain" of requests, each waiting for last one to complete. 

# Licence
MIT
