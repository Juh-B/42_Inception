FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    mariadb-server \
    && rm -rf /var/lib/apt/lists/*

# Pre-create runtime AND log directories with correct ownership
RUN mkdir -p /run/mysqld /var/lib/mysql /var/log/mysql \
    && chown -R mysql:mysql /run/mysqld /var/lib/mysql /var/log/mysql

COPY conf/my.conf /etc/mysql/mariadb.conf.d/60-inception.cnf
COPY tools/init_db.sh /usr/local/bin/init_db.sh
RUN chmod +x /usr/local/bin/init_db.sh

EXPOSE ${MARIADB_INTERNAL_PORT}

ENTRYPOINT ["/usr/local/bin/init_db.sh"]
CMD ["mysqld", "--user=mysql"]
