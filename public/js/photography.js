(function () {
  var grid = document.querySelector(".photo-grid");
  if (!grid) return;

  // True masonry (each photo placed into the currently-shortest column) is
  // used instead of CSS column-count: CSS columns fill one column fully
  // before starting the next, and break-inside:avoid can strand an item
  // that doesn't quite fit, leaving a gap at the bottom of that column.
  // Placing items greedily avoids that entirely and keeps photos in date
  // order (the order they're already in) rather than needing to reorder
  // them to dodge awkward gaps. Uses each photo's width/height attributes
  // (known at build time) so layout doesn't have to wait for lazy-loaded
  // images to actually download.
  var GAP = 20;

  function columnCount() {
    if (window.innerWidth <= 560) return 1;
    if (window.innerWidth >= 700) return 3;
    return 2;
  }

  function layoutMasonry() {
    var items = Array.prototype.slice.call(grid.querySelectorAll(".photo-item"));
    if (!items.length) return;

    var columns = columnCount();
    var colWidth = (grid.clientWidth - GAP * (columns - 1)) / columns;
    var colHeights = new Array(columns).fill(0);

    // Set widths first so each item's rendered height (image via its
    // width/height attributes, caption via real text wrapping) is correct
    // before we measure it below.
    items.forEach(function (item) {
      item.style.position = "absolute";
      item.style.margin = "0";
      item.style.width = colWidth + "px";
    });

    items.forEach(function (item) {
      var col = colHeights.indexOf(Math.min.apply(null, colHeights));
      item.style.left = col * (colWidth + GAP) + "px";
      item.style.top = colHeights[col] + "px";
      colHeights[col] += item.offsetHeight + GAP;
    });

    grid.style.position = "relative";
    grid.style.height = Math.max.apply(null, colHeights) - GAP + "px";
  }

  layoutMasonry();
  var resizeTimer;
  window.addEventListener("resize", function () {
    clearTimeout(resizeTimer);
    resizeTimer = setTimeout(layoutMasonry, 150);
  });

  var overlay = document.createElement("div");
  overlay.className = "lightbox-overlay";
  overlay.innerHTML = '<img class="lightbox-img" alt="">';
  document.body.appendChild(overlay);
  var img = overlay.querySelector(".lightbox-img");

  function open(src, alt) {
    img.src = src;
    img.alt = alt || "";
    overlay.classList.add("is-open");
    document.body.style.overflow = "hidden";
  }

  function close() {
    overlay.classList.remove("is-open");
    document.body.style.overflow = "";
    img.src = "";
  }

  grid.querySelectorAll(".photo-link").forEach(function (link) {
    link.addEventListener("click", function (e) {
      e.preventDefault();
      var thumb = link.querySelector("img");
      open(link.getAttribute("href"), thumb ? thumb.alt : "");
    });
  });

  overlay.addEventListener("click", close);
  document.addEventListener("keydown", function (e) {
    if (e.key === "Escape") close();
  });
})();
