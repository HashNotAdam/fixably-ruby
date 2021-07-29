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
    end
  end
end
