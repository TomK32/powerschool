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
    ptg: '/powerschool-ptg-api/v2/',
    xte: '/ws/xte'
  }


  def initialize(api_credentials)
    self.client = Class.new(Powerschool::Client) do |klass|
      uri = api_credentials['base_uri'] || Powerschool::Client::BASE_URI
      klass.base_uri(uri)
    end.new(api_credentials)
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
    options = options.dup
    options.each_pair do |key, value|
      regexp_path_option = /(:#{key}$|:#{key}([:\/-_]))/
      if path.match(regexp_path_option)
        if value.blank?
          raise "Blank value for parameter '%s' in '%s'" % [key, path]
        end
        path.gsub!(regexp_path_option, "#{value}\\2")
        options.delete(key)
      end
    end
    if parameter = path.match(/:(\w*)/)
      raise "Missing parameter '%s' in '%s'. Parameters: %s" % [parameter[1], path, options]
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

      # a rare(?) case has been observed where (in this case section_enrollment) did return a single
      # data object as a hash rather than as a hash inside an array
      if results.is_a?(Hash)
        results = [results]
      end
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
  get :student, :ws, '/student/:student_id'
  get :students, :ws, '/student'
  get :school_teachers, :ws, '/school/:school_id/staff'
  get :school_students, :ws, '/school/:school_id/student'
  get :school_sections, :ws, '/school/:school_id/section'
  get :school_courses, :ws, '/school/:school_id/course'
  get :school_terms, :ws, '/school/:school_id/term'
  get :section_enrollment, :ws, '/section/:section_id/section_enrollment'

  # PowerTeacher Gradebook (pre Powerschool 10)
  get :assignment, :ptg, 'assignment/:id'
  post :post_section_assignment, :ptg, '/section/:section_id/assignment'
  put :put_assignment_scores, :ptg, '/assignment/:assignment_id/score'
  put :put_assignment_score, :ptg, '/assignment/:assignment_id/student/:student_id/score'

  # PowerTeacher Pro
  post :xte_post_section_assignment, :xte, '/section/assignment'
  put :xte_put_assignment_scores, :xte, '/score'

  get :metadata, :ws, '/metadata'
  get :areas, '/ws/schema/area'
  get :tables, '/ws/schema/table'
  get :table_metadata, '/ws/schema/table/:table/metadata'
  get :area_table, '/ws/schema/area/:area/table'

  get :queries, '/ws/schema/query/api'


  def start_year
    offset = Date.today.month < 8 ? -1 : 0
    year = self.client.api_credentials['start_year'] || (Date.today.year + offset)
  end

  # Special method to filter terms and find the current ones
  def current_terms(options, today = nil)
    terms = []
    today ||= Date.today.to_s(:db)
    self.all(:school_terms, options) do |term, response|
      if term['end_date'] >= today
        terms << term
      end
    end
    if terms.empty?
      options[:query] = {q: 'start_year==%s' % start_year}
      self.all(:school_terms, options) do |term, response|
        if term['end_date'] >= today
          terms << term
        end
      end
    end
    # now filter again for the start date and if there isn't one matching we have to return the most recent one
    in_two_weeks = (Date.parse(today) + 2.weeks).to_s(:db)
    active_terms = terms.select{|term| term['start_date'] <= in_two_weeks }
    if active_terms.any?
      return active_terms
    end
    return terms
  end
end
