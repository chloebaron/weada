class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]

  has_many :user_events
  has_many :activities, through: :user_events


  def self.from_omniauth(auth)
    data = auth.info
    user = User.where(email: data['email']).first

    # Uncomment the section below if you want users to be created if they don't exist
    unless user
      user = User.create(
        email: data['email'],
        password: Devise.friendly_token[0,20],
        refresh_token: auth.credentials.refresh_token
      )
    end

    user
  end

  # def generate_activityies
  #   WeadaCalenderGeneration.run(self)
  # end
end
