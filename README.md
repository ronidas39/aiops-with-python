# AIOps with Python

Build a working AIOps platform, one layer at a time, with Python.

This is the code for the freeCodeCamp course of the same name. Ten modules, about seven
hours. Every module writes code except module zero, and every module leaves behind a piece
the next one needs.

## What you build

By the end you have a platform with six layers:

| Layer | What it does |
|---|---|
| Signal | Collects the metrics, the logs and the traces |
| Detect | Works out what is not normal |
| Correlate | Turns thousands of alerts into one incident |
| Explain | Says which change caused it, and shows the evidence |
| Act | Applies the fix, inside rules that you wrote |
| The map | Knows what depends on what, and feeds the three layers above |

The map is the layer that makes it a platform. Without it the other five are five separate
scripts that happen to run next to each other.

## What you operate

You do not build the application. You operate the OpenTelemetry Demo, which is the reference
system maintained by the OpenTelemetry project: nineteen services written in twelve languages,
talking to each other over gRPC. None of it is code you wrote.

That is on purpose. In a real job you are handed systems other people built, in languages you
do not use, and asked to keep them running. A course where the instructor also wrote the
application teaches the easy version of the problem.

## What it costs

The lab runs on Amazon EKS. Two m6i.2xlarge nodes and the EKS control plane come to roughly
eighty seven cents an hour at the time of writing. A forty minute module costs about sixty
cents, and the whole course costs four to six dollars.

Modules two, three and four are Python against data that is already in this repository, so
they run on a laptop with no cluster at all.

Every module has a `make down`. Use it. An EKS cluster you forget about costs about twenty one
dollars a day.

## How this repository is arranged

One folder per module. Inside each one:

    README.md      what the module does, what you need first, what it costs, how to tear it down
    terraform/     the cluster, the node group, the database, the permissions
    k8s/           the manifests
    starter/       where you begin
    final/         where you should end up
    data/          exported snapshots, so every step still works with no cluster running

If a step will not run for you, open `final/` and compare. The saved data is in there too, so
you are never blocked by an expired account or a service that has moved on.

## What you need before you start

Python, a terminal, an AWS account, and about sixteen gigabytes of memory if you want to run
the laptop-only modules locally. No API key is needed at any point. Every model in this course
runs locally through Ollama.

## Licence

MIT. Use it, change it, ship it.
