require 'weary'

class Powerschool::Client < Weary::Client
  cattr_accessor :headers
  ENDPOINT = "https://partner5.powerschool.com/ws/v1"

  def domain
    return ENDPOINT
  end
  def headers
    return @@headers ||= {}
  end
end

