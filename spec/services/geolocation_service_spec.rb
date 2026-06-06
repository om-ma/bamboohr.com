require "rails_helper"

RSpec.describe GeolocationService do
  let(:provider) { instance_double(GeolocationProviders::Ipstack) }
  subject(:service) { described_class.new(provider: provider) }

  let(:provider_data) do
    {
      ip: "8.8.8.8",
      url: nil,
      continent_code: "NA",
      continent_name: "North America",
      country_code: "US",
      country_name: "United States",
      region_code: "CA",
      region_name: "California",
      city: "Mountain View",
      zip: "94035",
      latitude: 37.386,
      longitude: -122.0838
    }
  end

  describe "#fetch_and_store" do
    it "creates a new Geolocation record" do
      allow(provider).to receive(:fetch).with("8.8.8.8").and_return(provider_data)

      expect { service.fetch_and_store("8.8.8.8") }.to change(Geolocation, :count).by(1)

      geo = Geolocation.last
      expect(geo.ip).to eq("8.8.8.8")
      expect(geo.city).to eq("Mountain View")
    end

    it "updates an existing record for the same IP" do
      create(:geolocation, ip: "8.8.8.8", city: "Old City")
      allow(provider).to receive(:fetch).with("8.8.8.8").and_return(provider_data)

      expect { service.fetch_and_store("8.8.8.8") }.not_to change(Geolocation, :count)

      expect(Geolocation.find_by(ip: "8.8.8.8").city).to eq("Mountain View")
    end

    it "propagates provider errors" do
      allow(provider).to receive(:fetch).and_raise(GeolocationProviders::NotFoundError, "cannot resolve")

      expect { service.fetch_and_store("bad.invalid") }.to raise_error(GeolocationProviders::NotFoundError)
    end
  end
end
