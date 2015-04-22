require 'openssl'
require 'base64'
require 'json'
require 'httparty'

require 'powerschool/client'
class Powerschool
  attr_accessor :client
  attr_accessor :metadata
  API_PATHS = {
    ws: '/ws/v1',
    ptg: '/powerschool-ptg-api/v2/'
  }


  def initialize(api_credentials = nil)
    self.client = Client.new(api_credentials) if api_credentials
  end
  class << self
    [:get, :post, :put, :delete].each do |command|
      define_method(command.to_s) do |method, api, path = nil|
        if path.nil?
          path, api = api, nil
        end
        define_method(method) do |options = {}|
          return self.client.class.send(command, prepare_path(path.dup, api, options), self.client.options.merge(options))
        end
      end
    end
  end

  def prepare_path(path, api, options)
    options.each_pair do |key, value|
      path.gsub!(/(:#{key}$|:#{key})([:\/-_])/, "#{value}\\2")
    end
    if parameter = path.match(/:(\w*)/)
      raise "Missing parameter '%s' for '%s'" % [parameter[1], path]
    end
    if api
      path = (API_PATHS[api] + path).gsub('//', '/')
    end
    path
  end

  # retreive max_page_size from metadata. Defaults to 100
  def get_page_size(resource)
    @metadata ||= self.metadata()
    @metadata['%s_max_page_size' % resource.split('/').last.singularize] rescue 100
  end

  # Process every object for a resource.
  def all(resource, options = {}, &block)
    page_size = (options[:query][:pagesize] rescue nil) || get_page_size(resource)
    _options = options.dup
    _options[:query] ||= {}
    _options[:query][:pagesize] ||= page_size

    page = 1
    results = []
    begin
      _options[:query][:page] = page
      response = self.send(resource, _options)
      results = response.parsed_response || {}
      if !response.parsed_response
        if response.headers['www-authenticate'].match(/Bearer error/)
          raise response.headers['www-authenticate'].to_s
        end
      end
      plural = results.keys.first
      results = results[plural][plural.singularize] || []
      results.each do |result|
        block.call(result, response)
      end
      page += 1
    end while results.any? && results.size == page_size
  end



  # client is set up per district so it returns only one district
  # for urls with parameters
  get :district, :ws, '/district'
  get :schools, :ws, '/district/school'
  get :teachers, :ws, '/staff'
  get :students, :ws, '/student'
  get :school_teachers, :ws, '/school/:school_id/staff'
  get :school_students, :ws, '/school/:school_id/student'
  get :school_sections, :ws, '/school/:school_id/section'
  get :school_courses, :ws, '/school/:school_id/course'
  get :school_terms, :ws, '/school/:school_id/term'
  get :section_enrollment, :ws, '/section/:section_id/section_enrollment'

  post :assignment, :ptg, '/assignment'
  post :assignment_score, :ptg, '/assignment/:assignment_id/'

  get :metadata, '/metadata'

  # Special method to filter terms and find the current ones
  def current_terms(options, today = nil)
    terms = []
    today ||= Date.today.to_s(:db)
    self.all(:school_terms, options) do |term, response|
      if term['start_date'] <= today && term['end_date'] >= today
        terms << term
      end
    end
    return terms
  end
end
