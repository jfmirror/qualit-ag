#!/bin/bash
backup="/mnt/e/DATA/OPENMIRROR/BRAIN/jespejo/propuestas/Qualit/BN/backup"
script_backup="/home/jespejo/qualit/BN/main/backup"
while read file
do
	name=`echo $file | awk -F, '{ print $1}'`
	dato=`echo $file | awk -F, '{ print $2}'`
	
	file=`grep "$dato" $backup/* | awk -F: '{ print $1 }' | head -n1`

	cp "$file" "$script_backup/$name"
done < ./backup.files
