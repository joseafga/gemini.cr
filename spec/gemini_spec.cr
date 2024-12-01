require "./spec_helper"

describe Gemini do
  it "generate content" do
    model = Gemini::GenerativeModel.new("gemini-1.5-flash")
    response = model.generate_content("Explain how AI works")

    response.text.empty?.should be_false
  end

  it "generate content with configuration and force finish by max tokens" do
    config = Gemini::GenerationConfig.new(max_output_tokens: 1)
    model = Gemini::GenerativeModel.new("gemini-1.5-flash", generation_config: config)
    response = model.generate_content("Explain how AI works")

    response.text.empty?.should be_false
    response.candidates.first.finish_reason.should eq Gemini::FinishReason::MaxTokens
  end
end
