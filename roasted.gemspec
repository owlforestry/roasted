# -*- encoding: utf-8 -*-
require File.expand_path('../lib/roasted/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Mikko Kokkonen"]
  gem.email         = ["mikko@owlforestry.com"]
  gem.description   = %q{
    Roasted is a simple bootstrapping library to install
    all necessary applications and requirements to freshly
    installed OS X. Roasted install not only applications
    but also preferences and licenses if possible.}
  gem.summary       = %q{Simple application installation and configuration library for OS X}
  gem.homepage      = "http://www.github.com/owlforestry/roasted"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "roasted"
  gem.require_paths = ["lib"]
  gem.version       = Roasted::VERSION
  
  gem.add_dependency 'thor'
  gem.add_dependency 'plist'
end
