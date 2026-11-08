# frozen_string_literal: true

RSpec.describe Fixably::Order::File do
  include_examples(
    "a nested resource",
    "file",
    "orders/:order_id/files",
    %i[list]
  )
end
