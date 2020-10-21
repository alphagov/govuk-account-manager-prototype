class DeleteController < ApplicationController
  before_action :authenticate_user!, only: [:show]

  def show; end

  def confirmation; end
end
