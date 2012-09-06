<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2">
  <pattern>
    <rule context='split'>
      <report test='count(banana) &lt; 4'>
        You need four bananas to make a bunch.  Many more is okay, too.
      </report>
    </rule>
    <rule context="banana">
      <assert test="@instrument != 'drums' or . = 'Bingo'">
        If he plays the drums, he must be Bingo!
      </assert>
    </rule>
    <rule context="@instrument">
      <assert test="not(parent::banana) or 
                    . = 'guitar' or . = 'drums' or . = 'bass' or . = 'keyboard'">
        Bananas can only play guitar, drums, bass, or keyboard.
      </assert>
    </rule>
  </pattern>
</schema>