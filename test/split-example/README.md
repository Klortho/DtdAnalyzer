This directory holds a complete example that should include at least one of the major features
of a DTD that is handled by the DtdAnalyzer.  The file split-mockup.daz.xml is a mockup of what
the output should look like, including how all the annotations are extracted and put into the
output.

Note the two new additions, that aren't described in the paper:
* Top-level annotations element is for the "!dtd" annotations.
* The top-level <modules> element is constructed based on the "!module" annotations.
  It uses the name in the structured comment line and cross-references that to a
  system and public id, so that we can cross-reference each element, attribute, and
  entity to the module in which it is defined.
