#
# 05.10.2016 - Bodo Schulz
#
#
# v2.1.0

# -----------------------------------------------------------------------------

require 'sinatra'
require 'redcarpet'

# -----------------------------------------------------------------------------

set :port, 2222

before do
  headers "Content-Type" => "text/html; charset=utf8"
end

def generatePage(filePath)

  # Read style file for inline
  # but we use an own stylesheet file
#  style = File.read( 'style.css' )

  #Use Redcarpet to convert Markdown->HTML
  redcarpet = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown  = redcarpet.render( File.read( filePath ) )

  content = %(
  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
  <html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<!--    <link rel="icon" type="image/x-icon" href="/favicon.ico"> -->
    <title>operation-view : #{filePath}</title>
    <link crossorigin="anonymous" href="/style.css" media="all" rel="stylesheet" />
<!--    <style type="text/css">#{style}</style> -->
  </head>
  <body><div id="container">#{markdown}</div></body>
  )

  return content
end

def source()

  parts    = params[:base].split('.')
  name     = parts.first
  ext      = parts.last
  filename = name  + ".md"
  source   = File.read(filename)

  generatePage( filename )

end

# server our stylesheet
get '/style.css'do

  style = File.read( 'style.css' )

  headers "Content-Type" => "text/css; charset=utf8"

  style

end

# server a index site
get '/' do

  generatePage( 'index.md' )

end

# serve named sites
get '/:base' do

  response.headers['Cache-Control'] = 'public, max-age=300'

  source()

end

# thats all