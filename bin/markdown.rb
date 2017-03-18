#!/usr/bin/ruby
#
# 17.03.2016 - Bodo Schulz
#
#
# v0.5.0

# -----------------------------------------------------------------------------

require 'sinatra/base'
require 'yaml'

require_relative '../lib/markdown-parser'
require_relative '../lib/logging'

# -----------------------------------------------------------------------------

module Sinatra

  class CertServiceRest < Base

    include Logging

    configure do

      set :environment, :production

      @publicFolder    = ENV.fetch( 'PUBLIC_FOLDER'  , '/var/www' )
      @restServicePort = ENV.fetch( 'PORT', 2222 )
      @restServiceBind = ENV.fetch( 'BIND_TO', '0.0.0.0' )
      @stylesheet      = ENV.fetch( 'STYLESHEET', 'style.css' )

      @defaultPath     = File.expand_path( '../', File.dirname( __FILE__ ) )

    end

    set :environment, :production
    set :logging, true
    set :app_file, caller_files.first || $0
    set :run, Proc.new { $0 == app_file }
    set :dump_errors, true
    set :show_exceptions, false
    set :public_folder, @publicFolder

    set :bind, @restServiceBind
    set :port, @restServicePort.to_i

    # -----------------------------------------------------------------------------

    config = {
      :defaultPath  => @defaultPath,
      :publicFolder => @publicFolder,
      :styleSheets  => @stylesheet
    }

    parser = MarkdownParser::Parser.new( config )

    # -----------------------------------------------------------------------------

    # serve our stylesheet
    get '/*.css' do

      logger.debug( "request: #{params}" )

      headers 'Content-Type' => 'text/css; charset=utf8'
      response.headers['Cache-Control'] = 'public, max-age=3200'

      style = File.read( parser.getStylesheet() )
      style

    end

    # serve a index site
    get '/' do

      logger.debug( 'request: /' )

      headers 'Content-Type' => 'text/html; charset=utf8'
      response.headers['Cache-Control'] = 'public, max-age=300'

      parser.generatePage( 'index.md' )

    end

    # serve named sites
    get '/:base' do

      logger.debug( "request: #{params}" )

      headers 'Content-Type' => 'text/html; charset=utf8'
      response.headers['Cache-Control'] = 'public, max-age=300'

      parser.generatePage( params )

    end

    # -----------------------------------------------------------------------------
    run! if app_file == $0
    # -----------------------------------------------------------------------------
  end

end

# thats all
