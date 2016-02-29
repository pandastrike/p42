# p42

A CLI for simplifying the use of Docker.

## Getting Started

### Prerequites

- Bash version 3 or later
- Docker version 1.10
- Docker Machine version 0.6
- Node version 4 or later
- NPM version 2 or later
- `yaml` (via `npm install yaml -g`) version 1 or later

### Installation

To install into `/usr/local/p42`:

```
$ curl -L https://github.com/pandastrike/p42/archive/master.tar.gz |\
    tar -xvs /p42-master/p42/ -C /usr/local
```

For bash users:

```bash
echo 'eval "$(/usr/local/bin/p42/bin env -)"' >> ~/.bash_profile
exec bash
```
For zsh users:

```zsh
echo 'eval "$(/usr/local/bin/p42/bin env -)"' >> ~/.zshenv
source ~/.zshenv
```

### Creating A Cluster

#### Create A Docker Host

```bash
$ p42 cluster host
```

#### Create A Cluster

This will give you a cluster with a single (master) node.

```bash
$ p42 cluster create
```

#### Add Nodes To The Cluster

To add 3 nodes to your cluster:

```bash
$ p42 cluster add --size 3
```

To add just one:

```bash
$ p42 cluster add
```

#### Using Docker Commands

If you want to use Docker commands directly:

```bash
$ eval $(p42 cluster env)
```

which will select the Swarm master, if possible, or the default machine otherwise.

#### Examining Your Cluster

```bash
p42 cluster ls
```

### Running An App

## Status

`p42` is under heavy development.
