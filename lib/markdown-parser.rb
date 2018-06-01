
require 'ruby_dig' if RUBY_VERSION < '2.3'

require 'redcarpet'
require 'erb'
require 'filemagic'

require_relative 'logging'
require_relative 'version'

# -----------------------------------------------------------------------------

module MarkdownParser

  class Parser

    include Logging

    def initialize( settings = {} )

      logger.debug(settings)

      @default_web_root = settings.dig(:default_path)
      @public_folder    = settings.dig(:public_folder)
      @stylesheets      = settings.dig(:stylesheets)

      version              = MarkdownParser::VERSION
      date                 = MarkdownParser::DATE

      logger.info( '-----------------------------------------------------------------' )
      logger.info( ' Markdown Server' )
      logger.info( "  Version #{version} (#{date})" )
      logger.info( '  Copyright 2017-2018 Bodo Schulz' )
      logger.info( '' )
      logger.info( '-----------------------------------------------------------------' )
      logger.info( '' )

    end


    def parse( markdown_file )
      # Use Redcarpet to convert Markdown->HTML
      redcarpet = Redcarpet::Markdown.new( Redcarpet::Render::HTML, :tables => true )
      redcarpet.render( File.read( markdown_file ) )
    end


    def generate_page( params = {} )

      file_name = params.dig(:splat).first
      file_name = 'index.md' if( file_name == '' )
      file_name = format( '%s.md', file_name.split('.').first )
      markdown_file = nil

      result_code = 200

      files = []
      files = [
        format( '%s/%s'         , @public_folder   , file_name ),
        format( '%s/_default/%s', @default_web_root, file_name )
      ]

      logger.debug( "search files #{files}" )

      files.each do |f|
        if( File.exist?( f ) )
          markdown_file = f
          break
        end
      end

      if( markdown_file == nil )
        result_code = 404
        markdown_file = format( '%s/_default/404.md', @default_web_root )
      end

      logger.debug( "use file: #{markdown_file}" )

      template = File.read( get_template() )

      renderer = ERB.new( template )

      # Template Datas
      title         = markdown_file.split('/').last.split('.').first
      styleSheet    = @stylesheets
      favicon       = ''
      markdownData  = parse( markdown_file )

      content = renderer.result(binding)

      # render the template
      { status: result_code, content: content }
    end


    def get_static_file(params = {})

      file_name = params.dig(:splat).first
      result_code = 200
      result_code = 404 if( file_name == '' )
      static_file = nil
      mime_type   = nil

      puts file_name

      files = []
      files = [
        format( '%s/%s'        , @public_folder, file_name ),
        format( '%s/img/%s'    , @public_folder, file_name ),
        format( '%s/images/%s' , @public_folder, file_name ),
        format( '%s/static/%s' , @public_folder, file_name ),
        format( '%s/_img/%s'   , @public_folder, file_name ),
        format( '%s/_images/%s', @public_folder, file_name ),
        format( '%s/_static/%s', @public_folder, file_name )
      ]

      logger.debug( "search files #{files}" )

      files.each do |f|
        if( File.exist?( f ) )
          static_file = f
          break
        end
      end

      if( static_file == nil )
        result_code = 404
        static_file = nil
      end

      logger.debug( "use file: #{static_file}" )

      mime_type = FileMagic.new(FileMagic::MAGIC_MIME).file(static_file) unless(static_file.nil?)

      { status: result_code, mime_type: mime_type, static_file: static_file }
    end


    def get_stylesheet()

      stylesheet = nil

      files = []
      files = [
        format( '%s/%s'               , @public_folder, @stylesheets ),
        format( '%s/_styles/%s'       , @public_folder, @stylesheets ),
        format( '%s/_styles/style.css', @default_web_root )
      ]

      logger.debug( "search stylesheets #{files}" )

      files.each do |f|
        if( File.exist?( f ) )
          stylesheet = f
          break
        end
      end

      logger.debug( "use stylesheet: #{stylesheet}" )

      stylesheet
    end

    private

    def get_template( tpl = 'index.erb' )

      templatefile = nil

      files = []
      files = [
        format( '%s/_template/%s', @public_folder  , tpl ),
        format( '%s/_template/%s', @default_web_root, tpl )
      ]

      logger.debug( "search templates #{files}" )

      files.each do |f|
        if( File.exist?( f ) )
          templatefile = f
          break
        end
      end

      templatefile
    end
  end
end
