## Module: ExchangeRateProvider

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

2. Ensure you have Bundler installed (optional):

   ```bash
   gem install bundler
   ```

3. If using Bundler, add to your `Gemfile`:

   ```ruby
   gem 'json'
   ```

   Then run:

   ```bash
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

## Usage

## Dockerfile (in progress...)

```ruby
require_relative 'lib/exchange_rate_provider'

# 1. Instantiate the provider (uses Net::HTTP by default):
provider = ExchangeRateProvider.new

# 2. Fetch all rates (base USD):
rates = provider.latest
# => { "EUR" => 0.92, "BRL" => 5.50, ... }

# 3. Fetch specific targets:
brl_rate = provider.latest(targets: 'BRL')
# => { "BRL" => 5.50 }

# 4. Fetch a single rate:
eur_to_jpy = provider.rate('EUR', 'JPY')
# => 158.23  (example value)
```

---

## Running

```bash
irb -r './lib/exchange_rate_provider.rb'
ExchangeRateProvider.new.latest
```

---

## Testing

We use RSpec for unit tests. Ensure you have the `rspec` gem installed:

Run the full test suite:

```bash
rspec
```

A sample spec file lives at `spec/lib/exchange_rate_provider_spec.rb`. The tests inject a fake HTTP client and verify:

* Successful parsing of rates
* Error handling on non-success HTTP status
* JSON parse errors
* Missing `data` key

---
