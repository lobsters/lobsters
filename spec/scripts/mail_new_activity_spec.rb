require_relative '../../script/mail_new_activity'

describe 'EmailSender' do
  it "encodes text as quoted printable" do
    expect("Why Use Pointers?".quoted_printable(true)).to eq("=?UTF-8?Q?Why_Use_Pointers=3F?=")
  end
end
