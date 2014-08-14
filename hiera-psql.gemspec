$:.unshift File.expand_path("../lib", __FILE__)
require 'hiera/backend/psql_version'

Gem::Specification.new do |s|
  s.version = HieraBackends::PostgreSQL::VERSION
  s.name = "hiera-psql"
  s.email = "erik.gustav.dalen@gmail.com"
  s.authors = "Erik Dalen"
  s.summary = "A PostgreSQL backend for Hiera."
  s.description = "Allows hiera functions to pull data from a PostgreSQL database."
  s.has_rdoc = false
  s.homepage = "http://github.com/dalen/hiera-psql"
  s.license = "Apache 2.0"
  s.files = Dir["lib/**/*.rb"]
  s.files += ["LICENSE"]

  s.add_dependency 'hiera', '1.2.1'
  s.add_dependency 'pg', '0.15.1'
  s.add_dependency 'json', '1.8.0'
  s.add_dependency 'json_pure', '1.8.0'

  s.add_development_dependency 'rspec', '2.13'

end
