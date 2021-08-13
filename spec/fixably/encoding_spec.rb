# frozen_string_literal: true

RSpec.describe Fixably::Encoding do
  describe "#encode" do
    let(:described_class) do
      stub_const(
        "Fixably::FakeCustomer",
        Class.new(Fixably::ApplicationResource) do
          include Fixably::Encoding

          self.site = "https://demo.fixably.com"

          has_one :one_thing
          has_one :another_thing

          has_many :many_things
          has_many :other_things

          attr_accessor :attributes
        end
      )
    end
    let(:fake_association) do
      stub_const(
        "Fixably::FakeAssociation",
        Class.new(described_class) do
          has_one :association, class_name: "fixably/fake_association"
        end
      )
    end

    attributes = {
      "id" => 1,
      "href" => "https://...",
      "first_name" => "Jill",
      "created_at" => "2000-01-01",
    }
    encoded_attributes = { "firstName" => "Jill" }

    include_examples(
      "an Active Resource encoder",
      attributes,
      encoded_attributes
    )

    context "when the resource has has_one associations" do
      let(:instance) do
        described_class.new(id: 1, name: "Main thing").tap do |inst|
          inst.one_thing = fake_association.new(
            id: 2, href: "https://...", first_name: "Jill",
            created_at: "2000-01-01"
          )
          inst.another_thing = fake_association.new(
            id: 3, href: "https://...", first_name: "Chris",
            created_at: "2000-01-01"
          )
        end
      end

      context "when the has_one associations are nil" do
        let(:instance) { described_class.new(id: 1, name: "Main thing") }

        it "ignores the associations" do
          expect(instance.encode).to eq(
            { name: "Main thing" }.to_json
          )
        end
      end
    end

    context "when the resource has has_many associations" do
      let(:instance) do
        inst = described_class.new(id: 1, name: "Main thing")
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

    context "when a parent_association is set on the resource" do
      let!(:parent_resource) do
        stub_const(
          "Fixably::FakeOrder",
          Class.new(Fixably::ApplicationResource) do
            has_many :fake_notes, class_name: "fixably/fake_order/fake_note"
          end
        )
      end
      let(:resource) do
        stub_const(
          "Fixably::FakeOrder::FakeNote",
          Class.new(Fixably::ApplicationResource)
        )
      end

      it "nests the attributes in a key named after the resource" do
        instance = resource.new(text: "New note")
        instance.parent_association = :fake_notes
        expect(instance.encode).to eq(
          { fakeNotes: [{ text: "New note" }] }.to_json
        )
      end
    end
  end
end
