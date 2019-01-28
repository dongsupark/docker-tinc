#!/bin/bash -e

mkdir --parents ${CONTAINER_STATE_DIR}
touch ${CONTAINER_STATE_DIR}/docker-tinc-first-start-done

exec tinc --config=${CONTAINER_SERVICE_DIR}/tinc/data start --no-detach ${TINC_CMD_ARGS}
