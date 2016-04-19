require 'rubygems'
require 'bundler'
require 'logger'

Bundler.setup

require 'coveralls'
Coveralls.wear!

require 'active_record'
require 'database_cleaner'
require 'usda-nutrient-database'
require 'shoulda-matchers'
require 'webmock/rspec'
require_relative 'support/database'

UsdaNutrientDatabase.configure do |config|
  config.perform_logging = false
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
  end
end

# This file was generated by the `rspec --init` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# Require this file using `require "spec_helper"` to ensure that it is only
# loaded once.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.include(Shoulda::Matchers::ActiveModel, type: :model)
  config.include(Shoulda::Matchers::ActiveRecord, type: :model)

  include Database

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  config.fail_fast = true

  db_name = ENV['DB'] || 'postgresql'
  database_yml = File.expand_path('../database.yml', __FILE__)
  ActiveRecord::Base.configurations = YAML.load_file(database_yml)
  db_config = ActiveRecord::Base.configurations[db_name]

  setup_database(db_name, db_config)

  begin
    ActiveRecord::Base.establish_connection(db_name.to_sym)
    ActiveRecord::Base.connection
  rescue PG::ConnectionBad
    ActiveRecord::Base.establish_connection db_config.merge('database' => nil)
    ActiveRecord::Base.connection.create_database db_config['database']
    ActiveRecord::Base.establish_connection db_config
  end

  ActiveRecord::Base.logger = Logger.new(File.join(File.dirname(__FILE__), 'debug.log'))
  ActiveRecord::Base.default_timezone = :utc

  ActiveRecord::Migration.verbose = false
  load(File.join(File.dirname(__FILE__), 'schema.rb'))

  config.before :suite do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before do
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end
end
