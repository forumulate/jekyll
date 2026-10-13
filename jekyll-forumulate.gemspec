require_relative "lib/jekyll-forumulate/version"

Gem::Specification.new do |s|
  s.name        = "jekyll-forumulate"
  s.version     = Jekyll::Forumulate::VERSION
  s.summary     = "Liquid tags for Forumulate comments, docs search and changelog, plus build-time content."
  s.description = "Embed Forumulate in a Jekyll site and render your public blog posts, forum topics, " \
                  "changelog releases and docs pages into the static HTML at build time."
  s.authors     = ["Forumulate"]
  s.homepage    = "https://github.com/forumulate/jekyll"
  s.license     = "MIT"
  s.files       = Dir["lib/**/*.rb", "README.md", "LICENSE"]
  s.required_ruby_version = ">= 2.7"
  s.add_dependency "jekyll", ">= 3.9", "< 5.0"
  s.metadata = {
    "homepage_uri" => "https://forumulate.com/guides",
    "source_code_uri" => "https://github.com/forumulate/jekyll",
  }
end
