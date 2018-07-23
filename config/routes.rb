Rails.application.routes.draw do
  get '/', to: "games#index"
  get 'game_data', to: "games#game_data"
  post 'new_game', to: "games#new_game"
  post 'record_roll', to: "games#record_roll"
end
