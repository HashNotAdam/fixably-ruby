# frozen_string_literal: true

RSpec.describe Fixably::Customer do
  include_examples(
    "a resource",
    "customer",
    "customers",
    %i[create list show update]
  )

  describe "#save" do
    context "when both the email and phone are blank" do
      it "is invalid" do
        instance = described_class.new
        expect(instance).not_to be_valid

        instance = described_class.new(phone: "")
        expect(instance).not_to be_valid
        instance = described_class.new(phone: "1")
        expect(instance).to be_valid

        instance = described_class.new(email: "")
        expect(instance).not_to be_valid
        instance = described_class.new(email: "@")
        expect(instance).to be_valid
      end

      it "adds an error to the instance" do
        instance = described_class.new(phone: "")
        instance.valid?
        error = instance.errors.full_messages.to_sentence
        expect(error).to eq("Either email or phone must be present")

        instance = described_class.new(email: "")
        instance.valid?
        error = instance.errors.full_messages.to_sentence
        expect(error).to eq("Either email or phone must be present")
      end
    end
  end

  describe "#encode" do
    attributes = {
      "id" => 1,
      "href" => "https://...",
      "first_name" => "Jill",
      "tags" => [],
      "created_at" => "2000-01-01",
    }
    encoded_attributes = { "firstName" => "Jill" }

    include_examples(
      "an Active Resource encoder",
      attributes,
      encoded_attributes
    )
  end
end
