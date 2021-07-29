# frozen_string_literal: true

RSpec.describe Fixably::ActiveResource::PaginatedCollection do
  let(:instance) { described_class.new(collection_wrapper) }
  let(:collection_wrapper) do
    {
      "limit" => limit,
      "offset" => offset,
      "totalItems" => total_items,
      "unexpected" => "value",
      "items" => items,
    }
  end
  let(:limit) { 25 }
  let(:offset) { 0 }
  let(:total_items) { 100 }
  let(:items) do
    [
      { "first_name" => "Lawrence", "last_name" => "Terry" },
      { "first_name" => "Chris", "last_name" => "Shields" },
    ]
  end

  it "is an ActiveResource::Collection" do
    expect(described_class.ancestors).to include(::ActiveResource::Collection)
  end

  it "extracts the collection from items" do
    expect(instance).to eq(
      [
        { "first_name" => "Lawrence", "last_name" => "Terry" },
        { "first_name" => "Chris", "last_name" => "Shields" },
      ]
    )
  end

  it "extracts the limit parameter" do
    expect(instance.limit).to eq(25)
  end

  it "extracts the offset parameter" do
    expect(instance.offset).to eq(0)
  end

  it "extracts the total items parameter" do
    expect(instance.total_items).to eq(100)
  end

  describe "paginated_each" do
    let(:limit) { 2 }
    let(:total_items) { 2 }

    it "iterates over the current page" do
      records = []
      instance.paginated_each { records << _1 }
      expect(records).to eq(items)
    end

    context "when there are multiple pages of records" do
      let(:total_items) { 6 }
      let(:second_page) { described_class.new(second_wrapper) }
      let(:second_wrapper) do
        wrapper = collection_wrapper.dup
        wrapper["offset"] = 2
        wrapper["items"] = second_items
        wrapper
      end
      let(:second_items) do
        [
          { "first_name" => "Valene", "last_name" => "Douglas" },
          { "first_name" => "Beatrice", "last_name" => "McDermott" },
        ]
      end
      let(:third_page) { described_class.new(third_wrapper) }
      let(:third_wrapper) do
        wrapper = collection_wrapper.dup
        wrapper["offset"] = 4
        wrapper["items"] = third_items
        wrapper
      end
      let(:third_items) do
        [
          { "first_name" => "Ashley", "last_name" => "Emmerich" },
          { "first_name" => "Ismael", "last_name" => "Bahringer" },
        ]
      end

      before do
        allow(instance).to receive(:next_page).and_return(second_page)
        allow(second_page).to receive(:next_page).and_return(third_page)
      end

      it "iterates over all records of all pages" do
        records = []
        instance.paginated_each { records << _1 }
        expect(records).to eq(
          items.dup.concat(second_items).concat(third_items)
        )
      end
    end
  end

  describe "paginated_map" do
    let(:limit) { 2 }
    let(:total_items) { 6 }
    let(:second_page) { described_class.new(second_wrapper) }
    let(:second_wrapper) do
      wrapper = collection_wrapper.dup
      wrapper["offset"] = 2
      wrapper["items"] = second_items
      wrapper
    end
    let(:second_items) do
      [
        { "first_name" => "Valene", "last_name" => "Douglas" },
        { "first_name" => "Beatrice", "last_name" => "McDermott" },
      ]
    end
    let(:third_page) { described_class.new(third_wrapper) }
    let(:third_wrapper) do
      wrapper = collection_wrapper.dup
      wrapper["offset"] = 4
      wrapper["items"] = third_items
      wrapper
    end
    let(:third_items) do
      [
        { "first_name" => "Ashley", "last_name" => "Emmerich" },
        { "first_name" => "Ismael", "last_name" => "Bahringer" },
      ]
    end

    before do
      allow(instance).to receive(:next_page).and_return(second_page)
      allow(second_page).to receive(:next_page).and_return(third_page)
    end

    it "return an array of records from all pages" do
      expect(instance.paginated_map).to eq(
        items.dup.concat(second_items).concat(third_items)
      )
    end
  end

  describe "next_page" do
    let(:limit) { 25 }
    let(:offset) { 0 }
    let(:total_items) { 100 }
    let(:resource) { Class.new(Fixably::ApplicationResource) }
    let(:original_params) { { first_name: "Lawrence", expand: "items" } }

    let(:second_page) do
      page = instance.dup
      page.instance_variable_set(:@offset, 25)
      page
    end

    before do
      instance.resource_class = resource
      instance.original_params = original_params
    end

    it "makes a request for the next page" do
      allow(instance).to receive(:where).and_return(second_page)
      next_page = instance.next_page
      expect(instance).to have_received(:where).with(limit: 25, offset: 25)

      allow(next_page).to receive(:where)
      next_page.next_page
      expect(next_page).to have_received(:where).with(limit: 25, offset: 50)
    end

    it "uses the same search parmeters" do
      allow(resource).to receive(:where).and_return(second_page)
      next_page = instance.next_page
      expect(resource).to have_received(:where).with(
        first_name: "Lawrence", expand: "items", limit: 25, offset: 25
      )

      allow(resource).to receive(:where)
      next_page.next_page
      expect(resource).to have_received(:where).with(
        first_name: "Lawrence", expand: "items", limit: 25, offset: 50
      )
    end

    context "when there are no more pages" do
      let(:total_items) { 5 }

      it "raises an error" do
        expect { instance.next_page }.to raise_error(
          StopIteration,
          "There are no more pages"
        )
      end
    end
  end

  describe "#next_page?" do
    subject { instance.next_page? }

    context "when the offset is 0" do
      let(:offset) { 0 }

      context "when the limit is equal to the total items" do
        let(:limit) { 25 }
        let(:total_items) { 25 }

        it { is_expected.to be false }
      end

      context "when the total items is greater than the limit" do
        let(:limit) { 25 }
        let(:total_items) { 30 }

        it { is_expected.to be true }
      end
    end

    context "when the limit is greater than the total items" do
      let(:limit) { 25 }
      let(:offset) { 0 }
      let(:total_items) { 20 }

      it { is_expected.to be false }
    end

    context "when the limit plus offset is less than the total items" do
      let(:limit) { 25 }
      let(:offset) { 4 }
      let(:total_items) { 30 }

      it { is_expected.to be true }
    end

    context "when the limit plus offset is equal to the total items" do
      let(:limit) { 25 }
      let(:offset) { 5 }
      let(:total_items) { 30 }

      it { is_expected.to be false }
    end

    context "when the limit plus offset is greater than the total items" do
      let(:limit) { 25 }
      let(:offset) { 10 }
      let(:total_items) { 30 }

      it { is_expected.to be false }
    end
  end

  describe "previous_page" do
    let(:limit) { 25 }
    let(:offset) { 75 }
    let(:total_items) { 100 }
    let(:resource) { Class.new(Fixably::ApplicationResource) }
    let(:original_params) { { first_name: "Lawrence", expand: "items" } }

    let(:second_page) do
      page = instance.dup
      page.instance_variable_set(:@offset, 50)
      page
    end

    before do
      instance.resource_class = resource
      instance.original_params = original_params
    end

    it "makes a request for the previous page" do
      allow(instance).to receive(:where).and_return(second_page)
      previous_page = instance.previous_page
      expect(instance).to have_received(:where).with(limit: 25, offset: 50)

      allow(previous_page).to receive(:where)
      previous_page.previous_page
      expect(previous_page).to have_received(:where).with(limit: 25, offset: 25)
    end

    it "uses the same search parmeters" do
      allow(resource).to receive(:where).and_return(second_page)
      previous_page = instance.previous_page
      expect(resource).to have_received(:where).with(
        first_name: "Lawrence", expand: "items", limit: 25, offset: 50
      )

      allow(resource).to receive(:where)
      previous_page.previous_page
      expect(resource).to have_received(:where).with(
        first_name: "Lawrence", expand: "items", limit: 25, offset: 25
      )
    end

    context "when there are no more pages" do
      let(:offset) { 0 }

      it "raises an error" do
        expect { instance.previous_page }.to raise_error(
          StopIteration,
          "There are no more pages"
        )
      end
    end

    context "when the next offset would be negative" do
      let(:limit) { 25 }
      let(:offset) { 20 }

      before { allow(instance).to receive(:where) }

      it "sets the offset to 0" do
        instance.previous_page
        expect(instance).to have_received(:where).
          with(limit: anything, offset: 0)
      end

      it "sets the limit to the delta" do
        instance.previous_page
        expect(instance).to have_received(:where).
          with(limit: 20, offset: anything)
      end
    end
  end

  describe "#previous_page?" do
    subject { instance.previous_page? }

    context "when the offset is 0" do
      let(:offset) { 0 }

      it { is_expected.to be false }
    end

    context "when the offset is positive" do
      let(:offset) { 1 }

      it { is_expected.to be true }
    end
  end
end
