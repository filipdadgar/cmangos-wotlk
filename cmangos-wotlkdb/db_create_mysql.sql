CREATE DATABASE IF NOT EXISTS wotlkrealmd DEFAULT CHARSET utf8 COLLATE utf8_general_ci;
CREATE DATABASE IF NOT EXISTS wotlkcharacters DEFAULT CHARSET utf8 COLLATE utf8_general_ci;
CREATE DATABASE IF NOT EXISTS wotlkmangos DEFAULT CHARSET utf8 COLLATE utf8_general_ci;
CREATE DATABASE IF NOT EXISTS logs DEFAULT CHARSET utf8 COLLATE utf8_general_ci;

-- User is created by Docker ENV, but we ensure permissions here
-- Using IF NOT EXISTS to avoid errors if already created
CREATE USER IF NOT EXISTS 'mangos'@'%' IDENTIFIED BY 'mangos';
ALTER USER 'mangos'@'%' IDENTIFIED BY 'mangos';

CREATE USER IF NOT EXISTS 'mangos'@'localhost' IDENTIFIED BY 'mangos';
ALTER USER 'mangos'@'localhost' IDENTIFIED BY 'mangos';

GRANT ALL PRIVILEGES ON wotlkrealmd.* TO 'mangos'@'%';
GRANT ALL PRIVILEGES ON wotlkcharacters.* TO 'mangos'@'%';
GRANT ALL PRIVILEGES ON wotlkmangos.* TO 'mangos'@'%';
GRANT ALL PRIVILEGES ON logs.* TO 'mangos'@'%';

GRANT ALL PRIVILEGES ON wotlkrealmd.* TO 'mangos'@'localhost';
GRANT ALL PRIVILEGES ON wotlkcharacters.* TO 'mangos'@'localhost';
GRANT ALL PRIVILEGES ON wotlkmangos.* TO 'mangos'@'localhost';
GRANT ALL PRIVILEGES ON logs.* TO 'mangos'@'localhost';

FLUSH PRIVILEGES;
