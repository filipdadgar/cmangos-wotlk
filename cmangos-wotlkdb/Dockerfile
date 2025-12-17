FROM mariadb
RUN apt-get update -y && apt-get upgrade -y

RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y \
	git \
	wget \
	gzip \
	bash

RUN git clone https://github.com/cmangos/wotlk-db.git
RUN git clone https://github.com/cmangos/mangos-wotlk.git

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

VOLUME /var/lib/mysql

ADD my.cnf /etc/mysql/

EXPOSE 3306
CMD ["mariadbd", "--max-allowed-packet=32505856"]
