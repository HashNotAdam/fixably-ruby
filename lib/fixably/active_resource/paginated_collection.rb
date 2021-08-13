# frozen_string_literal: true

require_relative "../create_has_many_record"

module Fixably
  module ActiveResource
    class PaginatedCollection < ::ActiveResource::Collection
      class << self
        def paginatable?(value)
          collection = attributes(value)
          return false unless collection.is_a?(Hash)

          interface = %w[limit offset total_items items]
          (interface - collection.keys).empty?
        end

        def attributes(collection_wrapper)
          if collection_wrapper.respond_to?(:attributes)
            collection_wrapper.attributes
          else
            collection_wrapper
          end
        end
      end

      attr_reader :limit
      attr_reader :offset
      attr_reader :total_items

      attr_accessor :parent_resource
      attr_accessor :parent_association

      def initialize(collection_wrapper = nil)
        @limit = collection_wrapper&.fetch("limit") || 0
        @offset = collection_wrapper&.fetch("offset") || 0
        @total_items = collection_wrapper&.fetch("totalItems") do
          collection_wrapper.fetch("total_items")
        end || 0

        collection = collection_wrapper&.fetch("items") || []
        super(collection)
      end

      def <<(record)
        CreateHasManyRecord.(record: record, collection: self)
      end

      def paginated_each
        page = self

        loop do
          page.each { yield(_1) }
          break unless page.next_page?

          page = page.next_page
        end
      end

      def paginated_map
        [].tap do |records|
          paginated_each { records << _1 }
        end
      end

      def next_page
        raise StopIteration, "There are no more pages" unless next_page?

        where(limit: limit, offset: offset + limit)
      end

      def next_page?
        (limit + offset) < total_items
      end

      def previous_page
        raise StopIteration, "There are no more pages" unless previous_page?

        new_offset = offset - limit
        new_limit = limit
        new_limit += new_offset if new_offset.negative?
        new_offset = 0 if new_offset.negative?

        where(limit: new_limit, offset: new_offset)
      end

      def previous_page?
        offset.positive?
      end
    end
  end
end
