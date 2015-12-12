    CREATE TABLE  sessions (
        id           CHAR(40) PRIMARY KEY not null
      , session_data TEXT
      --, last_active timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    );
