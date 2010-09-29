
module cwx.editor.gui.dwt.replacedialog;

import cwx.area;
import cwx.summary;
import cwx.event;
import cwx.coupon;
import cwx.utils;
import cwx.card;
import cwx.motion;
import cwx.flag;
import cwx.usecounter;
import cwx.path;
import cwx.background;

import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.utils;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.commons;

import std.string;

import dwt.widgets.Shell;
import dwt.widgets.Text;
import dwt.widgets.Button;
import dwt.widgets.Composite;
import dwt.widgets.Control;
import dwt.widgets.Group;
import dwt.widgets.Label;
import dwt.widgets.MessageBox;
import dwt.widgets.Table;
import dwt.widgets.TableItem;
import dwt.events.SelectionAdapter;
import dwt.events.SelectionEvent;
import dwt.events.MouseAdapter;
import dwt.events.MouseEvent;
import dwt.events.KeyAdapter;
import dwt.events.KeyEvent;
import dwt.events.DisposeListener;
import dwt.events.DisposeEvent;
import dwt.layout.GridLayout;
import dwt.layout.GridData;
import dwt.layout.RowLayout;
import dwt.layout.RowData;
import dwt.graphics.Image;

/// テキスト検索と置換を行うダイアログ。
class ReplaceDialog {
private:
	Commons _comm;
	Props _prop;
	Summary _summ;

	Shell _win;

	Text _from;
	Text _to;

	/// 貼り紙
	Button _summary;
	/// シナリオ出現条件
	Button _rCoupon;
	/// メッセージ
	Button _msg;
	/// カード名
	Button _cardName;
	/// カード解説
	Button _cardDesc;
	/// イベントテキスト
	Button _event;
	/// フラグ/ステップ
	Button _flag;
	/// クーポン
	Button _coupon;
	/// ゴシップ
	Button _gossip;
	/// 終了印
	Button _end;
	/// エリア/バトル/パッケージ名
	Button _area;
	/// キーコード
	Button _keyCode;

	Table _result;
	Label _status;

	bool summary() {return _summary.getSelection;}
	bool msg() {return _msg.getSelection;}
	bool cardName() {return _cardName.getSelection;}
	bool cardDesc() {return _cardDesc.getSelection;}
	bool event() {return _event.getSelection;}
	bool flag() {return _flag.getSelection;}
	bool coupon() {return _coupon.getSelection;}
	bool gossip() {return _gossip.getSelection;}
	bool end() {return _end.getSelection;}
	bool area() {return _area.getSelection;}
	bool keyCode() {return _keyCode.getSelection;}
	class ML : MouseAdapter {
		public override void mouseDoubleClick(MouseEvent e) {
			if (_result.isFocusControl && e.button == 1) {
				openPath;
			}
		}
	}
	class KL : KeyAdapter {
		public override void keyPressed(KeyEvent e) {
			if (_result.isFocusControl && e.character == DWT.CR) {
				openPath;
			}
		}
	}
	class KLS : KeyAdapter {
		public override void keyPressed(KeyEvent e) {
			if (_from.isFocusControl && e.character == DWT.CR) {
				search;
			}
		}
	}
	class KLR : KeyAdapter {
		public override void keyPressed(KeyEvent e) {
			if (_to.isFocusControl && e.character == DWT.CR) {
				replace;
			}
		}
	}
public:
	this(Commons comm, Props prop, Shell shell, Summary summ) {
		_comm = comm;
		_prop = prop;
		_summ = summ;
		_win = new Shell(shell, DWT.SHELL_TRIM);
		_win.setText = _prop.msgs.dlgTitReplaceText;
		_win.setImage = prop.images.app;
		setup;
		_win.open;
		_win.setActive;
	}
	Shell widget() {
		return _win;
	}
	void summary(Summary summ) {
		_summ = summ;
		_result.removeAll;
	}

	private void setup() {
		auto area = _win;
		area.setLayout = new GridLayout(2, false);
		{
			auto grp = new Group(area, DWT.NONE);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.horizontalSpan = 2;
			grp.setLayoutData = gd;
			grp.setText = _prop.msgs.replText;
			grp.setLayout = new GridLayout(2, false);
			auto lf = new Label(grp, DWT.NONE);
			lf.setText = _prop.msgs.replTextFrom;
			_from = new Text(grp, DWT.BORDER);
			gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.widthHint = _prop.var.etc.nameWidth;
			_from.setLayoutData = gd;
			_from.addKeyListener(new KLS);
			auto lt = new Label(grp, DWT.NONE);
			lt.setText = _prop.msgs.replTextTo;
			_to = new Text(grp, DWT.BORDER);
			_to.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			_to.addKeyListener(new KLR);
		}
		{
			auto grp = new Group(area, DWT.NONE);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.horizontalSpan = 2;
			gd.widthHint = _prop.var.etc.searchResultTableWidth;
			grp.setLayoutData = gd;
			grp.setText = _prop.msgs.replTextTarget;
			grp.setLayout = new CenterLayout;
			auto rl = new RowLayout(DWT.HORIZONTAL);
			rl.wrap = true;
			rl.pack = false;
			grp.setLayout = rl;
			Button createB(string text) {
				auto b = new Button(grp, DWT.CHECK);
				b.setText = text;
				return b;
			}
			_summary = createB(_prop.msgs.replTextSummary);
			_msg = createB(_prop.msgs.replTextMessage);
			_cardName = createB(_prop.msgs.replTextCardName);
			_cardDesc = createB(_prop.msgs.replTextCardDesc);
			_event = createB(_prop.msgs.replTextEventText);
			_flag = createB(_prop.msgs.replTextFlagAndStep);
			_coupon = createB(_prop.msgs.replTextCoupon);
			_gossip = createB(_prop.msgs.replTextGossip);
			_end = createB(_prop.msgs.replTextEndScenario);
			_area = createB(_prop.msgs.replTextAreaName);
			_keyCode = createB(_prop.msgs.replTextKeyCode);
		}
		{
			_result = new Table(area, DWT.BORDER | DWT.SINGLE | DWT.FULL_SELECTION | DWT.V_SCROLL);
			auto gd = new GridData(GridData.FILL_HORIZONTAL | GridData.FILL_VERTICAL);
			gd.horizontalSpan = 2;
			gd.widthHint = _prop.var.etc.searchResultTableWidth;
			gd.heightHint = _prop.var.etc.searchResultTableHeight;
			_result.setLayoutData = gd;
			_result.addMouseListener = new ML;
			_result.addKeyListener = new KL;
			new FullTableColumn(_result, DWT.NONE);
		}
		{
			_status = new Label(area, DWT.NONE);
			_status.setText = _prop.msgs.searchResult(0);
			_status.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			auto comp = new Composite(area, DWT.NONE);
			auto gl = new GridLayout(3, true);
			gl.marginWidth = 0;
			gl.marginHeight = 0;
			comp.setLayout = gl;
			Button createButton(string text, void delegate() push) {
				auto b = new Button(comp, DWT.PUSH);
				b.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				b.setText = text;
				auto sa = new class SelectionAdapter {
					private void delegate() push;
					override void widgetSelected(SelectionEvent e) {
						push();
					}
				};
				sa.push = push;
				b.addSelectionListener(sa);
				return b;
			}
			createButton(_prop.msgs.search, &search);
			createButton(_prop.msgs.replace, &replace);
			createButton(_prop.msgs.replaceExit, &exit);
		}
		_summary.setSelection = _prop.var.etc.replaceTextSummary;
		_msg.setSelection = _prop.var.etc.replaceTextMessage;
		_cardName.setSelection = _prop.var.etc.replaceTextCardName;
		_cardDesc.setSelection = _prop.var.etc.replaceTextCardDescription;
		_event.setSelection = _prop.var.etc.replaceTextEventText;
		_flag.setSelection = _prop.var.etc.replaceTextFlagAndStep;
		_coupon.setSelection = _prop.var.etc.replaceTextCoupon;
		_gossip.setSelection = _prop.var.etc.replaceTextGossip;
		_end.setSelection = _prop.var.etc.replaceTextEndScenario;
		_area.setSelection = _prop.var.etc.replaceTextAreaName;
		_keyCode.setSelection = _prop.var.etc.replaceTextKeyCode;
		_win.addDisposeListener(new DL);
		auto cs = _win.computeSize(DWT.DEFAULT, DWT.DEFAULT);
		auto size = _prop.var.replaceDlg;
		if (size.width != DWT.DEFAULT) cs.x = size.width;
		if (size.height != DWT.DEFAULT) cs.x = size.height;
		_win.setSize = cs;
	}
	private class DL : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			if (!_win.getMaximized) {
				auto s = _win.getSize;
				_prop.var.replaceDlg.width = s.x;
				_prop.var.replaceDlg.height = s.y;
			}
			_prop.var.etc.replaceTextSummary = _summary.getSelection;
			_prop.var.etc.replaceTextMessage = _msg.getSelection;
			_prop.var.etc.replaceTextCardName = _cardName.getSelection;
			_prop.var.etc.replaceTextCardDescription = _cardDesc.getSelection;
			_prop.var.etc.replaceTextEventText = _event.getSelection;
			_prop.var.etc.replaceTextFlagAndStep = _flag.getSelection;
			_prop.var.etc.replaceTextCoupon = _coupon.getSelection;
			_prop.var.etc.replaceTextGossip = _gossip.getSelection;
			_prop.var.etc.replaceTextEndScenario = _end.getSelection;
			_prop.var.etc.replaceTextAreaName = _area.getSelection;
			_prop.var.etc.replaceTextKeyCode = _keyCode.getSelection;
		}
	}
	private void search() {
		_replMode = false;
		replaceImpl;
	}
	private void replace() {
		_replMode = true;
		replaceImpl;
	}
	private void replaceImpl() {
		string from = _from.getText;
		if (from.length == 0) return;
		string to = _to.getText;
		if (from == to) return;
		_result.removeAll;
		size_t count = 0;
		bool sr = false;
		if (summary) {
			sr |= repl(null, &_summ.scenarioName, &_summ.scenarioName, count);
			sr |= repl(null, &_summ.desc, &_summ.desc, count);
		}
		if (coupon) {
			sr |= replRqCoupons!(Summary)(null, _summ, count);
		}
		if (sr) {
			addResult(_summ);
		}
		foreach (cc; _summ.casts) {
			bool r = replCard!(CastCard)(null, cc, count);
			if (coupon) {
				auto coupons = cc.coupons.dup;
				foreach (ref cp; coupons) {
					r |= repl(null, {return cp.name;},
						(string t) {cp = new Coupon(t, cp.value);}, count);
				}
				cc.coupons = coupons;
			}
			if (r) {
				addResult(cc);
			}
			foreach (c; cc.skills) {
				replCard(c, c, count);
				replEvent(c, count);
			}
			foreach (c; cc.items) {
				replCard(c, c, count);
				replEvent(c, count);
			}
			foreach (c; cc.beasts) {
				replCard(c, c, count);
				replEvent(c, count);
			}
		}
		foreach (c; _summ.skills) {
			replCard(c, c, count);
			replEvent(c, count);
		}
		foreach (c; _summ.items) {
			replCard(c, c, count);
			replEvent(c, count);
		}
		foreach (c; _summ.beasts) {
			replCard(c, c, count);
			replEvent(c, count);
		}
		foreach (c; _summ.infos) {
			replCard(c, c, count);
		}
		foreach (a; _summ.areas) {
			if (area) {
				repl(a, &a.name, &a.name, count);
			}
			foreach (c; a.cards) {
				replCard(c, c, count);
			}
			replEvent(a, count);
		}
		foreach (b; _summ.battles) {
			if (area) {
				repl(b, &b.name, &b.name, count);
			}
			replEvent(b, count);
		}
		foreach (p; _summ.packages) {
			if (area) {
				repl(p, &p.name, &p.name, count);
			}
			replEvent(p, count);
		}
		if (flag) {
			void replFS(FlagDir dir) {
				foreach (f; dir.flags) {
					string old = f.name;
					replFlagName(dir, f, count);
					_summ.useCounter.change(toFlagId(old), toFlagId(f.name));
					bool r = false;
					r |= repl(null, &f.on, &f.on, count);
					r |= repl(null, &f.off, &f.off, count);
					if (r) addResult(f);
				}
				foreach (s; dir.steps) {
					string old = s.name;
					replFlagName(dir, s, count);
					_summ.useCounter.change(toStepId(old), toStepId(s.name));
					bool r = false;
					foreach (i, v; s.values) {
						r |= repl(null, {return v;}, (string t) {s.setValue(i, t);}, count);
					}
					if (r) addResult(s);
				}
				foreach (c; dir.subDirs) {
					replFS(c);
				}
			}
			replFS(_summ.flagDirRoot);
		}
		if (count > 0) {
			_comm.refUseCount.call;
			_comm.replText.call;
		}
		if (_replMode) {
			_status.setText = _prop.msgs.replTextResult(count);
		} else {
			_status.setText = _prop.msgs.searchResult(count);
		}
	}
	private void exit() {
		_win.close;
	}
	private bool _replMode = false;

	private void openPath() {
		auto itms = _result.getSelection;
		if (itms.length) {
			auto path = (cast(CWXPath) itms[0].getData).cwxPath;
			try {
				if (_comm.openCWXPath(path)) {
					_win.setActive;
					return;
				}
			} catch (Exception e) {
				debugln(e);
			}
			MessageBox.showWarning(_prop.msgs.cwxPathOpenError(path), _prop.msgs.dlgTitWarning, _win);
		}
	}
	private void addResult(CWXPath path) {
		auto itm = new TableItem(_result, DWT.NONE);
		Image img = null;
		string text = "*Error*";
		auto sum = cast(Summary) path;
		if (sum) {
			img = _prop.images.summary;
			text = _prop.msgs.summary;
		}
		auto bgi = cast(BgImage) path;
		if (bgi) {
			img = _prop.images.backs;
			text = _prop.msgs.searchResultBgImage(bgi);
		}
		auto are = cast(Area) path;
		if (are) {
			img = _prop.images.area;
			text = _prop.msgs.searchResultIds(are);
		}
		auto bat = cast(Battle) path;
		if (bat) {
			img = _prop.images.battle;
			text = _prop.msgs.searchResultIds(bat);
		}
		auto pac = cast(Package) path;
		if (pac) {
			img = _prop.images.packages;
			text = _prop.msgs.searchResultIds(pac);
		}
		auto cas = cast(CastCard) path;
		if (cas) {
			img = _prop.images.casts;
			text = _prop.msgs.searchResultIds(cas);
		}
		auto ski = cast(SkillCard) path;
		if (ski) {
			img = _prop.images.skill;
			text = _prop.msgs.searchResultIds(ski);
		}
		auto ite = cast(ItemCard) path;
		if (ite) {
			img = _prop.images.item;
			text = _prop.msgs.searchResultIds(ite);
		}
		auto bea = cast(BeastCard) path;
		if (bea) {
			img = _prop.images.beast;
			text = _prop.msgs.searchResultIds(bea);
		}
		auto inf = cast(InfoCard) path;
		if (inf) {
			img = _prop.images.info;
			text = _prop.msgs.searchResultIds(inf);
		}
		auto con = cast(Content) path;
		if (con) {
			img = _prop.images.content(con.type);
			text = _prop.msgs.contentText(con, _summ);
		}
		auto fla = cast(Flag) path;
		if (fla) {
			img = _prop.images.flag;
			text = _prop.msgs.searchResultFlags(fla);
		}
		auto ste = cast(Step) path;
		if (ste) {
			img = _prop.images.step;
			text = _prop.msgs.searchResultFlags(ste);
		}
		auto fld = cast(FlagDir) path;
		if (fld) {
			img = _prop.images.flagDir;
			text = _prop.msgs.searchResultFlags(fld);
		}
		auto eve = cast(EventTree) path;
		if (eve) {
			img = _prop.images.eventTree;
			text = _prop.msgs.searchResultEventTree(eve);
		}
		auto men = cast(MenuCard) path;
		if (men) {
			img = _prop.images.cards;
			text = _prop.msgs.searchResultMenuCard(men);
		}
		auto ene = cast(EnemyCard) path;
		if (ene) {
			img = _prop.images.cards;
			text = _prop.msgs.searchResultEnemyCard(ene, _summ);
		}
		assert (img);
		itm.setImage = img;
		itm.setText = text;
		itm.setData = cast(Object) path;
	}
	private bool repl(CWXPath path, string delegate() get, void delegate(string) set, ref size_t count) {
		string from = _from.getText;
		string to = _to.getText;
		string text = get();
		auto c = .count(text, from);
		count += c;
		if (c > 0) {
			if (_replMode) set(.replace(text, from, to));
			if (path) addResult(path);
			return true;
		}
		return false;
	}

	private bool replFlagName(F)(FlagDir parent, F flag, ref size_t count) {
		string from = _from.getText;
		string to = _to.getText;
		string text = flag.name;
		auto c = .count(text, from);
		count += c;
		if (c > 0) {
			if (_replMode) flag.name = parent.validName(.replace(text, from, to));
			addResult(flag);
			return true;
		}
		return false;
	}

	private bool replRqCoupons(C)(CWXPath path, C targ, ref size_t count) {
		auto coupons = targ.rCoupons;
		bool r = false;
		foreach (ref cp; coupons) {
			r |= repl(null, {return cp;}, (string t) {cp = t;}, count);
		}
		if (r) {
			if (_replMode) targ.rCoupons = coupons;
			if (path) addResult(targ);
			return true;
		}
		return false;
	}

	private bool replKeyCode(C)(CWXPath path, C targ, ref size_t count) {
		if (keyCode) {
			auto kcs = targ.keyCodes.dup;
			bool r = false;
			foreach (ref kc; kcs) {
				r |= repl(null, {return kc;}, (string t) {kc = t;}, count);
			}
			if (r) {
				if (_replMode) targ.keyCodes = kcs;
				if (path) addResult(path);
				return true;
			}
		}
		return false;
	}

	private bool replCard(C)(CWXPath path, C card, ref size_t count) {
		string from = _from.getText;
		string to = _to.getText;
		bool r = false;
		if (cardName) {
			r |= repl(null, &card.name, &card.name, count);
		}
		if (cardDesc) {
			r |= repl(null, &card.desc, &card.desc, count);
		}
		static if (is (C : EffectCard)) {
			r |= replKeyCode!(C)(null, card, count);
		}
		if (r && path) {
			addResult(path);
		}
		return r;
	}
	private void replEvent(EventTreeOwner owner, ref size_t count) {
		string from = _from.getText;
		string to = _to.getText;
		void replE(Content eo, Content e) {
			assert (!eo || eo.detail.owner);
			bool r = false;
			if (event && (!eo || eo.type == CType.TALK_MESSAGE || eo.type == CType.TALK_DIALOG)) {
				r |= repl(null, &e.name, &e.name, count);
			}
			if (coupon) {
				r |= repl(null, &e.coupon, &e.coupon, count);
			}
			if (gossip) {
				r |= repl(null, &e.gossip, &e.gossip, count);
			}
			if (end) {
				r |= repl(null, &e.completeStamp, &e.completeStamp, count);
			}
			if (msg) {
				r |= repl(null, &e.text, &e.text, count);
				auto dlgs = e.dialogs;
				foreach (dlg; dlgs) {
					if (msg) {
						r |= repl(null, &dlg.text, &dlg.text, count);
					}
					if (coupon) {
						r |= replRqCoupons!(typeof(dlg))(null, dlg, count);
					}
				}
			}
			foreach (m; e.motions) {
				if (m.beast) {
					r |= replCard!(BeastCard)(null, m.beast, count);
					replEvent(m.beast, count);
				}
			}
			if (r) {
				addResult(e);
			}
			if (e.detail.owner) {
				foreach (child; e.next) {
					replE(e, child);
				}
			}
		}
		foreach (et; owner.trees) {
			foreach (e; et.starts) {
				replE(null, e);
			}
			replKeyCode(et, et, count);
		}
	}
}
