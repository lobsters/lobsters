class FixLinksInInviteNotes < ActiveRecord::Migration[7.1]
  def up
    ModNote.where("note LIKE '%another user tried to redeem%'").find_each do |mod_note|
      mod_note.note = mod_note.note.gsub(/attempted redeemer: \[(.*)\].*\)/) do |match|
        "attempted redeemer: [#{$1}](https://#{Rails.application.domain}/~#{$1})"
      end
      mod_note.save!
    end
  end

  def down
    # time to roll forward
  end
end
