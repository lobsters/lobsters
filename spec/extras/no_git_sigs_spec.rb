# typed: false

require "open3"

require "rails_helper"

# We don't use gpg signatures in this repo. This ugly test tries to detect and prohibit them because
# git and github lack options to prohibit them in the repo. If you sign a commit, every other user's
# log messages get cluttered up with gpg's errors about verifying signatures. I'm not going to
# require that every potential contributor take on the chores of integrating gpg.
#
# If you are reading this because the build is failing, disable signatures in this repo:
#  $ git config --local commit.gpgsign false
#
# And then for each commit you signed:
#  $ git commit --amend --no-edit --no-gpg-sign COMMITID
#
# I'm sorry for the hassle. If git didn't print spurious gpg warnings I'd love to delete it.

describe "gpg" do
  it "is as usable as a lead feather duster" do
    stdout, stderr, _ = Open3.capture3("git log --oneline --show-signature | head -9")
    expect(stdout).to_not include("gpg: ")
    expect(stderr).to_not include("allowedSignersFile")
    expect(stderr).to_not include("gpg.ssh")
  end
end
