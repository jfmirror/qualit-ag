#!/bin/bash
i=0
while read ip
do
	i=$(($i+5))
	echo "ip prefix-list $1 seq $i permit $ip"
done < ./prefix.list
