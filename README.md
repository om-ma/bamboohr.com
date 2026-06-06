# Geolocation API

A RESTful JSON API for storing and retrieving IP/URL geolocation data, backed by [ipstack.com](https://ipstack.com).

## Stack

- Ruby 3.4.2 / Rails 8.1 (API-only)
- SQLite3
- `jsonapi-serializer` (JSON API spec responses)
- RSpec + WebMock + FactoryBot (test suite)

---

## Quick Start

### 1. Prerequisites

- Ruby 3.4.2 (via RVM: `rvm use 3.4.2`)
- Bundler: `gem install bundler`
- An [ipstack.com](https://ipstack.com) API key (free tier works)

### 2. Clone & install

```bash
git clone https://github.com/om-ma/bamboohr.com.git
cd bamboohr.com
bundle install
```

### 3. Configure environment

```bash
cp .env.example .env
# edit .env and fill in IPSTACK_API_KEY and API_KEY
```

Then export them (or use a tool like `direnv`):

```bash
export IPSTACK_API_KEY=your_ipstack_key
export API_KEY=your_chosen_secret_key
```

### 4. Set up the database

```bash
bundle exec rails db:create db:migrate
```

### 5. Start the server

```bash
bundle exec rails server
# Listening on http://localhost:3000
```

### 6. Run the test suite

```bash
bundle exec rspec
```

---

## Authentication

All endpoints require the header:

```
X-Api-Key: <your API_KEY value>
```

---

## Endpoints

All responses follow the [JSON API](https://jsonapi.org) specification.

### List all geolocations

```
GET /api/v1/geolocations
```

### Get geolocation by IP or URL

```
GET /api/v1/geolocations/:ip_or_url
```

Examples:
```
GET /api/v1/geolocations/8.8.8.8
GET /api/v1/geolocations/google.com
```

### Add geolocation

Fetches data from ipstack and stores it.

```
POST /api/v1/geolocations
Content-Type: application/json

{
  "data": {
    "attributes": {
      "ip_or_url": "8.8.8.8"
    }
  }
}
```

Accepts an IP address or a hostname/URL. If a URL is provided it is resolved to an IP.

### Delete geolocation

```
DELETE /api/v1/geolocations/:ip_or_url
```

---

## Example session

```bash
# Store a geolocation
curl -X POST http://localhost:3000/api/v1/geolocations \
  -H "X-Api-Key: secret" \
  -H "Content-Type: application/json" \
  -d '{"data":{"attributes":{"ip_or_url":"8.8.8.8"}}}'

# Retrieve it by IP
curl http://localhost:3000/api/v1/geolocations/8.8.8.8 \
  -H "X-Api-Key: secret"

# Retrieve it by URL
curl http://localhost:3000/api/v1/geolocations/dns.google \
  -H "X-Api-Key: secret"

# Delete it
curl -X DELETE http://localhost:3000/api/v1/geolocations/8.8.8.8 \
  -H "X-Api-Key: secret"
```

---

## Response format

```json
{
  "data": {
    "id": "1",
    "type": "geolocation",
    "attributes": {
      "ip": "8.8.8.8",
      "url": null,
      "continent_code": "NA",
      "continent_name": "North America",
      "country_code": "US",
      "country_name": "United States",
      "region_code": "CA",
      "region_name": "California",
      "city": "Mountain View",
      "zip": "94035",
      "latitude": "37.386",
      "longitude": "-122.0838",
      "created_at": "2026-06-07T00:00:00.000Z",
      "updated_at": "2026-06-07T00:00:00.000Z"
    }
  }
}
```

Error responses use the JSON API errors format:

```json
{
  "errors": [
    {
      "status": "404",
      "title": "Not Found",
      "detail": "Geolocation not found for '9.9.9.9'"
    }
  ]
}
```

---

## Swapping the geolocation provider

The provider is injected via `GeolocationService`:

```ruby
GeolocationService.new(provider: MyOtherProvider.new)
```

To add a new provider, subclass `GeolocationProviders::Base` and implement `#fetch(ip_or_url)` returning a hash with keys matching the `Geolocation` model attributes. Then update `GeolocationService`'s default.

---

## Architecture

```
app/
  providers/
    geolocation_providers.rb          # module + error classes
    geolocation_providers/
      base.rb                         # abstract interface + shared helpers
      ipstack.rb                      # ipstack.com implementation
  services/
    geolocation_service.rb            # orchestrates fetch + persist
  controllers/
    application_controller.rb         # auth + error handlers
    api/v1/geolocations_controller.rb
  models/
    geolocation.rb
  serializers/
    geolocation_serializer.rb         # JSON API
spec/
  models/
  providers/
  services/
  requests/
```
