module Jekyll
  module Forumulate
    # The `forumulate:` block of _config.yml.
    class Config
      attr_reader :org, :space, :base_url, :api_url, :mode, :elements_src, :cache_ttl, :timeout

      def initialize(site_config)
        raw = site_config["forumulate"] || {}
        @org = raw["org"]
        @space = raw["space"]
        @base_url = (raw["base_url"] || "https://forumulate.com").to_s.chomp("/")
        @api_url = (raw["api_url"] || "#{@base_url}/api").to_s.chomp("/")
        @mode = (raw["mode"] || "script").to_s
        @elements_src = raw["elements_src"] || "https://cdn.jsdelivr.net/npm/@forumulate/embed@1"
        @cache_ttl = (raw["cache_ttl"] || 300).to_i
        @timeout = (raw["timeout"] || 5).to_i
      end
    end
  end
end
