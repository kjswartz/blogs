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

## Table of Contents
- [User Setup](#user-setup)

- [Database Server](database_server)

- [Web Server](web_server)

# User Setup
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


