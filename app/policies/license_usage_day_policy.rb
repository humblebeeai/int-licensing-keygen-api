# frozen_string_literal: true

# HBAI: the account-wide daily usage report (NICHE-427). Billing data, so staff
# roles only; a product reads its own licences through the per-licence report.
class LicenseUsageDayPolicy < ApplicationPolicy
  def index?
    verify_permissions!('license.read')
    verify_environment!(
      strict: false, # aggregates, not one record
    )

    case bearer
    in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
      allow!
    else
      deny!
    end
  end
end
