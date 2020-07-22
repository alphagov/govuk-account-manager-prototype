class ActivityController < ApplicationController
  before_action :authenticate_user!

  def show
    @activity = current_user.activities.order(created_at: :desc)
  end
end
