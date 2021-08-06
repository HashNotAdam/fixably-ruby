# frozen_string_literal: true

RSpec.describe Fixably::Customer::ShippingAddress do
  include_examples("a resource", "shipping address", nil, [])
end
