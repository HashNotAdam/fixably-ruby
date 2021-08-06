# frozen_string_literal: true

require_relative "action_policy"
require_relative "argument_parameterisation"

module Fixably
  module Actions
    def self.included(klass)
      klass.extend(ClassMethods)
    end

    module ClassMethods
      include ArgumentParameterisation

      def all(*arguments)
        ActionPolicy.new(resource: self).list!
        super(*arguments)
      end

      def create(attributes = {})
        ActionPolicy.new(resource: self).create!
        super(attributes)
      end

      def create!(attributes = {})
        ActionPolicy.new(resource: self).create!
        super(attributes)
      end

      def delete(id, options = {})
        ActionPolicy.new(resource: self).delete!
        super(id, options)
      end

      def exists?(id, options = {})
        find(id, options)
        true
      rescue ::ActiveResource::ResourceNotFound
        false
      end

      def find(*arguments)
        scope = arguments.slice(0)

        ActionPolicy.new(resource: self).show! unless scope.is_a?(Symbol)

        args = parametize_arguments(scope, arguments.slice(1))

        super(scope, args)
      end

      def first(*arguments)
        ActionPolicy.new(resource: self).list!

        args = arguments.first || {}
        args[:limit] = 1
        super(args)
      end

      def last(*arguments)
        ActionPolicy.new(resource: self).list!

        args = parametize_arguments(:last, arguments.first)
        collection = find_every(args)
        return collection.last unless collection.offset.zero?
        return collection.last if collection.total_items <= collection.limit

        args = args[:params].merge(limit: 1, offset: collection.total_items - 1)
        super(args)
      end

      def where(clauses = {})
        ActionPolicy.new(resource: self).list!

        arguments = stringify_array_values(clauses)
        find(:all, arguments)
      end
    end

    def destroy
      ActionPolicy.new(resource: self).delete!
      super()
    end

    def save(validate: true)
      if validate
        message = new? ? :create! : :update!
        ActionPolicy.new(resource: self).public_send(message)
      end

      super()
    end

    # rubocop:disable Style/RaiseArgs
    def save!
      if new?
        ActionPolicy.new(resource: self).create!
      else
        ActionPolicy.new(resource: self).update!
      end

      save(validate: false) ||
        raise(::ActiveResource::ResourceInvalid.new(self))
    end
    # rubocop:enable Style/RaiseArgs
  end
end
