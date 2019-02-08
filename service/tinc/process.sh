#!/bin/bash -e

mkdir --parents ${CONTAINER_STATE_DIR}
touch ${CONTAINER_STATE_DIR}/docker-tinc-first-start-done

STARTUP_CONF="/environment/default.startup.conf"

PUBLIC_IP_MAIN=$(/service/tinc/get-fargate-task-ipaddr.sh)
PUBLIC_IP_PEER=$(/service/tinc/get-fargate-task-ipaddr.sh --get-peer)

sed -i "s/nodemain.Address = [0-9.]*/nodemain.Address = ${PUBLIC_IP_MAIN}/g" ${STARTUP_CONF}
sed -i "s/nodepeer.Address = [0-9.]*/nodepeer.Address = ${PUBLIC_IP_PEER}/g" ${STARTUP_CONF}

readarray cmds < ${STARTUP_CONF}

for cmd in "${cmds[@]}"; do
  echo "Run tinc command: ${cmd}"
  tinc --config=${CONTAINER_SERVICE_DIR}/tinc/data ${cmd}
done

exec tinc --config=${CONTAINER_SERVICE_DIR}/tinc/data start --bypass-security --logfile=/var/log/tinc.log --no-detach ${TINC_CMD_ARGS}
