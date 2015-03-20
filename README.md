# Realtime Metrics Docker Container

## Introduction

This is a simple container for quickly spinning up a collector and dashboard display for realtime stats.

The version of Graphite included in this container has been modified to capture and display data at 1 second resolution. Stock Graphite only supports 1 minute resolution or higher. This is very handy for measuring tests using [Storyplayer](https://datasift.github.io/storyplayer/) and [SavageD](https://github.com/ganbarodigital/SavageD).

See [Stuart's blog post on realtime graphing with Graphite](http://blog.stuartherbert.com/php/2011/09/21/real-time-graphing-with-graphite/) for more details.

This container is based on [Kamon's container](https://github.com/kamon-io/docker-grafana-graphite). Check our their container if you want Graphite but don't need realtime stats!

## Includes

* Grafana for nice-looking dashboards on port 80
* Graphite's webapp on port 81
* statsd collector on port 8125/udp

## How To Use

We assume that you already have a working Docker setup installed locally.

To build the container, run:

    ./build.sh

Once the container has been built, to start it, run:

    ./run.sh

## License

See [LICENSE.md](LICENSE.md) for details.