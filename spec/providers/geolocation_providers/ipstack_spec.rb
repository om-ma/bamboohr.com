require "rails_helper"

RSpec.describe GeolocationProviders::Ipstack do
  subject(:provider) { described_class.new(api_key: "test_key") }

  let(:ip) { "134.201.250.155" }
  let(:ipstack_url) { "http://api.ipstack.com/#{ip}?access_key=test_key" }

  let(:success_payload) do
    {
      ip: ip,
      continent_code: "NA",
      continent_name: "North America",
      country_code: "US",
      country_name: "United States",
      region_code: "CA",
      region_name: "California",
      city: "Los Angeles",
      zip: "90012",
      latitude: 34.0655,
      longitude: -118.2405
    }.to_json
  end

  describe "#fetch with IP address" do
    before do
      stub_request(:get, ipstack_url).to_return(status: 200, body: success_payload, headers: { "Content-Type" => "application/json" })
    end

    it "returns normalized geolocation data" do
      result = provider.fetch(ip)

      expect(result[:ip]).to eq(ip)
      expect(result[:country_code]).to eq("US")
      expect(result[:city]).to eq("Los Angeles")
      expect(result[:latitude]).to eq(34.0655)
      expect(result[:url]).to be_nil
    end
  end

  describe "#fetch with URL" do
    let(:url) { "example.com" }

    before do
      allow(Resolv).to receive(:getaddress).with("example.com").and_return(ip)
      stub_request(:get, ipstack_url).to_return(status: 200, body: success_payload, headers: { "Content-Type" => "application/json" })
    end

    it "resolves the URL and stores the original URL" do
      result = provider.fetch(url)

      expect(result[:ip]).to eq(ip)
      expect(result[:url]).to eq("example.com")
    end
  end

  describe "error handling" do
    it "raises InvalidInput when API key is missing" do
      expect {
        described_class.new(api_key: nil).fetch(ip)
      }.to raise_error(GeolocationProviders::InvalidInput, /IPSTACK_API_KEY/)
    end

    it "raises NetworkError on HTTP failure" do
      stub_request(:get, ipstack_url).to_return(status: 500)

      expect { provider.fetch(ip) }.to raise_error(GeolocationProviders::NetworkError)
    end

    it "raises NetworkError on connection refused" do
      stub_request(:get, ipstack_url).to_raise(Errno::ECONNREFUSED)

      expect { provider.fetch(ip) }.to raise_error(GeolocationProviders::NetworkError, /unreachable/)
    end

    it "raises ProviderError on provider-level error" do
      error_payload = { success: false, error: { code: 999, info: "Something went wrong" } }.to_json
      stub_request(:get, ipstack_url).to_return(status: 200, body: error_payload)

      expect { provider.fetch(ip) }.to raise_error(GeolocationProviders::ProviderError, "Something went wrong")
    end

    it "raises InvalidInput on invalid API key (code 101)" do
      error_payload = { success: false, error: { code: 101, info: "Invalid API key" } }.to_json
      stub_request(:get, ipstack_url).to_return(status: 200, body: error_payload)

      expect { provider.fetch(ip) }.to raise_error(GeolocationProviders::InvalidInput, "Invalid API key")
    end

    it "raises NotFoundError when DNS resolution fails" do
      allow(Resolv).to receive(:getaddress).and_raise(Resolv::ResolvError, "no address")

      expect { provider.fetch("nonexistent.invalid") }.to raise_error(GeolocationProviders::NotFoundError, /Cannot resolve/)
    end

    it "raises NetworkError on invalid JSON response" do
      stub_request(:get, ipstack_url).to_return(status: 200, body: "not-json")

      expect { provider.fetch(ip) }.to raise_error(GeolocationProviders::NetworkError, /Invalid JSON/)
    end
  end
end
