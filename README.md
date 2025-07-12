# Convert PNG to WebP (Quarto Extension)

![CI](https://github.com/klausbrunner/convert-to-webp/actions/workflows/ci.yml/badge.svg)

Converts `.png` images in your Quarto document to lossless `.webp` format when rendering to HTML.
This improves compression while retaining quality. Particularly useful for images created by R or Python code chunks, such as diagrams.

## Features

- Converts `.png` files to `.webp` using the `cwebp` command-line tool
- Updates image references in the rendered output
- Logs compression savings
- Optional: deletes original `.png` files after successful conversion

## Installation

```bash
quarto add klausbrunner/convert-to-webp
```

## Usage

In your Quarto document or `_quarto.yml`, enable the filter:

```yaml
filters:
  - convert-to-webp
```

To also delete the original PNG files after conversion (which makes most sense for images created from code chunks):

```yaml
webp-delete-originals: true
```

To disable conversion (typically because you want to exempt a single document from running this filter):

```yaml
webp-disable: true
```

## Requirements

- You need a Unix-like environment (Linux, BSD, macOS, WSL) for this to work.
- The `cwebp` tool must be installed and available in your system `PATH`. It's availabe from all the usual package managers, though package names vary (e.g. `webp` on Debian/Ubuntu, `libwebp-tools` on Fedora, `webp` on macOS with Homebrew).

Check by running:

```bash
cwebp -version
```

## Notes

- Only applies when rendering to HTML formats
- Only .png images are converted; other image formats are left unchanged.
