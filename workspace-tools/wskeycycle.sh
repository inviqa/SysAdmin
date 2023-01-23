#!/usr/bin/env bash


function load_parameters {
    tmp="${0%.*}"
    ME=${tmp##*/}
    DEBUG=1
    REQUIREMENTS=('gsed' 'ws')
    DEVELOPMENT_KEY_DEFAULT=''
    DEVELOPMENT_KEY_NEW=''
    DEVELOPMENT_KEY_FILE=''
    ORIGINAL_SECRETS=()
    WS_FILE="workspace.yml"
    WS_FILE_OVERRIDE="workspace.override.yml"
    WS_JENKINS_FILE="Jenkinsfile"
    RESTORE_BACKUP=false
    read_parameters "${@}"

    export WS_FILE_ORIGINAL="${WS_FILE}.orig"
    export WS_FILE_OVERRIDE_ORIGINAL="${WS_FILE_OVERRIDE}.orig"
}

function print_usage {
  printf  "usage: %s [options] \n" "${ME}"
  printf  "\noptions:"
  USAGE="
      -d|--debug <level>                0: show only command errors and rotation completion
                                        1: show only command errors
                                        2: show all computed steps output
      -h|--help                         Print this help  
      -k|--development-key-file <file>  Path to the plaintext file containing your new Development Key (if this parameter is not specified a new Key will generated automatically)
      -o|--workspace-override-file      Path to the Workspace Override file where the current Development Key is stored (defaults to workspace.override.yml)
      -q|--quiet                        Equal to --debug 0
      -r|--restore                      Restore .orig backup to original Workspace files
      -w|--workspace-file               Path to the Workspace file where the encrypted secrets are stored (defaults to workspace.yml)

"
echo "${USAGE}"
}

function validate_argument {
  ARGUMENT="${1}"
  if [[ -z "${ARGUMENT}" || "${ARGUMENT}" == "-*" ]]; then
    echo "(e) | Invalid or missing argument ${1}"
    print_usage
    exit 1
  fi
}

function read_parameters {
  if [[ -n "${1}" ]]; then
    case "${1}" in
      -d|--debug)
        validate_argument "${2}"
        DEBUG="${2}"
        shift 2
        ;;
      -h|--help)
        print_usage
        exit 0
        ;;
      -k|--development-key-file)
        validate_argument "${2}"
        DEVELOPMENT_KEY_FILE="${2}"
        shift 2
        ;;
      -o|--workspace-override-file)
        validate_argument "${2}"
        WS_FILE_OVERRIDE="${2}"
        shift 2
        ;;
      -q|--quiet)
        DEBUG=0
        shift 1
        ;;
      -r|--restore)
        RESTORE_BACKUP=true
        shift 1
        ;;
      -w|--workspace-file)
        validate_argument "${2}"
        WS_FILE="${2}"
        shift 2
        ;;
      *)
        echo "(e) | Invalid option: ${1}"
        print_usage
        exit 1
        ;;
    esac
    read_parameters "${@}"
  fi
}
    
function is_requirement_available {
    for TOOL in "${REQUIREMENTS[@]}"
    do
        TOOL_PATH="$( command -v "${TOOL}")"
        if [[ ! -x "${TOOL_PATH}" ]]; then
            echo "(e) | ABORTING: COMMAND '${TOOL}' NOT FOUND OR NOT EXECUTABLE!"
            return 1
        else
            if [[ ${DEBUG} -ge 1 ]]; then echo "(d) | REQUIREMENT FOUND: ${TOOL_PATH}"; fi
        fi
    done
}

function backup_workspace_files {
    if [[ ${DEBUG} -ge 1 ]]; then echo "(d) | WS_FILE: ${WS_FILE}"; fi
    if [[ ${DEBUG} -ge 1 ]]; then echo "(d) | WS_FILE_OVERRIDE: ${WS_FILE_OVERRIDE}"; fi
    for FILE in "${WS_FILE}" "${WS_FILE_OVERRIDE}"
    do
        if [[ -f "${FILE}" ]]; then
            BACKUP_FILE="${FILE}.orig"
            if [[ ! -f "${BACKUP_FILE}" ]]; then
                cp -a "${FILE}" "${BACKUP_FILE}"
                if [[ ${DEBUG} -ge 1 ]]; then echo "(d) | BACKUP OF '${FILE}' CREATED: '${BACKUP_FILE}'"; fi
            else
                if [[ ${DEBUG} -ge 1 ]]; then echo "(d) | SKIPPING BACKUP: '${BACKUP_FILE}' already exists"; fi
            fi
        else
            echo "(e) | ABORTING: WORKSPACE FILE '${FILE}' NOT FOUND!"
            exit 1
        fi
    done
}

function restore_workspace_files {
    if [[ ${DEBUG} -ge 2 ]]; then echo "(d) | WS_FILE: ${WS_FILE}"; fi
    if [[ ${DEBUG} -ge 2 ]]; then echo "(d) | WS_FILE_ORIGINAL: ${WS_FILE_ORIGINAL}"; fi
    if [[ ${DEBUG} -ge 2 ]]; then echo "(d) | WS_FILE_OVERRIDE: ${WS_FILE_OVERRIDE}"; fi
    if [[ ${DEBUG} -ge 2 ]]; then echo "(d) | WS_FILE_OVERRIDE_ORIGINAL: ${WS_FILE_OVERRIDE_ORIGINAL}"; fi
    for FILE in "${WS_FILE}" "${WS_FILE_OVERRIDE}"
    do
        BACKUP_FILE="${FILE}.orig"
        if [[ -f "${BACKUP_FILE}" ]]; then 
            if cp -a "${BACKUP_FILE}" "${FILE}"; then
                if [[ ${DEBUG} -ge 1 ]]; then echo "(d) | BACKUP '${BACKUP_FILE}' RESTORED TO '${FILE}'"; fi
            else
                if [[ ${DEBUG} -ge 1 ]]; then echo "(e) | ABORTING: COULD NOT RESTORE '${FILE}'"; fi
            fi
        else
            echo "(e) | ABORTING: BACKUP FILE '${BACKUP_FILE}' NOT FOUND"
            exit 1
        fi
    done
}

function get_development_key_default {
    DEVELOPMENT_KEY_DEFAULT="$( grep "key('default')" "${WS_FILE_OVERRIDE_ORIGINAL}" || true )"
    DEVELOPMENT_KEY_DEFAULT="${DEVELOPMENT_KEY_DEFAULT##*:\ }"
    DEVELOPMENT_KEY_CURRENT="$( grep "key('default')" "${WS_FILE_OVERRIDE}" || true )"
    DEVELOPMENT_KEY_CURRENT="${DEVELOPMENT_KEY_CURRENT##*:\ }"

    if [[ ${DEBUG} -ge 2 ]]; then echo "(d) | DEVELOPMENT_KEY_DEFAULT: ${DEVELOPMENT_KEY_DEFAULT}"; fi
    if [[ "${DEVELOPMENT_KEY_DEFAULT}" != "${DEVELOPMENT_KEY_CURRENT}" ]]; then
        if [[ ${DEBUG} -ge 2 ]]; then echo "(d) | DEVELOPMENT_KEY_CURRENT: ${DEVELOPMENT_KEY_CURRENT}"; fi
        echo "(e) | ABORTING..."
        echo "(e) | THE ORIGINAL DEVELOPMENT KEY '${DEVELOPMENT_KEY_DEFAULT:0:5}.....' DIFFERS FROM THE CURRENT KEY '${DEVELOPMENT_KEY_CURRENT:0:5}.....'"
        echo "(e) | IT WILL NOT BE ABLE TO DECRYPT THE SECRETS '${WS_FILE_OVERRIDE}'"
        echo "(i) | This is probably due to a previous Workspace Development Key rotation"
        echo "(i) | Restore the '.origin' backup files to cycle from the ORIGINAL Workspace file"
        echo "(i) | Remove the '.origin' backup files to cycle from the NEW Workspace files"
        exit 1
    fi
}

function update_development_key {
    if is_string_in_file "${DEVELOPMENT_KEY_DEFAULT}" "${WS_FILE_OVERRIDE}"; then
        if [[ -n "${DEVELOPMENT_KEY_FILE}" ]]; then
            if [[ ${DEBUG} -ge 1 ]]; then echo "(d) | USING NEW DEVELOPMENT FROM '${DEVELOPMENT_KEY_FILE}'"; fi
            if [[ -f "${DEVELOPMENT_KEY_FILE}" ]]; then
                DEVELOPMENT_KEY_NEW="$( cat "${DEVELOPMENT_KEY_FILE}" )"
            else
                echo "(e) | ABORTING: 'DEVELOPMENT_KEY_FILE' NOT FOUND"
                exit 1
            fi
        else
            if [[ ${DEBUG} -ge 1 ]]; then echo "(d) | GENERATING A NEW DEVELOPMENT KEY VIA 'ws secret generate-random-key'"; fi 
            DEVELOPMENT_KEY_NEW="$( ws secret generate-random-key )"
        fi
        if [[ -n "${DEVELOPMENT_KEY_NEW}" ]]; then 
            replace_string_in_file "${DEVELOPMENT_KEY_DEFAULT}" "${DEVELOPMENT_KEY_NEW}" "${WS_FILE_OVERRIDE}"
            if [[ ${DEBUG} -ge 2 ]]; then echo "(d) | DEVELOPMENT_KEY_NEW: ${DEVELOPMENT_KEY_NEW}"; fi
        else
            echo "(e) | ABORTING: NEW DEVELOPMENT KEY IS ANY EMPTY STRING"
            exit 1
        fi
    else
        echo "(e) | ABORTING: '${DEVELOPMENT_KEY_DEFAULT:0:5}.....' NOT FOUND IN '${WS_FILE_OVERRIDE}'"
        exit 1
    fi
}

function is_string_in_file {
    STRING="${1}"
    FILE="${2}"
    if grep -q "${STRING}" "${FILE}"; then
        if [[ ${DEBUG} -ge 2 ]]; then echo "(d) | STRING '${STRING:0:10}.....' FOUND IN '${FILE}'"; fi
        return  0
    else
        if [[ ${DEBUG} -ge 2 ]]; then echo "(d) | STRING '${STRING:0:10}.....' NOT FOUND IN '${FILE}'"; fi
        return 1
    fi
}

function replace_string_in_file {
    OLD_STRING="${1}"
    NEW_STRING="${2}"
    FILE="${3}"

    if [[ ${#OLD_STRING} -ge 30 ]]; then
        OLD_STRING_TRIMMED="${OLD_STRING:0:10}...${OLD_STRING: -10:10}"
    else
        OLD_STRING_TRIMMED="${OLD_STRING:0:10}..."
    fi
    if [[ ${#OLD_STRING} -ge 30 ]]; then
        NEW_STRING_TRIMMED="${NEW_STRING:0:10}...${NEW_STRING: -10:10}"
    else
        NEW_STRING_TRIMMED="${NEW_STRING:0:10}..."
    fi
    
    if [[ -f "${FILE}" ]]; then
        gsed -i -e "s|${OLD_STRING}|${NEW_STRING}|" "${FILE}"
        if is_string_in_file "${NEW_STRING:0:300}" "${FILE}"; then
            if [[ ${DEBUG} -ge 1 ]]; then echo "(d) | STRING '${OLD_STRING_TRIMMED}' REPLACED WITH '${NEW_STRING_TRIMMED}' IN '${FILE}'"; fi
        else
            echo "(e) | ABORTING..."
            echo "(e) | ERROR WHILE REPLACING STRING '${OLD_STRING_TRIMMED}' WITH  '${NEW_STRING_TRIMMED}' IN FILE '${FILE}'"
            exit 1
        fi
    else
        echo "(e) | ABORTING: FILE '${FILE}' not found!"
        exit 1
    fi
}

function get_old_encryption_secrets {
    SECRETS_ARRAY=()
    GREP_COMMAND="grep decrypt ${WS_FILE_ORIGINAL}"
    if  [[ "${BASH_VERSINFO:-0}" -ge 4 ]]; then
        mapfile -t SECRETS_ARRAY < <( ${GREP_COMMAND} | sort --unique || true )
    else
        # shellcheck disable=SC2207
        # SECRETS_ARRAY=( "$( "${GREP_COMMAND}" | sort --unique || true)" )
        SECRETS_ARRAY=( "$( ${GREP_COMMAND} | sort --unique || true )" )
    fi

    if [[ ${DEBUG} -ge 1 ]]; then echo "(d) | SECRETS_#: ${#SECRETS_ARRAY[*]}"; fi

    for (( ELEMENT=0; ELEMENT<${#SECRETS_ARRAY[*]}; ELEMENT++ ));
    do
        SECRET="${SECRETS_ARRAY[${ELEMENT}]}"
        SECRET="${SECRET##*decrypt(\'}"
        SECRET="${SECRET##*decrypt(\"}"
        SECRET="${SECRET%%\'\)*}"
        SECRET="${SECRET%%\"\)*}"
        ORIGINAL_SECRETS[ELEMENT]="${SECRET}"
        if [[ ${DEBUG} -ge 2 ]]; then echo "(d) | OLD_ENCRYPTION[${ELEMENT}]: ${ORIGINAL_SECRETS[ELEMENT]}"; fi
    done
    if [[ ${DEBUG} -ge 1 ]]; then echo "(d) | ${#ORIGINAL_SECRETS[*]} UNIQUE SECRETS FOUND"; fi
}

function get_raw_secrets {
    if [[ ${#ORIGINAL_SECRETS[*]} -ge 1 ]]; then
        for (( ELEMENT=0; ELEMENT<${#ORIGINAL_SECRETS[*]}; ELEMENT++ ));
        do
            ORIGINAL_SECRET="${ORIGINAL_SECRETS[${ELEMENT}]}"
            RAW_SECRET="$( ws secret decrypt "${ORIGINAL_SECRET}")"
            if [[ -n "${RAW_SECRET}" ]]; then
                RAW_SECRETS[ELEMENT]="${RAW_SECRET}"
                if [[ ${DEBUG} -ge 2 ]]; then echo "(d) | RAW_SECRET[${ELEMENT}]: ${RAW_SECRETS[ELEMENT]:1:5}....."; fi
            fi
        done
        if [[ ${#ORIGINAL_SECRETS[*]} -ne ${#RAW_SECRETS[*]} ]]; then
            echo "(e) | ABORTING..."
            echo "(e) | UNEXPECTED ERROR: QUANTITY OF ENCRYPTED SECRETS IS ${#ORIGINAL_SECRETS[*]} Vs ${#RAW_SECRETS[*]} RAW SECRETS"
            exit 1
        fi
    else
        echo "(i) | NO SECRETS FOUND"
    fi
}

function generate_new_encryption_secrets {
    if [[ ${#RAW_SECRET[*]} -ge 1 ]]; then
        for (( ELEMENT=0; ELEMENT<${#RAW_SECRETS[*]}; ELEMENT++ ));
        do
            RAW_SECRET="${RAW_SECRETS[${ELEMENT}]}"
            if [[ -n "${RAW_SECRET}" ]]; then
                NEW_ENCRYPTION_SECRET="$( ws secret encrypt "${RAW_SECRET}")"
                NEW_ENCRYPTION_SECRETS[ELEMENT]="${NEW_ENCRYPTION_SECRET}"
                if [[ ${DEBUG} -ge 2 ]]; then echo "(d) | NEW_ENCRYPTION[${ELEMENT}]: ${NEW_ENCRYPTION_SECRETS[ELEMENT]}"; fi
            fi
        done
        if [[ ${#NEW_ENCRYPTION_SECRETS[*]} -ne ${#RAW_SECRETS[*]} ]]; then
            echo "(e) | ABORTING..."
            echo "(e) | UNEXPECTED ERROR: QUANTITY OF NEW ENCRYPTED SECRETS IS ${#NEW_ENCRYPTION_SECRETS[*]} Vs ${#RAW_SECRETS[*]} RAW SECRETS"
            exit 1
        fi
    else
        if [[ ${DEBUG} -ge 1 ]]; then echo "(d) | NO RAW SECRET FOUND"; fi
    fi
}

function reencrypt_secrets {
    RAW_SECRETS=()
    ORIGINAL_SECRETS=()
    NEW_ENCRYPTION_SECRETS=()

    get_development_key_default
    get_old_encryption_secrets
    get_raw_secrets
    update_development_key
    generate_new_encryption_secrets
    if [[ ${#NEW_ENCRYPTION_SECRETS[*]} -ge 1 ]]; then
        if [[ ${DEBUG} -ge 1 ]]; then echo "(d) | UPDATING SECRETS WITH NEW ENCRYPTION"; fi
        for (( ELEMENT=0; ELEMENT<${#ORIGINAL_SECRETS[*]}; ELEMENT++ ));
        do
            ORIGINAL_SECRET="${ORIGINAL_SECRETS[${ELEMENT}]}"
            NEW_ENCRYPTION_SECRET="${NEW_ENCRYPTION_SECRETS[${ELEMENT}]}"
            if [[ -n "${ORIGINAL_SECRET}"  &&  -n "${NEW_ENCRYPTION_SECRET}" ]]; then
                if replace_string_in_file "${ORIGINAL_SECRET}" "${NEW_ENCRYPTION_SECRET}" "${WS_FILE}"; then
                    if [[ ${DEBUG} -ge 2 ]]; then echo "(d) | NEW_ENCRYPTION[${ELEMENT}]: ${NEW_ENCRYPTION_SECRETS[ELEMENT]}"; fi
                else
                    echo "(e) | ABORTING..."
                    echo "(e) | UNEXPECTED ERROR WHILE UPDATING SECRET[${ELEMENT}]"
                    exit 1
                fi
            fi
        done
        echo "(i) | ${#NEW_ENCRYPTION_SECRETS[*]} UNIQUE SECRETS UPDATED"
    else
        echo "(i) | PROCESS COMPLETED WITHOUT PROCESSING ANY SECRET"
    fi

}

function check_jenkins {
    if [[ -f "${WS_JENKINS_FILE}" ]]; then
        if [[ ${DEBUG} -ge 1 ]]; then echo "(d) | JENKINS FILE '${WS_JENKINS_FILE}' FOUND"; fi
        JENKINS_MY127WS_KEY="$( grep "MY127WS_KEY" "${WS_JENKINS_FILE}" || true )"
        JENKINS_MY127WS_KEY="${JENKINS_MY127WS_KEY//[[:blank:]]/}" 
        if [[ -n "${JENKINS_MY127WS_KEY}" ]]; then
            if [[ ${DEBUG} -ge 1 ]]; then echo "(d) | JENKINS FILE USES '${JENKINS_MY127WS_KEY}'"; fi
            echo "(i) | Consider updating the Jenkins credential"
            echo "(i) | If necessary update the Workspace attribute 'jenkins.credentials.my127ws_key'"
        fi
    else
        if [[ ${DEBUG} -ge 1 ]]; then echo "(d) | NO JENKINS FILE FOUND"; fi
    fi
}

load_parameters "${@}"
if [[ "${RESTORE_BACKUP}" == true ]];then
    restore_workspace_files
    exit 0
fi

if is_requirement_available; then
    backup_workspace_files
    reencrypt_secrets
    check_jenkins
    exit 0
else
    exit 1
fi
