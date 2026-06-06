class Geolocation < ApplicationRecord
  IP_REGEX = /\A(\d{1,3}\.){3}\d{1,3}\z|\A([0-9a-fA-F]{0,4}:){2,7}[0-9a-fA-F]{0,4}\z/

  validates :ip, presence: true, uniqueness: true
  validates :ip, format: { with: IP_REGEX, message: "must be a valid IP address" }, allow_blank: true

  scope :by_ip_or_url, ->(value) {
    where(ip: value).or(where(url: value)).limit(1)
  }

  def self.find_by_ip_or_url(value)
    by_ip_or_url(value).first
  end
end
