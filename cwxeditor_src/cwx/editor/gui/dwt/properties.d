
module cwx.editor.gui.dwt.properties;

import cwx.utils;
import cwx.xml;
import cwx.skin;
import cwx.background;
import cwx.structs;

import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.dockingfolder;

import std.conv;
import std.string;
import std.file;
import std.path;
import std.utf;

import org.eclipse.swt.SWT;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Composite;

private:

struct PropValue(string PKey, T, T Default, bool ReadOnly) {
	private T _value = Default;
	const
	string key() {
		return PKey;
	}
	static const bool READ_ONLY = ReadOnly;

	static if (!ReadOnly) {
		void opAssign(T value) {
			_value = value;
		}
		void opCall(T value) {
			_value = value;
		}
	}
	static T init() {return Default;}
	const
	void toNode(ref XNode node) {
		static if (is (typeof(_value.toNode))) {
			_value.toNode(node);
		} else static if (isVArray!(T)) {
			auto e = node.newElement(key);
			foreach (v; _value) {
				static if (is (typeof(v.toNode))) {
					v.toNode(e);
				} else {
					e.newElement("value", to!(string)(v));
				}
			}
		} else {
			node.newElement(key, to!(string)(_value));
		}
	}
	T opCall() {
		return _value;
	}
	const
	const(T) opCall() {
		return _value;
	}
	void fromNode(ref XNode node) {
		static if (is (typeof(_value.fromNode))) {
			_value.fromNode(node);
		} else static if (isVArray!(T)) {
			_value = [];
			node.onTag[null] = (ref XNode v) {
				static if (is (typeof(_value[0].fromNode))) {
					typeof(_value[0]) val;
					val.fromNode(v);
					_value ~= val;
				} else {
					_value ~= to!(typeof(_value[0]))(v.value);
				}
			};
			node.parse;
		} else {
			_value = to!(T)(node.value);
		}
	}
}

bool isSorted(T)(T arr) {
	foreach (i, v; arr) {
		if (arr.length <= i + 1) break;
		if (v > arr[i + 1]) {
			return false;
		}
	}
	return true;
}

abstract class Properties {
	/// mixinによってプロパティの値と値を設定/取得する関数を生成する。
	/// 例えば:
	/// ---
	/// mixin Property!("width", int, 100);
	/// ---
	/// 以上によって、以下のフィールドと関数が生成される。
	/// ---
	/// private final PropValue!("width", int, 100) _width;
	/// int width() {
	/// 	return _width();
	/// }
	/// void width(int value) {
	/// 	_width = value;
	/// }
	/// ---
	/// Params:
	/// Name = プロパティ名。
	/// VType = プロパティの型。
	/// Default = プロパティのデフォルト値。
	protected template Property(string Name, VType, VType Default, bool ReadOnly = false) {
		mixin ("private PropValue!("
			~ "\"" ~ Name ~ "\", " ~ VType.stringof ~ ", " ~ Default.stringof ~ ", " ~ ReadOnly.stringof ~ ") "
			~ "_" ~ Name ~ ";");
		mixin ("const const(" ~ VType.stringof ~ ") " ~ Name ~ "() {return _" ~ Name ~ "();}");
		mixin ("const const(" ~ VType.stringof ~ ") " ~ Name ~ "_init() {return Default;}");
		static if (!ReadOnly) {
			mixin ("void " ~ Name ~ "(" ~ VType.stringof ~ " value) {_" ~ Name ~ " = value;}");
		}
	}
	/// mixinによってXML化する関数及びXMLからプロパティ群をロードする関数を生成する。
	/// Params:
	/// SubClass = Propertiesのサブクラス。
	/// Root = ルート要素の名前。
	protected template XMLFuncs(SubClass : Properties, string Root = "") {
		static if (Root.length > 0) {
			string toXML() {
				auto e = XNode.create(Root);
				foreach (fld; this.tupleof) {
					if (!fld.READ_ONLY || fld() != fld.init) {
						fld.toNode(e);
					}
				}
				return e.text;
			}
			static SubClass fromXML(string xml) {
				try {
					auto node = XNode.parse(xml);
					return fromNode(node);
				} catch (Exception) {
					SubClass r;
					return r;
				}
			}
		}
		void toNode(ref XNode node) {
			static if (Root == "") {
				auto e = node;
			} else {
				auto e = node.newElement(Root);
			}
			foreach (fld; this.tupleof) {
				if (!fld.READ_ONLY || fld() != fld.init) {
					fld.toNode(e);
				}
			}
		}
		static SubClass fromNode(ref XNode node) {
			auto r = new SubClass;
			static if (Root == "") {
				auto e = node;
			} else {
				auto e = node.child(Root, false);
			}
			if (e.valid) {
				foreach (i, fld; r.tupleof) {
					auto n = e.child(fld.key, false);
					if (n.valid) {
						try {
							// FIXME: fld.fromNode()だと上手く行かない？
							r.tupleof[i].fromNode(n);
						} catch {
						}
					}
				}
			}
			return r;
		}
	}
}

class WindowProps(string PropName, int Width, int Height)
		: Properties, DSize {
	mixin Property!("maximized", bool, false);
	mixin Property!("minimized", bool, false);
	mixin Property!("x", int, SWT.DEFAULT);
	mixin Property!("y", int, SWT.DEFAULT);
	mixin Property!("width", int, Width);
	mixin Property!("height", int, Height);
	mixin Property!("visible", bool, true);

	mixin XMLFuncs!(WindowProps, PropName);
}

class MainWin : Properties, DSize {
	mixin Property!("x", int, SWT.DEFAULT);
	mixin Property!("y", int, SWT.DEFAULT);
	mixin Property!("width", int, 1024);
	mixin Property!("height", int, 768);
	mixin Property!("maximized", bool, false);

	mixin XMLFuncs!(MainWin, "mainWindow");
}

class ContWin : Properties {
	mixin Property!("x", int, SWT.DEFAULT);
	mixin Property!("y", int, SWT.DEFAULT);

	mixin XMLFuncs!(ContWin, "contentsWindow");
}

class DialogParam(string Name, int WidthDef = SWT.DEFAULT, int HeightDef = SWT.DEFAULT)
		: Properties, DSize {
	mixin Property!("width", int, WidthDef);
	mixin Property!("height", int, HeightDef);

	mixin XMLFuncs!(DialogParam, Name);
}

class EventWin(string Name, int Width, int Height) : Properties, DSize {
	mixin Property!("x", int, SWT.DEFAULT);
	mixin Property!("y", int, SWT.DEFAULT);
	mixin Property!("maximized", bool, false);
	mixin Property!("width", int, Width);
	mixin Property!("height", int, Height);

	mixin Property!("eventSashL", int, 2);
	mixin Property!("eventSashR", int, 7);

	mixin XMLFuncs!(EventWin, Name);
}
alias EventWin!("areaWindow", SWT.DEFAULT, SWT.DEFAULT) AreaWin;
alias EventWin!("battleWindow", SWT.DEFAULT, SWT.DEFAULT) BattleWin;
alias EventWin!("packageWindow", 800, 520) PackageWin;
alias EventWin!("cardEventWindow", 800, 520) CardEventWin;

struct BgImageSetting {
	static const XML_NAME = "bgImageSetting";
	string name;
	int x;
	int y;
	int width;
	int height;
	bool mask;
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
	const
	XNode toNode() {
		auto e = XNode.create(XML_NAME);
		toNodeImpl(e);
		return e;
	}
	const
	void toNode(ref XNode node) {
		auto e = node.newElement(XML_NAME);
		toNodeImpl(e);
	}
	const
	private void toNodeImpl(ref XNode e) {
		e.newElement("name", name);
		e.newElement("x", x);
		e.newElement("y", y);
		e.newElement("width", width);
		e.newElement("height", height);
		e.newElement("mask", mask);
	}
	void fromNode(ref XNode node) {
		name = node.childText("name", true);
		x = to!(int)(node.childText("x", true));
		y = to!(int)(node.childText("y", true));
		width = to!(int)(node.childText("width", true));
		height = to!(int)(node.childText("height", true));
		mask = to!(bool)(node.childText("mask", true));
	}
}

struct OuterTool {
	static const XML_NAME = "tool";
	string name;
	string command;
	string workDir;
	const
	OuterTool dup() {
		OuterTool r;
		r.name = name;
		r.command = command;
		r.workDir = workDir;
		return r;
	}
	static OuterTool opCall(string name, string command, string workDir) {
		OuterTool r;
		r.name = name;
		r.command = command;
		r.workDir = workDir;
		return r;
	}
	const
	XNode toNode() {
		auto e = XNode.create(XML_NAME);
		toNodeImpl(e);
		return e;
	}
	const
	void toNode(ref XNode node) {
		auto e = node.newElement(XML_NAME);
		toNodeImpl(e);
	}
	const
	private void toNodeImpl(ref XNode e) {
		e.newElement("name", name);
		e.newElement("command", command);
		e.newElement("workDir", workDir);
	}
	void fromNode(ref XNode node) {
		name = node.childText("name", true);
		command = node.childText("command", true);
		workDir = node.childText("workDir", true);
	}
	static string parse(string str, string file, string sPath) {
		dstring buf;
		bool bs = false;
		foreach (dchar c; str) {
			if (bs) {
				if (c == 'f' || c == 'F') {
					buf ~= toUTF32(file);
				} else if (c == 's' || c == 'S') {
					buf ~= toUTF32(sPath);
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
		return toUTF8(buf);
	}
}

/// 背景画像のデフォルト設定を示すための構造体。
/// 拡張子はスキンによるため、nameには拡張子を含めない。
struct BgImageS {
	string name;
	int x;
	int y;
	uint width;
	uint height;
	bool mask;
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
	void fromNode(ref XNode node) {
		if (node.name != "background") throw new Exception("Node is not background");
		name = node.attr!(string)("name", true);
		x = node.attr!(int)("x", true);
		y = node.attr!(int)("y", true);
		width = node.attr!(uint)("width", true);
		height = node.attr!(uint)("height", true);
		mask = node.attr!(bool)("mask", true);
	}
	static BgImageS[] createBgImageSs(BgImage[] bgs) {
		BgImageS[] r;
		r.length = bgs.length;
		foreach (i, b; bgs) {
			r[i] = BgImageS(getName(b.path), b.x, b.y, b.width, b.height, b.mask);
		}
		return r;
	}
	static BgImage[] createBgImages(Skin skin, in BgImageS[] bgs) {
		BgImage[] r;
		r.length = bgs.length;
		foreach (i, b; bgs) {
			auto path = skin.findImagePath(addExt(b.name, skin.extImage), "");
			if (path.length) {
				path = abs2rel(skin.tableDir, nabs(path));
			} else {
				path = addExt(b.name, skin.extImage);
			}
			r[i] = new BgImage(path, "", b.x, b.y, b.width, b.height, b.mask);
		}
		return r;
	}
}

/// クラシックなエンジンの情報。
struct ClassicEngine {
	static const XML_NAME = "classicEngine";
	string name;
	string enginePath = "";
	string dataDirName = "";
	string execute = "";
	const
	XNode toNode() {
		auto e = XNode.create(XML_NAME);
		toNodeImpl(e);
		return e;
	}
	const
	void toNode(ref XNode node) {
		auto e = node.newElement(XML_NAME);
		toNodeImpl(e);
	}
	const
	private void toNodeImpl(ref XNode e) {
		e.newAttr("name", name);
		e.newAttr("enginePath", enginePath);
		e.newAttr("dataDirName", dataDirName);
		e.newAttr("execute", execute);
	}
	void fromNode(ref XNode node) {
		if (node.name != "classicEngine") throw new Exception("Node is not classicEngine");
		name = node.attr!(string)("name", true);
		enginePath = node.attr!(string)("enginePath", true);
		dataDirName = node.attr!(string)("dataDirName", true);
		execute = node.attr!(string)("execute", true);
	}
}

class FlexEtcProps : Properties {
	mixin Property!("singleWindow", bool, true);
	mixin Property!("toolsLock", bool, false);
	mixin Property!("toolsOrder", int[], []);
	mixin Property!("toolsWrapIndices", int[], [8]);
	mixin Property!("directorySashL", int, 2);
	mixin Property!("directorySashR", int, 5);
	mixin Property!("directorySashV", bool, false);
	mixin Property!("filesSortColumn", int, 1);
	mixin Property!("filesSortDirection", int, SWT.UP);
	mixin Property!("fileNameColumn", int, 300);
	mixin Property!("fileExtColumn", int, 60);
	mixin Property!("fileCountColumn", int, 60);
	mixin Property!("areaIdColumn", int, 50);
	mixin Property!("areaNameColumn", int, 400);
	mixin Property!("areaCountColumn", int, 60);
	mixin Property!("summaryParamSashL", int, 2);
	mixin Property!("summaryParamSashR", int, 1);
	mixin Property!("rCouponsStartAreaSashL", int, 1);
	mixin Property!("rCouponsStartAreaSashR", int, 1);
	mixin Property!("areaViewL", int, 1);
	mixin Property!("areaViewR", int, 4);
	mixin Property!("partyCardAlpha", int, 176, true);
	mixin Property!("viewPartyCardsArea", bool, true);
	mixin Property!("viewPartyCardsBattle", bool, true);
	mixin Property!("viewEnemyCardDebug", bool, false);
	mixin Property!("viewPartyCardsEvent", bool, true);
	mixin Property!("messageAlpha", int, 176, true);
	mixin Property!("viewMessageArea", bool, false);
	mixin Property!("viewMessageBattle", bool, false);
	mixin Property!("viewMessageEvent", bool, false);
	mixin Property!("fixedImagesArea", bool, false);
	mixin Property!("fixedImagesBattle", bool, false);
	mixin Property!("fixedImagesEvent", bool, false);
	mixin Property!("viewCards", bool, true);
	mixin Property!("viewBgImages", bool, true);
	mixin Property!("areaSashT", int, 5);
	mixin Property!("areaSashB", int, 4);
	mixin Property!("flagSashL", int, 3);
	mixin Property!("flagSashR", int, 7);
	mixin Property!("flagSashV", bool, false);
	mixin Property!("flagsWidth", int, 150, true);
	mixin Property!("flagsHeight", int, 200, true);
	mixin Property!("menuCardSashL", int, 5);
	mixin Property!("menuCardSashR", int, 3);
	mixin Property!("enemyCardSashL", int, 3);
	mixin Property!("enemyCardSashR", int, 5);
	mixin Property!("backSashL", int, 5);
	mixin Property!("backSashR", int, 3);
	mixin Property!("bgImageSampleWidth", int, 150, true);
	mixin Property!("bgImageSampleHeight", int, 150, true);
	mixin Property!("cardIdColumn", int, 50);
	mixin Property!("cardNameColumn", int, 100);
	mixin Property!("cardDescriptionColumn", int, 280);
	mixin Property!("cardCountColumn", int, 60);
	mixin Property!("couponWidth", int, 150, true);
	mixin Property!("couponValueColumn", int, 40, true);
	mixin Property!("physicalRadarWidth", int, 230, true);
	mixin Property!("physicalRadarHeight", int, 160, true);
	mixin Property!("enhanceRadarWidth", int, 230, true);
	mixin Property!("enhanceRadarHeight", int, 175, true);
	mixin Property!("idColumn", int, 50);
	mixin Property!("nameTableWidth", int, 250, true);
	mixin Property!("nameTableHeight", int, 250, true);
	mixin Property!("flagEventSashL", int, 3);
	mixin Property!("flagEventSashR", int, 2);
	mixin Property!("nameWidth", int, 200, true);
	mixin Property!("firesWidth", int, 120, true);
	mixin Property!("flagNameWidth", int, 150, true);
	mixin Property!("flagInitWidth", int, 50, true);
	mixin Property!("flagValueWidth", int, 50, true);
	mixin Property!("flagNameColumn", int, 190);
	mixin Property!("flagInitColumn", int, 90);
	mixin Property!("flagCountColumn", int, 60);
	mixin Property!("filesWidth", int, 150, true);
	mixin Property!("filesHeight", int, 150, true);
	mixin Property!("talkersWidth", int, 100, true);
	mixin Property!("motionsWidth", int, 150, true);
	mixin Property!("imageListWidth", int, 380);
	mixin Property!("imageListHeight", int, 300);
	mixin Property!("cardLife", bool, false);
	mixin Property!("cardDetails", bool, false);
	mixin Property!("cardsMarginX", int, 5, true);
	mixin Property!("cardsSpaceX", int, 8, true);
	mixin Property!("cardsMarginY", int, 5, true);
	mixin Property!("cardsSpaceY", int, 8, true);
	mixin Property!("cardsDefaultWrap", int, 4, true);
	mixin Property!("contentsOrder", int[], []);
	mixin Property!("contentsLock", bool, false);
	mixin Property!("contentsWrapIndices", int[], [4, 6, 8]);
	mixin Property!("contentsAutoOpen", bool, true);
	mixin Property!("contentsContinue", bool, false);
	mixin Property!("contentsFloat", bool, false);
	mixin Property!("smoothingCard", bool, true);
	mixin Property!("ignorePathsWidth", int, 50, false);
	mixin Property!("bgImageSettingsNameWidth", int, 150, true);
	mixin Property!("bgImageSettingsNameHeight", int, 250, true);
	mixin Property!("outerToolsNameWidth", int, 150, true);
	mixin Property!("outerToolsNameHeight", int, 150, true);
	mixin Property!("classicEnginesNameWidth", int, 150, true);
	mixin Property!("classicEnginesNameHeight", int, 250, true);

	mixin Property!("wallpaper", string, "");
	mixin Property!("wallColorR", int, 0);
	mixin Property!("wallColorG", int, 0);
	mixin Property!("wallColorB", int, 128);
	mixin Property!("bgImagesDefault", BgImageS[], [BgImageS("MapOfWirth", 0, 0, 632, 420, false)]);
	mixin Property!("bgImageSettingsSashL", int, 1);
	mixin Property!("bgImageSettingsSashR", int, 1);
	mixin Property!("bgImageKeyCodeSashL", int, 2);
	mixin Property!("bgImageKeyCodeSashR", int, 1);
	mixin Property!("outerToolsSashL", int, 1);
	mixin Property!("outerToolsSashR", int, 2);
	mixin Property!("classicEnginesSashL", int, 1);
	mixin Property!("classicEnginesSashR", int, 2);
	mixin Property!("outerToolsAndClassicEnginesSashL", int, 1);
	mixin Property!("outerToolsAndClassicEnginesSashR", int, 1);
	mixin Property!("keyCodeWidth", int, 100, true);
	mixin Property!("scenarioPath", string, "");
	mixin Property!("tempPath", string, "temp");
	mixin Property!("backupPath", string, "backup");
	mixin Property!("backupEnabled", bool, true);
	mixin Property!("backupInterval", int, 15);
	mixin Property!("backupCount", int, 10);

	mixin Property!("openHistories", string[], []);
	mixin Property!("historyMax", int, 9);
	mixin Property!("historySnipLength", int, 30);
	mixin Property!("searchResultTableWidth", int, 400, true);
	mixin Property!("searchResultTableHeight", int, 200, true);
	version (Windows) {
		mixin Property!("engine", string, "CardWirthPy.exe", true);
		mixin Property!("enginePath", string, "CardWirthPy.exe");
	} else {
		mixin Property!("engine", string, "CardWirthPy", true);
		mixin Property!("enginePath", string, "CardWirthPy");
	}
	mixin Property!("defaultSkin", string, "MedievalFantasy", true);
	mixin Property!("defaultAuthor", string, "");
	mixin Property!("canCreateClassic", bool, false);

	mixin Property!("expandXMLs", bool, false);
	mixin Property!("xmlCopy", bool, false);
	mixin Property!("saveInnerImagePath", bool, false);
	mixin Property!("traceDirectories", bool, true);
	mixin Property!("logicalSort", bool, true);
	mixin Property!("copyDesc", bool, false);
	mixin Property!("refCardsAtEditBgImage", bool, true);
	mixin Property!("soundPlayType", int, 0);

	mixin Property!("searchHistories", string[], []);
	mixin Property!("replaceHistories", string[], []);
	mixin Property!("searchHistoryMax", int, 50);
	mixin Property!("replaceTextNotIgnoreCase", bool, false);
	mixin Property!("replaceTextRegExp", bool, false);
	mixin Property!("replaceTextWildcard", bool, false);
	mixin Property!("replaceTextSummary", bool, true);
	mixin Property!("replaceTextMessage", bool, true);
	mixin Property!("replaceTextCardName", bool, true);
	mixin Property!("replaceTextCardDescription", bool, true);
	mixin Property!("replaceTextEventText", bool, true);
	mixin Property!("replaceTextStart", bool, true);
	mixin Property!("replaceTextFlagAndStep", bool, true);
	mixin Property!("replaceTextCoupon", bool, true);
	mixin Property!("replaceTextGossip", bool, true);
	mixin Property!("replaceTextEndScenario", bool, true);
	mixin Property!("replaceTextAreaName", bool, true);
	mixin Property!("replaceTextKeyCode", bool, true);
	mixin Property!("searchUnusedFlag", bool, true);
	mixin Property!("searchUnusedStep", bool, true);
	mixin Property!("searchUnusedArea", bool, true);
	mixin Property!("searchUnusedBattle", bool, true);
	mixin Property!("searchUnusedPackage", bool, true);
	mixin Property!("searchUnusedCast", bool, true);
	mixin Property!("searchUnusedSkill", bool, true);
	mixin Property!("searchUnusedItem", bool, true);
	mixin Property!("searchUnusedBeast", bool, true);
	mixin Property!("searchUnusedInfo", bool, true);
	mixin Property!("searchUnusedStart", bool, true);
	mixin Property!("searchUnusedPath", bool, true);

	mixin Property!("flagTrues", string[], ["TRUE", "表示", "ON", "有", "可", "済み"], true);
	mixin Property!("flagFalses", string[], ["FALSE", "非表示", "OFF", "無", "不可", "まだ"], true);

	mixin Property!("bgImageSettings", BgImageSetting[], [
		BgImageSetting("冒険者の宿", 116, 15, 400, 260, false),
		BgImageSetting("冒険者の宿(フレーム)", 116, 14, 400, 261, true),
		BgImageSetting("フル", 0, 0, 632, 420, false),
		BgImageSetting("フル(マスク)", 0, 0, 632, 420, true),
		BgImageSetting("カード", 0, 0, 74, 94, true),
		BgImageSetting("冒険者カード", 0, 0, 95, 130, false),
		BgImageSetting("ゲームオーバー", 116, 55, 400, 260, false),
		BgImageSetting("Qubes 地面", 160, 80, 320, 160, true),
		BgImageSetting("Qubes 左後", 80, 0, 240, 160, true),
		BgImageSetting("Qubes 右後", 320, 0, 240, 160, true),
		BgImageSetting("Qubes 左前", 80, 80, 240, 200, true),
		BgImageSetting("Qubes 右前", 320, 80, 240, 200, true)
	]);
	mixin Property!("standardCoupons", string[], [
		"：Ｒ", "＿１", "＿２", "＿３", "＿４", "＿５", "＿６"
	], true);
	mixin Property!("standardKeyCodes", string[], [
		"攻撃",
		"治療",
		"魔法",
		"召喚獣",
		"気功法",
		"遠距離攻撃",
		"神聖な攻撃",
		"魔法による攻撃",
		"炎による攻撃",
		"冷気による攻撃",
		"暗殺",
		"精神を回復",
		"中毒を解除",
		"麻痺を解除",
		"眠り",
		"麻痺",
		"中毒",
		"呪縛",
		"沈黙",
		"召喚",
		"鑑定",
		"解錠",
		"呪縛を解除",
		"沈黙を解除",
		"魔法を解除",
		"",
		"魔力感知",
		"生命感知",
		"魔法の鍵",
		"解読",
		"石化",
		"石化を解除",
		"蝙蝠変化",
		"明かり",
		"目つぶし",
		"魅了",
		"透明",
		"召喚獣を付与",
		"暴露",
		"即死",
		"一撃必殺",
		"対象消去",
		"恐慌",
		"不浄な攻撃",
		"呪い",
		"飛行",
		"浮遊",
		"灯火",
		"",
		"フェイント",
		"防御",
		"逃走",
		"カード交換",
		"ペナルティ",
		"リサイクル"
	]);
	version (Windows) {
		mixin Property!("outerTools", OuterTool[], [
			OuterTool("メモ帳", "notepad $F", ""),
			OuterTool("ペイント", "mspaint $F", "")
		]);
	} else {
		mixin Property!("outerTools", OuterTool[], []);
	}
	mixin Property!("ignorePaths", string[], [".*"]);

	mixin Property!("selectedArchiveFilter", string, "zip");

	mixin Property!("classicEngines", ClassicEngine[], []);
	mixin Property!("addNewClassicEngine", bool, true);

	mixin Property!("drawCountOfUseOfStart", bool, true);
	mixin Property!("drawContentTreeLine", bool, true);

	mixin XMLFuncs!(FlexEtcProps);
}

public class FlexProps {
	MainWin mainWin;
	WindowProps!("dataWindow", SWT.DEFAULT, 400) dataWin;
	WindowProps!("cardWindow", SWT.DEFAULT, 400) cardWin;
	WindowProps!("directoryWindow", SWT.DEFAULT, 400) dirWin;
	AreaWin areaWin;
	BattleWin battleWin;
	PackageWin packageWin;
	CardEventWin cardEventWin;
	ContWin contentsWin;
	DialogParam!("settingsDialog") settingsDlg;
	DialogParam!("replaceDialog", 600) replaceDlg;
	DialogParam!("summaryDialog") summaryDlg;
	DialogParam!("menuCardDialog") menuCardDlg;
	DialogParam!("areaBackgroundDialog") areaBackgroundDlg;
	DialogParam!("areaBackgroundNFDialog") areaBackgroundNFDlg;
	DialogParam!("enemyCardDialog") enemyCardDlg;
	DialogParam!("castCardDialog") castCardDlg;
	DialogParam!("skillCardDialog") skillCardDlg;
	DialogParam!("itemCardDialog") itemCardDlg;
	DialogParam!("beastCardDialog") beastCardDlg;
	DialogParam!("infoCardDialog") infoCardDlg;
	DialogParam!("bgImagesDialog", 850) bgImagesDlg;
	DialogParam!("flagDialog") flagDlg;
	DialogParam!("stepDialog") stepDlg;
	DialogParam!("newScenarioDialog") newScDlg;
	DialogParam!("speakDialog") speakDlg;
	DialogParam!("messageDialog") msgDlg;
	DialogParam!("cardEventDialog") cardEvtDlg;
	DialogParam!("flagEventDialog", 350) flagEvtDlg;
	DialogParam!("effectEventDialog") effEvtDlg;
	DialogParam!("soundEventDialog") soundEvtDlg;
	DialogParam!("couponEventDialog") couponEvtDlg;
	DialogParam!("inputEventDialog") inputEvtDlg;
	DialogParam!("selectEventDialog") selEvtDlg;
	DialogParam!("scriptDialog", 400, 300) scriptDlg;
	FlexEtcProps etc;

	private enum IniLocation {
		STANDARD, LOCAL, COPY
	}

	private string _path;
	this(string appPath, string confFileName) {
		IniLocation loc = IniLocation.STANDARD;
		string iniFileName = "cwxeditor.xml";
		if (.exists(std.path.join(appPath.getDirName, iniFileName))) {
			// 1.0との互換性を維持するため、アプリケーションのディレクトリに
			// cwxeditor.xmlがあった場合、LOCALをデフォルトにする。
			loc = IniLocation.LOCAL;
		}
		try {
			if (.exists(confFileName)) {
				auto node = XNode.parse(cast(string) std.file.read(confFileName));
				node.onTag["location"] = (ref XNode node) {
					if (0 == icmp(node.value, "standard")) {
						loc = IniLocation.STANDARD;
					} else if (0 == icmp(node.value, "local")) {
						loc = IniLocation.LOCAL;
					} else if (0 == icmp(node.value, "copy")) {
						loc = IniLocation.COPY;
					}
				};
				node.onTag["file"] = (ref XNode node) {
					iniFileName = node.value;
				};
				node.parse;
			}
		} catch (Exception e) {
			debugln(e);
		}

		string dir;
		final switch (loc) {
		case IniLocation.STANDARD:
			dir = appDataDir(appPath);
			dir = std.path.join(dir, "cwxeditor");
			break;
		case IniLocation.LOCAL:
			dir = appPath.getDirName;
			break;
		case IniLocation.COPY:
			string base = std.path.join(appPath.getDirName, iniFileName);
			dir = appDataDir(appPath);
			dir = std.path.join(dir, "cwxeditor");
			string dest = std.path.join(dir, iniFileName);
			if (.exists(base) && !.exists(dest)) {
				try {
					if (!.exists(dir)) mkdirRecurse(dir);
					std.file.copy(base, dest);
				} catch (Exception e) {
					debugln(e);
				}
			}
			break;
		}

		_path = std.path.join(dir, iniFileName);
		if (exists(_path)) {
			try {
				auto node = XNode.parse(cast(string) read(_path));
				if (node.name == "cwxeditor" || node.name == "CWXEditor") {
					foreach (i, fld; this.tupleof) {
						this.tupleof[i] = fromNode(node, fld);
					}
					return;
				}
			} catch {
			}
			foreach (i, fld; this.tupleof) {
				this.tupleof[i] = newField(fld);
			}
		} else {
			foreach (i, fld; this.tupleof) {
				this.tupleof[i] = newField(fld);
			}

			// この二つの設定だけは環境によって初期値が変わる
			final switch (loc) {
			case IniLocation.STANDARD, IniLocation.COPY:
				dir = appDataDir(appPath);
				dir = std.path.join(dir, "cwxeditor");
				etc.tempPath = std.path.join(dir, "temp");
				etc.backupPath = std.path.join(dir, "backup");
				break;
			case IniLocation.LOCAL:
				etc.tempPath = "temp";
				etc.backupPath = "backup";
				break;
			}
		}
	}
	T fromNode(T)(ref XNode node, T t) {
		static if (is(typeof(T.fromNode(node)))) {
			if (!t) {
				return T.fromNode(node);
			}
		}
		return t;
	}
	T newField(T)(T t) {
		static if (is(typeof(new T))) {
			if (!t) {
				return new T;
			}
		}
		return t;
	}
	DockingFolderCTC loadDock(Composite parent, int style, Control delegate(Composite, string) create) {
		DockingFolderCTC r = null;
		if (exists(_path)) {
			int retryCount = 0;
			while (!r) {
				try {
					auto text = cast(string) read(_path);
					auto node = XNode.parse(text);
					void df(ref XNode node) {
						r = DockingFolderCTC.fromNode(node, parent, style, create);
					}
					node.onTag["dockingFolder"] = &df;
					node.parse;
					return r;
				} catch (Exception e) {
					// FIXME: DockingFolder.fromNode()内でたまにアクセス違反が発生する
					debug debugln(e);
					if (r && r.area) r.area.dispose;
					retryCount++;
					if (retryCount > 100) {
						debugln(e);
						return null;
					}
				}
			}
		}
		return r;
	}
	void save(DockingFolderCTC dock) {
		save(_path, dock);
	}
	void save(string xmlFileName, DockingFolderCTC dock) {
		auto node = XNode.create("cwxeditor");
		foreach (i, fld; this.tupleof) {
			toNode(node, fld);
		}
		if (dock) {
			dock.toNode(node, ["work"]);
		}
		auto dir = xmlFileName.getDirName;
		if (!.exists(dir)) mkdirRecurse(dir);
		write(xmlFileName, node.text);
	}
	void toNode(T)(ref XNode node, T t) {
		static if (is(typeof(t.toNode(node)))) {
			t.toNode(node);
		}
	}
}
