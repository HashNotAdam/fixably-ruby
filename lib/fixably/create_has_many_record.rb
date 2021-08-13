# frozen_string_literal: true

module Fixably
  class CreateHasManyRecord
    def self.call(record:, collection:)
      new(record: record, collection: collection).call
    end

    attr_reader :record
    attr_reader :collection

    def initialize(record:, collection:)
      @record = record
      @collection = collection
    end

    def call
      can_append!
      save_record
      collection.elements << record
    end

    private

    def can_append!
      instance_of_resource_class!
      nested_resource!
      parent_recource_known!
      parent_association_known!
      parent_is_persisted!
    end

    def instance_of_resource_class!
      return if record.instance_of?(collection.resource_class)

      raise(
        TypeError,
        "Appended record must be an instance of " \
        "#{collection.resource_class.name}"
      )
    end

    def nested_resource!
      return if nested_resource?

      raise(
        ArgumentError,
        "Can only appended resources nested one level deep"
      )
    end

    def nested_resource?
      name_parts = record.class.name.split("::")
      name_parts.length.equal?(3)
    end

    def parent_recource_known!
      return if collection.parent_resource

      raise "A parent resource has not been set"
    end

    def parent_association_known!
      return if collection.parent_association

      raise "The association to the parent resource has not been set"
    end

    def parent_is_persisted!
      if !collection.parent_resource.persisted?
        raise "The parent resource has not been been persisted"
      end

      if !collection.parent_resource.id?
        raise "Cannot find an ID for the parent resource"
      end
    end

    def save_record
      record.parent_association = collection.parent_association
      record.prefix_options[parent_id_key] = collection.parent_resource.id
      record.save!
    end

    def parent_id_key
      "#{collection.parent_resource.class.name.split("::").last.underscore}_id".
        to_sym
    end
  end
end
