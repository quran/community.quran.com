class CreateFeedbacks < ActiveRecord::Migration[6.0]
  def change
    create_table :feedbacks do |t|
      t.string :title
      t.text :message
      t.string :email
      t.string :url
      t.string :image
      t.timestamps
    end
  end
end
