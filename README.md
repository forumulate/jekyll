# jekyll-forumulate

Forumulate for Jekyll: Liquid tags for comments, the docs search / ask-AI box
and the "What's new" changelog bell, plus build-time tags that render your
public blog posts, forum topics, changelog releases and docs pages straight
into the static HTML.

## Install

```ruby
# Gemfile
group :jekyll_plugins do
  gem "jekyll-forumulate"
end
```

```yaml
# _config.yml
forumulate:
  org: acme              # organization slug or id
  space: community       # default space; every tag accepts space="..."
  # base_url: https://forumulate.com   # or your custom domain
  # api_url:                           # defaults to base_url + /api
  # mode: elements                     # emit <forumulate-*> custom elements
  # cache_ttl: 300                     # seconds, kept in .jekyll-cache
```

## Embeds

```liquid
{% forumulate_comments %}
{% forumulate_comments space="blog-comments" theme="dark" topic=page.forumulate_topic %}
{% forumulate_widget mode="ask" placeholder="Ask the docs" %}
{% forumulate_changelog space="changelog" %}
```

Quoted values are literals, unquoted ones are Liquid variables. Every value is
HTML-escaped into a `data-*` attribute (or an element attribute in `elements`
mode; `use_elements="true"` switches one tag).

## Build-time content

```liquid
{% forumulate_items blog limit=5 as posts %}
<ul>{% for post in posts %}
  <li><a href="{{ post.url }}">{{ post.title | escape }}</a></li>
{% endfor %}</ul>

{% forumulate_item forum page.topic as topic %}
{% forumulate_markdown blog page.post_slug as body %}{{ body | forumulate_html }}
```

Kinds: `blog`, `forum`, `changelog`, `docs`. Only the public read API is used,
no token. If Forumulate is unreachable the build logs a warning and the list is
empty — a build never fails because of it. `forumulate_html` renders Markdown
with raw HTML, event attributes and `javascript:` links removed (forum posts are
written by visitors). Rebuild (or schedule a rebuild) to pick up new content.

## License

MIT

---

## About this repository

This repository is a public mirror, refreshed on each Forumulate release
(one commit per release). Pull requests are welcome; accepted changes are
applied upstream and arrive here with the next release.

- API reference: https://forumulate.com/reference
- Guides: https://forumulate.com/guides
- Community and support: https://forumulate.com/community
- Source: https://github.com/forumulate/jekyll
