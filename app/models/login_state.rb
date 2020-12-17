class LoginState < ApplicationRecord
  belongs_to :user
  belongs_to :jwt, optional: true, dependent: :destroy
end
