# frozen_string_literal: true

# HBAI: unbound licence files (LicenseCheckoutService). Decrypts the licence file in the last
# response with its licence key and checks whether the licence's metadata came with it.
Then /^the license file should (not )?carry the license metadata$/ do |negate|
  json = JSON.parse(last_response.body)
  cert = json.dig('data', 'attributes', 'certificate')
  key  = @account.licenses.find(json.dig('data', 'relationships', 'license', 'data', 'id')).key

  enc = JSON.parse(Base64.decode64(cert.delete_prefix("-----BEGIN LICENSE FILE-----\n")
                                       .delete_suffix("-----END LICENSE FILE-----\n")))
            .fetch('enc')

  attrs =
    if enc.include?('.')
      ciphertext, iv, tag = enc.split('.').map { Base64.strict_decode64(it) }

      aes = OpenSSL::Cipher::AES256.new(:GCM)
      aes.decrypt
      aes.key       = OpenSSL::Digest::SHA256.digest(key)
      aes.iv        = iv
      aes.auth_tag  = tag
      aes.auth_data = ''

      JSON.parse(aes.update(ciphertext) + aes.final)
    else
      JSON.parse(Base64.strict_decode64(enc))
    end.dig('data', 'attributes')

  if negate
    expect(attrs).to_not have_key('metadata')
  else
    expect(attrs['metadata']).to include('modelKey' => 'secret-model-key')
  end
end
