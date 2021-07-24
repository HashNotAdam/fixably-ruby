# frozen_string_literal: true

RSpec.describe Fixably::Model do
  it "instructs Active Resource to not add .json to URLs" do
    expect(described_class.include_format_in_path).to be false
  end

  describe ".headers" do
    it "adds the API authorisation to the default headers" do
      api_key = Fixably.config.require(:api_key)
      expect(described_class.headers).to eq(
        { "Authorization" => api_key }
      )
    end
  end

  describe ".site" do
    let(:subdomain) { Fixably.config.require(:subdomain) }
    let(:api_version) { "v3" }
    let(:base_uri) { "https://#{subdomain}.fixably.com/api/#{api_version}" }

    it "uses the subdomain and API version to set the base URI" do
      allow(described_class).to receive(:site=)
      described_class.site
      expect(described_class).to have_received(:site=).with(base_uri)
    end

    it "only sets the base URI if it is not already set" do
      described_class.site = base_uri
      allow(described_class).to receive(:site=)
      described_class.site
      expect(described_class).not_to have_received(:site=)
    end

    it "returns a URI instance of the base URI" do
      uri_instance = URI.parse(base_uri)
      expect(described_class.site).to eq(uri_instance)
    end
  end
end
