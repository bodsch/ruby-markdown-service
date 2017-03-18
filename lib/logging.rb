#!/usr/bin/ruby

require 'logger'

# -------------------------------------------------------------------------------------------------

module Logging

  def logger
    @logger ||= Logging.logger_for( self.class.name )
  end

  # Use a hash class-ivar to cache a unique Logger per class:
  @loggers = {}

  class << self
    def logger_for( classname )
      @loggers[classname] ||= configure_logger_for( classname )
    end

    def configure_logger_for( classname )

      logFile         = '/var/log/markdown-server.log'
      file            = File.new( logFile, File::WRONLY | File::APPEND | File::CREAT, 0666 )
      file.sync       = true

      if( File.exists?( logFile ) )
        FileUtils.chmod( 0666, logFile )
        FileUtils.chown( 'nobody', 'nobody', logFile )
      end

      logger                 = Logger.new( file, 'weekly', 1024000 )
#      logger                 = Logger.new(STDOUT)
      logger.progname        = classname
      logger.level           = Logger::INFO
      logger.datetime_format = "%Y-%m-%d %H:%M:%S::%3N"
      logger.formatter       = proc do |severity, datetime, progname, msg|
        "[#{datetime.strftime( logger.datetime_format )}] #{severity.ljust(5)} : #{progname} - #{msg}\n"
      end


      logger
    end
  end
end

# -------------------------------------------------------------------------------------------------
