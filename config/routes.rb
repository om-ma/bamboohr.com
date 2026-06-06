Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :geolocations,
                only: [:index, :show, :create, :destroy],
                param: :ip_or_url,
                constraints: { ip_or_url: /[^\/]+/ }
    end
  end
end
