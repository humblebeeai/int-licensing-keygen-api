# frozen_string_literal: true

# HBAI: applies one usage report from a licensed server (NICHE-427).
#
# A report carries a client-chosen batch id and per-model, per-day totals. The batch
# row, the daily rows and the licence's uses all change in one transaction, so a
# retried report either applies fully once or not at all. uses is incremented in SQL
# rather than through License#save: the images were already served, so billing must
# record them even past the limit, and two servers reporting at once must not 409.
class LicenseUsageRecordService < BaseService
  Result = Data.define(:duplicate, :images)

  MAX_ENTRIES = 100
  MAX_COUNT   = 1_000_000
  MAX_AGE     = 400.days
  MODEL_ID    = /\A[a-z0-9][a-z0-9._-]*\z/

  class InvalidReportError < StandardError
    attr_reader :pointer

    def initialize(message, pointer:)
      @pointer = pointer

      super(message)
    end
  end

  def initialize(license:, batch_id:, entries:)
    @license  = license
    @batch_id = batch_id
    @entries  = entries
  end

  def call
    rows   = aggregate(entries)
    images = rows.sum { it[:images] }
    now    = Time.current

    duplicate = LicenseUsageBatch.transaction do
      inserted = LicenseUsageBatch.insert_all(
        [{ account_id: license.account_id, license_id: license.id, batch_id:, images:, created_at: now }],
        unique_by: %i[license_id batch_id],
        returning: %i[id],
      )

      next true if
        inserted.rows.empty?

      LicenseUsageDay.upsert_all(
        rows.map {
          it.merge(
            account_id: license.account_id,
            environment_id: license.environment_id,
            license_id: license.id,
            created_at: now,
            updated_at: now,
          )
        },
        unique_by: %i[license_id model_id day],
        on_duplicate: Arel.sql(<<~SQL.squish),
          images = license_usage_days.images + EXCLUDED.images,
          requests = license_usage_days.requests + EXCLUDED.requests,
          failed = license_usage_days.failed + EXCLUDED.failed,
          updated_at = EXCLUDED.updated_at
        SQL
        record_timestamps: false,
      )

      License.where(id: license.id)
             .update_all(['uses = COALESCE(uses, 0) + ?', images]) if images.positive?

      false
    end

    license.reload

    Result.new(duplicate:, images: duplicate ? 0 : images)
  end

  private

  attr_reader :license,
              :batch_id,
              :entries

  # Sums entries that share a model and day, so one report never upserts the same
  # row twice (Postgres refuses that in a single statement). Sorted, so two reports
  # for the same licence lock its rows in the same order and cannot deadlock.
  def aggregate(entries)
    raise InvalidReportError.new('must have at least one entry', pointer: '/meta/entries') if
      entries.blank?

    raise InvalidReportError.new("must have at most #{MAX_ENTRIES} entries", pointer: '/meta/entries') if
      entries.size > MAX_ENTRIES

    today = Time.current.utc.to_date
    rows  = {}

    entries.each_with_index do |entry, i|
      pointer = "/meta/entries/#{i}"
      day     = entry[:day]

      # One spelling per model, or "Unified" and "unified" become two billing rows.
      raise InvalidReportError.new('must be lowercase letters, digits, ".", "_" or "-"', pointer: "#{pointer}/modelId") unless
        entry[:model_id].to_s.match?(MODEL_ID)

      raise InvalidReportError.new('must not be in the future', pointer: "#{pointer}/day") if
        day > today + 1

      raise InvalidReportError.new("must be within #{MAX_AGE.in_days.to_i} days", pointer: "#{pointer}/day") if
        day < today - MAX_AGE

      counts = entry.slice(:images, :requests, :failed).transform_values { it.to_i }

      counts.each do |key, value|
        raise InvalidReportError.new("must be between 0 and #{MAX_COUNT}", pointer: "#{pointer}/#{key}") unless
          value.between?(0, MAX_COUNT)
      end

      row = rows[[entry[:model_id], day]] ||= { model_id: entry[:model_id], day:, images: 0, requests: 0, failed: 0 }

      counts.each { |key, value| row[key] += value }
    end

    rows.values.sort_by { [it[:model_id], it[:day]] }
  end
end
