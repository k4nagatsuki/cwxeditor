
module cwx.editor.gui.dwt.couponview;

import cwx.coupon;
import cwx.card;
import cwx.types;
import cwx.features;
import cwx.utils;
import cwx.race;
import cwx.xml;
import cwx.skin;
import cwx.path;
import cwx.menu;
import cwx.types;

import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.radarspinner;
import cwx.editor.gui.dwt.xmlbytestransfer;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.dmenu;

import std.datetime;
import std.string;
import std.conv;

import org.eclipse.swt.all;

import java.lang.all;

public:

enum CVType {
	Cast,
	Valued,
}

/// 得点付きクーポンのビュー。
class CouponView(CVType Type) : Composite {
	void delegate()[] modEvent;
	private void raiseModifyEvent() {
		foreach (dlg; modEvent) {
			dlg();
		}
	}
	private string _id;

	private Commons _comm;
	private Props _prop;
	private KeyDownFilter _kdFilter;

	private UndoManager _undoCoupons;

	private TextMenuModify _newCouponTM;
	static if (CVType.Cast == Type) {
		private Text _newCoupon;
		private Button _couponType;
	} else {
		private Combo _newCoupon;
		private CCombo _couponType;
		private int[CouponType] _couponTypeTable;
		private CouponType[int] _couponTypeTable2;
	}
	private Spinner _couponVal;
	private Table _coupons;
	private ToolBar _toolbar;

	@property
	void enabled(bool e) {
		_newCoupon.setEnabled(e);
		_couponType.setEnabled(e);
		_couponVal.setEnabled(e);
		_coupons.setEnabled(e);
		_toolbar.setEnabled(e);
	}
	@property
	bool enabled() {
		return _newCoupon.isEnabled();
	}

	private class UndoCoupons : Undo {
		private Coupon[] _coupons;
		private int _selected;
		this () {
			save();
		}
		private void save() {
			_coupons = this.outer.coupons;
			_selected = this.outer._coupons.getSelectionIndex();
		}
		private void impl() {
			auto coupons = _coupons;
			auto selected = _selected;
			save();
			this.outer._coupons.setRedraw(false);
			scope (exit) this.outer._coupons.setRedraw(true);
			this.outer._coupons.removeAll();
			foreach (c; coupons) {
				appendCoupon(c);
			}
			this.outer._coupons.select(selected);
			this.outer._coupons.showSelection();
			_comm.refreshToolBar();
		}
		override void undo() {impl();}
		override void redo() {impl();}
		override void dispose() {
			// Nothing
		}
	}
	private void storeCoupons() {
		_undoCoupons ~= new UndoCoupons;
	}
	private void undoCoupons() {
		_undoCoupons.undo();
		_comm.refreshToolBar();
	}
	private void redoCoupons() {
		_undoCoupons.redo();
		_comm.refreshToolBar();
	}
	private Image couponImage(int value) {
		return value > 1 ? _prop.images.couponHigh
			: (value > 0 ? _prop.images.couponPlus
			: (value < 0 ? _prop.images.couponMinus : _prop.images.couponNormal));
	}
	private void appendCoupon(in Coupon coupon, int index = -1) {
		TableItem itm;
		if (index >= 0) {
			itm = new TableItem(_coupons, SWT.NONE, index);
		} else {
			itm = new TableItem(_coupons, SWT.NONE);
		}
		itm.setImage(0, couponImage(coupon.value));
		itm.setText(0, coupon.name);
		itm.setText(1, to!(string)(coupon.value));
		itm.setData(new Coupon(coupon));
		_coupons.setSelection([itm]);
		_coupons.showSelection();
		_comm.refreshToolBar();
	}
	private void addCoupon() {
		if (_newCoupon.getText().length > 0) {
			foreach (i, itm; _coupons.getItems()) {
				if (_newCoupon.getText() == (cast(Coupon) itm.getData()).name) {
					_coupons.select(i);
					return;
				}
			}
			storeCoupons();
			appendCoupon(new Coupon(_newCoupon.getText(), _couponVal.getSelection()), _coupons.getSelectionIndex());
			raiseModifyEvent();
			_comm.refreshToolBar();
		}
	}
	private void altCoupon() {
		int index = _coupons.getSelectionIndex();
		if (_newCoupon.getText().length > 0 && index >= 0) {
			foreach (i, itm; _coupons.getItems()) {
				if (_newCoupon.getText() == (cast(Coupon) itm.getData()).name && i != index) {
					_coupons.select(i);
					return;
				}
			}
			storeCoupons();
			auto itm = _coupons.getItem(index);
			auto coupon = new Coupon(_newCoupon.getText(), _couponVal.getSelection());
			itm.setImage(0, couponImage(coupon.value));
			itm.setText(0, coupon.name);
			itm.setText(1, to!(string)(coupon.value));
			itm.setData(coupon);
			raiseModifyEvent();
			_comm.refreshToolBar();
		}
	}
	void addCoupon(Coupon coupon) {
		foreach (i, itm; _coupons.getItems()) {
			if (coupon.name == (cast(Coupon) itm.getData()).name) {
				return;
			}
		}
		storeCoupons();
		appendCoupon(coupon);
		raiseModifyEvent();
		_comm.refreshToolBar();
	}
	private void delCoupon() {
		int i = _coupons.getSelectionIndex();
		if (i >= 0) {
			delCoupon(i);
		}
	}
	void delCoupon(int i) {
		storeCoupons();
		_coupons.remove(i);
		if (i >= _coupons.getItemCount()) i--;
		if (i >= 0) {
			_coupons.select(i);
			selCoupon();
		}
		raiseModifyEvent();
		_comm.refreshToolBar();
	}
	private void selCoupon() {
		auto i = _coupons.getSelectionIndex();
		if (-1 != i) {
			auto c = cast(Coupon) _coupons.getItem(i).getData();
			_newCoupon.setText(c.name);
			_newCouponTM.reset();
			_couponVal.setSelection(c.value);
			updateCouponType();
		}
		_comm.refreshToolBar();
	}
	private void updateCouponType() {
		static if (CVType.Cast == Type) {
			_couponType.setSelection(_prop.sys.isCouponType(_newCoupon.getText(), CouponType.Hide));
		} else {
			auto type = _prop.sys.couponType(_newCoupon.getText());
			auto p = type in _couponTypeTable;
			if (p) {
				_couponType.select(*p);
			} else {
				// ノーマル
				_couponType.select(0);
			}
		}
	}
	private void swapCoupon(int index1, int index2) {
		auto itm1 = _coupons.getItem(index1);
		auto itm2 = _coupons.getItem(index2);
		auto img = itm1.getImage();
		auto text1 = itm1.getText(0);
		auto text2 = itm1.getText(1);
		auto data = itm1.getData();
		itm1.setImage(itm2.getImage());
		itm1.setText(0, itm2.getText(0));
		itm1.setText(1, itm2.getText(1));
		itm1.setData(itm2.getData());
		itm2.setImage(img);
		itm2.setText(0, text1);
		itm2.setText(1, text2);
		itm2.setData(data);
		raiseModifyEvent();
	}
	private void upCoupon() {
		int index = _coupons.getSelectionIndex();
		if (index > 0) {
			storeCoupons();
			swapCoupon(index, index - 1);
			_coupons.select(index - 1);
			_comm.refreshToolBar();
		}
	}
	private void downCoupon() {
		int index = _coupons.getSelectionIndex();
		if (index >= 0 && index + 1 < _coupons.getItemCount()) {
			storeCoupons();
			swapCoupon(index, index + 1);
			_coupons.select(index + 1);
			_comm.refreshToolBar();
		}
	}

	private class CDropListener : DropTargetAdapter {
		override void dragEnter(DropTargetEvent e){
			e.detail = DND.DROP_MOVE;
		}
		override void dragOver(DropTargetEvent e){
			e.detail = DND.DROP_MOVE;
		}
		override void drop(DropTargetEvent e){
			if (!isXMLBytes(e.data)) return;
			e.detail = DND.DROP_NONE;
			string xml = bytesToXML(e.data);
			try {
				auto node = XNode.parse(xml);
				if (node.name != Coupon.XML_NAME) return;
				scope p = (cast(DropTarget) e.getSource()).getControl().toControl(e.x, e.y);
				storeCoupons();
				auto t = _coupons.getItem(p);
				int index = t ? _coupons.indexOf(t) : _coupons.getItemCount();
				appendCoupon(Coupon.fromNode(node, LATEST_VERSION), index);
				if (_id == node.attr("paneId", false)) {
					_coupons.select(index);
					e.detail = DND.DROP_MOVE;
				}
				raiseModifyEvent();
				_comm.refreshToolBar();
			} catch (Exception e) {
				debugln(e);
			}
		}
	}
	private class CDragListener : DragSourceAdapter {
		private TableItem _itm;
		override void dragStart(DragSourceEvent e) {
			e.doit = (cast(DragSource) e.getSource()).getControl().isFocusControl();
		}
		override void dragSetData(DragSourceEvent e){
			if (XMLBytesTransfer.getInstance().isSupportedType(e.dataType)) {
				auto c = cast(Table) (cast(DragSource) e.getSource()).getControl();
				int index = c.getSelectionIndex();
				if (index >= 0) {
					auto cp = cast(Coupon) c.getItem(index).getData();
					auto node = cp.toNode();
					node.newAttr("paneId", _id);
					e.data = bytesFromXML(node.text);
					_itm = c.getItem(index);
				}
			}
		}
		override void dragFinished(DragSourceEvent e) {
			if (e.detail == DND.DROP_MOVE) {
				_itm.dispose();
				_coupons.redraw();
				_comm.refreshToolBar();
			}
		}
	}
	private class CouponTCPD : TCPD {
		@property
		private Coupon selection() {
			auto i = _coupons.getSelectionIndex();
			return -1 != i ? cast(Coupon) _coupons.getItem(i).getData() : null;
		}
		override void cut(SelectionEvent se) {
			auto c = selection;
			if (c) {
				copy(se);
				del(se);
			}
		}
		override void copy(SelectionEvent se) {
			auto c = selection;
			if (c) {
				XMLtoCB(_prop, _comm.clipboard, c.toNode().text);
				_comm.refreshToolBar();
			}
		}
		override void paste(SelectionEvent se) {
			auto xml = CBtoXML(_comm.clipboard);
			if (xml) {
				try {
					auto node = XNode.parse(xml);
					if (node.name == Coupon.XML_NAME) {
						storeCoupons();
						auto coupon = Coupon.fromNode(node, LATEST_VERSION);
						string name = createNewName(coupon.name, (string s) {
							foreach (itm; _coupons.getItems()) {
								auto c = cast(Coupon) itm.getData();
								if (c.name == s) return false;
							}
							return true;
						}, true);
						appendCoupon(new Coupon(name, coupon.value), _coupons.getSelectionIndex());
					}
					raiseModifyEvent();
				} catch (Exception e) {
					debugln(e);
				}
			}
		}
		override void del(SelectionEvent se) {
			delCoupon();
		}
		override void clone(SelectionEvent se) {
			_comm.clipboard.memoryMode = true;
			scope (exit) _comm.clipboard.memoryMode = false;
			copy(se);
			paste(se);
		}
		@property
		override bool canDoTCPD() {
			return _coupons.isFocusControl();
		}
		@property
		bool canDoT() {
			return _coupons.getSelectionIndex() != -1;
		}
		@property
		bool canDoC() {
			return _coupons.getSelectionIndex() != -1;
		}
		@property
		bool canDoP() {
			return CBisXML(_comm.clipboard);
		}
		@property
		bool canDoD() {
			return _coupons.getSelectionIndex() != -1;
		}
		@property
		bool canDoClone() {
			return canDoC;
		}
	}
	private class SelCoupon : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			selCoupon();
		}
	}
	private class HTBTraverse : Listener {
		override void handleEvent(Event e) {e.doit = true;}
	}
	private class HTBKeyDown : Listener {
		override void handleEvent(Event e) {e.doit = true;}
	}
	this (Commons comm, Composite parent, int style, bool delegate() catchMod) {
		super (parent, style);

		_id = format("%08X", &this) ~ "-" ~ to!(string)(Clock.currTime());

		_comm = comm;
		_prop = comm.prop;
		_undoCoupons = new UndoManager(_prop.var.etc.undoMaxEtc);
		this.setLayout(new GridLayout(3, false));
		_toolbar = new ToolBar(this, SWT.FLAT);
		{
			_comm.put(_toolbar);
			_toolbar.addListener(SWT.Traverse, new HTBTraverse);
			_toolbar.addListener(SWT.KeyDown, new HTBKeyDown);
			createToolItem2(_comm, _toolbar, _prop.msgs.addCoupon, _prop.images.addCoupon, &addCoupon, () => _newCoupon.getText().length > 0);
			createToolItem2(_comm, _toolbar, _prop.msgs.altCoupon, _prop.images.altCoupon, &altCoupon, () => _newCoupon.getText().length > 0 && _coupons.getSelectionIndex() != -1);
			createToolItem2(_comm, _toolbar, _prop.msgs.delCoupon, _prop.images.couponDelete, &delCoupon, () => _coupons.getSelectionIndex() != -1);
			static if (CVType.Cast == Type) {
				new ToolItem(_toolbar, SWT.SEPARATOR);
				createToolItem(_comm, _toolbar, MenuID.Up, &upCoupon, () => _coupons.getSelectionIndex() != -1 && 0 < _coupons.getSelectionIndex());
				createToolItem(_comm, _toolbar, MenuID.Down, &downCoupon, () => _coupons.getSelectionIndex() != -1 && _coupons.getSelectionIndex() + 1 < _coupons.getItemCount());
			}

			auto gd = new GridData(GridData.HORIZONTAL_ALIGN_END);
			gd.horizontalSpan = 2;
			static if (CVType.Cast == Type) {
				_couponType = new Button(this, SWT.CHECK);
				_couponType.setLayoutData(gd);
				_couponType.setText(_prop.msgs.couponHide);
				.listener(_couponType, SWT.Selection, {
					if (_couponType.getSelection()) {
						_newCoupon.setText(_prop.sys.convCoupon(_newCoupon.getText(), CouponType.Hide, true));
					} else {
						_newCoupon.setText(_prop.sys.convCoupon(_newCoupon.getText(), CouponType.Normal, true));
					}
				});
			} else {
				_couponType = new CCombo(this, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
				_couponType.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
				_couponType.setLayoutData(gd);
				foreach (i, type; [CouponType.Normal, CouponType.Hide, CouponType.Dur, CouponType.DurBattle]) {
					_couponType.add(_prop.msgs.couponTypeName(type));
					_couponTypeTable[type] = i;
					_couponTypeTable2[i] = type;
				}
				.listener(_couponType, SWT.Selection, {
					auto type = _couponTypeTable2[_couponType.getSelectionIndex()];
					_newCoupon.setText(_prop.sys.convCoupon(_newCoupon.getText(), type, false));
				});
			}
		}
		{
			static if (CVType.Cast == Type) {
				_newCoupon = new Text(this, SWT.BORDER);
				.listener(_newCoupon, SWT.Modify, &updateCouponType);
			} else {
				_newCoupon = new Combo(this, SWT.BORDER | SWT.DROP_DOWN);
				_newCoupon.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
				.listener(_newCoupon, SWT.Modify, &updateCouponType);
				updateCoupons();
			}
			_newCouponTM = createTextMenu!(typeof(_newCoupon))(_comm, _prop, _newCoupon, catchMod);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.horizontalSpan = 2;
			_newCoupon.setLayoutData(gd);
			_couponVal = new Spinner(this, SWT.BORDER);
			_couponVal.setMinimum(cast(int) _prop.var.etc.couponValueMax * -1);
			_couponVal.setMaximum(_prop.var.etc.couponValueMax);
			static if (CVType.Valued == Type) {
				_couponVal.setSelection(1);
			}
		}
		{
			_coupons = new Table(this, SWT.BORDER | SWT.SINGLE | SWT.FULL_SELECTION);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.horizontalSpan = 3;
			gd.widthHint = _prop.var.etc.couponWidth;
			_coupons.setLayoutData(gd);
			auto cc = new FullTableColumn(_coupons, SWT.NONE);
			auto cv = new TableColumn(_coupons, SWT.NONE);
			cv.setWidth(40);
			saveColumnWidth!("prop.var.etc.couponValueColumn")(_prop, cv);
			auto menu = new Menu(_coupons);
			createMenuItem(_comm, menu, MenuID.Undo, &undoCoupons, &_undoCoupons.canUndo);
			createMenuItem(_comm, menu, MenuID.Redo, &redoCoupons, &_undoCoupons.canRedo);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.Up, &upCoupon, () => _coupons.getSelectionIndex() != -1 && 0 < _coupons.getSelectionIndex());
			createMenuItem(_comm, menu, MenuID.Down, &downCoupon, () => _coupons.getSelectionIndex() != -1 && _coupons.getSelectionIndex() + 1 < _coupons.getItemCount());
			new MenuItem(menu, SWT.SEPARATOR);
			appendMenuTCPD(_comm, menu, new CouponTCPD, true, true, true, true, true);
			_coupons.setMenu(menu);
		}
		_coupons.addSelectionListener(new SelCoupon);
		this.setTabList([cast(Control)_toolbar, _newCoupon, _couponType, _couponVal, _coupons]);

		auto drag = new DragSource(_coupons, DND.DROP_MOVE | DND.DROP_COPY);
		drag.setTransfer([XMLBytesTransfer.getInstance()]);
		drag.addDragListener(new CDragListener);
		auto drop = new DropTarget(_coupons, DND.DROP_DEFAULT | DND.DROP_MOVE | DND.DROP_COPY);
		drop.setTransfer([XMLBytesTransfer.getInstance()]);
		drop.addDropListener(new CDropListener);

		_comm.refMenu.add(&refMenu);
		_comm.refUndoMax.add(&refUndoMax);
		_comm.refSkin.add(&updateCoupons);
		_comm.refCoupons.add(&updateCoupons);
		this.addDisposeListener(new Dispose);
		_kdFilter = new KeyDownFilter();
		this.getDisplay().addFilter(SWT.KeyDown, _kdFilter);
	}
	private class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			_comm.refMenu.remove(&refMenu);
			_comm.refUndoMax.remove(&refUndoMax);
			_comm.refSkin.remove(&updateCoupons);
			_comm.refCoupons.remove(&updateCoupons);
			e.widget.getDisplay().removeFilter(SWT.KeyDown, _kdFilter);
		}
	}
	private class KeyDownFilter : Listener {
		this () {
			refMenu(MenuID.Undo);
			refMenu(MenuID.Redo);
		}
		override void handleEvent(Event e) {
			auto c = cast(Control) e.widget;
			if (!c || c.getShell() !is getShell()) return;
			if (isDescendant(this.outer, c)) {
				if (c.getMenu() && findMenu(c.getMenu(), e.keyCode, e.character, e.stateMask)) return;
				if (eqAcc(_undoAcc, e.keyCode, e.character, e.stateMask)) {
					_undoCoupons.undo();
					e.doit = false;
				} else if (eqAcc(_redoAcc, e.keyCode, e.character, e.stateMask)) {
					_undoCoupons.redo();
					e.doit = false;
				}
			}
		}
	}
	private int _undoAcc;
	private int _redoAcc;
	private void refMenu(MenuID id) {
		if (id == MenuID.Undo) _undoAcc = convertAccelerator(_prop.buildMenu(MenuID.Undo));
		if (id == MenuID.Redo) _redoAcc = convertAccelerator(_prop.buildMenu(MenuID.Redo));
	}

	private void refUndoMax() {
		_undoCoupons.max = _prop.var.etc.undoMaxEtc;
	}

	private void updateCoupons() {
		static if (CVType.Cast != Type) {
			auto c = _newCoupon.getText();
			_newCoupon.removeAll();
			auto cs = castCoupons(_comm, false, _comm.skin.legacyName);
			string[] cs2;
			if (_prop.var.etc.usedCouponToCombo) {
				foreach (coupon; _comm.summary.useCounter.coupon.keys.sort) {
					if (!.contains(cs2, coupon.id)) cs2 ~= coupon;
				}
			}
			foreach (coupon; cs2 ~ cs) {
				_newCoupon.add(coupon);
			}
			_newCoupon.select(0);
			if (c.length && -1 == _newCoupon.indexOf(c)) {
				_newCoupon.add(c, 0);
			}
			_newCoupon.setText(c);
		}
	}

	@property
	Coupon[] coupons() {
		Coupon[] r;
		r.length = _coupons.getItemCount();
		foreach (i, itm; _coupons.getItems()) {
			r[i] = cast(Coupon) itm.getData();
		}
		return r;
	}
	@property
	void coupons(in Coupon[] coupons) {
		_undoCoupons.reset();
		foreach (c; coupons) {
			appendCoupon(c);
		}
	}
}
