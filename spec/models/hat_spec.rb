require 'rails_helper'

describe Hat, type: :model do
  describe '#hat' do
    it { should validate_presence_of(:hat) }
  end
end
