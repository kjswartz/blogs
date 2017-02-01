# Web Server
([back to main](../))
## Table of Contents
- [Directory Setup](#directory-setup)

- [Environment Variables](#environment-variables)
	- [bash_profile](#bash_profile)

	- [bashrc](#bashrc)

- [RVM](#rvm)

- [Puma](#puma)
	- [Init Scripts](#puma-init-scripts)

	- [Commands](#puma-commands)

- [NGINX](#nginx)
	- [Init Scripts](#nginx-init-scripts)

	- [Commands](#nginx-commands)

## Directory Setup
We need to setup our project directory and set the permissions. This will give ownership to our `deploy` user and group we setup and give the owner and group read-write and execute permission.
All other users will have read and execute permission.
```
$ mkdir /var/www/<project_name>
$ chown <deploy_user>:<deploy_group> /var/www/<project_name>
$ chmod 775 /opt/myproject
```

[More on Permissions](http://www.elated.com/articles/understanding-permissions/)

([back to top](#table-of-contents))

## Environment Variables
In order to utilize our environment variables in our app will need to setup our `.bashrc` and `.bash_profile`.
The below snippets should be enough to get these files setup if they are not already. Remember to do this as your `deploy` user, so `sudo su - <deploy_user>` first!
Also, be sure to `source` these files after modifying them in order for any changes to take immediate effect.

([back to top](#table-of-contents))

### bash_profile
```
# Get the aliases and functions
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

PATH=$PATH:$HOME/.local/bin:$HOME/bin
export PATH

source ~/.profile
```

([back to top](#table-of-contents))

### bashrc
```
# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

export <KEY>=<VALUE>

export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting
``` 

([back to top](#table-of-contents))

## [RVM](https://rvm.io/)
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

([back to top](#table-of-contents))

## [Puma](https://github.com/puma/puma)
Puma will be the server responsible for running our app. We'll be using Capistrano for deploying our app 
so our `puma.rb` configuration file will live in a shared folder. See [here](puma_example.rb) for an example configuration.
```
$ mkdir /var/www/<project>/shared
```

([back to top](#table-of-contents))

### Puma Commands
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

([back to top](#table-of-contents))

### Puma Init Scripts
[Jungle Init](https://github.com/puma/puma/tree/master/tools/jungle/init.d)

([back to top](#table-of-contents))


## [NGINX](https://www.nginx.com/resources/wiki/start/)
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

([back to top](#table-of-contents))

### NGINX Init Scripts
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

([back to top](#table-of-contents))

### NGINX Commands
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

([back to top](#table-of-contents))

