

require 'redcarpet'
require 'erb'

require_relative 'logging'

# -----------------------------------------------------------------------------

module MarkdownParser

  class Parser

    include Logging

    def initialize( settings = {} )

      @defaultWebRoot = settings.dig(:defaultPath)
      @publicFolder   = settings.dig(:publicFolder)
      @styleSheets    = settings.dig(:styleSheets)

      version              = '0.8.2'
      date                 = '2017-04-20'

      logger.info( '-----------------------------------------------------------------' )
      logger.info( ' Markdown Server' )
      logger.info( "  Version #{version} (#{date})" )
      logger.info( '  Copyright 2017 Bodo Schulz' )
      logger.info( '' )
      logger.info( '-----------------------------------------------------------------' )
      logger.info( '' )

    end

    def parse( markdownFile )

      # Use Redcarpet to convert Markdown->HTML
      redcarpet = Redcarpet::Markdown.new( Redcarpet::Render::HTML, :tables => true )
      markdown  = redcarpet.render( File.read( markdownFile ) )

      return markdown

    end


    def generatePage( params = {} )

      fileName = params.dig(:splat).first

      if( fileName == '' )
        fileName = 'index.md'
      end

      fileName = sprintf( '%s.md', fileName.split('.').first )

      markdownFile = nil

      files = Array.new()
      files = [
        sprintf( '%s/%s'         , @publicFolder  , fileName ),
        sprintf( '%s/_default/%s', @defaultWebRoot, fileName )
      ]

      logger.debug( "search files #{files}" )

      files.each do |f|

        if( File.exist?( f ) )
          markdownFile = f
          break
        end

      end

      if( markdownFile == nil )
        markdownFile = sprintf( '%s/_default/404.md', @defaultWebRoot )
      end

      logger.debug( "use file: #{markdownFile}" )

      template = File.read( getTemplate() )

      renderer = ERB.new( template )

      # Template Datas
      title         = markdownFile.split('/').last.split('.').first
      styleSheet    = @styleSheets
      favicon       = ''
      markdownData  = self.parse( markdownFile )


      # render the template
      return output = renderer.result(binding)

    end


    def getStylesheet()

      stylesheet = nil

      files = Array.new()
      files = [
        sprintf( '%s/%s'               , @publicFolder, @styleSheets ),
        sprintf( '%s/_styles/%s'       , @publicFolder, @styleSheets ),
        sprintf( '%s/_styles/style.css', @defaultWebRoot )
      ]

      logger.debug( "search stylesheets #{files}" )

      files.each do |f|

        if( File.exist?( f ) )
          stylesheet = f
          break
        end

      end

      logger.debug( "use stylesheet: #{stylesheet}" )

      return stylesheet

    end

    private

    def getTemplate( tpl = 'index.erb' )

      templatefile = nil

      files = Array.new()
      files = [
        sprintf( '%s/_template/%s', @publicFolder  , tpl ),
        sprintf( '%s/_template/%s', @defaultWebRoot, tpl )
      ]

      logger.debug( "search templates #{files}" )

      files.each do |f|

        if( File.exist?( f ) )
          templatefile = f
          break
        end

      end

      return templatefile

    end

  end


end
