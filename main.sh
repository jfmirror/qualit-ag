#!/bin/bash

#INPUT_FILE=Backup_Jose_Domingo_Choquehuanca.txt
FINAL_PATH="./final"
PATH_BACKUP="./backup"
PATH_TMP="./temp"
PATH_LIB="./lib"
PATH_LOG="./log"

#--flush diles
rm -rf $PATH_TMP/*
rm -rf $FINAL_PATH/*
rm -rf $PATH_LOG/*
rm -rf ./tmp/*

ls $PATH_BACKUP > $PATH_TMP/backup_files.txt

#format and rename files backup
rename(){
        while read file_name
        do
                cat $PATH_BACKUP/$file_name | sed -e 's/[[:cntrl:]]//g' | sed -e 's/--More--          //g' > $PATH_BACKUP/$file_name.tmp
		rm -rf $PATH_BACKUP/$file_name
		mv $PATH_BACKUP/${file_name}.tmp $PATH_BACKUP/$file_name 
                dos2unix $PATH_BACKUP/$file_name
		#tmphostname=`grep -e "^hostname" $PATH_BACKUP/$file_name | awk -F" " '{ print $2}'`
                #newhostname=`cat $PATH_BACKUP/$file_name | grep -e "^$tmphostname" | awk -F"#" '{ print $1 }' | head -n1`
		#if [ "$newhostname" != "" ]; then
	        #        echo "rename: $PATH_BACKUP/$file_name -> $PATH_BACKUP/$newhostname.txt" >> $PATH_LOG/mapping_rename.log
        	#        mv $PATH_BACKUP/$file_name $PATH_BACKUP/$newhostname.txt
		#fi

        done < $PATH_TMP/backup_files.txt
}

rename
echo "\n"

ls $PATH_BACKUP > $PATH_TMP/backup_files.txt

while read backup_file
do
	#echo "\nprocesando: $backup_file:\n"

	#get dhcp pool
	cat $PATH_BACKUP/${backup_file} | grep -e '^ip dhcp excluded-address ' | awk -F" " '{ print $4 }' > $PATH_TMP/${backup_file}.dhcp.excluded

	#validando si existen excluded address para continuar
	flag=`cat $PATH_TMP/${backup_file}.dhcp.excluded | head -n1`
	if [ "$flag" != "" ]; then
		#head
		echo "type,vlan,name,red,ip / mask,cidr,wildcard,device,oficina,departamento,direcion,cid,tmp" > $FINAL_PATH/${backup_file}.csv
		echo "name,network,defaultrouter,option150,dnsserver,excluded address" > $FINAL_PATH/${backup_file}_dhcp.csv
		cat $PATH_BACKUP/${backup_file} | grep -e '^ip dhcp pool' | awk -F" " '{ print $4 }' >> $PATH_TMP/${backup_file}.dhcp.pool
		sh $PATH_LIB/getdhcp.sh $PATH_BACKUP/${backup_file} $PATH_TMP/${backup_file}.dhcp.pool
			
	else
		echo "type,vlan,name,red,ip / mask,cidr,wildcard,device,oficina,departamento,direcion,cid,tmp" > $FINAL_PATH/${backup_file}.csv
	fi

	#get interfaces
	flag=`grep "^interface GigabitEthernet[0-9]/[0-9]" $PATH_BACKUP/${backup_file} | wc -l`
	#flag=`cat $PATH_TMP/${backup_file} | head -n1`

	if [ $flag -le 6 ]; then
		#process format 1 to excel
		echo "[$flag] process format 1 to excel"
		cat $PATH_BACKUP/${backup_file} | grep -e "^interface Vlan[2-9]*" | awk -F"Vlan" '{ print $2 }' > $PATH_TMP/${backup_file}
		cat $PATH_BACKUP/${backup_file} | grep -e "^interface BVI[0-9]$" | awk -F" " '{ print $2 }' >> $PATH_TMP/${backup_file}

		#get vlan
		sh $PATH_LIB/getvlan.sh $PATH_TMP/${backup_file} $PATH_BACKUP/$backup_file 1

	elif [ $flag -gt 6 ]; then
		#process format 2 to excel
		echo "[$flag] process format 2 to excel"
		cat $PATH_BACKUP/${backup_file} | grep -e "^interface GigabitEthernet[0|1]\/[0|1]\.[0-9]*$" | awk -F"." '{ print $2 }' >> $PATH_TMP/${backup_file}

		#get vlan
		sh $PATH_LIB/getvlan.sh $PATH_TMP/${backup_file} $PATH_BACKUP/$backup_file 2
	else
		echo "No se puede identificar ${backup_file}"
	fi
	echo "lo,10,GESTION,,,/32,0.0.0.0,cisco,,,,,ererer\nlo,20,MRA,,,/32,0.0.0.0,cisco,,,,,ererer\nlo,30,GETVPN,,,/32,0.0.0.0,cisco,,,,,ererer\nlo,40,DSLW_SNA,,,/32,0.0.0.0,cisco,,,,,ererer\nip_wan,,,,,,,cisco,,,,,ererer\nip_mod_peer,,PEER_GBP|IP_MODEM,,,,,cisco,,,,,ererer\nlo,40,DSLW_SNA,,,,,teldat,,,,,ererer" >> $FINAL_PATH/${backup_file}.csv
	if [ -f ./tmp/teldatipfisica.txt ]; then
		cat ./tmp/teldatipfisica.txt >> $FINAL_PATH/${backup_file}.csv
	fi
	echo "\n"

done < $PATH_TMP/backup_files.txt
