# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe MachinePolicy, type: :policy do
  subject { described_class.new(record, account:, environment:, bearer:, token:) }

  with_role_authorization :admin do
    with_scenarios %i[accessing_machines] do
      with_token_authentication do
        with_permissions %w[machine.read] do
          without_token_permissions { denies :index }

          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }

        within_environment :isolated do
          with_bearer_and_token_trait :in_shared_environment do
            denies :index
          end

          with_bearer_and_token_trait :in_nil_environment do
            denies :index
          end

          allows :index
        end

        within_environment :shared do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :index
          end

          with_bearer_and_token_trait :in_nil_environment do
            allows :index
          end

          allows :index
        end

        within_environment nil do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :index
          end

          with_bearer_and_token_trait :in_shared_environment do
            denies :index
          end

          allows :index
        end
      end
    end

    with_scenarios %i[accessing_a_machine] do
      with_token_authentication do
        with_permissions %w[machine.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[machine.create] do
          without_token_permissions { denies :create }

          allows :create
        end

        with_permissions %w[machine.update] do
          without_token_permissions { denies :update }

          allows :update
        end

        with_permissions %w[machine.delete] do
          without_token_permissions { denies :destroy }

          allows :destroy
        end

        with_permissions %w[machine.check-out] do
          without_token_permissions { denies :check_out }

          allows :check_out
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy, :check_out
          end

          allows :show, :create, :update, :destroy, :check_out
        end

        with_default_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy, :check_out
          end

          allows :show, :create, :update, :destroy, :check_out
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end

        within_environment :isolated do
          with_bearer_and_token_trait :in_shared_environment do
            denies :show, :create, :update, :destroy, :check_out
          end

          with_bearer_and_token_trait :in_nil_environment do
            denies :show, :create, :update, :destroy, :check_out
          end

          allows :show, :create, :update, :destroy, :check_out
        end

        within_environment :shared do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :show, :create, :update, :destroy, :check_out
          end

          with_bearer_and_token_trait :in_nil_environment do
            allows :show, :create, :update, :destroy, :check_out
          end

          allows :show, :create, :update, :destroy, :check_out
        end

        within_environment nil do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :show, :create, :update, :destroy, :check_out
          end

          with_bearer_and_token_trait :in_shared_environment do
            denies :show, :create, :update, :destroy, :check_out
          end

          allows :show, :create, :update, :destroy, :check_out
        end
      end
    end

    with_scenarios %i[accessing_another_account accessing_machines] do
      with_token_authentication do
        with_permissions %w[machine.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_another_account accessing_a_machine] do
      with_token_authentication do
        with_permissions %w[machine.read] do
          denies :show
        end

        with_permissions %w[machine.create] do
          denies :create
        end

        with_permissions %w[machine.update] do
          denies :update
        end

        with_permissions %w[machine.delete] do
          denies :destroy
        end

        with_permissions %w[machine.check-out] do
          denies :check_out
        end

        with_wildcard_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end

        with_default_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end
      end
    end
  end

  with_role_authorization :environment do
    within_environment :self do
      with_scenarios %i[accessing_machines] do
        with_token_authentication do
          with_permissions %w[machine.read] do
            without_token_permissions { denies :index }

            allows :index
          end

          with_wildcard_permissions { allows :index }
          with_default_permissions  { allows :index }
          without_permissions       { denies :index }

          within_environment :isolated do
            with_bearer_and_token_trait :isolated do
              allows :index
            end

            with_bearer_and_token_trait :shared do
              denies :index
            end
          end

          within_environment :shared do
            with_bearer_and_token_trait :isolated do
              denies :index
            end

            with_bearer_and_token_trait :shared do
              allows :index
            end
          end

          within_environment nil do
            with_bearer_and_token_trait :isolated do
              denies :index
            end

            with_bearer_and_token_trait :shared do
              denies :index
            end
          end
        end
      end

      with_scenarios %i[accessing_a_machine] do
        with_token_authentication do
          with_permissions %w[machine.read] do
            without_token_permissions { denies :show }

            allows :show
          end

          with_permissions %w[machine.create] do
            without_token_permissions { denies :create }

            allows :create
          end

          with_permissions %w[machine.update] do
            without_token_permissions { denies :update }

            allows :update
          end

          with_permissions %w[machine.delete] do
            without_token_permissions { denies :destroy }

            allows :destroy
          end

          with_permissions %w[machine.check-out] do
            without_token_permissions { denies :check_out }

            allows :check_out
          end

          with_wildcard_permissions do
            without_token_permissions do
              denies :show, :create, :update, :destroy, :check_out
            end

            allows :show, :create, :update, :destroy, :check_out
          end

          with_default_permissions do
            without_token_permissions do
              denies :show, :create, :update, :destroy, :check_out
            end

            allows :show, :create, :update, :destroy, :check_out
          end

          without_permissions do
            denies :show, :create, :update, :destroy, :check_out
          end

          within_environment :isolated do
            with_bearer_and_token_trait :isolated do
              allows :show, :create, :update, :destroy, :check_out
            end

            with_bearer_and_token_trait :shared do
              denies :show, :create, :update, :destroy, :check_out
            end
          end

          within_environment :shared do
            with_bearer_and_token_trait :isolated do
              denies :show, :create, :update, :destroy, :check_out
            end

            with_bearer_and_token_trait :shared do
              allows :show, :create, :update, :destroy, :check_out
            end
          end

          within_environment nil do
            with_bearer_and_token_trait :isolated do
              denies :show, :create, :update, :destroy, :check_out
            end

            with_bearer_and_token_trait :shared do
              denies :show, :create, :update, :destroy, :check_out
            end
          end
        end
      end
    end
  end

  with_role_authorization :product do
    with_scenarios %i[accessing_its_machines] do
      with_token_authentication do
        with_permissions %w[machine.read] do
          without_token_permissions { denies :index }

          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_its_machine] do
      with_token_authentication do
        with_permissions %w[machine.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[machine.create] do
          without_token_permissions { denies :create }

          allows :create
        end

        with_permissions %w[machine.update] do
          without_token_permissions { denies :update }

          allows :update
        end

        with_permissions %w[machine.delete] do
          without_token_permissions { denies :destroy }

          allows :destroy
        end

        with_permissions %w[machine.check-out] do
          without_token_permissions { denies :check_out }

          allows :check_out
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy, :check_out
          end

          allows :show, :create, :update, :destroy, :check_out
        end

        with_default_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy, :check_out
          end

          allows :show, :create, :update, :destroy, :check_out
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end
      end
    end

    with_scenarios %i[accessing_machines] do
      with_token_authentication do
        with_permissions %w[machine.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_machine] do
      with_token_authentication do
        with_permissions %w[machine.read] do
          denies :show
        end

        with_permissions %w[machine.create] do
          denies :create
        end

        with_permissions %w[machine.update] do
          denies :update
        end

        with_permissions %w[machine.delete] do
          denies :destroy
        end

        with_permissions %w[machine.check-out] do
          denies :check_out
        end

        with_wildcard_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end

        with_default_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end
      end
    end
  end

  with_role_authorization :license do
    with_scenarios %i[accessing_its_machines] do
      with_license_authentication do
        with_permissions %w[machine.read] do
          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end

      with_token_authentication do
        with_permissions %w[machine.read] do
          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_its_machine] do
      with_license_authentication do
        with_permissions %w[machine.read] do
          allows :show
        end

        with_permissions %w[machine.create] do
          allows :create
        end

        with_permissions %w[machine.update] do
          allows :update
        end

        with_permissions %w[machine.delete] do
          allows :destroy
        end

        with_permissions %w[machine.check-out] do
          allows :check_out
        end

        with_wildcard_permissions do
          allows :show, :create, :update, :destroy, :check_out
        end

        with_default_permissions do
          allows :show, :create, :update, :destroy, :check_out
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end
      end

      with_token_authentication do
        with_permissions %w[machine.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[machine.create] do
          without_token_permissions { denies :create }

          allows :create
        end

        with_permissions %w[machine.update] do
          without_token_permissions { denies :update }

          allows :update
        end

        with_permissions %w[machine.delete] do
          without_token_permissions { denies :destroy }

          allows :destroy
        end

        with_permissions %w[machine.check-out] do
          without_token_permissions { denies :check_out }

          allows :check_out
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy, :check_out
          end

          allows :show, :create, :update, :destroy, :check_out
        end

        with_default_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy, :check_out
          end

          allows :show, :create, :update, :destroy, :check_out
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end
      end
    end

    # HBAI: a machine file carries the AES model key, so check-out is gated on more than
    # ownership -- the licence has to still be good and the machine has to still be
    # heartbeating. Read access is deliberately unaffected; only check-out hands out the key.
    with_scenarios %i[accessing_its_machine] do
      with_license_authentication do
        with_default_permissions do
          context 'with a suspended license' do
            let(:license_traits) { [:suspended] }

            denies :check_out
          end

          context 'with an expired license that revokes access' do
            # Matches verify_license_for_release!: expiry alone does not deny, the policy
            # has to revoke on expiry. Set on the licence rather than through
            # policy_traits, which as_license does not thread into the bearer.
            let(:license_traits) { %i[expired revoke_access_expiration_strategy] }

            denies :check_out
          end

          context 'with an expired license that only restricts access' do
            # RESTRICT_ACCESS keeps what the licence already has, so the weights stay open.
            let(:license_traits) { %i[expired restrict_access_expiration_strategy] }

            allows :check_out
          end

          context 'with a dead machine' do
            let(:machine_traits) { [:dead] }

            denies :check_out
          end

          context 'with a machine that has never sent a heartbeat' do
            # NOT_STARTED, not DEAD: the container activates and decrypts back to back,
            # so requiring a prior heartbeat would deadlock every cold start.
            let(:machine_traits) { [:idle] }

            allows :check_out
          end

          context 'with a live machine on a good license' do
            let(:machine_traits) { [:alive] }

            allows :check_out
          end
        end
      end
    end

    with_scenarios %i[accessing_machines] do
      with_license_authentication do
        with_permissions %w[machine.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end

      with_token_authentication do
        with_permissions %w[machine.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_machine] do
      with_license_authentication do
        with_permissions %w[machine.read] do
          denies :show
        end

        with_permissions %w[machine.create] do
          denies :create
        end

        with_permissions %w[machine.update] do
          denies :update
        end

        with_permissions %w[machine.delete] do
          denies :destroy
        end

        with_permissions %w[machine.check-out] do
          denies :check_out
        end

        with_wildcard_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end

        with_default_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end
      end

      with_token_authentication do
        with_permissions %w[machine.read] do
          denies :show
        end

        with_permissions %w[machine.create] do
          denies :create
        end

        with_permissions %w[machine.update] do
          denies :update
        end

        with_permissions %w[machine.delete] do
          denies :destroy
        end

        with_permissions %w[machine.check-out] do
          denies :check_out
        end

        with_wildcard_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end

        with_default_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end
      end
    end
  end

  with_role_authorization :user do
    with_bearer_trait :with_owned_licenses do
      with_scenarios %i[accessing_its_machines] do
        with_token_authentication do
          with_permissions %w[machine.read] do
            allows :index
          end

          with_wildcard_permissions { allows :index }
          with_default_permissions  { allows :index }
          without_permissions       { denies :index }
        end
      end

      with_scenarios %i[accessing_its_machine] do
        with_token_authentication do
          with_permissions %w[machine.read] do
            without_token_permissions { denies :show }

            allows :show
          end

          with_permissions %w[machine.create] do
            without_token_permissions { denies :create }

            allows :create
          end

          with_permissions %w[machine.update] do
            without_token_permissions { denies :update }

            allows :update
          end

          with_permissions %w[machine.delete] do
            without_token_permissions { denies :destroy }

            allows :destroy
          end

          with_permissions %w[machine.check-out] do
            without_token_permissions { denies :check_out }

            allows :check_out
          end

          with_wildcard_permissions do
            without_token_permissions do
              denies :show, :create, :update, :destroy, :check_out
            end

            allows :show, :create, :update, :destroy, :check_out
          end

          with_default_permissions do
            without_token_permissions do
              denies :show, :create, :update, :destroy, :check_out
            end

            allows :show, :create, :update, :destroy, :check_out
          end

          without_permissions do
            denies :show, :create, :update, :destroy, :check_out
          end
        end
      end

      with_scenarios %i[accessing_machines] do
        with_token_authentication do
          with_permissions %w[machine.read] do
            denies :index
          end

          with_wildcard_permissions { denies :index }
          with_default_permissions  { denies :index }
          without_permissions       { denies :index }
        end
      end

      with_scenarios %i[accessing_a_machine] do
        with_token_authentication do
          with_permissions %w[machine.read] do
            denies :show
          end

          with_wildcard_permissions do
            denies :show, :create, :update, :destroy, :check_out
          end

          with_default_permissions do
            denies :show, :create, :update, :destroy, :check_out
          end

          without_permissions do
            denies :show, :create, :update, :destroy, :check_out
          end
        end
      end
    end

    with_bearer_trait :with_user_licenses do
      with_scenarios %i[accessing_its_machines] do
        with_token_authentication do
          with_permissions %w[machine.read] do
            allows :index
          end

          with_wildcard_permissions { allows :index }
          with_default_permissions  { allows :index }
          without_permissions       { denies :index }
        end
      end

      with_scenarios %i[accessing_its_machine] do
        with_token_authentication do
          with_permissions %w[machine.read] do
            without_token_permissions { denies :show }

            allows :show
          end

          with_permissions %w[machine.create] do
            without_token_permissions { denies :create }

            allows :create
          end

          with_permissions %w[machine.update] do
            without_token_permissions { denies :update }

            allows :update
          end

          with_permissions %w[machine.delete] do
            without_token_permissions { denies :destroy }

            allows :destroy
          end

          with_permissions %w[machine.check-out] do
            without_token_permissions { denies :check_out }

            allows :check_out
          end

          with_wildcard_permissions do
            without_token_permissions do
              denies :show, :create, :update, :destroy, :check_out
            end

            allows :show, :create, :update, :destroy, :check_out
          end

          with_default_permissions do
            without_token_permissions do
              denies :show, :create, :update, :destroy, :check_out
            end

            allows :show, :create, :update, :destroy, :check_out
          end

          without_permissions do
            denies :show, :create, :update, :destroy, :check_out
          end
        end
      end

      with_scenarios %i[accessing_our_machines] do
        with_token_authentication do
          with_permissions %w[machine.read] do
            allows :index
          end

          with_wildcard_permissions { allows :index }
          with_default_permissions  { allows :index }
          without_permissions       { denies :index }
        end
      end

      with_scenarios %i[accessing_our_machine] do
        with_token_authentication do
          with_permissions %w[machine.read] do
            without_token_permissions { denies :show }

            allows :show
          end

          with_permissions %w[machine.create] do
            denies :create
          end

          with_permissions %w[machine.update] do
            denies :update
          end

          with_permissions %w[machine.delete] do
            denies :destroy
          end

          with_permissions %w[machine.check-out] do
            without_token_permissions { denies :check_out }

            allows :check_out
          end

          with_wildcard_permissions do
            without_token_permissions do
              denies :show, :create, :update, :destroy, :check_out
            end

            denies :create, :update, :destroy
            allows :show, :check_out
          end

          with_default_permissions do
            without_token_permissions do
              denies :show, :create, :update, :destroy, :check_out
            end

            denies :create, :update, :destroy
            allows :show, :check_out
          end

          without_permissions do
            denies :show, :create, :update, :destroy, :check_out
          end
        end
      end
    end

    with_scenarios %i[accessing_machines] do
      with_token_authentication do
        with_permissions %w[machine.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_machine] do
      with_token_authentication do
        with_permissions %w[machine.read] do
          denies :show
        end

        with_permissions %w[machine.create] do
          denies :create
        end

        with_permissions %w[machine.update] do
          denies :update
        end

        with_permissions %w[machine.delete] do
          denies :destroy
        end

        with_permissions %w[machine.check-out] do
          denies :check_out
        end

        with_wildcard_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end

        with_default_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end
      end
    end
  end

  without_authorization do
    with_scenarios %i[accessing_machines] do
      without_authentication do
        denies :index
      end
    end

    with_scenarios %i[accessing_a_machine] do
      without_authentication do
        denies :show, :create, :update, :destroy, :check_out
      end
    end
  end
end
