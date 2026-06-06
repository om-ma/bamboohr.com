require "rails_helper"

RSpec.describe Geolocation, type: :model do
  describe "validations" do
    subject { build(:geolocation) }

    it { is_expected.to validate_presence_of(:ip) }

    it "enforces uniqueness on ip" do
      create(:geolocation, ip: "5.5.5.5")
      duplicate = build(:geolocation, ip: "5.5.5.5")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:ip]).to include("has already been taken")
    end

    it "accepts a valid IPv4 address" do
      expect(build(:geolocation, ip: "8.8.8.8")).to be_valid
    end

    it "accepts a valid IPv6 address" do
      expect(build(:geolocation, ip: "2001:4860:4860:0000:0000:0000:0000:8888")).to be_valid
    end

    it "rejects an invalid IP" do
      expect(build(:geolocation, ip: "not-an-ip")).not_to be_valid
    end
  end

  describe ".find_by_ip_or_url" do
    let!(:record) { create(:geolocation, ip: "8.8.8.8", url: "dns.google") }

    it "finds by IP" do
      expect(Geolocation.find_by_ip_or_url("8.8.8.8")).to eq(record)
    end

    it "finds by URL" do
      expect(Geolocation.find_by_ip_or_url("dns.google")).to eq(record)
    end

    it "returns nil when not found" do
      expect(Geolocation.find_by_ip_or_url("9.9.9.9")).to be_nil
    end
  end
end
