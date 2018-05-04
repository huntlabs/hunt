#!/bin/bash

echo "Usage: ./bench.sh Name plaintext 127.0.0.1 8080"

let max_threads=$(cat /proc/cpuinfo | grep processor | wc -l)
accept="text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
duration=15
levels=(512 512 512 512 512)
max_concurrency=512

if [ -n "$1" ]; then
name=$1
else
name="Unknown"
fi

if [ -n "$2" ]; then
test_type=$2
else
test_type="plaintext"
fi
	
if [ -n "$3" ]; then
server_host=$3
else
server_host="127.0.0.1"
fi

if [ -n "$4" ]; then
server_port=$4
else
server_port=8080
fi

url="http://$server_host:$server_port/$test_type"


echo ""
echo "---------------------------------------------------------"
echo " Running Primer $name"
echo " wrk -H 'Host: $server_host' -H 'Accept: $accept' -H 'Connection: keep-alive' --latency -d 5 -c 8 --timeout 8 -t 8 $url"
echo "---------------------------------------------------------"
echo ""
wrk -H 'Host: $server_host' -H 'Accept: $accept' -H 'Connection: keep-alive' --latency -d 5 -c 8 --timeout 8 -t 8 $url
sleep 5

echo ""
echo "---------------------------------------------------------"
echo " Running Warmup $name"
echo " wrk -H 'Host: $server_host' -H 'Accept: $accept' -H 'Connection: keep-alive' --latency -d $duration -c $max_concurrency --timeout 8 -t $max_threads \"$url\""
echo "---------------------------------------------------------"
echo ""
wrk -H 'Host: $server_host' -H 'Accept: $accept' -H 'Connection: keep-alive' --latency -d $duration -c $max_concurrency --timeout 8 -t $max_threads $url
sleep 5

for c in ${levels[*]}
do
echo ""
echo "---------------------------------------------------------"
echo " Concurrency: $c for $name"
echo " wrk -H 'Host: $server_host' -H 'Accept: $accept' -H 'Connection: keep-alive' --latency -d $duration -c $c --timeout 8 -t $(($c>$max_threads?$max_threads:$c)) \"$url\""
echo "---------------------------------------------------------"
echo ""
STARTTIME=$(date +"%s")
wrk -H 'Host: $server_host' -H 'Accept: $accept' -H 'Connection: keep-alive' --latency -d $duration -c $c --timeout 8 -t "$(($c>$max_threads?$max_threads:$c))" $url
echo "STARTTIME $STARTTIME"
echo "ENDTIME $(date +"%s")"
sleep 2
done
