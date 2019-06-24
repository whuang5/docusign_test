class CreateAgreements < ActiveRecord::Migration[6.0]
  def change
    create_table :agreements do |t|
      t.string :name
      t.string :attachment
      t.timestamps
    end
  end
end
