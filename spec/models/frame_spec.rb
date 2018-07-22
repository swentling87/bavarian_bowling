require 'rails_helper'

RSpec.describe Frame, type: :model do
  describe '#validations' do
    it { should belong_to(:game) }
    it { should belong_to(:player) }
  end
end
