# frozen_string_literal: true

RSpec.shared_examples "a resource" do |name, uri, actions|
  let(:connection) { instance_double(ActiveResource::Connection) }
  let(:has_one_associations) do
    reflections = described_class.reflections.select do |_name, reflection|
      reflection.macro.equal?(:has_one)
    end
    reflections.keys
  end
  let(:has_many_associations) do
    reflections = described_class.reflections.select do |_name, reflection|
      reflection.macro.equal?(:has_many)
    end
    reflections.keys
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
          "name" => "Fatima Kunze",
          "phone" => "1",
          "serial_number" => "2",
        }.to_json
      end

      it "makes a POST request" do
        described_class.
          create(name: "Latashia Bergnaum", phone: "1", serial_number: "2")

        expect(connection).to have_received(:post).with(
          "/api/v3/#{uri}",
          { name: "Latashia Bergnaum", phone: "1", serialNumber: "2" }.to_json,
          anything
        )
      end

      it "updates the attributes based on the response" do
        result = described_class.
          create(name: "Latashia Bergnaum", phone: "1", serial_number: "2")

        expect(result.attributes).to eq(
          "id" => 1, "name" => "Fatima Kunze", "phone" => "1",
          "serial_number" => "2"
        )
      end
    end

    describe ".create!" do
      before do
        response.body = {
          "id" => 1,
          "name" => "Fatima Kunze",
          "phone" => "1",
          "serial_number" => "2",
        }.to_json
      end

      it "makes a POST request" do
        described_class.
          create!(name: "Latashia Bergnaum", phone: "1", serial_number: "2")

        expect(connection).to have_received(:post).with(
          "/api/v3/#{uri}",
          { name: "Latashia Bergnaum", phone: "1", serialNumber: "2" }.to_json,
          anything
        )
      end

      it "updates the attributes based on the response" do
        result = described_class.
          create!(name: "Latashia Bergnaum", phone: "1", serial_number: "2")

        expect(result.attributes).to eq(
          "id" => 1, "name" => "Fatima Kunze", "phone" => "1",
          "serial_number" => "2"
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
          let(:expansion) do
            { expand: "items(#{associations})" }.to_query
          end
          let(:associations) do
            has_one_associations.map { _1.to_s.camelize(:lower) }.join(",")
          end

          it "nests the associations under items" do
            chain = described_class
            has_one_associations.each { chain = chain.includes(_1) }
            chain.all

            expect(connection).to have_received(:get).with(
              "/api/v3/#{uri}?#{expansion}", anything
            )
          end

          context "when the same association is included multiple times" do
            it "only includes the association once" do
              chain = described_class
              has_one_associations.each do |association|
                2.times { chain = chain.includes(association) }
              end
              chain.all

              expect(connection).to have_received(:get).with(
                "/api/v3/#{uri}?#{expansion}", anything
              )
            end
          end
        end
      end

      if includes_has_many
        describe "has_many link expansion" do
          let(:expansion) do
            associations = has_many_associations.map { "#{_1}(items)" }.
              join(",")
            { expand: "items(#{associations})" }.to_query
          end

          it "nests the associations under items including nested items" do
            chain = described_class
            has_many_associations.each { chain = chain.includes(_1) }
            chain.all

            expect(connection).to have_received(:get).with(
              "/api/v3/#{uri}?#{expansion}", anything
            )
          end

          context "when the same association is included multiple times" do
            it "only includes the association once" do
              chain = described_class
              has_many_associations.each do |association|
                2.times { chain = chain.includes(association) }
              end
              chain.all

              expect(connection).to have_received(:get).with(
                "/api/v3/#{uri}?#{expansion}", anything
              )
            end
          end
        end
      end

      if includes_has_one && includes_has_many
        describe "both has_one and has_many link expansion" do
          let(:expansion) do
            { expand: "items(#{associations})" }.to_query
          end
          let(:associations) do
            has_one = has_one_associations.join(",")
            has_many = has_many_associations.map { "#{_1}(items)" }.join(",")
            "#{has_one},#{has_many}".camelize(:lower)
          end

          it "nests the both has_one and has_many associations" do
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

      context "when an expansion string is supplied" do
        it "uses the string rather than includes" do
          described_class.all(expand: "custom expansion string")

          expect(connection).to have_received(:get).with(
            "/api/v3/#{uri}?expand=custom+expansion+string", anything
          )
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
          let(:expansion) do
            { expand: "items(#{associations})" }.to_query
          end
          let(:associations) do
            has_one_associations.map { _1.to_s.camelize(:lower) }.join(",")
          end

          it "nests the associations under items" do
            chain = described_class
            has_one_associations.each { chain = chain.includes(_1) }
            chain.first

            expect(connection).to have_received(:get).with(
              "/api/v3/#{uri}?#{expansion}&limit=1", anything
            )
          end

          context "when the same association is included multiple times" do
            it "only includes the association once" do
              chain = described_class
              has_one_associations.each do |association|
                2.times { chain = chain.includes(association) }
              end
              chain.first

              expect(connection).to have_received(:get).with(
                "/api/v3/#{uri}?#{expansion}&limit=1", anything
              )
            end
          end
        end
      end

      if includes_has_many
        describe "has_many link expansion" do
          let(:expansion) do
            associations = has_many_associations.map { "#{_1}(items)" }.
              join(",")
            { expand: "items(#{associations})" }.to_query
          end

          it "nests the associations under items including nested items" do
            chain = described_class
            has_many_associations.each { chain = chain.includes(_1) }
            chain.first

            expect(connection).to have_received(:get).with(
              "/api/v3/#{uri}?#{expansion}&limit=1", anything
            )
          end

          context "when the same association is included multiple times" do
            it "only includes the association once" do
              chain = described_class
              has_many_associations.each do |association|
                2.times { chain = chain.includes(association) }
              end
              chain.first

              expect(connection).to have_received(:get).with(
                "/api/v3/#{uri}?#{expansion}&limit=1", anything
              )
            end
          end
        end
      end

      if includes_has_one && includes_has_many
        describe "both has_one and has_many link expansion" do
          let(:expansion) do
            { expand: "items(#{associations})" }.to_query
          end
          let(:associations) do
            has_one = has_one_associations.join(",")
            has_many = has_many_associations.map { "#{_1}(items)" }.join(",")
            "#{has_one},#{has_many}".camelize(:lower)
          end

          it "nests the both has_one and has_many associations" do
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

      context "when an expansion string is supplied" do
        it "uses the string rather than includes" do
          described_class.first(expand: "custom expansion string")

          expect(connection).to have_received(:get).with(
            "/api/v3/#{uri}?expand=custom+expansion+string&limit=1", anything
          )
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
          let(:expansion) do
            { expand: "items(#{associations})" }.to_query
          end
          let(:associations) do
            has_one_associations.map { _1.to_s.camelize(:lower) }.join(",")
          end

          it "nests the associations under items" do
            chain = described_class
            has_one_associations.each { chain = chain.includes(_1) }
            chain.last

            expect(connection).to have_received(:get).with(
              "/api/v3/#{uri}?#{expansion}", anything
            )
          end

          context "when the same association is included multiple times" do
            it "only includes the association once" do
              chain = described_class
              has_one_associations.each do |association|
                2.times { chain = chain.includes(association) }
              end
              chain.last

              expect(connection).to have_received(:get).with(
                "/api/v3/#{uri}?#{expansion}", anything
              )
            end
          end
        end
      end

      if includes_has_many
        describe "has_many link expansion" do
          let(:expansion) do
            associations = has_many_associations.map { "#{_1}(items)" }.
              join(",")
            { expand: "items(#{associations})" }.to_query
          end

          it "nests the associations under items including nested items" do
            chain = described_class
            has_many_associations.each { chain = chain.includes(_1) }
            chain.last

            expect(connection).to have_received(:get).with(
              "/api/v3/#{uri}?#{expansion}", anything
            )
          end

          context "when the same association is included multiple times" do
            it "only includes the association once" do
              chain = described_class
              has_many_associations.each do |association|
                2.times { chain = chain.includes(association) }
              end
              chain.last

              expect(connection).to have_received(:get).with(
                "/api/v3/#{uri}?#{expansion}", anything
              )
            end
          end
        end
      end

      if includes_has_one && includes_has_many
        describe "both has_one and has_many link expansion" do
          let(:expansion) do
            { expand: "items(#{associations})" }.to_query
          end
          let(:associations) do
            has_one = has_one_associations.join(",")
            has_many = has_many_associations.map { "#{_1}(items)" }.join(",")
            "#{has_one},#{has_many}".camelize(:lower)
          end

          it "nests the both has_one and has_many associations" do
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

      context "when an expansion string is supplied" do
        it "uses the string rather than includes" do
          described_class.last(expand: "custom expansion string")

          expect(connection).to have_received(:get).with(
            "/api/v3/#{uri}?expand=custom+expansion+string", anything
          )
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
          let(:expansion) do
            { expand: "items(#{associations})" }.to_query
          end
          let(:associations) do
            has_one_associations.map { _1.to_s.camelize(:lower) }.join(",")
          end

          it "nests the associations under items" do
            chain = described_class
            has_one_associations.each { chain = chain.includes(_1) }
            chain.where(first_name: "Jill")

            expect(connection).to have_received(:get).with(
              "/api/v3/#{uri}?#{expansion}&#{query}", anything
            )
          end

          context "when the same association is included multiple times" do
            it "only includes the association once" do
              chain = described_class
              has_one_associations.each do |association|
                2.times { chain = chain.includes(association) }
              end
              chain.where(first_name: "Jill")

              expect(connection).to have_received(:get).with(
                "/api/v3/#{uri}?#{expansion}&#{query}", anything
              )
            end
          end
        end
      end

      if includes_has_many
        describe "has_many link expansion" do
          let(:expansion) do
            associations = has_many_associations.map { "#{_1}(items)" }.
              join(",")
            { expand: "items(#{associations})" }.to_query
          end

          it "nests the associations under items including nested items" do
            chain = described_class
            has_many_associations.each { chain = chain.includes(_1) }
            chain.where(first_name: "Jill")

            expect(connection).to have_received(:get).with(
              "/api/v3/#{uri}?#{expansion}&#{query}", anything
            )
          end

          context "when the same association is included multiple times" do
            it "only includes the association once" do
              chain = described_class
              has_many_associations.each do |association|
                2.times { chain = chain.includes(association) }
              end
              chain.where(first_name: "Jill")

              expect(connection).to have_received(:get).with(
                "/api/v3/#{uri}?#{expansion}&#{query}", anything
              )
            end
          end
        end
      end

      if includes_has_one && includes_has_many
        describe "both has_one and has_many link expansion" do
          let(:expansion) do
            { expand: "items(#{associations})" }.to_query
          end
          let(:associations) do
            has_one = has_one_associations.join(",")
            has_many = has_many_associations.map { "#{_1}(items)" }.join(",")
            "#{has_one},#{has_many}".camelize(:lower)
          end

          it "nests the both has_one and has_many associations" do
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

      context "when an expansion string is supplied" do
        it "uses the string rather than includes" do
          described_class.
            where(first_name: "Jill", expand: "custom expansion string")

          expect(connection).to have_received(:get).with(
            "/api/v3/#{uri}?expand=custom+expansion+string&#{query}", anything
          )
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
          let(:expansion) do
            { expand: associations }.to_query
          end
          let(:associations) do
            has_one_associations.map { _1.to_s.camelize(:lower) }.join(",")
          end

          it "nests the associations under items" do
            chain = described_class
            has_one_associations.each { chain = chain.includes(_1) }
            chain.find(1)

            expect(connection).to have_received(:get).with(
              "/api/v3/#{uri}/1?#{expansion}", anything
            )
          end

          context "when the same association is included multiple times" do
            it "only includes the association once" do
              chain = described_class
              has_one_associations.each do |association|
                2.times { chain = chain.includes(association) }
              end
              chain.find(1)

              expect(connection).to have_received(:get).with(
                "/api/v3/#{uri}/1?#{expansion}", anything
              )
            end
          end
        end
      end

      if includes_has_many
        describe "has_many link expansion" do
          let(:expansion) do
            associations = has_many_associations.map { "#{_1}(items)" }.
              join(",")
            { expand: associations }.to_query
          end

          it "nests the associations under items including nested items" do
            chain = described_class
            has_many_associations.each { chain = chain.includes(_1) }
            chain.find(1)

            expect(connection).to have_received(:get).with(
              "/api/v3/#{uri}/1?#{expansion}", anything
            )
          end

          context "when the same association is included multiple times" do
            it "only includes the association once" do
              chain = described_class
              has_many_associations.each do |association|
                2.times { chain = chain.includes(association) }
              end
              chain.find(1)

              expect(connection).to have_received(:get).with(
                "/api/v3/#{uri}/1?#{expansion}", anything
              )
            end
          end
        end
      end

      if includes_has_one && includes_has_many
        describe "both has_one and has_many link expansion" do
          let(:expansion) do
            { expand: associations }.to_query
          end
          let(:associations) do
            has_one = has_one_associations.join(",")
            has_many = has_many_associations.map { "#{_1}(items)" }.join(",")
            "#{has_one},#{has_many}".camelize(:lower)
          end

          it "nests the both has_one and has_many associations" do
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

      context "when an expansion string is supplied" do
        it "uses the string rather than includes" do
          described_class.find(1, expand: "custom expansion string")

          expect(connection).to have_received(:get).with(
            "/api/v3/#{uri}/1?expand=custom+expansion+string", anything
          )
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
        "name" => "Fatima Kunze",
        "phone" => "2",
        "serial_number" => "3",
      }.to_json
    end

    if actions.include?(:create)
      context "when the record is new" do
        it "makes a POST request" do
          instance = described_class.
            new(name: "Latashia Bergnaum", phone: "1", serial_number: "2")
          instance.save

          expect(connection).to have_received(:post).with(
            "/api/v3/#{uri}",
            {
              name: "Latashia Bergnaum", phone: "1", serialNumber: "2",
            }.to_json,
            anything
          )
        end

        it "updates the attributes based on the response" do
          instance = described_class.
            new(name: "Latashia Bergnaum", phone: "1", serial_number: "2")
          instance.save

          expect(instance.attributes).to eq(
            "id" => 1, "name" => "Fatima Kunze", "phone" => "2",
            "serial_number" => "3"
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
          instance = described_class.new(phone: "1", serial_number: "2")
          instance.instance_variable_set(:@persisted, true)
          instance.save(validate: false)

          expect(connection).to have_received(:put).with(
            "/api/v3/#{uri}/",
            { phone: "1", serialNumber: "2" }.to_json,
            anything
          )
        end

        it "updates the attributes based on the response" do
          instance = described_class.new(phone: "1", serial_number: "2")
          instance.instance_variable_set(:@persisted, true)
          instance.save

          expect(instance.attributes).to eq(
            "id" => 1, "name" => "Fatima Kunze", "phone" => "2",
            "serial_number" => "3"
          )
        end
      end
    else
      context "when the record is being updated" do
        it "raises an error" do
          instance = described_class.
            new(first_name: "Emilee", last_name: "Jerde", phone: "1")
          instance.instance_variable_set(:@persisted, true)
          expect { instance.save! }.to raise_error(
            Fixably::UnsupportedError,
            "Fixably does not support updating #{name.pluralize}"
          )
        end
      end
    end
  end
end
