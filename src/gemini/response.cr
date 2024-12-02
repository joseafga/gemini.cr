module Gemini
  # Response from the model supporting multiple candidate responses.
  #
  # See: https://ai.google.dev/api/generate-content#generatecontentresponse
  struct GenerateContentResponse
    include JSON::Serializable
    # Candidate responses from the model.
    getter candidates : Array(Candidate) = [] of Candidate

    # Returns the prompt's feedback related to the content filters.
    @[JSON::Field(key: "promptFeedback")]
    getter prompt_feedback : PromptFeedback = PromptFeedback.new

    # Metadata on the generation requests' token usage. *(Output only)*
    @[JSON::Field(key: "usageMetadata")]
    getter usage_metadata : UsageMetadata

    @[JSON::Field(key: "modelVersion")]
    getter model_version : String?

    # A quick accessor equivalent to `#candidates.first.content!.parts`
    def parts
      candidates.first.content.parts
    end

    # A quick accessor equivalent to `#candidates.first.content!.parts.first.text`
    def text
      io = IO::Memory.new
      parts.each &.text? do |text|
        io << text << '\n'
      end

      io.to_s.chomp
    end

    # Alias for `#text`
    def to_s
      text
    end

    def after_initialize
      raise MissingCandidates.new("Field `#candidates` is empty", prompt_feedback.block_reason) if @candidates.empty?
    end

    # A response candidate generated from the model.
    #
    # See: https://ai.google.dev/api/generate-content#candidate
    struct Candidate
      include JSON::Serializable
      # Generated content returned from the model. *(Output only)*
      getter! content : Gemini::Content

      # The reason why the model stopped generating tokens. *(Optional, Output only)*
      # If empty, the model has not stopped generating tokens.
      @[JSON::Field(key: "finishReason")]
      getter finish_reason : FinishReason?

      # List of ratings for the safety of a response candidate.
      # There is at most one rating per category.
      @[JSON::Field(key: "safetyRatings")]
      getter safety_ratings : Array(SafetyRating) = [] of SafetyRating

      # Citation information for model-generated candidate. *(Output only)*
      # This field may be populated with recitation information for any text included in the content. These are passages
      # that are "recited" from copyrighted material in the foundational LLM's training data.
      # TODO: citationMetadata - object (CitationMetadata)

      # Token count for this candidate. *(Output only)*
      @[JSON::Field(key: "tokenCount")]
      getter token_count : Int32 = 0

      # *(Output only)*
      # TODO: avgLogprobs - number

      # Log-likelihood scores for the response tokens and top tokens *(Output only)*
      # TODO: logprobsResult - object (LogprobsResult)

      # Index of the candidate in the list of response candidates. *(Output only)*
      getter index : Int32 = 0

      def after_initialize
        raise MissingContent.new("Field `#content` is missing", finish_reason) if @content.nil?
      end
    end

    # A set of the feedback metadata the prompt specified in `Gemini::Content`.
    #
    # See: https://ai.google.dev/api/generate-content#PromptFeedback
    struct PromptFeedback
      include JSON::Serializable
      # If set, the prompt was blocked and no candidates are returned. *(Optional)*
      @[JSON::Field(key: "blockReason")]
      getter block_reason : BlockReason?

      # Ratings for safety of the prompt. There is at most one rating per category.
      @[JSON::Field(key: "safetyRatings")]
      getter safety_ratings : Array(SafetyRating) = [] of SafetyRating

      def initialize
      end
    end

    # Metadata on the generation request's token usage.
    #
    # See: https://ai.google.dev/api/generate-content#UsageMetadata
    struct UsageMetadata
      include JSON::Serializable
      # Number of tokens in the prompt. When cachedContent is set, this is still the total effective prompt size meaning
      # this includes the number of tokens in the cached content.
      @[JSON::Field(key: "promptTokenCount")]
      getter prompt_token_count : Int32

      # Number of tokens in the cached part of the prompt (the cached content)
      @[JSON::Field(key: "cachedContentTokenCount")]
      getter cached_content_token_count : Int32?

      # Total number of tokens across all the generated response candidates.
      @[JSON::Field(key: "candidatesTokenCount")]
      getter candidates_token_count : Int32?

      # Total token count for the generation request (prompt + response candidates).
      @[JSON::Field(key: "totalTokenCount")]
      getter total_token_count : Int32
    end
  end
end
