# frozen_string_literal: true

module Fixably
  class User < ApplicationResource
    actions :show

    schema do
      integer :id
      string :first_name
      string :last_name
      string :email
      string :phone
    end
  end
end
