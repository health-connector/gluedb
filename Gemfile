source 'https://rubygems.org'

gem 'rails', '3.2.16'

gem "mongoid", "~> 3.1.6"
gem "origin"
gem "aasm", "~> 3.0.25"
gem "nokogiri", "~> 1.6.1"
gem "bunny", '1.4.1'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'virtus'
gem 'spreadsheet'
gem 'ruby-ole', '1.2.11.7'
gem 'openhbx_cv2', git: "https://github.com/dchbx/openhbx_cv2.git"
gem "interactor", "~> 3.0"
gem 'interactor-rails', '2.0.2'
gem "psych", "2.0.5"

group :development do
  gem 'capistrano', '2.15.4'
  gem 'ruby-progressbar', '1.6.0'
#  gem 'jazz_hands'
end

group :development, :assets, :test do
  gem 'libv8'
  gem 'therubyracer', :platforms => :ruby
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'less-rails-bootstrap', '3.2.0'
  gem 'designmodo-flatuipro-rails', git: "git@github.com:dchbx/designmodo-flatuipro-rails.git"
end

group :development, :assets do
  gem 'uglifier', '>= 1.0.3'
  gem 'font-awesome-rails', '4.2.0.0'
  gem "rails_best_practices"
end

group :development, :test do
  gem "parallel_tests"
end

group :test do
  gem 'test-unit'
	gem 'mongoid-rspec'
  gem 'rspec', '3.3.0'
  gem 'rspec-core', '3.3.2'
  gem 'rspec-rails', '3.3.3'
  gem 'rspec-collection_matchers', '1.1.2'
  gem 'capybara'
  gem "capybara-webkit"
  gem 'factory_girl_rails'
  gem 'database_cleaner', '1.5.3'
  gem 'ci_reporter', '2.0.0'
  gem 'savon', '2.7'
  gem 'simplecov', :require => false
  gem 'rubycritic', :require => false
  gem 'rspec_junit_formatter'
end

group :production do
  gem 'unicorn', '4.8.2'
#  gem 'bluepill', '0.0.68'
  gem 'eye'
end

gem "haml"
gem 'kaminari'
gem 'bootstrap-kaminari-views', '0.0.5'
gem "pd_x12"
gem 'carrierwave-mongoid', '0.7.1', :require => 'carrierwave/mongoid'
gem 'devise', '3.3.0'
gem "rsec"
gem "mongoid_auto_increment"
gem 'american_date', '1.1.0'
gem 'cancancan', '~> 1.9'
gem 'oj'
gem 'roo'
gem 'bh'
gem 'nokogiri-happymapper', :require => 'happymapper'
gem 'prawn', '~> 0.11.1'
gem 'forkr', '1.0.2'
gem 'edi_codec', git: "git@github.com:dchbx/edi_codec.git"
gem 'ibsciss-middleware', git: "https://github.com/dchbx/ruby-middleware.git", :require => "middleware"
