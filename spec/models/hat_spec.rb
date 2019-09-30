require 'rails_helper'

describe Hat do
  describe '#hat' do
    it { is_expected.to validate_presence_of(:hat) }
    it { is_expected.to validate_length_of(:hat).is_at_most(255) }
  end

  describe '#link' do
    it { is_expected.to validate_length_of(:link).is_at_most(255) }
  end
end
