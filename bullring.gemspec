$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "bullring/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "bullring"
  s.version     = Bullring::VERSION
  s.authors     = ["JP Slavinsky (Kindling Labs)"]
  s.email       = ["jps@kindlinglabs.com"]
  s.homepage    = "http://www.github.com/kindlinglabs/bullring"
  s.summary     = "Safely run untrusted Javascript from Ruby"
  s.description = "Safely run untrusted Javascript from Ruby"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.platform = $platform || RUBY_PLATFORM[/java/] || 'ruby'

  s.add_dependency "uglifier"
  s.add_dependency "therubyrhino"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rails", "~> 3.2.2"
  
  if s.platform.to_s == 'java'
    # s.add_development_dependency 'ruby-debug'
  else
    s.add_development_dependency "ruby-debug19"    
  end

end
