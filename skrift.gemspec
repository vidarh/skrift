# frozen_string_literal: true

require_relative "lib/skrift/version"

Gem::Specification.new do |spec|
  spec.name = "skrift"
  spec.version = Skrift::VERSION
  spec.authors = ["Vidar Hokstad"]
  spec.email = ["vidar@hokstad.com"]

  spec.summary = "A pure Ruby TruteType font renderer"
  #spec.description = "TODO: Write a longer description or delete this line."
  spec.homepage = "https://github.com/vidarh/skrift"
  spec.license = "ISC"
  spec.required_ruby_version = ">= 2.7.0"

  #spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  #spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
