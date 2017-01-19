# How to Deploy a Rails App on RHEL 

Recently I had the opportunity to build and deploy a Rails Application to a Red Hat Linux ([RHEL](https://www.redhat.com/en/technologies/linux-platforms/enterprise-linux)) instance. 
My setup consisted of two different groups of servers (Production and Staging), and two separate servers within those groups (web and database), for a grand total of 4x servers. 
The web server is where our application will be housed with a NGINX HTTP server and a Puma web server. Our Postgresql database is going to live on our database server and only be used 
for storing our database. Why not just have both the database and application live on the same server? Because I was given two servers to utilize. You can keep everything on the same server to avoid
having to setup and maintain/host multiple servers, but if you can spare the resources i.e. someone else's is forking the bill and wanted it setup that way, why not? I kind of like the separation of
concerns here as well. I'm sure there are additional security and configuration concerns we could explore here covering the pros or cons, but that goes way beyond the scope for what I'm trying to accomplish here.  




## Tools
- Puma
- NGINX
- Postgresql

### [Puma](https://github.com/puma/puma)




#### [Jungle Init](https://github.com/puma/puma/tree/master/tools/jungle/init.d)


### [NGINX](https://www.nginx.com/resources/wiki/start/)

### [Postgresql](https://www.postgresql.org/download/)
