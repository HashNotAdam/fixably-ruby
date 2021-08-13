# frozen_string_literal: true

RSpec.describe Fixably::Authorization do
  let(:resource) { Class.new(Fixably::ApplicationResource) }

  describe ".headers" do
    it "adds the API authorisation to the default headers" do
      expect(resource.headers).to eq(
        {
          "Authorization" =>
            "pk_0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJK",
        }
      )
    end
  end
end
