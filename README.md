# jameshowe.eu

Source for [James Howe](https://jameshowe.eu)'s personal site — a cryptography research/professional homepage covering publications, talks, and contact info.

## Stack

Built with [Jekyll](https://jekyllrb.com), on top of the [Lanyon](https://github.com/poole/lanyon) theme (itself built on [Poole](https://github.com/poole/poole)), and deployed via [GitHub Pages](https://pages.github.com/) with a custom domain (see `CNAME`).

## Structure

- `_config.yml` — site config (title, description, analytics, plugins)
- `_layouts/`, `_includes/` — Jekyll templates
- `public/css/` — Lanyon/Poole theme CSS
- `*.md` — page content (`index.md`, `papers.md`, `talks.md`, `saga.md`, `contact.md`)
- `files/` — CV, slides, posters, and other downloadable assets referenced from the pages above

## Local development

```sh
bundle install
bundle exec jekyll serve
```

## License

Theme CSS/layout originally released under the MIT license by [Mark Otto](https://github.com/mdo) — see `LICENSE.md`.
