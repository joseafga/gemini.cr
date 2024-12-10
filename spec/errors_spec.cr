require "./spec_helper"

describe Gemini do
  it "exception by block reason: PROHIBITED_CONTENT", tags: "error" do
    ex = expect_raises(Gemini::MissingCandidatesException) do
      Gemini::GenerateContentResponse.from_json Samples.load_json("prohibited_content_00")
    end

    ex.block_reason.should eq Gemini::BlockReason::ProhibitedContent
  end

  it "exception by finish reason: SAFETY", tags: "error" do
    ex = expect_raises(Gemini::MissingContentException) do
      Gemini::GenerateContentResponse.from_json Samples.load_json("finish_reason_safety_00")
    end

    ex.finish_reason.should eq Gemini::FinishReason::Safety
  end

  it "bad response by invalid argument", tags: "error" do
    ex = expect_raises(Gemini::BadResponseException, "Invalid JSON payload received. Unknown name \"pars\" at 'system_instruction': Cannot find field.\nInvalid JSON payload received. Unknown name \"xyz\": Cannot find field.") do
      raise Gemini::BadResponseException.new "Can't parse JSON response", Samples.load_json("error_00")
    end

    ex.code.should eq 400
    ex.status.should eq "INVALID_ARGUMENT"
  end

  it "bad response by the service is currently unavailable", tags: "error" do
    ex = expect_raises(Gemini::BadResponseException, "The service is currently unavailable.") do
      raise Gemini::BadResponseException.new "Can't parse JSON response", Samples.load_json("error_01")
    end

    ex.code.should eq 503
    ex.status.should eq "UNAVAILABLE"
  end
end
