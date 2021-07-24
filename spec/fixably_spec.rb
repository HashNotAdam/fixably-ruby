# frozen_string_literal: true

RSpec.describe Fixably do
  it "has a version number" do
    expect(Fixably::VERSION).not_to be nil
  end

  describe ".config" do
    it "returns the current configuration" do
      expect(described_class.config.class).to be Fixably::Config
    end
  end

  describe ".configure" do
    after { Fixably::Helpers::Config.configure }

    it "sets configuration variables passed into a block" do
      described_class.configure do |config|
        config.api_key = "api_key"
      end

      expect(described_class.config.api_key).to eq "api_key"
    end

    context "when a block is not supplied" do
      it "raises an ArgumentError" do
        expect { described_class.configure }.to raise_error(
          ArgumentError,
          "configure must be called with a block"
        )
      end
    end
  end

  describe ".logger" do
    let(:config_spy) { Fixably::Config.new }
    let(:previous_config) { described_class.config }
    let(:logger) { Logger.new(nil) }

    before do
      previous_config
      described_class.instance_variable_set(:@config, config_spy)
      allow(config_spy).to receive(:logger).and_return(logger)
    end

    after do
      described_class.instance_variable_set(:@config, previous_config)
    end

    it "returns the current logger as defined in the configuration" do
      expect(described_class.logger).to be logger
    end
  end
end
