require 'openssl'
require 'base64'
require 'json'
require 'httparty'

require 'powerschool/client'
class Powerschool
  attr_accessor :client
  attr_accessor :metadata

  def initialize(api_credentials)
    @client = Client.new(api_credentials)
  end

  def self.get(method, path)
    define_method(method) do |options = {}|
      _path = path.dup
      options.each_pair do |key, value|
        _path.gsub!(/(:#{key}$|:#{key})([:\/-_])/, "#{value}\\2")
      end
      if parameter = _path.match(/:(\w*)/)
        raise "Missing parameter '%s' for '%s'" % [parameter[1], _path]
      end
      return @client.class.get(_path, @client.options.merge(options))
    end
  end

  # retreive max_page_size from metadata. Defaults to 100
  def get_page_size(resource)
    @metadata ||= self.metadata()
    @metadata['%s_max_page_size' % resource.split('/').last.singularize] rescue 100
  end

  # Process every object for a resource.
  def all(resource, options = {}, &block)
    page_size = options[:query][:pagesize] || get_page_size(resource)
    _options = options.dup
    _options[:query] ||= {}
    _options[:query][:pagesize] ||= page_size

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
    end while results.any? && results.size == page_size
  end

  # client is set up per district so it returns only one district
  # for urls with parameters
  get :district, '/district'
  get :schools, '/district/school'
  get :teachers, '/staff'
  get :students, '/student'
  get :school_teachers, '/school/:school_id/staff'
  get :school_students, '/school/:school_id/student'
  get :school_sections, '/school/:school_id/section'
  get :school_courses, '/school/:school_id/course'
  get :school_terms, '/school/:school_id/term'
  get :section_enrollment, '/section/:section_id/section_enrollment'

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
