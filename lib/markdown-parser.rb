
require 'redcarpet'
require 'erb'

require_relative 'logging'

# -----------------------------------------------------------------------------

module MarkdownParser

  class Parser

    include Logging

    def initialize( settings = {} )

      @default_web_root = settings.dig(:default_path)
      @public_folder    = settings.dig(:public_folder)
      @stylesheets      = settings.dig(:stylesheets)

      version              = '0.10.0'
      date                 = '2018-02-13'

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
        format( '%s/%s'         , @public_folder  , file_name ),
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
      markdownData  = self.parse( markdown_file )

      # render the template
      { status: result_code, content: renderer.result(binding) }
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
