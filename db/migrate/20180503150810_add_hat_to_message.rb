class AddHatToMessage < ActiveRecord::Migration[6.0]

  def change
    add_reference :messages, :hat, index: true
  end

end
