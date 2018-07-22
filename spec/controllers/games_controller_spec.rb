require 'rails_helper'

RSpec.describe GamesController, type: :controller do
  describe '#new_game' do
    it "creates a new game" do
      expect(Game.count).to eq(0)
      post :new_game, params: { player_names: "\"test\"" }
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
      expect(response.body).to eq("{\"status\":\"ok\",\"message\":[{\"Tester\":[[null,null],[0]],\"total\":0}]}")
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
      frame = Frame.create!(game: game, player: player, position: 1)
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
      expect(response.body).to eq("{\"status\":\"ok\",\"message\":\"Score recorded.\"}")
    end
  end
end
