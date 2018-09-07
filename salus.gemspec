# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "salus/version"

Gem::Specification.new do |spec|
  spec.name          = "salus"
  spec.version       = Salus::VERSION
  spec.licenses      = ['BSD']
  spec.authors       = ["divanikus"]
  spec.email         = ["d1pro@yandex.ru"]

  spec.summary       = %q{Simple DSL for writing metrics collecting agents.}
  spec.description   = %q{A simple library for quick creation of collector agents.}
  spec.homepage      = "https://github.com/divanikus/salus/"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.15"

  spec.add_dependency "thor", "~> 0.20"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
