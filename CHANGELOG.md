# Changelog

All notable changes to this project will be documented in this file.

Here’s the **English version** of your release notes:

---

## [1.0.0] – 2025-08-09

### Added

* **Logging for Currency Service** – `ExchangeRateProvider` now logs requests and responses, making debugging and monitoring easier.
* **Automatic Retries** – Added retry mechanism for currency API calls in case of temporary failures or error responses.
* **Transaction API Documentation** – Added detailed section on creating and listing transactions, including request/response examples.

### Changed

* Overall documentation updates with clearer descriptions and more complete examples.

### Technical

* Improved code structure for easier maintenance and testing.

---

## [0.3.0] – 2025-08-09

### Added

* **TransactionsController** for managing transactions (`create` actions).
* **TransactionsSerializer** for rendering single transaction details.
* **TransactionsSerializer.collection** helper for rendering lists of transactions.

### Changed

* Removed `Api::V1` namespace — all transaction routes are now accessible directly under `/transactions`.

## [0.2.0] – 2025-08-06

### Added

* Rails new app template with version 8.0.2

* Adds Docker support with docker-compose for development

* Updates CI to support Rails 8.0.2 and SQLite

### Changed

* Improved documentation

## [0.1.0] – 2025-08-06

### Added

* A single `CurrencyConverter` class for conversionerting between BRL, USD, EUR ,  JPY [and more](https://currencyapi.com/docs/currency-list)

### Fixed

* Better error messages on failed requests

---

### Quick Start

```ruby
require_relative 'lib/exchange_rate_provider'
require_relative 'lib/exchange_rate_converter'

# 1. fetch the current rates:
rates = exchangerateprovider.new.latest(base: 'usd', targets: %w[usd eur brl jpy])

# 2. instantiate the converter with the rates:
converter = exchangerateconverter.new(rates)

# 3. convert 100 usd to brl:
amount_in_brl = converter.convert(100, base: 'usd', target: 'brl')
# => 550.1471065
```
---

## \[0.0.1] - 2025-08-06

### Added

* **New class** `ExchangeRateProvider`
Fetches live rates from CurrencyAPI with a simple constructor:

  ```ruby
  provider = ExchangeRateProvider.new(
      http_client: Net::HTTP,           # injectable HTTP client
      api_key: 'your-api-key'           # or via ENV['CURRENCY_API_KEY']
  )
  ```
* **Easy usage**

  ```ruby
  provider.latest                # ⇒ { "USD"=>1.0, "EUR"=>0.92, … }
  provider.latest(targets: %w[EUR BRL])  # ⇒ { "EUR"=>0.92, "BRL"=>5.5 }
  ```
* **Built-in error messages** for:

  * 403 Forbidden → “please upgrade your plan”
  * 404 Not Found → “Endpoint not found”
  * 422 Validation errors → shows error details
  * 429 Rate limit → “Rate limit exceeded”
  * 5xx Server errors → “Server error <code>”
  * Network failures → “Network error: <message>”
