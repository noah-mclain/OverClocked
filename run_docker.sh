#!/bin/bash

export HOST_OS=$(uname)

docker compose -f docker/docker-compose.yml up --build