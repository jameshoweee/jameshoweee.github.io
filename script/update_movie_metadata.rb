#!/usr/bin/env ruby
# Enriches _data/movies.yml with genre/director data from TMDB, caching the
# result in _data/movie_metadata.yml keyed by "title|year" so already-looked-up
# films aren't re-queried on every run (TMDB is free but rate-limited, and most
# runs only add a handful of new films).
#
# Requires TMDB_API_KEY in the environment (a TMDB v3 API key - see
# themoviedb.org account settings -> API).
#
# Also writes a pre-computed _data/movie_stats.yml with top genres/directors,
# since counting a multi-valued field (a film can have several genres) per
# film across the whole list isn't something Liquid's filters handle well -
# far simpler to do that aggregation here in Ruby and let the page just
# display an already-sorted result.

require "net/http"
require "json"
require "yaml"
require "uri"

API_KEY = ENV.fetch("TMDB_API_KEY") { abort "TMDB_API_KEY is not set" }
MOVIES_PATH = File.join(__dir__, "..", "_data", "movies.yml")
METADATA_PATH = File.join(__dir__, "..", "_data", "movie_metadata.yml")
STATS_PATH = File.join(__dir__, "..", "_data", "movie_stats.yml")

def tmdb_get(path, params)
  uri = URI("https://api.themoviedb.org/3#{path}")
  uri.query = URI.encode_www_form(params.merge(api_key: API_KEY))
  response = Net::HTTP.get_response(uri)
  return nil unless response.is_a?(Net::HTTPSuccess)

  JSON.parse(response.body)
end

movies = YAML.load_file(MOVIES_PATH) || []
metadata = File.exist?(METADATA_PATH) ? (YAML.load_file(METADATA_PATH) || {}) : {}

films = movies.map { |m| [m["title"], m["year"]] }.uniq
new_films = films.reject { |title, year| metadata.key?("#{title}|#{year}") }

puts "#{films.size} unique films, #{new_films.size} not yet cached"

new_films.each do |title, year|
  key = "#{title}|#{year}"
  details = tmdb_get("/search/movie", { query: title, year: year })
  next unless details && details["results"] && !details["results"].empty?

  match = details["results"].find { |r| r["release_date"].to_s.start_with?(year.to_s) } || details["results"].first
  full = tmdb_get("/movie/#{match['id']}", {})
  credits = tmdb_get("/movie/#{match['id']}/credits", {})
  director = credits && credits["crew"] && credits["crew"].find { |c| c["job"] == "Director" }

  metadata[key] = {
    "genres" => full && full["genres"] ? full["genres"].map { |g| g["name"] } : [],
    "director" => director && director["name"],
  }

  print "."
  sleep 0.25 # be polite to TMDB's rate limit
end
puts

File.write(METADATA_PATH, metadata.to_yaml)
puts "Wrote #{metadata.size} cached films to #{METADATA_PATH}"

# --- Aggregate stats, computed here rather than in Liquid ---

genre_counts = Hash.new(0)
director_counts = Hash.new(0)

films.each do |title, year|
  data = metadata["#{title}|#{year}"]
  next unless data

  (data["genres"] || []).each { |g| genre_counts[g] += 1 }
  director_counts[data["director"]] += 1 if data["director"]
end

top = ->(counts, n) { counts.sort_by { |_, c| -c }.first(n).map { |name, count| { "name" => name, "count" => count } } }

stats = {
  "top_genres" => top.call(genre_counts, 8),
  "top_directors" => top.call(director_counts, 8),
  # Full sorted director list for the page's filter dropdown - computed here
  # rather than in Liquid, which has no clean way to dedupe/sort a field
  # that lives in a separate joined data file.
  "all_directors" => director_counts.keys.sort,
}

File.write(STATS_PATH, stats.to_yaml)
puts "Wrote #{STATS_PATH}"
