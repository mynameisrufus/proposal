$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "proposal/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "proposal"
  s.version     = Proposal::VERSION
  s.authors     = ["Rufus Post"]
  s.email       = ["rufuspost@gmail.com"]
  s.homepage    = "https://github.com/mynameisrufus/proposal"
  s.summary     = "Simple unobtrusive token invitation engine for rails"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["Rakefile"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "turn"
end
