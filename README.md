# prometheus-metrics-grafana-test

## Prerequisites

* git
* Docker Desktop / OrbStack

## Setup

```sh
git clone https://github.com/dskecse/prometheus-metrics-grafana-test
cd $_
cp .env.example .env
docker compose up
```

This will:

* clone the repo
* `cd` into the repo dir
* create `.env` file from `.env.example`
  * NOTE: Make sure to replace placeholder values
* pull up official Prometheus and Grafana Docker images and build containers
* spin up [Prometheus on port `9090`](http://localhost:9090/)
* spin up [Grafana on port `3000`](http://localhost:3000/)
  * use `admin` user and a specified password to log in
* instruct Prometheus to scrape metrics from itself every 15 seconds.
