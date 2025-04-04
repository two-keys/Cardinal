# frozen_string_literal: true

def next?
  File.basename(__FILE__) == 'Gemfile.next'
end

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.2.2'

gem 'bundler', '~>2.4'

gem 'rails', '~> 7.2.2'

# if next?
#  gem 'rails', '~> 7.2.2'
# else
#  gem 'rails', '~> 7.0.8'
# end

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem 'sprockets-rails'

# Use postgresql as the database for Active Record
gem 'pg', '~> 1.1'

# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '~> 5.0'

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem 'turbo-rails'

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem 'stimulus-rails'

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem 'jbuilder'

# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.0'

# Use hiredis wrapper
gem 'hiredis'

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Use Sass to process CSS
# gem 'sassc-rails'

gem 'cssbundling-rails'

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem 'image_processing', '>= 1.2'

# Pagination gem
gem 'pagy', '~> 5.6'

# User authentication
gem 'devise'

# Markdown support
gem 'redcarpet'

# Emoji
gem 'gemoji'

# Ancestry (self-referential, node-based tree traversal)
gem 'ancestry'

# Discord Webhooks
gem 'discordrb-webhooks'

# Sentry error reporting
gem 'sentry-rails'
gem 'sentry-ruby'

# Unleash feature flags
gem 'unleash', '~> 4.0.0'

# CanCanCan Authorization
gem 'cancancan'

gem 'debug', platforms: %i[mri mingw x64_mingw]

# Stripe
gem 'stripe'

# See https://github.com/minitest/minitest/issues/1007
gem 'minitest', '!= 5.25.0'

# https://github.com/rails/rails-html-sanitizer/security/advisories/GHSA-rxv5-gxqc-xx8g
gem 'rails-html-sanitizer', '>= 1.6.1'

# Used for CSS sanitization
gem 'sanitize'

# https://github.com/rails/rails/security/advisories/GHSA-vfm5-rmrh-j26v
gem 'actionpack', '>= 7.0.8.7'

# Audit logging
gem 'active_snapshot'

# Analytics
gem 'ahoy_matey'
gem 'chartkick'
gem 'clockwork'
gem 'rollups'

# Web Push Notifications
gem 'web-push'

# Text Search
gem 'pg_search', '~> 2.3', '>= 2.3.2'

# Tailwind
gem 'tailwindcss-rails', '~> 4.0'

# Mail CSS
gem 'roadie-rails'

# Javascript Bundling
gem 'jsbundling-rails'

# Spam prevention
gem 'recaptcha'

# Fancy activerecord postgres features
gem 'active_record_extended'

# IP Banning
gem 'rack-attack'

# Upgrades
gem 'next_rails'

# Markdown Editor
gem 'marksmith'

gem 'net-imap', '>= 0.5.6'
gem 'nokogiri', '>= 1.18.4'
gem 'rack', '~> 2.2.13'

gem 'rack-cors', '~> 2.0'

# Mailing
gem 'postmark-rails'

# For Data transfer time estimate
gem 'ruby-progressbar', '~> 1.13'

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem

  gem 'brakeman', require: false
  gem 'bundler-audit', require: false
  gem 'faker'
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem 'web-console'

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
  gem 'bullet'
  gem 'hotwire-livereload', '~> 2.0'
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'webdrivers'
end
