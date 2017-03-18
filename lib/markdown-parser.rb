

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

    end

    def parse( markdownFile )

      # Use Redcarpet to convert Markdown->HTML
      redcarpet = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
      markdown  = redcarpet.render( File.read( markdownFile ) )

      return markdown

    end

    def generatePage( params = {} )

      logger.debug( params )

      if( params.is_a?( String ) )
        params = {}
        params['base'] = 'index.md'
      end

      fileName = params.dig('base')

      markdownFile = nil

      files = Array.new()
      files = [
        sprintf( '%s/%s'         , @publicFolder  , fileName ),
        sprintf( '%s/_default/%s', @defaultWebRoot, fileName )
      ]

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

      name         = markdownFile.split('.').first
      markdownFile = name  + ".md"


      template = File.read( sprintf( '%s/_template/index.erb', @defaultWebRoot ) )

      logger.debug( "use template: #{template}" )

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
        sprintf( '%s/%s'               , @publicFolder  , @styleSheets ),
        sprintf( '%s/_styles/%s'       , @defaultWebRoot, @styleSheets ),
        sprintf( '%s/_styles/style.css', @defaultWebRoot )
      ]

      files.each do |f|

        if( File.exist?( f ) )
          stylesheet = f
          break
        end

      end

      logger.debug( "use stylesheet: #{stylesheet}" )

      return stylesheet

    end


  end


end
