module KeybaseProofsHelper
  def keybase_user_link(kb_sig)
    File.join Keybase.BASE_URL, kb_sig[:kb_username]
  end

  def keybase_proof_link(kb_sig)
    File.join Keybase.BASE_URL, kb_sig[:kb_username], "sigchain\##{kb_sig[:sig_hash]}"
  end
end
