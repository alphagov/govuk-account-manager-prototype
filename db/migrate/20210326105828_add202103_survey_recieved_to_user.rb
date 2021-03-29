class Add202103SurveyRecievedToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :has_received_2021_03_survey, :boolean, default: false, null: false
  end
end
