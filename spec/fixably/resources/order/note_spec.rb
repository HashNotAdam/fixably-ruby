# frozen_string_literal: true

RSpec.describe Fixably::Order::Note do
  include_examples(
    "a nested resource",
    "note",
    "orders/:order_id/notes",
    %i[create list show],
    { type: "INTERNAL" }.with_indifferent_access
  )

  describe "validation" do
    context "when the record is empty" do
      subject { described_class.new }

      it { is_expected.not_to be_valid }
    end

    context "when the type is DIAGNOSIS" do
      subject do
        instance = described_class.new
        instance.type = "DIAGNOSIS"
        instance
      end

      it { is_expected.to be_valid }
    end

    context "when the type is INTERNAL" do
      subject do
        instance = described_class.new
        instance.type = "INTERNAL"
        instance
      end

      it { is_expected.to be_valid }
    end

    context "when the type is ISSUE" do
      subject do
        instance = described_class.new
        instance.type = "ISSUE"
        instance
      end

      it { is_expected.to be_valid }
    end

    context "when the type is RESOLUTION" do
      subject do
        instance = described_class.new
        instance.type = "RESOLUTION"
        instance
      end

      it { is_expected.to be_valid }
    end

    context "when the type is something else" do
      subject do
        instance = described_class.new
        instance.type = "OTHER"
        instance
      end

      it { is_expected.not_to be_valid }
    end
  end
end
