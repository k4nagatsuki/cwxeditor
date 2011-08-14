
module cwx.editor.gui.dwt.commons;

import cwx.card;
import cwx.area;
import cwx.flag;
import cwx.summary;
import cwx.utils;
import cwx.event;
import cwx.skin;

import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.areaview;
import cwx.editor.gui.dwt.mainwindow;
import cwx.editor.gui.dwt.areawindow;
import cwx.editor.gui.dwt.cardwindow;
import cwx.editor.gui.dwt.eventwindow;
import cwx.editor.gui.dwt.directorywindow;
import cwx.editor.gui.dwt.datawindow;
import cwx.editor.gui.dwt.dockingfolder;
import cwx.editor.gui.dwt.sbshell;

import std.path;
import std.file;

import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.graphics.Image;

private class Dlg(Arg ...) {
	private static const ID = "cwx.editor.gui.dwt.commons.Dlg";
	debug {
		private string[] _fileDlg;
		private size_t[] _lineDlg;
		~this () {
			foreach (i, f; _fileDlg) {
				debugln("Common event sender remained: ", f, ", ", _lineDlg[i]);
			}
		}
	}
	private void delegate(Object, Arg)[] _dlg;
	private NoS[] _noss;

	private class NoS {
		void delegate(Arg) dlg;
		void call(Object sender, Arg arg) {
			dlg(arg);
		}
	}
	private void addImpl(void delegate(Arg) dlg) {
		auto nos = new NoS;
		nos.dlg = dlg;
		_dlg ~= &nos.call;
		_noss ~= nos;
	}
	private void addImpl(void delegate(Object, Arg) dlg) {
		_dlg ~= dlg;
	}
	debug {
		void add(string File = __FILE__, size_t Line = __LINE__, T)(T dlg) {
			addImpl(dlg);
			_fileDlg ~= File;
			_lineDlg ~= Line;
			assert (_dlg.length == _fileDlg.length);
			assert (_dlg.length == _lineDlg.length);
		}
	} else {
		void add(void delegate(Arg) dlg) {
			addImpl(dlg);
		}
		void add(void delegate(Object, Arg) dlg) {
			addImpl(dlg);
		}
	}
	void remove(void delegate(Arg) dlg) {
		foreach (i, nos; _noss) {
			if (nos.dlg is dlg) {
				_noss = _noss[0 .. i] ~ _noss[i + 1 .. $];
				remove(&nos.call);
				return;
			}
		}
		assert (0);
	}
	void remove(void delegate(Object, Arg) dlg) {
		foreach (i, c; _dlg) {
			if (c is dlg) {
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
	size_t count() {
		return _dlg.length;
	}
	void call(Arg args) {
		foreach (c; _dlg) {
			c(null, args);
		}
	}
	void call(Object sender, Arg args) {
		foreach (c; _dlg) {
			c(sender, args);
		}
	}
}

/// 最上位のパネル。
abstract class TopLevelPanel {
	abstract string title();
	abstract Image image();
	abstract Composite shell();
	protected abstract void delegate(string) statusText();

	private static class WrapDlg {
		private void delegate() _dlg;
		this (void delegate() dlg) {
			_dlg = dlg;
		}
		void call(SelectionEvent se) {_dlg();}
	}
	private void delegate(SelectionEvent)[MenuID] _act;
	void putMenuAction(MenuID menuID, void delegate() dlg) {
		if (!(menuID in _act)) {
			_act[menuID] = &(new WrapDlg(dlg)).call;
		}
	}
	void putMenuAction(MenuID menuID, void delegate(SelectionEvent se) dlg) {
		if (!(menuID in _act)) _act[menuID] = dlg;
	}
	private bool delegate()[MenuID] _chk;
	void putMenuChecked(MenuID menuID, void delegate() dlg, bool delegate() get) {
		if (!(menuID in _act)) {
			_act[menuID] = &(new WrapDlg(dlg)).call;
		}
		if (!(menuID in _chk)) _chk[menuID] = get;
	}
	void putMenuChecked(MenuID menuID, void delegate(SelectionEvent se) dlg, bool delegate() get) {
		if (!(menuID in _act)) _act[menuID] = dlg;
		if (!(menuID in _chk)) _chk[menuID] = get;
	}
	void delegate(SelectionEvent) menuAction(MenuID menuID) {
		auto p = menuID in _act;
		return p ? *p : null;
	}
	bool delegate() menuChecked(MenuID menuID) {
		auto p = menuID in _chk;
		return p ? *p : null;
	}
	private string _status = "";
	string statusLine() {return _status;}
	void statusLine(string statusLine) {
		_status = statusLine;
		auto t = statusText;
		if (t) t(statusLine);
	}
}
class TLPData {
	TopLevelPanel tlp;
	Object main = null;
	this (TopLevelPanel tlp) {
		this.tlp = tlp;
	}
}

class Commons {
	Dlg!(Shell) save;
	Dlg!() saved;
	Dlg!(Summary) refScenario;
	Dlg!() refScenarioName;
	Dlg!() refScenarioPath;
	Dlg!() refSkin;
	Dlg!() refStandardKeyCodes;
	Dlg!() refOuterTools;
	Dlg!(string, string, bool) refPath;
	Dlg!(string) refPaths;
	Dlg!() delPaths;
	Dlg!(string, string) replPath;
	Dlg!() refUseCount;
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
	Dlg!(Flag[], Step[]) refFlagAndStep;
	Dlg!(Flag[], Step[]) delFlagAndStep;
	Dlg!(Flag) refFlag;
	Dlg!(Step) refStep;
	Dlg!(Flag) delFlag;
	Dlg!(Step) delStep;
	Dlg!() replText;
	Dlg!() replID;
	Dlg!() refIgnorePaths;
	Dlg!() refCardState;
	Dlg!() refWallpaper;
	Dlg!() refSortCondition;

	Dlg!(Area) refArea;
	Dlg!(Area) delArea;
	Dlg!(Battle) refBattle;
	Dlg!(Battle) delBattle;
	Dlg!(Package) refPackage;
	Dlg!(Package) delPackage;

	Dlg!(string) addMenuCard;
	Dlg!(string) refMenuCard;
	Dlg!(string) delMenuCard;
	Dlg!(string, int[]) upMenuCard;
	Dlg!(string, int[]) downMenuCard;
	Dlg!(string) addBgImage;
	Dlg!(string) refBgImage;
	Dlg!(string) delBgImage;
	Dlg!(string, int[]) upBgImage;
	Dlg!(string, int[]) downBgImage;

	Dlg!(Content) refContent;
	Dlg!(Content) delContent;

	Dlg!(Importable) closeAdds;

	const Object saveSync;

	private HashSet!(Composite) _ws;
	private Object[Composite] _wos;
	this() {
		saveSync = new Object;
		_ws = new HashSet!(Composite);
		foreach (i, fld; this.tupleof) {
			static if (is(typeof(typeof(fld).ID)) && typeof(fld).ID == "cwx.editor.gui.dwt.commons.Dlg") {
				this.tupleof[i] = new typeof(fld);
			}
		}
	}
	void dispose() {
		if (_wallpaper) _wallpaper.dispose();
	}
	private MainWindow _main;
	private DataWindow _dataWin = null;
	private TableWindow _tableWin = null;
	private FlagWindow _flagWin = null;
	private MainCardWindow _cardWin;
	private DirectoryWindow _dirWin;
	void baseShell(MainWindow main, DataWindow dataWin, MainCardWindow cardWin, DirectoryWindow dirWin) {
		_main = main;
		_dataWin = dataWin;
		_cardWin = cardWin;
		_dirWin = dirWin;
	}
	void baseShell(MainWindow main, TableWindow tableWin, FlagWindow flagWin,
			MainCardWindow cardWin, DirectoryWindow dirWin) {
		_main = main;
		_tableWin = tableWin;
		_flagWin = flagWin;
		_cardWin = cardWin;
		_dirWin = dirWin;
	}
	MainWindow mainWin() {return _main;}
	

	bool isChanged() {
		Summary summ;
		if (_dataWin) {
			summ = _dataWin.summary;
		} else {
			summ = _tableWin.summary;
		}
		return summ && (summ.isChanged || _dirWin.isChanged);
	}

	void closeAll() {
		foreach (w; _ws.toArray) {
			close(w);
		}
		assert (_ws.size == 0);
	}

	private Skin _skin;
	/// 現在のスキン。
	void skin(Skin skin) {_skin = skin;}
	/// ditto
	Skin skin() {return _skin;}

	/// アクティブなコンテントツールボックス。
	void actToolWin(Shell v) {_actToolWin = v;}
	Shell actToolWin() {return _actToolWin;}
	private Shell _actToolWin = null;

	private Window rOpen(Window, Main)(Main m) {
		foreach (w; _ws) {
			if ((cast(TLPData) w.getData).main is m) {
				auto shl = cast(Shell) w;
				if (shl) {
					shl.setMinimized = false;
					shl.setActive;
				} else {
					.forceFocus(w);
				}
				return cast(Window) _wos[w];
			}
		}
		return null;
	}
	private Window __open(string Pane, Window, Main, string Etc, Args ...)(Main m, Args args) {
		auto w = rOpen!(Window)(m);
		if (!w) {
			w = __open2!(Pane, Window, Main, Etc, Args)(m, args);
		}
		return w;
	}
	private Window __open2(string Pane, Window, Main, string Etc, Args ...)(Main m, Args args) {
		auto w = new Window(args);
		(cast(TLPData) w.shell.getData).main = m;
		static if (Etc.length) mixin (Etc);
		open(w, Pane);
		return w;
	}
	private class SCL : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			auto shl = cast(Composite) e.widget;
			_wos.remove(shl);
		}
	}
	private string workPaneKey() {
		return _main.dock.findPane("work")[0];
	}
	private Composite workPane() {
		if (!_main.dock) return _main.shell;
		return _main.dock.pane(workPaneKey);
	}
	Composite sidePane() {
		if (!_main.dock) return _main.shell;
		auto s = _main.dock.findPane("side");
		if (s.length) return _main.dock.pane(s[0]);
		return _main.dock.addPane(workPane, Dir.E, 3, 1, _main.dock.newCtrlKey("side"));
	}
	private Window __openArea(A, Window)(Props prop, Summary summ, A area) {
		if (!area) return null;
		return __open!("work", Window, A, "", Commons, Props, Summary, Composite, Shell, A)
			(area, this, prop, summ, workPane,
			cast(Shell) (_dataWin ? _dataWin.shell : _tableWin.shell), area);
	}
	AreaWindow openArea(Props prop, Summary summ, Area area) {
		return __openArea!(Area, AreaWindow)(prop, summ, area);
	}
	BattleWindow openArea(Props prop, Summary summ, Battle area) {
		return __openArea!(Battle, BattleWindow)(prop, summ, area);
	}
	PackageWindow openArea(Props prop, Summary summ, Package area) {
		return __openArea!(Package, PackageWindow)(prop, summ, area);
	}

	HandCardWindow openHands(Props prop, Summary summ, CastCard c) {
		auto w = rOpen!(HandCardWindow)(c);
		if (w) return w;
		return __open2!("side", HandCardWindow, CastCard, "w.refresh(args[2], m);", Commons, Props, Summary, Composite)
			(c, this, prop, summ, sidePane);
	}
	AddHandCardWindow openAddHands(Props prop, Importable summ, CastCard c, Summary toc) {
		auto w = rOpen!(AddHandCardWindow)(c);
		if (w) return w;
		return __open2!("side", AddHandCardWindow, CastCard, "", Commons, Props, Composite, Importable, CastCard, Summary)
			(c, this, prop, sidePane, summ, c, toc);
	}

	Window __openUseEvent(C, Window)(Props prop, Summary summ, C c) {
		return __open!("work", Window, C, "", Commons, Props, Summary, Composite, Shell, C)
			(c, this, prop, summ, workPane, cast(Shell) _cardWin.shell, c);
	}
	SkillEventWindow openUseEvents(Props prop, Summary summ, SkillCard c) {
		return __openUseEvent!(SkillCard, SkillEventWindow)(prop, summ, c);
	}
	ItemEventWindow openUseEvents(Props prop, Summary summ, ItemCard c) {
		return __openUseEvent!(ItemCard, ItemEventWindow)(prop, summ, c);
	}
	BeastEventWindow openUseEvents(Props prop, Summary summ, BeastCard c) {
		return __openUseEvent!(BeastCard, BeastEventWindow)(prop, summ, c);
	}
	private void show(Composite c, string pane, Dir dir, string key,
			TopLevelPanel delegate(Composite) create, string text) {
		auto shl = cast(Shell) c;
		if (shl) {
			shl.setMinimized = false;
			shl.open;
		} else {
			if (_main.dock.control(key)) {
				.forceFocus(c);
				return;
			}
			Composite p;
			string[] ps = _main.dock.findPane(pane);
			if (ps.length) {
				p = _main.dock.pane(ps[0]);
			} else {
				int l, r;
				if (dir == Dir.N || dir == Dir.W) {
					l = 1;
					r = dir == Dir.N ? 3 : 4;
				} else {
					l = dir == Dir.S ? 3 : 4;
					r = 1;
				}
				p = _main.dock.addPane(workPane, dir, l, r, _main.dock.newPaneKey(pane));
			}
			auto tlp = create(p);
			_main.dock.add(tlp.shell, text, tlp.image, key, true);
		}
	}
	private void openMain(string Key, string Pane, Dir D, Win)(Win win) {
		show(win.shell, Pane, D, Key, delegate TopLevelPanel(Composite p) {
			win.reconstruct(p);
			return win;
		}, win.title);
	}
	void openDataWin() {
		if (_dataWin) {
			openMain!("data", "data", Dir.N)(_dataWin);
		} else {
			openMain!("data", "data", Dir.N)(_tableWin);
		}
	}
	void openFlagWin() {
		openMain!("flag", "data", Dir.N)(_flagWin);
	}
	void openCardWin() {
		openMain!("card", "data", Dir.N)(_cardWin);
	}
	void openDirWin() {
		openMain!("file", "data", Dir.N)(_dirWin);
	}
	void open(TopLevelPanel tlp, string pane) {
		_ws.add(tlp.shell);
		_wos[tlp.shell] = tlp;
		tlp.shell.addDisposeListener(new CloseRemover!(Composite)(_ws, tlp.shell));
		tlp.shell.addDisposeListener(new SCL);
		auto shl = cast(Shell) tlp.shell;
		if (shl) {
			shl.open;
		} else {
			_main.dock.add(tlp.shell, tlp.title, tlp.image, _main.dock.newCtrlKey(pane), true);
		}
	}

	void setTitle(Composite comp, string text) {
		auto shell = cast(Shell) comp;
		if (shell) {
			shell.setText = text;
		} else {
			_main.dock.tabText(_main.dock.keyFromCtrl(comp), text);
		}
	}
	void close(Composite comp) {
		auto shell = cast(Shell) comp;
		if (shell) {
			shell.close;
		} else {
			_main.dock.close(_main.dock.keyFromCtrl(comp));
		}
	}
	bool singleWindowMode() {return _main.dock !is null;}

	void statusLine(Control base, string status) {
		if (!_main) return;
		TLPData tlp(Control base) {
			TLPData data = null;
			while (base && (data = cast(TLPData) base.getData) is null) {
				base = base.getParent;
			}
			return data;
		}
		auto data = tlp(base);
		if (data) {
			data.tlp.statusLine = status;
		}
		if (singleWindowMode) {
			_main.statusLine = status;
		}
	}

	bool openCWXPath(string path) {
		return _main.openCWXPath(path);
	}
	bool openFilePath(string path) {
		openDirWin;
		return _dirWin.select(path);
	}
	void replacePath(string from) {
		auto replWin = _main.openReplWin;
		if (replWin) replWin.replacePath(from);
	}

	ulong createPackage(Content baseStart) {
		openDataWin;
		if (_dataWin) {
			return _dataWin.createPackage(baseStart);
		} else {
			return _tableWin.createPackage(baseStart);
		}
	}

	private Image _wallpaper = null;
	Image wallpaper() {return _wallpaper;}
	void refreshWallpaper(Props prop) {
		try {
			string w = prop.var.etc.wallpaper;
			if (!w.length) {
				if (_wallpaper) _wallpaper.dispose();
				_wallpaper = null;
				return;
			}
			if (!cwx.utils.isabs(w)) {
				w = std.path.join(prop.parent.appPath.getDirName, w);
			}
			if (!w.length || !.exists(w)) {
				if (_wallpaper) _wallpaper.dispose();
				_wallpaper = null;
				return;
			}
			auto data = loadImage(w, false);
			if (_wallpaper) _wallpaper.dispose();
			_wallpaper = new Image(Display.getCurrent, data);
		} catch (Exception e) {
			if (_wallpaper) _wallpaper.dispose();
			_wallpaper = null;
			debugln(e);
		}
	}
}
