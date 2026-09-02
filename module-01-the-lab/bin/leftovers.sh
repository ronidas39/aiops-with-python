#!/usr/bin/env bash
# Run this AFTER `make down`. Deleting a cluster does not always take everything with it,
# and a load balancer or an unattached disk keeps billing quietly for months.
set -euo pipefail
# ⛔ REGION IS EXPLICIT. Without it these read whatever your default region is, which is not
# necessarily where the lab ran, and the check quietly passes while the leftovers bill on.
: "${AWS_REGION:=us-east-1}"
export AWS_PAGER=""

# ⛔ TWO KINDS OF LOAD BALANCER. `elbv2` covers ALB and NLB. A Service of type LoadBalancer on
# EKS can still create a CLASSIC one, and `elbv2` cannot see it at all.
echo "load balancers : $(aws elbv2 describe-load-balancers --region "$AWS_REGION" --query 'length(LoadBalancers)')"
echo "classic ELBs   : $(aws elb describe-load-balancers --region "$AWS_REGION" --query 'length(LoadBalancerDescriptions)')"
echo "eks log groups : $(aws logs describe-log-groups --region "$AWS_REGION" --log-group-name-prefix /aws/eks/ --query 'length(logGroups)')"
echo "unused disks   : $(aws ec2 describe-volumes --region "$AWS_REGION" --filters Name=status,Values=available --query 'length(Volumes)')"
echo "unused IPs     : $(aws ec2 describe-addresses --region "$AWS_REGION" --query "length(Addresses[?AssociationId==null])")"
echo
echo "⛔ These are ACCOUNT-WIDE counts for $AWS_REGION, not just this lab. If you already had"
echo "   a load balancer or an elastic IP before you started, it shows up here too. What you"
echo "   are looking for is a number that CHANGED after you ran make down."
echo
echo "   An /aws/eks/ log group survives eksctl delete cluster and keeps billing. Delete it:"
echo "     aws logs delete-log-group --region $AWS_REGION --log-group-name /aws/eks/aiops-lab/cluster"
