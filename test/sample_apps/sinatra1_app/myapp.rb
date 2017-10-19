require 'sinatra'

set :environment, :production
set :bind, "0.0.0.0"
set :port, 8080
set :show_exceptions, true

get '/' do
  "Hello World!"
end
