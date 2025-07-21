--[[
  WebP conversion filter for Quarto.
  Converts .png images to lossless .webp for HTML output.
  Requires cwebp command-line tool to be installed and available in PATH.
  Updates image references and logs size savings.
  Usage:
    Add this filter to your Quarto project by including it in the YAML front matter:
    filters:
      - convert-to-webp.lua
    Optional: delete original .png files:
    webp-delete-originals: true
]]

local Q <const> = quarto
local log <const> = Q.log

local fileops <const> = require("fileops")

if package.config:sub(1, 1) ~= "/" then
	log.warning("Non-Unix platform detected, skipping WebP conversion.")
	return {}
end

local _, can_convert = fileops.run_and_capture("cwebp -version")
if not can_convert then
	log.warning("'cwebp' not found, skipping WebP conversion.")
	return {}
end

local delete_originals = false
local disable_conversion = false
function Meta(meta)
	delete_originals = meta["webp-delete-originals"] == true
	disable_conversion = meta["webp-disable"] == true
	log.debug(("delete_originals=%s, disable_conversion=%s"):format(delete_originals, disable_conversion))
	return meta
end

function Image(img)
	if not Q.doc.is_format("html") or disable_conversion then
		return img
	end

	local src = img.src
	if not src:match("%.[Pp][Nn][Gg]$") then
		return img
	end

	local png, webp = src, src:gsub("%.[Pp][Nn][Gg]$", ".webp")
	if not fileops.file_exists(png) then
		log.warning("PNG not found: ", png)
		return img
	end

	local need_conversion = not fileops.file_exists(webp)
	if not need_conversion then
		local pm, wm = fileops.get_mtime(png), fileops.get_mtime(webp)
		if pm and wm and wm < pm then
			log.info("Reconvert updated image:", png)
			need_conversion = true
		end
	end

	if need_conversion then
		local psz = fileops.file_size(png)
		local cmd = ("cwebp -quiet -lossless -z 8 %s -o %s"):format(fileops.sh_quote(png), fileops.sh_quote(webp))
		local out, ok = fileops.run_and_capture(cmd)
		if not ok or not fileops.file_exists(webp) then
			log.error("cwebp failed for ", png)
			log.error(out)
			return img
		end

		local wsz = fileops.file_size(webp)
		if psz and wsz then
			local diff = psz - wsz
			log.info(
				string.format(
					"%s → %s: %.1fKB → %.1fKB saved %.1fKB (%.1f%%)",
					png,
					webp,
					psz / 1024,
					wsz / 1024,
					diff / 1024,
					diff / psz * 100
				)
			)
		end

		if delete_originals and not os.remove(png) then
			log.warning("Could not delete PNG: ", png)
		end
	end

	img.src = webp
	return img
end

return {
	{ Meta = Meta },
	{ Image = Image },
}
