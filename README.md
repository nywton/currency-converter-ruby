# Currency Converter
[![CI](https://github.com/nywton/currency-converter-ruby/actions/workflows/ci.yml/badge.svg)](https://github.com/nywton/currency-converter-ruby/actions/workflows/ci.yml)

A lightweight Rails app that fetches exchange rates from [CurrencyAPI](https://currencyapi.com/) and caches them, enabling **unlimited conversions** without spending your API credits.

**Key Features**

- **Unlimited Conversions**: Rates are cached and refreshed once daily, so regardless of how many conversions you perform, you’ll only consume CurrencyAPI credits once per day.

- **Simple REST API**:  
- **Full Currency Support**: Converts any currency available in CurrencyAPI.  


🔗 [Full currency list](https://currencyapi.com/docs/currency-list)

---
Made with 💚 for my friends at [Jaya.tech](https://jaya.tech/) intend to solve the challenge of currency conversion described in [INTRUCTIONS.md](./INSTRUCTIONS.md) file.

---
## Table of Contents

- [Currency Amount Limits](#currency-amount-limits)
- [Prerequisites](#prerequisites)
- [Configuration](#configuration)
- [Installation](#installation)
- [Running](#running)
- [Testing](#testing)
- [Session API](#session-api)
- [CLI Usage](#cli-usage)
  - [Fetching Rates from CurrencyAPI](#fetching-rates-from-currencyapi)
  - [Converting amounts](#converting-amounts)
- [ChangeLog](#changelog)

---

Here’s a shorter, more natural version of your architecture summary:

---

## **Key Architectural Decisions**

### **1. API-first with thin controllers**

* `Api::V1::TransactionsController` mainly orchestrates: delegates logic to services/concerns and returns JSON.
* **Trade-off:** more files, but clear separation of responsibilities.

### **2. Explicit domain service objects**

* `Transactions::Create` encapsulates the use case (convert, persist, handle errors).
* **Benefit:** high testability, isolated business logic;.

### **3. External API integration encapsulation**

* `ExchangeRateProvider` isolates the CurrencyAPI HTTP call and parsing.
* **Benefit:** easy mocking in tests; single point for timeouts/retries/logging.

### **4. Decoupling conversion logic from API integration**

* A dedicated converter (`ExchangeRateConverter` or equivalent) computes amounts/rates from given data.
* **Benefit:** conversion rules are independent from the data source.

### **5. Edge caching inside the app**

* `Rails.cache.fetch` with semantic keys (`exchange_rates:*`) and **end-of-day (EoD)** expiration.
* **Benefit:** reduces latency and API cost; avoids rate limits. Helps with **unlimited conversions**.
* Infra: **Solid Cache** (via `solid_cache_entries` table) in dev/prod.

### **6. Stateless JWT authentication**

* `before_action :require_authentication`, `current_user` resolved via token (secret in `Rails.configuration.x.jwt_secret`).
* **Benefit:** scales horizontally without session storage; works with mobile/web clients.
* **Config choice:** secret comes from **credentials/ENV** (12-factor compliant).

### **7. Monetary precision and validations**

* Use of `BigDecimal` and strict validations on value ranges/scale in `Transaction` (+ rounding).
* **Benefit:** accounting consistency; avoids floating-point errors.

### **8. Cross-controller concerns**

* `ExchangeRates` controller concern to expose `latest_exchange_rates` as a helper method.
* **Benefit:** reusable logic across controllers/views; avoids bloated controllers.

### **9. Comprehensive test coverage**

* Request specs (status/JSON), model specs (validations/precision), service specs (flow and error handling), and authentication helpers (JWT in tests).
* **Benefit:** safer refactoring; serves as living documentation of contracts.

### **10. Dedicated operational tasks**

* Rake tasks for transaction creation/seeding and related routines.
* **Benefit:** automation of repetitive or offline jobs; separates operational workflows from web traffic.

### **RateConverter – USD-based currency conversion**

* Converts amounts between any two currencies using USD-anchored rates.
* **Benefit:** Pure, reusable logic independent from API or caching, easy to test and swap data sources. Permits conversion of any currency from any currency.

## **Risks / Next Steps**

* Centralize **error handling and timeouts** in `ExchangeRateProvider` (consider circuit breaker/retry with jitter).

---

## Currency Amount Limits

Your `from_value` and `to_value` columns are now `decimal(18,2)` (16 integer digits, 2 fractional). Here’s what the extremes look like in a few common currencies:

| Currency         | Symbol | Maximum Value              | Minimum Value              |
|------------------|--------|----------------------------|----------------------------|
| US Dollar        | \$     | \$9 999 999 999 999 999.99  | -\$9 999 999 999 999 999.99 |
| Euro             | €      | €9 999 999 999 999 999.99   | -€9 999 999 999 999 999.99  |
| Japanese Yen     | ¥      | ¥9 999 999 999 999 999.99   | -¥9 999 999 999 999 999.99  |
| Brazilian Real   | R\$    | R\$9 999 999 999 999 999.99 | -R\$9 999 999 999 999 999.99 |

> **Note:**  
> - All `from_value`/`to_value` entries must fall within ±9 999 999 999 999 999.99.  
> - The `rate` column remains `decimal(18,4)` (14 integer digits, 4 fractional), so its range is 0.0001…99 999 999 999 999.9999.  

---

## Prerequisites

* Ruby 3.x
* A CurrencyAPI account (signup at [https://app.currencyapi.com](https://app.currencyapi.com))
* Your API key from the CurrencyAPI dashboard

---
## Configuration

1. Clone this repository or copy the `lib/exchange_rate_provider.rb` file into your project:

   ```bash
    git clone https://github.com/nywton/currency-converter-ruby
    cd currency-converter-ruby
   
    # checkout to the branch
    git checkout nywton_barros
   ```

2. Copy the example environment file

First, make a copy of the sample env file:

   ```bash
   cp sample.env .env
   ````

3. Visit the CurrencyAPI dashboard to retrieve your API key:

   ```bash
    # Open in browser:
    https://app.currencyapi.com/dashboard
   ```

Then open the newly created `.env` in your editor and set your `CURRENCY_API_KEY`:

```dotenv
CURRENCY_API_KEY="your_actual_currencyapi_key_here"
```

4. (optional) Export your API key as an environment variable for local development:

  ```bash
  export CURRENCY_API_KEY="your_actual_currencyapi_key_here"
  export JWT_SECRET_KEY="your_actual_jwt_secret_key_here"
  ```
---

**NOTE:** Currency API currently has limited free api calls. I will improve this by adding a cache layer to make possible unlimited rate convertions in a day.

<img width="1351" height="405" alt="image" src="https://github.com/user-attachments/assets/4a94071e-c74b-4715-9782-71102d270682" />


## Installation

2. Docker setup:

Spin up the app inside Docker (no local Ruby install needed):

   ```bash
   # Build the image
   docker compose build
   
   # Start the app container and run migrations
   docker compose up web
   
   # Run migrations (optional since the app is already running)
   docker compose exec web bin/rails db:setup

   ```

3. Local setup:

 Ensure you have `CURRENCY_API_KEY` and `JWT_SECRET` set in your environment:

   ```bash
   # Install dependencies
   gem install bundler && bundle install --jobs 4
   
   # Run create sqlite and run migrations (manually)
   bin/rails db:setup

   # Run tests
   bundle exec rspec
   ```
---

## Running

1. Docker:

   ```bash
   # Build the image
   docker compose up web

   # Run tests environment (bundle exec rspec)
   docker compose run --rm test
   
   # Stop the app container
   docker compose down
   ```
2. Local:

   ```bash
   bin/rails server -b 0.0.0.0 -p 3000
   ```

3. Useful Docker commands:

   ```bash
   # 1. Build the image
   docker compose build
   # (optional) Build from scratch (no cache)
   docker compose build --no-cache
   
   # 2. Run migrations and seeds
   docker compose exec web bin/rails db:setup
   # (optional) if there are no running containers
   docker compose run --rm web bin/rails db:setup
   
   # 3. Run tests
   # Run rspec --format documentation
   docker compose run --rm test
   # (optional) Run rspec without formatting
   docker compose run --rm test bundle exec rspec
   # (optional) Guard rspec
   docker compose run --rm test bundle exec guard
   
   # 4. Run rails server
   docker compose up web --remove-orphans
   
   # 5. Run rails console
   docker compose exec web bin/rails console
   # (optional) if there are no running containers
   docker compose run --rm web bin/rails console
   
   # 6. Stop the containers
   docker compose down
   # (optional) Stop & remove containers, networks, volumes and images
   docker compose down --rmi all --volumes --remove-orphans   
   ```

---

## Testing

We use RSpec for unit tests. Ensure you have the `rspec` gem installed:

Run the full test suite:

1. Docker:

   ```bash
   # rspec --format documentation
   docker compose run --rm test

   # bundle exec rspec
   docker compose run --rm test bundle exec rspec

   # bundle exec guard
   docker compose run --rm test bundle exec guard
   ```

2. Local:

   ```bash
   bundle exec rspec --format documentation
   ```

Or if you want run guard:

   ```bash
   bundle exec guard
   ```

A sample spec file lives at `spec/lib/fixtures/requests/currencyapi/get_latest_currency.json`, representing the response from the CurrencyAPI.

---
## Session API

Authenticate a user and obtain a JSON Web Token (JWT) for subsequent requests.

### Endpoint

```
POST api/v1/session
```

### Example Request with cURL

```bash
curl -X POST http://localhost:3000/api/v1/session \
  -H "Content-Type: application/json" \
  -d '{"email_address":"jane@example.com","password":"secret"}'
```

### Request Details

* **URL:** `http://localhost:3000/api/v1/session`
* **Headers:**

  * `Content-Type: application/json`
* **Body:**

  ```json
  {
    "email_address": "jane@example.com",
    "password": "secret"
  }
  ```

### Successful Response

* **Status:** `201 Created`
* **Body:**

  ```json
  {
    "token": "eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxLCJleHAiOjE3NTQ3MDEzNzR9.CfwA_v65OXetxtoooW9Ewa-2DAIS9CtwHdmtgfthX_I"
  }
  ```

### Error Responses

* **Status:** `401 Unauthorized`

* **Body:**

  ```json
  {
    "error": "Invalid credentials"
  }
  ```

* **Status:** `400 Bad Request` (missing parameters)

* **Body:**

  ```json
  {
    "error": "Missing email_address or password"
  }
  ```

---

## Transactions API

Create a new transaction record.

### Endpoint

```
POST api/v1/transactions
```

### Example Request with cURL

```bash
curl -X POST http://localhost:3000/api/v1/transactions \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
        "transaction": {
          "from_currency": "USD",
          "to_currency":   "BRL",
          "from_value": 100
        }
      }'
```

### Request Details

* **URL:** `http://localhost:3000/api/v1/transactions`
* **Headers:**

  * `Content-Type: application/json`
* **Body:**

  ```json
  {
    "transaction": {
      "user_id": 123,
      "from_currency": "USD",
      "to_currency": "BRL",
      "from_value": 100,
      "to_value": 525.32,
      "rate": 5.2532
    }
  }
  ```

### Successful Response

* **Status:** `201 Created`
* **Body:**

  ```json
  {
    "id": 987,
    "user_id": 123,
    "from_currency": "USD",
    "to_currency": "BRL",
    "from_value": 100.0,
    "to_value": 525.32,
    "rate": 5.2532,
    "timestamp": "2025-08-08T14:30:45.123Z"
  }
  ```

### Error Responses

* **Status:** `422 Unprocessable Entity`
  **Body:**

  ```json
  {
    "errors": [
      "From currency is not a supported currency code",
      "Rate must be greater than or equal to 0.0001"
    ]
  }
  ```

* **Status:** `400 Bad Request` (missing wrapper)
  **Body:**

  ```json
  {
    "error": "Missing transaction parameters"
  }
  ```

---

## CLI Usage

* NOTE: Ensure you have `CURRENCY_API_KEY` set in your environment.

* NOTE: Each execution will count as api calls to CurrencyAPI.

### Fetching Rates from CurrencyAPI

The ExchangeRateProvider class can be used to fetch exchange rates from CurrencyAPI.

* You can use the `latest` method to fetch all rates for a given base currency.

* The following examples show how to use the ExchangeRateProvider class.

1. Fetch all rates with Docker: (ensure you have `CURRENCY_API_KEY` set in your environment)

   ```bash
   # Default base is USD
   docker compose run --rm --remove-orphans web bin/rails runner "puts ExchangeRateProvider.new.latest"
   # => { "EUR" => 0.92, "BRL" => 5.50, ... }
   
   # Fetch specific base and targets:
   docker compose run --rm web --remove-orphans bin/rails runner "puts ExchangeRateProvider.new.latest(base: 'BRL', targets: ['USD', 'EUR'])"
   # => {"USD" => 0.1832108847, "EUR" => 0.1570722103}
   ```

2. Fetch all rates with local Ruby:

   ```ruby
   # in bash
   $ irb -r ./lib/exchange_rate_provider
   
   # in irb
   # 1. Instantiate the provider (uses Net::HTTP by default):
   provider = ExchangeRateProvider.new
   
   # 2. Fetch all rates (base USD):
   rates = provider.latest
   # => { "EUR" => 0.92, "BRL" => 5.50, ... }
   
   # 3. Fetch usd rates for specific targets:
   brl_rate = provider.latest(targets: 'BRL')
   # => { "BRL" => 5.50 }
   # 4. Fetch specific base and targets: (BRL/USD, BRL/EUR)
   provider.latest(base: 'BRL', targets: ['USD', 'EUR'])
   #=> {"EUR" => 0.1569435088, "USD" => 0.1817695646}
   ```

---
### Converting amounts

The ExchangeRateConverter class can be used to convert amounts using exchange rates fetched from CurrencyAPI.

* You can use the `convert` method to convert an amount from one currency to another.
* It makes possible to cache fetched rates to avoid making repeated requests to CurrencyAPI.
* The following examples show how to use the ExchangeRateConverter class.

1. Convert amounts with Docker:

   ```bash
   # Default base is USD. Convert 100 usd to brl:
   docker compose run --rm --remove-orphans web bin/rails runner "puts ExchangeRateConverter.new(ExchangeRateProvider.new.latest).convert(100, base: 'usd', target: 'brl')"
   # => 550.1471065
   
   # Convert specific base and target:
   docker compose run --rm --remove-orphans web bin/rails runner "puts ExchangeRateConverter.new(ExchangeRateProvider.new.latest).convert(100, base: 'brl', target: 'usd')"
   
   # Run from fixtures:
   ```

2. Convert amounts with local Ruby (irb):

this project also provides an `exchange_rate_converter` to perform amount conversions using fetched rates:

   ```ruby
   
   # in bash:
   $ irb
   
   # In irb:
   require_relative 'lib/exchange_rate_provider'
   require_relative 'lib/exchange_rate_converter'
   
   # 1. fetch the current rates:
   rates = ExchangeRateProvider.new.latest(base: 'usd', targets: %w[usd eur brl jpy])
   
   # 2. instantiate the converter with the rates:
   converter = ExchangeRateConverter.new(rates)
   
   # 3. convert 100 usd to brl:
   amount_in_brl = converter.convert(100, base: 'usd', target: 'brl')
   # => 550.1471065
   ```
---

## ChangeLog

For a detailed history of changes and version notes, please see the [CHANGELOG.md](./CHANGELOG.md) file.
