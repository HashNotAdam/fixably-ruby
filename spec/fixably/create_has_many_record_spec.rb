# frozen_string_literal: true

RSpec.describe Fixably::CreateHasManyRecord do
  let(:resource) do
    stub_const(
      "Fixably::FakeOrder::FakeNote",
      Class.new(Fixably::ApplicationResource)
    )
  end
  let(:parent_resource) do
    child_resource = resource
    stub_const(
      "Fixably::FakeOrder",
      Class.new(Fixably::ApplicationResource) do
        has_many :notes, class_name: child_resource.name.underscore
      end
    )
  end

  context "when the record is a parent resource" do
    let(:resource) do
      stub_const(
        "Fixably::FakeOrder",
        Class.new(Fixably::ApplicationResource)
      )
    end

    it "raises an ArgumentError" do
      collection = Fixably::ActiveResource::PaginatedCollection.new
      collection.resource_class = resource
      record = resource.new
      expect { described_class.(record: record, collection: collection) }.
        to raise_error(
          ArgumentError, "Can only appended resources nested one level deep"
        )
    end
  end

  context "when the record is a nested resource" do
    let(:collection) do
      collection = Fixably::ActiveResource::PaginatedCollection.new
      collection.resource_class = resource
      collection.parent_resource = parent_record
      collection.parent_association = :notes
      collection
    end
    let(:record) { resource.new }
    let(:parent_record) do
      result = parent_resource.new
      result.instance_variable_set(:@persisted, true)
      result.id = 1
      result
    end

    before { allow(record).to receive(:save!) }

    it "sets the parent association on the resource" do
      described_class.(record: record, collection: collection)
      expect(record.parent_association).to eq(:notes)
    end

    it "sets the parent resource ID on the resource" do
      described_class.(record: record, collection: collection)
      expect(record.prefix_options).to include(fake_order_id: 1)
    end

    it "calls save! on the record" do
      described_class.(record: record, collection: collection)
      expect(record).to have_received(:save!)
    end

    it "appends the record to the collection" do
      described_class.(record: record, collection: collection)
      expect(collection.elements).to include(record)
    end

    context "when the record isn't an instance of the collection resource" do
      let(:another_resource) do
        stub_const(
          "Fixably::FakeOrder::FakeTask",
          Class.new(Fixably::ApplicationResource)
        )
      end
      let(:collection) do
        collection = Fixably::ActiveResource::PaginatedCollection.new
        collection.resource_class = resource
        collection
      end

      it "raises an ArgumentError" do
        record = another_resource.new
        expect { described_class.(record: record, collection: collection) }.
          to raise_error(
            TypeError,
            "Appended record must be an instance of #{resource.name}"
          )
      end
    end

    context "when a parent_resource has not been set" do
      let(:collection) do
        collection = Fixably::ActiveResource::PaginatedCollection.new
        collection.resource_class = resource
        collection
      end

      it "raises an RuntimeError" do
        record = resource.new
        expect { described_class.(record: record, collection: collection) }.
          to raise_error(
            RuntimeError,
            "A parent resource has not been set"
          )
      end
    end

    context "when a parent_association has not been set" do
      let(:collection) do
        collection = Fixably::ActiveResource::PaginatedCollection.new
        collection.resource_class = resource
        collection.parent_resource = parent_resource.new
        collection
      end

      it "raises an RuntimeError" do
        record = resource.new
        expect { described_class.(record: record, collection: collection) }.
          to raise_error(
            RuntimeError,
            "The association to the parent resource has not been set"
          )
      end
    end

    context "when a parent_resource has not been persisted" do
      let(:collection) do
        collection = Fixably::ActiveResource::PaginatedCollection.new
        collection.resource_class = resource
        collection.parent_resource = parent_resource.new
        collection.parent_association = :notes
        collection
      end

      it "raises an RuntimeError" do
        record = resource.new
        expect { described_class.(record: record, collection: collection) }.
          to raise_error(
            RuntimeError,
            "The parent resource has not been been persisted"
          )
      end
    end

    context "when a parent_resource does not have an ID" do
      let(:collection) do
        collection = Fixably::ActiveResource::PaginatedCollection.new
        collection.resource_class = resource
        collection.parent_resource = parent_resource.new
        collection.parent_resource.instance_variable_set(:@persisted, true)
        collection.parent_association = :notes
        collection
      end

      it "raises an RuntimeError" do
        record = resource.new
        expect { described_class.(record: record, collection: collection) }.
          to raise_error(
            RuntimeError,
            "Cannot find an ID for the parent resource"
          )
      end
    end
  end
end
