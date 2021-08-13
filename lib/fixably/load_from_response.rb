# frozen_string_literal: true

module Fixably
  module LoadFromResponse
    # Fixably returns collections as hashes which confuses Active Resource
    # rubocop:disable Style/OptionalBooleanParameter
    def load(attributes, remove_root = false, persisted = false)
      super(attributes, remove_root, persisted)
      load_nested_paginated_collections
      remove_empty_associations
      self
    end
    # rubocop:enable Style/OptionalBooleanParameter

    protected

    def load_attributes_from_response(response)
      resp = response.dup

      if response_code_allows_body?(resp.code)
        body = self.class.format.decode(resp.body)
        body = decontruct_array_response(body)
        body.deep_transform_keys!(&:underscore)
        resp.body = self.class.format.encode(body)
      end

      super(resp)
    end

    private

    def decontruct_array_response(attributes)
      return attributes if attributes.respond_to?(:to_hash)

      if attributes.length > 1
        raise(
          ArgumentError,
          "Unable to unpack an array response with more than 1 record"
        )
      end

      attributes.first
    end

    def load_nested_paginated_collections
      reflections.each do |name, specs|
        if specs.macro.equal?(:has_many)
          load_has_many(name)
        else
          load_has_one(name)
        end
      end
    end

    def load_has_many(name)
      collection = attributes[name]
      return unless ActiveResource::PaginatedCollection.paginatable?(collection)

      resource = reflections.fetch(name).klass
      paginated_collection = resource.
        __send__(:instantiate_collection, collection_attributes(collection))
      paginated_collection.parent_resource = self
      paginated_collection.parent_association = name
      attributes[name] = paginated_collection
    end

    def collection_attributes(collection)
      collection.attributes.transform_values do |value|
        if value.respond_to?(:map)
          value.map(&:attributes)
        else
          value
        end
      end
    end

    def load_has_one(name)
      element = attributes[name]
      return unless element.class.name.include?("::Item::")

      resource = reflections.fetch(name).klass
      attributes[name] = resource.new(element.attributes, true)
    end

    # Fixably may send back empty records with a href but that causes
    # Active Record to think there is an actual record and removes the ability
    # to perform actions that would either retrieve or create those records
    def remove_empty_associations
      reflections.each do |name, spec|
        next unless attributes.key?(name)
        next unless empty_association?(attributes.fetch(name))

        attributes.delete(name)
        if instance_variable_defined?(:"@#{name}")
          remove_instance_variable(:"@#{name}")
        end

        create_empty_collection(name) if spec.macro.equal?(:has_many)
      end
    end

    def empty_association?(record)
      return false unless record.respond_to?(:attributes)

      record.attributes.keys.eql?(%w[href])
    end

    def create_empty_collection(name)
      attributes[name] = self.class.collection_parser.new.tap do |collection|
        collection.resource_class = reflections.fetch(name).klass
        collection.parent_resource = self
        collection.parent_association = name
      end
    end
  end
end
