class GamesController < ApplicationController
  protect_from_forgery with: :null_session
  include ResponseHandler

  # POST start new game
  # Takes a body with comma separated string of names
  # /new_game
  def new_game
    params_check(params[:player_names]) {
        @game = Game.create
        params[:player_names].split(",").each do |player_name|
          player = Player.create(name: player_name, game: @game)
          10.times do |i|
            i == 10 ? Frame.create!(game: @game, player: player, position: i, final_frame: true) : Frame.create!(game: @game, player: player, position: i + 1)
          end
        end
      players = @game.players.map{ |player| { "#{player.name}": player.id } }
      process_response(@game.present?, "Congratulations, you started a new game. Here's your game id: #{@game.id} and player data: #{players}", @game.id)
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
    params_check(params[:game_id], params[:roll_value], params[:player_id], params[:frame_number]) {
      @game = Game.find_by(id: params[:game_id])
      @roll = params[:roll_value].to_i
      @player = @game.players.find(params[:player_id])
      @frame = @player.frames.find_by(position: params[:frame_number])
      
      # Return bad request if trying to throw a second ball when the frame has a strike
      if @frame.strike && !@frame.final_frame
        return process_response(false)
      end
      
      # Return bad request if trying to enter a roll value larger than 10 or two values larger than 10
      if @roll > 10 || ((!@frame.final_frame && @frame.first_roll) && @frame.first_roll + @roll > 10)
        return process_response(false)
      end
      
      if @frame.first_roll.nil?
        process_first_roll
      elsif (@frame.first_roll && @frame.second_roll) && (@frame.first_roll + @frame.second_roll >= 10) && @frame.final_frame
        @frame.third_roll = @roll
        @frame.score =  @roll + @frame.first_roll + @frame.second_roll
      elsif !@frame.first_roll.nil?
        process_second_roll
      end
      
      if previous_frame_exists?(@frame)
        previous_frame_bonus(@frame, @roll)
      end

      @frame.save
      process_response(true, "Score recorded.")
    }
  end
  
  private
  
  def process_first_roll
    @frame.first_roll = @roll
    @frame.strike = true if @roll == 10
  end
  
  def process_second_roll
    @frame.second_roll = @roll
    @frame.spare =  true if @roll == 10 || @frame.first_roll + @roll == 10
    @frame.score = @frame.first_roll + @roll if !@frame.spare
  end
  
  def previous_frame_bonus(frame, roll)
    previous = Frame.find_by(game_id: frame.game_id, player_id: frame.player_id, position: (frame.position - 1))
    if previous.spare && frame.second_roll.nil?
      previous.update!(score: roll + 10)
    elsif previous.strike && !frame.first_roll.nil? && !frame.second_roll.nil?
      previous.update!(score: 10 + frame.first_roll + roll)
    elsif previous_frame_exists?(previous)
      second_level_frame = Frame.find_by(game_id: previous.game_id, player_id: previous.player_id, position: (previous.position - 1))
      second_level_frame.score = 20 + roll if second_level_frame.strike && previous.strike
    end
  end
      
  def previous_frame_exists?(frame)
    (frame.position - 1) > 0
  end
end