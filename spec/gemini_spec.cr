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
    response = Gemini::GenerateContentResponse.from_json SAMPLES["citation_metadata_00"]

    response.text.empty?.should be_false
    response.candidates.first.finish_reason.should eq Gemini::FinishReason::Stop
    response.usage_metadata.prompt_token_count.should eq 5
    response.usage_metadata.total_token_count.should eq 709
  end
end
