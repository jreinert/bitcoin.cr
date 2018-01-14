require "json"

module Bitcoin
  module RPC
    abstract struct Request(T)
      JSONRPC_VERSION = "2.0"
      JSON.mapping(
        jsonrpc: { type: String?, default: JSONRPC_VERSION },
        method: String,
        params: Array(T)
      )
    end

    struct Payment
      enum Category
        Send
        Receive
        Generate
        Immature
        Orphan
        Move
      end

      module EnumConverter(T)
        class Error < Exception
        end

        def self.from_json(parser)
          string = parser.read_string
          {% begin %}
          case string
          {% for option in T.constants %}
          when {{option.stringify.underscore}} then T::{{option}}
          {% end %}
          else raise Error.new("Invalid option: #{string}")
          end
          {% end %}
        end
      end

      enum Replacable
        Yes
        No
        Unknown
      end

      JSON.mapping(
        account: String,
        address: String?,
        category: { type: Category, converter: EnumConverter(Category) },
        amount: Float64,
        label: String?,
        vout: Int64?,
        fee: Float64?,
        confirmations: Int32?,
        trusted: Bool?,
        generated: Bool?,
        block_hash: { type: String?, key: "blockhash" },
        block_index: { type: Int64?, key: "blockindex" },
        block_time: {
          type: Time?,
          key: "blocktime",
          converter: Time::EpochConverter,
        },
        txid: String?,
        wallet_conflicts: {
          type: Array(String)?, key: "walletconflicts"
        },
        time: { type: Time, converter: Time::EpochConverter },
        time_received: {
          type: Time?, converter: Time::EpochConverter, key: "timereceived"
        },
        comment: String?,
        to: String?,
        other_account: { type: String?, key: "otheraccount" },
        bip125_replacable: {
          type: Replacable?, key: "bip125-replacable",
          converter: EnumConverter(Replacable)
        },
        abandoned: Bool?
      )

      def self.from_json(io)
      end
    end

    module Requests
      macro response(type)
        struct Response
          struct Error
            JSON.mapping(code: Int32, message: String)
          end

          JSON.mapping(result: {{type}}?, error: Error?)
        end
      end

      struct Balance < Request(String | Int32)
        def initialize(account : String = "", confirmations = 1)
          @method = "getbalance"
          @params = [account, confirmations]
        end

        Requests.response Float64
      end

      struct NewAddress < Request(String)
        def initialize(account : String = "")
          @method = "getnewaddress"
          @params = [account]
        end

        Requests.response String
      end

      struct ListTransactions < Request(String | Int32)
        def initialize(account : String = "", count : Int32 = 10, skip : Int32 = 0)
          @method = "listtransactions"
          @params = [account, count, skip]
        end

        Requests.response Array(Payment)
      end

      struct SendTo < Request(String | Float64 | Bool | Nil)
        def initialize(
          address : String, amount : Float64, comment : String? = nil,
          comment_to : String? = nil, subtract_fee : Bool = false
        )
          @method = "sendtoaddress"
          @params = [address, amount, comment, comment_to, subtract_fee]
        end

        Requests.response String
      end
    end
  end
end
