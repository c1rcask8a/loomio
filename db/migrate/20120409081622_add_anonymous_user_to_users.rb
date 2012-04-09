class AddAnonymousUserToUsers < ActiveRecord::Migration
  def self.up
    user = User.create!( :email => 'anonymous@loom.io', :name => 'Anonymous', :password => 'password' )
  end

  def self.down
    user = User.find_by_email( 'anonymous@loom.io' )
    user.destroy
  end
end
