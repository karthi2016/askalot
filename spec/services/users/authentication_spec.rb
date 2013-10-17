require 'spec_helper'

describe Users::Authentication do
  describe '#authorized?' do
    it 'validates user authorization' do
      params  = { login: 'user', password: 'password' }
      service = double(:service)

      authorization = Users::Authentication.new(service, params)

      expect(service).to receive(:authenticate).with('user', 'password').and_return(double.as_null_object)

      expect(authorization).to be_authorized
    end
  end

  describe '#create_user!' do
    it 'creates user with session' do
      pending
    end
  end
end
