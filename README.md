# Oracle REST Data Services (ORDS) on Docker

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


Buiding Image & loggin
https://forums.docker.com/t/capture-ouput-of-docker-build-into-a-log-file/123178 

```
docker build --no-cache --progress=plain ol8_ords:latest . 2>&1 | tee build.log

```



If you are using an external host volume for persistent storage, the build expects it to owned by a group with the group ID of 1042. This is described here.

```
docker network create ords_network
```




```
docker run -dit --name ol8_ords_con \
             -p 8080:8080 -p 8443:8443 \
             --network=ords_network \
              -e "DB_SERVICE_NAME=neoranch_high"  \
              -e "SYS_USER=ADMIN" \
             -e "SYS_USER_PASSWORD=Pandora_1234" \
             -e "SETUP_ORDS_USERS=No" \
             -e "ORDS_USER=ORDS_PUBLIC_USER2" \
             -e "ORDS_USER_PASSWORD=Pandora_1234" \
             -e "GATEWAY_USER=ORDS_PLSQL_GATEWAY2" \
             -e "GATEWAY_USER_PASSWORD=Pandora_1234" \
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



[Docker : Host File System Permissions for Container Persistent Host Volumes](https://oracle-base.com/articles/linux/docker-host-file-system-permissions-for-container-persistent-host-volumes)
