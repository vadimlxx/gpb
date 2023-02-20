-- сделано под MariaDB

SET NAMES utf8;

USE cc;

-- движок Aria т.к. это логи
CREATE TABLE `message` (
    `id` VARCHAR(255) PRIMARY KEY NOT NULL ,
    created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    int_id CHAR(16) COLLATE utf8_bin NOT NULL,
    str VARCHAR(1024),
    -- status TINYINT(1) NOT NULL, -- не используется
    KEY (created),
    KEY (int_id)
) ENGINE=Aria ROW_FORMAT=PAGE PAGE_CHECKSUM=1 TRANSACTIONAL=1 DEFAULT CHARACTER SET utf8;


CREATE TABLE `log` (
    int_id CHAR(16) COLLATE utf8_bin NOT NULL,
    created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    str VARCHAR(1024),
    address VARCHAR(255) DEFAULT '',
    -- без PRIMARY KEY
    KEY (created),
    KEY (address)
) ENGINE=Aria ROW_FORMAT=PAGE PAGE_CHECKSUM=1 TRANSACTIONAL=1 DEFAULT CHARACTER SET utf8;
