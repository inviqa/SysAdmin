#!/usr/bin/env bash

set -e

function create_deploy_sudo() {

  local SUDOERS_FILE='/etc/sudoers.d/deploy';
  local TMP_DIR=$(mktemp -dt "$(basename $0).XXXXXXXXXX");
  local SUDO_GID='2000';
  local TMP_FILE="${TMP_DIR}/deploy";

cat << EOF > "${TMP_FILE}"
  Defaults:%#${SUDO_GID} !requiretty
  %#${SUDO_GID}  ALL=(ALL)       NOPASSWD: ALL
EOF
  mv "${TMP_FILE}" "${SUDOERS_FILE}";
  chmod 0600 "${SUDOERS_FILE}";
}

create_deploy_sudo;
