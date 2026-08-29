---
layout: page
title: Photography
permalink: /personal/photography/
nav: false
---

A few photos I've taken. Shown downsized, with EXIF metadata stripped from the
file and rendered as a caption instead. Click a photo for a larger view.

{% assign photos = site.data.photos %}
{% if photos.size == 0 %}
<p class="muted">Coming soon.</p>
{% else %}
<div class="photo-grid">
  {% for photo in photos %}
  <figure class="photo-item">
    <a class="photo-link" href="{{ photo.large_file }}">
      <img src="{{ photo.file }}" alt="{{ photo.location | default: 'Photo' }}" loading="lazy" width="{{ photo.width }}" height="{{ photo.height }}">
    </a>
    <figcaption class="photo-caption">
      <span class="photo-location">{{ photo.location }}</span>
      <div class="photo-exif">
        {% if photo.camera %}<span>{{ photo.camera }}</span>{% endif %}
        {% if photo.lens %}<span>{{ photo.lens }}</span>{% endif %}
        {% if photo.focal_length %}<span>{{ photo.focal_length }}</span>{% endif %}
        {% if photo.aperture %}<span>{{ photo.aperture }}</span>{% endif %}
        {% if photo.shutter %}<span>{{ photo.shutter }}</span>{% endif %}
        {% if photo.iso %}<span>ISO {{ photo.iso }}</span>{% endif %}
        {% if photo.date %}<span>{{ photo.date | date: "%-d %b %Y" }}</span>{% endif %}
      </div>
    </figcaption>
  </figure>
  {% endfor %}
</div>
{% endif %}

<script src="{{ site.baseurl }}/public/js/photography.js" defer></script>
