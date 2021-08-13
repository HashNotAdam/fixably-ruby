# frozen_string_literal: true

RSpec.describe Fixably::ApplicationResource do
  let(:resource) do
    stub_const(
      "Fixably::FakeCustomer",
      Class.new(described_class)
    )
  end

  it "instructs Active Resource to not add .json to URLs" do
    expect(described_class.include_format_in_path).to be false
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

  describe ".site_url" do
    subject(:url) { resource.__send__(:site_url) }

    context "when called on a parent resource" do
      it "returns the base URL" do
        expect(url).to eq("https://demo.fixably.com/api/v3")
      end
    end

    context "when called on a nested association" do
      let(:resource) do
        stub_const(
          "Fixably::FakeCustomer::Contact",
          Class.new(described_class)
        )
      end

      it "includes the parent ID in the URL" do
        expect(url).to eq(
          "https://demo.fixably.com/api/v3/fake_customers/:fake_customer_id"
        )
      end
    end
  end
end
