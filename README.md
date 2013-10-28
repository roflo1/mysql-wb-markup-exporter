mysql-wb-markup-exporter
===================================

# About

This is a fork from theMightyFly's Confluence Export Plugin for MySQL Workbench.

I did a quick hack to allow exporting to HTML, and should easily be modified to support other markup languages.

The original branch is here:
https://github.com/theMightyFly/mysql-wb-confluence-markup-exporter

What follows is mostly the original plugin's documentation which I haven't yet updates (expect some differences). You should still be able to figure out how to make it work.

## Credits
Generating MySQL Database Documentation for Confluence with MySQL Workbench Plugin

http://ralf.schaeftlein.de/2011/02/24/generating-mysql-database-documentation-for-confluence-with-mysql-workbench-plugin/

# Howto

## Install

1. Download an Exporter Script
2. Start your MySQL Workbench
3. Choose from the "scripting" menu the entry "Install Plugin/Module..."
4. Change Drop down in the Dialog to File type "lua Files.."
5. Choose downloaded File and click open
6. Restart Workbench

## Export markup
1. Open previously generated ER model file *.mwb
2. Choose from the "Plugins" menu the entry "Catalog" and their the new entry "Confluence Markup Exporter..."
3. Markup is now in the clipboard

## Import into Confluence
1. Open in Confluence an existing page or create a new onw
2. Click on "Edit" button and go to tab "Wiki Markup"
3. Paste the generated documentation and click on "save" button


# License 

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
