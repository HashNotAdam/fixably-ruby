# frozen_string_literal: true

module Fixably
  class Model < ::ActiveResource::Base
    self.include_format_in_path = false

    class << self
      def headers
        result = super()
        result["Authorization"] = api_key
        result
      end

      def site
        define_site_url unless _site_defined?
        super()
      end

      private

      def api_key
        Fixably.config.require(:api_key)
      end

      def define_site_url
        self.site = "https://#{subdomain}.fixably.com/api/#{api_version}"
      end

      def subdomain
        Fixably.config.require(:subdomain)
      end

      def api_version = "v3"
    end
  end
end
