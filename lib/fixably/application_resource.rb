# frozen_string_literal: true

require_relative "actions"
require_relative "action_policy"
require_relative "resource_lazy_loader"

module Fixably
  class ApplicationResource < ::ActiveResource::Base
    self.include_format_in_path = false

    include Actions

    class << self
      def actions(values = nil)
        if eql?(ApplicationResource)
          raise "actions can only be called on a sub-class"
        end

        @actions ||= [].freeze
        return @actions if values.nil?

        @actions = format_actions(values).freeze
      end

      def headers
        result = super()
        result["Authorization"] = api_key
        result
      end

      def includes(association)
        ResourceLazyLoader.new(model: self).includes(association)
      end

      def site
        define_site_url unless _site_defined?
        super()
      end

      protected

      def site_url
        base_url = "https://#{subdomain}.fixably.com/api/#{api_version}"

        name_parts = name.split("::")
        return base_url if name_parts.length.equal?(2)

        parent_resource = name_parts[1].downcase
        "#{base_url}/#{parent_resource.pluralize}/:#{parent_resource}_id"
      end

      private

      # rubocop:disable Metrics/MethodLength
      def format_actions(values)
        unless values.respond_to?(:to_sym) || values.respond_to?(:to_a)
          raise(
            ArgumentError,
            "actions should be able to be converted into an Array or a Symbol"
          )
        end

        Array.wrap(values).map do
          action = _1.to_sym

          unless allowed_actions.include?(action)
            raise ArgumentError, "Unsupported action, #{action}, supplied"
          end

          action
        end
      end
      # rubocop:enable Metrics/MethodLength

      def allowed_actions = %i[create delete list show update]

      def api_key
        Fixably.config.require(:api_key)
      end

      def define_site_url
        self.site = site_url
      end

      def subdomain
        Fixably.config.require(:subdomain)
      end

      def api_version = "v3"
    end

    # Since our monkey patch converts the keys to underscore, it is necessary to
    # convert them back to camelcase when performing a create or update
    def encode(_options = nil, attrs: nil)
      attrs ||= attributes
      remove_ids(attrs)
      remove_has_many_associations(attrs)
      remove_unallowed_parameters(attrs)
      attrs = attrs.deep_transform_keys { _1.camelize(:lower) }
      attrs.public_send("to_#{self.class.format.extension}")
    end

    protected

    def load_attributes_from_response(response)
      resp = response.dup

      if response_code_allows_body?(resp.code)
        body = self.class.format.decode(resp.body)
        body.deep_transform_keys!(&:underscore)
        resp.body = self.class.format.encode(body)
      end

      super(resp)
    end

    def remove_on_encode = []

    private

    def remove_ids(attrs)
      attrs.delete("id")
      has_ones = reflections.select { _2.macro.equal?(:has_one) }
      has_ones.keys.each do
        attr_hash = public_send(_1)&.attributes
        next unless attr_hash

        attr_hash.delete("id")
        attrs[_1] = attr_hash
      end
    end

    def remove_has_many_associations(attrs)
      reflections.select { _2.macro.equal?(:has_many) }.keys.each do
        attrs.delete(_1)
      end
    end

    def remove_unallowed_parameters(attrs)
      %w[href].concat(remove_on_encode).each { attrs.delete(_1) }
      attrs
    end
  end
end
