#!/usr/bin/env bash
# Delete the log group an EKS cluster can leave behind, and say plainly when there isn't one.
#
#   ./bin/cleanlogs.sh          # or: make cleanlogs
#
# ⛔ "NOTHING TO DELETE" IS THE EXPECTED ANSWER FOR THIS LAB. Control plane logging is switched
# off in eks/cluster.yaml, so the group is never created. The bare `aws logs delete-log-group`
# exits 254 with ResourceNotFoundException, make reports "Error 254", and it looks on camera
# like the lab is broken when in fact everything is correct.
set -uo pipefail
export AWS_PAGER=""

REGION="${AWS_REGION:-us-east-1}"
GROUP="${GROUP:-/aws/eks/aiops-lab/cluster}"

found=$(aws logs describe-log-groups --region "$REGION" \
          --log-group-name-prefix "$GROUP" \
          --query 'length(logGroups)' --output text 2>/dev/null || echo 0)

if [ "$found" = "0" ] || [ -z "$found" ]; then
  echo "  No log group called $GROUP in $REGION."
  echo "  That is the right answer for this lab: control plane logging is off in cluster.yaml,"
  echo "  so the cluster never created one. Nothing to clean up, and nothing is billing."
  exit 0
fi

echo "  Found it. Deleting $GROUP in $REGION."
aws logs delete-log-group --region "$REGION" --log-group-name "$GROUP"
echo "  Deleted. That one survives eksctl delete cluster, so it is worth knowing about."
