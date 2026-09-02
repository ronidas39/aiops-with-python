# Module 1. The lab, and breaking something on purpose

Everything typed in the module 1 video is here. Clone it once and follow along.

## What you end up with

- A real Kubernetes cluster on AWS, one node, built with one command
- A real system running on it: 19 services in 12 languages, that you did not write
- Metrics, traces and logs from all of it, in one place
- A memory leak you switch on yourself, and a pod killed by it

## What it costs

**About $0.48 an hour** in `us-east-1`, measured 2026-09-01.

| | |
|---|---|
| EKS control plane | $0.10/hr, on a version in **standard** support |
| one `m6i.2xlarge` node | $0.3872/hr |
| **while it is running** | **~$0.48/hr** |
| **if you forget it for a day** | **~$11.50** |

The whole course costs about five dollars if you run `make down` when you stop.

⛔ **Run a Kubernetes version that is still in standard support.** A version in *extended*
support bills the control plane at six times the rate, and `eksctl` will not warn you. Check
with `aws eks describe-cluster-versions --region us-east-1`.

## Before you start

You need an AWS account **with a payment method on it**, and seven things on your machine.

⛔ **If your AWS account is new, do not create access keys for the root login.** Open IAM,
create a user, attach the `AdministratorAccess` policy, and make the key for that user. That
is fine for a learning account and it is not fine at work.

### Install, on a Mac

    brew install awscli eksctl kubernetes-cli helm

### Install, on Linux or on Windows inside WSL

⛔ **Only two of these four are in the normal Ubuntu packages.** `kubernetes-cli` is a
Homebrew-only name, and neither `eksctl` nor `helm` is in apt. The rest come from upstream.

    sudo apt update && sudo apt install -y unzip curl git make python3

    # AWS CLI v2
    curl -fsSL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o aws.zip \
      && unzip -q aws.zip && sudo ./aws/install

    # helm
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

    # eksctl
    curl -fsSL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" \
      | sudo tar xz -C /usr/local/bin

    # kubectl
    curl -fsSLO "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
      && sudo install kubectl /usr/local/bin/

⛔ **On Windows use WSL, not Git Bash.** Git Bash has no `make`, and every command here goes
through the Makefile.

### Then check all of them:

    export AWS_PAGER=""  # or the AWS CLI opens a pager and waits for a keypress

    aws --version        # AWS CLI v2
    eksctl version       # ⛔ 0.201.0 or newer, or metrics-server is not installed
    kubectl version --client
    helm version
    git --version
    python3 --version    # bin/fault.sh needs it
    make --version

    aws configure                                        # region: us-east-1
    aws sts get-caller-identity --query Arn --output text # should print an ARN

⛔ **An ARN only proves AWS knows who you are, not that you are allowed to do anything.** If
`make up` fails after fifteen minutes with `AccessDenied`, that is permissions, not the key.

### Put a budget on it before you start

    aws budgets create-budget --account-id "$(aws sts get-caller-identity --query Account --output text)" \
      --budget '{"BudgetName":"aiops-course","BudgetLimit":{"Amount":"20","Unit":"USD"},"TimeUnit":"MONTHLY","BudgetType":"COST"}'

It does not stop anything. It makes a forgotten cluster a number you notice.

A brand new AWS account often has a low CPU quota. If `make up` stops with
`VcpuLimitExceeded`, ask AWS for an increase on "Running On-Demand Standard instances" and
come back. It is free and it usually takes a few hours.

## The whole module, in six commands

    make up          # about 15 to 20 minutes. Builds the cluster.
    make demo        # about 3 minutes. Installs 30 pods.
    make grafana     # opens a tunnel, then http://localhost:8080/grafana/
    make leak        # switches the memory leak on
    make heal        # switches it off again
    make down        # ⛔ DO THIS. Every time you stop.

Then, once, after `make down`:

    make leftovers   # checks nothing was left behind billing you

## What is in here

| Path | What it is |
|---|---|
| `eks/cluster.yaml` | the cluster. One node, `m6i.2xlarge`, public subnets |
| `Makefile` | every command in the video |
| `bin/fault.sh` | turn one of the demo's built-in faults on or off |
| `bin/faults.sh` | list all 15 faults and what each can be set to |
| `bin/leftovers.sh` | find AWS resources left behind after a delete |

## Why one node

The whole stack, including the language model that arrives in module 6, used **17.5 GiB**.
A second node was paying for nothing. It has to be an eight CPU box, and that is about CPU,
not memory: the model needs seven cores while it is answering.

## Why public subnets

A private setup needs a NAT gateway. That is about **$32 a month** whether you use it or not,
and it teaches you nothing that this course is about. Real production clusters are private.
This one is a lab.

## The faults

The OpenTelemetry Demo ships 15 of them. `make faults` prints the live list. The one this
module uses:

    ./bin/fault.sh emailMemoryLeak 10000x    # OOMKilled in about 70 seconds
    ./bin/fault.sh emailMemoryLeak 100x      # climbs 44 -> 81 MiB over 35 minutes
    ./bin/fault.sh emailMemoryLeak off

⛔ **The variants are `off, 1x, 10x, 100x, 1000x, 10000x`.** They are not `on` and `off`.
Setting a variant name that does not exist is accepted without any error and quietly does
nothing. `bin/fault.sh` checks the name against the flag's own list before writing, because
that mistake cost me twenty two minutes of watching a completely flat memory graph.

## Numbers measured on this exact setup

Recorded 2026-09-01 in `us-east-1`, so you can tell whether yours is behaving.

| | |
|---|---|
| cluster build | about 15 to 20 minutes |
| Kubernetes version | 1.36, in standard support until 2027-08-02 |
| `helm install` | 185 seconds |
| pods running | 30 |
| memory, once quiet | 5.4 GiB |
| CPU, once quiet | 12% of the node |
| CPU **during** the install | 66%, and it means nothing |
| email pod request and limit | 100Mi and 100Mi |
| first OOMKill at 10000x | 69 seconds |
| second OOMKill | by 99 seconds |

⛔ **Never size a cluster from a reading you took while it was still starting.** The 66% above
is thirty containers all booting at the same time. Two minutes later it was 12%. I nearly
doubled the cluster over that number.
