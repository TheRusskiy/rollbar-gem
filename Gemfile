# This file was generated by Appraisal

source 'https://rubygems.org'

is_jruby = defined?(JRUBY_VERSION) || (defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby')

gem 'activerecord-jdbcsqlite3-adapter', :platform => :jruby
gem 'appraisal'
gem 'jruby-openssl', :platform => :jruby
gem 'rails', '4.2.8'
gem 'rake'
gem 'rspec-rails', '~> 3.4'
gem 'sqlite3', '< 1.4.0', :platform => [:ruby, :mswin, :mingw]

unless is_jruby
  if RUBY_VERSION >= '2.5'
    gem 'oj'
  elsif RUBY_VERSION >= '2.4.0'
    gem 'oj', '~> 2.16.1' # rubocop:disable Bundler/DuplicatedGem
  else
    gem 'oj', '~> 2.12.14' # rubocop:disable Bundler/DuplicatedGem
  end
end

if RUBY_VERSION > '1.8.7' && RUBY_VERSION < '2.2.2'
  gem 'sidekiq', '~> 2.13.0'
else
  gem 'sidekiq', '>= 2.13.0' # rubocop:disable Bundler/DuplicatedGem
end

platforms :rbx do
  gem 'minitest'
  gem 'racc'
  gem 'rubinius-developer_tools'
  gem 'rubysl', '~> 2.0' unless RUBY_VERSION.start_with?('1')
end

if RUBY_VERSION.start_with?('1.9')
  gem 'shoryuken', '>= 4.0.0', '<= 4.0.2'
  gem 'sucker_punch', '~> 1.0'
elsif RUBY_VERSION.start_with?('2')
  gem 'codacy-coverage'
  gem 'shoryuken' # rubocop:disable Bundler/DuplicatedGem
  gem 'simplecov'
  gem 'sucker_punch', '~> 2.0' # rubocop:disable Bundler/DuplicatedGem
end

gem 'aws-sdk-sqs'
gem 'database_cleaner'
gem 'delayed_job', :require => false
gem 'generator_spec'
gem 'girl_friday', '>= 0.11.1'
gem 'redis'
gem 'resque', '< 2.0.0'
gem 'rspec-command'
gem 'rubocop', :require => false
gem 'sinatra'
gem 'webmock', :require => false

gemspec
