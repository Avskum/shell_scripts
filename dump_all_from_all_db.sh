for x in `mysql --skip-column-names db_name -e 'show tables;'`; do
     mysqldump -u db_name $x > "$x.sql"
done
