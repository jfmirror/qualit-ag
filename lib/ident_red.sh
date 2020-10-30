#!/bin/bash
while read line
do
	vlan=`echo $line | awk -F, '{ print $1 }'`
	if [[ "$vlan" != "vlan" ]]; then
		#IP y MK
		ip=`echo $line | awk -F, '{ print $3}' | awk -F" " '{ print $1"/"$2 }'`
		ipcalc $ip > 
		
		#solo mascara de s.r.
		#mask=`echo $line | awk -F, '{ print $3}' | awk -F" " '{ print $2 }'`

		if [[ -n $mask ]]; then
			cidr=`echo $line | awk -F, '{ print $4 }'`
			if [[ $cidr -gt 23 ]]; then
				octeto1al3=`echo $ip | awk -F. '{ print $1"."$2"."$3 }'`
				octeto4=`echo $ip | awk -F. '{ print $4 }'`
				mkocteto4=`echo $mask | awk -F. '{ print $4 }'`

				sh ./datosip.sh $cidr $octeto1al3 $octeto4 $ip

				elif [[ $cidr -lt 24 ]] && [[ $cidr -gt 16 ]]; then
					octeto1al2=`echo $ip | awk -F. '{ print $1"."$2 }'`
					octeto3=`echo $ip | awk -F. '{ print $3 }'`
					mkocteto3=`echo $mask | awk -F. '{ print $3 }'`

					sh ./datosip.sh $cidr $octeto1al2 $octeto3 $ip
				else
					echo "no hay coincidencias"
			fi
		fi
	fi

done < ../final/cfg_backup.txt_cfg_vlanip.csv
