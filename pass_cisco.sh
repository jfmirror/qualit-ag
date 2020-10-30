#!/bin/bash
#Cisco

IN_FILE="./final"
TMP="./tmp"
MODEL="./model/cisco"
CFG="./cfg"

rm -rf $TMP/*

vrrp(){
        octetos=`echo $ip | awk -F. '{ print $1"."$2"."$3"." }'`
        octeto4=`echo $ip | awk -F. '{ print $4 }'`

        if [ "$iface" = "60" ]; then
        	octeto4=$(($octeto4 + 2))
                ipfisica=`echo ${octetos}${octeto4}`
	elif [ "$iface" != "1" ] && [ "$iface" != "60" ]; then 
        	octeto4=$(($octeto4 - 2))
                ipfisica=`echo ${octetos}${octeto4}`
        fi
}

i=0

ls $IN_FILE/*[^dhcp].csv > $TMP/list_files.txt
while read linea
do

	file=`echo $linea | awk -F"/" '{ print $3 }'`
	echo "process $file"
	i=0

	if [ -f $IN_FILE/${file} ]; then
		cat $IN_FILE/${file} | sed -e '/^type/d' > $TMP/${file}
		while read linea
		do
			tipo=`echo $linea | awk -F"," '{ print $1}'`	
			iface=`echo $linea | awk -F"," '{ print $2}'`
			name=`echo $linea | awk -F"," '{ print $3}'`
			red=`echo $linea | awk -F"," '{ print $4}'`
			redsincidr=`echo $linea | awk -F"," '{ print $4}' | awk -F"/" '{ print $1 }'`
			ipmask=`echo $linea | awk -F"," '{ print $5}'`
			ip=`echo $linea | awk -F"," '{ print $5}' | awk -F" " '{ print $1 }'`
			mask=`echo $linea | awk -F"," '{ print $5}' | awk -F" " '{ print $2 }'`
			cidr=`echo $linea | awk -F"," '{ print $6}'`
			wildcard=`echo $linea | awk -F"," '{ print $7}'`
			device=`echo $linea | awk -F"," '{ print $8}'`
			oficina=`echo $linea | awk -F"," '{ print $9}'`
			dpto=`echo $linea | awk -F"," '{ print $10}'`
			dir=`echo $linea | awk -F"," '{ print $11}'`
			cid=`echo $linea | awk -F"," '{ print $12}'`


			if [ "$tipo" = "L2" ] || [ "$tipo" = "L2L3" ]; then
				if [ "$iface" != "1" ] && [ "$iface" != "" ]; then
					echo "vlan $iface" >> $TMP/2_model_vlans_${file}.txt
					if [ "$name" != "" ]; then
						echo " name \"$name\""  >> $TMP/2_model_vlans_${file}.txt
					fi
					echo "!"  >> $TMP/2_model_vlans_${file}.txt
				fi
			fi
                        if [ "$tipo" = "lo" ] && [ "$device" = "cisco" ]; then
				if [ "$ip" != "" ]; then
					if [ "$iface" != "40" ]; then
						echo -e "!\ninterface Loopback${iface}" >> $TMP/4_model_iface_loopback_${file}.txt
						echo " description \"$name\"" >> $TMP/4_model_iface_loopback_${file}.txt
						echo " ip address $ipmask 255.255.255.255" >> $TMP/4_model_iface_loopback_${file}.txt
						echo "!" >> $TMP/4_model_iface_loopback_${file}.txt
					else
						echo -e "!\ninterface Loopback${iface}" >> $TMP/4_model_iface_loopback_${file}.txt
						echo " description \"$name\"" >> $TMP/4_model_iface_loopback_${file}.txt
						echo " ip address $ipmask 255.255.255.255" >> $TMP/4_model_iface_loopback_${file}.txt
						echo " shutdown" >> $TMP/4_model_iface_loopback_${file}.txt
						echo "!" >> $TMP/4_model_iface_loopback_${file}.txt
					fi
				else
					if [ "$iface" != "40" ]; then
						echo -e "!\nInterface Loopback${iface}" >> $TMP/4_model_iface_loopback_${file}.txt
						echo " description \"$name\"" >> $TMP/4_model_iface_loopback_${file}.txt
						echo " ip address <### ${tipo}_${iface}_${device} > 255.255.255.255" >> $TMP/4_model_iface_loopback_${file}.txt
						echo "!" >> $TMP/4_model_iface_loopback_${file}.txt
					else
						echo -e "!\nInterface Loopback${iface}" >> $TMP/4_model_iface_loopback_${file}.txt
						echo " description \"$name\"" >> $TMP/4_model_iface_loopback_${file}.txt
						echo " ip address <### ${tipo}_${iface}_${device} > 255.255.255.255" >> $TMP/4_model_iface_loopback_${file}.txt
						echo " shutdown" >> $TMP/4_model_iface_loopback_${file}.txt
						echo "!" >> $TMP/4_model_iface_loopback_${file}.txt
					fi
				fi
			fi

			if [ "$tipo" != "lo" ]; then
				if [ "$iface" != "1" ] && [ "$iface" != "" ]; then
					if [ "$ipmask" != "" ]; then
						vrrp
						echo -e "!" >> $TMP/6_model_iface_vlan_${file}.txt
						echo "interface Vlan$iface" >> $TMP/6_model_iface_vlan_${file}.txt
						echo " description \"$name\"" >> $TMP/6_model_iface_vlan_${file}.txt
						echo " ip address $ipfisica $mask" >> $TMP/6_model_iface_vlan_${file}.txt
						echo " ip tcp adjust-mss 1360" >> $TMP/6_model_iface_vlan_${file}.txt
						echo " load-interval 30" >> $TMP/6_model_iface_vlan_${file}.txt
						if [ "$iface" != "BVI1" ]; then
						       if [ $iface -gt 255 ]; then
								tmpiface=`echo $iface | cut -c3`
								echo " vrrp $tmpiface ip $ip" >> $TMP/6_model_iface_vlan_${file}.txt
								echo " vrrp $tmpiface priority 150" >> $TMP/6_model_iface_vlan_${file}.txt
								echo " service-policy input SetDscpLan" >> $TMP/6_model_iface_vlan_${file}.txt
								echo "!" >> $TMP/6_model_iface_vlan_${file}.txt
							else
								echo " vrrp $iface ip $ip" >> $TMP/6_model_iface_vlan_${file}.txt
								echo " vrrp $iface priority 150" >> $TMP/6_model_iface_vlan_${file}.txt
								echo " service-policy input SetDscpLan" >> $TMP/6_model_iface_vlan_${file}.txt
								echo "!" >> $TMP/6_model_iface_vlan_${file}.txt

						       fi
						fi
					fi
				fi
			fi

			if [ "$tipo" = "lo" ] && [ "$iface" = "10" ]; then
				echo -e "!" >> $TMP/8_model_bgp_${file}.txt
				echo "router bgp 64516" >> $TMP/8_model_bgp_${file}.txt
				if [ "$ipmask" != "" ]; then
					echo " bgp router-id $ipmask" >> $TMP/8_model_bgp_${file}.txt
				else
					echo " bgp router-id  <### ${tipo}_${iface}>" >> $TMP/8_model_bgp_${file}.txt

				fi
				echo " bgp log-neighbor-changes" >> $TMP/8_model_bgp_${file}.txt
				echo " neighbor LAN_iBGP peer-group" >> $TMP/8_model_bgp_${file}.txt
				echo " neighbor LAN_iBGP remote-as 64516" >> $TMP/8_model_bgp_${file}.txt
				echo " neighbor LAN_iBGP description \"Enlace Router Local Principal\"" >> $TMP/8_model_bgp_${file}.txt
				echo " neighbor WAN_HS2_PRINC peer-group" >> $TMP/8_model_bgp_${file}.txt
				echo " neighbor WAN_HS2_PRINC remote-as 64630" >> $TMP/8_model_bgp_${file}.txt
				echo " neighbor WAN_HS2_PRINC description \"Enlace Principal VSAT $sede\"" >> $TMP/8_model_bgp_${file}.txt
				echo " neighbor WAN_HS2_PRINC ebgp-multihop 4" >> $TMP/8_model_bgp_${file}.txt
				echo " neighbor WAN_HS2_PRINC timers 15 45" >> $TMP/8_model_bgp_${file}.txt
				echo " neighbor WAN_HS2_SEC peer-group" >> $TMP/8_model_bgp_${file}.txt
				echo " neighbor WAN_HS2_SEC remote-as 64630" >> $TMP/8_model_bgp_${file}.txt
				echo " neighbor WAN_HS2_SEC description \"Enlace Secundario VSAT $sede\"" >> $TMP/8_model_bgp_${file}.txt
				echo " neighbor WAN_HS2_SEC ebgp-multihop 4" >> $TMP/8_model_bgp_${file}.txt
				echo " neighbor WAN_HS2_SEC timers 15 45" >> $TMP/8_model_bgp_${file}.txt
				echo " neighbor <IP_Fisica_BVi0_Teldat> peer-group LAN_iBGP" >> $TMP/8_model_bgp_${file}.txt
				echo " neighbor 172.20.62.251 peer-group WAN_HS2_PRINC" >> $TMP/8_model_bgp_${file}.txt
				echo " neighbor 172.20.62.252 peer-group WAN_HS2_SEC" >> $TMP/8_model_bgp_${file}.txt
				echo " address-family ipv4" >> $TMP/8_model_bgp_${file}.txt
				cat $IN_FILE/${file} | grep -E '^lo|ip_wan|L2L3' > $TMP/datosprefix.txt
				while read datosprefix
				do		
					tmptipo=`echo $datosprefix | awk -F, '{ print $1 }'`
					tmpiface=`echo $datosprefix | awk -F, '{ print $2 }'`
					tmpname=`echo $datosprefix | awk -F, '{ print $3 }'`
					tmpipmask=`echo $datosprefix | awk -F, '{ print $5}'`
					tmpip=`echo $datosprefix | awk -F, '{ print $5}' | awk -F" " '{ print $1}'`
					tmpmask=`echo $datosprefix | awk -F, '{ print $5}' | awk -F" " '{ print $2}'`
					tmpred=`echo $datosprefix | awk -F, '{ print $4}' | awk -F"/" '{ print $1}'`
					tmpdevice=`echo $datosprefix | awk -F"," '{ print $8}'`
					if [ "$tmptipo" = "L2L3" ] && [ "$tmpred" != "" ]; then
						echo "  network $tmpred mask $tmpmask" >> $TMP/8_model_bgp_${file}.txt
					fi
					if [ "$tmptipo" = "lo" ]; then
						if [ "$tmpiface" = "10" ] || [ "$tmpiface" = "20" ] || [ "$tmpiface" = "30" ] || [ "$tmpiface" = "40" ]; then
							if [ "$tmpip" != "" ] ; then
								echo "  network $tmpipmask mask 255.255.255.255" >> $TMP/8_model_bgp_${file}.txt
							else
								echo "  network <### ${tmptipo}_${tmpiface}_${tmpdevice} > mask 255.255.255.255" >> $TMP/8_model_bgp_${file}.txt
							fi
						fi
					fi
				done < $TMP/datosprefix.txt
			fi
				if [ "$iface" = "301" ]; then
					echo "ip access-list extended qos4" >> $TMP/12_model_qos4_${file}.txt
					echo "permit ip $redsincidr $wildcard any" >> $TMP/12_model_qos4_${file}.txt
				fi
				
				if [ "$iface" = "60" ]; then
					echo "ip access-list extended qos5" >> $TMP/12_model_qos5_${file}.txt
					echo " permit ip $redsincidr $wildcard any" >> $TMP/12_model_qos5_${file}.txt
				fi
				if [ "$iface" = "200" ]; then
					echo " permit ip $redsincidr $wildcard 10.16.253.0 0.0.0.255" >> $TMP/12_model_qos5_${file}.txt
					echo " permit ip $redsincidr $wildcard 10.17.253.0 0.0.0.255" >> $TMP/12_model_qos5_${file}.txt
				fi
				if [ "$tipo" = "lo" ] && [ "$iface" = "30" ] && [ "$device" = "cisco" ]; then
					if [ "$ip" != "" ]; then
						echo " permit ip host $ip any" >> $TMP/12_model_qos5_${file}.txt
					else
						echo " permit ip host <### ${tipo}_${iface} > any" >> $TMP/12_model_qos5_${file}.txt

					fi
				fi
				if [ "$tipo" = "lo" ] && [ "$iface" = "40" ] && [ "$device" = "cisco" ]; then
					if [ "$ip" != "" ]; then
						echo " permit ip host $ip any" >> $TMP/12_model_qos5_${file}.txt
					else
						echo " permit ip host <### ${tipo}_${iface} > any" >> $TMP/12_model_qos5_${file}.txt
					fi
				fi

			if [ "$tipo" = "L2L3" ]; then
				i=$(($i + 5))
				if [ "$red" != "" ]; then
					echo "ip prefix-list Red_LAN seq $i permit $red" >> $TMP/14_model_prefixlist_${file}.txt
				else
					echo "ip prefix-list Red_LAN seq $i permit <### ${tipo}_${iface}>" >> $TMP/14_model_prefixlist_${file}.txt
				fi

			elif [ "$tipo" = "lo" ] && [ "$device" = "cisco" ]; then
				i=$(($i + 5))
				if [ "$ip" != "" ]; then
					echo "ip prefix-list Red_LAN seq $i permit $ip" >> $TMP/14_model_prefixlist_${file}.txt
				else
					echo "ip prefix-list Red_LAN seq $i permit <### ${tipo}_${iface}>/32" >> $TMP/14_model_prefixlist_${file}.txt
				fi

			elif [ "$tipo" = "lo" ] && [ "$device" = "teldat" ]; then
				i=$(($i + 5))
				if [ "$ip" != "" ]; then
					echo "ip prefix-list Red_LAN seq $i permit $ip" >> $TMP/14_model_prefixlist_${file}.txt
				else
					echo "ip prefix-list Red_LAN seq $i permit <### ${tipo}_${iface}_$device>/32" >> $TMP/14_model_prefixlist_${file}.txt
				fi
			fi

		done < $TMP/${file}

	cat $MODEL/1_model_hostname.txt  > $CFG/cisco_cfg_${file}.txt
	cat $TMP/2_model_vlans_${file}.txt  >> $CFG/cisco_cfg_${file}.txt
	cat $MODEL/3.txt >> $CFG/cisco_cfg_${file}.txt
	cat $TMP/4_model_iface_loopback_${file}.txt >> $CFG/cisco_cfg_${file}.txt
	cat $MODEL/5_model_interface_wan.txt >> $CFG/cisco_cfg_${file}.txt 
	cat $TMP/6_model_iface_vlan_${file}.txt >> $CFG/cisco_cfg_${file}.txt
	cat $MODEL/7.txt >> $CFG/cisco_cfg_${file}.txt
	cat $TMP/8_model_bgp_${file}.txt >> $CFG/cisco_cfg_${file}.txt
	cat $MODEL/9.txt >> $CFG/cisco_cfg_${file}.txt
	cat $MODEL/10.txt >> $CFG/cisco_cfg_${file}.txt
	cat $MODEL/11.txt >> $CFG/cisco_cfg_${file}.txt
	cat $TMP/12_model_qos4_${file}.txt >> $CFG/cisco_cfg_${file}.txt
	cat $TMP/12_model_qos5_${file}.txt >> $CFG/cisco_cfg_${file}.txt
	cat $MODEL/13.txt >> $CFG/cisco_cfg_${file}.txt
	echo -e "\n" >> $CFG/cisco_cfg_${file}.txt
	cat $TMP/14_model_prefixlist_${file}.txt >> $CFG/cisco_cfg_${file}.txt
	cat $MODEL/15.txt >> $CFG/cisco_cfg_${file}.txt
	#
	#<NOMBRE_SEDE>
	hostname=`echo $file | awk -F"." ' { print $1 }'`
	if [ "$hostname" != "" ]; then
		cat $CFG/cisco_cfg_${file}.txt | sed -e "s/<NOMBRE_SEDE>/$hostname/g" > $TMP/cisco_cfg_${file}.txt
	else
		cat $CFG/cisco_cfg_${file}.txt | sed -e "s/<NOMBRE_SEDE>/<###>/g" > $TMP/cisco_cfg_${file}.txt
	fi

	ip_mod_peer=`cat $IN_FILE/${file} | grep "ip_mod_peer" | awk -F"," '{ print $5 }'`
	if [ "$ip_mod_peer" != "" ]; then
		cat $TMP/cisco_cfg_${file}.txt | sed -e "s/<IP_MODEM>/$ip_mod_peer/g" > $CFG/cisco_cfg_${file}.txt
	else
		cat $TMP/cisco_cfg_${file}.txt | sed -e "s/<IP_MODEM>/<### IP_MODEM>/g" > $CFG/cisco_cfg_${file}.txt
	fi

	#<IP_WAN>
	ip_wan=`cat $IN_FILE/${file} | grep "ip_wan" | awk -F"," '{ print $5 }'`
	if [ "$ip_wan" != "" ]; then
		cat $CFG/cisco_cfg_${file}.txt | sed -e "s/<IP_WAN>/$ip_wan/g" > $TMP/cisco_cfg_${file}.txt
	else
		cat $CFG/cisco_cfg_${file}.txt | sed -e "s/<IP_WAN>/<### IP_WAN>/g" > $TMP/cisco_cfg_${file}.txt

	fi

	#<NOMBRE>
	if [ "$oficina" != "" ]; then
		tmpoficina=`echo $oficina | tr 'a-z' 'A-Z'` 
		cat $TMP/cisco_cfg_${file}.txt | sed -e "s/<NOMBRE>/$tmpoficina/g" > $CFG/cisco_cfg_${file}.txt
	else
		cat $TMP/cisco_cfg_${file}.txt | sed -e "s/<NOMBRE>/<###>/g" > $CFG/cisco_cfg_${file}.txt
	fi

	#<IP_Fisica_BVi0_Teldat>
	ip_fisica=`cat $IN_FILE/${file} | grep "ip_fisica" | awk -F"," '{ print $5 }'`
	if [ "$ip_fisica" != "" ]; then
		cat $TMP/cisco_cfg_${file}.txt | sed -e "s/<IP_Fisica_BVi0_Teldat>/$ip_fisica/g" > $CFG/cisco_cfg_${file}.txt
	else
		cat $TMP/cisco_cfg_${file}.txt | sed -e "s/<IP_Fisica_BVi0_Teldat>/<### IP_Fisica_BVi0_Teldat>/g" > $CFG/cisco_cfg_${file}.txt
	fi

	#<IP_LO_TELDAT_SNA_LO40>
	ip_lo40_teldat=`cat $IN_FILE/${file} | grep "lo" | grep "40" | grep "teldat"| awk -F"," '{ print $5 }'`
	if [ "$ip_lo40_teldat" != "" ]; then
		cat $CFG/cisco_cfg_${file}.txt | sed -e "s/<IP_LO_TELDAT_SNA_LO40>/$ip_lo40_teldat/g" > $TMP/cisco_cfg_${file}.txt
	else
		cat $CFG/cisco_cfg_${file}.txt | sed -e "s/<IP_LO_TELDAT_SNA_LO40>/<### lo_40_teldat >/g" > $TMP/cisco_cfg_${file}.txt
	fi

	#          <DIRECCION>              
	if [ "$dir" != "" ]; then
		cat $TMP/cisco_cfg_${file}.txt | sed -e "s/          <DIRECCION>              /$dir/g" > $CFG/cisco_cfg_${file}.txt
	else
		cat $TMP/cisco_cfg_${file}.txt | sed -e "s/          <DIRECCION>              /<### DIRECCION>/g" > $CFG/cisco_cfg_${file}.txt
	fi

	#             <CIUDAD>              
	if [ "$dpto" != "" ]; then
		cat $CFG/cisco_cfg_${file}.txt | sed -e "s/             <CIUDAD>              /$dpto/g" > $TMP/cisco_cfg_${file}.txt
	else
		cat $CFG/cisco_cfg_${file}.txt | sed -e "s/             <CIUDAD>              /<### SEDE>/g" > $TMP/cisco_cfg_${file}.txt
	fi

	cat $TMP/cisco_cfg_${file}.txt > $CFG/cisco_cfg_${file}.txt

	else
		echo no
	fi
done < $TMP/list_files.txt
