class ApplicationController < ActionController::API
  before_action :authenticate!

  rescue_from ActiveRecord::RecordNotFound,    with: :not_found
  rescue_from ActiveRecord::RecordInvalid,     with: :unprocessable
  rescue_from GeolocationProviders::InvalidInput,  with: :bad_request
  rescue_from GeolocationProviders::NotFoundError, with: :unprocessable
  rescue_from GeolocationProviders::NetworkError,  with: :service_unavailable
  rescue_from GeolocationProviders::ProviderError, with: :unprocessable

  private

  def authenticate!
    token = request.headers["X-Api-Key"]
    render_error("401", "Unauthorized", "Invalid or missing API key", :unauthorized) unless valid_token?(token)
  end

  def valid_token?(token)
    return false if token.blank?

    expected = ENV["API_KEY"]
    return false if expected.blank?

    ActiveSupport::SecurityUtils.secure_compare(token, expected)
  end

  def render_error(status_code, title, detail, http_status)
    render json: {
      errors: [{ status: status_code, title: title, detail: detail }]
    }, status: http_status
  end

  def not_found(e)
    render_error("404", "Not Found", e.message, :not_found)
  end

  def unprocessable(e)
    render_error("422", "Unprocessable Entity", e.message, :unprocessable_entity)
  end

  def bad_request(e)
    render_error("400", "Bad Request", e.message, :bad_request)
  end

  def service_unavailable(e)
    render_error("503", "Service Unavailable", e.message, :service_unavailable)
  end
end
