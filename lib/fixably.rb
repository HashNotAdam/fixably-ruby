# frozen_string_literal: true

require "active_resource"
require_relative "fixably/active_resource/paginated_collection"
require_relative "fixably/active_resource/base"

require "fixably/config"
require "fixably/logger"
require "fixably/version"

require_relative "fixably/application_resource"
require_relative "fixably/resources/customer"

module Fixably
  @config = Config.new

  class << self
    attr_reader :config

    def configure(&block)
      if block.nil?
        raise ArgumentError, "configure must be called with a block"
      end

      yield config
    end

    def logger
      config.logger
    end
  end
end
