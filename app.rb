require "rubygems"

require 'gmail'
require 'sinatra'
require "sinatra/base"
require "sinatra/config_file"
require 'redis'
require 'json'

class App < Sinatra::Base

 register Sinatra::ConfigFile

  # Configuration
  #username   = ENV["GMAIL_USERNAME"]
  #password   = ENV["GMAIL_PASSWORD"]

  config_file 'config.yml'

  expiration = 60 * 5; # 5 minutes

  redis = Redis.new

  get '/' do

    if !redis[:unread_count] || !redis[:email_count]

      gmail = Gmail.new(username, password) 

      redis[:email_count]  = gmail.inbox.count
      redis[:unread_count] = gmail.inbox.count(:unread)

      redis.expire("read_count",   expiration)
      redis.expire("unread_count", expiration)

    end

    email_count  = redis[:email_count].to_i
    unread_count = redis[:unread_count].to_i

    points = (email_count - unread_count) + unread_count * 2

    if points > 9
      status = "red"
    elsif points > 3
      status = "yellow"
    else
      status = "green"
    end

    content_type :json
    { :status => status, :points => points, :total => email_count, :unread => unread_count }.to_json

  end

  get '/reset' do
    redis.DEL("email_count")
    redis.DEL("unread_count")

    redirect "/"
  end

end
