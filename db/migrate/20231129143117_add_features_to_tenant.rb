class AddFeaturesToTenant < ActiveRecord::Migration[7.0]
  def change
    add_column :tenants, :feature_flags, :jsonb
  end
end
