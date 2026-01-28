require "active_support/concern"

module FullTextSearch
  def self.[](*cols)
    Module.new do
      extend ActiveSupport::Concern

      included do
        after_create do |record|
          table_name = "#{record.class.table_name}_fts"
          column_list = cols.join(", ")
          value_list = (["?"] * cols.length).join(", ")
          values = cols.map {|c| record.public_send(c) }

          ActiveRecord::Base.connection.exec_insert("INSERT INTO #{table_name} (rowid, #{column_list}) values (?, #{value_list})", nil, [record.id] + values)
        end

        after_update do |record|
          any_changes = cols.map {|c| record.saved_change_to_attribute(c) }.any?

          if any_changes
            # contentless-delete tables in sqlite require all the columns when updating them, see for more info:
            # https://www.sqlite.org/fts5.html#contentless_delete_tables

            table_name = "#{record.class.table_name}_fts"
            column_list = cols.map {|c| "#{c} = ?" }.join(", ")
            values = cols.map {|c| record.public_send(c) }

            ActiveRecord::Base.connection.exec_update("UPDATE #{table_name} set #{column_list} where rowid = ?", nil, values + [record.id])
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
