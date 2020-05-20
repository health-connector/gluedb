source 'https://rubygems.org'

gem 'rake', '10.4.2'
gem 'rails', '5.2.4.3'

gem "mongoid", "~> 6.0.0"
gem "origin"
gem "aasm", "~> 3.0.25"
gem "nokogiri", "~> 1.6.1"
gem "bunny", '1.4.1'
gem 'amq-protocol', '2.0.1'
gem 'jquery-rails', '4.0.1'
gem 'jquery-ui-rails', '5.0.5'
gem 'virtus'
gem 'spreadsheet', '1.0.4'
gem 'ruby-ole', '1.2.11.7'
gem 'openhbx_cv2', git: "https://github.com/dchbx/openhbx_cv2.git"
gem "interactor", "~> 3.0"
gem 'interactor-rails', '2.2.0'
gem "psych", "2.0.5"

group :development do
  gem 'capistrano', '2.15.4'
  gem 'rubocop', '0.57.2'
  gem 'rubocop-git', '0.1.3'
  gem 'overcommit', '0.44.0'
#  gem 'jazz_hands'
end

group 'development', 'test' do
  gem 'rspec', '3.3.0'
  gem 'rspec-core', '3.3.2'
end

group :development, :assets, :test do
  gem 'libv8'
  gem 'therubyracer', '0.12.2', :platforms => :ruby
  gem 'sass-rails', '~> 5.0.5'
  gem 'coffee-rails', '~> 4.2.2'
  gem 'less-rails-bootstrap', '3.2.0'
  gem 'designmodo-flatuipro-rails', git: "git@github.com:dchbx/designmodo-flatuipro-rails.git"
end

group :development, :assets do
  gem 'uglifier', '>= 1.0.3'
  gem 'font-awesome-rails', '4.7.0.4'
  gem "rails_best_practices", ">= 1.17.0"
end

group :development, :test do
  gem "parallel_tests"
end

group :test do
  gem 'test-unit'
  gem 'mongoid-rspec', '>= 4.0.0'
  gem 'rspec-rails', '3.5.0'
  gem 'rspec-collection_matchers', '1.1.2'
  gem 'capybara', '2.4.4'
  gem 'factory_girl_rails', '4.5.0'
  gem 'factory_girl', '4.5.0'
  gem 'database_cleaner', '1.5.3'
  gem 'ci_reporter', '2.0.0'
  gem 'savon', '2.7'
  gem 'simplecov', :require => false
  gem 'rspec_junit_formatter'
end

group :production do
  gem 'unicorn', '4.8.2'
#  gem 'bluepill', '0.0.68'
  gem 'eye', '0.6.4'
  gem 'celluloid', '0.15.2'
  gem 'nio4r', '1.1.1'
end

gem 'ruby-progressbar', '~> 1.7'
gem "haml"
gem 'kaminari', '0.16.3'
gem 'bootstrap-kaminari-views', '0.0.5'
gem "pd_x12"
gem 'carrierwave-mongoid', '0.8.0', :require => 'carrierwave/mongoid'
gem 'devise', '4.4.2'
gem "rsec"
gem "mongoid_auto_increment", "0.1.2"
gem 'american_date', '1.1.0'
gem 'cancancan', '~> 1.9'
gem 'oj'
gem 'roo', '2.1.0'
gem 'bh', '>= 1.3.6'
gem 'nokogiri-happymapper', :require => 'happymapper'
gem 'prawn', '~> 0.11.1'
gem 'forkr', '1.0.2'
gem 'edi_codec', git: "git@github.com:health-connector/edi_codec.git", branch: "ma-0.2.3"
gem 'ibsciss-middleware', git: "https://github.com/dchbx/ruby-middleware.git", :require => "middleware"
gem 'rgl', '0.5.2'
gem 'aws-sdk'

# configuration support
gem "config", "1.0.0"
