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
* instruct Prometheus to scrape metrics from itself every 15 seconds
* spin up a [Rack app on port `9292`](http://localhost:9292/)
* expose a `/metrics` endpoint on the Rack app to be scraped by Prometheus
* register a `test_requests_total` counter metric with Prometheus
* increment a newly created counter metric on `http://localhost:9292/test` requests
* instruct Prometheus to scrape metrics from the Rack app every 15 seconds.

## Connect Grafana to Prometheus

To visualize Prometheus metrics in Grafana, the 1st step is to establish a connection between the two.
This involves configuring Prometheus as a data source:

* open up Grafana's [Add new data source](http://localhost:3000/connections/datasources/new) page
* choose Prometheus from the list
* enter the `Prometheus server URL`: `http://prometheus:9090`
* and click `Save & Test` to verify the connection.
