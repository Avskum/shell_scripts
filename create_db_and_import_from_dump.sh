for i in $(ls -1 /home/backupSQL/b/2021-11-09-00-15/ | cut -d"." -f-1); do echo "Doing $i.sql" ; mysql -e "create database $i"; sleep 1; mysql $i < /home/backupSQL/b/2021-11-09-00-15/$i.sql ;done
