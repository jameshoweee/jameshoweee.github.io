(function () {
  var list = document.querySelector(".movie-list");
  if (!list) return;

  var sortSelect = document.getElementById("movie-sort");
  var directorSelect = document.getElementById("movie-director-filter");

  function rows() {
    return Array.prototype.slice.call(list.querySelectorAll(".movie-row"));
  }

  function applySort() {
    var mode = sortSelect ? sortSelect.value : "date-desc";
    var sorted = rows().sort(function (a, b) {
      switch (mode) {
        case "date-asc":
          return a.dataset.date.localeCompare(b.dataset.date);
        case "rating-desc":
          return parseFloat(b.dataset.rating || 0) - parseFloat(a.dataset.rating || 0);
        case "rating-asc":
          return parseFloat(a.dataset.rating || 0) - parseFloat(b.dataset.rating || 0);
        case "director":
          return (a.dataset.director || "").localeCompare(b.dataset.director || "");
        case "date-desc":
        default:
          return b.dataset.date.localeCompare(a.dataset.date);
      }
    });
    sorted.forEach(function (row) {
      list.appendChild(row);
    });
  }

  function applyFilter() {
    var director = directorSelect ? directorSelect.value : "";
    rows().forEach(function (row) {
      var show = !director || row.dataset.director === director;
      row.style.display = show ? "" : "none";
    });
  }

  if (sortSelect) sortSelect.addEventListener("change", applySort);
  if (directorSelect) directorSelect.addEventListener("change", applyFilter);
})();
