#!/bin/bash
while read interface
do
	iface=`echo $interface | awk -F" " '{ print $1 }'`
	echo "network $iface"
	echo "no shutdown"
	echo "exit"
	echo ";"
done < ./interfaces.txt
