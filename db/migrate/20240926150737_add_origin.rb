class AddOrigin < ActiveRecord::Migration[7.2]
  def change
    change_table :domains, bulk: true do
      add_column :domains, :selector, :string, null: true
      add_column :domains, :replacement, :string, null: true
      add_column :domains, :stories_count, :integer, null: false, default: 0
    end

    # bad data in prod lobsters; using &. so this runs clean on sister sites
    # unused extra domain
    Domain.find_by(id: 20017, domain: "codingunicorn.dev")&.destroy!
    # duplicate for this domain
    story = Story.find_by(short_id: "5tw3fr")
    story&.update!(domain: Domain.find(20552))
    Domain.find_by(id: 20553, domain: "aaronhawley.livejournal.com")&.destroy!

    change_table :domains, bulk: true do
      add_index :domains, :domain, unique: true
    end

    create_table :origins do |t|
      t.references :domain, null: false
      t.string :identifier, null: false

      t.integer :stories_count, null: false, default: 0

      t.datetime :banned_at, null: true, default: nil
      t.integer :banned_by_user_id, null: true, default: nil
      t.string :banned_reason, limit: 200

      t.timestamps
    end
    change_table :moderations, bulk: true do
      add_column :moderations, :origin_id, :integer, null: true, default: nil
      add_index :moderations, :origin_id
    end

    add_reference :stories, :origin, null: true

    # make Domain selectors for our most common sites
    if (d = Domain.find_by(domain: "github.com"))
      Rails.logger.debug { "Adding selector to #{d.domain} and updating #{d.stories.count} stories" }
      d.selector = "\\Ahttps?://github.com/+([^/]+).*\\z"
      d.replacement = "github.com/\\1"
      d.save!
    end
    if (d = Domain.find_by(domain: "github.io"))
      Rails.logger.debug { "Adding selector to #{d.domain} and updating #{d.stories.count} stories" }
      d.selector = "\\Ahttps?://([^\\.]+).github.io/+.*\\z"
      d.replacement = "github.com/\\1"
      d.save!
    end
    if (d = Domain.find_by(domain: "dev.to"))
      Rails.logger.debug { "Adding selector to #{d.domain} and updating #{d.stories.count} stories" }
      d.selector = "\\Ahttps?://dev.to/+([^/]+).*\\z"
      d.replacement = "dev.to/\\1"
      d.save!
    end
    if (d = Domain.find_by(domain: "medium.com"))
      Rails.logger.debug { "Adding selector to #{d.domain} and updating #{d.stories.count} stories" }
      d.selector = "\\Ahttps?://medium.com/+([^/]+).*\\z"
      d.replacement = "medium.com/\\1"
      d.save!
    end
    if (d = Domain.find_by(domain: "dataswamp.org"))
      Rails.logger.debug { "Adding selector to #{d.domain} and updating #{d.stories.count} stories" }
      d.selector = "\\Ahttps?://dataswamp.org/+([^/]+).*\\z"
      d.replacement = "dataswamp.org/\\1"
      d.save!
    end

    Domain.update_all("stories_count = (select count(*) from stories where domain_id = domains.id)")
    Origin.update_all("stories_count = (select count(*) from stories where origin_id = origins.id)")
  end
end
