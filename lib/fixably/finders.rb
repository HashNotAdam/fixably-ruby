# frozen_string_literal: true

module Fixably
  module Finders
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
      arguments = stringify_array_values(clauses)
      find(:all, arguments)
    end

    private

    def parametize_arguments(arguments)
      arguments ||= {}
      params = arguments.dup
      params[:expand] = expand_associations(params)
      { params: params }
    end

    def expand_associations(arguments)
      if arguments[:expand].present? && arguments[:expand].is_a?(String)
        return arguments[:expand]
      end

      associations = arguments.fetch(:expand, []).map { "#{_1}(items)" }
      result = Set.new
      result << "items"
      result.merge(associations)
      result.join(",")
    end

    def stringify_array_values(arguments)
      arguments.dup.tap do |args|
        args.each do |attribute, value|
          next unless value.is_a?(Array)

          validate_array_value!(attribute, value)
          value << nil if value.length.equal?(1)
          args[attribute] = "[#{value.map { stringify(_1) }.join(",")}]"
        end
      end
    end

    def validate_array_value!(attribute, value)
      return if value.length.positive? && value.length <= 2

      raise(
        ArgumentError,
        "Ranged searches should have either 1 or 2 values but " \
        "#{attribute} has #{value.length}"
      )
    end

    def stringify(value)
      if value.respond_to?(:strftime)
        value.strftime("%F")
      else
        value
      end
    end
  end
end
