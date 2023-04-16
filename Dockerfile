# ------------------------------------------------------------------------------
# Dockerfile to build basic Oracle REST Data Services (ORDS) images
# Based on the following:
#   - Oracle Linux 8 - Slim
#   - Java 11 :
#       https://adoptium.net/releases.html?variant=openjdk11&jvmVariant=hotspot
#   - Tomcat 9.0.x :
#       https://tomcat.apache.org/download-90.cgi
#   - Oracle REST Data Services (ORDS) :
#       http://www.oracle.com/technetwork/developer-tools/rest-data-services/downloads/index.html
#   - Oracle Application Express (APEX) :
#       http://www.oracle.com/technetwork/developer-tools/apex/downloads/index.html
#   - Oracle SQLcl :
#       http://www.oracle.com/technetwork/developer-tools/sqlcl/downloads/index.html
#
# Example build and run. Assumes Docker network called "my_network" to connect to DB.
#
# docker build -t ol8_ords:latest .
# docker build --squash -t ol8_ords:latest .
# Podman
# docker build --format docker --no-cache -t ol8_ords:latest .
#
# docker run -dit --name ol8_ords_con -p 8080:8080 -p 8443:8443 --network=my_network -e DB_HOSTNAME=ol8_19_con ol8_ords:latest
# Pure CATALINA_BASE on a persistent volume.
# docker run -dit --name ol8_ords_con -p 8080:8080 -p 8443:8443 --network=my_network -e DB_HOSTNAME=ol8_18_con -v /home/docker_user/volumes/ol8_19_ords_tomcat:/u01/config/instance1 ol8_ords:latest
#
# docker logs --follow ol8_ords_con
# docker exec -it ol8_ords_con bash
#
# docker stop --time=30 ol8_ords_con
# docker start ol8_ords_con
#
# docker rm -vf ol8_ords_con
#
# ------------------------------------------------------------------------------

# Set the base image to Oracle Linux 8
FROM oraclelinux:8-slim
#FROM oraclelinux:8

# File Author / Maintainer
# Use LABEL rather than deprecated MAINTAINER
# MAINTAINER M.Yasir Ali Shah (yasirali.wizerp@gmail.com)
LABEL maintainer="yasirali.wizerp@gmail.com"
# ------------------------------------------------------------------------------
# Define fixed (build time) environment variables.
ENV JAVA_SOFTWARE="OpenJDK11U-jdk_x64_linux_hotspot_11.0.18_10.tar.gz"          \
    TOMCAT_SOFTWARE="apache-tomcat-9.0.71.tar.gz"                              \
    ORDS_SOFTWARE="ords-latest.zip"                                            \
    APEX_SOFTWARE="apex_22.2_en.zip"                                           \ 
    SQLCL_SOFTWARE="sqlcl-latest.zip"                                          \
    SOFTWARE_DIR="/u01/software"                                               \
    SCRIPTS_DIR="/u01/scripts"                                                 \
    KEYSTORE_DIR="/u01/keystore"                                               \
    ORDS_HOME="/u01/ords"                                                      \
    ORDS_CONF="/u01/config/ords"                                               \
    JAVA_HOME="/u01/java/latest"                                               \
    CATALINA_HOME="/u01/tomcat/latest"                                         \
    CATALINA_BASE="/u01/config/instance1"  \
    TNS_ADMIN="/u01/oracle/network/admin"

# ------------------------------------------------------------------------------
# Define config (runtime) environment variables.
ENV DB_HOSTNAME="localhost"                                           \
    SYS_USER="ADMIN"      \
    SYS_USER_PASSWORD="ApexPassword1"   \
    ORDS_USER="ORDS_PUBLIC_USER2" \
    ORDS_USER_PASSWORD="ApexPassword1"  \
    GATEWAY_USER="ORDS_PLSQL_GATEWAY2"  \
    GATEWAY_USER_PASSWORD="ApexPassword1"  \
    DB_SERVICE_NAME="ORCL_HIGH"    \
    SETUP_ORDS_USERS="Yes" \
#   DB_PORT="1521"                                                             \
#   DB_SERVICE="pdb1"                                                          \
#    APEX_PUBLIC_USER_PASSWORD="ApexPassword1"                                  \
#    APEX_TABLESPACE="APEX"                                                     \
#    TEMP_TABLESPACE="TEMP"                                                     \
#    APEX_LISTENER_PASSWORD="ApexPassword1"                                     \
#    APEX_REST_PASSWORD="ApexPassword1"                                         \
#    PUBLIC_PASSWORD="ApexPassword1"                                            \
#    SYS_PASSWORD="SysPassword1"                                                \
    KEYSTORE_PASSWORD="KeystorePassword1"                                      \
    AJP_SECRET="AJPSecret1"                                                    \
    AJP_ADDRESS="::1"                                                          \
    APEX_IMAGES_REFRESH="false"                                                \
    PROXY_IPS="123.123.123.123\|123.123.123.124"                               \
    JAVA_OPTS="-Dconfig.url=${ORDS_CONF} -Xms1024M -Xmx1024M"


# ------------------------------------------------------------------------------
# Get all the files for the build.
COPY software/* ${SOFTWARE_DIR}/
COPY scripts/* ${SCRIPTS_DIR}/

# ------------------------------------------------------------------------------
# Unpack all the software and remove the media.
# No config done in the build phase.
RUN sh ${SCRIPTS_DIR}/install_os_packages.sh                                && \
    sh ${SCRIPTS_DIR}/ords_software_installation.sh

# Perform the following actions as the tomcat user
USER tomcat

#VOLUME [${CATALINA_BASE}]
EXPOSE 8080 8443
HEALTHCHECK --interval=1m --start-period=1m \
   CMD ${SCRIPTS_DIR}/healthcheck.sh >/dev/null || exit 1

# ------------------------------------------------------------------------------
# The start script performs all config based on runtime environment variables,
# and starts tomcat.
CMD exec ${SCRIPTS_DIR}/start.sh

# End
