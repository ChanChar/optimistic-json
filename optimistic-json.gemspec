# frozen_string_literal: true

require_relative "lib/optimistic/json/version"

Gem::Specification.new do |spec|
  spec.name = "optimistic-json"
  spec.version = Optimistic::Json::VERSION
  spec.authors = ["Charles C. Lee"]
  spec.email = ["charleschanlee@gmail.com"]

  spec.summary = "Parse potentially incomplete JSON in a best effort manner."
  spec.description = "Heavily inspired by [`best-effort-json-parser`]" \
    "(https://github.com/beenotung/best-effort-json-parser) to parse potentially " \
    "incomplete JSON in a best effort manner."
  spec.homepage = "https://github.com/ChanChar/optimistic-json"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  # spec.metadata["allowed_push_host"] = ""

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # https://github.com/intridea/multi_json
  # Allow users to swap JSON engine (e.g. Oj, Yajl, the default JSON gem)
  spec.add_dependency "logger"
  spec.add_dependency "multi_json", "~> 1.0"
  spec.add_dependency "sorbet-runtime"

  spec.add_development_dependency "debug"
  spec.add_development_dependency "gem-release"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
  spec.add_development_dependency "rubocop-rspec"
  spec.add_development_dependency "sorbet"
  spec.add_development_dependency "tapioca"
end
