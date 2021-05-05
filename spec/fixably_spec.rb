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
  end
end
