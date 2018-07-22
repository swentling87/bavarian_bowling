require 'rails_helper'

RSpec.describe Game, type: :model do
  describe '#validations' do
    it { should have_many(:players) }
    it { should have_many(:frames) }
  end
end
