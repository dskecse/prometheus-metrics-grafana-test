# frozen_string_literal: true

require "rack"
require "singleton"
require "forwardable"

require "prometheus/middleware/collector"
require "prometheus/middleware/exporter"

use Rack::Deflater
use Prometheus::Middleware::Collector
use Prometheus::Middleware::Exporter

Registry = Prometheus::Client.registry

class Application
  def initialize
    test_requests_total
  end

  def call(env)
    req = Rack::Request.new(env)
    case req.path_info
    when %r{\A/test}
      test_requests_total.increment(labels: { url: req.url, cache: false, http_status_code: 200 })
      [200, { "Content-Type" => "text/html" }, ["OK"]]
    else
      [404, { "Content-Type" => "text/html" }, ["Not Found: #{req.path_info}"]]
    end
  end

  private

  def test_requests_total
    @test_requests_total ||= Registry.counter(
      :test_requests_total,
      docstring: "The total number of test requests.",
      labels: %i(url cache http_status_code)
    )
  end
end

run Application.new
