#!/bin/bash

#docker kill gabarodigital/realtime-metrics
#docker rm ganbarodigital/realtime-metrics
#truncate ./logs/* --size 0

DAEMON=
if [[ -z $1 ]] ; then
	DAEMON="-d"
fi

docker run $DAEMON -v $(pwd)/logs:/var/log/supervisor -p 8200:80 -p 8201:81 -p 8125:8125/udp -p 8126:8126 -t -i ganbarodigital/realtime-metrics $*