#!/bin/bash
cidr=$1
octetos=$2
octeto=$3
ip=$4

bit=$((32 - $cidr))
dif=$((8 - $bit) 
saltos=$((2 ** $bits))

if [[ $octeto -gt 0 ]]&&[[ $octeto -lt $saltos ]]; then
	echo operacion
	echo "--------"
	echo "#host = 2^$bit"
	echo "#J = 2^"
	echo $octetos.$((0 + 1))

fi


#cho $octetos.$octeto / $bit / $saltos
