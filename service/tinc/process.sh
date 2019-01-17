#!/bin/bash -e

exec tincd --config ${CONTAINER_SERVICE_DIR}/tinc/data --no-detach $TINC_CMD_ARGS
