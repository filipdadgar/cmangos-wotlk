CREATE DATABASE IF NOT EXISTS wotlkrealmd DEFAULT CHARSET utf8 COLLATE utf8_general_ci;
CREATE DATABASE IF NOT EXISTS wotlkcharacters DEFAULT CHARSET utf8 COLLATE utf8_general_ci;
CREATE DATABASE IF NOT EXISTS wotlkmangos DEFAULT CHARSET utf8 COLLATE utf8_general_ci;
CREATE DATABASE IF NOT EXISTS logs DEFAULT CHARSET utf8 COLLATE utf8_general_ci;
create user 'mangos'@'localhost' identified by 'mangos';
SET PASSWORD FOR 'mangos'@'localhost' = PASSWORD('mangos');
GRANT ALL PRIVILEGES ON *.* TO 'mangos'@'%' IDENTIFIED BY 'mangos';
flush privileges;
grant all on wotlkrealmd.* to mangos@'%' with grant option;
grant all on wotlkcharacters.* to mangos@'%' with grant option;
grant all on wotlkmangos.* to mangos@'%' with grant option;
grant all on logs.* to mangos@'%' with grant option;