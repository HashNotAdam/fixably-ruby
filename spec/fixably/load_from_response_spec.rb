# frozen_string_literal: true

RSpec.describe Fixably::LoadFromResponse do
  let(:resource) do
    stub_const(
      "Fixably::FakeCustomer",
      Class.new(Fixably::ApplicationResource) do
        has_one :association, class_name: "fixably/fake_association"
        has_many :associations, class_name: "fixably/fake_association"
        has_many :many_associations, class_name: "fixably/fake_association"
      end
    )
  end
  let!(:fake_association) do
    stub_const(
      "Fixably::FakeAssociation",
      Class.new(Fixably::ApplicationResource) do
        has_one :association, class_name: "fixably/fake_association"
      end
    )
  end

  describe "#load" do
    let(:attributes) do
      {}
    end

    it "returns self" do
      instance = resource.new
      result = instance.load(attributes)
      expect(instance).to be(result)
    end

    context "when the attributes include a has_one association" do
      subject(:association) do
        instance = resource.new.load(attributes)
        instance.association
      end

      let(:attributes) do
        {
          "firstName" => "Davis",
          "lastName" => "Turner",
          "association" => { "firstName" => "Jill", "lastName" => "Wunsch" },
        }
      end

      it "creates a new instance of the association" do
        expect(association).to be_instance_of(fake_association)
      end

      it "populates the instance with the attributes" do
        expect(association.attributes).to eq(attributes["association"])
      end
    end

    context "when the attributes include a paginated has_many association" do
      subject(:associations) { instance.associations }

      let(:instance) { resource.new.load(attributes) }
      let(:attributes) do
        {
          "firstName" => "Davis",
          "lastName" => "Turner",
          "associations" => {
            "limit" => 25,
            "offset" => 0,
            "total_items" => 25,
            "items" => [
              { "firstName" => "Jill", "lastName" => "Wunsch" },
              { "firstName" => "Randell", "lastName" => "Huels" },
            ],
          },
        }
      end

      it "returns a PaginatedCollection" do
        expect(associations).
          to be_a(Fixably::ActiveResource::PaginatedCollection)
      end

      it "sets the current resource as the collection parent_resource" do
        expect(associations.parent_resource).to be(instance)
      end

      it "sets the association name as the collection parent_association" do
        expect(associations.parent_association).to be(:associations)
      end

      it "sets the pagination metadata" do
        expect(associations.limit).to eq(25)
        expect(associations.offset).to eq(0)
        expect(associations.total_items).to eq(25)
      end

      it "loads the records into resource instances" do
        expect(associations.count).to eq(2)
        expect(associations[0]).to be_instance_of(fake_association)
        expect(associations[1]).to be_instance_of(fake_association)
      end

      it "populates the records with the attributes" do
        expect(associations[0].attributes).
          to eq("first_name" => "Jill", "last_name" => "Wunsch")
        expect(associations[1].attributes).
          to eq({ "first_name" => "Randell", "last_name" => "Huels" })
      end

      context "when there is a nested has_one association" do
        subject(:nested_association) { associations.first.association }

        let(:attributes) do
          {
            "firstName" => "Davis",
            "lastName" => "Turner",
            "associations" => {
              "limit" => 25,
              "offset" => 0,
              "total_items" => 25,
              "items" => [
                {
                  "firstName" => "Jill",
                  "lastName" => "Wunsch",
                  "association" => {
                    "firstName" => "Tiffany",
                    "lastName" => "Gerlach",
                  },
                },
              ],
            },
          }
        end

        it "creates a new instance of the correct association" do
          expect(nested_association).to be_instance_of(fake_association)
        end

        it "marks the record as persisted" do
          expect(nested_association.persisted?).to be true
        end
      end
    end

    context "when the attributes include an unpaginated has_many association" do
      let(:attributes) do
        {
          "firstName" => "Davis",
          "lastName" => "Turner",
          "associations" => [
            { "firstName" => "Jill", "lastName" => "Wunsch" },
            { "firstName" => "Randell", "lastName" => "Huels" },
          ],
        }
      end

      it "returns a PaginatedCollection" do
        result = resource.new.load(attributes)
        expect(result.associations).to be_instance_of(Array)
      end

      it "loads the records into resource instances" do
        result = resource.new.load(attributes)
        expect(result.associations.count).to eq(2)
        expect(result.associations[0]).to be_a(fake_association)
        expect(result.associations[1]).to be_a(fake_association)
      end
    end

    context "when a has_one association is nothing more than a href" do
      let(:attributes) do
        {
          "firstName" => "Davis",
          "lastName" => "Turner",
          "association" => { "href" => "https://demo.fixably.com/..." },
        }
      end

      it "removes the association from the attributes" do
        instance = resource.new.load(attributes)
        expect(instance.attributes.key?("association")).to be false
      end

      it "removes an associationed instance variable if one exists" do
        instance = resource.new
        instance.instance_variable_set(:@association, nil)
        instance.load(attributes)
        expect(instance.instance_variable_defined?(:@association)).to be false
      end
    end

    context "when a has_many association is nothing more than a href" do
      let(:attributes) do
        {
          "firstName" => "Davis",
          "lastName" => "Turner",
          "associations" => { "href" => "https://demo.fixably.com/..." },
        }
      end

      it "replaces the attributes with an empty collection" do
        instance = resource.new.load(attributes)
        attributes = instance.attributes["associations"]
        expect(attributes).
          to be_instance_of(Fixably::ActiveResource::PaginatedCollection)
        expect(attributes).to be_empty
      end

      it "sets the resource_class of the collection" do
        instance = resource.new.load(attributes)
        attributes = instance.attributes["associations"]
        expect(attributes.resource_class).to be(fake_association)
      end

      it "sets the parent_resource of the collection" do
        instance = resource.new.load(attributes)
        attributes = instance.attributes["associations"]
        expect(attributes.parent_resource).to be(instance)
      end

      it "sets the parent_association of the collection" do
        instance = resource.new.load(attributes)
        attributes = instance.attributes["associations"]
        expect(attributes.parent_association).to be(:associations)
      end

      it "removes an associationed instance variable if one exists" do
        instance = resource.new
        instance.instance_variable_set(:@associations, nil)
        instance.load(attributes)
        expect(instance.instance_variable_defined?(:@associations)).to be false
      end

      context "when another has_many association is a valid record" do
        let(:attributes) do
          {
            "firstName" => "Davis",
            "lastName" => "Turner",
            "associations" => {
              "href" => "https://demo.fixably.com/...",
              "id" => 1,
            },
            "many_associations" => { "href" => "https://demo.fixably.com/..." },
          }
        end

        it "does not remove the valid association" do
          instance = resource.new.load(attributes)
          expect(instance.attributes.key?("associations")).to be true
        end

        it "replaces the invalid association with an empty collection" do
          instance = resource.new.load(attributes)
          attrs = instance.attributes["many_associations"]
          expect(attrs).
            to be_instance_of(Fixably::ActiveResource::PaginatedCollection)
          expect(attrs).to be_empty
        end
      end
    end
  end

  describe "#load_attributes_from_response" do
    let(:response) { Net::HTTPOK.new(1, http_status, "") }
    let(:duplicate_response) { Net::HTTPOK.new(1, http_status, "") }
    let(:response_body) do
      { "firstName" => "Jill", "lastName" => "Wunsch" }
    end
    let(:http_status) { 200 }

    before do
      allow(response).to receive(:dup).and_return(duplicate_response)
      duplicate_response.body = response_body.to_json
      duplicate_response.instance_variable_set(:@read, true)
    end

    it "duplicates the response before making modifications" do
      resource.new.__send__(:load_attributes_from_response, response)
      expect(response).to have_received(:dup)
    end

    context "when the request can have a body" do
      let(:http_status) { 200 }

      it "underscores the keys of the response body" do
        resource.new.__send__(:load_attributes_from_response, response)
        expect(duplicate_response.body).to eq(
          { "first_name" => "Jill", "last_name" => "Wunsch" }.to_json
        )
      end
    end

    describe "a response from creating a has_many association" do
      let(:response_body) do
        [{ "firstName" => "Jill", "lastName" => "Wunsch" }]
      end

      it "extracts the first record from the array" do
        resource.new.__send__(:load_attributes_from_response, response)
        expect(duplicate_response.body).to eq(
          { "first_name" => "Jill", "last_name" => "Wunsch" }.to_json
        )
      end
    end

    context "when an array body has multiple records" do
      let(:response_body) do
        [
          { "firstName" => "Jill", "lastName" => "Wunsch" },
          { "firstName" => "Davis", "lastName" => "Turner" },
        ]
      end

      it "raises a RuntimeError" do
        expect do
          resource.new.__send__(:load_attributes_from_response, response)
        end.to raise_error(
          ArgumentError,
          "Unable to unpack an array response with more than 1 record"
        )
      end
    end

    context "when the request can not have a body" do
      let(:http_status) { 204 }

      it "does not modify the response body" do
        resource.new.__send__(:load_attributes_from_response, response)
        expect(duplicate_response.body).to eq(
          { "firstName" => "Jill", "lastName" => "Wunsch" }.to_json
        )
      end
    end

    it "sets the values from the response to the instance" do
      instance = resource.new
      expect(instance).not_to respond_to(:first_name)
      instance.__send__(:load_attributes_from_response, response)
      expect(instance.first_name).to eq("Jill")
    end
  end
end
