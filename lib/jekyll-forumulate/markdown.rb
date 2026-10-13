require "kramdown"

module Jekyll
  module Forumulate
    # Markdown -> HTML for content fetched from Forumulate.
    #
    # Forum posts are written by visitors, and kramdown passes raw HTML (and IAL
    # attributes like `{: onclick=...}`) straight through. So the parsed tree is
    # scrubbed before conversion: HTML elements are unwrapped to their content,
    # raw passthroughs become plain (escaped) text, event-handler and style
    # attributes are dropped, and only http(s)/mailto/relative URLs survive.
    module Markdown
      SAFE_URL = %r{\A(?:https?:|mailto:|#|/|\.{0,2}/|[^:/?#]+(?:[/?#]|\z))}i.freeze
      DROP = %i[xml_comment xml_pi html_doctype].freeze

      module_function

      def to_html(text)
        input = defined?(Kramdown::Parser::GFM) ? "GFM" : "kramdown"
        doc = Kramdown::Document.new(text.to_s, input: input, auto_ids: true)
        scrub(doc.root)
        doc.to_html
      end

      def scrub(el)
        el.children = el.children.flat_map do |child|
          next [] if DROP.include?(child.type)

          if child.type == :raw
            next [Kramdown::Element.new(:text, child.value.to_s)]
          end
          scrub(child)
          next child.children if child.type == :html_element

          clean_attrs(child)
          [child]
        end
        el
      end

      def clean_attrs(el)
        el.attr.delete_if { |name, _| name.to_s =~ /\A(on|style\z|srcdoc\z|formaction\z)/i }
        %w[href src].each do |name|
          value = el.attr[name]
          el.attr[name] = "#" if value && value.strip !~ SAFE_URL
        end
      end
    end
  end
end
