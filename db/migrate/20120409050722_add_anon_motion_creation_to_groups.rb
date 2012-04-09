class AddAnonMotionCreationToGroups < ActiveRecord::Migration
  def change
    add_column :groups, :anon_motion_creation, :boolean
  end
end
