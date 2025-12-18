FROM mariadb
RUN apt-get update -y && apt-get upgrade -y

RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y \
	git \
	wget \
	gzip \
	bash \
	debianutils

RUN git clone https://github.com/cmangos/wotlk-db.git
RUN git clone https://github.com/cmangos/mangos-wotlk.git

# Try to download the Full DB archive expected by InstallFullDB.sh.
# First try the specific file; if it's not available, fall back to the releases
# tarball containing backups and extract into /wotlk-db/Full_DB.
RUN mkdir -p /wotlk-db/Full_DB \
 && wget -O /wotlk-db/Full_DB/WoTLKDB_1_9_14092.sql.gz https://github.com/cmangos/wotlk-db/raw/master/Full_DB/WoTLKDB_1_9_14092.sql.gz || \
	(wget -qO- https://github.com/cmangos/wotlk-db/releases/download/latest/wotlk-all-backups.tar.gz | tar -xz -C /wotlk-db/Full_DB --strip-components=0 || true)

ENV MYSQL_ROOT_PASSWORD mangos
ENV MYSQL_USER mangos
ENV MYSQL_PASSWORD mangos

RUN mkdir -p /cmangos/sql
ADD db_create_mysql.sql /cmangos/sql
RUN wget -O /cmangos/sql/characters.sql https://raw.githubusercontent.com/cmangos/mangos-wotlk/master/sql/base/characters.sql
RUN wget -O /cmangos/sql/mangos.sql https://raw.githubusercontent.com/cmangos/mangos-wotlk/master/sql/base/mangos.sql
RUN wget -O /cmangos/sql/realmd.sql https://raw.githubusercontent.com/cmangos/mangos-wotlk/master/sql/base/realmd.sql
#ADD https://github.com/cmangos/wotlk-db/raw/master/Full_DB/WoTLKDB_1_3_14015.sql.gz /cmangos/sql/. 
#RUN gunzip /cmangos/sql/WoTLKDB_1_3_14015.sql.gz && chmod 777 /cmangos/sql/WoTLKDB_1_3_14015.sql

#COPY mangos-wotlk/sql/base/dbc/cmangos_fixes /cmangos/base/dbc/cmangos_fixes
#COPY mangos-wotlk/sql/base/dbc/original_data /cmangos/base/dbc/original_data
#COPY mangos-wotlk/sql/updates /cmangos/sql/updates

ADD InstallFullDB.config /wotlk-db/InstallFullDB.config
RUN chmod -R 777 /wotlk-db/

ADD sqlstart.sh /docker-entrypoint-initdb.d
RUN chmod +x /docker-entrypoint-initdb.d/sqlstart.sh || true
RUN if [ -f /wotlk-db/InstallFullDB.sh ]; then chmod +x /wotlk-db/InstallFullDB.sh || true; fi

VOLUME /var/lib/mysql

ADD my.cnf /etc/mysql/

EXPOSE 3306
CMD ["mariadbd", "--max-allowed-packet=32505856"]
