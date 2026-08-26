#!/usr/bin/env ruby
# One-time import: builds _data/movies.yml from a full Letterboxd data
# export, reconciling three separate CSVs that each cover a different,
# overlapping slice of "movies I've watched":
#
#   - diary.csv:   dated log entries, with rating/rewatch. The only source
#                  with a real watched date. Can have multiple rows for the
#                  same film (rewatches).
#   - ratings.csv: every film ever rated, dated by when it was RATED, not
#                  watched - not a reliable stand-in for a watch date.
#   - watched.csv: every film ever marked watched, the complete superset
#                  (1307 films, matching Letterboxd's own /stats page) -
#                  most of these have neither a diary entry nor a rating.
#
# Every diary.csv row becomes its own entry (preserving rewatches). Every
# other watched.csv film becomes one entry with watched_date: '' ("no real
# watch date"), using its ratings.csv rating if one exists, or rating: nil
# ("never rated") otherwise. Run once by hand:
#   ruby script/import_letterboxd_backfill.rb /path/to/letterboxd-export-folder
#
# Ongoing updates after this come from script/update_movies.rb instead, which
# merges new diary entries from the public RSS feed into the same file (the
# RSS feed only ever exposes dated diary entries, not the full watched/rated
# lists, so newly watched-but-undiaried films need a re-run of this script
# against a fresh export to pick up).

require "csv"
require "yaml"
require "set"

export_dir = ARGV[0] or abort "usage: #{$0} <path-to-letterboxd-export-folder>"
diary_path = File.join(export_dir, "diary.csv")
ratings_path = File.join(export_dir, "ratings.csv")
watched_path = File.join(export_dir, "watched.csv")
likes_path = File.join(export_dir, "likes", "films.csv")

[diary_path, ratings_path, watched_path, likes_path].each do |p|
  abort "not found: #{p}" unless File.exist?(p)
end

liked_films = CSV.read(likes_path, headers: true).map { |row| [row["Name"], row["Year"].to_i] }.to_set

# ratings.csv can list a film more than once in edge cases; last one wins,
# which is fine since Letterboxd only keeps one current rating per film.
ratings_by_film = {}
CSV.read(ratings_path, headers: true).each do |row|
  next if row["Rating"].to_s.empty?

  ratings_by_film[[row["Name"], row["Year"].to_i]] = row["Rating"].to_f
end

diary_entries = CSV.read(diary_path, headers: true).map do |row|
  key = [row["Name"], row["Year"].to_i]
  {
    "title" => row["Name"],
    "year" => row["Year"].to_i,
    "watched_date" => row["Watched Date"],
    "rating" => row["Rating"].to_s.empty? ? nil : row["Rating"].to_f,
    "liked" => liked_films.include?(key),
    "rewatch" => row["Rewatch"] == "Yes",
    "url" => row["Letterboxd URI"],
  }
end
diaried_films = diary_entries.map { |e| [e["title"], e["year"]] }.to_set

undiaried_entries = []
CSV.read(watched_path, headers: true).each do |row|
  key = [row["Name"], row["Year"].to_i]
  next if diaried_films.include?(key)

  undiaried_entries << {
    "title" => row["Name"],
    "year" => row["Year"].to_i,
    "watched_date" => "",
    "rating" => ratings_by_film[key],
    "liked" => liked_films.include?(key),
    "rewatch" => false,
    "url" => row["Letterboxd URI"],
  }
end

entries = diary_entries + undiaried_entries

# Tiebreak on title+year so same-day (or same-no-date) entries sort
# deterministically, matching script/update_movies.rb's ordering - otherwise
# the merge script sees a spurious "change" on its first run for no actual
# data reason.
entries.sort_by! { |e| [e["watched_date"], e["title"], e["year"]] }
entries.reverse!

out_path = File.join(__dir__, "..", "_data", "movies.yml")
File.write(out_path, entries.to_yaml)

puts "#{diary_entries.size} diary entries + #{undiaried_entries.size} watched-only films = #{entries.size} total"
