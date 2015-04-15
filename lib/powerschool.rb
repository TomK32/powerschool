require 'openssl'
require 'base64'
require 'json'
require 'httparty'

require 'powerschool/client'
class Powerschool
  attr_accessor :client

  def initialize(api_credentials)
    @client = Client.new(api_credentials)
  end

  def self.get(method, path)
    define_method(method) do |options = {}|
      options.each_pair do |key, value|
        path.gsub!(/(:#{key}$|:#{key})([:\/-_])/, "#{value}\\2")
      end
      if parameter = path.match(/:(\w*)/)
        raise "Missing parameter '%s' for '%s'" % [parameter[1], path]
      end
      return @client.class.get(path, @client.options.merge(options))
    end
  end

  get :districts, '/district'
  get :schools, '/school'
  get :teachers, '/staff'
  get :students, '/students'
  get :sections, '/section'
end
