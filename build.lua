-- Uses Pandoc to convert Markdown files to HTML, then place the complete website into the `site` folder
-- 2026 CJHB

-- == File handling "library" ===========================================================
local file = {}

-- Checks whether an object (file or directory) exists at a path
--
-- Parameters:
-- - path: The path to check
--
-- Returns:
-- A boolean, which is true if the path exists, and false otherwise.
function file.exists(path)
	local ok, err = os.rename(path, path)

	if not ok then
		if code == 13 then
			-- permission denied, but still exists
			return true
		end
	end

	return ok, err
end

-- Checks whether a path is a directory or not
--
-- Parameters:
-- - path: The path to check
--
-- Returns:
-- A boolean, which is true if the path is a directory, and false if it is not. Also
-- returns false if the path does not exist.
function file.is_dir(path)
	return file.exists(path.."/")
end

-- == The rest of the program ===========================================================

-- Every Markdown file found by scan_dir()
local md_paths = {}

-- get a list of all of the .md files in `src`
local function scan_dir(path)
	if file.is_dir(path) then
		local objs = {}

		local ls = io.popen("ls "..path, "r")
		local dir = ""
		while dir ~= nil do
			dir = ls:read()

			if dir ~= nil then
				table.insert(objs, dir)
			end
		end
		ls:close()

		for _,v in pairs(objs) do
			local obj = path.."/"..v

			if file.is_dir(obj) then
				scan_dir(obj)

				-- create any subdirs that exist in "src"
				local exit = os.execute("mkdir site/"..obj:sub(5))
				if exit == false then
					print("Fatal error: could not make directory \"site/"..obj:sub(5).."\"")
				end
			elseif file.exists(obj) then
				if obj:sub(-3) == ".md" then
					print("Found markdown file: "..obj)
					table.insert(md_paths, obj)
				end
			end
		end
	else
		print("Warning: Skipping path \""..path.."\", as it does not exist or is not a directory")
	end
end

local function convert_files(tbl)
	for _,v in pairs(tbl) do
		-- convert "v" using pandoc
		print("Converting file \""..v.."\" to \"site/"..v:sub(5, -4)..".html\"")
		local exit = os.execute("pandoc -s --template src/pandoc-template.html -o site/"..v:sub(5, -4)..".html "..v)
		if exit == false then
			os.exit(1)
		end
	end
end

local function main()
	os.execute("rm -fr site")
	os.execute("mkdir site")

	scan_dir("src")
	convert_files(md_paths)

	-- copy everything in "deps" (stylesheets, images, etc.) to "site/"
	print("Copying contents of \"deps/\" to \"site/\"")
	os.execute("cp -r deps/* site/")
end

main()
