# frozen_string_literal: true

RSpec.describe Fixably::Queue do
  include_examples(
    "a resource",
    "queue",
    "queues",
    %i[list show]
  )
end
