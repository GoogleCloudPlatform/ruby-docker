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
  "ruby app"
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

route :get, :post, '/log' do
  logger.info {{log_key: "Test log from sinatra app"}}
  "Log entry submitted"
end

route :get, :post, '/monitoring' do
  time_series_hash = {
      metric: {
        type: "custom.googleapis.com/samples/sinatra1"
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
          double_value: 123.45
        }
      }]
    }
  time_series = Google::Monitoring::V3::TimeSeries.decode_json time_series_hash.to_json

  monitoring.create_time_series "projects/#{project_id}", [time_series]

  "Time series submitted."
end



