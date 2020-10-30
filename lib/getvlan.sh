#!/bin/bash
# $1=ruta file vlans, $2=ruta file backups $3=flag formato
PATH_TMP="./tmp"
FINAL_PATH="./final"

#rm -rf $PATH_TMP/*

#Categoriza tipo de interface
L2L3() {
 if [ "$1" != "" ]; then
  typo="L2L3"
 else
  typo="L2"
 fi
}

#Datos del direccionamiento de la vlanid
ipnet() {
 if [ "$1" != "" ]; then
  ipcalc -b $1 > $PATH_TMP/${file}_datosred_${vlanid}.txt
  
  red=`cat $PATH_TMP/${file}_datosred_${vlanid}.txt | grep "Network" | awk -F":" '{ print $2}' | sed -e 's/ //g'`
  cidr=`cat $PATH_TMP/${file}_datosred_${vlanid}.txt | grep "Network" | awk -F"/" '{ print "/"$2}' | sed -e 's/ //g'`
  wildcard=`cat $PATH_TMP/${file}_datosred_${vlanid}.txt | grep "Wildcard" | awk -F":" '{ print $2}' | sed -e 's/ //g'`
 fi
}

ipteldat(){
        tmpipteldat=`echo $1 | awk -F" " '{ print $1 }'`
        octetos_teldat=`echo $tmpipteldat | awk -F. '{ print $1"."$2"."$3"." }'`
        octeto4_teldat=`echo $tmpipteldat | awk -F. '{ print $4 }'`
        octeto4_teldat=$(($octeto4_teldat - 1))
        ipfisica_teldat=`echo $octetos_teldat$octeto4_teldat`
}

file=`echo "$1" | awk -F"/" '{ print $3 }'`
while read vlanid
do
	if [ "$3" = "1" ]; then
		#Bloque BVI
		if [ "$vlanid" = "BVI1" ] ; then
		#if [ "$vlanid" = "200" ] ; then
			sed -n "/^interface ${vlanid}/,/\!/p" $2 > $PATH_TMP/${file}_l3vlan$vlanid.txt
			#sed -n "/^interface GigabitEthernet[01]\/[01]\.${vlanid}\$/,/\!/p" $2 >> "$PATH_TMP/${file}_l3vlan${vlanid}.txt"
			if [ -f $PATH_TMP/${file}_l3vlan$vlanid.txt ]; then	
				description=`cat $PATH_TMP/${file}_l3vlan$vlanid.txt | grep -e "^ description " | awk -F" description " '{ print $2 }' | sed -e 's/"//g'`
				ipmask=`cat $PATH_TMP/${file}_l3vlan$vlanid.txt | grep -e "^ ip address " | awk -F" ip address " '{ print $2 }'`
				L2L3 "$ipmask"
				#pasando ip y mascara a la funcion
				if [ "$typo" = "L2L3" ]; then
					ipnet "$ipmask"
					echo "$typo,$vlanid,$description,$red,$ipmask,$cidr,$wildcard"
					echo "$typo,200,SNA,$red,$ipmask,$cidr,$wildcard,,,,,,ererer" >> $FINAL_PATH/${file}.csv

					#restando 1 para hallar ip fisical teldat
					ipteldat $ipmask
					echo "ip_fisica,,Fisica,,$ipfisica_teldat,,,teldat,,,,,ererer" > ./tmp/teldatipfisica.txt
				else
					red=""
					ipmask=""
					cidr=""
					wildcard=""
				fi

			fi
		elif [ "$vlanid" != "200" ]; then
			#Bloque ip
			sed -n "/^interface Vlan${vlanid}/,/\!/p" $2 > $PATH_TMP/${file}_l3vlan$vlanid.txt
			#sed -n "/^interface GigabitEthernet[01]\/[01]\.${vlanid}\$/,/\!/p" $2 >> $PATH_TMP/${file}_l3vlan$vlanid.txt
			if [ -f $PATH_TMP/${file}_l3vlan$vlanid.txt ]; then	
				description=`cat $PATH_TMP/${file}_l3vlan$vlanid.txt | grep -e "^ description " | awk -F" description " '{ print $2}' | sed -e 's/"//g'`
				ipmask=`cat $PATH_TMP/${file}_l3vlan$vlanid.txt | grep -e "^ ip address " | awk -F" ip address " '{ print $2 }'`
				L2L3 "$ipmask"
				#pasando ip y mascara a la funcion
				if [ "$typo" = "L2L3" ]; then
					ipnet "$ipmask"
					echo "$typo,$vlanid,$description,$red,$ipmask,$cidr,$wildcard"
					echo "$typo,$vlanid,$description,$red,$ipmask,$cidr,$wildcard,,,,,,ererer" >> $FINAL_PATH/${file}.csv
				else
					red=""
					ipmask=""
					cidr=""
					wildcard=""
				fi
			fi
		fi

	elif [ "$3" = "2" ]; then
		#Bloque BVI
		if [ "$vlanid" = "BVI1" ]; then
			sed -n "/^interface ${vlanid}$/,/\!/p" $2 > $PATH_TMP/${file}_l3$vlanid.txt
			if [ -f $PATH_TMP/${file}_l3$vlanid.txt ]; then
				description=`cat $PATH_TMP/${file}_l3$vlanid.txt | grep -e "^ description " | awk -F" description " '{ print $2 }' | sed -e 's/"//g'`
				ipmask=`cat $PATH_TMP/${file}_l3$vlanid.txt | grep -e "^ ip address " | awk -F" ip address " '{ print $2 }'`
				L2L3 "$ipmask"
				#pasando ip y mascara a la funcion
				if [ "$typo" = "L2L3" ]; then
					ipnet "$ipmask"
				else
					red=""
					ipmask=""
					cidr=""
					wildcard=""
				fi

				echo "$typo,$vlanid,$description,$red,$ipmask,$cidr,$wildcard"
				echo "$typo,$vlanid,$description,$red,$ipmask,$cidr,$wildcard,,,,,,ererer" >> $FINAL_PATH/${file}.csv
			fi
		else
			#Bloque ip
			sed -n "/^interface GigabitEthernet[0|1]\/[0|1]\.${vlanid}$/,/\!/p" $2 > $PATH_TMP/${file}_l3vlan$vlanid.txt
			if [ -f $PATH_TMP/${file}_l3vlan$vlanid.txt ]; then
				description=`cat $PATH_TMP/${file}_l3vlan$vlanid.txt | grep -e "^ description " | awk -F" description " '{ print $2 }' | sed -e 's/"//g'`
				ipmask=`cat $PATH_TMP/${file}_l3vlan$vlanid.txt | grep -e "^ ip address " | awk -F" ip address " '{ print $2 }'`
				L2L3 "$ipmask"
				#pasando ip y mascara a la funcion
				if [ "$typo" = "L2L3" ]; then
					ipnet "$ipmask"
				else
					red=""
					ipmask=""
					cidr=""
					wildcard=""
				fi

				echo "$typo,$vlanid,$description,$red,$ipmask,$cidr,$wildcard"
				echo "$typo,$vlanid,$description,$red,$ipmask,$cidr,$wildcard,,,,,,ererer" >> $FINAL_PATH/${file}.csv
			fi
		fi
	fi
done < $1
