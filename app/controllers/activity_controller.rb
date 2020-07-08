class ActivityController < ApplicationController
  before_action :authenticate_user!

  def show
    @activity = [] # TODO: implement
  end
end
