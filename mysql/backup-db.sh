#!/bin/bash 

BAK_FILE_NM=_db_backup_`date +"%Y%m%d"`.sql 
BAK_LOG_FILE_NM=0db_backup_`date +"%Y%m%d"`.log
BAK_FILE_SAVE_PATH=/home/ubuntu/db-backup/backup-files 
BAK_FILE_DIRECTORY=`date +"%Y%m%d"` 
WEEK_AGO=`date -d '1 week ago' +"%Y%m%d"` 
MYSQL_HOST='localhost' MYSQL_USER='db계정명'
MYSQL_PASSWORD='db암호명' 

