# Kludge for AR generating invalid SQLite SQL, from https://github.com/rails/rails/pull/59707
module ArelSqliteUnionOperandsUnwrapped
  def grouping_parentheses(o, collector, always_wrap_selects = true)
    return visit(o, collector) unless always_wrap_selects

    super
  end
end

Arel::Visitors::SQLite.prepend(ArelSqliteUnionOperandsUnwrapped)
