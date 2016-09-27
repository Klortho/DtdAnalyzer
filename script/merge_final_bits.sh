#!/bin/sh

# Run this from dtdanalyzer/analyze

# This is strictly for BITS

xslpath="/pmc/work/peterskm/stash/Projects/dtdanalyzer/DtdAnalyzer/xslt"
datapath="/pmc/work/peterskm/stash/Projects/dtdanalyzer/analyze"

cd source

echo "Created combined file from dtdanalyzer XML files."

echo "Create start tag for new root"

echo '<final-list>' > $datapath/source/bits_elements.xml

echo 'Grab Brown DTDs'
find . -name "bits0.1.out*" > b01.txt
find . -name "bits0.2.out*" > b02.txt
find . -name "bits1.0.out*" > b10.txt
find . -name "bits2.0.out*" > b20.txt

echo 'Merge bits text files'
cat b01.txt b02.txt b10.txt b20.txt > bits_elements.txt

for p in `cat bits_elements.txt`
do echo "Strip XML declaration, pull source XML information"
grep -vh '<?xml version="1.0" encoding="UTF-8"?>' $p >> $datapath/source/bits_elements.xml
done

echo '</final-list>' >> $datapath/source/bits_elements.xml

echo "Remove text files"
rm b01.txt b02.txt b10.txt b20.txt bits_elements.txt

cd ../


if [ -e source/bits_elements.xml ]

then

echo "Remove extra #PCDATA OR bars from content-model/@spaced attribute values"
sed 's/( #PCDATA | )\*/( #PCDATA )\*/' source/bits_elements.xml > source/bits_elements_clean.xml

echo "Restructuring source XML"
java -jar /pmc/JAVA/saxon9b/saxon9.jar -xsl:$xslpath/restructure_source.xsl -s:source/bits_elements_clean.xml -o:bits_elements.xml bits01="file:///pmc/load/converter3/dtd/bits/0.1/BITS-book0.dtd" bits02="file:///pmc/load/converter3/dtd/bits/0.2/BITS-book0.dtd" bits10="file:///pmc/load/converter3/dtd/bits/1.0/BITS-book1.dtd" bits20="file:///pmc/load/converter3/dtd/bits/2.0/BITS-book2.dtd"

else
echo "No such file found in this directory"

fi

if [ -e bits_elements.xml ]

then
echo "Converting XML file to HTML"
java -jar /pmc/JAVA/saxon9b/saxon9.jar -xsl:$xslpath/final_element_list.xsl -s:bits_elements.xml -o:bits_elements.html

echo "Remove clean file"
rm source/bits_elements_clean.xml

else
echo "No such file found in this directory"

fi
