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

-- Check if file exists
local function file_exists(path)
  local f = io.open(path, "r")
  if f then
    f:close()
    return true
  else
    return false
  end
end

-- Check if cwebp is available
local function cwebp_available()
  local result = os.execute("cwebp -version > /dev/null 2>&1")
  return result ~= false and result ~= nil
end

-- Run a shell command and capture its output
local function run_and_capture(cmd)
  local handle = io.popen(cmd .. " 2>&1")
  if not handle then return nil, false end
  local output = handle:read("*a")
  local ok, reason, code = handle:close()
  return output, ok, reason, code
end

-- Get file size in bytes
local function file_size(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local size = f:seek("end")
  f:close()
  return size
end

-- Initial setup
local can_convert = cwebp_available()
if not can_convert then
  io.stderr:write("Warning: 'cwebp' not found in PATH. WebP conversion will be skipped.\n")
end

local delete_originals = false

function Meta(meta)
  if meta["webp-delete-originals"] then
    delete_originals = true
  end
  return meta
end

function Image(img)
  if not can_convert or not quarto.doc.is_format("html") then
    return img
  end

  if img.src:match("%.png$") then
    local png_path = img.src
    local webp_path = png_path:gsub("%.png$", ".webp")

    if not file_exists(png_path) then
      io.stderr:write("Warning: PNG file not found: ", png_path, "\n")
      return img
    end

    if not file_exists(webp_path) then
      local png_size = file_size(png_path)

      local cmd = string.format(
        'cwebp -quiet -lossless -z 9 -m 6 "%s" -o "%s"',
        png_path, webp_path
      )
      local output, ok, reason, code = run_and_capture(cmd)

      if not ok or not file_exists(webp_path) then
        io.stderr:write("Error: cwebp failed to convert ", png_path, "\n")
        io.stderr:write("Reason: ", tostring(reason), " (code ", tostring(code), ")\n")
        io.stderr:write("Output:\n", output, "\n")
        return img
      end

      local webp_size = file_size(webp_path)
      if png_size and webp_size then
        local diff = png_size - webp_size
        local percent = (diff / png_size) * 100
        io.stdout:write(string.format(
          "Converted %s → %s (%.1f KB → %.1f KB, saved %.1f KB, -%.1f%%)\n",
          png_path, webp_path,
          png_size / 1024, webp_size / 1024,
          diff / 1024, percent
        ))
      end

      if delete_originals then
        local removed = os.remove(png_path)
        if not removed then
          io.stderr:write("Warning: Could not delete original PNG: ", png_path, "\n")
        end
      end
    end

    img.src = webp_path
  end

  return img
end

-- ensure Meta is processed before Image
return {
  { Meta = Meta },
  { Image = Image }
}
