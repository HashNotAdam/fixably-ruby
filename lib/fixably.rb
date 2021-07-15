# frozen_string_literal: true

require "active_model"

require "fixably/config"
require "fixably/logger"
require "fixably/version"

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
  end
end
