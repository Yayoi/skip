class AddParentidToPages < ActiveRecord::Migration
  def self.up
    add_column :pages, :parent_id, :integer, :default=>0
  end

  def self.down
    remove_column :pages, :parent_id
  end
end
