require 'openssl'
require 'base64'
require 'json'
require 'httparty'

class Powerschool
  include HTTParty
  VERSION = '0.1'
  attr_accessor :auth_token
  attr_accessor :api_credentials

  base_uri 'https://partner5.powerschool.com/ws/v1/'
  AUTH_ENDPOINT = 'https://partner5.powerschool.com/oauth/access_token'

  debug_output $stdout

  def initialize(api_credentials)
    self.api_credentials = api_credentials
    @options = {:headers => {'Accept' => 'json'}}
  end

  def options(other = {})
    if !@authenticated
      authenticate
    end
    @options.merge(other)
  end

  def self.get(method, path)
    define_method(method) do
      self.class.get(path, options)
    end
  end

  get :districts, '/district'
  get :schools, '/school'
  get :teachers, '/staff'
  get :students, '/students'
  get :sections, '/section'


  def authenticate(force = false)
    headers = {
      'ContentType' => 'application/x-www-form-urlencoded;charset=UTF-8',
      'Accept' => 'json',
      'Authorization' => 'Basic ' + Base64.encode64([self.api_credentials['id'], self.api_credentials['secret']].join(':')).gsub(/\n/, '') }
    response = HTTParty.post(Powerschool::AUTH_ENDPOINT, {headers: headers, body: 'grant_type=client_credentials'})
    @options[:headers] ||= {}
    @authenticated = false
    if response.parsed_response && response.parsed_response['access_token']
      @options[:headers].merge!('Authorization' => 'Bearer ' + response.parsed_response['access_token'])
      @authenticated = true
    end
    return @authenticated
  end
end
