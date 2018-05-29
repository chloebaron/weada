class Activity < ApplicationRecord
  has_many :user_events
  has_many :users
end
