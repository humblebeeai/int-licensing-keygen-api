# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Role, type: :model do
  let(:account)  { create(:account) }
  let(:resource) { create(:user, account:) }

  # FIXME(ezekg) this isn't working with the default :role factory
  # it_behaves_like :accountable

  subject { resource.role }

  describe 'pattern matching' do
    context 'with admin role' do
      let(:resource) { create(:admin, account:) }

      it 'should pattern match with attribute hash' do
        expect((subject in name: 'user' | 'admin' | 'environment' | 'product' | 'license')).to be true
        expect((subject in name: 'user')).to be false
        expect((subject in name: 'admin')).to be true
        expect((subject in name: 'environment')).to be false
        expect((subject in name: 'product')).to be false
        expect((subject in name: 'license')).to be false
      end

      it 'should pattern match with role symbols' do
        expect((subject in Role(:user | :admin | :environment | :product | :license))).to be true
        expect((subject in Role(:user))).to be false
        expect((subject in Role(:admin))).to be true
        expect((subject in Role(:environment))).to be false
        expect((subject in Role(:product))).to be false
        expect((subject in Role(:license))).to be false
      end
    end

    context 'with user role' do
      let(:resource) { create(:user, account:) }

      it 'should pattern match with attribute hash' do
        expect((subject in name: 'user' | 'admin' | 'environment' | 'product' | 'license')).to be true
        expect((subject in name: 'user')).to be true
        expect((subject in name: 'admin')).to be false
        expect((subject in name: 'environment')).to be false
        expect((subject in name: 'product')).to be false
        expect((subject in name: 'license')).to be false
      end

      it 'should pattern match with role symbols' do
        expect((subject in Role(:user | :admin | :environment | :product | :license))).to be true
        expect((subject in Role(:user))).to be true
        expect((subject in Role(:admin))).to be false
        expect((subject in Role(:environment))).to be false
        expect((subject in Role(:product))).to be false
        expect((subject in Role(:license))).to be false
      end
    end

    context 'with environment role' do
      let(:resource) { create(:environment, account:) }

      it 'should pattern match with attribute hash' do
        expect((subject in name: 'user' | 'admin' | 'environment' | 'product' | 'license')).to be true
        expect((subject in name: 'user')).to be false
        expect((subject in name: 'admin')).to be false
        expect((subject in name: 'environment')).to be true
        expect((subject in name: 'product')).to be false
        expect((subject in name: 'license')).to be false
      end

      it 'should pattern match with role symbols' do
        expect((subject in Role(:user | :admin | :environment | :product | :license))).to be true
        expect((subject in Role(:user))).to be false
        expect((subject in Role(:admin))).to be false
        expect((subject in Role(:environment))).to be true
        expect((subject in Role(:product))).to be false
        expect((subject in Role(:license))).to be false
      end
    end

    context 'with product role' do
      let(:resource) { create(:product, account:) }

      it 'should pattern match with attribute hash' do
        expect((subject in name: 'user' | 'admin' | 'environment' | 'product' | 'license')).to be true
        expect((subject in name: 'user')).to be false
        expect((subject in name: 'admin')).to be false
        expect((subject in name: 'environment')).to be false
        expect((subject in name: 'product')).to be true
        expect((subject in name: 'license')).to be false
      end

      it 'should pattern match with role symbols' do
        expect((subject in Role(:user | :admin | :environment | :product | :license))).to be true
        expect((subject in Role(:user))).to be false
        expect((subject in Role(:admin))).to be false
        expect((subject in Role(:environment))).to be false
        expect((subject in Role(:product))).to be true
        expect((subject in Role(:license))).to be false
      end
    end

    context 'with license role' do
      let(:resource) { create(:license, account:) }

      it 'should pattern match with attribute hash' do
        expect((subject in name: 'user' | 'admin' | 'environment' | 'product' | 'license')).to be true
        expect((subject in name: 'user')).to be false
        expect((subject in name: 'admin')).to be false
        expect((subject in name: 'environment')).to be false
        expect((subject in name: 'product')).to be false
        expect((subject in name: 'license')).to be true
      end

      it 'should pattern match with role symbols' do
        expect((subject in Role(:user | :admin | :environment | :product | :license))).to be true
        expect((subject in Role(:user))).to be false
        expect((subject in Role(:admin))).to be false
        expect((subject in Role(:environment))).to be false
        expect((subject in Role(:product))).to be false
        expect((subject in Role(:license))).to be true
      end
    end
  end

  describe 'role permission defaults' do
    it 'resets permissions to full admin defaults when promoting a persisted user to admin' do
      resource.role.update!(permissions: Permission.where(action: %w[user.read]).ids)

      resource.role.update!(name: :admin)

      expect(resource.role.reload.permissions.actions).to match_array(Permission::ADMIN_PERMISSIONS)
    end

    it 'does not keep admin-only permissions when demoting an admin to user' do
      resource = create(:admin, account:)

      resource.role.update!(name: :user)

      expect(resource.role.reload.permissions.actions).to match_array(resource.default_permissions)
      expect(resource.role.permissions.actions).to_not include('admin.read')
    end
  end
end
