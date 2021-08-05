# frozen_string_literal: true

RSpec.describe Fixably::Finders do
  let(:described_class) { Class.new(Fixably::ApplicationResource) }

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

    context "when an argument has an array value" do
      before { allow(described_class).to receive(:find) }

      context "when the array has two values" do
        it "converts the two values to a string value" do
          described_class.where(created_at: %w[2000-01-01 2000-02-01])
          expect(described_class).to have_received(:find).
            with(:all, { created_at: "[2000-01-01,2000-02-01]" })
        end

        it "converts time values into strings" do
          from = Time.parse("2000-01-01 10:00:00")
          to = Time.parse("2000-02-01 13:00:00")
          described_class.where(created_at: [from, to])
          expect(described_class).to have_received(:find).
            with(:all, { created_at: "[2000-01-01,2000-02-01]" })
        end
      end

      context "when the array has two values and the first is nil" do
        before { allow(described_class).to receive(:find) }

        it "converts nil into an empty space" do
          described_class.where(created_at: [nil, "2000-02-01"])
          expect(described_class).to have_received(:find).
            with(:all, { created_at: "[,2000-02-01]" })
        end
      end

      context "when the array has two values and the second is nil" do
        before { allow(described_class).to receive(:find) }

        it "converts nil into an empty space" do
          described_class.where(created_at: ["2000-01-01", nil])
          expect(described_class).to have_received(:find).
            with(:all, { created_at: "[2000-01-01,]" })
        end
      end

      context "when the array is empty" do
        before { allow(described_class).to receive(:find) }

        it "raises and ArgumentError" do
          expect { described_class.where(created_at: []) }.to raise_error(
            ArgumentError,
            "Ranged searches should have either 1 or 2 values but " \
            "created_at has 0"
          )
        end
      end

      context "when the array has one value" do
        before { allow(described_class).to receive(:find) }

        it "acts as if a nil second value was supplied" do
          described_class.where(created_at: ["2000-01-01"])
          expect(described_class).to have_received(:find).
            with(:all, { created_at: "[2000-01-01,]" })
        end
      end

      context "when the array has more than two values" do
        before { allow(described_class).to receive(:find) }

        it "raises and ArgumentError" do
          values = %w[2000-01-01 2000-02-01 2000-03-01]
          expect { described_class.where(created_at: values) }.to raise_error(
            ArgumentError,
            "Ranged searches should have either 1 or 2 values but " \
            "created_at has 3"
          )
        end
      end
    end
  end
end
