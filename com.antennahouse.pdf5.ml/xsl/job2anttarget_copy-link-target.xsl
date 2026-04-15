<?xml version="1.0" encoding="UTF-8"?>
<!--
    ****************************************************************
    DITA map with .job.xml to Ant file Stylesheet
    Module: ditamap to Ant file and extract resource paths from .job.xml templates
    Copyright © 2026 Antenna House, Inc. All rights reserved.
    Antenna House is a trademark of Antenna House, Inc.
    URL    : http://www.antennahouse.com/
    E-mail : info@antennahouse.com
    ****************************************************************
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:ahf="http://www.antennahouse.com/names/XSLT/Functions/Document"
  xmlns:ahs="http://www.antennahouse.com/names/XSLT/Document/Layout"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map" exclude-result-prefixes="xs ahf ahs map"
  default-mode="MODE_PROC_JOB_FOR_COPY">
  <xsl:output method="adaptive"/>
  <xsl:param name="PRM_INPUT_DIR" as="xs:anyURI" required="yes"/>
  <!--Referenced resources @outputclass -->
  <xsl:param name="PRM_TEMP_DIR" as="xs:anyURI" required="yes"/>
  <xsl:param name="PRM_OUTPUT_DIR" as="xs:anyURI" required="yes"/>

  <xsl:param name="PRM_LINK_TARGET_OUTPUT_CLASS" as="xs:string" required="yes"/>
  <xsl:param name="PRM_TARGET_NAME" as="xs:string" required="yes"/>
  
  
  <xsl:mode name="MODE_PROC_JOB_FOR_COPY" on-no-match="shallow-skip"/>
  
  <xsl:variable name="gInputDirNormalized" as="xs:string" select="$PRM_INPUT_DIR => ahf:bsToSlash()"/>
  <xsl:variable name="gLinkTargetOutputClass" as="xs:string+"
    select="$PRM_LINK_TARGET_OUTPUT_CLASS => tokenize('[,\s]')"/>
  <xsl:variable name="gFileList" as="map(xs:string, xs:string)" 
    select="let $list := //file[@input => empty()]
            return fold-left($list, map {}, function ($res, $cur) {
                      $res => map:put(string($cur/@path), string($cur/@result))}
                   )"/>
  <!--
  get rootmap
  note: expected rootmap has file@input="true"  on `.job.xml`
  -->
  <xsl:variable name="gInputMap" select="//file[@format = 'ditamap'][@input = 'true'][1]"
    as="element()"/>
  
  <xsl:import href="plugin:com.antennahouse.pdf5.ml:xsl/dita2fo_constants.xsl"/>
  <xsl:import href="plugin:com.antennahouse.pdf5.ml:xsl/dita2fo_util.xsl"/>
  <xsl:import href="plugin:com.antennahouse.pdf5.ml:xsl/dita2fo_error_util.xsl"/>
  <xsl:import href="plugin:com.antennahouse.pdf5.ml:xsl/dita2fo_message.xsl/"/>

  <xsl:template match="/" mode="MODE_PROC_JOB_FOR_COPY">
    <xsl:variable name="map"  as="document-node()"
      select="concat('file:///', $PRM_TEMP_DIR, '/', $gInputMap/@uri) => ahf:bsToSlash() => resolve-uri() => doc()"/>
    <!--
      target is like as
    `<topicref processing-role="resource-only" href="..." outputclass="<CONTAINS_TARGET>"/>`
    -->
    <xsl:variable name="targetElements" as="element()*" 
      select="$map/*[@class => contains-token('map/map')]//*[@class => contains-token('map/topicref')][string(@processing-role) eq 'resource-only'][@outputclass => ahf:seqContains($gLinkTargetOutputClass)]"/>
    
    <!--sanitize path-->
    <xsl:variable name="hrefSeq" as="xs:string*" select="$targetElements ! ahf:bsToSlash(@href)"/>
    <!--generate Ant temporal task -->
    <project>
      <target>
        <xsl:attribute name="name" select="$PRM_TARGET_NAME"/> 
        <xsl:for-each select="$hrefSeq">
          <xsl:variable name="relativePath" as="xs:string"
            select="$gFileList => map:get(.) => substring-after($gInputDirNormalized) => ahf:bsToSlash()"/>
          <copy>
            <xsl:attribute name="tofile"
              select="$PRM_OUTPUT_DIR || '${file.separator}' || $relativePath"/>
            <xsl:attribute name="file" select="$PRM_TEMP_DIR || '${file.separator}' || ."/>
          </copy>
        </xsl:for-each>
      </target>
    </project>
  </xsl:template>

</xsl:stylesheet>
