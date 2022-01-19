# frozen_string_literal: true

RSpec.describe Fixably::Actions do
  let(:action_policy_double) { instance_double(Fixably::ActionPolicy) }
  let(:fake_has_one) do
    stub_const(
      "Fixably::FakeHasOne",
      Class.new(Fixably::ApplicationResource)
    )
  end
  let(:fake_has_many) do
    stub_const(
      "Fixably::FakeHasMany",
      Class.new(Fixably::ApplicationResource)
    )
  end
  let(:resource) do
    has_one_class_name = fake_has_one.name.underscore
    has_many_class_name = fake_has_many.name.underscore

    stub_const(
      "Fixably::FakeCustomer",
      Class.new(Fixably::ApplicationResource) do
        has_one :association, class_name: has_one_class_name
        has_one :name_with_underscores, class_name: has_one_class_name
        has_many :relation, class_name: has_many_class_name
      end
    )
  end
  let(:instance) { resource.new }

  describe ".included" do
    context "when a class does not include this module" do
      let(:class_without_module) { Class.new }

      it "does not include the module class methods" do
        expect(class_without_module).not_to respond_to(:all)
        expect(class_without_module).not_to respond_to(:create)
        expect(class_without_module).not_to respond_to(:create!)
        expect(class_without_module).not_to respond_to(:delete)
        expect(class_without_module).not_to respond_to(:exists?)
        expect(class_without_module).not_to respond_to(:find)
        expect(class_without_module).not_to respond_to(:first)
        expect(class_without_module).not_to respond_to(:last)
        expect(class_without_module).not_to respond_to(:where)
      end

      it "does not include the module instance methods" do
        instance = class_without_module.new
        expect(instance).not_to respond_to(:destroy)
        expect(instance).not_to respond_to(:save)
        expect(instance).not_to respond_to(:save!)
      end
    end

    context "when a class includes this module" do
      let(:class_with_module) do
        include_module = described_class
        Class.new do
          include include_module
        end
      end

      it "includes the module class methods" do
        expect(class_with_module).to respond_to(:all)
        expect(class_with_module).to respond_to(:create)
        expect(class_with_module).to respond_to(:create!)
        expect(class_with_module).to respond_to(:delete)
        expect(class_with_module).to respond_to(:exists?)
        expect(class_with_module).to respond_to(:find)
        expect(class_with_module).to respond_to(:first)
        expect(class_with_module).to respond_to(:last)
        expect(class_with_module).to respond_to(:where)
      end

      it "includes the module instance methods" do
        instance = class_with_module.new
        expect(instance).to respond_to(:destroy)
        expect(instance).to respond_to(:save)
        expect(instance).to respond_to(:save!)
      end
    end
  end

  describe ".actions" do
    let(:all_actions) { %i[create delete list show update] }

    context "when it is called on ApplicationResource" do
      specify do
        expect { Fixably::ApplicationResource.actions }.to raise_error(
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
        expect { resource.actions(Class.new) }.to raise_error(
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

  describe ".all" do
    before do
      allow(Fixably::ActionPolicy).
        to receive(:new).and_return(action_policy_double)
      allow(action_policy_double).to receive(:list!).and_return(true)
      allow(ActiveResource::Base).to receive(:all)
    end

    it "validates that the request is supported" do
      resource.all
      expect(Fixably::ActionPolicy).
        to have_received(:new).with(resource: resource)
      expect(action_policy_double).to have_received(:list!)
    end

    it "forwards the message to the superclass" do
      resource.all(argument1: "A", argument2: "B")
      expect(ActiveResource::Base).
        to have_received(:all).with(argument1: "A", argument2: "B")
    end

    context "when no arguments are supplied" do
      it "passes no arguments" do
        resource.all
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

      resource.create

      expect(Fixably::ActionPolicy).
        to have_received(:new).with(resource: resource)
      expect(action_policy_double).to have_received(:create!)
    end

    context "when the create action is supported" do
      before do
        allow(Fixably::ActionPolicy).
          to receive(:new).and_return(action_policy_double)
        allow(action_policy_double).to receive(:create!).and_return(true)
      end

      it "forwards the message to the superclass" do
        resource.create
        expect(ActiveResource::Base).to have_received(:create).with({})
      end

      it "forwards on any supplied options" do
        resource.create(option1: "A", option2: "B")
        expect(ActiveResource::Base).
          to have_received(:create).with(option1: "A", option2: "B")
      end
    end

    context "when the create action is not supported" do
      it "raises an UnsupportedError" do
        expect { resource.create }.to raise_error(
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

      resource.create!

      expect(Fixably::ActionPolicy).
        to have_received(:new).with(resource: resource)
      expect(action_policy_double).to have_received(:create!)
    end

    context "when the create action is supported" do
      before do
        allow(Fixably::ActionPolicy).
          to receive(:new).and_return(action_policy_double)
        allow(action_policy_double).to receive(:create!).and_return(true)
      end

      it "forwards the message to the superclass" do
        resource.create!
        expect(ActiveResource::Base).to have_received(:create!).with({})
      end

      it "forwards on any supplied options" do
        resource.create!(option1: "A", option2: "B")
        expect(ActiveResource::Base).
          to have_received(:create!).with(option1: "A", option2: "B")
      end
    end

    context "when the create action is not supported" do
      it "raises an UnsupportedError" do
        expect { resource.create! }.to raise_error(
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
      resource.delete(1)
      expect(Fixably::ActionPolicy).
        to have_received(:new).with(resource: resource)
      expect(action_policy_double).to have_received(:delete!)
    end

    it "forwards the message to the superclass" do
      resource.delete(1)
      expect(ActiveResource::Base).to have_received(:delete).with(1, {})
    end

    it "forwards on any supplied options" do
      resource.delete(1, option: "A")
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
      resource.exists?(1)
      expect(Fixably::ActionPolicy).
        to have_received(:new).with(resource: resource)
      expect(action_policy_double).to have_received(:show!)
    end

    it "attempts to find the record" do
      allow(resource).to receive(:find)
      resource.exists?(1, argument1: "A", argument2: "B")
      expect(resource).
        to have_received(:find).with(1, argument1: "A", argument2: "B")
    end

    it "defaults the options to an empty hash" do
      allow(resource).to receive(:find)
      resource.exists?(1)
      expect(resource).to have_received(:find).with(1, {})
    end

    context "when the record exist" do
      before { allow(resource).to receive(:find).and_return({ a: "a" }) }

      specify do
        result = resource.exists?(1)
        expect(result).to be true
      end
    end

    context "when the record does not exist" do
      before do
        error = ::ActiveResource::ResourceNotFound.new({})
        allow(resource).to receive(:find).and_raise(error)
      end

      specify do
        result = resource.exists?(1)
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
      resource.find(1)
      expect(Fixably::ActionPolicy).
        to have_received(:new).with(resource: resource)
      expect(action_policy_double).to have_received(:show!)
    end

    it "passes the message to ActiveResource with a request to expand items" do
      resource.find(1)
      expect(ActiveResource::Base).to have_received(:find).
        with(1, params: {})
    end

    it "allows the ID to be supplied as a string" do
      resource.find("1")
      expect(ActiveResource::Base).to have_received(:find).
        with("1", params: {})
    end

    context "when expanded associations are supplied" do
      it "merges the supplied associations with items" do
        resource.find(1, expand: %i[association relation])
        expect(ActiveResource::Base).to have_received(:find).
          with(1, params: { expand: "association,relation(items)" })
      end

      context "when the association name includes underscores" do
        it "camelizes the name" do
          resource.find(1, expand: %i[name_with_underscores])
          expect(ActiveResource::Base).to have_received(:find).
            with(1, params: { expand: "nameWithUnderscores" })
        end
      end

      context "when expand is a string" do
        it "passes it on unmodified" do
          resource.find(1, expand: "do not modify")
          expect(ActiveResource::Base).to have_received(:find).
            with(1, params: { expand: "do not modify" })
        end
      end
    end

    context "when options are supplied" do
      it "merges the options into the params" do
        resource.find(1, { option1: "A", option2: "B" })
        expect(ActiveResource::Base).to have_received(:find).
          with(
            1,
            { params: { option1: "A", option2: "B" } }
          )
      end

      it "does not modify the supplied arguments directly" do
        arguments = { option1: "A", option2: "B" }
        resource.find(1, arguments)
        expect(arguments).to eq(option1: "A", option2: "B")
      end
    end

    context "when the parameteres are already nested under a params key" do
      it "does not re-nest the parameters" do
        resource.find(1, params: { option1: "A", option2: "B" })
        expect(ActiveResource::Base).to have_received(:find).
          with(
            1,
            { params: { option1: "A", option2: "B" } }
          )
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
      resource.first
      expect(Fixably::ActionPolicy).
        to have_received(:new).with(resource: resource)
      expect(action_policy_double).to have_received(:list!)
    end

    it "sets the limit parameter to 1 before passing on the message" do
      resource.first
      expect(ActiveResource::Base).to have_received(:first).with(limit: 1)
    end

    context "when arguments are supplied" do
      it "forwards the arguments" do
        resource.first(argument1: "A", argument2: "B")
        expect(ActiveResource::Base).to have_received(:first).
          with(argument1: "A", argument2: "B", limit: 1)
      end
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
      resource.includes(:association)
      expect(Fixably::ResourceLazyLoader).
        to have_received(:new).with(model: resource)
    end

    it "send an includes message to the new instance" do
      resource.includes(:association)
      expect(resource_lazy_loader_double).
        to have_received(:includes).with(:association)
    end

    it "returns the new instance" do
      result = resource.includes(:association)
      expect(result).to be resource_lazy_loader_double
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
      resource.last
      expect(Fixably::ActionPolicy).
        to have_received(:new).with(resource: resource)
      expect(action_policy_double).to have_received(:list!)
    end

    context "when there are no results for the search" do
      let(:collection) do
        Fixably::ActiveResource::PaginatedCollection.new(
          { "limit" => 25, "offset" => 0, "totalItems" => 0, "items" => [] }
        )
      end

      it "makes the request via find_every" do
        resource.last(argument1: "A", argument2: "B")
        expect(ActiveResource::Base).
          to have_received(:find_every).with(
            params: { argument1: "A", argument2: "B", expand: "items" }
          )
      end

      it "returns nil" do
        expect(resource.last).to be_nil
      end

      it "does not make a second request" do
        allow(ActiveResource::Base).to receive(:last)
        resource.last
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
        resource.last(offset: 5)
        expect(ActiveResource::Base).
          to have_received(:find_every).with(
            params: { offset: 5, expand: "items" }
          )
      end

      it "returns the last item" do
        result = resource.last(offset: 5)
        expect(result).to eq(items.last)
      end

      it "does not make a second request" do
        allow(ActiveResource::Base).to receive(:last)
        resource.last(offset: 5)
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
        resource.last
        expect(ActiveResource::Base).
          to have_received(:find_every).with(params: { expand: "items" })
      end

      it "returns the last item" do
        expect(resource.last).to eq(items.last)
      end

      it "does not make a second request" do
        allow(ActiveResource::Base).to receive(:last)
        resource.last
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
        resource.last
        expect(ActiveResource::Base).
          to have_received(:find_every).with(params: { expand: "items" })
      end

      it "returns the last item" do
        expect(resource.last).to eq(items.last)
      end

      it "does not make a second request" do
        allow(ActiveResource::Base).to receive(:last)
        resource.last
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
        resource.last
        expect(ActiveResource::Base).
          to have_received(:find_every).with(params: { expand: "items" })
      end

      it "makes a second request via ActiveResource::Base.last" do
        resource.last
        expect(ActiveResource::Base).
          to have_received(:last).with(expand: "items", limit: 1, offset: 89)
      end

      it "returns the last item" do
        expect(resource.last).to eq("id" => 90)
      end
    end

    context "when the parameteres are already nested under a params key" do
      it "does not re-nest the parameters" do
        resource.last(params: { option1: "A", option2: "B" })
        expect(ActiveResource::Base).
          to have_received(:find_every).
          with(params: { expand: "items", option1: "A", option2: "B" })
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
      allow(resource).to receive(:find)
      resource.where
      expect(Fixably::ActionPolicy).
        to have_received(:new).with(resource: resource)
      expect(action_policy_double).to have_received(:list!)
    end

    it "forwards the message to find" do
      allow(resource).to receive(:find)
      resource.where(argument1: "A", argument2: "B")
      expect(resource).to have_received(:find).with(
        :all, argument1: "A", argument2: "B"
      )
    end

    it "delegates parameter preparation to find" do
      allow(ActiveResource::Base).to receive(:find)
      resource.where(argument1: "A", argument2: "B")
      expect(ActiveResource::Base).to have_received(:find).with(
        :all, params: { argument1: "A", argument2: "B", expand: "items" }
      )
    end

    context "when no arguments are supplied" do
      before { allow(resource).to receive(:find) }

      it "passes on an empty hash" do
        resource.where
        expect(resource).to have_received(:find).with(:all, {})
      end
    end

    context "when an argument has an array value" do
      before { allow(resource).to receive(:find) }

      context "when the array has two values" do
        it "converts the two values to a string" do
          resource.where(created_at: %w[2000-01-01 2000-02-01])
          expect(resource).to have_received(:find).
            with(:all, { created_at: "[2000-01-01,2000-02-01]" })
        end

        it "converts time values into strings" do
          from = Time.parse("2000-01-01 10:00:00")
          to = Time.parse("2000-02-01 13:00:00")
          resource.where(created_at: [from, to])
          expect(resource).to have_received(:find).
            with(:all, { created_at: "[2000-01-01,2000-02-01]" })
        end
      end

      context "when the array has two values and the first is nil" do
        before { allow(resource).to receive(:find) }

        it "converts nil into an empty space" do
          resource.where(created_at: [nil, "2000-02-01"])
          expect(resource).to have_received(:find).
            with(:all, { created_at: "[,2000-02-01]" })
        end
      end

      context "when the array has two values and the second is nil" do
        before { allow(resource).to receive(:find) }

        it "converts nil into an empty space" do
          resource.where(created_at: ["2000-01-01", nil])
          expect(resource).to have_received(:find).
            with(:all, { created_at: "[2000-01-01,]" })
        end
      end

      context "when the array is empty" do
        before { allow(resource).to receive(:find) }

        it "raises and ArgumentError" do
          expect { resource.where(created_at: []) }.to raise_error(
            ArgumentError,
            "Ranged searches should have either 1 or 2 values but " \
            "created_at has 0"
          )
        end
      end

      context "when the array has one value" do
        before { allow(resource).to receive(:find) }

        it "acts as if a nil second value was supplied" do
          resource.where(created_at: ["2000-01-01"])
          expect(resource).to have_received(:find).
            with(:all, { created_at: "[2000-01-01,]" })
        end
      end

      context "when the array has more than two values" do
        before { allow(resource).to receive(:find) }

        it "raises and ArgumentError" do
          values = %w[2000-01-01 2000-02-01 2000-03-01]
          expect { resource.where(created_at: values) }.to raise_error(
            ArgumentError,
            "Ranged searches should have either 1 or 2 values but " \
            "created_at has 3"
          )
        end
      end

      context "when other values are also supplied" do
        it "converts the only the array to a string" do
          resource.where(
            id: 1,
            created_at: %w[2000-01-01 2000-02-01],
            num: 2
          )
          expect(resource).to have_received(:find).
            with(:all, { id: 1, created_at: "[2000-01-01,2000-02-01]", num: 2 })
        end
      end

      context "when the value is array-like" do
        let(:value) do
          klass = Class.new(Array)
          result = klass.new
          result << "2000-01-01"
          result << "2000-02-01"
          result
        end

        it "converts the values to a string" do
          resource.where(created_at: value)
          expect(resource).to have_received(:find).
            with(:all, { created_at: "[2000-01-01,2000-02-01]" })
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
        to have_received(:new).with(resource: resource)
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
          to have_received(:new).with(resource: resource)
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
          to have_received(:new).with(resource: resource)
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
          to have_received(:new).with(resource: resource)
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
          to have_received(:new).with(resource: resource)
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
