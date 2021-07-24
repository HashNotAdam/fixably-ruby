# frozen_string_literal: true

module Fixably
  module ActiveResource
    class PaginatedCollection < ::ActiveResource::Collection
      attr_reader :limit
      attr_reader :offset
      attr_reader :total_items
    end
  end
end
