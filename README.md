# Geolocation API

A RESTful JSON API for storing and retrieving IP/URL geolocation data, backed by [ipstack.com](https://ipstack.com).

## Stack

- Ruby 3.4.2 / Rails 8.1 (API-only)
- SQLite3
- `jsonapi-serializer` (JSON API spec responses)
- `dotenv-rails` (local env variable loading)
- RSpec + WebMock + FactoryBot (test suite)

---

## Getting Started

### Prerequisites

- An [ipstack.com](https://ipstack.com) API key (free tier works)
- **Docker** — or Ruby 3.4.2 + Bundler if running locally without Docker

### 1. Clone the repo

```bash
git clone https://github.com/om-ma/bamboohr.com.git
cd bamboohr.com
```

### 2. Configure environment

```bash
cp .env.example .env
```

Open `.env` and fill in your values:

```bash
IPSTACK_API_KEY=your_ipstack_api_key_here
API_KEY=choose_a_strong_random_secret
```

---

## Option A — Run with Docker Compose (recommended)

No Ruby installation required.

```bash
docker compose up --build
```

That's it. The container will:
1. Install all gems
2. Create and migrate the database
3. Start the server on `http://localhost:3002`

**Run the test suite inside Docker:**

```bash
docker compose run --rm api bundle exec rspec
```

**Stop the server:**

```bash
docker compose down
```

---

## Option B — Run locally with Ruby

**Prerequisites:** Ruby 3.4.2 (e.g. via RVM: `rvm use 3.4.2`) and Bundler.

```bash
bundle install
bundle exec rails db:create db:migrate
bundle exec rails server
# Listening on http://localhost:3002
```

**Run the test suite:**

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

Fetches data from ipstack and stores it. Accepts an IP address or a hostname/URL — if a URL is given it is resolved to an IP first.

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

### Delete geolocation

```
DELETE /api/v1/geolocations/:ip_or_url
```

---

## Example session

```bash
# Store a geolocation by IP
curl -X POST http://localhost:3002/api/v1/geolocations \
  -H "X-Api-Key: your_api_key" \
  -H "Content-Type: application/json" \
  -d '{"data":{"attributes":{"ip_or_url":"8.8.8.8"}}}'

# Store a geolocation by URL
curl -X POST http://localhost:3002/api/v1/geolocations \
  -H "X-Api-Key: your_api_key" \
  -H "Content-Type: application/json" \
  -d '{"data":{"attributes":{"ip_or_url":"google.com"}}}'

# Retrieve by IP
curl http://localhost:3002/api/v1/geolocations/8.8.8.8 \
  -H "X-Api-Key: your_api_key"

# Retrieve by URL
curl http://localhost:3002/api/v1/geolocations/google.com \
  -H "X-Api-Key: your_api_key"

# List all
curl http://localhost:3002/api/v1/geolocations \
  -H "X-Api-Key: your_api_key"

# Delete
curl -X DELETE http://localhost:3002/api/v1/geolocations/8.8.8.8 \
  -H "X-Api-Key: your_api_key"
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

The provider is injected into `GeolocationService`:

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
