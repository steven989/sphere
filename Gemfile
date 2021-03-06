source 'https://rubygems.org'


#use Puma for server
gem 'puma'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.4'
# Use sqlite3 as the database for Active Record
# gem 'sqlite3'
gem 'pg'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
gem 'jquery-ui-rails'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc
# Authentication
gem 'sorcery', '~> 0.9.1'
# Console beautification
gem 'hirb'
# Better database query
gem 'squeel'
# Image upload
gem 'carrierwave', '>= 1.0.0.rc', '< 2.0'
# Image upload from data URI (data stream)
gem 'carrierwave-data-uri'
# Work with Amazon S3
gem 'fog-aws'
# Modify images
gem 'rmagick'
# Save creditials securely
gem 'figaro', '~> 1.0'
# Google API
gem 'google-api-client', '~> 0.9', require: 'google/apis/calendar_v3'
# Authentication to API providers
gem 'omniauth'
# Oauth for Google
gem 'omniauth-google-oauth2'
# HTTP requests
gem 'httparty'
# Parse date and time from string
gem 'chronic'
# Oauth for Facebook
gem 'omniauth-facebook'
# APIs for Facebook
gem 'koala', "~> 2.2"
# API for Fullcontact, to get pictures and additional information about connections
gem 'fullcontact'
# Google contacts 
gem 'google_contacts_api'
# Oauth2
gem 'oauth2'
# Font awesome
gem 'font-awesome-rails'
# Dump database data into seed file
gem 'seed_dump'
# Monitoring
gem 'newrelic_rpm'
# Email validation
gem 'email_validator'
#Impersonation
gem 'pretender'
#Adobe typekit
gem 'typekit-rails'
#timezones
gem 'tzinfo'
gem 'tzinfo-data'
#delayed job
gem 'delayed_job_active_record'
# get user browser info
gem 'browser'
# pagination
gem 'kaminari'


# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# This is for the detailed logs
group :production do
  gem "rails_12factor"
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'
  # serve gzipped files
  gem 'heroku-deflater'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
end

