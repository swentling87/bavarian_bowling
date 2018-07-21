# == Schema Information
#
# Table name: frames
#
#  id          :integer          not null, primary key
#  player_id   :integer
#  game_id     :integer
#  first_roll  :integer
#  second_roll :integer
#  third_roll  :integer
#  score       :integer          default(0)
#  strike      :boolean
#  spare       :boolean
#  final_frame :boolean
#  position    :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Frame < ApplicationRecord
  belongs_to :player
  belongs_to :game

end
