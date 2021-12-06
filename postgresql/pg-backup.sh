#!/bin/bash 

# 편집필요: 사용 변수
PROFILE='/root/.profile'
PG_PORT=8282

# 변수
BAK_FILE_NM=_`date +"%Y%m%d"`.tar 
BAK_LOG_FILE_NM=0db_backup_`date +"%Y%m%d"`.log
BAK_FILE_SAVE_PATH=/root/db-backup/backup-files 
BAK_FILE_DIRECTORY=`date +"%Y%m%d"` 
WEEK_AGO=`date -d '1 week ago' +"%Y%m%d"`

source ${PROFILE}
mkdir ${BAK_FILE_SAVE_PATH}/${BAK_FILE_DIRECTORY}

for target in $(cat /root/db-backup/shell-script/backup-db-list.txt); 
do 
  PG_HOST=$(echo $target | cut -d ':' -f1)
  PG_PORT=$(echo $target | cut -d ':' -f2)
  DATABASE=$(echo $target | cut -d ':' -f3)
  PG_USER=$(echo $target | cut -d ':' -f4)
  
  echo `date +"%Y-%m-%d %H:%M:%S"`" @@@ "$backup_database" backup shell script start! @@@" >> ${BAK_FILE_SAVE_PATH}/${BAK_FILE_DIRECTORY}/${BAK_LOG_FILE_NM} 
  
  pg_dump -h ${PG_HOST} -p ${PG_PORT} -d ${DATABASE} -U ${PG_USER}-F t > ${BAK_FILE_SAVE_PATH}/${BAK_FILE_DIRECTORY}/${DATABASE}${BAK_FILE_NM} 2>&1 && echo `date +"%Y-%m-%d %H:%M:%S"`" @@@ "$backup_database" backup shell script end! @@@" >> ${BAK_FILE_SAVE_PATH}/${BAK_FILE_DIRECTORY}/${BAK_LOG_FILE_NM} 
  
  echo "" >> ${BAK_FILE_SAVE_PATH}/${BAK_FILE_DIRECTORY}/${BAK_LOG_FILE_NM} 
  
done 

rm -rf ${BAK_FILE_SAVE_PATH}/${WEEK_AGO}
