# frozen_string_literal: true

module Fixably
  module Helpers
    class Config
      def self.configure
        Fixably.configure do |config|
          config.api_key = "pk_0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJK"
          config.subdomain = "demo"
        end
      end
    end
  end
end
