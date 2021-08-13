# frozen_string_literal: true

RSpec.describe Fixably::Order do
  include_examples(
    "a resource",
    "order",
    "orders",
    %i[create list show]
  )

  describe "validation" do
    context "when the record is empty" do
      subject { described_class.new }

      it { is_expected.to be_valid }
    end

    context "when the internal_location is CUSTOMER" do
      subject do
        instance = described_class.new
        instance.internal_location = "CUSTOMER"
        instance
      end

      it { is_expected.to be_valid }
    end

    context "when the internal_location is DEALER_SHOP" do
      subject do
        instance = described_class.new
        instance.internal_location = "DEALER_SHOP"
        instance
      end

      it { is_expected.to be_valid }
    end

    context "when the internal_location is IN_TRANSIT" do
      subject do
        instance = described_class.new
        instance.internal_location = "IN_TRANSIT"
        instance
      end

      it { is_expected.to be_valid }
    end

    context "when the internal_location is SERVICE" do
      subject do
        instance = described_class.new
        instance.internal_location = "SERVICE"
        instance
      end

      it { is_expected.to be_valid }
    end

    context "when the internal_location is STORE" do
      subject do
        instance = described_class.new
        instance.internal_location = "STORE"
        instance
      end

      it { is_expected.to be_valid }
    end

    context "when the internal_location is something else" do
      subject do
        instance = described_class.new
        instance.internal_location = "OTHER"
        instance
      end

      it { is_expected.not_to be_valid }
    end
  end
end
