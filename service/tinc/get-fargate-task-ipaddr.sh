#!/bin/bash
#
# Get a public IP address that matches with the private IP address of the
# current host inside an AWS ECS cluster.

set -e

if ! command -v aws >& /dev/null; then
  echo "aws command not found"
  exit 1
fi

if ! command -v jq >& /dev/null; then
  echo "jq command not found"
  exit 1
fi

OPTS="$1"
PEER_MODE=0

if [[ $# -ge 1 ]]; then
  if [[ "$OPTS" == "-h" ]] || [[ "$OPTS" == "--help" ]]; then
    echo "USAGE: $0 [options]"
    echo "  -h, --help: print help message"
    echo "  -p, --get-peer: get IP address of peer mode instead of main node"
    exit 1
  fi

  if [[ "$OPTS" == "-p" ]] || [[ "$OPTS" == "--get-peer" ]]; then
    echo "turning on peer mode"
    PEER_MODE=1
  fi
fi

INPUT_PRIVATE_IPADDR=$(ip address | grep -A2 eth0: | grep inet | tr -s ' ' | cut -d' ' -f3 | cut -d'/' -f1)

CLUSTER_NAME=$(aws ecs list-clusters | jq -r '.clusterArns | .[]')

tasks=()
while IFS=  read -r line; do
  tasks+=( "$line" )
done < <( aws ecs list-tasks --cluster="$CLUSTER_NAME" | jq -r '.taskArns | .[] ')

# Now ${tasks[@]} includes ARN of each task.
# Using the task ARN, get a private IP address: "aws ecs describe-tasks".
#
# Example of tasks:
#
# {
#    "tasks": [
#        {
#...
#            "containers": [
#                {
#                    "containerArn": "arn:aws:ecs:eu-central-1:871592188115:container/33ad0c37-638f-4bdc-bdb6-349221d0da93",
#                    "taskArn": "arn:aws:ecs:eu-central-1:871592188115:task/ffe56985-0992-4913-a55d-5b7eeb10e44b",
#                    "name": "fargate-test",
#                    "networkInterfaces": [
#                        {
#                            "attachmentId": "f249d321-246b-4b1e-ae86-0ccdddc278e4",
#                            "privateIpv4Address": "10.0.1.17"
#                        }
#                    ],
#                }
#            ],
#
# From the private IP address, look for a public address in the Elastic Network Interfaces:
#  "aws ec2 describe-network-interfaces".
#
# Example of NetworkInterfaces:
#
# {
#    "NetworkInterfaces": [
#        {
#...
#            "PrivateIpAddress": "10.0.0.225",
#            "PrivateIpAddresses": [
#                {
#                    "Association": {
#                       "IpOwnerId": "amazon",
#                       "PublicDnsName": "ec2-3-122-94-109.eu-central-1.compute.amazonaws.com",
#                       "PublicIp": "3.122.94.109"
#                     },
#                   "Primary": true,
#                   "PrivateDnsName": "ip-10-0-0-225.eu-central-1.compute.internal",
#                   "PrivateIpAddress": "10.0.0.225"
#                }
#            ],

privateAddress=""
privateAddressMain=""
privateAddressPeer=""

for task in "${tasks[@]}" ; do
  privateAddress=$(aws ecs describe-tasks --tasks="$task" --cluster="$CLUSTER_NAME" | jq -r '.tasks | .[] | .containers | .[] | .networkInterfaces | .[] | .privateIpv4Address')
  #echo "private address = $privateAddress"

  if [ "${INPUT_PRIVATE_IPADDR}" != "${privateAddress}" ]; then
    if [ "${PEER_MODE}" == "0" ]; then
      privateAddressPeer=${privateAddress}
    else
      privateAddressMain=${privateAddress}
    fi
  else
    if [ "${PEER_MODE}" == "0" ]; then
      privateAddressMain=${privateAddress}
    else
      privateAddressPeer=${privateAddress}
    fi
  fi
done

if [ "${privateAddressMain}" == "" ]; then
  echo "A matching public IP address for main node not found."
  exit 1
fi

if [ "${privateAddressPeer}" == "" ]; then
  echo "A matching public IP address for peer node not found."
  exit 1
fi


if [ "${PEER_MODE}" == "0" ]; then
  privateAddress=${privateAddressMain}
else
  privateAddress=${privateAddressPeer}
fi

publicAddress=$(aws ec2 describe-network-interfaces | jq -r '.NetworkInterfaces | .[] | select(.PrivateIpAddress=="'"${privateAddress}"'") | .PrivateIpAddresses | .[] | .Association.PublicIp ')

echo "$publicAddress"
exit 0
