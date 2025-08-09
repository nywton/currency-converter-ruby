require "rails_helper"

RSpec.describe Transactions::Create do
  describe "#commit_with" do
    let(:user_id)       { 42 }
    let(:from_currency) { "USD" }
    let(:to_currency)   { "BRL" }
    let(:from_value)    { "100.00" } # String on purpose; service should call #to_d
    let(:usd_rates)     { { "USD" => 1.0, "BRL" => 5.0 } }

    subject(:service) do
      described_class.new(
        user_id:       user_id,
        from_currency: from_currency,
        to_currency:   to_currency,
        from_value:    from_value
      )
    end

    let(:converter) { instance_double("RateConverter") }

    before do
      allow(RateConverter).to receive(:new)
        .with(usd_rates)
        .and_return(converter)

      allow(converter).to receive(:convert)
        .with(instance_of(BigDecimal), base: from_currency, target: to_currency)
        .and_return({ to_value: 500.0, rate: 5.0 })
    end

    context "when the transaction saves successfully" do
      let(:transaction_double) do
        instance_double(
          "Transaction",
          save: true,
          errors: instance_double("ActiveModel::Errors", full_messages: []),
        )
      end

      before do
        allow(Transaction).to receive(:new).with(
          hash_including(
            user_id:       user_id,
            from_currency: from_currency,
            to_currency:   to_currency,
            from_value:    instance_of(BigDecimal),
            to_value:      500.0,
            rate:          5.0,
          )
        ).and_return(transaction_double)
      end

      it "builds the converter with the given USD rates" do
        service.commit_with(usd_rates)
        expect(RateConverter).to have_received(:new).with(usd_rates)
      end

      it "converts using the given currencies and a BigDecimal value" do
        service.commit_with(usd_rates)
        expect(converter).to have_received(:convert)
          .with(instance_of(BigDecimal), base: "USD", target: "BRL")
      end

      it "persists a Transaction and assigns it to #transaction" do
        service.commit_with(usd_rates)
        expect(service.transaction).to eq(transaction_double)
      end

      it "returns self for method-chaining" do
        expect(service.commit_with(usd_rates)).to be(service)
      end

      it "does not add errors" do
        service.commit_with(usd_rates)
        expect(service.errors).to be_empty
        expect(service).to be_success
      end
    end

    context "when the transaction fails to save" do
      let(:transaction_errors) do
        instance_double("ActiveModel::Errors", full_messages: [ "Rate is invalid" ])
      end

      let(:transaction_double) do
        instance_double("Transaction", save: false, errors: transaction_errors)
      end

      before do
        allow(Transaction).to receive(:new).and_return(transaction_double)
      end

      it "collects the model error messages into #errors" do
        service.commit_with(usd_rates)
        expect(service.errors).to eq([ "Rate is invalid" ])
      end

      it "exposes the unsaved transaction and returns self" do
        result = service.commit_with(usd_rates)
        expect(result).to be(service)
        expect(service.transaction).to eq(transaction_double)
        expect(service).not_to be_success
      end
    end
  end

  describe "#success?" do
    it "is true when there are no errors" do
      service = described_class.allocate
      service.instance_variable_set(:@errors, [])
      expect(service.success?).to be(true)
    end

    it "is false when there are errors" do
      service = described_class.allocate
      service.instance_variable_set(:@errors, [ "oops" ])
      expect(service.success?).to be(false)
    end
  end
end
