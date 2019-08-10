
module cwx.editor.gui.dwt.commons;

import cwx.area;
import cwx.card;
import cwx.event;
import cwx.filesync;
import cwx.flag;
import cwx.importutils;
import cwx.menu;
import cwx.path;
import cwx.skin;
import cwx.structs;
import cwx.summary;
import cwx.system;
import cwx.types;
import cwx.usecounter;
import cwx.utils;
import cwx.xml;

import cwx.editor.gui.dwt.areaview;
import cwx.editor.gui.dwt.areawindow;
import cwx.editor.gui.dwt.cardpane;
import cwx.editor.gui.dwt.cardwindow;
import cwx.editor.gui.dwt.datawindow;
import cwx.editor.gui.dwt.directorywindow;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.dockingfolder;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.eventtreeview;
import cwx.editor.gui.dwt.eventview;
import cwx.editor.gui.dwt.eventwindow;
import cwx.editor.gui.dwt.flagspane;
import cwx.editor.gui.dwt.history;
import cwx.editor.gui.dwt.mainwindow;
import cwx.editor.gui.dwt.namewindow;
import cwx.editor.gui.dwt.sbshell;
import cwx.editor.gui.dwt.smalldialogs;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.xmlbytestransfer;

import std.conv;
import std.exception;
import std.file;
import std.path;
import std.typecons;

import core.sync.mutex;

import org.eclipse.swt.all;

Skin findSkin(Commons comm, Props prop, in Summary summ, string type = null, string name = null, string legacyEngine = "", bool appendClassicSkin = true) { mixin(S_TRACE);
	auto legacy = summ ? summ.legacy : false;
	auto sPath = summ ? (summ.readOnlyPath != "" ? summ.readOnlyPath : summ.useTemp ? summ.origZipName : summ.scenarioPath) : "";
	if (type is null) type = summ ? summ.type : "";
	if (name is null) name = summ ? summ.skinName : "";
	return findSkin(comm, prop, summ, legacy, sPath, type, name, legacyEngine, appendClassicSkin);
}

Skin findSkin(Commons comm, Props prop, in Summary summ, bool legacy, string sPath, string type, string name = null, string legacyEngine = "", bool appendClassicSkin = true) { mixin(S_TRACE);
	if (summ) { mixin(S_TRACE);
		findCWPy(prop, sPath);
	}
	if (!summ) { mixin(S_TRACE);
		return findSkin2(prop, prop.var.etc.defaultSkin, prop.var.etc.defaultSkinName);
	}
	if (type is null) type = summ.type;
	if (name is null) name = summ ? summ.skinName : "";
	if (legacy && !type.length) { mixin(S_TRACE);
		if (legacyEngine.length) { mixin(S_TRACE);
			auto lEngine = prop.toAppAbs(legacyEngine);
			foreach (ce; prop.var.etc.classicEngines) { mixin(S_TRACE);
				auto enginePath = prop.toAppAbs(ce.enginePath);
				if (!enginePath.exists()) continue;
				if (cfnmatch(enginePath, lEngine)) { mixin(S_TRACE);
					return .createClassicSkin(prop, ce);
				}
			}
		}
		auto skin = Skin.find(prop.parent, prop.enginePath, type, sPath, legacy,
			prop.var.etc.classicEngineRegex, prop.var.etc.classicDataDirRegex,
			prop.var.etc.classicMatchKey, prop.var.etc.classicEngines, prop.var.etc.defaultSkin);
		void find() { mixin(S_TRACE);
			if (!appendClassicSkin) return;
			if (!prop.var.etc.addNewClassicEngine) return;
			if (!skin.legacyEngine.length) return;
			auto lEngine = prop.toAppAbs(skin.legacyEngine);
			foreach (ce; prop.var.etc.classicEngines) { mixin(S_TRACE);
				auto enginePath = prop.toAppAbs(ce.enginePath);
				if (!enginePath.exists()) continue;
				if (cfnmatch(enginePath, lEngine)) { mixin(S_TRACE);
					skin = createClassicSkin(prop, ce);
					return;
				}
			}
			string dataDirName = abs2rel(skin.legacyDataPath, lEngine.dirName());
			auto ce = ClassicEngine(lEngine.baseName().stripExtension(), lEngine, dataDirName, "");
			ClassicEngine[] arr;
			foreach (e; prop.var.etc.classicEngines) { mixin(S_TRACE);
				arr ~= e.dup;
			}
			prop.var.etc.classicEngines = arr ~ ce;
			comm.refClassicSkin.call();
		}
		if (skin.legacyEngine.length) { mixin(S_TRACE);
			find();
		} else { mixin(S_TRACE);
			skin = null;
			foreach (ce; prop.var.etc.classicEngines) { mixin(S_TRACE);
				auto enginePath = prop.toAppAbs(ce.enginePath);
				if (!enginePath.exists()) continue;
				skin = createClassicSkin(prop, ce);
				break;
			}
		}
		if (skin) { mixin(S_TRACE);
			skin.initialize();
			return skin;
		}
	}
	return findSkin2(prop, type, name);
}

class Dlg(Arg ...) {
	private static const ID = "cwx.editor.gui.dwt.commons.Dlg";
	debug {
		private string[] _fileDlg;
		private size_t[] _lineDlg;
		void dispose() { mixin(S_TRACE);
			foreach (i, f; _fileDlg) { mixin(S_TRACE);
				debugln("Common event sender remained: ", f, ", ", _lineDlg[i]);
			}
		}
	} else {
		void dispose() { }
	}
	private void delegate(Object, Arg)[] _dlg;
	private NoS[] _noss;

	private class NoS {
		void delegate(Arg) dlg;
		void call(Object sender, Arg arg) { mixin(S_TRACE);
			dlg(arg);
		}
	}
	private void addImpl(void delegate(Arg) dlg) { mixin(S_TRACE);
		auto nos = new NoS;
		nos.dlg = dlg;
		_dlg ~= &nos.call;
		_noss ~= nos;
	}
	private void addImpl(void delegate(Object, Arg) dlg) { mixin(S_TRACE);
		_dlg ~= dlg;
	}
	debug {
		void add(string File = __FILE__, size_t Line = __LINE__, T)(T dlg) { mixin(S_TRACE);
			addImpl(dlg);
			_fileDlg ~= File;
			_lineDlg ~= Line;
			assert (_dlg.length == _fileDlg.length);
			assert (_dlg.length == _lineDlg.length);
		}
	} else {
		void add(void delegate(Arg) dlg) { mixin(S_TRACE);
			addImpl(dlg);
		}
		void add(void delegate(Object, Arg) dlg) { mixin(S_TRACE);
			addImpl(dlg);
		}
	}
	void remove(void delegate(Arg) dlg) { mixin(S_TRACE);
		foreach (i, nos; _noss) { mixin(S_TRACE);
			if (nos.dlg is dlg) { mixin(S_TRACE);
				_noss = _noss[0 .. i] ~ _noss[i + 1 .. $];
				remove(&nos.call);
				return;
			}
		}
		assert (0);
	}
	void remove(void delegate(Object, Arg) dlg) { mixin(S_TRACE);
		foreach (i, c; _dlg) { mixin(S_TRACE);
			if (c is dlg) { mixin(S_TRACE);
				_dlg = _dlg[0 .. i] ~ _dlg[i + 1 .. $];
				debug {
					assert (_dlg.length + 1 == _fileDlg.length);
					_fileDlg = _fileDlg[0 .. i] ~ _fileDlg[i + 1 .. $];
					_lineDlg = _lineDlg[0 .. i] ~ _lineDlg[i + 1 .. $];
				}
				return;
			}
		}
		assert (0);
	}
	@property
	size_t count() { mixin(S_TRACE);
		return _dlg.length;
	}
	void call(Arg args) { mixin(S_TRACE);
		foreach (c; _dlg) { mixin(S_TRACE);
			c(null, args);
		}
	}
	void call(Object sender, Arg args) { mixin(S_TRACE);
		foreach (c; _dlg) { mixin(S_TRACE);
			c(sender, args);
		}
	}
}

/// 最上位のパネル。
abstract class TopLevelPanel {
	@property
	abstract string title();
	@property
	abstract Image image();
	@property
	abstract Composite shell();
	@property
	Control focusControl() { return null; }
	@property
	protected abstract void delegate(string) statusText();

	private static class WrapDlg {
		private void delegate() _dlg;
		this (void delegate() dlg) { mixin(S_TRACE);
			_dlg = dlg;
		}
		void call(SelectionEvent se) { _dlg(); }
	}
	private bool delegate()[MenuID] _enabled;
	private void delegate(SelectionEvent)[MenuID] _act;
	void putMenuAction(MenuID menuID, void delegate() dlg, bool delegate() enabled) { mixin(S_TRACE);
		if (!(menuID in _act)) { mixin(S_TRACE);
			_act[menuID] = &(new WrapDlg(dlg)).call;
			_enabled[menuID] = enabled;
		}
	}
	void putMenuAction(MenuID menuID, void delegate(SelectionEvent se) dlg, bool delegate() enabled) { mixin(S_TRACE);
		if (!(menuID in _act)) _act[menuID] = dlg;
		_enabled[menuID] = enabled;
	}
	private bool delegate()[MenuID] _chk;
	void putMenuChecked(MenuID menuID, void delegate() dlg, bool delegate() get, bool delegate() enabled) { mixin(S_TRACE);
		if (!(menuID in _act)) { mixin(S_TRACE);
			_act[menuID] = &(new WrapDlg(dlg)).call;
			_enabled[menuID] = enabled;
		}
		if (!(menuID in _chk)) _chk[menuID] = get;
	}
	void putMenuChecked(MenuID menuID, void delegate(SelectionEvent se) dlg, bool delegate() get, bool delegate() enabled) { mixin(S_TRACE);
		if (!(menuID in _act)) { mixin(S_TRACE);
			_act[menuID] = dlg;
			_enabled[menuID] = enabled;
		}
		if (!(menuID in _chk)) { mixin(S_TRACE);
			_chk[menuID] = get;
		}
	}
	void delegate(SelectionEvent) menuAction(MenuID menuID) { mixin(S_TRACE);
		auto p = menuID in _act;
		return p ? *p : null;
	}
	bool delegate() menuChecked(MenuID menuID) { mixin(S_TRACE);
		auto p = menuID in _chk;
		return p ? *p : null;
	}
	bool delegate() menuEnabled(MenuID menuID) { mixin(S_TRACE);
		if (!shell || shell.isDisposed()) return null;
		auto p = menuID in _enabled;
		return p ? *p : null;
	}
	bool doMenu(Commons comm, int keyCode, wchar character, int stateMask, SelectionEvent delegate() e) { mixin(S_TRACE);
		foreach (menu, dlg; _act) { mixin(S_TRACE);
			if (.isLocalMenu(menu)) continue;
			if (!dlg) continue;
			auto accel = .convertAccelerator(comm.prop.buildMenu(menu));
			if (!.eqAcc(accel, keyCode, character, stateMask)) continue;
			auto p = menu in _enabled;
			if (p && *p !is null && !(*p)()) continue;
			comm.isMenuAccelerating = accel;
			scope (exit) comm.isMenuAccelerating = 0;
			dlg(e());
			return true;
		}
		return false;
	}
	private string _status = "";
	@property
	string statusLine() { return _status; }
	@property
	void statusLine(string statusLine) { mixin(S_TRACE);
		_status = statusLine;
		auto t = statusText;
		if (t) t(statusLine);
	}
	abstract bool openCWXPath(string cwxPath, bool shellActivate);
	@property
	abstract string[] openedCWXPath();
}
interface SashPanel {}
class TLPData {
	TopLevelPanel tlp;
	Object main = null;
	this (TopLevelPanel tlp) { mixin(S_TRACE);
		this.tlp = tlp;
	}
}

TLPData tlpData(Control c) { mixin(S_TRACE);
	while (c) { mixin(S_TRACE);
		auto tlpData = cast(TLPData) c.getData();
		if (tlpData) { mixin(S_TRACE);
			return tlpData;
		}
		c = c.getParent();
	}
	throw new Exception("Not TLP child.", __FILE__, __LINE__);
}
TopLevelPanel getTopLevelPanel(Control c) { mixin(S_TRACE);
	while (c) { mixin(S_TRACE);
		auto tlpData = cast(TLPData)c.getData();
		if (tlpData) { mixin(S_TRACE);
			return tlpData.tlp;
		}
		c = c.getParent();
	}
	return null;
}

class Commons {
	Dlg!() changed;
	Dlg!() refToolsEnabled;
	Dlg!() refImageScale;
	Dlg!() refSwitchFixedWithCheckBox;
	Dlg!() refImagePaneSelectionFilter;
	Dlg!(Shell) save;
	Dlg!() saved;
	Dlg!() refHistories;
	Dlg!() refImportHistory;
	Dlg!() refHistoryMax;
	Dlg!() refSearchHistories;
	Dlg!() refExecutedParties;
	Dlg!() refPartyHistoryMax;
	Dlg!(Summary) refScenario;
	Dlg!() refScenarioName;
	Dlg!() refScenarioPath;
	Dlg!() refSkin;
	Dlg!() refClassicSkin;
	Dlg!() refDataVersion;
	Dlg!() refTargetVersion;
	Dlg!() refStandardSelections;
	Dlg!() refStandardKeyCodes;
	Dlg!() refOuterTools;
	Dlg!() refEventTemplates;
	Dlg!(string, string, bool) refPath;
	Dlg!(string) refPaths;
	Dlg!() delPaths;
	Dlg!(string, string) replPath;
	Dlg!() refUseCount;
	Dlg!() refAreaTable;
	Dlg!(CastCard) refCast;
	Dlg!(CastCard) delCast;
	Dlg!(SkillCard) refSkill;
	Dlg!(CWXPath, SkillCard) delSkill;
	Dlg!(ItemCard) refItem;
	Dlg!(CWXPath, ItemCard) delItem;
	Dlg!(BeastCard) refBeast;
	Dlg!(CWXPath, BeastCard) delBeast;
	Dlg!(InfoCard) refInfo;
	Dlg!(InfoCard) delInfo;
	Dlg!(FlagDir[]) refFlagDir;
	Dlg!(FlagDir[]) delFlagDir;
	Dlg!(cwx.flag.Flag[], Step[], cwx.flag.Variant[]) refFlagAndStep;
	Dlg!(cwx.flag.Flag[], Step[], cwx.flag.Variant[]) delFlagAndStep;
	Dlg!() replText;
	Dlg!() replID;
	Dlg!() refIgnorePaths;
	Dlg!() refCardState;
	Dlg!() refWallpaper;
	Dlg!() refSortCondition;
	Dlg!(CardTableColumn, int) refCardTableColumnWidth;
	Dlg!() refShowCardListHeader;
	Dlg!() refShowCardListTitle;
	Dlg!() refUndoMax;
	Dlg!(MenuID) refMenu;
	Dlg!() refSoundType;
	Dlg!() refShowToolBar;
	Dlg!() refCardImageStatus;
	Dlg!() refEventTreeStyle;
	Dlg!() refRadarStyle;
	Dlg!() refCastCardParameterEditStyle;
	Dlg!() refShowAptitudes;
	Dlg!() refVarSelectStyle;
	Dlg!() refEventTreeViewStyle;
	Dlg!() refEventEditorStyle;
	Dlg!() refContentsToolBoxStyle;
	Dlg!(int) refEventTreeSlope;
	Dlg!() refFloatMessagePreview;
	Dlg!() refUseMessageWindowColorInTextContentDialog;
	Dlg!() refUpdateMotionBarStyle;
	Dlg!() refMenuCardAndBgImageList;

	Dlg!() refTableViewStyle;
	Dlg!(Area) refArea;
	Dlg!(Area) delArea;
	Dlg!(Battle) refBattle;
	Dlg!(Battle) delBattle;
	Dlg!(Package) refPackage;
	Dlg!(Package) delPackage;
	Dlg!(CardTableColumn, int) refMainCardsSort;
	Dlg!(CardTableColumn, int) refHandCardsSort;
	Dlg!(CardTableColumn, int) refImportCardsSort;
	Dlg!(CardTableColumn, int) refImportHandCardsSort;
	Dlg!(int, int) refImportAreasSort;

	Dlg!(string) addMenuCard;
	Dlg!(string) refMenuCard;
	Dlg!(string) delMenuCard;
	Dlg!(string, int[], int) upMenuCard;
	Dlg!(string, int[], int) downMenuCard;
	Dlg!(const(AbstractArea), const(Tuple!(size_t, size_t))[]) refMenuCardIndices;
	Dlg!(string) addBgImage;
	Dlg!(string) refBgImage;
	Dlg!(string) delBgImage;
	Dlg!(string, int[], int) upBgImage;
	Dlg!(string, int[], int) downBgImage;
	Dlg!(bool, CType, MenuID, bool, bool) selContentTool;

	Dlg!(EventTree) refEventTree;
	Dlg!(EventTree) delEventTree;
	Dlg!(Content) refContent;
	Dlg!(Content) delContent;
	Dlg!() refContentText;
	Dlg!() refPreviewValues;

	Dlg!() refCoupons;
	Dlg!() refGossips;
	Dlg!() refCompleteStamps;
	Dlg!() refKeyCodes;
	Dlg!() refCellNames;
	Dlg!() refCardGroups;

	Dlg!(Summary) closeAdds;

	Mutex saveSync;

	private Props _prop = null;
	private FileSync _sync = null;

	bool[string] flagDirExpanded;
	bool[string] stepDirExpanded;
	bool[string] variantDirExpanded;
	bool[string] flagAreaExpanded;
	bool[string] flagBattleExpanded;
	bool[string] flagPackageExpanded;
	void clearExpanded() { mixin(S_TRACE);
		flagDirExpanded = null;
		stepDirExpanded = null;
		variantDirExpanded = null;
		flagAreaExpanded = null;
		flagBattleExpanded = null;
		flagPackageExpanded = null;
	}

	private HashSet!(Composite) _ws;
	private Object[Composite] _wos;
	this (Props prop, FileSync sync) { mixin(S_TRACE);
		_prop = prop;
		_sync = sync;
		_ws = new HashSet!(Composite);
		_aws = new HashSet!(Composite);
		_toolbars = new HashSet!(Control);
		foreach (i, fld; this.tupleof) { mixin(S_TRACE);
			static if (is(typeof(typeof(fld).ID)) && typeof(fld).ID == "cwx.editor.gui.dwt.commons.Dlg") {
				this.tupleof[i] = new typeof(fld);
			}
		}
		refScenario.add(&clearFlagDirExpandedS);
		refScenario.add(&clearStepDirExpandedS);
		refScenario.add(&clearVariantDirExpandedS);
		refScenario.add(&clearAreaDirExpandedS);
		refScenario.add(&clearBattleDirExpandedS);
		refScenario.add(&clearPackageDirExpandedS);
		refVarSelectStyle.add(&clearFlagDirExpanded);
		refVarSelectStyle.add(&clearStepDirExpanded);
		refVarSelectStyle.add(&clearVariantDirExpanded);
		refVarSelectStyle.add(&clearAreaDirExpanded);
		refVarSelectStyle.add(&clearBattleDirExpanded);
		refVarSelectStyle.add(&clearPackageDirExpanded);
		refContentsToolBoxStyle.add(&reconstructContentsToolBox);
	}
	private void clearFlagDirExpandedS(Summary summ) { flagDirExpanded = null; }
	private void clearFlagDirExpanded() { flagDirExpanded = null; }
	private void clearStepDirExpandedS(Summary summ) { stepDirExpanded = null; }
	private void clearStepDirExpanded() { stepDirExpanded = null; }
	private void clearVariantDirExpandedS(Summary summ) { variantDirExpanded = null; }
	private void clearVariantDirExpanded() { variantDirExpanded = null; }
	private void clearAreaDirExpandedS(Summary summ) { flagDirExpanded = null; }
	private void clearAreaDirExpanded() { flagDirExpanded = null; }
	private void clearBattleDirExpandedS(Summary summ) { flagDirExpanded = null; }
	private void clearBattleDirExpanded() { flagDirExpanded = null; }
	private void clearPackageDirExpandedS(Summary summ) { flagDirExpanded = null; }
	private void clearPackageDirExpanded() { flagDirExpanded = null; }

	@property
	inout
	inout(Props) prop() { return _prop; }

	@property
	inout
	inout(FileSync) sync() { return _sync; }

	void dispose() { mixin(S_TRACE);
		if (_wallpaper) _wallpaper.dispose();
		refScenario.remove(&clearFlagDirExpandedS);
		refScenario.remove(&clearStepDirExpandedS);
		refScenario.remove(&clearVariantDirExpandedS);
		refScenario.remove(&clearAreaDirExpandedS);
		refScenario.remove(&clearBattleDirExpandedS);
		refScenario.remove(&clearPackageDirExpandedS);
		refVarSelectStyle.remove(&clearFlagDirExpanded);
		refVarSelectStyle.remove(&clearStepDirExpanded);
		refVarSelectStyle.remove(&clearVariantDirExpanded);
		refVarSelectStyle.remove(&clearAreaDirExpanded);
		refVarSelectStyle.remove(&clearBattleDirExpanded);
		refVarSelectStyle.remove(&clearPackageDirExpanded);
		refContentsToolBoxStyle.remove(&reconstructContentsToolBox);
		foreach (i, fld; this.tupleof) { mixin(S_TRACE);
			static if (is(typeof(typeof(fld).ID)) && typeof(fld).ID == "cwx.editor.gui.dwt.commons.Dlg") {
				this.tupleof[i].dispose();
			}
		}
	}

	private int _isMenuAccelerating = 0;
	/// メニューイベント中に、そのイベントのアクセラレータとして
	/// 押されたShift・Ctrl・Altの状態を返す。
	@property
	const
	int isMenuAccelerating() { return _isMenuAccelerating; }
	@property
	void isMenuAccelerating(int mask) { _isMenuAccelerating = mask; };

	private MainWindow _main = null;
	private TableWindow _tableWin = null;
	private FlagWindow _flagWin = null;
	private CardWindow _castWin = null;
	private CardWindow _skillWin = null;
	private CardWindow _itemWin = null;
	private CardWindow _beastWin = null;
	private CardWindow _infoWin = null;
	private DirectoryWindow _dirWin = null;

	private CouponWindow _couponWin = null;
	private GossipWindow _gossipWin = null;
	private CompleteStampWindow _completeStampWin = null;
	private KeyCodeWindow _keyCodeWin = null;
	private CellNameWindow _cellNameWin = null;
	private CardGroupWindow _cardGroupWin = null;

	private ClipData _clipboard = null;

	private HashSet!Control _toolbars;
	void put(ToolBar bar) { mixin(S_TRACE);
		_toolbars.add(bar);
		bar.addDisposeListener(new CloseRemover!Control(_toolbars, bar));
	}
	void put(Control w, bool delegate() enabled) { mixin(S_TRACE);
		auto d = new MenuData();
		d.enabled = enabled;
		w.setData(d);
		_toolbars.add(w);
		w.addDisposeListener(new CloseRemover!Control(_toolbars, w));
	}
	private Control _lastFocusEditor = null;
	@property
	Control lastFocusEditor() { return _lastFocusEditor; }

	void refreshToolBar() { mixin(S_TRACE);
		refreshToolBar(null);
	}
	private bool _refreshToolBar = false;
	private Control _refreshToolBarArg = null;
	void refreshToolBar(Control fc) { mixin(S_TRACE);
		_refreshToolBarArg = fc;
		if (_refreshToolBar) return;
		_refreshToolBar = true;
		auto display = _main.shell.getDisplay();
		.asyncExec(display, { mixin(S_TRACE);
			if (_main.shell.isDisposed()) return;
			_refreshToolBar = false;
			refreshToolBarImpl(_refreshToolBarArg);
		});
	}
	private void refreshToolBarImpl(Control fc) { mixin(S_TRACE);
		_lastFocusEditor = null;
		if (!_main) return;
		if (!_main.shell) return;
		if (!fc) { mixin(S_TRACE);
			auto display = _main.shell.getDisplay();
			fc = display.getFocusControl();
		}
		bool delegate()[MenuID] cMenuTbl;
		if ((cast(Text)fc || cast(StyledText)fc || cast(Combo)fc || cast(CCombo)fc) && fc.getShell() is mainWin.shell) { mixin(S_TRACE);
			auto menu = fc.getMenu();
			if (menu) { mixin(S_TRACE);
				foreach (itm; menu.getItems()) { mixin(S_TRACE);
					auto d = cast(MenuData)itm.getData();
					if (d && d.enabled) { mixin(S_TRACE);
						cMenuTbl[d.id] = d.enabled;
					}
				}
				_lastFocusEditor = fc;
			}
		}
		void s(Widget itm) { mixin(S_TRACE);
			auto d = cast(MenuData)itm.getData();
			if (!d) return;
			try { mixin(S_TRACE);
				bool enbl;
				auto cMenuE = d.id in cMenuTbl;
				if (cMenuE) { mixin(S_TRACE);
					enbl = (*cMenuE)();
				} else if (d.enabled) { mixin(S_TRACE);
					enbl = d.enabled();
				} else { mixin(S_TRACE);
					return;
				}
				auto toolItm = cast(ToolItem)itm;
				if (toolItm) { mixin(S_TRACE);
					if (toolItm.isEnabled() != enbl) toolItm.setEnabled(enbl);
				} else { mixin(S_TRACE);
					auto ctrl = cast(Control)itm;
					if (ctrl.isEnabled() != enbl) ctrl.setEnabled(enbl);
				}
			} catch (Throwable e) {
				if (auto t = cast(ToolItem)itm) debugln(t.getText());
				if (auto t = cast(MenuItem)itm) debugln(t.getText());
				printStackTrace();
				debugln(std.conv.text(d.id));
				debugln(e);
			}
		}
		foreach (w; _toolbars) { mixin(S_TRACE);
			auto bar = cast(ToolBar) w;
			if (bar) { mixin(S_TRACE);
				if (!bar.isVisible()) continue;
				foreach (itm; bar.getItems()) { mixin(S_TRACE);
					s(itm);
				}
			} else { mixin(S_TRACE);
				s(w);
			}
		}
		_main.refreshToolBar(cMenuTbl);
		refToolsEnabled.call();
	}
	void updateToolBarText() { mixin(S_TRACE);
		void s(ToolBar bar) { mixin(S_TRACE);
			foreach (itm; bar.getItems()) { mixin(S_TRACE);
				auto data = cast(MenuData)itm.getData();
				if (!data) continue;
				if (itm.getImage()) { mixin(S_TRACE);
					itm.setToolTipText(_prop.buildTool(data.id));
				} else { mixin(S_TRACE);
					itm.setText(_prop.buildTool(data.id));
				}
			}
		}
		foreach (w; _toolbars) { mixin(S_TRACE);
			auto bar = cast(ToolBar)w;
			if (!bar) continue;
			s(bar);
		}
		foreach (bar; _main.toolBars) { mixin(S_TRACE);
			s(bar);
		}
	}
	void baseShell(MainWindow main, TableWindow tableWin, FlagWindow flagWin,
			CardWindow castWin, CardWindow skillWin, CardWindow itemWin, CardWindow beastWin, CardWindow infoWin,
			DirectoryWindow dirWin, CouponWindow couponWin, GossipWindow gossipWin, CompleteStampWindow completeStampWin,
			KeyCodeWindow keyCodeWin, CellNameWindow cellNameWin, CardGroupWindow cardGroupWin) { mixin(S_TRACE);
		_main = main;
		_tableWin = tableWin;
		_flagWin = flagWin;
		_castWin = castWin;
		_skillWin = skillWin;
		_itemWin = itemWin;
		_beastWin = beastWin;
		_infoWin = infoWin;
		_dirWin = dirWin;
		_couponWin = couponWin;
		_gossipWin = gossipWin;
		_completeStampWin = completeStampWin;
		_keyCodeWin = keyCodeWin;
		_cellNameWin = cellNameWin;
		_cardGroupWin = cardGroupWin;
		_clipboard = new ClipData(new Clipboard(_main.shell.getDisplay()));
	}

	@property
	MainWindow mainWin() { return _main; }
	@property
	Shell mainShell() { return _main.shell.getShell(); }
	/// Clipboard#dispose()で異常が発生するため、
	/// 新規生成は避け、常にこの唯一のインスタンスを使用する。
	@property
	ClipData clipboard() { return _clipboard; }

	@property
	Summary summary() { mixin(S_TRACE);
		return _tableWin.summary;
	}

	@property
	bool isChanged() { mixin(S_TRACE);
		auto summ = _tableWin.summary;
		return summ && (summ.isChanged || _dirWin.isChanged);
	}

	void closeAll() { mixin(S_TRACE);
		foreach (w; _ws.toArray()) { mixin(S_TRACE);
			if (!_ws.contains(w)) { mixin(S_TRACE);
				// 他のウィンドウに連動して閉じたものを回避
				continue;
			}
			// 分割領域のサイズを保存するためそれ以外を優先して閉じる
			auto tlpData = cast(TLPData) w.getData();
			if (!(cast(SashPanel) tlpData.tlp)) { mixin(S_TRACE);
				close(w);
			}
		}
		foreach (w; _ws.toArray()) { mixin(S_TRACE);
			if (!_ws.contains(w)) continue;
			close(w);
		}
		assert (_ws.size == 0);
		foreach (w; _aws.toArray()) { mixin(S_TRACE);
			if (!_aws.contains(w)) continue;
			close(w);
		}
		assert (_aws.size == 0);
	}

	private Skin _skin;
	/// 現在のスキン。
	@property
	void skin(Skin skin) { _skin = skin; }
	/// ditto
	@property
	inout
	inout(Skin) skin() { return _skin; }
	/// 履歴を見て適用するべきスキンを探す。
	Skin findSkinFromHistory(in Summary summ) { mixin(S_TRACE);
		OpenHistory hist;
		return findSkinFromHistory(summ, hist);
	}
	/// ditto
	Skin findSkinFromHistory(in Summary summ, out OpenHistory hist) { mixin(S_TRACE);
		hist = .findHistory(this, .createHistString(summ));
		if (hist.path.length && (hist.skinType.length || hist.skinEngine.length)) { mixin(S_TRACE);
			return .findSkin(this, prop, summ, hist.skinType, hist.skinName, hist.skinEngine);
		}
		return .findSkin(this, prop, summ);
	}

	/// スキンに属する素材の拡張子が変更された場合は追従する。
	void updateSkinMaterialsExtension(UseCounter useCounter, Skin oldSkin, Skin newSkin) { mixin(S_TRACE);
		if (!useCounter) return;
		if (!oldSkin) oldSkin = findSkin2(prop, prop.var.etc.defaultSkin, prop.var.etc.defaultSkinName);
		if (oldSkin is newSkin) return;
		void proc(in string[] oldDirs, in string[] newDirs, in string[] exts) { mixin(S_TRACE);
			try {
				foreach (oldDir; oldDirs) { mixin(S_TRACE);
					if (!oldDir.exists() || !oldDir.isDir()) return;
					foreach (path; oldDir.dirEntries(SpanMode.depth)) { mixin(S_TRACE);
						if (!path.isFile) continue;
						auto oldRel = abs2rel(path, oldDir);
						if (!useCounter.get(toPathId(oldRel))) continue;
						nd: foreach (newDir; newDirs) { mixin(S_TRACE);
							if (!newDir.exists() || !newDir.isDir()) continue;
							auto newAbs = newDir.buildPath(oldRel);
							if (newAbs.exists()) continue;
							// 拡張子を付け替えて探索する
							foreach (ext; exts) { mixin(S_TRACE);
								newAbs = newAbs.setExtension(ext);
								if (!newAbs.exists()) continue;
								// 発見したので変更
								auto newRel = abs2rel(newAbs, newDir);
								useCounter.change(toPathId(oldRel), toPathId(newRel));
								this.refPath.call(oldRel, newRel, false);
								break nd;
							}
						}
					}
				}
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
			}
		}
		proc(oldSkin.tableDirs, newSkin.tableDirs, oldSkin.extImage);
		proc(oldSkin.bgmDirs, newSkin.bgmDirs, oldSkin.extBgm);
		proc(oldSkin.seDirs, newSkin.seDirs, oldSkin.extSound);
	}

	private void activate(Composite w, bool shellActivate) { mixin(S_TRACE);
		auto shl = cast(Shell) w;
		if (shl) { mixin(S_TRACE);
			shl.setMinimized(false);
			if (shellActivate) shl.setActive();
		} else { mixin(S_TRACE);
			.forceFocus(w, shellActivate);
		}
	}
	private Window rOpen(Window, Main)(Main m, bool shellActivate) { mixin(S_TRACE);
		foreach (w; _ws) { mixin(S_TRACE);
			if ((cast(TLPData)w.getData()).main is m) { mixin(S_TRACE);
				activate(w, shellActivate);
				return cast(Window) _wos[w];
			}
		}
		return null;
	}
	private Composite[] opened(Main)(Main m) { mixin(S_TRACE);
		Composite[] ws;
		foreach (w; _ws) { mixin(S_TRACE);
			if ((cast(TLPData) w.getData()).main is m) { mixin(S_TRACE);
				ws ~= w;
			}
		}
		return ws;
	}
	private Window openImpl(string Pane, Window, Main, string Etc, Args ...)(Main m, bool shellActivate, bool canDuplicate, Args args) { mixin(S_TRACE);
		Window w = canDuplicate ? null : rOpen!(Window)(m, shellActivate);
		if (!w) { mixin(S_TRACE);
			w = openImpl2!(Pane, Window, Main, Etc, Args)(m, shellActivate, args);
		}
		return w;
	}
	private Window openImpl2(string Pane, Window, Main, string Etc, Args ...)(Main m, bool shellActivate, Args args) { mixin(S_TRACE);
		auto w = new Window(args);
		(cast(TLPData) w.shell.getData()).main = m;
		static if (Etc.length) mixin(Etc);
		open(w, Pane);
		return w;
	}
	private class SCL : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			auto shl = cast(Composite) e.widget;
			_wos.remove(shl);
		}
	}
	@property
	private string workPaneKey() { mixin(S_TRACE);
		auto mainWorks = _main.dock.findPane("work", false);
		return mainWorks.length ? mainWorks[0] : _main.dock.findPane("work", true)[0];
	}
	@property
	private Composite workPane() { mixin(S_TRACE);
		if (!_main.dock) return _main.shell;
		return _main.dock.pane(workPaneKey);
	}
	@property
	Composite sidePane() { mixin(S_TRACE);
		if (!_main.dock) return _main.shell;
		auto pane = workPaneKey;
		return _main.dock.addPaneFromCtrlMemory(pane, Dir.E, 3, 1, "side", "side");
	}
	private Window openAreaImpl(A, Window)(Props prop, Summary summ, A area, UndoManager undo, bool shellActivate, bool canDuplicate) { mixin(S_TRACE);
		if (!area) return null;
		bool readOnly = this.summary !is summ;
		return openImpl!("work", Window, A, "", Commons, Props, Summary, Composite, Shell, A, UndoManager, bool)
			(area, shellActivate, canDuplicate, this, prop, summ, workPane,
			cast(Shell)_tableWin.shell, area, undo, readOnly);
	}
	private BindWindow openAreaB(A, BindWindow, SceneWindow)(Props prop, Summary summ, A area, bool shellActivate, bool canDuplicate) { mixin(S_TRACE);
		auto ws = opened(area);
		UndoManager undo = null;
		foreach (w; ws) { mixin(S_TRACE);
			auto tlpData = (cast(TLPData) w.getData());
			auto sw = cast(SceneWindow)tlpData.tlp;
			if (sw) { mixin(S_TRACE);
				undo = sw.undoManager;
			}
			auto ew = cast(EventWindow)tlpData.tlp;
			if (ew) { mixin(S_TRACE);
				undo = ew.undoManager;
			}
			close(w);
		}
		return openAreaImpl!(A, BindWindow)(prop, summ, area, undo, shellActivate, canDuplicate);
	}
	private Window1 openAreaSE(A, Window1, Window2)(Props prop, Summary summ, A area, bool shellActivate, bool canDuplicate) { mixin(S_TRACE);
		auto ws = opened(area);
		UndoManager undo = null;
		foreach (w; ws) { mixin(S_TRACE);
			auto tlpData = (cast(TLPData) w.getData());
			auto asw = cast(Window1) tlpData.tlp;
			if (asw) { mixin(S_TRACE);
				if (canDuplicate) { mixin(S_TRACE);
					undo = asw.undoManager;
				} else { mixin(S_TRACE);
					activate(w, shellActivate);
					return asw;
				}
			}
			auto aew = cast(Window2) tlpData.tlp;
			if (aew) undo = aew.undoManager;
		}
		return openAreaImpl!(A, Window1)(prop, summ, area, undo, shellActivate, canDuplicate);
	}
	TopLevelPanel openAreaScene(Props prop, Summary summ, Area area, bool shellActivate, bool canDuplicate) { mixin(S_TRACE);
		return openAreaSE!(Area, AreaSceneWindow, EventWindow)(prop, summ, area, shellActivate, canDuplicate);
	}
	TopLevelPanel openAreaEvent(Props prop, Summary summ, Area area, bool shellActivate, bool canDuplicate) { mixin(S_TRACE);
		return openAreaSE!(Area, EventWindow, AreaSceneWindow)(prop, summ, area, shellActivate, canDuplicate);
	}
	TopLevelPanel openAreaScene(Props prop, Summary summ, Battle area, bool shellActivate, bool canDuplicate) { mixin(S_TRACE);
		return openAreaSE!(Battle, BattleSceneWindow, EventWindow)(prop, summ, area, shellActivate, canDuplicate);
	}
	TopLevelPanel openAreaEvent(Props prop, Summary summ, Battle area, bool shellActivate, bool canDuplicate) { mixin(S_TRACE);
		return openAreaSE!(Battle, EventWindow, BattleSceneWindow)(prop, summ, area, shellActivate, canDuplicate);
	}
	EventWindow openArea(Props prop, Summary summ, Package area, bool shellActivate, bool canDuplicate) { mixin(S_TRACE);
		return openAreaImpl!(Package, EventWindow)(prop, summ, area, null, shellActivate, canDuplicate);
	}

	CardWindow openHands(Props prop, Summary summ, CastCard c, bool shellActivate) { mixin(S_TRACE);
		auto w = rOpen!(CardWindow)(c, shellActivate);
		if (w) return w;
		return openImpl2!("side", CardWindow, CastCard, "w.refresh(args[3], m);", Commons, Props, CardWindowKind, Summary, Composite)
			(c, shellActivate, this, prop, CardWindowKind.Hand, summ, sidePane);
	}
	CardWindow openAddHands(Props prop, Summary summ, CastCard c, Summary toc, bool shellActivate) { mixin(S_TRACE);
		auto w = rOpen!(CardWindow)(c, shellActivate);
		if (w) return w;
		return openImpl2!("side", CardWindow, CastCard, "", Commons, Props, CardWindowKind, Composite, Summary, CastCard, Summary)
			(c, shellActivate, this, prop, CardWindowKind.ImportSourceHand, sidePane, summ, c, toc);
	}

	private EventWindow openUseEventImpl(C)(Props prop, Summary summ, C c, bool shellActivate, bool canDuplicate) { mixin(S_TRACE);
		Shell parent;
		UndoManager undo = null;
		foreach (w; opened(c)) { mixin(S_TRACE);
			auto tlpData = cast(TLPData)w.getData();
			auto ew = cast(EventWindow)tlpData.tlp;
			if (ew) { mixin(S_TRACE);
				undo = ew.undoManager;
				break;
			}
		}
		static if (is(C : CastCard)) {
			parent = cast(Shell) _castWin.shell;
		} else static if (is(C : SkillCard)) {
			parent = cast(Shell) _skillWin.shell;
		} else static if (is(C : ItemCard)) {
			parent = cast(Shell) _itemWin.shell;
		} else static if (is(C : BeastCard)) {
			parent = cast(Shell) _beastWin.shell;
		} else static if (is(C : InfoCard)) {
			parent = cast(Shell) _infoWin.shell;
		} else static assert (0);
		bool readOnly = this.summary !is summ;
		return openImpl!("work", EventWindow, C, "", Commons, Props, Summary, Composite, Shell, C, UndoManager, bool)
			(c, shellActivate, canDuplicate, this, prop, summ, workPane, parent, c, undo, readOnly);
	}
	EventWindow openUseEvents(Props prop, Summary summ, EffectCard c, bool shellActivate, bool canDuplicate) { mixin(S_TRACE);
		if (auto card = cast(SkillCard)c) { mixin(S_TRACE);
			return openUseEventImpl!(SkillCard)(prop, summ, card, shellActivate, canDuplicate);
		} else if (auto card = cast(ItemCard)c) { mixin(S_TRACE);
			return openUseEventImpl!(ItemCard)(prop, summ, card, shellActivate, canDuplicate);
		} else if (auto card = cast(BeastCard)c) { mixin(S_TRACE);
			return openUseEventImpl!(BeastCard)(prop, summ, card, shellActivate, canDuplicate);
		} else assert (0);
	}
	private void show(Composite c, string pane, Dir dir, string key,
			TopLevelPanel delegate(Composite) create, string text, bool shellActivate) { mixin(S_TRACE);
		auto shl = cast(Shell) c;
		if (shl) { mixin(S_TRACE);
			shl.setMinimized(false);
			shl.open();
		} else { mixin(S_TRACE);
			if (_main.dock.control(key)) { mixin(S_TRACE);
				auto tlpData = cast(TLPData)c.getData();
				if (tlpData && tlpData.tlp.focusControl) { mixin(S_TRACE);
					.forceFocus(tlpData.tlp.focusControl, shellActivate);
				} else {
					.forceFocus(c, shellActivate);
				}
				return;
			}
			Image image;
			_main.dock.addFromMemory((Composite p) { mixin(S_TRACE);
				auto tlp = create(p);
				image = tlp.image;
				return tlp.shell;
			}, text, null, key, pane, workPaneKey, dir, true, loc);
			_main.dock.tabImage(key, image);
		}
	}
	@property
	private NewCtrlLocation loc() { mixin(S_TRACE);
		if (_prop.var.etc.openTabAtRightOfCurrentTab) { mixin(S_TRACE);
			return NewCtrlLocation.Right;
		}
		return NewCtrlLocation.Last;
	}
	private void openMain(string Key, string Pane, Dir D, Win)(Win win, bool shellActivate) { mixin(S_TRACE);
		show(win.shell, Pane, D, Key, delegate TopLevelPanel(Composite p) { mixin(S_TRACE);
			win.reconstruct(p);
			return win;
		}, win.title, shellActivate);
	}
	void openDataWin(bool shellActivate) { mixin(S_TRACE);
		openMain!("data", "data", Dir.N)(_tableWin, shellActivate);
	}
	FlagsPane openFlagWin(bool shellActivate) { mixin(S_TRACE);
		openMain!("flag", "data", Dir.N)(_flagWin, shellActivate);
		return _flagWin.flags;
	}
	CardPane openCardPane(CardType cardType, bool shellActivate) { mixin(S_TRACE);
		final switch (cardType) {
		case CardType.Cast: return openCastWin(shellActivate);
		case CardType.Skill: return openSkillWin(shellActivate);
		case CardType.Item: return openItemWin(shellActivate);
		case CardType.Beast: return openBeastWin(shellActivate);
		case CardType.Info: return openInfoWin(shellActivate);
		}
	}
	CardPane openCastWin(bool shellActivate) { mixin(S_TRACE);
		openMain!("castCard", "data", Dir.N)(_castWin, shellActivate);
		return _castWin.paneCast;
	}
	CardPane openSkillWin(bool shellActivate) { mixin(S_TRACE);
		openMain!("skillCard", "data", Dir.N)(_skillWin, shellActivate);
		return _skillWin.paneSkill;
	}
	CardPane openItemWin(bool shellActivate) { mixin(S_TRACE);
		openMain!("itemCard", "data", Dir.N)(_itemWin, shellActivate);
		return _itemWin.paneItem;
	}
	CardPane openBeastWin(bool shellActivate) { mixin(S_TRACE);
		openMain!("beastCard", "data", Dir.N)(_beastWin, shellActivate);
		return _beastWin.paneBeast;
	}
	CardPane openInfoWin(bool shellActivate) { mixin(S_TRACE);
		openMain!("infoCard", "data", Dir.N)(_infoWin, shellActivate);
		return _infoWin.paneInfo;
	}

	void openDirWin(bool shellActivate) { mixin(S_TRACE);
		openMain!("file", "data", Dir.N)(_dirWin, shellActivate);
	}

	void openCouponWin(bool shellActivate) { mixin(S_TRACE);
		openMain!("coupon", "data", Dir.N)(_couponWin, shellActivate);
	}
	void openGossipWin(bool shellActivate) { mixin(S_TRACE);
		openMain!("gossip", "data", Dir.N)(_gossipWin, shellActivate);
	}
	void openCompleteStampWin(bool shellActivate) { mixin(S_TRACE);
		openMain!("completeStamp", "data", Dir.N)(_completeStampWin, shellActivate);
	}
	void openKeyCodeWin(bool shellActivate) { mixin(S_TRACE);
		openMain!("keyCode", "data", Dir.N)(_keyCodeWin, shellActivate);
	}
	void openCellNameWin(bool shellActivate) { mixin(S_TRACE);
		openMain!("cellName", "data", Dir.N)(_cellNameWin, shellActivate);
	}
	void openCardGroupWin(bool shellActivate) { mixin(S_TRACE);
		openMain!("cardGroup", "data", Dir.N)(_cardGroupWin, shellActivate);
	}

	private void open(TopLevelPanel tlp, string pane) { mixin(S_TRACE);
		_ws.add(tlp.shell);
		_wos[tlp.shell] = tlp;
		tlp.shell.addDisposeListener(new CloseRemover!(Composite)(_ws, tlp.shell));
		tlp.shell.addDisposeListener(new SCL);
		auto shl = cast(Shell) tlp.shell;
		if (shl) { mixin(S_TRACE);
			shl.open();
		} else { mixin(S_TRACE);
			_main.dock.add(tlp.shell, tlp.title, tlp.image, _main.dock.newCtrlKey(pane), true, loc);
		}
	}

	TopLevelPanel areaWindowFrom(string cwxPath, bool shellActivate) { mixin(S_TRACE);
		if (!mainWin.summary) return null;
		auto a = mainWin.summary.findCWXPath(cwxPath);
		if (!a) return null;
		foreach (w; _ws) { mixin(S_TRACE);
			auto tlpData = (cast(TLPData) w.getData());
			if (tlpData.main is cast(Object) a) { mixin(S_TRACE);
				auto asw = cast(AreaSceneWindow) tlpData.tlp;
				if (asw) return tlpData.tlp;
				auto bsw = cast(BattleSceneWindow) tlpData.tlp;
				if (bsw) return tlpData.tlp;
			}
		}
		return null;
	}
	TopLevelPanel eventWindowFrom(string cwxPath, bool shellActivate) { mixin(S_TRACE);
		if (!mainWin.summary) return null;
		auto a = mainWin.summary.findCWXPath(cwxPath);
		if (!a) return null;
		foreach (w; _ws) { mixin(S_TRACE);
			auto tlpData = (cast(TLPData) w.getData());
			if (tlpData.main is cast(Object) a) { mixin(S_TRACE);
				auto ew = cast(EventWindow)tlpData.tlp;
				if (ew) return tlpData.tlp;
			}
		}
		return null;
	}
	AbstractAreaView!(A, C, UseCards, UseBacks)[] areaViewsFrom(A, C, bool UseCards, bool UseBacks)(string cwxPath, bool shellActivate) { mixin(S_TRACE);
		if (!mainWin.summary) return [];
		auto a = mainWin.summary.findCWXPath(cwxPath);
		if (!a) return [];
		typeof(return) r;
		foreach (w; _ws) { mixin(S_TRACE);
			auto tlpData = (cast(TLPData) w.getData());
			if (tlpData.main is cast(Object) a) { mixin(S_TRACE);
				static if (is(A : Area)) {
					auto asw = cast(AreaSceneWindow) tlpData.tlp;
					if (asw) r ~= asw.areaView;
				} else static if (is(A : Battle)) {
					auto bsw = cast(BattleSceneWindow) tlpData.tlp;
					if (bsw) r ~= bsw.areaView;
				} else static assert (0);
			}
		}
		return r;
	}
	EventView[] eventViewsFrom(in CWXPath path, bool shellActivate) { mixin(S_TRACE);
		EventView[] r;
		foreach (w; _ws) { mixin(S_TRACE);
			auto tlpData = (cast(TLPData)w.getData());
			if (tlpData.main is cast(Object)path) { mixin(S_TRACE);
				if (auto ew = cast(EventWindow)tlpData.tlp) {
					r ~= ew.eventView;
				}
			}
		}
		return r;
	}
	EventTreeView[] eventTreeViewFrom(in CWXPath path, in EventTree et, bool shellActivate) { mixin(S_TRACE);
		if (!et) { mixin(S_TRACE);
			EventTreeView[] r;
			foreach (v; eventViewsFrom(path, shellActivate)) { mixin(S_TRACE);
				r ~= v.eventTreeView;
			}
			return r;
		}
		auto owner = .rebindable(et.owner);
		if (auto c = cast(AbstractSpCard)owner) owner = c.abstractOwner;
		if (auto c = cast(PlayerCardEvents)owner) owner = c.owner;
		EventTreeView[] r;
		foreach (w; _ws) { mixin(S_TRACE);
			auto tlpData = (cast(TLPData)w.getData());
			if (tlpData.main is cast(Object)owner) { mixin(S_TRACE);
				auto ew = cast(EventWindow)tlpData.tlp;
				if (ew) r ~= ew.eventTreeView;
			}
		}
		return r;
	}
	CardWindow handCardWindowFrom(Props prop, Summary summ, CastCard c, bool open, bool shellActivate) { mixin(S_TRACE);
		foreach (w; _ws) { mixin(S_TRACE);
			auto tlpData = (cast(TLPData) w.getData());
			if (tlpData.main is c) { mixin(S_TRACE);
				return cast(CardWindow)tlpData.tlp;
			}
		}
		if (open) { mixin(S_TRACE);
			return openHands(prop, summ, c, shellActivate);
		}
		return null;
	}
	private void foreachEventTreeView(bool delegate(EventTreeView view) dlg) { mixin(S_TRACE);
		foreach (w; _ws) { mixin(S_TRACE);
			auto tlpData = (cast(TLPData)w.getData());
			if (cast(EventTreeOwner)tlpData.main) { mixin(S_TRACE);
				EventTreeView view = null;
				auto ew = cast(EventWindow)tlpData.tlp;
				if (ew) view = ew.eventTreeView;
				if (view) { mixin(S_TRACE);
					if (!dlg(view)) continue;
				}
			}
		}
	}
	ContentsToolBox getContentsToolBox(EventTreeView eventTreeView) {
		EventTreeView view = null;
		if (_prop.var.etc.contentsFloat || _prop.var.etc.contentsAutoHide) {
			foreachEventTreeView((v) { mixin(S_TRACE);
				if (v && v !is eventTreeView && v.widget.getShell() is eventTreeView.widget.getShell()
						&& v.contentsToolBox && (v.contentsToolBox.isSingleton || !v.widget.isVisible())) { mixin(S_TRACE);
					view = v;
					return false;
				}
				return true;
			});
		}
		if (view) { mixin(S_TRACE);
			auto box = view.contentsToolBox;
			box.owner = eventTreeView;
			return box;
		}
		return new ContentsToolBox(eventTreeView);
	}
	bool poolContentsToolBox(ContentsToolBox box) {
		EventTreeView view = null;
		foreachEventTreeView((v) { mixin(S_TRACE);
			if (v && !v.readOnly && !v.contentsToolBox && box.owner !is v && box.owner.widget.getShell() is v.widget.getShell()) { mixin(S_TRACE);
				view = v;
				return false;
			}
			return true;
		});
		if (view) { mixin(S_TRACE);
			box.owner = view;
			return true;
		} else { mixin(S_TRACE);
			return false;
		}
	}
	private void reconstructContentsToolBox() {
		foreachEventTreeView((v) { mixin(S_TRACE);
			if (v && v.contentsToolBox) { mixin(S_TRACE);
				v.contentsToolBox.dispose();
			}
			return true;
		});
		foreachEventTreeView((v) { mixin(S_TRACE);
			if (v && (v.widget.isVisible() || !(_prop.var.etc.contentsFloat || _prop.var.etc.contentsAutoHide))) { mixin(S_TRACE);
				assert (v.contentsToolBox is null);
				getContentsToolBox(v);
			}
			return true;
		});
	}

	private HashSet!(Composite) _aws;
	private void addScenarioImpl(CardWindow[] ws) { mixin(S_TRACE);
		foreach (w; ws) { mixin(S_TRACE);
			w.shell.addDisposeListener(new CloseRemover!(Composite)(_aws, w.shell));
			_aws.add(w.shell);
			this.open(w, "side");
		}
	}
	// 他のシナリオからのカードのインポート。
	void addScenario(Props prop) { mixin(S_TRACE);
		auto summ = mainWin.summary;
		if (!summ) return;
		void delegate(string) setStatusLine = &mainWin.setStatusLine;
		auto parent = mainWin.shell;
		AddCard.openScenario(this, prop, parent, setStatusLine, summ, summ, &addScenarioImpl);
	}
	/// ditto
	void addScenario(Props prop, string[] paths, void delegate() failure = null) { mixin(S_TRACE);
		auto summ = mainWin.summary;
		if (!summ) return;
		void delegate(string) setStatusLine = &mainWin.setStatusLine;
		auto parent = mainWin.shell;
		AddCard.openScenario(this, prop, parent, setStatusLine, summ, summ, paths, &addScenarioImpl, failure);
	}
	/// ditto
	void doImport(Summary to, Summary from, in string[] resCWXPath) { mixin(S_TRACE);
		import std.array;
		import std.algorithm;

		auto dialog = new ImportOptionDialog(this, mainShell, to && to.legacy);
		if (!dialog.open()) return;
		auto opt = dialog.option;

		auto result = .importResource(prop.parent, to, from, resCWXPath, opt);
		auto dialog2 = new ImportResultDialog(this, summary, mainShell, result);
		if (!dialog2.open()) return;
		result = dialog2.checkedResult;

		if (result.materials.length) { mixin(S_TRACE);
			foreach (r; result.materials) { mixin(S_TRACE);
				auto dir = r.dst.dirName();
				if (!dir.exists()) { mixin(S_TRACE);
					dir.mkdirRecurse();
				}
				try { mixin(S_TRACE);
					if (isBinImg(r.src)) { mixin(S_TRACE);
						std.file.write(r.dst, strToBImg(r.src));
					} else { mixin(S_TRACE);
						if (!r.dst.dirName().exists()) { mixin(S_TRACE);
							std.file.mkdirRecurse(r.dst.dirName());
						}
						std.file.copy(r.src, r.dst);
					}
				} catch (Exception e) {
					printStackTrace();
					debugln(e);
				}
			}
			_dirWin.refresh();
		}
		if (result.flags.length || result.steps.length || result.variants.length) {
			openFlagWin(false).addFlagsAndSteps(result.flags, result.steps, result.variants);
		}
		if (result.casts.length) openCastWin(false).addCards(std.algorithm.sort!("a.id < b.id")(result.casts.values).array().to!(Card[]));
		if (result.skills.length) openSkillWin(false).addCards(std.algorithm.sort!("a.id < b.id")(result.skills.values).array().to!(Card[]));
		if (result.items.length) openItemWin(false).addCards(std.algorithm.sort!("a.id < b.id")(result.items.values).array().to!(Card[]));
		if (result.beasts.length) openBeastWin(false).addCards(std.algorithm.sort!("a.id < b.id")(result.beasts.values).array().to!(Card[]));
		if (result.infos.length) openInfoWin(false).addCards(std.algorithm.sort!("a.id < b.id")(result.infos.values).array().to!(Card[]));
		auto areas = std.algorithm.sort!("a.id < b.id")(result.areas.values).map!((a) => cast(AbstractArea)a)().array();
		areas ~= std.algorithm.sort!("a.id < b.id")(result.battles.values).map!((a) => cast(AbstractArea)a)().array();
		areas ~= std.algorithm.sort!("a.id < b.id")(result.packages.values).map!((a) => cast(AbstractArea)a)().array();
		if (areas.length) { mixin(S_TRACE);
			openDataWin(false);
			_tableWin.areas.addAreas(areas);
		}
		refreshToolBar();
	}
	EventTemplateDialog _evtTmplDlg = null;
	EventTemplateDialog editScEventTemplate(Shell shell) { mixin(S_TRACE);
		if (!summary) return null;
		if (_evtTmplDlg) { mixin(S_TRACE);
			_evtTmplDlg.active();
			return _evtTmplDlg;
		}
		auto dlg = new EventTemplateDialog(this, prop, summary, shell, summary.eventTemplates);
		dlg.appliedEvent ~= { mixin(S_TRACE);
			summary.eventTemplates = dlg.eventTemplates;
			refEventTemplates.call();
		};
		dlg.closeEvent ~= { _evtTmplDlg = null; };
		_evtTmplDlg = dlg;
		dlg.open();
		return dlg;
	}

	void setTitle(Composite comp, string text) { mixin(S_TRACE);
		auto shell = cast(Shell) comp;
		if (shell) { mixin(S_TRACE);
			shell.setText(text);
		} else { mixin(S_TRACE);
			_main.dock.tabText(_main.dock.keyFromCtrl(comp), text);
		}
	}
	void close(Composite comp) { mixin(S_TRACE);
		auto shell = cast(Shell) comp;
		if (shell) { mixin(S_TRACE);
			shell.close();
		} else { mixin(S_TRACE);
			_main.dock.close(_main.dock.keyFromCtrl(comp));
		}
	}

	void setStatusLine(Control base, string status, bool refMain = true) { mixin(S_TRACE);
		if (!_main) return;
		if (base && base.isDisposed()) return;
		TLPData tlp(Control base) { mixin(S_TRACE);
			TLPData data = null;
			while (base && (data = cast(TLPData) base.getData()) is null) { mixin(S_TRACE);
				if (cast(Shell) base) break;
				base = base.getParent();
			}
			return data;
		}
		auto data = tlp(base);
		if (data) { mixin(S_TRACE);
			data.tlp.statusLine = status;
		}
		if (base && base.isVisible() && refMain && _main.dock) { mixin(S_TRACE);
			auto fc = Display.getCurrent().getFocusControl();
			if (fc && fc.isVisible()) { mixin(S_TRACE);
				auto data2 = tlp(fc);
				if (!data2 || data2 is data) { mixin(S_TRACE);
					_main.statusLine = status;
				}
			}
		}
	}
	@property
	string statusLine() { mixin(S_TRACE);
		return _main.statusLine;
	}

	bool openCWXPath(string path, bool shellActivate) { mixin(S_TRACE);
		return _main.openCWXPath(path, shellActivate);
	}
	bool openFilePath(string path, bool shellActivate, bool deselectEtc = false) { mixin(S_TRACE);
		openDirWin(shellActivate);
		return _dirWin.select(path, deselectEtc);
	}
	void replacePath(string from, bool start) { mixin(S_TRACE);
		auto replWin = _main.openReplWin();
		if (replWin) replWin.replacePath(from, start);
	}
	void replaceID(ID)(ID id, bool start) { mixin(S_TRACE);
		auto replWin = _main.openReplWin();
		if (replWin) replWin.replaceID(id, start);
	}
	void selectIDName(ID)(in ID[] ids, bool shellActivate) { mixin(S_TRACE);
		if (!ids.length) return;
		static if (is(ID:CouponId)) {
			openCouponWin(shellActivate);
			_couponWin.select(ids);
		} else static if (is(ID:GossipId)) {
			openGossipWin(shellActivate);
			_gossipWin.select(ids);
		} else static if (is(ID:CompleteStampId)) {
			openCompleteStampWin(shellActivate);
			_completeStampWin.select(ids);
		} else static if (is(ID:KeyCodeId)) {
			openKeyCodeWin(shellActivate);
			_keyCodeWin.select(ids);
		} else static if (is(ID:CellNameId)) {
			openCellNameWin(shellActivate);
			_cellNameWin.select(ids);
		} else static if (is(ID:CardGroupId)) {
			openCardGroupWin(shellActivate);
			_cardGroupWin.select(ids);
		} else static assert (0);
	}

	void selectSummary(bool shellActivate) { mixin(S_TRACE);
		openDataWin(shellActivate);
		return _tableWin.selectSummary();
	}
	ulong createPackage(EventTree baseTree, string name, bool shellActivate) { mixin(S_TRACE);
		openDataWin(shellActivate);
		return _tableWin.createPackage(baseTree, name);
	}
	ulong createPackage(Content baseStart, string name, bool shellActivate) { mixin(S_TRACE);
		openDataWin(shellActivate);
		return _tableWin.createPackage(baseStart, name);
	}

	private Image _wallpaper = null;
	@property
	Image wallpaper() { return _wallpaper; }
	void refreshWallpaper(Props prop) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			string w = prop.var.etc.wallpaper;
			if (!w.length) { mixin(S_TRACE);
				if (_wallpaper) _wallpaper.dispose();
				_wallpaper = null;
				return;
			}
			if (!isAbsolute(w)) { mixin(S_TRACE);
				w = std.path.buildPath(prop.parent.appPath.dirName(), w);
			}
			if (!w.length || !.exists(w)) { mixin(S_TRACE);
				if (_wallpaper) _wallpaper.dispose();
				_wallpaper = null;
				return;
			}
			auto data = loadImage(w, false);
			if (_wallpaper) _wallpaper.dispose();

			static immutable minWidth = 256;
			static immutable minHeight = 256;
			if (prop.var.etc.wallpaperStyle == WallpaperStyle.Tile && (data.width <= minWidth || data.height <= minHeight)) { mixin(S_TRACE);
				// 敷き詰める場合、あまり細かいイメージだとパフォーマンスが落ちるので
				// あらかじめある程度敷き詰めたものを用意しておく
				if (data.width <= minWidth || data.height <= minHeight) { mixin(S_TRACE);
					auto width = cast(int)(data.width * (cast(double)minWidth / data.width));
					auto height = cast(int)(data.height * (cast(double)minHeight / data.height));
					auto img = new Image(Display.getCurrent(), data);
					scope (exit) img.dispose();
					_wallpaper = new Image(Display.getCurrent(), width, height);
					auto gc = new GC(_wallpaper);
					scope (exit) gc.dispose();
					drawWallpaper(gc, img, new Rectangle(0, 0, width, height), WallpaperStyle.Tile);
				}
			} else { mixin(S_TRACE);
				_wallpaper = new Image(Display.getCurrent(), data);
			}
		} catch (Exception e) {
			if (_wallpaper) _wallpaper.dispose();
			_wallpaper = null;
			printStackTrace();
			debugln(e);
		}
	}

	/// シナリオ内にあるJpy1ファイルの内容の上書きが必要であれば更新する。
	bool updateJpy1Files(bool forceUpdate = false) { mixin(S_TRACE);
		if (summary) { mixin(S_TRACE);
			return summary.updateJpy1Files(prop.parent, prop.var.etc.autoUpdateJpy1File || forceUpdate, _sync);
		}
		return false;
	}
}
