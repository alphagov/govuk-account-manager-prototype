class User < ApplicationRecord
  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end

  devise :database_authenticatable,
         :confirmable,
         :lockable,
         :recoverable,
         :registerable,
         :rememberable,
         :timeoutable,
         :trackable,
         :validatable

  validates :password, format: { with: /\A.*[0-9].*\z/ }, allow_blank: true

  has_many :access_grants,
           class_name: "Doorkeeper::AccessGrant",
           foreign_key: :resource_owner_id,
           dependent: :delete_all

  has_many :access_tokens,
           class_name: "Doorkeeper::AccessToken",
           foreign_key: :resource_owner_id,
           dependent: :delete_all

  has_many :activities,
           dependent: :delete_all

  def update_tracked_fields!(request)
    super(request)
    Activity.login!(self, request.remote_ip) unless new_record?
  end
end
