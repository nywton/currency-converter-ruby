# frozen_string_literal: true

require_relative '../../lib/exchange_rate_converter'

RSpec.describe ExchangeRateConverter do
  let(:rates) do
    {
      'USD' => 1.0,
      'EUR' => 2.0,
      'BRL' => 4.0,
      'JPY' => 8.0
    }
  end

  subject(:converter) { described_class.new(rates) }

  describe '#initialize' do
    it 'upcases all rate keys internally' do
      mixed_rates = { 'usD' => 1.0, 'BrL' => 4.0 }
      converter   = described_class.new(mixed_rates)

      stored = converter.instance_variable_get(:@rates)

      expect(stored).to eq({ 'USD' => 1.0, 'BRL' => 4.0 })
    end
  end

  describe '#convert' do
    context 'when converting from USD' do
      it 'converts 10 USD to EUR' do
        expect(converter.convert(10, base: 'USD', target: 'EUR')).to eq(20.0)
      end

      it 'converts 10 USD to BRL' do
        expect(converter.convert(10, base: 'USD', target: 'BRL')).to eq(40.0)
      end

      it 'converts 10 USD to JPY' do
        expect(converter.convert(10, base: 'USD', target: 'JPY')).to eq(80.0)
      end
    end

    context 'when converting from BRL' do
      it 'converts 10 BRL to USD' do
        expect(converter.convert(10, base: 'BRL', target: 'USD')).to eq(2.5)
      end

      it 'converts 10 BRL to EUR' do
        expect(converter.convert(10, base: 'BRL', target: 'EUR')).to eq(5.0)
      end

      it 'converts 10 BRL to JPY' do
        expect(converter.convert(10, base: 'BRL', target: 'JPY')).to eq(20.0)
      end
    end

    context 'when converting from EUR' do
      it 'converts 10 EUR to USD' do
        expect(converter.convert(10, base: 'EUR', target: 'USD')).to eq(5.0)
      end

      it 'converts 10 EUR to BRL' do
        expect(converter.convert(10, base: 'EUR', target: 'BRL')).to eq(20.0)
      end

      it 'converts 10 EUR to JPY' do
        expect(converter.convert(10, base: 'EUR', target: 'JPY')).to eq(40.0)
      end
    end

    context 'when converting from JPY' do
      it 'converts 10 JPY to USD' do
        expect(converter.convert(10, base: 'JPY', target: 'USD')).to eq(1.25)
      end

      it 'converts 10 JPY to BRL' do
        expect(converter.convert(10, base: 'JPY', target: 'BRL')).to eq(5.0)
      end

      it 'converts 10 JPY to EUR' do
        expect(converter.convert(10, base: 'JPY', target: 'EUR')).to eq(2.5)
      end
    end

    context 'with unknown currencies' do
      it 'raises ArgumentError for unknown base currency' do
        expect { converter.convert(10, base: 'XXX', target: 'USD') }
          .to raise_error(ArgumentError, /Unknown base currency/)
      end

      it 'raises ArgumentError for unknown target currency' do
        expect { converter.convert(10, base: 'USD', target: 'YYY') }
          .to raise_error(ArgumentError, /Unknown target currency/)
      end
    end
  end
end
