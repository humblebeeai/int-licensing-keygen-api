# frozen_string_literal: true

class LicenseCheckoutService < AbstractCheckoutService
  class InvalidIncludeError < StandardError; end
  class InvalidLicenseError < StandardError; end
  class UnboundWithoutExpiryError < StandardError; end

  ALLOWED_INCLUDES = %w[
    entitlements
    environment
    product
    policy
    group
    owner
    users
  ].freeze

  # HBAI: `unbound` lets an encrypted licence file carry the licence's metadata, model
  # key included. Only the controller sets it, and only for an admin checking out a
  # licence whose policy opted in (see Policy#unbound_licence_file?). Set before `super`,
  # which builds the renderer from #checkout_context.
  def initialize(license:, environment: nil, include: [], unbound: false, **kwargs)
    raise InvalidLicenseError, 'license must be present' unless
      license.present?

    @unbound = unbound

    raise InvalidIncludeError, 'invalid includes' if
      (include - ALLOWED_INCLUDES).any?

    @license     = license
    @environment = environment

    # this is used when an algorithm is not explicitly provided
    sign = case license.scheme
           when 'RSA_2048_PKCS1_PSS_SIGN_V2',
                'RSA_2048_PKCS1_PSS_SIGN'
             'rsa-pss-sha256'
           when 'RSA_2048_PKCS1_SIGN_V2',
                'RSA_2048_PKCS1_SIGN',
                'RSA_2048_PKCS1_ENCRYPT',
                'RSA_2048_JWT_RS256'
             'rsa-sha256'
           when 'ED25519_SIGN'
             'ed25519'
           when 'ECDSA_P256_SIGN'
             'ecdsa-p256'
           else
             true
           end

    super(sign:, include:, **kwargs)

    # HBAI: an unbound file has no machine, no counter and no heartbeat; the licence's end
    # date is the only thing that stops it. So it needs one, and the file may not outlive
    # it. After `super`, which knows whether the file is encrypted -- only then does it
    # carry the key.
    if unbound && encrypted?
      remaining = license.expiry.present? ? (license.expiry - Time.current).to_i : nil

      raise UnboundWithoutExpiryError, 'an unbound licence file needs a licence that has not ended, with at least an hour left' if
        remaining.nil? || remaining < 1.hour

      @ttl = [ttl&.to_i, remaining].compact.min
    end
  end

  def call
    issued_at  = Time.current
    expires_at = if ttl?
                   issued_at + ActiveSupport::Duration.build(ttl)
                 else
                   nil
                 end

    meta = { issued: issued_at, expiry: expires_at, ttl: ttl }
    incl = includes & ALLOWED_INCLUDES
    data = renderer.render(license, meta: meta, include: incl)
                   .to_json

    enc = if encrypted?
            encrypt(data, secret: license.key)
          else
            encode(data, strict: true)
          end
    sig = sign(enc, prefix: 'license')
    alg = algorithm

    doc  = { enc: enc, sig: sig, alg: alg }
    enc  = encode(doc.to_json)
    cert = <<~TXT
      -----BEGIN LICENSE FILE-----
      #{enc}
      -----END LICENSE FILE-----
    TXT

    LicenseFile.new(
      environment_id: environment&.id,
      account_id: account.id,
      license_id: license.id,
      certificate: cert,
      issued_at: issued_at,
      expires_at: expires_at,
      ttl: ttl,
      includes: incl,
      algorithm:,
    )
  end

  private

  attr_reader :environment,
              :license

  # HBAI: a licence file is sealed under license.key alone, so it stays closed to secrets
  # unless the file is unbound on purpose -- and even then only when encrypted, since an
  # unencrypted file is base64 anyone can decode.
  def checkout_context = encrypted? && @unbound ? :unbound_license_checkout : :checkout
end
