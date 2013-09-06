
module cwx.structs;

import cwx.perf;
import cwx.features;
import cwx.types;
import cwx.xml;

import std.conv;
import std.path;

/// 壁紙のスタイル。
enum WallpaperStyle {
	Center = 0, /// 中央に表示。
	Tile = 1, /// 並べて表示。
	Expand = 2, /// 拡大して表示。
	ExpandFull = 3 /// はみ出さないように拡大。
}

/// ソート方向を表す。
enum SortDir {
	Up = 1, /// 昇順。
	Down = 2, /// 降順。
	None = 0 /// ソートしない。
}

/// 台詞コンテントの簡易表示方式。
enum DialogStatus {
	Top = 0, /// 最上位を表示。
	Under = 1, /// 最下位を表示。
	UnderWithCoupon = 2, /// 最下位(条件クーポンあり)を表示。
}

/// 編集開始方法。
enum EditTrigger {
	Quick = 0, /// 2度のクリックで即編集開始。
	Slow = 1, /// ダブルクリックが発生した場合は編集開始しない。
}

/// 起動オプション。
struct LaunchOption {
	string conf;
	bool create = false;
	bool createclassic = false;
	string createName = null;
	string createSkin = null;
	string createclassicPath = "";
	string[] openPaths = [];
	string scenario = null;
	string selectfile = "";
	string putlangfile = "";
	bool noload = false;
	bool help = false;

	void parseStrings(string[] args) { mixin(S_TRACE);
		size_t sc = 0u;
		for (int i = 0; i < args.length; i++) { mixin(S_TRACE);
			try { mixin(S_TRACE);
				switch (args[i]) {
				case "-a": // エリア表示
					if (i + 1 < args.length) openPaths ~= "area:id:" ~ args[i + 1];
					sc = i + 2u;
					break;
				case "-b": // バトル表示
					if (i + 1 < args.length) openPaths ~= "battle:id:" ~ args[i + 1];
					sc = i + 2u;
					break;
				case "-p": // パッケージ表示
					if (i + 1 < args.length) openPaths ~= "package:id:" ~ args[i + 1];
					sc = i + 2u;
					break;
				case "-conf": // 設定ファイル指定
					if (i + 1 < args.length) conf = args[i + 1];
					sc = i + 2u;
					break;
				case "-create": // 起動と同時に新規作成
					create = true;
					if (i + 1 < args.length) createName = args[i + 1];
					if (i + 2 < args.length) createSkin = args[i + 2];
					sc = i + 3u;
					break;
				case "-createclassic": // 起動と同時に新規作成(クラシック)
					createclassic = true;
					if (i + 1 < args.length) createName = args[i + 1];
					if (i + 2 < args.length) createclassicPath = args[i + 2];
					sc = i + 3u;
					break;
				case "-selectfile": // 起動と同時にファイルを選択
					if (i + 1 < args.length) selectfile = args[i + 1];
					sc = i + 2u;
					break;
				case "-putlangfile": // 起動と同時に言語ファイルを出力して終了
					if (i + 1 < args.length) putlangfile = args[i + 1];
					sc = i + 1u;
					break;
				case "-noload": // 最後に開いていたシナリオを開かない
					noload = true;
					sc = i + 1u;
					break;
				case "-help", "-h", "/?": // usage
					help = true;
					break;
				default:
					if (i > sc) { mixin(S_TRACE);
						openPaths ~= args[i];
					}
					break;
				}
			} catch (Exception e) {
				debugln(e);
			}
		}
		if (sc < args.length) { mixin(S_TRACE);
			scenario = args[sc];
		}
		if (create || createclassic) { mixin(S_TRACE);
			scenario = null;
		}
	}
}

/// サイズを持つオブジェクト。
interface DSize {
	/// 幅。
	@property
	void width(int);
	/// ditto
	@property
	int width();
	/// 高さ。
	@property
	void height(int);
	/// ditto
	@property
	int height();
}

/// サイズと位置を持つオブジェクト。
interface WSize : DSize {
	/// X座標。
	@property
	void x(int);
	/// ditto
	@property
	int x();
	/// Y座標
	@property
	void y(int);
	/// ditto
	@property
	int y();
	/// 最大化。
	@property
	void maximized(bool);
	/// ditto
	@property
	bool maximized();
}

/// 座標を表す。
struct CPoint {
	int x;
	int y;
	const
	void toNode(ref XNode e, string name = "point") { mixin(S_TRACE);
		auto r = e.newElement(name);
		r.newAttr("x", x);
		r.newAttr("y", y);
	}
	void fromNode(ref XNode node) { mixin(S_TRACE);
		if (node.name != "point") throw new Exception("Node is not point");
		x = node.attr!(int)("x", true);
		y = node.attr!(int)("y", true);
	}
}

/// サイズを表す。
struct CSize {
	uint width;
	uint height;
	const
	void toNode(ref XNode e, string name = "size") { mixin(S_TRACE);
		auto r = e.newElement(name);
		r.newAttr("width", width);
		r.newAttr("height", height);
	}
	void fromNode(ref XNode node) { mixin(S_TRACE);
		width = node.attr!(uint)("width", true);
		height = node.attr!(uint)("height", true);
	}
}

/// 矩形範囲を表す。
struct CRect {
	int x;
	int y;
	int width;
	int height;
	const
	void toNode(ref XNode e, string name = "rect") { mixin(S_TRACE);
		auto r = e.newElement(name);
		r.newAttr("x", x);
		r.newAttr("y", y);
		r.newAttr("width", width);
		r.newAttr("height", height);
	}
	void fromNode(ref XNode node) { mixin(S_TRACE);
		x = node.attr!(int)("x", true);
		y = node.attr!(int)("y", true);
		width = node.attr!(int)("width", true);
		height = node.attr!(int)("height", true);
	}
}

/// 上下左右の値を持つ。
struct CInsets {
	int n; /// 上。
	int e; /// 右。
	int s; /// 下。
	int w; /// 左。
	const
	void toNode(ref XNode e, string name = "insets") { mixin(S_TRACE);
		auto r = e.newElement(name);
		r.newAttr("n", n);
		r.newAttr("e", this.e);
		r.newAttr("s", s);
		r.newAttr("w", w);
	}
	void fromNode(ref XNode node) { mixin(S_TRACE);
		n = node.attr!(int)("n", true);
		e = node.attr!(int)("e", true);
		s = node.attr!(int)("s", true);
		w = node.attr!(int)("w", true);
	}
}

/// RGB色情報。
struct CRGB {
	uint r;
	uint g;
	uint b;
	uint a = 255;
	const
	void toNode(ref XNode e, string name = "rgb") { mixin(S_TRACE);
		auto r = e.newElement(name);
		r.newAttr("r", this.r);
		r.newAttr("g", g);
		r.newAttr("b", b);
		r.newAttr("a", a);
	}
	void fromNode(ref XNode node) { mixin(S_TRACE);
		r = node.attr!(uint)("r", true);
		g = node.attr!(uint)("g", true);
		b = node.attr!(uint)("b", true);
		a = node.attr!(uint)("a", false, 255);
	}
}

/// フォント情報。
struct CFont {
	string name;
	uint point;
	bool bold;
	bool italic;
	const
	void toNode(ref XNode e, string name = "font") { mixin(S_TRACE);
		auto r = e.newElement(name);
		r.newAttr("name", name);
		r.newAttr("point", point);
		r.newAttr("bold", bold);
		r.newAttr("italic", italic);
	}
	void fromNode(ref XNode node) { mixin(S_TRACE);
		name = node.attr!(string)("name", true);
		point = node.attr!(uint)("point", true);
		bold = node.attr!(bool)("bold", true);
		italic = node.attr!(bool)("italic", true);
	}
}

/// 背景画像の簡単設定。
struct BgImageSetting {
	static const XML_NAME = "bgImageSetting";
	string name; /// 設定名。
	int x; /// X座標。
	int y; /// Y座標。
	int width; /// 幅。
	int height; /// 高さ。
	bool mask; /// マスク。
	/// コピーを作成する。
	@property
	const
	BgImageSetting dup() { mixin(S_TRACE);
		BgImageSetting r;
		r.name = name;
		r.x = x;
		r.y = y;
		r.width = width;
		r.height = height;
		r.mask = mask;
		return r;
	}
	static BgImageSetting opCall(string name, int x, int y, int width, int height, bool mask) {
		BgImageSetting r;
		r.name = name;
		r.x = x;
		r.y = y;
		r.width = width;
		r.height = height;
		r.mask = mask;
		return r;
	}
	/// XMLノードとして取り扱うための関数群。
	const
	XNode toNode() { mixin(S_TRACE);
		auto e = XNode.create(XML_NAME);
		toNodeImpl(e);
		return e;
	}
	/// ditto
	const
	void toNode(ref XNode node) { mixin(S_TRACE);
		auto e = node.newElement(XML_NAME);
		toNodeImpl(e);
	}
	/// ditto
	const
	private void toNodeImpl(ref XNode e) { mixin(S_TRACE);
		e.newElement("name", name);
		e.newElement("x", x);
		e.newElement("y", y);
		e.newElement("width", width);
		e.newElement("height", height);
		e.newElement("mask", mask);
	}
	/// ditto
	void fromNode(ref XNode node) { mixin(S_TRACE);
		name = node.childText("name", true);
		x = to!(int)(node.childText("x", true));
		y = to!(int)(node.childText("y", true));
		width = to!(int)(node.childText("width", true));
		height = to!(int)(node.childText("height", true));
		mask = to!(bool)(node.childText("mask", true));
	}
}

/// 外部ツールの設定。
struct OuterTool {
	static const XML_NAME = "tool";
	string name; /// 設定名。
	string command; /// コマンド。
	string workDir; /// 実行ディレクトリ。
	string mnemonic; /// アクセスキー。
	string hotkey; /// ショートカット。
	/// コピーを作成する。
	@property
	const
	OuterTool dup() { mixin(S_TRACE);
		OuterTool r;
		r.name = name;
		r.command = command;
		r.workDir = workDir;
		r.mnemonic = mnemonic;
		r.hotkey = hotkey;
		return r;
	}
	static OuterTool opCall(string name, string command, string workDir, string mnemonic, string hotkey) {
		OuterTool r;
		r.name = name;
		r.command = command;
		r.workDir = workDir;
		r.mnemonic = mnemonic;
		r.hotkey = hotkey;
		return r;
	}
	/// XMLノードとして取り扱うための関数群。
	const
	XNode toNode() { mixin(S_TRACE);
		auto e = XNode.create(XML_NAME);
		toNodeImpl(e);
		return e;
	}
	/// ditto
	const
	void toNode(ref XNode node) { mixin(S_TRACE);
		auto e = node.newElement(XML_NAME);
		toNodeImpl(e);
	}
	/// ditto
	const
	private void toNodeImpl(ref XNode e) { mixin(S_TRACE);
		e.newElement("name", name);
		e.newElement("command", command);
		e.newElement("workDir", workDir);
		if (mnemonic.length) e.newAttr("mnemonic", mnemonic);
		if (hotkey.length) e.newAttr("hotkey", hotkey);
	}
	/// ditto
	void fromNode(ref XNode node) { mixin(S_TRACE);
		name = node.childText("name", true);
		command = node.childText("command", true);
		workDir = node.childText("workDir", true);
		mnemonic = node.attr!string("mnemonic", false, "");
		hotkey = node.attr!string("hotkey", false, "");
	}
	/// コマンドをパースする。$Fをファイル名に置換、$Sをシナリオ名に置換する。
	static string parse(string str, string file, string sPath) { mixin(S_TRACE);
		dstring buf;
		bool bs = false;
		foreach (dchar c; str) { mixin(S_TRACE);
			if (bs) { mixin(S_TRACE);
				if (c == 'f' || c == 'F') { mixin(S_TRACE);
					buf ~= to!dstring(file);
				} else if (c == 's' || c == 'S') { mixin(S_TRACE);
					buf ~= to!dstring(sPath);
				} else if (c == '$') { mixin(S_TRACE);
					buf ~= "$"d;
				} else { mixin(S_TRACE);
					buf ~= "$"d ~ c;
				}
				bs = false;
			} else { mixin(S_TRACE);
				if (c == '$') { mixin(S_TRACE);
					bs = true;
				} else { mixin(S_TRACE);
					buf ~= c;
				}
			}
		}
		if (bs) { mixin(S_TRACE);
			buf ~= "$";
		}
		return to!string(buf);
	}
}

/// デフォルト設定用の背景画像構造体。
struct BgImageS {
	string type; /// セルのタイプ。image、text、colorのいずれか。
	int x; /// X座標。
	int y; /// Y座標。
	uint width; /// 幅。
	uint height; /// 高さ。
	bool mask; /// マスク。

	// ImageCell
	string name; /// ファイル名。拡張子はスキンによるため、拡張子を含めない。

	// TextCell
	string text;
	string fontName;
	uint size;
	CRGB color;
	bool bold;
	bool italic;
	bool underline;
	bool strike;
	bool vertical;
	BorderingType borderingType;
	CRGB borderingColor;
	uint borderingWidth;

	// ColorCell
	BlendMode blendMode;
	GradientDir gradientDir;
	CRGB color1;
	CRGB color2;

	/// 背景画像セルの設定を生成する。
	static BgImageS opCall(string name, int x, int y, int width, int height, bool mask) {
		BgImageS s;
		s.type = "image";
		s.name = name;
		s.x = x;
		s.y = y;
		s.width = width;
		s.height = height;
		s.mask = mask;
		return s;
	}

	/// XMLノードとして取り扱うための関数群。
	const
	void toNode(ref XNode e) { mixin(S_TRACE);
		auto r = e.newElement("background");
		r.newAttr("type", type);
		r.newAttr("x", x);
		r.newAttr("y", y);
		r.newAttr("width", width);
		r.newAttr("height", height);
		r.newAttr("mask", mask);
		switch (type) {
		case "image":
			r.newAttr("name", name);
			break;
		case "text":
			r.value = text;
			auto f = r.newElement("font", fontName);
			f.newAttr("size", size);
			if (bold) f.newAttr("bold", bold);
			if (italic) f.newAttr("italic", italic);
			if (underline) f.newAttr("underline", underline);
			if (strike) f.newAttr("strike", strike);
			if (vertical) f.newAttr("vertical", vertical);
			color.toNode(r);
			if (borderingType !is BorderingType.None) { mixin(S_TRACE);
				auto b = r.newElement("bordering");
				b.newAttr("type", fromBorderingType(borderingType));
				b.newAttr("width", borderingWidth);
				borderingColor.toNode(b);
			}
			break;
		case "color":
			r.newAttr("blendMode", fromBlendMode(blendMode));
			color1.toNode(r);
			if (gradientDir !is GradientDir.None) { mixin(S_TRACE);
				auto g = r.newElement("gradient");
				g.newAttr("direction", fromGradientDir(gradientDir));
				color2.toNode(g);
			}
			break;
		default:
			throw new Exception("Unknown type: " ~ type);
		}
	}
	/// ditto
	void fromNode(ref XNode node) { mixin(S_TRACE);
		if (node.name != "background") throw new Exception("Node is not background");
		type = node.attr!(string)("type", false, "image");
		x = node.attr!(int)("x", true);
		y = node.attr!(int)("y", true);
		width = node.attr!(uint)("width", true);
		height = node.attr!(uint)("height", true);
		mask = node.attr!(bool)("mask", true);
		switch (type) {
		case "image":
			name = node.attr!(string)("name", true);
			break;
		case "text":
			text = node.value;
			node.onTag["font"] = (ref XNode node) { mixin(S_TRACE);
				fontName = node.value;
				size = node.attr!uint("size", true);
				bold = node.attr!bool("bold", false, bold);
				italic = node.attr!bool("italic", false, italic);
				underline = node.attr!bool("underline", false, underline);
				strike = node.attr!bool("strike", false, strike);
				vertical = node.attr!bool("vertical", false, vertical);
			};
			node.onTag["rgb"] = (ref XNode node) { mixin(S_TRACE);
				color.fromNode(node);
			};
			node.onTag["bordering"] = (ref XNode node) { mixin(S_TRACE);
				borderingType = toBorderingType(node.attr("type", true));
				borderingWidth = node.attr!uint("width", true);
				node.onTag["rgb"] = (ref XNode node) { mixin(S_TRACE);
					borderingColor.fromNode(node);
				};
				node.parse();
			};
			node.parse();
			break;
		case "color":
			blendMode = toBlendMode(node.attr("blendMode", true));
			node.onTag["rgb"] = (ref XNode node) { mixin(S_TRACE);
				color1.fromNode(node);
			};
			node.onTag["gradient"] = (ref XNode node) { mixin(S_TRACE);
				gradientDir = toGradientDir(node.attr("direction", true));
				node.onTag["rgb"] = (ref XNode node) { mixin(S_TRACE);
					color2.fromNode(node);
				};
				node.parse();
			};
			node.parse();
			break;
		default:
			throw new Exception("Unknown type: " ~ type);
		}
	}
}

/// クラシックなエンジンの情報。
struct ClassicEngine {
	static const XML_NAME = "classicEngine";
	string name; /// 情報名。
	string enginePath = ""; /// 実行ファイルのパス。
	string dataDirName = ""; /// データフォルダのパス。
	string execute = ""; /// 実行ファイルの代わりに実行されるファイルの名称。
	string mnemonic; /// アクセスキー。
	string hotkey; /// ショートカット。

	string okText = null;
	string[string] sexName;
	string[string] periodName;
	string[string] natureName;
	string[string] makingsName;

	int[Physical][Sex] physicalModSex;
	int[Physical][Period] physicalModPeriod;
	int[Physical][Nature] physicalModNature;
	int[Physical][Makings] physicalModMakings;
	real[Mental][Sex] mentalModSex;
	real[Mental][Period] mentalModPeriod;
	real[Mental][Nature] mentalModNature;
	real[Mental][Makings] mentalModMakings;

	private static R[P][E] dupAA(P, E, R)(in R[P][E] aa) { mixin(S_TRACE);
		R[P][E] r;
		foreach (key1, value1; aa) { mixin(S_TRACE);
			R[P] arr;
			foreach (key2, value2; value1) { mixin(S_TRACE);
				arr[key2] = value2;
			}
			r[key1] = arr;
		}
		return r;
	}

	/// コピーを生成する。
	@property
	const
	ClassicEngine dup() { mixin(S_TRACE);
		ClassicEngine ce;
		ce.name = name;
		ce.enginePath = enginePath;
		ce.dataDirName = dataDirName;
		ce.execute = execute;
		ce.mnemonic = mnemonic;
		ce.hotkey = hotkey;
		ce.okText = okText;

		foreach (key, value; sexName) ce.sexName[key] = value;
		foreach (key, value; periodName) ce.periodName[key] = value;
		foreach (key, value; natureName) ce.natureName[key] = value;
		foreach (key, value; makingsName) ce.makingsName[key] = value;

		ce.physicalModSex = dupAA!(Physical, Sex, int)(physicalModSex);
		ce.physicalModPeriod = dupAA!(Physical, Period, int)(physicalModPeriod);
		ce.physicalModNature = dupAA!(Physical, Nature, int)(physicalModNature);
		ce.physicalModMakings = dupAA!(Physical, Makings, int)(physicalModMakings);
		ce.mentalModSex = dupAA!(Mental, Sex, real)(mentalModSex);
		ce.mentalModPeriod = dupAA!(Mental, Period, real)(mentalModPeriod);
		ce.mentalModNature = dupAA!(Mental, Nature, real)(mentalModNature);
		ce.mentalModMakings = dupAA!(Mental, Makings, real)(mentalModMakings);

		return ce;
	}

	/// エンジンを実行する。
	const
	string executePath(string appPath, bool engine) { mixin(S_TRACE);
		if (!enginePath.length) return "";
		string path = enginePath;
		if (!.isAbsolute(path)) { mixin(S_TRACE);
			auto dir = appPath.dirName();
			path = std.path.buildPath(dir, path);
		}
		if (!engine && execute.length) { mixin(S_TRACE);
			if (.isAbsolute(execute)) { mixin(S_TRACE);
				path = execute;
			} else { mixin(S_TRACE);
				path = std.path.buildPath(path.dirName(), execute);
			}
		}
		return path;
	}
	/// XMLノードとして取り扱うための関数群。
	const
	XNode toNode() { mixin(S_TRACE);
		auto e = XNode.create(XML_NAME);
		toNodeImpl(e);
		return e;
	}
	/// ditto
	const
	void toNode(ref XNode node) { mixin(S_TRACE);
		auto e = node.newElement(XML_NAME);
		toNodeImpl(e);
	}
	/// ditto
	const
	private void toNodeImpl(ref XNode e) { mixin(S_TRACE);
		e.newAttr("name", name);
		e.newAttr("enginePath", enginePath);
		e.newAttr("dataDirName", dataDirName);
		e.newAttr("execute", execute);
		if (mnemonic.length) e.newAttr("mnemonic", mnemonic);
		if (hotkey.length) e.newAttr("hotkey", hotkey);
		if (okText !is null) e.newAttr("okText", okText);
		if (sexName.length) { mixin(S_TRACE);
			auto ee = e.newElement("sexName");
			foreach (key, value; sexName) { mixin(S_TRACE);
				auto ne = ee.newElement("name", value);
				ne.newAttr("key", key);
			}
		}
		if (periodName.length) { mixin(S_TRACE);
			auto ee = e.newElement("periodName");
			foreach (key, value; periodName) { mixin(S_TRACE);
				auto ne = ee.newElement("name", value);
				ne.newAttr("key", key);
			}
		}
		if (natureName.length) { mixin(S_TRACE);
			auto ee = e.newElement("natureName");
			foreach (key, value; natureName) { mixin(S_TRACE);
				auto ne = ee.newElement("name", value);
				ne.newAttr("key", key);
			}
		}
		if (makingsName.length) { mixin(S_TRACE);
			auto ee = e.newElement("makingsName");
			foreach (key, value; makingsName) { mixin(S_TRACE);
				auto ne = ee.newElement("name", value);
				ne.newAttr("key", key);
			}
		}
		putAA!(Physical, Sex, int)(e, "sexPhysical", physicalModSex);
		putAA!(Physical, Period, int)(e, "periodPhysical", physicalModPeriod);
		putAA!(Physical, Nature, int)(e, "naturePhysical", physicalModNature);
		putAA!(Physical, Makings, int)(e, "makingsPhysical", physicalModMakings);
		putAA!(Mental, Sex, real)(e, "sexMental", mentalModSex);
		putAA!(Mental, Period, real)(e, "periodMental", mentalModPeriod);
		putAA!(Mental, Nature, real)(e, "natureMental", mentalModNature);
		putAA!(Mental, Makings, real)(e, "makingsMental", mentalModMakings);
	}
	private static void putAA(P, E, R)(ref XNode e, string eName, in R[P][E] aa) { mixin(S_TRACE);
		static if (is(E:Sex)) {
			alias fromSex toNameE;
		} else static if (is(E:Period)) {
			alias fromPeriod toNameE;
		} else static if (is(E:Nature)) {
			alias fromNature toNameE;
		} else static if (is(E:Makings)) {
			alias fromMakings toNameE;
		} else static assert (0);
		static if (is(P:Physical)) {
			alias fromPhysical toNameP;
		} else static if (is(P:Mental)) {
			alias fromMental toNameP;
		} else static assert (0);
		if (!aa.length) return;
		auto ee = e.newElement(eName);
		foreach (key1, value1; aa) { mixin(S_TRACE);
			if (!value1.length) continue;
			auto pe = ee.newElement("params");
			pe.newAttr("key", toNameE(key1));
			foreach (key2, value2; value1) { mixin(S_TRACE);
				auto ve = pe.newElement("value", .text(value2));
				ve.newAttr("key", toNameP(key2));
			}
		}
	}

	/// エンジンの実行ファイル名から拡張子を取り戻した文字列を返す。
	@property
	const
	string legacyName() { mixin(S_TRACE);
		return enginePath.baseName().stripExtension();
	}

	/// 特徴名をクリアする。
	void clearFeatures() { mixin(S_TRACE);
		okText = null;
		typeof(this.sexName) sexName;
		this.sexName = sexName;
		typeof(this.periodName) periodName;
		this.periodName = periodName;
		typeof(this.natureName) natureName;
		this.natureName = natureName;
		typeof(this.makingsName) makingsName;
		this.makingsName = makingsName;

		typeof(this.physicalModSex) physicalModSex;
		this.physicalModSex = physicalModSex;
		typeof(this.physicalModPeriod) physicalModPeriod;
		this.physicalModPeriod = physicalModPeriod;
		typeof(this.physicalModNature) physicalModNature;
		this.physicalModNature = physicalModNature;
		typeof(this.physicalModMakings) physicalModMakings;
		this.physicalModMakings = physicalModMakings;
		typeof(this.mentalModSex) mentalModSex;
		this.mentalModSex = mentalModSex;
		typeof(this.mentalModPeriod) mentalModPeriod;
		this.mentalModPeriod = mentalModPeriod;
		typeof(this.mentalModNature) mentalModNature;
		this.mentalModNature = mentalModNature;
		typeof(this.mentalModMakings) mentalModMakings;
		this.mentalModMakings = mentalModMakings;
	}

	/// ditto
	void fromNode(ref XNode node) { mixin(S_TRACE);
		if (node.name != "classicEngine") throw new Exception("Node is not classicEngine");
		clearFeatures();

		name = node.attr!(string)("name", true);
		enginePath = node.attr!(string)("enginePath", true);
		dataDirName = node.attr!(string)("dataDirName", true);
		execute = node.attr!(string)("execute", true);
		mnemonic = node.attr!string("mnemonic", false, "");
		hotkey = node.attr!string("hotkey", false, "");
		okText = node.attr!string("okText", false, null);
		node.onTag["sexName"] = (ref XNode node) { mixin(S_TRACE);
			node.onTag["name"] = (ref XNode node) { mixin(S_TRACE);
				string key = node.attr!string("key", false, null);
				if (key !is null) sexName[key] = node.value;
			};
			node.parse();
		};
		node.onTag["periodName"] = (ref XNode node) { mixin(S_TRACE);
			node.onTag["name"] = (ref XNode node) { mixin(S_TRACE);
				string key = node.attr!string("key", false, null);
				if (key !is null) periodName[key] = node.value;
			};
			node.parse();
		};
		node.onTag["natureName"] = (ref XNode node) { mixin(S_TRACE);
			node.onTag["name"] = (ref XNode node) { mixin(S_TRACE);
				string key = node.attr!string("key", false, null);
				if (key !is null) natureName[key] = node.value;
			};
			node.parse();
		};
		node.onTag["makingsName"] = (ref XNode node) { mixin(S_TRACE);
			node.onTag["name"] = (ref XNode node) { mixin(S_TRACE);
				string key = node.attr!string("key", false, null);
				if (key !is null) makingsName[key] = node.value;
			};
			node.parse();
		};
		getAA(node, "sexPhysical", physicalModSex);
		getAA(node, "periodPhysical", physicalModPeriod);
		getAA(node, "naturePhysical", physicalModNature);
		getAA(node, "makingsPhysical", physicalModMakings);
		getAA(node, "sexMental", mentalModSex);
		getAA(node, "periodMental", mentalModPeriod);
		getAA(node, "natureMental", mentalModNature);
		getAA(node, "makingsMental", mentalModMakings);
		node.parse();
	}
	private static void getAA(P, E, R)(ref XNode node, string eName, ref R[P][E] aa) { mixin(S_TRACE);
		static if (is(E:Sex)) {
			alias toSex fromNameE;
		} else static if (is(E:Period)) {
			alias toPeriod fromNameE;
		} else static if (is(E:Nature)) {
			alias toNature fromNameE;
		} else static if (is(E:Makings)) {
			alias toMakings fromNameE;
		} else static assert (0);
		static if (is(P:Physical)) {
			alias toPhysical fromName;
		} else static if (is(P:Mental)) {
			alias toMental fromName;
		} else static assert (0);
		node.onTag[eName] = (ref XNode node) { mixin(S_TRACE);
			R[P] arr;
			string keyStr = node.attr!string("key", false, "");
			if (keyStr.length) { mixin(S_TRACE);
				auto key = fromNameE(keyStr);
				node.onTag["params"] = (ref XNode node) { mixin(S_TRACE);
					auto keyStr = node.attr!string("key", false, "");
					if (keyStr.length) { mixin(S_TRACE);
						auto key = fromName(keyStr);
						arr[key] = to!R(node.value);
					}
				};
				node.parse();
				if (arr.length) { mixin(S_TRACE);
					aa[key] = arr;
				}
			}
		};
	}
}

/// シナリオのテンプレートの情報。
struct ScTemplate {
	static const XML_NAME = "scenarioTemplate";
	string name; /// 情報名。
	string path = ""; /// ファイル・ディレクトリのパス。

	/// XMLノードとして取り扱うための関数群。
	const
	XNode toNode() { mixin(S_TRACE);
		auto e = XNode.create(XML_NAME);
		toNodeImpl(e);
		return e;
	}
	/// ditto
	const
	void toNode(ref XNode node) { mixin(S_TRACE);
		auto e = node.newElement(XML_NAME);
		toNodeImpl(e);
	}
	/// ditto
	const
	private void toNodeImpl(ref XNode e) { mixin(S_TRACE);
		e.newAttr("name", name);
		e.newAttr("path", path);
	}
	/// ditto
	void fromNode(ref XNode node) { mixin(S_TRACE);
		if (node.name != XML_NAME) throw new Exception("Node is not scenarioTemplate");
		name = node.attr!(string)("name", true);
		path = node.attr!(string)("path", true);
	}
}

/// イベントのテンプレートの情報。
struct EvTemplate {
	static const XML_NAME = "eventTemplate";
	string name; /// 情報名。
	string script = ""; /// スクリプト。
	string mnemonic = ""; /// アクセスキー。
	string hotkey = ""; /// ショートカット。

	/// XMLノードとして取り扱うための関数群。
	const
	XNode toNode() { mixin(S_TRACE);
		auto e = XNode.create(XML_NAME, script);
		toNodeImpl(e);
		return e;
	}
	/// ditto
	const
	void toNode(ref XNode node) { mixin(S_TRACE);
		auto e = node.newElement(XML_NAME, script);
		toNodeImpl(e);
	}
	/// ditto
	const
	private void toNodeImpl(ref XNode e) { mixin(S_TRACE);
		e.newAttr("name", name);
		if (mnemonic.length) e.newAttr("mnemonic", mnemonic);
		if (hotkey.length) e.newAttr("hotkey", hotkey);
	}
	/// ditto
	void fromNode(ref XNode node) { mixin(S_TRACE);
		if (node.name != XML_NAME) throw new Exception("Node is not eventTemplate");
		name = node.attr!(string)("name", true);
		mnemonic = node.attr!string("mnemonic", false, "");
		hotkey = node.attr!string("hotkey", false, "");
		script = node.value;
	}
}

/// 開いたシナリオの履歴。
struct OpenHistory {
	static const XML_NAME = "openHistory";
	string path; /// シナリオのパス。
	string skinName = ""; /// スキン名。skinEngineより優先される。
	string skinEngine = ""; /// リソースを使用するエンジン名。

	/// XMLノードとして取り扱うための関数群。
	const
	XNode toNode() { mixin(S_TRACE);
		auto e = XNode.create(XML_NAME, path);
		toNodeImpl(e);
		return e;
	}
	/// ditto
	const
	void toNode(ref XNode node) { mixin(S_TRACE);
		auto e = node.newElement(XML_NAME, path);
		toNodeImpl(e);
	}
	/// ditto
	const
	private void toNodeImpl(ref XNode e) { mixin(S_TRACE);
		if (skinName.length) e.newAttr("skinName", skinName);
		if (skinEngine.length) e.newAttr("skinEngine", skinEngine);
	}
	/// ditto
	void fromNode(ref XNode node) { mixin(S_TRACE);
		// 以前のバージョンでは要素名が"value"になっている
		// 可能性があるため、チェックしない

		skinName = node.attr!(string)("skinName", false, "");
		skinEngine = node.attr!(string)("skinEngine", false, "");
		path = node.value;
	}
}
