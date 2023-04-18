# Oracle REST Data Services (ORDS) on Docker

Apache Tomcat 9 (as ORDS is using JAX Servlet and not Jakarta Servlets)
Oracle JDK 17
ORDS Latest **Current at 23.1 , will wait until it fails



The following article provides a description of this Dockerfile.

[Docker : Oracle REST Data Services (ORDS) on Docker](https://oracle-base.com/articles/linux/docker-oracle-rest-data-services-ords-on-docker)

Directory contents when software is included.

```
$ tree
.
├── Dockerfile
├── README.md
├── scripts
│   ├── healthcheck.sh
│   ├── install_os_packages.sh
│   ├── ords_software_installation.sh
│   ├── server.xml
│   └── start.sh
└── software
    ├── apache-tomcat-9.0.71.tar.gz
    ├── apex_22.2_en.zip
    ├── OpenJDK11U-jdk_x64_linux_hotspot_11.0.18_10.tar.gz
    ├── ords-latest.zip
    ├── put_software_here.txt
    └── sqlcl-latest.zip

$
```

* Pre-requisites


Since we will be using external host volume for persistent storage, the build expects it to owned by a group with the group ID of 1042. Please complete the steps here

[Docker : Host File System Permissions for Container Persistent Host Volumes](https://oracle-base.com/articles/linux/docker-host-file-system-permissions-for-container-persistent-host-volumes)



Buiding Image & loggin
https://forums.docker.com/t/capture-ouput-of-docker-build-into-a-log-file/123178 

after installing docker-compose

```
[root@localhost] sudo usermod -aG docker docker_user;


docker-compose up --force-recreate -d 2>&1 | tee build.log
docker-compose build
docker-compose run
setting project name 
docker-compose -p my_proj up --build

```
[root@host] su - docker_user
[docker_user@host]
cd /tmp
git clone 
cd ords

docker build --no-cache --progress=plain -t ol8_ords:latest . 2>&1 | tee build.log

```



```
docker network create ords_network
```

* Creating  volume for the docker containers


mkdir -p /home/docker_user/volumes/ol_ords_tomcat_nginx_config 
docker volume create --driver local \
    --opt type=none \
    --opt device=/home/docker_user/volumes/ol_ords_tomcat_nginx_config \
    --opt o=bind ords_server_config_vol




```
docker run -dit --hostname ords_instance1  --name ol8_ords_con \
             -p 8080:8080 -p 8443:8443 \
             --network=ords_network \
             -e "HOST_NAME=localhost"  \
             -e "DB_SERVICE_NAME=neoranch_high"  \
             -e "SYS_USER=ADMIN" \
             -e "SYS_USER_PASSWORD=Pandora_1234" \
             -e "SETUP_ORDS_USERS=No" \
             -e "ORDS_USER=ORDS_PUBLIC_USER2" \
             -e "ORDS_USER_PASSWORD=Pandora_1234" \
             -e "GATEWAY_USER=ORDS_PLSQL_GATEWAY2" \
             -e "GATEWAY_USER_PASSWORD=Pandora_1234" \
             -v /home/docker_user/volumes/ol_ords_tomcat:/u01/config \
            ol8_ords:latest


```

For Portrainer

```
SYS_USER=ADMIN
SYS_USER_PASSWORD=Pandora_1234
SETUP_ORDS_USERS=No
ORDS_USER=ORDS_PUBLIC_USER2
ORDS_USER_PASSWORD=Pandora_1234
GATEWAY_USER=ORDS_PLSQL_GATEWAY2
GATEWAY_USER_PASSWORD=Pandora_1234


```
Verify host names

```
docker container ls
 docker exec <container name> hostname
 
docker exec ol8_ords_con hostname


```

# Development Related:

For JDK installation we have following options
1) installing Package java-17-openjdk in install_os_pacakges.sh 
  and thus JAVA_HOME already set, comment out setting Manually JAVA_HOME in dockerfile ENV JAVA_HOME
  and remove downloading the rpm file
  so commentout code in ords_software_install.sh
2) using targ.gz
3) using rpm install agains JAVA_HOME automatically set


