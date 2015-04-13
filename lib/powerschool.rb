require 'rest-client'
require 'openssl'
require 'base64'
require 'json'

class Powerschool
  VERSION = '0.1'
  AUTH_ENDPOINT = 'https://partner5.powerschool.com/oauth/access_token'

  attr_accessor :auth_token
  attr_accessor :api_credentials

  def initialize(options)
    self.api_credentials = options
    if self.authenticate()
      Powerschool::Client.headers['Authorization'] = 'Bearer ' + self.auth_token
    else
      raise "Authentication has failed"
    end
  end

  def authenticate(force = false)
    return self.auth_token if Sources::Powerschool.auth_token && !force
    headers = {
      content_type: 'application/x-www-form-urlencoded;charset=UTF-8', accept: 'json',
      authorization: 'Basic ' + Base64.encode64([self.api_credentials['id'], self.api_credentials['secret']].join(':')).gsub(/\n/, '') }
    response = RestClient.post(Powerschool::AUTH_ENDPOINT, 'grant_type=client_credentials', headers)
    self.auth_token = JSON.parse(response)['access_token'] rescue nil
  end

  def districts
    @districts ||= Powerschool::District.new
  end
end

require 'powerschool/client'
require 'powerschool/district'
require 'powerschool/school'
require 'powerschool/student'
require 'powerschool/teacher'
