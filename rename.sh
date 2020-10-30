#!/bin/bash

ls ./backup > ./tmp/name.txt
while read name
do
	newname=`echo $name | sed -e 's/[(|)]//g' | sed -e 's/-/_/g' | sed -e 's/ //g'`
	echo "renombrando de $name -> $newname"
	mv "./backup/$name" "./backup/$newname"
done < ./tmp/name.txt
