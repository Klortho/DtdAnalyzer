JATSCon 2012 Paper
==================

This paper was prepared for [JATSCon 2012](http://jats.nlm.nih.gov/jats-con/).

The main source is jatscon-paper.xml.  It uses declares and uses some external
entities for the code snippets and other examples.  Each of those code snippets
is a file in this directory; the complete list is gist-list.txt (they used to
be individual gists).

To get the snippet included in the paper, it must be XML-escaped.  The perl
script gist-escape.pl does this, rewriting each "gist" to a file with the
same name, but an extension ".ent".

So, to "build" this paper, starting from the contents here in github:
* Run gist-escape.pl

If you add a gist, or change the name of one, you'll have to update the
list of entity definitions at the top of jatscon-paper.xml.  The gist-escape.pl
script conveniently prints this out for you, so you can just copy-paste.
