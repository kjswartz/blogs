# Database Server Setup
## Table of Contents
- [Postgresql](#postgresql)
	- [Installation](#pg-installation)

	- [User and DB Setup](#user-and-database-creation)
	
	- [Testing Connectivity](#pg-connectivity)

- [Redis](#redis)
	- [Installation](#redis-installation)

	- [Commands](#redis-commands)
	
	- [Testing Connectivity](#redis-connectivity)


## [Postgresql](https://www.postgresql.org/download/linux/redhat/)

### PG Installation 
To install `postgres` use the following command. Installing `postgresql-contrib` will give use access to some additional utilities such as `hstore`.
```
$ sudo yum install postgresql-server postgresql-contrib
```
If you want to install a particular distribution you can get a list of available postgresql distributions by typing the following:
```
$ yum list postgresql*
```
And then you can select the distribution you want to install:
```
$ yum install postgresql-9.2.15-1.el7_2.x86_64
```
Due to policies for Red Hat family distributions, the PostgreSQL installation will not be enabled for automatic start or have the database initialized automatically. 
To make your database installation complete, you need to perform these two steps:
```
$ service postgresql initdb
$ chkconfig postgresql on
```

[back to top](#table-of-contents)

### User and Database Creation
A user (`postgres`) is created by default during installation. The below command will log into user postgres. You're shell prompt should change to something like `-bash-4.2$` after connecting.
```
$ sudo -i -u postgres
```
If you are prompted for a password, this will be your normal user password. You will be given a shell prompt for the postgres user. 
We can then create a different user for our database. This will ask you the name of the role and whether they should be a superuser. 
NOTE User needs to be a `SUPERUSER` in order to run schema migration if utilizing `hstore` extension. You can type `$ man createuser` to get the official documentation. 
```
$ createuser --<user_name>
```
Then you can set a password for the new user with:
```
$ \password <user> <password>
```
Create your database:
```
$ createdb <database_name>
```
You can then enter a postgres shell prompt by typing `$ psql`. You should now see `postgres=#` as your initial prompt.
From here you can type `\l` to get a list of databases to check that your created database is there and verify the owner. 

To change owners of a database: [Postgres ALTER ROLER docs](https://www.postgresql.org/docs/9.0/static/sql-alterrole.html)
```
postgres=# ALTER DATABASE <name> OWNER TO <user>;
```
If you want to alter a user role follow the below syntax:
```
postgres=# ALTER ROLE <user> WITH <option>;
```
We'll want to allow the user we created earlier the ability to login: 
```
postgres=# ALTER ROLE <user> WITH LOGIN;
```

[back to top](#table-of-contents)

### PG Connectivity
Since we are using two different servers to host our web code and database, we'll need to make sure we can access our database from our `webserver`. 
- NOTE: If you have a firewall setup you'll need to configure it to allow access from your webserver on port `5432`.  

- NOTE you may need to `yum install postgresql` on your webserver to use psql in order to test your connection via the command line.

```
$ psql -h <host-ip> -p <port> -U <user> -W <database_name> 
```
You will then be prompted for the user password and if successful you'll prompt should change to the `database_name=>`. 
You can use `\l` to list databases, `\dt` to see a list of the tables in your database and `\q` to quit.

[back to top](#table-of-contents)

## [Redis](https://redis.io/topics/quickstart)
Redis will be utilized as our caching solution. A client connects to a Redis server creating a TCP connection to the port 6379. 

### Redis Installation 
As `root` user or user with sudo privilages:
```
$ sudo yum install redis
```
Since we are setting up separate servers for our database of web files will need to modify the `redis.conf` configuration file. 
```
$ vim /etc/redis.conf
```
Then you'll need to change the `bind 127.0.0.1` to `bind 0.0.0.0` in order to connect from outside server.

[back to top](#table-of-contents)

### Redis Commands
You can use the service command to start, stop, and check the status of redis.
- Start
```
$ service redis start
```
- Stop
```
$ service redis stop
```
- Check Status
```
$ service redis status
```

[back to top](#table-of-contents)

### Redis Connectivity 
You will need to be able to access your server on port 6379. You can check to see if it is configured the below command. Then check to see if port 6379 is listed. 
If you are using a firewall you'll have to configure this setting. 
```
$ sudo iptables -L
```
You can then check from your web server to see if you are able access redis. Make sure `redis` os running on you database server and that the port is open.
You can use [netcat](https://en.wikipedia.org/wiki/Netcat) to test the connection.
```
$ nc -v <host-ip> 6379
```
If you are successful you should see something similiar to below. Then you can just use `Ctl-C` to exit.
```
Ncat: Connected to <host-ip>:6379.
```

[back to top](#table-of-contents)

