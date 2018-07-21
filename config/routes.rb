Rails.application.routes.draw do
  post 'new_game', to: "games#new_game"
  post 'record_roll', to: "games#record_roll"
end
