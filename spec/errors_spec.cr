require "./spec_helper"

describe Gemini do
  it "exception by block reason: PROHIBITED_CONTENT", tags: "error" do
    ex = expect_raises(Gemini::MissingCandidatesException) do
      Gemini::GenerateContentResponse.from_json SAMPLES["prohibited_content_00"]
    end

    ex.block_reason.should eq Gemini::BlockReason::ProhibitedContent
  end

  it "exception by finish reason: SAFETY", tags: "error" do
    ex = expect_raises(Gemini::MissingContentException) do
      Gemini::GenerateContentResponse.from_json SAMPLES["finish_reason_safety_00"]
    end

    ex.finish_reason.should eq Gemini::FinishReason::Safety
  end

  it "bad response by invalid argument", tags: "error" do
    ex = expect_raises(Gemini::BadResponseException) do
      raise Gemini::BadResponseException.new "Can't parse JSON response", SAMPLES["error_00"]
    end

    ex.error.try &.code.should eq 400
    ex.error.try &.status.should eq "INVALID_ARGUMENT"
  end

  it "bad response by the service is currently unavailable", tags: "error" do
    ex = expect_raises(Gemini::BadResponseException) do
      raise Gemini::BadResponseException.new "Can't parse JSON response", SAMPLES["error_01"]
    end

    ex.error.try &.code.should eq 503
    ex.error.try &.status.should eq "UNAVAILABLE"
  end
end
