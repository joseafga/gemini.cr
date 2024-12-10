require "http/client"
require "mime/media_type"

module Gemini
  # Generates a model response given an input.
  #
  # [API Reference](https://ai.google.dev/api/generate-content#method:-models.generatecontent)
  class GenerativeModel
    include JSON::Serializable
    HEADERS = HTTP::Headers{"Content-Type" => "application/json"}

    # Developer set `system instruction(s)`. Currently, text only. *(Optional)*
    #
    # [API Reference](https://ai.google.dev/gemini-api/docs/system-instructions)
    @[JSON::Field(key: "systemInstruction")]
    property system_instruction : Content?

    # The content of the current conversation with the model. *(Required)*
    # For single-turn queries, this is a single instance. For multi-turn queries  like chat, this is a repeated field
    # that contains the conversation history and the latest request.
    property! contents : Array(Content) | Deque(Content) | Content

    # A list of Tools the Model may use to generate the next response. *(Optional)*
    property tools : Array(Tool)?

    # Tool configuration for any Tool specified in the request. Refer to the Function calling guide for a usage example.
    # *(Optional)*
    @[JSON::Field(key: "toolConfig")]
    property tool_config : ToolConfig?

    # A list of unique SafetySetting instances for blocking unsafe content. *(Optional)*
    @[JSON::Field(key: "safetySettings")]
    property safety_settings : Array(SafetySetting)?

    # Configuration options for model generation and outputs. *(Optional)*
    @[JSON::Field(key: "generationConfig")]
    property generation_config : GenerationConfig?

    # The name of the content [cached](https://ai.google.dev/gemini-api/docs/caching) to use as context to serve the
    # prediction. *(Optional)*
    @[JSON::Field(key: "cachedContent")]
    property cached_content : String?

    @[JSON::Field(ignore: true)]
    @endpoint : String

    # Configuration parameters are optional and non-initialized, so they must be defined later
    def initialize(
      model_name : String,
      @system_instruction = nil,
      @generation_config = nil,
      @safety_settings = nil,
      @tools = nil,
      @tool_config = nil,
      @cached_content = nil
    )
      @endpoint = "https://generativelanguage.googleapis.com/v1beta/models/#{model_name}:generateContent?key=#{Gemini.config.api_key}"
    end

    def generate_content(text : String) : GenerateContentResponse
      @contents = Content.new(text, role: :user)
      request
    end

    def generate_content(@contents) : GenerateContentResponse
      request
    end

    private def request
      Log.debug { "Requesting -> #{to_pretty_json}" }
      response = HTTP::Client.post @endpoint, body: to_json, headers: HEADERS
      content_type = MIME::MediaType.parse(response.headers["Content-Type"])

      case content_type.media_type
      when "application/json"
        Log.debug { "Received <- #{response.body}" }

        begin
          GenerateContentResponse.from_json response.body
        rescue ex : JSON::SerializableError
          raise Gemini::BadResponseException.new "Can't parse JSON response", response.body
        end
      else
        raise "Unknown Content-Type: #{content_type.media_type}"
      end
    end
  end

  # Configuration options for model generation and outputs.
  # Not all parameters are configurable for every model.
  #
  # [API Reference](https://ai.google.dev/api/generate-content#generationconfig)
  struct GenerationConfig
    include JSON::Serializable
    # Number of generated responses to return.
    @[JSON::Field(key: "candidateCount")]
    property candidate_count : Int32?

    # The set of character sequences (up to 5) that will stop output generation.
    # If specified, the API will stop at the first appearance of a stop sequence. The stop sequence will not be
    # included as part of the response.
    @[JSON::Field(key: "stopSequences")]
    property stop_sequences : Array(String)?

    # Controls the randomness of the output.
    # Values can range from `[0.0,1.0]`, inclusive. A value closer to `1.0` will produce responses that are more
    # varied and creative, while a value closer to `0.0` will typically result in more straightforward responses from
    # the model.
    property temperature : Float64?

    # The maximum number of tokens to include in a candidate.
    # If unset, this will default to output_token_limit specified in the model's specification.
    @[JSON::Field(key: "maxOutputTokens")]
    property max_output_tokens : Int32?

    # The maximum number of tokens to consider when sampling.
    # The model uses combined Top-k and nucleus sampling. Top-k sampling considers the set of top_k most probable
    # tokens. Defaults to 40.
    @[JSON::Field(key: "topK")]
    property top_k : Int32?

    # The maximum cumulative probability of tokens to consider when sampling.
    # The model uses combined Top-k and nucleus sampling.
    # Tokens are sorted based on their assigned probabilities so that only the most likely tokens are considered.
    # Top-k sampling directly limits the maximum number of tokens to consider, while Nucleus sampling limits number of
    # tokens based on the cumulative probability.
    @[JSON::Field(key: "topP")]
    property top_p : Float64?

    # Output response mimetype of the generated candidate text.
    # Supported mimetype:
    # * **text/plain**: (default) Text output.
    # * **application/json**: JSON response in the candidates.
    @[JSON::Field(key: "responseMimeType")]
    property response_mime_type : String?

    # Specifies the format of the JSON requested if response_mime_type is `application/json`.
    @[JSON::Field(key: "responseSchema")]
    property response_schema : Schema?

    # Presence penalty applied to the next token's logprobs if the token has already been seen in the response.
    # *(Optional)*
    # This penalty is binary on/off and not dependant on the number of times the token is used (after the first).
    # Use frequencyPenalty for a penalty that increases with each use.
    # A positive penalty will discourage the use of tokens that have already been used in the response, increasing the
    # vocabulary.
    # A negative penalty will encourage the use of tokens that have already been used in the response, decreasing the
    # vocabulary.
    @[JSON::Field(key: "presencePenalty")]
    property presence_penalty : Float64?

    # Frequency penalty applied to the next token's logprobs, multiplied by the number of times each token has
    # been seen in the response so far. *(Optional)*
    # A positive penalty will discourage the use of tokens that have already been used, proportional to the number of
    # times the token has been used: The more a token is used, the more dificult it is for the model to use that token
    # again increasing the vocabulary of responses.
    #
    # Caution: A negative penalty will encourage the model to reuse tokens proportional to the number of times the
    # token has been used. Small negative values will reduce the vocabulary of a response. Larger negative values will
    # cause the model to start repeating a common token until it hits the maxOutputTokens limit: "...the the the the
    # the...".
    @[JSON::Field(key: "frequencyPenalty")]
    property frequency_penalty : Float64?

    # If `true`, export the logprobs results in response. *(Optional)*
    @[JSON::Field(key: "responseLogprobs")]
    property? response_logprobs : Bool?

    # Only valid if `#responseLogprobs` is `true`. This sets the number of top logprobs to return at each decoding
    # step in the `Candidate#logprobs_result`. *(Optional)*
    @[JSON::Field(key: "logprobs")]
    property logprobs : Int32?

    def initialize(
      @candidate_count = nil,
      @stop_sequences = nil,
      @temperature = nil,
      @max_output_tokens = nil,
      @top_k = nil,
      @top_p = nil,
      @response_mime_type = nil,
      @response_schema = nil,
      @presence_penalty = nil,
      @frequency_penalty = nil,
      @response_logprobs = nil,
      @logprobs = nil
    )
    end
  end
end
