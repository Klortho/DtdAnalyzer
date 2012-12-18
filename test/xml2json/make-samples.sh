rm *-2json.xsl

dtd2xml2json -s sample1.dtd -b ../../xslt/xml2json.xsl sample1-2json.xsl
xsltproc sample1-2json.xsl sample1.xml > sample1.json

dtd2xml2json -s sample2.dtd -b ../../xslt/xml2json.xsl sample2-2json.xsl
xsltproc sample2-2json.xsl sample2a.xml > sample2a.json
xsltproc sample2-2json.xsl sample2b.xml > sample2b.json
xsltproc sample2-2json.xsl sample2c.xml > sample2c.json

dtd2xml2json -s sample3.dtd -b sample3.xsl sample3-2json.xsl
xsltproc sample3-2json.xsl sample3.xml > sample3.json

dtd2xml2json -s sample4.dtd -b ../../xslt/xml2json.xsl sample4-2json.xsl
xsltproc sample4-2json.xsl sample4.xml > sample4.json

