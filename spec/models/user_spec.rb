require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'email normalization' do
    it 'downcases and strips the email_address on create' do
      user = User.create(email_address: ' Foo@Example.COM ', password: 'password')
      expect(user.email_address).to eq('foo@example.com')
    end

    it 'downcases and strips the email_address on update' do
      user = User.create(email_address: 'initial@example.com', password: 'password')
      user.update(email_address: ' Bar@Example.ORG ')
      expect(user.email_address).to eq('bar@example.org')
    end
  end

  describe 'password functionality' do
    let(:user) { User.create(email_address: 'test@example.com', password: 'secret123') }

    it 'generates a password_digest' do
      expect(user.password_digest).to be_present
    end

    it 'authenticates with the correct password' do
      expect(user.authenticate('secret123')).to eq(user)
    end

    it 'does not authenticate with an incorrect password' do
      expect(user.authenticate('wrongpass')).to be_falsey
    end

    it 'updates the password_digest when password is changed' do
      original_digest = user.password_digest
      user.update(password: 'newsecret')
      expect(user.password_digest).not_to eq(original_digest)
      expect(user.authenticate('newsecret')).to eq(user)
    end

    it 'does not authenticate with nil password' do
      expect(user.authenticate(nil)).to be_falsey
    end
  end

  describe 'validations' do
    it 'is invalid without a password' do
      user = User.new(email_address: 'test@example.com')
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("can't be blank")
    end

    it 'is valid when email_address and password are present' do
      user = User.new(email_address: 'user@example.com', password: 'password')
      expect(user).to be_valid
    end
  end
end
