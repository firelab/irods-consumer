#!/usr/bin/env bash
set -e

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

_fixGSI() {
    python /var/lib/irods/packaging/update_json.py /var/lib/irods/.irods/irods_environment.json string irods_authentication_scheme "PAM"
    python /var/lib/irods/packaging/update_json.py /var/lib/irods/.irods/irods_environment.json string X509_USER_CERT "/var/lib/irods/.globus/usercert.pem"
    python /var/lib/irods/packaging/update_json.py /var/lib/irods/.irods/irods_environment.json string X509_USER_KEY "/var/lib/irods/.globus/userkey.pem"
    python /var/lib/irods/packaging/update_json.py /var/lib/irods/.irods/irods_environment.json string X509_CERT_DIR "/var/lib/irods/.globus/certificates"
    python /var/lib/irods/packaging/update_json.py /var/lib/irods/.irods/irods_environment.json string irods_ssl_dh_params_file "/var/lib/irods/.globus/dhparams.pem"
    python /var/lib/irods/packaging/update_json.py /var/lib/irods/.irods/irods_environment.json string irods_ssl_certificate_chain_file "/var/lib/irods/.globus/usercert.pem"
    python /var/lib/irods/packaging/update_json.py /var/lib/irods/.irods/irods_environment.json string irods_ssl_certificate_key_file "/var/lib/irods/.globus/userkey.pem"
    python /var/lib/irods/packaging/update_json.py /etc/irods/server_config.json string zone_auth_scheme "GSI"
    python /var/lib/irods/packaging/update_json.py /etc/irods/server_config.json string rcComm_t "/C=US/O=Globus Consortium/OU=Globus Connect Service/CN=60803eee-9fba-11e6-b0de-22000b92c261"
    python /var/lib/irods/packaging/update_json.py /etc/irods/server_config.json string KerberosServicePrincipal "irodsserver/vault.firelab.org@FIRELAB.ORG"
    python /var/lib/irods/packaging/update_json.py /etc/irods/server_config.json string KerberosKeytab "/etc/krb5.keytab"
    python /var/lib/irods/packaging/update_json.py /etc/irods/server_config.json string environment_variables,KRB5_KTNAME "/etc/krb5.keytab"
    python /var/lib/irods/packaging/update_json.py /etc/irods/server_config.json string irods_default_resource "firelab"
    python /var/lib/irods/packaging/update_json.py /var/lib/irods/.irods/irods_environment.json string irods_default_resource "firelab"
    gosu root update-ca-certificates
}

_usage() {
    echo "Usage: ${0} [-h] [-ix run_irods] [-v] [arguments]"
    echo " "
    echo "options:"
    echo "-h                    show brief help"
    echo "-i run_irods          initialize iRODS 4.2.2 consumer"
    echo "-x run_irods          use existing iRODS 4.2.2 consumer files"
    echo "-v                    verbose output"
    echo ""
    echo "Example:"
    echo "  $ docker run --rm mjstealey/irods-consumer:4.2.2 -h           # show help"
    echo "  $ docker run -d mjstealey/irods-consumer:4.2.2 -i run_irods   # init with default settings"
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
        _fixGSI
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
    exec "$@"
fi

exit 0;
