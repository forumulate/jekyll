require "erb"
require "jekyll"
require "jekyll-forumulate/version"
require "jekyll-forumulate/config"
require "jekyll-forumulate/client"
require "jekyll-forumulate/markdown"

module Jekyll
  module Forumulate
    # key="literal", key='literal', key=variable.path or key=123
    ARG = /([a-z_][a-z0-9_]*)\s*=\s*(?:"([^"]*)"|'([^']*)'|([\w.\-\[\]]+))/i.freeze
    ATTR_NAME = /\A[a-z][a-z0-9-]*\z/.freeze

    def self.config(context)
      Config.new(context.registers[:site].config)
    end

    def self.client(context)
      site = context.registers[:site]
      # One client per build, so its Jekyll::Cache handle is shared.
      site.instance_variable_get(:@forumulate_client) ||
        site.instance_variable_set(:@forumulate_client, Client.new(Config.new(site.config)))
    end

    # Parse `key=value` pairs; unquoted values are looked up in the Liquid context.
    def self.args(markup, context)
      markup.to_s.scan(ARG).each_with_object({}) do |(key, dq, sq, var), out|
        out[key] = dq || sq || (var =~ /\A\d+\z/ ? var.to_i : context[var])
      end
    end

    def self.attrs(pairs, prefix)
      pairs.map do |name, value|
        next if value.nil? || value == false

        attr = name.to_s.tr("_", "-").downcase
        raise ArgumentError, "forumulate: invalid option name #{name.inspect}" unless attr =~ ATTR_NAME

        value = "true" if value == true
        %( #{prefix}#{attr}="#{ERB::Util.html_escape(value.to_s)}")
      end.compact.join
    end

    EMBEDS = {
      "comments" => ["comments.js", "forumulate-comments"],
      "widget" => ["widget.js", "forumulate-widget"],
      "changelog" => ["changelog.js", "forumulate-changelog"],
      "feed" => [nil, "forumulate-feed"],
      "search" => [nil, "forumulate-search"],
    }.freeze

    # {% forumulate_comments %}, {% forumulate_widget mode="ask" %}, ...
    class EmbedTag < Liquid::Tag
      def initialize(tag_name, markup, tokens)
        super
        @kind = tag_name.sub("forumulate_", "")
        @markup = markup
      end

      def render(context)
        cfg = Forumulate.config(context)
        opts = Forumulate.args(@markup, context)
        script, element = EMBEDS.fetch(@kind)
        org = opts.delete("org") || cfg.org
        space = opts.delete("space") || cfg.space
        raise ArgumentError, "forumulate: set forumulate.org and forumulate.space in _config.yml" if org.to_s.empty? || space.to_s.empty?

        use_elements = opts.key?("use_elements") ? opts.delete("use_elements").to_s == "true" : cfg.mode == "elements"
        base = { "org" => org, "space" => space, "api" => cfg.api_url }.merge(opts)
        if use_elements || script.nil?
          %(<#{element}#{Forumulate.attrs(base, '')}></#{element}>) +
            %(<script type="module" src="#{ERB::Util.html_escape(cfg.elements_src)}" async></script>)
        else
          src = ERB::Util.html_escape("#{cfg.api_url}/embed/#{script}")
          %(<div class="forumulate-#{@kind}"><script src="#{src}"#{Forumulate.attrs(base, 'data-')} async></script></div>)
        end
      end
    end

    # {% forumulate_items blog limit=5 as posts %}
    # {% forumulate_item forum page.topic as topic %}
    # {% forumulate_markdown blog page.slug as body %}
    class ContentTag < Liquid::Tag
      SYNTAX = /\A\s*(\w+)\s+(?:("[^"]*"|'[^']*'|[\w.\-\[\]]+)\s+)?(.*?)\s*as\s+(\w+)\s*\z/m.freeze

      def initialize(tag_name, markup, tokens)
        super
        @what = tag_name.sub("forumulate_", "")
        m = SYNTAX.match(markup)
        raise SyntaxError, "Syntax: {% #{tag_name} <kind> [slug] [key=value ...] as <variable> %}" unless m

        @kind, @slug, @rest, @var = m.captures
      end

      def render(context)
        opts = Forumulate.args(@rest, context)
        client = Forumulate.client(context)
        space = opts["space"]
        slug = @slug && (@slug =~ /\A["']/ ? @slug[1..-2] : context[@slug])
        context.scopes.last[@var] =
          case @what
          when "items" then client.items(@kind, space: space, limit: (opts["limit"] || 10).to_i)
          when "item" then client.item(@kind, slug, space: space)
          when "markdown" then client.markdown(@kind, slug, space: space)
          end
        ""
      end
    end

    # {{ body | forumulate_html }}: Markdown -> scrubbed HTML.
    module Filters
      def forumulate_html(text)
        Markdown.to_html(text)
      end
    end
  end
end

%w[comments widget changelog feed search].each do |kind|
  Liquid::Template.register_tag("forumulate_#{kind}", Jekyll::Forumulate::EmbedTag)
end
%w[items item markdown].each do |what|
  Liquid::Template.register_tag("forumulate_#{what}", Jekyll::Forumulate::ContentTag)
end
Liquid::Template.register_filter(Jekyll::Forumulate::Filters)
