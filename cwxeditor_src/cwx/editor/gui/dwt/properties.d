
module cwx.editor.gui.dwt.properties;

import cwx.utils;
import cwx.xml;
import cwx.structs;
import cwx.settings;
import cwx.menu;
import cwx.variables;
import cwx.versioninfo;

import cwx.editor.gui.dwt.dockingfolder;

import std.ascii;
import std.conv;
import std.string;
import std.file;
import std.path;
import std.utf;
import std.datetime;

import org.eclipse.swt.all;

/// ウィンドウ状態のプロパティ。
class WindowProps(string PropName, int Width, int Height, ulong SizeChgVersion = 0)
		: Properties, WSize {
	auto _maximized = Prop!(bool)("maximized", false);
	@property const bool maximized() {return _maximized;}
	@property void maximized(bool v) {_maximized = v;}

	auto _minimized = Prop!(bool)("minimized", false);
	@property const bool minimized() {return _minimized;}
	@property void minimized(bool v) {_minimized = v;}

	auto _x = Prop!(int)("x", SWT.DEFAULT);
	@property const int x() {return _x;}
	@property void x(int v) {_x = v;}

	auto _y = Prop!(int)("y", SWT.DEFAULT);
	@property const int y() {return _y;}
	@property void y(int v) {_y = v;}

	auto _width = Prop!(int)("width", Width, SizeChgVersion);
	@property const int width() {return _width;}
	@property void width(int v) {_width = v;}

	auto _height = Prop!(int)("height", Height, SizeChgVersion);
	@property const int height() {return _height;}
	@property void height(int v) {_height = v;}

	auto _visible = Prop!(bool)("visible", true);
	@property const bool visible() {return _visible;}
	@property void visible(bool v) {_visible = v;}

	mixin XMLFuncs!(WindowProps, PropName);
}

class MainWin : Properties, WSize {
	auto _x = Prop!(int)("x", SWT.DEFAULT);
	@property const int x() {return _x;}
	@property void x(int v) {_x = v;}

	auto _y = Prop!(int)("y", SWT.DEFAULT);
	@property const int y() {return _y;}
	@property void y(int v) {_y = v;}

	auto _width = Prop!(int)("width", 1024);
	@property const int width() {return _width;}
	@property void width(int v) {_width = v;}

	auto _height = Prop!(int)("height", 768);
	@property const int height() {return _height;}
	@property void height(int v) {_height = v;}

	auto _maximized = Prop!(bool)("maximized", false);
	@property const bool maximized() {return _maximized;}
	@property void maximized(bool v) {_maximized = v;}

	mixin XMLFuncs!(MainWin, "mainWindow");
}

class ContWin : Properties {
	auto _x = Prop!(int)("x", SWT.DEFAULT);
	@property const int x() {return _x;}
	@property void x(int v) {_x = v;}

	auto _y = Prop!(int)("y", SWT.DEFAULT);
	@property const int y() {return _y;}
	@property void y(int v) {_y = v;}

	mixin XMLFuncs!(ContWin, "contentsWindow");
}

class DialogParam(string Name, int WidthDef = SWT.DEFAULT, int HeightDef = SWT.DEFAULT, ulong SizeChgVersion = 0)
		: Properties, DSize {
	auto _width = Prop!(int)("width", WidthDef, SizeChgVersion);
	@property const int width() {return _width;}
	@property void width(int v) {_width = v;}

	auto _height = Prop!(int)("height", HeightDef, SizeChgVersion);
	@property const int height() {return _height;}
	@property void height(int v) {_height = v;}

	mixin XMLFuncs!(DialogParam, Name);
}

class EventWin(string Name, int Width, int Height, ulong SizeChgVersion = 0) : Properties, WSize {
	auto _x = Prop!(int)("x", SWT.DEFAULT);
	@property const int x() {return _x;}
	@property void x(int v) {_x = v;}

	auto _y = Prop!(int)("y", SWT.DEFAULT);
	@property const int y() {return _y;}
	@property void y(int v) {_y = v;}

	auto _maximized = Prop!(bool)("maximized", false);
	@property const bool maximized() {return _maximized;}
	@property void maximized(bool v) {_maximized = v;}

	auto _width = Prop!(int)("width", Width, SizeChgVersion);
	@property const int width() {return _width;}
	@property void width(int v) {_width = v;}

	auto _height = Prop!(int)("height", Height, SizeChgVersion);
	@property const int height() {return _height;}
	@property void height(int v) {_height = v;}

	auto _eventSashL = Prop!(int)("eventSashL", 2);
	@property const int eventSashL() {return _eventSashL;}
	@property void eventSashL(int v) {_eventSashL = v;}

	auto _eventSashR = Prop!(int)("eventSashR", 7);
	@property const int eventSashR() {return _eventSashR;}
	@property void eventSashR(int v) {_eventSashR = v;}

	mixin XMLFuncs!(EventWin, Name);
}
class ToolWin(string PropName, int Width, int Height, ulong SizeChgVersion = 0)
		: Properties, DSize {
	auto _x = Prop!(int)("x", SWT.DEFAULT);
	@property const int x() {return _x;}
	@property void x(int v) {_x = v;}

	auto _y = Prop!(int)("y", SWT.DEFAULT);
	@property const int y() {return _y;}
	@property void y(int v) {_y = v;}

	auto _width = Prop!(int)("width", Width, SizeChgVersion);
	@property const int width() {return _width;}
	@property void width(int v) {_width = v;}

	auto _height = Prop!(int)("height", Height, SizeChgVersion);
	@property const int height() {return _height;}
	@property void height(int v) {_height = v;}

	mixin XMLFuncs!(ToolWin, PropName);
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
	DialogParam!("settingsDialog", SWT.DEFAULT, SWT.DEFAULT, 2012080500) settingsDlg;
	ToolWin!("featuresWindow", SWT.DEFAULT, 300) featuresWin;
	WindowProps!("replaceDialog", 900, SWT.DEFAULT, 2012090100) replaceDlg;
	DialogParam!("summaryDialog", SWT.DEFAULT, SWT.DEFAULT, 2012101100) summaryDlg;
	DialogParam!("menuCardDialog", SWT.DEFAULT, SWT.DEFAULT, 2012101100) menuCardDlg;
	DialogParam!("areaBackgroundDialog") areaBackgroundDlg;
	DialogParam!("areaBackgroundNFDialog") areaBackgroundNFDlg;
	DialogParam!("areaTextCellDialog", 750, 630) areaTextCellDlg;
	DialogParam!("areaTextCellNFDialog") areaTextCellNFDlg;
	DialogParam!("areaColorCellDialog", 700, 450) areaColorCellDlg;
	DialogParam!("areaColorCellNFDialog") areaColorCellNFDlg;
	DialogParam!("enemyCardDialog") enemyCardDlg;
	DialogParam!("castCardDialog", SWT.DEFAULT, SWT.DEFAULT, 2012101100) castCardDlg;
	DialogParam!("skillCardDialog", SWT.DEFAULT, SWT.DEFAULT, 2012101100) skillCardDlg;
	DialogParam!("itemCardDialog", SWT.DEFAULT, SWT.DEFAULT, 2012101100) itemCardDlg;
	DialogParam!("beastCardDialog", SWT.DEFAULT, SWT.DEFAULT, 2012101100) beastCardDlg;
	DialogParam!("infoCardDialog", SWT.DEFAULT, SWT.DEFAULT, 2012101100) infoCardDlg;
	DialogParam!("bgImagesDialog", 850) bgImagesDlg;
	DialogParam!("flagDialog") flagDlg;
	DialogParam!("stepDialog") stepDlg;
	DialogParam!("newScenarioDialog", SWT.DEFAULT, SWT.DEFAULT, 2012072100) newScDlg;
	WindowProps!("speakDialog", SWT.DEFAULT, SWT.DEFAULT, 2012111500) speakDlg;
	WindowProps!("messageDialog", SWT.DEFAULT, SWT.DEFAULT, 2012101100) msgDlg;
	DialogParam!("cardEventDialog") cardEvtDlg;
	DialogParam!("flagEventDialog", 350) flagEvtDlg;
	DialogParam!("effectEventDialog") effEvtDlg;
	DialogParam!("soundEventDialog") soundEvtDlg;
	DialogParam!("couponEventDialog") couponEvtDlg;
	DialogParam!("inputEventDialog") inputEvtDlg;
	DialogParam!("selectEventDialog") selEvtDlg;
	DialogParam!("scriptDialog", 400, 300) scriptDlg;
	DialogParam!("commentDialog", 350, 200, 2013080800) commentDlg;
	WindowProps!("dialogPreview", SWT.DEFAULT, 500) dlgPrev;
	WindowProps!("messagePreview", SWT.DEFAULT, 500) msgPrev;
	WindowProps!("scriptVariablesDialog", 400, 400) scriptVarSetDlg;
	DialogParam!("flagCombiDialog", 350) flagCombiDlg;
	DialogParam!("eventTemplateDialog", 600, 400) evTemplDlg;
	DialogParam!("toolBarCustomizeDialog", 650, 400) toolBarCustomDlg;
	MenuProps menu;
	FlexEtcProps etc;

	private enum IniLocation {
		STANDARD, LOCAL, COPY, NOTHING
	}

	private IniLocation _loc;
	private string _path;
	private string _appPath;
	private string _cwxDir = null;
	private XNode _node;

	private bool _noFile = false;
	private string _noFileTemp;

	version (Windows) {
		private static immutable CWX_DIR = "cwxeditor";
		private static immutable CWX_DIR_NOS = "cwxeditor_no_settings";
	} else { mixin(S_TRACE);
		private static immutable CWX_DIR = ".cwxeditor";
		private static immutable CWX_DIR_NOS = ".cwxeditor_no_settings";
	}

	this (string appPath, string confFileName) { mixin(S_TRACE);
		_appPath = appPath;
		string dStr = .text(__LINE__);
		try { mixin(S_TRACE);
			dStr ~= " - " ~ .text(__LINE__);
			_loc = IniLocation.STANDARD;
			string iniFileName = "cwxeditor.xml";
			string iniPath = std.path.buildPath(appPath.dirName(), iniFileName);
			dStr ~= " - " ~ iniPath;
			if (.exists(iniPath)) { mixin(S_TRACE);
				// 1.0との互換性を維持するため、アプリケーションのディレクトリに
				// cwxeditor.xmlがあった場合、LOCALをデフォルトにする。
				_loc = IniLocation.LOCAL;
			}
			dStr ~= " - " ~ .text(__LINE__);
			try { mixin(S_TRACE);
				if (.exists(confFileName)) { mixin(S_TRACE);
					dStr ~= " - " ~ .text(__LINE__);
					auto node = XNode.parse(std.file.readText(confFileName));
					node.onTag["location"] = (ref XNode node) { mixin(S_TRACE);
						if (0 == icmp(node.value, "standard")) { mixin(S_TRACE);
							_loc = IniLocation.STANDARD;
						} else if (0 == icmp(node.value, "local")) { mixin(S_TRACE);
							_loc = IniLocation.LOCAL;
						} else if (0 == icmp(node.value, "copy")) { mixin(S_TRACE);
							_loc = IniLocation.COPY;
						} else if (0 == icmp(node.value, "nothing")) { mixin(S_TRACE);
							_loc = IniLocation.NOTHING;
						}
					};
					node.onTag["file"] = (ref XNode node) { mixin(S_TRACE);
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
			final switch (_loc) {
			case IniLocation.STANDARD:
				dStr ~= " - " ~ .text(__LINE__);
				dir = appDataDir(appPath);
				dir = std.path.buildPath(dir, CWX_DIR);
				break;
			case IniLocation.LOCAL:
				dStr ~= " - " ~ .text(__LINE__);
				dir = appPath.dirName();
				break;
			case IniLocation.COPY:
				dStr ~= " - " ~ .text(__LINE__);
				string base = std.path.buildPath(appPath.dirName(), iniFileName);
				dir = appDataDir(appPath);
				dir = std.path.buildPath(dir, CWX_DIR);
				string dest = std.path.buildPath(dir, iniFileName);
				if (.exists(base) && !.exists(dest)) { mixin(S_TRACE);
					try { mixin(S_TRACE);
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
				dir = std.path.buildPath(dir, CWX_DIR_NOS);
				break;
			}
			dStr ~= " - " ~ .text(__LINE__);

			_path = std.path.buildPath(dir, iniFileName);
			_cwxDir = dir;
			dStr ~= " - " ~ .text(__LINE__);
			if (!_noFile && exists(_path)) { mixin(S_TRACE);
				dStr ~= " - " ~ .text(__LINE__);
				if (!reloadImpl(false, dStr)) { mixin(S_TRACE);
					dStr ~= " - " ~ .text(__LINE__);
					createBackup();
				}
				dStr ~= " - " ~ .text(__LINE__);
				foreach (i, fld; this.tupleof) { mixin(S_TRACE);
					this.tupleof[i] = newField(fld);
				}
				dStr ~= " - " ~ .text(__LINE__);
			} else { mixin(S_TRACE);
				dStr ~= " - " ~ .text(__LINE__);
				foreach (i, fld; this.tupleof) { mixin(S_TRACE);
					this.tupleof[i] = newField(fld);
				}

				// tempとbackupの設定だけは環境によって初期値が変わる
				final switch (_loc) {
				case IniLocation.STANDARD, IniLocation.COPY:
					dStr ~= " - " ~ .text(__LINE__);
					etc.tempPath = std.path.buildPath(cwxDir, "temp");
					etc.backupPath = std.path.buildPath(cwxDir, "backup");
					break;
				case IniLocation.NOTHING:
					_noFileTemp = createNewFileName(cwxDir, true);
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
				etc.backupBeforeSavePath = etc.backupPath;
			}
		} catch (Throwable e) {
			fdebugln(dStr);
			fdebugln(e);
			throw new Exception(dStr, __FILE__, __LINE__);
		}
	}

	@property
	string cwxDir() { mixin(S_TRACE);
		return _cwxDir;
	}

	void cleanup() { mixin(S_TRACE);
		if (!_noFile) return;
		delAll(_noFileTemp);
	}
	bool reload() { mixin(S_TRACE);
		if (_noFile) return true;
		string dStr = .text(__LINE__);
		return reloadImpl(true, dStr);
	}
	void delNodeTemp() { mixin(S_TRACE);
		XNode node;
		_node = node;
	}
	private bool reloadImpl(bool force, ref string dStr) { mixin(S_TRACE);
		if (_noFile) return true;
		try { mixin(S_TRACE);
			dStr ~= " - " ~ .text(__LINE__);
			_node = XNode.parse(std.file.readText(_path));
			dStr ~= " - " ~ .text(__LINE__);
			if (_node.name == "cwxeditor" || _node.name == "CWXEditor") { mixin(S_TRACE);
				ulong dataVersion = _node.attr("version", false, 0);
				dStr ~= " - " ~ .text(__LINE__);
				foreach (i, fld; this.tupleof) { mixin(S_TRACE);
					this.tupleof[i] = fromNode(_node, fld, force, dataVersion);
				}
				if (dataVersion < 2012072700) { mixin(S_TRACE);
					etc.backupBeforeSavePath.value = etc.backupPath;
				}
				dStr ~= " - " ~ .text(__LINE__);
			}
			dStr ~= " - " ~ .text(__LINE__);
			return true;
		} catch(Exception e) { mixin(S_TRACE);
			debugln(e);
			return false;
		}
	}
	private T fromNode(T)(ref XNode node, T t, bool force, ulong dataVersion) { mixin(S_TRACE);
		static if (is(typeof(T.fromNode(node, dataVersion)))) {
			if (!t || force) { mixin(S_TRACE);
				return T.fromNode(node, dataVersion);
			}
		} else static if (is(typeof(T.fromNode(node)))) {
			if (!t || force) { mixin(S_TRACE);
				return T.fromNode(node);
			}
		}
		return t;
	}
	private T newField(T)(T t) { mixin(S_TRACE);
		static if (is(T == class)) {
			if (!t) { mixin(S_TRACE);
				return new T;
			}
		}
		return t;
	}
	DockingFolderCTC loadDock(Composite parent, int style, bool delegate(DockingFolderCTC, string) canVanish, Control delegate(Composite, string) create) { mixin(S_TRACE);
		if (_noFile) return null;
		string dStr = .text(__LINE__);
		try { mixin(S_TRACE);
			dStr ~= " - " ~ .text(__LINE__);
			DockingFolderCTC r = null;
			if (exists(_path)) { mixin(S_TRACE);
				int retryCount = 0;
				dStr ~= " - " ~ .text(__LINE__);
				while (!r) { mixin(S_TRACE);
					try { mixin(S_TRACE);
						dStr ~= " - " ~ .text(__LINE__);
						XNode node;
						if (_node.valid) { mixin(S_TRACE);
							node = _node;
						} else { mixin(S_TRACE);
							auto text = std.file.readText(_path);
							dStr ~= " - " ~ .text(__LINE__);
							node = XNode.parse(text);
						}
						dStr ~= " - " ~ .text(__LINE__);
						void df(ref XNode node) { mixin(S_TRACE);
							dStr ~= " - " ~ .text(__LINE__);
							r = DockingFolderCTC.fromNode(node, parent, style, canVanish, create);
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
						if (retryCount > 100) { mixin(S_TRACE);
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
	private void createBackup() { mixin(S_TRACE);
		if (_noFile) return;
		auto d = Clock.currTime();
		string bakPath = format("%s.bak.%04d%02d%02d%02d%02d%02d", _path, d.year, d.month, d.day, d.hour, d.minute, d.second);
		try { mixin(S_TRACE);
			std.file.copy(_path, bakPath);
		} catch (Exception e) {
			debugln(e);
		}
	}
	void save(DockingFolderCTC dock) { mixin(S_TRACE);
		if (_noFile) return;
		save(_path, dock);
	}
	void save(string xmlFileName, DockingFolderCTC dock) { mixin(S_TRACE);
		if (_noFile) return;
		auto node = XNode.create("cwxeditor");
		node.newAttr("version", APP_VERSION_NUM);
		foreach (i, fld; this.tupleof) { mixin(S_TRACE);
			toNode(node, fld);
		}
		if (dock) { mixin(S_TRACE);
			dock.toNode(node, ["work"]);
		}
		auto dir = xmlFileName.dirName();
		if (!.exists(dir)) mkdirRecurse(dir);
		write(xmlFileName, node.text);
	}
	void toNode(T)(ref XNode node, T t) { mixin(S_TRACE);
		static if (is(typeof(t.toNode(node)))) {
			t.toNode(node);
		}
	}
}
