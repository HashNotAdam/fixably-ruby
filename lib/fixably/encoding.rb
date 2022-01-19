# frozen_string_literal: true

module Fixably
  module Encoding
    # Since our monkey patch converts the keys to underscore, it is necessary to
    # convert them back to camelcase when performing a create or update
    def encode(_options = nil, attrs: nil)
      attrs ||= attributes
      remove_has_many_associations(attrs)
      remove_unallowed_parameters(attrs)
      nest_for_association(attrs).
        deep_transform_keys { _1.camelize(:lower) }.
        public_send("to_#{self.class.format.extension}")
    end

    protected

    def remove_on_encode = %w[created_at href id]

    def remove_has_many_associations(attrs)
      has_many_reflections = reflections.select do |_name, reflection|
        reflection.macro.equal?(:has_many)
      end

      has_many_reflections.each_key do |reflection_name|
        attrs.delete(reflection_name)
      end
    end

    private

    def remove_unallowed_parameters(attrs)
      remove_on_encode.each { attrs.delete(_1) }
    end

    def nest_for_association(attrs)
      return attrs unless parent_association

      { parent_association.to_s => [attrs] }
    end
  end
end
