OrScopes
--------

This [gist](https://gist.github.com/j-mcnally/250eaaceef234dd8971b) by [j-mcnally](https://gist.github.com/j-mcnally) as a rails plugin.

__without arguments__

If #or is used without arguments, it returns an ActiveRecord::OrChain object that can
be used to chain queries with any other relation method, like where:

<pre>
  Post.where("id = 1").or.where("id = 2")
  # SELECT `posts`.* FROM `posts`  WHERE (('id = 1' OR 'id = 2'))
</pre>

It can also be chained with a named scope:

<pre>
  Post.where("id = 1").or.containing_the_letter_a
  # SELECT `posts`.* FROM `posts`  WHERE (('id = 1' OR 'body LIKE \\'%a%\\''))
</pre>
  

__ActiveRecord::Relation__

When #or is used with an ActiveRecord::Relation as an argument, it merges the two
relations, with the exception of the WHERE clauses, that are joined using the OR
operand.

<pre>
  Post.where("id = 1").or(Post.where("id = 2"))
  # SELECT `posts`.* FROM `posts`  WHERE (('id = 1' OR 'id = 2'))
</pre>

__anything you would pass to #where__

\#or also accepts anything that could be passed to the #where method, as
a shortcut:

<pre>
  Post.where("id = 1").or("id = ?", 2)
  # SELECT `posts`.* FROM `posts`  WHERE (('id = 1' OR 'id = 2'))
</pre>


