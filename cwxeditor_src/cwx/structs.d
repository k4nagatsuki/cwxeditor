
module cwx.structs;

import cwx.xml;
import cwx.utils;

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
	string putlangfile = "";
	bool help = false;

	void parseStrings(string[] args) {
		size_t sc = 0u;
		for (int i = 0; i < args.length; i++) {
			try {
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
				case "-putlangfile": // 起動と同時に言語ファイルを出力して終了
					if (i + 1 < args.length) putlangfile = args[i + 1];
					sc = i + 1u;
					break;
				case "-help", "-h", "/?": // usage
					help = true;
					break;
				default:
					if (i > sc) {
						openPaths ~= args[i];
					}
					break;
				}
			} catch (Exception e) {
				debugln(e);
			}
		}
		if (sc < args.length) {
			scenario = args[sc];
		}
		if (create || createclassic) {
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
	void toNode(ref XNode e) {
		auto r = e.newElement("point");
		r.newAttr("x", x);
		r.newAttr("y", y);
	}
	void fromNode(ref XNode node) {
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
	void toNode(ref XNode e) {
		auto r = e.newElement("size");
		r.newAttr("width", width);
		r.newAttr("height", height);
	}
	void fromNode(ref XNode node) {
		if (node.name != "size") throw new Exception("Node is not size");
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
	void toNode(ref XNode e) {
		auto r = e.newElement("rect");
		r.newAttr("x", x);
		r.newAttr("y", y);
		r.newAttr("width", width);
		r.newAttr("height", height);
	}
	void fromNode(ref XNode node) {
		if (node.name != "rect") throw new Exception("Node is not rect");
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
	void toNode(ref XNode e) {
		auto r = e.newElement("insets");
		r.newAttr("n", n);
		r.newAttr("e", this.e);
		r.newAttr("s", s);
		r.newAttr("w", w);
	}
	void fromNode(ref XNode node) {
		if (node.name != "insets") throw new Exception("Node is not insets");
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
	void toNode(ref XNode e) {
		auto r = e.newElement("rgb");
		r.newAttr("r", this.r);
		r.newAttr("g", g);
		r.newAttr("b", b);
		r.newAttr("a", a);
	}
	void fromNode(ref XNode node) {
		if (node.name != "rgb") throw new Exception("Node is not rgb");
		r = node.attr!(uint)("r", true);
		g = node.attr!(uint)("g", true);
		b = node.attr!(uint)("b", true);
		a = node.attr!(uint)("a", true);
	}
}

/// フォント情報。
struct CFont {
	string name;
	uint point;
	bool bold;
	bool italic;
	const
	void toNode(ref XNode e) {
		auto r = e.newElement("font");
		r.newAttr("name", name);
		r.newAttr("point", point);
		r.newAttr("bold", bold);
		r.newAttr("italic", italic);
	}
	void fromNode(ref XNode node) {
		if (node.name != "font") throw new Exception("Node is not font");
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
	BgImageSetting dup() {
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
	XNode toNode() {
		auto e = XNode.create(XML_NAME);
		toNodeImpl(e);
		return e;
	}
	/// ditto
	const
	void toNode(ref XNode node) {
		auto e = node.newElement(XML_NAME);
		toNodeImpl(e);
	}
	/// ditto
	const
	private void toNodeImpl(ref XNode e) {
		e.newElement("name", name);
		e.newElement("x", x);
		e.newElement("y", y);
		e.newElement("width", width);
		e.newElement("height", height);
		e.newElement("mask", mask);
	}
	/// ditto
	void fromNode(ref XNode node) {
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
	OuterTool dup() {
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
	XNode toNode() {
		auto e = XNode.create(XML_NAME);
		toNodeImpl(e);
		return e;
	}
	/// ditto
	const
	void toNode(ref XNode node) {
		auto e = node.newElement(XML_NAME);
		toNodeImpl(e);
	}
	/// ditto
	const
	private void toNodeImpl(ref XNode e) {
		e.newElement("name", name);
		e.newElement("command", command);
		e.newElement("workDir", workDir);
		if (mnemonic.length) e.newAttr("mnemonic", mnemonic);
		if (hotkey.length) e.newAttr("hotkey", hotkey);
	}
	/// ditto
	void fromNode(ref XNode node) {
		name = node.childText("name", true);
		command = node.childText("command", true);
		workDir = node.childText("workDir", true);
		mnemonic = node.attr!string("mnemonic", false, "");
		hotkey = node.attr!string("hotkey", false, "");
	}
	/// コマンドをパースする。$Fをファイル名に置換、$Sをシナリオ名に置換する。
	static string parse(string str, string file, string sPath) {
		dstring buf;
		bool bs = false;
		foreach (dchar c; str) {
			if (bs) {
				if (c == 'f' || c == 'F') {
					buf ~= to!dstring(file);
				} else if (c == 's' || c == 'S') {
					buf ~= to!dstring(sPath);
				} else if (c == '$') {
					buf ~= "$"d;
				} else {
					buf ~= "$"d ~ c;
				}
				bs = false;
			} else {
				if (c == '$') {
					bs = true;
				} else {
					buf ~= c;
				}
			}
		}
		if (bs) {
			buf ~= "$";
		}
		return to!string(buf);
	}
}

/// デフォルト設定用の背景画像構造体。
struct BgImageS {
	string name; /// ファイル名。拡張子はスキンによるため、拡張子を含めない。
	int x; /// X座標。
	int y; /// Y座標。
	uint width; /// 幅。
	uint height; /// 高さ。
	bool mask; /// マスク。
	/// XMLノードとして取り扱うための関数群。
	const
	void toNode(ref XNode e) {
		auto r = e.newElement("background");
		r.newAttr("name", name);
		r.newAttr("x", x);
		r.newAttr("y", y);
		r.newAttr("width", width);
		r.newAttr("height", height);
		r.newAttr("mask", mask);
	}
	/// ditto
	void fromNode(ref XNode node) {
		if (node.name != "background") throw new Exception("Node is not background");
		name = node.attr!(string)("name", true);
		x = node.attr!(int)("x", true);
		y = node.attr!(int)("y", true);
		width = node.attr!(uint)("width", true);
		height = node.attr!(uint)("height", true);
		mask = node.attr!(bool)("mask", true);
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

	/// コピーを生成する。
	@property
	const
	ClassicEngine dup() {
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
		return ce;
	}

	/// エンジンを実行する。
	const
	string executePath(string appPath, bool engine) {
		if (!enginePath.length) return "";
		string path = enginePath;
		if (!cwx.utils.isabs(path)) {
			auto dir = appPath.dirName();
			path = std.path.buildPath(dir, path);
		}
		if (!engine && execute.length) {
			if (cwx.utils.isabs(execute)) {
				path = execute;
			} else {
				path = std.path.buildPath(path.dirName(), execute);
			}
		}
		return path;
	}
	/// XMLノードとして取り扱うための関数群。
	const
	XNode toNode() {
		auto e = XNode.create(XML_NAME);
		toNodeImpl(e);
		return e;
	}
	/// ditto
	const
	void toNode(ref XNode node) {
		auto e = node.newElement(XML_NAME);
		toNodeImpl(e);
	}
	/// ditto
	const
	private void toNodeImpl(ref XNode e) {
		e.newAttr("name", name);
		e.newAttr("enginePath", enginePath);
		e.newAttr("dataDirName", dataDirName);
		e.newAttr("execute", execute);
		if (mnemonic.length) e.newAttr("mnemonic", mnemonic);
		if (hotkey.length) e.newAttr("hotkey", hotkey);
		if (okText !is null) e.newAttr("okText", okText);
		if (sexName.length) {
			auto ee = e.newElement("sexName");
			foreach (key, value; sexName) {
				auto ne = ee.newElement("name", value);
				ne.newAttr("key", key);
			}
		}
		if (periodName.length) {
			auto ee = e.newElement("periodName");
			foreach (key, value; periodName) {
				auto ne = ee.newElement("name", value);
				ne.newAttr("key", key);
			}
		}
		if (natureName.length) {
			auto ee = e.newElement("natureName");
			foreach (key, value; natureName) {
				auto ne = ee.newElement("name", value);
				ne.newAttr("key", key);
			}
		}
		if (makingsName.length) {
			auto ee = e.newElement("makingsName");
			foreach (key, value; makingsName) {
				auto ne = ee.newElement("name", value);
				ne.newAttr("key", key);
			}
		}
	}

	/// エンジンの実行ファイル名から拡張子を取り戻した文字列を返す。
	@property
	const
	string legacyName() {
		return enginePath.baseName().stripExtension();
	}

	/// 特徴名をクリアする。
	void clearFeatures() {
		okText = null;
		typeof(sexName) sexName;
		this.sexName = sexName;
		typeof(periodName) periodName;
		this.periodName = periodName;
		typeof(natureName) natureName;
		this.natureName = natureName;
		typeof(makingsName) makingsName;
		this.makingsName = makingsName;
	}

	/// ditto
	void fromNode(ref XNode node) {
		if (node.name != "classicEngine") throw new Exception("Node is not classicEngine");
		clearFeatures();

		name = node.attr!(string)("name", true);
		enginePath = node.attr!(string)("enginePath", true);
		dataDirName = node.attr!(string)("dataDirName", true);
		execute = node.attr!(string)("execute", true);
		mnemonic = node.attr!string("mnemonic", false, "");
		hotkey = node.attr!string("hotkey", false, "");
		okText = node.attr!string("okText", false, null);
		node.onTag["sexName"] = (ref XNode node) {
			node.onTag["name"] = (ref XNode node) {
				string key = node.attr!string("key", false, null);
				if (key !is null) sexName[key] = node.value;
			};
			node.parse();
		};
		node.onTag["periodName"] = (ref XNode node) {
			node.onTag["name"] = (ref XNode node) {
				string key = node.attr!string("key", false, null);
				if (key !is null) periodName[key] = node.value;
			};
			node.parse();
		};
		node.onTag["natureName"] = (ref XNode node) {
			node.onTag["name"] = (ref XNode node) {
				string key = node.attr!string("key", false, null);
				if (key !is null) natureName[key] = node.value;
			};
			node.parse();
		};
		node.onTag["makingsName"] = (ref XNode node) {
			node.onTag["name"] = (ref XNode node) {
				string key = node.attr!string("key", false, null);
				if (key !is null) makingsName[key] = node.value;
			};
			node.parse();
		};
		node.parse();
	}
}

/// シナリオのテンプレートの情報。
struct ScTemplate {
	static const XML_NAME = "scenarioTemplate";
	string name; /// 情報名。
	string path = ""; /// ファイル・ディレクトリのパス。
	/// XMLノードとして取り扱うための関数群。
	const
	XNode toNode() {
		auto e = XNode.create(XML_NAME);
		toNodeImpl(e);
		return e;
	}
	/// ditto
	const
	void toNode(ref XNode node) {
		auto e = node.newElement(XML_NAME);
		toNodeImpl(e);
	}
	/// ditto
	const
	private void toNodeImpl(ref XNode e) {
		e.newAttr("name", name);
		e.newAttr("path", path);
	}
	/// ditto
	void fromNode(ref XNode node) {
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

	/// XMLノードとして取り扱うための関数群。
	const
	XNode toNode() {
		auto e = XNode.create(XML_NAME, script);
		toNodeImpl(e);
		return e;
	}
	/// ditto
	const
	void toNode(ref XNode node) {
		auto e = node.newElement(XML_NAME, script);
		toNodeImpl(e);
	}
	/// ditto
	const
	private void toNodeImpl(ref XNode e) {
		e.newAttr("name", name);
	}
	/// ditto
	void fromNode(ref XNode node) {
		if (node.name != XML_NAME) throw new Exception("Node is not eventTemplate");
		name = node.attr!(string)("name", true);
		script = node.value;
	}
}
