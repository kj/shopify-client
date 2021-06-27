# frozen_string_literal: true

require 'faraday'
require 'json'
require 'timeout'

module ShopifyClient
  class BulkRequest
    OperationError = Class.new(Error)

    CanceledOperationError = Class.new(OperationError)
    ExpiredOperationError = Class.new(OperationError)
    FailedOperationError = Class.new(OperationError)
    ObsoleteOperationError = Class.new(OperationError)

    TimeoutError = Class.new(Error)

    class Operation
      # @param client [Client]
      # @param id [String]
      def initialize(client, id)
        @client = client
        @id = id
      end

      # Wait for the operation to complete, then download the JSONL result
      # data which is yielded as an {Enumerator} to the block. The data is
      # streamed and parsed line by line to limit memory usage.
      #
      # @param delay [Integer] delay between polling requests in seconds
      #
      # @yield [Enumerator<Hash>] yields each parsed line of JSONL
      #
      # @raise CanceledOperationError
      # @raise ExpiredOperationError
      # @raise FailedOperationError
      # @raise ObsoleteOperationError
      def call(delay: 1, &block)
        url = loop do
          status, url = poll

          case status
          when 'CANCELED'
            raise CanceledOperationError
          when 'EXPIRED'
            raise ExpiredOperationError
          when 'FAILED'
            raise FailedOperationError
          when 'COMPLETED'
            break url
          else
            sleep(delay)
          end
        end

        return if url.nil?

        begin
          file = Tempfile.new(mode: 0600)
          Faraday.get(url) do |request|
            request.options.on_data = ->(chunk, _) do
              file.write(chunk)
            end
          end
          file.rewind
          block.(Enumerator.new do |y|
            file.each_line { |line| y << JSON.parse(line) }
          end)
        ensure
          file.close
          file.unlink
        end
      end

      # Cancel the bulk operation.
      #
      # @raise ObsoleteOperationError
      # @raise TimeoutError
      def cancel
        begin
          @client.graphql(<<~QUERY)
            mutation {
              bulkOperationCancel(id: "#{@id}") {
                userErrors {
                  field
                  message
                }
              }
            }
          QUERY
        rescue Response::GraphQLClientError => e
          return if e.response.user_errors.message?([
            /cannot be canceled when it is completed/,
          ])

          raise e
        end

        poll_until(['CANCELED', 'COMPLETED'])
      end

      # Poll until operation status is met.
      #
      # @param statuses [Array<String>] to terminate polling on
      # @param timeout [Integer] in seconds
      #
      # @raise ObsoleteOperationError
      # @raise TimeoutError
      def poll_until(statuses, timeout: 60)
        Timeout.timeout(timeout) do
          loop do
            status, _ = poll

            break if statuses.any? { |expected_status| status == expected_status }
          end
        end
      rescue Timeout::Error
        raise TimeoutError, 'exceeded %s seconds polling for status %s' % [
          timeout,
          statuses.join(', '),
        ]
      end

      # @return [Array(String, String | nil)] the operation status and the
      #   download URL, or nil if the result data is empty
      private def poll
        op = @client.graphql(<<~QUERY).data['data']['currentBulkOperation']
          {
            currentBulkOperation {
              id
              status
              url
            }
          }
        QUERY

        raise ObsoleteOperationError if op['id'] != @id

        [
          op['status'],
          op['url'],
        ]
      end
    end

    # Create and start a new bulk operation via the GraphQL API. Any currently
    # running bulk operations are cancelled.
    #
    # @param client [Client]
    # @param query [String] the GraphQL query
    #
    # @return [Operation]
    #
    # @example
    #   bulk_request.(client, <<~QUERY).() do |products|
    #     {
    #       products {
    #         edges {
    #           node {
    #             id
    #             handle
    #           }
    #         }
    #       }
    #     }
    #   QUERY
    #     db.transaction do
    #       products.each do |product|
    #         db[:products].insert(
    #           id: product['id'],
    #           handle: product['handle'],
    #         )
    #       end
    #     end
    #   end
    def call(client, query)
      ShopifyClient.assert_api_version!('2019-10')

      op = client.graphql(<<~QUERY)['data']['currentBulkOperation']
        {
          currentBulkOperation {
            id
            status
            url
          }
        }
      QUERY

      case op&.fetch('status')
      when 'CANCELING'
        Operation.new(client, op['id']).poll_until(['CANCELED'])
      when 'CREATED', 'RUNNING'
        Operation.new(client, op['id']).cancel
      end

      id = client.graphql(<<~QUERY).data['data']['bulkOperationRunQuery']['bulkOperation']['id']
        mutation {
          bulkOperationRunQuery(
            query: """
              #{query}
            """
          ) {
            bulkOperation {
              id
            }
            userErrors {
              field
              message
            }
          }
        }
      QUERY

      Operation.new(client, id)
    end
  end
end
