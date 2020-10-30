#!/bin/bash

IN_FILE="./final"
TMP="./tmp"
MODEL="./model/teldat"
CFG="./cfg"

i=0

rm -rf $TMP/*

ls $IN_FILE/*[^dhcp].csv > $TMP/list_files.txt

while read linea
do
        file=`echo $linea | awk -F"/" '{ print $3 }'`
        #dos2unix $IN_FILE/$file

        if [ -f $IN_FILE/${file} ]; then
                cat $IN_FILE/${file} | sed -e '/^type/d' > $TMP/${file}
                while read linea
		do
                        tipo=`echo $linea | awk -F"," '{ print $1}'`
                        iface=`echo $linea | awk -F"," '{ print $2}'`
                        name=`echo $linea | awk -F"," '{ print $3}'`
                        redbgp=`echo $linea | awk -F"," '{ print $4}'`
                        red=`echo $linea | awk -F"," '{ print $4}' | awk -F/ '{ print $1} '`
                        ip=`echo $linea | awk -F"," '{ print $5}' | awk -F" " '{ print $1 }'`
                        mask=`echo $linea | awk -F"," '{ print $5}' | awk -F" " '{ print $2 }'`
                        ipmask=`echo $linea | awk -F"," '{ print $5}'`
                        cidr=`echo $linea | awk -F"," '{ print $6}'`
                        wildcard=`echo $linea | awk -F"," '{ print $7}'`
                        device=`echo $linea | awk -F"," '{ print $11}'`
                        oficina=`echo $linea | awk -F"," '{ print $12}'`
                        dpto=`echo $linea | awk -F"," '{ print $13}'`
                        dir=`echo $linea | awk -F"," '{ print $14}'`
                        cid=`echo $linea | awk -F"," '{ print $15}'`

                        #vrrp
                        ipvirtual=`echo $ipmask | awk -F" " '{ print $1 }'`
                        ipiface=`echo $ipmask | awk -F" " '{ print $1 }'`
                        maskiface=`echo $ipmask | awk -F" " '{ print $2 }'`
                        octetos=`echo $ipiface | awk -F. '{ print $1"."$2"."$3"." }'`
                        octeto4=`echo $ipiface | awk -F. '{ print $4 }'`

			i=$(($i + 1))
			if [ "$iface" != "" ]; then
				echo "        vlan $iface ethernet0/0 port 1" >> $TMP/16_vlan_${file}_teldat.txt
				echo "        vlan $iface ethernet0/0 port 2" >> $TMP/16_vlan_${file}_teldat.txt
				echo "        vlan $iface ethernet0/0 port internal" >> $TMP/16_vlan_${file}_teldat.txt
				echo "        !" >> $TMP/16_vlan_${file}_teldat.txt
			fi

			#interfaces
			if [ "$tipo" == "L3" ] || [ "$tipo" == "L2L3" ]; then
				#BVI 0
				if [ "$iface" == "200" ]; then

		                        #vrrp
		                        ipvirtual=`echo $ipmask | awk -F" " '{ print $1 }'`
                		        ipiface=`echo $ipmask | awk -F" " '{ print $1 }'`
		                        maskiface=`echo $ipmask | awk -F" " '{ print $2 }'`
                		        octetos=`echo $ipiface | awk -F. '{ print $1"."$2"."$3"." }'`
		                        octeto4=`echo $ipiface | awk -F. '{ print $4 }'`

                		        if [ "$iface" = "60" ]; then
                                		octeto4=$(($octeto4 + 1))
		                                ipmask=`echo ${octetos}${octeto4} $maskiface`

                		        elif [ "$iface" != "60" ] && [ "$iface" != "" ]; then
        	                        	octeto4=$(($octeto4 - 2))
	        	                        ipmask=`echo ${octetos}${octeto4} $maskiface`
                        		fi
	                                
					echo "   add device bvi 0" >> $TMP/interfaces_${file}_teldat.txt
					echo -e "\n   network bvi0" >> $TMP/network_${file}_teldat.txt
					echo "; -- Bridge Virtual Interface configuration --" >> $TMP/network_${file}_teldat.txt
					echo "      description \"BRIDGE-SNA-USUARIOS\"" >> $TMP/network_${file}_teldat.txt
					echo ";" >> $TMP/network_${file}_teldat.txt
					echo "      ip address $ipmask " >> $TMP/network_${file}_teldat.txt
					echo "      ip policy route-map SET_DSCP" >> $TMP/network_${file}_teldat.txt
					echo "      ip tcp adjust-mss 1360" >> $TMP/network_${file}_teldat.txt
					echo ";" >> $TMP/network_${file}_teldat.txt
					echo "      ip vrrp $iface ip $ipvirtual" >> $TMP/network_${file}_teldat.txt
					echo "      ip vrrp $iface priority 200" >> $TMP/network_${file}_teldat.txt
					echo ";" >> $TMP/network_${file}_teldat.txt
					echo "      load-interval 30" >> $TMP/network_${file}_teldat.txt
					echo "      shutdown" >> $TMP/network_${file}_teldat.txt
					echo ";" >> $TMP/network_${file}_teldat.txt
					echo "   exit" >> $TMP/network_${file}_teldat.txt
					echo ";" >> $TMP/network_${file}_teldat.txt

					echo "   network ethernet0/0.$iface" >> $TMP/network_${file}_teldat.txt
					echo "; -- Ethernet Subinterface Configuration --" >> $TMP/network_${file}_teldat.txt
					echo "      description \"$name\"" >> $TMP/network_${file}_teldat.txt
					echo ";" >> $TMP/network_${file}_teldat.txt
					echo "      ip policy route-map SET_DSCP" >> $TMP/network_${file}_teldat.txt
					echo "      ip tcp adjust-mss 1360" >> $TMP/network_${file}_teldat.txt
					echo ";" >> $TMP/network_${file}_teldat.txt
					echo "      load-interval 30" >> $TMP/network_${file}_teldat.txt
					echo "      encapsulation dot1q $iface" >> $TMP/network_${file}_teldat.txt
					echo "      shutdown" >> $TMP/network_${file}_teldat.txt
					echo ";" >> $TMP/network_${file}_teldat.txt
					echo "   exit" >> $TMP/network_${file}_teldat.txt
					echo ";" >> $TMP/network_${file}_teldat.txt

					echo "      no vlan-bridging" >> $TMP/7_network_${file}_teldat.txt
					echo "      port ethernet0/0.$iface 1" >> $TMP/7_network_${file}_teldat.txt
					echo "      dls"  >> $TMP/network_${file}_teldat.txt
					echo "      protocol-filter dsap 4 1" >> $TMP/7_network_${file}_teldat.txt
					echo "      protocol-filter dsap 8 1" >> $TMP/7_network_${file}_teldat.txt
					echo "      protocol-filter dsap c 1" >> $TMP/7_network_${file}_teldat.txt
					echo "      no stp" >> $TMP/7_network_${file}_teldat.txt
					echo "	    route-protocol ip" >> $TMP/7_network_${file}_teldat.txt
					echo "   exit" >> $TMP/7_network_${file}_teldat.txt
					echo ";" >> $TMP/7_network_${file}_teldat.txt
					echo ";" >> $TMP/7_network_${file}_teldat.txt

					echo ";" >> $TMP/8_${file}_teldat.txt
					echo "     open-sap ethernet0/0.$iface 0" >> $TMP/8_${file}_teldat.txt
					echo "     open-sap ethernet0/0.$iface 4" >> $TMP/8_${file}_teldat.txt
					echo "     open-sap ethernet0/0.$iface 8" >> $TMP/8_${file}_teldat.txt
					echo "     open-sap ethernet0/0.$iface c" >> $TMP/8_${file}_teldat.txt
					echo ";" >> $TMP/8_${file}_teldat.txt
					echo ";" >> $TMP/8_${file}_teldat.txt

					echo "         [$iface] export as 12252 prot direct $red mask $mask exact restric" >> $TMP/bgp_${file}_teldat.txt

				else
					
					echo "   network ethernet0/0.${iface}" >> $TMP/network_${file}_teldat.txt
	                                if [ $iface -gt 255 ]; then
                                                tmpiface=`echo $iface | cut -c3`
                                        fi
					echo "; -- Ethernet Subinterface Configuration --" >> $TMP/network_${file}_teldat.txt
					echo "      description \"$name\"" >> $TMP/network_${file}_teldat.txt
					echo ";" >> $TMP/network_${file}_teldat.txt
					echo "      ip address $ipmask" >> $TMP/network_${file}_teldat.txt
					echo "      ip policy route-map SET_DSCP" >> $TMP/network_${file}_teldat.txt
					echo "      ip tcp adjust-mss 1360" >> $TMP/network_${file}_teldat.txt
					echo ";" >> $TMP/network_${file}_teldat.txt
					echo "      ip vrrp $tmpiface ip $ip" >> $TMP/network_${file}_teldat.txt
					echo "      ip vrrp $tmpiface priority 200" >> $TMP/network_${file}_teldat.txt
					echo "      ip vrrp $tmpiface track interface ethernet0/1.1 prio-cost 80" >> $TMP/network_${file}_teldat.txt
					echo ";" >> $TMP/network_${file}_teldat.txt
					echo "      load-interval 30" >> $TMP/network_${file}_teldat.txt
					echo "      encapsulation dot1q $iface" >> $TMP/network_${file}_teldat.txt
					echo "      shutdown" >> $TMP/network_${file}_teldat.txt
					echo ";" >> $TMP/network_${file}_teldat.txt
					echo "   exit" >> $TMP/network_${file}_teldat.txt
					echo ";" >> $TMP/network_${file}_teldat.txt
					
					echo "vlan $iface"
					echo "   add device eth-subinterface ethernet0/0 $iface" >> $TMP/interfaces_${file}_teldat.txt
					echo "   entry $i default" >> $TMP/acl100_${file}_teldat.txt
					echo "   entry $i permit" >> $TMP/acl100_${file}_teldat.txt
					echo "   entry $i prefix" $red $mask  >> $TMP/acl100_${file}_teldat.txt
					echo "   ;" >> $TMP/acl100_${file}_teldat.txt
					
					echo "         [$iface] export as 12252 prot direct $red mask $mask exact" >> $TMP/bgp_${file}_teldat.txt
				fi

			elif [ "$tipo" == "lo10" ] || [ "$tipo" == "lo20" ] || [ "$tipo" == "lo30" ] || [ "$tipo" == "lo40" ]; then
				echo "vlan $iface"
				ifaceloop=`echo $tipo | awk -Fo '{ print $2 }'`
				echo "   add device loopback $ifaceloop" >> $TMP/${file}_teldat.txt
				echo "   entry $i default" >> $TMP/acl100_${file}_teldat.txt
				echo "   entry $i permit" >> $TMP/acl100_${file}_teldat.txt
				echo "   entry $i prefix" $ip 255.255.255.255 >> $TMP/acl100_${file}_teldat.txt
				echo "   ;" >> $TMP/acl100_${file}_teldat.txt

				echo "network loopback${ifaceloop}" >> $TMP/network_${file}_teldat.txt
				echo "; -- Loopback interface configuration --" >> $TMP/network_${file}_teldat.txt
				echo "     description "Loopback $name"" >> $TMP/network_${file}_teldat.txt
				echo ";" >> $TMP/network_${file}_teldat.txt
				echo "     ip address $ip 255.255.255.255" >> $TMP/network_${file}_teldat.txt
				echo ";" >> $TMP/network_${file}_teldat.txt
				echo "      exit" >> $TMP/network_${file}_teldat.txt
				echo ";" >> $TMP/network_${file}_teldat.txt

				echo "        [$iface] export as 12252 prot direct host $ip" >> $TMP/bgp_${file}_teldat.txt
				if [ "$tipo" == "lo40" ]; then
					echo "       [$iface] export as 12252 prot direct host $ip restric" >> $TMP/bgp_${file}_teldat.txt
					cat $MODEL/15_ntp.txt | sed -e "s/\[IP_ADD_LOOPBACK40\]/$ip/g" > $TMP/15_ntp_${file}_teldat.txt 
				fi

			elif [ "$tipo" == "ip_peer" ]; then
				cat "$MODEL/12_bg_peer.txt" | sed -e "s/\[IP_ADD_PE_WAN\]/$ip/g" >> $TMP/bgp_peer_${file}_teldat.txt
			fi
		done < $TMP/${file}
	fi
cat $MODEL/1_interfaces.txt > $CFG/teldat_cfg_${file}.txt
cat $TMP/interfaces_${file}_teldat.txt >> $CFG/teldat_cfg_${file}.txt
cat $MODEL/2.txt >> $CFG/teldat_cfg_${file}.txt
cat $TMP/acl100_${file}_teldat.txt >> $CFG/teldat_cfg_${file}.txt
cat $MODEL/3.txt >> $CFG/teldat_cfg_${file}.txt
cat $TMP/network_${file}_teldat.txt >> $CFG/teldat_cfg_${file}.txt
cat $MODEL/5.txt >> $CFG/teldat_cfg_${file}.txt
cat $MODEL/6.txt >> $CFG/teldat_cfg_${file}.txt
cat $TMP/7_network_${file}_teldat.txt >> $CFG/teldat_cfg_${file}.txt
cat $TMP/8_${file}_teldat.txt >> $CFG/teldat_cfg_${file}.txt
cat $MODEL/9.txt >> $CFG/teldat_cfg_${file}.txt
cat $TMP/bgp_${file}_teldat.txt >> $CFG/teldat_cfg_${file}.txt
cat $MODEL/11.txt >> $CFG/teldat_cfg_${file}.txt
cat $TMP/bgp_peer_${file}_teldat.txt >> $CFG/teldat_cfg_${file}.txt
cat $TMP/15_ntp_${file}_teldat.txt >> $CFG/teldat_cfg_${file}.txt
cat $TMP/16_vlan_${file}_teldat.txt >> $CFG/teldat_cfg_${file}.txt
cat $MODEL/17.txt >> $CFG/teldat_cfg_${file}.txt
done < $TMP/list_files.txt

