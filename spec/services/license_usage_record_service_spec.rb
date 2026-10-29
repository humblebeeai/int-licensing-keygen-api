# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe LicenseUsageRecordService do
  let(:account) { create(:account) }
  let(:policy)  { create(:policy, account:, max_uses: 10) }
  let(:license) { create(:license, account:, policy:, uses: 0) }
  let(:today)   { Time.current.utc.to_date }

  def entry(model_id: 'extraction_full_premium', day: today, images: 3, requests: 3, failed: 0)
    { model_id:, day:, images:, requests:, failed: }
  end

  def record(batch_id: SecureRandom.uuid, entries: [entry])
    described_class.call(license:, batch_id:, entries:)
  end

  it 'records a new batch' do
    result = record

    expect(result.duplicate).to be false
    expect(result.images).to eq 3
    expect(license.uses).to eq 3

    day = LicenseUsageDay.sole

    expect(day).to have_attributes(
      account_id: account.id,
      license_id: license.id,
      model_id: 'extraction_full_premium',
      day: today,
      images: 3,
      requests: 3,
      failed: 0,
    )
  end

  it 'counts a batch once when it is sent twice' do
    record(batch_id: 'batch-1')
    result = record(batch_id: 'batch-1')

    expect(result.duplicate).to be true
    expect(result.images).to eq 0
    expect(license.uses).to eq 3
    expect(LicenseUsageDay.sole.images).to eq 3
    expect(LicenseUsageBatch.count).to eq 1
  end

  it 'lets another licence use the same batch id' do
    other = create(:license, account:, policy:, uses: 0)

    record(batch_id: 'batch-1')
    result = described_class.call(license: other, batch_id: 'batch-1', entries: [entry])

    expect(result.duplicate).to be false
    expect(other.uses).to eq 3
  end

  it 'adds to the same row across batches' do
    record
    record(entries: [entry(images: 2, requests: 3, failed: 1)])

    expect(LicenseUsageDay.sole).to have_attributes(images: 5, requests: 6, failed: 1)
    expect(license.uses).to eq 5
  end

  it 'sums entries for the same model and day within one batch' do
    record(entries: [entry(images: 1, requests: 1), entry(images: 2, requests: 2)])

    expect(LicenseUsageDay.sole).to have_attributes(images: 3, requests: 3)
    expect(license.uses).to eq 3
  end

  it 'keeps models and days apart' do
    record(
      entries: [
        entry(model_id: 'extraction_full_premium', day: today),
        entry(model_id: 'extraction_full_primary', day: today),
        entry(model_id: 'extraction_full_premium', day: today - 1),
      ],
    )

    expect(LicenseUsageDay.count).to eq 3
    expect(license.uses).to eq 9
  end

  it 'writes rows in model and day order, whatever order the client sent' do
    rows = described_class.new(license:, batch_id: 'x', entries: []).send(:aggregate, [
      entry(model_id: 'b', day: today),
      entry(model_id: 'a', day: today),
      entry(model_id: 'a', day: today - 1),
    ])

    expect(rows.map { [it[:model_id], it[:day]] }).to eq [['a', today - 1], ['a', today], ['b', today]]
  end

  it 'records usage past the licence limit' do
    record(entries: [entry(images: 12, requests: 12)])

    expect(license.uses).to eq 12
    expect(LicenseUsageDay.sole.images).to eq 12
  end

  it 'does not touch uses for a batch with only failures' do
    result = record(entries: [entry(images: 0, requests: 2, failed: 2)])

    expect(result.images).to eq 0
    expect(license.uses).to eq 0
    expect(LicenseUsageDay.sole).to have_attributes(requests: 2, failed: 2)
  end

  it 'starts from zero when uses is null' do
    license.update_column(:uses, nil)

    record

    expect(license.uses).to eq 3
  end

  it 'accepts a day up to a year back, for an offline server' do
    record(entries: [entry(day: today - 365)])

    expect(LicenseUsageDay.sole.day).to eq today - 365
  end

  describe 'refusals' do
    def refused(entries)
      expect { record(entries:) }.to raise_error(LicenseUsageRecordService::InvalidReportError)

      expect(LicenseUsageBatch.count).to eq 0
      expect(LicenseUsageDay.count).to eq 0
      expect(license.reload.uses).to eq 0
    end

    it('refuses no entries')         { refused([]) }
    it('refuses too many entries')   { refused(Array.new(101) { entry }) }
    it('refuses a future day')       { refused([entry(day: today + 2)]) }
    it('refuses a day too far back') { refused([entry(day: today - 401)]) }
    it('refuses a negative count')   { refused([entry(images: -1)]) }
    it('refuses a huge count')       { refused([entry(requests: 1_000_001)]) }
    it('refuses a model in capitals') { refused([entry(model_id: 'Extraction_Full_Premium')]) }
    it('refuses a model with spaces') { refused([entry(model_id: 'extraction_full_premium ')]) }
  end
end
