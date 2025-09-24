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

## Test Assumptions

1. Make a few calls to the `/test` endpoint and check to see if the absolute increase of the `test_requests_total` counter over last hour matches that number regardless of the app/container restarts.

* make 3 calls to the app's `/test` endpoint
* head over to the app's `/metrics` endpoint and see the `test_requests_total` counter value equals `3`:
```
test_requests_total{url="http://localhost:9292/test",cache="false",http_status_code="200"} 3.0
```
* open up [Prometheus Query page](http://localhost:9090/query) and type in the PromQL query:
```
increase(test_requests_total[1h])
```
* click the `Execute` button and see the following output:
```
{cache="false", http_status_code="200", instance="app:9292", job="rack-app", url="http://localhost:9292/test"}	3.036697247706421
```
* stop containers
* run `docker compose up` again
* head over to the app's `/metrics` endpoint and see the `test_requests_total` counter value is missing
* make 2 calls to the app's `/test` endpoint
* open up the app's `/metrics` endpoint and see the `test_requests_total` counter value equals `2`:
```
test_requests_total{url="http://localhost:9292/test",cache="false",http_status_code="200"} 2.0
```
* open up [Prometheus Query page](http://localhost:9090/query), type in the same PromQL query as before and click `Execute`
* see that the output now equals around `5`:
```
{cache="false", http_status_code="200", instance="app:9292", job="rack-app", url="http://localhost:9292/test"}  5.023649883011872
```

For a counter the absolute value has no real meaning. It is how it changes which is important.
The counter might reset to zero at any point, so one should be looking at the `increase()`,
which tells us how much the counter has increased by over a period of time.

`rate()`, `irate()`, `increase()` functions only work for counter metrics,
since they treat any value decrease as a counter reset and can only output non-negative results.

2. Making 2 calls to the `/test` endpoint within a minute shows the `test_requests_total` counter value increased by `2` in the `/metrics` endpoint.

And Prometheus counts both calls when making the following PromQL query:
```
increase(test_requests_total[24h])
```

but the same query with a `1h` (or e.g. `6h`) range:
```
increase(test_requests_total[1h])
```

outputs the value around `1`:
```
{cache="false", http_status_code="200", instance="app:9292", job="rack-app", url="http://localhost:9292/test"}	1.051789703159926
```

3. TODO: Test the difference between `$__range`, `$__interval`, `$__rate_interval` and `$__range_interval` global built-in variables on Grafana dashboards.

## Helpful Links

* https://prometheus.io/docs/prometheus/latest/querying/basics/
* https://prometheus.io/docs/prometheus/latest/querying/examples/
* https://promlabs.com/promql-cheat-sheet/
* https://training.promlabs.com/training/understanding-promql/basic-querying/gauge-derivatives-and-predictions/
* https://valyala.medium.com/promql-tutorial-for-beginners-9ab455142085
* https://www.dash0.com/documentation/dash0/metrics/promql-query-patterns#calculating-total-count-over-time-range-5m
