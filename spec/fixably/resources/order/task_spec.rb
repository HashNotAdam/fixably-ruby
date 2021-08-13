# frozen_string_literal: true

RSpec.describe Fixably::Order::Task do
  describe ".update" do
    it "is not implemented" do
      instance = described_class.new
      instance.instance_variable_set(:@persisted, true)
      expect { instance.save }.
        to raise_error("Updating order tasks has not been implemented")
    end
  end
end
