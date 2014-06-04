#!/usr/bin/env bash

function _install_nagios_rpms() {
  local EPEL_VERSION=${1:-'5'}
  local DOWNLOAD_DIR=$(mktemp -d)
  cd ${DOWNLOAD_DIR}

  local EPEL_RELEASE=''
  local REMI_RELEASE=''

  local EPEL_RPM='epel.noarch.rpm'
  local REMI_RPM='remi-release.rpm'

  if [ "${EPEL_VERSION}" == '5' ];
  then
     EPEL_RELEASE='http://dl.fedoraproject.org/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm'
     REMI_RELEASE='http://rpms.famillecollet.com/enterprise/remi-release-5.rpm'
  else
    EPEL_RELEASE='http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm'
    REMI_RELEASE='http://rpms.famillecollet.com/enterprise/remi-release-6.rpm'
  fi
  curl -o "${EPEL_RPM}" "${EPEL_RELEASE}"
  curl -o "${REMI_RPM}" "${REMI_RELEASE}"

  sudo rpm -Uvh "${EPEL_RPM}" "${REMI_RPM}"
  rm -rf ${DOWNLOAD_DIR}
}

function _command_exists() {
  local COMMAND="${1}"
  command -v "${COMMAND}" >/dev/null 2>&1 || return 1;
}

function setup_nagios() {
  local NAGIOS_USER='nagios'
  local NAGIOS_USER_HOME="/home/${NAGIOS_USER}"
  local NAGIOS_BIN_DIR="${NAGIOS_USER_HOME}/bin"
  local RSA_PUB_KEY_URL=${1:-'https://raw.github.com/inviqa/SysAdmin/master/nagios/inviqa_nagios_user_rsa_public_key.pub'}
  local THIRD_PARTY_UNPACKAGED_SCRIPTS_URL=${2:-'https://raw.github.com/inviqa/SysAdmin/master/nagios/third-party'}
  local NAGIOS_SCRIPTS_SYSTEM_DIR='/usr/lib64/nagios/plugins'

  if ! id -u "${NAGIOS_USER}" >/dev/null 2>&1;
  then
    # creation of a nagios user on each server
    echo "User ${NAGIOS_USER} not fouond, creating..."
    sudo adduser "${NAGIOS_USER}" --home "${NAGIOS_USER_HOME}"
  fi
  sudo passwd -l "${NAGIOS_USER}"

  # install the SSH2 RSA Public key of the nagios user of the nagios/icinga server
  sudo mkdir -p "${NAGIOS_USER_HOME}/.ssh"
  sudo curl -o "${NAGIOS_USER_HOME}/.ssh/authorized_keys" "${RSA_PUB_KEY_URL}"
  sudo chown -R "${NAGIOS_USER}":"${NAGIOS_USER}" "${NAGIOS_USER_HOME}/.ssh"
  sudo chmod -R go-rwx "${NAGIOS_USER_HOME}/.ssh"

  if ! _command_exists 'lsb_release';
  then
    echo 'lsb_release command not found, installing...'
    sudo yum install -y redhat-lsb
  fi
  local REDHAT_VERSION_NUMBER=$(lsb_release -rs | cut -f1 -d.)

  _install_nagios_rpms ${REDHAT_VERSION_NUMBER}

  # Installation of nagios checks scripts and necassary libraries
  sudo yum install -y nagios-plugins nagios-common nagios-plugins-http nagios-plugins-load nagios-plugins-disk nagios-plugins-swap

  # Installation of the System Memory check script
  sudo mkdir -p "${NAGIOS_BIN_DIR}"

  sudo curl -k -o "${NAGIOS_BIN_DIR}/check_mem.pl" "${THIRD_PARTY_UNPACKAGED_SCRIPTS_URL}/check_mem.pl"

  # linking the installed check scripts to the nagios's home/bin folder as expected by the nagios server
  ln -f -s "${NAGIOS_SCRIPTS_SYSTEM_DIR}/check_disk" "${NAGIOS_BIN_DIR}/check_disk"
  ln -f -s "${NAGIOS_SCRIPTS_SYSTEM_DIR}/check_load" "${NAGIOS_BIN_DIR}/check_load"
  ln -f -s "${NAGIOS_SCRIPTS_SYSTEM_DIR}/check_swap" "${NAGIOS_BIN_DIR}/check_swap"
  ln -f -s "${NAGIOS_SCRIPTS_SYSTEM_DIR}/check_http" "${NAGIOS_BIN_DIR}/check_http"

  sudo chown -R "${NAGIOS_USER}":"${NAGIOS_USER}" "${NAGIOS_BIN_DIR}"
}

setup_nagios
