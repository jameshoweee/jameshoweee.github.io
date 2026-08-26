#!/usr/bin/env ruby
# One-time import: turns a Letterboxd data export (diary.csv + likes/films.csv)
# into _data/movies.yml. Run once by hand:
#   ruby script/import_letterboxd_backfill.rb /path/to/letterboxd-export-folder
#
# Ongoing updates after this come from script/update_movies.rb instead, which
# merges new entries from the public RSS feed into the same file.

require "csv"
require "yaml"
require "set"

export_dir = ARGV[0] or abort "usage: #{$0} <path-to-letterboxd-export-folder>"
diary_path = File.join(export_dir, "diary.csv")
likes_path = File.join(export_dir, "likes", "films.csv")

abort "not found: #{diary_path}" unless File.exist?(diary_path)
abort "not found: #{likes_path}" unless File.exist?(likes_path)

# Letterboxd's "Letterboxd URI" column is a boxd.it short link that is NOT
# stable per film — the same film can get a different shortlink on different
# rows (confirmed: two diary entries for the same rewatched film had two
# different URIs). Title+year is the only reliable join key across CSVs.
liked_films = CSV.read(likes_path, headers: true).map { |row| [row["Name"], row["Year"]] }.to_set

entries = CSV.read(diary_path, headers: true).map do |row|
  {
    "title" => row["Name"],
    "year" => row["Year"].to_i,
    "watched_date" => row["Watched Date"],
    "rating" => row["Rating"].to_s.empty? ? nil : row["Rating"].to_f,
    "liked" => liked_films.include?([row["Name"], row["Year"]]),
    "rewatch" => row["Rewatch"] == "Yes",
    "url" => row["Letterboxd URI"],
  }
end

# Tiebreak on title+year so same-day entries sort deterministically, matching
# script/update_movies.rb's ordering (otherwise the merge script would see
# a spurious "change" on its first run for no actual data reason). Title
# alone isn't enough - two different films can share a title (e.g. the 2014
# "Next Goal Wins" documentary and the 2023 film of the same name, watched
# the same day).
entries.sort_by! { |e| [e["watched_date"], e["title"], e["year"]] }
entries.reverse!

out_path = File.join(__dir__, "..", "_data", "movies.yml")
File.write(out_path, entries.to_yaml)

puts "Wrote #{entries.size} entries to #{File.expand_path(out_path)}"
