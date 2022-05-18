#!/bin/bash

docker-compose -f docker-compose-bloc-web.yml down
if [[ "$OSTYPE" == "darwin"* ]]; then
	# Mac OSX
    docker-compose -f docker-compose-bloc-server-mac.yml down
elif [[ "$OSTYPE" == "linux"* ]]; then
	# Linux
    docker-compose -f docker-compose-bloc-server-linux.yml down
fi
docker-compose down