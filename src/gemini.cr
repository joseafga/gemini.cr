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
    getter error : Error?
    getter response : String

    def initialize(@message, @response, @cause = nil)
      try_parse_error
    end

    def try_parse_error
      @error = Error.from_json(response, root: "error")
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
