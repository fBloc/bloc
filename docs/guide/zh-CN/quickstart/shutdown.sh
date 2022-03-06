#!/bin/bash

docker-compose down
docker-compose -f docker-compose-bloc-server-mac.yml down
docker-compose -f docker-compose-bloc-server-linux.yml down
