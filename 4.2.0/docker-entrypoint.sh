#!/usr/bin/env bash
set -e

<<<<<<< HEAD
IRODS_CONFIG_FILE=/irods.config
SETUP_IRODS=false
REJOIN_IRODS=false
FirstArg="$1"

update_uid_gid() {
    gosu root chown -R irods:irods /var/lib/irods
    gosu root chown -R irods:irods /etc/irods
}

generate_config() {
    DATABASE_HOSTNAME_OR_IP=$(/sbin/ip -f inet -4 -o addr | grep eth | cut -d '/' -f 1 | rev | cut -d ' ' -f 1 | rev)
    echo "${IRODS_SERVICE_ACCOUNT_NAME}" > ${IRODS_CONFIG_FILE}
    echo "${IRODS_SERVICE_ACCOUNT_GROUP}" >> ${IRODS_CONFIG_FILE}
    echo "${IRODS_SERVER_ROLE}" >> ${IRODS_CONFIG_FILE}
    echo "${IRODS_PROVIDER_ZONE_NAME}" >> ${IRODS_CONFIG_FILE}
    echo "${IRODS_PROVIDER_HOST_NAME}" >> ${IRODS_CONFIG_FILE}
    echo "${IRODS_PORT}" >> ${IRODS_CONFIG_FILE}
    echo "${IRODS_PORT_RANGE_BEGIN}" >> ${IRODS_CONFIG_FILE}
    echo "${IRODS_PORT_RANGE_END}" >> ${IRODS_CONFIG_FILE}
    echo "${IRODS_CONTROL_PLANE_PORT}" >> ${IRODS_CONFIG_FILE}
    echo "${IRODS_SCHEMA_VALIDATION}" >> ${IRODS_CONFIG_FILE}
    echo "${IRODS_SERVER_ADMINISTRATOR_USER_NAME}" >> ${IRODS_CONFIG_FILE}
    echo "yes" >> ${IRODS_CONFIG_FILE}
    echo "${IRODS_SERVER_ZONE_KEY}" >> ${IRODS_CONFIG_FILE}
    echo "${IRODS_SERVER_NEGOTIATION_KEY}" >> ${IRODS_CONFIG_FILE}
    echo "${IRODS_CONTROL_PLANE_KEY}" >> ${IRODS_CONFIG_FILE}
    echo "${IRODS_SERVER_ADMINISTRATOR_PASSWORD}" >> ${IRODS_CONFIG_FILE}
    echo "${IRODS_VAULT_DIRECTORY}" >> ${IRODS_CONFIG_FILE}
}

if [[ "$FirstArg" = 'setup_irods.sh' ]]; then
    SETUP_IRODS=true
fi
if [[ "$FirstArg" = 'rejoin_irods' ]]; then
    REJOIN_IRODS=true
fi

if $SETUP_IRODS; then
    # Generate iRODS config file
    generate_config

    # Setup iRODS
    if [[ "$1" = 'setup_irods.sh' ]] && [[ "$#" -eq 1 ]]; then
        # Configure with environment variables
        gosu root python /var/lib/irods/scripts/setup_irods.py < ${IRODS_CONFIG_FILE}
    else
        # TODO: Configure with file
        gosu root python /var/lib/irods/scripts/setup_irods.py < ${IRODS_CONFIG_FILE}
=======
INIT=false
EXISTING=false
USAGE=false
VERBOSE=false
RUN_IRODS=false

_update_uid_gid() {
    # update UID
    gosu root usermod -u ${UID_IRODS} irods
    # update GID
    gosu root groupmod -g ${GID_IRODS} irods
    # update directories
    gosu root chown -R irods:irods /var/lib/irods
    gosu root chown -R irods:irods /etc/irods
}

_irods_tgz() {
    if [ -z "$(ls -A /var/lib/irods)" ]; then
        gosu root cp /irods.tar.gz /var/lib/irods/irods.tar.gz
        cd /var/lib/irods/
        if $VERBOSE; then
            echo "!!! populating /var/lib/irods with initial contents !!!"
            gosu root tar -zxvf irods.tar.gz
        else
            gosu root tar -zxf irods.tar.gz
        fi
        cd /
        gosu root rm -f /var/lib/irods/irods.tar.gz
>>>>>>> mjstealey/master
    fi
}

_generate_config() {
    local OUTFILE=/irods.config
    echo "${IRODS_SERVICE_ACCOUNT_NAME}" > $OUTFILE
    echo "${IRODS_SERVICE_ACCOUNT_GROUP}" >> $OUTFILE
    echo "${IRODS_SERVER_ROLE}" >> $OUTFILE
    echo "${IRODS_PROVIDER_ZONE_NAME}" >> $OUTFILE
    echo "${IRODS_PROVIDER_HOST_NAME}" >> $OUTFILE
    echo "${IRODS_PORT}" >> $OUTFILE
    echo "${IRODS_PORT_RANGE_BEGIN}" >> $OUTFILE
    echo "${IRODS_PORT_RANGE_END}" >> $OUTFILE
    echo "${IRODS_CONTROL_PLANE_PORT}" >> $OUTFILE
    echo "${IRODS_SCHEMA_VALIDATION}" >> $OUTFILE
    echo "${IRODS_SERVER_ADMINISTRATOR_USER_NAME}" >> $OUTFILE
    echo "yes" >> $OUTFILE
    echo "${IRODS_SERVER_ZONE_KEY}" >> $OUTFILE
    echo "${IRODS_SERVER_NEGOTIATION_KEY}" >> $OUTFILE
    echo "${IRODS_CONTROL_PLANE_KEY}" >> $OUTFILE
    echo "${IRODS_SERVER_ADMINISTRATOR_PASSWORD}" >> $OUTFILE
    echo "${IRODS_VAULT_DIRECTORY}" >> $OUTFILE
}

_usage() {
    echo "Usage: ${0} [-h] [-ix run_irods] [-v] [arguments]"
    echo " "
    echo "options:"
    echo "-h                    show brief help"
    echo "-i run_irods          initialize iRODS 4.2.0 consumer"
    echo "-x run_irods          use existing iRODS 4.2.0 consumer files"
    echo "-v                    verbose output"
    echo ""
    echo "Example:"
    echo "  $ docker run --rm mjstealey/irods-consumer:4.2.0 -h           # show help"
    echo "  $ docker run -d mjstealey/irods-consumer:4.2.0 -i run_irods   # init with default settings"
    echo ""
    exit 0
}

while getopts hixv opt; do
  case "${opt}" in
    h)      USAGE=true ;;
    i)      INIT=true && echo "INFO: Initialize iRODS consumer";;
    x)      EXISTING=true && echo "INFO: Use existing iRODS consumer files";;
    v)      VERBOSE=true ;;
    ?)      USAGE=true && echo "ERROR: Invalid option provided";;
  esac
done

<<<<<<< HEAD
    # Keep container alive
    tail -f /dev/null
elif $REJOIN_IRODS; then
    #To restart a consumer after the container has been shut down
    update_uid_gid
    gosu root /etc/init.d/irods start
    echo "Success"
    echo "You have rejoined the irods network"
    tail -f /dev/null
else
    echo "Hmmm... Somthing went wrong along the way"
=======
for var in "$@"
do
    if [[ "${var}" = 'run_irods' ]]; then
        RUN_IRODS=true
    fi
done

if $RUN_IRODS; then
    if $USAGE; then
        _usage
    fi
    if $INIT; then
        _irods_tgz
        _update_uid_gid
        _generate_config
        gosu root python /var/lib/irods/scripts/setup_irods.py < /irods.config
        _update_uid_gid
        if $VERBOSE; then
            echo "INFO: show ienv"
            gosu irods ienv
        fi
        gosu root tail -f /dev/null
    fi
    if $EXISTING; then
        _update_uid_gid
        gosu root service irods start
        gosu root tail -f /dev/null
    fi
else
    if $USAGE; then
        _usage
    fi
    _update_uid_gid
>>>>>>> mjstealey/master
    exec "$@"
fi

exit 0;
