#!/usr/bin/ruby
#
# 17.03.2016 - Bodo Schulz
#
#
# v0.8.0

# -----------------------------------------------------------------------------

require 'sinatra/base'
require 'yaml'

require_relative '../lib/markdown-parser'
require_relative '../lib/logging'

# -----------------------------------------------------------------------------

module Sinatra

  class MarkdownService < Base

    include Logging

    configure do

      @public_folder     = ENV.fetch( 'PUBLIC_FOLDER'  , '/var/www' )
      @rest_service_port = ENV.fetch( 'PORT', 2222 )
      @rest_service_bind = ENV.fetch( 'BIND_TO', '0.0.0.0' )
      @stylesheet        = ENV.fetch( 'STYLESHEET', 'style.css' )

      @default_path      = File.expand_path( '../', File.dirname( __FILE__ ) )

      file      = File.new( '/var/log/sinatra.log', File::WRONLY | File::APPEND | File::CREAT, 0o666 )
      file.sync = true

      use Rack::CommonLogger, file

    end

    set :environment, :production
    set :logging, true
    set :app_file, caller_files.first || $0
    set :run, Proc.new { $0 == app_file }
    set :dump_errors, true
    set :show_exceptions, false

    set :bind, @rest_service_bind
    set :port, @rest_service_port.to_i

    # -----------------------------------------------------------------------------

    config = {
      default_path: @default_path,
      public_folder: @public_folder,
      stylesheets: @stylesheet
    }

    parser = MarkdownParser::Parser.new( config )

    # -----------------------------------------------------------------------------

    get '/health' do
      status 200
    end

    # -----------------------------------------------------------------------------

    # serve our stylesheet
    get '/*.css' do

      headers 'Content-Type' => 'text/css; charset=utf8'
      response.headers['Cache-Control'] = 'public, max-age=3200'

      File.read( parser.get_stylesheet() )
    end

    # serve an individual favicon
    get '/*.ico' do

#       logger.debug( "request: #{params}" )
#
#       headers 'Content-Type' => 'text/css; charset=utf8'
#       response.headers['Cache-Control'] = 'public, max-age=3200'
#
#       style = File.read( parser.get_stylesheet() )
#       style

    end

    # serve all the rest
    get '/*' do

      headers 'Content-Type' => 'text/html; charset=utf8'
      response.headers['Cache-Control'] = 'public, max-age=300'

      parser.generate_page( params )
    end

    # -----------------------------------------------------------------------------
    run! if app_file == $0
    # -----------------------------------------------------------------------------
  end

end

# thats all
