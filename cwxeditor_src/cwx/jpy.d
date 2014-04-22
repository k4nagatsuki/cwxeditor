
module cwx.jpy;

import cwx.structs;
import cwx.utils;
import cwx.sjis;

import std.array;
import std.conv;
import std.exception;
import std.string;
import std.regex;
import std.utf;

enum Animation {
	NONE = 0,
	DRAW = 1,
	UNDO = 2,
	SMOOTH = 3,
	WAIT = 4
}
enum Colormap {
	NONE = 0,
	GRAY_SCALE = 1,
	SEPIA = 2,
	PINK = 3,
	SUNNY_RED = 4,
	LEAF_GREEN = 5,
	OCEAN_BLUE = 6,
	LIGHTNING = 7,
	PURPLE_LIGHT = 8,
	AQUA_LIGHT = 9,
	CRIMSON = 10,
	DARK_GREEN = 11,
	DARK_BLUE = 12,
	SWAMP = 13,
	DARK_PURPLE = 14,
	DARK_SKY = 15
}

enum Dirtype {
	CURRENT = 1,
	TABLE = 2,
	SCHEME = 3,
	SCENARIO = 4,
	WAV = 5,
	PARENT = 6,
	PROGRAM = 7
}

enum Colorexchange {
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
	MONO = 2,
	NOISE = 3,
	C_NOISE = 4,
	MOSAIC = 5
}

enum Paintmode {
	NONE = 0,
	AND = 1,
	OR = 2,
	BLEND = 3,
	NO_PAINT = 4
}

enum Turn {
	NONE = 0,
	LEFT = 1,
	RIGHT = 2
}

private {
	CPoint pointVal(string value) {
		auto sp = std.string.split(value, ",");
		if (sp.length < 2) throw new Exception("invalid point: " ~ value);
		return CPoint(to!(int)(astrip(sp[0])), to!(int)(astrip(sp[1])));
	}
	CRect rectVal(string value) {
		auto sp = std.string.split(value, ",");
		if (sp.length < 4) throw new Exception("invalid rect: " ~ value);
		return CRect(to!(int)(astrip(sp[0])), to!(int)(astrip(sp[1])),
			to!(int)(astrip(sp[2])), to!(int)(astrip(sp[3])));
	}
	CRGB rgbVal(string value) {
		if (value.length < 7 || (value[0] != '$' && value[0] != '#')) {
			try {
				int val = std.conv.parse!int(value, 16);
				int r = val & 0xFF0000 >>> 16;
				int g = val & 0x00FF00 >>> 8;
				int b = val & 0x0000FF >>> 0;
				return CRGB(r, g, b);
			} catch (Exception e) {
				throw new Exception("invalid rgb: " ~ value);
			}
		}
		auto sr = value[1 .. 3];
		auto sg = value[3 .. 5];
		auto sb = value[5 .. 7];
		return CRGB(toImpl!int(sr, 16), toImpl!int(sg, 16), toImpl!int(sb, 16));
	}
	Enum enumVal(Enum)(string value) {
		return cast(Enum) to!(int)(value);
	}
	string strVal(string value) {
		try {
			cwx.utils.validate(value);
			return value;
		} catch {
			return touni(value);
		}
	}
	int intVal(string value) {
		if (value.endsWith("px")) value = value[0 .. $-2];
		return to!(int)(value);
	}
	bool boolVal(string value) {return value == "1";}
}

/// pathのファイルを読み込む。
string readJPYFile(string path, out bool isSJIS) {
	char[] value;
	try {
		value = cast(char[]) std.file.readText(path);
		isSJIS = false;
		return assumeUnique(value);
	} catch {
		isSJIS = true;
		value = cast(char[]) std.file.read(path);
		return touni(value);
	}
}
/// ditto
private string readJPYFile(string path) {
	try {
		return std.file.readText(path);
	} catch (UTFException e) {
		return touni(cast(char[]) std.file.read(path));
	}
}
/// pathへ書き込む。
void writeJPYFile(string path, string value, bool isSJIS) {
	if (isSJIS) {
		value = tosjis(value);
	}
	std.file.write(path, value);
}

private string stripValue(string eqAfter) {
	auto value = astrip(eqAfter);
	if (value.length >= 2 && value[0] == '"' && value[$ - 1] == '"') {
		value = value[1 .. $ - 1];
	}
	return value;
}

/// Jpy1の1ファイルの定義。
struct Jpy1 {
	/// ファイルに含まれるセクション。
	Jpy1Sec[] sections;
	/// pathからJpy1を読込む。
	static Jpy1 load(string path) {
		Jpy1 r;
		foreach (line; splitLines!string(readJPYFile(path))) {
			line = astrip(line);
			if (!line.length || line[0] == ';') continue;
			if (line[0] == '[' && line[$ - 1] == ']') {
				// label
				Jpy1Sec sec;
				sec.label = astrip(line[1 .. $ - 1]);
				r.sections ~= sec;
				continue;
			}
			if (!r.sections.length) throw new Exception("label not found");
			with (r.sections[$ - 1]) {
				// contents
				int eq = .cCountUntil(line, '=');
				if (eq == -1) throw new Exception("invalid line: " ~ line);
				auto key = astrip(line[0 .. eq]);
				auto value = stripValue(line[eq + 1 .. $]);
				switch (.toLower(key)) {
				case "backwidth": backwidth = intVal(value); break;
				case "backheight": backheight = intVal(value); break;
				case "backcolor": backcolor = rgbVal(value); break;
				case "width": width = intVal(value); break;
				case "height": height = intVal(value); break;
				case "color": color = rgbVal(value); break;
				case "dirdepth": dirdepth = intVal(value); break;
				case "filename": filename = strVal(value); break;
				case "dirtype": dirtype = enumVal!(Dirtype)(value); break;
				case "loadcache": loadcache = enumVal!(Cache)(value); break;
				case "savecache": savecache = enumVal!(Cache)(value); break;
				case "visible": visible = boolVal(value); break;
				case "position": position = pointVal(value); break;
				case "transparent": transparent = boolVal(value); break;
				case "clip": clip = rectVal(value); break;
				case "paintmode": paintmode = enumVal!(Paintmode)(value); break;
				case "alpha": alpha = intVal(value); break;
				case "animeclip": animeclip = rectVal(value); break;
				case "animation": animation = enumVal!(Animation)(value); break;
				case "animeposition": animeposition = pointVal(value); break;
				case "animemove": animemove = pointVal(value); break;
				case "wait": wait = intVal(value); break;
				case "animespeed": animespeed = intVal(value); break;
				case "smooth": smooth = boolVal(value); break;
				case "colorexchange": colorexchange = enumVal!(Colorexchange)(value); break;
				case "colormap": colormap = enumVal!(Colormap)(value); break;
				case "filter": filter = enumVal!(Filter)(value); break;
				case "mask": mask = enumVal!(Mask)(value); break;
				case "noise": noise = enumVal!(Noise)(value); break;
				case "noisepoint": noisepoint = intVal(value); break;
				case "turn": turn = enumVal!(Turn)(value); break;
				case "flip": flip = boolVal(value); break;
				case "mirror": mirror = boolVal(value); break;
				case "comment": comment = strVal(value); break;
				default: throw new Exception("invalid command: " ~ line);
				}
			}
		}
		return r;
	}
}

/// Jpy1のセクションブロック。
struct Jpy1Sec {
	/// セクションのラベル。
	string label;

	int backwidth = -1; // 画像が無い場合の自動サイズは632
	int backheight = -1; // 画像が無い場合は自動サイズは420
	// FIXME: マニュアルによれば初期値は白だがcwconv.dllの実装は黒
//	CRGB backcolor = CRGB(255, 255, 255);
	CRGB backcolor = CRGB(0, 0, 0);
	int width = -1;
	int height = -1;
//	CRGB color = CRGB(255, 255, 255);
	CRGB color = CRGB(0, 0, 0);

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

	Colorexchange colorexchange = Colorexchange.NONE;
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

private struct JptxTag {
	string name;
	int tagValue;
	string[string] attr;
	static JptxTag parse(string startTag) {
		auto reg = .match(toUTF32(startTag), .regex!(dstring)("^<[A-Z]+"d, "i"));
		if (reg.empty) throw new Exception("invalid start tag: " ~ startTag);
		JptxTag tag;
		tag.name = .toLower(toUTF8(reg.hit[1 .. $]));
		dstring p = reg.post;
		if (!p.length) throw new Exception("invalid start tag: " ~ startTag);
		if (startsWith(p, "=\""d)) {
			int ei = .cCountUntil(p[2 .. $], '"');
			if (ei == -1) throw new Exception("invalid start tag: " ~ startTag);
			tag.tagValue = to!(int)(p[2 .. ei + 2]);
			p = p[ei + 4 .. $];
		}
		if (startsWith(p, "="d)) {
			int ei = .cCountUntil(p, ' ');
			if (ei == -1) ei = .cCountUntil(p, '>');
			tag.tagValue = ei == -1 ? to!(int)(p[1 .. $]) : to!(int)(p[1 .. ei]);
			if (ei != -1) p = p[ei + 1 .. $];
		}
		static const ATTR = " *([A-Z]+)=(\"[^\"]+\"|[^\"]+)"d;
		auto attrReg = .regex!(dstring)(ATTR, "gi");
		foreach (m; .match(p, attrReg)) {
			if(m.empty) break;
			p = m.post;
			auto cap = m.captures;
			auto val = to!string(cap[2]);
			if (2 <= val.length && val.startsWith("\"") && val.endsWith("\"")) {
				val = val[1 .. $ - 1];
			}
			tag.attr[.toLower(to!string(cap[1]))] = val;
		}
		return tag;
	} unittest {
		debug mixin(UTPerf);
		auto t1 = JptxTag.parse("<b>");
		assert (t1.name == "b");
		auto t2 = JptxTag.parse("<lineheight=\"80\">");
		assert (t2.name == "lineheight");
		assert (t2.tagValue == 80);
		auto t3 = JptxTag.parse("<font face=\"face\" pixels=\"14\">");
		assert (t3.name == "font");
		assert (t3.attr["face"] == "face");
		assert (t3.attr["pixels"] == "14");
	}
}
private struct JptxParser {
	bool autoline = true;

	void delegate(string) onText = null;

	void delegate() onBR = null;

	void delegate() onB = null;
	void delegate() onI = null;
	void delegate() onU = null;
	void delegate() onS = null;
	void delegate(int) onShiftx = null;
	void delegate(int) onShifty = null;
	void delegate(int) onLineheight = null;
	void delegate(string face, CRGB color, int pixels) onFont = null;

	void delegate() onEndB = null;
	void delegate() onEndI = null;
	void delegate() onEndU = null;
	void delegate() onEndS = null;
	void delegate() onEndShiftx = null;
	void delegate() onEndShifty = null;
	void delegate() onEndLineheight = null;
	void delegate() onEndFont = null;

	private void startTag(string tagText) {
		auto tag = JptxTag.parse(tagText);
		switch (tag.name) {
		case "br": {
			if (onBR) onBR();
		} break;
		case "b": {
			if (onB) onB();
		} break;
		case "i": {
			if (onI) onI();
		} break;
		case "u": {
			if (onU) onU();
		} break;
		case "s": {
			if (onS) onS();
		} break;
		case "shiftx": {
			if (onShiftx) onShiftx(tag.tagValue);
		} break;
		case "shifty": {
			if (onShifty) onShifty(tag.tagValue);
		} break;
		case "lineheight": {
			if (onLineheight) onLineheight(tag.tagValue);
		} break;
		case "font": {
			if (onFont) {
				string face = "";
				CRGB rgb = CRGB(-1, -1, -1);
				int pixels = -1;
				auto pFace = "face" in tag.attr;
				if (pFace) face = strVal(*pFace);
				auto pRgb = "color" in tag.attr;
				if (pRgb) rgb = rgbVal(*pRgb);
				auto pPixels = "pixels" in tag.attr;
				if (pPixels) pixels = intVal(*pPixels);
				onFont(face, rgb, pixels);
			}
		} break;
		default: assert (0, tag.name);
		}
	}
	private void endTag(string tagText) {
		auto tag = tagText[2 .. $ - 1];
		switch (.toLower(tag)) {
		case "b": {
			if (onEndB) onEndB();
		} break;
		case "i": {
			if (onEndI) onEndI();
		} break;
		case "u": {
			if (onEndU) onEndU();
		} break;
		case "s": {
			if (onEndS) onEndS();
		} break;
		case "shiftx": {
			if (onEndShiftx) onEndShiftx();
		} break;
		case "shifty": {
			if (onEndShifty) onEndShifty();
		} break;
		case "lineheight": {
			if (onEndLineheight) onEndLineheight();
		} break;
		case "font": {
			if (onEndFont) onEndFont();
		} break;
		default: assert (0, tag);
		}
	}
	void parse(string text) {
		immutable TAG = "</(b|i|u|s|shiftx|shifty|lineheight|font)>"d
			~ "|<"d
			~ "(br|b|i|u|s|shiftx=(\"-?[0-9]+\"|-?[0-9]+)|shifty=(\"-?[0-9]+\"|-?[0-9]+)"d
			~ "|lineheight=(\"-?[0-9]+\"|-?[0-9]+)"d
			~ "|font( +(face=(\"[^\"]+\"|[^\"]+)|color=(\"[\\$#][0-9A-Fa-f]{6}\"|[\\$#][0-9A-Fa-f]{6})"d
			~ "|pixels=(\"-?[0-9]+\"|-?[0-9]+)))+)"d
			~ ">"d;
		if (autoline) {
			auto r = .regex!(dstring)("^" ~ TAG ~ "$", "i");
			auto lines = splitLines!string(text);
			text = "";
			foreach (i, line; lines) {
				text ~= line;
				if (i + 1 < lines.length && .match(toUTF32(line), r).empty) {
					text ~= "<br>";
				}
			}
		} else {
			text = replace(text, "\r\n", "");
			text = replace(text, "\r", "");
			text = replace(text, "\n", "");
		}
		auto r = .regex!(dstring)(TAG, "i");
		while (text.length) {
			auto reg = .match(toUTF32(text), r);
			if (!reg.empty) {
				if (onText && reg.pre.length) onText(toUTF8(reg.pre));
				auto m = toUTF8(reg.hit);
				if (std.algorithm.startsWith(m, "</")) {
					endTag(m);
				} else {
					startTag(m);
				}
				text = toUTF8(reg.post);
				continue;
			}
			if (onText) {
				onText(text);
			}
			text = "";
		}
	}
}

/// Jptxの描画状態。
struct JptxParam {
	bool b = false;
	bool i = false;
	bool u = false;
	bool s = false;
	int shiftx = 0;
	int shifty = 0;
	int lineheight = 100;
	string face = "";
	CRGB color = CRGB(-1, -1, -1);
	int pixels = -1;
}
/// Jptxの1ファイルの定義。
struct Jptx {
	/// テキスト。タグがそのままの形で含まれる。
	string text;

	// FIXME: マニュアルによれば初期値は白だがcwconv.dllの実装は黒
//	CRGB backcolor = CRGB(255, 255, 255);
	CRGB backcolor = CRGB(0, 0, 0);
	int backwidth = -1;
	int backheight = -1;
	bool autoline = 1;
	int lineheight = 100; // %
	int fontpixels = 12;
	CRGB fontcolor = CRGB(255, 255, 255);
	string fontface = "ＭＳ Ｐゴシック";
	int antialias = false;
	bool fonttransparent = false;

	unittest {
		debug mixin(UTPerf);
		Jptx jptx;
		jptx.text = "Jptxのテスト。<br>改行した後、<b>太字<i>かつ斜体</i></b><s>打ち消し</s>"
			~ "<font color=\"$000000\" face=\"font!\" pixels=\"28\">font!の黒の28px"
			~ "<font color=\"$FF0000\">ここはfont!の赤の28px</font>ここもfont!の黒の28px</font>"
			~ "<shiftx=\"20\">shiftx=20<shiftx=\"10\">shiftx=10<shiftx=20>shiftx=20</shiftx>"
			~ "<shifty=\"20\">shifty=20<shifty=\"10\">shifty=10<shifty=20>shifty=20</shifty>"
			~ "<lineheight=\"50\">高さ50%<lineheight=\"30\">高さ30%</lineheight></lineheight>";
		jptx.fontface = "testfont";
		jptx.lineheight = 80;
		jptx.fontpixels = 18;
		jptx.fontcolor = CRGB(128, 128, 128);
		int count = 0;
		jptx.parse((string text, in JptxParam param) {
			void chk(string t, bool b, bool i, bool u, bool s,
					int shiftx, int shifty, int lineheight,
					string face, CRGB color, int pixels) {
				assert (text == t, to!(string)(count) ~ ", " ~ text);
				assert (param.b == b, to!(string)(count));
				assert (param.i == i, to!(string)(count));
				assert (param.u == u, to!(string)(count));
				assert (param.s == s, to!(string)(count));
				assert (param.shiftx == shiftx, format("%d, %d", count, param.shiftx));
				assert (param.shifty == shifty, format("%d, %d", count, param.shifty));
				assert (param.lineheight == lineheight, format("%d, %d", count, param.lineheight));
				assert (param.face == face, format("%d, %s", count, param.face));
				assert (param.color == color, format("%d, %d:%d:%d", count, param.color.r, param.color.g, param.color.b));
				assert (param.pixels == pixels, format("%d, %d", count, param.pixels));
			}
			switch (count) {
			case 0: {
				chk("Jptxのテスト。", false, false, false, false,
					0, 0, 80, "testfont", CRGB(128, 128, 128), 18);
			} break;
			case 1: {
				chk("\n", false, false, false, false,
					0, 0, 80, "testfont", CRGB(128, 128, 128), 18);
			} break;
			case 2: {
				chk("改行した後、", false, false, false, false,
					0, 0, 80, "testfont", CRGB(128, 128, 128), 18);
			} break;
			case 3: {
				chk("太字", true, false, false, false,
					0, 0, 80, "testfont", CRGB(128, 128, 128), 18);
			} break;
			case 4: {
				chk("かつ斜体", true, true, false, false,
					0, 0, 80, "testfont", CRGB(128, 128, 128), 18);
			} break;
			case 5: {
				chk("打ち消し", false, false, false, true,
					0, 0, 80, "testfont", CRGB(128, 128, 128), 18);
			} break;
			case 6: {
				chk("font!の黒の28px", false, false, false, false,
					0, 0, 80, "font!", CRGB(0, 0, 0), 28);
			} break;
			case 7: {
				chk("ここはfont!の赤の28px", false, false, false, false,
					0, 0, 80, "font!", CRGB(255, 0, 0), 28);
			} break;
			case 8: {
				chk("ここもfont!の黒の28px", false, false, false, false,
					0, 0, 80, "font!", CRGB(0, 0, 0), 28);
			} break;
			case 9: {
				chk("shiftx=20", false, false, false, false,
					20, 0, 80, "testfont", CRGB(128, 128, 128), 18);
			} break;
			case 10: {
				chk("shiftx=10", false, false, false, false,
					10, 0, 80, "testfont", CRGB(128, 128, 128), 18);
			} break;
			case 11: {
				chk("shiftx=20", false, false, false, false,
					20, 0, 80, "testfont", CRGB(128, 128, 128), 18);
			} break;
			case 12: {
				chk("shifty=20", false, false, false, false,
					0, 20, 80, "testfont", CRGB(128, 128, 128), 18);
			} break;
			case 13: {
				chk("shifty=10", false, false, false, false,
					0, 10, 80, "testfont", CRGB(128, 128, 128), 18);
			} break;
			case 14: {
				chk("shifty=20", false, false, false, false,
					0, 20, 80, "testfont", CRGB(128, 128, 128), 18);
			} break;
			case 15: {
				chk("高さ50%", false, false, false, false,
					0, 0, 50, "testfont", CRGB(128, 128, 128), 18);
			} break;
			case 16: {
				chk("高さ30%", false, false, false, false,
					0, 0, 30, "testfont", CRGB(128, 128, 128), 18);
			} break;
			default: assert (0);
			}
			count++;
		});
	}
	/// textを分析し、経過をonTextに渡す。
	/// 改行は独立したテキスト"\n"として渡される。
	void parse(void delegate(string text, in JptxParam param) onText) {
		JptxParam param;
		param.b = false;
		param.i = false;
		param.u = false;
		param.s = false;
		param.shiftx = 0;
		param.shifty = 0;
		param.lineheight = lineheight;
		param.face = fontface;
		param.color = fontcolor;
		param.pixels = fontpixels;
		// stack
		int sB = 0, sI = 0, sU = 0, sS = 0;
		string[] sFace;
		CRGB[] sColor;
		int[] sPixels;
		// parse
		JptxParser parser;
		parser.onB = () {
			sB++;
			param.b = true;
		};
		parser.onEndB = () {
			sB--;
			if (sB <= 0) param.b = false;
		};
		parser.onI = () {
			sI++;
			param.i = true;
		};
		parser.onEndI = () {
			sI--;
			if (sI <= 0) param.i = false;
		};
		parser.onU = () {
			sU++;
			param.u = true;
		};
		parser.onEndU = () {
			sU--;
			if (sU <= 0) param.u = false;
		};
		parser.onS = () {
			sS++;
			param.s = true;
		};
		parser.onEndS = () {
			sS--;
			if (sS <= 0) param.s = false;
		};
		parser.onShiftx = (int shiftx) {
			param.shiftx = shiftx;
		};
		parser.onEndShiftx = () {
			// 効果無し
		};
		parser.onShifty = (int shifty) {
			param.shifty = shifty;
		};
		parser.onEndShifty = () {
			// 効果無し
		};
		parser.onLineheight = (int lineheight) {
			param.lineheight = lineheight;
		};
		parser.onEndLineheight = () {
			// 効果無し
		};
		parser.onFont = (string face, CRGB color, int pixels) {
			if (!face.length) face = param.face;
			if (color.r == -1) color = param.color;
			if (pixels == -1) pixels = param.pixels;
			sFace ~= face;
			sColor ~= color;
			sPixels ~= pixels;
			param.face = face;
			param.color = color;
			param.pixels = pixels;
		};
		parser.onEndFont = () {
			if (!sFace.length) return;
			sFace = sFace[0 .. $ - 1];
			param.face = sFace.length ? sFace[$ - 1] : fontface;
			sColor = sColor[0 .. $ - 1];
			param.color = sColor.length ? sColor[$ - 1] : fontcolor;
			sPixels = sPixels[0 .. $ - 1];
			param.pixels = sPixels.length ? sPixels[$ - 1] : fontpixels;
		};
		parser.onBR = () {
			onText("\n", param);
			param.shiftx = 0;
			param.shifty = 0;
		};
		parser.onText = (string text) {
			onText(text, param);
			param.shiftx = 0;
			param.shifty = 0;
		};
		parser.parse(text);
	}
	/// pathからJptxを読込む。
	static Jptx load(string path) {
		Jptx r;
		string t = "";
		bool textFirst = true;
		bool init = false;
		bool text = false;
		foreach (line; splitLines!string(readJPYFile(path))) {
			auto sline = astrip(line);
			if (!text && sline.length && sline[0] == ';') continue;
			if (sline.length && sline[0] == '[' && sline[$ - 1] == ']') {
				// label
				switch (astrip(sline[1 .. $ - 1])) {
				case "jptx:init": {
					if (!text) {
						init = true;
						text = false;
						continue;
					}
				} break;
				case "jptx:begin": {
					if (!text) {
						init = false;
						text = true;
						continue;
					}
				} break;
				case "jptx:end": {
					init = true;
					text = false;
					continue;
				}
				default:
				}
			}
			if (init) {
				with (r) {
					// init
					int eq = .cCountUntil(sline, '=');
					if (eq == -1) throw new Exception("invalid line: " ~ line);
					auto key = astrip(sline[0 .. eq]);
					auto value = stripValue(sline[eq + 1 .. $]);
					switch (.toLower(key)) {
					case "backcolor": backcolor = rgbVal(value); break;
					case "backwidth": backwidth = intVal(value); break;
					case "backheight": backheight = intVal(value); break;
					case "autoline": autoline = boolVal(value); break;
					case "lineheight": lineheight = intVal(value); break;
					case "fontpixels": fontpixels = intVal(value); break;
					case "fontcolor": fontcolor = rgbVal(value); break;
					case "fontface": fontface = strVal(value); break;
					case "antialias": antialias = intVal(value); break;
					case "fonttransparent": fonttransparent = boolVal(value); break;
					default: throw new Exception("invalid command: " ~ line);
					}
				}
			}
			if (text) {
				if (textFirst) {
					textFirst = false;
				} else {
					t ~= "\n";
				}
				try {
					cwx.utils.validate(line);
					t ~= line;
				} catch {
					t ~= touni(line);
				}
			}
		}
		if (t.length && t[$ - 1] == '\n') {
			t = t[0 .. $ - 1];
		}
		r.text = t;
		return r;
	}
}

/// JPTXの設定内からテキスト部分を抽出する。
string jptxText(string jptxAll) {
	string r = "";
	bool inText = false;
	foreach (line; jptxAll.splitLines(KeepTerminator.yes)) {
		if (!inText && chomp(line).icmp("[jptx:begin]") == 0) {
			inText = true;
		} else if (inText && chomp(line).icmp("[jptx:end]") == 0) {
			inText = false;
		} else if (inText) {
			r ~= line;
		}
	}
	return r;
} unittest {
	debug mixin(UTPerf);
	assert (jptxText("[jptx:init]\nline1\nline2\r\n\n[jptx:begin]\r\na\nbcd\r\nefg\r\n[jptx:end]")
		== "a\nbcd\r\nefg\r\n");
}
/// JPTXの設定内のテキスト部分を置換する。
string jptxText(string jptxAll, string jptxText) {
	string r = "";
	bool inText = false, put = false;
	foreach (line; jptxAll.splitLines(KeepTerminator.yes)) {
		if (!inText && chomp(line).icmp("[jptx:begin]") == 0) {
			inText = true;
			r ~= line;
			if (!put) {
				r ~= jptxText;
				put = true;
			}
		} else if (inText && chomp(line).icmp("[jptx:end]") == 0) {
			inText = false;
			r ~= line;
		} else if (!inText) {
			r ~= line;
		}
	}
	return r;
} unittest {
	debug mixin(UTPerf);
	assert (jptxText("[jptx:init]\nline1\nline2\r\n\n[jptx:begin]\r\na\nbcd\r\nefg\r\n[jptx:end]", "a\rbc\r\n")
		== "[jptx:init]\nline1\nline2\r\n\n[jptx:begin]\r\na\rbc\r\n[jptx:end]");
}

enum Copymode {
	AUTO = 0,
	BEFORE_SCREEN = 1,
	SCREEN = 2,
	PAINT_OUT = 3
}

const JPDC_COMMENT_FILE = "file";
const JPDC_COMMENT_DIR = "dir";

/// Jpdcの1ファイルの定義。
struct Jpdc {
	CRect clip = CRect(0, 0, 632, 420);
	Copymode copymode = Copymode.AUTO;
	string saveFileName = "";
	string savecomment = "";

	/// pathからJpdcを読込む。
	static Jpdc load(string path) {
		Jpdc r;
		bool init = false;
		foreach (line; splitLines!string(readJPYFile(path))) {
			line = astrip(line);
			if (!line.length || line[0] == ';') continue;
			if (line[0] == '[' && line[$ - 1] == ']') {
				// label
				switch (astrip(line[1 .. $ - 1])) {
				case "jpdc:init": {
					init = true;
					continue;
				} break;
				default:
				}
			}
			if (init) {
				with (r) {
					// init
					int eq = .cCountUntil(line, '=');
					if (eq == -1) throw new Exception("invalid line: " ~ line);
					auto key = astrip(line[0 .. eq]);
					auto value = stripValue(line[eq + 1 .. $]);
					switch (.toLower(key)) {
					case "clip": clip = rectVal(value); break;
					case "copymode": copymode = enumVal!(Copymode)(value); break;
					case "savefilename": saveFileName = strVal(value); break;
					case "savecomment": savecomment = strVal(value); break;
					default: throw new Exception("invalid command: " ~ line);
					}
				}
			}
		}
		return r;
	}
}
