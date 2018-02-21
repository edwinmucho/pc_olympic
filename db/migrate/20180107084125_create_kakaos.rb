class CreateKakaos < ActiveRecord::Migration
  def change
    create_table :kakaos do |t|

      t.timestamps null: false
    end
  end
end
