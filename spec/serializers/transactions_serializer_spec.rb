require "rails_helper"

RSpec.describe TransactionsSerializer do
  let(:transaction) do
    create(:transaction,
      from_currency: "USD",
      to_currency:   "BRL",
      from_value:    BigDecimal("100.00"),
      to_value:      BigDecimal("550.00"),
      rate:          BigDecimal("5.5000"))
  end

  describe "#as_json" do
    subject(:json) { described_class.new(transaction).as_json }

    it "renders the expected keys" do
      expect(json.keys).to match_array(%i[
        transaction_id user_id from_currency to_currency
        from_value to_value rate timestamp
      ])
    end

    it "renders numeric fields as numbers with expected scales" do
      expect(json[:from_value]).to eq(100.0)
      expect(json[:to_value]).to eq(550.0)
      expect(json[:rate]).to eq(5.5)
      expect(json[:from_value]).to be_a(Float)
      expect(json[:to_value]).to be_a(Float)
      expect(json[:rate]).to be_a(Float)
    end

    it "renders identifiers and currencies correctly" do
      expect(json[:transaction_id]).to eq(transaction.id)
      expect(json[:user_id]).to eq(transaction.user_id)
      expect(json[:from_currency]).to eq("USD")
      expect(json[:to_currency]).to eq("BRL")
    end

    it "renders ISO8601 timestamp" do
      expect(json[:timestamp]).to eq(transaction.created_at.iso8601)
    end
  end

  describe ".collection" do
    it "serializes an array of records" do
      records = create_list(:transaction, 3)
      out = described_class.collection(records)
      expect(out).to be_an(Array)
      expect(out.size).to eq(3)
      expect(out.first).to include(:transaction_id, :user_id, :from_value, :timestamp)
    end
  end
end
