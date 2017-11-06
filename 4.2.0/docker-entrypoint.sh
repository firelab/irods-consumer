#!/usr/bin/env bash
set -e

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
    fi

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
    exec "$@"
fi

exit 0;
