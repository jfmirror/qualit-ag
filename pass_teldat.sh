#!/bin/bash
#TELDAT

IN_FILE="./final"
TMP="./tmp"
MODEL="./model/teldat"
CFG="./cfg"

i=0
entry=0

rm -rf $TMP/*

vrrp(){
        octetos=`echo $ip | awk -F. '{ print $1"."$2"."$3"." }'`
        octeto4=`echo $ip | awk -F. '{ print $4 }'`

        if [ "$iface" = "60" ]; then
                octeto4=$(($octeto4 + 1))
                ipfisica=`echo ${octetos}${octeto4}`
        elif [ "$iface" != "1" ] && [ "$iface" != "60" ]; then
                octeto4=$(($octeto4 - 1))
                ipfisica=`echo ${octetos}${octeto4}`
        fi
}

ipnet(){
	ipcalc -b $1 > $TMP/${file}_dhcp.tmp
	ipmax=`cat $TMP/${file}_dhcp.tmp | grep "HostMax" | awk -F":" '{ print $2}' | tr -d '\n' | sed -e "s/ //g"`
	ipmin=`cat $TMP/${file}_dhcp.tmp | grep "HostMin" | awk -F":" '{ print $2}' | tr -d '\n' | sed -e "s/ //g"`

	if [ "$iface" = "60" ]; then
		octetos=`echo $ipmin | awk -F"." '{ print $1"."$2"."$3"." }'`
		#octeto4=`echo $ipmin | awk -F"." '{ print $4 }'`
		#octeto4=$(($octeto4 + 3))
		#nuevaipmin=`echo ${octetos}$octeto4`
		#nuevaipmin=`echo ${octetos}20`
	else
		octetos=`echo $ipmax | awk -F"." '{ print $1"."$2"."$3"." }'`
		#octeto4=`echo $ipmax | awk -F"." '{ print $4 }'`
		#octeto4=$(($octeto4 - 4))
		#nuevaipmax=`echo $octetos$octeto4`
		#nuevaipmax=`echo ${octetos}97`
	fi
}

ls $IN_FILE/*[^dhcp].csv > $TMP/list_files.txt

while read linea
do
	i=0
        file=`echo $linea | awk -F"/" '{ print $3 }'`

	echo "process $file"

        if [ -f $IN_FILE/${file} ]; then
                cat $IN_FILE/${file} | sed -e '/^type/d' > $TMP/${file}
                while read linea
		do
                        tipo=`echo $linea | awk -F"," '{ print $1 }'`
                        iface=`echo $linea | awk -F"," '{ print $2 }'`
                        name=`echo $linea | awk -F"," '{ print $3 }'`
                        red=`echo $linea | awk -F"," '{ print $4 }'`
                        redsincidr=`echo $linea | awk -F"," '{ print $4 }' | awk -F"/" '{ print $1 }'`
                        ipmask=`echo $linea | awk -F"," '{ print $5 }'`
                        ip=`echo $linea | awk -F"," '{ print $5 }' | awk -F" " '{ print $1 }'`
                        mask=`echo $linea | awk -F"," '{ print $5 }' | awk -F" " '{ print $2 }'`
                        cidr=`echo $linea | awk -F"," '{ print $6 }'`
                        wildcard=`echo $linea | awk -F"," '{ print $7 }'`
                        device=`echo $linea | awk -F"," '{ print $8 }'`
                        oficina=`echo $linea | awk -F"," '{ print $9 }'`
                        dpto=`echo $linea | awk -F"," '{ print $10 }'`
                        dir=`echo $linea | awk -F"," '{ print $11 }'`
                        cid=`echo $linea | awk -F"," '{ print $12 }'`

			#DHCP
			if [ "$iface" = "60" ]; then 
				echo ";" >> $TMP/7_1_dhcp_${file}.txt
					       ipnet $ipmask $iface 
				echo "         subnet VOIP 1 network $redsincidr $mask" >> $TMP/7_1_dhcp_${file}.txt
				#echo "         subnet VOIP 1 range $nuevaipmin $ipmax" >> $TMP/7_1_dhcp_${file}.txt
				echo "         subnet VOIP 1 range ${octetos}20 ${octetos}22" >> $TMP/7_1_dhcp_${file}.txt
				echo "         subnet VOIP 1 dns-server 10.7.11.12" >> $TMP/7_1_dhcp_${file}.txt
				echo "         subnet VOIP 1 dns-server 10.7.11.180" >> $TMP/7_1_dhcp_${file}.txt
				echo "         subnet VOIP 1 router $ip" >> $TMP/7_1_dhcp_${file}.txt
				echo "         subnet VOIP 1 option 150 hex 0a0f5114" >> $TMP/7_1_dhcp_${file}.txt
				echo "         subnet VOIP 1 option 150 hex 0a07140d" >> $TMP/7_1_dhcp_${file}.txt
				echo "         subnet VOIP 1 option 150 hex 0a0f510c" >> $TMP/7_1_dhcp_${file}.txt
				echo ";" >> $TMP/7_1_dhcp_${file}.txt
			fi

			if [ "$iface" = "202" ]; then 
					       ipnet $ipmask $iface 
				echo "         subnet POS 2 network $redsincidr $mask" >> $TMP/7_1_dhcp_${file}.txt
				#echo "         subnet POS 2 range $ipmin $nuevaipmax" >> $TMP/7_1_dhcp_${file}.txt
				echo "         subnet POS 2 range ${octetos}97 ${octetos}99" >> $TMP/7_1_dhcp_${file}.txt
				file_dhcp=`echo $file | awk -F"." '{ print $1 }'`
				if [ -f $IN_FILE/${file_dhcp}_dhcp.csv ]; then
					IP_DNS_VLAN_202=`cat $IN_FILE/${file_dhcp}_dhcp.csv | grep "POS" | awk -F, '{ print $5 }'`
					echo "         subnet POS 2 dns-server $IP_DNS_VLAN_202" >> $TMP/7_1_dhcp_${file}.txt
				else
					echo "         subnet POS 2 dns-server [IP_DNS_VLAN_202]" >> $TMP/7_1_dhcp_${file}.txt

				fi
				echo "         subnet POS 2 router $ip" >> $TMP/7_1_dhcp_${file}.txt
				echo ";" >> $TMP/7_1_dhcp_${file}.txt
				echo "      exit" >> $TMP/7_1_dhcp_${file}.txt
				echo ";" >> $TMP/7_1_dhcp_${file}.txt
				echo "   exit" >> $TMP/7_1_dhcp_${file}.txt
				echo ";" >> $TMP/7_1_dhcp_${file}.txt
			fi

			#Interface fisicas
			if [ "$tipo" = "L2L3" ] || [ "$tipo" = "L2" ]; then
				echo "   add device eth-subinterface ethernet0/0 $iface" >> $TMP/1_subinterfaces_${file}.txt
			
			#Interfaces loopback and network loopback
			elif [ "$tipo" = "lo" ] && [ "$device" = "teldat" ]; then
				if [ "$ipmask" != "" ]; then
					echo "   add device loopback $iface" >> $TMP/1_loopback_${file}.txt
					echo "   network loopback$iface" >> $TMP/5_network_loopback_${file}.txt
					echo "; -- Loopback interface configuration --"  >> $TMP/5_network_loopback_${file}.txt
					echo "      description \"Loopback $name\""  >> $TMP/5_network_loopback_${file}.txt
					echo ";"  >> $TMP/5_network_loopback_${file}.txt
					echo "      ip address $ipmask 255.255.255.255"  >> $TMP/5_network_loopback_${file}.txt
					if [ "$iface" = "40" ]; then
						echo "      shutdown" >> $TMP/5_network_loopback_${file}.txt
					fi
					echo ";"  >> $TMP/5_network_loopback_${file}.txt
					echo "   exit"  >> $TMP/5_network_loopback_${file}.txt
					echo ";"  >> $TMP/5_network_loopback_${file}.txt
				else
					echo "***" >> $TMP/1_loopback_${file}.txt
					#echo "   add device loopback $iface" >> $TMP/1_loopback_${file}.txt
					echo "   network loopback$iface" >> $TMP/5_network_loopback_${file}.txt
					echo "; -- Loopback interface configuration --"  >> $TMP/5_network_loopback_${file}.txt
					echo "      description \"Loopback $name\""  >> $TMP/5_network_loopback_${file}.txt
					echo ";"  >> $TMP/5_network_loopback_${file}.txt
					echo "      ip address <### ${tipo}_${iface}> 255.255.255.255"  >> $TMP/5_network_loopback_${file}.txt
					if [ "$iface" = "40" ]; then
						echo "      shutdown" >> $TMP/5_network_loopback_${file}.txt
					fi
					echo ";"  >> $TMP/5_network_loopback_${file}.txt
					echo "   exit"  >> $TMP/5_network_loopback_${file}.txt
					echo ";"  >> $TMP/5_network_loopback_${file}.txt
				fi
			fi

			#prefix list fisicas
			if [ "$tipo" = "L2L3" ] && [ "$tipo" != "lo" ]; then
				i=$(($i + 1))

				echo "      vlan $iface ethernet0/0 port 1" >> $TMP/10_vlan_${file}.txt
				echo "      vlan $iface ethernet0/0 port 2" >> $TMP/10_vlan_${file}.txt
				echo "      vlan $iface ethernet0/0 port internal" >> $TMP/10_vlan_${file}.txt
			fi
			#prefixlist list loopback
			if [ "$tipo" = "lo" ] && [ "$device" = "teldat" ]; then
				i=$(($i + 1))
				echo "      entry $i default" >> $TMP/3_prefix_list100_${file}.txt
				echo "      entry $i permit" >> $TMP/3_prefix_list100_${file}.txt
				echo "      entry $i prefix $ip 255.255.255.255" >> $TMP/3_prefix_list100_${file}.txt
				echo ";" >> $TMP/3_prefix_list100_${file}.txt
			fi
					
			#BGP
			if [ "$tipo" = "lo" ] && [ "$device" = "teldat" ]; then
				if [ "$iface" != "40" ]; then
					echo "         export as 12252 prot direct host $ipmask" >> $TMP/8_bgp_${file}.txt
				else
					echo "         export as 12252 prot direct host $ipmask" restric >> $TMP/8_bgp_${file}.txt
				fi
			fi

			if [ "$tipo" = "L2L3" ] && [ "$iface" = "200" ]; then
				echo "         export as 12252 prot direct $redsincidr mask $mask exact restric" >> $TMP/8_bgp_${file}.txt
			elif [ "$tipo" = "L2L3" ]; then
				echo "         export as 12252 prot direct $redsincidr mask $mask exact" >> $TMP/8_bgp_${file}.txt
			fi

			if [ "$tipo" = "L2L3" ]; then
                                echo "      entry $i default" >> $TMP/3_prefix_list100_${file}.txt
       	                        echo "      entry $i permit" >> $TMP/3_prefix_list100_${file}.txt
               	                echo "      entry $i prefix $redsincidr $mask" >> $TMP/3_prefix_list100_${file}.txt
                       	        echo ";" >> $TMP/3_prefix_list100_${file}.txt

				#vrrp BVI
				if [ "$iface" = "200" ]; then
					echo "   network ethernet0/0.$iface" >> $TMP/6_vrrp_${file}.txt
					echo "; -- Ethernet Subinterface Configuration --" >> $TMP/6_vrrp_${file}.txt
					echo "      description \"$name\"" >> $TMP/6_vrrp_${file}.txt
					echo ";" >> $TMP/6_vrrp_${file}.txt
					echo "      ip policy route-map SET_DSCP" >> $TMP/6_vrrp_${file}.txt
					echo "      ip tcp adjust-mss 1360" >> $TMP/6_vrrp_${file}.txt
					echo ";" >> $TMP/6_vrrp_${file}.txt
					echo "      load-interval 30" >> $TMP/6_vrrp_${file}.txt
					echo "      encapsulation dot1q $iface" >> $TMP/6_vrrp_${file}.txt
					echo "      shutdown" >> $TMP/6_vrrp_${file}.txt
					echo "      exit" >> $TMP/6_vrrp_${file}.txt
					echo ";" >> $TMP/6_vrrp_${file}.txt
					#
					echo "   network bvi0" >> $TMP/6_vrrp_${file}.txt
					echo "; -- Bridge Virtual Interface configuration --" >> $TMP/6_vrrp_${file}.txt
					echo "      description \"BRIDGE-SNA-USUARIOS\"" >> $TMP/6_vrrp_${file}.txt
					echo ";"  >> $TMP/6_vrrp_${file}.txt
					vrrp $ip
					echo "      ip address $ipfisica $mask" >> $TMP/6_vrrp_${file}.txt
					echo "      ip policy route-map SET_DSCP" >> $TMP/6_vrrp_${file}.txt
					echo "      ip tcp adjust-mss 1360" >> $TMP/6_vrrp_${file}.txt
					echo ";" >> $TMP/6_vrrp_${file}.txt
			        	echo "      ip vrrp $iface ip $ip" >> $TMP/6_vrrp_${file}.txt
					echo "      ip vrrp $iface priority 200" >> $TMP/6_vrrp_${file}.txt
					echo ";" >> $TMP/6_vrrp_${file}.txt
					echo "      load-interval 30" >> $TMP/6_vrrp_${file}.txt
  				        echo "      shutdown" >> $TMP/6_vrrp_${file}.txt
					echo ";" >> $TMP/6_vrrp_${file}.txt
					echo "      exit" >> $TMP/6_vrrp_${file}.txt
					echo ";" >> $TMP/6_vrrp_${file}.txt
				else
					echo "   network ethernet0/0.$iface" >> $TMP/6_vrrp_${file}.txt
					echo "; -- Ethernet Switch configuration --" >> $TMP/6_vrrp_${file}.txt
					echo "      description \"$name\"" >> $TMP/6_vrrp_${file}.txt
					echo ";"  >> $TMP/6_vrrp_${file}.txt
					vrrp $ip
					echo "      ip address $ipfisica $mask" >> $TMP/6_vrrp_${file}.txt
					echo "      ip policy route-map SET_DSCP" >> $TMP/6_vrrp_${file}.txt
					echo "      ip tcp adjust-mss 1360" >> $TMP/6_vrrp_${file}.txt
					echo ";"  >> $TMP/6_vrrp_${file}.txt
					if [ $iface -gt 255 ]; then
                                               	tmpiface=`echo $iface | cut -c3`
						if [ $tmpiface = 0 ]; then
							tmpiface=$(($tmpiface + 19 ))
						fi
			        		echo "      ip vrrp $tmpiface ip $ip" >> $TMP/6_vrrp_${file}.txt
						echo "      ip vrrp $tmpiface priority 200" >> $TMP/6_vrrp_${file}.txt
						echo "      ip vrrp $tmpiface track interface ethernet0/1.1 prio-cost 80" >> $TMP/6_vrrp_${file}.txt
					else
			        		echo "      ip vrrp $iface ip $ip" >> $TMP/6_vrrp_${file}.txt
						echo "      ip vrrp $iface priority 200" >> $TMP/6_vrrp_${file}.txt
						echo "      ip vrrp $iface track interface ethernet0/1.1 prio-cost 80" >> $TMP/6_vrrp_${file}.txt
					fi
					echo ";" >> $TMP/6_vrrp_${file}.txt
					echo "      load-interval 30" >> $TMP/6_vrrp_${file}.txt
					echo "      encapsulation dot1q $iface" >> $TMP/6_vrrp_${file}.txt
  				        echo "      shutdown" >> $TMP/6_vrrp_${file}.txt
					echo ";" >> $TMP/6_vrrp_${file}.txt
					echo "      exit" >> $TMP/6_vrrp_${file}.txt
					echo ";" >> $TMP/6_vrrp_${file}.txt
				fi
			fi
		done < $TMP/${file}
	fi
	cat $MODEL/1_subinterfaces.txt > $CFG/teldat_cfg_${file}.txt
	cat $TMP/1_subinterfaces_${file}.txt >> $CFG/teldat_cfg_${file}.txt
	cat $TMP/1_loopback_${file}.txt >> $CFG/teldat_cfg_${file}.txt
	cat $MODEL/2.txt >> $CFG/teldat_cfg_${file}.txt
	cat $TMP/3_prefix_list100_${file}.txt >> $CFG/teldat_cfg_${file}.txt
	cat $MODEL/4.txt >> $CFG/teldat_cfg_${file}.txt
	cat $TMP/5_network_loopback_${file}.txt >> $CFG/teldat_cfg_${file}.txt
	cat $TMP/6_vrrp_${file}.txt >> $CFG/teldat_cfg_${file}.txt
	cat $MODEL/6_1.txt >> $CFG/teldat_cfg_${file}.txt
	cat $MODEL/7.txt >> $CFG/teldat_cfg_${file}.txt
	cat $TMP/7_1_dhcp_${file}.txt >> $CFG/teldat_cfg_${file}.txt
	cat $MODEL/7_2.txt >> $CFG/teldat_cfg_${file}.txt
	cat $TMP/8_bgp_${file}.txt >> $CFG/teldat_cfg_${file}.txt
	cat $MODEL/9.txt >> $CFG/teldat_cfg_${file}.txt
	cat $TMP/10_vlan_${file}.txt >> $CFG/teldat_cfg_${file}.txt
	cat $MODEL/11.txt >> $CFG/teldat_cfg_${file}.txt
	cat $CFG/teldat_cfg_${file}.txt | sed -e "s/\[OFICINA\]/$oficina/g" > $TMP/teldat_cfg_${file}.txt
	cat $TMP/teldat_cfg_${file}.txt | sed -e "s/\[DIRECCION\]/$dir/g" > $CFG/teldat_cfg_${file}.txt
	cat $CFG/teldat_cfg_${file}.txt | sed -e "s/\[DEPARTAMENTO\]/$dpto/g" > $TMP/teldat_cfg_${file}.txt
	cat $TMP/teldat_cfg_${file}.txt | sed -e "s/\[XYZ\]/$cid/g" > $CFG/teldat_cfg_${file}.txt

	#[IP_ADD_LOOPBACK10]
        ip_lo10=`cat $IN_FILE/${file} | grep -e "^lo" | grep "GESTION" | grep "teldat" | awk -F"," '{ print $5}'`
        cat $CFG/teldat_cfg_${file}.txt | sed -e "s/\[IP_ADD_LOOPBACK10\]/$ip_lo10/g" > $TMP/teldat_cfg_${file}.txt

	#[IP_ADD_LOOPBACK20]
        ip_lo20=`cat $IN_FILE/${file} | grep -e "^lo" | grep "MRA" | grep "teldat " | awk -F"," '{ print $5}'`
        cat $TMP/teldat_cfg_${file}.txt | sed -e "s/\[IP_ADD_LOOPBACK20\]/$ip_lo20/g" > $CFG/teldat_cfg_${file}.txt

	#[IP_ADD_LOOPBACK30]
        ip_lo30=`cat $IN_FILE/${file} | grep -e "^lo" | grep "GETVPN" | grep "teldat" | awk -F"," '{ print $5}'`
        cat $CFG/teldat_cfg_${file}.txt | sed -e "s/\[IP_ADD_LOOPBACK30\]/$ip_lo30/g" > $TMP/teldat_cfg_${file}.txt

	#[IP_ADD_LOOPBACK40]
        ip_lo40=`cat $IN_FILE/${file} | grep -e "^lo" | grep "DSLW_SNA" | grep "teldat" | awk -F"," '{ print $5}'`
        cat $TMP/teldat_cfg_${file}.txt | sed -e "s/\[IP_ADD_LOOPBACK40\]/$ip_lo40/g" > $CFG/teldat_cfg_${file}.txt

	#[VLAN_BVI]
        vlan200=`cat $IN_FILE/${file} | grep -e "^L2L3" | grep "200" | awk -F"," '{ print $2}'`
        cat $CFG/teldat_cfg_${file}.txt | sed -e "s/\[VLAN_BVI\]/$vlan200/g" > $TMP/teldat_cfg_${file}.txt
	
	#[RED_CCTV] [MASK_RED_CCTV]
        RED301=`cat $IN_FILE/${file} | grep -e "^L2L3" | grep "301" | awk -F"," '{ print $4}' | awk -F"/" '{ print $1}'`
        MK301=`cat $IN_FILE/${file} | grep -e "^L2L3" | grep "301" | awk -F"," '{ print $5}' | awk -F" " '{ print $2}'`
        cat $TMP/teldat_cfg_${file}.txt | sed -e "s/\[RED_CCTV\] \[MASK_RED_CCTV\]/$RED301 $MK301/g" > $CFG/teldat_cfg_${file}.txt

	#[RED_SNA] [MASK_RED_SNA]
        RED200=`cat $IN_FILE/${file} | grep -e "^L2L3" | grep "200" | awk -F"," '{ print $4}' | awk -F"/" '{ print $1}'`
        MK200=`cat $IN_FILE/${file} | grep -e "^L2L3" | grep "200" | awk -F"," '{ print $5}' | awk -F" " '{ print $2}'`
        cat $CFG/teldat_cfg_${file}.txt | sed -e "s/\[RED_SNA\] \[MASK_RED_SNA\]/$RED200 $MK200/g" > $TMP/teldat_cfg_${file}.txt

	#[RED_VOIP] [MASK_RED_VOIP]
        RED60=`cat $IN_FILE/${file} | grep -e "^L2L3" | grep "60" | awk -F"," '{ print $4}' | awk -F"/" '{ print $1}'`
        MK60=`cat $IN_FILE/${file} | grep -e "^L2L3" | grep "60" | awk -F"," '{ print $5}' | awk -F" " '{ print $2}'`
        cat $TMP/teldat_cfg_${file}.txt | sed -e "s/\[RED_VOIP\] \[MASK_RED_VOIP\]/$RED60 $MK60/g" > $CFG/teldat_cfg_${file}.txt

	#[IP_ADD_WAN_CPE] [MASK_WAN_CPE]
	IP_ADD_WAN_CPE=`cat $IN_FILE/${file} | grep -e "^ip_wan" | grep "teldat" | awk -F"," '{ print $5}'`
	if [ "$IP_ADD_WAN_CPE" != "" ]; then
	        cat $CFG/teldat_cfg_${file}.txt | sed -e "s/\[IP_ADD_WAN_CPE\] \[MASK_WAN_CPE\]/$IP_ADD_WAN_CPE 255.255.255.252/g" > $TMP/teldat_cfg_${file}.txt
	fi

	#[IP_ADD_PE_WAN]
	IP_ADD_PE_WAN=`cat $IN_FILE/${file} | grep -e "^ip_mod_peer" | grep "teldat" | awk -F"," '{ print $5}'`
	if [ "$IP_ADD_PE_WAN" != "" ]; then
	        cat $TMP/teldat_cfg_${file}.txt | sed -e "s/\[IP_ADD_PE_WAN\]/$IP_ADD_PE_WAN/g" > $TMP/teldat_cfg_${file}.txt.1
	fi

	#IP_ADD_SNA_CONTIGENCIA
        IP_ADD_SNA_CONTIGENCIA=`cat $IN_FILE/${file} | grep -e "^ip_fisica" | grep "cisco" | awk -F"," '{ print $5}'`
	if [ "$IP_ADD_SNA_CONTIGENCIA" != "" ]; then
	       cat $TMMP/teldat_cfg_${file}.txt.1 | sed -e "s/\[IP_ADD_SNA_CONTIGENCIA\]/$IP_ADD_SNA_CONTIGENCIA/g" > $CFG/teldat_cfg_${file}.txt
	fi

done < $TMP/list_files.txt
