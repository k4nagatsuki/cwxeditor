
module cwx.structs;

import cwx.perf;
import cwx.utils : printStackTrace, fromBool, debugln;
import cwx.features;
import cwx.types;
import cwx.xml;

import std.ascii;
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

DialogStatus toDialogStatus(int dialogStatus) { mixin(S_TRACE);
	switch (dialogStatus) {
	case DialogStatus.Top:
	case DialogStatus.Under:
	case DialogStatus.UnderWithCoupon:
		return cast(DialogStatus)dialogStatus;
	default:
		return DialogStatus.Top;
	}
}

/// 状態の強度と持続時間の表示。
enum ShowStatusTime {
	No = 0, /// 表示しない。
	Always = 1, /// 常に表示。
	WithSkin = 2, /// スキン使用時のみ表示。
}

ShowStatusTime toShowStatusTime(int showStatusTime) { mixin(S_TRACE);
	switch (showStatusTime) {
	case ShowStatusTime.No:
	case ShowStatusTime.Always:
	case ShowStatusTime.WithSkin:
		return cast(ShowStatusTime)showStatusTime;
	default:
		return ShowStatusTime.Always;
	}
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
	string createSkinType = null;
	string createSkinName = null;
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
					i++;
					break;
				case "-b": // バトル表示
					if (i + 1 < args.length) openPaths ~= "battle:id:" ~ args[i + 1];
					sc = i + 2u;
					i++;
					break;
				case "-p": // パッケージ表示
					if (i + 1 < args.length) openPaths ~= "package:id:" ~ args[i + 1];
					sc = i + 2u;
					i++;
					break;
				case "-conf": // 設定ファイル指定
					if (i + 1 < args.length) conf = args[i + 1];
					sc = i + 2u;
					i++;
					break;
				case "-create": // 起動と同時に新規作成
					create = true;
					if (i + 1 < args.length) createName = args[i + 1];
					if (i + 2 < args.length) createSkinType = args[i + 2];
					if (i + 3 < args.length) createSkinName = args[i + 3];
					sc = i + 4u;
					i += 2;
					break;
				case "-createclassic": // 起動と同時に新規作成(クラシック)
					createclassic = true;
					if (i + 1 < args.length) createName = args[i + 1];
					if (i + 2 < args.length) createclassicPath = args[i + 2];
					sc = i + 3u;
					i += 2;
					break;
				case "-selectfile": // 起動と同時にファイルを選択
					if (i + 1 < args.length) selectfile = args[i + 1];
					sc = i + 2u;
					i++;
					break;
				case "-putlangfile": // 起動と同時に言語ファイルを出力して終了
					if (i + 1 < args.length) putlangfile = args[i + 1];
					sc = i + 1u;
					i++;
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
				printStackTrace();
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
	string name; /// フォント名。
	uint point; /// ポイントサイズ、または使用される文脈によってピクセルサイズ。
	bool bold; /// 太字か。
	bool italic; /// 斜体か。
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
	int layer; /// レイヤ。
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
		r.layer = layer;
		return r;
	}
	static BgImageSetting opCall(string name, int x, int y, int width, int height, bool mask, int layer) {
		BgImageSetting r;
		r.name = name;
		r.x = x;
		r.y = y;
		r.width = width;
		r.height = height;
		r.mask = mask;
		r.layer = layer;
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
		e.newElement("layer", layer);
	}
	/// ditto
	void fromNode(ref XNode node) { mixin(S_TRACE);
		name = node.childText("name", true);
		x = to!(int)(node.childText("x", true));
		y = to!(int)(node.childText("y", true));
		width = to!(int)(node.childText("width", true));
		height = to!(int)(node.childText("height", true));
		mask = to!(bool)(node.childText("mask", true));
		layer = to!(int)(node.childText("layer", LAYER_BACK_CELL));
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
		return .parseDollarParams(str, ['F':file, 'S':sPath]);
	} unittest { mixin(S_TRACE);
		debug mixin(UTPerf);

		assert (parse("cwxeditor $F $S $$", "FILE", "SCENARIO") == "cwxeditor FILE SCENARIO $");
		assert (parse("cwxeditor $s $f $$", "FILE", "SCENARIO") == "cwxeditor SCENARIO FILE $");
	}
}

/// '$'記号で表されるフォーマット文字列を連想配列が持つパラメータに置換する。
/// 例えば"name=$N"のような文字列と{ 'N':"VALUE" }のような連想配列を
/// "name=VALUE"に変換する。
/// "$$"は'$'に変換する。
string parseDollarParams(in char[] format, in string[char] params) { mixin(S_TRACE);
	char[] buf;
	bool bs = false;
	foreach (c; format) { mixin(S_TRACE);
		if (bs) { mixin(S_TRACE);
			if (auto p = c.toLower() in params) { mixin(S_TRACE);
				buf ~= *p;
			} else if (auto p = c.toUpper() in params) { mixin(S_TRACE);
				buf ~= *p;
			} else if (c == '$') { mixin(S_TRACE);
				buf ~= '$';
			} else { mixin(S_TRACE);
				buf ~= '$';
				buf ~= c;
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
		buf ~= '$';
	}
	return to!string(buf);
} unittest { mixin(S_TRACE);
	debug mixin(UTPerf);

	assert (parseDollarParams("notepad $F", ['f':"filename"]) == "notepad filename");
	assert (parseDollarParams(" $F / $s / $$ /", ['f':"fff", 'S':"ssss"]) == " fff / ssss / $ /");
}

/// デフォルト設定用の背景画像構造体。
struct BgImageS {
	string type; /// セルのタイプ。image、text、colorのいずれか。
	int x; /// X座標。
	int y; /// Y座標。
	uint width; /// 幅。
	uint height; /// 高さ。
	bool mask; /// マスク。
	int layer; /// レイヤ。
	string cellName; /// イベント操作用のセル名。
	Smoothing smoothing = Smoothing.Default; /// ImageCellとPCCellで使用する背景のスムージング設定(Wsn.2)。

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
	bool antialias;
	BorderingType borderingType;
	CRGB borderingColor;
	uint borderingWidth;
	UpdateType updateType;

	// ColorCell
	BlendMode blendMode;
	GradientDir gradientDir;
	CRGB color1;
	CRGB color2;

	// PCCell
	uint pcNumber;
	bool expand;

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
		r.newAttr("cellName", cellName);
		r.newAttr("layer", to!string(layer));
		switch (type) {
		case "image":
			r.newAttr("name", name);
			r.newAttr("smoothing", fromSmoothing(smoothing));
			break;
		case "text":
			r.newElement("text", text);
			auto f = r.newElement("font", fontName);
			f.newAttr("size", size);
			if (bold) f.newAttr("bold", bold);
			if (italic) f.newAttr("italic", italic);
			if (underline) f.newAttr("underline", underline);
			if (strike) f.newAttr("strike", strike);
			if (vertical) f.newAttr("vertical", vertical);
			if (antialias) f.newAttr("antialias", antialias);
			color.toNode(r);
			if (borderingType !is BorderingType.None) { mixin(S_TRACE);
				auto b = r.newElement("bordering");
				b.newAttr("type", fromBorderingType(borderingType));
				b.newAttr("width", borderingWidth);
				borderingColor.toNode(b);
			}
			r.newAttr("updateType", fromUpdateType(updateType));
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
		case "pc":
			r.newAttr("pcNumber", to!string(pcNumber));
			r.newAttr("expand", fromBool(expand));
			r.newAttr("smoothing", fromSmoothing(smoothing));
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
		mask = node.attr!(bool)("mask", false, false);
		layer = node.attr!(int)("layer", false, false);
		cellName = node.attr("cellName", false, "");
		switch (type) {
		case "image":
			name = node.attr!(string)("name", true);
			smoothing = toSmoothing(node.attr("smoothing", false, "Default"));
			break;
		case "text":
			node.onTag["text"] = (ref XNode node) { mixin(S_TRACE);
				text = node.value;
			};
			node.onTag["font"] = (ref XNode node) { mixin(S_TRACE);
				fontName = node.value;
				size = node.attr!uint("size", true);
				bold = node.attr!bool("bold", false, bold);
				italic = node.attr!bool("italic", false, italic);
				underline = node.attr!bool("underline", false, underline);
				strike = node.attr!bool("strike", false, strike);
				vertical = node.attr!bool("vertical", false, vertical);
				antialias = node.attr!bool("antialias", false, antialias);
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
			updateType = toUpdateType(node.attr("updateType", false, "Variables"));
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
		case "pc":
			pcNumber = node.attr!(uint)("pcNumber", true);
			expand = node.attr!(bool)("expand", false, false);
			smoothing = toSmoothing(node.attr("smoothing", false, "Default"));
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

/// クラシックな性別を文字列に変換する。
string fromSex(Sex e) { mixin(S_TRACE);
	if (e == Sex(0)) return "Male";   // 男
	if (e == Sex(1)) return "Female"; // 女
	throw new Exception(e.text());
}
/// ditto
Sex toSex(string e) { mixin(S_TRACE);
	final switch (e) {
	case "Male":   return Sex(0);
	case "Female": return Sex(1);
	}
}

/// クラシックな年代を文字列に変換する。
string fromPeriod(Period e) { mixin(S_TRACE);
	if (e == Period(0)) return "Child"; // 子供
	if (e == Period(1)) return "Young"; // 若者
	if (e == Period(2)) return "Adult"; // 大人
	if (e == Period(3)) return "Old";   // 老人
	throw new Exception(e.text());
}
/// ditto
Period toPeriod(string e) { mixin(S_TRACE);
	final switch (e) {
	case "Child": return Period(0); // 子供
	case "Young": return Period(1); // 若者
	case "Adult": return Period(2); // 大人
	case "Old":   return Period(3); // 老人
	}
}

/// クラシックな素質を文字列に変換する。
string fromNature(Nature e) { mixin(S_TRACE);
	if (e == Nature(0))  return "Spi"; // 標準型
	if (e == Nature(1))  return "Agl"; // 万能型
	if (e == Nature(2))  return "Str"; // 勇将型
	if (e == Nature(3))  return "Vit"; // 豪傑型
	if (e == Nature(4))  return "Int"; // 知将型
	if (e == Nature(5))  return "Sch"; // 策士型
	if (e == Nature(6))  return "Med"; // 凡庸型
	if (e == Nature(7))  return "Bri"; // 英明型
	if (e == Nature(8))  return "Mat"; // 無双型
	if (e == Nature(9))  return "Gen"; // 天才型
	if (e == Nature(10)) return "Her"; // 英雄型
	if (e == Nature(11)) return "Div"; // 神仙型
	throw new Exception(e.text());
}
/// ditto
Nature toNature(string e) { mixin(S_TRACE);
	final switch (e) {
	case "Spi": return Nature(0);  // 標準型
	case "Agl": return Nature(1);  // 万能型
	case "Str": return Nature(2);  // 勇将型
	case "Vit": return Nature(3);  // 豪傑型
	case "Int": return Nature(4);  // 知将型
	case "Sch": return Nature(5);  // 策士型
	case "Med": return Nature(6);  // 凡庸型
	case "Bri": return Nature(7);  // 英明型
	case "Mat": return Nature(8);  // 無双型
	case "Gen": return Nature(9);  // 天才型
	case "Her": return Nature(10); // 英雄型
	case "Div": return Nature(11); // 神仙型
	}
}

/// クラシックな特徴を文字列に変換する。
string fromMakings(Makings e) { mixin(S_TRACE);
	if (e == Makings(0))  return "LooksB";   // 秀麗
	if (e == Makings(1))  return "LooksU";   // 醜悪
	if (e == Makings(2))  return "ClassH";   // 高貴の出
	if (e == Makings(3))  return "ClassL";   // 下賎の出
	if (e == Makings(4))  return "BredT";    // 都会育ち
	if (e == Makings(5))  return "BredC";    // 田舎育ち
	if (e == Makings(6))  return "MeansH";   // 裕福
	if (e == Makings(7))  return "MeansL";   // 貧乏
	if (e == Makings(8))  return "FaithF";   // 厚き信仰
	if (e == Makings(9))  return "FaithI";   // 不心得者
	if (e == Makings(10)) return "ReliR";   // 誠実
	if (e == Makings(11)) return "ReliU";   // 不実
	if (e == Makings(12)) return "DispC";   // 冷静沈着
	if (e == Makings(13)) return "DispS";   // 猪突猛進
	if (e == Makings(14)) return "DesireG"; // 貪欲
	if (e == Makings(15)) return "DesireC"; // 無欲
	if (e == Makings(16)) return "DevoteD"; // 献身的
	if (e == Makings(17)) return "DevoteS"; // 利己的
	if (e == Makings(18)) return "DiscO";   // 秩序派
	if (e == Makings(19)) return "DiscC";   // 混沌派
	if (e == Makings(20)) return "PolitR";  // 進取派
	if (e == Makings(21)) return "PolitC";  // 保守派
	if (e == Makings(22)) return "SenseR";  // 神経質
	if (e == Makings(23)) return "SenseS";  // 鈍感
	if (e == Makings(24)) return "CurioB";  // 好奇心旺盛
	if (e == Makings(25)) return "CurioI";  // 無頓着
	if (e == Makings(26)) return "NotionR"; // 過激
	if (e == Makings(27)) return "NotionM"; // 穏健
	if (e == Makings(28)) return "IdeaO";   // 楽観的
	if (e == Makings(29)) return "IdeaP";   // 悲観的
	if (e == Makings(30)) return "WorkH";   // 勤勉
	if (e == Makings(31)) return "WorkS";   // 遊び人
	if (e == Makings(32)) return "CharC";   // 陽気
	if (e == Makings(33)) return "CharB";   // 内気
	if (e == Makings(34)) return "StyleF";  // 派手
	if (e == Makings(35)) return "StyleP";  // 地味
	if (e == Makings(36)) return "PrideP";  // 高慢
	if (e == Makings(37)) return "PrideM";  // 謙虚
	if (e == Makings(38)) return "RefR";    // 上品
	if (e == Makings(39)) return "RefB";    // 粗野
	if (e == Makings(40)) return "GraceG";  // 武骨
	if (e == Makings(41)) return "GraceR";  // 繊細
	if (e == Makings(42)) return "LinerH";  // 硬派
	if (e == Makings(43)) return "LinerM";  // 軟派
	if (e == Makings(44)) return "PerS";    // お人好し
	if (e == Makings(45)) return "PerT";    // ひねくれ者
	if (e == Makings(46)) return "FameH";   // 名誉こそ命
	if (e == Makings(47)) return "FameA";   // 愛に生きる
	throw new Exception(e.text());
}
/// ditto
Makings toMakings(string e) { mixin(S_TRACE);
	final switch (e) {
	case "LooksB":  return Makings(0);  // 秀麗
	case "LooksU":  return Makings(1);  // 醜悪
	case "ClassH":  return Makings(2);  // 高貴の出
	case "ClassL":  return Makings(3);  // 下賎の出
	case "BredT":   return Makings(4);  // 都会育ち
	case "BredC":   return Makings(5);  // 田舎育ち
	case "MeansH":  return Makings(6);  // 裕福
	case "MeansL":  return Makings(7);  // 貧乏
	case "FaithF":  return Makings(8);  // 厚き信仰
	case "FaithI":  return Makings(9);  // 不心得者
	case "ReliR":   return Makings(10); // 誠実
	case "ReliU":   return Makings(11); // 不実
	case "DispC":   return Makings(12); // 冷静沈着
	case "DispS":   return Makings(13); // 猪突猛進
	case "DesireG": return Makings(14); // 貪欲
	case "DesireC": return Makings(15); // 無欲
	case "DevoteD": return Makings(16); // 献身的
	case "DevoteS": return Makings(17); // 利己的
	case "DiscO":   return Makings(18); // 秩序派
	case "DiscC":   return Makings(19); // 混沌派
	case "PolitR":  return Makings(20); // 進取派
	case "PolitC":  return Makings(21); // 保守派
	case "SenseR":  return Makings(22); // 神経質
	case "SenseS":  return Makings(23); // 鈍感
	case "CurioB":  return Makings(24); // 好奇心旺盛
	case "CurioI":  return Makings(25); // 無頓着
	case "NotionR": return Makings(26); // 過激
	case "NotionM": return Makings(27); // 穏健
	case "IdeaO":   return Makings(28); // 楽観的
	case "IdeaP":   return Makings(29); // 悲観的
	case "WorkH":   return Makings(30); // 勤勉
	case "WorkS":   return Makings(31); // 遊び人
	case "CharC":   return Makings(32); // 陽気
	case "CharB":   return Makings(33); // 内気
	case "StyleF":  return Makings(34); // 派手
	case "StyleP":  return Makings(35); // 地味
	case "PrideP":  return Makings(36); // 高慢
	case "PrideM":  return Makings(37); // 謙虚
	case "RefR":    return Makings(38); // 上品
	case "RefB":    return Makings(39); // 粗野
	case "GraceG":  return Makings(40); // 武骨
	case "GraceR":  return Makings(41); // 繊細
	case "LinerH":  return Makings(42); // 硬派
	case "LinerM":  return Makings(43); // 軟派
	case "PerS":    return Makings(44); // お人好し
	case "PerT":    return Makings(45); // ひねくれ者
	case "FameH":   return Makings(46); // 名誉こそ命
	case "FameA":   return Makings(47); // 愛に生きる
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
	string skinType = ""; /// スキンタイプ。skinEngineより優先される。
	string skinName = ""; /// スキン名。同タイプのスキンが複数ある場合に参照される。
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
		if (skinType.length) e.newAttr("skinType", skinType);
		if (skinName.length) e.newAttr("skinName", skinName);
		if (skinEngine.length) e.newAttr("skinEngine", skinEngine);
	}
	/// ditto
	void fromNode(ref XNode node) { mixin(S_TRACE);
		// 以前のバージョンでは要素名が"value"になっている
		// 可能性があるため、チェックしない

		skinType = node.attr!(string)("skinType", false, "");
		skinName = node.attr!(string)("skinName", false, "");
		skinEngine = node.attr!(string)("skinEngine", false, "");
		path = node.value;
	}
}

/// シナリオの実行に使うパーティの情報。
struct ExecutionParty {
	static const XML_NAME = "executionParty";
	string engineName; /// エンジン定義名。
	string enginePath; /// エンジンの絶対パス。
	bool isClassic; /// クラシックなエンジンか。
	string yadoName; /// 宿名。
	string yadoPath; /// 宿の相対パス。
	string partyName; /// パーティ名。
	string partyPath; /// パーティの相対パス。

	/// XMLノードとして取り扱うための関数群。
	const
	XNode toNode() { mixin(S_TRACE);
		auto e = XNode.create(XML_NAME);
		toNodeImpl(e);
		return e;
	}
	/// ditto
	const
	void toNode(ref XNode node, string name = XML_NAME) { mixin(S_TRACE);
		auto e = node.newElement(name);
		toNodeImpl(e);
	}
	/// ditto
	const
	private void toNodeImpl(ref XNode e) { mixin(S_TRACE);
		if (enginePath != "") { mixin(S_TRACE);
			e.newAttr("engineName", engineName);
			e.newAttr("enginePath", enginePath);
			e.newAttr("classic", isClassic);
			e.newAttr("yadoName", yadoName);
			e.newAttr("yadoPath", yadoPath);
			e.newAttr("partyName", partyName);
			e.newAttr("partyPath", partyPath);
		}
	}
	/// ditto
	void fromNode(ref XNode node) { mixin(S_TRACE);
		engineName = node.attr!(string)("engineName", false, "");
		enginePath = node.attr!(string)("enginePath", false, "");
		isClassic = node.attr!(bool)("classic", false, false);
		yadoName = node.attr!(string)("yadoName", false, "");
		yadoPath = node.attr!(string)("yadoPath", false, "");
		partyName = node.attr!(string)("partyName", false, "");
		partyPath = node.attr!(string)("partyPath", false, "");
	}
}

/// イベントコンテントの変換グループ。
/// UI上で同じグループ内のコンテントタイプが主な変換先として表示される。
struct ContentConversionGroup {
	static immutable XML_NAME = "contentConversionGroup";

	CType[] group; /// 変換グループ。

	/// XMLノードとして取り扱うための関数群。
	const
	XNode toNode() { mixin(S_TRACE);
		auto e = XNode.create(XML_NAME);
		toNodeImpl(e);
		return e;
	}
	/// ditto
	const
	void toNode(ref XNode node, string name = XML_NAME) { mixin(S_TRACE);
		auto e = node.newElement(name);
		toNodeImpl(e);
	}
	/// ditto
	const
	private void toNodeImpl(ref XNode e) { mixin(S_TRACE);
		import cwx.event;
		foreach (cType; group) { mixin(S_TRACE);
			auto d = contentDetail(cType);
			e.newElement(d.names[0], d.type);
		}
	}
	/// ditto
	void fromNode(ref XNode node) { mixin(S_TRACE);
		import cwx.event;
		group = [];
		node.onTag["type"] = (ref XNode node) { mixin(S_TRACE);
			group ~= cTypeFrom(node.value, node.attr("type", false, ""));
		};
		node.parse();
	}
}

/// ツールバーの設定。
struct ToolBarSettings {
	/// ツールバーの設定。二次元配列になっており、
	/// 移動可能なツールバー一つを一単位として
	/// それを複数含む構造を表現する。
	Tool[][] tools;

	/// インスタンスを生成する。
	static ToolBarSettings opCall(Tool[][] tools) {
		ToolBarSettings settings;
		settings.tools = tools;
		return settings;
	}

	/// コピーを生成する。
	@property
	const
	ToolBarSettings dup() {
		Tool[][] tools;
		foreach (bar; this.tools) {
			tools ~= bar.dup;
		}
		return ToolBarSettings(tools);
	}

	/// XMLノードとして取り扱うための関数群。
	const
	void toNode(ref XNode e, string name = "toolBarSettings") { mixin(S_TRACE);
		auto node = e.newElement(name);
		foreach (toolbar; tools) {
			auto bar = node.newElement("toolBar");
			foreach (tool; toolbar) {
				tool.toNode(bar);
			}
		}
	}
	/// ditto
	void fromNode(ref XNode node) { mixin(S_TRACE);
		tools = [];
		node.onTag["toolBar"] = (ref XNode node) {
			Tool[] toolbar;
			node.onTag[Tool.XML_NAME] = (ref XNode node) {
				Tool tool;
				tool.fromNode(node);
				toolbar ~= tool;
			};
			node.parse();
			tools ~= toolbar;
		};
		node.parse();
	}
}

/// ツールアイテムの設定。
struct Tool {
	static immutable XML_NAME = "toolItem";

	/// このツールアイテムが単なる区切りであればtrue。
	bool separator;
	/// このツールアイテムがどのようなメニューとして機能するか。
	MenuID menu;

	/// ツールとしてのインスタンスを生成する。
	static Tool opCall(MenuID id) {
		Tool tool;
		tool.separator = false;
		tool.menu = id;
		return tool;
	}
	/// 区切りとしてのインスタンスを生成する。
	static Tool opCall() {
		Tool tool;
		tool.separator = true;
		return tool;
	}

	/// XMLノードとして取り扱うための関数群。
	const
	XNode toNode() { mixin(S_TRACE);
		auto e = XNode.create(XML_NAME, separator ? "" : to!string(menu));
		toNodeImpl(e);
		return e;
	}
	/// ditto
	const
	void toNode(ref XNode node) { mixin(S_TRACE);
		auto e = node.newElement(XML_NAME, separator ? "" : to!string(menu));
		toNodeImpl(e);
	}
	/// ditto
	const
	private void toNodeImpl(ref XNode e) { mixin(S_TRACE);
		if (separator) e.newAttr("separator", true);
	}
	/// ditto
	void fromNode(ref XNode node) { mixin(S_TRACE);
		separator = node.attr!bool("separator", false, false);
		if (!separator) { mixin(S_TRACE);
			try {
				menu = node.valueTo!MenuID;
			} catch (ConvException) {
				separator = true;
			}
		}
	}
}
