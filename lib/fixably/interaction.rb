# frozen_string_literal: true

require "active_interaction"
# This should be required by Active Interation but, as of 4.0.3, an exception
# will be thrown if it isn't required
require "active_support/core_ext/hash/indifferent_access"

module Fixably
  class Interaction < ActiveInteraction::Base
    def execute
      raise "You need to create an execute method on your interaction"
    end
  end
end
