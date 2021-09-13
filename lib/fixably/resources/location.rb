# frozen_string_literal: true

module Fixably
  class Location < ApplicationResource
    actions %i[list show]

    # TODO
    # has_many :deliveries
  end
end
