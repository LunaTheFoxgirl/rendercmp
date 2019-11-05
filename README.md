# RenderCMP
A small utility to compare the noise of renders to a ground truth.

This tool has not been thorughly tested, but any contributions are welcome.

## How to compile
Install a D compiler (https://dlang.org)
Run `dub` in this directory; the application should then be built.

run `rendercmp --help` to get usage info.


## Info from help text
May be out of date
```
rendercmp (options) <ground truth image> <images to compare...>
Similarity is dervived through the similarity between the noise and the ground truth on the RGB channels, as well an CIE algorithm generated grayscale luminance channel.
Check the source to see the formular used.

The score is based on the average similarity across all the tests.

Notes:
	It's recommended to compare bitmap (BMP) or Targa (TGA) images, as they have little to no compression artifacts.
	Only 8-bit-per-channel image files are supported.

Options:
	--help | Displays this help page

Supported image formats:
	BMP
	TGA
	PNG
	JPEG
```