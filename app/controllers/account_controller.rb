class AccountController < ApplicationController
  before_action :authenticate_user!

  def show
    @consents = nil # TODO: implement
    @sessions = nil # TODO: implement
  end
end
