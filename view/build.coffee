fs = require("fs")
fse = require("fs-extra")
path = require("path")
url = require("url")
decompress = require("decompress")
rp = require("request-promise")
less = require("less")
recursive = require("recursive-readdir")

DEST_DIR = path.join(__dirname, "..", "static")
CACHE_DIR = path.join(__dirname, "cache")

EXT_MODULES =

  "jQuery":
    version: "2.2.4"
    url: -> "https://code.jquery.com/jquery-#{@version}.min.js"
    destDir: "js"

  "Bootstrap":
    version: "3.3.4"
    url: -> "https://github.com/twbs/bootstrap/archive/v#{@version}.tar.gz"
    sourceDir: -> "bootstrap-#{@version}/dist"
    files: [
      "fonts/glyphicons-halflings-regular.woff2"
      "js/bootstrap.min.js"
    ]

  "Font Awesome":
    version: "4.6.3"
    url: -> "https://github.com/FortAwesome/Font-Awesome/archive/v#{@version}.tar.gz"
    sourceDir: -> "Font-Awesome-#{@version}"
    files: [
      "css/font-awesome.min.css"
      "fonts/fontawesome-webfont.woff2"
    ]

  "Ace":
    version: "1.2.3"
    url: -> "https://github.com/ajaxorg/ace-builds/archive/v#{@version}.tar.gz"
    sourceDir: -> "ace-builds-#{@version}/src-min-noconflict"
    destDir: "ace"
    files: [
      "ace.js"
      "theme-twilight.js"
      "mode-coffee.js"
      "worker-coffee.js"
      "mode-javascript.js"
      "worker-javascript.js"
      "mode-python.js"
      "mode-ruby.js"
      "mode-yaml.js"
    ]

  "spin.js":
    version: "2.3.2"
    url: -> "https://github.com/fgnass/spin.js/archive/#{@version}.tar.gz"
    sourceDir: -> "spin.js-#{@version}"
    destDir: "js"
    files: [
      "spin.min.js"
      "jquery.spin.js"
    ]

  "Bootbox":
    version: "4.4.0"
    url: -> "https://github.com/makeusabrew/bootbox/releases/download/v#{
      @version}/bootbox.min.js"
    destDir: "js"

  "Bootstrap Notify":
    version: "3.1.3"
    url: ->
      "https://github.com/mouse0270/bootstrap-notify/releases/download/#{
      @version}/bootstrap-notify.min.js"
    destDir: "js"

  "jQuery-ScrollTabs":
    version: "2.0.0"
    url: -> "https://github.com/joshreed/jQuery-ScrollTabs/archive/#{
      @version}.tar.gz"
    sourceDir: -> "jQuery-ScrollTabs-#{@version}"
    files: [
      "js/jquery.scrolltabs.js"
      "js/jquery.mousewheel.js"
      "css/scrolltabs.css"
    ]

  "Split.js":
    disabled: true
    version: "1.0.7"
    url: -> "https://github.com/nathancahill/Split.js/archive/v#{@version}.tar.gz"
    sourceDir: -> "Split.js-#{@version}"
    destDir: "js"
    files: [
      "split.min.js"
    ]

  "jsTree":
    version: "3.3.1"
    url: -> "https://github.com/vakata/jstree/archive/#{@version}.tar.gz"
    sourceDir: -> "jstree-#{@version}/dist"
    destDir: "jstree"
    files: [
      "jstree.min.js"
      "themes/default/32px.png"
      "themes/default/40px.png"
      "themes/default/style.min.css"
      "themes/default/throbber.gif"
    ]

GENERATED_HTMLS =
  "index.html":
    source: "index.html"

GENERATED_CSSS =
  "css/rubic.css":
    source: "rubic.less"
    options:
      compress: true
      paths: [path.join(CACHE_DIR, "Bootstrap"), __dirname]

COPIED_DIRS =
  "images":
    source: "images"
    ignore: [".*", "*.xcf", "*.svg"]

install_module = (name, mod) ->
  title = "#{name} @ #{mod.version}"
  destDir = path.join(DEST_DIR, mod.destDir?() ? mod.destDir ? "")
  cacheDir = path.join(CACHE_DIR, name.replace(/\s+/g, "_"))
  sourceDir = path.join(cacheDir, mod.sourceDir?() ? "")
  urlObject = url.parse(mod.url())
  archive = path.join(cacheDir, path.basename(urlObject.pathname))
  files = mod.files or [path.basename(urlObject.pathname)]
  return Promise.resolve().then(=>
    download = false
    unpack = false
    install = false
    for file in files
      unless fs.existsSync(path.join(destDir, file))
        install = true
      unless fs.existsSync(path.join(sourceDir, file))
        unpack = true if mod.files
        unless fs.existsSync(archive)
          download = true
    return false unless install
    return Promise.resolve(
    ).then(=>
      return unless download
      # Download
      console.log("Downloading #{title}")
      return rp(
        url: urlObject.href
        encoding: null
      ).then((data) =>
        fse.mkdirsSync(path.dirname(archive))
        fs.writeFileSync(archive, data)
        install = true
        return
      )
    ).then(=>
      return unless unpack
      # Unpack
      console.log("Unpacking #{title}")
      return decompress(archive, cacheDir)
    ).then(=>
      return install
    )
  ).then((install) =>
    unless install
      console.log("Skipped #{title}")
      return
    console.log("Installing #{title}")
    for file in files
      fse.copySync(
        path.join(sourceDir, file)
        path.join(destDir, file)
      )
  )

generate_html = (dest, info) ->
  return Promise.resolve(
  ).then(=>
    console.log("Generating #{dest}")
    process = (infile, out, started = false) =>
      last = false
      ln = 0
      for line in fs.readFileSync(infile, {encoding: "utf-8"}).split("\n")
        ln += 1
        if line.match(/<!--begin-->/)
          started = true
          continue
        else if line.match(/<!--end-->/)
          started = false
        else if match = line.match(/<!--include\(([^\)]+)\)-->/)
          process(path.join(path.dirname(infile), match[1]), out) if started
          last = false
          continue
        if started
          indent = line.match(/^(\s*)/)[1]
          out.push("#{indent}<!--#{path.relative(__dirname, infile)}:#{ln}-->") unless last
          out.push(line)
        last = started
    result = []
    process(path.join(__dirname, info.source), result, true)
    fs.writeFileSync(path.join(DEST_DIR, dest), result.join("\n"))
    return
  )

generate_css = (dest, info) =>
  return Promise.resolve(
  ).then(=>
    console.log("Generating #{dest}")
    return new Promise((resolve, reject) =>
      less.render(
        fs.readFileSync(
          path.join(__dirname, info.source)
          {encoding: "utf-8"}
        )
        Object.assign({filename: dest}, info.options)
        (err, output) =>
          return reject(err) if err?
          fs.writeFileSync(path.join(DEST_DIR, dest), output.css)
          return resolve()
      )
    )
  )

copy_directory = (dest, info) =>
  return Promise.resolve(
  ).then(=>
    console.log("Copying files in #{dest}")
    return new Promise((resolve, reject) =>
      destDir = path.join(DEST_DIR, dest)
      baseDir = path.join(__dirname, info.source)
      recursive(baseDir, info.ignore, (err, files) =>
        return reject(err) if err?
        for file in files
          relPath = path.relative(baseDir, file)
          to = path.join(destDir, relPath)
          fse.mkdirsSync(path.dirname(to))
          fse.copySync(file, to)
        return resolve()
      )
    )
  )

return Promise.resolve(
).then(=>
  return Object.keys(EXT_MODULES).reduce(
    (promise, name) =>
      return promise.then(=>
        install_module(name, EXT_MODULES[name])
      )
    Promise.resolve()
  )
).then(=>
  Object.keys(GENERATED_HTMLS).reduce(
    (promise, name) =>
      return promise.then(=>
        generate_html(name, GENERATED_HTMLS[name])
      )
    Promise.resolve()
  )
).then(=>
  Object.keys(GENERATED_CSSS).reduce(
    (promise, name) =>
      return promise.then(=>
        generate_css(name, GENERATED_CSSS[name])
      )
    Promise.resolve()
  )
).then(=>
  Object.keys(COPIED_DIRS).reduce(
    (promise, name) =>
      return promise.then(=>
        copy_directory(name, COPIED_DIRS[name])
      )
    Promise.resolve()
  )
).then(=>
  console.log("Done")
).catch((error) =>
  console.log(error)
  process.exitCode = 1
)

