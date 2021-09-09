# frozen_string_literal: true

RSpec.describe Fixably::Status do
  include_examples(
    "a resource",
    "status",
    "statuses",
    %i[list show]
  )
end
