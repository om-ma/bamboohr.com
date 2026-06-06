module GeolocationProviders
  class Base
    # Fetches geolocation data for a given IP address or URL.
    # Returns a Hash with symbolized keys matching Geolocation attributes.
    def fetch(ip_or_url)
      raise NotImplementedError, "#{self.class} must implement #fetch"
    end

    private

    def ip?(value)
      value.match?(/\A(\d{1,3}\.){3}\d{1,3}\z/) ||
        value.match?(/\A([0-9a-fA-F]{0,4}:){2,7}[0-9a-fA-F]{0,4}\z/)
    end

    def resolve_to_ip(ip_or_url)
      return ip_or_url if ip?(ip_or_url)

      hostname = extract_hostname(ip_or_url)
      Resolv.getaddress(hostname)
    rescue Resolv::ResolvError => e
      raise GeolocationProviders::NotFoundError, "Cannot resolve '#{ip_or_url}': #{e.message}"
    rescue URI::InvalidURIError
      raise GeolocationProviders::InvalidInput, "Invalid URL: #{ip_or_url}"
    end

    def extract_hostname(url)
      uri = URI.parse(url.include?("://") ? url : "http://#{url}")
      uri.hostname || raise(URI::InvalidURIError)
    end
  end
end
