require "active_support/concern"

module FullTextSearch
  def self.[](*cols)
    Module.new do
      extend ActiveSupport::Concern

      included do
        after_create do |record|
          fts = Arel::Table.new("#{record.class.table_name}_fts")
          values = cols.map { |c| [fts[c], record.public_send(c)] }

          ActiveRecord::Base.connection.insert(Arel::InsertManager.new(fts).insert([[fts[:rowid], record.id]] + values))
        end

        after_update do |record|
          any_changes = cols.map { |c| record.saved_change_to_attribute(c) }.any?

          if any_changes
            # contentless-delete tables in sqlite require all the columns when updating them, see for more info:
            # https://www.sqlite.org/fts5.html#contentless_delete_tables

            fts = Arel::Table.new("#{record.class.table_name}_fts")
            values = cols.map { |c| [fts[c], record.public_send(c)] }

            ActiveRecord::Base.connection.update(Arel::UpdateManager.new(fts).set(values).where(fts[:rowid].eq(record.id)))
          end
        end

        after_destroy do |record|
          table_name = "#{record.class.table_name}_fts"

          ActiveRecord::Base.connection.exec_delete("DELETE FROM #{table_name} where rowid = ?", nil, [record.id])
        end
      end
    end
  end
end
