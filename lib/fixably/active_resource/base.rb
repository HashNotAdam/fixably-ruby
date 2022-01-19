# frozen_string_literal: true

module ActiveResource
  class Base
    class << self
      private

      alias original_instantiate_record instantiate_record

      # Fixably uses camel case keys but it's more Ruby-like to use underscores
      def instantiate_record(record, prefix_options = {})
        underscored_record = record.deep_transform_keys(&:underscore)
        original_instantiate_record(underscored_record, prefix_options)
      end

      alias original_query_string query_string

      # Fixably expects all searches to be sent under a singular query parameter
      # q=search1,search2,attribute:search3
      def query_string(options)
        opts = {}

        non_query_parameters.each do |parameter|
          opts[parameter] = options.fetch(parameter) if options[parameter]
        end

        f = filters(options)
        opts[:q] = f.join(",") unless f.count.zero?

        original_query_string(opts)
      end

      def filters(options)
        options.each_with_object([]) do |(key, value), array|
          next if non_query_parameters.include?(key)

          array <<
            if key.equal?(:filter)
              value
            else
              camel_key = key.to_s.camelize(:lower)
              "#{camel_key}:#{value}"
            end
        end
      end

      def non_query_parameters = %i[expand limit offset page]
    end
  end
end

ActiveResource::Base.collection_parser =
  Fixably::ActiveResource::PaginatedCollection
