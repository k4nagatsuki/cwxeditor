
module cwx.editor.gui.dwt.properties;

import cwx.utils;
import cwx.xml;
import cwx.skin;
import cwx.background;
import cwx.structs;
import cwx.settings;
import cwx.menu;
import cwx.variables;
import cwx.versioninfo;

import cwx.editor.gui.dwt.dockingfolder;

import std.conv;
import std.string;
import std.file;
import std.path;
import std.utf;
import std.datetime;

import org.eclipse.swt.all;

/// ウィンドウ状態のプロパティ。
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
	MenuProps menu;
	FlexEtcProps etc;

	private enum IniLocation {
		STANDARD, LOCAL, COPY, NOTHING
	}

	private string _path;
	private XNode _node;

	private bool _noFile = false;
	private string _noFileTemp;

	this (string appPath, string confFileName) {
		string dStr = .text(__LINE__);
		try {
			dStr ~= " - " ~ .text(__LINE__);
			IniLocation loc = IniLocation.STANDARD;
			string iniFileName = "cwxeditor.xml";
			string iniPath = std.path.buildPath(appPath.dirName(), iniFileName);
			dStr ~= " - " ~ iniPath;
			if (.exists(iniPath)) {
				// 1.0との互換性を維持するため、アプリケーションのディレクトリに
				// cwxeditor.xmlがあった場合、LOCALをデフォルトにする。
				loc = IniLocation.LOCAL;
			}
			dStr ~= " - " ~ .text(__LINE__);
			try {
				if (.exists(confFileName)) {
					dStr ~= " - " ~ .text(__LINE__);
					auto node = XNode.parse(std.file.readText(confFileName));
					node.onTag["location"] = (ref XNode node) {
						if (0 == icmp(node.value, "standard")) {
							loc = IniLocation.STANDARD;
						} else if (0 == icmp(node.value, "local")) {
							loc = IniLocation.LOCAL;
						} else if (0 == icmp(node.value, "copy")) {
							loc = IniLocation.COPY;
						} else if (0 == icmp(node.value, "nothing")) {
							loc = IniLocation.NOTHING;
						}
					};
					node.onTag["file"] = (ref XNode node) {
						iniFileName = node.value;
					};
					dStr ~= " - " ~ .text(__LINE__);
					node.parse();
					dStr ~= " - " ~ .text(__LINE__);
				}
			} catch (Exception e) {
				debugln(e);
			}
			dStr ~= " - " ~ .text(__LINE__);

			string dir;
			dStr ~= " - " ~ .text(__LINE__);
			final switch (loc) {
			case IniLocation.STANDARD:
				dStr ~= " - " ~ .text(__LINE__);
				dir = appDataDir(appPath);
				dir = std.path.buildPath(dir, "cwxeditor");
				break;
			case IniLocation.LOCAL:
				dStr ~= " - " ~ .text(__LINE__);
				dir = appPath.dirName();
				break;
			case IniLocation.COPY:
				dStr ~= " - " ~ .text(__LINE__);
				string base = std.path.buildPath(appPath.dirName(), iniFileName);
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
			case IniLocation.NOTHING:
				_noFile = true;
				dStr ~= " - " ~ .text(__LINE__);
				dir = appDataDir(appPath);
				dir = std.path.buildPath(dir, "cwxeditor_no_settings");
				break;
			}
			dStr ~= " - " ~ .text(__LINE__);

			_path = std.path.buildPath(dir, iniFileName);
			if (!_noFile && exists(_path)) {
				dStr ~= " - " ~ .text(__LINE__);
				if (!reloadImpl(false, dStr)) {
					dStr ~= " - " ~ .text(__LINE__);
					createBackup();
				}
				dStr ~= " - " ~ .text(__LINE__);
				foreach (i, fld; this.tupleof) {
					this.tupleof[i] = newField(fld);
				}
				dStr ~= " - " ~ .text(__LINE__);
			} else {
				dStr ~= " - " ~ .text(__LINE__);
				foreach (i, fld; this.tupleof) {
					this.tupleof[i] = newField(fld);
				}

				// tempとbackupの設定だけは環境によって初期値が変わる
				final switch (loc) {
				case IniLocation.STANDARD, IniLocation.COPY:
					dStr ~= " - " ~ .text(__LINE__);
					dir = appDataDir(appPath);
					dir = std.path.buildPath(dir, "cwxeditor");
					etc.tempPath = std.path.buildPath(dir, "temp");
					etc.backupPath = std.path.buildPath(dir, "backup");
					break;
				case IniLocation.NOTHING:
					_noFileTemp = createNewFileName(dir, true);
					dStr ~= " - " ~ .text(__LINE__);
					etc.tempPath = std.path.buildPath(_noFileTemp, "temp");
					etc.backupPath = std.path.buildPath(_noFileTemp, "backup");
					break;
				case IniLocation.LOCAL:
					dStr ~= " - " ~ .text(__LINE__);
					etc.tempPath = "temp";
					etc.backupPath = "backup";
					break;
				}
				dStr ~= " - " ~ .text(__LINE__);
			}
		} catch (Throwable e) {
			fdebugln(dStr);
			fdebugln(e);
			throw new Exception(dStr, __FILE__, __LINE__);
		}
	}
	void cleanup() {
		if (!_noFile) return;
		delAll(_noFileTemp);
	}
	bool reload() {
		if (_noFile) return true;
		string dStr = .text(__LINE__);
		return reloadImpl(true, dStr);
	}
	void delNodeTemp() {
		XNode node;
		_node = node;
	}
	private bool reloadImpl(bool force, ref string dStr) {
		if (_noFile) return true;
		try {
			dStr ~= " - " ~ .text(__LINE__);
			_node = XNode.parse(std.file.readText(_path));
			dStr ~= " - " ~ .text(__LINE__);
			if (_node.name == "cwxeditor" || _node.name == "CWXEditor") {
				dStr ~= " - " ~ .text(__LINE__);
				foreach (i, fld; this.tupleof) {
					this.tupleof[i] = fromNode(_node, fld, force);
				}
				dStr ~= " - " ~ .text(__LINE__);
			}
			dStr ~= " - " ~ .text(__LINE__);
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
		static if (is(T == class)) {
			if (!t) {
				return new T;
			}
		}
		return t;
	}
	DockingFolderCTC loadDock(Composite parent, int style, Control delegate(Composite, string) create) {
		if (_noFile) return null;
		string dStr = .text(__LINE__);
		try {
			dStr ~= " - " ~ .text(__LINE__);
			DockingFolderCTC r = null;
			if (exists(_path)) {
				int retryCount = 0;
				dStr ~= " - " ~ .text(__LINE__);
				while (!r) {
					try {
						dStr ~= " - " ~ .text(__LINE__);
						XNode node;
						if (_node.valid) {
							node = _node;
						} else {
							auto text = std.file.readText(_path);
							dStr ~= " - " ~ .text(__LINE__);
							node = XNode.parse(text);
						}
						dStr ~= " - " ~ .text(__LINE__);
						void df(ref XNode node) {
							dStr ~= " - " ~ .text(__LINE__);
							r = DockingFolderCTC.fromNode(node, parent, style, create);
							dStr ~= " - " ~ .text(__LINE__);
						}
						node.onTag["dockingFolder"] = &df;
						dStr ~= " - " ~ .text(__LINE__);
						node.parse();
						dStr ~= " - " ~ .text(__LINE__);
						return r;
					} catch (Exception e) {
						// FIXME: DockingFolder.fromNode()内でたまにアクセス違反が発生する
						dStr ~= " - " ~ .text(__LINE__);
						debug debugln(e);
						if (r && r.area) r.area.dispose();
						dStr ~= " - " ~ .text(__LINE__);
						retryCount++;
						if (retryCount > 100) {
							dStr ~= " - " ~ .text(__LINE__);
							createBackup();
							dStr ~= " - " ~ .text(__LINE__);
							debugln(e);
							dStr ~= " - " ~ .text(__LINE__);
							return null;
						}
					}
					dStr ~= " - " ~ .text(__LINE__);
				}
				dStr ~= " - " ~ .text(__LINE__);
			}
			dStr ~= " - " ~ .text(__LINE__);
			return r;
		} catch (Throwable e) {
			fdebugln(dStr);
			fdebugln(e);
			throw new Exception(dStr, __FILE__, __LINE__);
		}
	}
	private void createBackup() {
		if (_noFile) return;
		auto d = Clock.currTime();
		string bakPath = format("%s.bak.%04d%02d%02d%02d%02d%02d", _path, d.year, d.month, d.day, d.hour, d.minute, d.second);
		try {
			std.file.copy(_path, bakPath);
		} catch (Exception e) {
			debugln(e);
		}
	}
	void save(DockingFolderCTC dock) {
		if (_noFile) return;
		save(_path, dock);
	}
	void save(string xmlFileName, DockingFolderCTC dock) {
		if (_noFile) return;
		auto node = XNode.create("cwxeditor");
		node.newAttr("version", APP_VERSION_NUM);
		foreach (i, fld; this.tupleof) {
			toNode(node, fld);
		}
		if (dock) {
			dock.toNode(node, ["work"]);
		}
		auto dir = xmlFileName.dirName();
		if (!.exists(dir)) mkdirRecurse(dir);
		write(xmlFileName, node.text);
	}
	void toNode(T)(ref XNode node, T t) {
		static if (is(typeof(t.toNode(node)))) {
			t.toNode(node);
		}
	}
}
