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

# -----------------------------------------------------------------------------

module Sinatra

  class CertServiceRest < Base

    configure do

      set :environment, :production

      @publicFolder     = '/var/www'
      @restServicePort  = 2222
      @restServiceBind  = '0.0.0.0'
      @stylesheet       = 'style.css'

      if( File.exist?( '/etc/markdown-service.yaml' ) )

        config = YAML.load_file( '/etc/markdown-service.yaml' )

        @publicFolder     = config.dig( 'publicFolder' )
        @restServicePort  = config.dig( 'port' )
        @restServiceBind  = config.dig( 'bind' )
        @stylesheet       = config.dig( 'stylesheet' )
      end

      @defaultPath = File.expand_path( '../', File.dirname( __FILE__ ) )

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

    before do
      headers 'Content-Type' => 'text/html; charset=utf8'
    end

    # -----------------------------------------------------------------------------

    config = {
      :defaultPath  => @defaultPath,
      :publicFolder => @publicFolder,
      :styleSheets  => @stylesheet
    }

    parser = MarkdownParser::Parser.new( config )

    # -----------------------------------------------------------------------------

    # serve our stylesheet
    get '/style.css'do

      headers 'Content-Type' => 'text/css; charset=utf8'

      style = File.read( parser.getStylesheet() )
      style

    end

    # serve a index site
    get '/' do

      response.headers['Cache-Control'] = 'public, max-age=300'

      parser.generatePage( 'index.md' )

    end

    # serve named sites
    get '/:base' do

      response.headers['Cache-Control'] = 'public, max-age=300'

      parser.generatePage( params )

    end

    # -----------------------------------------------------------------------------
    run! if app_file == $0
    # -----------------------------------------------------------------------------
  end

end

# thats all
