require "log"
require "json"
require "./gemini/**"

# Google Gemini API
#
# ```
# require "gemini"
#
# Gemini.configure do |config|
#   config.api_key = "GEMINI_API_KEY"
# end
#
# model = Gemini::GenerativeModel.new("gemini-1.5-flash")
# response = model.generate_content("Explain how AI works")
#
# puts response.text
# ```
module Gemini
  VERSION = "0.2.0"
  Log     = ::Log.for("gemini")

  class BadResponseException < Exception
    getter code : Int32?
    getter status : String?

    # The *message* is a fallback, after parsing json *message* will be replaced (or not).
    def initialize(@message, response, @cause = nil)
      try_parse_error JSON::PullParser.new(response)
    end

    def try_parse_error(pull)
      pull.read_begin_object
      pull.read_object_key # => "error"
      pull.read_object do |key|
        case key
        when "code"
          @code = pull.read?(Int32)
        when "status"
          @status = pull.read_string
        when "message"
          @message = pull.read_string
        end
      end
      pull.read_end_object
    rescue
    end
  end

  class MissingCandidatesException < Exception
    property block_reason : BlockReason

    def initialize(@message, block_reason = nil, @cause = nil)
      @block_reason = block_reason || BlockReason::BlockReasonUnspecified
    end
  end

  class MissingContentException < Exception
    property finish_reason : FinishReason

    def initialize(@message, finish_reason = nil, @cause = nil)
      @finish_reason = finish_reason || FinishReason::FinishReasonUnspecified
    end
  end
end
