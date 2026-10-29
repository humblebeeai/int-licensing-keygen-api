# frozen_string_literal: true

module Licenses
  class UsagePolicy < ApplicationPolicy
    authorize :license

    def increment?
      verify_permissions!('license.usage.increment')
      verify_environment!

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :environment)
        allow!
      in role: Role(:product) if license.product == bearer
        allow!
      in role: Role(:user) if license.owner == bearer
        !license.protected?
      in role: Role(:license) if license == bearer
        allow!
      else
        deny!
      end
    end

    # HBAI: the daily usage report (NICHE-427). Billing data, so not the licence itself.
    def show?
      verify_permissions!('license.read')
      verify_environment!

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
        allow!
      in role: Role(:product) if license.product == bearer
        allow!
      else
        deny!
      end
    end

    def decrement?
      verify_permissions!('license.usage.decrement')
      verify_environment!

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :environment)
        allow!
      in role: Role(:product) if license.product == bearer
        allow!
      else
        deny!
      end
    end

    def reset?
      verify_permissions!('license.usage.reset')
      verify_environment!

      case bearer
      in role: Role(:admin | :developer | :sales_agent | :support_agent | :environment)
        allow!
      in role: Role(:product) if license.product == bearer
        allow!
      else
        deny!
      end
    end
  end
end
