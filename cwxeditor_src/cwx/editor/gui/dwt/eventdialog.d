
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
import cwx.path;
import cwx.structs;
import cwx.menu;
import cwx.types;

import cwx.editor.gui.sound;

import cwx.editor.gui.dwt.areaview;
import cwx.editor.gui.dwt.areaviewutils;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.materialselect;
import cwx.editor.gui.dwt.motionview;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.incsearch;

import std.algorithm : countUntil;
import std.conv;
import std.math;
import std.path;
import std.traits;

import org.eclipse.swt.all;

immutable transitionSpeedDef = Content.transitionSpeed_min + ((Content.transitionSpeed_max - Content.transitionSpeed_min) / 2);

abstract class EventDialog : AbsDialog {
	private Commons _comm;
	private Props _prop;
	private Summary _summ;
	private Content _parent;
	private Content _evt;
	private CType _type;

	private class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			_comm.delContent.remove(&delContent);
			_comm.refSkin.remove(&refSkin);
		}
	}
	private void delContent(Content c) {
		if ((_evt && _evt.isDescendant(c)) || (_parent && _parent.isDescendant(c))) {
			forceCancel();
		}
	}

	this (Commons comm, Props prop, Shell shell, Summary summ, CType type, Content parent, Content evt, bool resizable, DSize size, bool eClose, bool rightGroup = false) in {
		assert (!evt || evt.type is type);
		assert (summ);
	} body {
		super (prop, shell, false, .tryFormat(prop.msgs.dlgTitContent, prop.msgs.contentName(type)), prop.images.content(type), resizable, size, true, true, [], rightGroup);
		enterClose = eClose;
		_comm = comm;
		_prop = prop;
		_summ = summ;
		_type = type;
		_parent = parent;
		_evt = evt;
		_comm.delContent.add(&delContent);
		_comm.refSkin.add(&refSkin);
		getShell().addDisposeListener(new Dispose);
	}

	@property
	Content event() {
		return _evt;
	}
	@property protected Commons comm() {return _comm;}
	@property protected Props prop() {return _prop;}
	@property protected Summary summ() {return _summ;}
	@property protected Content evt() {return _evt;}
	@property protected void evt(Content evt) {_evt = evt;}
	@property protected CType type() {return _type;}

	protected void refSkin() {}

	bool openCWXPath(string path, bool shellActivate) {
		return cpempty(path);
	}
}

class ContentCommentDialog : AbsDialog {
	private Commons _comm;
	private Props _prop;
	private Content _parent;
	private Content _evt;
	private Text _comment;

	private class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			_comm.delContent.remove(&delContent);
		}
	}
	private void delContent(Content c) {
		if ((_evt && _evt.isDescendant(c)) || (_parent && _parent.isDescendant(c))) {
			forceCancel();
		}
	}

	this (Commons comm, Props prop, Shell shell, Content parent, Content evt) in {
		assert (evt);
	} body {
		super (prop, shell, false, prop.msgs.dlgTitComment, prop.images.menu(MenuID.Comment), true, prop.var.commentDlg, true);
		_comm = comm;
		_prop = prop;
		_parent = parent;
		_evt = evt;
		_comm.delContent.add(&delContent);
		getShell().addDisposeListener(new Dispose);
	}

	override void setup(Composite area) {
		auto cl = new CenterLayout;
		cl.fillHorizontal = true;
		cl.fillVertical = true;
		area.setLayout(cl);
		_comment = new Text(area, SWT.BORDER | SWT.MULTI | SWT.WRAP | SWT.V_SCROLL);
		mod(_comment);
		_comment.setText(_evt.comment);
		createTextMenu!Text(_comm, _prop, _comment, &catchMod);
		auto font = _comment.getFont();
		auto fSize = font ? cast(uint) font.getFontData()[0].height : 0;
		_comment.setFont(new Font(Display.getCurrent(), dwtData(_prop.looks.textDlgFont(fSize))));
		_comment.setSelection(to!dstring(_comment.getText()).length);
		closeEvent ~= () {
			_comment.getFont().dispose();
		};
	}

	override bool apply() {
		_evt.comment = lastRet(wrapReturnCode(_comment.getText()));
		return true;
	}
}

/// エリア・バトル・パッケージ・キャスト・情報の選択を行うダイアログ。
class AreaSelectDialog(CType Type, A, string Areas) : EventDialog {
private:
	ulong _selectedID = 0;
	Table _list;
	IncSearch _incSearch;
	void incSearch() {
		.forceFocus(_list, true);
		_incSearch.startIncSearch();
	}

	static if (Type == CType.CHANGE_AREA) {
		Combo _ts;
		Spinner _tsSpeed;
		Transition[int] _tsTbl;
	}
	void selected() {
		auto index = _list.getSelectionIndex();
		if (-1 != index) {
			_selectedID = (cast(A) _list.getItem(index).getData()).id;
		}
	}
	void refreshList() {
		auto summary = _summ;
		ulong id = _selectedID;
		_list.removeAll();
		size_t i = 0;
		foreach (a; mixin (Areas)) {
			if (!_incSearch.match(a.name)) continue;
			auto itm = new TableItem(_list, SWT.NONE);
			itm.setData(a);
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
			if (id == a.id) _list.select(i);
			i++;
		}
		_list.showSelection();
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
			_ts.setEnabled(!_summ.legacy);
			_tsSpeed.setEnabled(!_summ.legacy);
		}
	}
	void openView() {
		auto i = _list.getSelectionIndex();
		if (-1 == i) return;
		auto a = cast(A) _list.getItem(i).getData();
		try {
			_comm.openCWXPath(cpaddattr(a.cwxPath(true), "shallow"), false);
		} catch (Exception e) {
			debugln(e);
		}
	}
	class OpenView : MouseAdapter {
		override void mouseDoubleClick(MouseEvent e) {
			if (1 != e.button) return;
			openView();
		}
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) {
		super (comm, prop, shell, summ, Type, parent, evt, true, prop.var.selEvtDlg, true);
	}
protected:
	override void setup(Composite area) {
		area.setLayout(new GridLayout(1, false));
		_list = new Table(area, SWT.SINGLE | SWT.FULL_SELECTION | SWT.BORDER | SWT.V_SCROLL);
		mod(_list);
		auto idCol = new TableColumn(_list, SWT.NONE);
		saveColumnWidth!("prop.var.etc.idColumn")(_prop, idCol);
		auto nameCol = new FullTableColumn(_list, SWT.NONE);
		auto gd = new GridData(GridData.FILL_BOTH);
		gd.widthHint = _prop.var.etc.nameTableWidth;
		gd.heightHint = _prop.var.etc.nameTableHeight;
		_list.setLayoutData(gd);
		_list.addMouseListener(new OpenView);
		.listener(_list, SWT.Selection, &selected);
		auto menu = new Menu(_list.getShell(), SWT.POP_UP);
		createMenuItem(comm, menu, MenuID.IncSearch, &incSearch, null);
		new MenuItem(menu, SWT.SEPARATOR);
		static if (is(A : Area) || is(A : Battle) || is(A : Package)) {
			createMenuItem(comm, menu, MenuID.OpenAtTableView, &openView, () => _list.getSelectionIndex() != -1);
		} else static if (is(A : CastCard) || is(A : InfoCard)) {
			createMenuItem(comm, menu, MenuID.OpenAtCardView, &openView, () => _list.getSelectionIndex() != -1);
		} else static assert (0);
		_list.setMenu(menu);
		_incSearch = new IncSearch(comm, _list);
		_incSearch.modEvent ~= &refreshList;
		refreshList();
		static if (Type == CType.CHANGE_AREA) {
			{
				auto comp = new Composite(area, SWT.NONE);
				comp.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
				comp.setLayout(zeroMarginGridLayout(3, false));
				auto lt = new Label(comp, SWT.NONE);
				lt.setText(_prop.msgs.transition);
				_ts = new Combo(comp, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
				auto tgd = new GridData;
				tgd.horizontalSpan = 2;
				_ts.setLayoutData(tgd);
				_ts.setVisibleItemCount(prop.var.etc.comboVisibleItemCount);
				foreach (i, t; ALL_TRANSITION) {
					_ts.add(_prop.msgs.transitionName(t));
					_tsTbl[i] = t;
					if (_evt && t == _evt.transition) _ts.select(i);
				}
				auto ls = new Label(comp, SWT.NONE);
				ls.setText(_prop.msgs.transitionSpeed);
				_tsSpeed = new Spinner(comp, SWT.BORDER);
				_tsSpeed.setMaximum(Content.transitionSpeed_max);
				_tsSpeed.setMinimum(Content.transitionSpeed_min);
				auto hint = new Label(comp, SWT.NONE);
				hint.setText(.tryFormat(_prop.msgs.rangeHint, Content.transitionSpeed_min, Content.transitionSpeed_max));
			}
			if (_evt) {
				_tsSpeed.setSelection(_evt.transitionSpeed);
			} else {
				_ts.select(0);
				_tsSpeed.setSelection(.transitionSpeedDef);
			}
			refreshTS();
		}
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

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) {
			static if (Type == CType.CHANGE_AREA) {
				_selectedID = _evt.area;
			} else static if (Type == CType.START_BATTLE) {
				_selectedID = _evt.battle;
			} else static if (Type == CType.CALL_PACKAGE || Type == CType.LINK_PACKAGE) {
				_selectedID = _evt.packages;
			} else static if (Type == CType.BRANCH_CAST || Type == CType.GET_CAST || Type == CType.LOSE_CAST) {
				_selectedID = _evt.casts;
			} else static if (Type == CType.BRANCH_INFO || Type == CType.GET_INFO || Type == CType.LOSE_INFO) {
				_selectedID = _evt.info;
			} else {
				static assert (0);
			}
			foreach (i, itm; _list.getItems()) {
				if (_selectedID == (cast(A) itm.getData()).id) {
					_list.select(i);
					break;
				}
			}
		}
		if (-1 == _list.getSelectionIndex()) {
			_list.select(0);
			_selectedID = (cast(A) _list.getItem(0).getData()).id;
		}

		_list.showSelection();
	}

	override bool apply() {
		assert (_list.getItemCount() > 0);
		auto id = _selectedID;
		if (!_evt) {
			_evt = new Content(Type, "");
		}
		static if (Type == CType.CHANGE_AREA) {
			auto ts = _tsTbl[_ts.getSelectionIndex()];
			uint tsSpeed = _tsSpeed.getSelection();
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
	string _selected = "";

	EventTree _et;

	Table _list;

	IncSearch _incSearch;
	void incSearch() {
		.forceFocus(_list, true);
		_incSearch.startIncSearch();
	}

	void selected() {
		int index = _list.getSelectionIndex();
		if (-1 == index) return;
		_selected = (cast(Content) _list.getItem(index).getData()).name;
	}

	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			_comm.refContent.remove(&refContent);
			_comm.delContent.remove(&delContent);
		}
	}
	void refContent(Content c) {
		refreshStarts(null);
	}
	void delContent(Content c) {
		refreshStarts(c);
	}
	void refreshStarts() {
		refreshStarts(null);
	}
	void refreshStarts(Content del) {
		string sel = _selected;

		_list.removeAll();
		int i = 0;
		foreach (s; _et.starts) {
			if (s is del) continue;
			if (!_incSearch.match(s.name)) continue;
			auto itm = new TableItem(_list, SWT.NONE);
			itm.setData(s);
			itm.setImage(0, _prop.images.content(CType.START));
			itm.setText(0, s.name);
			if (sel == s.name) _list.select(i);
			i++;
		}
		if (del && sel == del.name && _list.getItemCount()) {
			_list.select(0);
			_selected = (cast(Content) _list.getItem(0).getData()).name;
		}
		_list.showSelection();
	}
	void openView() {
		auto i = _list.getSelectionIndex();
		if (-1 == i) return;
		auto a = cast(Content) _list.getItem(i).getData();
		try {
			_comm.openCWXPath(cpaddattr(a.cwxPath(true), "shallow"), false);
		} catch (Exception e) {
			debugln(e);
		}
	}
	class OpenView : MouseAdapter {
		override void mouseDoubleClick(MouseEvent e) {
			if (1 != e.button) return;
			openView();
		}
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) {
		_et = parent.tree;
		super (comm, prop, shell, summ, Type, parent, evt, true, prop.var.selEvtDlg, true);
	}

protected:
	override void setup(Composite area) {
		area.setLayout(new GridLayout(1, false));
		_list = new Table(area, SWT.SINGLE | SWT.FULL_SELECTION | SWT.BORDER | SWT.V_SCROLL);
		mod(_list);
		auto nameCol = new FullTableColumn(_list, SWT.NONE);
		auto gd = new GridData(GridData.FILL_BOTH);
		gd.widthHint = _prop.var.etc.nameTableWidth;
		gd.heightHint = _prop.var.etc.nameTableHeight;
		_list.setLayoutData(gd);
		_list.addMouseListener(new OpenView);
		auto menu = new Menu(_list.getShell(), SWT.POP_UP);
		createMenuItem(comm, menu, MenuID.IncSearch, &incSearch, null);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(comm, menu, MenuID.OpenAtEventView, &openView, () => _list.getSelectionIndex() != -1);
		_list.setMenu(menu);
		.listener(_list, SWT.Selection, &selected);
		_incSearch = new IncSearch(comm, _list);
		_incSearch.modEvent ~= &refreshStarts;

		refreshStarts();
		_comm.refContent.add(&refContent);
		_comm.delContent.add(&delContent);
		_list.addDisposeListener(new Dispose);

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) {
			_selected = _evt.start;
			foreach (i, itm; _list.getItems()) {
				if (_selected == (cast(Content) itm.getData()).name) {
					_list.select(i);
					break;
				}
			}
		}
		if (-1 == _list.getSelectionIndex()) {
			_list.select(0);
			_selected = (cast(Content) _list.getItem(0).getData()).name;
		}
		_list.showSelection();
	}

	override bool apply() {
		if (!_evt) _evt = new Content(Type, "");
		_evt.start = _selected;
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
		area.setLayout(cl);
		auto grp = new Group(area, SWT.NONE);
		grp.setText(_prop.msgs.afterClear);
		grp.setLayout(new CenterLayout(SWT.VERTICAL | SWT.HORIZONTAL, 0));
		auto comp = new Composite(grp, SWT.NONE);
		comp.setLayout(new GridLayout(1, true));
		_mark = new Button(comp, SWT.RADIO);
		mod(_mark);
		_mark.setText(_prop.msgs.afterClearEndMark);
		_unmark = new Button(comp, SWT.RADIO);
		mod(_unmark);
		_unmark.setText(_prop.msgs.afterClearNoEndMark);

		if (_evt) {
			if (_evt.complete) {
				_mark.setSelection(true);
			} else {
				_unmark.setSelection(true);
			}
		} else {
			_mark.setSelection(true);
		}
	}

	override bool apply() {
		if (!_evt) {
			_evt = new Content(CType.END, "");
		}
		_evt.complete = _mark.getSelection();
		return true;
	}
}

/// クーポン関連イベントの設定を行うダイアログ。
class CouponEventDialog(CType Type, bool EditValue, bool Field) : EventDialog {
private:
	Button[Range] _range;
	Button[CouponType] _type;
	Combo _name;
	static if (EditValue) {
		Spinner _value;
	}

	void refreshWarning() {
		string[] ws;
		static if (Type is CType.GET_COUPON || Type is CType.LOSE_COUPON) {
			if (prop.sys.isCouponType(_name.getText(), CouponType.System)) {
				ws ~= .tryFormat(prop.msgs.warningSystemCoupon, prop.sys.couponSystem);
			}
		}
		static if (Field) {
			if (_range[Range.FIELD].getSelection()) {
				ws ~= prop.msgs.warningBranchCouponAtField;
			}
		}
		warning = ws;
	}

	class SelType : SelectionAdapter {
		private CouponType _coType;
		this (CouponType coType) {
			_coType = coType;
		}
		override void widgetSelected(SelectionEvent e) {
			_name.setText(prop.sys.convCoupon(_name.getText(), _coType, true));
		}
	}

	protected override void refSkin() {
		refreshCoupons();
	}
	void refreshCoupons() {
		auto c = _name.getText();
		_name.removeAll();
		auto cs = castCoupons(comm, false, comm.skin.legacyName);
		string[] cs2;
		if (prop.var.etc.usedCouponToCombo) {
			foreach (coupon; comm.summary.useCounter.coupon.keys.sort) {
				if (!.contains(cs2, coupon.id)) cs2 ~= coupon;
			}
		}
		foreach (coupon; cs2 ~ cs) {
			_name.add(coupon);
		}
		_name.select(0);
		if (c.length && -1 == _name.indexOf(c)) {
			_name.add(c, 0);
		}
		_name.setText(c);
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) {
		super (comm, prop, shell, summ, Type, parent, evt, true, prop.var.couponEvtDlg, true);
	}
protected:
	override void setup(Composite area) {
		area.setLayout(new GridLayout(2, false));
		auto skin = _comm.skin;

		auto leftComp = new Composite(area, SWT.NONE);
		leftComp.setLayout(zeroMarginGridLayout(1, true));
		leftComp.setLayoutData(new GridData(GridData.FILL_VERTICAL));
		{
			auto grp = new Group(leftComp, SWT.NONE);
			static if (EditValue) {
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			} else {
				grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			}
			grp.setText(_prop.msgs.range);
			grp.setLayout(new GridLayout(1, true));
			auto ranges = RANGE_MEMBER.dup;
			static if (Field) {
				ranges ~= Range.FIELD;
			}
			foreach (r; ranges) {
				auto radio = new Button(grp, SWT.RADIO);
				mod(radio);
				radio.setLayoutData(new GridData(GridData.FILL_BOTH));
				radio.setText(_prop.msgs.rangeName(r));
				.listener(radio, SWT.Selection, &refreshWarning);
				_range[r] = radio;
			}
		}
		{
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto cl = new CenterLayout(SWT.VERTICAL, 0);
			cl.fillHorizontal = true;
			grp.setLayout(cl);
			grp.setText(_prop.msgs.couponName);
			{
				auto comp = new Composite(grp, SWT.NONE);
				comp.setLayout(new GridLayout(3, false));
				{
					_name = new Combo(comp, SWT.BORDER | SWT.DROP_DOWN);
					mod(_name);
					_name.setVisibleItemCount(prop.var.etc.comboVisibleItemCount);
					createTextMenu!Combo(_comm, _prop, _name, &catchMod);
					auto gd = new GridData(GridData.FILL_HORIZONTAL);
					gd.horizontalSpan = 3;
					gd.widthHint = _prop.var.etc.nameWidth;
					_name.setLayoutData(gd);
					refreshCoupons();
				}
				foreach (coType; [CouponType.Normal, CouponType.Hide, CouponType.Dur, CouponType.DurBattle]) {
					auto b = new Button(comp, SWT.RADIO);
					b.setText(_prop.msgs.couponTypeDesc(coType));
					auto gd = new GridData(GridData.FILL_HORIZONTAL);
					gd.horizontalSpan = 3;
					b.setLayoutData(gd);
					b.addSelectionListener(new SelType(coType));
					_type[coType] = b;
				}
				.listener(_name, SWT.Modify, {
					auto t = prop.sys.couponType(_name.getText());
					bool checked = false;
					foreach (coType; _type.keys) {
						_type[coType].setSelection(coType == t);
						checked |= (coType == t);
					}
					if (!checked) _type[CouponType.Normal].setSelection(true);
					refreshWarning();
				});
			}
		}
		static if (EditValue) {
			{
				auto grp = new Group(leftComp, SWT.NONE);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setText(_prop.msgs.couponValue);
				grp.setLayout(new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL));
				auto comp = new Composite(grp, SWT.NONE);
				comp.setLayout(zeroMarginGridLayout(2, false));
				_value = new Spinner(comp, SWT.BORDER);
				mod(_value);
				_value.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				_value.setMaximum(_prop.var.etc.couponValueMax);
				_value.setMinimum(-(cast(int) _prop.var.etc.couponValueMax));
				auto lr = new Label(comp, SWT.LEFT);
				lr.setText(.tryFormat(_prop.msgs.couponValueRange, -(cast(int) prop.var.etc.couponValueMax), prop.var.etc.couponValueMax));
			}
		}
		comm.refCoupons.add(&refreshCoupons);
		.listener(_name, SWT.Dispose, {
			comm.refCoupons.remove(&refreshCoupons);
		});

		if (_evt) {
			_range[_evt.range].setSelection(true);
			auto cType = prop.sys.couponType(_evt.coupon);
			auto cTypeP = cType in _type;
			if (cTypeP) {
				cTypeP.setSelection(true);
			} else {
				_type[CouponType.Normal].setSelection(true);
			}
			_name.setText(_evt.coupon);
			_name.add(_evt.coupon, 0);
			static if (EditValue) {
				_value.setSelection(_evt.couponValue);
			}
		} else {
			_range[Range.SELECTED].setSelection(true);
			_type[CouponType.Normal].setSelection(true);
			static if (EditValue) {
				_value.setSelection(0);
			}
		}
		refreshWarning();
	}

	override bool apply() {
		if (!_evt) _evt = new Content(Type, "");
		foreach (range, radio; _range) {
			if (radio.getSelection()) {
				_evt.range = range;
				_evt.coupon = _name.getText();
				static if (EditValue) {
					_evt.couponValue = _value.getSelection();
				}
				break;
			}
		}
		comm.refCoupons.call();
		return true;
	}
}

alias CouponEventDialog!(CType.BRANCH_COUPON, false, true) BranchCouponDialog;
alias CouponEventDialog!(CType.GET_COUPON, true, false) GetCouponDialog;
alias CouponEventDialog!(CType.LOSE_COUPON, false, false) LoseCouponDialog;

/// 終了印とゴシップの設定を行うダイアログ。
private class OneTextEventDialog(CType Type, string Name, string Get, string Set) : EventDialog {
private:
	Combo _name;

	void refreshCombo() {
		auto c = _name.getText();
		_name.removeAll();

		if (CDetail.fromType(Type).use(CArg.GOSSIP)) {
			foreach (n; comm.summary.useCounter.gossip.keys.sort) {
				_name.add(n);
			}
		}
		if (CDetail.fromType(Type).use(CArg.COMPLETE_STAMP)) {
			foreach (n; comm.summary.useCounter.completeStamp.keys.sort) {
				_name.add(n);
			}
		}
		_name.select(0);
		if (c.length && -1 == _name.indexOf(c)) {
			_name.add(c, 0);
		}
		_name.setText(c);
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) {
		super (comm, prop, shell, summ, Type, parent, evt, true, prop.var.inputEvtDlg, true);
	}
protected:
	override void setup(Composite area) {
		area.setLayout(new GridLayout(1, false));
		{
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setText(mixin (Name));
			auto cl = new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0);
			cl.fillHorizontal = true;
			grp.setLayout(cl);
			auto comp = new Composite(grp, SWT.NONE);
			comp.setLayout(new GridLayout(1, true));

			_name = new Combo(comp, SWT.BORDER | SWT.DROP_DOWN);
			mod(_name);
			_name.setVisibleItemCount(prop.var.etc.comboVisibleItemCount);
			createTextMenu!Combo(_comm, _prop, _name, &catchMod);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.widthHint = _prop.var.etc.nameWidth;
			_name.setLayoutData(gd);
			refreshCombo();
		}
		if (CDetail.fromType(Type).use(CArg.GOSSIP)) {
			comm.refGossips.add(&refreshCombo);
			.listener(_name, SWT.Dispose, {
				comm.refGossips.remove(&refreshCombo);
			});
		}
		if (CDetail.fromType(Type).use(CArg.COMPLETE_STAMP)) {
			comm.refCompleteStamps.add(&refreshCombo);
			.listener(_name, SWT.Dispose, {
				comm.refCompleteStamps.remove(&refreshCombo);
			});
		}

		if (_evt) {
			_name.setText(mixin (Get));
		}
	}

	override bool apply() {
		if (!_evt) _evt = new Content(Type, "");
		string text = _name.getText();
		mixin (Set);
		if (CDetail.fromType(Type).use(CArg.GOSSIP)) {
			comm.refGossips.call();
		}
		if (CDetail.fromType(Type).use(CArg.COMPLETE_STAMP)) {
			comm.refCompleteStamps.call();
		}
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
		_ts.setEnabled(!_summ.legacy);
		_tsSpeed.setEnabled(!_summ.legacy);
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

	override
	bool openCWXPath(string path, bool shellActivate) {
		return _view.openCWXPath(path, shellActivate);
	}
protected:
	override void setup(Composite area) {
		area.setLayout(new GridLayout(1, false));
		auto skin = _comm.skin;
		{
			_view = createBgImagesViewAndMenu(_comm, _prop, _summ, _cont, area, _refTarget);
			mod(_view);
			_view.setLayoutData(new GridData(GridData.FILL_BOTH));
		}
		{
			auto comp = new Composite(area, SWT.NONE);
			comp.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
			comp.setLayout(zeroMarginGridLayout(5, false));
			auto lt = new Label(comp, SWT.NONE);
			lt.setText(_prop.msgs.transition);
			_ts = new Combo(comp, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
			mod(_ts);
			_ts.setVisibleItemCount(prop.var.etc.comboVisibleItemCount);
			foreach (i, t; ALL_TRANSITION) {
				_ts.add(_prop.msgs.transitionName(t));
				_tsTbl[i] = t;
				if (_evt && t == _evt.transition) _ts.select(i);
			}
			auto ls = new Label(comp, SWT.NONE);
			ls.setText(_prop.msgs.transitionSpeed);
			_tsSpeed = new Spinner(comp, SWT.BORDER);
			mod(_tsSpeed);
			_tsSpeed.setMaximum(Content.transitionSpeed_max);
			_tsSpeed.setMinimum(Content.transitionSpeed_min);
			auto hint = new Label(comp, SWT.NONE);
			hint.setText(.tryFormat(_prop.msgs.rangeHint, Content.transitionSpeed_min, Content.transitionSpeed_max));
		}
		refreshTS();

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) {
			_tsSpeed.setSelection(_evt.transitionSpeed);
		} else {
			_ts.select(0);
			_tsSpeed.setSelection(.transitionSpeedDef);
		}
	}

	override bool apply() {
		_evt.backs = _cont.backs;
		auto ts = _tsTbl[_ts.getSelectionIndex()];
		uint tsSpeed = _tsSpeed.getSelection();
		_evt.transition = ts;
		_evt.transitionSpeed = tsSpeed;
		return true;
	}
}

/// BGMイベントの設定を行うダイアログ。
class BgmDialog : EventDialog {
private:
	MaterialSelect!(MtType.BGM, Combo, Table) _msel;

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) {
		super (comm, prop, shell, summ, CType.PLAY_BGM, parent, evt, true, prop.var.soundEvtDlg, true);
	}
protected:
	override void setup(Composite area) {
		area.setLayout(new GridLayout(4, false));
		{
			auto skin = _comm.skin;
			_msel = new MaterialSelect!(MtType.BGM, Combo, Table)
				(_comm, _prop, _summ, null, [_prop.msgs.bgmStop]);
			_msel.createDirsCombo(area).setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			mod(_msel);
			_msel.modEvent ~= {
				warning = comm.skin.warningBGM(prop.parent, _msel.filePath, summ.legacy);
			};

			_msel.createPlayButton(area).setLayoutData(new GridData);
			_msel.createRefreshButton(area, false).setLayoutData(new GridData);
			_msel.createDirectoryButton(area, false).setLayoutData(new GridData);

			auto gd = new GridData(GridData.FILL_BOTH);
			gd.horizontalSpan = 4;
			gd.widthHint = _prop.var.etc.nameTableWidth;
			gd.heightHint = _prop.var.etc.nameTableHeight;
			auto list = _msel.createFileList(area);
			list.setLayoutData(gd);
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
	MaterialSelect!(MtType.SE, Combo, Table) _msel;

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) {
		super (comm, prop, shell, summ, CType.PLAY_SOUND, parent, evt, true, prop.var.soundEvtDlg, true);
	}
protected:
	override void setup(Composite area) {
		area.setLayout(new GridLayout(5, false));
		{
			auto skin = _comm.skin;
			_msel = new MaterialSelect!(MtType.SE, Combo, Table)
				(_comm, _prop, _summ, null, []);
			_msel.createDirsCombo(area).setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			mod(_msel);
			_msel.modEvent ~= {
				warning = comm.skin.warningSE(prop.parent, _msel.filePath, summ.legacy);
			};

			_msel.createStopButton(area).setLayoutData(new GridData);
			_msel.createPlayButton(area).setLayoutData(new GridData);
			_msel.createRefreshButton(area, false).setLayoutData(new GridData);
			_msel.createDirectoryButton(area, false).setLayoutData(new GridData);

			auto gd = new GridData(GridData.FILL_BOTH);
			gd.horizontalSpan = 5;
			gd.widthHint = _prop.var.etc.nameTableWidth;
			gd.heightHint = _prop.var.etc.nameTableHeight;
			auto list = _msel.createFileList(area);
			list.setLayoutData(gd);
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
			_value.setSelection(_value.getSelection() + _v);
		}
	}
	override void setup(Composite area) {
		area.setLayout(new GridLayout(1, false));
		{
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setText(mixin (Name));
			grp.setLayout(new CenterLayout(SWT.VERTICAL | SWT.HORIZONTAL, 0));
			auto comp = new Composite(grp, SWT.NONE);
			_value = new Spinner(comp, SWT.BORDER);
			mod(_value);
			_value.setMinimum(Min);
			_value.setMaximum(mixin (Max));
			comp.setLayout(new GridLayout(10 <= _value.getMaximum() ? 3 : 2, false));
			if (10 <= _value.getMaximum()) {
				auto tools = new Composite(comp, SWT.NONE);
				tools.setLayout(new FillLayout(SWT.HORIZONTAL));
				for (int i = 5; i <= _value.getMaximum() && i < 10000; i*= i == 5 ? 2 : 10) {
					auto ts = new Composite(tools, SWT.NONE);
					ts.setLayout(new FillLayout(SWT.VERTICAL));
					void createB(int i) {
						auto r = new Button(ts, SWT.PUSH);
						auto fontd = r.getFont().getFontData();
						foreach (fd; fontd) {
							fd.height /= 1.5;
						}
						r.setFont(new Font(Display.getCurrent(), fontd));
						r.addDisposeListener(new class DisposeListener {
							override void widgetDisposed(DisposeEvent e) {
								(cast(Control) e.widget).getFont().dispose();
							}
						});
						r.setText(i < 0 ? to!(string)(i) : "+" ~ to!(string)(i));
						r.addSelectionListener(new PM(i));
					}
					createB(i);
					createB(-i);
				}
			}
			auto l = new Label(comp, SWT.NONE);
			l.setText(.tryFormat(_prop.msgs.rangeHint, Min, _value.getMaximum()));
		}

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) {
			_value.setSelection(mixin (Get));
		} else {
			_value.setSelection(Def);
		}
	}

	override bool apply() {
		if (!_evt) _evt = new Content(Type, "");
		int value = _value.getSelection();
		mixin (Set);
		return true;
	}
}

alias NumericEventDialog!(CType.WAIT, "_prop.msgs.waitName",
		"_prop.var.etc.waitMax", "_evt.wait", "_evt.wait = value;") WaitEventDialog;

alias NumericEventDialog!(CType.BRANCH_RANDOM, "_prop.msgs.randomName",
		"100", "_evt.percent", "_evt.percent = value;", 0, 50) BrRandomEventDialog;

alias NumericEventDialog!(CType.BRANCH_PARTY_NUMBER, "_prop.msgs.partyNumName",
		"_prop.var.etc.partyMax", "_evt.partyNumber", "_evt.partyNumber = value;", 1, 1) BrNumEventDialog;

template MoneyEventDialog(CType Type) {
	alias NumericEventDialog!(Type, "_prop.msgs.moneyName",
		"_prop.var.etc.priceMax", "_evt.money", "_evt.money = value;") MoneyEventDialog;
}

/// 効果イベントの設定を行うダイアログ。
class EffectDialog : EventDialog {
private:
	MotionView _mview;
	Spinner _lev;
	MaterialSelect!(MtType.SE, Combo, Combo) _se;
	Scale _sucRate;
	Button[EffectType] _effTyp;
	Button[Resist] _res;
	Button[CardVisual] _vis;
	Button[Target.M] _targ;

	void refreshWarning() {
		string[] ws;
		if (_se.path != "" && !_se.selectedDefDir) ws ~= prop.msgs.warningNotDefaultSE;
		warning = ws ~ comm.skin.warningSE(prop.parent, _se.filePath, summ.legacy);
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) {
		super (comm, prop, shell, summ, CType.EFFECT, parent, evt, true, prop.var.effEvtDlg, true);
	}

	override
	bool openCWXPath(string path, bool shellActivate) {
		return _mview.openCWXPath(path, shellActivate);
	}
protected:
	override void setup(Composite area) {
		auto cl = new CenterLayout;
		cl.fillHorizontal = true;
		cl.fillVertical = true;
		area.setLayout(cl);
		auto tabf = new CTabFolder(area, SWT.BORDER);
		auto tabM = new CTabItem(tabf, SWT.NONE);
		tabM.setText(_prop.msgs.motion);
		{
			_mview = new MotionView(_comm, _prop, _summ, tabf);
			mod(_mview);
			tabM.setControl(_mview);
		}
		auto tabS = new CTabItem(tabf, SWT.NONE);
		tabS.setText(_prop.msgs.settings);
		{
			auto comp = new Composite(tabf, SWT.NONE);
			tabS.setControl(comp);
			comp.setLayout(new GridLayout(2, false));
			{
				auto comp2 = new Composite(comp, SWT.NONE);
				comp2.setLayoutData(new GridData(GridData.FILL_BOTH));
				comp2.setLayout(zeroMarginGridLayout(1, true));
				{
					auto grp = new Group(comp2, SWT.NONE);
					grp.setText(_prop.msgs.targetLevel);
					grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
					grp.setLayout(new GridLayout(2, false));
					_lev = new Spinner(grp, SWT.BORDER);
					mod(_lev);
					_lev.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
					_lev.setMinimum(-(cast(int) _prop.var.etc.castLevelMax));
					_lev.setMaximum(_prop.var.etc.castLevelMax);
					auto l = new Label(grp, SWT.NONE);
					l.setText(.tryFormat(_prop.msgs.rangeHint, _lev.getMinimum(), _lev.getMaximum()));
				}
				{
					auto grp = new Group(comp2, SWT.NONE);
					grp.setText(_prop.msgs.elementProps);
					grp.setLayoutData(new GridData(GridData.FILL_BOTH));
					grp.setLayout(new GridLayout(2, true));
					foreach (i, eff; [EffectType.PHYSIC, EffectType.MAGIC,
							EffectType.MAGICAL_PHYSIC, EffectType.PHYSICAL_MAGIC,
							EffectType.NONE]) {
						auto radio = new Button(grp, SWT.RADIO);
						mod(radio);
						auto gd = new GridData(GridData.FILL_BOTH);
						if (2 <= i) {
							gd.horizontalSpan = 2;
						}
						radio.setLayoutData(gd);
						radio.setText(.tryFormat(_prop.msgs.effectTypeElement, _prop.msgs.effectTypeName(eff)));
						radio.setToolTipText(_prop.msgs.effectTypeDesc(eff));
						_effTyp[eff] = radio;
					}
				}
				{
					auto grp = new Group(comp2, SWT.NONE);
					grp.setText(_prop.msgs.resistProps);
					grp.setLayoutData(new GridData(GridData.FILL_BOTH));
					grp.setLayout(new GridLayout(2, true));
					foreach (res; [Resist.AVOID, Resist.RESIST, Resist.UNFAIL]) {
						auto radio = new Button(grp, SWT.RADIO);
						mod(radio);
						radio.setText(_prop.msgs.resistName(res));
						radio.setToolTipText(_prop.msgs.resistDesc(res));
						radio.setLayoutData(new GridData(GridData.FILL_BOTH));
						_res[res] = radio;
					}
				}
			}
			{
				auto comp2 = new Composite(comp, SWT.NONE);
				comp2.setLayoutData(new GridData(GridData.FILL_BOTH));
				comp2.setLayout(zeroMarginGridLayout(2, false));
				{
					auto grp = new Group(comp2, SWT.NONE);
					grp.setText(_prop.msgs.effectVisual);
					grp.setLayoutData(new GridData(GridData.FILL_BOTH));
					grp.setLayout(new GridLayout(1, false));
					foreach (v; [CardVisual.NONE, CardVisual.REVERSE, CardVisual.HORIZONTAL, CardVisual.VERTICAL]) {
						auto radio = new Button(grp, SWT.RADIO);
						mod(radio);
						radio.setLayoutData(new GridData(GridData.FILL_BOTH));
						radio.setText(_prop.msgs.cardVisualName(v));
						_vis[v] = radio;
					}
				}
				{
					auto grp = new Group(comp2, SWT.NONE);
					grp.setText(_prop.msgs.judgeTarget);
					grp.setLayoutData(new GridData(GridData.FILL_BOTH));
					grp.setLayout(new GridLayout(1, true));
					foreach (m; [Target.M.SELECTED, Target.M.RANDOM, Target.M.PARTY]) {
						auto radio = new Button(grp, SWT.RADIO);
						mod(radio);
						radio.setText(_prop.msgs.targetName(m));
						radio.setLayoutData(new GridData(GridData.FILL_BOTH));
						_targ[m] = radio;
					}
				}
				{
					auto grp = new Group(comp2, SWT.NONE);
					grp.setText(_prop.msgs.se);
					auto gd = new GridData(GridData.FILL_HORIZONTAL);
					gd.horizontalSpan = 2;
					grp.setLayoutData(gd);
					grp.setLayout(new GridLayout(3, false));
					_se = new MaterialSelect!(MtType.SE, Combo, Combo)(comm, prop, summ, null, [prop.msgs.soundNone]);
					mod(_se);
					_se.modEvent ~= &refreshWarning;
					_se.createDirsCombo(grp).setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
					_se.createStopButton(grp);
					_se.createPlayButton(grp);
					auto gdfl = new GridData(GridData.FILL_HORIZONTAL);
					gdfl.horizontalSpan = 4;
					_se.createFileList(grp).setLayoutData(gdfl);
				}
				{
					auto gd = new GridData(GridData.FILL_BOTH);
					gd.horizontalSpan = 2;
					createSuccessRateScale(_prop, comp2, _sucRate).setLayoutData(gd);
					mod(_sucRate);
				}
			}
		}
		tabf.setLayoutData(area.computeSize(SWT.DEFAULT, SWT.DEFAULT));
		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) {
			_mview.motions = _evt.motions;
			_lev.setSelection(_evt.signedLevel);
			_se.path = _evt.soundPath;
			_sucRate.setSelection(_evt.successRate + Content.successRate_max);
			_effTyp[_evt.effectType].setSelection(true);
			_res[_evt.resist].setSelection(true);
			_vis[_evt.cardVisual].setSelection(true);
			_targ[_evt.targetNS.m].setSelection(true);
		} else {
			_mview.motions = [];
			_lev.setSelection(0);
			_se.path = "";
			_sucRate.setSelection(Content.successRate_max + Content.successRate_max);
			_effTyp[EffectType.NONE].setSelection(true);
			_res[Resist.UNFAIL].setSelection(true);
			_vis[CardVisual.NONE].setSelection(true);
			_targ[Target.M.SELECTED].setSelection(true);
		}
	}

	override bool apply() {
		if (!_evt) _evt = new Content(CType.EFFECT, "");
		_evt.motions = _mview.motions;
		_evt.signedLevel = _lev.getSelection();
		_evt.soundPath = _se.path;
		_evt.successRate = cast(int) _sucRate.getSelection() - Content.successRate_max;
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
	void refreshWarning()  {
		string[] ws;
		static if (Type is CType.CHECK_STEP) {
			ws ~= .tryFormat(_prop.msgs.warningUnknownContent, _prop.msgs.contentName(CType.CHECK_STEP));
		}
		warning = ws;
	}

	FlagDir _root;

	SplitPane _sash;
	Table _flags;
	Table _values;

	string _selected;

	IncSearch _incSearch;
	void incSearch() {
		.forceFocus(_flags, true);
		_incSearch.startIncSearch();
	}

	@property
	string listSelected() {
		auto f = selected;
		return f ? f.path : "";
	}

	@property
	F selected() {
		int index = _flags.getSelectionIndex();
		if (-1 == index) {
			return null;
		}
		return cast(F) _flags.getItem(index).getData();
	}

	@property
	uint selectedValue() {
		return _values.getSelectionIndex();
	}

	void refreshValues() {
		static if (is(F:Flag)) {
			F flag = summ.flagDirRoot.findFlag(_selected);
		} else static if (is(F:Step)) {
			F flag = summ.flagDirRoot.findStep(_selected);
		} else static assert (0);
		static if (SelValue) {
			int sel = _values.getSelectionIndex();
		}
		_values.removeAll();
		if (flag) {
			static if (is (F == Flag)) {
				auto itm1 = new TableItem(_values, SWT.NONE);
				itm1.setText(flag.on);
				auto itm2 = new TableItem(_values, SWT.NONE);
				itm2.setText(flag.off);
			} else static if (is (F == Step)) {
				foreach (val; flag.values) {
					auto itm = new TableItem(_values, SWT.NONE);
					itm.setText(val);
				}
			} else {
				static assert (0);
			}
			static if (SelValue) {
				if (sel < 0) sel = 0;
				static if (is (F == Step)) {
					if (sel >= flag.values.length) sel = flag.values.length - 1;
				}
				_values.select(sel);
			}
		}
		updateLabel();
	}
	class SListener : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			int index = _flags.getSelectionIndex();
			if (-1 != index) {
				string selPath = (cast(F) _flags.getItem(index).getData()).path;
				if (_selected == selPath) {
					static if (SelValue) {
						_values.select(0);
						updateLabel();
					}
				} else {
					_selected = selPath;
					refreshValues();
				}
			}
		}
	}
	class ValSListener : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			updateLabel();
		}
	}
	void refreshList() {
		static if (is (F == Flag)) {
			auto flags = _root.allFlags;
		} else static if (is (F == Step)) {
			auto flags = _root.allSteps;
		} else static assert (0);
		string sel = _selected;
		_flags.removeAll();
		bool has = false;
		size_t i = 0;
		foreach (flag; flags) {
			auto path = flag.path;
			if (!has && path == sel) {
				has = true;
			}
			if (!_incSearch.match(path)) continue;
			auto itm = new TableItem(_flags, SWT.NONE);
			itm.setData(flag);
			itm.setText(path);
			static if (is(F : Flag)) {
				itm.setImage(_prop.images.flag);
			} else static if (is(F : Step)) {
				itm.setImage(_prop.images.step);
			} else static assert (0);
			if (path == sel) _flags.select(i);
			i++;
		}
		if (!has && _flags.getItemCount()) {
			_flags.select(0);
			_selected = (cast(F) _flags.getItem(0).getData()).path;
		}
		refreshValues();
	}
	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			_comm.refFlagAndStep.remove(&refFS);
			_comm.delFlagAndStep.remove(&delFS);
		}
	}
	void refFS(Flag[] f, Step[] s) {
		static if (is(F : Flag)) {
			if (!f.length) return;
		} else {
			if (!s.length) return;
		}
		int sel = _values.getSelectionIndex();
		refreshValues();
		_values.select(sel);
	}
	void delFS(Flag[] f, Step[] s) {
		static if (is(F : Flag)) {
			if (!f.length) return;
		} else {
			if (!s.length) return;
		}
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

	void openView() {
		auto i = _flags.getSelectionIndex();
		if (-1 == i) return;
		auto a = cast(F) _flags.getItem(i).getData();
		try {
			_comm.openCWXPath(cpaddattr(a.cwxPath(true), "shallow"), false);
		} catch (Exception e) {
			debugln(e);
		}
	}
	class OpenView : MouseAdapter {
		override void mouseDoubleClick(MouseEvent e) {
			if (1 != e.button) return;
			openView();
		}
	}
	static if (Type is CType.CHECK_STEP) {
		Label _cmpLabel = null;
		Combo _cmp = null;
		Comparison4[] _cmps;
		void updateLabel() {
			F step = selected;
			assert (step !is null);
			uint value = selectedValue;
			_cmpLabel.setText(.tryFormat(prop.msgs.stepValueIs, step.path, step.getValue(value)));
		}
	} else {
		void updateLabel() {
			// 処理無し
		}
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt, FlagDir root) {
		_root = root;
		super (comm, prop, shell, summ, Type, parent, evt, true, prop.var.flagEvtDlg, true);
		closeEvent ~= {
			auto ws = _sash.getWeights();
			_prop.var.etc.flagEventSashL = ws[0];
			_prop.var.etc.flagEventSashR = ws[1];
		};
	}
protected:
	override void setup(Composite area) {
		area.setLayout(new GridLayout(1, true));
		_sash = new SplitPane(area, SWT.HORIZONTAL);
		_sash.setLayoutData(new GridData(GridData.FILL_BOTH));
		auto left = new Composite(_sash, SWT.NONE);
		left.setLayout(zeroGridLayout(1));
		auto right = new Composite(_sash, SWT.NONE);
		right.setLayout(zeroGridLayout(1));
		{
			auto l1 = new CLabel(left, SWT.NONE);
			auto l2 = new CLabel(right, SWT.NONE);
			static if (is (F == Flag)) {
				l1.setText(_prop.msgs.flag);
				l1.setImage(_prop.images.flag);
				l2.setText(_prop.msgs.flagValue);
			} else static if (is (F == Step)) {
				l1.setText(_prop.msgs.step);
				l1.setImage(_prop.images.step);
				l2.setText(_prop.msgs.stepValue);
			} else {
				static assert (0);
			}
			auto gd = new GridData;
			gd.heightHint = l1.computeSize(SWT.DEFAULT, SWT.DEFAULT).y;
			l2.setLayoutData(gd);
		}
		{
			_flags = new Table(left, SWT.SINGLE | SWT.FULL_SELECTION | SWT.BORDER | SWT.V_SCROLL);
			mod(_flags);
			_incSearch = new IncSearch(comm, _flags);
			_incSearch.modEvent ~= &refreshList;
			new FullTableColumn(_flags, SWT.NONE);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.heightHint = _prop.var.etc.nameTableHeight;
			_flags.setLayoutData(gd);
			_flags.addSelectionListener(new SListener);

			_flags.addMouseListener(new OpenView);
			auto menu = new Menu(_flags.getShell(), SWT.POP_UP);
			createMenuItem(comm, menu, MenuID.IncSearch, &incSearch, null);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(comm, menu, MenuID.OpenAtVarView, &openView, () => _flags.getSelectionIndex() != -1);
			_flags.setMenu(menu);
		}
		{
			_values = new Table(right, SWT.SINGLE | SWT.FULL_SELECTION | SWT.BORDER | SWT.V_SCROLL);
			new FullTableColumn(_values, SWT.NONE);
			mod(_values);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.heightHint = _prop.var.etc.nameTableHeight;
			_values.setLayoutData(gd);
			_values.setEnabled(SelValue);
			_values.addSelectionListener(new ValSListener);
		}
		static if (Type is CType.CHECK_STEP) {
			auto comp = new Composite(area, SWT.NONE);
			comp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			comp.setLayout(zeroMarginGridLayout(2, false));
			_cmpLabel = new Label(comp, SWT.RIGHT);
			_cmpLabel.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			_cmp = new Combo(comp, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
			mod(_cmp);
			_cmp.setVisibleItemCount(prop.var.etc.comboVisibleItemCount);
			foreach (cmp; EnumMembers!Comparison4) {
				_cmp.add(prop.msgs.comparison4Name(cmp));
				_cmps ~= cmp;
			}
		}

		_comm.refFlagAndStep.add(&refFS);
		_comm.delFlagAndStep.add(&delFS);
		_flags.addDisposeListener(new Dispose);

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		refreshList();
		if (_evt) {
			static if (is (F == Flag)) {
				_selected = _evt.flag;
			} else static if (is (F == Step)) {
				_selected = _evt.step;
			} else {
				static assert (0);
			}
			int index = -1;
			foreach (i, itm; _flags.getItems()) {
				if ((cast(F) itm.getData()).path == _selected) {
					index = i;
					break;
				}
			}
			index = index >= 0 ? index : 0;
			_flags.select(index);
			_selected = (cast(F) _flags.getItem(index).getData()).path;
			_flags.showSelection();
			refreshValues();
			static if (SelValue) {
				static if (is (F == Flag)) {
					_values.select(_evt.flagValue ? 0 : 1);
				} else static if (is (F == Step)) {
					_values.select(_evt.stepValue);
				} else {
					static assert (0);
				}
			}
			static if (Type is CType.CHECK_STEP) {
				_cmp.select(_cmps.countUntil(_evt.comparison4));
			}
		} else {
			_flags.select(0);
			_selected = (cast(F) _flags.getItem(0).getData()).path;
			refreshValues();
			static if (Type is CType.CHECK_STEP) {
				_cmp.select(0);
			}
		}
		updateLabel();
		refreshWarning();
		_sash.setWeights([_prop.var.etc.flagEventSashL, _prop.var.etc.flagEventSashR]);
	}

	override bool apply() {
		assert (_flags.getItemCount() > 0);
		if (!_evt) _evt = new Content(Type, "");
		static if (is (F == Flag)) {
			_evt.flag = _selected;
			static if (SelValue) {
				_evt.flagValue = _values.getSelectionIndex() == 0;
			}
		} else static if (is (F == Step)) {
			_evt.step = _selected;
			static if (SelValue) {
				_evt.stepValue = _values.getSelectionIndex();
			}
		} else {
			static assert (0);
		}
		static if (Type is CType.CHECK_STEP) {
			_evt.comparison4 = _cmps[_cmp.getSelectionIndex()];
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
alias FlagStepDialog!(CType.CHECK_STEP, Step, true) CheckStepDialog;

/// フラグ・ステップの組み合わせを選択するダイアログ。
private class FlagStepCombiDialog(CType Type, F, bool Random) : EventDialog {
private:
	FlagDir _root;

	SplitPane _sash;
	Table _flags1;
	Table _flags2;

	string _selected1;
	string _selected2;

	void refreshWarning() {
		string[] ws;
		ws ~= .tryFormat(_prop.msgs.warningUnknownContent, _prop.msgs.contentName(Type));
		warning = ws;
	}

	IncSearch _incSearch1;
	IncSearch _incSearch2;
	void incSearch1() {
		.forceFocus(_flags1, true);
		_incSearch1.startIncSearch();
	}
	void incSearch2() {
		.forceFocus(_flags2, true);
		_incSearch2.startIncSearch();
	}

	string getPath(TableItem itm) {
		auto f = cast(F) itm.getData();
		static if (Random) {
			return f ? f.path : prop.sys.randomValue;
		} else {
			assert (f !is null);
			return f.path;
		}
	}

	@property
	string listSelected1() {
		int index = _flags1.getSelectionIndex();
		if (-1 == index) return "";
		return getPath(_flags1.getItem(index));
	}
	@property
	string listSelected2() {
		int index = _flags2.getSelectionIndex();
		if (-1 == index) return "";
		return getPath(_flags2.getItem(index));
	}

	class SListener : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			auto flags = cast(Table) e.widget;
			int index = flags.getSelectionIndex();
			if (-1 != index) {
				string selPath = getPath(flags.getItem(index));
				if (_flags1 is flags) {
					_selected1 = selPath;
				} else {
					assert (_flags2 is flags);
					_selected2 = selPath;
				}
			}
		}
	}
	void refreshList() {
		static if (is (F == Flag)) {
			auto flags = _root.allFlags;
		} else static if (is (F == Step)) {
			auto flags = _root.allSteps;
		} else static assert (0);
		string sel1 = _selected1;
		string sel2 = _selected2;
		_flags1.removeAll();
		_flags2.removeAll();
		bool has1 = false;
		bool has2 = false;
		void put(F flag, string path, string text, Table flags, string sel) {
			auto itm = new TableItem(flags, SWT.NONE);
			itm.setData(flag);
			itm.setText(text);
			if (flag) {
				static if (is(F : Flag)) {
					itm.setImage(_prop.images.flag);
				} else static if (is(F : Step)) {
					itm.setImage(_prop.images.step);
				} else static assert (0);
			}
			if (path == sel) flags.select(flags.getItemCount() - 1);
		}
		static if (Random) {
			{
				auto path = prop.sys.randomValue;
				if (!has1 && path == sel1) has1 = true;
				put(null, path, prop.msgs.randomValue, _flags1, sel1);
			}
		}
		foreach (flag; flags) {
			auto path = flag.path;
			if (!has1 && path == sel1) has1 = true;
			if (!has2 && path == sel2) has2 = true;
			if (_incSearch1.match(path)) {
				put(flag, path, path, _flags1, sel1);
			}
			if (_incSearch2.match(path)) {
				put(flag, path, path, _flags2, sel2);
			}
		}
		if (!has1 && _flags1.getItemCount()) {
			_flags1.select(0);
			_selected1 = getPath(_flags1.getItem(0));
		}
		if (!has2 && _flags2.getItemCount()) {
			_flags2.select(0);
			_selected2 = getPath(_flags2.getItem(0));
		}
	}
	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			_comm.refFlagAndStep.remove(&refFS);
			_comm.delFlagAndStep.remove(&delFS);
		}
	}
	void refFS(Flag[] f, Step[] s) {
		static if (is(F : Flag)) {
			if (!f.length) return;
		} else {
			if (!s.length) return;
		}
		refreshList();
	}
	void delFS(Flag[] f, Step[] s) {
		static if (is(F : Flag)) {
			if (!f.length) return;
		} else {
			if (!s.length) return;
		}
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

	void openViewImpl(Table flags) {
		auto i = flags.getSelectionIndex();
		if (-1 == i) return;
		auto a = cast(F) flags.getItem(i).getData();
		try {
			_comm.openCWXPath(cpaddattr(a.cwxPath(true), "shallow"), false);
		} catch (Exception e) {
			debugln(e);
		}
	}
	void openView1() {openViewImpl(_flags1);}
	void openView2() {openViewImpl(_flags2);}
	class OpenView : MouseAdapter {
		override void mouseDoubleClick(MouseEvent e) {
			if (1 != e.button) return;
			openViewImpl(cast(Table) e.widget);
		}
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt, FlagDir root) {
		_root = root;
		super (comm, prop, shell, summ, Type, parent, evt, true, prop.var.flagCombiDlg, true);
		closeEvent ~= {
			auto ws = _sash.getWeights();
			_prop.var.etc.flagCombiSashL = ws[0];
			_prop.var.etc.flagCombiSashR = ws[1];
		};
	}
protected:
	override void setup(Composite area) {
		area.setLayout(new GridLayout(1, true));
		_sash = new SplitPane(area, SWT.HORIZONTAL);
		_sash.setLayoutData(new GridData(GridData.FILL_BOTH));
		auto left = new Composite(_sash, SWT.NONE);
		left.setLayout(zeroGridLayout(1));
		auto right = new Composite(_sash, SWT.NONE);
		right.setLayout(zeroGridLayout(1));
		{
			auto l1 = new CLabel(left, SWT.NONE);
			auto l2 = new CLabel(right, SWT.NONE);
			static if (Type == CType.SUBSTITUTE_STEP || Type == CType.SUBSTITUTE_FLAG) {
				l1.setText(_prop.msgs.substituteSource);
				l2.setText(_prop.msgs.substituteTarget);
			} else static if (Type == CType.BRANCH_STEP_CMP || Type == CType.BRANCH_FLAG_CMP) {
				l1.setText(_prop.msgs.cmpSource);
				l2.setText(_prop.msgs.cmpTarget);
			} else static assert (0);
			static if (is (F == Flag)) {
				l1.setImage(_prop.images.flag);
				l2.setImage(_prop.images.flag);
			} else static if (is (F == Step)) {
				l1.setImage(_prop.images.step);
				l2.setImage(_prop.images.step);
			} else {
				static assert (0);
			}
		}
		void createList(Composite comp, ref Table flags, ref IncSearch incSearch, void delegate() openView, void delegate() startSearch) {
			flags = new Table(comp, SWT.SINGLE | SWT.FULL_SELECTION | SWT.BORDER | SWT.V_SCROLL);
			mod(flags);
			incSearch = new IncSearch(comm, flags);
			incSearch.modEvent ~= &refreshList;
			new FullTableColumn(flags, SWT.NONE);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.heightHint = _prop.var.etc.nameTableHeight;
			flags.setLayoutData(gd);
			flags.addSelectionListener(new SListener);

			flags.addMouseListener(new OpenView);
			auto menu = new Menu(flags.getShell(), SWT.POP_UP);
			createMenuItem(comm, menu, MenuID.IncSearch, startSearch, null);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(comm, menu, MenuID.OpenAtVarView, openView, () => flags.getSelectionIndex() != -1);
			flags.setMenu(menu);
		}
		createList(left, _flags1, _incSearch1, &openView1, &incSearch1);
		createList(right, _flags2, _incSearch2, &openView2, &incSearch2);

		_comm.refFlagAndStep.add(&refFS);
		_comm.delFlagAndStep.add(&delFS);
		_sash.addDisposeListener(new Dispose);

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		refreshList();
		if (_evt) {
			static if (is (F == Flag)) {
				_selected1 = _evt.flag;
				_selected2 = _evt.flag2;
			} else static if (is (F == Step)) {
				_selected1 = _evt.step;
				_selected2 = _evt.step2;
			} else {
				static assert (0);
			}
			void put(Table flags, ref string selected) {
				int index = -1;
				foreach (i, itm; flags.getItems()) {
					if (getPath(itm) == selected) {
						index = i;
						break;
					}
				}
				index = index >= 0 ? index : 0;
				flags.select(index);
				selected = getPath(flags.getItem(index));
				flags.showSelection();
			}
			put(_flags1, _selected1);
			put(_flags2, _selected2);
		} else {
			_flags1.select(0);
			_flags2.select(0);
			_selected1 = getPath(_flags1.getItem(0));
			_selected2 = getPath(_flags2.getItem(0));
		}
		refreshWarning();
		_sash.setWeights([_prop.var.etc.flagCombiSashL, _prop.var.etc.flagCombiSashR]);
	}

	override bool apply() {
		assert (_flags1.getItemCount() > 0);
		assert (_flags2.getItemCount() > 0);
		if (!_evt) _evt = new Content(Type, "");
		static if (is (F == Flag)) {
			_evt.flag = _selected1;
			_evt.flag2 = _selected2;
		} else static if (is (F == Step)) {
			_evt.step = _selected1;
			_evt.step2 = _selected2;
		} else {
			static assert (0);
		}
		return true;
	}
}

alias FlagStepCombiDialog!(CType.SUBSTITUTE_STEP, Step, true) SubstituteStepDialog;
alias FlagStepCombiDialog!(CType.SUBSTITUTE_FLAG, Flag, true) SubstituteFlagDialog;
alias FlagStepCombiDialog!(CType.BRANCH_STEP_CMP, Step, false) BrStepCmpDialog;
alias FlagStepCombiDialog!(CType.BRANCH_FLAG_CMP, Flag, false) BrFlagCmpDialog;

/// メンバ選択分岐の設定を行うダイアログ。
class BrMemberDialog : EventDialog {
private:
	// FIXME: KeyTypeにboolを使えない？
	Button[] _all;
	Button[] _random;

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) {
		super (comm, prop, shell, summ, CType.BRANCH_SELECT, parent, evt, false, null, true);
	}
protected:
	override void setup(Composite area) {
		area.setLayout(new GridLayout(2, false));
		void createR(string title, string trueText, string falseText, ref Button[] btns) {
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(new CenterLayout);
			grp.setText(title);
			auto comp = new Composite(grp, SWT.NONE);
			comp.setLayout(zeroMarginGridLayout(1, true));
			auto btnT = new Button(comp, SWT.RADIO);
			mod(btnT);
			btnT.setText(trueText);
			auto btnF = new Button(comp, SWT.RADIO);
			mod(btnF);
			btnF.setText(falseText);
			btns.length = 2;
			btns[0] = btnT;
			btns[1] = btnF;
		}
		createR(_prop.msgs.selectMember, _prop.msgs.activeMember, _prop.msgs.allMember, _all);
		createR(_prop.msgs.selectMethod, _prop.msgs.manualMethod, _prop.msgs.randomMethod, _random);

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) {
			_all[_evt.targetAll ? 1 : 0].setSelection(true);
			_random[_evt.random ? 1 : 0].setSelection(true);
		} else {
			_all[0].setSelection(true);
			_random[0].setSelection(true);
		}
	}

	override bool apply() {
		if (!_evt) _evt = new Content(CType.BRANCH_SELECT, "");
		_evt.targetAll = _all[1].getSelection();
		_evt.random = _random[1].getSelection();
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
		area.setLayout(new GridLayout(3, false));
		{
			auto comp = new Composite(area, SWT.NONE);
			comp.setLayout(zeroMarginGridLayout(1, true));
			{
				auto grp = new Group(comp, SWT.NONE);
				grp.setText(_prop.msgs.targetLevel);
				grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				grp.setLayout(new GridLayout(2, false));
				_lev = new Spinner(grp, SWT.BORDER);
				mod(_lev);
				_lev.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				_lev.setMinimum(-(cast(int) _prop.var.etc.castLevelMax));
				_lev.setMaximum(_prop.var.etc.castLevelMax);
				auto l = new Label(grp, SWT.NONE);
				l.setText(.tryFormat(_prop.msgs.rangeHint, _lev.getMinimum(), _lev.getMaximum()));
			}
			{
				auto grp = new Group(comp, SWT.NONE);
				grp.setText(_prop.msgs.judgeTarget);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setLayout(new GridLayout(1, true));
				foreach (m; [Target.M.SELECTED, Target.M.RANDOM, Target.M.PARTY]) {
					auto radio = new Button(grp, SWT.RADIO);
					mod(radio);
					radio.setText(_prop.msgs.targetName(m));
					radio.setLayoutData(new GridData(GridData.FILL_BOTH));
					_targ[m] = radio;
				}
			}
			{
				auto grp = new Group(comp, SWT.NONE);
				grp.setText(_prop.msgs.judgeSleep);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setLayout(new GridLayout(1, true));
				_sleep[1] = new Button(grp, SWT.RADIO);
				mod(_sleep[1]);
				_sleep[1].setText(_prop.msgs.sleepDisabled);
				_sleep[0] = new Button(grp, SWT.RADIO);
				mod(_sleep[0]);
				_sleep[0].setText(_prop.msgs.sleepEnabled);
			}
		}
		{
			auto grp = new Group(area, SWT.NONE);
			grp.setText(_prop.msgs.aptPhysical);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto cl = new CenterLayout(SWT.HORIZONTAL, 0);
			cl.fillVertical = true;
			grp.setLayout(cl);
			auto comp2 = new Composite(grp, SWT.NONE);
			comp2.setLayout(new GridLayout(1, true));
			foreach (phy; [Physical.DEX, Physical.AGL, Physical.INT,
					Physical.STR, Physical.VIT, Physical.MIN]) {
				auto radio = new Button(comp2, SWT.RADIO);
				mod(radio);
				radio.setLayoutData(new GridData(GridData.FILL_VERTICAL));
				radio.setText(_prop.msgs.physicalName(phy));
				_phy[phy] = radio;
			}
		}
		{
			auto grp = new Group(area, SWT.NONE);
			grp.setText(_prop.msgs.aptMental);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto cl = new CenterLayout(SWT.HORIZONTAL, 0);
			cl.fillVertical = true;
			grp.setLayout(cl);
			auto comp2 = new Composite(grp, SWT.NONE);
			comp2.setLayout(new GridLayout(2, true));
			static const Ms = [Mental.AGGRESSIVE, Mental.UNAGGRESSIVE,
				Mental.CHEERFUL, Mental.UNCHEERFUL,
				Mental.BRAVE, Mental.UNBRAVE, Mental.CAUTIOUS, Mental.UNCAUTIOUS,
				Mental.TRICKISH, Mental.UNTRICKISH];
			foreach (i, m; Ms) {
				auto radio = new Button(comp2, SWT.RADIO);
				mod(radio);
				radio.setLayoutData(new GridData(GridData.FILL_BOTH));
				radio.setText(_prop.msgs.mentalName(m));
				_mtl[m] = radio;
			}
		}
		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) {
			_lev.setSelection(_evt.signedLevel);
			_targ[_evt.targetS.m].setSelection(true);
			_sleep[_evt.targetS.sleep ? 0 : 1].setSelection(true);
			_phy[_evt.physical].setSelection(true);
			_mtl[_evt.mental].setSelection(true);
		} else {
			_lev.setSelection(0);
			_targ[Target.M.SELECTED].setSelection(true);
			_sleep[1].setSelection(true);
			_phy[Physical.DEX].setSelection(true);
			_mtl[Mental.AGGRESSIVE].setSelection(true);
		}
	}

	override bool apply() {
		if (!_evt) _evt = new Content(CType.BRANCH_ABILITY, "");
		auto targ = Target(getRadioValue!(Target.M)(_targ), _sleep[0].getSelection());
		_evt.signedLevel = _lev.getSelection();
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
		area.setLayout(new GridLayout(2, false));
		{
			auto grp = new Group(area, SWT.NONE);
			grp.setText(_prop.msgs.judgeTarget);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(new CenterLayout);
			auto comp = new Composite(grp, SWT.NONE);
			comp.setLayout(zeroMarginGridLayout(1, true));
			_ave[1] = new Button(comp, SWT.RADIO);
			mod(_ave[1]);
			_ave[1].setText(_prop.msgs.selectedLevel);
			_ave[0] = new Button(comp, SWT.RADIO);
			mod(_ave[0]);
			_ave[0].setText(_prop.msgs.allMemberLevel);
		}
		{
			auto grp = new Group(area, SWT.NONE);
			grp.setText(_prop.msgs.judgeLevel);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(new CenterLayout);
			auto comp = new Composite(grp, SWT.NONE);
			comp.setLayout(zeroMarginGridLayout(2, false));
			_lev = new Spinner(comp, SWT.BORDER);
			mod(_lev);
			_lev.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			_lev.setMinimum(1);
			_lev.setMaximum(_prop.var.etc.castLevelMax);
			auto l = new Label(comp, SWT.NONE);
			l.setText(.tryFormat(_prop.msgs.rangeHint, _lev.getMinimum(), _lev.getMaximum()));
		}

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) {
			_ave[_evt.average ? 0 : 1].setSelection(true);
			_lev.setSelection(_evt.unsignedLevel);
		} else {
			_ave[1].setSelection(true);
			_lev.setSelection(1);
		}
	}

	override bool apply() {
		if (!_evt) _evt = new Content(CType.BRANCH_LEVEL, "");
		_evt.average = _ave[0].getSelection();
		_evt.unsignedLevel = _lev.getSelection();
		return true;
	}
}

private Composite createStatusPane(Props prop, Composite area, ref Button[Status] stat, void delegate(Button) mod) {
	auto grp = new Group(area, SWT.NONE);
	grp.setText(prop.msgs.judgeState);
	grp.setLayout(new GridLayout(4, true));
	auto statuses = [Status.ACTIVE, Status.INACTIVE, Status.ALIVE, Status.DEAD,
			Status.FINE, Status.INJURED, Status.HEAVY_INJURED, Status.UNCONSCIOUS,
			Status.POISON, Status.SLEEP, Status.BIND, Status.PARALYZE,
			Status.CONFUSE, Status.OVERHEAT, Status.BRAVE, Status.PANIC,
			Status.SILENCE, Status.FACE_UP, Status.ANTI_MAGIC,
			Status.UP_ACTION, Status.UP_AVOID, Status.UP_RESIST, Status.UP_DEFENSE,
			Status.DOWN_ACTION, Status.DOWN_AVOID, Status.DOWN_RESIST, Status.DOWN_DEFENSE];
	foreach (s; statuses) {
		auto radio = new Button(grp, SWT.RADIO);
		mod(radio);
		radio.setText(prop.msgs.statusName(s));
		radio.setLayoutData(new GridData(GridData.FILL_BOTH));
		stat[s] = radio;
	}
	return grp;
}
private Composite createStatusHint(Props prop, Composite area) {
	auto grp = new Group(area, SWT.NONE);
	grp.setText(prop.msgs.stateHint);
	grp.setLayout(new CenterLayout);
	auto comp = new Composite(grp, SWT.NONE);
	comp.setLayout(zeroMarginGridLayout(1, true));
	auto hint1 = new Label(comp, SWT.NONE);
	hint1.setText(prop.msgs.statusActive);
	auto hint2 = new Label(comp, SWT.NONE);
	hint2.setText(prop.msgs.statusInactive);
	auto hint3 = new Label(comp, SWT.NONE);
	hint3.setText(prop.msgs.statusAlive);
	auto hint4 = new Label(comp, SWT.NONE);
	hint4.setText(prop.msgs.statusDead);
	return grp;
}

/// 状態分岐の設定を行うダイアログ。
class BrStateDialog : EventDialog {
private:
	Button[Target.M] _targ;
	Button[Status] _stat;

	void refreshWarning() {
		string[] ws;
		foreach (st; [Status.CONFUSE, Status.OVERHEAT, Status.BRAVE, Status.PANIC]) {
			if (_stat[st].getSelection()) {
				ws ~= .tryFormat(prop.msgs.warningBranchStatusMental, prop.msgs.statusName(st));
			}
		}
		warning = ws;
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) {
		super (comm, prop, shell, summ, CType.BRANCH_STATUS, parent, evt, false, null, true);
	}
protected:
	override void setup(Composite area) {
		area.setLayout(new GridLayout(1, false));
		{
			auto grp = new Group(area, SWT.NONE);
			grp.setText(_prop.msgs.judgeTarget);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(new GridLayout(3, true));
			foreach (m; [Target.M.SELECTED, Target.M.RANDOM, Target.M.PARTY]) {
				auto radio = new Button(grp, SWT.RADIO);
				mod(radio);
				radio.setText(_prop.msgs.targetName(m));
				radio.setLayoutData(new GridData(GridData.FILL_BOTH));
				_targ[m] = radio;
			}
		}
		auto status = createStatusPane(prop, area, _stat, &mod!Button);
		status.setLayoutData(new GridData(GridData.FILL_BOTH));
		foreach (st, b; _stat) {
			.listener(b, SWT.Selection, &refreshWarning);
		}
		auto hint = createStatusHint(prop, area);
		hint.setLayoutData(new GridData(GridData.FILL_BOTH));

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) {
			_targ[_evt.targetNS.m].setSelection(true);
			_stat[_evt.status].setSelection(true);
		} else {
			_targ[Target.M.SELECTED].setSelection(true);
			_stat[Status.ACTIVE].setSelection(true);
		}
		refreshWarning();
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
				_num.setEnabled(!_allDel.getSelection());
			}
		}
	}
	Button[Range] _range;
	Table _list;
	IncSearch _incSearch;
	void incSearch() {
		.forceFocus(_list, true);
		_incSearch.startIncSearch();
	}

	ulong _selectedID = 0;
	void selected() {
		auto index = _list.getSelectionIndex();
		if (-1 != index) {
			_selectedID = (cast(C) _list.getItem(index).getData()).id;
		}
	}

	void refreshList() {
		ulong id = _selectedID;
		_list.removeAll();
		size_t i = 0;
		foreach (c; mixin (Cards)) {
			if (!_incSearch.match(c.name)) continue;
			auto itm = new TableItem(_list, SWT.NONE);
			itm.setData(c);
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
			if (id == c.id) _list.select(i);
			i++;
		}
		_list.showSelection();
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

	void openView() {
		auto i = _list.getSelectionIndex();
		if (-1 == i) return;
		auto a = cast(C) _list.getItem(i).getData();
		try {
			_comm.openCWXPath(cpaddattr(a.cwxPath(true), "shallow"), false);
		} catch (Exception e) {
			debugln(e);
		}
	}
	class OpenView : MouseAdapter {
		override void mouseDoubleClick(MouseEvent e) {
			if (1 != e.button) return;
			openView();
		}
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) {
		super (comm, prop, shell, summ, Type, parent, evt, true, prop.var.cardEvtDlg, true);
	}
protected:
	override void setup(Composite area) {
		area.setLayout(new GridLayout(2, false));
		{
			auto comp = new Composite(area, SWT.NONE);
			comp.setLayoutData(new GridData(GridData.FILL_VERTICAL));
			comp.setLayout(zeroMarginGridLayout(1, true));
			{
				auto grp = new Group(comp, SWT.NONE);
				grp.setText(_prop.msgs.cardNumber);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				auto cl = new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0);
				cl.fillHorizontal = true;
				grp.setLayout(cl);
				auto comp2 = new Composite(grp, SWT.NONE);
				comp2.setLayout(new GridLayout(2, false));
				_num = new Spinner(comp2, SWT.BORDER);
				mod(_num);
				_num.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				_num.setMinimum(1);
				_num.setMaximum(_prop.var.etc.cardNumberMax);
				auto l = new Label(comp2, SWT.NONE);
				l.setText(.tryFormat(_prop.msgs.rangeHint, _num.getMinimum(), _num.getMaximum()));
				static if (Delete) {
					_allDel = new Button(comp2, SWT.CHECK);
					mod(_allDel);
					_allDel.setText(_prop.msgs.cardAllDelete);
					auto gd = new GridData;
					gd.horizontalSpan = 2;
					_allDel.setLayoutData(gd);
					_allDel.addSelectionListener(new DelSListener);
				}
			}
			{
				auto grp = new Group(comp, SWT.NONE);
				grp.setText(_prop.msgs.cardEventRange);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setLayout(new GridLayout(1, true));
				foreach (r; [Range.SELECTED, Range.RANDOM, Range.PARTY,
						Range.BACKPACK, Range.PARTY_AND_BACKPACK, Range.FIELD]) {
					auto radio = new Button(grp, SWT.RADIO);
					mod(radio);
					radio.setText(_prop.msgs.rangeName(r));
					radio.setLayoutData(new GridData(GridData.FILL_BOTH));
					_range[r] = radio;
				}
			}
		}
		{
			_list = new Table(area, SWT.SINGLE | SWT.FULL_SELECTION | SWT.BORDER | SWT.V_SCROLL);
			mod(_list);
			_incSearch = new IncSearch(comm, _list);
			_incSearch.modEvent ~= &refreshList;
			auto idCol = new TableColumn(_list, SWT.NONE);
			saveColumnWidth!("prop.var.etc.idColumn")(_prop, idCol);
			auto nameCol = new FullTableColumn(_list, SWT.NONE);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.widthHint = _prop.var.etc.nameTableWidth;
			gd.heightHint = _prop.var.etc.nameTableHeight;
			_list.setLayoutData(gd);
			.listener(_list, SWT.Selection, &selected);

			_list.addMouseListener(new OpenView);
			auto menu = new Menu(_list.getShell(), SWT.POP_UP);
			createMenuItem(comm, menu, MenuID.IncSearch, &incSearch, null);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(comm, menu, MenuID.OpenAtCardView, &openView, () => _list.getSelectionIndex() != -1);
			_list.setMenu(menu);

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
			static if (is (C == SkillCard)) {
				_selectedID = _evt.skill;
			} else static if (is (C == ItemCard)) {
				_selectedID = _evt.item;
			} else static if (is (C == BeastCard)) {
				_selectedID = _evt.beast;
			} else {
				static assert (0);
			}
			foreach (i, itm; _list.getItems()) {
				if (_selectedID == (cast(C) itm.getData()).id) {
					_list.select(i);
					break;
				}
			}

			static if (Delete) {
				if (_evt.cardNumber == 0u) {
					_allDel.setSelection(true);
					_num.setSelection(1);
					_num.setEnabled(false);
				} else {
					_allDel.setSelection(false);
					_num.setSelection(_evt.cardNumber);
				}
			} else {
				_num.setSelection(_evt.cardNumber);
			}
			_range[_evt.range].setSelection(true);
		} else {
			static if (Delete) {
				_allDel.setSelection(false);
			}
			_num.setSelection(1);
			_range[RangeDef].setSelection(true);
		}
		assert (_list.getItemCount());
		if (-1 == _list.getSelectionIndex()) {
			_list.select(0);
			_selectedID = (cast(C) _list.getItem(0).getData()).id;
		}
	}

	override bool apply() {
		assert (_list.getItemCount());
		if (!_evt) _evt = new Content(Type, "");
		static if (is (C == SkillCard)) {
			_evt.skill = _selectedID;
		} else static if (is (C == ItemCard)) {
			_evt.item = _selectedID;
		} else static if (is (C == BeastCard)) {
			_evt.beast = _selectedID;
		} else {
			static assert (0);
		}
		_evt.range = getRadioValue!(Range)(_range);
		static if (Delete) {
			if (_allDel.getSelection()) {
				_evt.cardNumber = 0u;
			} else {
				_evt.cardNumber = _num.getSelection();
			}
		} else {
			_evt.cardNumber = _num.getSelection();
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
		area.setLayout(new GridLayout(1, false));
		{
			auto grp = new Group(area, SWT.NONE);
			grp.setText(_prop.msgs.transitionType);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(new CenterLayout);
			auto comp = new Composite(grp, SWT.NONE);
			comp.setLayout(zeroMarginGridLayout(3, false));
			auto lt = new Label(comp, SWT.NONE);
			lt.setText(_prop.msgs.transition);
			_ts = new Combo(comp, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
			mod(_ts);
			auto gd = new GridData;
			gd.horizontalSpan = 2;
			_ts.setLayoutData(gd);
			_ts.setVisibleItemCount(prop.var.etc.comboVisibleItemCount);
			foreach (i, t; ALL_TRANSITION) {
				_ts.add(_prop.msgs.transitionName(t));
				_tsTbl[i] = t;
				if (_evt && t == _evt.transition) _ts.select(i);
			}
			auto ls = new Label(comp, SWT.NONE);
			ls.setText(_prop.msgs.transitionSpeed);
			_tsSpeed = new Spinner(comp, SWT.BORDER);
			mod(_tsSpeed);
			_tsSpeed.setMaximum(Content.transitionSpeed_max);
			_tsSpeed.setMinimum(Content.transitionSpeed_min);
			auto hint = new Label(comp, SWT.NONE);
			hint.setText(.tryFormat(_prop.msgs.rangeHint, Content.transitionSpeed_min, Content.transitionSpeed_max));
		}
		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) {
			_tsSpeed.setSelection(_evt.transitionSpeed);
		} else {
			_ts.select(0);
			_tsSpeed.setSelection(.transitionSpeedDef);
		}
	}

	override bool apply() {
		if (!_evt) _evt = new Content(CType.REDISPLAY, "");
		auto ts = _tsTbl[_ts.getSelectionIndex()];
		uint tsSpeed = _tsSpeed.getSelection();
		_evt.transition = ts;
		_evt.transitionSpeed = tsSpeed;
		return true;
	}
}

/// ランダム選択分岐の設定を行うダイアログ。
class BrRandomSelectDialog : EventDialog {
private:
	Button[CastRange] _castRange;
	Button _hasLevel, _hasStatus;
	Spinner _levMin, _levMax;
	Button[Status] _status;

	void refreshWarning()  {
		string[] ws;
		ws ~= .tryFormat(_prop.msgs.warningUnknownContent, _prop.msgs.contentName(CType.BRANCH_RANDOM_SELECT));
		warning = ws;
	}

	void levMaxEnter(int enter) {
		if (enter > 0 && _levMin.getSelection() != 0 && enter < _levMin.getSelection()) {
			_levMin.setSelection(enter);
		}
	}
	void levMinEnter(int enter) {
		if (enter > 0 && _levMax.getSelection() != 0 && enter > _levMax.getSelection()) {
			_levMax.setSelection(enter);
		}
	}

	void updateEnabled() {
		_levMin.setEnabled(_hasLevel.getSelection());
		_levMax.setEnabled(_hasLevel.getSelection());
		foreach (key, b; _status) {
			b.setEnabled(_hasStatus.getSelection());
		}
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) {
		super (comm, prop, shell, summ, CType.BRANCH_RANDOM_SELECT, parent, evt, false, null, true);
	}
protected:
	override void setup(Composite area) {
		area.setLayout(new GridLayout(1, false));
		{
			auto grp = new Group(area, SWT.NONE);
			grp.setText(_prop.msgs.selectMember);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(new GridLayout(3, true));
			foreach (r; EnumMembers!CastRange) {
				auto radio = new Button(grp, SWT.CHECK);
				mod(radio);
				radio.setText(prop.msgs.castRangeName(r));
				radio.setLayoutData(new GridData(GridData.FILL_BOTH));
				_castRange[r] = radio;
			}

			auto sep = new Label(grp, SWT.SEPARATOR | SWT.HORIZONTAL);
			auto sgd = new GridData(GridData.FILL_HORIZONTAL);
			sgd.horizontalSpan = 3;
			sep.setLayoutData(sgd);

			_hasLevel = new Button(grp, SWT.CHECK);
			mod(_hasLevel);
			_hasLevel.setText(prop.msgs.randomSelectHasLevel);
			_hasLevel.setLayoutData(new GridData(GridData.FILL_BOTH));
			.listener(_hasLevel, SWT.Selection, &updateEnabled);

			_hasStatus = new Button(grp, SWT.CHECK);
			mod(_hasStatus);
			_hasStatus.setText(prop.msgs.randomSelectHasStatus);
			_hasStatus.setLayoutData(new GridData(GridData.FILL_BOTH));
			.listener(_hasStatus, SWT.Selection, &updateEnabled);
		}
		{
			auto grp = new Group(area, SWT.NONE);
			grp.setText(_prop.msgs.targetLevel);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(new CenterLayout);
			auto comp = new Composite(grp, SWT.NONE);
			comp.setLayout(zeroMarginGridLayout(4, false));

			_levMin = new Spinner(comp, SWT.BORDER);
			mod(_levMin);
			_levMin.setMinimum(1);
			_levMin.setMaximum(_prop.var.etc.castLevelMax);
			new SpinnerEdit(_levMin, &levMinEnter);
			auto lbl = new Label(comp, SWT.NONE);
			lbl.setText(_prop.msgs.levSep);
			_levMax = new Spinner(comp, SWT.BORDER);
			mod(_levMax);
			_levMax.setMinimum(1);
			_levMax.setMaximum(_prop.var.etc.castLevelMax);
			new SpinnerEdit(_levMax, &levMaxEnter);
			auto lHint = new Label(comp, SWT.NONE);
			lHint.setText(.tryFormat(_prop.msgs.rangeHint, 1, _prop.var.etc.castLevelMax));
		}
		auto status = createStatusPane(prop, area, _status, &mod!Button);
		status.setLayoutData(new GridData(GridData.FILL_BOTH));
		auto hint = createStatusHint(prop, area);
		hint.setLayoutData(new GridData(GridData.FILL_BOTH));

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) {
			foreach (e; _evt.castRange) {
				_castRange[e].setSelection(true);
			}
			_hasLevel.setSelection(0 < _evt.levelMax);
			_hasStatus.setSelection(Status.NONE !is _evt.status);
			if (_hasLevel.getSelection()) {
				_levMin.setSelection(_evt.levelMin);
				_levMax.setSelection(_evt.levelMax);
			} else {
				_levMin.setSelection(1);
				_levMax.setSelection(1);
			}
			if (_hasStatus.getSelection()) {
				_status[_evt.status].setSelection(true);
			} else {
				_status[Status.ACTIVE].setSelection(true);
			}
		} else {
			_castRange[CastRange.PARTY].setSelection(true);
			_hasLevel.setSelection(false);
			_hasStatus.setSelection(false);
			_levMin.setSelection(1);
			_levMax.setSelection(1);
			_status[Status.ACTIVE].setSelection(true);
		}
		updateEnabled();
		refreshWarning();
	}

	override bool apply() {
		if (!_evt) _evt = new Content(CType.BRANCH_RANDOM_SELECT, "");
		CastRange[] range;
		foreach (e, b; _castRange) {
			if (b.getSelection()) range ~= e;
		}
		_evt.castRange = range;
		bool hasLevel = _hasLevel.getSelection();
		bool hasStatus = _hasStatus.getSelection();
		if (hasLevel) {
			_evt.levelMin = _levMin.getSelection();
			_evt.levelMax = _levMax.getSelection();
		} else {
			_evt.levelMin = 0;
			_evt.levelMax = 0;
		}
		if (hasStatus) {
			_evt.status = getRadioValue!(Status)(_status);
		} else {
			_evt.status = Status.NONE;
		}
		return true;
	}
}

/// キーコード所持判定の設定を行うダイアログ。
class BrKeyCodeDialog : EventDialog {
private:
	Button[Range] _keyCodeRange;
	Button[EffectCardType] _effectCardType;
	Combo _keyCode;
	IncSearch _incSearch;
	void incSearch() {
		.forceFocus(_keyCode, true);
		_incSearch.startIncSearch();
	}

	void refreshWarning()  {
		string[] ws;
		ws ~= .tryFormat(_prop.msgs.warningUnknownContent, _prop.msgs.contentName(CType.BRANCH_KEY_CODE));
		warning = ws;
	}

	void refStandardKeyCodes() {
		string id = _keyCode.getText();
		_keyCode.removeAll();

		string[] stdKCs = _prop.var.etc.standardKeyCodes.dup;

		auto kcs = summ.useCounter.keyCode.keys;
		string[] kcs2;
		foreach (string kc; kcs.sort) {
			if (!.contains(stdKCs, kc)) {
				kcs2 ~= kc;
			}
		}

		if (kcs2.length) {
			kcs2 ~= "";
		}
		kcs2 ~= stdKCs;
		foreach (kc; kcs2) {
			if (!_incSearch.match(kc)) continue;
			_keyCode.add(kc);
		}
		_keyCode.setText(id);
	}
	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			_comm.refStandardKeyCodes.remove(&refStandardKeyCodes);
			_comm.refKeyCodes.remove(&refStandardKeyCodes);
		}
	}

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) {
		super (comm, prop, shell, summ, CType.BRANCH_KEY_CODE, parent, evt, false, null, true);
	}
protected:
	override void setup(Composite area) {
		area.setLayout(new GridLayout(2, false));
		{
			auto grp = new Group(area, SWT.NONE);
			grp.setText(_prop.msgs.range);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(new CenterLayout(SWT.HORIZONTAL));
			auto comp = new Composite(grp, SWT.NONE);
			comp.setLayout(zeroMarginGridLayout(1, true));
			foreach (r; [Range.SELECTED, Range.RANDOM, Range.BACKPACK, Range.PARTY_AND_BACKPACK]) {
				auto radio = new Button(comp, SWT.RADIO);
				mod(radio);
				radio.setText(_prop.msgs.rangeName(r));
				radio.setLayoutData(new GridData(GridData.FILL_BOTH));
				_keyCodeRange[r] = radio;
			}
		}
		{
			auto grp = new Group(area, SWT.NONE);
			grp.setText(_prop.msgs.cardType);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(new CenterLayout(SWT.HORIZONTAL));
			auto comp = new Composite(grp, SWT.NONE);
			comp.setLayout(zeroMarginGridLayout(1, true));
			foreach (r; [EffectCardType.ALL, EffectCardType.SKILL, EffectCardType.ITEM, EffectCardType.BEAST]) {
				auto radio = new Button(comp, SWT.RADIO);
				mod(radio);
				radio.setText(_prop.msgs.effectCardTypeName(r));
				radio.setLayoutData(new GridData(GridData.FILL_BOTH));
				_effectCardType[r] = radio;
			}
		}
		{
			auto grp = new Group(area, SWT.NONE);
			grp.setText(_prop.msgs.keyCode);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.horizontalSpan = 2;
			grp.setLayoutData(gd);
			grp.setLayout(new GridLayout(1, true));

			_keyCode = new Combo(grp, SWT.BORDER | SWT.DROP_DOWN);
			mod(_keyCode);
			_keyCode.setVisibleItemCount(prop.var.etc.comboVisibleItemCount);
			auto menu = new Menu(_keyCode.getShell(), SWT.POP_UP);
			createMenuItem(comm, menu, MenuID.IncSearch, &incSearch, null);
			new MenuItem(menu, SWT.SEPARATOR);
			_keyCode.setMenu(menu);
			createTextMenu!Combo(_comm, _prop, _keyCode, &catchMod);
			auto kgd = new GridData(GridData.FILL_HORIZONTAL);
			kgd.widthHint = _prop.var.etc.nameWidth;
			_keyCode.setLayoutData(kgd);

			_incSearch = new IncSearch(comm, _keyCode);
			_incSearch.modEvent ~= &refStandardKeyCodes;

			refStandardKeyCodes();
		}
		_comm.refStandardKeyCodes.add(&refStandardKeyCodes);
		_comm.refKeyCodes.add(&refStandardKeyCodes);
		_keyCode.addDisposeListener(new Dispose);

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) {
			_keyCodeRange[_evt.keyCodeRange].setSelection(true);
			_effectCardType[_evt.effectCardType].setSelection(true);
			_keyCode.setText(_evt.keyCode);
		} else {
			_keyCodeRange[Range.SELECTED].setSelection(true);
			_effectCardType[EffectCardType.ALL].setSelection(true);
			_keyCode.setText("");
		}
		refreshWarning();
	}

	override bool apply() {
		if (!_evt) _evt = new Content(CType.BRANCH_KEY_CODE, "");

		_evt.keyCode = _keyCode.getText();
		_evt.keyCodeRange = getRadioValue!(Range)(_keyCodeRange);
		_evt.effectCardType = getRadioValue!(EffectCardType)(_effectCardType);

		_comm.refKeyCodes.call();
		return true;
	}
}

/// ラウンド分岐の設定を行うダイアログ。
class BranchRoundDialog : EventDialog {
private:
	void refreshWarning()  {
		string[] ws;
		ws ~= .tryFormat(_prop.msgs.warningUnknownContent, _prop.msgs.contentName(CType.BRANCH_ROUND));
		warning = ws;
	}

	Spinner _value;
	Combo _cmp;
	Comparison3[] _cmps;

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) {
		super (comm, prop, shell, summ, CType.BRANCH_ROUND, parent, evt, false, null, true);
	}
protected:
	override void setup(Composite area) {
		area.setLayout(new GridLayout(1, false));
		{
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setText(prop.msgs.roundCondition);
			grp.setLayout(new CenterLayout(SWT.VERTICAL | SWT.HORIZONTAL, 0));
			auto comp = new Composite(grp, SWT.NONE);
			comp.setLayout(new GridLayout(4, false));

			auto l1 = new Label(comp, SWT.NONE);
			l1.setText(_prop.msgs.roundIs);

			_value = new Spinner(comp, SWT.BORDER);
			mod(_value);
			_value.setMinimum(0);
			_value.setMaximum(_prop.var.etc.roundMax);

			auto l2 = new Label(comp, SWT.NONE);
			l2.setText(_prop.msgs.roundCmpIs);

			_cmp = new Combo(comp, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
			mod(_cmp);
			_cmp.setVisibleItemCount(prop.var.etc.comboVisibleItemCount);
			foreach (cmp; EnumMembers!Comparison3) {
				_cmp.add(prop.msgs.comparison3Name(cmp));
				_cmps ~= cmp;
			}
		}

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) {
			_value.setSelection(_evt.round);
			_cmp.select(_cmps.countUntil(_evt.comparison3));
		} else {
			_value.setSelection(0);
			_cmp.select(0);
		}
		refreshWarning();
	}

	override bool apply() {
		if (!_evt) _evt = new Content(CType.BRANCH_ROUND, "");
		_evt.round = _value.getSelection();
		_evt.comparison3 = _cmps[_cmp.getSelectionIndex()];
		return true;
	}
}
