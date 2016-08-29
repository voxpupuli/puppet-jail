source "https://rubygems.org"

group :test do
  gem "rake"
  gem "puppet", ENV['PUPPET_VERSION'] || '~> 4.6.1'
  gem "rspec"
  gem "rspec-core"
  gem "rspec-puppet", :git => 'https://github.com/rodjek/rspec-puppet.git'
  gem "puppetlabs_spec_helper"
  gem "metadata-json-lint"
  gem "rspec-puppet-facts"
  gem 'json_pure', '<=2.0.1', :require => false if RUBY_VERSION =~ /^1\./
end

group :development do
  gem "travis"
  gem "travis-lint"
  gem "vagrant-wrapper"
  gem "puppet-blacksmith"
end

group :system_tests do
  gem "beaker"
  gem "beaker-rspec"
end
