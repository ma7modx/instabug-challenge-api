class CreateBugIndexOnElasticsearch < ActiveRecord::Migration
  def change
    Bug.__elasticsearch__.create_index!
    Bug.import
  end
end
