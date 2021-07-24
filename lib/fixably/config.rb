# frozen_string_literal: true

require_relative "logger"

module Fixably
  class Config
    attr_accessor :api_key
    attr_accessor :subdomain

    def logger
      Logger.logger
    end

    def logger=(log)
      Logger.logger = log
    end

    def require(param)
      value = public_send(param)
      return value unless value.nil? || value.empty?

      require_error(param)
    end

    private

    def require_error(param)
      raise(
        ArgumentError,
        <<~MESSAGE
          #{param} is required but hasn't been set.
          Fixably.configure do |config|
            config.#{param} = "value"
          end
        MESSAGE
      )
    end
  end
end
