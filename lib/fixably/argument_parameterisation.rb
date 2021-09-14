# frozen_string_literal: true

module Fixably
  module ArgumentParameterisation
    private

    def parametize_arguments(scope, arguments)
      arguments ||= {}
      arguments.merge!(arguments.delete(:params)) if arguments.key?(:params)

      associations = expand_associations(scope, arguments)
      arguments[:expand] = associations if associations

      { params: arguments }
    end

    def expand_associations(scope, arguments)
      return if arguments[:expand].instance_of?(String)

      case scope
      when :all, :first, :last
        assoc = associations(arguments)&.join(",")
        assoc ? "items(#{assoc})" : "items"
      when :one, nil, Integer, String
        associations(arguments)&.join(",")
      else
        raise ArgumentError, "Unknown scope: #{scope.inspect}"
      end
    end

    def associations(arguments)
      arguments[:expand]&.to_set { expand_association(_1) }
    end

    def expand_association(association)
      association_name = association.to_s.camelize(:lower)
      relationship = reflections.fetch(association).macro
      case relationship
      when :has_one
        association_name
      when :has_many
        "#{association_name}(items)"
      else
        raise ArgumentError, "Unknown relationship, #{relationship}"
      end
    end

    def stringify_array_values(arguments)
      arguments.tap do |args|
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
