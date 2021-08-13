# frozen_string_literal: true

RSpec.shared_examples(
  "a nested resource"
) do |name, uri, actions, extra_attrs = {}|
  let(:connection) { instance_double(ActiveResource::Connection) }
  let(:response) { Net::HTTPOK.new(1, 200, "") }
  let(:parent_id) { uri.split("/").fetch(1)[1..].to_sym }
  let(:formatted_uri) { "/api/v3/#{uri}".sub(":#{parent_id}", "1") }

  before do
    allow(described_class).to receive(:connection).and_return(connection)
    allow(connection).to receive(:get).and_return(response)
    allow(connection).to receive(:post).and_return(response)
    allow(connection).to receive(:put).and_return(response)
    response.instance_variable_set(:@read, true)
  end

  if actions.include?(:create)
    describe ".create" do
      let(:options) do
        options = { first_name: "Emilee", last_name: "Jerde", phone: "1" }
        options[parent_id] = 1
        options.merge(extra_attrs)
      end

      before do
        response.body = {
          "id" => 1,
          "firstName" => "Jill",
          "lastName" => "Wunsch",
          "phone" => "1",
        }.merge(extra_attrs).to_json
      end

      it "makes a POST request" do
        instance = described_class.create(options)
        expectation = { firstName: "Emilee", lastName: "Jerde", phone: "1" }.
          merge(extra_attrs).
          to_json

        expect(instance).to be_valid
        expect(connection).to have_received(:post).
          with(formatted_uri, expectation, anything)
      end

      it "updates the attributes based on the response" do
        instance = described_class.create(options)

        expect(instance.attributes).to eq(
          {
            "id" => 1, "first_name" => "Jill", "last_name" => "Wunsch",
            "phone" => "1",
          }.merge(extra_attrs)
        )
      end
    end

    describe ".create!" do
      let(:options) do
        options = { first_name: "Emilee", last_name: "Jerde", phone: "1" }
        options[parent_id] = 1
        options.merge(extra_attrs)
      end

      before do
        response.body = {
          "id" => 1,
          "firstName" => "Jill",
          "lastName" => "Wunsch",
          "phone" => "1",
        }.merge(extra_attrs).to_json
      end

      it "makes a POST request" do
        instance = described_class.create!(options)
        expectation = { firstName: "Emilee", lastName: "Jerde", phone: "1" }.
          merge(extra_attrs).
          to_json

        expect(instance).to be_valid
        expect(connection).to have_received(:post).
          with(formatted_uri, expectation, anything)
      end

      it "updates the attributes based on the response" do
        instance = described_class.create!(options)

        expect(instance.attributes).to eq(
          {
            "id" => 1, "first_name" => "Jill", "last_name" => "Wunsch",
            "phone" => "1",
          }.merge(extra_attrs)
        )
      end
    end
  else
    describe ".create" do
      it "raises an error" do
        expect { described_class.create }.to raise_error(
          Fixably::UnsupportedError,
          "Fixably does not support creating #{name.pluralize}"
        )
      end

      it "accepts arguments for interface compatibility" do
        expect do
          described_class.create(argument1: "A", argument2: "B")
        end.to raise_error(
          Fixably::UnsupportedError,
          "Fixably does not support creating #{name.pluralize}"
        )
      end
    end

    describe ".create!" do
      it "raises an error" do
        expect { described_class.create! }.to raise_error(
          Fixably::UnsupportedError,
          "Fixably does not support creating #{name.pluralize}"
        )
      end

      it "accepts arguments for interface compatibility" do
        expect do
          described_class.create!(argument1: "A", argument2: "B")
        end.to raise_error(
          Fixably::UnsupportedError,
          "Fixably does not support creating #{name.pluralize}"
        )
      end
    end
  end

  if actions.include?(:delete)
    describe ".delete" do
      it "requires a test"
    end
  else
    describe ".delete" do
      it "raises an error" do
        expect { described_class.delete(1) }.to raise_error(
          Fixably::UnsupportedError,
          "Fixably does not support deleting #{name.pluralize}"
        )
      end

      it "accepts an id and options for interface compatibility" do
        expect { described_class.delete(1, argument: "A") }.to raise_error(
          Fixably::UnsupportedError,
          "Fixably does not support deleting #{name.pluralize}"
        )
      end
    end

    describe "#destroy" do
      it "raises an error" do
        expect { described_class.new.destroy }.to raise_error(
          Fixably::UnsupportedError,
          "Fixably does not support deleting #{name.pluralize}"
        )
      end
    end
  end

  if actions.include?(:list)
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
        described_class.all("#{parent_id}": 1)
        expect(connection).to have_received(:get).with(
          "#{formatted_uri}?expand=items", anything
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
        described_class.first("#{parent_id}": 1)
        expect(connection).to have_received(:get).with(
          "#{formatted_uri}?expand=items&limit=1", anything
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
        described_class.last("#{parent_id}": 1)
        expect(connection).to have_received(:get).with(
          "#{formatted_uri}?expand=items", anything
        )
      end

      context "when there are more items than fit in a page" do
        let(:total_items) { 91 }

        it "makes a second request to get the last item" do
          described_class.last("#{parent_id}": 1)
          expect(connection).to have_received(:get).with(
            "#{formatted_uri}?expand=items", anything
          ).with(
            "#{formatted_uri}?expand=items&limit=1&offset=90", anything
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
        described_class.where(first_name: "Jill", "#{parent_id}": 1)

        query = { q: "firstName:Jill" }.to_query
        expect(connection).to have_received(:get).with(
          "#{formatted_uri}?expand=items&#{query}", anything
        )
      end
    end
  else
    describe ".all" do
      it "raises an error" do
        expect { described_class.all }.to raise_error(
          Fixably::UnsupportedError,
          "Fixably does not support listing #{name.pluralize}"
        )
      end

      it "accepts options for interface compatibility" do
        expect { described_class.all("#{parent_id}": 1) }.to raise_error(
          Fixably::UnsupportedError,
          "Fixably does not support listing #{name.pluralize}"
        )
      end
    end

    describe ".first" do
      it "raises an error" do
        expect { described_class.first }.to raise_error(
          Fixably::UnsupportedError,
          "Fixably does not support listing #{name.pluralize}"
        )
      end

      it "accepts an id and options for interface compatibility" do
        expect { described_class.first("#{parent_id}": 1) }.to raise_error(
          Fixably::UnsupportedError,
          "Fixably does not support listing #{name.pluralize}"
        )
      end
    end

    describe ".last" do
      it "raises an error" do
        expect { described_class.last }.to raise_error(
          Fixably::UnsupportedError,
          "Fixably does not support listing #{name.pluralize}"
        )
      end

      it "accepts an id and options for interface compatibility" do
        expect { described_class.last("#{parent_id}": 1) }.
          to raise_error(
            Fixably::UnsupportedError,
            "Fixably does not support listing #{name.pluralize}"
          )
      end
    end

    describe ".where" do
      it "raises an error" do
        expect { described_class.where(first_name: "Jill") }.to raise_error(
          Fixably::UnsupportedError,
          "Fixably does not support listing #{name.pluralize}"
        )
      end
    end
  end

  if actions.include?(:show)
    describe ".exists?" do
      before do
        response.body = {
          "firstName" => "Jill",
          "lastName" => "Wunsch",
        }.to_json
      end

      it "makes a GET request" do
        described_class.exists?(1, "#{parent_id}": 1)
        expect(connection).to have_received(:get).with(
          "#{formatted_uri}/1", anything
        )
      end
    end

    describe ".find" do
      before do
        response.body = {
          "firstName" => "Jill",
          "lastName" => "Wunsch",
        }.to_json
      end

      it "makes a GET request" do
        described_class.find(1, "#{parent_id}": 1)
        expect(connection).to have_received(:get).with(
          "#{formatted_uri}/1", anything
        )
      end
    end
  else
    describe ".exists?" do
      it "raises an error" do
        expect { described_class.exists?(1) }.to raise_error(
          Fixably::UnsupportedError,
          "Fixably does not support retrieving #{name.pluralize}"
        )
      end

      it "accepts options for interface compatibility" do
        expect { described_class.exists?(1, "#{parent_id}": 1) }.
          to raise_error(
            Fixably::UnsupportedError,
            "Fixably does not support retrieving #{name.pluralize}"
          )
      end
    end

    describe ".find" do
      it "raises an error" do
        expect { described_class.find(1) }.to raise_error(
          Fixably::UnsupportedError,
          "Fixably does not support retrieving #{name.pluralize}"
        )
      end

      it "accepts options for interface compatibility" do
        expect { described_class.find(1, "#{parent_id}": 1) }.
          to raise_error(
            Fixably::UnsupportedError,
            "Fixably does not support retrieving #{name.pluralize}"
          )
      end
    end
  end

  describe "#save" do
    let(:options) do
      options = { first_name: "Emilee", last_name: "Jerde", phone: "1" }
      options[parent_id] = 1
      options.merge(extra_attrs)
    end

    before do
      response.body = {
        "id" => 1,
        "firstName" => "Jill",
        "lastName" => "Wunsch",
        "phone" => "2",
      }.merge(extra_attrs).to_json
    end

    if actions.include?(:create)
      context "when the record is new" do
        it "makes a POST request" do
          instance = described_class.new(options)
          instance.save
          expectation = { firstName: "Emilee", lastName: "Jerde", phone: "1" }.
            merge(extra_attrs).
            to_json

          expect(connection).to have_received(:post).
            with(formatted_uri, expectation, anything)
        end

        it "updates the attributes based on the response" do
          instance = described_class.new(options)
          instance.save

          expect(instance.attributes).to eq(
            {
              "id" => 1, "first_name" => "Jill", "last_name" => "Wunsch",
              "phone" => "2",
            }.merge(extra_attrs)
          )
        end
      end
    else
      context "when the record is new" do
        it "raises an error" do
          instance = described_class.new(options)
          expect { instance.save }.to raise_error(
            Fixably::UnsupportedError,
            "Fixably does not support creating #{name.pluralize}"
          )
        end
      end
    end

    if actions.include?(:update)
      context "when the record is being updated" do
        let(:instance) do
          instance = described_class.new(options)
          instance.instance_variable_set(:@persisted, true)
          instance
        end

        it "makes a PUT request" do
          instance.save(validate: false)

          expect(connection).to have_received(:put).with(
            "#{formatted_uri}/",
            { firstName: "Emilee", lastName: "Jerde", phone: "1" }.to_json,
            anything
          )
        end

        it "updates the attributes based on the response" do
          instance.save

          expect(instance.attributes).to eq(
            {
              "id" => 1, "first_name" => "Jill", "last_name" => "Wunsch",
              "phone" => "2",
            }
          )
        end
      end
    else
      context "when the record is being updated" do
        let(:instance) do
          instance = described_class.new(options)
          instance.instance_variable_set(:@persisted, true)
          instance
        end

        it "raises an error" do
          expect { instance.save }.to raise_error(
            Fixably::UnsupportedError,
            "Fixably does not support updating #{name.pluralize}"
          )
        end
      end
    end
  end
end
