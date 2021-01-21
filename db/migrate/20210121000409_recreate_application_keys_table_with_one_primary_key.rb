class RecreateApplicationKeysTableWithOnePrimaryKey < ActiveRecord::Migration[6.0]
  def up
    # read all the keys into memory before destroying the table - this
    # is fine at the moment.
    application_keys = ApplicationKey.all.map do |key|
      {
        application_uid: key.application_uid,
        key_id: key.key_id,
        pem: key.pem
      }
    end

    drop_table :application_keys

    create_table :application_keys do |t|
      t.string :application_uid, null: false
      t.uuid   :key_id,          null: false
      t.string :pem,             null: false

      t.timestamps default: -> { 'now()' }, null: false

      t.index :application_uid
      t.index :key_id
    end

    ApplicationKey.insert_all(application_keys)
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "cannot be reversed without reinstalling the composite_primary_keys gem"
  end
end
