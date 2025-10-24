source "https://rubygems.org"

ruby "3.0.0"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.1.5"

# Use mysql as the database for Active Record
gem "mysql2", "~> 0.5"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
# gem "jbuilder"

# Use Redis adapter to run Action Cable in production
gem "redis", ">= 4.0.1"

# Resque for background jobs
gem "resque", "~> 2.6.0"
gem "resque-scheduler", "~> 4.10.2"

# FTP/SFTP support for file transfer
gem "net-sftp", "~> 4.0"
gem "rubyzip", "~> 2.3"

# Tencent Cloud COS support (using AWS S3 compatible approach)
gem "aws-sdk-s3", "~> 1.0"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Authentication and Authorization
gem "bcrypt", "~> 3.1.7"
gem "jwt", "~> 2.7"
gem "omniauth", "~> 2.1"
gem "omniauth-github", "~> 2.0"
gem "omniauth-rails_csrf_protection", "~> 1.0"
gem "omniauth-wechat-oauth2", "~> 0.1"
gem "cancancan", "~> 3.5"
gem "kaminari", "~> 1.2"

# HTTP client for API requests
gem "httparty", "~> 0.21"

# Database adapters using Sequel
gem "sequel", "~> 5.75"
gem "pg", "~> 1.5"           # PostgreSQL
gem "sqlite3", "~> 1.6"      # SQLite
gem "trino-client"
# gem "oracle-enhanced", "~> 7.0"  # Oracle (uncomment if needed)
# gem "tiny_tds", "~> 2.1"         # SQL Server (uncomment if needed)

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ mswin mswin64 mingw x64_mingw jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
# gem "rack-cors"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri mswin mswin64 mingw x64_mingw ]

  # Load environment variables from .env file
  gem 'dotenv-rails'
end

group :development do
  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

