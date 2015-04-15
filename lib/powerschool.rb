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

  def all(resource, options = {}, &block)
    _options = options.dup
    _options[:query] ||= {}
    page = 1
    results = []
    begin
      _options[:query][:page] = page
      response = self.send(resource, _options)
      results = response.parsed_response
      plural = results.keys.first
      results = results[plural][plural.singularize] || []
      results.each do |result|
        block.call(result, response)
      end
      page += 1
    end while results.any?
  end

  # client is set up per district so it returns only one district
  # for urls with parameters
  get :district, '/district'
  get :schools, '/district/school'
  get :teachers, '/staff'
  get :students, '/student'
  get :sections, '/section'
  get :school_teachers, '/school/:school_id/staff'
  get :school_sections, '/school/:school_id/section'
  get :school_students, '/school/:school_id/student'

  get :metadata, '/metadata'
end
