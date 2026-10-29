# frozen_string_literal: true

# HBAI: a usage report already applied, keyed by the client's batch id (NICHE-427).
class LicenseUsageBatch < ApplicationRecord
  include Accountable

  belongs_to :license

  has_account default: -> { license&.account_id }
end
