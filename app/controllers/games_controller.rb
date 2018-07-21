class GamesController < ApplicationController
  protect_from_forgery with: :null_session
  include ResponseHandler

  # POST start new game
  # Takes a body with comma separated string of names
  # /new_game
  def new_game
    params_check(params[:player_names]) {
        @game = Game.create
        JSON.parse(params[:player_names]).split(",").each do |player_name|
          player = Player.create(name: player_name, game: @game)
          10.times do |i|
            i == 10 ? Frame.create!(game: @game, player: player, position: i, final_frame: true) : Frame.create!(game: @game, player: player, position: i + 1)
          end
        end
      players = @game.players.map{ |player| { "#{player.name}": player.id } }
      process_response(@game.present?, "Congratulations, you started a new game. Here's your game id: #{@game.id} and player data: #{players}")
    }
  end
  
  # GET game data
  # /game_data?game_id=xxx
  def game_data
    frame_data = []
    params_check(params[:game_id]) {
        @game = Game.find(params[:game_id])
        @game.players.each do |player|
          player_frame_data = { player.name => [] }
          player.frames.order(:position).each do |frame|
            current_frame = [[frame.first_roll, frame.second_roll], [frame.score]]
            current_frame.append(frame.third_roll) if frame.final_frame && current_frame.flatten.sum >= 10
            player_frame_data["#{player.name}"] += current_frame
          end
          binding.pry
          player_frame_data[:total] = player.frames.map(&:score).compact.sum
          frame_data << player_frame_data
        end
      process_response(!frame_data.empty?, frame_data)
    }
  end
  
  # POST record bowling result from roll
  # Takes body as such: { game_id: www, player_id: xxx, frame_number: yyy, roll_value: zzz }
  # /record_roll
  def record_roll
    params_check(params[:game_id]) {
      @game = Game.find(params[:game_id])
    }
    params_check(params[:roll_value]) {
      @roll = params[:roll_value].to_i
    }
    params_check(params[:player_id]) {
      @player = @game.players.find(params[:player_id])
    }
    params_check(params[:frame_number]) {
      @frame = @player.frames.find_by(position: params[:frame_number])
    }
    if @frame.first_roll.nil? && !previous_frame_exists?(@frame)
      @frame.update!(first_roll: @roll)
      @frame.update!(strike: true) if @roll == 10
    elsif !@frame.first_roll.nil? && !previous_frame_exists?(@frame)
      @frame.update!(second_roll: @roll)
      @frame.update!(spare: true) if @roll == 10 || @frame.first_roll + @roll == 10
      @frame.update!(score: @frame.first_roll + @roll) if !@frame.spare
    elsif @frame.first_roll.nil? && previous_frame_exists?(@frame)
      @frame.update!(first_roll: @roll)
      previous_frame_bonus(@frame, @roll)
      @frame.update!(strike: true) if @roll == 10
    elsif (!@frame.first_roll.nil? && !@frame.second_roll.nil?) && (@frame.first_roll + @frame.second_roll >= 10) && @frame.final_frame
      @frame.update!(third_roll: @roll, score: @roll + 10 )
      previous_frame_bonus(@frame, @roll)
    elsif !@frame.first_roll.nil? && previous_frame_exists?(@frame)
      @frame.update!(second_roll: @roll)
      previous_frame_bonus(@frame, @roll)
      @frame.update!(spare: true) if @roll == 10 || ( @frame.first_roll + @roll ) == 10
      @frame.update!(score: @frame.first_roll + @roll) if !@frame.spare
    end
    process_response(true, "Score recorded.")
  end
  
  private
  
  def previous_frame_bonus(frame, roll)
    if previous_frame_exists?(frame)
      previous = Frame.find_by(game_id: frame.game_id, player_id: frame.player_id, position: (frame.position - 1))
      if previous.spare && frame.second_roll.nil?
        previous.update!(score: roll + 10)
      elsif previous.strike && !frame.first_roll.nil? && !frame.second_roll.nil?
        previous.update!(score: 10 + frame.first_roll + roll)
        frame.update!(second_roll: roll)
      elsif previous_frame_exists?(previous)
        second_level_frame = Frame.find_by(game_id: previous.game_id, player_id: previous.player_id, position: (previous.position - 1))
        second_level_frame.update!(score: 20 + roll) if second_level_frame.strike && previous.strike
      elsif frame.final_frame
        frame.update!(score: frame.fire_roll + frame.second_roll + frame.third_roll)
      end
    end
  end
  
  def previous_frame_exists?(frame)
    (frame.position - 1) > 0
  end
end