class CreateMessagesTags < ActiveRecord::Migration[7.0]
  def change
    create_table :messages_tags do |t|
      t.references :message, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end
  end
end
