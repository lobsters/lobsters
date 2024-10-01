class AddOrigin < ActiveRecord::Migration[7.2]
  def change
    add_column :domains, :selector, :string, null: true
    add_column :domains, :replacement, :string, null: true

    # bad data in prod lobsters; using &. so this runs clean on sister sites
    # unused extra domain
    Domain.find_by(id: 20017, domain: "codingunicorn.dev")&.destroy
    # duplicate for this domain
    story = Story.find_by(short_id: "5tw3fr")
    story&.update!(domain: Domain.find(20552))
    Domain.find_by(id: 20553, domain: "aaronhawley.livejournal.com")&.destroy

    add_index :domains, :domain, unique: true

    create_table :origins do |t|
      t.references :domain, null: false
      t.string :identifier, null: false

      t.timestamps
    end

    add_reference :stories, :origin, null: true
    add_index :stories, :origin
  end
end
