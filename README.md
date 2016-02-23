# p42

A CLI for simplifying the use of Docker. Probably a precursor to a Huxley reboot.

## Reference

### start

The `start` subcommand provisions a Docker host that can be used to create the cluster.

### cluster

The `cluster` subcommand allows you to create a cluster and add nodes.

```
$ p42 cluster create
Generating token...
Creating Swarm Master...
```

Once that completes, you should see the swarm master:

```
$ docker-machine ls
NAME       ACTIVE   DRIVER         STATE     URL                          SWARM               DOCKER    ERRORS
default    -        digitalocean   Running   tcp://162.243.156.65:2376                        v1.10.1
swarm-00   -        digitalocean   Running   tcp://192.241.198.149:2376   swarm-00 (master)   v1.10.2
```

Next, you can add nodes to the cluster.

```
$ p42 cluster add
Adding Node to Swarm...
Creating machine [swarm-01]...
```

## Status

`p42` is under heavy development and is very likely to change, be replaced, or any number of other horrible fates.

I'm considering moving the `start` command under the `cluster` command. I'd also like to add more cluster-related commands so you don't have to fall back quite as much to the `docker` commands.
