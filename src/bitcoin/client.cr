require "json"
require "http/client"
require "./rpc"

module Bitcoin
  class Client
    class Error < Exception
    end

    def initialize(rpc_password, host = "localhost", port = 8332)
      @client = HTTP::Client.new(host, port)
      @client.basic_auth("", rpc_password)
    end

    {% for request in RPC::Requests.constants %}
      # See `RPC::Requests::{{request}}`
      def {{request.stringify.underscore.id}}(*args)
        request_body = RPC::Requests::{{request}}.new(*args).to_json
        @client.post("/", body: request_body) do |response|
          response = RPC::Requests::{{request}}::Response.from_json(
            response.body_io.not_nil!
          )

          result, error = { response.result, response.error }
          raise Error.new(error.message) if error && !result
          result
        end
      end
    {% end %}
  end
end
