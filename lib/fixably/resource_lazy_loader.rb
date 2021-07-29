# frozen_string_literal: true

module Fixably
  class ResourceLazyLoader
    attr_reader :model
    attr_reader :associations_to_expand

    def initialize(model:)
      if !model.respond_to?(:ancestors) ||
          !model.ancestors.include?(ApplicationResource)
        raise(
          ArgumentError,
          "The model is expected to be a class that extend ApplicationResource"
        )
      end

      @model = model
      @associations_to_expand = Set.new
    end

    def includes(association)
      unless model.reflections.key?(association)
        raise(
          ArgumentError,
          "#{association} is not a known association of #{model}"
        )
      end

      associations_to_expand << association

      self
    end

    def find(*args)
      id = args.slice(0)
      options = expand_associations(args.slice(1) || {})
      arguments = [options].concat(args[2..] || [])

      model.find(id, *arguments)
    end

    def first(*args)
      options = expand_associations(args.slice(0) || {})
      arguments = [options].concat(args[1..] || [])

      model.first(*arguments)
    end

    def last(*args)
      options = expand_associations(args.slice(0) || {})
      arguments = [options].concat(args[1..] || [])

      model.last(*arguments)
    end

    def all(*args)
      options = expand_associations(args.slice(0) || {})
      arguments = [options].concat(args[1..] || [])

      model.all(*arguments)
    end

    def where(clauses = {})
      arguments = expand_associations(clauses)
      model.where(arguments)
    end

    private

    def expand_associations(args)
      expand = args[:expand].to_a.to_set
      args[:expand] = expand.merge(associations_to_expand)
      args
    end
  end
end
