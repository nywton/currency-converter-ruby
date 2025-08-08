require 'rails_helper'

RSpec.describe Transaction, type: :model do
  subject { build(:transaction) }

  context 'with valid factory' do
    it { is_expected.to be_valid }
  end

  describe 'validations' do
    it 'requires from_currency' do
      subject.from_currency = nil
      subject.validate
      expect(subject.errors[:from_currency]).to include("can't be blank")
    end

    it 'rejects unsupported from_currency' do
      subject.from_currency = 'XYZ'
      subject.validate
      expect(subject.errors[:from_currency]).to include('XYZ is not a supported currency code')
    end

    it 'requires to_currency' do
      subject.to_currency = nil
      subject.validate
      expect(subject.errors[:to_currency]).to include("can't be blank")
    end

    it 'rejects unsupported to_currency' do
      subject.to_currency = 'ZZZ'
      subject.validate
      expect(subject.errors[:to_currency]).to include('ZZZ is not a supported currency code')
    end

    it 'rounds from_value to two decimal places on save' do
      transaction = create(:transaction, from_value: 1.123)
      expect(transaction.reload.from_value.to_s('F')).to eq('1.12')
    end

    it 'rounds to_value to two decimal places on save' do
      transaction = create(:transaction, from_value: 1.123, to_value: 3.987)
      expect(transaction.reload.to_value.to_s('F')).to eq('3.99')
    end

    it 'rounds rate to four decimal places on save' do
      transaction = create(:transaction, rate: 1.23456)
      expect(transaction.reload.rate.to_s('F')).to eq('1.2346')
    end

    it 'validates numericality for from_value' do
      subject.from_value = 'abc'
      subject.validate
      expect(subject.errors[:from_value]).to include('is not a number')
    end

    it 'validates numericality for to_value' do
      subject.to_value = 'abc'
      subject.validate
      expect(subject.errors[:to_value]).to include('is not a number')
    end

    it 'validates numericality for rate' do
      subject.rate = 'xyz'
      subject.validate
      expect(subject.errors[:rate]).to include('is not a number')
    end
  end

  describe 'timestamp and JSON' do
    let(:transaction) { create(:transaction) }

    it { expect(transaction.timestamp).to eq(transaction.created_at) }
    it { expect(transaction.as_json).to have_key('timestamp') }
  end
end
