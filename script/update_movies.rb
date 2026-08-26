#!/usr/bin/env ruby
# Scheduled update: pulls recent entries from the public Letterboxd RSS feed
# and merges any new ones into _data/movies.yml (the file seeded once by
# script/import_letterboxd_backfill.rb). Letterboxd's feed only exposes a
# rolling recent window (~50 entries), so this merges by (title, year,
# watched_date) rather than overwriting, to avoid losing the backfilled
# history whenever an old entry scrolls out of the feed.

require "net/http"
require "rexml/document"
require "yaml"

FEED_URL = "https://letterboxd.com/jhowe/rss/"
DATA_PATH = File.join(__dir__, "..", "_data", "movies.yml")

def text_of(item, name)
  el = item.get_elements(".//*[local-name()='#{name}']").first
  el && el.text && el.text.strip
end

uri = URI(FEED_URL)
response = Net::HTTP.get_response(uri)
abort "failed to fetch feed: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

doc = REXML::Document.new(response.body)

feed_entries = doc.get_elements("//item").map do |item|
  {
    "title" => text_of(item, "filmTitle"),
    "year" => text_of(item, "filmYear").to_i,
    "watched_date" => text_of(item, "watchedDate"),
    "rating" => (r = text_of(item, "memberRating")) && !r.empty? ? r.to_f : nil,
    "liked" => text_of(item, "memberLike") == "Yes",
    "rewatch" => text_of(item, "rewatch") == "Yes",
    "url" => item.get_elements("link").first&.text&.strip,
  }
end

abort "no items parsed from feed - aborting without touching the data file" if feed_entries.empty?

existing = File.exist?(DATA_PATH) ? (YAML.load_file(DATA_PATH) || []) : []

# Include rewatch in the key: the same film can legitimately be logged twice
# on the same day (e.g. watched again later that day), distinguished only by
# the rewatch flag on the second entry. This is a best-effort key, not a
# perfect one - three+ same-day same-flag entries for one film would still
# collide, but that's an extreme edge case.
key = ->(e) { [e["title"], e["year"], e["watched_date"], e["rewatch"]] }
by_key = {}
existing.each { |e| by_key[key.call(e)] = e }
feed_entries.each { |e| by_key[key.call(e)] = e }

# Tiebreak on title+year too: without a secondary key, entries watched on the
# same date can silently reorder between runs (Ruby's sort isn't stable for
# ties), which made the file "change" every run even with no new data. Title
# alone isn't enough - two different films can share a title (e.g. the 2014
# "Next Goal Wins" documentary and the 2023 film of the same name).
merged = by_key.values.sort_by { |e| [e["watched_date"], e["title"], e["year"]] }.reverse

if merged != existing
  File.write(DATA_PATH, merged.to_yaml)
  puts "Updated #{DATA_PATH}: #{existing.size} -> #{merged.size} entries"
else
  puts "No changes"
end
