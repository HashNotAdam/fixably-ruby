# frozen_string_literal: true

RSpec.describe Fixably::Config do
  let(:instance) do
    inst = described_class.new
    inst.api_key = api_key
    inst.subdomain = subdomain
    inst
  end

  let(:api_key) { "api_key" }
  let(:subdomain) { "subdomain" }

  describe "#require" do
    it "returns the value of the requested parameter" do
      expect(instance.require(:api_key)).to eq(api_key)
    end

    context "when the parameter has not been set" do
      let(:api_key) { nil }

      it "raises an ArgumentError" do
        expect { instance.require(:api_key) }.to raise_error(
          ArgumentError,
          <<~MESSAGE
            api_key is required but hasn't been set.
            Fixably.configure do |config|
              config.api_key = "value"
            end
          MESSAGE
        )
      end
    end

    context "when the parameter is an empty string" do
      let(:api_key) { "" }

      it "raises an ArgumentError" do
        expect { instance.require(:api_key) }.to raise_error(
          ArgumentError,
          <<~MESSAGE
            api_key is required but hasn't been set.
            Fixably.configure do |config|
              config.api_key = "value"
            end
          MESSAGE
        )
      end
    end
  end
end
