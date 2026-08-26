#!/usr/bin/env ruby
# Enriches _data/movies.yml with genre/director data from TMDB, caching the
# result in _data/movie_metadata.yml keyed by "title|year" so already-looked-up
# films aren't re-queried on every run (TMDB is free but rate-limited, and most
# runs only add a handful of new films).
#
# Requires TMDB_API_KEY in the environment - either a v3 API key or a v4 Read
# Access Token both work, since requests are authenticated via the
# Authorization header (see themoviedb.org account settings -> API).
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
FAVORITES_PATH = File.join(__dir__, "..", "_data", "favorites.yml")
METADATA_PATH = File.join(__dir__, "..", "_data", "movie_metadata.yml")
STATS_PATH = File.join(__dir__, "..", "_data", "movie_stats.yml")
POSTER_BASE = "https://image.tmdb.org/t/p/w500"

$tmdb_errors_logged = 0
# TMDB has two credential styles: a v3 API key (passed as ?api_key=) and a v4
# Read Access Token (passed as an Authorization: Bearer header). Since either
# could be what's stored in the secret, try Bearer first and fall back to the
# query-param style rather than guessing which one was configured.
$tmdb_auth_style = :bearer

def tmdb_get(path, params)
  uri = URI("https://api.themoviedb.org/3#{path}")
  request_with = lambda do |style|
    u = uri.dup
    req_params = params.dup
    headers = {}
    if style == :bearer
      headers["Authorization"] = "Bearer #{API_KEY}"
    else
      req_params[:api_key] = API_KEY
    end
    u.query = URI.encode_www_form(req_params)
    Net::HTTP.start(u.host, u.port, use_ssl: true) do |http|
      http.get(u.request_uri, headers)
    end
  end

  response = request_with.call($tmdb_auth_style)
  if response.code == "401" && $tmdb_auth_style == :bearer
    $tmdb_auth_style = :api_key
    response = request_with.call($tmdb_auth_style)
  end

  unless response.is_a?(Net::HTTPSuccess)
    if $tmdb_errors_logged < 3
      warn "TMDB request failed: #{path} -> #{response.code} #{response.body&.slice(0, 300)}"
      $tmdb_errors_logged += 1
    end
    return nil
  end

  JSON.parse(response.body)
end

movies = YAML.load_file(MOVIES_PATH) || []
favorites = File.exist?(FAVORITES_PATH) ? (YAML.load_file(FAVORITES_PATH) || []) : []
metadata = File.exist?(METADATA_PATH) ? (YAML.load_file(METADATA_PATH) || {}) : {}

diary_films = movies.map { |m| [m["title"], m["year"]] }
favorite_films = favorites.map { |f| [f["title"], f["year"]] }
films = (diary_films + favorite_films).uniq
# A film "needs" a lookup if it's not cached at all, OR if it's cached from
# before "runtime"/"countries"/"director_gender" were added below -
# re-fetching those for already-cached films costs nothing extra since they
# come from the same /movie/{id} and /credits responses already being made
# for genres/poster/director.
new_films = films.reject { |title, year| metadata["#{title}|#{year}"]&.key?("director_gender") }

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
    # TMDB's credits response already tags each crew member with a gender
    # code (0 unspecified, 1 female, 2 male, 3 non-binary) - free from the
    # same call, no extra request needed to build a "top women directors" list.
    "director_gender" => director && director["gender"],
    "poster" => full && full["poster_path"] ? "#{POSTER_BASE}#{full['poster_path']}" : nil,
    "runtime" => full && full["runtime"],
    "countries" => full && full["production_countries"] ? full["production_countries"].map { |c| c["name"] } : [],
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
director_genders = {}
country_counts = Hash.new(0)

films.each do |title, year|
  data = metadata["#{title}|#{year}"]
  next unless data

  (data["genres"] || []).each { |g| genre_counts[g] += 1 }
  if data["director"]
    director_counts[data["director"]] += 1
    director_genders[data["director"]] = data["director_gender"]
  end
  (data["countries"] || []).each { |c| country_counts[c] += 1 }
end

# TMDB gender code 1 = female.
women_director_counts = director_counts.select { |name, _| director_genders[name] == 1 }

# Hours watched counts every logged watch (a rewatch counts its runtime
# again), unlike the other stats which count each unique film once - so this
# sums over the diary rows in movies.yml, not the deduped `films` list.
total_minutes = diary_films.sum { |title, year| metadata["#{title}|#{year}"]&.fetch("runtime", nil) || 0 }

top = ->(counts, n) { counts.sort_by { |_, c| -c }.first(n).map { |name, count| { "name" => name, "count" => count } } }
# Liquid has no built-in thousands-separator filter, so format for display here.
with_commas = ->(n) { n.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse }

stats = {
  "film_count" => with_commas.call(films.size),
  "hours_watched" => with_commas.call((total_minutes / 60.0).round),
  "director_count" => with_commas.call(director_counts.keys.size),
  "country_count" => with_commas.call(country_counts.keys.size),
  "top_genres" => top.call(genre_counts, 8),
  "top_directors" => top.call(director_counts, 8),
  "top_women_directors" => top.call(women_director_counts, 4),
  # Full sorted director list for the page's filter dropdown - computed here
  # rather than in Liquid, which has no clean way to dedupe/sort a field
  # that lives in a separate joined data file.
  "all_directors" => director_counts.keys.sort,
}

File.write(STATS_PATH, stats.to_yaml)
puts "Wrote #{STATS_PATH}"
