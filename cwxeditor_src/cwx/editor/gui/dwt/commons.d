
module cwx.editor.gui.dwt.commons;

import cwx.card;
import cwx.area;
import cwx.flag;
import cwx.summary;
import cwx.utils;
import cwx.skin;

import cwx.editor.gui.dwt.skin;
import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.utils;
import cwx.editor.gui.dwt.areaview;
import cwx.editor.gui.dwt.mainwindow;
import cwx.editor.gui.dwt.areawindow;
import cwx.editor.gui.dwt.cardwindow;
import cwx.editor.gui.dwt.eventwindow;
import cwx.editor.gui.dwt.directorywindow;
import cwx.editor.gui.dwt.datawindow;
import cwx.editor.gui.dwt.dockingfolder;

import dwt.widgets.Shell;
import dwt.widgets.Composite;
import dwt.widgets.Control;
import dwt.events.DisposeListener;
import dwt.events.DisposeEvent;
import dwt.graphics.Image;

private struct Dlg(Arg ...) {
	private void delegate(Object, Arg)[] _dlg;
	private NoS[] _noss;
	private class NoS {
		void delegate(Arg) dlg;
		void call(Object sender, Arg arg) {
			dlg(arg);
		}
	}
	void add(void delegate(Arg) dlg) {
		auto nos = new NoS;
		nos.dlg = dlg;
		_dlg ~= &nos.call;
		_noss ~= nos;
	}
	void add(void delegate(Object, Arg) dlg) {
		_dlg ~= dlg;
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

	private void delegate()[string] _act;
	private void delegate()[string] _tt;
	private string[string] _menuToTool;
	private string[string] _toolToMenu;
	void putMenuAction(string menuText, void delegate() dlg) {
		if (!(menuText in _act)) _act[menuText] = dlg;
	}
	void putMenuAction(string menuText, string ttText, void delegate() dlg) {
		putMenuAction(menuText, dlg);
		if (!(ttText in _tt)) {
			_tt[ttText] = dlg;
		}
		_menuToTool[menuText] = ttText;
		_toolToMenu[ttText] = menuText;
	}
	private bool delegate()[string] _chk;
	private bool delegate()[string] _ttChk;
	void putMenuChecked(string menuText, void delegate() dlg, bool delegate() get) {
		if (!(menuText in _act)) _act[menuText] = dlg;
		if (!(menuText in _chk)) _chk[menuText] = get;
	}
	void putMenuChecked(string menuText, string ttText, void delegate() dlg, bool delegate() get) {
		putMenuChecked(menuText, dlg, get);
		if (!(ttText in _tt)) _tt[ttText] = dlg;
		if (!(ttText in _ttChk)) _ttChk[ttText] = get;
		_menuToTool[menuText] = ttText;
		_toolToMenu[ttText] = menuText;
	}
	string toolToMenu(string ttText) {
		auto p = ttText in _toolToMenu;
		return p ? *p : null;
	}
	string menuToTool(string menuText) {
		auto p = menuText in _menuToTool;
		return p ? *p : null;
	}
	void delegate() menuAction(string menuText) {
		auto p = menuText in _act;
		return p ? *p : null;
	}
	void delegate() toolAction(string ttText) {
		auto p = ttText in _tt;
		return p ? *p : null;
	}
	bool delegate() menuChecked(string menuText) {
		auto p = menuText in _chk;
		return p ? *p : null;
	}
	bool delegate() toolChecked(string ttText) {
		auto p = ttText in _ttChk;
		return p ? *p : null;
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
	Dlg!() replText;

	Dlg!(Area) refArea;
	Dlg!(Area) delArea;
	Dlg!(Battle) refBattle;
	Dlg!(Battle) delBattle;
	Dlg!(Package) refPackage;
	Dlg!(Package) delPackage;

	Dlg!(Importable) closeAdds;

	private HashSet!(Composite) _ws;
	private Object[Composite] _wos;
	this() {
		_ws = new HashSet!(Composite);
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
	
	void closeAll() {
		foreach (w; _ws.toArray) {
			close(w);
		}
		assert (_ws.size == 0);
	}

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
		auto shl = cast(Shell) win.shell;
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

	bool openCWXPath(string path) {
		return _main.openCWXPath(path);
	}
}
