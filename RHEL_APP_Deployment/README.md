# How to Deploy a Rails App on RHEL 

Recently I had the opportunity to build and deploy a Rails Application to a Red Hat Linux ([RHEL](https://www.redhat.com/en/technologies/linux-platforms/enterprise-linux)) instance. 
My setup consisted of two different groups of servers (Production and Staging), and two separate servers within those groups (web and database), for a grand total of 4x servers. 
The web server is where our application will be housed with a NGINX HTTP server and a Puma web server. Our Postgresql database is going to live on our database server and only be used 
for storing our database. Why not just have both the database and application live on the same server? Because I was given two servers to utilize. You can keep everything on the same server to avoid
having to setup and maintain/host multiple servers, but if you can spare the resources i.e. someone else's is forking the bill and wanted it setup that way, why not? I kind of like the separation of
concerns here as well. I'm sure there are additional security and configuration concerns we could explore here covering the pros or cons, but that goes way beyond the scope for what I'm trying to accomplish here.  

We will be using [yum](https://access.redhat.com/solutions/9934) for installing software packages. 
From RHEL: `yum` is the primary tool for getting, installing, deleting, querying, and managing Red Hat Enterprise Linux RPM software packages from official Red Hat software repositories, 
as well as other third-party repositories. `yum` is used in Red Hat Enterprise Linux versions 5 and later. Versions of Red Hat Enterprise Linux 4 and earlier used `up2date`.

## User Setup
Depending on who setup your servers you may need to create or modify users. I will just quickly cover the basics of setting up a user here. You should have a root user when you initially setup your server. 
The general structure we'll operate from for our web server is three user types: a root user, a user that can ssh into our server, and a deploy user in charge of running our app. 
You do not want to run your app as the root user and you do not want to use your root user for main ssh access user. 
On our database server we'll be fine with just our root user and then a user responsible for ssh access.
As the root user we can create accounts and groups.

We should create a specific group for a deploy user to belong to. You can name this the same as what you name your deploy user.
```
$ groupadd [options] <group_name>
$ groupadd www-data
```
Now create your deploy user. Since we already created our deploy group we can immediately add our new user to this group with the `-g` flag.
```
$ useradd [options] <user_name>
$ useradd -g www-data www-data
```
In order to set a user's group after creation 
```
$ usermod -aG <group_name> <user_name>
```
By default new users are locked accounts, meaning they do not have ssh access and you can only switch to them once you are logged in. 
We do NOT want to unlock our deploy user account. However, if are you creating an account for ssh access use the following to add a password.
```
$ passwd <user_name>
```
In order to lock a user who previously had login access
```
$ passwd -l <user_name>
```

[See Here for additional information and options](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/System_Administrators_Guide/s1-users-tools.html)

## Database Server
### Database Tools
- [Postgresql](#postgresql)
- [Redis](#redis)

### [Postgresql](https://www.postgresql.org/download/linux/redhat/)

#### Installation 
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
#### User and Database Creation
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

#### Testing connection from our Web Server
Since we are using two different servers to host our web code and database, we'll need to make sure we can access our database from our `webserver`. 
- NOTE: If you have a firewall setup you'll need to configure it to allow access from your webserver on port `5432`.  

- NOTE you may need to `yum install postgresql` on your webserver to use psql in order to test your connection via the command line.

```
$ psql -h <host-ip> -p <port> -U <user> -W <database_name> 
```
You will then be prompted for the user password and if successful you'll prompt should change to the `database_name=>`. 
You can use `\l` to list databases, `\dt` to see a list of the tables in your database and `\q` to quit.

Helpful guides
- [Postgres installation](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-postgresql-on-centos-7)

- [Postgres Docs](https://www.postgresql.org/docs/9.0/static/)

### [Redis](https://redis.io/topics/quickstart)
Redis will be utilized as our caching solution. A client connects to a Redis server creating a TCP connection to the port 6379. 

#### Installation 
As `root` user or user with sudo privilages:
```
$ sudo yum install redis
```
Since we are setting up separate servers for our database of web files will need to modify the `redis.conf` configuration file. 
```
$ vim /etc/redis.conf
```
Then you'll need to change the `bind 127.0.0.1` to `bind 0.0.0.0` in order to connect from outside server.

#### Control Commands
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

#### Access 
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


## Web Server
### Initial Directory Setup
We need to setup our project directory and set the permissions. This will give ownership to our `deploy` user and group we setup and give the owner and group read-write and execute permission.
All other users will have read and execute permission.
```
$ mkdir /var/www/<project_name>
$ chown <deploy_user>:<deploy_group> /var/www/<project_name>
$ chmod 775 /opt/myproject
```

[More on Permissions](http://www.elated.com/articles/understanding-permissions/)

### Varible Configuration 
In order to utilize our environment variables in our app will need to setup our `.bashrc` and `.bash_profile`.
The below snippets should be enough to get these files setup if they are not already. Remember to do this as your `deploy` user, so `sudo su - <deploy_user>` first!
Also, be sure to `source` these files after modifying them in order for any changes to take immediate effect.

#### .bash_profile
```
# Get the aliases and functions
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

PATH=$PATH:$HOME/.local/bin:$HOME/bin
export PATH

source ~/.profile
```

#### .bashrc
```
# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

export <KEY>=<VALUE>

export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting
``` 


### Webserver Tools
- Puma
- NGINX
- RVM

#### [RVM](https://rvm.io/)
I prefer using [RVM](https://rvm.io/rvm/install) for installing ruby so lets set that up. The following step will install `mpapis public key`.
```
$ gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
```
Then we can install RVM stable. Follow the instructions, you'll possibly have to run an additional command based on the output.
```
$ curl -sSL https://get.rvm.io | bash -s stable
```
Once RVM is installed source the rvm script and install ruby.
```
$ source /etc/profile.d/rvm.sh 
$ rvm install 2.3.1 
```
We also need to install bundler.
```
$ gem install bundler
```

#### [Puma](https://github.com/puma/puma)
Puma will be the server responsible for running our app. We'll be using Capistrano for deploying our app 
so our `puma.rb` configuration file will live in a shared folder. See [here](puma_example.rb) for an example configuration.
```
$ mkdir /var/www/<project>/shared
```

##### Server commands
To start puma in the background
```
$ bundle exec pumactl -F /var/www/<project>/shared/puma.rb start &
```

To stop puma
```
bundle exec pumactl -P /var/www/<project>/shared/tmp/pids/puma.pid restart'
```
or
```
$ ps aux | grep puma
kswartz          32760   0.0  0.7  2670400 120608 s001  S     1:18PM   0:03.94 puma 3.6.0 (tcp://0.0.0.0:3000) [<project>] 
$ kill -s 15 32760
```

To restart
```
pumactl -P /var/www/<project>/shared/tmp/pids/puma.pid restart'
```


##### [Jungle Init](https://github.com/puma/puma/tree/master/tools/jungle/init.d)


#### [NGINX](https://www.nginx.com/resources/wiki/start/)
NGINX is a free, open-source, high-performance HTTP server and reverse proxy.
```
$ yum install nginx
```
[nginx.conf](nginx_example.conf) example can be found here.

Create a sites-enabled directory if on does NOT exist. This is where we'll place our site specific configuration file (project_name.conf). 
```
$ mkdir /etc/nginx/sites-enabled
```
[project.conf](sites-enabled_example.conf) example can be found here.

##### INIT Scripts
We should configure NGINX to automatically start when the server does.
Grab the `init.d` script from [here](https://www.nginx.com/resources/wiki/start/topics/examples/redhatnginxinit/) and save as `/etc/init.d/nginx`

Make the file executable
```
$ chmod 755 /etc/init.d/nginx -v
```
Now turn on the [chkconfig](http://linuxcommand.org/man_pages/chkconfig8.html) for nginx.
```
$ chkconfig nginx on
```
To test everything is setup restart your server and check to see that NGINX starts.
```
$ shutdown -r now
or 
$ reboot
```
Once the server becomes available login and check NGINX status
```
$ service nginx status
``` 

##### Server Commands
NGINX commands are controlled with `service` from root user.

Start:
```
$ service nginx start
```
Check status:
```
$ service nginx status
```
Restart:
```
$ service nginx restart
```
Stop:
```
$ service nginx stop
```
