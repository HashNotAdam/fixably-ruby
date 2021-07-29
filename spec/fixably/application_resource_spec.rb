# frozen_string_literal: true

RSpec.describe Fixably::ApplicationResource do
  it "instructs Active Resource to not add .json to URLs" do
    expect(described_class.include_format_in_path).to be false
  end

  describe ".find" do
    before { allow(ActiveResource::Base).to receive(:find) }

    it "passes the message to ActiveResource with a request to expand items" do
      described_class.find(1)
      expect(ActiveResource::Base).to have_received(:find).
        with(1, params: { expand: "items" })
    end

    context "when expanded associations are supplied" do
      it "merges the supplied associations with items" do
        described_class.find(1, expand: [:association])
        expect(ActiveResource::Base).to have_received(:find).
          with(1, params: { expand: "items,association(items)" })
      end

      context "when expand is a string" do
        it "passes it on unmodified" do
          described_class.find(1, expand: "do not modify")
          expect(ActiveResource::Base).to have_received(:find).
            with(1, params: { expand: "do not modify" })
        end
      end
    end

    context "when options are supplied" do
      it "merges the options into the params" do
        described_class.find(1, { option1: "A", option2: "B" })
        expect(ActiveResource::Base).to have_received(:find).
          with(
            1,
            { params: { expand: "items", option1: "A", option2: "B" } }
          )
      end

      it "does not modify the supplied arguments directly" do
        arguments = { option1: "A", option2: "B" }
        described_class.find(1, arguments)
        expect(arguments).to eq(option1: "A", option2: "B")
      end
    end
  end

  describe ".first" do
    before { allow(ActiveResource::Base).to receive(:first) }

    it "sets the limit parameter to 1 before passing on the message" do
      described_class.first
      expect(ActiveResource::Base).to have_received(:first).with(limit: 1)
    end

    context "when arguments are supplied" do
      it "forwards the arguments" do
        described_class.first(argument1: "A", argument2: "B")
        expect(ActiveResource::Base).to have_received(:first).
          with(argument1: "A", argument2: "B", limit: 1)
      end
    end
  end

  describe ".last" do
    before do
      allow(ActiveResource::Base).to receive(:find_every).and_return(collection)
    end

    context "when there are no results for the search" do
      let(:collection) do
        Fixably::ActiveResource::PaginatedCollection.new(
          { "limit" => 25, "offset" => 0, "totalItems" => 0, "items" => [] }
        )
      end

      it "makes the request via find_every" do
        described_class.last(argument1: "A", argument2: "B")
        expect(ActiveResource::Base).
          to have_received(:find_every).with(
            params: { argument1: "A", argument2: "B", expand: "items" }
          )
      end

      it "returns nil" do
        expect(described_class.last).to be_nil
      end

      it "does not make a second request" do
        allow(ActiveResource::Base).to receive(:last)
        described_class.last
        expect(ActiveResource::Base).not_to have_received(:last)
      end
    end

    context "when the user provides an offset" do
      let(:collection) do
        Fixably::ActiveResource::PaginatedCollection.new(
          { "limit" => 3, "offset" => 5, "totalItems" => 50, "items" => items }
        )
      end
      let(:items) { [{ "id" => 6 }, { "id" => 7 }, { "id" => 8 }] }

      it "makes the request via find_every" do
        described_class.last(offset: 5)
        expect(ActiveResource::Base).
          to have_received(:find_every).with(
            params: { offset: 5, expand: "items" }
          )
      end

      it "returns the last item" do
        result = described_class.last(offset: 5)
        expect(result).to eq(items.last)
      end

      it "does not make a second request" do
        allow(ActiveResource::Base).to receive(:last)
        described_class.last(offset: 5)
        expect(ActiveResource::Base).not_to have_received(:last)
      end
    end

    context "when the number of records is less than the page length" do
      let(:collection) do
        Fixably::ActiveResource::PaginatedCollection.new(
          { "limit" => 25, "offset" => 0, "totalItems" => 3, "items" => items }
        )
      end
      let(:items) { [{ "id" => 1 }, { "id" => 2 }, { "id" => 3 }] }

      it "makes the request via find_every" do
        described_class.last
        expect(ActiveResource::Base).
          to have_received(:find_every).with(params: { expand: "items" })
      end

      it "returns the last item" do
        expect(described_class.last).to eq(items.last)
      end

      it "does not make a second request" do
        allow(ActiveResource::Base).to receive(:last)
        described_class.last
        expect(ActiveResource::Base).not_to have_received(:last)
      end
    end

    context "when the number of records is equal to the page length" do
      let(:collection) do
        Fixably::ActiveResource::PaginatedCollection.new(
          { "limit" => 3, "offset" => 0, "totalItems" => 3, "items" => items }
        )
      end
      let(:items) { [{ "id" => 1 }, { "id" => 2 }, { "id" => 3 }] }

      it "makes the request via find_every" do
        described_class.last
        expect(ActiveResource::Base).
          to have_received(:find_every).with(params: { expand: "items" })
      end

      it "returns the last item" do
        expect(described_class.last).to eq(items.last)
      end

      it "does not make a second request" do
        allow(ActiveResource::Base).to receive(:last)
        described_class.last
        expect(ActiveResource::Base).not_to have_received(:last)
      end
    end

    context "when the number of records is greater than the page length" do
      let(:collection) do
        Fixably::ActiveResource::PaginatedCollection.new(
          { "limit" => 25, "offset" => 0, "totalItems" => 90, "items" => [] }
        )
      end

      before do
        allow(ActiveResource::Base).to receive(:last).and_return("id" => 90)
      end

      it "makes the request via find_every" do
        described_class.last
        expect(ActiveResource::Base).
          to have_received(:find_every).with(params: { expand: "items" })
      end

      it "makes a second request via ActiveResource::Base.last" do
        described_class.last
        expect(ActiveResource::Base).
          to have_received(:last).with(limit: 1, offset: 89)
      end

      it "returns the last item" do
        expect(described_class.last).to eq("id" => 90)
      end
    end
  end

  describe ".where" do
    it "forwards the message to find" do
      allow(described_class).to receive(:find)
      described_class.where(argument1: "A", argument2: "B")
      expect(described_class).to have_received(:find).with(
        :all, argument1: "A", argument2: "B"
      )
    end

    it "delegates parameter preparation to find" do
      allow(ActiveResource::Base).to receive(:find)
      described_class.where(argument1: "A", argument2: "B")
      expect(ActiveResource::Base).to have_received(:find).with(
        :all, params: { argument1: "A", argument2: "B", expand: "items" }
      )
    end

    context "when no arguments are supplied" do
      before { allow(described_class).to receive(:find) }

      it "passes on an empty hash" do
        described_class.where
        expect(described_class).to have_received(:find).with(:all, {})
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
      described_class.new.__send__(:load_attributes_from_response, response)
      expect(response).to have_received(:dup)
    end

    context "when the request can have a body" do
      let(:http_status) { 200 }

      it "underscores the keys of the response body" do
        described_class.new.__send__(:load_attributes_from_response, response)
        expect(duplicate_response.body).to eq(
          { "first_name" => "Jill", "last_name" => "Wunsch" }.to_json
        )
      end
    end

    context "when the request can not have a body" do
      let(:http_status) { 204 }

      it "does not modify the response body" do
        described_class.new.__send__(:load_attributes_from_response, response)
        expect(duplicate_response.body).to eq(
          { "firstName" => "Jill", "lastName" => "Wunsch" }.to_json
        )
      end
    end

    it "sets the values from the response to the instance" do
      instance = described_class.new
      expect(instance).not_to respond_to(:first_name)
      instance.__send__(:load_attributes_from_response, response)
      expect(instance.first_name).to eq("Jill")
    end
  end
end
