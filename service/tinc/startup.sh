#!/bin/bash -e

PEERS=${PEERS:-nodepeer}

readarray cmds < environment/default.startup.conf

FIRST_START_DONE="${CONTAINER_STATE_DIR}/docker-tinc-first-start-done"
# container first start
if [ ! -e "$FIRST_START_DONE" ]; then
  mkdir --parents ${CONTAINER_SERVICE_DIR}/tinc/data/hosts

  for peer in "${PEERS}"; do
    touch ${CONTAINER_SERVICE_DIR}/tinc/data/hosts/${peer}
  done

  echo "#!/bin/bash" >> ${CONTAINER_SERVICE_DIR}/tinc/data/tinc-up
  echo "ip link set tap0 up" >> ${CONTAINER_SERVICE_DIR}/tinc/data/tinc-up
  echo "ip addr add 10.1.1.1/24 dev tap0" >> ${CONTAINER_SERVICE_DIR}/tinc/data/tinc-up

  chmod +x ${CONTAINER_SERVICE_DIR}/tinc/data/tinc-up

  TINC_HOSTNAME="nodemain"
  tinc --config ${CONTAINER_SERVICE_DIR}/tinc/data init $TINC_HOSTNAME

  for cmd in "${cmds[@]}"; do
    echo "Run tinc command: ${cmd}"
    tinc --config=${CONTAINER_SERVICE_DIR}/tinc/data ${cmd}
  done
fi

exit 0
