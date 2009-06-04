$:.unshift *Dir[File.dirname(__FILE__) + "/vendor/*/lib"]

require 'sinatra/base'
require 'rack-flash'
require 'logger'
require 'em-http'
require 'memcache'

require File.join(File.dirname(__FILE__), *%w[lib user])

class Thunder < Sinatra::Default
  set :app_file, __FILE__
  set :static, true
  enable :sessions

  use Rack::Flash

  def check_user(user)
    if user.exists?
      @repos = user.repos
      @repos ? erb(:show) : erb(:loading)
    else
      flash[:error] = params[:username]
      redirect '/'
    end
  end

  get '/' do
    status(404) if flash.has?(:error)
    erb :index
  end

  get '/user' do
    if params[:username].empty?
      flash[:invalid] = "invalid"
      redirect '/'
    end

    redirect "/~#{params[:username]}"
  end

  get '/ping/~:username' do
    @user = User.get(params[:username])
    @user.loaded? ? "/~#{@user.name}" : ''
  end

  get '/~:username?' do
    @user = User.get(params[:username])
    return erb(:loading) unless @user.loaded?

    @repos = @user.repos
    etag @user.etag
    erb :show
  end
end
