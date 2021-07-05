# frozen_string_literal: true

require "fixably/config"
require "fixably/logger"
require "fixably/interaction"
require "fixably/resource"
require "fixably/version"

require "fixably/validators/filters"

module Fixably
  @config = Config.new

  class << self
    attr_reader :config

    def configure(&_block)
      yield config
    end
  end
end
