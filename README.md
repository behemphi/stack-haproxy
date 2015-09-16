# Purpose

This repo contains all the services necessary to run haproxy and have it
dynamcially react to nginx backends coming and going.

# Set Up

This repo is designed only to work on a single host locally based on [this 
set up](http://stackengine.com/docker-101-01-docker-development-environments/).
It is assumed you have started a machine called `stackengine-haproxy`

`docker-machine create stackengine-haproxy --driver virtualbox`

You will need to get the IP address from your local guest:

`docker-machine ip stackengine-haproxy`

Copy this value into `docker-compose.yml` replacing the existing 
`192.168.99.104`

For now you can build the haproxy image locally:

`docker build -t behemphi/haproxy .`

To run the services as a single machien stack:

`docker-compose up`

Note, this will run services in the foreground with some nice color-coded 
output.  It will be handy for later when smoke testing.

# Overiew

The `consul` and `registrator` services are the plumbing necessary to keep 
track of the various nginx services that are starting and stopping.

The `haproxy` service contains a small amount of plumbing as well. The
[`consul-template` tool](https://github.com/hashicorp/consul-template) is
used to watch the `consul` service for the registering and deregistering of 
nginx backends. 

This mean that we must have two processes running in the container. This means
we need a supervising process. So ultimately, starting the `haproxy` service 
causes `supervisord` to run in the container, `supervisord` then starts 
`consul-template` and `haproxy`.

When an event occurs (nginx service going up or down), `consul-template` 
rewrites the config with the correct values from `consul`.

## Try It

When you `docker-compose up` two nginx containers are started for you. If you 
get inside the `stack_haproxy` you can find the configuration file

`docker exec -it stack_haproxy sh`

and

`cat /etc/haproxy/haproxy.cfg`

Try starting some more nginx services on the host:

`docker run -d -p :80 nginx3 nginx`

In your browser, hit http://192.168.99.102 and see the Nginx welcome page. 
Note the output from Docker Compose shows you which of the nginx services 
actually responded.  Every 3rd time you won't get a message.  This is due to
the fact that the third nginx service is unknown to Compose.  

Stop the `nginx3` service. Refresh your browser a few more times and check the 
config again.

# Headaches

* `supervisord` does _not_ like managing daemonized services. As you harden
the haproxy config be sure you don't daemonize it.
* `supervisord` does not honor the `priority` config for each service. There
is no way to control the start order of the services.  This will result in 
dirty logs.
* `confd` only looks at the kv store of consul rather than the service list. 
`consul-template` was much more convenient to use for this reason. If you are
using etcd or some other service discovery layer, you will want to use 
`confd`
* Getting `registrator` to report register services in a way that was useful
(i.e. the address registered was routable from other containers) is where 
the vast majority of work went.  The `-h IP_ADDR` is ugly. I am considering 
an overlay network or trying `etcd` and `confd` to make this more dynamic.
* It would be a pretty small matter to write a shell script that fronts the 
docker-compose.yml and does the IP substituion for you. 

# License 

MIT