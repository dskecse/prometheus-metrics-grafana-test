# frozen_string_literal: true

threads 1, 5
port ENV.fetch("PORT")
environment ENV.fetch("RACK_ENV")
