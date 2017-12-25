class Powerschool
  class Client
    class AuthenticationError < RuntimeError
    end
    include HTTParty

    VERSION = '0.2'
    attr_accessor :api_credentials, :authenticated, :options

    BASE_URI = 'https://partner3.powerschool.com'
    base_uri BASE_URI
    AUTH_ENDPOINT = '/oauth/access_token'

    # debug_output $stdout

    def initialize(api_credentials, options = {})
      @api_credentials = api_credentials
      if (api_credentials['secret'].blank? || api_credentials['id'].blank?) && api_credentials['access_token'].blank?
        raise AuthenticationError.new('Access token or api credentials are required')
      end
      @options = {:headers => {'User-Agent' => "Ruby Powerschool #{VERSION}", 'Accept' => 'application/json', 'Content-Type' => 'application/json'}}.merge(options)
    end

    def options(other = {})
      if !@authenticated
        authenticate
      end
      @options.merge(other)
    end

    def authenticate(force = false)
      @authenticated = false
      if ! @api_credentials['access_token']
        headers = {
          'ContentType' => 'application/x-www-form-urlencoded;charset=UTF-8',
          'Accept' => 'application/json',
          'Authorization' => 'Basic ' + Base64.encode64([self.api_credentials['id'], self.api_credentials['secret']].join(':')).gsub(/\n/, '') }
        response = HTTParty.post(self.class.base_uri + AUTH_ENDPOINT, {headers: headers, body: 'grant_type=client_credentials'})
        @options[:headers] ||= {}
        if response.parsed_response && response.parsed_response['access_token']
          @api_credentials['access_token'] = response.parsed_response['access_token']
        end
      end
      if @api_credentials['access_token']
        @options[:headers].merge!('Authorization' => 'Bearer ' + @api_credentials['access_token'])
        @authenticated = true
      else
        raise AuthenticationError.new("Could not authenticate: %s -- headers: %s" % [response.inspect, headers])
      end
      return @authenticated
    end
  end
end
