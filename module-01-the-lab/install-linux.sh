#!/usr/bin/env bash
# The four tools, for Linux and for Windows inside WSL.
#
#   curl -fsSL https://raw.githubusercontent.com/ronidas39/aiops-with-python/main/module-01-the-lab/install-linux.sh | bash
#
# ⛔ ONLY TWO OF THESE FOUR ARE IN THE NORMAL UBUNTU PACKAGES. `kubernetes-cli` is a
# Homebrew-only name, and neither eksctl nor helm is in apt, so the rest come from upstream.
# This exists as a script because the commands are long, and a long command printed on a page
# wraps, and the wrap arrives in the shell as a real newline. That cost three recording takes.
set -euo pipefail

sudo apt-get update
sudo apt-get install -y unzip curl git make python3

if ! command -v aws >/dev/null; then
  curl -fsSL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/aws.zip
  unzip -q -o /tmp/aws.zip -d /tmp && sudo /tmp/aws/install --update
fi

command -v helm >/dev/null || curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

if ! command -v eksctl >/dev/null; then
  curl -fsSL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" \
    | sudo tar xz -C /usr/local/bin
fi

if ! command -v kubectl >/dev/null; then
  curl -fsSLO "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  sudo install kubectl /usr/local/bin/ && rm -f kubectl
fi

echo
for t in aws eksctl kubectl helm git python3 make; do
  printf "  %-9s %s\n" "$t" "$(command -v "$t" || echo 'NOT FOUND')"
done
