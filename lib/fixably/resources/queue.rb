# frozen_string_literal: true

module Fixably
  class Queue < ApplicationResource
    actions %i[list show]

    has_many :statuses, class_name: "fixably/status"
  end
end
