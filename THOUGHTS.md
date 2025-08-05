# Currency Converter

## What I’m trying to solve
- Conversion between currencies
- `POST /convert?from_currency=USD&to_currency=BRL`
- from_currency: BRL, USD, EUR, JPY
- to_currency: BRL, USD, EUR, JPY

- Example:
```json
{
  "transaction_id": 42,
  "user_id": 123,
  "from_currency": "USD",
  "to_currency": "BRL",
  "from_value": 100,
  "to_value": 525.32,
  "rate": 5.2532,
  "timestamp": "2024-05-19T18:00:00Z"
}
```
- **Store user transactions**
GET /transactions?user_id=123
- **Caching**  
Store recent rates so we don’t fetch the same data over and over.  
- **Currency validation**  
Only allow BRL, USD, EUR, JPY (and reject anything else).  

## Solutions

There are a couple of ways to solve this problem. For instace:

1. We can simplely foward the request to the currency api with some validations. 
Passing directly the `from` and `to` currencies.

```bash
curl -G "https://api.currencyapi.com/v3/latest" \
-d "apikey=YOUR_API_KEY" \
-d "base_currency=BRL" \
-d "currencies=USD,EUR,JPY"
```
2. We can store the rates in a hash and use them to calculate the conversion. 
So we don’t need to call the api every time. Since the currencies probably changes once a day, 
we can store the rates in a cache.

## Conversion formula (using USD as pivot)

```ruby
# Define rates relative to 1 USD
RATES = {
    'BRL' => 5.5073808762,   # 1 USD = 5.50738 BRL
    'EUR' => 0.8630801178,   # 1 USD = 0.86308 EUR
    'JPY' => 146.767703476,  # 1 USD = 146.76770 JPY
    'USD' => 1.0
}

def convert(amount, from:, to:, rates: RATES)
    amount * (rates[to] / rates[from])
end

# Examples
puts format("%.2f EUR", convert(100, from: 'BRL', to: 'EUR'))
# → 100 × (0.86308 / 5.50738) |  15.68 EUR

puts format("%.2f JPY", convert(50, from: 'EUR', to: 'JPY'))
# → 50 × (146.76770 / 0.86308) | 8503.71 JPY

````

* Example: 100 BRL → EUR ≈ 100 × (0.86308 / 5.50738) ≈ 15.68 EUR
* Example: 50 EUR → JPY ≈ 50 × (146.7677 / 0.86308) ≈ 8 503.71 JPY

## Fetching rates

```bash
curl -G "https://api.currencyapi.com/v3/latest" \
-d "apikey=YOUR_API_KEY" \
-d "base_currency=USD" \
-d "currencies=BRL,EUR,JPY,USD"
```

* Response includes a `last_updated_at` timestamp and a map of currency codes to values.
* To use a different base (e.g. BRL), just swap `base_currency=BRL` and request USD, EUR, JPY.

## Caching & invalidation

1. Store the full API response in cache (keyed by `base_currency`).
2. Compute TTL = `last_updated_at` + 1 day.
3. If it’s a weekend, extend TTL until Monday (markets are closed).
4. Why:
   * Avoid unnecessary calls when rates haven’t changed.
   * Keep things fresh during weekdays, but tolerate longer on weekends.

