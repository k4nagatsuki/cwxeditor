
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

import dwt.widgets.Shell;

private struct Dlg(Arg ...) {
	private void delegate(Object, Arg)[] _dlg;
	private NoS[] _noss;
	class NoS {
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

	this() {
		_aws = new typeof(_aws);
		_bws = new typeof(_bws);
		_pws = new typeof(_pws);
		_hws = new typeof(_hws);
		_sews = new typeof(_sews);
		_iews = new typeof(_iews);
		_bews = new typeof(_bews);
	}
	private MainWindow _main;
	private Shell _areaWin, _cardWin;
	void baseShell(MainWindow main, Shell areaWin, Shell cardWin) {
		_main = main;
		_areaWin = areaWin;
		_cardWin = cardWin;
	}
	void closeAll() {
		foreach (w; _aws.toArray) {
			(cast(AreaWindow) w).shell.close;
		}
		assert (_aws.size == 0);
		foreach (w; _bws.toArray) {
			(cast(BattleWindow) w).shell.close;
		}
		assert (_bws.size == 0);
		foreach (w; _pws.toArray) {
			(cast(PackageWindow) w).shell.close;
		}
		assert (_pws.size == 0);
		foreach (w; _hws.toArray) {
			(cast(HandCardWindow) w).shell.close;
		}
		assert (_hws.size == 0);
		foreach (w; _sews.toArray) {
			(cast(SkillEventWindow) w).shell.close;
		}
		assert (_sews.size == 0);
		foreach (w; _iews.toArray) {
			(cast(ItemEventWindow) w).shell.close;
		}
		assert (_iews.size == 0);
		foreach (w; _bews.toArray) {
			(cast(BeastEventWindow) w).shell.close;
		}
		assert (_bews.size == 0);
	}

	/// アクティブなコンテントツールボックス。
	void actToolWin(Shell v) {_actToolWin = v;}
	Shell actToolWin() {return _actToolWin;}
	private Shell _actToolWin = null;

	private HashSet!(AreaWindow) _aws;
	private HashSet!(BattleWindow) _bws;
	private HashSet!(PackageWindow) _pws;
	private Window __openArea(A, Window)(Props prop, Summary summ, A area, HashSet!(Window) ws) {
		foreach (w; ws) {
			if (w.eventTreeOwner == area) {
				w.shell.setMinimized = false;
				w.shell.setActive;
				return w;
			}
		}
		auto w = new Window(this, prop, summ, _main.shell, _areaWin, area);
		w.shell.addShellListener(new CloseRemover!(Window)(ws, w));
		ws.add(w);
		w.shell.open;
		return w;
	}
	AreaWindow openArea(Props prop, Summary summ, Area area) {
		if (!area) return null;
		return __openArea!(Area, AreaWindow)(prop, summ, area, _aws);
	}
	BattleWindow openArea(Props prop, Summary summ, Battle area) {
		if (!area) return null;
		return __openArea!(Battle, BattleWindow)(prop, summ, area, _bws);
	}
	PackageWindow openArea(Props prop, Summary summ, Package area) {
		if (!area) return null;
		return __openArea!(Package, PackageWindow)(prop, summ, area, _pws);
	}

	private HashSet!(HandCardWindow) _hws;
	HandCardWindow openHands(Props prop, Summary summ, CastCard c) {
		foreach (w; _hws) {
			if (w.owner is c) {
				w.shell.setMinimized = false;
				w.shell.setActive;
				return w;
			}
		}
		auto hcw = new HandCardWindow(this, prop, summ, _main.shell);
		_hws.add(hcw);
		hcw.shell.addShellListener(new CloseRemover!(HandCardWindow)(_hws, hcw));
		hcw.refresh(summ, c);
		hcw.open;
		return hcw;
	}
	private HashSet!(SkillEventWindow) _sews;
	private HashSet!(ItemEventWindow) _iews;
	private HashSet!(BeastEventWindow) _bews;
	Window __openUseEvent(C, Window)(Props prop, Summary summ, C c, HashSet!(Window) ews) {
		foreach (w; ews) {
			if (w.eventTreeOwner is c) {
				w.shell.setMinimized = false;
				w.shell.setActive;
				return w;
			}
		}
		auto ew = new Window(this, prop, summ, _main.shell, _cardWin, c);
		ews.add(ew);
		ew.shell.addShellListener(new CloseRemover!(Window)(ews, ew));
		ew.shell.open;
		return ew;
	}
	SkillEventWindow openUseEvents(Props prop, Summary summ, SkillCard c) {
		return __openUseEvent!(SkillCard, SkillEventWindow)(prop, summ, c, _sews);
	}
	ItemEventWindow openUseEvents(Props prop, Summary summ, ItemCard c) {
		return __openUseEvent!(ItemCard, ItemEventWindow)(prop, summ, c, _iews);
	}
	BeastEventWindow openUseEvents(Props prop, Summary summ, BeastCard c) {
		return __openUseEvent!(BeastCard, BeastEventWindow)(prop, summ, c, _bews);
	}
	bool openCWXPath(string path) {
		return _main.openCWXPath(path);
	}
}
