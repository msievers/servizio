# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "servizio/version"

Gem::Specification.new do |spec|
  spec.name          = "servizio"
  spec.version       = Servizio::VERSION
  spec.authors       = ["Michael Sievers"]
  spec.summary       = %q{Yet another service object support library}
  spec.homepage      = "https://github.com/msievers/servizio"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "activemodel", ">= 4.0.0"
  
  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
