---
layout: page
title: Movies
permalink: /personal/movies/
nav: false
---

A diary of what I've watched, pulled automatically from [Letterboxd](https://letterboxd.com/jhowe/).

{% assign favorites = site.data.favorites %}
{% if favorites.size > 0 %}
<div class="section-label">Four Favorites</div>
<div class="favorite-films">
  {% for film in favorites %}
  {% assign fav_key = film.title | append: "|" | append: film.year %}
  {% assign fav_meta = site.data.movie_metadata[fav_key] %}
  <div class="favorite-film">
    {% if fav_meta.poster %}
      <img src="{{ fav_meta.poster }}" alt="{{ film.title }} ({{ film.year }}) poster">
    {% else %}
      <div class="favorite-film-placeholder">{{ film.title }}</div>
    {% endif %}
    <div class="favorite-film-title">{{ film.title }}</div>
  </div>
  {% endfor %}
</div>
{% endif %}

{% assign movies = site.data.movies | sort: "watched_date" | reverse %}
{% assign all_directors = site.data.movie_stats.all_directors %}

{% if site.data.movie_stats.top_genres.size > 0 or site.data.movie_stats.top_directors.size > 0 %}
<div class="movie-favorites">
  {% if site.data.movie_stats.top_genres.size > 0 %}
  <div>
    <div class="section-label">Favorite Genres</div>
    <div class="tags">
      {% for g in site.data.movie_stats.top_genres %}<span>{{ g.name }} ({{ g.count }})</span>{% endfor %}
    </div>
  </div>
  {% endif %}
  {% if site.data.movie_stats.top_directors.size > 0 %}
  <div>
    <div class="section-label">Favorite Directors</div>
    <div class="tags">
      {% for d in site.data.movie_stats.top_directors %}<span>{{ d.name }} ({{ d.count }})</span>{% endfor %}
    </div>
  </div>
  {% endif %}
</div>
{% endif %}

<div class="movie-controls">
  <label>
    Sort by
    <select id="movie-sort">
      <option value="date-desc">Watched (newest)</option>
      <option value="date-asc">Watched (oldest)</option>
      <option value="rating-desc">Rating (highest)</option>
      <option value="rating-asc">Rating (lowest)</option>
      {% if all_directors.size > 0 %}<option value="director">Director</option>{% endif %}
    </select>
  </label>
  {% if all_directors.size > 0 %}
  <label>
    Director
    <select id="movie-director-filter">
      <option value="">All directors</option>
      {% for d in all_directors %}<option value="{{ d }}">{{ d }}</option>{% endfor %}
    </select>
  </label>
  {% endif %}
</div>

<ul class="movie-list">
  {% for movie in movies %}
  {% assign meta_key = movie.title | append: "|" | append: movie.year %}
  {% assign meta = site.data.movie_metadata[meta_key] %}
  <li class="movie-row" data-date="{{ movie.watched_date }}" data-rating="{{ movie.rating }}" data-director="{{ meta.director }}">
    <div class="movie-main">
      <a class="movie-title" href="{{ movie.url }}">{{ movie.title }}</a>
      <span class="movie-year">({{ movie.year }})</span>
      {% if movie.liked %}<span class="movie-liked" title="Liked">&hearts;</span>{% endif %}
      {% if movie.rewatch %}<span class="movie-rewatch" title="Rewatch">&#8635;</span>{% endif %}
      {% if meta.director %}<span class="movie-director">{{ meta.director }}</span>{% endif %}
    </div>
    <div class="movie-meta">
      {% if movie.rating %}
        <span class="movie-rating">
          {% assign full_stars = movie.rating | floor %}
          {% assign half_star = movie.rating | minus: full_stars %}
          {% for i in (1..full_stars) %}&#9733;{% endfor %}{% if half_star >= 0.5 %}&#189;{% endif %}
        </span>
      {% endif %}
      <span class="movie-date">{{ movie.watched_date | date: "%-d %b %Y" }}</span>
    </div>
  </li>
  {% endfor %}
</ul>

<script src="{{ site.baseurl }}/public/js/movies.js" defer></script>
