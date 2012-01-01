
module cwx.editor.gui.dwt.properties;

import cwx.utils;
import cwx.xml;
import cwx.skin;
import cwx.background;
import cwx.structs;

import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.dockingfolder;
import cwx.editor.gui.dwt.variables;

import std.conv;
import std.string;
import std.file;
import std.path;
import std.utf;
import std.datetime;

import org.eclipse.swt.SWT;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Composite;

private:

struct PropValue(string PKey, T, T Default, bool ReadOnly) {
	private T _value = Default;
	@property
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
	@property
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
			node.parse();
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
		mixin ("@property const const(" ~ VType.stringof ~ ") " ~ Name ~ "() {return _" ~ Name ~ "();}");
		mixin ("@property const const(" ~ VType.stringof ~ ") " ~ Name ~ "_init() {return Default;}");
		static if (!ReadOnly) {
			mixin ("@property void " ~ Name ~ "(" ~ VType.stringof ~ " value) {_" ~ Name ~ " = value;}");
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
				static if (is(typeof(fld.READ_ONLY))) {
					if (!fld.READ_ONLY || fld() != fld.init) {
						fld.toNode(e);
					}
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
					static if (is(typeof(fld.READ_ONLY))) {
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
			}
			return r;
		}
	}
}

class WindowProps(string PropName, int Width, int Height)
		: Properties, WSize {
	mixin Property!("maximized", bool, false);
	mixin Property!("minimized", bool, false);
	mixin Property!("x", int, SWT.DEFAULT);
	mixin Property!("y", int, SWT.DEFAULT);
	mixin Property!("width", int, Width);
	mixin Property!("height", int, Height);
	mixin Property!("visible", bool, true);

	mixin XMLFuncs!(WindowProps, PropName);
}

class MainWin : Properties, WSize {
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

class EventWin(string Name, int Width, int Height) : Properties, WSize {
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
alias EventWin!("areaSceneWindow", SWT.DEFAULT, SWT.DEFAULT) AreaSceneWin;
alias EventWin!("areaEventWindow", SWT.DEFAULT, SWT.DEFAULT) AreaEventWin;
alias EventWin!("battleWindow", SWT.DEFAULT, SWT.DEFAULT) BattleWin;
alias EventWin!("battleSceneWindow", SWT.DEFAULT, SWT.DEFAULT) BattleSceneWin;
alias EventWin!("battleEventWindow", SWT.DEFAULT, SWT.DEFAULT) BattleEventWin;
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
	@property
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
			r[i] = BgImageS(stripExtension(b.path), b.x, b.y, b.width, b.height, b.mask);
		}
		return r;
	}
	static BgImage[] createBgImages(Skin skin, in BgImageS[] bgs) {
		BgImage[] r;
		r.length = bgs.length;
		foreach (i, b; bgs) {
			auto path = skin.findImagePath(setExtension(b.name, skin.extImage), "");
			if (path.length) {
				path = abs2rel(skin.tableDir, nabs(path));
			} else {
				path = setExtension(b.name, skin.extImage);
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
	string executePath(string appPath) {
		if (!enginePath.length) return "";
		string path = enginePath;
		if (!cwx.utils.isabs(path)) {
			auto dir = appPath.dirName;
			path = std.path.buildPath(dir, path);
		}
		if (execute.length) {
			if (cwx.utils.isabs(execute)) {
				path = execute;
			} else {
				path = std.path.buildPath(path.dirName, execute);
			}
		}
		return path;
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

public class FlexProps {
	MainWin mainWin;
	WindowProps!("dataWindow", SWT.DEFAULT, 400) dataWin;
	WindowProps!("cardWindow", SWT.DEFAULT, 400) cardWin;
	WindowProps!("directoryWindow", SWT.DEFAULT, 400) dirWin;
	AreaWin areaWin;
	AreaSceneWin areaSceneWin;
	AreaEventWin areaEventWin;
	BattleWin battleWin;
	BattleSceneWin battleSceneWin;
	BattleEventWin battleEventWin;
	PackageWin packageWin;
	CardEventWin cardEventWin;
	ContWin contentsWin;
	DialogParam!("settingsDialog") settingsDlg;
	WindowProps!("replaceDialog", 600, SWT.DEFAULT) replaceDlg;
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
	WindowProps!("speakDialog", SWT.DEFAULT, SWT.DEFAULT) speakDlg;
	WindowProps!("messageDialog", SWT.DEFAULT, SWT.DEFAULT) msgDlg;
	DialogParam!("cardEventDialog") cardEvtDlg;
	DialogParam!("flagEventDialog", 350) flagEvtDlg;
	DialogParam!("effectEventDialog") effEvtDlg;
	DialogParam!("soundEventDialog") soundEvtDlg;
	DialogParam!("couponEventDialog") couponEvtDlg;
	DialogParam!("inputEventDialog") inputEvtDlg;
	DialogParam!("selectEventDialog") selEvtDlg;
	DialogParam!("scriptDialog", 400, 300) scriptDlg;
	DialogParam!("commentDialog", 300, 200) commentDlg;
	WindowProps!("dialogPreview", SWT.DEFAULT, 500) dlgPrev;
	WindowProps!("messagePreview", SWT.DEFAULT, 500) msgPrev;
	FlexEtcProps etc;

	private enum IniLocation {
		STANDARD, LOCAL, COPY
	}

	private string _path;
	this(string appPath, string confFileName) {
		IniLocation loc = IniLocation.STANDARD;
		string iniFileName = "cwxeditor.xml";
		if (.exists(std.path.buildPath(appPath.dirName, iniFileName))) {
			// 1.0との互換性を維持するため、アプリケーションのディレクトリに
			// cwxeditor.xmlがあった場合、LOCALをデフォルトにする。
			loc = IniLocation.LOCAL;
		}
		try {
			if (.exists(confFileName)) {
				auto node = XNode.parse(std.file.readText(confFileName));
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
				node.parse();
			}
		} catch (Exception e) {
			debugln(e);
		}

		string dir;
		final switch (loc) {
		case IniLocation.STANDARD:
			dir = appDataDir(appPath);
			dir = std.path.buildPath(dir, "cwxeditor");
			break;
		case IniLocation.LOCAL:
			dir = appPath.dirName;
			break;
		case IniLocation.COPY:
			string base = std.path.buildPath(appPath.dirName, iniFileName);
			dir = appDataDir(appPath);
			dir = std.path.buildPath(dir, "cwxeditor");
			string dest = std.path.buildPath(dir, iniFileName);
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

		_path = std.path.buildPath(dir, iniFileName);
		if (exists(_path)) {
			if (!reloadImpl(false)) {
				createBackup();
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
				dir = std.path.buildPath(dir, "cwxeditor");
				etc.tempPath = std.path.buildPath(dir, "temp");
				etc.backupPath = std.path.buildPath(dir, "backup");
				break;
			case IniLocation.LOCAL:
				etc.tempPath = "temp";
				etc.backupPath = "backup";
				break;
			}
		}
	}
	bool reload() {
		return reloadImpl(true);
	}
	private bool reloadImpl(bool force) {
		try {
			auto node = XNode.parse(std.file.readText(_path));
			if (node.name == "cwxeditor" || node.name == "CWXEditor") {
				foreach (i, fld; this.tupleof) {
					this.tupleof[i] = fromNode(node, fld, force);
				}
			}
			return true;
		} catch(Exception e) {
			debugln(e);
			return false;
		}
	}
	private T fromNode(T)(ref XNode node, T t, bool force) {
		static if (is(typeof(T.fromNode(node)))) {
			if (!t || force) {
				return T.fromNode(node);
			}
		}
		return t;
	}
	private T newField(T)(T t) {
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
					auto text = std.file.readText(_path);
					auto node = XNode.parse(text);
					void df(ref XNode node) {
						r = DockingFolderCTC.fromNode(node, parent, style, create);
					}
					node.onTag["dockingFolder"] = &df;
					node.parse();
					return r;
				} catch (Exception e) {
					// FIXME: DockingFolder.fromNode()内でたまにアクセス違反が発生する
					debug debugln(e);
					if (r && r.area) r.area.dispose();
					retryCount++;
					if (retryCount > 100) {
						createBackup();
						debugln(e);
						return null;
					}
				}
			}
		}
		return r;
	}
	private void createBackup() {
		auto d = Clock.currTime();
		string bakPath = format("%s.bak.%04d%02d%02d%02d%02d%02d", _path, d.year, d.month, d.day, d.hour, d.minute, d.second);
		try {
			std.file.copy(_path, bakPath);
		} catch (Exception e) {
			debugln(e);
		}
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
		auto dir = xmlFileName.dirName;
		if (!.exists(dir)) mkdirRecurse(dir);
		write(xmlFileName, node.text);
	}
	void toNode(T)(ref XNode node, T t) {
		static if (is(typeof(t.toNode(node)))) {
			t.toNode(node);
		}
	}
}
