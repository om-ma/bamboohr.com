class GeolocationSerializer
  include JSONAPI::Serializer

  set_type :geolocation

  attributes :ip, :url,
             :continent_code, :continent_name,
             :country_code, :country_name,
             :region_code, :region_name,
             :city, :zip,
             :latitude, :longitude,
             :created_at, :updated_at
end
