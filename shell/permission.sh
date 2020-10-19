#!/bin/bash
. Setup/servers.properties

SOURCE_SERVER=$SOURCE_SERVER
DESTINATION_SERVER=$DESTINATION_SERVER
PASSWORD=`cat .secret.lck | openssl enc -base64 -d -aes-256-cbc -nosalt -pass pass:garbageKey`


changePermission(){
	if [ ! -n "$PERMISSION" ]
	then
		echo "NO PERMISSION for" $SOURCE_PATH
	else
		echo "SET PERMISSION" $PERMISSION "for" $SOURCE_PATH 
		printf  "\n"
		echo $PASSWORD | sudo -S -k chmod -R $PERMISSION /$DESTINATION_PATH/$SOURCE_PATH 
		printf  "\n"
	fi
}

changeOwner(){
	if [ ! -n "$OWNERSHIP" ]
	then
		echo "NO OWNERSHIP for" $SOURCE_PATH 
		printf  "\n"
	else 
		if [ ! -n "$GROUP" ]
		then
			echo "SET OWNERSHIP" $OWNERSHIP "for" $SOURCE_PATH 
			printf  "\n"
		else
			echo "SET OWNERSHIP" $OWNERSHIP "and group" $GROUP "for" $SOURCE_PATH 
			printf  "\n"
		fi
		echo  $PASSWORD | sudo -S -k  chown -R $OWNERSHIP:$GROUP /$DESTINATION_PATH/$SOURCE_PATH 
		printf  "\n"
	fi
}

changePermissionOwners(){
    var1=$1
    cd /
    cd $filepath
    
    if [ $var1 == 'file' ]
    then
        INPUT=$INPUT_FILE
    fi

    if [ $var1 == 'folder' ]
    then
        INPUT=$INPUT_FOLDER
    fi

    OLDIFS=$IFS
    IFS=','
    [ ! -f $INPUT ] && { echo "$INPUT file not found"; exit 99; }
    while read SOURCE_PATH DESTINATION_PATH PERMISSION OWNERSHIP GROUP
    do
        changePermission "$SOURCE_PATH" "$DESTINATION_PATH" "$PERMISSION"
	    changeOwner "$SOURCE_PATH" "$DESTINATION_PATH" "$OWNERSHIP" "$GROUP"
		echo "########"
	done < $INPUT
	IFS=$OLDIFS
}
	

filepath=`pwd`

cd Setup
INPUT_FILE=Setup/fileLocation.csv
INPUT_FOLDER=Setup/folderLocation.csv
changePermissionOwners folder
changePermissionOwners file



