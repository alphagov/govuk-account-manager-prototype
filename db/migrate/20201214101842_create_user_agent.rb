class CreateUserAgent < ActiveRecord::Migration[6.0]
  def change
    create_table :user_agents do |t|
      t.string :name, limit: 1000, null: false
    end

    add_index :user_agents, :name, unique: true

    add_reference :security_activities, :user_agent, index: true
    add_foreign_key :security_activities, :user_agents
  end
end
