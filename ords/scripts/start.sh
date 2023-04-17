echo "******************************************************************************"
echo "Check if this is the first run." `date`
echo "******************************************************************************"
FIRST_RUN="false"
if [ ! -f ~/CONTAINER_ALREADY_STARTED_FLAG ]; then
  echo "First run."
  FIRST_RUN="true"
  touch ~/CONTAINER_ALREADY_STARTED_FLAG
else
  echo "Not first run."
fi

echo "******************************************************************************"
echo "Handle shutdowns." `date`
echo "docker stop --time=30 {container}" `date`
echo "******************************************************************************"
function gracefulshutdown {
  ${CATALINA_HOME}/bin/shutdown.sh
}

trap gracefulshutdown SIGINT
trap gracefulshutdown SIGTERM
trap gracefulshutdown SIGKILL

echo "******************************************************************************"
echo "Check DB is available." `date`
echo "******************************************************************************"
export PATH=${PATH}:${JAVA_HOME}/bin:${ORDS_HOME}/bin
export TNS_ADMIN=${TNS_ADMIN}
#export _JAVA_OPTIONS=${JAVA_OPTS}
export ORDS_CONFIG=${ORDS_CONF}



function check_db {
  CONNECTION=$1
  RETVAL=`/u01/sqlcl/bin/sql -silent ${CONNECTION} <<EOF
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF TAB OFF
SELECT 'Alive' FROM dual;
EXIT;
EOF`

  RETVAL="${RETVAL//[$'\t\r\n']}"
  if [ "${RETVAL}" = "Alive" ]; then
    DB_OK=0
  else
    DB_OK=1
  fi
}

function create_ords_users {
  CONNECTION=$1
  RETVAL=`/u01/sqlcl/bin/sql -silent ${CONNECTION} <<EOF
create user ${ORDS_USER} identified by "${ORDS_USER_PASSWORD}";
grant connect to ORDS_PUBLIC_USER2;
begin
    ords_admin.provision_runtime_role(
        p_user => '${ORDS_USER}'
        , p_proxy_enabled_schemas => true
    );
end;
/
CREATE USER ${GATEWAY_USER} IDENTIFIED BY "${GATEWAY_USER_PASSWORD}";
BEGIN
  ORDS_ADMIN.CONFIG_PLSQL_GATEWAY(
        p_runtime_user => '${ORDS_USER}', 
        p_plsql_gateway_user => '${GATEWAY_USER}');
END;
/
SELECT 'Done' FROM dual;
EXIT;
EOF`

  RETVAL="${RETVAL//[$'\t\r\n']}"
  if [ "${RETVAL}" = "Done" ]; then
    ORDS_USER_CREATED=0
  else
    ORDS_USER_CREATED=1
  fi
}


CONNECTION="${SYS_USER}/${SYS_USER_PASSWORD}@${DB_SERVICE_NAME} as sysdba"
check_db ${CONNECTION}
while [ ${DB_OK} -eq 1 ]
do
  echo "DB not available yet. Waiting for 30 seconds."
  sleep 30
  check_db ${CONNECTION}
done



if [ ! -d ${CATALINA_BASE}/conf ]; then
  echo "******************************************************************************"
  echo "New CATALINA_BASE location." `date`
  echo "******************************************************************************"
  if [ -f ${CATALINA_BASE}/conf ]; then
    rm -f ${CATALINA_BASE}/conf
  fi
  mkdir -p ${CATALINA_BASE}/conf
  mkdir -p ${CATALINA_BASE}/logs
  mkdir -p ${CATALINA_BASE}/temp
  mkdir -p ${CATALINA_BASE}/webapps
  mkdir -p ${CATALINA_BASE}/work
  cp -R ${CATALINA_HOME}/conf/* ${CATALINA_BASE}/conf/
  cp -R ${CATALINA_HOME}/logs/* ${CATALINA_BASE}/logs/
  cp -R ${CATALINA_HOME}/temp/* ${CATALINA_BASE}/temp/
  cp -R ${CATALINA_HOME}/webapps/* ${CATALINA_BASE}/webapps/
  cp -R ${CATALINA_HOME}/work/* ${CATALINA_BASE}/work/
fi

if [ ! -d ${CATALINA_BASE}/webapps/i ]; then
  echo "******************************************************************************"
  echo "First time APEX images." `date`
  echo "******************************************************************************"
  mkdir -p ${CATALINA_BASE}/webapps/i/
  cp -R ${SOFTWARE_DIR}/images/* ${CATALINA_BASE}/webapps/i/
  APEX_IMAGES_REFRESH="false"
fi

if [ "${APEX_IMAGES_REFRESH}" == "true" ]; then
  echo "******************************************************************************"
  echo "Overwrite APEX images." `date`
  echo "******************************************************************************"
  cp -R ${SOFTWARE_DIR}/images/* ${CATALINA_BASE}/webapps/i/
fi



if [ "${FIRST_RUN}" == "true" ]; then
  echo "******************************************************************************"
  echo "Configure ORDS. Safe to run on DB with existing config." `date`
  echo "******************************************************************************"
  
  
  cd ${ORDS_HOME}


  if [ "${CREATE_ORDS_USERS}" ==  "Yes" ]; then
    echo "******************************************************************************"
    echo "Creating ORDS Public users" `date`
    echo "******************************************************************************"
    create_ords_users ${CONNECTION}
    if [ ${ORDS_USER_CREATED} -eq 1 ]; then
     echo "......ORDS Public users created successfully......." `date`

    fi;

  fi;
  
  #  echo "...........wallet.zip..........." `date`
  
  # if [ ! -d ${ORDS_CONF}/wallet ]; then
  # echo "******************************************************************************"
  # echo "Copy wallet.zip to ords_conf/wallet" `date`
  # echo "******************************************************************************"
  # cp ${SOFTWARE_DIR}/wallet.zip ${ORDS_CONF}/wallet/wallet.zip
  # rm -f ${SOFTWARE_DIR}/wallet*.zip
  # fi;




  echo "...........Configuring ords ..........." `date`

  if [ ! -d ${ORDS_CONF} ]; then

  #sometime is does not generate the configurations so first give one config command and then install adb
  #${ORDS_HOME}/bin/ords --config ${ORDS_CONF} config set db.username  ${ORDS_USER} 
  # ${ORDS_HOME}/bin/ords --config ${ORDS_CONF} config set standalone.static.path ${APEX_IMAGES} 
  # ${ORDS_HOME}/bin/ords --config ${ORDS_CONF} config set db.wallet.zip.path ${WALLET_PATH}
  # ${ORDS_HOME}/bin/ords --config ${ORDS_CONF} config set  db.wallet.zip.service ${DB_SERVICE_NAME}
  # ${ORDS_HOME}/bin/ords --config ${ORDS_CONF} config set plsql.gateway.mode proxied

  ${ORDS_HOME}/bin/ords --config ${ORDS_CONF}/ install adb --admin-user ${SYS_USER} --db-user ${ORDS_USER} --gateway-user ${GATEWAY_USER} --wallet ${TNS_ADMIN}/wallet.zip --wallet-service-name ${DB_SERVICE_NAME} --feature-sdw true --log-folder ${CONFIG_HOME}/logs --password-stdin <<EOF
  ${SYS_USER_PASSWORD}
  ${ORDS_USER_PASSWORD}
  ${GATEWAY_USER_PASSWORD}
  EOF
  

  #  ${ORDS_HOME}/bin/ords --config ${ORDS_CONF} install adb \
  #        --admin-user ${SYS_USER} \
  #        --db-user ${ORDS_USER} \
  #        --gateway-user ${GATEWAY_USER} \
  #        --log-folder ${ORDS_CONF}/logs \
  #        --feature-db-api true \
  #        --feature-rest-enabled-sql true \
  #        --feature-sdw true \       
  #        --gateway-mode proxied \       
  #        --wallet ${ORDS_CONF}/wallet/wallet.zip \
  #        --wallet-service-name ${DB_SERVICE_NAME} \      
  #        --password-stdin <<EOF
  # ${SYS_USER_PASSWORD}
  # ${ORDS_USER_PASSWORD}
  # ${GATEWAY_USER_PASSWORD}
  # EOF
  # instead of copy we will use the ords command
  # cp ords.war ${CATALINA_BASE}/webapps/
  
  ords --config  ${ORDS_CONF}/ war ${CATALINA_BASE}/webapps/${ORDS_PATH_PREFIX}.war
  fi

fi

if [ "${FIRST_RUN}" != "true"  &&  "${RECONFIGURE_ORDS}" == "Yes"]; then

echo "******************************************************************************"
  # echo "Reconfiguring ORDS based on the new values Provided" `date`
  # echo "******************************************************************************"
  
  #sometime is does not generate the configurations so first give one config command and then install adb
  #${ORDS_HOME}/bin/ords --config ${ORDS_CONF} config set db.username  ${ORDS_USER} 
  # ${ORDS_HOME}/bin/ords --config ${ORDS_CONF} config set standalone.static.path ${APEX_IMAGES} 
  # ${ORDS_HOME}/bin/ords --config ${ORDS_CONF} config set db.wallet.zip.path ${WALLET_PATH}
  # ${ORDS_HOME}/bin/ords --config ${ORDS_CONF} config set  db.wallet.zip.service ${DB_SERVICE_NAME}
  # ${ORDS_HOME}/bin/ords --config ${ORDS_CONF} config set plsql.gateway.mode proxied

  ${ORDS_HOME}/bin/ords --config ${ORDS_CONF}/ install adb --admin-user ${SYS_USER} --db-user ${ORDS_USER} --gateway-user ${GATEWAY_USER} --wallet ${TNS_ADMIN}/wallet.zip --wallet-service-name ${DB_SERVICE_NAME} --feature-sdw true --log-folder ${CONFIG_HOME}/logs --password-stdin <<EOF
  ${SYS_USER_PASSWORD}
  ${ORDS_USER_PASSWORD}
  ${GATEWAY_USER_PASSWORD}
  EOF

  #  ${ORDS_HOME}/bin/ords --config ${ORDS_CONF} install adb \
  #        --admin-user ${SYS_USER} \
  #        --db-user ${ORDS_USER} \
  #        --gateway-user ${GATEWAY_USER} \
  #        --log-folder ${ORDS_CONF}/logs \
  #        --feature-db-api true \
  #        --feature-rest-enabled-sql true \
  #        --feature-sdw true \       
  #        --gateway-mode proxied \       
  #        --wallet ${ORDS_CONF}/wallet/wallet.zip \
  #        --wallet-service-name ${DB_SERVICE_NAME} \      
  #        --password-stdin <<EOF
  # ${SYS_USER_PASSWORD}
  # ${ORDS_USER_PASSWORD}
  # ${GATEWAY_USER_PASSWORD}
  # EOF
  #instead of copy we will use the ords command
  # cp ords.war ${CATALINA_BASE}/webapps/
  ords --config  ${ORDS_CONF}/ war ${CATALINA_BASE}/webapps/${ORDS_PATH_PREFIX}.war
 
fi

echo "...........keystore.jks ..........." `date`

if [ ! -f ${KEYSTORE_DIR}/keystore.jks ]; then
  echo "******************************************************************************"
  echo "Configure HTTPS." `date`
  echo "******************************************************************************"
  mkdir -p ${KEYSTORE_DIR}
  cd ${KEYSTORE_DIR}
  ${JAVA_HOME}/bin/keytool -genkey -keyalg RSA -alias selfsigned -keystore keystore.jks \
     -dname "CN=${HOSTNAME}, OU=My Department, O=My Company, L=Birmingham, ST=West Midlands, C=GB" \
     -storepass ${KEYSTORE_PASSWORD} -validity 3600 -keysize 2048 -keypass ${KEYSTORE_PASSWORD}

  sed -i -e "s|###KEYSTORE_DIR###|${KEYSTORE_DIR}|g" ${SCRIPTS_DIR}/server.xml
  sed -i -e "s|###KEYSTORE_PASSWORD###|${KEYSTORE_PASSWORD}|g" ${SCRIPTS_DIR}/server.xml
  sed -i -e "s|###AJP_SECRET###|${AJP_SECRET}|g" ${SCRIPTS_DIR}/server.xml
  sed -i -e "s|###AJP_ADDRESS###|${AJP_ADDRESS}|g" ${SCRIPTS_DIR}/server.xml
  sed -i -e "s|###PROXY_IPS###|${PROXY_IPS}|g" ${SCRIPTS_DIR}/server.xml
  cp ${SCRIPTS_DIR}/server.xml ${CATALINA_BASE}/conf
  cp ${SCRIPTS_DIR}/web.xml ${CATALINA_BASE}/conf
fi;

echo "******************************************************************************"
echo "Start Tomcat." `date`
echo "******************************************************************************"
${CATALINA_HOME}/bin/startup.sh

echo "******************************************************************************"
echo "Tail the catalina.out file as a background process" `date`
echo "and wait on the process so script never ends." `date`
echo "******************************************************************************"
tail -f ${CATALINA_BASE}/logs/catalina.out &
bgPID=$!
wait $bgPID
