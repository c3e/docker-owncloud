#!/bin/sh

OWNCLOUD_VERSION=8.1.0

docker build $@ --rm -t owncloud:${OWNCLOUD_VERSION} .
docker tag -f owncloud:${OWNCLOUD_VERSION} owncloud:latest

# docker build $@ --rm -t owncloud-data - < Dockerfile.DC
