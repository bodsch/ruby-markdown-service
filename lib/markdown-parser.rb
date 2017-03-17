
require 'redcarpet'
require 'erb'

module MarkdownParser

  class Parser

    def initialize( settings = {} )

      @defaultWebRoot = settings.dig(:defaultPath)
      @publicFolder   = settings.dig(:publicFolder)

    end

    def parse( markdownFile )

      # Use Redcarpet to convert Markdown->HTML
      redcarpet = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
      markdown  = redcarpet.render( File.read( markdownFile ) )

      return markdown

    end

    def generatePage( params = {} )

      # {"splat"=>[], "captures"=>["index.md"], "base"=>"index.md"}
      if( params.is_a?( String ) )
        params = {}
        params['base'] = 'index.md'
      end

      fileName = params.dig('base')

      markdownFile = nil

      files = Array.new()
      files = [
        ('%s/%s' % [ @publicFolder, fileName ]),
        ('%s/_default/%s' % [ @defaultWebRoot, fileName ])
      ]

      files.each do |f|

        if( File.exist?( f ) )
          markdownFile = f
          break
        end

      end

      if( markdownFile == nil )
        markdownFile = ('%s/_default/404.md' % [ @defaultWebRoot ])
      end

      name     = markdownFile.split('.').first
#       ext      = markdownFile.split('.').last
      markdownFile = name  + ".md"


      template = File.read('%s/_template/index.erb' % [ @defaultWebRoot ])

      renderer = ERB.new( template )

      # Template Datas
      title         = ''
      markdownData  = self.parse( markdownFile )

      # render the template
      return output = renderer.result(binding)

    end

    def source()

      parts    = params[:base].split('.')


      generatePage( filename )

    end


  end


end
