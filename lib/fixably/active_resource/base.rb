# frozen_string_literal: true

ActiveResource::Base.singleton_class.class_eval do
  private

  alias_method :original_instantiate_collection, :instantiate_collection

  # Active Resource expects collection responses to be an array of elements
  # but Fixably includes the collection in an "items" key
  def instantiate_collection(
    collection_wrapper, original_params = {}, prefix_options = {}
  )
    collection = collection_wrapper.fetch("items")
    result = original_instantiate_collection(
      collection, original_params, prefix_options
    )
    result.instance_variable_set(:@limit, collection_wrapper.fetch("limit"))
    result.instance_variable_set(:@offset, collection_wrapper.fetch("offset"))
    result.instance_variable_set(
      :@total_items, collection_wrapper.fetch("totalItems")
    )
    result
  end
end

ActiveResource::Base.collection_parser =
  Fixably::ActiveResource::PaginatedCollection
