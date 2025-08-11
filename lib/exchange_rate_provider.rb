require "httparty"
require "json"

class ExchangeRateProvider
  include HTTParty
  base_uri "https://api.currencyapi.com"

  RETRYABLE_CODES  = (500..599).to_a + [ 429 ]
  RETRYABLE_ERRORS = [
    SocketError, Timeout::Error, Errno::ECONNRESET,
    Net::OpenTimeout, Net::ReadTimeout
  ].freeze

  MAX_RETRIES     = 3
  RETRY_DELAY_SEC = 0.5

  def initialize(api_key: nil, version: "v3")
    raise "CURRENCY_API_KEY must be set" if api_key.blank?

    @base_params = { apikey: api_key }
    @version     = version
  end

  # Fetch latest exchange rates defaulting to USD
  # Returns Hash like { "USD" => 1.0, "BRL" => 5.0, ... }
  def latest(base: "USD", targets: nil)
    query = @base_params.dup
    query[:base_currency] = base.to_s.upcase
    query[:currencies]    = Array(targets).map(&:upcase).join(",") if targets
    path = "/#{@version}/latest"

    response = with_retries do |attempt|
      log_request(:get, path, query, attempt) { self.class.get(path, query: query) }
    end

    handle_http_errors!(response)
    parsed = parse_json!(response.body)
    rates  = extract_rates(parsed)
    filter_rates(rates, targets)
  rescue *RETRYABLE_ERRORS => e
    log_error(event: "currencyapi.network_error", error: e.class.name, message: e.message)
    raise "Network error: #{e.message}"
  end

  private

  def with_retries
    attempts = 0

    loop do
      attempts += 1
      begin
        resp = yield(attempts)

        if resp.respond_to?(:code) && RETRYABLE_CODES.include?(resp.code.to_i) && attempts <= MAX_RETRIES
          log_warn(event: "currencyapi.retry", attempt: attempts, http_code: resp.code)
          sleep RETRY_DELAY_SEC
          next
        end

        return resp
      rescue *RETRYABLE_ERRORS => e
        if attempts > MAX_RETRIES
          raise
        else
          log_warn(event: "currencyapi.retry", attempt: attempts, error: e.class.name, message: e.message)
          sleep RETRY_DELAY_SEC
          next
        end
      end
    end
  end

  def log_request(http_verb, path, query, attempt)
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    tagged do
      Rails.logger.info(
        event:   "currencyapi.request",
        verb:    http_verb.to_s.upcase,
        path:    path,
        query:   redact_apikey(query),
        attempt: attempt
      )

      resp = yield

      Rails.logger.info(
        event:       "currencyapi.response",
        path:        path,
        http_code:   resp.code,
        duration_ms: ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round
      )

      resp
    end
  end

  def tagged(&blk)
    if Rails.logger.respond_to?(:tagged)
      Rails.logger.tagged("ExchangeRateProvider", "CurrencyAPI", "v#{@version}", &blk)
    else
      yield
    end
  end

  def redact_apikey(query)
    query.merge(apikey: "[REDACTED]")
  end

  def handle_http_errors!(resp)
    code = resp.code.to_i
    return if code.between?(200, 299)

    case code
    when 403 then raise "Forbidden: please upgrade your plan"
    when 404 then raise "Endpoint not found"
    when 422 then raise_validation_error!(resp.body)
    when 429 then raise "Rate limit exceeded"
    when 500..599 then raise "Server error #{code}"
    else raise "HTTP error #{code}"
    end
  end

  def raise_validation_error!(body)
    error   = JSON.parse(body)
    type    = error.dig("error", "type")
    message = error.dig("error", "message")
    raise "Validation error (#{type}): #{message}"
  rescue JSON::ParserError
    raise "Validation error (422)"
  end

  def parse_json!(body)
    JSON.parse(body)
  rescue JSON::ParserError => e
    log_error(
      event:   "currencyapi.json_parse_error",
      error:   e.class.name,
      message: e.message,
      snippet: body.to_s[0, 200]
    )
    raise "Invalid JSON response"
  end

  def extract_rates(parsed_body)
    parsed_body.fetch("data").transform_values { |h| h.fetch("value") }
  end

  def filter_rates(rates, targets)
    return rates unless targets
    allowed = Array(targets).map(&:upcase)
    rates.slice(*allowed)
  end

  def log_warn(**payload)
    tagged { Rails.logger.warn(payload) }
  end

  def log_error(**payload)
    tagged { Rails.logger.error(payload) }
  end
end
