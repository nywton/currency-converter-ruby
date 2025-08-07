## Exchange Rate Converting
[![CI](https://github.com/nywton/currency-converter-ruby/actions/workflows/ci.yml/badge.svg)](https://github.com/nywton/currency-converter-ruby/actions/workflows/ci.yml)

# Currency Converter

A lightweight Rails app that fetches exchange rates from CurrencyAPI and caches them locally—enabling **unlimited conversions** without spending your API credits.

**Key Features**
- **Unlimited Calls**: All conversions use cached rates, so you never consume CurrencyAPI credits.
- **Simple REST API**:  
- **Full Currency Support**: Converts any currency available in CurrencyAPI.  


🔗 [Full currency list](https://currencyapi.com/docs/currency-list)

---
Made with 💚 for my friends at [Jaya.tech](https://jaya.tech/)


## Prerequisites

* Ruby 3.x
* A CurrencyAPI account (signup at [https://app.currencyapi.com](https://app.currencyapi.com))
* Your API key from the CurrencyAPI dashboard

---

## Configuration

#### 1. Clone this repository or copy the `lib/exchange_rate_provider.rb` file into your project:

```bash
 git clone https://github.com/nywton/currency-converter-ruby
 cd currency-converter-ruby

 # checkout to the branch
 git checkout nywton_barros
```

#### 2. Copy the example environment file

First, make a copy of the sample env file:

```bash
cp sample.env .env
````

#### 3. Visit the CurrencyAPI dashboard to retrieve your API key:

```bash
 # Open in browser:
 https://app.currencyapi.com/dashboard
```

Then open the newly created `.env` in your editor and set your `CURRENCY_API_KEY`:

```dotenv
CURRENCY_API_KEY="your_actual_currencyapi_key_here"
```

#### 4. (optional) Export your API key as an environment variable for local development:

```bash
export CURRENCY_API_KEY="your_actual_currencyapi_key_here"
```
---

**NOTE:** Currency API currently has limited free api calls. I will improve this by adding a cache layer to make poosible unlimited rate convertions in a day.

<img width="1351" height="405" alt="image" src="https://github.com/user-attachments/assets/4a94071e-c74b-4715-9782-71102d270682" />


## Install and Run

#### 2. Docker setup:

Spin up the app inside Docker (no local Ruby install needed):

```bash
# Build the image
docker compose build

# Start the app container
docker compose up web -d

# Run migrations
docker compose exec web bin/rails db:create db:migrate
   ```

#### 3. Local setup:
 Ensure you have `CURRENCY_API_KEY` set in your environment:

```bash
gem install bundler

bundle install

bin/rails db:create db:migrate
```
---

## Running Rails Server

#### 1. Docker:

```bash
# Build the image
docker-compose up web

# or
docker-compose run --rm --remove-orphans web bin/rails server -b 0.0.0.0 -p 3000
```
#### 2. Local:

```bash
bin/rails server -b 0.0.0.0 -p 3000
```
---

## Testing

We use RSpec for unit tests. Ensure you have the `rspec` gem installed:

Run the full test suite:

#### 1. Docker:

```bash
docker-compose run --rm --remove-orphans test
```

#### 2. Local:

```bash
bundle exec rspec
```

Or if you want run guard:

```bash
bundle exec guard
```

A sample spec file lives at `spec/lib/fixtures/requests/currencyapi/get_latest_currency.json`, representing the response from the CurrencyAPI.

---
## CLI Usage

* NOTE: Ensure you have `CURRENCY_API_KEY` set in your environment.

* NOTE: Each execution will count as api calls to CurrencyAPI.

### Fetching Rates from CurrencyAPI

The ExchangeRateProvider class can be used to fetch exchange rates from CurrencyAPI.

* You can use the `latest` method to fetch all rates for a given base currency.

* The following examples show how to use the ExchangeRateProvider class.

#### 1. Fetch all rates with Docker: (ensure you have `CURRENCY_API_KEY` set in your environment)

```bash
# Default base is USD
docker-compose run --rm --remove-orphans web bin/rails runner "puts ExchangeRateProvider.new.latest"
# => { "EUR" => 0.92, "BRL" => 5.50, ... }

# Fetch specific base and targets:
docker-compose run --rm web --remove-orphans bin/rails runner "puts ExchangeRateProvider.new.latest(base: 'BRL', targets: ['USD', 'EUR'])"
# => {"USD" => 0.1832108847, "EUR" => 0.1570722103}
```

#### 2. Fetch all rates with local Ruby:

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

#### 1. Convert amounts with Docker:

```bash
# Default base is USD. Convert 100 usd to brl:
docker-compose run --rm --remove-orphans web bin/rails runner "puts ExchangeRateConverter.new(ExchangeRateProvider.new.latest).convert(100, base: 'usd', target: 'brl')"
# => 550.1471065

# Convert specific base and target:
docker-compose run --rm --remove-orphans web bin/rails runner "puts ExchangeRateConverter.new(ExchangeRateProvider.new.latest).convert(100, base: 'brl', target: 'usd')"

# Run from fixtures:
```

#### 2. Convert amounts with local Ruby (irb):

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
