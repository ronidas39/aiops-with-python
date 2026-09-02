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
| EKS control plane | $0.10/hr |
| one `m6i.2xlarge` node | $0.3872/hr |
| **while it is running** | **~$0.48/hr** |
| **if you forget it for a day** | **~$11.50** |

The whole course costs two or three dollars if you run `make down` when you stop.

## Before you start

You need an AWS account, and these four on your machine:

    aws --version        # AWS CLI v2
    eksctl version
    kubectl version --client
    helm version

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
