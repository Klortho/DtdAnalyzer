#!/bin/sh

#Run this from dtdanalyzer/analyze

#Combine all dtdanalyzer files into one XML file

xslpath="/pmc/work/peterskm/stash/Projects/dtdanalyzer/DtdAnalyzer/xslt"
datapath="/pmc/work/peterskm/stash/Projects/dtdanalyzer/analyze"

cd source

    echo "Created combined files from dtdanalyzer XML files."

    echo "Create start tag for new root"

    echo '<final-list>' > $datapath/source/elements.xml
    
    echo 'Grab Green DTDs'
    find . -name "*arch.out*" > arch.txt

    echo 'Grab Blue DTDs'
    find . -name "*pub.out*" > pub.txt

    echo 'Grab Pumpkin DTDs'
    find . -name "nlm2.1.auth.out*" > 21.txt
    find . -name "nlm2.2.auth.out*" > 22.txt
    find . -name "nlm2.3.auth.out*" > 23.txt
    find . -name "nlm3.0.auth.out*" > 30.txt
    find . -name "jats1.0.auth.out*" > j10.txt
    find . -name "jats1.1d1.auth.out*" > j1d1.txt
    find . -name "jats1.1d2.auth.out*" > j1d2.txt
    find . -name "jats1.1d3.auth.out*" > j1d3.txt
    find . -name "jats1.1.auth.out*" > j11.txt

    echo 'Merge author text files'
    cat 21.txt 22.txt 23.txt 30.txt j10.txt j1d1.txt j1d2.txt j1d3.txt j11.txt > auth.txt

    echo 'Merge text files'
    cat arch.txt pub.txt auth.txt > elements.txt

    for p in `cat elements.txt`
    do echo "Strip XML declaration, pull source XML information"
    grep -vh '<?xml version="1.0" encoding="UTF-8"?>' $p >> $datapath/source/elements.xml
    done

    echo '</final-list>' >> $datapath/source/elements.xml

    echo "Remove text files"
    rm arch.txt pub.txt auth.txt 21.txt 22.txt 23.txt 30.txt j10.txt j1d1.txt j1d2.txt j1d3.txt j11.txt elements.txt

    cd ../
   
    

if [ -e source/elements.xml ]

then

echo "Restructuring source XML"
java -jar /pmc/JAVA/saxon9b/saxon9.jar -xsl:$xslpath/restructure_source.xsl -s:source/elements.xml -o:dtdcombined.xml nlm1arch="file:///pmc/load/converter3/dtd/nlm/1.0/archivearticle.dtd" nlm11arch="file:///pmc/load/converter3/dtd/nlm/1.1/archivearticle.dtd" nlm2arch="file:///pmc/load/converter3/dtd/nlm/2.0/archivearticle.dtd" nlm21arch="file:///pmc/load/converter3/dtd/nlm/2.1/archivearticle.dtd" nlm22arch="file:///pmc/load/converter3/dtd/nlm/2.2/archivearticle.dtd" nlm23arch="file:///pmc/load/converter3/dtd/nlm/2.3/archivearticle.dtd" nlm3arch="file:///pmc/load/converter3/dtd/nlm/3.0/archivearticle3.dtd" jats1arch="file:///pmc/load/converter3/dtd/niso-Z39.96/1.0/JATS-archivearticle1.dtd" jats1d1arch="file:///pmc/load/converter3/dtd/niso-Z39.96/1.1d1/JATS-archivearticle1.dtd" jats1d2arch="file:///pmc/load/converter3/dtd/niso-Z39.96/1.1d2/JATS-archivearticle1.dtd" jats1d3arch="file:///pmc/load/converter3/dtd/niso-Z39.96/1.1d3/JATS-archivearticle1.dtd" jats11arch="file:///pmc/load/converter3/dtd/niso-Z39.96/1.1/JATS-archivearticle1.dtd" nlm1pub="file:///pmc/load/converter3/dtd/nlm/1.0/journalpublishing.dtd" nlm11pub="file:///pmc/load/converter3/dtd/nlm/1.1/journalpublishing.dtd" nlm2pub="file:///pmc/load/converter3/dtd/nlm/2.0/journalpublishing.dtd" nlm21pub="file:///pmc/load/converter3/dtd/nlm/2.1/journalpublishing.dtd" nlm22pub="file:///pmc/load/converter3/dtd/nlm/2.2/journalpublishing.dtd" nlm23pub="file:///pmc/load/converter3/dtd/nlm/2.3/journalpublishing.dtd" nlm3pub="file:///pmc/load/converter3/dtd/nlm/3.0/journalpublishing3.dtd" jats1pub="file:///pmc/load/converter3/dtd/niso-Z39.96/1.0/JATS-journalpublishing1.dtd" jats1d1pub="file:///pmc/load/converter3/dtd/niso-Z39.96/1.1d1/JATS-journalpublishing1.dtd" jats1d2pub="file:///pmc/load/converter3/dtd/niso-Z39.96/1.1d2/JATS-journalpublishing1.dtd" jats1d3pub="file:///pmc/load/converter3/dtd/niso-Z39.96/1.1d3/JATS-journalpublishing1.dtd" jats11pub="file:///pmc/load/converter3/dtd/niso-Z39.96/1.1/JATS-journalpublishing1.dtd" nlm21auth="file:///pmc/load/converter3/dtd/nlm/2.1/articleauthoring.dtd" nlm22auth="file:///pmc/load/converter3/dtd/nlm/2.2/articleauthoring.dtd" nlm23auth="file:///pmc/load/converter3/dtd/nlm/2.3/articleauthoring.dtd" nlm3auth="file:///pmc/load/converter3/dtd/nlm/3.0/articleauthoring3.dtd" jats1auth="file:///pmc/load/converter3/dtd/niso-Z39.96/1.0/JATS-articleauthoring1.dtd" jats1d1auth="file:///pmc/load/converter3/dtd/niso-Z39.96/1.1d1/JATS-articleauthoring1.dtd" jats1d2auth="file:///pmc/load/converter3/dtd/niso-Z39.96/1.1d2/JATS-articleauthoring1.dtd" jats1d3auth="file:///pmc/load/converter3/dtd/niso-Z39.96/1.1d3/JATS-articleauthoring1.dtd" jats11auth="file:///pmc/load/converter3/dtd/niso-Z39.96/1.1/JATS-articleauthoring1.dtd"

else
echo "No such file found in this directory"

fi

if [ -e dtdcombined.xml ]

then
echo "Converting XML file to HTML"
java -jar /pmc/JAVA/saxon9b/saxon9.jar -xsl:$xslpath/final_element_list.xsl -s:dtdcombined.xml -o:dtdcombined.html

else
echo "No such file found in this directory"

fi


