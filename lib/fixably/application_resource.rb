# frozen_string_literal: true

require_relative "actions"
require_relative "authorization"
require_relative "encoding"
require_relative "load_from_response"

module Fixably
  class ApplicationResource < ::ActiveResource::Base
    self.include_format_in_path = false

    include Actions
    include Encoding
    include LoadFromResponse
    extend Authorization

    attr_accessor :parent_association

    class << self
      def site
        self.site = site_url unless _site_defined?
        super()
      end

      protected

      def site_url
        subdomain = Fixably.config.require(:subdomain)
        base_url = "https://#{subdomain}.fixably.com/api/#{api_version}"

        name_parts = name.split("::")
        return base_url if name_parts.length.equal?(2)

        parent_resource = name_parts.fetch(1).underscore
        "#{base_url}/#{parent_resource.pluralize}/:#{parent_resource}_id"
      end

      private

      def api_version = "v3"
    end

    def initialize(attributes = {}, persisted = false) # rubocop:disable Style/OptionalBooleanParameter
      super(attributes, persisted)

      self.class.site
    end
  end
end
