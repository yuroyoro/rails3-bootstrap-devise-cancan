if Rails.env.development? || Rails.env.test?
  class String
    def pretty_format_sql
      require "anbt-sql-formatter/formatter"
      rule = AnbtSql::Rule.new
      rule.keyword = AnbtSql::Rule::KEYWORD_UPPER_CASE
      %w(count sum substr date).each{|func_name|
        rule.function_names << func_name.upcase
      }
      rule.indent_string = "    "
      formatter = AnbtSql::Formatter.new(rule)
      formatter.format(self)
    end
  end
end
