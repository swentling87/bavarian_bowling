class GamesController < ApplicationController
  include ResponseHandler

  #POST start new game
  # /new_game
  def new_game
    params_check(params[:player_names]) {
      @game = Game.create
      params[:player_names].each do |player_name|
        player = Player.create(name: player_name, game: @game.id)
        10.times do
          Frame.create(player_id: player.id)
        end
      end
    }
    process_response(@game.exists?, "Congratulations, you started a new game.")
  end
  
  #GET game data
  # /game_data?id=xxx
  def game_data
    frame_data = []
    params_check(params[:game_id]) {
      @game = Game.find(params[:game_id])
      @game.players.each do |player|
        player_frame_data = { player.name => [] }
        player.frames.order_by(:position).each do |frame|
          current_frame = [[frame.first_roll, frame.second_roll], [frame.score]]
          current_frame.append(frame.third_roll) if frame.final_frame && current_frame.sum >= 10
          player_frame_data["#{player.name}"] += current_frame
        end
        frame_data << player_frame_data
      end
    process_response(frame_data.empty?, frame_data)
  end
  
  #POST record bowling result from roll
  # /record_roll?game_id=yyy&player_id=zzz&frame_number=aaa&roll_value=xxx
  def record_roll
    @game = Game.find(params[:game_id])
    roll = params[:roll_value]
    frame = @game.players.find(player_id).frames.find_by(position: frame_number)
    case frame
    when frame.first_roll.nil? && !previous_frame_exists?(frame)
      frame.update!(first_roll: roll)
      frame.update!(strike: true) if roll == 10
    when !frame.first_roll.nil? && !previous_frame_exists?(frame)
      frame.update!(second_roll: roll)
      frame.update!(spare: true) if roll || ( frame.first_roll + roll ) == 10
    when frame.first_roll.nil? && previous_frame_exists?(frame)
      frame.update!(first_roll: roll)
      previous_frame_bonus(frame, roll)
      frame.update!(strike: true) if roll == 10
    when !frame.first_roll.nil? && previous_frame_exists?(frame)
      frame.update!(second_roll: roll)
      previous_frame_bonus(frame, roll)
      frame.update!(spare: true) if roll || ( frame.first_roll + roll ) == 10
    when (frame.first_roll + frame.second_roll == 10) && frame.final_frame
      frame.update!(third_roll: roll)
      previous_frame_bonus(frame, roll)
    end
    process_response(@game.exists?, "Congratulations, you started a new game.")
  end
  
  private
  
  def previous_frame_bonus(frame, roll)
    if previous_frame_exists?(frame)
      previous = Frame.find_by(game_id: frame.game_id, player_id: frame.player_id, position: (frame.position - 1))
      if previous.spare
        previous.update!(score: roll + 10)
      elsif previous.strike && !frame.first.nil? && frame.second_roll.nil?
        previous.update!(score: 10 + frame.first_roll + roll)
        frame.update!(second_roll: roll)
      elsif previous_frame_exists?(previous)
        second_level_frame = Frame.find_by(game_id: previous.game_id, player_id: previous.player_id, position: (previous.position - 1))
        second_level_frame.update!(score: 20 + roll) if second_level_frame.strike && previous.second_roll.strike
      elsif frame.final_frame
        frame.update!(score: frame.fire_roll + frame.second_roll + frame.third_roll)
      end
    end

  end
  
  def previous_frame_exists?(frame)
    (frame.position - 1) > 0
  end
  
  def roll_attributes
    params.require(:game_id, :player_id, :roll_value)
  end
end