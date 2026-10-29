# frozen_string_literal: true

# HBAI: one row per licence, model and UTC day (NICHE-427). Rows outlive the
# licence on purpose: they are what Niche bills from.
class LicenseUsageDay < ApplicationRecord
  include Environmental
  include Accountable

  belongs_to :license

  has_environment default: -> { license&.environment_id }
  has_account default: -> { license&.account_id }

  scope :between, -> (from, to) { where(day: from..to) }
end
