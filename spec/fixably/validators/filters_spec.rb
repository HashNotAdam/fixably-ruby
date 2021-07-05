# frozen_string_literal: true

RSpec.describe Fixably::Validators::Filters do
  subject(:run!) do
    described_class.run!(permitted_filters: permitted_filters, filters: filters)
  end

  let(:permitted_filters) do
    {
      limit: {
        required: true,
        type: Integer,
      },
      offset: {
        required: true,
        type: Integer,
      },
    }
  end

  context "when the supplied filters are valid" do
    let(:filters) do
      {
        limit: 10,
        offset: 5,
      }
    end

    it { is_expected.to be true }
  end

  context "when filters is not supplied" do
    subject { described_class.run!(permitted_filters: permitted_filters) }

    let(:permitted_filters) do
      {
        limit: {
          required: false,
          type: Integer,
        },
        offset: {
          required: false,
          type: Integer,
        },
      }
    end

    it { is_expected.to be true }
  end

  it "requires that permitted_filters is supplied" do
    expect { described_class.run! }.to raise_error(
      ActiveInteraction::InvalidInteractionError,
      "Permitted filters is required"
    )
  end

  context "when required parameters are not supplied" do
    let(:filters) do
      {}
    end

    it "raises an error" do
      expect { run! }.to raise_error(
        ActiveInteraction::InvalidInteractionError,
        "The endpoint requires the limit filter, " \
        "The endpoint requires the offset filter"
      )
    end
  end

  context "when unpermitted parameters are supplied" do
    let(:filters) do
      {
        limit: 10,
        offset: 5,
        foo: "bar",
        baz: "fuzz",
      }
    end

    it "raises an error" do
      expect { run! }.to raise_error(
        ActiveInteraction::InvalidInteractionError,
        "Received unexpected parameter, foo, Received unexpected parameter, baz"
      )
    end
  end

  context "when filters are supplied with incorrect types" do
    let(:filters) do
      {
        limit: "limit",
        offset: {},
      }
    end

    it "raises an error" do
      expect { run! }.to raise_error(
        ActiveInteraction::InvalidInteractionError,
        "Expected limit to be a Integer but it is a String, " \
        "Expected offset to be a Integer but it is a " \
        "ActiveSupport::HashWithIndifferentAccess"
      )
    end
  end
end
