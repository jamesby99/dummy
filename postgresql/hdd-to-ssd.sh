cp -r /postgresql/* /postgresql2
chown -R postgres:postgres /postgresql2
sed -i.bak -r "s/random_page_cost = 4/random_page_cost = 1.1/g" /etc/postgresql/11/main/postgresql.conf
sed -i.bak -r "s/effective_io_concurrency = 2/effective_io_concurrency = 200/g" /etc/postgresql/11/main/postgresql.conf
