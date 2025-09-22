# frozen_string_literal: true

require "rack"
require "singleton"
require "forwardable"

require "prometheus/middleware/collector"
require "prometheus/middleware/exporter"

use Rack::Deflater
use Prometheus::Middleware::Collector
use Prometheus::Middleware::Exporter

class Application
  class Metrics
    include Singleton

    class << self
      extend Forwardable

      def_delegators :instance, :register_all
    end

    def register_all
      test_requests_total
    end

    private

    Registry = Prometheus::Client.registry

    def test_requests_total
      @test_requests_total ||= Registry.counter(
        :test_requests_total,
        docstring: 'The total number of test requests.',
        labels: %i(
          url
          cache
          http_status_code
        )
      )
    end
  end

  def call(env)
    ["200", { "Content-Type" => "text/html" }, ["OK"]]
  end
end

Application::Metrics.register_all

run Application.new
