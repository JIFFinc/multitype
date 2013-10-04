# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'multitype/version'

Gem::Specification.new do |spec|
  spec.name          = "multitype"
  spec.version       = Multitype::VERSION
  spec.authors       = ["Kelly Becker"]
  spec.email         = ["kellylsbkr@gmail.com"]
  spec.description   = %q{Allows for dynamic methods and data dependent on the data on a classes instance attributes}
  spec.summary       = %q{Add dynamic methods for ruby classes}
  spec.homepage      = ""

  # Determine the proper license for this code
  # spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "awesome_print"
  spec.add_dependency "activesupport", ">= 3.2.13"
end
