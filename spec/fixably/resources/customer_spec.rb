# frozen_string_literal: true

RSpec.describe Fixably::Customer do
  let(:connection) { instance_double(ActiveResource::Connection) }
  let(:response) { Net::HTTPOK.new(1, 200, "") }

  before do
    allow(described_class).to receive(:connection).and_return(connection)
    allow(connection).to receive(:get).and_return(response)
    allow(connection).to receive(:post).and_return(response)
    allow(connection).to receive(:put).and_return(response)
    response.instance_variable_set(:@read, true)
  end

  describe ".find" do
    before do
      response.body = { "firstName" => "Jill", "lastName" => "Wunsch" }.to_json
    end

    it "makes a GET request" do
      described_class.find(1)
      expect(connection).to have_received(:get).with(
        "/api/v3/customers/1?expand=items", anything
      )
    end
  end

  describe ".all" do
    before do
      response.body = {
        "limit" => 25,
        "offset" => 0,
        "totalItems" => 127,
        "items" => [
          { "firstName" => "Jill", "lastName" => "Wunsch" },
        ],
      }.to_json
    end

    it "makes a GET request" do
      described_class.all
      expect(connection).to have_received(:get).with(
        "/api/v3/customers?expand=items", anything
      )
    end
  end

  describe ".first" do
    before do
      response.body = {
        "limit" => 25,
        "offset" => 0,
        "totalItems" => 127,
        "items" => [
          { "firstName" => "Jill", "lastName" => "Wunsch" },
        ],
      }.to_json
    end

    it "makes a GET request" do
      described_class.first
      expect(connection).to have_received(:get).with(
        "/api/v3/customers?expand=items&limit=1", anything
      )
    end
  end

  describe ".last" do
    let(:total_items) { 5 }

    before do
      response.body = {
        "limit" => 25,
        "offset" => 0,
        "totalItems" => total_items,
        "items" => [
          { "firstName" => "Jill", "lastName" => "Wunsch" },
        ],
      }.to_json
    end

    it "makes a GET request" do
      described_class.last
      expect(connection).to have_received(:get).with(
        "/api/v3/customers?expand=items", anything
      )
    end

    context "when there are more items than fit in a page" do
      let(:total_items) { 91 }

      it "makes a second request to get the last item" do
        described_class.last
        expect(connection).to have_received(:get).with(
          "/api/v3/customers?expand=items", anything
        ).with(
          "/api/v3/customers?expand=items&limit=1&offset=90", anything
        )
      end
    end
  end

  describe ".where" do
    before do
      response.body = {
        "limit" => 25,
        "offset" => 0,
        "totalItems" => 127,
        "items" => [
          { "firstName" => "Jill", "lastName" => "Wunsch" },
        ],
      }.to_json
    end

    it "makes a GET request" do
      described_class.where(first_name: "Jill")

      query = { q: "firstName:Jill" }.to_query
      expect(connection).to have_received(:get).with(
        "/api/v3/customers?expand=items&#{query}", anything
      )
    end
  end

  describe ".create" do
    before do
      response.body = {
        "id" => 1,
        "firstName" => "Jill",
        "lastName" => "Wunsch",
        "phone" => "1",
      }.to_json
    end

    it "makes a POST request" do
      described_class.
        create(first_name: "Emilee", last_name: "Jerde", phone: "1")

      expect(connection).to have_received(:post).with(
        "/api/v3/customers",
        { firstName: "Emilee", lastName: "Jerde", phone: "1" }.to_json,
        anything
      )
    end

    it "updates the attributes based on the response" do
      result = described_class.
        create(first_name: "Emilee", last_name: "Jerde", phone: "1")

      expect(result.attributes).to eq(
        {
          "id" => 1, "first_name" => "Jill", "last_name" => "Wunsch",
          "phone" => "1",
        }
      )
    end
  end

  describe ".delete" do
    it "raises an error" do
      expect { described_class.delete(1) }.to raise_error(
        Fixably::UnsupportedError, "Fixably does not support deleting customers"
      )
    end

    it "accepts an id and options for interface compatibility" do
      expect { described_class.delete(1, argument: "A") }.to raise_error(
        Fixably::UnsupportedError, "Fixably does not support deleting customers"
      )
    end
  end

  describe "#destroy" do
    it "raises an error" do
      expect { described_class.new.destroy }.to raise_error(
        Fixably::UnsupportedError, "Fixably does not support deleting customers"
      )
    end
  end

  describe "#save" do
    before do
      response.body = {
        "id" => 1,
        "firstName" => "Jill",
        "lastName" => "Wunsch",
        "phone" => "2",
      }.to_json
    end

    context "when both the email and phone are blank" do
      it "is invalid" do
        instance = described_class.new
        expect(instance).not_to be_valid

        instance = described_class.new(phone: "")
        expect(instance).not_to be_valid
        instance = described_class.new(phone: "1")
        expect(instance).to be_valid

        instance = described_class.new(email: "")
        expect(instance).not_to be_valid
        instance = described_class.new(email: "@")
        expect(instance).to be_valid
      end
    end

    context "when the record is new" do
      it "makes a POST request" do
        instance = described_class.
          new(first_name: "Emilee", last_name: "Jerde", phone: "1")
        instance.save

        expect(connection).to have_received(:post).with(
          "/api/v3/customers",
          { firstName: "Emilee", lastName: "Jerde", phone: "1" }.to_json,
          anything
        )
      end

      it "updates the attributes based on the response" do
        instance = described_class.
          new(first_name: "Emilee", last_name: "Jerde", phone: "1")
        instance.save

        expect(instance.attributes).to eq(
          {
            "id" => 1, "first_name" => "Jill", "last_name" => "Wunsch",
            "phone" => "2",
          }
        )
      end
    end

    context "when the record is being updated" do
      it "makes a PUT request" do
        instance = described_class.
          new(first_name: "Emilee", last_name: "Jerde", phone: "1")
        instance.instance_variable_set(:@persisted, true)
        instance.save

        expect(connection).to have_received(:put).with(
          "/api/v3/customers/",
          { firstName: "Emilee", lastName: "Jerde", phone: "1" }.to_json,
          anything
        )
      end

      it "updates the attributes based on the response" do
        instance = described_class.
          new(first_name: "Emilee", last_name: "Jerde", phone: "1")
        instance.instance_variable_set(:@persisted, true)
        instance.save

        expect(instance.attributes).to eq(
          {
            "id" => 1, "first_name" => "Jill", "last_name" => "Wunsch",
            "phone" => "2",
          }
        )
      end
    end
  end

  describe "#encode" do
    let(:attributes) do
      {
        "id" => 1,
        "first_name" => "Jennefer",
        "last_name" => "Crona",
        "tags" => [],
      }
    end
    let(:sanitised_attributes) do
      {
        "firstName" => "Jennefer",
        "lastName" => "Crona",
      }
    end

    it_behaves_like "an Active Resource encoder"

    it "removes attributes that would be rejected by the Fixably API" do
      instance = described_class.new
      instance.instance_variable_set(:@attributes, attributes)
      expect(instance.encode).to eq(sanitised_attributes.to_json)
    end
  end
end
