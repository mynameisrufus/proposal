$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "proposal/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "proposal"
  s.version     = Proposal::VERSION
  s.authors     = ["Rufus Post"]
  s.email       = ["rufuspost@gmail.com"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of Proposal."
  s.description = "TODO: Description of Proposal."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "turn"
end
