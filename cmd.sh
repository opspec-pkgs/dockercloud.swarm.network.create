#!/bin/sh

set -e

echo "starting docker daemon"
nohup dockerd \
  --host=unix:///var/run/docker.sock \
  --storage-driver=overlay2 &

# poll for docker daemon up
max_retries=6
n=0
until [ $n -ge $max_retries ]
do
  docker ps > /dev/null 2>&1 && break
  n=$((n+1))
  sleep 1
done

if [ "$n" -eq "$max_retries" ]; then
  # assume failed
  cat nohup.out
  exit 1
fi

echo "connecting to swarm $SWARM_NAME as $DOCKER_USER"
result=$(/client)
export "${result##* }"

echo creating network if not found
docker network inspect "$networkName" &> /dev/null || docker network create --driver "$networkDriver" "$networkName"
