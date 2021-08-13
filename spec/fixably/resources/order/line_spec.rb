# frozen_string_literal: true

RSpec.describe Fixably::Order::Line do
  include_examples(
    "a nested resource",
    "line",
    "orders/:order_id/lines",
    %i[list show]
  )
end
