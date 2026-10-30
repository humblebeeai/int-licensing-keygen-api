# frozen_string_literal: true

module Api::V1::Licenses::Actions
  # HBAI: per-model, per-day usage reports from licensed servers (NICHE-427).
  # Same permission as increment-usage: a licence key may report its own usage.
  class UsageRecordsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_license

    authorize :license

    typed_params {
      format :jsonapi

      param :meta, type: :hash do
        param :batch_id, type: :string, length: { minimum: 1, maximum: 64 }
        param :entries, type: :array do
          items type: :hash do
            param :model_id, type: :string, length: { minimum: 1, maximum: 128 }
            param :day, type: :date, coerce: true
            param :images, type: :integer
            param :requests, type: :integer
            param :failed, type: :integer, optional: true
          end
        end
      end
    }
    def create
      authorize! license,
        with: Licenses::UsagePolicy,
        to: :increment?

      result = LicenseUsageRecordService.call(
        license:,
        batch_id: usage_record_meta[:batch_id],
        entries: usage_record_meta[:entries],
      )

      if result.images.positive?
        BroadcastEventService.call(
          event: 'license.usage.incremented',
          account: current_account,
          resource: license,
        )
      end

      render jsonapi: license, meta: { duplicate: result.duplicate }
    rescue LicenseUsageRecordService::InvalidReportError => e
      render_bad_request detail: e.message,
                         source: { pointer: e.pointer }
    end

    MAX_REPORT_DAYS = 400

    # Daily rows and totals for one licence between two UTC dates, both inclusive.
    typed_query {
      param :start, type: :date, coerce: true
      param :end, type: :date, coerce: true
      param :model, type: :string, optional: true
    }
    def show
      authorize! license,
        with: Licenses::UsagePolicy,
        to: :show?

      from, to = usage_record_query.values_at(:start, :end)

      if to < from
        render_bad_request detail: 'must not be before start', source: { parameter: 'end' }

        return
      end

      if (to - from).to_i >= MAX_REPORT_DAYS
        render_bad_request detail: "must be within #{MAX_REPORT_DAYS} days of start", source: { parameter: 'end' }

        return
      end

      days = LicenseUsageDay.where(license_id: license.id)
                            .between(from, to)
      days = days.where(model_id: usage_record_query[:model]) if
        usage_record_query[:model].present?

      rows = days.reorder(:day, :model_id).map do |row|
        { day: row.day.iso8601, modelId: row.model_id, images: row.images, requests: row.requests, failed: row.failed }
      end

      render json: {
        data: rows,
        meta: {
          licenseId: license.id,
          start: from.iso8601,
          end: to.iso8601,
          images: rows.sum { it[:images] },
          requests: rows.sum { it[:requests] },
          failed: rows.sum { it[:failed] },
        },
      }
    end

    private

    attr_reader :license

    def set_license
      scoped_licenses = authorized_scope(current_account.licenses)

      @license = FindByAliasService.call(scoped_licenses, id: params[:id], aliases: :key)

      Current.resource = license
    end
  end
end
