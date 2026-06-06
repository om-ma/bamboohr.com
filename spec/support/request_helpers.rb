module RequestHelpers
  def auth_headers
    { "X-Api-Key" => "test-api-key", "Content-Type" => "application/json" }
  end

  def json_response
    JSON.parse(response.body)
  end
end
