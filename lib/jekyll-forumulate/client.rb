require "erb"
require "json"
require "net/http"
require "uri"

module Jekyll
  module Forumulate
    # Build-time reads from the PUBLIC read API. Results are kept in
    # Jekyll::Cache (on disk under .jekyll-cache) for cache_ttl seconds, so
    # `jekyll serve` rebuilds do not refetch on every save. A failure yields an
    # empty list and a warning: a build never fails because Forumulate is down.
    class Client
      KINDS = {
        "blog" => ["/blog", "articles", "/blog/t/%s", "b"],
        "forum" => ["/forum", "topics", "/forum/t/%s", "f"],
        "changelog" => ["/changelog", "releases", "/changelog/t/%s", "c"],
        "docs" => ["", nil, "/pages/%s", "p"],
      }.freeze

      def initialize(config)
        @config = config
        @cache = defined?(Jekyll::Cache) ? Jekyll::Cache.new("Jekyll::Forumulate") : {}
      end

      def items(kind, space: nil, limit: 10)
        path, key, = spec(kind)
        rows =
          if kind.to_s == "docs"
            data = fetch(space_url(space))
            (data ? data.fetch("collections", []) : [])
              .flat_map { |c| c.fetch("pages", []) }
              .reject { |p| p["hideFromNav"] }
              .first(limit.to_i)
          else
            data = fetch("#{space_url(space)}#{path}?limit=#{limit.to_i}")
            data ? Array(data[key]) : []
          end
        rows.map { |row| row.merge("url" => row["externalUrl"] || reader_url(kind, space, row["slug"] || row["id"])) }
      end

      def item(kind, slug, space: nil)
        data = fetch(space_url(space) + format(spec(kind)[2], esc(slug)))
        return nil unless data

        piece = data["article"] || data["topic"] || data["release"] || data
        piece.merge("url" => reader_url(kind, space, piece["slug"] || slug))
      end

      def markdown(kind, slug, space: nil)
        body = fetch(space_url(space) + format(spec(kind)[2], esc(slug)) + ".md", json: false)
        body.is_a?(String) ? body : ""
      end

      private

      def spec(kind)
        KINDS.fetch(kind.to_s) { raise ArgumentError, "forumulate: unknown kind #{kind.inspect}" }
      end

      def esc(value)
        ERB::Util.url_encode(value.to_s)
      end

      def space_url(space)
        org = @config.org
        space ||= @config.space
        raise ArgumentError, "forumulate: set forumulate.org and forumulate.space in _config.yml" if org.to_s.empty? || space.to_s.empty?

        "#{@config.api_url}/public/orgs/#{esc(org)}/spaces/#{esc(space)}"
      end

      def reader_url(kind, space, slug)
        "#{@config.base_url}/#{spec(kind)[3]}/#{esc(@config.org)}/#{esc(space || @config.space)}/#{esc(slug)}"
      end

      def fetch(url, json: true)
        hit = @cache.key?(url) ? @cache[url] : nil
        return hit[1] if hit && hit[0] > Time.now.to_i

        value, ttl = request(url, json)
        @cache[url] = [Time.now.to_i + ttl, value]
        value
      end

      def request(url, json)
        uri = URI(url)
        res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                              open_timeout: @config.timeout, read_timeout: @config.timeout) do |http|
          req = Net::HTTP::Get.new(uri)
          req["Accept"] = json ? "application/json" : "text/markdown"
          req["User-Agent"] = "jekyll-forumulate"
          http.request(req)
        end
        unless res.is_a?(Net::HTTPSuccess)
          Jekyll.logger.warn("Forumulate:", "#{url} answered #{res.code}") if defined?(Jekyll.logger)
          return [false, 30]
        end
        body = res.body.to_s.dup.force_encoding("UTF-8")
        [json ? JSON.parse(body) : body, @config.cache_ttl]
      rescue StandardError => e
        Jekyll.logger.warn("Forumulate:", "#{url}: #{e.message}") if defined?(Jekyll.logger)
        [false, 30]
      end
    end
  end
end
