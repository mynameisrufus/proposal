# $LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require File.expand_path("../../test/dummy/config/environment.rb", __FILE__)
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../../test/dummy/db/migrate", __FILE__)]
ActiveRecord::Migrator.migrations_paths << File.expand_path('../../db/migrate', __FILE__)

require "minitest/autorun"
require "active_support/test_case"

ActiveRecord::Migration.maintain_test_schema!
