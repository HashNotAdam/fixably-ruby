# frozen_string_literal: true

module Fixably
  module Helpers
    class Config
      def self.configure
        Fixably.configure do |config|
          config.api_key = ENV["FIXABLY_API_KEY"]
          config.subdomain = ENV["FIXABLY_SUBDOMAIN"]
        end
      end
    end
  end
end
