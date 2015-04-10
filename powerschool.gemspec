Gem::Specification.new do |s|
  s.name = "powerschool"
  s.version = "0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Thomas R. Koll"]
  s.date = "2015-04-10"
  s.description = "Provides a ruby interface to Powerschool API"
  s.summary = "Provides a ruby interface to Powerschool API"
  s.email = "tomk@naiku.net"
  s.extra_rdoc_files = [
    "README"
  ]
  s.files = [
    "Gemfile",
    "LICENSE",
    "README",
    "lib/powerschool.rb",
    "lib/powerschool/base.rb",
    "lib/powerschool/district.rb",
    "lib/powerschool/school.rb",
    "spec/spec_helper.rb",
    "powerschool.gemspec"
    ]
end
