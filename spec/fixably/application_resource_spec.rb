# frozen_string_literal: true

RSpec.describe Fixably::ApplicationResource do
  it "instructs Active Resource to not add .json to URLs" do
    expect(described_class.include_format_in_path).to be false
  end

  describe ".actions" do
    let(:all_actions) { %i[create delete list show update] }
    let(:resource) { Class.new(described_class) }

    context "when it is called on #{described_class.name}" do
      specify do
        expect { described_class.actions }.to raise_error(
          RuntimeError,
          "actions can only be called on a sub-class"
        )
      end
    end

    context "when the resource has no actions" do
      it "returns an empty array" do
        expect(resource.actions).to eq([])
      end

      it "freezes the array" do
        expect(resource.actions).to be_frozen
      end
    end

    context "when the resource has actions" do
      before { resource.instance_variable_set(:@actions, all_actions) }

      it "returns the actions array" do
        expect(resource.actions).to eq(all_actions)
      end
    end

    context "when an array is supplied" do
      it "stores an actions array" do
        resource.actions(all_actions)
        expect(resource.instance_variable_get(:@actions)).to eq(all_actions)
      end

      it "freezes the array" do
        resource.actions(all_actions)
        expect(resource.instance_variable_get(:@actions)).to be_frozen
      end

      context "when an unexpected action is supplied" do
        it "raises an ArgumentError" do
          expect { resource.actions(%i[unknown]) }.to raise_error(
            ArgumentError,
            "Unsupported action, unknown, supplied"
          )
        end
      end

      context "when actions are supplied as strings" do
        it "converts the string to a symbol" do
          actions = all_actions.map(&:to_s)
          resource.actions(actions)
          expect(resource.instance_variable_get(:@actions)).to eq(all_actions)
        end
      end
    end

    context "when a symbol is supplied" do
      it "stores the action in an array" do
        resource.actions(:create)
        expect(resource.instance_variable_get(:@actions)).to eq([:create])
      end
    end

    context "when a string is supplied" do
      it "stores the action as a symbol in an array" do
        resource.actions("create")
        expect(resource.instance_variable_get(:@actions)).to eq([:create])
      end
    end

    context "when supplying something that can't be converted into an Array" do
      it "raises an ArgumentError" do
        expect { resource.actions(OpenStruct.new) }.to raise_error(
          ArgumentError,
          "actions should be able to be converted into an Array or a Symbol"
        )
      end
    end

    context "when supplying values that can't be converted into Symbols" do
      it "raises an NoMethodError" do
        expect { resource.actions([nil]) }.to raise_error(
          NoMethodError,
          "undefined method `to_sym' for nil:NilClass"
        )
      end
    end
  end

  describe ".headers" do
    it "adds the API authorisation to the default headers" do
      api_key = Fixably.config.require(:api_key)
      expect(described_class.headers).to eq(
        { "Authorization" => api_key }
      )
    end
  end

  describe ".includes" do
    let(:resource_lazy_loader_double) do
      instance_double(Fixably::ResourceLazyLoader)
    end

    before do
      allow(Fixably::ResourceLazyLoader).
        to receive(:new).and_return(resource_lazy_loader_double)
      allow(resource_lazy_loader_double).
        to receive(:includes).and_return(resource_lazy_loader_double)
    end

    it "creates a new Fixably::ResourceLazyLoader passing in the caller" do
      described_class.includes(:association)
      expect(Fixably::ResourceLazyLoader).
        to have_received(:new).with(model: described_class)
    end

    it "send an includes message to the new instance" do
      described_class.includes(:association)
      expect(resource_lazy_loader_double).
        to have_received(:includes).with(:association)
    end

    it "returns the new instance" do
      result = described_class.includes(:association)
      expect(result).to be resource_lazy_loader_double
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

  describe "#encode" do
    it_behaves_like "an Active Resource encoder"

    context "when the resource has has_one associations" do
      let(:subclass) do
        Class.new(described_class) do
          def self.name = "Fixably::FakeCustomer"

          schema do
            integer :id
            string :name
          end

          has_one :one_thing
          has_one :another_thing
        end
      end
      let(:association_class) do
        Class.new(described_class) do
          def self.name = "Fixably::FakeAssociation"

          schema do
            integer :id
            string :name
          end
        end
      end
      let(:instance) do
        inst = subclass.new(id: 1, name: "Main thing")
        inst.one_thing = association_class.new(id: 2, name: "One thing")
        inst.another_thing = association_class.new(id: 3, name: "Another thing")
        inst
      end

      it "removes the IDs from associations" do
        expect(instance.encode).to eq(
          {
            name: "Main thing",
            oneThing: { name: "One thing" },
            anotherThing: { name: "Another thing" },
          }.to_json
        )
      end
    end

    context "when the resource has has_many associations" do
      let(:subclass) do
        Class.new(described_class) do
          def self.name = "Fixably::FakeCustomer"

          schema do
            integer :id
            string :name
          end

          has_many :many_things
          has_many :other_things
        end
      end
      let(:association_class) do
        Class.new(described_class) do
          def self.name = "Fixably::FakeAssociation"

          schema do
            integer :id
            string :name
          end
        end
      end
      let(:instance) do
        inst = subclass.new(id: 1, name: "Main thing")
        inst.attributes[:many_things] = ::ActiveResource::Collection.new([
          { id: 2, name: "Thing 2" },
          { id: 3, name: "Thing 3" },
        ])
        inst.attributes[:other_things] = ::ActiveResource::Collection.new([
          { id: 4, name: "Thing 4" },
          { id: 5, name: "Thing 5" },
        ])
        inst
      end

      it "removes the has_many associations" do
        expect(instance.encode).to eq(
          { name: "Main thing" }.to_json
        )
      end
    end
  end

  describe "#load_attributes_from_response" do
    let(:child_class) do
      Class.new(described_class) do
        def self.name = "Fixably::FakeCustomer"
      end
    end
    let(:response) { Net::HTTPOK.new(1, http_status, "") }
    let(:duplicate_response) { Net::HTTPOK.new(1, http_status, "") }
    let(:http_status) { 200 }

    before do
      allow(response).to receive(:dup).and_return(duplicate_response)
      duplicate_response.body =
        { "firstName" => "Jill", "lastName" => "Wunsch" }.to_json
      duplicate_response.instance_variable_set(:@read, true)
    end

    it "duplicates the response before making modifications" do
      child_class.new.__send__(:load_attributes_from_response, response)
      expect(response).to have_received(:dup)
    end

    context "when the request can have a body" do
      let(:http_status) { 200 }

      it "underscores the keys of the response body" do
        child_class.new.__send__(:load_attributes_from_response, response)
        expect(duplicate_response.body).to eq(
          { "first_name" => "Jill", "last_name" => "Wunsch" }.to_json
        )
      end
    end

    context "when the request can not have a body" do
      let(:http_status) { 204 }

      it "does not modify the response body" do
        child_class.new.__send__(:load_attributes_from_response, response)
        expect(duplicate_response.body).to eq(
          { "firstName" => "Jill", "lastName" => "Wunsch" }.to_json
        )
      end
    end

    it "sets the values from the response to the instance" do
      instance = child_class.new
      expect(instance).not_to respond_to(:first_name)
      instance.__send__(:load_attributes_from_response, response)
      expect(instance.first_name).to eq("Jill")
    end
  end
end
