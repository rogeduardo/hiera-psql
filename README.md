[![Build Status](https://travis-ci.org/mcourtois/hiera-psql.png)](https://travis-ci.org/mcourtois/hiera-psql)

Database schema
===============

The database should contain a table 'config' with 3 text columns, path, key & value.
Path is equivalent to the path in the hierarchy (with no file extensions), key is the hiera key and
value should contain the value in JSON format.

Example:

| path                   | key                  | value                   |
|:-----------------------|:---------------------|:------------------------|
| 'fqdn/foo.example.com' | 'class::num_param'   | '42'
| 'fqdn/foo.example.com' | 'class::str_param'   | '"foobar"'
| 'fqdn/bar.example.com' | 'class::array_param' | '[1, 2, 3]'
| 'fqdn/baz.example.com' | 'class::hash_param'  | '{ "key1": "value1", "key2": 2 }'

SQL:

    CREATE DATABASE hiera WITH owner=hiera template=template0 encoding='utf8';
    CREATE TABLE config (path varchar, key varchar, value varchar, UNIQUE(path,key));

Configuration
=============

The backend configuration takes a connection hash that it sends directly to the connect method of the postgres library. See the [ruby-pg documentation](http://deveiate.org/code/pg/PG/Connection.html#method-c-new) for more info on parameters it accepts.

Here is a example hiera config file.

    ---
    :hierarchy:
      - 'fqdn/%{fqdn}'
      - common
    
    :backends:
      - psql
    
    :psql:
      :connection:
        :dbname: hiera
        :host: localhost
        :user: root
        :password: examplepassword
