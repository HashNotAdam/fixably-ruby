# frozen_string_literal: true

module Fixably
  module Validators
    class Filters < Interaction
      hash :permitted_filters, strip: false
      hash :filters, default: {}, strip: false

      validate :required_filters_supplied
      validate :unpermitted_filters_supplied
      validate :filters_are_of_expected_type

      def execute
        true
      end

      private

      def required_filters_supplied
        required_filters.each do
          next unless filters[_1].nil?

          errors.add(:base, "The endpoint requires the #{_1} filter")
        end
      end

      def required_filters
        permitted_filters.each_with_object([]) do |(name, specs), required|
          required << name if specs.fetch(:required) == true
        end
      end

      def unpermitted_filters_supplied
        unpermitted_filters.each do
          errors.add(:base, "Received unexpected parameter, #{_1}")
        end
      end

      def unpermitted_filters
        filters.keys - permitted_filters.keys
      end

      def filters_are_of_expected_type
        filters.each do |name, value|
          specifications = permitted_filters[name]
          next if specifications.nil?

          type = specifications.fetch(:type)
          next if value.is_a?(type)

          errors.add(
            :base,
            "Expected #{name} to be a #{type} but it is a #{value.class}"
          )
        end
      end
    end
  end
end
