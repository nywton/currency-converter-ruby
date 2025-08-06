## ExchangeRateProvider

A Ruby client for fetching exchange rates from CurrencyAPI ([https://app.currencyapi.com](https://app.currencyapi.com)).

---

## Prerequisites

* Ruby 3.x
* A CurrencyAPI account (signup at [https://app.currencyapi.com](https://app.currencyapi.com))
* Your API key from the CurrencyAPI dashboard

---

## Installation

1. Clone this repository or copy the `lib/exchange_rate_provider.rb` file into your project:

   ```bash
   git clone https://github.com/nywton/currency-converter-ruby
   cd currency-converter-ruby

   # checkout to the branch
   git checkout nywton_barros
   ```
2. Ensure you have Bundler installed and install the dependencies:

   ```bash
   gem install bundler

   bundle install
   ```
---

## Configuration

1. Visit the CurrencyAPI dashboard to retrieve your API key:

   ```bash
   # Open in browser:
   https://app.currencyapi.com/dashboard
   ```

2. Export your API key as an environment variable:

   ```bash
   export CURRENCY_API_KEY="your_actual_currencyapi_key_here"
   ```
---

## Running

```bash
# ensure you have exported your API key
irb -r './lib/exchange_rate_provider.rb'

# Gets the latest EUR, BRL and JPY exchange rates in USD (USD/EUR, USD/BRL, USD/JPY)
ExchangeRateProvider.new.latest(targets: ['EUR', 'BRL', 'JPY'])
# => {"BRL" => 5.501471065, "EUR" => 0.8634201726, "JPY" => 147.5063664226}
```
---

## Usage

```ruby
require_relative 'lib/exchange_rate_provider'

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

## Testing

We use RSpec for unit tests. Ensure you have the `rspec` gem installed:

Run the full test suite:

```bash
rspec
```

Or if you want run guard:

```bash
bundle exec guard
```

A sample spec file lives at `spec/lib/fixtures/requests/currencyapi/get_latest_currency.json`, representing the response from the CurrencyAPI.

---
