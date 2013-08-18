
module cwx.editor.gui.dwt.commons;

import cwx.card;
import cwx.area;
import cwx.flag;
import cwx.summary;
import cwx.utils;
import cwx.event;
import cwx.skin;
import cwx.xml;
import cwx.menu;
import cwx.types;
import cwx.structs;
import cwx.system;

import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.areaview;
import cwx.editor.gui.dwt.mainwindow;
import cwx.editor.gui.dwt.areawindow;
import cwx.editor.gui.dwt.cardwindow;
import cwx.editor.gui.dwt.cardpane;
import cwx.editor.gui.dwt.eventwindow;
import cwx.editor.gui.dwt.eventview;
import cwx.editor.gui.dwt.eventtreeview;
import cwx.editor.gui.dwt.directorywindow;
import cwx.editor.gui.dwt.datawindow;
import cwx.editor.gui.dwt.dockingfolder;
import cwx.editor.gui.dwt.sbshell;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.xmlbytestransfer;

import std.exception;
import std.path;
import std.file;

import org.eclipse.swt.all;

Skin findSkin(Commons comm, Props prop, in Summary summ, string type = null, string legacyEngine = "", bool appendClassicSkin = true) { mixin(S_TRACE);
	if (summ && !summ.legacy) { mixin(S_TRACE);
		findCWPy(prop, summ.useTemp ? summ.zipName : summ.scenarioPath);
	}
	if (!summ) { mixin(S_TRACE);
		return findSkin2(prop, prop.var.etc.defaultSkin);
	}
	if (type is null) type = summ.type;
	if (summ.legacy && !type.length) { mixin(S_TRACE);
		if (legacyEngine.length) { mixin(S_TRACE);
			auto lEngine = prop.toAppAbs(legacyEngine);
			foreach (ce; prop.var.etc.classicEngines) { mixin(S_TRACE);
				if (cfnmatch(prop.toAppAbs(ce.enginePath), lEngine)) { mixin(S_TRACE);
					return createClassicSkin(prop, ce);
				}
			}
		}
		auto skin = Skin.find(prop.parent, prop.enginePath, type, summ.scenarioPath, summ.legacy, prop.var.etc.classicEngineRegex, prop.var.etc.classicDataDirRegex, prop.var.etc.classicMatchKey, prop.var.etc.classicEngines);
		void find() { mixin(S_TRACE);
			if (!appendClassicSkin) return;
			if (!prop.var.etc.addNewClassicEngine) return;
			if (!skin.legacyEngine.length) return;
			auto lEngine = prop.toAppAbs(skin.legacyEngine);
			foreach (ce; prop.var.etc.classicEngines) { mixin(S_TRACE);
				if (cfnmatch(prop.toAppAbs(ce.enginePath), lEngine)) { mixin(S_TRACE);
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
			if (prop.var.etc.classicEngines.length) { mixin(S_TRACE);
				auto ce = prop.var.etc.classicEngines[0];
				skin = createClassicSkin(prop, ce);
			}
		}
		return skin;
	}
	return findSkin2(prop, type);
}

class Dlg(Arg ...) {
	private static const ID = "cwx.editor.gui.dwt.commons.Dlg";
	debug {
		private string[] _fileDlg;
		private size_t[] _lineDlg;
		~this () { mixin(S_TRACE);
			foreach (i, f; _fileDlg) { mixin(S_TRACE);
				debugln("Common event sender remained: ", f, ", ", _lineDlg[i]);
			}
		}
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
	} else { mixin(S_TRACE);
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
	protected abstract void delegate(string) statusText();

	private static class WrapDlg {
		private void delegate() _dlg;
		this (void delegate() dlg) { mixin(S_TRACE);
			_dlg = dlg;
		}
		void call(SelectionEvent se) {_dlg();}
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
	private string _status = "";
	@property
	string statusLine() {return _status;}
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

class Commons {
	Dlg!() changed;
	Dlg!(Shell) save;
	Dlg!() saved;
	Dlg!() refHistories;
	Dlg!() refSearchHistories;
	Dlg!(Summary) refScenario;
	Dlg!() refScenarioName;
	Dlg!() refScenarioPath;
	Dlg!() refSkin;
	Dlg!() refClassicSkin;
	Dlg!() refTargetVersion;
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
	Dlg!(SkillCard) delSkill;
	Dlg!(ItemCard) refItem;
	Dlg!(ItemCard) delItem;
	Dlg!(BeastCard) refBeast;
	Dlg!(BeastCard) delBeast;
	Dlg!(InfoCard) refInfo;
	Dlg!(InfoCard) delInfo;
	Dlg!(FlagDir[]) refFlagDir;
	Dlg!(FlagDir[]) delFlagDir;
	Dlg!(Flag[], Step[]) refFlagAndStep;
	Dlg!(Flag[], Step[]) delFlagAndStep;
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
	Dlg!() refVarSelectStyle;
	Dlg!() refEventTreeViewStyle;
	Dlg!() refTerminalMark;

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

	Dlg!(string) addMenuCard;
	Dlg!(string) refMenuCard;
	Dlg!(string) delMenuCard;
	Dlg!(string, int[], int) upMenuCard;
	Dlg!(string, int[], int) downMenuCard;
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

	Dlg!(Summary) closeAdds;

	const Object saveSync;

	private Props _prop = null;

	bool[string] flagDirExpanded;

	private HashSet!(Composite) _ws;
	private Object[Composite] _wos;
	this (Props prop) { mixin(S_TRACE);
		saveSync = new Object;
		_prop = prop;
		_ws = new HashSet!(Composite);
		_aws = new HashSet!(Composite);
		_toolbars = new HashSet!(Control);
		foreach (i, fld; this.tupleof) { mixin(S_TRACE);
			static if (is(typeof(typeof(fld).ID)) && typeof(fld).ID == "cwx.editor.gui.dwt.commons.Dlg") {
				this.tupleof[i] = new typeof(fld);
			}
		}
		refScenario.add(&clearFlagDirExpandedS);
		refVarSelectStyle.add(&clearFlagDirExpanded);
	}
	private void clearFlagDirExpandedS(Summary summ) { mixin(S_TRACE);
		flagDirExpanded = null;
	}
	private void clearFlagDirExpanded() { mixin(S_TRACE);
		flagDirExpanded = null;
	}
	@property
	Props prop() {return _prop;}
	@property
	const
	const(Props) prop() {return _prop;}
	void dispose() { mixin(S_TRACE);
		if (_wallpaper) _wallpaper.dispose();
		refScenario.remove(&clearFlagDirExpandedS);
		refVarSelectStyle.remove(&clearFlagDirExpanded);
	}

	private MainWindow _main = null;
	private DataWindow _dataWin = null;
	private TableWindow _tableWin = null;
	private FlagWindow _flagWin = null;
	private MainCardWindow _cardWin = null;
	private CastCardWindow _castWin = null;
	private SkillCardWindow _skillWin = null;
	private ItemCardWindow _itemWin = null;
	private BeastCardWindow _beastWin = null;
	private InfoCardWindow _infoWin = null;
	private DirectoryWindow _dirWin = null;

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
	void refreshToolBar() { mixin(S_TRACE);
		refreshToolBar(null);
	}
	void refreshToolBar(Control fc) { mixin(S_TRACE);
		if (!fc) { mixin(S_TRACE);
			auto display = _main.shell.getDisplay();
			fc = display.getFocusControl();
		}
		bool delegate()[MenuID] cMenuTbl;
		if (cast(Text) fc || cast(Combo) fc || cast(CCombo) fc) { mixin(S_TRACE);
			auto menu = fc.getMenu();
			if (menu) { mixin(S_TRACE);
				foreach (itm; menu.getItems()) { mixin(S_TRACE);
					auto d = cast(MenuData) itm.getData();
					if (d && d.enabled) { mixin(S_TRACE);
						cMenuTbl[d.id] = d.enabled;
					}
				}
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
				auto toolItm = cast(ToolItem) itm;
				if (toolItm) { mixin(S_TRACE);
					toolItm.setEnabled(enbl);
				} else { mixin(S_TRACE);
					auto ctrl = cast(Control) itm;
					ctrl.setEnabled(enbl);
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
	}
	void baseShell(MainWindow main, DataWindow dataWin, MainCardWindow cardWin, DirectoryWindow dirWin) { mixin(S_TRACE);
		_main = main;
		_dataWin = dataWin;
		_cardWin = cardWin;
		_dirWin = dirWin;
		_clipboard = new ClipData(new Clipboard(_main.shell.getDisplay()));
	}
	void baseShell(MainWindow main, TableWindow tableWin, FlagWindow flagWin,
			CastCardWindow castWin, SkillCardWindow skillWin, ItemCardWindow itemWin, BeastCardWindow beastWin, InfoCardWindow infoWin,
			DirectoryWindow dirWin) { mixin(S_TRACE);
		_main = main;
		_tableWin = tableWin;
		_flagWin = flagWin;
		_castWin = castWin;
		_skillWin = skillWin;
		_itemWin = itemWin;
		_beastWin = beastWin;
		_infoWin = infoWin;
		_dirWin = dirWin;
		_clipboard = new ClipData(new Clipboard(_main.shell.getDisplay()));
	}
	@property
	MainWindow mainWin() {return _main;}
	@property
	Shell mainShell() {return _main.shell.getShell();}
	/// Clipboard#dispose()で異常が発生するため、
	/// 新規生成は避け、常にこの唯一のインスタンスを使用する。
	@property
	ClipData clipboard() {return _clipboard;}

	@property
	Summary summary() { mixin(S_TRACE);
		if (_dataWin) { mixin(S_TRACE);
			return _dataWin.summary;
		} else if (_tableWin) { mixin(S_TRACE);
			return _tableWin.summary;
		} else assert (0);
	}

	@property
	bool isChanged() { mixin(S_TRACE);
		Summary summ;
		if (_dataWin) { mixin(S_TRACE);
			summ = _dataWin.summary;
		} else { mixin(S_TRACE);
			summ = _tableWin.summary;
		}
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
	void skin(Skin skin) {_skin = skin;}
	/// ditto
	@property
	Skin skin() {return _skin;}
	/// 履歴を見て適用するべきスキンを探す。
	Skin findSkinFromHistory(in Summary summ) { mixin(S_TRACE);
		OpenHistory hist;
		return _main.findSkinFromHistory(summ, hist);
	}

	/// アクティブなコンテントツールボックス。
	@property
	void actToolWin(Shell v) {_actToolWin = v;}
	@property
	Shell actToolWin() {return _actToolWin;}
	private Shell _actToolWin = null;

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
			if ((cast(TLPData) w.getData()).main is m) { mixin(S_TRACE);
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
	private Window __open(string Pane, Window, Main, string Etc, Args ...)(Main m, bool shellActivate, Args args) { mixin(S_TRACE);
		auto w = rOpen!(Window)(m, shellActivate);
		if (!w) { mixin(S_TRACE);
			w = __open2!(Pane, Window, Main, Etc, Args)(m, shellActivate, args);
		}
		return w;
	}
	private Window __open2(string Pane, Window, Main, string Etc, Args ...)(Main m, bool shellActivate, Args args) { mixin(S_TRACE);
		auto w = new Window(args);
		(cast(TLPData) w.shell.getData()).main = m;
		static if (Etc.length) mixin (Etc);
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
		return _main.dock.findPane("work")[0];
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
	private Window __openArea(A, Window)(Props prop, Summary summ, A area, UndoManager undo, bool shellActivate) { mixin(S_TRACE);
		if (!area) return null;
		bool readOnly = this.summary !is summ;
		return __open!("work", Window, A, "", Commons, Props, Summary, Composite, Shell, A, UndoManager, bool)
			(area, shellActivate, this, prop, summ, workPane,
			cast(Shell) (_dataWin ? _dataWin.shell : _tableWin.shell), area, undo, readOnly);
	}
	private BindWindow openAreaB(A, BindWindow, SceneWindow, EventWindow)(Props prop, Summary summ, A area, bool shellActivate) { mixin(S_TRACE);
		auto ws = opened(area);
		UndoManager undo = null;
		foreach (w; ws) { mixin(S_TRACE);
			auto tlpData = (cast(TLPData) w.getData());
			auto sw = cast(SceneWindow) tlpData.tlp;
			if (sw) { mixin(S_TRACE);
				undo = sw.undoManager;
			}
			auto ew = cast(EventWindow) tlpData.tlp;
			if (ew) { mixin(S_TRACE);
				undo = ew.undoManager;
			}
			close(w);
		}
		return __openArea!(A, BindWindow)(prop, summ, area, undo, shellActivate);
	}
	private Window1 openAreaSE(A, BindWindow, Window1, Window2)(Props prop, Summary summ, A area, bool shellActivate) { mixin(S_TRACE);
		auto ws = opened(area);
		UndoManager undo = null;
		foreach (w; ws) { mixin(S_TRACE);
			auto tlpData = (cast(TLPData) w.getData());
			auto aw = cast(BindWindow) tlpData.tlp;
			if (aw) { mixin(S_TRACE);
				activate(w, shellActivate);
				return null;
			}
			auto asw = cast(Window1) tlpData.tlp;
			if (asw) { mixin(S_TRACE);
				activate(w, shellActivate);
				return asw;
			}
			auto aew = cast(Window2) tlpData.tlp;
			if (aew) undo = aew.undoManager;
		}
		return __openArea!(A, Window1)(prop, summ, area, undo, shellActivate);
	}
	AreaWindow openArea(Props prop, Summary summ, Area area, bool shellActivate) { mixin(S_TRACE);
		return openAreaB!(Area, AreaWindow, AreaSceneWindow, AreaEventWindow)(prop, summ, area, shellActivate);
	}
	TopLevelPanel openAreaScene(Props prop, Summary summ, Area area, bool shellActivate) { mixin(S_TRACE);
		return openAreaSE!(Area, AreaWindow, AreaSceneWindow, AreaEventWindow)(prop, summ, area, shellActivate);
	}
	TopLevelPanel openAreaEvent(Props prop, Summary summ, Area area, bool shellActivate) { mixin(S_TRACE);
		return openAreaSE!(Area, AreaWindow, AreaEventWindow, AreaSceneWindow)(prop, summ, area, shellActivate);
	}
	BattleWindow openArea(Props prop, Summary summ, Battle area, bool shellActivate) { mixin(S_TRACE);
		return openAreaB!(Battle, BattleWindow, BattleSceneWindow, BattleEventWindow)(prop, summ, area, shellActivate);
	}
	TopLevelPanel openAreaScene(Props prop, Summary summ, Battle area, bool shellActivate) { mixin(S_TRACE);
		return openAreaSE!(Battle, BattleWindow, BattleSceneWindow, BattleEventWindow)(prop, summ, area, shellActivate);
	}
	TopLevelPanel openAreaEvent(Props prop, Summary summ, Battle area, bool shellActivate) { mixin(S_TRACE);
		return openAreaSE!(Battle, BattleWindow, BattleEventWindow, BattleSceneWindow)(prop, summ, area, shellActivate);
	}
	PackageWindow openArea(Props prop, Summary summ, Package area, bool shellActivate) { mixin(S_TRACE);
		return __openArea!(Package, PackageWindow)(prop, summ, area, null, shellActivate);
	}

	HandCardWindow openHands(Props prop, Summary summ, CastCard c, bool shellActivate) { mixin(S_TRACE);
		auto w = rOpen!(HandCardWindow)(c, shellActivate);
		if (w) return w;
		return __open2!("side", HandCardWindow, CastCard, "w.refresh(args[2], m);", Commons, Props, Summary, Composite)
			(c, shellActivate, this, prop, summ, sidePane);
	}
	AddHandCardWindow openAddHands(Props prop, Summary summ, CastCard c, Summary toc, bool shellActivate) { mixin(S_TRACE);
		auto w = rOpen!(AddHandCardWindow)(c, shellActivate);
		if (w) return w;
		return __open2!("side", AddHandCardWindow, CastCard, "", Commons, Props, Composite, Summary, CastCard, Summary)
			(c, shellActivate, this, prop, sidePane, summ, c, toc);
	}

	private Window __openUseEvent(C, Window)(Props prop, Summary summ, C c, UndoManager undo, bool shellActivate) { mixin(S_TRACE);
		Shell parent;
		if (_cardWin) { mixin(S_TRACE);
			parent = cast(Shell) _cardWin.shell;
		} else { mixin(S_TRACE);
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
		}
		bool readOnly = this.summary !is summ;
		return __open!("work", Window, C, "", Commons, Props, Summary, Composite, Shell, C, UndoManager, bool)
			(c, shellActivate, this, prop, summ, workPane, parent, c, undo, readOnly);
	}
	SkillEventWindow openUseEvents(Props prop, Summary summ, SkillCard c, bool shellActivate) { mixin(S_TRACE);
		return __openUseEvent!(SkillCard, SkillEventWindow)(prop, summ, c, null, shellActivate);
	}
	ItemEventWindow openUseEvents(Props prop, Summary summ, ItemCard c, bool shellActivate) { mixin(S_TRACE);
		return __openUseEvent!(ItemCard, ItemEventWindow)(prop, summ, c, null, shellActivate);
	}
	BeastEventWindow openUseEvents(Props prop, Summary summ, BeastCard c, bool shellActivate) { mixin(S_TRACE);
		return __openUseEvent!(BeastCard, BeastEventWindow)(prop, summ, c, null, shellActivate);
	}
	private void show(Composite c, string pane, Dir dir, string key,
			TopLevelPanel delegate(Composite) create, string text, bool shellActivate) { mixin(S_TRACE);
		auto shl = cast(Shell) c;
		if (shl) { mixin(S_TRACE);
			shl.setMinimized(false);
			shl.open();
		} else { mixin(S_TRACE);
			if (_main.dock.control(key)) { mixin(S_TRACE);
				.forceFocus(c, shellActivate);
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
		if (_dataWin) { mixin(S_TRACE);
			openMain!("data", "data", Dir.N)(_dataWin, shellActivate);
		} else { mixin(S_TRACE);
			openMain!("data", "data", Dir.N)(_tableWin, shellActivate);
		}
	}
	void openFlagWin(bool shellActivate) { mixin(S_TRACE);
		if (_flagWin) { mixin(S_TRACE);
			openMain!("flag", "data", Dir.N)(_flagWin, shellActivate);
		} else { mixin(S_TRACE);
			openMain!("data", "data", Dir.N)(_dataWin, shellActivate);
			_dataWin.selectFlags();
		}
	}
	void openBindCardWin(bool shellActivate) { mixin(S_TRACE);
		openMain!("card", "data", Dir.N)(_cardWin, shellActivate);
	}
	MainCastCardPane openCastWin(bool shellActivate) { mixin(S_TRACE);
		if (_cardWin) { mixin(S_TRACE);
			openBindCardWin(shellActivate);
			return _cardWin.openCast(shellActivate);
		} else { mixin(S_TRACE);
			openMain!("castCard", "data", Dir.N)(_castWin, shellActivate);
			return _castWin.paneCast;
		}
	}
	MainSkillCardPane openSkillWin(bool shellActivate) { mixin(S_TRACE);
		if (_cardWin) { mixin(S_TRACE);
			openBindCardWin(shellActivate);
			return _cardWin.openSkill(shellActivate);
		} else { mixin(S_TRACE);
			openMain!("skillCard", "data", Dir.N)(_skillWin, shellActivate);
			return _skillWin.paneSkill;
		}
	}
	MainItemCardPane openItemWin(bool shellActivate) { mixin(S_TRACE);
		if (_cardWin) { mixin(S_TRACE);
			openBindCardWin(shellActivate);
			return _cardWin.openItem(shellActivate);
		} else { mixin(S_TRACE);
			openMain!("itemCard", "data", Dir.N)(_itemWin, shellActivate);
			return _itemWin.paneItem;
		}
	}
	MainBeastCardPane openBeastWin(bool shellActivate) { mixin(S_TRACE);
		if (_cardWin) { mixin(S_TRACE);
			openBindCardWin(shellActivate);
			return _cardWin.openBeast(shellActivate);
		} else { mixin(S_TRACE);
			openMain!("beastCard", "data", Dir.N)(_beastWin, shellActivate);
			return _beastWin.paneBeast;
		}
	}
	MainInfoCardPane openInfoWin(bool shellActivate) { mixin(S_TRACE);
		if (_cardWin) { mixin(S_TRACE);
			openBindCardWin(shellActivate);
			return _cardWin.openInfo(shellActivate);
		} else { mixin(S_TRACE);
			openMain!("infoCard", "data", Dir.N)(_infoWin, shellActivate);
			return _infoWin.paneInfo;
		}
	}

	void openDirWin(bool shellActivate) { mixin(S_TRACE);
		openMain!("file", "data", Dir.N)(_dirWin, shellActivate);
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
				auto aw = cast(AreaWindow) tlpData.tlp;
				if (aw) return tlpData.tlp;
				auto asw = cast(AreaSceneWindow) tlpData.tlp;
				if (asw) return tlpData.tlp;
				auto bw = cast(BattleWindow) tlpData.tlp;
				if (bw) return tlpData.tlp;
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
				auto aw = cast(AreaWindow) tlpData.tlp;
				if (aw) return tlpData.tlp;
				auto bw = cast(BattleWindow) tlpData.tlp;
				if (bw) return tlpData.tlp;
				auto ew = cast(IEventWindow) tlpData.tlp;
				if (ew) return tlpData.tlp;
			}
		}
		return null;
	}
	AbstractAreaView!(A, C, UseCards, UseBacks) areaViewFrom(A, C, bool UseCards, bool UseBacks)(string cwxPath, bool shellActivate) { mixin(S_TRACE);
		if (!mainWin.summary) return null;
		auto a = mainWin.summary.findCWXPath(cwxPath);
		if (!a) return null;
		foreach (w; _ws) { mixin(S_TRACE);
			auto tlpData = (cast(TLPData) w.getData());
			if (tlpData.main is cast(Object) a) { mixin(S_TRACE);
				static if (is(A : Area)) {
					auto aw = cast(AreaWindow) tlpData.tlp;
					if (aw) return aw.areaView;
					auto asw = cast(AreaSceneWindow) tlpData.tlp;
					if (asw) return asw.areaView;
				} else static if (is(A : Battle)) {
					auto bw = cast(BattleWindow) tlpData.tlp;
					if (bw) return bw.areaView;
					auto bsw = cast(BattleSceneWindow) tlpData.tlp;
					if (bsw) return bsw.areaView;
				} else static assert (0);
			}
		}
		return null;
	}
	EventView!(A, C, UseFire) eventViewFrom(A, C, bool UseFire)(string cwxPath, bool shellActivate) { mixin(S_TRACE);
		if (!mainWin.summary) return null;
		auto a = mainWin.summary.findCWXPath(cwxPath);
		if (!a) return null;
		foreach (w; _ws) { mixin(S_TRACE);
			auto tlpData = (cast(TLPData) w.getData());
			if (tlpData.main is cast(Object) a) { mixin(S_TRACE);
				static if (is(A : Area) && is(C : MenuCard) && UseFire) {
					auto aw = cast(AreaWindow) tlpData.tlp;
					if (aw) return aw.eventView;
				} else static if (is(A : Battle) && is(C : EnemyCard) && UseFire) {
					auto bw = cast(BattleWindow) tlpData.tlp;
					if (bw) return bw.eventView;
				}
				auto ew = cast(EventWindow!A) tlpData.tlp;
				if (ew) return ew.eventView;
			}
		}
		return null;
	}
	EventTreeView eventTreeViewFrom(string cwxPath, bool shellActivate) { mixin(S_TRACE);
		if (!mainWin.summary) return null;
		auto a = mainWin.summary.findCWXPath(cwxPath);
		if (!a) return null;
		auto et = cast(EventTree) a;
		if (!et) return null;
		auto eto = et.owner;
		auto spc = cast(AbstractSpCard) eto;
		if (spc) eto = spc.abstractOwner;
		foreach (w; _ws) { mixin(S_TRACE);
			auto tlpData = (cast(TLPData) w.getData());
			if (tlpData.main is cast(Object) eto) { mixin(S_TRACE);
				auto aw = cast(AreaWindow) tlpData.tlp;
				if (aw) return aw.eventView.eventTreeView;
				auto bw = cast(BattleWindow) tlpData.tlp;
				if (bw) return aw.eventView.eventTreeView;
				auto ew = cast(IEventWindow) tlpData.tlp;
				if (ew) return ew.eventTreeView;
			}
		}
		return null;
	}
	HandCardWindow handCardWindowFrom(Props prop, Summary summ, CastCard c, bool open, bool shellActivate) { mixin(S_TRACE);
		foreach (w; _ws) { mixin(S_TRACE);
			auto tlpData = (cast(TLPData) w.getData());
			if (tlpData.main is c) { mixin(S_TRACE);
				return cast(HandCardWindow) tlpData.tlp;
			}
		}
		if (open) { mixin(S_TRACE);
			return openHands(prop, summ, c, shellActivate);
		}
		return null;
	}

	private HashSet!(Composite) _aws;
	private void addScenarioImpl(Object[] ws) { mixin(S_TRACE);
		void delegate(ref XNode, in XMLInfo) addCast;
		void delegate(ref XNode, in XMLInfo) addSkill;
		void delegate(ref XNode, in XMLInfo) addItem;
		void delegate(ref XNode, in XMLInfo) addBeast;
		void delegate(ref XNode, in XMLInfo) addInfo;
		if (_cardWin) { mixin(S_TRACE);
			addCast = &_cardWin.addCast;
			addSkill = &_cardWin.addSkill;
			addItem = &_cardWin.addItem;
			addBeast = &_cardWin.addBeast;
			addInfo = &_cardWin.addInfo;
		} else { mixin(S_TRACE);
			addCast = &_castWin.addCast;
			addSkill = &_skillWin.addSkill;
			addItem = &_itemWin.addItem;
			addBeast = &_beastWin.addBeast;
			addInfo = &_infoWin.addInfo;
		}
		foreach (wo; ws) { mixin(S_TRACE);
			auto w = cast(AddCard.ACW) wo;
			w.setAddCast(addCast);
			w.setAddSkill(addSkill);
			w.setAddItem(addItem);
			w.setAddBeast(addBeast);
			w.setAddInfo(addInfo);
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
		if (!singleWindowMode(prop)) { mixin(S_TRACE);
			parent = _cardWin.shell;
			setStatusLine = &_cardWin.setStatusLine;
		}
		AddCard.openScenario(this, prop, parent, setStatusLine, summ, summ, &addScenarioImpl);
	}
	/// ditto
	void addScenario(Props prop, string[] paths) { mixin(S_TRACE);
		auto summ = mainWin.summary;
		if (!summ) return;
		void delegate(string) setStatusLine = &mainWin.setStatusLine;
		auto parent = mainWin.shell;
		if (!singleWindowMode(prop)) { mixin(S_TRACE);
			parent = _cardWin.shell;
			setStatusLine = &_cardWin.setStatusLine;
		}
		AddCard.openScenario(this, prop, parent, setStatusLine, summ, summ, paths, &addScenarioImpl);
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
	bool singleWindowMode(Props prop) { mixin(S_TRACE);
		if (_main) { mixin(S_TRACE);
			return _main.dock !is null;
		}
		return prop.var.etc.singleWindow;
	}

	void setStatusLine(Control base, string status, bool refMain = true) { mixin(S_TRACE);
		if (!_main) return;
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
	bool openFilePath(string path, bool shellActivate) { mixin(S_TRACE);
		openDirWin(shellActivate);
		return _dirWin.select(path);
	}
	void replacePath(string from, bool start) { mixin(S_TRACE);
		auto replWin = _main.openReplWin();
		if (replWin) replWin.replacePath(from, start);
	}
	void replaceID(ID)(ID id, bool start) { mixin(S_TRACE);
		auto replWin = _main.openReplWin();
		if (replWin) replWin.replaceID(id, start);
	}

	void selectSummary(bool shellActivate) { mixin(S_TRACE);
		openDataWin(shellActivate);
		if (_dataWin) { mixin(S_TRACE);
			return _dataWin.selectSummary();
		} else { mixin(S_TRACE);
			return _tableWin.selectSummary();
		}
	}
	ulong createPackage(Content baseStart, bool shellActivate) { mixin(S_TRACE);
		openDataWin(shellActivate);
		if (_dataWin) { mixin(S_TRACE);
			return _dataWin.createPackage(baseStart);
		} else { mixin(S_TRACE);
			return _tableWin.createPackage(baseStart);
		}
	}

	private Image _wallpaper = null;
	@property
	Image wallpaper() {return _wallpaper;}
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
			_wallpaper = new Image(Display.getCurrent(), data);
		} catch (Exception e) {
			if (_wallpaper) _wallpaper.dispose();
			_wallpaper = null;
			debugln(e);
		}
	}

	/// シナリオ内にあるJpy1ファイルの内容の上書きが必要であれば更新する。
	void updateJpy1Files() { mixin(S_TRACE);
		_dirWin.updateJpy1Files();
	}
}
