#!/usr/bin/env ruby
# Builds public/photos/*.jpg (downsized, EXIF-stripped derivatives) and
# _data/photos.yml (extracted EXIF rendered as text, plus a manually-supplied
# location caption) from a folder of full-quality original photos that lives
# OUTSIDE this repo.
#
# This is deliberate: the repo is public, and anything committed to git history
# is downloadable forever via `git clone`, regardless of any page-level
# restriction. True originals - and their embedded GPS/camera EXIF - must never
# be committed. This script reads originals from an external folder and only
# ever WRITES the processed derivatives into the repo.
#
# Two derivatives are produced per photo, mirroring how professional
# proofing/stock galleries handle this trade-off (a website can never stop
# someone saving whatever bytes it serves - the only real lever is controlling
# what gets served). Both get the same white print-mat + signature treatment
# for a consistent, signed presentation at every size:
#   - "web": what shows in the gallery grid. Small, and the mat/signature is
#     trivially cropped out - but the photo underneath is capped well short
#     of any usable/print size anyway, so cropping the mat off buys little.
#   - "large": what opens when a thumbnail is clicked, for viewing real detail
#     and colour. Same mat/signature, PLUS a large, semi-transparent watermark
#     diagonally across the CENTER of the photo itself, which can't be cropped
#     out without destroying the image, matching how stock-photo previews work.
#
# The signature itself is rendered separately via HarfBuzz (`hb-view`), not
# ImageMagick's -annotate: ImageMagick's basic text renderer looks up glyphs
# directly by character and skips a font's contextual-alternate/ligature
# tables entirely, which is exactly the data script fonts rely on for
# letters to join up convincingly. HarfBuzz is a real OpenType shaping
# engine (what browsers use) and applies that data properly. The rendered
# signature is then thinned via alpha-channel erosion (Mrs Sheppards'
# default weight read as too bold) and composited as an image rather than
# drawn as text.
#
# Requires (one-time, local machine only - never runs in CI):
#   brew install exiftool imagemagick harfbuzz
# Also requires the signature font installed locally (one-time):
#   cp MrsSheppards-Regular.ttf ~/Library/Fonts/
#
# Usage: point it at a folder containing the original images plus a
# captions.yml sidecar (filename -> manual location string, e.g.
# "Reykjavik, Iceland" - NOT derived from GPS EXIF, so exact coordinates are
# never extracted or published):
#   ruby script/build_photos.rb ~/Pictures/jameshowe-site-photos
#
# Rebuilds _data/photos.yml and public/photos/ from scratch on every run
# (no incremental caching, unlike update_movie_metadata.rb's TMDB cache -
# exiftool/magick are instant local calls with no rate limit, so there's
# nothing worth caching).

require "open3"
require "json"
require "yaml"
require "fileutils"

# The two derivatives are deliberately different sizes, not just different
# watermarks: the grid preview is kept small (a real deterrent on its own -
# even with the mat cropped out, it's short of any usable/print size), while
# the large/detail view stays big for genuine detail/colour viewing, relying
# entirely on the un-croppable center watermark for protection rather than
# obscurity.
MAX_DIMENSION_WEB   = 1200  # long-edge px cap for the grid preview
MAX_DIMENSION_LARGE = 2000  # long-edge px cap for the click-through detail view
JPEG_QUALITY  = 88     # tune freely

# Homebrew's ImageMagick ships with no fonts.xml registered on this machine
# (`magick -list font` returns nothing), so -annotate needs explicit font
# files rather than font names - point straight at macOS system fonts.
CAPTION_FONT       = "/System/Library/Fonts/Helvetica.ttc"
LARGE_MARK_FONT    = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"

SIGNATURE_FONT           = File.expand_path("~/Library/Fonts/MrsSheppards-Regular.ttf")
SIGNATURE_TEXT           = "James Howe"
SIGNATURE_RENDER_SIZE    = 300  # hb-view --font-size; rendered once, then scaled down per mat
SIGNATURE_ERODE_LEVEL    = 3    # alpha-channel thinning; 3 is the most that stays fully joined - 4+ starts breaking strokes apart
INK_COLOR      = "#221f1a"
MUTED_COLOR    = "#6b6459"

# Mat sizes scale with each derivative's own resolution, so the mat reads
# with the same proportions whether it's the small grid image or the large
# detail view. signature_height is the target pixel height of the
# (pre-rendered, pre-thinned) signature image once composited.
MAT_WEB = {
  border: 18, bottom_extra: 50, signature_height: 34, signature_offset: "+0+20",
  caption_pointsize: 10, caption_offset: "+0+11",
}
MAT_LARGE = {
  border: 28, bottom_extra: 84, signature_height: 56, signature_offset: "+0+34",
  caption_pointsize: 15, caption_offset: "+0+18",
}

LARGE_MARK_TEXT      = "© JAMES HOWE"
LARGE_MARK_POINTSIZE = 130

PHOTOS_DIR = File.join(__dir__, "..", "public", "photos")
DATA_PATH  = File.join(__dir__, "..", "_data", "photos.yml")

source_dir = ARGV[0] or abort "usage: #{$0} <path-to-source-photo-folder>"
abort "not found: #{source_dir}" unless File.directory?(source_dir)

captions_path = File.join(source_dir, "captions.yml")
abort "not found: #{captions_path}" unless File.exist?(captions_path)
captions = YAML.load_file(captions_path) || {}

%w[exiftool magick hb-view].each do |bin|
  abort "#{bin} not found on PATH - run: brew install exiftool imagemagick harfbuzz" if `which #{bin}`.strip.empty?
end
abort "signature font not found - copy MrsSheppards-Regular.ttf to ~/Library/Fonts/" unless File.exist?(SIGNATURE_FONT)

FileUtils.mkdir_p(PHOTOS_DIR)

def combine_make_model(make, model)
  return model || make if make.nil? || model.nil?
  model.start_with?(make) ? model : "#{make} #{model}"
end

# Render the signature once via HarfBuzz (real OpenType shaping, so the
# font's contextual-alternate/ligature data actually gets applied - see the
# top-of-file comment), then thin it via alpha-channel erosion. Reused for
# every photo since the text never changes.
signature_source = "/tmp/build_photos_signature_raw.png"
signature_png     = "/tmp/build_photos_signature.png"
_, err, status = Open3.capture3(
  "hb-view", "--font-file=#{SIGNATURE_FONT}", "--font-size=#{SIGNATURE_RENDER_SIZE}",
  "--features=+liga,+dlig,+calt,+clig,+swsh",
  "--foreground=#{INK_COLOR}ff", "--background=00000000",
  "--output-file=#{signature_source}", SIGNATURE_TEXT
)
abort "hb-view failed: #{err}" unless status.success?
_, err, status = Open3.capture3("magick", signature_source, "-channel", "A", "-morphology", "Erode", "Octagon:#{SIGNATURE_ERODE_LEVEL}", "+channel", signature_png)
abort "magick (signature erode) failed: #{err}" unless status.success?

# Args for the shared white-mat + signature treatment, sized per `mat`
# (MAT_WEB or MAT_LARGE).
def mat_args(mat, caption_text, signature_png)
  [
    "-bordercolor", "white", "-border", "#{mat[:border]}x#{mat[:border]}",
    "-gravity", "South", "-background", "white", "-splice", "0x#{mat[:bottom_extra]}",
    "(", signature_png, "-resize", "x#{mat[:signature_height]}", ")",
    "-gravity", "South", "-geometry", mat[:signature_offset], "-compose", "over", "-composite",
    "-gravity", "South",
    "-font", CAPTION_FONT, "-pointsize", mat[:caption_pointsize].to_s, "-fill", MUTED_COLOR,
    "-annotate", mat[:caption_offset], caption_text,
  ]
end

image_paths = Dir.glob(File.join(source_dir, "*")).select { |f| f =~ /\.jpe?g\z/i }.sort
entries = []

image_paths.each do |src|
  filename = File.basename(src)
  location = captions[filename] or abort "no caption entry for #{filename} in #{captions_path}"
  basename = File.basename(src, ".*").downcase
  web_dest   = File.join(PHOTOS_DIR, "#{basename}.jpg")
  large_dest = File.join(PHOTOS_DIR, "#{basename}-large.jpg")

  # Deliberately no -GPS* tags requested at all - never even extract GPS,
  # on top of stripping it later (defense in depth).
  json_out, err, status = Open3.capture3(
    "exiftool", "-json", "-d", "%Y-%m-%d",
    "-Make", "-Model", "-LensModel", "-LensID", "-LensInfo",
    "-ISO", "-FNumber", "-ExposureTime", "-FocalLength",
    "-DateTimeOriginal", "-CreateDate",
    src
  )
  abort "exiftool failed on #{filename}: #{err}" unless status.success?
  exif = JSON.parse(json_out).first

  lens = [exif["LensModel"], exif["LensID"], exif["LensInfo"]].find { |v| v && !v.to_s.strip.empty? }

  shutter = exif["ExposureTime"]&.to_s
  shutter += "s" if shutter && !shutter.include?("/")

  focal_length = exif["FocalLength"]&.to_s&.sub(/(\.0)?\s*mm\z/, "mm")

  date = exif["DateTimeOriginal"] || exif["CreateDate"]
  # Copyright year matches when the photo was taken, not when it was
  # processed - falls back to the current year for the rare file with no
  # extractable date at all.
  copyright_year = date ? date.split("-").first : Time.now.year.to_s
  caption_text = "© #{copyright_year} James Howe · jameshowe.eu"

  # -auto-orient must run before metadata is stripped (rotation often lives
  # only in EXIF, not the pixels). Both derivatives start from the same
  # large-resized base so their content/scale matches exactly; the web
  # derivative is downsized further below.
  _, err, status = Open3.capture3("magick", src, "-auto-orient", "-resize", "#{MAX_DIMENSION_LARGE}x#{MAX_DIMENSION_LARGE}>", "/tmp/build_photos_base.jpg")
  abort "magick (base resize) failed on #{filename}: #{err}" unless status.success?

  # "web" derivative: downsized further, then the white mat + signature.
  # Cropped out trivially, but this is the small grid image - and even the
  # photo underneath the mat is capped well short of any usable print size.
  # The real protection for detail viewing is the "large" derivative below.
  _, err, status = Open3.capture3(
    "magick", "/tmp/build_photos_base.jpg",
    "-resize", "#{MAX_DIMENSION_WEB}x#{MAX_DIMENSION_WEB}>",
    *mat_args(MAT_WEB, caption_text, signature_png),
    "-strip", "-quality", JPEG_QUALITY.to_s,
    web_dest
  )
  abort "magick (web) failed on #{filename}: #{err}" unless status.success?

  # Pixel dimensions of the "web" derivative (mat included), used by the
  # grid's masonry JS to lay out columns immediately without waiting for
  # each (lazy-loaded) image to actually download.
  dims_out, err, status = Open3.capture3("magick", "identify", "-format", "%w %h", web_dest)
  abort "magick identify failed on #{filename}: #{err}" unless status.success?
  web_width, web_height = dims_out.strip.split(" ").map(&:to_i)

  # "large" derivative: same mat + signature, PLUS a large, semi-transparent
  # watermark diagonally across the CENTER of the photo itself, which can't
  # be cropped out without destroying the image. Opened when a thumbnail is
  # clicked, so detail/colour are still fully visible underneath it.
  _, err, status = Open3.capture3(
    "magick", "/tmp/build_photos_base.jpg",
    "-gravity", "center",
    "-font", LARGE_MARK_FONT,
    "-fill", "rgba(255,255,255,0.28)", "-stroke", "rgba(0,0,0,0.18)", "-strokewidth", "1",
    "-pointsize", LARGE_MARK_POINTSIZE.to_s, "-annotate", "335x335+0+0", LARGE_MARK_TEXT,
    *mat_args(MAT_LARGE, caption_text, signature_png),
    "-strip", "-quality", "90",
    large_dest
  )
  abort "magick (large) failed on #{filename}: #{err}" unless status.success?

  entries << {
    "file"         => "/public/photos/#{basename}.jpg",
    "large_file"   => "/public/photos/#{basename}-large.jpg",
    "width"        => web_width,
    "height"       => web_height,
    "camera"       => combine_make_model(exif["Make"], exif["Model"]),
    "lens"         => lens,
    "iso"          => exif["ISO"],
    "aperture"     => exif["FNumber"] && "f/#{exif['FNumber']}",
    "shutter"      => shutter,
    "focal_length" => focal_length,
    "date"         => date,
    "location"     => location,
  }

  print "."
end
puts
[signature_source, signature_png, "/tmp/build_photos_base.jpg"].each { |f| File.delete(f) if File.exist?(f) }

entries.sort_by! { |e| e["date"] || "" }
entries.reverse!

File.write(DATA_PATH, entries.to_yaml)
puts "#{entries.size} photo(s) processed -> #{DATA_PATH} + #{PHOTOS_DIR}"
