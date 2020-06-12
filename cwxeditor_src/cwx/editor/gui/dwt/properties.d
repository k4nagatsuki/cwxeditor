
module cwx.editor.gui.dwt.properties;

import cwx.utils;
import cwx.xml;
import cwx.structs;
import cwx.settings;
import cwx.menu;
import cwx.variables;
import cwx.versioninfo;
import cwx.types;
import cwx.filesync;

import cwx.editor.gui.dwt.dockingfolder;
import cwx.editor.gui.dwt.dutils : ppis, dpiMuls;

import std.algorithm : max;
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
	@property const bool maximized() { return _maximized; }
	@property void maximized(bool v) { _maximized = v; }

	auto _minimized = Prop!(bool)("minimized", false);
	@property const bool minimized() { return _minimized; }
	@property void minimized(bool v) { _minimized = v; }

	auto _x = Prop!(int, false, true)("x", SWT.DEFAULT);
	@property const int x() { return _x; }
	@property void x(int v) { _x = v; }

	auto _y = Prop!(int, false, true)("y", SWT.DEFAULT);
	@property const int y() { return _y; }
	@property void y(int v) { _y = v; }

	auto _width = Prop!(int, false, true)("width", Width, SizeChgVersion);
	@property const int width() { return _width; }
	@property void width(int v) { _width = v; }

	auto _height = Prop!(int, false, true)("height", Height, SizeChgVersion);
	@property const int height() { return _height; }
	@property void height(int v) { _height = v; }

	auto _visible = Prop!(bool)("visible", true);
	@property const bool visible() { return _visible; }
	@property void visible(bool v) { _visible = v; }

	mixin XMLFuncs!(WindowProps, PropName);
}

class MainWin : Properties, WSize {
	auto _x = Prop!(int, false, true)("x", SWT.DEFAULT);
	@property const int x() { return _x; }
	@property void x(int v) { _x = v; }

	auto _y = Prop!(int, false, true)("y", SWT.DEFAULT);
	@property const int y() { return _y; }
	@property void y(int v) { _y = v; }

	auto _width = Prop!(int, false, true)("width", 1024);
	@property const int width() { return _width; }
	@property void width(int v) { _width = v; }

	auto _height = Prop!(int, false, true)("height", 768);
	@property const int height() { return _height; }
	@property void height(int v) { _height = v; }

	auto _maximized = Prop!(bool)("maximized", false);
	@property const bool maximized() { return _maximized; }
	@property void maximized(bool v) { _maximized = v; }

	mixin XMLFuncs!(MainWin, "mainWindow");
}

class ContWin : Properties {
	auto _x = Prop!(int, false, true)("x", SWT.DEFAULT);
	@property const int x() { return _x; }
	@property void x(int v) { _x = v; }

	auto _y = Prop!(int, false, true)("y", SWT.DEFAULT);
	@property const int y() { return _y; }
	@property void y(int v) { _y = v; }

	mixin XMLFuncs!(ContWin, "contentsWindow");
}

class DialogParam(string Name, int WidthDef = SWT.DEFAULT, int HeightDef = SWT.DEFAULT, ulong SizeChgVersion = 0)
		: Properties, DSize {
	auto _width = Prop!(int, false, true)("width", WidthDef, SizeChgVersion);
	@property const int width() { return _width; }
	@property void width(int v) { _width = v; }

	auto _height = Prop!(int, false, true)("height", HeightDef, SizeChgVersion);
	@property const int height() { return _height; }
	@property void height(int v) { _height = v; }

	mixin XMLFuncs!(DialogParam, Name);
}

class EventWin(string Name, int Width, int Height, ulong SizeChgVersion = 0) : Properties {
	auto eventSashL = Prop!(int)("eventSashL", 2);
	auto eventSashR = Prop!(int)("eventSashR", 7);

	mixin XMLFuncs!(EventWin, Name);
}
class ToolWin(string PropName, int Width, int Height, ulong SizeChgVersion = 0)
		: Properties, DSize {
	auto _x = Prop!(int, false, true)("x", SWT.DEFAULT);
	@property const int x() { return _x; }
	@property void x(int v) { _x = v; }

	auto _y = Prop!(int, false, true)("y", SWT.DEFAULT);
	@property const int y() { return _y; }
	@property void y(int v) { _y = v; }

	auto _width = Prop!(int, false, true)("width", Width, SizeChgVersion);
	@property const int width() { return _width; }
	@property void width(int v) { _width = v; }

	auto _height = Prop!(int, false, true)("height", Height, SizeChgVersion);
	@property const int height() { return _height; }
	@property void height(int v) { _height = v; }

	mixin XMLFuncs!(ToolWin, PropName);
}
alias EventWin!("areaSceneWindow", SWT.DEFAULT, SWT.DEFAULT) AreaSceneWin;
alias EventWin!("areaEventWindow", SWT.DEFAULT, SWT.DEFAULT) AreaEventWin;
alias EventWin!("battleSceneWindow", SWT.DEFAULT, SWT.DEFAULT) BattleSceneWin;
alias EventWin!("battleEventWindow", SWT.DEFAULT, SWT.DEFAULT) BattleEventWin;
alias EventWin!("packageWindow", 800, 520) PackageWin;
alias EventWin!("cardEventWindow", 800, 520) CardEventWin;

public class FlexProps {
	MainWin mainWin;
	AreaSceneWin areaSceneWin;
	AreaEventWin areaEventWin;
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
	DialogParam!("areaTextCellDialog", 750, 650, 2014111700) areaTextCellDlg;
	DialogParam!("areaTextCellNFDialog", 750, 650, 2014111700) areaTextCellNFDlg;
	DialogParam!("areaColorCellDialog", 700, 450) areaColorCellDlg;
	DialogParam!("areaColorCellNFDialog") areaColorCellNFDlg;
	DialogParam!("areaPCCellDialog") areaPCCellDlg;
	DialogParam!("areaPCCellNFDialog") areaPCCellNFDlg;
	DialogParam!("enemyCardDialog") enemyCardDlg;
	DialogParam!("castCardDialog", SWT.DEFAULT, SWT.DEFAULT, 2012101100) castCardDlg;
	DialogParam!("skillCardDialog", SWT.DEFAULT, SWT.DEFAULT, 2012101100) skillCardDlg;
	DialogParam!("itemCardDialog", SWT.DEFAULT, SWT.DEFAULT, 2012101100) itemCardDlg;
	DialogParam!("beastCardDialog", SWT.DEFAULT, SWT.DEFAULT, 2012101100) beastCardDlg;
	DialogParam!("infoCardDialog", SWT.DEFAULT, SWT.DEFAULT, 2012101100) infoCardDlg;
	DialogParam!("bgImagesDialog", 1000) bgImagesDlg;
	DialogParam!("defaultBgImagesDialog", 900) defBgImagesDlg;
	DialogParam!("flagDialog", 400, 200, 2017032600) flagDlg;
	DialogParam!("stepDialog", 400, 400, 2015111500) stepDlg;
	DialogParam!("variantDialog", -1, -1) variantDlg;
	DialogParam!("newScenarioDialog", SWT.DEFAULT, SWT.DEFAULT, 2012072100) newScDlg;
	WindowProps!("speakDialog", SWT.DEFAULT, SWT.DEFAULT, 2012111500) speakDlg;
	WindowProps!("messageDialog", SWT.DEFAULT, SWT.DEFAULT, 2012101100) msgDlg;
	DialogParam!("branchMemberDialog", SWT.DEFAULT, 400) brMemberDlg;
	DialogParam!("cardEventDialog", SWT.DEFAULT, SWT.DEFAULT, 2019011300) cardEvtDlg;
	DialogParam!("flagEventDialog", 350) flagEvtDlg;
	DialogParam!("effectEventDialog", SWT.DEFAULT, SWT.DEFAULT, 2019033000) effEvtDlg;
	DialogParam!("soundEventDialog") soundEvtDlg;
	DialogParam!("couponEventDialog", SWT.DEFAULT, SWT.DEFAULT, 2019033000) couponEvtDlg;
	DialogParam!("multiCouponEventDialog", SWT.DEFAULT, SWT.DEFAULT, 2019033000) multiCouponEvtDlg;
	DialogParam!("inputEventDialog") inputEvtDlg;
	DialogParam!("gossipEventDialog") gossipEvtDlg;
	DialogParam!("selectEventDialog") selEvtDlg;
	DialogParam!("loseBgImageEventDialog") loseBgImageEvtDlg;
	DialogParam!("scriptDialog", 400, 300) scriptDlg;
	DialogParam!("commentDialog", 350, 200, 2013080800) commentDlg;
	WindowProps!("dialogPreview", SWT.DEFAULT, 500) dlgPrev;
	WindowProps!("messagePreview", SWT.DEFAULT, 500) msgPrev;
	WindowProps!("scriptVariablesDialog", 400, 400) scriptVarSetDlg;
	DialogParam!("flagCombiDialog", 350) flagCombiDlg;
	DialogParam!("eventTemplateDialog", 600, 400) evTemplDlg;
	DialogParam!("toolBarCustomizeDialog", 650, 400) toolBarCustomDlg;
	DialogParam!("importResultDialog", 400, 400) importResultDlg;
	DialogParam!("scenarioLoadErrorsDialog", 300, 300) scenarioLoadErrorsDlg;
	DialogParam!("eventIgnitionsDialog", 350, 300) eventIgnitionsDlg;
	DialogParam!("eventIgnitionsWithRoundsDialog", 450, 300) eventIgnitionsWithRoundsDlg;
	DialogParam!("scenarioHistoryDialog", 500, 350) scenarioHistoryDlg;
	DialogParam!("executedPartyHistoryDialog", 500, 350) executedPartyHistoryDlg;
	DialogParam!("expressionDialog", 500, -1) expressionDlg;
	DialogParam!("expressionWithTargetDialog", 500, -1) expressionWithTargetDlg;
	DialogParam!("selectFeaturesDialog", 300, 300) selectFeaturesDlg;
	DialogParam!("addKeyCodesErrorDialog", 300, 300) addKeyCodesErrorDlg;
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
	private int _dpi= 96;

	private bool _noFile = false;
	private string _noFileTemp;

	version (Windows) {
		private static immutable CWX_DIR = "cwxeditor";
		private static immutable CWX_DIR_NOS = "cwxeditor_no_settings";
	} else {
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
				printStackTrace();
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
						printStackTrace();
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

				// レイアウト関係及びtempとbackupの設定だけは環境によって初期値が変わる
				etc.imageScale = .dpiMuls;
				etc.eventTreeSlope = etc.eventTreeSlope * .dpiMuls;
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
				etc.backupBeforeSavePath.value = etc.backupPath;
			}
			updatePPIs(Display.getCurrent().getDPI().x);

		} catch (Throwable e) {
			printStackTrace();
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
		if (reloadImpl(true, dStr)) { mixin(S_TRACE);
			updatePPIs(Display.getCurrent().getDPI().x);
			return true;
		}
		return false;
	}
	void delNodeTemp() { mixin(S_TRACE);
		XNode node;
		_node = node;
	}
	// 高DPI用にレイアウトパラメータを変更
	private void updatePPIs(int dpi) { mixin(S_TRACE);
		if (_dpi == dpi && _dpi == 96) return;
		auto dpiMuls = cast(real)dpi / _dpi;
		auto iDpiMuls = cast(real)dpi / 96;
		_dpi = dpi;
		foreach (i, pFld; this.tupleof) { mixin(S_TRACE);
			static if (is(typeof(pFld.tupleof))) {
				foreach (j, fld; pFld.tupleof) { mixin(S_TRACE);
					static if (is(typeof(fld.LAYOUT_VALUE))) {
						if (fld.value != SWT.DEFAULT) { mixin(S_TRACE);
							if (fld.readValue) { mixin(S_TRACE);
								this.tupleof[i].tupleof[j].value = cast(int)(fld.value * dpiMuls);
							} else { mixin(S_TRACE);
								assert (fld.value == fld.INIT);
								this.tupleof[i].tupleof[j].value = cast(int)(fld.value * iDpiMuls);
							}
						}
						if (fld.INIT != SWT.DEFAULT) { mixin(S_TRACE);
							this.tupleof[i].tupleof[j].INIT = cast(int)(fld.INIT * iDpiMuls);
						}
					}
				}
			}
		}
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
				dStr ~= " - " ~ .text(__LINE__);
				_dpi = _node.attr("dpi", false, 96);
				dStr ~= " - " ~ .text(__LINE__);
				if (dataVersion < 2012072700) { mixin(S_TRACE);
					// backupBeforeSavePath追加
					etc.backupBeforeSavePath.value = etc.backupPath;
				}
				if (dataVersion < 2014100400) { mixin(S_TRACE);
					// eventTreeSlopeを追加し任意角度設定が可能になったため
					// 元の設定に応じて初期角度を設定
					if (etc.straightEventTreeView) { mixin(S_TRACE);
						if (etc.gentleAngleEventTree) { mixin(S_TRACE);
							etc.eventTreeSlope.value = 8 * .dpiMuls;
						} else { mixin(S_TRACE);
							etc.eventTreeSlope.value = 0;
						}
					} else {
						etc.eventTreeSlope.value = 0;
					}
				}
				if (dataVersion < 2014102400) { mixin(S_TRACE);
					// 「シナリオを開始」追加
					bool has = false;
					toolO: foreach (ref tools; etc.mainToolBar.tools) { mixin(S_TRACE);
						foreach (ref tool; tools) { mixin(S_TRACE);
							if (tool.menu == MenuID.ExecEngineWithParty) {
								// ツールバー設定が初期値で保存されていなかった場合、
								// 新たな初期値にはMenuID.ExecEngineWithPartyが
								// 含まれているので追加不要
								has = true;
								break toolO;
							}
						}
					}
					if (!has) { mixin(S_TRACE);
						foreach (ref tools; etc.mainToolBar.tools) { mixin(S_TRACE);
							auto i = tools.cCountUntil(Tool(MenuID.ExecEngine));
							if (i != -1) { mixin(S_TRACE);
								tools = tools[0 .. i + 1] ~ Tool(MenuID.ExecEngineWithParty) ~ tools[i + 1 .. $];
								break;
							}
						}
					}
				}
				if (dataVersion < 2016091800) { mixin(S_TRACE);
					// imageScale追加
					etc.imageScale = .dpiMuls;
					etc.eventTreeSlope = etc.eventTreeSlope * .dpiMuls;
				}
				// 現在のDPI値に合わせて傾き値の補正
				etc.eventTreeSlope.INIT = .max(etc.eventTreeSlope.INIT.ppis, etc.eventTreeSlope);
				dStr ~= " - " ~ .text(__LINE__);
			}
			dStr ~= " - " ~ .text(__LINE__);
			return true;
		} catch(Exception e) { mixin(S_TRACE);
			printStackTrace();
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
	DockingFolderCTC loadDock(Composite parent, int style,
			bool delegate(string) hasCloseButton,
			bool delegate(DockingFolderCTC, string) canVanish,
			Control delegate(Composite, string) create,
			bool delegate(string) firstResize) { mixin(S_TRACE);
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
							r = DockingFolderCTC.fromNode(node, parent, style, hasCloseButton, canVanish, create, firstResize);
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
						printStackTrace();
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
			printStackTrace();
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
			printStackTrace();
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
		node.newAttr("dpi", _dpi);
		foreach (i, fld; this.tupleof) { mixin(S_TRACE);
			toNode(node, fld);
		}
		if (dock) { mixin(S_TRACE);
			dock.toNode(node, ["work"]);
		}
		auto dir = xmlFileName.dirName();
		if (!.exists(dir)) mkdirRecurse(dir);
		.writeFileAndSync(xmlFileName, node.text);
	}
	void toNode(T)(ref XNode node, T t) { mixin(S_TRACE);
		static if (is(typeof(t.toNode(node)))) {
			t.toNode(node);
		}
	}
}
