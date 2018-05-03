class AddHatToMessage < ActiveRecord::Migration[5.1]

  def change
    add_reference :messages, :hat, index: true
  end

end
