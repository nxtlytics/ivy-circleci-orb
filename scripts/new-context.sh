#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

THIS_SCRIPT=$(basename $0)
PADDING=$(printf %-${#THIS_SCRIPT}s " ")

usage () {
    echo "Usage:"
    echo "${THIS_SCRIPT} -s <REQUIRED: version control system type> -o <REQUIRED: org name>"
    echo "${PADDING} -c <REQUIRED: context-name> -v <REQUIRED: 1Password vault name containing item>"
    echo "${PADDING} -i <REQUIRED: 1Password item name to sync>"
    echo
    echo 'Creates new circleci context'
    echo "Note: this uses 1Password's op command line."
    echo '      Please run: eval $(op signin <1Password account name>)'
    exit 1
}

# Ensure dependencies are present
if [[ ! -x $(command -v circleci) || ! -x $(command -v op) || ! -x $(command -v jq) ]]; then
    echo "[-] Dependencies unmet.  Please verify that the following are installed and in the PATH: circleci, jq, op (1Password cli)" >&2
    exit 1
fi

while getopts ":s:o:c:v:i:" opt; do
  case ${opt} in
    s)
      VCS_TYPE="${OPTARG}" ;;
    o)
      ORG_NAME="${OPTARG}" ;;
    c)
      CONTEXT_NAME="${OPTARG}" ;;
    v)
      ONEPASSWORD_VAULT="${OPTARG}" ;;
    i)
      ONEPASSWORD_ITEM="${OPTARG}" ;;
    \?)
      usage ;;
    :)
      usage ;;
  esac
done

if [[ -z ${VCS_TYPE:-""} || -z ${ORG_NAME:-""} || -z ${CONTEXT_NAME:-""} || -z ${ONEPASSWORD_VAULT:-""} || -z ${ONEPASSWORD_ITEM:-""} ]]; then
  usage
fi

TMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir')

function cleanup () {
  rm -rf "${TMP_DIR}/"
}

# Make sure cleanup runs on exit
trap cleanup EXIT

OP_ITEMS="${TMP_DIR}/items_in_vault.json"
op list items --vault "${ONEPASSWORD_VAULT}" > "${OP_ITEMS}"

function get_context_from_1password() {
  local QUERY=".[] | select(.overview.title | test(\"^${ONEPASSWORD_ITEM}$\")) | .uuid"
  local ITEM_UUID="$(jq -r "${QUERY}" "${OP_ITEMS}")"
  op get item "${ITEM_UUID}" | jq -r .details.notesPlain | grep -v '```'
}

CONTEXT_VARS_VALUES=( $(get_context_from_1password) )

function add_envvar_to_context() {
  local SECRET_NAME="${1}"
  local SECRET_VALUE="${2}"
  echo -n "${SECRET_VALUE}" | circleci context store-secret "${VCS_TYPE}" "${ORG_NAME}" "${CONTEXT_NAME}" "${SECRET_NAME}"
}

if circleci context list "${VCS_TYPE}" "${ORG_NAME}" | grep "${CONTEXT_NAME}" &> /dev/null; then
  echo "Context: ${CONTEXT_NAME} already exists, I will not create it"
else
  echo "I will try to create context: ${CONTEXT_NAME}"
  circleci context create "${VCS_TYPE}" "${ORG_NAME}" "${CONTEXT_NAME}"
  echo "I will add its environment variables now"
  for i in "${CONTEXT_VARS_VALUES[@]}"; do
    NAME="$(echo "${i}" | cut -d ' ' -f1)"
    VALUE="$(echo "${i}" | cut -d ' ' -f2)"
    add_envvar_to_context "${NAME}" "${VALUE}"
  done
fi

echo "I'm done"
