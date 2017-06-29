require 'sinatra'
require "sinatra/multi_route"
require 'stackdriver'
require "google/cloud/monitoring/v3"
require 'open3'

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
