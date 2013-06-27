 --
 -- Copyright 2013 Ralf Schäftlein
 -- 
 -- Licensed under the Apache License, Version 2.0 (the "License"); you may not
 -- use this file except in compliance with the License. You may obtain a copy of
 -- the License at
 --
 -- http://www.apache.org/licenses/LICENSE-2.0
 -- 
 -- Unless required by applicable law or agreed to in writing, software
 -- distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 -- WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 -- License for the specific language governing permissions and limitations under
 -- the License.
 
-- standard plugin functions
--
-- this function is called first by MySQL Workbench core to determine number of
-- plugins in this module and basic plugin info
-- see the comments in the function body and adjust the parameters as appropriate
--


function getModuleInfo()

    -- module properties
    local props =
        {
            -- module name (ID)
            name = "MySQLConfluenceMarkupExporter",

            -- module author(s)
            author = "Ralf Schaeftlein",

            --module version
            version = "1.0.2",

            -- interface implemented by this module
            implements = "PluginInterface",

            -- plugin functions exposed by this module
            -- l looks like a parameterized list, i instance, o object, @ fully qualified class name
            functions =
                {
                    "getPluginInfo:l<o@app.Plugin>:",
                    "exportMarkupToClipboard:i:o@db.Catalog",
                    "exportHTMLMarkupToClipboard:i:o@db.Catalog"
                }
        }

    -- can't assign inside declaration
    props.name = props.name .. props.version

    return props
end

function objectPluginInput(type)

    return grtV.newObj("app.PluginObjectInput", {objectStructName = type})

end

function getPluginInfo()

    -- list of plugins this module exposes (list object of type app.Plugin?)
    local l = grtV.newList("object", "app.Plugin")

    -- plugin instances
    local plugin

    local props = getModuleInfo()

    -- new plugin: export Confluence to clipboard
    plugin = createNewPlugin("wb.catalog.util.exportMarkupToClipboard" .. props.version,
                             "Confluence Markup Exporter " .. props.version .. ": Copy to Clipboard",
                             props.name,
                             "exportMarkupToClipboard",
                             {objectPluginInput("db.Catalog")},
                             {"Catalog/Utilities", "Menu/Catalog"})

    -- append to list of plugins
    grtV.insert(l, plugin)

    -- new plugin: export HTML to clipboard
    plugin = createNewPlugin("wb.catalog.util.exportHTMLMarkupToClipboard" .. props.version,
                             "HTML Markup Exporter " .. props.version .. ": Copy to Clipboard",
                             props.name,
                             "exportHTMLMarkupToClipboard",
                             {objectPluginInput("db.Catalog")},
                             {"Catalog/Utilities", "Menu/Catalog"})

    -- append to list of plugins
    grtV.insert(l, plugin)

    return l
end

function createNewPlugin(name, caption, moduleName, moduleFunctionName, inputValues, groups)

    -- create dictionary, Lua seems to handle keys and values right...
    local props =
        {
            name = name,
            caption = caption,
            moduleName = moduleName,
            pluginType = "normal",
            moduleFunctionName = moduleFunctionName,
            inputValues = inputValues,
            rating = 100,
            showProgress = 0,
            groups = groups
        }

    local plugin = grtV.newObj("app.Plugin", props)

    -- set owner???
    plugin.inputValues[1].owner = plugin

    return plugin
end

--
-- Print some version information and copyright to the output window
function printVersion()
    print("\n\n\MySQL Schema to Confluence/HTML Markup Exporter v" .. getModuleInfo().version .. "\nCopyright (c) 2013 Ralf Schaeftlein - License: Apache License 2.0");
end

-- export function #1
function exportMarkupToClipboard(catalog)

    printVersion()
    local markup = generateConfluenceMarkup(catalog)

    Workbench:copyToClipboard(markup)

    print('\n > Confluence Markup  copied to clipboard')

    return 0
end




--
-- generates the confluence markup
function generateConfluenceMarkup(cat)
    local i, j, schema, tbl
    local markup = ""
    local optionsSetFlag = false

    for i = 1, grtV.getn(cat.schemata) do
        schema = cat.schemata[i]

        --print(schema)

        for j = 1, grtV.getn(schema.tables) do
            tbl = schema.tables[j]

            --
            -- do not export *_translation tables
            if (tbl.name ~= nil and tbl.name ~= "" and string.ends(tbl.name, "_translation") == false ) then
                markup = buildMarkupForSingleTable(tbl, schema, markup)
            end
        end
    end

    --print(markup)

    return markup
end


function buildMarkupForSingleTable(tbl, schema, markup)
    local k, l, col, index, column
    local actAsPart = ""
    local actAs = ""

    --
    -- start of adding a table
	markup = markup .. "h4. Tablestructure for table " .. tbl.name .. "\n"
	
	markup = markup .. "\n"
	
	if ( tbl.comment ~= nil and tbl.comment ~= "" ) then
		markup = markup .. tbl.comment .. "\n"
	end	

	markup = markup .. "\n"
	
	if (     tbl.tableEngine ~= nil and tbl.tableEngine ~= "") then
		markup = markup .. " engine " .. tbl.tableEngine .. "\n"
	end
	
	if ( tbl.defaultCharacterSetName ~= nil and tbl.defaultCharacterSetName ~= "" ) then
        markup = markup .. " charset: " .. tbl.defaultCharacterSetName .. "\n"
	end	
	if ( tbl.defaultCollationName ~= nil and tbl.defaultCollationName ~= "" ) then
		markup = markup .. " collation: " .. tbl.defaultCollationName .. "\n"
    end

	markup = markup .. "\n"
	
    markup = markup .. "|| *Column* || *Type* || *Null* || *autoincrement* || *default* || *Primary* || *Unique* || *Description*||\n"	
	
    --
    -- iterate through the table columns
    for k = 1, grtV.getn(tbl.columns) do
        col = tbl.columns[k]
        markup = buildMarkupForSingleColumn(tbl, col, markup)
    end

	markup = markup .. "\n"
	
	-- table index
    local indexes = ""
    for k = 1, grtV.getn(tbl.indices) do
        index = tbl.indices[k]
        if ( index.indexType == "INDEX" ) then
            indexes = indexes .. "| " .. index.name .. " | "
            for l = 1, grtV.getn(index.columns) do
                column = index.columns[l]
                indexes = indexes .. column.referencedColumn.name
                if ( l < grtV.getn(index.columns) ) then
                    indexes = indexes .. ", "
                end
            end
            indexes = indexes .. " | INDEX |\n"
        end
    end
    
	if ( indexes ~= nil and indexes ~= "") then
		markup = markup .. "h5. Indexes \n"
		markup = markup .. "|| *Name* || *Columns* || *Type* ||\n" 
		markup = markup .. indexes
	end
    
    -- final line break
    return markup .. "\n"
end

function buildMarkupForSingleColumn(tbl, col, markup)
    local l, m, p, u, n

	-- column name
	markup = markup .. "| " .. col.name .. " | " 
	
	-- column type
	if ( col.simpleType ~= nil ) then
		markup = markup .. col.simpleType.name 
	end	
	
	if ( col.length ~= -1 ) then
        markup = markup.. "(" ..col.length.. ")"
    end
	
	markup = markup .. " | "
	
	-- column not null?
	if ( col.isNotNull == 1 ) then
		markup = markup .. " NOT NULL " .. " | "
	else
	    markup = markup .. " NULL " .. " | "
	end
	
	-- autoincrement
	if ( col.autoIncrement == 1 ) then
		markup = markup ..  " true |"
	else 
	   markup = markup ..  " false |"
	end
	
	-- default
	if ( col.defaultValue ~= '') then
		markup = markup .. col.defaultValue .. " | " 
	else 
		markup = markup .. " | " 
	end 
	
	p = " false "
	u = " false "
	for m = 1, grtV.getn(tbl.indices) do
        index = tbl.indices[m]
        --
        -- checking for primary index
        if ( index.indexType == "PRIMARY" ) then
            for l = 1, grtV.getn(index.columns) do
                column = index.columns[l]
                if ( column.referencedColumn.name == col.name ) then
                    p = " true "
                end
            end
        end
        --
        -- checking for unique index
        if ( index.indexType == "UNIQUE" ) then
            -- check if just one column in index
            if ( grtV.getn(index.columns) == 1 ) then
                for l = 1, grtV.getn(index.columns) do
                    column = index.columns[l]
                    if ( column.referencedColumn.name == col.name ) then
                        u = " true "
                    end
                end
            end
        end
    end
	
	-- primary key?
	markup = markup .. p .. " | "
	
	-- unique key?
	markup = markup .. u .. " | "
	
	-- description
    if ( col.comment ~= nil and col.comment ~= '') then
		markup = markup .. col.comment 
	end
	
  	-- fk?
	for n = 1, grtV.getn(tbl.foreignKeys) do
		fk = tbl.foreignKeys[n]
		if ( fk.columns[1].name == col.name ) then
			markup = markup .. " (foreign key to table  " .. fk.referencedColumns[1].owner.name .. " column " .. fk.referencedColumns[1].name .. " ) "
		end 
	end
	
	markup = markup .. " | \n"
	
	
    return markup
end







-- export function #2
function exportHTMLMarkupToClipboard(catalog)

    printVersion()
    local markup = generateHTMLMarkup(catalog)

    Workbench:copyToClipboard(markup)

    print('\n > HTML Markup copied to clipboard')

    return 0
end


--
-- generates the HTML markup
function generateHTMLMarkup(cat)

    markup = {}
    markup["title_start"] = "<h2>"
    markup["title_end"] = "</h2>\n"
    markup["eol"] = "\n"
    markup["table_start"] = "<table>\n"
    markup["table_end"] = "</table>\n"
    markup["row_start"] = "<tr>"
    markup["row_end"] = "</tr>\n"
    markup["cell_header_start"] = "<th>"
    markup["cell_header_end"] = "</th>"
    markup["cell_data_start"] = "<td>"
    markup["cell_data_end"] = "</td>"
    markup["subtitle_start"] = "<h3>"
    markup["subtitle_end"] = "</h3>\n"

    return generateGenericMarkup(cat, markup)
end



-- GENERIC Markup functions...

--
-- generates a Generic markup
function generateGenericMarkup(cat, mktags)
    local i, j, schema, tbl
    local markup = ""
    local optionsSetFlag = false

    for i = 1, grtV.getn(cat.schemata) do
        schema = cat.schemata[i]

        --print(schema)

        for j = 1, grtV.getn(schema.tables) do
            tbl = schema.tables[j]

            --
            -- do not export *_translation tables
            if (tbl.name ~= nil and tbl.name ~= "" and string.ends(tbl.name, "_translation") == false ) then
				markup = buildGenericMarkupForSingleTable(tbl, schema, markup, mktags)
            end
        end
    end

    --print(markup)

    return markup
end

function buildGenericMarkupForSingleTable(tbl, schema, markup, mktags)
    local k, l, col, index, column
    local actAsPart = ""
    local actAs = ""

    --
    -- start of adding a table
	markup = markup .. mktags["title_start"] .."Tablestructure for table " .. tbl.name .. mktags["title_end"]
	
	markup = markup .. mktags["eol"]
	
	if ( tbl.comment ~= nil and tbl.comment ~= "" ) then
		markup = markup .. tbl.comment .. mktags["eol"]
	end	

	markup = markup .. mktags["eol"]
	
	if (     tbl.tableEngine ~= nil and tbl.tableEngine ~= "") then
		markup = markup .. " engine " .. tbl.tableEngine .. mktags["eol"]
	end
	
	if ( tbl.defaultCharacterSetName ~= nil and tbl.defaultCharacterSetName ~= "" ) then
        markup = markup .. " charset: " .. tbl.defaultCharacterSetName .. mktags["eol"]
	end	
	if ( tbl.defaultCollationName ~= nil and tbl.defaultCollationName ~= "" ) then
		markup = markup .. " collation: " .. tbl.defaultCollationName .. mktags["eol"]
    end

	markup = markup .. mktags["eol"]
	
	markup = markup .. mktags["table_start"]
    markup = markup .. mktags["row_start"] ..mktags["cell_header_start"].."*Column* "..mktags["cell_header_end"]..mktags["cell_header_start"].." *Type* "..mktags["cell_header_end"]..mktags["cell_header_start"].." *Null* "..mktags["cell_header_end"]..mktags["cell_header_start"]
	markup = markup .. "*autoincrement* "..mktags["cell_header_end"]..mktags["cell_header_start"].." *default* "..mktags["cell_header_end"].. mktags["cell_header_start"].." *Primary* "
	markup = markup .. mktags["cell_header_end"]..mktags["cell_header_start"].." *Unique* "..mktags["cell_header_end"]..mktags["cell_header_start"].." *Description*"..mktags["cell_header_end"]..mktags["row_end"]	
	
    --
    -- iterate through the table columns
    for k = 1, grtV.getn(tbl.columns) do
        col = tbl.columns[k]
		markup = buildGenericMarkupForSingleColumn(tbl, col, markup, mktags)
    end
	markup = markup .. mktags["table_end"]

	
	-- table index
    local indexes = ""
    for k = 1, grtV.getn(tbl.indices) do
        index = tbl.indices[k]
        if ( index.indexType == "INDEX" ) then
            indexes = indexes .. mktags["cell_data_start"] .. index.name .. mktags["cell_data_end"] .. mktags["cell_data_start"]
            for l = 1, grtV.getn(index.columns) do
                column = index.columns[l]
                indexes = indexes .. column.referencedColumn.name
                if ( l < grtV.getn(index.columns) ) then
                    indexes = indexes .. ", "
                end
            end
            indexes = mktags["row_start"]..indexes .. mktags["cell_data_end"] .. mktags["cell_data_start"].."INDEX"..mktags["cell_data_end"]..mktags["row_end"]
        end
    end
    
	if ( indexes ~= nil and indexes ~= "") then
		markup = markup .. mktags["subtitle_start"].."Indexes"..mktags["subtitle_end"]
		markup = markup .. mktags["table_start"]
		markup = markup .. mktags["row_start"]..mktags["cell_data_start"].." *Name* "..mktags["cell_data_end"]..mktags["cell_data_start"].." *Columns* "..mktags["cell_data_end"]..mktags["cell_data_start"].." *Type* "..mktags["cell_data_end"] .. mktags["row_end"]
		markup = markup .. indexes
		markup = markup .. mktags["table_end"]
	end

	return markup
end


function buildGenericMarkupForSingleColumn(tbl, col, markup, mktags)
    local l, m, p, u, n

	-- column name
	markup = markup .. mktags["row_start"] .. mktags["cell_data_start"] .. col.name .. mktags["cell_data_end"] .. mktags["cell_data_start"]
	
	-- column type
	if ( col.simpleType ~= nil ) then
		markup = markup .. col.simpleType.name 
	end	
	
	if ( col.length ~= -1 ) then
        markup = markup.. "(" ..col.length.. ")"
    end
	
	markup = markup .. mktags["cell_data_end"] .. mktags["cell_data_start"]
	
	-- column not null?
	if ( col.isNotNull == 1 ) then
		markup = markup .. " NOT NULL " .. mktags["cell_data_end"] .. mktags["cell_data_start"]
	else
	    markup = markup .. " NULL " .. mktags["cell_data_end"] .. mktags["cell_data_start"]
	end
	
	-- autoincrement
	if ( col.autoIncrement == 1 ) then
		markup = markup ..  " true " .. mktags["cell_data_end"] .. mktags["cell_data_start"]
	else 
	   markup = markup ..  " false " .. mktags["cell_data_end"] .. mktags["cell_data_start"]
	end
	
	-- default
	if ( col.defaultValue ~= '') then
		markup = markup .. col.defaultValue .. mktags["cell_data_end"] .. mktags["cell_data_start"] 
	else 
		markup = markup .. mktags["cell_data_end"] .. mktags["cell_data_start"]
	end 
	
	p = " false "
	u = " false "
	for m = 1, grtV.getn(tbl.indices) do
        index = tbl.indices[m]
        --
        -- checking for primary index
        if ( index.indexType == "PRIMARY" ) then
            for l = 1, grtV.getn(index.columns) do
                column = index.columns[l]
                if ( column.referencedColumn.name == col.name ) then
                    p = " true "
                end
            end
        end
        --
        -- checking for unique index
        if ( index.indexType == "UNIQUE" ) then
            -- check if just one column in index
            if ( grtV.getn(index.columns) == 1 ) then
                for l = 1, grtV.getn(index.columns) do
                    column = index.columns[l]
                    if ( column.referencedColumn.name == col.name ) then
                        u = " true "
                    end
                end
            end
        end
    end
	
	-- primary key?
	markup = markup .. p .. mktags["cell_data_end"] .. mktags["cell_data_start"]
	
	-- unique key?
	markup = markup .. u .. mktags["cell_data_end"] .. mktags["cell_data_start"]
	
	-- description
    if ( col.comment ~= nil and col.comment ~= '') then
		markup = markup .. col.comment 
	end
	
  	-- fk?
	for n = 1, grtV.getn(tbl.foreignKeys) do
		fk = tbl.foreignKeys[n]
		if ( fk.columns[1].name == col.name ) then
			markup = markup .. " (foreign key to table  " .. fk.referencedColumns[1].owner.name .. " column " .. fk.referencedColumns[1].name .. " ) "
		end 
	end
	
	markup = markup .. mktags["cell_data_end"] .. mktags["row_end"] .. mktags["eol"]
	
	
    return markup
end




function string.ends(String,End)
   return End=='' or string.sub(String,-string.len(End))==End
end
