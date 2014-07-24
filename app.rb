require "rubygems"

require 'gmail'
require 'sinatra'
require "sinatra/base"
require "sinatra/config_file"
require 'redis'
require 'json'

class App < Sinatra::Base

 register Sinatra::ConfigFile

  config_file 'config.yml'

  expiration = 60 * 5; # 5 minutes

  redis = Redis.new

  def calculate_status(points)

    return "red"    if points > 9
    return "yellow" if points > 3
    return "green"

  end

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

    status = calculate_status(points)

    content_type :json
    { :status => status, :points => points, :total => email_count, :unread => unread_count }.to_json

  end

  get '/reset' do
    redis.DEL("email_count")
    redis.DEL("unread_count")

    redirect "/"
  end

end
