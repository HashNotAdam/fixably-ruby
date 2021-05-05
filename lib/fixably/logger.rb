# frozen_string_literal: true

require "forwardable"
require "logger"

module Fixably
  module Logger
    extend SingleForwardable

    def_delegators :logger, *::Logger.instance_methods(false)

    class << self
      def logger
        @logger ||=
          if defined?(Rails.logger)
            Rails.logger
          else
            ruby_logger
          end
      end

      private

      def ruby_logger
        log = ::Logger.new($stdout)
        log.level = ::Logger::WARN
        log
      end
    end
  end
end
