module Api
  module V1
    class GeolocationsController < ApplicationController
      before_action :set_geolocation, only: [:show, :destroy]

      def index
        geolocations = Geolocation.order(created_at: :desc)
        render json: GeolocationSerializer.new(geolocations).serializable_hash
      end

      def show
        render json: GeolocationSerializer.new(@geolocation).serializable_hash
      end

      def create
        ip_or_url = params.dig(:data, :attributes, :ip_or_url).to_s.strip

        if ip_or_url.blank?
          return render_error("400", "Bad Request", "data.attributes.ip_or_url is required", :bad_request)
        end

        geolocation = GeolocationService.new.fetch_and_store(ip_or_url)
        render json: GeolocationSerializer.new(geolocation).serializable_hash, status: :created
      end

      def destroy
        @geolocation.destroy!
        head :no_content
      end

      private

      def set_geolocation
        value = CGI.unescape(params[:ip_or_url])
        @geolocation = Geolocation.find_by_ip_or_url(value)
        render_error("404", "Not Found", "Geolocation not found for '#{value}'", :not_found) unless @geolocation
      end
    end
  end
end
