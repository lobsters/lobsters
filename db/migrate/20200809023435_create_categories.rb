class CreateCategories < ActiveRecord::Migration[6.0]
  class Category < ActiveRecord::Base
    has_many :tags
  end
  class Tag < ActiveRecord::Base
    belongs_to :category
  end

  def change
    raise "You need to edit this migration to define categories matching your site" unless Rails.application.name == 'Lobsters'

    create_table :categories do |t|
      t.string :category

      t.timestamps
    end
    add_reference :tags, :category

    # list your tags in console with: Tag.all.pluck(:tag).join(' ')

    {
      compsci: %w{ai compsci distributed formalmethods graphics osdev plt programming networking},
      culture: %w{culture person philosophy law},
      field: %w{cogsci crypto education finance hardware math science},
      format: %w{ask audio pdf show slides transcript video},
      genre: %w{art book event historical job news rant release satire},
      interaction: %w{a11y design visualization},
      languages: %w{apl assembly c c++ clojure css d dotnet elixir elm erlang fortran go haskell java javascript lisp lua ml nodejs objectivec perl php python ruby rust scala swift},
      lobsters: %w{announce interview meta},
      os: %w{android dragonflybsd freebsd illumos ios linux mac netbsd openbsd unix windows},
      platforms: %w{browsers cryptocurrencies email games ipv6 mobile wasm web},
      practices: %w{api debugging devops performance practices privacy reversing scaling security testing virtualization},
      tools: %w{compilers databases emacs systemd vcs vim},
    }.each do |category, tags|
      c = Category.create! category: category
      Tag.where(tag: tags).update_all(category_id: c.id)
    end

    # if this is throwing an exception ("Data truncated for column"), there
    # are one or more tags with a null category_id
    change_column :tags, :category_id, :bigint, null: false

    # cleanups
    rename_column :tags, :inactive, :active
    change_column :tags, :active, :boolean, default: true, null: false
    change_column :tags, :privileged, :boolean, default: false, null: false
    change_column :tags, :is_media, :boolean, default: false, null: false
    Tag.update_all("active = !active")
  end
end
