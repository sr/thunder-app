$:.unshift *Dir[File.dirname(__FILE__) + "/vendor/*/lib"]

require 'sinatra/base'
require 'open-uri'
require 'net/http'
require 'rack-flash'
require 'activerecord'
require 'delayed_job'
require 'memcache'
require File.join(File.dirname(__FILE__), *%w[lib user])

class ThrottledError < StandardError ; end

class Thunder < Sinatra::Default
  set :root, File.dirname(__FILE__)
  set :static, true
  set :public, File.join(root, 'public')
  enable :sessions

  use Rack::Flash

  configure do
    config = YAML::load(File.open('config/database.yml'))
    environment = Sinatra::Application.environment.to_s
    ActiveRecord::Base.logger = Logger.new($stdout)
    ActiveRecord::Base.establish_connection(
      config[environment]
    )
  end

  helpers do
    def check_user(user)
      if user.exists?
        @repos = user.repos
        @repos ? erb(:show) : erb(:loading)
      else
        flash[:error] = params[:username]
        redirect '/'
      end
    end
  end

  get '/' do
    erb :index
  end

  get '/user' do
    redirect "/~#{params[:username]}"
  end

  get '/~:username' do
    @user = User.get(params[:username])

    return erb(:loading) unless @user.loaded?

    begin
      @repos = @user.repos(params[:sort] || 'watchers')
      erb(:show)
    rescue ThrottledError
      erb :throttled
    rescue Exception => err
      check_user(@user)
    end
  end
end
