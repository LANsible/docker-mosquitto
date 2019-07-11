#  🦟 Mosquitto in Docker the right way

[![Build Status](https://cloud.drone.io/api/badges/LANsible/docker-mosquitto/status.svg)](https://cloud.drone.io/LANsible/docker-mosquitto)
[![Docker Pulls](https://img.shields.io/docker/pulls/lansible/mosquitto.svg)](https://hub.docker.com/r/lansible/hoem-assistant)
[![Docker Version](https://images.microbadger.com/badges/version/lansible/mosquitto:latest.svg)](https://microbadger.com/images/lansible/mosquitto:latest)
[![Docker Size/Layers](https://images.microbadger.com/badges/image/lansible/mosquitto:latest.svg)](https://microbadger.com/images/lansible/mosquitto:latest)

## Why another mosquitto container?
When I tried to run the official Mosquitto container on Kubernetes I couldn't get it to work with a configmap.
Since Kubernetes 1.9.6 the configmaps are readonly, the directory where they are mounted to are also mounted readonly.
The current mosquitto container breaks on this due the hardcoded VOLUME definition.
I could mitigate this by mounting the config to somewhere else then /mosquitto but the VOLUME mount in the Dockerfile is just ugly.
Also this container is way smaller!

## Running the container

The default credentials are:

```yaml
username: mosquitto
password: mosquitto
```

### Local Docker
```
docker run -d lansible/mosquitto
```

### Docker-compose/Swarm

The repository contains a basic Docker Compose file which works with Swarm.
Use this or use it as a good start!

```yaml
cd examples/docker-compose
docker-compose up -d mosquitto
```
### Kubernetes

The kubectl files in the examples/kubernetes I use myself to deploy.
It uses a configmap for the configuration and it exposes mosquitto on Nodeport 31883 with a service.

```yaml
kubectl apply -f examples/kubernetes
```

## Getting the password for in the passwords file

Since this container is very minimal it misses the mosquitto_passwd utility but this is published as a seperate container.
It can be used like this:
```
docker run -it -v $(pwd):/data lansible/mosquito_passwd -c /data/passwordfile username
```

## Troubleshooting

Mosquitto not starting, try to run the container locally:
```
docker run lansible/mosquitto:latest
```

When something is going wrong you can jump to the cli like this:

```
docker run -it --entrypoint /bin/sh --user root lansible/mosquitto:latest
```

The mosquitto binary is located at `/usr/bin/mosquitto`
