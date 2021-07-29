# frozen_string_literal: true

require_relative "resource_lazy_loader"

module Fixably
  class ApplicationResource < ::ActiveResource::Base
    self.include_format_in_path = false

    class << self
      def find(*arguments)
        scope = arguments.slice(0)
        args = parametize_arguments(arguments.slice(1))
        super(scope, args)
      end

      def first(*arguments)
        args = arguments.first || {}
        args[:limit] = 1
        super(args)
      end

      def last(*arguments)
        args = parametize_arguments(arguments.first)
        collection = find_every(args)
        return collection.last unless collection.offset.zero?
        return collection.last if collection.total_items <= collection.limit

        super(limit: 1, offset: collection.total_items - 1)
      end

      def where(clauses = {})
        find(:all, clauses)
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
        "https://#{subdomain}.fixably.com/api/#{api_version}"
      end

      private

      def parametize_arguments(arguments)
        arguments ||= {}
        params = arguments.dup
        params[:expand] = expand_associations(params)
        { params: params }
      end

      def expand_associations(arguments)
        associations = arguments.fetch(:expand, []).map { "#{_1}(items)" }
        %w[items].concat(associations).join(",")
      end

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
      attrs.delete("href")
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
  end
end
