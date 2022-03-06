#!/bin/bash

# check needed port not used
used_ports=(8080, 27017, 5672, 15672, 9000, 8086)
for element in ${used_ports[@]}
do
	Pid=`lsof -i:$element | awk '{print $1 "  " $2}'`
	if [[ -z "$Pid" ]]
	then
		echo "bloc will use port $element"
	else
		echo "Fail: bloc is to use port $element but its in use - '$Pid'"
		exit 8
	fi
done

# start infra docker-compose
docker-compose up -d

# check infra components all ready
echo "checking whether influxDB is ready"
while :
do
	RESULT=$(curl -s --location --request GET 'http://localhost:8086/api/v2/setup')
	if [[ $RESULT == *"allowed"* ]]
	then
		break
	else
		echo "    Not ready"
	fi
	sleep 1
done
echo "    ready!"

echo "start check whether minio is ready"
while :
do
        RESULT=$(curl -s -o /dev/null -I -w "%{http_code}" 'http://localhost:9000/minio/health/live')
	if [[ $RESULT == "200" ]]
	then
		break
	else
		echo "    Not ready"
	fi
        sleep 1
done
echo "    ready!"

echo "start check whether rabbitMQ is ready"
while :
do
        RESULT=$(curl -s -o /dev/null -I -w "%{http_code}" 'http://localhost:15672/api/overview')
	if [[ $RESULT == *"401"* ]]
	then
		break
	else
		echo "    Not ready"
	fi
        sleep 1
done
echo "    ready!"

echo "start check whether mongoDB is ready"
while :
do
	Pid=`lsof -i:27017 | awk '{print $1 "  " $2}'`
	if [[ $RESULT == "" ]]
	then
		echo "    mongoDB not ready"
	else
		break
	fi
        sleep 1
done
echo "ready!"

# start bloc-server
echo "Starting bloc-server"
bloc_server_yaml=""
if [[ "$OSTYPE" == "darwin"* ]]; then
	# Mac OSX
	bloc_server_yaml="docker-compose-bloc-server-mac.yml"
else
	bloc_server_yaml="docker-compose-bloc-server-linux.yml"
fi

echo "bloc-server yaml file: $bloc_server_yaml"

try_amount=5
while [[ try_amount > 0 ]]
do
	docker-compose -f "$bloc_server_yaml" up -d
	server_status=`docker-compose -f "$bloc_server_yaml" ps | grep bloc_server`
	if [[ $server_status == *"Up"* ]]
	then
		echo "bloc-server is up"
		break
	else
		try_amount=$((try_amount - 1))
		sleep 10
		docker-compose -f "$bloc_server_yaml" up -d
	fi
done

echo "Checking whether bloc-server is valid"
RESULT=$(curl -s --location --request GET 'http://localhost:8080/api/v1/bloc')
if [[ $RESULT == *"Welcome aboard"* ]]
then
	echo "bloc-server is valid. All ready!"
else
	echo "bloc-server is not ready"
	./shutdown.sh
	exit 8
fi

# TODO 部署前端项目

# TODO 引导用户访问前端地址