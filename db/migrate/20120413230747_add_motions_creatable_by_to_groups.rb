class AddMotionsCreatableByToGroups < ActiveRecord::Migration
  def up
    add_column :groups, :motions_creatable_by, :string

    Group.reset_column_information
    Group.all.each do |group|
      group.members_invitable_by = :members
      group.save
    end
  end

  def down
    remove_column :groups, :motions_creatable_by, :string
  end
end
