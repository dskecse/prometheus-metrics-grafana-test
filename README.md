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

It also involves building a dashboard to display meaningful insights:

* head over to Grafana's [New dashboard](http://localhost:3000/dashboard/new) page
* click the `Add visualization` button
* select `Prometheus` from the data source dropdown
* choose `Stat` as a visualization type
* type in `Test requests count over time range` as a title
* choose `Last *` as a calculation
* optionally set `Decimals` to `0` to display floating-point numbers as integers
* inside the `Queries -> Metrics browser` type in the following query:
```
increase(test_requests_total[$__range])
```
* click `Save dashboard`
* experiment with setting different time ranges on the Grafana UI, e.g. `Last 3 hours`, `Last 24 hours`.

NOTE: Grafana will show up the number of increases of the counter metric over a specified time range.
If you see a decreasing graph somewhere on the stat visualization then be aware these values won't be counted.

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

3. Test the difference between `$__range`, `$__interval`, `$__rate_interval` and `$__range_interval` global built-in variables on Grafana dashboards.

* https://grafana.com/docs/grafana/latest/dashboards/variables/add-template-variables/#global-variables

1. `$__interval` variable is calculated using the time range and the width of the graph (the number of pixels).
Approximate calculation: `(to - from) / resolution`.
2. `$__range` variable represents the range for the current dashboard. It is calculated as `to - from`.
It is represented in seconds.
3. `$__rate_interval` variable is meant to be used in the `rate` function, see below.
4. `$__range_interval` variable seems to be missing from Grafana docs.

Example values for the same Grafana dashboard:

* `$__rate_interval`: `60` (seconds, basically `4 * scrape_interval` or `4 * 15s`)
* `$__interval`: `30`
* `$__range`: `21600` (when the time range on Grafana UI is `Last 6 hours`)
* `$__range_interval`: `21600s_` (when the time range is as above)

* https://grafana.com/docs/grafana/latest/datasources/prometheus/template-variables/#use-interval-and-range-variables
* https://grafana.com/docs/grafana/latest/datasources/prometheus/template-variables/#use-__rate_interval

> Grafana recommends using `$__rate_interval` with the `rate` and `increase` functions
> instead of `$__interval` or a fixed interval value. Since `$__rate_interval` is always
> at least four times the scrape interval, it helps avoid issues specific to Prometheus,
> such as gaps or inaccuracies in query results.

For example, instead of using the following:

```
rate(http_requests_total[5m])
```

or:

```
rate(http_requests_total[$__interval])
```

Use the following:

```
rate(http_requests_total[$__rate_interval])
```

The value of `$__rate_interval` is calculated as:

```
max($__interval + scrape_interval, 4 * scrape_interval)
```

> Here, `scrape_interval` refers to the `min step` setting (also known as `query_interval`)
> specified per PromQL query, if set. If not, Grafana falls back to the Prometheus data source's
> scrape interval setting (usually `15s`).

* https://grafana.com/blog/2020/09/28/new-in-grafana-7.2-__rate_interval-for-prometheus-rate-queries-that-just-work/

## Helpful Links

* https://prometheus.io/docs/prometheus/latest/querying/basics/
* https://prometheus.io/docs/prometheus/latest/querying/examples/
* https://promlabs.com/promql-cheat-sheet/
* https://training.promlabs.com/training/understanding-promql/basic-querying/gauge-derivatives-and-predictions/
* https://valyala.medium.com/promql-tutorial-for-beginners-9ab455142085
* https://www.dash0.com/documentation/dash0/metrics/promql-query-patterns#calculating-total-count-over-time-range-5m
