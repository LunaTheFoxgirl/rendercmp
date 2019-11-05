import std.stdio;
import std.math;
import std.format;
import imageformats;

enum ErrorNoArgs = "No arguments provided";

enum InfoText = "rendercmp (options) <ground truth image> <images to compare...>
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
";

enum ResultsText = "=====Results=====
Similarity R: %s %%
Similarity G: %s %%
Similarity B: %s %%
Similarity Grayscale: %s %%

Average: %s %%

Score (0-100): %d";

/**
	The final score
*/
struct Score {
	double percRed = 0;
	double percGreen = 0;
	double percBlue = 0;
	double percGrayscale = 0;
	double avgPerc = 0;
	int score;

	void genScore() {
		percRed = 1-(percRed/255);
		percGreen = 1-(percGreen/255);
		percBlue = 1-(percBlue/255);
		percGrayscale = 1-(percGrayscale/255);
		avgPerc = ((percRed+percGreen+percBlue+percGrayscale)/4.0);
		score = cast(int)(cast(double)avgPerc*100.0);
	}

	string toString() {
		return ResultsText.format(
			(percRed*100.0), 
			(percGreen*100.0), 
			(percBlue*100.0), 
			(percGrayscale*100.0), 
			(avgPerc*100.0), 
			score);
	}
}

struct Pixel {
	ubyte red;
	ubyte green;
	ubyte blue;

	/**
		Returns the CIE luminance function output for this pixel's reg, green and blue channel
	*/
	ubyte grayscale() {
		return cast(ubyte)(
			0.2126 * red +
			0.7152 * green +
			0.0722 * blue + 0.5
		);
	}

	/**
		Returns an array of the difference in noise values
	*/
	ubyte[4] diff(Pixel other) {
		return [
			noiseDiff(red, other.red),
			noiseDiff(green, other.green),
			noiseDiff(blue, other.blue),
			noiseDiff(grayscale, other.grayscale)
		];
	}
}

void main(string[] args_v)
{
	string[] args = args_v[1..$];
	if (args.length == 0) {
		writeln(ErrorNoArgs);
		writeln(InfoText);
		return;
	}

	string[] files;
	foreach(arg; args) {
		switch(arg) {

			case "--help":
				writeln(InfoText);
				return;

			default:
				files ~= arg;
				break;
		}
	}
	IFImage truth = read_image(files[0]);
	foreach(i; 1..files.length) {
		IFImage data = read_image(files[i]);

		Score scoreImage = scoreImage(truth, data);

		writeln("\nfile=%s\n".format(files[i]), scoreImage.toString());
	}
}

/**
	Compare ground truth against data
*/
Score scoreImage(IFImage truth, IFImage data) {
	if (truth.w != data.w) throw new Exception("Width and/or height does not match!");
	if (truth.h != data.h) throw new Exception("Width and/or height does not match!");
	if (truth.c != data.c) throw new Exception("Color format does not match!");
	if (truth.c < 3) throw new Exception("Color format not RGB or RGBA");

	Score score;

	Pixel[] truthImage = buildPixelMap(truth.pixels, cast(size_t)truth.c);
	Pixel[] dataImage = buildPixelMap(data.pixels, cast(size_t)data.c);
	ubyte[] noiseMap = buildNoiseMap(truthImage, dataImage);

	foreach(i; 0..noiseMap.length/4) {
		size_t ix = i*4;
		score.percRed += noiseMap[ix];
		score.avgPerc += noiseMap[ix++];

		score.percGreen += noiseMap[ix];
		score.avgPerc += noiseMap[ix++];

		score.percBlue += noiseMap[ix];
		score.avgPerc += noiseMap[ix++];
		
		score.percGrayscale += noiseMap[ix];
		score.avgPerc += noiseMap[ix++];
	}
	score.percRed /= truthImage.length;
	score.percGreen /= truthImage.length;
	score.percBlue /= truthImage.length;
	score.percGrayscale /= truthImage.length;
	score.genScore();
	return score;
}

Pixel[] buildPixelMap(ubyte[] data, size_t colors) {
	size_t len = colors == 4 ? data.length-(data.length/4) : 0;

	Pixel[] pixdata = new Pixel[len];

	size_t i = 0;
	do {
		pixdata[i/colors] = Pixel(data[i++], data[i++], data[i++]);
		if (colors == 4) i++;
	} while(i < data.length);
	return pixdata;
}

ubyte[] buildNoiseMap(Pixel[] truth, Pixel[] data) {
	ubyte[] noiseMap = new ubyte[truth.length*4];
	foreach(i, pixel; truth) {
		noiseMap[i*4..(i*4)+4] = pixel.diff(data[i]);
	}
	return noiseMap;
}

/**
	Gets the noise difference between the ground truth and the test data
*/
ubyte noiseDiff(ubyte truth, ubyte data) {
	return cast(ubyte)(data-truth);
}