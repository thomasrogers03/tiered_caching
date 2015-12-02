source 'https://rubygems.org'

gemspec

group :development do
  require 'yaml'
  require 'logger'
  gem 'rdoc'
  gem 'concurrent-ruby', '~> 0.8.0'
  gem 'thomas_utils', '~> 0.1', github: 'thomasrogers03/thomas_utils'
end

group :test do
  gem 'rspec', '~> 3.1.0', require: false
  gem 'rspec-its'
  gem 'guard-rspec'
  gem 'guard-bundler'
  gem 'guard'
  gem 'pry'
  gem 'timecop'
  gem 'simplecov', require: false
  gem 'connection_pool'
end
