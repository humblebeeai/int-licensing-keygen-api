# HBAI: daily usage per licence and model, for billing by date range (NICHE-427).
# Batches make a report idempotent: a client that retries after a lost response
# does not count the same images twice.
class CreateLicenseUsageDaysAndBatches < ActiveRecord::Migration[7.2]
  def change
    create_table :license_usage_days, id: :uuid, default: -> { 'uuid_generate_v4()' } do |t|
      t.uuid :account_id,     null: false
      t.uuid :environment_id, null: true
      t.uuid :license_id,     null: false

      t.string :model_id, null: false
      t.date   :day,      null: false
      t.bigint :images,   null: false, default: 0
      t.bigint :requests, null: false, default: 0
      t.bigint :failed,   null: false, default: 0

      t.timestamps

      t.index %i[license_id model_id day], unique: true
      t.index %i[account_id day]
      t.index %i[environment_id]
    end

    create_table :license_usage_batches, id: :uuid, default: -> { 'uuid_generate_v4()' } do |t|
      t.uuid :account_id, null: false
      t.uuid :license_id, null: false

      t.string :batch_id, null: false
      t.bigint :images,   null: false, default: 0

      t.datetime :created_at, null: false

      t.index %i[license_id batch_id], unique: true
      t.index %i[account_id created_at]
    end
  end
end
