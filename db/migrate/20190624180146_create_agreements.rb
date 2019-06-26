class CreateAgreements < ActiveRecord::Migration[6.0]
  def change
    create_table :agreements do |t|
      t.string :name
      t.string :status
      t.string :emails
      t.string :attachment
      t.string :envelope_id
      t.timestamps
    end
  end
end
