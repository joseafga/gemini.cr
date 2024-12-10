require "./spec_helper"

describe Gemini do
  # Quickstart
  it "generate content" do
    model = Gemini::GenerativeModel.new("gemini-1.5-flash")
    response = model.generate_content("Explain how AI works")

    response.text.empty?.should be_false
  end

  it "generate content with configuration and force finish by max tokens" do
    model = Gemini::GenerativeModel.new(
      "gemini-1.5-flash",
      generation_config: Gemini::GenerationConfig.new(
        candidate_count: 1,
        stop_sequences: ["x"],
        max_output_tokens: 1,
        temperature: 1.0
      )
    )
    response = model.generate_content("Explain how AI works")

    response.text.empty?.should be_false
    response.candidates.first.finish_reason.should eq Gemini::FinishReason::MaxTokens
  end

  # Currently have no intention of creating something like [ChatSession](https://ai.google.dev/gemini-api/docs/text-generation?lang=python#chat).
  # It should be something implemented at application level, for simple uses it is enough to use an `Array`.
  it "chatting" do
    model = Gemini::GenerativeModel.new("gemini-1.5-flash")

    # history
    chat = [
      Gemini::Content.new("Hello", role: :user),
      Gemini::Content.new("Great to meet you. What would you like to know?", role: :model),
    ]

    chat << Gemini::Content.new("I have 2 dogs in my house.", role: :user)
    response = model.generate_content(chat)
    chat << Gemini::Content.new(response.parts, role: :model)

    chat << Gemini::Content.new("How many paws are in my house?", role: :user)
    response = model.generate_content(chat)
    chat << Gemini::Content.new(response.parts, role: :model)

    response.text.empty?.should be_false
    chat.size.should eq 6
  end

  # TODO: citation API
  it "response with citation metadata" do
    response = Gemini::GenerateContentResponse.from_json Samples.load_json("citation_metadata_00")

    response.text.empty?.should be_false
    response.candidates.first.finish_reason.should eq Gemini::FinishReason::Stop
    response.usage_metadata.prompt_token_count.should eq 5
    response.usage_metadata.total_token_count.should eq 709
  end

  it "function calling" do
    func_found = false

    model = Gemini::GenerativeModel.new(
      "gemini-1.5-flash",
      tools: [Gemini::Tool.new([
        Gemini::FunctionDeclaration.new(
          "control_light",
          description: "Set the brightness and color temperature of a room light.",
          parameters: Gemini::Schema.new(
            type: :object,
            properties: {
              "brightness" => Gemini::Schema.new(
                type: :string,
                description: "Light level from 0 to 100. Zero is off and 100 is full brightness.",
              ),
              "color_temperature" => Gemini::Schema.new(
                type: :string,
                description: "Color temperature of the light.",
                format: "enum",
                enumeration: ["DAYLIGHT", "COOL", "WARM"]
              ),
            },
            required: ["brightness", "color_temperature"]
          )
        ),
      ])]
    )

    chat = [] of Gemini::Content
    chat << Gemini::Content.new("Dim the lights so the room feels cozy and warm.", role: :user)
    response = model.generate_content(chat)
    chat << Gemini::Content.new(response.parts, role: :model)

    # Check that you got the expected function callback.
    response.parts.each &.function_call? do |func_call|
      if func_call.name == "control_light"
        func_found = true
        color_temp = func_call.args.try &.["color_temperature"]

        ["DAYLIGHT", "COOL", "WARM"].should contain(color_temp)
      end
    end

    # Send the hypothetical API result back to the generative model.
    chat << Gemini::Content.new(
      Gemini::Part.new(Gemini::FunctionResponse.new(
        "control_light",
        JSON.parse %({"brightness": "30", "color_temperature": "warm"})
      )),
      role: :function
    )
    response = model.generate_content(chat)

    response.text.empty?.should be_false
    func_found.should be_true
  end
end
