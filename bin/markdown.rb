#!/usr/bin/ruby
#
# 17.03.2016 - Bodo Schulz
#
#
# v0.11.0

# -----------------------------------------------------------------------------

require 'sinatra/base'
require 'yaml'

require_relative '../lib/markdown-parser'
require_relative '../lib/logging'

# -----------------------------------------------------------------------------

module Sinatra

  LOGGING_BLACKLIST = ['/health']

  class FilteredCommonLogger < Rack::CommonLogger
    def call(env)
      if filter_log(env)
        # default CommonLogger behaviour: log and move on
        super
      else
        # pass request to next component without logging
        @app.call(env)
      end
    end

    # return true if request should be logged
    def filter_log(env)
      !LOGGING_BLACKLIST.include?(env['PATH_INFO'])
    end
  end

  class MarkdownService < Base

    include Logging

    configure do
      @public_folder     = ENV.fetch( 'PUBLIC_FOLDER'  , '/var/www' )
      @rest_service_port = ENV.fetch( 'PORT', 8080 )
      @rest_service_bind = ENV.fetch( 'BIND_TO', '0.0.0.0' )
      @stylesheet        = ENV.fetch( 'STYLESHEET', 'style.css' )

      @default_path      = File.expand_path( '../', File.dirname( __FILE__ ) )
    end

    set :environment, :production
    set :logging, false
    set :app_file, caller_files.first || $0
    set :run, Proc.new { $0 == app_file }
    set :dump_errors, true
    set :show_exceptions, false

    set :bind, @rest_service_bind
    set :port, @rest_service_port.to_i

    use FilteredCommonLogger

    # -----------------------------------------------------------------------------

    parser = MarkdownParser::Parser.new(
      default_path: @default_path,
      public_folder: @public_folder,
      stylesheets: @stylesheet
    )

    # -----------------------------------------------------------------------------

    # health check
    #
    get '/health' do
      status 200

      { version: MarkdownParser::VERSION, date: MarkdownParser::DATE }.to_json
    end

    # -----------------------------------------------------------------------------

    # serve our stylesheet
    #
    get '/*.css' do

      headers 'Content-Type' => 'text/css; charset=utf8'
      response.headers['Cache-Control'] = 'public, max-age=3200'

      File.read( parser.get_stylesheet() )
    end

    # serve static files
    #
    ['/img/*', '/image/*', '/images/*', '/static/*'].each do |path|
      get path do
        result = parser.get_static_file(params)
        result = JSON.parse( result ) if( result.is_a?( String ) )

        result_status      = result.dig(:status).to_i
        result_static_file = result.dig(:static_file)
        result_mime_type   = result.dig(:mime_type)

        if(result_status == 200 && result_static_file != nil && result_mime_type != nil)
          headers 'Content-Type' => result_mime_type
          response.headers['Cache-Control'] = 'public, max-age=3200'
          send_file( result_static_file )
        else
          result_status = 404
        end

        status result_status
      end
    end

    # serve all the rest
    #
    get '/*' do

      # puts FileMagic.new(FileMagic::MAGIC_MIME).file(__FILE__)

      headers 'Content-Type' => 'text/html; charset=utf8'
      response.headers['Cache-Control'] = 'public, max-age=300'

      puts @public_folder
      puts params

      result = parser.generate_page( params )
      result = JSON.parse( result ) if( result.is_a?( String ) )

      result_status  = result.dig(:status).to_i
      result_content = result.dig(:content)

      status result_status
      result_content
    end

    # -----------------------------------------------------------------------------
    run! if app_file == $0
    # -----------------------------------------------------------------------------
  end

end

# thats all
