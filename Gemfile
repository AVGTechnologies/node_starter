source 'https://rubygems.org'

gem 'multi_json',       '~> 1.0'
gem 'activesupport',    '~> 4.2'
gem 'activerecord',     '~> 4.2'
gem 'annotate',         '~> 2.6.10'

gem 'settingslogic',    '~> 2.0'
gem 'bunny',            '~> 1.6'
gem 'sqlite3',          '~> 1.3.11'
gem 'nokogiri',         '>= 1.6.7.rc'
gem 'sidekiq',          '= 3.4.2'

gem 'sys-proctable',    '= 0.9.9'

group :test, :development do
  gem 'rspec'
  gem 'rubocop'
  gem 'factory_girl', '~> 4.0'
  gem 'xml-simple'
end

group :test do
# TODO: investigate whether this gem is really needed
# it causes problem running travis-ci tests
# and when running on windows
#  gem 'fakefs'  
end

group :development do
  gem 'rails', '4.2.3', require: false
end 
