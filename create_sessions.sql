CREATE TABLE `sessions` (
    `id`           CHAR(40) PRIMARY KEY
  , `session_data` TEXT
  , `last_active` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
