# [snockets](http://github.com/TrevorBurnham/snockets)

DepGraph = require 'dep-graph'

CoffeeScript = require 'coffee-script'
fs           = require 'fs'
path         = require 'path'
uglify       = require 'uglify-js'
_            = require 'underscore'

module.exports = class Snockets
  constructor: (@options = {}) ->
    @options.src ?= '.'
    @options.async ?= true
    @cache = {}
    @concatCache = {}
    @depGraph = new DepGraph

  # ## Public methods

  scan: (filePath, flags, callback) ->
    if typeof flags is 'function'
      callback = flags; flags = {}
    flags ?= {}
    flags.async ?= @options.async

    @updateDirectives filePath, flags, (err, graphChanged) =>
      if err
        if callback then return callback err else throw err
      callback? null, @depGraph, graphChanged
      @depGraph

  getCompiledChain: (filePath, flags, callback) ->
    if typeof flags is 'function'
      callback = flags; flags = {}
    flags ?= {}
    flags.async ?= @options.async

    @updateDirectives filePath, flags, (err, graphChanged) =>
      if err
        if callback then return callback err else throw err
      try
        chain = @depGraph.getChain filePath
      catch e
        if callback then return callback e else throw e

      compiledChain = for link in chain.concat filePath
        o = {}
        if @compileFile link
          o.filename = stripExt(link) + '.js'
        else
          o.filename = link
        o.js = @cache[link].js.toString 'utf8'
        o

      callback? null, compiledChain, graphChanged
      compiledChain

  getConcatenation: (filePath, flags, callback) ->
    if typeof flags is 'function'
      callback = flags; flags = {}
    flags ?= {}
    flags.async ?= @options.async
    concatenationChanged = true

    @updateDirectives filePath, flags, (err, graphChanged) =>
      if err
        if callback then return callback err else throw err
      try
        if @concatCache[filePath]?.data
          concatenation = @concatCache[filePath].data.toString 'utf8'
          if !flags.minify then concatenationChanged = false
        else
          chain = @depGraph.getChain filePath
          concatenation = (for link in chain.concat filePath
            @compileFile link
            @cache[link].js.toString 'utf8'
          ).join '\n'
          @concatCache[filePath] = data: new Buffer(concatenation)
      catch e
        if callback then return callback e else throw e

      if flags.minify
        if @concatCache[filePath]?.minifiedData
          result = @concatCache[filePath].minifiedData.toString 'utf8'
          concatenationChanged = false
        else
          result = minify concatenation
          @concatCache[filePath].minifiedData = new Buffer(result)
      else
        result = concatenation

      callback? null, result, concatenationChanged
      result

  # ## Internal methods

  # Interprets the directives from the given file to update `@depGraph`.
  updateDirectives: (filePath, flags, excludes..., callback) ->
    return callback() if filePath in excludes
    excludes.push filePath

    depList = []
    graphChanged = false
    q = new HoldingQueue
      task: (depPath, next) =>
        return next() unless path.extname(depPath) in jsExts()
        if depPath is filePath
          err = new Error("Script tries to require itself: #{filePath}")
          return callback err
        unless depPath in depList
          depList.push depPath
        @updateDirectives depPath, flags, excludes..., (err) ->
          return callback err if err
          next()
      onComplete: =>
        unless _.isEqual depList , @depGraph.map[filePath]
          @depGraph.map[filePath] = depList
          graphChanged = true
        if graphChanged
          @concatCache[filePath] = null
        callback null, graphChanged

    require = (relPath) =>
      q.waitFor relName = stripExt relPath
      if relName.match EXPLICIT_PATH
        depPath = relName + '.js'
        q.perform relName, depPath
      else
        depName = @joinPath path.dirname(filePath), relName
        @findMatchingFile depName, flags, (err, depPath) ->
          return callback err if err
          q.perform relName, depPath

    requireTree = (dirName) =>
      q.waitFor dirName
      @readdir @absPath(dirName), flags, (err, items) =>
        return callback err if err
        q.unwaitFor dirName
        for item in items
          itemPath = @joinPath dirName, item
          continue if @absPath(itemPath) is @absPath(filePath)
          q.waitFor itemPath
          do (itemPath) =>
            @stat @absPath(itemPath), flags, (err, stats) =>
              return callback err if err
              if stats.isFile()
                q.perform itemPath, itemPath
              else
                requireTree itemPath
                q.unwaitFor itemPath

    @readFile filePath, flags, (err, fileChanged) =>
      return callback err if err
      if fileChanged then graphChanged = true
      for directive in parseDirectives(@cache[filePath].data.toString 'utf8')
        words = directive.replace(/['"]/g, '').split /\s+/
        [command, relPaths...] = words

        switch command
          when 'require'
            require relPath for relPath in relPaths
          when 'require_tree'
            for relPath in relPaths
              requireTree @joinPath path.dirname(filePath), relPath

      q.finalize()

  # Searches for a file with the given name (no extension, e.g. `'foo/bar'`)
  findMatchingFile: (filename, flags, callback) ->
    tryFiles = (filePaths) =>
      for filePath in filePaths
        if stripExt(@absPath filePath) is @absPath(filename)
          callback null, filePath
          return true

    return if tryFiles _.keys @cache
    @readdir path.dirname(@absPath filename), flags, (err, files) =>
      return callback err if err
      return if tryFiles (for file in files
        @joinPath path.dirname(filename), file
      )
      callback new Error("File not found: '#{filename}'")

  # Wrapper around fs.readdir or fs.readdirSync, depending on flags.async.
  readdir: (dir, flags, callback) ->
    if flags.async
      fs.readdir @absPath(dir), callback
    else
      try
        files = fs.readdirSync @absPath(dir)
        callback null, files
      catch e
        callback e

  # Wrapper around fs.stat or fs.statSync, depending on flags.async.
  stat: (filePath, flags, callback) ->
    if flags.async
      fs.stat @absPath(filePath), callback
    else
      try
        stats = fs.statSync @absPath(filePath)
        callback null, stats
      catch e
        callback e

  # Reads a file's data and timestamp into the cache.
  readFile: (filePath, flags, callback) ->
    @stat filePath, flags, (err, stats) =>
      return callback err if err
      if timeEq @cache[filePath]?.mtime, stats.mtime
        return callback null, false
      if flags.async
          fs.readFile @absPath(filePath), (err, data) =>
            return callback err if err
            @cache[filePath] = {mtime: stats.mtime, data}
            callback null, true
      else
        try
          data = fs.readFileSync @absPath(filePath)
          @cache[filePath] = {mtime: stats.mtime, data}
          callback null, true
        catch e
          callback e

  compileFile: (filePath) ->
    if (ext = path.extname filePath) is '.js'
      @cache[filePath].js = @cache[filePath].data
      false
    else
      src = @cache[filePath].data.toString 'utf8'
      js = compilers[ext[1..]].compileSync @absPath(filePath), src
      @cache[filePath].js = new Buffer(js)
      true

  absPath: (relPath) ->
    if relPath.match EXPLICIT_PATH
      relPath
    else if @options.src.match EXPLICIT_PATH
      @joinPath @options.src, relPath
    else
      @joinPath process.cwd(), @options.src, relPath

  joinPath: ->
    filePath = path.join.apply path, arguments

    # Replace backslashes with forward slashes for Windows compatability
    if process.platform is 'win32'
      slash = '/' # / on the same line as the regex breaks ST2 syntax highlight
      filePath.replace /\\/g, slash
    else
      filePath

# ## Compilers

module.exports.compilers = compilers =
  coffee:
    match: /\.js$/
    compileSync: (sourcePath, source) ->
      CoffeeScript.compile source, {filename: sourcePath}

# ## Regexes

EXPLICIT_PATH = /^\/|:/

HEADER = ///
(?:
  (\#\#\# .* \#\#\#\n*) |
  (// .* \n*) |
  (\# .* \n*)
)+
///

DIRECTIVE = ///
^[\W] *= \s* (\w+.*?) (\*\\/)?$
///gm

# ## Utility functions

class HoldingQueue
  constructor: ({@task, @onComplete}) ->
    @holdKeys = []
  waitFor: (key) ->
    @holdKeys.push key
  unwaitFor: (key) ->
    @holdKeys = _.without @holdKeys, key
  perform: (key, args...) ->
    @task args..., => @unwaitFor key
  finalize: ->
    if @holdKeys.length is 0
      @onComplete()
    else
      h = setInterval (=>
        if @holdKeys.length is 0
          @onComplete()
          clearInterval h
      ), 10

parseDirectives = (code) ->
  code = code.replace /[\r\t ]+$/gm, '\n'  # fix for issue #2
  return [] unless match = HEADER.exec(code)
  header = match[0]
  match[1] while match = DIRECTIVE.exec header

stripExt = (filePath) ->
  if path.extname(filePath) in jsExts()
    filePath[0...filePath.lastIndexOf('.')]
  else
    filePath

jsExts = ->
  (".#{ext}" for ext of compilers).concat '.js'

minify = (js) ->
  jsp = uglify.parser
  pro = uglify.uglify
  ast = jsp.parse js
  ast = pro.ast_mangle ast
  ast = pro.ast_squeeze ast
  pro.gen_code ast

timeEq = (date1, date2) ->
  date1? and date2? and date1.getTime() is date2.getTime()