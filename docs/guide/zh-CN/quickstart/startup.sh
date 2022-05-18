#!/bin/bash
# ----------- download relate fiels -----------
# make sure docker-compose.yml exist
infraFileLength=`cat docker-compose.yml | wc -l | xargs`

if [[ $infraFileLength == *"No such file"* ]]; then  # not exist then download
	wget -q https://raw.githubusercontent.com/fBloc/bloc/main/docs/guide/zh-CN/quickstart/docker-compose.yml -O docker-compose.yml
	infraFileLength=`cat docker-compose.yml | wc -l | xargs`
fi

if [[ $infraFileLength == "0" ]]; then  # download not valid, reminder user to download handly
	echo "Download docker-compose.yml fail. plz download https://raw.githubusercontent.com/fBloc/bloc/main/docs/guide/zh-CN/quickstart/docker-compose.yml to your current directory and name it to docker-compose.yml"
	exit 8
fi
echo "docker-compose.yml exist"

# make sure docker-compose-bloc-server-mac.yml exist
macServerComposeFileLineAmount=`cat docker-compose-bloc-server-mac.yml | wc -l | xargs`

if [[ $macServerComposeFileLineAmount == *"No such file"* ]]; then  # not exist then download
	wget -q https://raw.githubusercontent.com/fBloc/bloc/main/docs/guide/zh-CN/quickstart/docker-compose-bloc-server-mac.yml -O docker-compose-bloc-server-mac.yml
	macServerComposeFileLineAmount=`cat docker-compose-bloc-server-mac.yml | wc -l | xargs`
fi

if [[ $macServerComposeFileLineAmount == "0" ]]; then
	echo "Download docker-compose-bloc-server-mac.yml fail. plz download https://raw.githubusercontent.com/fBloc/bloc/main/docs/guide/zh-CN/quickstart/docker-compose-bloc-server-mac.yml to your current directory and name it to docker-compose-bloc-server-mac.yml"
	exit 8
fi
echo "docker-compose-bloc-server-mac.yml exist"

# make sure docker-compose-bloc-server-linux.yml exist
linuxServerComposeFileLineAmount=`cat docker-compose-bloc-server-linux.yml | wc -l | xargs`
if [[ $linuxServerComposeFileLineAmount == *"No such file"* ]]; then  # not exist then download
	wget -q https://raw.githubusercontent.com/fBloc/bloc/main/docs/guide/zh-CN/quickstart/docker-compose-bloc-server-linux.yml -O docker-compose-bloc-server-linux.yml
	linuxServerComposeFileLineAmount=`cat docker-compose-bloc-server-linux.yml | wc -l | xargs`
fi

if [[ $linuxServerComposeFileLineAmount == "0" ]]; then
	echo "Download docker-compose-bloc-server-linux.yml fail. plz download https://raw.githubusercontent.com/fBloc/bloc/main/docs/guide/zh-CN/quickstart/docker-compose-bloc-server-linux.yml to your current directory and name it to docker-compose-bloc-server-linux.yml"
	exit 8
fi
echo "docker-compose-bloc-server-linux.yml exist"

# make sure shutdown.sh exist
shutdownShFileLineAmount=`cat shutdown.sh | wc -l | xargs`
if [[ $shutdownShFileLineAmount == *"No such file"* ]]; then  # not exist then download
	wget -q https://raw.githubusercontent.com/fBloc/bloc/main/docs/guide/zh-CN/quickstart/shutdown.sh -O shutdown.sh
	shutdownShFileLineAmount=`cat shutdown.sh | wc -l | xargs`
fi

if [[ $shutdownShFileLineAmount == "0" ]]; then
	echo "Download shutdown.sh fail. plz download https://raw.githubusercontent.com/fBloc/bloc/main/docs/guide/zh-CN/quickstart/shutdown.sh to your current directory and name it to shutdown.sh"
	exit 8
fi
echo "shutdown.sh exist"

# ----------- end download -----------

# check needed port not used
used_ports=(8083, 8080, 27017, 5672, 15672, 9000, 8086)
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
echo "    ready!"

# start bloc-server
echo "Starting bloc-server"
bloc_server_yaml=""
if [[ "$OSTYPE" == "darwin"* ]]; then
	# Mac OSX
	bloc_server_yaml="docker-compose-bloc-server-mac.yml"
elif [[ "$OSTYPE" == "linux"* ]]; then
	# Linux
	bloc_server_yaml="docker-compose-bloc-server-linux.yml"
else
	# tmp to just use linux. later should support windows
	echo "your os $OSTYPE maybe not supported, use linux as default!"
	bloc_server_yaml="docker-compose-bloc-server-linux.yml"
fi

echo "bloc-server yaml file: $bloc_server_yaml"

try_amount=5
while [[ try_amount > 0 ]]
do
	docker-compose -f "$bloc_server_yaml" up -d
	sleep 3
	server_status=`docker-compose -f "$bloc_server_yaml" ps | grep bloc_server`
	if [[ $server_status == *"Up"* ]]
	then
		echo "    bloc-server is up"
		break
	else
		echo "    bloc-server is not up, retry"
		try_amount=$((try_amount - 1))
	fi
done

echo "Checking whether bloc-server is valid"
RESULT=$(curl -s --location --request GET 'http://localhost:8080/api/v1/bloc')
if [[ $RESULT == *"Welcome aboard!"* ]]
then
	echo "    bloc-server is valid"
else
	echo "    bloc-server is not ready"
	./shutdown.sh
	exit 8
fi

# start bloc-web
bloc_web_yaml="docker-compose-bloc-web.yml"
echo "Starting bloc_web, yaml file: $bloc_web_yaml"
docker-compose -f "$bloc_web_yaml" up -d
server_status=`docker-compose -f "$bloc_web_yaml" ps | grep bloc_web`
if [[ $server_status == *"Up"* ]]
then
	echo "    bloc_web is up"
fi

# Guide users to access the front-end address
echo "******************************"
echo "All ready, Visit http://localhost:8083/ to visit bloc UI"

if [[ "$OSTYPE" == "darwin"* ]]; then
	# Mac OSX
	open http://localhost:8083/
elif [[ "$OSTYPE" == "linux"* ]]; then
	# Linux
	xdg-open http://localhost:8083/
fi