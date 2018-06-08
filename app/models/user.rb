class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]

  has_many :user_events
  has_many :activities, through: :user_events


  def self.from_omniauth(auth, sleep_schedule)
    data = auth.info
    user = User.where(email: data['email']).first
    # Uncomment the section below if you want users to be created if they don't exist
    if user.nil? && sleep_schedule
      user = User.create!(
        email: data['email'],
        first_name: data['first_name'],
        last_name: data['last_name'],
        wake_up_hour: sleep_schedule["wakep er b_up_hour"],
        sleep_hour: sleep_schedule["sleep_hour"],
        work_start_time: sleep_schedule["start_time"],
        work_end_time: sleep_schedule["end_time"],
        password: Devise.friendly_token[0,20],
        refresh_token: auth.credentials.refresh_token
      )
      # raise
    elsif user
      user.update(refresh_token: auth.credentials.refresh_token)
    end

    user
  end
  # def generate_activityies
  #   WeadaCalenderGeneration.run(self)
  # end
end
