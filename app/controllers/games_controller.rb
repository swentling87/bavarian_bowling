class GamesController < ApplicationController
  include ResponseHandler

  #POST start new game
  # /new_game
  def new_game
    params_check(params[:player_names]) {
      @game = Game.create
      params[:player_names].each do |player_name|
        Player.create(name: player_name, game: @game.id)
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
          current_frame = [[frame.first, frame.second]]
          current_frame.append(frame.third) if frame.final_frame && current_frame.sum == 10
          player_frame_data["#{player.name}"] += current_frame
        end
        frame_data << player_frame_data
      end
    process_response(frame_data.empty?, frame_data)
  end
  
  #POST record bowling result from roll
  # /record_roll?game_id=yyy&player_id=zzz&roll_value=xxx
  def record_roll
    params_check(params[:game_id]) {
      params[:player_names].each do |player|
        Player.create(name: player, game: @game.id)
      end
    }
    process_response(@game.exists?, "Congratulations, you started a new game.")
  end
end