class ActivityController < ApplicationController
  before_action :authenticate_user!

  def show
    @activity = nil # TODO: implement
  end
end
