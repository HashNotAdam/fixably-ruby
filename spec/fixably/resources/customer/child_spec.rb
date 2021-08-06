# frozen_string_literal: true

RSpec.describe Fixably::Customer::Child do
  include_examples(
    "a nested resource",
    "children",
    "customers/:customer_id/children",
    %i[show]
  )
end
