---
layout: page
title: Movies
permalink: /personal/movies/
nav: false
---

A diary of what I've watched, pulled automatically from [Letterboxd](https://letterboxd.com/jhowe/).

{% assign movies = site.data.movies | sort: "watched_date" | reverse %}
<ul class="movie-list">
  {% for movie in movies %}
  <li class="movie-row">
    <div class="movie-main">
      <a class="movie-title" href="{{ movie.url }}">{{ movie.title }}</a>
      <span class="movie-year">({{ movie.year }})</span>
      {% if movie.liked %}<span class="movie-liked" title="Liked">&hearts;</span>{% endif %}
      {% if movie.rewatch %}<span class="movie-rewatch" title="Rewatch">&#8635;</span>{% endif %}
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
