class HomeController < ApplicationController

  def index
    unless Rails.env == "production"
      raise "Wrong Rails environment: #{Rails.env}"
    end
    render :text => "ruby app"
  end

end
