require "./spec_helper"

describe Gemini do
  it "handle PROHIBITED_CONTENT error", tags: "error" do
    Gemini::GenerateContentResponse.from_json SAMPLES["prohibited_content_00"]

    raise "No error triggered"
  rescue ex : Gemini::MissingCandidatesException
    # puts "Rescued `Gemini::MissingCandidatesException` -- #{ex.message} -- Block Reason: #{ex.block_reason}"
    ex.block_reason.should eq Gemini::BlockReason::ProhibitedContent
  end

  it "handle finish reason by SAFETY error", tags: "error" do
    Gemini::GenerateContentResponse.from_json SAMPLES["finish_reason_safety_00"]

    raise "No error triggered"
  rescue ex : Gemini::MissingContentException
    # puts "Rescued `Gemini::MissingContentException` -- #{ex.message} -- Finish Reason: #{ex.finish_reason}"
    ex.finish_reason.should eq Gemini::FinishReason::Safety
  end

  it "bad request error", tags: "error" do
    begin
      Gemini::GenerateContentResponse.from_json SAMPLES["bad_request_error_00"]
    rescue ex : JSON::SerializableError
      raise Gemini::BadResponseException.new "Can't parse JSON response", SAMPLES["bad_request_error_00"]
    end
  rescue ex : Gemini::BadResponseException
    ex.error.try &.code.should eq 400
    ex.error.try &.status.should eq "INVALID_ARGUMENT"
  end
end
