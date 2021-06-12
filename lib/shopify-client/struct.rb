# frozen_string_literal: true

module ShopifyClient
  class Struct < ::Struct
    # @param pp [PrettyPrint]
    def pretty_print(pp)
      pp.text(inspect)
    end
  end
end
