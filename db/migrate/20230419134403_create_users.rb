class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.references :subject, null: true, foreign_key: true

      t.integer :role, default: 0, null: false
      t.string :email, null: false
      t.string :name

      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
