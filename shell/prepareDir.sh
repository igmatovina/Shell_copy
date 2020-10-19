#!/bin/bash
. Setup/servers.properties

SOURCE_SERVER=$SOURCE_SERVER
DESTINATION_SERVER=$DESTINATION_SERVER
PASSWORD=`cat .secret.lck | openssl enc -base64 -d -aes-256-cbc -nosalt -pass pass:garbageKey`

correctSymlinks(){	
	cd /
    cd /$DESTINATION_PATH/$SOURCE_PATH
	find . -type l | while read l; do
    cd /$DESTINATION_PATH/$SOURCE_PATH
    name=$(basename "$l")
    target=$(readlink "$l")
    location=$(dirname "$l")
    rm $l
    cd $location
    ln -s /$DESTINATION_PATH$target $name
	done
}

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

copyStructure(){
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
        if [ $var1 == 'folder' ]
        then
	        echo "creating directory" /$DESTINATION_PATH/$SOURCE_PATH
	        cd /
			if [ ! -d /$DESTINATION_PATH ]
			then
				mkdir -p /$DESTINATION_PATH
			fi
            mkdir -p /$DESTINATION_PATH/$SOURCE_PATH 
            ssh $USER@$SOURCE_SERVER << EOF
            cd /
	        find $SOURCE_PATH/ \( -type l -o -type d \)  -printf "%P\0" |rsync --files-from - --from0 -av $SOURCE_PATH $USER@$DESTINATION_SERVER:/$DESTINATION_PATH/$SOURCE_PATH
EOF
	        correctSymlinks "$DESTINATION_PATH" "$SOURCE_PATH"
	    fi

        if [ $var1 == 'file' ]
        then
            
            ssh $USER@$SOURCE_SERVER << EOF
	        cd /
	        find /$SOURCE_PATH -printf "%P\0" |rsync --files-from - --from0 -avr /$SOURCE_PATH $USER@$DESTINATION_SERVER:/$DESTINATION_PATH/$SOURCE_PATH
EOF
        fi                     
        
        changePermission "$SOURCE_PATH" "$DESTINATION_PATH" "$PERMISSION"
	    changeOwner "$SOURCE_PATH" "$DESTINATION_PATH" "$OWNERSHIP" "$GROUP"
    
done < $INPUT
IFS=$OLDIFS
}

filepath=`pwd`
USER=`whoami`

cd Setup
dos2unix *csv

INPUT_FILE=Setup/fileLocation.csv
INPUT_FOLDER=Setup/folderLocation.csv

copyStructure folder
copyStructure file

