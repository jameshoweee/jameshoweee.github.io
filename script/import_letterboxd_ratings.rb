#!/usr/bin/env ruby
# One-time import: adds films that have a rating on Letterboxd but were never
# logged with a specific watched date in the diary (e.g. things watched
# before the diary was kept - "Parasite" rated 5 stars in 2019 but with no
# diary entry). Reads ratings.csv from a Letterboxd data export and merges
# any films not already present into the existing _data/movies.yml, rather
# than regenerating it - the diary has since accumulated real updates from
# the daily Letterboxd sync (script/update_movies.rb) that must be kept.
#
# These entries get watched_date: '' (displayed as "N/A" on the page,
# per user preference - the ratings.csv "Date" column is when the rating was
# logged, not when the film was actually watched, so it isn't a reliable
# stand-in and showing it as if it were a watch date would be misleading).
#
# Run once by hand:
#   ruby script/import_letterboxd_ratings.rb /path/to/letterboxd-export-folder

require "csv"
require "yaml"
require "set"

export_dir = ARGV[0] or abort "usage: #{$0} <path-to-letterboxd-export-folder>"
ratings_path = File.join(export_dir, "ratings.csv")
likes_path = File.join(export_dir, "likes", "films.csv")
movies_path = File.join(__dir__, "..", "_data", "movies.yml")

abort "not found: #{ratings_path}" unless File.exist?(ratings_path)
abort "not found: #{likes_path}" unless File.exist?(likes_path)

movies = YAML.load_file(movies_path) || []
existing_films = movies.map { |m| [m["title"], m["year"]] }.to_set
liked_films = CSV.read(likes_path, headers: true).map { |row| [row["Name"], row["Year"].to_i] }.to_set

new_entries = []
CSV.read(ratings_path, headers: true).each do |row|
  title = row["Name"]
  year = row["Year"].to_i
  next if existing_films.include?([title, year])

  new_entries << {
    "title" => title,
    "year" => year,
    "watched_date" => "",
    "rating" => row["Rating"].to_s.empty? ? nil : row["Rating"].to_f,
    "liked" => liked_films.include?([title, year]),
    "rewatch" => false,
    "url" => row["Letterboxd URI"],
  }
  existing_films << [title, year] # ratings.csv can list the same film twice in edge cases
end

merged = movies + new_entries
merged.sort_by! { |e| [e["watched_date"], e["title"], e["year"]] }
merged.reverse!

File.write(movies_path, merged.to_yaml)
puts "Added #{new_entries.size} rated-but-undated films (#{movies.size} -> #{merged.size} total entries)"
