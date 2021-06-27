# frozen_string_literal: true

module ShopifyClient
  module Resource
    module Read
      module ClassMethods
        # Set the default query params. Note that 'fields' may be passed as an
        # array of strings.
        #
        # @param params [Hash]
        #
        # @example
        #   default_params fields: 'id,tags'
        def default_params(params)
          define_method(:default_params) { params }
        end
      end

      # @param base [Class]
      def self.included(base)
        base.extend(ClassMethods)

        base.include(Base)
      end

      # @abstract Use {ClassMethods#default_params} to implement (optional)
      #
      # @return [Hash]
      def default_params
        {}
      end

      # Find a single result.
      #
      # @param client [Client]
      # @param id [Integer]
      # @param params [Hash]
      #
      # @return [Hash]
      def find_by_id(client, id, params = {})
        params = default_params.merge(params)

        client.get("#{resource_name}/#{id}", params).data[resource_name_singular]
      end

      # Find all results.
      #
      # @param client [Client]
      # @param params [Hash]
      #
      # @return [Enumerator<Hash>]
      #
      # @raise [ArgumentError] if 'fields' does not include 'id'
      def all(client, params = {})
        raise ArgumentError, 'missing id field' unless has_id?(params)

        Enumerator.new do |yielder|
          response = client.get(resource_name, params)

          loop do
            response.data[resource_name].each { |result| yielder << result }

            response = response.next_page || break
          end
        end
      end

      # @param params [Hash]
      #
      # @return [Boolean]
      private def has_id?(params)
        fields = params[:fields] || params['fields']

        return true if fields.nil?

        fields =~ /\bid\b/
      end
    end
  end
end
