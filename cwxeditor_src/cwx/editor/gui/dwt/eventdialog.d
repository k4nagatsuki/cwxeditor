
module cwx.editor.gui.dwt.eventdialog;

import cwx.summary;
import cwx.area;
import cwx.background;
import cwx.card;
import cwx.utils;
import cwx.event;
import cwx.types;
import cwx.flag;
import cwx.features;
import cwx.usecounter;
import cwx.skin;

import cwx.editor.gui.sound;

import cwx.editor.gui.dwt.areaview;
import cwx.editor.gui.dwt.skin;
import cwx.editor.gui.dwt.utils;
import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.materialselect;
import cwx.editor.gui.dwt.motionview;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.splitpane;

import std.conv;
import std.math;
import std.path;

import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Combo;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Group;
import org.eclipse.swt.widgets.List;
import org.eclipse.swt.widgets.Text;
import org.eclipse.swt.widgets.Spinner;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableColumn;
import org.eclipse.swt.widgets.TableItem;
import org.eclipse.swt.widgets.ToolBar;
import org.eclipse.swt.widgets.Scale;
import org.eclipse.swt.widgets.Menu;
import org.eclipse.swt.widgets.MenuItem;
import org.eclipse.swt.custom.CTabFolder;
import org.eclipse.swt.custom.CTabItem;
import org.eclipse.swt.custom.CLabel;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.MouseListener;
import org.eclipse.swt.events.MouseEvent;
import org.eclipse.swt.events.KeyListener;
import org.eclipse.swt.events.KeyEvent;
import org.eclipse.swt.graphics.Font;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.layout.FillLayout;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.GridData;

abstract class EventDialog : AbsDialog {
	private Commons _comm;
	private Props _prop;
	private Summary _summ;
	private Content _parent;
	private Content _evt;

	private class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			_comm.delContent.remove(&delContent);
			_comm.refSkin.remove(&refSkin);
		}
	}
	private void delContent(Content c) {
		if ((_evt && _evt.isDescendant(c)) || (_parent && _parent.isDescendant(c))) {
			forceCancel;
		}
	}

	this (Commons comm, Props prop, Shell shell, Summary summ, CType type, Content parent, Content evt, bool resizable, DSize size, bool eClose) in {
		assert (!evt || evt.type is type);
		assert (summ);
	} body {
		super (prop, shell, false, prop.msgs.dlgTitContent(type), prop.images.content(type), resizable, size, true);
		enterClose = eClose;
		_comm = comm;
		_prop = prop;
		_summ = summ;
		_parent = parent;
		_evt = evt;
		_comm.delContent.add(&delContent);
		_comm.refSkin.add(&refSkin);
		getShell.addDisposeListener(new Dispose);
	}

	Content event() {
		return _evt;
	}
	protected Commons comm() {return _comm;}
	protected Props prop() {return _prop;}
	protected Summary summ() {return _summ;}
	protected Content evt() {return _evt;}
	protected void evt(Content evt) {_evt = evt;}

	protected void refSkin() {}
}

/// エリア・バトル・パッケージ・キャスト・情報の選択を行うダイアログ。
class AreaSelectDialog(CType Type, A, string Areas) : EventDialog {
private:
	Table _list;

	static if (Type == CType.CHANGE_AREA) {
		Combo _ts;
		Spinner _tsSpeed;
		Transition[int] _tsTbl;
	}
	void refreshList() {
		auto summary = _summ;
		auto sels = _list.getSelection;
		ulong id = 0;
		if (sels.length) {
			id = (cast(A) sels[0].getData).id;
		} else if (_evt) {
			static if (Type == CType.CHANGE_AREA) {
				id = _evt.area;
			} else static if (Type == CType.START_BATTLE) {
				id = _evt.battle;
			} else static if (Type == CType.CALL_PACKAGE || Type == CType.LINK_PACKAGE) {
				id = _evt.packages;
			} else static if (Type == CType.BRANCH_CAST || Type == CType.GET_CAST || Type == CType.LOSE_CAST) {
				id = _evt.casts;
			} else static if (Type == CType.BRANCH_INFO || Type == CType.GET_INFO || Type == CType.LOSE_INFO) {
				id = _evt.info;
			} else {
				static assert (0);
			}
		}
		_list.removeAll();
		foreach (i, a; mixin (Areas)) {
			auto itm = new TableItem(_list, SWT.NONE);
			itm.setData = a;
			static if (Type == CType.CHANGE_AREA) {
				itm.setImage(0, _prop.images.area);
			} else static if (Type == CType.START_BATTLE) {
				itm.setImage(0, _prop.images.battle);
			} else static if (Type == CType.CALL_PACKAGE || Type == CType.LINK_PACKAGE) {
				itm.setImage(0, _prop.images.packages);
			} else static if (Type == CType.BRANCH_CAST || Type == CType.GET_CAST || Type == CType.LOSE_CAST) {
				itm.setImage(0, _prop.images.casts);
			} else static if (Type == CType.BRANCH_INFO || Type == CType.GET_INFO || Type == CType.LOSE_INFO) {
				itm.setImage(0, _prop.images.info);
			} else {
				static assert (0);
			}
			itm.setText(0, to!(string)(a.id));
			itm.setText(1, a.name);
			if (i == 0) _list.select = i;
			if (id == a.id) _list.select = i;
		}
	}
	void refA(A a) {refreshList();}
	void delA(A a) {
		auto summary = _summ;
		auto areas = mixin (Areas);
		if (areas.length) {
			refreshList();
		} else {
			forceCancel();
		}
	}
	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			static if (is(A : Area)) {
				_comm.refArea.remove(&refA);
				_comm.delArea.remove(&delA);
			} else static if (is(A : Battle)) {
				_comm.refBattle.remove(&refA);
				_comm.delBattle.remove(&delA);
			} else static if (is(A : Package)) {
				_comm.refPackage.remove(&refA);
				_comm.delPackage.remove(&delA);
			} else static if (is(A : CastCard)) {
				_comm.refCast.remove(&refA);
				_comm.delCast.remove(&delA);
			} else static if (is(A : InfoCard)) {
				_comm.refInfo.remove(&refA);
				_comm.delInfo.remove(&delA);
			} else static assert (0);
		}
	}
	protected override void refSkin() {
		refreshTS();
	}
	void refreshTS() {
		static if (Type == CType.CHANGE_AREA) {
			_ts.setEnabled = !_summ.legacy;
			_tsSpeed.setEnabled = !_summ.legacy;
		}
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) {
		super (comm, prop, shell, summ, Type, parent, evt, true, prop.var.selEvtDlg, true);
	}
protected:
	override void setup(Composite area) {
		area.setLayout = new GridLayout(1, false);
		_list = new Table(area, SWT.SINGLE | SWT.FULL_SELECTION | SWT.BORDER | SWT.V_SCROLL);
		auto idCol = new TableColumn(_list, SWT.NONE);
		saveColumnWidth!("prop.var.etc.idColumn")(_prop, idCol);
		auto nameCol = new FullTableColumn(_list, SWT.NONE);
		auto gd = new GridData(GridData.FILL_BOTH);
		gd.widthHint = _prop.var.etc.nameTableWidth;
		gd.heightHint = _prop.var.etc.nameTableHeight;
		_list.setLayoutData = gd;
		refreshList();
		static if (Type == CType.CHANGE_AREA) {
			{
				auto comp = new Composite(area, SWT.NONE);
				comp.setLayoutData = new GridData(GridData.HORIZONTAL_ALIGN_END);
				comp.setLayout = zeroMarginGridLayout(3, false);
				auto lt = new Label(comp, SWT.NONE);
				lt.setText = _prop.msgs.transition;
				_ts = new Combo(comp, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
				auto tgd = new GridData;
				tgd.horizontalSpan = 2;
				_ts.setLayoutData(tgd);
				_ts.setVisibleItemCount = 20;
				foreach (i, t; ALL_TRANSITION) {
					_ts.add(_prop.msgs.transition(t));
					_tsTbl[i] = t;
					if (_evt && t == _evt.transition) _ts.select(i);
				}
				auto ls = new Label(comp, SWT.NONE);
				ls.setText = _prop.msgs.transitionSpeed;
				_tsSpeed = new Spinner(comp, SWT.BORDER);
				_tsSpeed.setMaximum = Content.transitionSpeed_max;
				_tsSpeed.setMinimum = Content.transitionSpeed_min;
				auto hint = new Label(comp, SWT.NONE);
				hint.setText = _prop.msgs.rangeHint
					(Content.transitionSpeed_min,
					Content.transitionSpeed_max);
			}
			if (_evt) {
				_tsSpeed.setSelection = _evt.transitionSpeed;
			} else {
				_ts.select = 0;
				_tsSpeed.setSelection = _prop.looks.transitionSpeedDef;
			}
			refreshTS();
		}
		_list.showSelection;
		static if (is(A : Area)) {
			_comm.refArea.add(&refA);
			_comm.delArea.add(&delA);
		} else static if (is(A : Battle)) {
			_comm.refBattle.add(&refA);
			_comm.delBattle.add(&delA);
		} else static if (is(A : Package)) {
			_comm.refPackage.add(&refA);
			_comm.delPackage.add(&delA);
		} else static if (is(A : CastCard)) {
			_comm.refCast.add(&refA);
			_comm.delCast.add(&delA);
		} else static if (is(A : InfoCard)) {
			_comm.refInfo.add(&refA);
			_comm.delInfo.add(&delA);
		} else static assert (0);
		_list.addDisposeListener(new Dispose);
	}

	override bool apply() {
		auto id = (cast(A) _list.getSelection[0].getData).id;
		if (!_evt) {
			_evt = new Content(Type, "");
		}
		static if (Type == CType.CHANGE_AREA) {
			auto ts = _tsTbl[_ts.getSelectionIndex];
			uint tsSpeed = _tsSpeed.getSelection;
			_evt.area = id;
			_evt.transition = ts;
			_evt.transitionSpeed = tsSpeed;
		} else static if (Type == CType.START_BATTLE) {
			_evt.battle = id;
		} else static if (Type == CType.CALL_PACKAGE || Type == CType.LINK_PACKAGE) {
			_evt.packages = id;
		} else static if (Type == CType.BRANCH_CAST || Type == CType.GET_CAST || Type == CType.LOSE_CAST) {
			_evt.casts = id;
		} else static if (Type == CType.BRANCH_INFO || Type == CType.GET_INFO || Type == CType.LOSE_INFO) {
			_evt.info = id;
		} else {
			static assert (0);
		}
		return true;
	}
}

/// スタートコンテントの選択を行うダイアログ。
class StartSelectDialog(CType Type) : EventDialog {
private:
	Content[] _starts;

	Table _list;

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt, Content[] starts) in {
		foreach (s; starts) {
			assert (s.type == CType.START);
		}
	} body {
		_starts = starts;
		super (comm, prop, shell, summ, Type, parent, evt, true, prop.var.selEvtDlg, true);
	}

protected:
	override void setup(Composite area) {
		area.setLayout = new GridLayout(1, false);
		_list = new Table(area, SWT.SINGLE | SWT.FULL_SELECTION | SWT.BORDER | SWT.V_SCROLL);
		auto nameCol = new FullTableColumn(_list, SWT.NONE);
		auto gd = new GridData(GridData.FILL_BOTH);
		gd.widthHint = _prop.var.etc.nameTableWidth;
		gd.heightHint = _prop.var.etc.nameTableHeight;
		_list.setLayoutData = gd;
		foreach (i, s; _starts) {
			auto itm = new TableItem(_list, SWT.NONE);
			itm.setData = s;
			itm.setImage(0, _prop.images.content(CType.START));
			itm.setText(0, s.name);
			if (i == 0) _list.select = i;
			if (_evt) {
				if (_evt.start == s.name) _list.select = i;
			}
		}
		_list.showSelection;
	}

	override bool apply() {
		auto name = (cast(Content) _list.getSelection[0].getData).name;
		if (!_evt) _evt = new Content(Type, "");
		_evt.start = name;
		return true;
	}
}

/// クリアイベントの設定を行うダイアログ。
class ClearEventDialog : EventDialog {
private:
	Button _mark;
	Button _unmark;

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) {
		super (comm, prop, shell, summ, CType.END, parent, evt, false, null, enterClose);
	}
protected:
	override void setup(Composite area) {
		auto cl = new CenterLayout;
		cl.fillHorizontal = true;
		area.setLayout = cl;
		auto grp = new Group(area, SWT.NONE);
		grp.setText = _prop.msgs.afterClear;
		grp.setLayout = new CenterLayout(SWT.VERTICAL | SWT.HORIZONTAL, 0);
		auto comp = new Composite(grp, SWT.NONE);
		comp.setLayout = new GridLayout(1, true);
		_mark = new Button(comp, SWT.RADIO);
		_mark.setText = _prop.msgs.afterClearEndMark;
		_unmark = new Button(comp, SWT.RADIO);
		_unmark.setText = _prop.msgs.afterClearNoEndMark;

		if (_evt) {
			if (_evt.complete) {
				_mark.setSelection = true;
			} else {
				_unmark.setSelection = true;
			}
		} else {
			_mark.setSelection = true;
		}
	}

	override bool apply() {
		if (!_evt) {
			_evt = new Content(CType.END, "");
		}
		_evt.complete = _mark.getSelection;
		return true;
	}
}

/// 取得を除くクーポン関連イベントの設定を行うダイアログ。
class CouponEventDialog(CType Type, bool EditValue) : EventDialog {
private:
	Button[Range] _range;
	Combo _name;
	static if (EditValue) {
		Spinner _value;
	}

	protected override void refSkin() {
		refreshCoupons();
	}
	void refreshCoupons() {
		auto c = _name.getText;
		_name.removeAll();
		addCastCoupons(_name, prop, true, comm.skin.legacyName);
		_name.select = 0;
		if (c.length && -1 == _name.indexOf(c)) {
			_name.add(c, 0);
		}
		_name.setText = c;
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) {
		super (comm, prop, shell, summ, Type, parent, evt, true, prop.var.couponEvtDlg, true);
	}
protected:
	override void setup(Composite area) {
		area.setLayout = new GridLayout(2, false);
		auto skin = _comm.skin;
		{
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData = new GridData(GridData.FILL_VERTICAL);
			grp.setText = _prop.msgs.range;
			grp.setLayout = new GridLayout(1, true);
			foreach (r; RANGE_MEMBER) {
				auto radio = new Button(grp, SWT.RADIO);
				radio.setLayoutData = new GridData(GridData.FILL_BOTH);
				radio.setText = _prop.msgs.range(r);
				_range[r] = radio;
			}
		}
		{
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData = new GridData(GridData.FILL_BOTH);
			auto cl = new CenterLayout(SWT.VERTICAL, 0);
			cl.fillHorizontal = true;
			grp.setLayout = cl;
			grp.setText = _prop.msgs.couponName;
			{
				auto comp = new Composite(grp, SWT.NONE);
				comp.setLayout = new GridLayout(3, false);
				{
					_name = new Combo(comp, SWT.BORDER | SWT.DROP_DOWN);
					_name.setVisibleItemCount = 20;
					auto gd = new GridData(GridData.FILL_HORIZONTAL);
					gd.horizontalSpan = 3;
					gd.widthHint = _prop.var.etc.nameWidth;
					_name.setLayoutData = gd;
					refreshCoupons();
				}
				static if (EditValue) {
					auto ll = new Label(comp, SWT.RIGHT);
					ll.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
					ll.setText = _prop.msgs.couponValue;
					_value = new Spinner(comp, SWT.BORDER);
					_value.setLayoutData = new GridData(GridData.HORIZONTAL_ALIGN_CENTER);
					_value.setMaximum = Content.couponValue_max;
					_value.setMinimum = Content.couponValue_min;
					auto lr = new Label(comp, SWT.LEFT);
					lr.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
					lr.setText = _prop.msgs.couponValueRange(Content.couponValue_max);
				}
			}
		}

		if (_evt) {
			_range[_evt.range].setSelection = true;
			_name.setText = _evt.coupon;
			_name.add(_evt.coupon, 0);
			static if (EditValue) {
				_value.setSelection = _evt.couponValue;
			}
		} else {
			_range[Range.SELECTED].setSelection = true;
			static if (EditValue) {
				_value.setSelection = 0;
			}
		}
	}

	override bool apply() {
		if (!_evt) _evt = new Content(Type, "");
		foreach (range, radio; _range) {
			if (radio.getSelection) {
				_evt.range = range;
				_evt.coupon = _name.getText;
				static if (EditValue) {
					_evt.couponValue = _value.getSelection;
				}
				break;
			}
		}
		return true;
	}
}

/// 終了印とゴシップの設定を行うダイアログ。
private class OneTextEventDialog(CType Type, string Name, string Get, string Set) : EventDialog {
private:
	Text _text;

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) {
		super (comm, prop, shell, summ, Type, parent, evt, true, prop.var.inputEvtDlg, true);
	}
protected:
	override void setup(Composite area) {
		area.setLayout = new GridLayout(1, false);
		{
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData = new GridData(GridData.FILL_BOTH);
			grp.setText = mixin (Name);
			auto cl = new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0);
			cl.fillHorizontal = true;
			grp.setLayout = cl;
			auto comp = new Composite(grp, SWT.NONE);
			comp.setLayout = new GridLayout(1, true);

			_text = new Text(comp, SWT.BORDER);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.widthHint = _prop.var.etc.nameWidth;
			_text.setLayoutData = gd;
		}

		if (_evt) {
			_text.setText = mixin (Get);
		}
	}

	override bool apply() {
		if (!_evt) _evt = new Content(Type, "");
		string text = _text.getText;
		mixin (Set);
		return true;
	}
}

template GossipEventDialog(CType Type) {
	alias OneTextEventDialog!(Type, "_prop.msgs.gossipName",
		"_evt.gossip", "_evt.gossip = text;") GossipEventDialog;
}

template EndEventDialog(CType Type) {
	alias OneTextEventDialog!(Type, "_prop.msgs.endName",
		"_evt.completeStamp", "_evt.completeStamp = text;") EndEventDialog;
}

/// 背景変更イベントの設定を行うダイアログ。
class BgImagesDialog : EventDialog {
private:
	AbstractArea _refTarget;
	Combo _ts;
	Spinner _tsSpeed;
	Transition[int] _tsTbl;

	BgImageContainer _cont;

	BgImagesView _view;

	protected override void refSkin() {
		refreshTS();
	}
	void refreshTS() {
		_ts.setEnabled = !_summ.legacy;
		_tsSpeed.setEnabled = !_summ.legacy;
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt, AbstractArea refTarget) {
		_refTarget = refTarget;
		super (comm, prop, shell, summ, CType.CHANGE_BG_IMAGE, parent, evt, true, prop.var.bgImagesDlg, false);

		BgImage[] bgImages;
		if (evt) {
			foreach (b; evt.backs) {
				bgImages ~= b.dup;
			}
		}
		_cont = new BgImageContainer(bgImages);
	}
protected:
	override void setup(Composite area) {
		area.setLayout = new GridLayout(1, false);
		auto skin = _comm.skin;
		{
			_view = createBgImagesViewAndMenu(_comm, _prop, _summ, _cont, area, _refTarget);
			mod(_view);
			_view.setLayoutData = new GridData(GridData.FILL_BOTH);
		}
		{
			auto comp = new Composite(area, SWT.NONE);
			comp.setLayoutData = new GridData(GridData.HORIZONTAL_ALIGN_END);
			comp.setLayout = zeroMarginGridLayout(5, false);
			auto lt = new Label(comp, SWT.NONE);
			lt.setText = _prop.msgs.transition;
			_ts = new Combo(comp, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
			mod(_ts);
			_ts.setVisibleItemCount = 20;
			foreach (i, t; ALL_TRANSITION) {
				_ts.add(_prop.msgs.transition(t));
				_tsTbl[i] = t;
				if (_evt && t == _evt.transition) _ts.select(i);
			}
			auto ls = new Label(comp, SWT.NONE);
			ls.setText = _prop.msgs.transitionSpeed;
			_tsSpeed = new Spinner(comp, SWT.BORDER);
			mod(_tsSpeed);
			_tsSpeed.setMaximum = Content.transitionSpeed_max;
			_tsSpeed.setMinimum = Content.transitionSpeed_min;
			auto hint = new Label(comp, SWT.NONE);
			hint.setText = _prop.msgs.rangeHint
				(Content.transitionSpeed_min,
				Content.transitionSpeed_max);
		}
		refreshTS();

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) {
			_tsSpeed.setSelection = _evt.transitionSpeed;
		} else {
			_ts.select = 0;
			_tsSpeed.setSelection = _prop.looks.transitionSpeedDef;
		}
	}

	override bool apply() {
		if (!_evt) _evt = new Content(CType.CHANGE_BG_IMAGE, "");
		_evt.backs = _cont.backs;
		auto ts = _tsTbl[_ts.getSelectionIndex];
		uint tsSpeed = _tsSpeed.getSelection;
		_evt.transition = ts;
		_evt.transitionSpeed = tsSpeed;
		return true;
	}
}

/// BGMイベントの設定を行うダイアログ。
class BgmDialog : EventDialog {
private:
	MaterialSelect!(MtType.BGM, Combo, List) _msel;
	Button _play;
	string _playing;

	class PlayBGM : SelectionAdapter, KeyListener, MouseListener {
		private void play() {
			if (_play.getSelection) {
				auto path = _msel.filePath;
				if (path.length > 0) {
					_play.setToolTipText = _prop.msgs.stopBGM(getBaseName(path));
					_play.setImage = _prop.images.stopBGM;
					_playing = path;
					playBGMCW(_prop, path, _summ.legacy);
				} else {
					_play.setSelection = false;
					_playing = null;
				}
			} else {
				stopBGM;
				_play.setToolTipText = _prop.msgs.playBGM;
				_play.setImage = _prop.images.playBGM;
			}
		}
		override void mouseUp(MouseEvent e) {}
		override void mouseDown(MouseEvent e) {}
		override void mouseDoubleClick(MouseEvent e) {
			if (e.button == 1) {
				auto path = _msel.filePath;
				_play.setSelection = path != _playing;
				play;
			}
		}
		override void keyReleased(KeyEvent e) {}
		override void keyPressed(KeyEvent e) {
			if (e.character == SWT.CR) {
				auto path = _msel.filePath;
				_play.setSelection = path != _playing;
				play;
			}
		}
		override void widgetSelected(SelectionEvent e) {
			play;
		}
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) {
		super (comm, prop, shell, summ, CType.PLAY_BGM, parent, evt, true, prop.var.soundEvtDlg, true);
	}
protected:
	override void setup(Composite area) {
		area.setLayout = new GridLayout(4, false);
		{
			auto skin = _comm.skin;
			_msel = new MaterialSelect!(MtType.BGM, Combo, List)
				(_comm, _prop, _summ, null, [_prop.msgs.bgmStop]);
			_msel.createDirsCombo(area).setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			mod(_msel);

			_play = new Button(area, SWT.TOGGLE);
			_play.setLayoutData = new GridData;
			_play.setToolTipText = _prop.msgs.playBGM;
			_play.setImage = _prop.images.playBGM;
			auto pbgm = new PlayBGM;
			_play.addSelectionListener(pbgm);
			_play.addDisposeListener(new StopBGM);
			_msel.createRefreshButton(area, false).setLayoutData = new GridData;
			_msel.createDirectoryButton(area, false).setLayoutData = new GridData;

			auto gd = new GridData(GridData.FILL_BOTH);
			gd.horizontalSpan = 4;
			gd.widthHint = _prop.var.etc.nameTableWidth;
			gd.heightHint = _prop.var.etc.nameTableHeight;
			auto list = _msel.createFileList(area);
			list.setLayoutData = gd;
			list.addMouseListener(pbgm);
			list.addKeyListener(pbgm);
		}
		ignoreMod = true;
		scope (exit) ignoreMod = false;
		_msel.path = _evt ? _evt.bgmPath : "";
	}

	override bool apply() {
		if (!_evt) _evt = new Content(CType.PLAY_BGM, "");
		_evt.bgmPath = _msel.path;
		return true;
	}
}

/// 効果音イベントの設定を行うダイアログ。
class SeDialog : EventDialog {
private:
	MaterialSelect!(MtType.SE, Combo, List) _msel;

	class PlaySE : SelectionAdapter, KeyListener, MouseListener {
		private void play() {
			auto path = _msel.filePath;
			if (path.length > 0) {
				playSECW(_prop, path, _summ.legacy);
			}
		}
		override void mouseUp(MouseEvent e) {}
		override void mouseDown(MouseEvent e) {}
		override void mouseDoubleClick(MouseEvent e) {
			if (e.button == 1) {
				play;
			}
		}
		override void keyReleased(KeyEvent e) {}
		override void keyPressed(KeyEvent e) {
			if (e.character == SWT.CR) {
				play;
			}
		}
		override void widgetSelected(SelectionEvent e) {
			play;
		}
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) {
		super (comm, prop, shell, summ, CType.PLAY_SOUND, parent, evt, true, prop.var.soundEvtDlg, true);
	}
protected:
	override void setup(Composite area) {
		area.setLayout = new GridLayout(5, false);
		{
			auto skin = _comm.skin;
			_msel = new MaterialSelect!(MtType.SE, Combo, List)
				(_comm, _prop, _summ, null, []);
			_msel.createDirsCombo(area).setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			mod(_msel);

			auto stop = new Button(area, SWT.PUSH);
			stop.setLayoutData = new GridData;
			stop.setToolTipText = _prop.msgs.stopSound;
			stop.setImage = _prop.images.stopSound;
			auto sse = new StopSE;
			stop.addSelectionListener(sse);
			stop.addDisposeListener(sse);
			auto play = new Button(area, SWT.PUSH);
			play.setToolTipText = _prop.msgs.playSound;
			play.setImage = _prop.images.playSound;
			auto pse = new PlaySE;
			play.addSelectionListener(pse);
			_msel.createRefreshButton(area, false).setLayoutData = new GridData;
			_msel.createDirectoryButton(area, false).setLayoutData = new GridData;

			auto gd = new GridData(GridData.FILL_BOTH);
			gd.horizontalSpan = 5;
			gd.widthHint = _prop.var.etc.nameTableWidth;
			gd.heightHint = _prop.var.etc.nameTableHeight;
			auto list = _msel.createFileList(area);
			list.setLayoutData = gd;
			list.addKeyListener(pse);
			list.addMouseListener(pse);
		}
		ignoreMod = true;
		scope (exit) ignoreMod = false;
		_msel.path = _evt ? _evt.soundPath : "";
	}

	override bool apply() {
		if (!_evt) _evt = new Content(CType.PLAY_SOUND, "");
		_evt.soundPath = _msel.path;
		return true;
	}
}

/// 数値の設定を行うダイアログ。
private class NumericEventDialog(CType Type, string Name, string Max, string Get, string Set, uint Min = 0, uint Def = 0) : EventDialog {
private:
	Spinner _value;

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) {
		super (comm, prop, shell, summ, Type, parent, evt, false, null, true);
	}
protected:
	private class PM : SelectionAdapter {
		private int _v;
		this (int v) {_v = v;}
		override void widgetSelected(SelectionEvent e) {
			_value.setSelection = _value.getSelection + _v;
		}
	}
	override void setup(Composite area) {
		area.setLayout = new GridLayout(1, false);
		{
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData = new GridData(GridData.FILL_BOTH);
			grp.setText = mixin (Name);
			grp.setLayout = new CenterLayout(SWT.VERTICAL | SWT.HORIZONTAL, 0);
			auto comp = new Composite(grp, SWT.NONE);
			_value = new Spinner(comp, SWT.BORDER);
			mod(_value);
			_value.setMinimum = Min;
			_value.setMaximum = mixin (Max);
			comp.setLayout = new GridLayout(10 <= _value.getMaximum ? 3 : 2, false);
			if (10 <= _value.getMaximum) {
				auto tools = new Composite(comp, SWT.NONE);
				tools.setLayout = new FillLayout(SWT.HORIZONTAL);
				for (int i = 5; i <= _value.getMaximum && i < 10000; i*= i == 5 ? 2 : 10) {
					auto ts = new Composite(tools, SWT.NONE);
					ts.setLayout = new FillLayout(SWT.VERTICAL);
					void createB(int i) {
						auto r = new Button(ts, SWT.PUSH);
						auto fontd = r.getFont.getFontData;
						foreach (fd; fontd) {
							fd.height /= 1.5;
						}
						r.setFont = new Font(Display.getCurrent, fontd);
						r.addDisposeListener(new class DisposeListener {
							override void widgetDisposed(DisposeEvent e) {
								(cast(Control) e.widget).getFont.dispose;
							}
						});
						r.setText = i < 0 ? to!(string)(i) : "+" ~ to!(string)(i);
						r.addSelectionListener(new PM(i));
					}
					createB(i);
					createB(-i);
				}
			}
			auto l = new Label(comp, SWT.NONE);
			l.setText = _prop.msgs.rangeHint(Min, _value.getMaximum);
		}

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) {
			_value.setSelection = mixin (Get);
		} else {
			_value.setSelection = Def;
		}
	}

	override bool apply() {
		if (!_evt) _evt = new Content(Type, "");
		int value = _value.getSelection;
		mixin (Set);
		return true;
	}
}

alias NumericEventDialog!(CType.WAIT, "_prop.msgs.waitName",
		"Content.wait_max", "_evt.wait", "_evt.wait = value;") WaitEventDialog;

alias NumericEventDialog!(CType.BRANCH_RANDOM, "_prop.msgs.randomName",
		"100", "_evt.percent", "_evt.percent = value;", 0, 50) BrRandomEventDialog;

alias NumericEventDialog!(CType.BRANCH_PARTY_NUMBER, "_prop.msgs.partyNumName",
		"_prop.looks.partyMax", "_evt.partyNumber", "_evt.partyNumber = value;", 1, 1) BrNumEventDialog;

template MoneyEventDialog(CType Type) {
	alias NumericEventDialog!(Type, "_prop.msgs.moneyName",
		"Content.money_max", "_evt.money", "_evt.money = value;") MoneyEventDialog;
}

/// 効果イベントの設定を行うダイアログ。
class EffectDialog : EventDialog {
private:
	MotionView _mview;
	Spinner _lev;
	Combo _se;
	Scale _sucRate;
	Button[EffectType] _effTyp;
	Button[Resist] _res;
	Button[CardVisual] _vis;
	Button[Target.M] _targ;

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) {
		super (comm, prop, shell, summ, CType.EFFECT, parent, evt, true, prop.var.effEvtDlg, true);
	}
protected:
	override void setup(Composite area) {
		auto cl = new CenterLayout;
		cl.fillHorizontal = true;
		cl.fillVertical = true;
		area.setLayout = cl;
		auto tabf = new CTabFolder(area, SWT.BORDER);
		auto tabM = new CTabItem(tabf, SWT.NONE);
		tabM.setText = _prop.msgs.motion;
		{
			_mview = new MotionView(_comm, _prop, _summ, tabf);
			mod(_mview);
			tabM.setControl = _mview;
		}
		auto tabS = new CTabItem(tabf, SWT.NONE);
		tabS.setText = _prop.msgs.settings;
		{
			auto comp = new Composite(tabf, SWT.NONE);
			tabS.setControl = comp;
			comp.setLayout = new GridLayout(2, false);
			{
				auto comp2 = new Composite(comp, SWT.NONE);
				comp2.setLayoutData = new GridData(GridData.FILL_BOTH);
				comp2.setLayout = zeroMarginGridLayout(1, true);
				{
					auto grp = new Group(comp2, SWT.NONE);
					grp.setText = _prop.msgs.targetLevel;
					grp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
					grp.setLayout = new GridLayout(2, false);
					_lev = new Spinner(grp, SWT.BORDER);
					mod(_lev);
					_lev.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
					_lev.setMinimum = Content.signedLevel_min;
					_lev.setMaximum = Content.signedLevel_max;
					auto l = new Label(grp, SWT.NONE);
					l.setText = _prop.msgs.rangeHint(_lev.getMinimum, _lev.getMaximum);
				}
				{
					auto grp = new Group(comp2, SWT.NONE);
					grp.setText = _prop.msgs.elementProps;
					grp.setLayoutData = new GridData(GridData.FILL_BOTH);
					grp.setLayout = new GridLayout(2, true);
					foreach (i, eff; [EffectType.PHYSIC, EffectType.MAGIC,
							EffectType.MAGICAL_PHYSIC, EffectType.PHYSICAL_MAGIC,
							EffectType.NONE]) {
						auto radio = new Button(grp, SWT.RADIO);
						mod(radio);
						auto gd = new GridData(GridData.FILL_BOTH);
						if (2 <= i) {
							gd.horizontalSpan = 2;
						}
						radio.setLayoutData = gd;
						radio.setText = _prop.msgs.effectType(eff);
						_effTyp[eff] = radio;
					}
				}
				{
					auto grp = new Group(comp2, SWT.NONE);
					grp.setText = _prop.msgs.resistProps;
					grp.setLayoutData = new GridData(GridData.FILL_BOTH);
					grp.setLayout = new GridLayout(2, true);
					foreach (res; [Resist.AVOID, Resist.RESIST, Resist.UNFAIL]) {
						auto radio = new Button(grp, SWT.RADIO);
						mod(radio);
						radio.setText = _prop.msgs.resist(res);
						radio.setLayoutData = new GridData(GridData.FILL_BOTH);
						_res[res] = radio;
					}
				}
			}
			{
				auto comp2 = new Composite(comp, SWT.NONE);
				comp2.setLayoutData = new GridData(GridData.FILL_BOTH);
				comp2.setLayout = zeroMarginGridLayout(2, false);
				{
					auto grp = new Group(comp2, SWT.NONE);
					grp.setText = _prop.msgs.effectVisual;
					grp.setLayoutData = new GridData(GridData.FILL_BOTH);
					grp.setLayout = new GridLayout(1, false);
					foreach (v; [CardVisual.NONE, CardVisual.REVERSE, CardVisual.HORIZONTAL, CardVisual.VERTICAL]) {
						auto radio = new Button(grp, SWT.RADIO);
						mod(radio);
						radio.setLayoutData = new GridData(GridData.FILL_BOTH);
						radio.setText = _prop.msgs.cardVisual(v);
						_vis[v] = radio;
					}
				}
				{
					auto grp = new Group(comp2, SWT.NONE);
					grp.setText = _prop.msgs.judgeTarget;
					grp.setLayoutData = new GridData(GridData.FILL_BOTH);
					grp.setLayout = new GridLayout(1, true);
					foreach (m; [Target.M.SELECTED, Target.M.RANDOM, Target.M.PARTY]) {
						auto radio = new Button(grp, SWT.RADIO);
						mod(radio);
						radio.setText = _prop.msgs.target(m);
						radio.setLayoutData = new GridData(GridData.FILL_BOTH);
						_targ[m] = radio;
					}
				}
				{
					auto grp = new Group(comp2, SWT.NONE);
					grp.setText = _prop.msgs.se;
					auto gd = new GridData(GridData.FILL_BOTH);
					gd.horizontalSpan = 2;
					grp.setLayoutData = gd;
					grp.setLayout = new GridLayout(1, true);
					createDefSoundCombo(_prop, _summ, _comm.skin, grp, _se)
						.setLayoutData = new GridData(GridData.FILL_BOTH);
					mod(_se);
				}
				{
					auto gd = new GridData(GridData.FILL_BOTH);
					gd.horizontalSpan = 2;
					createSuccessRateScale(_prop, comp2, _sucRate).setLayoutData = gd;
					mod(_sucRate);
				}
			}
		}
		tabf.setLayoutData = area.computeSize(SWT.DEFAULT, SWT.DEFAULT);
		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) {
			_mview.motions = _evt.motions;
			_lev.setSelection = _evt.signedLevel;
			int sei = _se.indexOf(getBaseName(_evt.soundPath));
			_se.select = sei >= 0 ? sei : 0;
			_sucRate.setSelection = _evt.successRate + Content.successRate_max;
			_effTyp[_evt.effectType].setSelection = true;
			_res[_evt.resist].setSelection = true;
			_vis[_evt.cardVisual].setSelection = true;
			_targ[_evt.targetNS.m].setSelection = true;
		} else {
			_mview.motions = [];
			_lev.setSelection = 0;
			_se.select = 0;
			_sucRate.setSelection = Content.successRate_max + Content.successRate_max;
			_effTyp[EffectType.NONE].setSelection = true;
			_res[Resist.UNFAIL].setSelection = true;
			_vis[CardVisual.NONE].setSelection = true;
			_targ[Target.M.SELECTED].setSelection = true;
		}
	}

	override bool apply() {
		if (!_evt) _evt = new Content(CType.EFFECT, "");
		_evt.motions = _mview.motions;
		_evt.signedLevel = _lev.getSelection;
		_evt.soundPath = _se.getSelectionIndex > 0 ? _se.getText : "";
		_evt.successRate = cast(int) _sucRate.getSelection - Content.successRate_max;
		_evt.effectType = getRadioValue!(EffectType)(_effTyp);
		_evt.resist = getRadioValue!(Resist)(_res);
		_evt.cardVisual = getRadioValue!(CardVisual)(_vis);
		_evt.targetNS = Target(getRadioValue!(Target.M)(_targ), false);
		return true;
	}
}

/// フラグ・ステップの選択・設定を行うダイアログ。
private class FlagStepDialog(CType Type, F, bool SelValue) : EventDialog {
private:
	FlagDir _root;
	F[] _data;

	SplitPane _sash;
	List _flags;
	List _values;

	static if (SelValue) {
		int _sel;
	}

	void refreshValues(bool manual) {
		static if (SelValue) {
			if (manual && _values.getItemCount && _sel == _flags.getSelectionIndex) {
				_values.select = 0;
				return;
			}
			_sel = _flags.getSelectionIndex;
		}
		F flag = _data[_flags.getSelectionIndex];
		static if (SelValue) {
			int sel = _values.getSelectionIndex;
		}
		_values.removeAll;
		static if (is (F == Flag)) {
			_values.add(flag.on);
			_values.add(flag.off);
		} else static if (is (F == Step)) {
			foreach (val; flag.values) {
				_values.add(val);
			}
		} else {
			static assert (0);
		}
		static if (SelValue) {
			if (sel < 0) sel = 0;
			static if (is (F == Step)) {
				if (sel >= flag.values.length) sel = flag.values.length - 1;
			}
			_values.select = sel;
		}
	}
	class SListener : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			refreshValues(true);
		}
	}
	void refreshList() {
		string sel = "";
		auto ix = _flags.getSelectionIndex;
		if (-1 != ix) {
			sel = _data[ix].path;
		}
		static if (is (F == Flag)) {
			if (!sel && _evt) {
				sel = _evt.flag;
			}
			auto flags = _root.allFlags;
		} else static if (is (F == Step)) {
			if (!sel && _evt) {
				sel = _evt.step;
			}
			auto flags = _root.allSteps;
		} else {
			static assert (0);
		}
		_flags.removeAll();
		_data.length = flags.length;
		foreach (i, flag; flags) {
			auto path = flag.path;
			_flags.add(path);
			_data[i] = flag;
			if (0 == i) _flags.select = i;
			if (path == sel) _flags.select = i;
		}
	}
	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			static if (is(F : Flag)) {
				_comm.refFlag.remove(&refFS);
				_comm.delFlag.remove(&delFS);
			} else static if (is(F : Step)) {
				_comm.refStep.remove(&refFS);
				_comm.delStep.remove(&delFS);
			} else static assert (0);
		}
	}
	void refFS(F f) {
		int sel = _values.getSelectionIndex;
		refreshValues(false);
		_values.select = sel;
	}
	void delFS(F f) {
		static if (is(F : Flag)) {
			if (!_root.allFlags.length) {
				forceCancel();
				return;
			}
		} else static if (is(F : Step)) {
			if (!_root.allSteps.length) {
				forceCancel();
				return;
			}
		} else static assert (0);
		refreshList();
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt, FlagDir root) {
		_root = root;
		super (comm, prop, shell, summ, Type, parent, evt, true, prop.var.flagEvtDlg, true);
		closeEvent ~= {
			auto ws = _sash.getWeights;
			_prop.var.etc.flagEventSashL = ws[0];
			_prop.var.etc.flagEventSashR = ws[1];
		};
	}
protected:
	override void setup(Composite area) {
		area.setLayout = new GridLayout(1, true);
		_sash = new SplitPane(area, SWT.HORIZONTAL);
		_sash.setLayoutData = new GridData(GridData.FILL_BOTH);
		auto left = new Composite(_sash, SWT.NONE);
		left.setLayout = zeroGridLayout(1);
		auto right = new Composite(_sash, SWT.NONE);
		right.setLayout = zeroGridLayout(1);
		{
			auto l1 = new CLabel(left, SWT.NONE);
			auto l2 = new CLabel(right, SWT.NONE);
			static if (is (F == Flag)) {
				l1.setText = _prop.msgs.flag;
				l1.setImage = _prop.images.flag;
				l2.setText = _prop.msgs.flagValue;
			} else static if (is (F == Step)) {
				l1.setText = _prop.msgs.step;
				l1.setImage = _prop.images.step;
				l2.setText = _prop.msgs.stepValue;
			} else {
				static assert (0);
			}
		}
		{
			_flags = new List(left, SWT.SINGLE | SWT.BORDER | SWT.V_SCROLL);
			mod(_flags);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.heightHint = _prop.var.etc.nameTableHeight;
			_flags.setLayoutData = gd;
			refreshList();
			_flags.addSelectionListener(new SListener);
		}
		{
			_values = new List(right, SWT.SINGLE | SWT.BORDER | SWT.V_SCROLL);
			mod(_values);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.heightHint = _prop.var.etc.nameTableHeight;
			_values.setLayoutData = gd;
			_values.setEnabled = SelValue;
		}
		static if (is(F : Flag)) {
			_comm.refFlag.add(&refFS);
			_comm.delFlag.add(&delFS);
		} else static if (is(F : Step)) {
			_comm.refStep.add(&refFS);
			_comm.delStep.add(&delFS);
		} else static assert (0);
		_flags.addDisposeListener(new Dispose);

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) {
			static if (is (F == Flag)) {
				int index = _flags.indexOf(_evt.flag);
			} else static if (is (F == Step)) {
				int index = _flags.indexOf(_evt.step);
			} else {
				static assert (0);
			}
			_flags.select = index >= 0 ? index : 0;
			_flags.showSelection;
			refreshValues(false);
			static if (SelValue) {
				static if (is (F == Flag)) {
					_values.select = _evt.flagValue ? 0 : 1;
				} else static if (is (F == Step)) {
					_values.select = _evt.stepValue;
				} else {
					static assert (0);
				}
				_sel = _flags.getSelectionIndex;
			}
		} else {
			_flags.select = 0;
			refreshValues(false);
			static if (SelValue) _sel = 0;
		}
		_sash.setWeights([_prop.var.etc.flagEventSashL, _prop.var.etc.flagEventSashR]);
	}

	override bool apply() {
		if (!_evt) _evt = new Content(Type, "");
		static if (is (F == Flag)) {
			_evt.flag = _flags.getSelection[0];
			static if (SelValue) {
				_evt.flagValue = _values.getSelectionIndex == 0;
			}
		} else static if (is (F == Step)) {
			_evt.step = _flags.getSelection[0];
			static if (SelValue) {
				_evt.stepValue = _values.getSelectionIndex;
			}
		} else {
			static assert (0);
		}
		return true;
	}
}

alias FlagStepDialog!(CType.BRANCH_FLAG, Flag, false) BrFlagDialog;
alias FlagStepDialog!(CType.BRANCH_MULTI_STEP, Step, false) BrStepNDialog;
alias FlagStepDialog!(CType.BRANCH_STEP, Step, true) BrStepULDialog;
alias FlagStepDialog!(CType.SET_FLAG, Flag, true) FlagSetDialog;
alias FlagStepDialog!(CType.SET_STEP, Step, true) StepSetDialog;
alias FlagStepDialog!(CType.SET_STEP_UP, Step, false) StepPlusDialog;
alias FlagStepDialog!(CType.SET_STEP_DOWN, Step, false) StepMinusDialog;
alias FlagStepDialog!(CType.REVERSE_FLAG, Flag, false) FlagRDialog;
alias FlagStepDialog!(CType.CHECK_FLAG, Flag, false) FlagJudgeDialog;

/// メンバ選択分岐の設定を行うダイアログ。
class BrMemberDialog : EventDialog {
private:
	// FIXME: KeyTypeにboolを使えない？
	Button[] _all;
	Button[] _random;

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) {
		super (comm, prop, shell, summ, CType.BRANCH_ABILITY, parent, evt, false, null, true);
	}
protected:
	override void setup(Composite area) {
		area.setLayout = new GridLayout(2, false);
		void createR(string title, string trueText, string falseText, ref Button[] btns) {
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData = new GridData(GridData.FILL_BOTH);
			grp.setLayout = new CenterLayout;
			grp.setText = title;
			auto comp = new Composite(grp, SWT.NONE);
			comp.setLayout = zeroMarginGridLayout(1, true);
			auto btnT = new Button(comp, SWT.RADIO);
			mod(btnT);
			btnT.setText = trueText;
			auto btnF = new Button(comp, SWT.RADIO);
			mod(btnF);
			btnF.setText = falseText;
			btns.length = 2;
			btns[0] = btnT;
			btns[1] = btnF;
		}
		createR(_prop.msgs.selectMember, _prop.msgs.activeMember, _prop.msgs.allMember, _all);
		createR(_prop.msgs.selectMethod, _prop.msgs.manualMethod, _prop.msgs.randomMethod, _random);

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) {
			_all[_evt.targetAll ? 1 : 0].setSelection = true;
			_random[_evt.random ? 1 : 0].setSelection = true;
		} else {
			_all[0].setSelection = true;
			_random[0].setSelection = true;
		}
	}

	override bool apply() {
		if (!_evt) _evt = new Content(CType.BRANCH_SELECT, "");
		_evt.targetAll = _all[1].getSelection;
		_evt.random = _random[1].getSelection;
		return true;
	}
}

/// 能力判定分岐の設定を行うダイアログ。
class BrPowerDialog : EventDialog {
private:
	Spinner _lev;
	Button[Target.M] _targ;
	// FIXME: KeyTypeにboolを使えない？
	Button[2] _sleep;
	Button[Physical] _phy;
	Button[Mental] _mtl;

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) {
		super (comm, prop, shell, summ, CType.BRANCH_ABILITY, parent, evt, false, null, true);
	}
protected:
	override void setup(Composite area) {
		area.setLayout = new GridLayout(3, false);
		{
			auto comp = new Composite(area, SWT.NONE);
			comp.setLayout = zeroMarginGridLayout(1, true);
			{
				auto grp = new Group(comp, SWT.NONE);
				grp.setText = _prop.msgs.targetLevel;
				grp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				grp.setLayout = new GridLayout(2, false);
				_lev = new Spinner(grp, SWT.BORDER);
				mod(_lev);
				_lev.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				_lev.setMinimum = Content.signedLevel_min;
				_lev.setMaximum = Content.signedLevel_max;
				auto l = new Label(grp, SWT.NONE);
				l.setText = _prop.msgs.rangeHint(_lev.getMinimum, _lev.getMaximum);
			}
			{
				auto grp = new Group(comp, SWT.NONE);
				grp.setText = _prop.msgs.judgeTarget;
				grp.setLayoutData = new GridData(GridData.FILL_BOTH);
				grp.setLayout = new GridLayout(1, true);
				foreach (m; [Target.M.SELECTED, Target.M.RANDOM, Target.M.PARTY]) {
					auto radio = new Button(grp, SWT.RADIO);
					mod(radio);
					radio.setText = _prop.msgs.target(m);
					radio.setLayoutData = new GridData(GridData.FILL_BOTH);
					_targ[m] = radio;
				}
			}
			{
				auto grp = new Group(comp, SWT.NONE);
				grp.setText = _prop.msgs.judgeSleep;
				grp.setLayoutData = new GridData(GridData.FILL_BOTH);
				grp.setLayout = new GridLayout(1, true);
				_sleep[1] = new Button(grp, SWT.RADIO);
				mod(_sleep[1]);
				_sleep[1].setText = _prop.msgs.sleepDisabled;
				_sleep[0] = new Button(grp, SWT.RADIO);
				mod(_sleep[0]);
				_sleep[0].setText = _prop.msgs.sleepEnabled;
			}
		}
		{
			auto grp = new Group(area, SWT.NONE);
			grp.setText = _prop.msgs.aptPhysical;
			grp.setLayoutData = new GridData(GridData.FILL_BOTH);
			auto cl = new CenterLayout(SWT.HORIZONTAL, 0);
			cl.fillVertical = true;
			grp.setLayout = cl;
			auto comp2 = new Composite(grp, SWT.NONE);
			comp2.setLayout = new GridLayout(1, true);
			foreach (phy; [Physical.DEX, Physical.AGL, Physical.INT,
					Physical.STR, Physical.VIT, Physical.MIN]) {
				auto radio = new Button(comp2, SWT.RADIO);
				mod(radio);
				radio.setLayoutData = new GridData(GridData.FILL_VERTICAL);
				radio.setText = _prop.msgs.physical(phy);
				_phy[phy] = radio;
			}
		}
		{
			auto grp = new Group(area, SWT.NONE);
			grp.setText = _prop.msgs.aptMental;
			grp.setLayoutData = new GridData(GridData.FILL_BOTH);
			auto cl = new CenterLayout(SWT.HORIZONTAL, 0);
			cl.fillVertical = true;
			grp.setLayout = cl;
			auto comp2 = new Composite(grp, SWT.NONE);
			comp2.setLayout = new GridLayout(2, true);
			static const Ms = [Mental.AGGRESSIVE, Mental.UNAGGRESSIVE,
				Mental.CHEERFUL, Mental.UNCHEERFUL,
				Mental.BRAVE, Mental.UNBRAVE, Mental.CAUTIOUS, Mental.UNCAUTIOUS,
				Mental.TRICKISH, Mental.UNTRICKISH];
			foreach (i, m; Ms) {
				auto radio = new Button(comp2, SWT.RADIO);
				mod(radio);
				radio.setLayoutData = new GridData(GridData.FILL_BOTH);
				radio.setText = _prop.msgs.mental(m);
				_mtl[m] = radio;
			}
		}
		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) {
			_lev.setSelection = _evt.signedLevel;
			_targ[_evt.targetS.m].setSelection = true;
			_sleep[_evt.targetS.sleep ? 0 : 1].setSelection = true;
			_phy[_evt.physical].setSelection = true;
			_mtl[_evt.mental].setSelection = true;
		} else {
			_lev.setSelection = 0;
			_targ[Target.M.SELECTED].setSelection = true;
			_sleep[1].setSelection = true;
			_phy[Physical.DEX].setSelection = true;
			_mtl[Mental.AGGRESSIVE].setSelection = true;
		}
	}

	override bool apply() {
		if (!_evt) _evt = new Content(CType.BRANCH_ABILITY, "");
		auto targ = Target(getRadioValue!(Target.M)(_targ), _sleep[0].getSelection);
		_evt.signedLevel = _lev.getSelection;
		_evt.targetS = targ;
		_evt.physical = getRadioValue!(Physical)(_phy);
		_evt.mental = getRadioValue!(Mental)(_mtl);
		return true;
	}
}

/// レベル判定分岐の設定を行うダイアログ。
class BrLevelDialog : EventDialog {
private:
	Spinner _lev;
	Button[2] _ave;

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) {
		super (comm, prop, shell, summ, CType.BRANCH_LEVEL, parent, evt, false, null, true);
	}
protected:
	override void setup(Composite area) {
		area.setLayout = new GridLayout(2, false);
		{
			auto grp = new Group(area, SWT.NONE);
			grp.setText = _prop.msgs.judgeTarget;
			grp.setLayoutData = new GridData(GridData.FILL_BOTH);
			grp.setLayout = new CenterLayout;
			auto comp = new Composite(grp, SWT.NONE);
			comp.setLayout = zeroMarginGridLayout(1, true);
			_ave[1] = new Button(comp, SWT.RADIO);
			mod(_ave[1]);
			_ave[1].setText = _prop.msgs.selectedLevel;
			_ave[0] = new Button(comp, SWT.RADIO);
			mod(_ave[0]);
			_ave[0].setText = _prop.msgs.allMemberLevel;
		}
		{
			auto grp = new Group(area, SWT.NONE);
			grp.setText = _prop.msgs.judgeLevel;
			grp.setLayoutData = new GridData(GridData.FILL_BOTH);
			grp.setLayout = new CenterLayout;
			auto comp = new Composite(grp, SWT.NONE);
			comp.setLayout = zeroMarginGridLayout(2, false);
			_lev = new Spinner(comp, SWT.BORDER);
			mod(_lev);
			_lev.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			_lev.setMinimum = Content.unsignedLevel_min;
			_lev.setMaximum = Content.unsignedLevel_max;
			auto l = new Label(comp, SWT.NONE);
			l.setText = _prop.msgs.rangeHint(_lev.getMinimum, _lev.getMaximum);
		}

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) {
			_ave[_evt.average ? 0 : 1].setSelection = true;
			_lev.setSelection = _evt.unsignedLevel;
		} else {
			_ave[1].setSelection = true;
			_lev.setSelection = 1;
		}
	}

	override bool apply() {
		if (!_evt) _evt = new Content(CType.BRANCH_LEVEL, "");
		_evt.average = _ave[0].getSelection;
		_evt.unsignedLevel = _lev.getSelection;
		return true;
	}
}

/// 状態分岐の設定を行うダイアログ。
class BrStateDialog : EventDialog {
private:
	Button[Target.M] _targ;
	Button[Status] _stat;

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) {
		super (comm, prop, shell, summ, CType.BRANCH_STATUS, parent, evt, false, null, true);
	}
protected:
	override void setup(Composite area) {
		area.setLayout = new GridLayout(1, false);
		{
			auto grp = new Group(area, SWT.NONE);
			grp.setText = _prop.msgs.judgeTarget;
			grp.setLayoutData = new GridData(GridData.FILL_BOTH);
			grp.setLayout = new GridLayout(3, true);
			foreach (m; [Target.M.SELECTED, Target.M.RANDOM, Target.M.PARTY]) {
				auto radio = new Button(grp, SWT.RADIO);
				mod(radio);
				radio.setText = _prop.msgs.target(m);
				radio.setLayoutData = new GridData(GridData.FILL_BOTH);
				_targ[m] = radio;
			}
		}
		{
			auto grp = new Group(area, SWT.NONE);
			grp.setText = _prop.msgs.judgeState;
			grp.setLayoutData = new GridData(GridData.FILL_BOTH);
			grp.setLayout = new GridLayout(4, true);
			foreach (s; [Status.ACTIVE, Status.INACTIVE, Status.ALIVE, Status.DEAD,
					Status.FINE, Status.INJURED, Status.HEAVY_INJURED, Status.UNCONSCIOUS,
					Status.POISON, Status.SLEEP, Status.BIND, Status.PARALYZE]) {
				auto radio = new Button(grp, SWT.RADIO);
				mod(radio);
				radio.setText = _prop.msgs.status(s);
				radio.setLayoutData = new GridData(GridData.FILL_BOTH);
				_stat[s] = radio;
			}
		}
		{
			auto grp = new Group(area, SWT.NONE);
			grp.setText = _prop.msgs.stateHint;
			grp.setLayoutData = new GridData(GridData.FILL_BOTH);
			grp.setLayout = new CenterLayout;
			auto comp = new Composite(grp, SWT.NONE);
			comp.setLayout = zeroMarginGridLayout(1, true);
			auto hint1 = new Label(comp, SWT.NONE);
			hint1.setText = _prop.msgs.statusActive;
			auto hint2 = new Label(comp, SWT.NONE);
			hint2.setText = _prop.msgs.statusInactive;
			auto hint3 = new Label(comp, SWT.NONE);
			hint3.setText = _prop.msgs.statusAlive;
			auto hint4 = new Label(comp, SWT.NONE);
			hint4.setText = _prop.msgs.statusDead;
		}

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) {
			_targ[_evt.targetNS.m].setSelection = true;
			_stat[_evt.status].setSelection = true;
		} else {
			_targ[Target.M.SELECTED].setSelection = true;
			_stat[Status.ACTIVE].setSelection = true;
		}
	}

	override bool apply() {
		if (!_evt) _evt = new Content(CType.BRANCH_STATUS, "");
		auto targ = Target(getRadioValue!(Target.M)(_targ), false);
		_evt.targetNS = targ;
		_evt.status = getRadioValue!(Status)(_stat);
		return true;
	}
}

/// カード取得・喪失・所持判定の設定を行うダイアログ。
private class CardEventDialog(CType Type, C : EffectCard, string Cards, bool Delete, Range RangeDef) : EventDialog {
private:
	Spinner _num;
	static if (Delete) {
		Button _allDel;
		class DelSListener : SelectionAdapter {
			override void widgetSelected(SelectionEvent e) {
				_num.setEnabled = !_allDel.getSelection;
			}
		}
	}
	Button[Range] _range;
	Table _list;

	void refreshList() {
		auto sels = _list.getSelection;
		ulong id = 0;
		if (sels.length) {
			id = (cast(C) sels[0].getData).id;
		} else if (_evt) {
			static if (is (C == SkillCard)) {
				id = _evt.skill;
			} else static if (is (C == ItemCard)) {
				id = _evt.item;
			} else static if (is (C == BeastCard)) {
				id = _evt.beast;
			} else {
				static assert (0);
			}
		}
		_list.removeAll();
		foreach (i, c; mixin (Cards)) {
			auto itm = new TableItem(_list, SWT.NONE);
			itm.setData = c;
			static if (is (C == SkillCard)) {
				itm.setImage(0, _prop.images.skill);
			} else static if (is (C == ItemCard)) {
				itm.setImage(0, _prop.images.item);
			} else static if (is (C == BeastCard)) {
				itm.setImage(0, _prop.images.beast);
			} else {
				static assert (0);
			}
			itm.setText(0, to!(string)(c.id));
			itm.setText(1, c.name);
			if (i == 0) _list.select = i;
			if (id == c.id) _list.select = i;
		}
		_list.showSelection;
	}
	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			static if (is (C == SkillCard)) {
				_comm.refSkill.remove(&refCard);
				_comm.delSkill.remove(&delCard);
			} else static if (is (C == ItemCard)) {
				_comm.refItem.remove(&refCard);
				_comm.delItem.remove(&delCard);
			} else static if (is (C == BeastCard)) {
				_comm.refBeast.remove(&refCard);
				_comm.delBeast.remove(&delCard);
			} else static assert (0);
		}
	}

	void refCard(C c) {
		refreshList();
	}
	void delCard(C c) {
		auto cards = mixin (Cards);
		if (cards.length) {
			refreshList();
		} else {
			forceCancel();
		}
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) {
		super (comm, prop, shell, summ, Type, parent, evt, true, prop.var.cardEvtDlg, true);
	}
protected:
	override void setup(Composite area) {
		area.setLayout = new GridLayout(2, false);
		{
			auto comp = new Composite(area, SWT.NONE);
			comp.setLayoutData = new GridData(GridData.FILL_VERTICAL);
			comp.setLayout = zeroMarginGridLayout(1, true);
			{
				auto grp = new Group(comp, SWT.NONE);
				grp.setText = _prop.msgs.cardNumber;
				grp.setLayoutData = new GridData(GridData.FILL_BOTH);
				auto cl = new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0);
				cl.fillHorizontal = true;
				grp.setLayout = cl;
				auto comp2 = new Composite(grp, SWT.NONE);
				comp2.setLayout = new GridLayout(2, false);
				_num = new Spinner(comp2, SWT.BORDER);
				mod(_num);
				_num.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				_num.setMinimum = 1;
				_num.setMaximum = Content.cardNumber_max;
				auto l = new Label(comp2, SWT.NONE);
				l.setText = _prop.msgs.rangeHint(_num.getMinimum, _num.getMaximum);
				static if (Delete) {
					_allDel = new Button(comp2, SWT.CHECK);
					mod(_allDel);
					_allDel.setText = _prop.msgs.cardAllDelete;
					auto gd = new GridData;
					gd.horizontalSpan = 2;
					_allDel.setLayoutData = gd;
					_allDel.addSelectionListener(new DelSListener);
				}
			}
			{
				auto grp = new Group(comp, SWT.NONE);
				grp.setText = _prop.msgs.cardEventRange;
				grp.setLayoutData = new GridData(GridData.FILL_BOTH);
				grp.setLayout = new GridLayout(1, true);
				foreach (r; [Range.SELECTED, Range.RANDOM, Range.PARTY,
						Range.BACKPACK, Range.PARTY_AND_BACKPACK, Range.FIELD]) {
					auto radio = new Button(grp, SWT.RADIO);
					mod(radio);
					radio.setText = _prop.msgs.range(r);
					radio.setLayoutData = new GridData(GridData.FILL_BOTH);
					_range[r] = radio;
				}
			}
		}
		{
			_list = new Table(area, SWT.SINGLE | SWT.FULL_SELECTION | SWT.BORDER | SWT.V_SCROLL);
			mod(_list);
			auto idCol = new TableColumn(_list, SWT.NONE);
			saveColumnWidth!("prop.var.etc.idColumn")(_prop, idCol);
			auto nameCol = new FullTableColumn(_list, SWT.NONE);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.widthHint = _prop.var.etc.nameTableWidth;
			gd.heightHint = _prop.var.etc.nameTableHeight;
			_list.setLayoutData = gd;
			refreshList();
		}
		static if (is (C == SkillCard)) {
			_comm.refSkill.add(&refCard);
			_comm.delSkill.add(&delCard);
		} else static if (is (C == ItemCard)) {
			_comm.refItem.add(&refCard);
			_comm.delItem.add(&delCard);
		} else static if (is (C == BeastCard)) {
			_comm.refBeast.add(&refCard);
			_comm.delBeast.add(&delCard);
		} else static assert (0);
		_list.addDisposeListener(new Dispose);

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) {
			static if (Delete) {
				if (_evt.cardNumber == 0u) {
					_allDel.setSelection = true;
					_num.setSelection = 1;
					_num.setEnabled = false;
				} else {
					_allDel.setSelection = false;
					_num.setSelection = _evt.cardNumber;
				}
			} else {
				_num.setSelection = _evt.cardNumber;
			}
			_range[_evt.range].setSelection = true;
		} else {
			static if (Delete) {
				_allDel.setSelection = false;
			}
			_num.setSelection = 1;
			_range[RangeDef].setSelection = true;
		}
	}

	override bool apply() {
		if (!_evt) _evt = new Content(Type, "");
		auto id = (cast(C) _list.getSelection[0].getData).id;
		static if (is (C == SkillCard)) {
			_evt.skill = id;
		} else static if (is (C == ItemCard)) {
			_evt.item = id;
		} else static if (is (C == BeastCard)) {
			_evt.beast = id;
		} else {
			static assert (0);
		}
		_evt.range = getRadioValue!(Range)(_range);
		static if (Delete) {
			if (_allDel.getSelection) {
				_evt.cardNumber = 0u;
			} else {
				_evt.cardNumber = _num.getSelection;
			}
		} else {
			_evt.cardNumber = _num.getSelection;
		}
		return true;
	}
}

alias CardEventDialog!(CType.BRANCH_SKILL, SkillCard, "_summ.skills", false, Range.FIELD) BrSkillDialog;
alias CardEventDialog!(CType.BRANCH_ITEM, ItemCard, "_summ.items", false, Range.FIELD) BrItemDialog;
alias CardEventDialog!(CType.BRANCH_BEAST, BeastCard, "_summ.beasts", false, Range.FIELD) BrBeastDialog;
alias CardEventDialog!(CType.GET_SKILL, SkillCard, "_summ.skills", false, Range.SELECTED) GetSkillDialog;
alias CardEventDialog!(CType.GET_ITEM, ItemCard, "_summ.items", false, Range.SELECTED) GetItemDialog;
alias CardEventDialog!(CType.GET_BEAST, BeastCard, "_summ.beasts", false, Range.SELECTED) GetBeastDialog;
alias CardEventDialog!(CType.LOSE_SKILL, SkillCard, "_summ.skills", true, Range.FIELD) LostSkillDialog;
alias CardEventDialog!(CType.LOSE_ITEM, ItemCard, "_summ.items", true, Range.FIELD) LostItemDialog;
alias CardEventDialog!(CType.LOSE_BEAST, BeastCard, "_summ.beasts", true, Range.FIELD) LostBeastDialog;

/// 画面再構築イベントの設定を行うダイアログ。
class RefreshDialog : EventDialog {
private:
	Combo _ts;
	Spinner _tsSpeed;
	Transition[int] _tsTbl;

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) {
		super (comm, prop, shell, summ, CType.REDISPLAY, parent, evt, false, null, true);
	}
protected:
	override void setup(Composite area) {
		area.setLayout = new GridLayout(1, false);
		{
			auto grp = new Group(area, SWT.NONE);
			grp.setText = _prop.msgs.transitionType;
			grp.setLayoutData = new GridData(GridData.FILL_BOTH);
			grp.setLayout = new CenterLayout;
			auto comp = new Composite(grp, SWT.NONE);
			comp.setLayout = zeroMarginGridLayout(3, false);
			auto lt = new Label(comp, SWT.NONE);
			lt.setText = _prop.msgs.transition;
			_ts = new Combo(comp, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
			mod(_ts);
			auto gd = new GridData;
			gd.horizontalSpan = 2;
			_ts.setLayoutData = gd;
			_ts.setVisibleItemCount = 20;
			foreach (i, t; ALL_TRANSITION) {
				_ts.add(_prop.msgs.transition(t));
				_tsTbl[i] = t;
				if (_evt && t == _evt.transition) _ts.select(i);
			}
			auto ls = new Label(comp, SWT.NONE);
			ls.setText = _prop.msgs.transitionSpeed;
			_tsSpeed = new Spinner(comp, SWT.BORDER);
			mod(_tsSpeed);
			_tsSpeed.setMaximum = Content.transitionSpeed_max;
			_tsSpeed.setMinimum = Content.transitionSpeed_min;
			auto hint = new Label(comp, SWT.NONE);
			hint.setText = _prop.msgs.rangeHint
				(Content.transitionSpeed_min,
				Content.transitionSpeed_max);
		}
		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) {
			_tsSpeed.setSelection = _evt.transitionSpeed;
		} else {
			_ts.select = 0;
			_tsSpeed.setSelection = _prop.looks.transitionSpeedDef;
		}
	}

	override bool apply() {
		if (!_evt) _evt = new Content(CType.REDISPLAY, "");
		auto ts = _tsTbl[_ts.getSelectionIndex];
		uint tsSpeed = _tsSpeed.getSelection;
		_evt.transition = ts;
		_evt.transitionSpeed = tsSpeed;
		return true;
	}
}
