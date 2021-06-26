# frozen_string_literal: true

module ShopifyClient
  module Resource
    module Base
      module ClassMethods
        # Set the remote API resource name for the subclass. If a singular
        # is not provided, the plural will be used, without any trailing 's'.
        #
        # @param resource_plural [String, #to_s]
        # @param resource_singular [String, #to_s, nil]
        #
        # @example
        #   resource :orders
        #
        # @example
        #   resource :orders, :order
        def resource(name_plural, name_singular = nil)
          define_method(:resource_name) { name_plural.to_s }
          define_method(:resource_name_singular) do
            name_singular ? name_singular.to_s :  name_plural.to_s.sub(/s$/, '')
          end
        end
      end

      # @param base [Class]
      def self.included(base)
        base.extend(ClassMethods)
      end

      # @abstract Use {ClassMethods#resource} to implement (required)
      #
      # @return [String]
      def resource_name
        raise NotImplementedError
      end

      # @abstract Use {ClassMethods#resource} to implement (required)
      #
      # @return [String]
      def resource_name_singular
        raise NotImplementedError
      end
    end
  end
end
