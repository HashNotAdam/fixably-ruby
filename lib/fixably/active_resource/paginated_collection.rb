# frozen_string_literal: true

module Fixably
  module ActiveResource
    class PaginatedCollection < ::ActiveResource::Collection
      attr_reader :limit
      attr_reader :offset
      attr_reader :total_items

      def initialize(collection_wrapper)
        @limit = collection_wrapper.fetch("limit")
        @offset = collection_wrapper.fetch("offset")
        @total_items = collection_wrapper.fetch("totalItems")

        collection = collection_wrapper.fetch("items")
        super(collection)
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
