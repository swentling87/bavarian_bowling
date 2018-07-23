require 'rails_helper'

RSpec.describe GamesController, type: :controller do
  describe '#new_game' do
    it "creates a new game" do
      expect(Game.count).to eq(0)
      post :new_game, params: { player_names: "test" }
      expect(Game.count).to eq(1)
      expect(Player.first.name).to eq("test")
    end
    
    it "returns a response of Bad Request for a missing parameter of player_names" do
      expect(Game.count).to eq(0)
      post :new_game, params: { }
      expect(Game.count).to eq(0)
      expect(response.status).to be 400
    end
  end
  
  describe '#game_data' do
    before do
      game = Game.create!
      player = Player.create!(name: "Tester", game: game)
      frame = Frame.create!(game: game, player: player)
    end
    
    it "returns game data" do
      get :game_data, params: { game_id: 1 }
      expect(response.status).to be 200
      expect(response.body).to eq("{\"status\":\"ok\",\"message\":[{\"Tester\":[[null,null],[0]],\"total\":0}],\"optional\":[]}")
    end
    
    it "returns a response of Bad Request for a missing parameter of game_id" do
      get :game_data, params: { }
      expect(response.status).to be 400
    end
  end
  
  describe '#record_roll' do
    before do
      game = Game.create!
      player = Player.create!(name: "Tester", game: game)
      10.times do |i|
        i == 10 ? Frame.create!(game: game, player: player, position: i, final_frame: true) : Frame.create!(game: game, player: player, position: i + 1)
      end
    end
    
    it "returns a response of Bad Request for a missing parameter of game_id" do
      post :record_roll, params: { roll_value: 1, player_id: 1, frame_number: 1 }
      expect(response.status).to be 400
    end
    
    it "returns a response of Bad Request for a missing parameter of roll_value" do
      post :record_roll, params: { game_id: 1, player_id: 1, frame_number: 1 }
      expect(response.status).to be 400
    end
    
    it "returns a response of Bad Request for a missing parameter of player_id" do
      post :record_roll, params: { game_id: 1, roll_value: 1, frame_number: 1 }
      expect(response.status).to be 400
    end
    
    it "returns a response of Bad Request for a missing parameter of frame_number" do
      post :record_roll, params: { game_id: 1, roll_value: 1, player_id: 1 }
      expect(response.status).to be 400
    end
    
    it "returns a positive response for a recorded roll" do
      post :record_roll, params: { game_id: 1, roll_value: 9, player_id: 1, frame_number: 1 }
      expect(response.status).to be 200
      expect(response.body).to eq("{\"status\":\"ok\",\"message\":\"Score recorded.\",\"optional\":[]}")
    end
    
    it "returns the correct response for a recorded roll" do
      post :record_roll, params: { game_id: 1, roll_value: 9, player_id: 1, frame_number: 1 }
      expect(response.status).to be 200
      get :game_data, params: { game_id: 1 }
      expect(JSON.parse(response.body)).to eq(
        {"status"=>"ok", "message"=> [{"Tester"=>
          [[9, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0]], "total"=>0}], "optional"=>[]})
    end
    
    it "returns the correct response for a recorded roll" do
      post :record_roll, params: { game_id: 1, roll_value: 9, player_id: 1, frame_number: 1 }
      post :record_roll, params: { game_id: 1, roll_value: 0, player_id: 1, frame_number: 1 }
      expect(response.status).to be 200
      get :game_data, params: { game_id: 1 }
      expect(JSON.parse(response.body)).to eq(
        {"status"=>"ok", "message"=> [{"Tester"=>
          [[9, 0], [9], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0]], "total"=>9}], "optional"=>[]})
    end
    
    it "returns the correct response for a recorded roll after a spare" do
      post :record_roll, params: { game_id: 1, roll_value: 9, player_id: 1, frame_number: 1 }
      post :record_roll, params: { game_id: 1, roll_value: 1, player_id: 1, frame_number: 1 }
      post :record_roll, params: { game_id: 1, roll_value: 5, player_id: 1, frame_number: 2 }
      expect(response.status).to be 200
      get :game_data, params: { game_id: 1 }
      expect(JSON.parse(response.body)).to eq(
        {"status"=>"ok", "message"=> [{"Tester"=>
          [[9, 1], [15], [5, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0]], "total"=>15}], "optional"=>[]})
    end
    
    it "returns the correct response for a recorded roll after a strike" do
      post :record_roll, params: { game_id: 1, roll_value: 10, player_id: 1, frame_number: 1 }
      post :record_roll, params: { game_id: 1, roll_value: 5, player_id: 1, frame_number: 2 }
      post :record_roll, params: { game_id: 1, roll_value: 4, player_id: 1, frame_number: 2 }
      expect(response.status).to be 200
      get :game_data, params: { game_id: 1 }
      expect(JSON.parse(response.body)).to eq(
        {"status"=>"ok", "message"=> [{"Tester"=>
          [[10, nil], [19], [5, 4], [9], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0]], "total"=>28}], "optional"=>[]})
    end
    
    it "returns an error if trying to throw a 2nd ball after a strike" do
      post :record_roll, params: { game_id: 1, roll_value: 10, player_id: 1, frame_number: 1 }
      post :record_roll, params: { game_id: 1, roll_value: 5, player_id: 1, frame_number: 1 }
      expect(response.status).to be 400
      get :game_data, params: { game_id: 1 }
      expect(JSON.parse(response.body)).to eq(
        {"status"=>"ok", "message"=> [{"Tester"=>
          [[10, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0]], "total"=>0}], "optional"=>[]})
    end
    
    it "returns an error if trying to throw a 2nd ball for more than the amount of pins left" do
      post :record_roll, params: { game_id: 1, roll_value: 8, player_id: 1, frame_number: 1 }
      post :record_roll, params: { game_id: 1, roll_value: 8, player_id: 1, frame_number: 1 }
      expect(response.status).to be 400
      get :game_data, params: { game_id: 1 }
      expect(JSON.parse(response.body)).to eq(
        {"status"=>"ok", "message"=> [{"Tester"=>
          [[8, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0], [nil, nil], [0]], "total"=>0}], "optional"=>[]})
    end
  end
end
