Gem::Specification.new do |spec|
  spec.name          = "lita-salt"
  spec.version       = "0.2.0-beta"
  spec.authors       = ["Jurnell Cockhren"]
  spec.email         = ["jurnell@sophicware.com"]
  spec.description   = %q{Salt handler for lita 4+}
  spec.summary       = spec.description
  spec.homepage      = "http://sophicware.com"
  spec.license       = "MIT"
  spec.metadata      = { "lita_plugin_type" => "handler" }

  spec.files         = `git ls-files`.split($/)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "lita", ">= 4.2"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "rspec", ">= 3.0.0"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "guard-rake"
  spec.add_development_dependency "guard-rspec"
end
