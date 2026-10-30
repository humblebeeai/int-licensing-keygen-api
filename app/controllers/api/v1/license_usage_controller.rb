# frozen_string_literal: true

module Api::V1
  # HBAI: daily usage of every licence in the account, for the billing page (NICHE-427).
  # Rows of deleted licences stay in the report, with no name or product.
  class LicenseUsageController < Api::V1::BaseController
    MAX_REPORT_DAYS = 400

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!

    typed_query {
      param :start, type: :date, coerce: true
      param :end, type: :date, coerce: true
      param :product, type: :uuid, optional: true
    }
    def index
      authorize! with: LicenseUsageDayPolicy

      from, to = license_usage_query.values_at(:start, :end)

      if to < from
        render_bad_request detail: 'must not be before start', source: { parameter: 'end' }

        return
      end

      if (to - from).to_i >= MAX_REPORT_DAYS
        render_bad_request detail: "must be within #{MAX_REPORT_DAYS} days of start", source: { parameter: 'end' }

        return
      end

      days = LicenseUsageDay.where(account: current_account)
                            .for_environment(current_environment)
                            .between(from, to)
                            .left_joins(license: :product)
      days = days.where(licenses: { product_id: license_usage_query[:product] }) if
        license_usage_query[:product].present?

      rows = days.reorder('license_usage_days.day', 'license_usage_days.license_id', 'license_usage_days.model_id').pluck(
        'license_usage_days.day',
        'license_usage_days.license_id',
        'licenses.name',
        'licenses.key',
        'licenses.product_id',
        'products.name',
        'license_usage_days.model_id',
        'license_usage_days.images',
        'license_usage_days.requests',
        'license_usage_days.failed',
        'license_usage_days.updated_at',
      ).map do |day, license_id, license_name, key, product_id, product_name, model_id, images, requests, failed, updated_at|
        {
          day: day.iso8601,
          licenseId: license_id,
          licenseName: license_name,
          licenseKey: key&.first(8), # enough to recognise a licence in a report
          licenseDeleted: key.nil?,
          productId: product_id,
          productName: product_name,
          modelId: model_id,
          images:,
          requests:,
          failed:,
          updatedAt: updated_at.iso8601,
        }
      end

      render json: {
        data: rows,
        meta: {
          start: from.iso8601,
          end: to.iso8601,
          images: rows.sum { it[:images] },
          requests: rows.sum { it[:requests] },
          failed: rows.sum { it[:failed] },
        },
      }
    end
  end
end
