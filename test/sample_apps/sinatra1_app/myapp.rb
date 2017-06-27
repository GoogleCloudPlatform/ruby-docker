require 'sinatra'
require "sinatra/multi_route"
require 'stackdriver'
require "google/cloud/monitoring/v3"
require 'open3'

# Grab project_id from gcloud sdk
project_id = ENV["GOOGLE_CLOUD_PROJECT"]
fail "ENV GOOGLE_CLOUD_PROJECT missing." unless project_id
# service_name = "sinatra_sample_app"
# serivce_version = ENV['USER']

#######################################
# Setup ErrorReporting Middleware
use Google::Cloud::ErrorReporting::Middleware

#######################################
# Setup Logging Middleware
use Google::Cloud::Logging::Middleware

#######################################
# Setup Trace Middleware
use Google::Cloud::Trace::Middleware

#######################################
# Setup Monitoring
monitoring = Google::Cloud::Monitoring::V3::MetricServiceClient.new


set :environment, :production
set :bind, "0.0.0.0"
set :port, 8080
set :show_exceptions, true

get '/' do
  "Hello World!"
end

get '/system' do
  ENV.inspect
end

get '/_ah/health' do
  "Success"
end

route :get, :post, '/exception' do
  begin
    fail "Test error from sinatra app"
  rescue => e
    Google::Cloud::ErrorReporting.report e
  end
  "Error submitted."
end

route :get, :post, '/logging_standard' do
  request.body.rewind
  request_payload = JSON.parse request.body.read

  token = request_payload["token"]
  level = request_payload["level"].to_sym

  logger.add level, token
  "Log entry submitted"
end

route :get, :post, "/logging_custom" do
  request.body.rewind
  request_payload = JSON.parse request.body.read

  token = request_payload["token"]
  level = request_payload["level"].to_sym
  log_name = request_payload["log_name"]

  logging = Google::Cloud::Logging.new
  resource = Google::Cloud::Logging::Middleware.build_monitored_resource

  entry = logging.entry.tap do |e|
    e.payload = token
    e.log_name = log_name
    e.severity = level
    e.resource = resource
  end

  logging.write_entries entry
end

route :get, :post, '/monitoring' do
  request.body.rewind
  request_payload = JSON.parse request.body.read

  token = request_payload["token"]
  name = request_payload["name"]

  time_series_hash = {
      metric: {
        type: "custom.googleapis.com/#{name}"
      },
      resource: {
        type: "global"
      },
      points: [{
        interval: {
          endTime: {
            seconds: Time.now.to_i,
            nanos: Time.now.nsec
          }
        },
        value: {
          int64_value: token
        }
      }]
    }
  time_series = Google::Monitoring::V3::TimeSeries.decode_json time_series_hash.to_json

  p time_series

  monitoring.create_time_series "projects/#{project_id}", [time_series]

  "Time series submitted."
end



