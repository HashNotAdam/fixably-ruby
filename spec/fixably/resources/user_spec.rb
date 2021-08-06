# frozen_string_literal: true

RSpec.describe Fixably::User do
  include_examples("a resource", "user", "users", %i[show])
end
