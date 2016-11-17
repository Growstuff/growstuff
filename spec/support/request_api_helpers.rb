# frozen_string_literal: true
module RequestApiSpecHelpers
  def verify_response_headers(headers)
    expect(headers["Content-Type"]).to include("application/vnd.api+json")
  end

  def verify_data_key_in_json(response_body)
    parsed_body = JSON.parse(response_body)
    expect(parsed_body).to have_key("data")
  end

  def jsonapi_request_headers
    {
      'Content-type' => JSONAPI::MEDIA_TYPE,
      'Accept' => JSONAPI::MEDIA_TYPE
    }
  end
end
