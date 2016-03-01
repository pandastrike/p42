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

```
$ npm install -g p42
```

### Creating A Cluster

#### Create A Docker Host

```
$ p42 cluster host
```

#### Create A Cluster

This will give you a cluster with a single (master) node.

```
$ p42 cluster create
```

#### Add Nodes To The Cluster

To add 3 nodes to your cluster:

```
$ p42 cluster add --size 3
```

To add just one:

```
$ p42 cluster add
```

#### Using Docker Commands

If you want to use Docker commands directly:

```
$ eval $(p42 cluster env)
```

which will select the Swarm master, if possible, or the default machine otherwise.

#### Examining Your Cluster

```
p42 cluster ls
```

### Running An App

#### Initialize Your App

```
$ p42 init
Application name [blurb9]:
Organization repository [pandastrike]:
```

#### Add Mixins

Provide the git cloneable URL for the mixin repo:

```
$ p42 mixin add git@github.com:pandastrike/p42-mixin-nginx.git
Document root [www]:
```

#### Run Your App

The `run` command will build and run all the images described in your `launch` directory.

```
$ p42 run
```

## Example

Let's build a simple Web page and deploy it using `p42`.

We'll assume we've already run a cluster (see [Creating A Cluster](#creating-a-cluster)).

Let's create an application directory and initialize it.

```
$ mkdir hello-world
$ cd hello-world
$ p42 init
Application name [hello-world]:
Organization repository []: pandastrike
```

Add the Nginx mixin.

```
$ p42 mixin add git@github.com:pandastrike/p42-mixin-nginx.git
Document root [www]:
```

This will create a `launch/www` directory that includes a `Dockerfile` for running Nginx.

Create an index HTML file.

```
$ mkdir www
$ cat >> www/index.html
<h1>Hello, World!</h1>
```

Run your application.

```
$ p42 run
```

This will take a minute to build and run the image described by `launch/www/Dockerfile`.

Get the IP and port of your Nginx container.

```
$ p42 ps
swarm-01/hello-world-www 159.203.247.225:32769->80/tcp, 159.203.247.225:32768->443/tcp
$ curl 159.203.247.225:32769
<h1>Hello, World!</h1>
```

## Autocomplete

You can add autocomplete to your shell by running:

```
$ eval $(p42 env -)
```

## Status

`p42` is under heavy development.

## Reference

Run `p42 help` to get a list of commands and what they do.
