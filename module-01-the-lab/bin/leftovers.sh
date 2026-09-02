#!/usr/bin/env bash
# Run this AFTER `make down`. Deleting a cluster does not always take everything with it,
# and a load balancer or an unattached disk keeps billing quietly for months.
set -euo pipefail
echo "load balancers : $(aws elbv2 describe-load-balancers --query 'length(LoadBalancers)')"
echo "unused disks   : $(aws ec2 describe-volumes --filters Name=status,Values=available --query 'length(Volumes)')"
echo "unused IPs     : $(aws ec2 describe-addresses --query "length(Addresses[?AssociationId==null])")"
echo
echo "All three should be 0. Anything else is costing you money for nothing."
