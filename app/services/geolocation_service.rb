class GeolocationService
  def initialize(provider: GeolocationProviders::Ipstack.new)
    @provider = provider
  end

  def fetch_and_store(ip_or_url)
    data = @provider.fetch(ip_or_url)
    geolocation = Geolocation.find_or_initialize_by(ip: data[:ip])
    geolocation.assign_attributes(data)
    geolocation.save!
    geolocation
  end
end
