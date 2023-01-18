#!/usr/bin/env bash
DEBUG=2 # show progress output
# DEBUG=0 # show only command errors
# DEBUG=1 # show only command errors
# DEBUG=2 # show all computed steps output
REQUIREMENTS=("ws" "gsed")
export DEVELOPMENT_KEY_DEFAULT=''
export DEVELOPMENT_KEY_NEW=''
export ORIGINAL_SECRETS=()
export WS_FILE="${1:-workspace.yml}"
export WS_FILE_OVERRIDE="${2:-workspace.override.yml}"
export WS_FILE_ORIGINAL="${WS_FILE}.orig"
export WS_FILE_OVERRIDE_ORIGINAL="${WS_FILE_OVERRIDE}.orig"

    
function is_requirement_available {

    for TOOL in "${REQUIREMENTS[@]}"
    do
        TOOL_PATH="$( command -v "${TOOL}")"
        if [[ ! -x "${TOOL_PATH}" ]]; then
            echo "(e) | Command '${TOOL}' not found or not executable!"
            return 1
        else
            if [[ ${DEBUG} -ge 1 ]]; then echo "(d) | REQUIREMENT FOUND: ${TOOL_PATH}"; fi
            # return 0
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
            echo "(e) | Workspace file '${FILE}' not found!"
            exit 1
        fi
    done
}

function get_development_key_default {
    DEVELOPMENT_KEY_DEFAULT="$( grep "key('default')" "${WS_FILE_OVERRIDE_ORIGINAL}" || true )"
    DEVELOPMENT_KEY_DEFAULT="${DEVELOPMENT_KEY_DEFAULT##*:\ }"
    if [[ ${DEBUG} -ge 2 ]]; then echo "(d) | DEVELOPMENT_KEY_DEFAULT: ${DEVELOPMENT_KEY_DEFAULT}"; fi
}

function update_development_key {
    if is_string_in_file "${DEVELOPMENT_KEY_DEFAULT}" "${WS_FILE_OVERRIDE}"; then
        DEVELOPMENT_KEY_NEW="$( ws secret generate-random-key )"
        replace_string_in_file "${DEVELOPMENT_KEY_DEFAULT}" "${DEVELOPMENT_KEY_NEW}" "${WS_FILE_OVERRIDE}"
        if [[ ${DEBUG} -ge 2 ]]; then echo "(d) | DEVELOPMENT_KEY_NEW: ${DEVELOPMENT_KEY_NEW}"; fi
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
    # OLD_STRING=$(printf "%q" ${1})
    # NEW_STRING=$(printf "%q" ${2})
    OLD_STRING_TRIMMED="${OLD_STRING:0:10}....."
    NEW_STRING_TRIMMED="${NEW_STRING:0:10}....."
    FILE="${3}"
    if [[ -f "${FILE}" ]]; then
        ### these works only for simply values
        ### do not work for encrypted secrets
        # perl -pe "s|${OLD_STRING}|${NEW_STRING}|g" "${FILE}" > tmpfile && mv tmpfile "${FILE}"
        # printf '%s\n' ",s|${OLD_STRING}|${NEW_STRING}|g" w q | ed "${FILE}"
        # sed "s|${OLD_STRING}|${NEW_STRING}|" "${FILE}" > tmpfile && mv tmpfile "${FILE}"
        # sed -i -e 's|'"${OLD_STRING}"'|'"${NEW_STRING}"'|g' "${FILE}"
        gsed -i -e "s|${OLD_STRING}|${NEW_STRING}|" "${FILE}"

        # can't find a way to work with any string
        # awk '{gsub(${NEW_STRING}, ${OLD_STRING}, $0); print}' "${FILE}"
        # awk -v old=${OLD_STRING} -v new=${NEW_STRING} '{gsub(new, old, $0); print}' "${FILE}" > "${FILE}"

        if is_string_in_file "${NEW_STRING:0:300}" "${FILE}"; then
            if [[ ${DEBUG} -ge 1 ]]; then echo "(d) | STRING '${OLD_STRING_TRIMMED}' REPLACED WITH '${NEW_STRING_TRIMMED}' IN '${FILE}'"; fi
        else
            echo "(e) | ERROR WHILE REPLACING STRING '${OLD_STRING_TRIMMED}' WITH  '${NEW_STRING_TRIMMED}' IN FILE '${FILE}'"
            exit 1
        fi
    else
        echo "(e) | FILE '${FILE}' not found!"
        exit 1
    fi
}

function get_old_encryption_secrets {
    SECRETS_ARRAY=()
    if  [[ "${BASH_VERSINFO:-0}" -ge 4 ]]; then
        mapfile -t SECRETS_ARRAY < <(grep decrypt "${WS_FILE_ORIGINAL}" || true )
    else
        # shellcheck disable=SC2207
        SECRETS_ARRAY=( $( grep decrypt "${WS_FILE_ORIGINAL}" ) )
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
    if [[ ${DEBUG} -ge 1 ]]; then echo "(d) | ${#ORIGINAL_SECRETS[*]} SECRETS FOUND"; fi
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
                    echo "(e) | UNEXPECTED ERROR WHILE UPDATING SECRET[${ELEMENT}]"
                    exit 1
                fi
            fi
        done
        echo "(i) | ${#NEW_ENCRYPTION_SECRETS[*]} SECRETS UPDATED"
    else
        echo "(i) | PROCESS COMPLETED WITHOUT PROCESSING ANY SECRET"
    fi

}


if is_requirement_available; then
    backup_workspace_files
    reencrypt_secrets
    exit 0
else
    exit 1
fi




# if [[ ${DEBUG} -ge 2 ]]; then echo "(d) | ALL_ATTR: ${SECRETS_ARRAY[*]}"; fi
