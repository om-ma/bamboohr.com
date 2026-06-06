FactoryBot.define do
  factory :geolocation do
    sequence(:ip) { |n| "1.2.3.#{n}" }
    url            { nil }
    continent_code { "EU" }
    continent_name { "Europe" }
    country_code   { "PL" }
    country_name   { "Poland" }
    region_code    { "14" }
    region_name    { "Mazovia" }
    city           { "Warsaw" }
    zip            { "00-001" }
    latitude       { 52.229771 }
    longitude      { 21.011590 }

    trait :with_url do
      url { "example.com" }
    end
  end
end
