class ProfileController < ApplicationController
  before_action :authenticate_user!

  def show
    @profile = {}
  end
end
