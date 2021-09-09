# frozen_string_literal: true

module Fixably
  class Status < ApplicationResource
    actions %i[list show]

    has_one :custom, class_name: "fixably/status/custom"
    has_one :queue, class_name: "fixably/queue"

    class Custom < ApplicationResource; end
  end
end
