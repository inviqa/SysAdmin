#!/usr/bin/env bash

SUDO=''

if [[ ${EUID} -ne 0 ]]; then
   # Not running as root, use sudo
   SUDO='sudo';
fi

function _install_nagios_rpms() {
  local EPEL_VERSION=${1:-'6'}
  # make a temporary directory
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
  curl -L -o "${EPEL_RPM}" "${EPEL_RELEASE}"
  curl -L -o "${REMI_RPM}" "${REMI_RELEASE}"

  echo "Installing ${EPEL_RPM} ${EPEL_RELEASE}"
  ${SUDO} rpm -Uvh "${EPEL_RPM}" "${REMI_RPM}"
  rm -rf ${DOWNLOAD_DIR}  && cd ~
}

function _command_exists() {
  local COMMAND="${1}"
  command -v "${COMMAND}" >/dev/null 2>&1 || return 1;
}

function setup_nagios() {
  local NAGIOS_USER='nagios'
  local NAGIOS_USER_HOME="/home/${NAGIOS_USER}"
  local NAGIOS_BIN_DIR="${NAGIOS_USER_HOME}/bin"

  local THIRD_PARTY_UNPACKAGED_SCRIPTS_URL=${2:-'https://raw.github.com/inviqa/SysAdmin/master/nagios/third-party'}
  local NAGIOS_SCRIPTS_SYSTEM_DIR='/usr/lib64/nagios/plugins'

  if ! _command_exists 'lsb_release';
  then
    echo 'lsb_release command not found, installing...'
    ${SUDO} yum install -y redhat-lsb
  fi
  local REDHAT_VERSION_NUMBER=$(lsb_release -rs | cut -f1 -d.)

  _install_nagios_rpms ${REDHAT_VERSION_NUMBER}

  # Installation of nagios checks scripts and necassary libraries
  echo 'Install nagios RPMs'
  ${SUDO} yum install -y nagios-plugins nagios-common nagios-plugins-http nagios-plugins-load nagios-plugins-disk nagios-plugins-swap

  # Installation of the System Memory check script

  ${SUDO} mkdir -p "${NAGIOS_BIN_DIR}"

  cd "${NAGIOS_BIN_DIR}"

  rm ./*

  ${SUDO} curl -k -o "${NAGIOS_BIN_DIR}/check_mem.pl" "${THIRD_PARTY_UNPACKAGED_SCRIPTS_URL}/check_mem.pl"

  # linking the installed check scripts to the nagios's home/bin folder as expected by the nagios server
  ln -f -s "${NAGIOS_SCRIPTS_SYSTEM_DIR}/check_disk" "${NAGIOS_BIN_DIR}/check_disk"
  ln -f -s "${NAGIOS_SCRIPTS_SYSTEM_DIR}/check_load" "${NAGIOS_BIN_DIR}/check_load"
  ln -f -s "${NAGIOS_SCRIPTS_SYSTEM_DIR}/check_swap" "${NAGIOS_BIN_DIR}/check_swap"
  ln -f -s "${NAGIOS_SCRIPTS_SYSTEM_DIR}/check_http" "${NAGIOS_BIN_DIR}/check_http"

  ${SUDO} chown -R "${NAGIOS_USER}":"${NAGIOS_USER}"
}

setup_nagios
