
module cwx.jpy;

import cwx.structs;

import std.compat;

enum Animation {
	NONE = 0,
	DRAW = 1,
	UNDO = 2,
	SMOOTH = 3,
	WAIT = 4
}
enum Colormap {
	NONE = 0,
	MONO = 1,
	SEPIA = 2,
	MONO_MAGENTA = 3,
	MONO_RED = 4,
	MONO_GREEN = 5,
	MONO_BLUE = 6,
	MONO_YELLOW = 7,
	MONO_PURPLE = 8,
	MONO_CYAN = 9,
	MONO_D_RED = 10,
	MONO_D_GREEN = 11,
	MONO_D_BLUE = 12,
	MONO_D_YELLOW = 13,
	MONO_D_PURPLE = 14,
	MONO_D_CYAN = 15
}

enum Dirtype {
	CURRENT = 1,
	TABLE = 2,
	SCHEME = 3,
	FIRST_FILE = 4,
	WAV = 5,
	PARENT = 6,
	PROGRAM = 7
}

enum Exchange {
	NONE = 0,
	GBR = 1,
	BRG = 2,
	GRB = 3,
	BGR = 4,
	RBG = 5
}

enum Filter {
	NONE = 0,
	SHADE = 1,
	SHARP = 2,
	SUN = 3,
	C_EMBOSS = 4,
	D_EMBOSS = 5,
	ELEC = 6,
	MONO = 7,
	DIFFUSION = 8,
	NEGA = 9,
	EMBOSS = 10
}

enum Cache {
	NONE = 0,
	C1 = 1,
	C2 = 2,
	C3 = 3,
	C4 = 4,
	C5 = 5,
	C6 = 6,
	C7 = 7,
	C8 = 8
}

enum Mask {
	NONE = 0,
	V_LINE = 1,
	H_LINE = 2,
	MESH = 3
}

enum Noise {
	NONE = 0,
	LIGHT = 1,
	TWO = 2,
	NOISE = 3,
	C_NOISE = 4,
	MOSAIC = 5
}

enum Paintmode {
	NONE = 0,
	AND = 1,
	OR = 2,
	BLEND = 3
}

enum Turn {
	NONE = 0,
	LEFT = 1,
	RIGHT = 2
}

struct Jpy1 {
	string label;

	int backwidth = -1; // 画像が無い場合の自動サイズは632
	int backheight = -1; // 画像が無い場合は自動サイズは420
	CRGB backcolor = CRGB(255, 255, 255);
	int width = -1;
	int height = -1;
	CRGB color = CRGB(255, 255, 255);

	int dirdepth = 0;
	string filename = "";
	Dirtype dirtype = Dirtype.CURRENT; // これのみ0が無い
	Cache loadcache = Cache.NONE;
	Cache savecache = Cache.NONE;

	bool visible = true;
	CPoint position = CPoint(0, 0);
	bool transparent = false;
	CRect clip = CRect(0, 0, 0, 0);
	Paintmode paintmode = Paintmode.NONE;
	int alpha = 255;
	CRect animeclip = CRect(0, 0, 0, 0);
	Animation animation = Animation.NONE;
	CPoint animeposition = CPoint(0, 0);
	CPoint animemove = CPoint(0, 0);
	int wait = 0;
	int animespeed = 0;
	bool smooth = false;

	Exchange exchange = Exchange.NONE;
	Colormap colormap = Colormap.NONE;
	Filter filter = Filter.NONE;
	Mask mask = Mask.NONE;
	Noise noise = Noise.NONE;
	int noisepoint = 0;
	Turn turn = Turn.NONE;
	bool flip = false;
	bool mirror = false;

	string comment = "";
}

const JPTX_BR = "br";
const JPTX_B = "b";
const JPTX_I = "i";
const JPTX_U = "u";
const JPTX_S = "s";
const JPTX_SHIFTX = "shiftx";
const JPTX_SHIFTY = "shifty";
const JPTX_LINEHEIGHT = "lineheight";
const JPTX_FONT = "font";
const JPTX_FONT_ATTR_FACE = "face";
const JPTX_FONT_ATTR_COLOR = "color";
const JPTX_FONT_ATTR_PIXELS = "pixels";

class JptxNode {
	string left;
	JptxNode child = null;
	string right = "";

	// style
	string[] lines;
	bool b = false;
	bool i = false;
	bool u = false;
	bool s = false;
	int shiftx = 0;
	int shifty = 0;
	int lineheight = 100; // %
	string font_face = "";
	CRGB font_color = CRGB(-1, -1, -1);
	int font_pixels = -1;
}

struct Jptx {
	JptxNode text;

	CRGB backcolor = CRGB(255, 255, 255);
	int backwidth = -1;
	int backheight = -1;
	bool autoline = 1;
	int lineheight = 100; // %
	int fontpixels = 12;
	CRGB fontcolor = CRGB(255, 255, 255);
	string fontface = "ＭＳ　Ｐゴシック";
	int antialias = false;
	bool fonttransparent = false;
}

enum Copymode {
	AUTO = 0,
	BEFORE_SCREEN = 1,
	SCREEN = 2,
	PAINT_OUT = 3
}

const JPDC_COMMENT_FILE = "file";
const JPDC_COMMENT_DIR = "dir";

struct Jpdc {
	CRect clip = CRect(0, 0, 0, 0);
	Copymode copymode = Copymode.AUTO;
	string saveFileName = "";
	string savecomment = "";
}
