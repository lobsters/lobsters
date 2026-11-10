# ANALYZE creates these and the dumper can't read their untyped columns.
ActiveRecord::SchemaDumper.ignore_tables << /\Asqlite_stat/
