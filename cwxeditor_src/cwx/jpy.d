
module cwx.jpy;

import cwx.structs;
import cwx.utils;
import cwx.sjis;
import cwx.props;
import cwx.usecounter;
import cwx.path;

import std.array;
import std.conv;
import std.exception;
import std.string;
import std.regex;
import std.utf;
import std.path;

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

/// エフェクトブースターファイルをパースした際に
/// エラーが発生した場合、この例外が投げられる。
class EffectBoosterError : Exception {
	/// 1件のエラー。
	static struct EffectBoosterErrorInfo {
		string msg; /// エラーメッセージ。
		string file; /// エラーの発生したファイル。
		size_t line; /// エラーの発生した行。
	}

	private EffectBoosterErrorInfo[] _errors;

	/// インスタンスを生成する。
	this () { mixin(S_TRACE);
		super ("EffectBooster error", __FILE__, __LINE__);
	}

	/// エラーの一覧を返す。
	@property
	const
	const(EffectBoosterErrorInfo)[] errors() { return _errors; }

	/// エラー情報を追加する。
	void add(string msg, string file, size_t line) { mixin(S_TRACE);
		_errors ~= EffectBoosterErrorInfo(msg, file, line);
	}
}

private {
	CPoint pointVal(string value, in CProps prop, string file, size_t line, EffectBoosterError errInfo) { mixin(S_TRACE);
		auto sp = std.string.split(value, ",");
		if (sp.length < 2) { mixin(S_TRACE);
			errInfo.add(.tryFormat(prop.msgs.jpyErrorInvalidPoint, value), file, line);
			return CPoint(0, 0);
		}
		return CPoint(to!(int)(astrip(sp[0])), to!(int)(astrip(sp[1])));
	}
	CRect rectVal(string value, in CProps prop, string file, size_t line, EffectBoosterError errInfo) { mixin(S_TRACE);
		auto sp = std.string.split(value, ",");
		if (sp.length < 4) { mixin(S_TRACE);
			errInfo.add(.tryFormat(prop.msgs.jpyErrorInvalidRect, value), file, line);
			return CRect(0, 0, 0, 0);
		}
		try { mixin(S_TRACE);
			return CRect(to!(int)(astrip(sp[0])), to!(int)(astrip(sp[1])),
				to!(int)(astrip(sp[2])), to!(int)(astrip(sp[3])));
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
			errInfo.add(.tryFormat(prop.msgs.jpyErrorInvalidRect, value), file, line);
			return CRect(0, 0, 0, 0);
		}
	}
	CRGB rgbVal(string value, in CProps prop, string file, size_t line, EffectBoosterError errInfo) { mixin(S_TRACE);
		if (value.length < 7 || (value[0] != '$' && value[0] != '#')) { mixin(S_TRACE);
			try { mixin(S_TRACE);
				int val = std.conv.parse!int(value, 16);
				int r = val & 0xFF0000 >>> 16;
				int g = val & 0x00FF00 >>> 8;
				int b = val & 0x0000FF >>> 0;
				return CRGB(r, g, b);
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
				errInfo.add(.tryFormat(prop.msgs.jpyErrorInvalidRGB, value), file, line);
				return CRGB(0, 0, 0);
			}
		}
		auto sr = value[1 .. 3];
		auto sg = value[3 .. 5];
		auto sb = value[5 .. 7];
		try { mixin(S_TRACE);
			return CRGB(toImpl!int(sr, 16), toImpl!int(sg, 16), toImpl!int(sb, 16));
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
			errInfo.add(.tryFormat(prop.msgs.jpyErrorInvalidRGB, value), file, line);
			return CRGB(0, 0, 0);
		}
	}
	Enum enumVal(Enum)(string value, in CProps prop, string file, size_t line, EffectBoosterError errInfo) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			return cast(Enum) to!(int)(value);
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
			errInfo.add(.tryFormat(prop.msgs.jpyErrorInvalidEnum, value), file, line);
			return Enum.init;
		}
	}
	string strVal(string value, in CProps prop, string file, size_t line, EffectBoosterError errInfo) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			cwx.utils.validate(value);
			return value;
		} catch (Exception e) { mixin(S_TRACE);
			printStackTrace();
			debugln(e);
			try {
				return touni(value);
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
				errInfo.add(.tryFormat(prop.msgs.jpyErrorInvalidStr, value), file, line);
				return "";
			}
		}
	}
	int intVal(string value, in CProps prop, string file, size_t line, EffectBoosterError errInfo) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			if (value.endsWith("px")) value = value[0 .. $-2];
			return to!(int)(value);
		} catch (Exception e) {
			debugln(e);
			printStackTrace();
			errInfo.add(.tryFormat(prop.msgs.jpyErrorInvalidInt, value), file, line);
			return 0;
		}
	}
	bool boolVal(string value, in CProps prop, string file, size_t line, EffectBoosterError errInfo) { mixin(S_TRACE);
		return value == "1";
	}
}

/// pathのファイルを読み込む。
string readJPYFile(string path, in CProps prop, EffectBoosterError errInfo, out bool isSJIS) {
	char[] value;
	try {
		value = cast(char[])std.file.readText(path);
		isSJIS = false;
		return assumeUnique(value);
	} catch (Exception e) {
		isSJIS = true;
		value = cast(char[])readBinary(path);
		try {
			return touni(value);
		} catch (Exception e) {
			errInfo.add(prop.msgs.jpyErrorInvalidEncoding, path, 0);
			return "";
		}
	}
}
/// ditto
private string readJPYFile(string path, in CProps prop, EffectBoosterError errInfo) {
	try {
		return std.file.readText(path);
	} catch (UTFException e) {
		try {
			return touni(cast(char[])readBinary(path));
		} catch (Exception e) {
			errInfo.add(prop.msgs.jpyErrorInvalidEncoding, path, 0);
			return "";
		}
	}
}
/// pathへ書き込む。
void writeJPYFile(string path, string value, bool isSJIS) { mixin(S_TRACE);
	if (isSJIS) { mixin(S_TRACE);
		value = tosjis(value);
	}
	std.file.write(path, value);
}

private string stripValue(string eqAfter) { mixin(S_TRACE);
	auto value = astrip(eqAfter);
	if (value.length >= 2 && value[0] == '"' && value[$ - 1] == '"') { mixin(S_TRACE);
		value = value[1 .. $ - 1];
	}
	return value;
}

/// Jpy1の1ファイルの定義。
struct Jpy1 {
	/// ファイルに含まれるセクション。
	Jpy1Sec[] sections;
	/// ファイルパス。
	string jpy1Path;
	/// 改行コードを含めた全行をそのまま格納する。
	string[] lines;
	/// ファイルが本来はShift JISであればtrue。
	bool isSJIS;

	/// jpy1PathからJpy1を読込む。
	static Jpy1 load(in CProps prop, string sPath, string jpy1Path) { mixin(S_TRACE);
		Jpy1 r;
		auto errInfo = new EffectBoosterError;
		bool[string] secNames;
		r.jpy1Path = jpy1Path;
		r.lines = .splitLines(readJPYFile(jpy1Path, prop, errInfo, r.isSJIS), KeepTerminator.yes);
		foreach (i, line; r.lines) { mixin(S_TRACE);
			string origLine = line;
			line = line.chomp();
			auto lineNum = i + 1;
			line = astrip(line);
			if (!line.length || line[0] == ';') continue;
			if (line[0] == '[' && line[$ - 1] == ']') { mixin(S_TRACE);
				// label
				auto sec = new Jpy1Sec;
				sec.sPath = sPath;
				sec.fPath = jpy1Path;
				sec.label = astrip(line[1 .. $ - 1]);
				if (sec.label.toLower() in secNames) { mixin(S_TRACE);
					errInfo.add(.tryFormat(prop.msgs.jpyErrorDupSection, line), jpy1Path, lineNum);
				} else { mixin(S_TRACE);
					secNames[sec.label.toLower()] = true;
				}
				r.sections ~= sec;
				continue;
			}
			if (!r.sections.length) { mixin(S_TRACE);
				errInfo.add(prop.msgs.jpyErrorLabelNotFound, jpy1Path, lineNum);
				throw errInfo;
			}
			with (r.sections[$ - 1]) { mixin(S_TRACE);
				// contents
				int eq = .cCountUntil(line, '=');
				if (eq == -1) { mixin(S_TRACE);
					errInfo.add(.tryFormat(prop.msgs.jpyErrorInvalidLine, line), jpy1Path, lineNum);
					continue;
				}
				auto key = astrip(line[0 .. eq]);
				auto value = stripValue(line[eq + 1 .. $]);
				switch (.toLower(key)) {
				case "backwidth": backwidth = intVal(value, prop, jpy1Path, lineNum, errInfo); break;
				case "backheight": backheight = intVal(value, prop, jpy1Path, lineNum, errInfo); break;
				case "backcolor": backcolor = rgbVal(value, prop, jpy1Path, lineNum, errInfo); break;
				case "width": width = intVal(value, prop, jpy1Path, lineNum, errInfo); break;
				case "height": height = intVal(value, prop, jpy1Path, lineNum, errInfo); break;
				case "color": color = rgbVal(value, prop, jpy1Path, lineNum, errInfo); break;
				case "dirdepth": dirdepth = intVal(value, prop, jpy1Path, lineNum, errInfo); break;
				case "filename":
					filename = strVal(value, prop, jpy1Path, lineNum, errInfo);
					filenameIndex = i;
					filenameLine = origLine;
					break;
				case "flagname": break; // 編集ソフトが付与する特殊なコマンドで効果は無い
				case "dirtype": dirtype = enumVal!(Dirtype)(value, prop, jpy1Path, lineNum, errInfo); break;
				case "loadcache": loadcache = enumVal!(Cache)(value, prop, jpy1Path, lineNum, errInfo); break;
				case "savecache": savecache = enumVal!(Cache)(value, prop, jpy1Path, lineNum, errInfo); break;
				case "visible": visible = boolVal(value, prop, jpy1Path, lineNum, errInfo); break;
				case "position": position = pointVal(value, prop, jpy1Path, lineNum, errInfo); break;
				case "transparent": transparent = boolVal(value, prop, jpy1Path, lineNum, errInfo); break;
				case "clip": clip = rectVal(value, prop, jpy1Path, lineNum, errInfo); break;
				case "paintmode": paintmode = enumVal!(Paintmode)(value, prop, jpy1Path, lineNum, errInfo); break;
				case "alpha": alpha = intVal(value, prop, jpy1Path, lineNum, errInfo); break;
				case "animeclip": animeclip = rectVal(value, prop, jpy1Path, lineNum, errInfo); break;
				case "animation": animation = enumVal!(Animation)(value, prop, jpy1Path, lineNum, errInfo); break;
				case "animeposition": animeposition = pointVal(value, prop, jpy1Path, lineNum, errInfo); break;
				case "animemove": animemove = pointVal(value, prop, jpy1Path, lineNum, errInfo); break;
				case "wait": wait = intVal(value, prop, jpy1Path, lineNum, errInfo); break;
				case "animespeed": animespeed = intVal(value, prop, jpy1Path, lineNum, errInfo); break;
				case "smooth": smooth = boolVal(value, prop, jpy1Path, lineNum, errInfo); break;
				case "colorexchange": colorexchange = enumVal!(Colorexchange)(value, prop, jpy1Path, lineNum, errInfo); break;
				case "colormap": colormap = enumVal!(Colormap)(value, prop, jpy1Path, lineNum, errInfo); break;
				case "filter": filter = enumVal!(Filter)(value, prop, jpy1Path, lineNum, errInfo); break;
				case "mask": mask = enumVal!(Mask)(value, prop, jpy1Path, lineNum, errInfo); break;
				case "noise": noise = enumVal!(Noise)(value, prop, jpy1Path, lineNum, errInfo); break;
				case "noisepoint": noisepoint = intVal(value, prop, jpy1Path, lineNum, errInfo); break;
				case "turn": turn = enumVal!(Turn)(value, prop, jpy1Path, lineNum, errInfo); break;
				case "flip": flip = boolVal(value, prop, jpy1Path, lineNum, errInfo); break;
				case "mirror": mirror = boolVal(value, prop, jpy1Path, lineNum, errInfo); break;
				case "comment": comment = strVal(value, prop, jpy1Path, lineNum, errInfo); break;
				default:
					errInfo.add(.tryFormat( prop.msgs.jpyErrorInvalidCommand, key), jpy1Path, lineNum);
					continue;
				}
			}
		}
		if (errInfo.errors.length) throw errInfo;

		foreach (ref sec; r.sections) { mixin(S_TRACE);
			sec.path = sec.toMaterialPath();
			sec.needUpdate = false;
		}
		return r;
	}

	/// 使用回数カウンタを設定する。
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		foreach (ref sec; sections) { mixin(S_TRACE);
			sec.setUseCounter(uc);
		}
	}
	/// 使用回数カウンタを外す。
	void removeUseCounter() { mixin(S_TRACE);
		foreach (ref sec; sections) { mixin(S_TRACE);
			sec.removeUseCounter();
		}
	}

	/// ファイルパスの変更を反映する。
	/// oldPathがこのJpy1のファイルでもこのJpy1が含まれる
	/// ディレクトリでもない場合は何もしない。
	bool renameFile(string oldPath, string newPath) { mixin(S_TRACE);
		auto fPath = .nabs(jpy1Path);
		auto oPath = .nabs(oldPath);
		if (!fPath.fnstartsWith(oPath)) return false;
		if (!.cfnmatch(fPath, oPath)) { mixin(S_TRACE);
			newPath = newPath.buildPath(fPath.abs2rel(oPath));
		}
		jpy1Path = newPath;
		foreach (ref sec; sections) { mixin(S_TRACE);
			sec.fPath = jpy1Path;
		}
		return true;
	}

	/// ファイルパスの変更に伴ってファイルを上書き更新する。
	/// rewriteがfalseの場合はファイルの上書きはせず内部データのみを更新する。
	void updateJpy1File(in CProps prop, bool rewrite) { mixin(S_TRACE);
		bool update = false;
		foreach (ref sec; sections) { mixin(S_TRACE);
			if (sec.needUpdate && sec.filenameIndex != -1) { mixin(S_TRACE);
				int eq = sec.filenameLine.cCountUntil('=');
				assert (eq != -1);
				auto ret = sec.filenameLine[sec.filenameLine.chomp().length .. $];
				lines[sec.filenameIndex] = sec.filenameLine[0 .. eq+1] ~ sec.filename ~ ret;
				sec.needUpdate = false;
				update = true;
			}
		}
		if (update && rewrite) { mixin(S_TRACE);
			auto rLines = std.array.join(lines, "");
			if (isSJIS) { mixin(S_TRACE);
				rLines = tosjis(rLines);
			}
			std.file.write(jpy1Path, rLines);
		}
	}
}

/// Jpy1のセクションブロック。
class Jpy1Sec : PathUser, CWXPath {
	private this () { mixin(S_TRACE);
		super (this);
	}

	@property
	override
	string cwxPath(bool id) { mixin(S_TRACE);
		return "";
	}
	override
	CWXPath findCWXPath(string path) { mixin(S_TRACE);
		if (cpempty(path)) return this;
		return null;
	}
	@property
	override
	inout
	inout(CWXPath)[] cwxChilds() {return [];}
	@property
	override
	CWXPath cwxParent() {return null;}

	override
	void change(PathId newVal) { mixin(S_TRACE);
		super.change(newVal);
		auto newName = fromMaterialPath(cast(string)newVal);
		if (newName != filename) { mixin(S_TRACE);
			filename = newName;
			needUpdate = true;
		}
	}

	@property
	override
	void path(string path) { mixin(S_TRACE);
		super.path(path);
		auto newName = fromMaterialPath(path);
		if (newName != filename) { mixin(S_TRACE);
			filename = newName;
			needUpdate = true;
		}
	}

	private string toMaterialPath() { mixin(S_TRACE);
		string dir;
		switch (dirtype) {
		case Dirtype.CURRENT: { mixin(S_TRACE);
			dir = dirName(fPath);
		} break;
		case Dirtype.TABLE: return "";
		case Dirtype.SCHEME: return "";
		case Dirtype.SCENARIO: { mixin(S_TRACE);
			if (sPath == "") return "";
			dir = sPath;
		} break;
		case Dirtype.WAV: return "";
		case Dirtype.PARENT: { mixin(S_TRACE);
			dir = dirName(dirName(fPath));
			for (int dp = 0; dp < dirdepth; dp++) { mixin(S_TRACE);
				dir = dirName(dir);
			}
		} break;
		case Dirtype.PROGRAM: return "";
		default: return "";
		}
		auto fname = std.path.buildPath(dir, filename);
		sPath = .nabs(sPath);
		fname = .nabs(fname);
		if (fname.fnstartsWith(sPath)) { mixin(S_TRACE);
			return fname.abs2rel(sPath);
		}
		return "";
	}

	private string fromMaterialPath(string filename) { mixin(S_TRACE);
		string relPath(string sPath, string path) { mixin(S_TRACE);
			auto nsPath = nabs(sPath);
			auto nPath = nabs(path);
			return nPath.abs2rel(nsPath);
		}
		switch (dirtype) {
		case Dirtype.CURRENT: { mixin(S_TRACE);
			return relPath(dirName(fPath.abs2rel(sPath)), filename);
		} break;
		case Dirtype.TABLE: return filename.decodePath();
		case Dirtype.SCHEME: return filename.decodePath();
		case Dirtype.SCENARIO: { mixin(S_TRACE);
			return relPath(sPath, sPath.buildPath(filename));
		} break;
		case Dirtype.WAV: return filename.decodePath();
		case Dirtype.PARENT: { mixin(S_TRACE);
			string dir = dirName(dirName(fPath.abs2rel(sPath)));
			for (int dp = 0; dp < dirdepth; dp++) { mixin(S_TRACE);
				dir = dirName(dir);
			}
			return relPath(dir, filename);
		} break;
		case Dirtype.PROGRAM: return filename.decodePath();
		default: return filename.decodePath();
		}
	}

	/// 所属するシナリオのディレクトリ。
	/// シナリオに所属していない場合は""。
	string sPath;
	/// JPY1ファイルパス。
	string fPath;

	/// filenameがある行。ファイルの更新に使用する。
	int filenameIndex = -1;
	/// filenameがある行の内容。ファイルの更新に使用する。
	string filenameLine = "filename=";
	/// filenameが更新されたためファイルの上書きが必要な場合はtrue。
	bool needUpdate = false;

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
	static JptxTag parse(string startTag, in CProps prop, string file, size_t line, EffectBoosterError errInfo) { mixin(S_TRACE);
		auto reg = .match(toUTF32(startTag), .regex!(dstring)("^<[A-Z]+"d, "i"));
		if (reg.empty) { mixin(S_TRACE);
			errInfo.add(.tryFormat(prop.msgs.jpyErrorInvalidStartTag, startTag), file, line);
			return JptxTag();
		}
		JptxTag tag;
		tag.name = .toLower(toUTF8(reg.hit[1 .. $]));
		dstring p = reg.post;
		if (!p.length) { mixin(S_TRACE);
			errInfo.add(.tryFormat(prop.msgs.jpyErrorInvalidStartTag, startTag), file, line);
			return JptxTag();
		}
		if (startsWith(p, "=\""d)) { mixin(S_TRACE);
			int ei = .cCountUntil(p[2 .. $], '"');
			if (ei == -1) { mixin(S_TRACE);
				errInfo.add(.tryFormat(prop.msgs.jpyErrorInvalidStartTag, startTag), file, line);
				return JptxTag();
			}
			tag.tagValue = to!(int)(p[2 .. ei + 2]);
			p = p[ei + 4 .. $];
		}
		static const ATTR = " *([A-Z]+)=\"([^\"]+)\""d;
		auto attrReg = .regex!(dstring)(ATTR, "gi");
		foreach (m; .match(p, attrReg)) { mixin(S_TRACE);
			if(m.empty) break;
			p = m.post;
			auto cap = m.captures;
			tag.attr[.toLower(to!string(cap[1]))] = to!string(cap[2]);
		}
		return tag;
	} unittest { mixin(S_TRACE);
		debug mixin(UTPerf);
		auto t1 = JptxTag.parse("<b>", null, "", 0, null);
		assert (t1.name == "b");
		auto t2 = JptxTag.parse("<lineheight=\"80\">", null, "", 0, null);
		assert (t2.name == "lineheight");
		assert (t2.tagValue == 80);
		auto t3 = JptxTag.parse("<font face=\"face\" pixels=\"14\">", null, "", 0, null);
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

	private void startTag(string tagText, in CProps prop, string file, size_t line, EffectBoosterError errInfo) { mixin(S_TRACE);
		auto tag = JptxTag.parse(tagText, prop, file, line, errInfo);
		if (tag.name == "") return;
		switch (tag.name) {
		case "br": { mixin(S_TRACE);
			if (onBR) onBR();
		} break;
		case "b": { mixin(S_TRACE);
			if (onB) onB();
		} break;
		case "i": { mixin(S_TRACE);
			if (onI) onI();
		} break;
		case "u": { mixin(S_TRACE);
			if (onU) onU();
		} break;
		case "s": { mixin(S_TRACE);
			if (onS) onS();
		} break;
		case "shiftx": { mixin(S_TRACE);
			if (onShiftx) onShiftx(tag.tagValue);
		} break;
		case "shifty": { mixin(S_TRACE);
			if (onShifty) onShifty(tag.tagValue);
		} break;
		case "lineheight": { mixin(S_TRACE);
			if (onLineheight) onLineheight(tag.tagValue);
		} break;
		case "font": { mixin(S_TRACE);
			if (onFont) { mixin(S_TRACE);
				string face = "";
				CRGB rgb = CRGB(-1, -1, -1);
				int pixels = -1;
				auto pFace = "face" in tag.attr;
				if (pFace) face = strVal(*pFace, prop, file, line, errInfo);
				auto pRgb = "color" in tag.attr;
				if (pRgb) rgb = rgbVal(*pRgb, prop, file, line, errInfo);
				auto pPixels = "pixels" in tag.attr;
				if (pPixels) pixels = intVal(*pPixels, prop, file, line, errInfo);
				onFont(face, rgb, pixels);
			}
		} break;
		default: assert (0, tag.name);
		}
	}
	private void endTag(string tagText) { mixin(S_TRACE);
		auto tag = tagText[2 .. $ - 1];
		switch (.toLower(tag)) {
		case "b": { mixin(S_TRACE);
			if (onEndB) onEndB();
		} break;
		case "i": { mixin(S_TRACE);
			if (onEndI) onEndI();
		} break;
		case "u": { mixin(S_TRACE);
			if (onEndU) onEndU();
		} break;
		case "s": { mixin(S_TRACE);
			if (onEndS) onEndS();
		} break;
		case "shiftx": { mixin(S_TRACE);
			if (onEndShiftx) onEndShiftx();
		} break;
		case "shifty": { mixin(S_TRACE);
			if (onEndShifty) onEndShifty();
		} break;
		case "lineheight": { mixin(S_TRACE);
			if (onEndLineheight) onEndLineheight();
		} break;
		case "font": { mixin(S_TRACE);
			if (onEndFont) onEndFont();
		} break;
		default: assert (0, tag);
		}
	}
	void parse(string text, in CProps prop, string file, size_t line, EffectBoosterError errInfo) { mixin(S_TRACE);
		immutable TAG = "</(b|i|u|s|shiftx|shifty|lineheight|font)>"d
			~ "|<"d
			~ "(br|b|i|u|s|shiftx=\"-?[0-9]+\"|shifty=\"-?[0-9]+\""d
			~ "|lineheight=\"-?[0-9]+\""d
			~ "|font( +(face=\"[^\"]+\"|color=\"[\\$#][0-9A-Fa-f]{6}\""d
			~ "|pixels=\"[0-9]+\"))+)"d
			~ ">"d;
		if (autoline) { mixin(S_TRACE);
			auto r = .regex!(dstring)("^" ~ TAG ~ "$", "i");
			auto lines = splitLines!string(text);
			text = "";
			foreach (i, ln; lines) { mixin(S_TRACE);
				text ~= ln;
				if (i + 1 < lines.length && .match(toUTF32(ln), r).empty) { mixin(S_TRACE);
					text ~= "<br>";
				}
			}
		} else { mixin(S_TRACE);
			text = replace(text, "\r\n", "\n");
			text = replace(text, "\r", "\n");
		}
		auto r = .regex!(dstring)(TAG, "i");
		while (text.length) { mixin(S_TRACE);
			auto reg = .match(toUTF32(text), r);
			if (!reg.empty) { mixin(S_TRACE);
				line += .count(reg.pre, "\n");
				if (onText && reg.pre.length) onText(toUTF8(reg.pre.replace("\n", "")));
				auto m = toUTF8(reg.hit);
				if (std.algorithm.startsWith(m, "</")) { mixin(S_TRACE);
					endTag(m);
				} else { mixin(S_TRACE);
					startTag(m, prop, file, line, errInfo);
				}
				line += .count(reg.hit, "\n");
				text = toUTF8(reg.post);
				continue;
			}
			if (onText) { mixin(S_TRACE);
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
import std.typecons;
/// Jptxの1ファイルの定義。
struct Jptx {
	/// テキスト。タグがそのままの形で含まれる。
	string text;
	/// ファイルのパス。
	string file;
	/// テキストの開始位置。
	size_t textLine;
	/// エラーメッセージを引くための情報。
	Rebindable!(const CProps) props;

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

	unittest { mixin(S_TRACE);
		debug mixin(UTPerf);
		Jptx jptx;
		jptx.text = "Jptxのテスト。<br>改行した後、<b>太字<i>かつ斜体</i></b><s>打ち消し</s>"
			~ "<font color=\"$000000\" face=\"font!\" pixels=\"28\">font!の黒の28px"
			~ "<font color=\"$FF0000\">ここはfont!の赤の28px</font>ここもfont!の黒の28px</font>"
			~ "<shiftx=\"20\">shiftx=20<shiftx=\"-10\">shiftx=10</shiftx>shiftx=20</shiftx>"
			~ "<shifty=\"20\">shifty=20<shifty=\"-10\">shifty=10</shifty>shifty=20</shifty>"
			~ "<lineheight=\"50\">高さ50%<lineheight=\"30\">高さ30%</lineheight></lineheight>";
		jptx.fontface = "testfont";
		jptx.lineheight = 80;
		jptx.fontpixels = 18;
		jptx.fontcolor = CRGB(128, 128, 128);
		int count = 0;
		jptx.parse((string text, in JptxParam param) { mixin(S_TRACE);
			void chk(string t, bool b, bool i, bool u, bool s,
					int shiftx, int shifty, int lineheight,
					string face, CRGB color, int pixels) { mixin(S_TRACE);
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
			case 0: { mixin(S_TRACE);
				chk("Jptxのテスト。", false, false, false, false,
					0, 0, 80, "testfont", CRGB(128, 128, 128), 18);
			} break;
			case 1: { mixin(S_TRACE);
				chk("\n", false, false, false, false,
					0, 0, 80, "testfont", CRGB(128, 128, 128), 18);
			} break;
			case 2: { mixin(S_TRACE);
				chk("改行した後、", false, false, false, false,
					0, 0, 80, "testfont", CRGB(128, 128, 128), 18);
			} break;
			case 3: { mixin(S_TRACE);
				chk("太字", true, false, false, false,
					0, 0, 80, "testfont", CRGB(128, 128, 128), 18);
			} break;
			case 4: { mixin(S_TRACE);
				chk("かつ斜体", true, true, false, false,
					0, 0, 80, "testfont", CRGB(128, 128, 128), 18);
			} break;
			case 5: { mixin(S_TRACE);
				chk("打ち消し", false, false, false, true,
					0, 0, 80, "testfont", CRGB(128, 128, 128), 18);
			} break;
			case 6: { mixin(S_TRACE);
				chk("font!の黒の28px", false, false, false, false,
					0, 0, 80, "font!", CRGB(0, 0, 0), 28);
			} break;
			case 7: { mixin(S_TRACE);
				chk("ここはfont!の赤の28px", false, false, false, false,
					0, 0, 80, "font!", CRGB(255, 0, 0), 28);
			} break;
			case 8: { mixin(S_TRACE);
				chk("ここもfont!の黒の28px", false, false, false, false,
					0, 0, 80, "font!", CRGB(0, 0, 0), 28);
			} break;
			case 9: { mixin(S_TRACE);
				chk("shiftx=20", false, false, false, false,
					20, 0, 80, "testfont", CRGB(128, 128, 128), 18);
			} break;
			case 10: { mixin(S_TRACE);
				chk("shiftx=10", false, false, false, false,
					10, 0, 80, "testfont", CRGB(128, 128, 128), 18);
			} break;
			case 11: { mixin(S_TRACE);
				chk("shiftx=20", false, false, false, false,
					20, 0, 80, "testfont", CRGB(128, 128, 128), 18);
			} break;
			case 12: { mixin(S_TRACE);
				chk("shifty=20", false, false, false, false,
					0, 20, 80, "testfont", CRGB(128, 128, 128), 18);
			} break;
			case 13: { mixin(S_TRACE);
				chk("shifty=10", false, false, false, false,
					0, 10, 80, "testfont", CRGB(128, 128, 128), 18);
			} break;
			case 14: { mixin(S_TRACE);
				chk("shifty=20", false, false, false, false,
					0, 20, 80, "testfont", CRGB(128, 128, 128), 18);
			} break;
			case 15: { mixin(S_TRACE);
				chk("高さ50%", false, false, false, false,
					0, 0, 50, "testfont", CRGB(128, 128, 128), 18);
			} break;
			case 16: { mixin(S_TRACE);
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
	void parse(void delegate(string text, in JptxParam param) onText) { mixin(S_TRACE);
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
		int[] sShiftx, sShifty, sLineheight;
		string[] sFace;
		CRGB[] sColor;
		int[] sPixels;
		// parse
		JptxParser parser;
		parser.onB = () { mixin(S_TRACE);
			sB++;
			param.b = true;
		};
		parser.onEndB = () { mixin(S_TRACE);
			sB--;
			if (sB <= 0) param.b = false;
		};
		parser.onI = () { mixin(S_TRACE);
			sI++;
			param.i = true;
		};
		parser.onEndI = () { mixin(S_TRACE);
			sI--;
			if (sI <= 0) param.i = false;
		};
		parser.onU = () { mixin(S_TRACE);
			sU++;
			param.u = true;
		};
		parser.onEndU = () { mixin(S_TRACE);
			sU--;
			if (sU <= 0) param.u = false;
		};
		parser.onS = () { mixin(S_TRACE);
			sS++;
			param.s = true;
		};
		parser.onEndS = () { mixin(S_TRACE);
			sS--;
			if (sS <= 0) param.s = false;
		};
		parser.onShiftx = (int shiftx) { mixin(S_TRACE);
			sShiftx ~= shiftx;
			param.shiftx += shiftx;
		};
		parser.onEndShiftx = () { mixin(S_TRACE);
			if (!sShiftx.length) return;
			param.shiftx -= sShiftx[$ - 1];
			sShiftx = sShiftx[0 .. $ - 1];
		};
		parser.onShifty = (int shifty) { mixin(S_TRACE);
			sShifty ~= shifty;
			param.shifty += shifty;
		};
		parser.onEndShifty = () { mixin(S_TRACE);
			if (!sShifty.length) return;
			param.shifty -= sShifty[$ - 1];
			sShifty = sShifty[0 .. $ - 1];
		};
		parser.onLineheight = (int lineheight) { mixin(S_TRACE);
			sLineheight ~= lineheight;
			param.lineheight = lineheight;
		};
		parser.onEndLineheight = () { mixin(S_TRACE);
			if (!sLineheight.length) return;
			sLineheight = sLineheight[0 .. $ - 1];
			param.lineheight = sLineheight.length ? sLineheight[$ - 1] : 100;
		};
		parser.onFont = (string face, CRGB color, int pixels) { mixin(S_TRACE);
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
		parser.onEndFont = () { mixin(S_TRACE);
			if (!sFace.length) return;
			sFace = sFace[0 .. $ - 1];
			param.face = sFace.length ? sFace[$ - 1] : fontface;
			sColor = sColor[0 .. $ - 1];
			param.color = sColor.length ? sColor[$ - 1] : fontcolor;
			sPixels = sPixels[0 .. $ - 1];
			param.pixels = sPixels.length ? sPixels[$ - 1] : fontpixels;
		};
		parser.onBR = () { mixin(S_TRACE);
			onText("\n", param);
		};
		parser.onText = (string text) { mixin(S_TRACE);
			onText(text, param);
		};
		auto errInfo = new EffectBoosterError;
		parser.parse(text, props, file, textLine, errInfo);
		if (errInfo.errors.length) throw errInfo;
	}
	/// pathからJptxを読込む。
	static Jptx load(in CProps prop, string path) { mixin(S_TRACE);
		Jptx r;
		r.file = path;
		r.props = prop;
		auto errInfo = new EffectBoosterError;
		string t = "";
		bool textFirst = true;
		bool init = false;
		bool text = false;
		foreach (i, line; splitLines!string(readJPYFile(path, prop, errInfo))) { mixin(S_TRACE);
			auto lineNum = i + 1;
			auto sline = astrip(line);
			if (!text && sline.length && sline[0] == ';') continue;
			if (sline.length && sline[0] == '[' && sline[$ - 1] == ']') { mixin(S_TRACE);
				// label
				switch (astrip(sline[1 .. $ - 1])) {
				case "jptx:init": { mixin(S_TRACE);
					if (!text) { mixin(S_TRACE);
						init = true;
						text = false;
						continue;
					}
				} break;
				case "jptx:begin": { mixin(S_TRACE);
					if (!text) { mixin(S_TRACE);
						init = false;
						text = true;
						continue;
					}
				} break;
				case "jptx:end": { mixin(S_TRACE);
					init = true;
					text = false;
					continue;
				}
				default:
				}
			}
			if (init) { mixin(S_TRACE);
				with (r) { mixin(S_TRACE);
					// init
					int eq = .cCountUntil(sline, '=');
					if (eq == -1) { mixin(S_TRACE);
						errInfo.add(.tryFormat(prop.msgs.jpyErrorInvalidLine, line), path, lineNum);
						continue;
					}
					auto key = astrip(sline[0 .. eq]);
					auto value = stripValue(sline[eq + 1 .. $]);
					switch (.toLower(key)) {
					case "backcolor": backcolor = rgbVal(value, prop, path, lineNum, errInfo); break;
					case "backwidth": backwidth = intVal(value, prop, path, lineNum, errInfo); break;
					case "backheight": backheight = intVal(value, prop, path, lineNum, errInfo); break;
					case "autoline": autoline = boolVal(value, prop, path, lineNum, errInfo); break;
					case "lineheight": lineheight = intVal(value, prop, path, lineNum, errInfo); break;
					case "fontpixels": fontpixels = intVal(value, prop, path, lineNum, errInfo); break;
					case "fontcolor": fontcolor = rgbVal(value, prop, path, lineNum, errInfo); break;
					case "fontface": fontface = strVal(value, prop, path, lineNum, errInfo); break;
					case "antialias": antialias = intVal(value, prop, path, lineNum, errInfo); break;
					case "fonttransparent": fonttransparent = boolVal(value, prop, path, lineNum, errInfo); break;
					default:
						errInfo.add(.tryFormat(prop.msgs.jpyErrorInvalidCommand, key), path, lineNum);
						continue;
					}
				}
			}
			if (text) { mixin(S_TRACE);
				if (textFirst) { mixin(S_TRACE);
					textFirst = false;
					r.textLine = lineNum;
				} else { mixin(S_TRACE);
					t ~= "\n";
				}
				try { mixin(S_TRACE);
					cwx.utils.validate(line);
					t ~= line;
				} catch (Exception e) { mixin(S_TRACE);
					printStackTrace();
					debugln(e);
					t ~= touni(line);
				}
			}
		}
		if (t.length && t[$ - 1] == '\n') { mixin(S_TRACE);
			t = t[0 .. $ - 1];
		}
		r.text = t;
		if (errInfo.errors.length) throw errInfo;
		return r;
	}
}

/// JPTXの設定内からテキスト部分を抽出する。
string jptxText(string jptxAll) { mixin(S_TRACE);
	string r = "";
	bool inText = false;
	foreach (line; jptxAll.splitLines(KeepTerminator.yes)) { mixin(S_TRACE);
		if (!inText && chomp(line).icmp("[jptx:begin]") == 0) { mixin(S_TRACE);
			inText = true;
		} else if (inText && chomp(line).icmp("[jptx:end]") == 0) { mixin(S_TRACE);
			inText = false;
		} else if (inText) { mixin(S_TRACE);
			r ~= line;
		}
	}
	return r;
} unittest { mixin(S_TRACE);
	debug mixin(UTPerf);
	assert (jptxText("[jptx:init]\nline1\nline2\r\n\n[jptx:begin]\r\na\nbcd\r\nefg\r\n[jptx:end]")
		== "a\nbcd\r\nefg\r\n");
}
/// JPTXの設定内のテキスト部分を置換する。
string jptxText(string jptxAll, string jptxText) { mixin(S_TRACE);
	string r = "";
	bool inText = false, put = false;
	foreach (line; jptxAll.splitLines(KeepTerminator.yes)) { mixin(S_TRACE);
		if (!inText && chomp(line).icmp("[jptx:begin]") == 0) { mixin(S_TRACE);
			inText = true;
			r ~= line;
			if (!put) { mixin(S_TRACE);
				r ~= jptxText;
				put = true;
			}
		} else if (inText && chomp(line).icmp("[jptx:end]") == 0) { mixin(S_TRACE);
			inText = false;
			r ~= line;
		} else if (!inText) { mixin(S_TRACE);
			r ~= line;
		}
	}
	return r;
} unittest { mixin(S_TRACE);
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
	static Jpdc load(in CProps prop, string path) { mixin(S_TRACE);
		Jpdc r;
		auto errInfo = new EffectBoosterError;
		bool init = false;
		foreach (i, line; splitLines!string(readJPYFile(path, prop, errInfo))) { mixin(S_TRACE);
			auto lineNum = i + 1;
			line = astrip(line);
			if (!line.length || line[0] == ';') continue;
			if (line[0] == '[' && line[$ - 1] == ']') { mixin(S_TRACE);
				// label
				switch (astrip(line[1 .. $ - 1])) {
				case "jpdc:init": { mixin(S_TRACE);
					init = true;
					continue;
				} break;
				default:
				}
			}
			if (init) { mixin(S_TRACE);
				with (r) { mixin(S_TRACE);
					// init
					int eq = .cCountUntil(line, '=');
					if (eq == -1) { mixin(S_TRACE);
						errInfo.add(.tryFormat(prop.msgs.jpyErrorInvalidLine, line), path, lineNum);
					}
					auto key = astrip(line[0 .. eq]);
					auto value = stripValue(line[eq + 1 .. $]);
					switch (.toLower(key)) {
					case "clip": clip = rectVal(value, prop, path, lineNum, errInfo); break;
					case "copymode": copymode = enumVal!(Copymode)(value, prop, path, lineNum, errInfo); break;
					case "savefilename": saveFileName = strVal(value, prop, path, lineNum, errInfo); break;
					case "savecomment": savecomment = strVal(value, prop, path, lineNum, errInfo); break;
					default:
						errInfo.add(.tryFormat(prop.msgs.jpyErrorInvalidCommand, key), path, lineNum);
					}
				}
			}
		}
		if (errInfo.errors.length) throw errInfo;
		return r;
	}
}
