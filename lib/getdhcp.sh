#!/bin/bash
#$1=file backup $2=file pool dhcp

PATH_TMP="./tmp"
FINAL_PATH="./final"
BACKUP="./backup"

#solo nombre backup
backup_name=`echo $1 | awk -F"/" '{ print $3 }'`

echo $2

if [ "$2" != "" ]; then
	excluded=`tr '\n' ';' < ./temp/${backup_name}.dhcp.excluded | sed -e 's/;$//g'`
	while read dhcp_pool
	do
		sed -n "/ip dhcp pool $dhcp_pool/,/\!/p" $1 > $PATH_TMP/${backup_name}_${dhcp_pool}.dhcp
		network=`grep " network " $PATH_TMP/${backup_name}_${dhcp_pool}.dhcp | awk -F" network " '{ print $2 }'`
		defaultrouter=`grep " default-router " $PATH_TMP/${backup_name}_${dhcp_pool}.dhcp | awk -F" default-router " '{ print $2 }'`
		option150=`grep " option 150 ip " $PATH_TMP/${backup_name}_${dhcp_pool}.dhcp | awk -F" option 150 ip " '{ print $2 }'`
		dnsserver=`grep " dns-server " $PATH_TMP/${backup_name}_${dhcp_pool}.dhcp | awk -F" dns-server " '{ print $2 }'`

		echo "$dhcp_pool,$network,$defaultrouter,$option150,$dnsserver,$excluded">> $FINAL_PATH/${backup_name}_dhcp.csv

	done < $2
fi 
