lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name    = "fluent-plugin-sentry-ruby"
  spec.version = "0.4.1"
  spec.authors = ["buffalo"]
  spec.email   = ["buffalobigboy@gmail.com"]

  spec.summary       = %q{fluent plugin sentry.}
  spec.description   = %q{A fluent output plugin which integrated with sentry-ruby sdk.}
  spec.homepage      = "https://github.com/mengino/fluent-plugin-sentry"
  spec.license       = "Apache-2.0"

  test_files, files  = `git ls-files -z`.split("\x0").partition do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.files         = files
  spec.executables   = files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = test_files
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.17.2"
  spec.add_development_dependency "rake", "~> 12.3.3"
  spec.add_development_dependency "test-unit", "~> 3.2.9"
  spec.add_runtime_dependency "fluentd", [">= 0.14.10", "< 2"]
  spec.add_runtime_dependency "sentry-ruby", "~> 4.8"
end
