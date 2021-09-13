# frozen_string_literal: true

RSpec.describe Fixably::Order::Task do
  include_examples(
    "a nested resource",
    "task",
    "orders/:order_id/tasks",
    %i[list show]
  )
end
