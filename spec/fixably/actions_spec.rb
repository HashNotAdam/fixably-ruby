# frozen_string_literal: true

RSpec.describe Fixably::Actions do
  let(:action_policy_double) { instance_double(Fixably::ActionPolicy) }
  let(:fake_has_one) do
    Class.new(Fixably::ApplicationResource) do
      def self.name = "FakeHasOne"
    end
  end
  let(:fake_has_many) do
    Class.new(Fixably::ApplicationResource) do
      def self.name = "FakeHasMany"
    end
  end
  let(:described_class) do
    has_one_class_name = fake_has_one.name.underscore
    has_many_class_name = fake_has_one.name.underscore

    Class.new(Fixably::ApplicationResource) do
      def self.name = "FakeCustomer"

      has_one :association, class_name: has_one_class_name
      has_many :relation, class_name: has_many_class_name
    end
  end
  let(:instance) { described_class.new }

  describe ".all" do
    before do
      allow(Fixably::ActionPolicy).
        to receive(:new).and_return(action_policy_double)
      allow(action_policy_double).to receive(:list!).and_return(true)
      allow(ActiveResource::Base).to receive(:all)
    end

    it "validates that the request is supported" do
      described_class.all
      expect(Fixably::ActionPolicy).
        to have_received(:new).with(resource: described_class)
      expect(action_policy_double).to have_received(:list!)
    end

    it "forwards the message to the superclass" do
      described_class.all(argument1: "A", argument2: "B")
      expect(ActiveResource::Base).
        to have_received(:all).with(argument1: "A", argument2: "B")
    end

    context "when no arguments are supplied" do
      it "passes no arguments" do
        described_class.all
        expect(ActiveResource::Base).to have_received(:all).with(no_args)
      end
    end
  end

  describe ".create" do
    before { allow(ActiveResource::Base).to receive(:create) }

    it "validates that the request is supported" do
      allow(Fixably::ActionPolicy).
        to receive(:new).and_return(action_policy_double)
      allow(action_policy_double).to receive(:create!)

      described_class.create

      expect(Fixably::ActionPolicy).
        to have_received(:new).with(resource: described_class)
      expect(action_policy_double).to have_received(:create!)
    end

    context "when the create action is supported" do
      before do
        allow(Fixably::ActionPolicy).
          to receive(:new).and_return(action_policy_double)
        allow(action_policy_double).to receive(:create!).and_return(true)
      end

      it "forwards the message to the superclass" do
        described_class.create
        expect(ActiveResource::Base).to have_received(:create).with({})
      end

      it "forwards on any supplied options" do
        described_class.create(option1: "A", option2: "B")
        expect(ActiveResource::Base).
          to have_received(:create).with(option1: "A", option2: "B")
      end
    end

    context "when the create action is not supported" do
      it "raises an UnsupportedError" do
        expect { described_class.create }.to raise_error(
          Fixably::UnsupportedError,
          "Fixably does not support creating fake customers"
        )
      end
    end
  end

  describe ".create!" do
    before { allow(ActiveResource::Base).to receive(:create!) }

    it "validates that the request is supported" do
      allow(Fixably::ActionPolicy).
        to receive(:new).and_return(action_policy_double)
      allow(action_policy_double).to receive(:create!)

      described_class.create!

      expect(Fixably::ActionPolicy).
        to have_received(:new).with(resource: described_class)
      expect(action_policy_double).to have_received(:create!)
    end

    context "when the create action is supported" do
      before do
        allow(Fixably::ActionPolicy).
          to receive(:new).and_return(action_policy_double)
        allow(action_policy_double).to receive(:create!).and_return(true)
      end

      it "forwards the message to the superclass" do
        described_class.create!
        expect(ActiveResource::Base).to have_received(:create!).with({})
      end

      it "forwards on any supplied options" do
        described_class.create!(option1: "A", option2: "B")
        expect(ActiveResource::Base).
          to have_received(:create!).with(option1: "A", option2: "B")
      end
    end

    context "when the create action is not supported" do
      it "raises an UnsupportedError" do
        expect { described_class.create! }.to raise_error(
          Fixably::UnsupportedError,
          "Fixably does not support creating fake customers"
        )
      end
    end
  end

  describe ".delete" do
    before do
      allow(Fixably::ActionPolicy).
        to receive(:new).and_return(action_policy_double)
      allow(action_policy_double).to receive(:delete!).and_return(true)
      allow(ActiveResource::Base).to receive(:delete)
    end

    it "validates that the request is supported" do
      described_class.delete(1)
      expect(Fixably::ActionPolicy).
        to have_received(:new).with(resource: described_class)
      expect(action_policy_double).to have_received(:delete!)
    end

    it "forwards the message to the superclass" do
      described_class.delete(1)
      expect(ActiveResource::Base).to have_received(:delete).with(1, {})
    end

    it "forwards on any supplied options" do
      described_class.delete(1, option: "A")
      expect(ActiveResource::Base).
        to have_received(:delete).with(1, option: "A")
    end
  end

  describe ".exists?" do
    before do
      allow(Fixably::ActionPolicy).
        to receive(:new).and_return(action_policy_double)
      allow(action_policy_double).to receive(:show!).and_return(true)
      allow(ActiveResource::Base).to receive(:find)
    end

    it "validates that the request is supported" do
      described_class.exists?(1)
      expect(Fixably::ActionPolicy).
        to have_received(:new).with(resource: described_class)
      expect(action_policy_double).to have_received(:show!)
    end

    it "attempts to find the record" do
      allow(described_class).to receive(:find)
      described_class.exists?(1, argument1: "A", argument2: "B")
      expect(described_class).
        to have_received(:find).with(1, argument1: "A", argument2: "B")
    end

    context "when the record exist" do
      before { allow(described_class).to receive(:find).and_return({ a: "a" }) }

      specify do
        result = described_class.exists?(1)
        expect(result).to be true
      end
    end

    context "when the record does not exist" do
      before do
        error = ::ActiveResource::ResourceNotFound.new({})
        allow(described_class).to receive(:find).and_raise(error)
      end

      specify do
        result = described_class.exists?(1)
        expect(result).to be false
      end
    end
  end

  describe ".find" do
    before do
      allow(Fixably::ActionPolicy).
        to receive(:new).and_return(action_policy_double)
      allow(action_policy_double).to receive(:show!).and_return(true)
      allow(ActiveResource::Base).to receive(:find)
    end

    it "validates that the request is supported" do
      described_class.find(1)
      expect(Fixably::ActionPolicy).
        to have_received(:new).with(resource: described_class)
      expect(action_policy_double).to have_received(:show!)
    end

    it "passes the message to ActiveResource with a request to expand items" do
      described_class.find(1)
      expect(ActiveResource::Base).to have_received(:find).
        with(1, params: {})
    end

    context "when expanded associations are supplied" do
      it "merges the supplied associations with items" do
        described_class.find(1, expand: %i[association relation])
        expect(ActiveResource::Base).to have_received(:find).
          with(1, params: { expand: "association,relation(items)" })
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
            { params: { option1: "A", option2: "B" } }
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
    before do
      allow(Fixably::ActionPolicy).
        to receive(:new).and_return(action_policy_double)
      allow(action_policy_double).to receive(:list!).and_return(true)
      allow(ActiveResource::Base).to receive(:first)
    end

    it "validates that the request is supported" do
      described_class.first
      expect(Fixably::ActionPolicy).
        to have_received(:new).with(resource: described_class)
      expect(action_policy_double).to have_received(:list!)
    end

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
    let(:collection) do
      Fixably::ActiveResource::PaginatedCollection.new(
        { "limit" => 25, "offset" => 0, "totalItems" => 0, "items" => [] }
      )
    end

    before do
      allow(Fixably::ActionPolicy).
        to receive(:new).and_return(action_policy_double)
      allow(action_policy_double).to receive(:list!).and_return(true)
      allow(ActiveResource::Base).to receive(:find_every).and_return(collection)
    end

    it "validates that the request is supported" do
      described_class.last
      expect(Fixably::ActionPolicy).
        to have_received(:new).with(resource: described_class)
      expect(action_policy_double).to have_received(:list!)
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
          to have_received(:last).with(expand: "items", limit: 1, offset: 89)
      end

      it "returns the last item" do
        expect(described_class.last).to eq("id" => 90)
      end
    end
  end

  describe ".where" do
    before do
      allow(Fixably::ActionPolicy).
        to receive(:new).and_return(action_policy_double)
      allow(action_policy_double).to receive(:list!).and_return(true)
    end

    it "validates that the request is supported" do
      allow(described_class).to receive(:find)
      described_class.where
      expect(Fixably::ActionPolicy).
        to have_received(:new).with(resource: described_class)
      expect(action_policy_double).to have_received(:list!)
    end

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

  describe "#destroy" do
    before do
      allow(Fixably::ActionPolicy).
        to receive(:new).and_return(action_policy_double)
      allow(action_policy_double).to receive(:delete!).and_return(true)
      allow(instance).to receive(:run_callbacks)
    end

    it "validates that the request is supported" do
      instance.destroy
      expect(Fixably::ActionPolicy).
        to have_received(:new).with(resource: described_class)
      expect(action_policy_double).to have_received(:delete!)
    end

    it "forwards the message to the superclass" do
      instance.destroy
      expect(instance).to have_received(:run_callbacks).with(:destroy)
    end
  end

  describe "#save" do
    before { allow(instance).to receive(:run_callbacks) }

    context "when creating a new record" do
      before { allow(action_policy_double).to receive(:create!) }

      it "validates that the request is supported" do
        allow(Fixably::ActionPolicy).
          to receive(:new).and_return(action_policy_double)

        instance.save

        expect(Fixably::ActionPolicy).
          to have_received(:new).with(resource: described_class)
        expect(action_policy_double).to have_received(:create!)
      end

      context "when the create action is supported" do
        before do
          allow(Fixably::ActionPolicy).
            to receive(:new).and_return(action_policy_double)
          allow(action_policy_double).to receive(:create!).and_return(true)
        end

        it "forwards the message to the superclass" do
          instance.save
          expect(instance).to have_received(:run_callbacks).with(:validate)
        end
      end

      context "when the create action is not supported" do
        it "raises a Fixably::UnsupportedError" do
          expect { instance.save! }.to raise_error(
            Fixably::UnsupportedError,
            "Fixably does not support creating fake customers"
          )
        end
      end
    end

    context "when updating an existing record" do
      before do
        allow(instance).to receive(:new?).and_return(false)
        allow(action_policy_double).to receive(:update!)
      end

      it "validates that the request is supported" do
        allow(Fixably::ActionPolicy).
          to receive(:new).and_return(action_policy_double)

        instance.save

        expect(Fixably::ActionPolicy).
          to have_received(:new).with(resource: described_class)
        expect(action_policy_double).to have_received(:update!)
      end

      context "when the validate parameter is false" do
        it "does not validate the request is supported" do
          allow(Fixably::ActionPolicy).to receive(:new)
          instance.save(validate: false)
          expect(Fixably::ActionPolicy).not_to have_received(:new)
        end
      end

      context "when the update action is supported" do
        before do
          allow(Fixably::ActionPolicy).
            to receive(:new).and_return(action_policy_double)
          allow(action_policy_double).to receive(:update!).and_return(true)
        end

        it "forwards the message to the superclass" do
          instance.save
          expect(instance).to have_received(:run_callbacks).with(:validate)
        end
      end

      context "when the update action is not supported" do
        it "raises a Fixably::UnsupportedError" do
          expect { instance.save! }.to raise_error(
            Fixably::UnsupportedError,
            "Fixably does not support updating fake customers"
          )
        end
      end
    end
  end

  describe "#save!" do
    before { allow(instance).to receive(:run_callbacks) }

    context "when creating a new record" do
      before { allow(action_policy_double).to receive(:create!) }

      it "validates that the request is supported" do
        allow(Fixably::ActionPolicy).
          to receive(:new).and_return(action_policy_double)

        begin
          instance.save!
        rescue ActiveResource::ResourceInvalid
        end

        expect(Fixably::ActionPolicy).
          to have_received(:new).with(resource: described_class)
        expect(action_policy_double).to have_received(:create!)
      end

      context "when the create action is supported" do
        before do
          allow(Fixably::ActionPolicy).
            to receive(:new).and_return(action_policy_double)
          allow(action_policy_double).to receive(:create!).and_return(true)
        end

        it "forwards the message to save" do
          allow(instance).to receive(:save)

          begin
            instance.save!
          rescue ActiveResource::ResourceInvalid
          end

          expect(instance).to have_received(:save).with(validate: false)
        end

        context "when the save fails" do
          before { allow(instance).to receive(:save).and_return(false) }

          it "raises an ActiveResource::ResourceInvalid error" do
            expect { instance.save! }.to raise_error(
              ActiveResource::ResourceInvalid,
              "Failed."
            )
          end

          it "passes the response to the error" do
            instance.save!
          rescue ActiveResource::ResourceInvalid => e
            expect(e.response).to be(instance)
          end
        end
      end

      context "when the create action is not supported" do
        it "raises a Fixably::UnsupportedError" do
          expect { instance.save! }.to raise_error(
            Fixably::UnsupportedError,
            "Fixably does not support creating fake customers"
          )
        end
      end
    end

    context "when updating an existing record" do
      before do
        allow(instance).to receive(:new?).and_return(false)
        allow(action_policy_double).to receive(:update!)
      end

      it "validates that the request is supported" do
        allow(Fixably::ActionPolicy).
          to receive(:new).and_return(action_policy_double)

        begin
          instance.save!
        rescue ActiveResource::ResourceInvalid
        end

        expect(Fixably::ActionPolicy).
          to have_received(:new).with(resource: described_class)
        expect(action_policy_double).to have_received(:update!)
      end

      context "when the update action is supported" do
        before do
          allow(Fixably::ActionPolicy).
            to receive(:new).and_return(action_policy_double)
          allow(action_policy_double).to receive(:update!).and_return(true)
        end

        it "forwards the message to save" do
          allow(instance).to receive(:save)

          begin
            instance.save!
          rescue ActiveResource::ResourceInvalid
          end

          expect(instance).to have_received(:save).with(validate: false)
        end

        context "when the save fails" do
          before { allow(instance).to receive(:save).and_return(false) }

          it "raises an ActiveResource::ResourceInvalid error" do
            expect { instance.save! }.to raise_error(
              ActiveResource::ResourceInvalid,
              "Failed."
            )
          end

          it "passes the response to the error" do
            instance.save!
          rescue ActiveResource::ResourceInvalid => e
            expect(e.response).to be(instance)
          end
        end
      end

      context "when the update action is not supported" do
        it "raises a Fixably::UnsupportedError" do
          expect { instance.save! }.to raise_error(
            Fixably::UnsupportedError,
            "Fixably does not support updating fake customers"
          )
        end
      end
    end
  end
end
