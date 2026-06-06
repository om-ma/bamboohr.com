require "rails_helper"

RSpec.describe "Api::V1::Geolocations", type: :request do
  before { ENV["API_KEY"] = "test-api-key" }
  after  { ENV.delete("API_KEY") }

  let!(:geolocation) { create(:geolocation, ip: "8.8.8.8", url: "dns.google") }

  # ─── Authentication ─────────────────────────────────────────────────────────

  describe "authentication" do
    it "returns 401 when X-Api-Key header is missing" do
      get "/api/v1/geolocations"
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 when X-Api-Key is wrong" do
      get "/api/v1/geolocations", headers: { "X-Api-Key" => "wrong" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 when API_KEY env is not set" do
      ENV.delete("API_KEY")
      get "/api/v1/geolocations", headers: { "X-Api-Key" => "test-api-key" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ─── GET /api/v1/geolocations ───────────────────────────────────────────────

  describe "GET /api/v1/geolocations" do
    it "returns all geolocations" do
      get "/api/v1/geolocations", headers: auth_headers
      expect(response).to have_http_status(:ok)
      expect(json_response.dig("data")).to be_an(Array)
      expect(json_response["data"].length).to eq(1)
    end

    it "returns JSON API structure" do
      get "/api/v1/geolocations", headers: auth_headers
      record = json_response["data"].first
      expect(record["type"]).to eq("geolocation")
      expect(record["attributes"]).to include("ip", "country_code", "city")
    end
  end

  # ─── GET /api/v1/geolocations/:ip_or_url ───────────────────────────────────

  describe "GET /api/v1/geolocations/:ip_or_url" do
    it "returns geolocation by IP" do
      get "/api/v1/geolocations/8.8.8.8", headers: auth_headers
      expect(response).to have_http_status(:ok)
      expect(json_response.dig("data", "attributes", "ip")).to eq("8.8.8.8")
    end

    it "returns geolocation by URL" do
      get "/api/v1/geolocations/dns.google", headers: auth_headers
      expect(response).to have_http_status(:ok)
      expect(json_response.dig("data", "attributes", "ip")).to eq("8.8.8.8")
    end

    it "returns 404 for unknown IP" do
      get "/api/v1/geolocations/9.9.9.9", headers: auth_headers
      expect(response).to have_http_status(:not_found)
      expect(json_response["errors"].first["status"]).to eq("404")
    end

    it "returns 404 for unknown URL" do
      get "/api/v1/geolocations/unknown.example", headers: auth_headers
      expect(response).to have_http_status(:not_found)
    end
  end

  # ─── POST /api/v1/geolocations ──────────────────────────────────────────────

  describe "POST /api/v1/geolocations" do
    let(:provider) { instance_double(GeolocationProviders::Ipstack) }
    let(:provider_data) do
      {
        ip: "1.1.1.1", url: nil,
        continent_code: "OC", continent_name: "Oceania",
        country_code: "AU", country_name: "Australia",
        region_code: "QLD", region_name: "Queensland",
        city: "Brisbane", zip: "4000",
        latitude: -27.4679, longitude: 153.0278
      }
    end

    before do
      allow(GeolocationProviders::Ipstack).to receive(:new).and_return(provider)
      allow(provider).to receive(:fetch).with("1.1.1.1").and_return(provider_data)
    end

    it "creates a new geolocation record" do
      expect {
        post "/api/v1/geolocations",
             params: { data: { attributes: { ip_or_url: "1.1.1.1" } } }.to_json,
             headers: auth_headers
      }.to change(Geolocation, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_response.dig("data", "attributes", "ip")).to eq("1.1.1.1")
      expect(json_response.dig("data", "attributes", "city")).to eq("Brisbane")
    end

    it "returns 400 when ip_or_url is missing" do
      post "/api/v1/geolocations",
           params: { data: { attributes: {} } }.to_json,
           headers: auth_headers

      expect(response).to have_http_status(:bad_request)
      expect(json_response["errors"].first["status"]).to eq("400")
    end

    it "returns 400 on invalid input from provider" do
      allow(provider).to receive(:fetch).and_raise(GeolocationProviders::InvalidInput, "Invalid IP")

      post "/api/v1/geolocations",
           params: { data: { attributes: { ip_or_url: "not-an-ip" } } }.to_json,
           headers: auth_headers

      expect(response).to have_http_status(:bad_request)
    end

    it "returns 422 when DNS resolution fails" do
      allow(provider).to receive(:fetch).and_raise(GeolocationProviders::NotFoundError, "Cannot resolve")

      post "/api/v1/geolocations",
           params: { data: { attributes: { ip_or_url: "nonexistent.invalid" } } }.to_json,
           headers: auth_headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 503 when provider is unreachable" do
      allow(provider).to receive(:fetch).and_raise(GeolocationProviders::NetworkError, "Provider unreachable")

      post "/api/v1/geolocations",
           params: { data: { attributes: { ip_or_url: "1.1.1.1" } } }.to_json,
           headers: auth_headers

      expect(response).to have_http_status(:service_unavailable)
    end
  end

  # ─── DELETE /api/v1/geolocations/:ip_or_url ─────────────────────────────────

  describe "DELETE /api/v1/geolocations/:ip_or_url" do
    it "deletes a geolocation by IP" do
      expect {
        delete "/api/v1/geolocations/8.8.8.8", headers: auth_headers
      }.to change(Geolocation, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "deletes a geolocation by URL" do
      expect {
        delete "/api/v1/geolocations/dns.google", headers: auth_headers
      }.to change(Geolocation, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "returns 404 for unknown IP" do
      delete "/api/v1/geolocations/9.9.9.9", headers: auth_headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
