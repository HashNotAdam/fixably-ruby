# frozen_string_literal: true

module Fixably
  class Order < ApplicationResource
    actions %i[create list show]

    schema do
      string :internal_location
      boolean :is_draft
      string :reference
    end

    has_one :contact, class_name: "fixably/order/contact"
    has_one :customer, class_name: "fixably/customer"
    has_one :ordered_by, class_name: "fixably/customer"
    has_one :handled_by, class_name: "fixably/customer"

    has_many :lines, class_name: "fixably/order/line"
    has_many :notes, class_name: "fixably/order/note"
    has_many :tasks, class_name: "fixably/order/task"

    # TODO
    # has_one :device
    # has_one :location
    # has_one :queue
    # has_one :status
    # has_one :store

    ALLOWED_INTERNAL_LOCATIONS =
      %w[CUSTOMER DEALER_SHOP IN_TRANSIT SERVICE STORE].freeze

    validates(
      :internal_location,
      inclusion: {
        in: ALLOWED_INTERNAL_LOCATIONS,
        message: "should be one of " + # rubocop:disable Style/StringConcatenation
          ALLOWED_INTERNAL_LOCATIONS.to_sentence(last_word_connector: " or "),
      },
      allow_nil: true
    )

    class Contact < ApplicationResource
      schema do
        string :full_name
        string :company
        string :phone_number
        string :email_address
      end
    end

    class Line < ApplicationResource
      actions %i[list show]
    end

    class Note < ApplicationResource
      actions %i[create list show]

      ALLOWED_TYPES = %w[DIAGNOSIS INTERNAL ISSUE RESOLUTION].freeze

      validates(
        :type,
        inclusion: {
          in: ALLOWED_TYPES,
          message: "should be one of " \
                   "#{ALLOWED_TYPES.to_sentence(last_word_connector: " or ")}",
        }
      )

      schema do
        string :title
        string :text
        string :type
      end
    end

    class Task < ApplicationResource
      actions %i[list show update]

      # TODO
      # has_one :task

      def update
        raise "Updating order tasks has not been implemented"
      end
    end
  end
end
