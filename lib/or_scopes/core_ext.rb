# Author: https://gist.github.com/j-mcnally/250eaaceef234dd8971b

module ActiveRecord
  module Querying
    delegate :or, :to => :all
  end
end

module ActiveRecord
  module QueryMethods
    # OrChain objects act as placeholder for queries in which #or does not have any parameter.
    # In this case, #or must be chained with any other relation method to return a new relation.
    # It is intended to allow .or.where() and .or.named_scope.
    class OrChain
      def initialize(scope)
        @scope = scope
      end
 
      def method_missing(method, *args, &block)
        right_relation = @scope.klass.unscoped do
          @scope.klass.send(method, *args, &block)
        end
        @scope.or(right_relation)
      end
    end

    # Returns a new relation, which is the result of filtering the current relation
    # according to the conditions in the arguments, joining WHERE clauses with OR
    # operand, contrary to the default behaviour that uses AND.
    #
    # #or accepts conditions in one of several formats. In the examples below, the resulting
    # SQL is given as an illustration; the actual query generated may be different depending
    # on the database adapter.
    #
    # === without arguments
    #
    # If #or is used without arguments, it returns an ActiveRecord::OrChain object that can
    # be used to chain queries with any other relation method, like where:
    #
    #    Post.where("id = 1").or.where("id = 2")
    #    # SELECT `posts`.* FROM `posts`  WHERE (('id = 1' OR 'id = 2'))
    #
    # It can also be chained with a named scope:
    #
    #    Post.where("id = 1").or.containing_the_letter_a
    #    # SELECT `posts`.* FROM `posts`  WHERE (('id = 1' OR 'body LIKE \\'%a%\\''))
    #
    # === ActiveRecord::Relation
    #
    # When #or is used with an ActiveRecord::Relation as an argument, it merges the two
    # relations, with the exception of the WHERE clauses, that are joined using the OR
    # operand.
    #
    #    Post.where("id = 1").or(Post.where("id = 2"))
    #    # SELECT `posts`.* FROM `posts`  WHERE (('id = 1' OR 'id = 2'))
    #
    # === anything you would pass to #where
    #
    # #or also accepts anything that could be passed to the #where method, as
    # a shortcut:
    #
    #    Post.where("id = 1").or("id = ?", 2)
    #    # SELECT `posts`.* FROM `posts`  WHERE (('id = 1' OR 'id = 2'))
    #
    def or(opts = :chain, *rest)
      if opts == :chain
        OrChain.new(self)
      else
        left = with_default_scope
        right = (ActiveRecord::Relation === opts) ? opts : klass.unscoped.where(opts, rest)

        unless left.where_values.empty? || right.where_values.empty?
          left.where_values = [left.where_ast.or(right.where_ast)]
          right.where_values = []
        end

        left = left.merge(right)
      end
    end


    # Returns an Arel AST containing only where_values
    def where_ast
      arel_wheres = []

      where_values.each do |where|
        arel_wheres << (String === where ? Arel.sql(where) : where)
      end

      return Arel::Nodes::And.new(arel_wheres) if arel_wheres.length >= 2

      if Arel::Nodes::SqlLiteral === arel_wheres.first
        Arel::Nodes::Grouping.new(arel_wheres.first)
      else
        arel_wheres.first
      end
    end

  end
end

