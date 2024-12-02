require "log"
require "json"
require "./gemini/**"

# Google Gemini API
module Gemini
  VERSION = "0.1.0"
  Log     = ::Log.for("gemini")

  class BadResponse < Exception
    getter error : Error?
    getter response : String

    def initialize(@message, @response, @cause = nil)
      try_parse_error
    end

    def try_parse_error
      @error = Error.from_json(response, root: "error")
      true
    rescue
      false
    end
  end

  class MissingCandidates < Exception
    property block_reason : BlockReason

    def initialize(@message, block_reason = nil, @cause = nil)
      @block_reason = block_reason || BlockReason::BlockReasonUnspecified
    end
  end

  class MissingContent < Exception
    property finish_reason : FinishReason

    def initialize(@message, finish_reason = nil, @cause = nil)
      @finish_reason = finish_reason || FinishReason::FinishReasonUnspecified
    end
  end
end
