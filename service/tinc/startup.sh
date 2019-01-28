#!/bin/bash -e

readarray cmds < environment/default.startup.conf

FIRST_START_DONE="${CONTAINER_STATE_DIR}/docker-tinc-first-start-done"
# container first start
if [ ! -e "$FIRST_START_DONE" ]; then
  mkdir --parents ${CONTAINER_SERVICE_DIR}/tinc/data

  TINC_HOSTNAME=$(echo $HOSTNAME | sed -e 's/[^a-zA-Z0-9\_]/_/g')
  tinc --config ${CONTAINER_SERVICE_DIR}/tinc/data init $TINC_HOSTNAME

  for cmd in "${cmds[@]}"; do
    echo "Run tinc command: ${cmd}"
    tinc --config=${CONTAINER_SERVICE_DIR}/tinc/data ${cmd}
  done
fi

exit 0
