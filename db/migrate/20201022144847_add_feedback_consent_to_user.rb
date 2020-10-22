class AddFeedbackConsentToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :feedback_consent, :boolean, null: false, default: false
  end
end
