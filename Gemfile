source 'https://rubygems.org'

gem 'rails', '~> 8.0.0'
gem 'openssl', '>= 3.3.1'
gem 'propshaft'
gem 'pg', '~> 1.1'
gem 'puma', '>= 5.0'
gem 'jsbundling-rails'
gem 'turbo-rails'
gem 'jbuilder'

gem 'aws-sdk-s3', require: false

gem 'tzinfo-data', platforms: %i[ windows jruby ]

gem 'thruster', require: false

group :development, :test do
  gem 'brakeman', require: false
  gem 'rubocop-rails-omakase', require: false
end

group :development do
  gem 'debug', require: false
  gem 'byebug'
  gem 'web-console'
end

group :test do
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'mocha', '~> 2.7'
  gem 'minitest', '~> 5.25'
end

group :production, :development do
  gem 'sentry-ruby'
  gem 'sentry-rails'
end

gem 'devise', '~> 4.9'
gem 'devise-jwt', '~> 0.10.0'
gem 'rack-cors', '~> 2.0'
gem 'redis', '~> 5.4'
gem 'solid_queue', '~> 1.1'

gem 'omniauth', '~> 2.1'
gem 'omniauth-google-oauth2', '~> 1.1'
gem 'omniauth-rails_csrf_protection', '~> 1.0'

gem 'pundit', '~> 2.3'
gem 'kaminari', '~> 1.2'
gem 'aasm', '~> 5.5'
gem 'image_processing', '~> 1.2'
gem 'gmail_xoauth', '~> 0.4'
