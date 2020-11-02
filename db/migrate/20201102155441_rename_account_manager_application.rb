class RenameAccountManagerApplication < ActiveRecord::Migration[6.0]
  def up
    Doorkeeper::Application.where(name: "GOV.UK Account Manager").update(name: "GOV.UK Account")
  end
end
