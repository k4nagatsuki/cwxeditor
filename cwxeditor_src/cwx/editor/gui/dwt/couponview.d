
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
import cwx.system;
import cwx.summary;

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
import cwx.editor.gui.dwt.chooser;

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
	private void raiseModifyEvent() { mixin(S_TRACE);
		foreach (dlg; modEvent) { mixin(S_TRACE);
			dlg();
		}
	}
	private string _id;

	private int _readOnly = 0;
	private Commons _comm;
	private Props _prop;
	private Summary _summ;
	private KeyDownFilter _kdFilter;

	private UndoManager _undoCoupons;

	private TextMenuModify _newCouponTM;
	private Combo _newCoupon;
	static if (CVType.Cast == Type) {
		private Button _couponType;
	} else {
		private CCombo _couponType;
		private int[CouponType] _couponTypeTable;
		private CouponType[int] _couponTypeTable2;
	}
	private Spinner _couponVal;
	private Table _coupons;
	private ToolBar _toolbar;

	private class UndoCoupons : Undo {
		private Coupon[] _coupons;
		private int _selected;
		this () { mixin(S_TRACE);
			save();
		}
		private void save() { mixin(S_TRACE);
			_coupons = this.outer.coupons;
			_selected = this.outer._coupons.getSelectionIndex();
		}
		private void impl() { mixin(S_TRACE);
			auto coupons = _coupons;
			auto selected = _selected;
			save();
			this.outer._coupons.setRedraw(false);
			scope (exit) this.outer._coupons.setRedraw(true);
			this.outer._coupons.removeAll();
			foreach (c; coupons) { mixin(S_TRACE);
				appendCoupon(c);
			}
			this.outer._coupons.select(selected);
			this.outer._coupons.showSelection();
			_comm.refreshToolBar();
		}
		override void undo() {impl();}
		override void redo() {impl();}
		override void dispose() { mixin(S_TRACE);
			// Nothing
		}
	}
	private void storeCoupons() { mixin(S_TRACE);
		_undoCoupons ~= new UndoCoupons;
	}
	private void undoCoupons() { mixin(S_TRACE);
		_undoCoupons.undo();
		_comm.refreshToolBar();
	}
	private void redoCoupons() { mixin(S_TRACE);
		_undoCoupons.redo();
		_comm.refreshToolBar();
	}
	private Image couponImage(int value) { mixin(S_TRACE);
		return value > 1 ? _prop.images.couponHigh
			: (value > 0 ? _prop.images.couponPlus
			: (value < 0 ? _prop.images.couponMinus : _prop.images.couponNormal));
	}
	private void appendCoupon(in Coupon coupon, int index = -1) { mixin(S_TRACE);
		TableItem itm;
		if (index >= 0) { mixin(S_TRACE);
			itm = new TableItem(_coupons, SWT.NONE, index);
		} else { mixin(S_TRACE);
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
	private void addCoupon() { mixin(S_TRACE);
		if (_newCoupon.getText().length > 0) { mixin(S_TRACE);
			foreach (i, itm; _coupons.getItems()) { mixin(S_TRACE);
				if (_newCoupon.getText() == (cast(Coupon) itm.getData()).name) { mixin(S_TRACE);
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
	private void altCoupon() { mixin(S_TRACE);
		int index = _coupons.getSelectionIndex();
		if (_newCoupon.getText().length > 0 && index >= 0) { mixin(S_TRACE);
			foreach (i, itm; _coupons.getItems()) { mixin(S_TRACE);
				if (_newCoupon.getText() == (cast(Coupon) itm.getData()).name && i != index) { mixin(S_TRACE);
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
	void addCoupon(Coupon coupon) { mixin(S_TRACE);
		foreach (i, itm; _coupons.getItems()) { mixin(S_TRACE);
			if (coupon.name == (cast(Coupon) itm.getData()).name) { mixin(S_TRACE);
				return;
			}
		}
		storeCoupons();
		appendCoupon(coupon);
		raiseModifyEvent();
		_comm.refreshToolBar();
	}
	private void delCoupon() { mixin(S_TRACE);
		int i = _coupons.getSelectionIndex();
		if (i >= 0) { mixin(S_TRACE);
			delCoupon(i);
		}
	}
	void delCoupon(int i) { mixin(S_TRACE);
		storeCoupons();
		_coupons.remove(i);
		if (i >= _coupons.getItemCount()) i--;
		if (i >= 0) { mixin(S_TRACE);
			_coupons.select(i);
			selCoupon();
		}
		raiseModifyEvent();
		_comm.refreshToolBar();
	}
	private void selCoupon() { mixin(S_TRACE);
		auto i = _coupons.getSelectionIndex();
		if (-1 != i) { mixin(S_TRACE);
			auto c = cast(Coupon) _coupons.getItem(i).getData();
			_newCoupon.setText(c.name);
			_newCouponTM.reset();
			_couponVal.setSelection(c.value);
			updateCouponType();
		}
		_comm.refreshToolBar();
	}
	private void updateCouponType() { mixin(S_TRACE);
		static if (CVType.Cast == Type) {
			_couponType.setSelection(_prop.sys.isCouponType(_newCoupon.getText(), CouponType.Hide));
		} else { mixin(S_TRACE);
			auto type = _prop.sys.couponType(_newCoupon.getText());
			auto p = type in _couponTypeTable;
			if (p) { mixin(S_TRACE);
				_couponType.select(*p);
			} else { mixin(S_TRACE);
				// ノーマル
				_couponType.select(0);
			}
		}
	}
	private void swapCoupon(int index1, int index2) { mixin(S_TRACE);
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
	private void upCoupon() { mixin(S_TRACE);
		int index = _coupons.getSelectionIndex();
		if (index > 0) { mixin(S_TRACE);
			storeCoupons();
			swapCoupon(index, index - 1);
			_coupons.select(index - 1);
			_comm.refreshToolBar();
		}
	}
	private void downCoupon() { mixin(S_TRACE);
		int index = _coupons.getSelectionIndex();
		if (index >= 0 && index + 1 < _coupons.getItemCount()) { mixin(S_TRACE);
			storeCoupons();
			swapCoupon(index, index + 1);
			_coupons.select(index + 1);
			_comm.refreshToolBar();
		}
	}

	private class CDropListener : DropTargetAdapter {
		override void dragEnter(DropTargetEvent e){ mixin(S_TRACE);
			e.detail = _readOnly ? DND.DROP_NONE : DND.DROP_MOVE;
		}
		override void dragOver(DropTargetEvent e){ mixin(S_TRACE);
			e.detail = _readOnly ? DND.DROP_NONE : DND.DROP_MOVE;
		}
		override void drop(DropTargetEvent e){ mixin(S_TRACE);
			if (!isXMLBytes(e.data)) return;
			e.detail = DND.DROP_NONE;
			string xml = bytesToXML(e.data);
			try { mixin(S_TRACE);
				auto node = XNode.parse(xml);
				if (node.name != Coupon.XML_NAME) return;
				scope p = (cast(DropTarget) e.getSource()).getControl().toControl(e.x, e.y);
				storeCoupons();
				auto t = _coupons.getItem(p);
				int index = t ? _coupons.indexOf(t) : _coupons.getItemCount();
				auto ver = new XMLInfo(_prop.sys, LATEST_VERSION);
				appendCoupon(Coupon.fromNode(node, ver), index);
				if (_id == node.attr("paneId", false)) { mixin(S_TRACE);
					_coupons.select(index);
					e.detail = DND.DROP_MOVE;
				}
				raiseModifyEvent();
				_comm.refreshToolBar();
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
			}
		}
	}
	private class CDragListener : DragSourceAdapter {
		private TableItem _itm;
		override void dragStart(DragSourceEvent e) { mixin(S_TRACE);
			e.doit = (cast(DragSource) e.getSource()).getControl().isFocusControl();
		}
		override void dragSetData(DragSourceEvent e){ mixin(S_TRACE);
			if (XMLBytesTransfer.getInstance().isSupportedType(e.dataType)) { mixin(S_TRACE);
				auto c = cast(Table) (cast(DragSource) e.getSource()).getControl();
				int index = c.getSelectionIndex();
				if (index >= 0) { mixin(S_TRACE);
					auto cp = cast(Coupon) c.getItem(index).getData();
					auto node = cp.toNode();
					node.newAttr("paneId", _id);
					e.data = bytesFromXML(node.text);
					_itm = c.getItem(index);
				}
			}
		}
		override void dragFinished(DragSourceEvent e) { mixin(S_TRACE);
			if (!_readOnly && e.detail == DND.DROP_MOVE) { mixin(S_TRACE);
				_itm.dispose();
				_coupons.redraw();
				_comm.refreshToolBar();
			}
		}
	}
	private class CouponTCPD : TCPD {
		@property
		private Coupon selection() { mixin(S_TRACE);
			auto i = _coupons.getSelectionIndex();
			return -1 != i ? cast(Coupon) _coupons.getItem(i).getData() : null;
		}
		override void cut(SelectionEvent se) { mixin(S_TRACE);
			auto c = selection;
			if (c) { mixin(S_TRACE);
				copy(se);
				del(se);
			}
		}
		override void copy(SelectionEvent se) { mixin(S_TRACE);
			auto c = selection;
			if (c) { mixin(S_TRACE);
				XMLtoCB(_prop, _comm.clipboard, c.toNode().text);
				_comm.refreshToolBar();
			}
		}
		override void paste(SelectionEvent se) { mixin(S_TRACE);
			auto xml = CBtoXML(_comm.clipboard);
			if (xml) { mixin(S_TRACE);
				try { mixin(S_TRACE);
					auto node = XNode.parse(xml);
					if (node.name == Coupon.XML_NAME) { mixin(S_TRACE);
						storeCoupons();
						auto ver = new XMLInfo(_prop.sys, LATEST_VERSION);
						auto coupon = Coupon.fromNode(node, ver);
						string name = createNewName(coupon.name, (string s) { mixin(S_TRACE);
							foreach (itm; _coupons.getItems()) { mixin(S_TRACE);
								auto c = cast(Coupon) itm.getData();
								if (c.name == s) return false;
							}
							return true;
						}, true);
						appendCoupon(new Coupon(name, coupon.value), _coupons.getSelectionIndex());
					}
					raiseModifyEvent();
				} catch (Exception e) {
					printStackTrace();
					debugln(e);
				}
			}
		}
		override void del(SelectionEvent se) { mixin(S_TRACE);
			delCoupon();
		}
		override void clone(SelectionEvent se) { mixin(S_TRACE);
			_comm.clipboard.memoryMode = true;
			scope (exit) _comm.clipboard.memoryMode = false;
			copy(se);
			paste(se);
		}
		@property
		override bool canDoTCPD() { mixin(S_TRACE);
			return true;
		}
		@property
		bool canDoT() { mixin(S_TRACE);
			return !_readOnly && _coupons.getSelectionIndex() != -1;
		}
		@property
		bool canDoC() { mixin(S_TRACE);
			return _coupons.getSelectionIndex() != -1;
		}
		@property
		bool canDoP() { mixin(S_TRACE);
			return !_readOnly && CBisXML(_comm.clipboard);
		}
		@property
		bool canDoD() { mixin(S_TRACE);
			return !_readOnly && _coupons.getSelectionIndex() != -1;
		}
		@property
		bool canDoClone() { mixin(S_TRACE);
			return !_readOnly && canDoC;
		}
	}
	private class SelCoupon : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			selCoupon();
		}
	}
	private class HTBTraverse : Listener {
		override void handleEvent(Event e) {e.doit = true;}
	}
	private class HTBKeyDown : Listener {
		override void handleEvent(Event e) {e.doit = true;}
	}
	this (Commons comm, Summary summ, Composite parent, int style, bool delegate() catchMod) { mixin(S_TRACE);
		super (parent, style);

		auto o = this;
		_id = format("%08X", &o) ~ "-" ~ to!(string)(Clock.currTime());

		_readOnly = style & SWT.READ_ONLY;
		_comm = comm;
		_summ = summ;
		_prop = comm.prop;
		_undoCoupons = new UndoManager(_prop.var.etc.undoMaxEtc);
		this.setLayout(new GridLayout(3, false));
		_toolbar = new ToolBar(this, SWT.FLAT);
		{ mixin(S_TRACE);
			_comm.put(_toolbar);
			_toolbar.addListener(SWT.Traverse, new HTBTraverse);
			_toolbar.addListener(SWT.KeyDown, new HTBKeyDown);
			createToolItem2(_comm, _toolbar, _prop.msgs.addCoupon, _prop.images.addCoupon, &addCoupon, () => !_readOnly && _newCoupon.getText().length > 0);
			createToolItem2(_comm, _toolbar, _prop.msgs.altCoupon, _prop.images.altCoupon, &altCoupon, () => !_readOnly && _newCoupon.getText().length > 0 && _coupons.getSelectionIndex() != -1);
			createToolItem2(_comm, _toolbar, _prop.msgs.delCoupon, _prop.images.couponDelete, &delCoupon, () => !_readOnly && _coupons.getSelectionIndex() != -1);
			static if (CVType.Cast == Type) {
				new ToolItem(_toolbar, SWT.SEPARATOR);
				createToolItem(_comm, _toolbar, MenuID.Up, &upCoupon, () => !_readOnly && _coupons.getSelectionIndex() != -1 && 0 < _coupons.getSelectionIndex());
				createToolItem(_comm, _toolbar, MenuID.Down, &downCoupon, () => !_readOnly && _coupons.getSelectionIndex() != -1 && _coupons.getSelectionIndex() + 1 < _coupons.getItemCount());
			}

			auto gd = new GridData(GridData.HORIZONTAL_ALIGN_END);
			gd.horizontalSpan = 2;
			static if (CVType.Cast == Type) {
				_couponType = new Button(this, SWT.CHECK);
				_couponType.setEnabled(!_readOnly);
				_couponType.setLayoutData(gd);
				_couponType.setText(_prop.msgs.couponHide);
				.listener(_couponType, SWT.Selection, { mixin(S_TRACE);
					if (_couponType.getSelection()) { mixin(S_TRACE);
						_newCoupon.setText(_prop.sys.convCoupon(_newCoupon.getText(), CouponType.Hide, true));
					} else { mixin(S_TRACE);
						_newCoupon.setText(_prop.sys.convCoupon(_newCoupon.getText(), CouponType.Normal, true));
					}
				});
			} else { mixin(S_TRACE);
				_couponType = new CCombo(this, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
				_couponType.setEnabled(!_readOnly);
				_couponType.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
				_couponType.setLayoutData(gd);
				foreach (i, type; [CouponType.Normal, CouponType.Hide, CouponType.Dur, CouponType.DurBattle]) { mixin(S_TRACE);
					_couponType.add(_prop.msgs.couponTypeName(type));
					_couponTypeTable[type] = i;
					_couponTypeTable2[i] = type;
				}
				.listener(_couponType, SWT.Selection, { mixin(S_TRACE);
					auto type = _couponTypeTable2[_couponType.getSelectionIndex()];
					_newCoupon.setText(_prop.sys.convCoupon(_newCoupon.getText(), type, false));
				});
			}
		}
		{ mixin(S_TRACE);
			static if (CVType.Cast == Type) {
				_newCoupon = createCouponCombo!Combo(_comm, _summ, this, catchMod, CouponComboType.Cast, "", _newCouponTM);
				.listener(_newCoupon, SWT.Modify, &updateCouponType);
			} else { mixin(S_TRACE);
				_newCoupon = createCouponCombo!Combo(_comm, _summ, this, catchMod, CouponComboType.Talker, "", _newCouponTM);
				.listener(_newCoupon, SWT.Modify, &updateCouponType);
			}
			_newCoupon.setEnabled(!_readOnly);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.horizontalSpan = 2;
			_newCoupon.setLayoutData(gd);
			_couponVal = new Spinner(this, SWT.BORDER | _readOnly);
			initSpinner(_couponVal);
			_couponVal.setMinimum(cast(int) _prop.var.etc.couponValueMax * -1);
			_couponVal.setMaximum(_prop.var.etc.couponValueMax);
			static if (CVType.Valued == Type) {
				_couponVal.setSelection(1);
			}
		}
		{ mixin(S_TRACE);
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
			if (!_readOnly) { mixin(S_TRACE);
				createMenuItem(_comm, menu, MenuID.Undo, &undoCoupons, () => !_readOnly && _undoCoupons.canUndo);
				createMenuItem(_comm, menu, MenuID.Redo, &redoCoupons, () => !_readOnly && _undoCoupons.canRedo);
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.Up, &upCoupon, () => !_readOnly && _coupons.getSelectionIndex() != -1 && 0 < _coupons.getSelectionIndex());
				createMenuItem(_comm, menu, MenuID.Down, &downCoupon, () => !_readOnly && _coupons.getSelectionIndex() != -1 && _coupons.getSelectionIndex() + 1 < _coupons.getItemCount());
				new MenuItem(menu, SWT.SEPARATOR);
				appendMenuTCPD(_comm, menu, new CouponTCPD, true, true, true, true, true);
			} else { mixin(S_TRACE);
				appendMenuTCPD(_comm, menu, new CouponTCPD, false, true, false, false, false);
			}
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
		this.addDisposeListener(new Dispose);
		_kdFilter = new KeyDownFilter();
		this.getDisplay().addFilter(SWT.KeyDown, _kdFilter);
	}
	private class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			_comm.refMenu.remove(&refMenu);
			_comm.refUndoMax.remove(&refUndoMax);
			e.widget.getDisplay().removeFilter(SWT.KeyDown, _kdFilter);
		}
	}
	private class KeyDownFilter : Listener {
		this () { mixin(S_TRACE);
			refMenu(MenuID.Undo);
			refMenu(MenuID.Redo);
		}
		override void handleEvent(Event e) { mixin(S_TRACE);
			auto c = cast(Control) e.widget;
			if (!c || c.getShell() !is getShell()) return;
			if (isDescendant(this.outer, c)) { mixin(S_TRACE);
				if (c.getMenu() && findMenu(c.getMenu(), e.keyCode, e.character, e.stateMask)) return;
				if (eqAcc(_undoAcc, e.keyCode, e.character, e.stateMask)) { mixin(S_TRACE);
					_undoCoupons.undo();
					e.doit = false;
				} else if (eqAcc(_redoAcc, e.keyCode, e.character, e.stateMask)) { mixin(S_TRACE);
					_undoCoupons.redo();
					e.doit = false;
				}
			}
		}
	}
	private int _undoAcc;
	private int _redoAcc;
	private void refMenu(MenuID id) { mixin(S_TRACE);
		if (id == MenuID.Undo) _undoAcc = convertAccelerator(_prop.buildMenu(MenuID.Undo));
		if (id == MenuID.Redo) _redoAcc = convertAccelerator(_prop.buildMenu(MenuID.Redo));
	}

	private void refUndoMax() { mixin(S_TRACE);
		_undoCoupons.max = _prop.var.etc.undoMaxEtc;
	}

	@property
	Coupon[] coupons() { mixin(S_TRACE);
		Coupon[] r;
		r.length = _coupons.getItemCount();
		foreach (i, itm; _coupons.getItems()) { mixin(S_TRACE);
			r[i] = cast(Coupon) itm.getData();
		}
		return r;
	}
	@property
	void coupons(in Coupon[] coupons) { mixin(S_TRACE);
		_undoCoupons.reset();
		foreach (c; coupons) { mixin(S_TRACE);
			appendCoupon(c);
		}
	}

	@property
	void enabled(bool e) { mixin(S_TRACE);
		_newCoupon.setEnabled(!_readOnly && e);
		_couponType.setEnabled(!_readOnly && e);
		_couponVal.setEnabled(!_readOnly && e);
		_coupons.setEnabled(e);
		_toolbar.setEnabled(!_readOnly && e);
	}
	@property
	bool enabled() { mixin(S_TRACE);
		return _coupons.isEnabled();
	}

	@property
	void toolTip(string t) { mixin(S_TRACE);
		_coupons.setToolTipText(t);
	}
	@property
	string toolTip() { mixin(S_TRACE);
		return _coupons.getToolTipText();
	}
}
