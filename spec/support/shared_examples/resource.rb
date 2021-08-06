# frozen_string_literal: true

RSpec.shared_examples "a resource" do |name, uri, actions|
  let(:connection) { instance_double(ActiveResource::Connection) }
  let(:has_one_associations) do
    described_class.reflections.select { _2.macro.equal?(:has_one) }.keys
  end
  let(:has_many_associations) do
    described_class.reflections.select { _2.macro.equal?(:has_many) }.keys
  end
  let(:response) { Net::HTTPOK.new(1, 200, "") }

  before do
    allow(described_class).to receive(:connection).and_return(connection)
    allow(connection).to receive(:get).and_return(response)
    allow(connection).to receive(:post).and_return(response)
    allow(connection).to receive(:put).and_return(response)
    response.instance_variable_set(:@read, true)
  end

  includes_has_one =
    described_class.reflections.values.any? { _1.macro.equal?(:has_one) }
  includes_has_many =
    described_class.reflections.values.any? { _1.macro.equal?(:has_many) }

  if actions.include?(:create)
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
          "/api/v3/#{uri}",
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

    describe ".create!" do
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
          create!(first_name: "Emilee", last_name: "Jerde", phone: "1")

        expect(connection).to have_received(:post).with(
          "/api/v3/#{uri}",
          { firstName: "Emilee", lastName: "Jerde", phone: "1" }.to_json,
          anything
        )
      end

      it "updates the attributes based on the response" do
        result = described_class.
          create!(first_name: "Emilee", last_name: "Jerde", phone: "1")

        expect(result.attributes).to eq(
          {
            "id" => 1, "first_name" => "Jill", "last_name" => "Wunsch",
            "phone" => "1",
          }
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
        described_class.all
        expect(connection).to have_received(:get).with(
          "/api/v3/#{uri}?expand=items", anything
        )
      end

      if includes_has_one
        describe "has_one link expansion" do
          it "nests the associations under items" do
            expansion = { expand: "items(#{has_one_associations.join(",")})" }.
              to_query
            chain = described_class
            has_one_associations.each { chain = chain.includes(_1) }
            chain.all

            expect(connection).to have_received(:get).with(
              "/api/v3/#{uri}?#{expansion}", anything
            )
          end
        end
      end

      if includes_has_many
        describe "has_many link expansion" do
          it "nests the associations under items including netsed items" do
            associations = has_many_associations.map { "#{_1}(items)" }.
              join(",")
            expansion = { expand: "items(#{associations})" }.to_query
            chain = described_class
            has_many_associations.each { chain = chain.includes(_1) }
            chain.all

            expect(connection).to have_received(:get).with(
              "/api/v3/#{uri}?#{expansion}", anything
            )
          end
        end
      end

      if includes_has_one && includes_has_many
        describe "both has_one and has_many link expansion" do
          it "nests the both has_one and has_many associations" do
            has_one = has_one_associations.join(",")
            has_many = has_many_associations.map { "#{_1}(items)" }.join(",")
            expansion = { expand: "items(#{has_one},#{has_many})" }.to_query
            chain = described_class
            has_one_associations.each { chain = chain.includes(_1) }
            has_many_associations.each { chain = chain.includes(_1) }
            chain.all

            expect(connection).to have_received(:get).with(
              "/api/v3/#{uri}?#{expansion}", anything
            )
          end
        end
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
          "/api/v3/#{uri}?expand=items&limit=1", anything
        )
      end

      if includes_has_one
        describe "has_one link expansion" do
          it "nests the associations under items" do
            expansion = { expand: "items(#{has_one_associations.join(",")})" }.
              to_query
            chain = described_class
            has_one_associations.each { chain = chain.includes(_1) }
            chain.first

            expect(connection).to have_received(:get).with(
              "/api/v3/#{uri}?#{expansion}&limit=1", anything
            )
          end
        end
      end

      if includes_has_many
        describe "has_many link expansion" do
          it "nests the associations under items including netsed items" do
            associations = has_many_associations.map { "#{_1}(items)" }.
              join(",")
            expansion = { expand: "items(#{associations})" }.to_query
            chain = described_class
            has_many_associations.each { chain = chain.includes(_1) }
            chain.first

            expect(connection).to have_received(:get).with(
              "/api/v3/#{uri}?#{expansion}&limit=1", anything
            )
          end
        end
      end

      if includes_has_one && includes_has_many
        describe "both has_one and has_many link expansion" do
          it "nests the both has_one and has_many associations" do
            has_one = has_one_associations.join(",")
            has_many = has_many_associations.map { "#{_1}(items)" }.join(",")
            expansion = { expand: "items(#{has_one},#{has_many})" }.to_query
            chain = described_class
            has_one_associations.each { chain = chain.includes(_1) }
            has_many_associations.each { chain = chain.includes(_1) }
            chain.first

            expect(connection).to have_received(:get).with(
              "/api/v3/#{uri}?#{expansion}&limit=1", anything
            )
          end
        end
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
          "/api/v3/#{uri}?expand=items", anything
        )
      end

      context "when there are more items than fit in a page" do
        let(:total_items) { 91 }

        it "makes a second request to get the last item" do
          described_class.last
          expect(connection).to have_received(:get).with(
            "/api/v3/#{uri}?expand=items", anything
          ).with(
            "/api/v3/#{uri}?expand=items&limit=1&offset=90", anything
          )
        end
      end

      if includes_has_one
        describe "has_one link expansion" do
          it "nests the associations under items" do
            expansion = { expand: "items(#{has_one_associations.join(",")})" }.
              to_query
            chain = described_class
            has_one_associations.each { chain = chain.includes(_1) }
            chain.last

            expect(connection).to have_received(:get).with(
              "/api/v3/#{uri}?#{expansion}", anything
            )
          end
        end
      end

      if includes_has_many
        describe "has_many link expansion" do
          it "nests the associations under items including netsed items" do
            associations = has_many_associations.map { "#{_1}(items)" }.
              join(",")
            expansion = { expand: "items(#{associations})" }.to_query
            chain = described_class
            has_many_associations.each { chain = chain.includes(_1) }
            chain.last

            expect(connection).to have_received(:get).with(
              "/api/v3/#{uri}?#{expansion}", anything
            )
          end
        end
      end

      if includes_has_one && includes_has_many
        describe "both has_one and has_many link expansion" do
          it "nests the both has_one and has_many associations" do
            has_one = has_one_associations.join(",")
            has_many = has_many_associations.map { "#{_1}(items)" }.join(",")
            expansion = { expand: "items(#{has_one},#{has_many})" }.to_query
            chain = described_class
            has_one_associations.each { chain = chain.includes(_1) }
            has_many_associations.each { chain = chain.includes(_1) }
            chain.last

            expect(connection).to have_received(:get).with(
              "/api/v3/#{uri}?#{expansion}", anything
            )
          end
        end
      end
    end

    describe ".where" do
      let(:query) do
        { q: "firstName:Jill" }.to_query
      end

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
        expect(connection).to have_received(:get).with(
          "/api/v3/#{uri}?expand=items&#{query}", anything
        )
      end

      if includes_has_one
        describe "has_one link expansion" do
          it "nests the associations under items" do
            expansion = { expand: "items(#{has_one_associations.join(",")})" }.
              to_query
            chain = described_class
            has_one_associations.each { chain = chain.includes(_1) }
            chain.where(first_name: "Jill")

            expect(connection).to have_received(:get).with(
              "/api/v3/#{uri}?#{expansion}&#{query}", anything
            )
          end
        end
      end

      if includes_has_many
        describe "has_many link expansion" do
          it "nests the associations under items including netsed items" do
            associations = has_many_associations.map { "#{_1}(items)" }.
              join(",")
            expansion = { expand: "items(#{associations})" }.to_query
            chain = described_class
            has_many_associations.each { chain = chain.includes(_1) }
            chain.where(first_name: "Jill")

            expect(connection).to have_received(:get).with(
              "/api/v3/#{uri}?#{expansion}&#{query}", anything
            )
          end
        end
      end

      if includes_has_one && includes_has_many
        describe "both has_one and has_many link expansion" do
          it "nests the both has_one and has_many associations" do
            has_one = has_one_associations.join(",")
            has_many = has_many_associations.map { "#{_1}(items)" }.join(",")
            expansion = { expand: "items(#{has_one},#{has_many})" }.to_query
            chain = described_class
            has_one_associations.each { chain = chain.includes(_1) }
            has_many_associations.each { chain = chain.includes(_1) }
            chain.where(first_name: "Jill")

            expect(connection).to have_received(:get).with(
              "/api/v3/#{uri}?#{expansion}&#{query}", anything
            )
          end
        end
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
        expect { described_class.all(option1: "A", option2: "B") }.to raise_error(
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
        expect { described_class.first(argument1: "A", argument2: "B") }.
          to raise_error(
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
        expect { described_class.last(argument1: "A", argument2: "B") }.
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
        described_class.exists?(1)
        expect(connection).to have_received(:get).with(
          "/api/v3/#{uri}/1", anything
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
        described_class.find(1)
        expect(connection).to have_received(:get).with(
          "/api/v3/#{uri}/1", anything
        )
      end

      if includes_has_one
        describe "has_one link expansion" do
          it "nests the associations under items" do
            expansion = { expand: has_one_associations.join(",") }.
              to_query
            chain = described_class
            has_one_associations.each { chain = chain.includes(_1) }
            chain.find(1)

            expect(connection).to have_received(:get).with(
              "/api/v3/#{uri}/1?#{expansion}", anything
            )
          end
        end
      end

      if includes_has_many
        describe "has_many link expansion" do
          it "nests the associations under items including netsed items" do
            associations = has_many_associations.map { "#{_1}(items)" }.
              join(",")
            expansion = { expand: associations }.to_query
            chain = described_class
            has_many_associations.each { chain = chain.includes(_1) }
            chain.find(1)

            expect(connection).to have_received(:get).with(
              "/api/v3/#{uri}/1?#{expansion}", anything
            )
          end
        end
      end

      if includes_has_one && includes_has_many
        describe "both has_one and has_many link expansion" do
          it "nests the both has_one and has_many associations" do
            has_one = has_one_associations.join(",")
            has_many = has_many_associations.map { "#{_1}(items)" }.join(",")
            expansion = { expand: "#{has_one},#{has_many}" }.to_query
            chain = described_class
            has_one_associations.each { chain = chain.includes(_1) }
            has_many_associations.each { chain = chain.includes(_1) }
            chain.find(1)

            expect(connection).to have_received(:get).with(
              "/api/v3/#{uri}/1?#{expansion}", anything
            )
          end
        end
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
        expect { described_class.exists?(1, option1: "A", option2: "B") }.
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
        expect { described_class.find(1, option1: "A", option2: "B") }.
          to raise_error(
            Fixably::UnsupportedError,
            "Fixably does not support retrieving #{name.pluralize}"
          )
      end
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

    if actions.include?(:create)
      context "when the record is new" do
        it "makes a POST request" do
          instance = described_class.
            new(first_name: "Emilee", last_name: "Jerde", phone: "1")
          instance.save

          expect(connection).to have_received(:post).with(
            "/api/v3/#{uri}",
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
    else
      context "when the record is new" do
        it "raises an error" do
          instance = described_class.
            new(first_name: "Emilee", last_name: "Jerde", phone: "1")
          expect { instance.save }.to raise_error(
            Fixably::UnsupportedError,
            "Fixably does not support creating #{name.pluralize}"
          )
        end
      end
    end

    if actions.include?(:update)
      context "when the record is being updated" do
        it "makes a PUT request" do
          instance = described_class.
            new(first_name: "Emilee", last_name: "Jerde", phone: "1")
          instance.instance_variable_set(:@persisted, true)
          instance.save(validate: false)

          expect(connection).to have_received(:put).with(
            "/api/v3/#{uri}/",
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
    else
      context "when the record is being updated" do
        it "raises an error" do
          instance = described_class.
            new(first_name: "Emilee", last_name: "Jerde", phone: "1")
          expect { instance.save! }.to raise_error(
            Fixably::UnsupportedError,
            "Fixably does not support creating #{name.pluralize}"
          )
        end
      end
    end
  end
end
