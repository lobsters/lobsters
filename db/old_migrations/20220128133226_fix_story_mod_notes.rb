class FixStoryModNotes < ActiveRecord::Migration[6.1]
  def up
    # fix formatting in existing notes
    ActiveRecord::Base.connection.execute <<~SQL
      update mod_notes set note = 
        replace(
          replace(
            replace(
              replace(
                note,
                "\nurl: ", "\n- url: "
              ),
              "title: ", "\n- title: "
            ),
            "user_is_author: ", "\n- user_is_author: "
          ),
          "etags: ", "e\n- tags: "
        )
      where note like "Attempted to post a story %";
    SQL
    # rerender markdown
    ModNote.where('note like "Attempted to post a story %"').each do |mn|
      mn.markeddown_note = mn.generated_markeddown
      mn.save!
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
