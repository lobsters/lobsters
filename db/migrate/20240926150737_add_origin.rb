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
    add_column :domains, :stories_count, :integer, null: false, default: 0

    create_table :origins do |t|
      t.references :domain, null: false
      t.string :identifier, null: false

      t.integer :stories_count, null: false, default: 0

      t.datetime :banned_at, null: true, default: nil
      t.integer :banned_by_user_id, null: true, default: nil
      t.string :banned_reason, limit: 200

      t.timestamps
    end
    add_column :moderations, :origin_id, :integer, null: true, default: nil
    add_index :moderations, :origin_id

    add_reference :stories, :origin, null: true

    # make Domain selectors for our most common sites
    if (d = Domain.find_by(domain: "github.com"))
      puts "Adding selector to #{d.domain} and updating #{d.stories.count} stories"
      d.selector = "\\Ahttps?://github.com/+([^/]+).*\\z"
      d.replacement = "github.com/\\1"
      d.save!
    end
    if (d = Domain.find_by(domain: "github.io"))
      puts "Adding selector to #{d.domain} and updating #{d.stories.count} stories"
      d.selector = "\\Ahttps?://([^\\.]+).github.io/+.*\\z"
      d.replacement = "github.com/\\1"
      d.save!
    end
    if (d = Domain.find_by(domain: "dev.to"))
      puts "Adding selector to #{d.domain} and updating #{d.stories.count} stories"
      d.selector = "\\Ahttps?://dev.to/+([^/]+).*\\z"
      d.replacement = "dev.to/\\1"
      d.save!
    end
    if (d = Domain.find_by(domain: "medium.com"))
      puts "Adding selector to #{d.domain} and updating #{d.stories.count} stories"
      d.selector = "\\Ahttps?://medium.com/+([^/]+).*\\z"
      d.replacement = "medium.com/\\1"
      d.save!
    end
    if (d = Domain.find_by(domain: "dataswamp.org"))
      puts "Adding selector to #{d.domain} and updating #{d.stories.count} stories"
      d.selector = "\\Ahttps?://dataswamp.org/+([^/]+).*\\z"
      d.replacement = "dataswamp.org/\\1"
      d.save!
    end

    Domain.update_all("stories_count = (select count(*) from stories where domain_id = domains.id)")
    Origin.update_all("stories_count = (select count(*) from stories where origin_id = origins.id)")
  end
end
