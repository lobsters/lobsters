require 'rails_helper'

describe FreenodeTaxonomyReader do
  let(:socket) { double('TCPSocket') }
  let(:username) { 'example' }
  subject { described_class.new(socket_provider: -> () { socket }, username_provider: -> () { username }) }

  it 'talks to NickServ to get a taxonomy' do
    expect(socket).to receive(:write).with("NICK #{username}\r\n")
    expect(socket).to receive(:write).with("USER #{username} * * :Lobsters\r\n")
    expect(socket).to receive(:write).with("PRIVMSG NickServ :TAXONOMY sample\r\n")

    expect(socket).to receive(:gets).and_return(
                        ":#{described_class::NICKSERV}: Taxonomy for sample:",
                        ":#{described_class::NICKSERV}: LOBSTERS: Value",
                        ":#{described_class::NICKSERV}: End of sample taxonomy"
                      )
    expect(socket).to receive(:close)

    expect(subject.for_user('sample')).to eql('LOBSTERS' => 'Value')
  end
end
