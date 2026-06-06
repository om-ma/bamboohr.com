module GeolocationProviders
  Error         = Class.new(StandardError)
  NetworkError  = Class.new(Error)
  NotFoundError = Class.new(Error)
  InvalidInput  = Class.new(Error)
  ProviderError = Class.new(Error)
end
