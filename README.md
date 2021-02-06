#  🦟 Mosquitto in Docker the right way

[![Build Status](https://gitlab.com/lansible1/docker-mosquitto/badges/master/pipeline.svg)](https://gitlab.com/lansible1/docker-mosquitto/pipelines)
[![Docker Pulls](https://img.shields.io/docker/pulls/lansible/mosquitto.svg)](https://hub.docker.com/r/lansible/mosquitto)
[![Docker Version](https://images.microbadger.com/badges/version/lansible/mosquitto:latest.svg)](https://microbadger.com/images/lansible/mosquitto:latest)
[![Docker Size/Layers](https://images.microbadger.com/badges/image/lansible/mosquitto:latest.svg)](https://microbadger.com/images/lansible/mosquitto:latest)

## Why another mosquitto container?
When I tried to run the official Mosquitto container on Kubernetes I couldn't get it to work with a configmap.
Since Kubernetes 1.9.6 the configmaps are readonly, the directory where they are mounted to are also mounted readonly.
The current mosquitto container breaks on this due the hardcoded VOLUME definition.
I could mitigate this by mounting the config to somewhere else then /mosquitto but the VOLUME mount in the Dockerfile is just ugly.
Also this container is way smaller!

## Running the container

The default configuration allows passwordless connections. Just do and you should be able to connect to localhost:1883:
```
docker run -it -p 1883:1883 lansible/mosquitto:latest
```

### Docker-compose/Swarm

The repository contains a basic Docker Compose file which works with Swarm.
Use this or use it as a good start and example how to use a password file.

```yaml
cd examples/docker-compose
docker-compose up -d mosquitto
```

Now you should be able to connect to port 31883 with the mosquitto:mosquitto credentials

### Kubernetes

The kubectl files in the examples/kubernetes I use myself to deploy.
It uses a configmap for the configuration and it exposes mosquitto on Nodeport 31883 with a service.

```yaml
kubectl apply -f examples/kubernetess
```

Now you should be able to connect to port 31883 with the mosquitto:mosquitto credentials

## Getting the password for in the passwords file

Since this container is very minimal it misses the mosquitto_passwd utility but you can easily run the upstream container.
```
docker run -it -v $(pwd):/data eclipse-mosquitto mosquitto_passwd
# Create passwordfile
docker run -it -v $(pwd):/data eclipse-mosquitto mosquitto_passwd -c /data/passwordfile username
```

## Troubleshooting

Mosquitto not starting, try to run the container locally:
```
docker run lansible/mosquitto:latest
```

## Credits

* [eclipse/mosquitto](https://github.com/eclipse/mosquitto)
