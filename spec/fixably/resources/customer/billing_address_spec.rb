# frozen_string_literal: true

RSpec.describe Fixably::Customer::BillingAddress do
  include_examples("a resource", "billing address", nil, [])
end
