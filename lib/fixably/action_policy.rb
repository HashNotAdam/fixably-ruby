# frozen_string_literal: true

module Fixably
  class ActionPolicy
    attr_reader :resource

    def initialize(resource:)
      @resource = resource.instance_of?(Class) ? resource : resource.class
      validate_resource!
    end

    def create?
      resource.actions.include?(:create)
    end

    def create!
      return true if create?

      raise(
        UnsupportedError,
        "Fixably does not support creating #{resource_name}"
      )
    end

    def delete?
      resource.actions.include?(:delete)
    end

    def delete!
      return true if delete?

      raise(
        UnsupportedError,
        "Fixably does not support deleting #{resource_name}"
      )
    end

    def list?
      resource.actions.include?(:list)
    end

    def list!
      return true if list?

      raise(
        UnsupportedError,
        "Fixably does not support listing #{resource_name}"
      )
    end

    def show?
      resource.actions.include?(:show)
    end

    def show!
      return true if show?

      raise(
        UnsupportedError,
        "Fixably does not support retrieving #{resource_name}"
      )
    end

    def update?
      resource.actions.include?(:update)
    end

    def update!
      return true if update?

      raise(
        UnsupportedError,
        "Fixably does not support updating #{resource_name}"
      )
    end

    private

    def validate_resource!
      return if resource.ancestors.include?(ApplicationResource)

      raise(
        ArgumentError,
        "The resource should inherit from ApplicationResource"
      )
    end

    def resource_name
      resource.name.split("::").last.underscore.humanize.pluralize.downcase
    end
  end

  class UnsupportedError < StandardError; end
end
