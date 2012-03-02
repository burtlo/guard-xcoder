# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'guard/xcoder'

Gem::Specification.new do |s|
  s.name        = 'guard-xcoder'
  s.version     = Guard::Xcoder::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Franklin Webber']
  s.email       = ['franklin.webber@gmail.com']
  s.homepage    = 'http://github.com/burtlo/guard-xcoder'
  s.summary     = 'Guard gem for performing commands with Xcode projects'
  s.description = 'Guard::Xcoder performs project operations when project files are modified.'
  
  s.required_rubygems_version = '>= 1.3.6'
  s.rubyforge_project         = 'guard-xcoder'
  
  s.add_dependency 'guard',   '>= 0.10.0'
  
  s.add_development_dependency 'bundler', '~> 1.0'
  s.add_development_dependency 'rspec', '~> 2.0'
  s.add_development_dependency 'guard-rspec'

  s.files        = Dir.glob('{lib}/**/*') + %w[LICENSE README.md]
  s.require_path = 'lib'
end
