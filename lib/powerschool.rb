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

  # client is set up per district so it returns only one district
  # for urls with parameters
  get :district, '/district'
  get :schools, '/district/school'
  get :teachers, '/staff'
  get :students, '/student'
  get :sections, '/section'
  get :school_sections, '/school/:school_id/section'
  get :school_students, '/school/:school_id/student'

  get :metadata, '/metadata'
end
