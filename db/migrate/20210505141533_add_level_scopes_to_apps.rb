class AddLevelScopesToApps < ActiveRecord::Migration[6.0]
  def up
    Doorkeeper::Application.where("scopes LIKE '%transition_checker%'").each do |app|
      unless app.scopes.include? "level0"
        app.update!(scopes: "#{app.scopes} level0 level1")
      end
    end
  end
end
