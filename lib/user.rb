require 'yaml'
require 'ostruct'

class User
  def self.cache
    @@cache ||= if MemCache.respond_to?(:cache)
      MemCache.cache
    else
      MemCache.new("0.0.0.0:11211")
    end
  end

  def self.get(username)
    new(username)
  end

  attr_accessor :name

  def initialize(name)
    @name = name

    EM.next_tick { load_data }
  end

  def loaded?
    etag && body
  end

  def exists?
    true # TODO
  end

  def etag
    User.cache.get(name)
  end

  def body
    User.cache.get(etag)
  end

  def yaml
    @yaml ||= loaded? ? YAML.load(body) : {}
  end

  def repos
    @repos ||= begin
       yaml['repositories'] \
        .map     { |repo| OpenStruct.new(repo)  } \
        .reject  { |repo| repo.fork }
    end
  end

  private

  def load_data
    uri     = "http://github.com/api/v2/yaml/repos/show/#{name}"
    etag    = User.cache.get(name)
    headers = etag ? {"If-None-Match" => etag} : {}

    puts "** Fetching repo data for #{name}"
    http = EventMachine::HttpRequest.new(uri).get(:head => headers)
    http.callback {
      next unless [302, 200].include?(http.response_header.status)

      puts "cache miss"
      remote_etag = http.response_header["ETAG"]
      User.cache.set(name, remote_etag)
      User.cache.set(remote_etag, http.response)
    }
  end
end
