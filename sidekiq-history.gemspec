# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sidekiq/history/version'

Gem::Specification.new do |spec|
  spec.name          = "sidekiq-history"
  spec.version       = Sidekiq::History::VERSION
  spec.authors       = ["Russ Smith"]
  spec.email         = ["russ@bashme.org"]
  spec.description   = %q{History for sidekiq jobs.}
  spec.summary       = %q{History for sidekiq jobs.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "sidekiq", ">= 3.0.0"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "sprockets"
  spec.add_development_dependency "sinatra"
end
