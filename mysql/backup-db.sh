#!/bin/bash 

# 편집후 사용 변수
PROFILE= /home/ubuntu/.profile
MYSQL_HOST='localhost' 
MYSQL_USER='db계정명'
MYSQL_PASSWORD='db암호명'

# 변수
BAK_FILE_NM=_db_backup_`date +"%Y%m%d"`.sql 
BAK_LOG_FILE_NM=0db_backup_`date +"%Y%m%d"`.log
BAK_FILE_SAVE_PATH=/home/ubuntu/db-backup/backup-files 
BAK_FILE_DIRECTORY=`date +"%Y%m%d"` 
WEEK_AGO=`date -d '1 week ago' +"%Y%m%d"` 

source ${PROFILE}
mkdir ${BAK_FILE_SAVE_PATH}/${BAK_FILE_DIRECTORY}
for backup_database in $(cat /home/ubuntu/db-backup/shell-script/backup-db-list.txt); 
do 

  echo `date +"%Y-%m-%d %H:%M:%S"`" @@@ "$backup_database" backup shell script start! @@@" >> ${BAK_FILE_SAVE_PATH}/${BAK_FILE_DIRECTORY}/${BAK_LOG_FILE_NM} 
  
  mysqldump --single-transaction --databases $backup_database -h ${MYSQL_HOST} -u ${MYSQL_USER} -p${MYSQL_PASSWORD} > ${BAK_FILE_SAVE_PATH}/${BAK_FILE_DIRECTORY}/$backup_database${BAK_FILE_NM} 2>&1 && 
  echo `date +"%Y-%m-%d %H:%M:%S"`" @@@ "$backup_database" backup shell script end! @@@" >> ${BAK_FILE_SAVE_PATH}/${BAK_FILE_DIRECTORY}/${BAK_LOG_FILE_NM} 
  
  echo "" >> ${BAK_FILE_SAVE_PATH}/${BAK_FILE_DIRECTORY}/${BAK_LOG_FILE_NM} 
  
done 

rm -rf $BAK_FILE_SAVE_PATH/$WEEK_AGO
