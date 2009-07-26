DROP TABLE datalog;
CREATE TABLE datalog (
    name varchar(256),
    datakey varchar(256),
    value varchar(256),
    logged_at timestamp,
    source varchar(256)
);

DROP TABLE datatypes;
CREATE TABLE datatypes (
    name varchar(256),
    datakey varchar(256),
    datatype char(16),
    primary key (name, datakey)
);

DROP TABLE metadata;
CREATE TABLE metadata (
    datakey char(16),
    value varchar(256),
    primary key(datakey)
);

INSERT INTO metadata VALUES ('max_id', '0');
INSERT INTO metadata VALUES ('last_boot', '1970-01-01 00:00:00');
