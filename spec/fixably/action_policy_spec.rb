# frozen_string_literal: true

RSpec.describe Fixably::ActionPolicy do
  let(:instance) { described_class.new(resource: resource) }
  let(:resource) do
    acts = actions
    Class.new(Fixably::ApplicationResource) do
      actions acts

      def self.name = "Customer"
    end
  end
  let(:actions) { [] }

  describe "#initialize" do
    it "accepts a resource class" do
      expect(instance.resource).to be resource
    end

    it "accepts a resource instance and stores it's class" do
      resource_instance = resource.new
      instance = described_class.new(resource: resource_instance)
      expect(instance.resource).to be resource
    end

    context "when the class is not a resource" do
      let(:resource) { Class.new }

      it "raises an ArgumentError" do
        expect { described_class.new(resource: resource) }.to raise_error(
          ArgumentError,
          "The resource should inherit from ApplicationResource"
        )
      end
    end
  end

  describe "#create?" do
    subject { instance.create? }

    context "when the resource actions include create" do
      let(:actions) { [:create] }

      it { is_expected.to be true }
    end

    context "when the resource actions do not include create" do
      it { is_expected.to be false }
    end
  end

  describe "#create!" do
    context "when the resource actions include create" do
      let(:actions) { [:create] }

      it "returns true" do
        expect(instance.create!).to be(true)
      end
    end

    context "when the resource actions do not include create" do
      it "raises an UnsupportedError" do
        expect { instance.create! }.to raise_error(
          Fixably::UnsupportedError,
          "Fixably does not support creating customers"
        )
      end
    end
  end

  describe "#delete?" do
    subject { instance.delete? }

    context "when the resource actions include delete" do
      let(:actions) { [:delete] }

      it { is_expected.to be true }
    end

    context "when the resource actions do not include delete" do
      it { is_expected.to be false }
    end
  end

  describe "#delete!" do
    context "when the resource actions include delete" do
      let(:actions) { [:delete] }

      it "returns true" do
        expect(instance.delete!).to be(true)
      end
    end

    context "when the resource actions do not include delete" do
      it "raises an UnsupportedError" do
        expect { instance.delete! }.to raise_error(
          Fixably::UnsupportedError,
          "Fixably does not support deleting customers"
        )
      end
    end
  end

  describe "#list?" do
    subject { instance.list? }

    context "when the resource actions include list" do
      let(:actions) { [:list] }

      it { is_expected.to be true }
    end

    context "when the resource actions do not include list" do
      it { is_expected.to be false }
    end
  end

  describe "#list!" do
    context "when the resource actions include list" do
      let(:actions) { [:list] }

      it "returns true" do
        expect(instance.list!).to be(true)
      end
    end

    context "when the resource actions do not include list" do
      it "raises an UnsupportedError" do
        expect { instance.list! }.to raise_error(
          Fixably::UnsupportedError,
          "Fixably does not support listing customers"
        )
      end
    end
  end

  describe "#show?" do
    subject { instance.show? }

    context "when the resource actions include show" do
      let(:actions) { [:show] }

      it { is_expected.to be true }
    end

    context "when the resource actions do not include show" do
      it { is_expected.to be false }
    end
  end

  describe "#show!" do
    context "when the resource actions include show" do
      let(:actions) { [:show] }

      it "returns true" do
        expect(instance.show!).to be(true)
      end
    end

    context "when the resource actions do not include show" do
      it "raises an UnsupportedError" do
        expect { instance.show! }.to raise_error(
          Fixably::UnsupportedError,
          "Fixably does not support retrieving customers"
        )
      end
    end
  end

  describe "#update?" do
    subject { instance.update? }

    context "when the resource actions include update" do
      let(:actions) { [:update] }

      it { is_expected.to be true }
    end

    context "when the resource actions do not include update" do
      it { is_expected.to be false }
    end
  end

  describe "#update!" do
    context "when the resource actions include update" do
      let(:actions) { [:update] }

      it "returns true" do
        expect(instance.update!).to be(true)
      end
    end

    context "when the resource actions do not include update" do
      it "raises an UnsupportedError" do
        expect { instance.update! }.to raise_error(
          Fixably::UnsupportedError,
          "Fixably does not support updating customers"
        )
      end
    end
  end
end
