class RemoveUserIdToUsers < ActiveRecord::Migration
  def up
    remove_column :users, :user_is
  end

  def down
    add_column :users, :user_is, :string
  end
end
