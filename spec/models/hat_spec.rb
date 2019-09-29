require 'rails_helper'

describe Hat, type: :model do
  describe '#hat' do
    it { should validate_presence_of(:hat) }
    it { should validate_length_of(:hat).is_at_most(255) }
  end

  describe '#link' do
    it { should validate_length_of(:link).is_at_most(255) }
  end
end
