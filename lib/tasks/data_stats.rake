desc "Generates data stats"
task data_stats: :environment do
  Rails.application.eager_load!

  tables = []
  ApplicationRecord.descendants.sort_by(&:to_s).each do |descendant|
    puts "querying table #{descendant.table_name}"

    table_stats = {
      class_name: descendant.to_s,
      table_name: descendant.table_name,
      row_count: descendant.count
    }

    table_stats[:columns] =
      descendant.columns.map do |column|
        puts "querying column #{descendant.table_name}.#{column.name}"

        case column.sql_type_metadata.type
        when :binary
          descendant.connection.exec_query(
            <<~SQL
              select
                avg(length(`#{column.name}`)) avg_length,
                stddev_pop(length(`#{column.name}`)) stddev_pop_length,
                count(`#{column.name}`) column_count
              from `#{descendant.table_name}`
            SQL
          ).to_a.first
        when :boolean
          descendant.connection.exec_query(
            <<~SQL
              select
                count(case `#{column.name}` when 0 then 1 end) count_false,
                count(case `#{column.name}` when 1 then 1 end) count_true,
                count(`#{column.name}`) column_count
              from `#{descendant.table_name}`
            SQL
          ).to_a.first
        when :date, :datetime
          descendant.connection.exec_query(
            <<~SQL
              select
                min(`#{column.name}`) min_,
                max(`#{column.name}`) max_,
                count(`#{column.name}`) column_count
              from `#{descendant.table_name}`
            SQL
          ).to_a.first
        when :decimal, :float, :integer
          descendant.connection.exec_query(
            <<~SQL
              select
                avg(`#{column.name}`) avg_,
                stddev_pop(`#{column.name}`) stddev_pop_,
                min(`#{column.name}`) min_,
                max(`#{column.name}`) max_,
                count(`#{column.name}`) column_count
              from `#{descendant.table_name}`
            SQL
          ).to_a.first.map { |k, v| [k, v.to_f] }.to_h # decimals sometimes get serialized to strings, so just cast to float since precision doesn't matter
        when :string
          descendant.connection.exec_query(
            <<~SQL
              select
                avg(char_length(`#{column.name}`)) avg_char_length,
                stddev_pop(char_length(`#{column.name}`)) stddev_pop_char_length,
                count(`#{column.name}`) column_count
              from `#{descendant.table_name}`
            SQL
          ).to_a.first
        when :text
          descendant.connection.exec_query(
            <<~SQL
              select
                avg(char_length(`#{column.name}`)) avg_char_length,
                stddev_pop(char_length(`#{column.name}`)) stddev_pop_char_length,
                avg(char_length(`#{column.name}`) - char_length(replace(`#{column.name}`, ' ', '')) + 1) avg_word_count,
                stddev_pop(char_length(`#{column.name}`) - char_length(replace(`#{column.name}`, ' ', '')) + 1) stddev_pop_word_count,
                count(`#{column.name}`) column_count
              from `#{descendant.table_name}`
            SQL
          ).to_a.first
        else
          raise "unknown type #{column.sql_type_metadata.type}"
        end.merge({column_name: column.name, column_type: column.sql_type_metadata.type})
      end

    tables << table_stats
  end

  File.write("/tmp/stats.json", JSON.pretty_generate(tables))
end
