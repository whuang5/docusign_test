class CreateAgreements < ActiveRecord::Migration[6.0]
  def change
    create_table :agreements do |t|
      t.string :preview_url
      t.string :names
      t.string :orders
      t.string :status
      t.string :emails
      t.string :attachment
      t.string :completed_attachment
      t.string :original_name
      t.string :content_type
      t.string :file_size
      t.string :envelope_id
      t.timestamps
    end
  end
end