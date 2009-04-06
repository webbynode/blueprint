# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{blueprint}
  s.version = "0.0.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Felipe Coury"]
  s.date = %q{2009-04-06}
  s.email = %q{felipe@webbynode.com}
  s.extra_rdoc_files = ["README.rdoc", "LICENSE"]
  s.files = ["README.rdoc", "VERSION.yml", "lib/blueprint", "lib/blueprint/blueprint.rb", "lib/blueprint/components.rb", "lib/blueprint/utils.rb", "lib/blueprint.rb", "test/blueprint_test.rb", "test/test_helper.rb", "LICENSE"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/webbynode/blueprint}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Wanna build a stack? Give us the blueprint.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
