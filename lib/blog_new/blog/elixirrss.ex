defmodule BlogNew.Blog.ElixirRSS do
  @moduledoc """
  This module contains functions from the elixir-rss library at https://github.com/BennyHallett/elixir-rss.git. The library is fine, but the version in Hex is outdated and bugged, so I've included the new version here.
  """
  def feed(channel, items) do
    """
    <?xml version="1.0" encoding="utf-8"?>
    <rss version="2.0">
    <channel>
    #{channel}#{Enum.join(items, "")}</channel>
    </rss>
    """
  end

  def item(title, desc, pubDate, link, guid) do
    """
    <item>
    <title>#{title}</title>
    <description><![CDATA[#{desc}]]></description>
    <pubDate>#{pubDate}</pubDate>
    <link>#{link}</link>
    <guid>#{guid}</guid>
    </item>
    """
  end

  def channel(title, link, desc, date, lang) do
    """
    <title>#{title}</title>
    <link>#{link}</link>
    <description>#{desc}</description>
    <lastBuildDate>#{date}</lastBuildDate>
    <language>#{lang}</language>
    """
  end
end
