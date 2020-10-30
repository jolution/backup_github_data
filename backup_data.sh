#!/bin/bash

#     _       _       _   _             
#    (_) ___ | |_   _| |_(_) ___  _ __  
#    | |/ _ \| | | | | __| |/ _ \| '_ \ 
#    | | (_) | | |_| | |_| | (_) | | | |
#   _/ |\___/|_|\__,_|\__|_|\___/|_| |_|
#  |__/                                 
#
# GitHub Backup Branches as zip
# v0.1

cd /backup/
if test -f "/backup/.env"
then
    eval "$(egrep -v '^#' .env | xargs)"

    if [ -z "$CUSTOMERLIST" ]
    then
        echo "No Customerlist found, exit"
        exit 1
    fi

else
    echo "/backup/.env doesnt exists, skip backup"
    exit 1
fi


function backup {

    cd /backup/customer/$CUSTOMER/

    if test -f "/backup/customer/$CUSTOMER/.env"
    then
        eval "$(egrep -v '^#' .env | xargs)"

        if [ -z "$TOKEN" ]
        then
            echo "No Github Token found, exit"
            exit 1
        fi

    else
        echo "/backup/customer/$CUSTOMER/.env doesnt exists, skip backup"
        exit 1
    fi

    # General settings
    FILE_PREFIX=`date +\%Y-\%m-\%d_\%H-\%M-\%S`

    BACKUP_DIR="/backup/customer/${CUSTOMER}/data"
    #Alternative way: like in backup_data.sh
    #BACKUP_DIR="/backup/customer/${CUSTOMER}/${PERIOD}/data/"

    BRANCHESLIST="master develop"
    # Alternative way: get all branches from github
    #BRANCHESLIST=$(curl -H "Authorization: token $TOKEN" https://api.github.com/repos/$OWNER/$CUSTOMER/branches | grep -Po '"name": "\K[A-Z0-9a-z-/.]*')

    # Use space as separator and apply as pattern
    for BRANCH in ${BRANCHESLIST// / }
    do
        # Generate Folder (if it doesnt exist)
        mkdir -p "${BACKUP_DIR}/${BRANCH}"

        #BRANCHLASTPUSH=$(curl -H "Authorization: token $TOKEN" https://api.github.com/repos/$OWNER/$CUSTOMER/commits/$BRANCH | grep -oE "[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}" | head -1)
        #BRANCHLASTBACKUP=$(stat --printf="%y" $BACKUP_DIR/$BRANCH | grep -oE "[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}")

        BRANCHLASTPUSH=$(curl -H "Authorization: token $TOKEN" https://api.github.com/repos/$OWNER/$CUSTOMER/commits/$BRANCH | grep -oE "([0-9]{4}-[0-9]{1,2}-[0-9]{1,2})T([0-9]{2}:[0-9]{2}:[0-9]{2})Z" | head -1)
        BRANCHLASTPUSHDATE=$(date -d $BRANCHLASTPUSH +"%Y-%m-%d_%H-%M-%S")

        FILE=$BACKUP_DIR/${BRANCH}/${BRANCHLASTPUSHDATE}_${BRANCH}.zip
        if test -f "$FILE"
        then
            echo "$FILE exists, skip backup"
        else
            #wget -L --header="Authorization: token $TOKEN" https://github.com/$OWNER/$CUSTOMER/archive/$BRANCH.zip -P $BACKUP_DIR
            wget -L --header="Authorization: token $TOKEN" https://github.com/$OWNER/$CUSTOMER/archive/$BRANCH.zip -O $BACKUP_DIR/${BRANCH}/${BRANCHLASTPUSHDATE}_${BRANCH}.zip;
        fi

        if ! test -z "$KEEPCOPYS"; then
            # Remove files if more than x files

            #COUNTFILES=$(ls $BACKUP_DIR/$BRANCH | wc -l)
            COUNTFILES=$(find $BACKUP_DIR/$BRANCH -type f | wc -l)
            # More Files than x ?
            if [ $COUNTFILES -gt $KEEPCOPYS ]
            then
                
                # TODO: Instead 4 set KEEPCOPYS VAR
                #find $BACKUP_DIR/$BRANCH -name "*.zip" -type f | sort -r | tail -n +$((KEEPCOPYS+1))
                FILES=$(find $BACKUP_DIR/$BRANCH -name "*.zip" -type f | sort -r | tail -n +4);
                for FILE in ${FILES}
                do
                    echo "Remove File: ${FILE}"
                    rm ${FILE}
                done
            fi

        fi
        #stat master | grep Modify
        #stat --printf="%y" master | grep -oE "[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}"

    done

}
 
# Use space as separator and apply as pattern
for CUSTOMER in ${CUSTOMERLIST// / }
do
   backup $CUSTOMER
done
