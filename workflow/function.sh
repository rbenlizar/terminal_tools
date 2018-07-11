set -u

# When script exists, run the clean up process
trap exit_app 0

trap error_app INT TERM HUP KILL

WORKFLOWS_DIR=''
PLAYBOOK_DIR=''

_init() {

  WORKFLOWS_DIR=`readlink -f ${1} | xargs dirname`
  PLAYBOOK_DIR=`dirname ${WORKFLOWS_DIR}`

  # suppress the output of the pushd command
  pushd ${PLAYBOOK_DIR}/ 1>/dev/null
}

_cleanup() {
  # suppress output of the popd command
  popd 1>/dev/null
}

exit_app() {
  _cleanup
}

error_app() {
  echo 'Error encountered - exiting'
  _cleanup
  exit 1
}

_execute_playbook() {
  local sTags="${1}"
  local sPlaybook="${2}"
  shift 2

  local sEnvironment="${G_ENVIRONMENT_NAME}"
  local sBuildVersion=''
  if [[ "n${G_DEPLOY_VERSION}" != 'n' ]] ; then
    sBuildVersion="--extra-vars=deploy_build_version=${G_DEPLOY_VERSION}"
    echo "Running with: ${sBuildVersion}"
  fi

  set -x

  time \
  ANSIBLE_HOST_KEY_CHECKING=false \
  ANSIBLE_FORCE_COLOR=true \
  /usr/bin/ansible-playbook \
    ${sPlaybook} \
    -i ../ansible-ee-inventory/ee-${sEnvironment}.ini \
    --tags ${sTags} \
    --diff \
    ${sBuildVersion} \
    ${G_DRYRUN} \
    $@

  set +x
}

_download_roles() {

  if [[ -r ./requirements.yml ]] ; then
    echo "Downloading roles for execution"
    time \
    /usr/bin/ansible-galaxy \
      install \
      -r \
      ./requirements.yml
  fi
}

