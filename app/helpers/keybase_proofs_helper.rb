module KeybaseProofsHelper
  def keybase_user_link(keybase_signature)
    File.join Keybase.BASE_URL, keybase_signature[:kb_username]
  end

  def keybase_proof_link(keybase_signature)
    File.join Keybase.BASE_URL, keybase_signature[:kb_username], "sigchain\##{keybase_signature[:sig_hash]}"
  end
end
