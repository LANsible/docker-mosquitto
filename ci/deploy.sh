#!/bin/bash
echo "Pushing ${DOCKER_NAMESPACE}/${CONTAINER_NAME}:${ANSIBLE_VERSION}"
echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin
docker push ${DOCKER_NAMESPACE}/${CONTAINER_NAME}
docker manifest create \
    ${DOCKER_NAMESPACE}/${CONTAINER_NAME}:latest \
    ${DOCKER_NAMESPACE}/${CONTAINER_NAME}:amd64 \
    ${DOCKER_NAMESPACE}/${CONTAINER_NAME} \
    ${DOCKER_NAMESPACE}/${CONTAINER_NAME} \
    ${DOCKER_NAMESPACE}/${CONTAINER_NAME} \
    ${DOCKER_NAMESPACE}/${CONTAINER_NAME} \
docker manifest push lansible/mosquitto:latest