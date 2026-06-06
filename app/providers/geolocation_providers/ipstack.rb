require "net/http"
require "resolv"

module GeolocationProviders
  class Ipstack < Base
    BASE_URL = "http://api.ipstack.com"

    def initialize(api_key: ENV.fetch("IPSTACK_API_KEY", nil))
      @api_key = api_key
    end

    def fetch(ip_or_url)
      raise GeolocationProviders::InvalidInput, "IPSTACK_API_KEY is not configured" if @api_key.blank?

      ip = resolve_to_ip(ip_or_url)
      original_url = ip?(ip_or_url) ? nil : ip_or_url

      data = request(ip)
      normalize(data, original_url: original_url)
    end

    private

    def request(ip)
      uri = URI("#{BASE_URL}/#{ip}?access_key=#{@api_key}")
      response = Net::HTTP.get_response(uri)

      raise GeolocationProviders::NetworkError, "HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      parsed = JSON.parse(response.body)

      if parsed["success"] == false
        code = parsed.dig("error", "code")
        info = parsed.dig("error", "info") || "Unknown provider error"
        raise error_for_code(code, info)
      end

      parsed
    rescue JSON::ParserError
      raise GeolocationProviders::NetworkError, "Invalid JSON response from provider"
    rescue Errno::ECONNREFUSED, SocketError, Net::OpenTimeout, Net::ReadTimeout => e
      raise GeolocationProviders::NetworkError, "Provider unreachable: #{e.message}"
    end

    def normalize(data, original_url:)
      {
        ip:             data["ip"],
        url:            original_url,
        continent_code: data["continent_code"],
        continent_name: data["continent_name"],
        country_code:   data["country_code"],
        country_name:   data["country_name"],
        region_code:    data["region_code"],
        region_name:    data["region_name"],
        city:           data["city"],
        zip:            data["zip"],
        latitude:       data["latitude"],
        longitude:      data["longitude"]
      }
    end

    def error_for_code(code, info)
      case code
      when 101, 102, 103 then GeolocationProviders::InvalidInput.new(info)
      when 404            then GeolocationProviders::NotFoundError.new(info)
      else                     GeolocationProviders::ProviderError.new(info)
      end
    end
  end
end
