# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gi_cat_driver/version'

Gem::Specification.new do |spec|
  spec.name          = "gi_cat_driver"
  spec.version       = GiCatDriver::VERSION
  spec.authors       = ["Stuart Reed", "Miao Liu"]
  spec.email         = ["stuart.reed@nsidc.org", "miao.liu@nsidc.org"]
  spec.description   = %q{Configure and control deployed instances of GI-Cat.}
  spec.summary       = %q{Configure and control deployed instances of GI-Cat.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features|xml)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 0.8.7"
  spec.add_dependency "nokogiri"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake", "~> 10.0.3"
  spec.add_development_dependency "rspec", "~> 2.13.0"
  spec.add_development_dependency "pygments.rb", "~> 0.4.2"
  spec.add_development_dependency "mustache", "~> 0.99.4"
  spec.add_development_dependency "redcarpet", "~> 2.2.2"
  spec.add_development_dependency "rocco", "~> 0.8.2"
  spec.add_development_dependency "webmock", "~> 1.11.0"
end
