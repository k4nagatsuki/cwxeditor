
module cwx.editor.gui.dwt.couponview;

import cwx.card;
import cwx.coupon;
import cwx.features;
import cwx.menu;
import cwx.path;
import cwx.race;
import cwx.skin;
import cwx.summary;
import cwx.system;
import cwx.types;
import cwx.types;
import cwx.usecounter;
import cwx.utils;
import cwx.warning;
import cwx.xml;

import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.chooser;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.radarspinner;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.xmlbytestransfer;

static import std.algorithm;
import std.algorithm : map;
import std.array;
import std.conv;
import std.datetime;
import std.string;
import std.typecons;

import org.eclipse.swt.all;

import java.lang.all;

public:

enum CVType {
	Cast, /// 得点付きクーポンのビュー(キャストカードの経歴)。
	Valued, /// 得点付きクーポンのビュー(評価条件)。
	NoValued, /// 得点無し・クーポン分岐用(Wsn.2)。
	Branch /// クーポン所持分岐用。
}

/// クーポンのビュー。
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
	private UseCounter _uc;
	private bool _isHistoryView; /// キャラクターの経歴欄か。評価条件などの場合はfalse。
	private KeyDownFilter _kdFilter;
	private Tuple!(Period, const(Race)) delegate() _getFeature;

	private UndoManager _undoCoupons;

	private TextMenuModify _newCouponTM;
	private Combo _newCoupon;
	static if (CVType.Cast == Type) {
		private Button _couponType;
		private Spinner _couponVal;
		private TableTCEdit _tte2;
		private bool[string] _sexCoupons;
		private bool[string] _periodCoupons;
		private bool[string] _natureCoupons;
		private bool[string] _makingCoupons;
	} else static if (CVType.Valued == Type) {
		private CCombo _couponType;
		private int[CouponType] _couponTypeTable;
		private CouponType[int] _couponTypeTable2;
		private Spinner _couponVal;
		private TableTCEdit _tte2;
	} else {
		private CCombo _couponType;
		private int[CouponType] _couponTypeTable;
		private CouponType[int] _couponTypeTable2;
	}
	private Table _coupons;
	private ToolBar _toolbar;
	private TableTCEdit _tte1;

	private class UndoCoupons : Undo {
		private Coupon[] _coupons;
		private int[] _selected;
		this () { mixin(S_TRACE);
			save();
		}
		private void save() { mixin(S_TRACE);
			_coupons = this.outer.coupons;
			_selected = this.outer._coupons.getSelectionIndices();
		}
		private void impl() { mixin(S_TRACE);
			if (_tte1.isEditing) _tte1.cancel();
			static if (CVType.NoValued != Type && CVType.Branch != Type) {
				if (_tte2.isEditing) _tte2.cancel();
			}
			auto coupons = _coupons;
			auto selected = _selected;
			save();
			this.outer._coupons.setRedraw(false);
			scope (exit) this.outer._coupons.setRedraw(true);
			this.outer._coupons.removeAll();
			foreach (c; coupons) { mixin(S_TRACE);
				appendCoupon(c);
			}
			this.outer._coupons.deselectAll();
			this.outer._coupons.select(selected);
			this.outer._coupons.showSelection();
			_comm.refreshToolBar();
		}
		override void undo() { impl(); }
		override void redo() { impl(); }
		override void dispose() { mixin(S_TRACE);
			// Nothing
		}
	}
	private void storeCoupons() { mixin(S_TRACE);
		_undoCoupons ~= new UndoCoupons;
	}
	private void undoCoupons() { mixin(S_TRACE);
		if (_tte1.isEditing) _tte1.cancel();
		static if (CVType.NoValued != Type && CVType.Branch != Type) {
			if (_tte2.isEditing) _tte2.cancel();
		}
		_undoCoupons.undo();
		_comm.refreshToolBar();
	}
	private void redoCoupons() { mixin(S_TRACE);
		if (_tte1.isEditing) _tte1.cancel();
		static if (CVType.NoValued != Type && CVType.Branch != Type) {
			if (_tte2.isEditing) _tte2.cancel();
		}
		_undoCoupons.redo();
		_comm.refreshToolBar();
	}
	private Image couponImage(int value) { mixin(S_TRACE);
		return value > 1 ? _prop.images.couponHigh
			: (value > 0 ? _prop.images.couponPlus
			: (value < 0 ? _prop.images.couponMinus : _prop.images.couponNormal));
	}
	private TableItem appendCoupon(in Coupon coupon, int index = -1, bool select = true) { mixin(S_TRACE);
		TableItem itm;
		if (index >= 0) { mixin(S_TRACE);
			itm = new TableItem(_coupons, SWT.NONE, index);
		} else { mixin(S_TRACE);
			itm = new TableItem(_coupons, SWT.NONE);
		}

		static if (CVType.NoValued != Type && CVType.Branch != Type) {
			itm.setText(0, coupon.name);
			itm.setText(1, to!(string)(coupon.value));
		} else {
			itm.setText(0, coupon.name);
		}
		itm.setData(new Coupon(coupon));
		updateWarning(itm);
		if (select) { mixin(S_TRACE);
			_coupons.setSelection([itm]);
			_coupons.showSelection();
			_comm.refreshToolBar();
		}
		return itm;
	}

	private void addCoupon() { mixin(S_TRACE);
		if (_newCoupon.getText().length > 0) { mixin(S_TRACE);
			if (_tte1.isEditing) _tte1.enter();
			static if (CVType.NoValued != Type && CVType.Branch != Type) {
				if (_tte2.isEditing) _tte2.enter();
			}
			string name = createNewName(_newCoupon.getText(), (string s) { mixin(S_TRACE);
				foreach (itm; _coupons.getItems()) { mixin(S_TRACE);
					auto c = cast(Coupon) itm.getData();
					if (c.name == s) return false;
				}
				return true;
			}, true);
			storeCoupons();

			static if (CVType.NoValued != Type && CVType.Branch != Type) {
				auto coupon = new Coupon(name, _couponVal.getSelection());
			} else {
				auto coupon = new Coupon(name, 0);
			}

			if (_isHistoryView) { mixin(S_TRACE);
				appendCoupon(coupon, _coupons.getSelectionIndex());
			} else { mixin(S_TRACE);
				appendCoupon(coupon);
			}
			raiseModifyEvent();
			_comm.refreshToolBar();
		}
	}
	private void altCoupon() { mixin(S_TRACE);
		int index = _coupons.getSelectionIndex();
		if (_newCoupon.getText().length > 0 && index >= 0) { mixin(S_TRACE);
			if (_tte1.isEditing) _tte1.enter();
			static if (CVType.NoValued != Type && CVType.Branch != Type) {
				if (_tte2.isEditing) _tte2.enter();
			}
			foreach (i, itm; _coupons.getItems()) { mixin(S_TRACE);
				if (_newCoupon.getText() == (cast(Coupon)itm.getData()).name && i != index) { mixin(S_TRACE);
					_coupons.select(cast(int)i);
					return;
				}
			}
			storeCoupons();
			auto itm = _coupons.getItem(index);
			static if (CVType.NoValued != Type && CVType.Branch != Type) {
				auto coupon = new Coupon(_newCoupon.getText(), _couponVal.getSelection());
				itm.setText(0, coupon.name);
				itm.setText(1, .to!(string)(coupon.value));
			} else {
				auto coupon = new Coupon(_newCoupon.getText(), 0);
				itm.setText(0, coupon.name);
			}

			itm.setData(coupon);
			updateWarning(itm);
			raiseModifyEvent();
			_comm.refreshToolBar();
		}
	}
	void addCoupon(Coupon coupon) { mixin(S_TRACE);
		if (_tte1.isEditing) _tte1.enter();
		static if (CVType.NoValued != Type && CVType.Branch != Type) {
			if (_tte2.isEditing) _tte2.enter();
		}
		string name = createNewName(coupon.name, (string s) { mixin(S_TRACE);
			foreach (itm; _coupons.getItems()) { mixin(S_TRACE);
				auto c = cast(Coupon)itm.getData();
				if (c.name == s) return false;
			}
			return true;
		}, true);
		storeCoupons();
		appendCoupon(new Coupon(name, coupon.value));
		raiseModifyEvent();
		_comm.refreshToolBar();
	}
	private void delCoupon() { mixin(S_TRACE);
		delCoupon(_coupons.getSelectionIndices());
	}
	void delCoupon(in int[] indices) { mixin(S_TRACE);
		if (!indices.length) return;
		_coupons.setRedraw(false);
		scope (exit) _coupons.setRedraw(true);
		if (_tte1.isEditing) _tte1.enter();
		static if (CVType.NoValued != Type && CVType.Branch != Type) {
			if (_tte2.isEditing) _tte2.enter();
		}
		storeCoupons();
		foreach_reverse (i; indices) { mixin(S_TRACE);
			_coupons.remove(i);
		}
		raiseModifyEvent();
		auto i = _coupons.getSelectionIndex();
		if (i != -1) { mixin(S_TRACE);
			_coupons.select(i);
			selCoupon();
		} else { mixin(S_TRACE);
			_comm.refreshToolBar();
		}
	}
	private void selCoupon() { mixin(S_TRACE);
		if (!_readOnly) { mixin(S_TRACE);
			auto i = _coupons.getSelectionIndex();
			if (-1 != i) { mixin(S_TRACE);
				auto c = cast(Coupon)_coupons.getItem(i).getData();
				_newCoupon.setText(c.name);
				_newCouponTM.reset();
				static if (CVType.NoValued != Type && CVType.Branch != Type) {
					_couponVal.setSelection(c.value);
				}
				updateCouponType();
			}
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
			uppdateCouponTypeHint();
		}
	}
	static if (CVType.Cast !is Type) {
		private void uppdateCouponTypeHint() { mixin(S_TRACE);
			auto coType = _couponTypeTable2[_couponType.getSelectionIndex()];
			auto typeName = _prop.msgs.couponTypeLongDesc(coType);
			string toolTip = "";
			final switch (coType) {
			case CouponType.Normal:
				break;
			case CouponType.Hide:
				toolTip = .tryFormat(typeName, _prop.sys.couponHide);
				break;
			case CouponType.System:
				toolTip = .tryFormat(typeName, _prop.sys.couponSystem);
				break;
			case CouponType.Dur:
				toolTip = .tryFormat(typeName, _prop.sys.couponDur);
				break;
			case CouponType.DurBattle:
				toolTip = .tryFormat(typeName, _prop.sys.couponDurBattle);
				break;
			}
			_couponType.setToolTipText(toolTip);
		}
	}

	@property
	private bool canUp() { mixin(S_TRACE);
		if (_readOnly) return false;
		if (!_coupons || _coupons.isDisposed()) return false;
		auto indices = _coupons.getSelectionIndices();
		std.algorithm.sort(indices);
		return indices.length && 0 < indices[0];
	}
	private void upCoupon() { mixin(S_TRACE);
		if (!canUp) return;
		_coupons.setRedraw(false);
		scope (exit) _coupons.setRedraw(true);
		if (_tte1.isEditing) _tte1.enter();
		static if (CVType.NoValued != Type && CVType.Branch != Type) {
			if (_tte2.isEditing) _tte2.enter();
		}
		auto indices = _coupons.getSelectionIndices();
		std.algorithm.sort(indices);
		storeCoupons();
		foreach (index; indices) { mixin(S_TRACE);
			_coupons.upItem(index);
		}
		_coupons.showSelection();
		raiseModifyEvent();
		_comm.refreshToolBar();
	}
	@property
	private bool canDown() { mixin(S_TRACE);
		if (_readOnly) return false;
		if (!_coupons || _coupons.isDisposed()) return false;
		auto indices = _coupons.getSelectionIndices();
		std.algorithm.sort(indices);
		return indices.length && indices[$ - 1] + 1 < _coupons.getItemCount();
	}
	private void downCoupon() { mixin(S_TRACE);
		if (!canDown) return;
		_coupons.setRedraw(false);
		scope (exit) _coupons.setRedraw(true);
		if (_tte1.isEditing) _tte1.enter();
		static if (CVType.NoValued != Type && CVType.Branch != Type) {
			if (_tte2.isEditing) _tte2.enter();
		}
		auto indices = _coupons.getSelectionIndices();
		std.algorithm.sort(indices);
		storeCoupons();
		foreach_reverse (index; indices) { mixin(S_TRACE);
			_coupons.downItem(index);
		}
		_coupons.showSelection();
		raiseModifyEvent();
		_comm.refreshToolBar();
	}
	@property
	private bool canAddInitialCoupons() { mixin(S_TRACE);
		if (_readOnly) return false;
		if (!_getFeature) return false;
		bool[string] names;
		foreach (name; couponNames) names[name] = true;

		auto skin = _comm.skin;
		auto f = _getFeature();
		auto coupons = (f[1] ? f[1].coupons : []) ~ skin.periodInitialCoupons(_comm.prop.sys, f[0]);
		foreach (coupon; coupons) { mixin(S_TRACE);
			if (coupon.name !in names) return true;
		}
		return false;
	}
	@property
	private void addInitialCoupons() { mixin(S_TRACE);
		if (_readOnly) return;
		if (!_getFeature) return;

		if (_tte1.isEditing) _tte1.enter();
		static if (CVType.NoValued != Type && CVType.Branch != Type) {
			if (_tte2.isEditing) _tte2.enter();
		}
		auto stored = false;
		bool[string] names;
		foreach (name; couponNames) names[name] = true;

		auto skin = _comm.skin;
		auto f = _getFeature();
		auto coupons = (f[1] ? f[1].coupons : []) ~ skin.periodInitialCoupons(_comm.prop.sys, f[0]);
		TableItem[] itms;
		foreach_reverse (coupon; coupons) { mixin(S_TRACE);
			if (coupon.name in names) continue;
			if (!stored) storeCoupons();
			stored = true;
			itms ~= appendCoupon(coupon, 0);
			updateWarning(itms[$ - 1]);
		}
		_coupons.setSelection(itms);
		_coupons.showSelection();
		_comm.refreshToolBar();
	}

	private void reverseCoupons() { mixin(S_TRACE);
		if (_coupons.getItemCount() < 2) return;
		if (_tte1.isEditing) _tte1.enter();
		static if (CVType.NoValued != Type && CVType.Branch != Type) {
			if (_tte2.isEditing) _tte2.enter();
		}
		storeCoupons();
		Coupon[] coupons;
		foreach (itm; _coupons.getItems()) { mixin(S_TRACE);
			coupons ~= cast(Coupon)itm.getData();
		}
		std.algorithm.reverse(coupons);
		foreach (i, itm; _coupons.getItems()) { mixin(S_TRACE);
			auto coupon = coupons[i];
			static if (CVType.NoValued != Type && CVType.Branch != Type) {
				itm.setText(0, coupon.name);
				itm.setText(1, .text(coupon.value));
			} else {
				itm.setText(0, coupon.name);
			}
			itm.setData(coupon);
			updateWarning(itm);
		}
	}

	static if (CVType.Valued == Type) {
		@property
		private bool canReverseSignOfValues() { mixin(S_TRACE);
			if (_readOnly) return false;
			foreach (i; _coupons.getSelectionIndices()) { mixin(S_TRACE);
				if (auto coupon = cast(Coupon)_coupons.getItem(i).getData()) { mixin(S_TRACE);
					if (coupon.value != 0) return true;
				}
			}
			return false;
		}
		@property
		private void reverseSignOfValues() { mixin(S_TRACE);
			if (_readOnly) return;

			if (_tte1.isEditing) _tte1.enter();
			static if (CVType.NoValued != Type && CVType.Branch != Type) {
				if (_tte2.isEditing) _tte2.enter();
			}
			auto stored = false;

			foreach (i; _coupons.getSelectionIndices()) { mixin(S_TRACE);
				auto itm = _coupons.getItem(i);
				if (auto coupon = cast(Coupon)itm.getData()) { mixin(S_TRACE);
					if (coupon.value == 0) continue;
					if (!stored) storeCoupons();
					stored = true;
					itm.setData(new Coupon(coupon.name, -coupon.value));
					itm.setText(1, .text(-coupon.value));
					updateWarning(itm);
				}
			}
			if (!stored) return;
			raiseModifyEvent();
			_comm.refreshToolBar();
		}
	}

	private class CDropListener : DropTargetAdapter {
		override void dragEnter(DropTargetEvent e) { mixin(S_TRACE);
			e.detail = _readOnly ? DND.DROP_NONE : DND.DROP_MOVE;
		}
		override void dragOver(DropTargetEvent e) { mixin(S_TRACE);
			e.detail = _readOnly ? DND.DROP_NONE : DND.DROP_MOVE;
		}
		override void drop(DropTargetEvent e) { mixin(S_TRACE);
			if (!isXMLBytes(e.data)) return;
			e.detail = DND.DROP_NONE;
			string xml = bytesToXML(e.data);
			try { mixin(S_TRACE);
				auto node = XNode.parse(xml);
				auto p = (cast(DropTarget)e.getSource()).getControl().toControl(e.x, e.y);
				auto t = _coupons.getItem(p);
				int index = t ? _coupons.indexOf(t) : _coupons.getItemCount();
				auto samePane = _id == node.attr("paneId", false);
				if (samePane && index == _dragIndex) return;
				if (!appendFromNode(node, index, samePane)) return;

				if (samePane) { mixin(S_TRACE);
					e.detail = DND.DROP_MOVE;
				} else { mixin(S_TRACE);
					e.detail = DND.DROP_COPY;
				}
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
			}
		}
	}
	bool appendFromNode(ref XNode node, int index, bool move) { mixin(S_TRACE);
		if (node.name != Coupon.XML_NAME_M) return false;
		auto ver = new XMLInfo(_prop.sys, LATEST_VERSION);
		Coupon[] coupons;
		node.onTag[Coupon.XML_NAME] = (ref XNode node) { mixin(S_TRACE);
			coupons ~= Coupon.fromNode(node, ver);
		};
		node.parse();
		if (!coupons.length) return false;
		_coupons.setRedraw(false);
		scope (exit) _coupons.setRedraw(true);
		if (_tte1.isEditing) _tte1.enter();
		static if (CVType.NoValued != Type && CVType.Branch != Type) {
			if (_tte2.isEditing) _tte2.enter();
		}
		storeCoupons();
		TableItem[] itms = [];
		foreach (coupon; coupons) { mixin(S_TRACE);
			itms ~= appendCoupon(coupon, index, false);
			index++;
		}
		_coupons.deselectAll();
		_coupons.setSelection(itms);
		_coupons.showSelection();
		raiseModifyEvent();
		_comm.refreshToolBar();
		return true;
	}
	private int _dragIndex = -1;
	private class CDragListener : DragSourceAdapter {
		private TableItem[] _itms;
		override void dragStart(DragSourceEvent e) { mixin(S_TRACE);
			e.doit = (cast(DragSource) e.getSource()).getControl().isFocusControl();
		}
		override void dragSetData(DragSourceEvent e) { mixin(S_TRACE);
			if (XMLBytesTransfer.getInstance().isSupportedType(e.dataType)) { mixin(S_TRACE);
				auto c = cast(Table)(cast(DragSource) e.getSource()).getControl();
				_itms = c.getSelection();
				if (!_itms.length) return;
				_dragIndex = c.getSelectionIndex();
				if (_dragIndex == -1) return;
				auto coupons = _itms.map!(itm => cast(Coupon)itm.getData())().array();
				auto node = XNode.create("Coupons");
				node.newAttr("paneId", _id);
				foreach (coupon; coupons) { mixin(S_TRACE);
					coupon.toNode(node);
				}
				e.data = bytesFromXML(node.text);
			}
		}
		override void dragFinished(DragSourceEvent e) { mixin(S_TRACE);
			if (!_readOnly && e.detail == DND.DROP_MOVE) { mixin(S_TRACE);
				if (_tte1.isEditing) _tte1.enter();
				static if (CVType.NoValued != Type && CVType.Branch != Type) {
					if (_tte2.isEditing) _tte2.enter();
				}
				_coupons.setRedraw(false);
				scope (exit) _coupons.setRedraw(true);
				foreach_reverse (itm; _itms) itm.dispose();
				raiseModifyEvent();
				_comm.refreshToolBar();
			}
			_dragIndex = -1;
			_itms = [];
		}
	}
	private class CouponTCPD : TCPD {
		override void cut(SelectionEvent se) { mixin(S_TRACE);
			if (0 < _coupons.getSelectionCount()) { mixin(S_TRACE);
				copy(se);
				del(se);
			}
		}
		override void copy(SelectionEvent se) { mixin(S_TRACE);
			auto cs = map!((itm) => cast(Coupon)itm.getData())(_coupons.getSelection());
			if (cs.length) { mixin(S_TRACE);
				auto node = XNode.create(Coupon.XML_NAME_M);
				foreach (c; cs) { mixin(S_TRACE);
					c.toNode(node);
				}
				XMLtoCB(_prop, _comm.clipboard, node.text);
				_comm.refreshToolBar();
			}
		}
		override void paste(SelectionEvent se) { mixin(S_TRACE);
			auto xml = CBtoXML(_comm.clipboard);
			if (xml) { mixin(S_TRACE);
				try { mixin(S_TRACE);
					auto node = XNode.parse(xml);
					Coupon[] coupons;
					bool[string] names;
					foreach (itm; _coupons.getItems()) { mixin(S_TRACE);
						auto c = cast(Coupon)itm.getData();
						names[c.name] = true;
					}
					if (node.name == Coupon.XML_NAME) { mixin(S_TRACE);
						storeCoupons();
						auto ver = new XMLInfo(_prop.sys, LATEST_VERSION);
						coupons ~= Coupon.fromNode(node, ver);
					} else if (node.name == Coupon.XML_NAME_M) { mixin(S_TRACE);
						auto ver = new XMLInfo(_prop.sys, LATEST_VERSION);
						node.onTag[Coupon.XML_NAME] = (ref XNode node) { mixin(S_TRACE);
							coupons ~= Coupon.fromNode(node, ver);
						};
						node.parse();
					}
					if (!coupons.length) return;
					_coupons.setRedraw(false);
					scope (exit) _coupons.setRedraw(true);
					storeCoupons();
					if (_tte1.isEditing) _tte1.enter();
					static if (CVType.NoValued != Type && CVType.Branch != Type) {
						if (_tte2.isEditing) _tte2.enter();
					}
					auto index = _coupons.getSelectionIndex();
					if (index == -1) index = _coupons.getItemCount();
					TableItem[] itms;
					foreach (coupon; coupons) { mixin(S_TRACE);
						string name = createNewName(coupon.name, (string s) { mixin(S_TRACE);
							return s !in names;
						}, true);
						names[name] = true;
						itms ~= appendCoupon(new Coupon(name, coupon.value), index, false);
						index++;
					}
					_coupons.setSelection(itms);
					_coupons.showSelection();
					_comm.refreshToolBar();
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
			if (!_coupons || _coupons.isDisposed()) return false;
			return !_readOnly && _coupons.getSelectionIndex() != -1;
		}
		@property
		bool canDoC() { mixin(S_TRACE);
			if (!_coupons || _coupons.isDisposed()) return false;
			return _coupons.getSelectionIndex() != -1;
		}
		@property
		bool canDoP() { mixin(S_TRACE);
			if (!_coupons || _coupons.isDisposed()) return false;
			return !_readOnly && CBisXML(_comm.clipboard);
		}
		@property
		bool canDoD() { mixin(S_TRACE);
			if (!_coupons || _coupons.isDisposed()) return false;
			return !_readOnly && _coupons.getSelectionIndex() != -1;
		}
		@property
		bool canDoClone() { mixin(S_TRACE);
			if (!_coupons || _coupons.isDisposed()) return false;
			return !_readOnly && canDoC;
		}
	}
	private class SelCoupon : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			selCoupon();
		}
	}
	private class HTBTraverse : Listener {
		override void handleEvent(Event e) { e.doit = true; }
	}
	private class HTBKeyDown : Listener {
		override void handleEvent(Event e) { e.doit = true; }
	}
	this (Commons comm, Summary summ, UseCounter uc, Composite parent, int style, bool delegate() catchMod, Tuple!(Period, const(Race)) delegate() getFeature) { mixin(S_TRACE);
		super (parent, style);
		_isHistoryView = getFeature !is null;
		_getFeature = getFeature;

		_id = .objectIDValue(this);

		_readOnly = style & SWT.READ_ONLY;

		_comm = comm;
		_summ = summ;
		_uc = uc;
		_prop = comm.prop;
		_undoCoupons = new UndoManager(_prop.var.etc.undoMaxEtc);
		this.setLayout(zeroMarginGridLayout(3, false));
		if (!_readOnly) { mixin(S_TRACE);
			_toolbar = new ToolBar(this, SWT.FLAT);
			_comm.put(_toolbar);
			_toolbar.addListener(SWT.Traverse, new HTBTraverse);
			_toolbar.addListener(SWT.KeyDown, new HTBKeyDown);
			bool canAddCoupon() { mixin(S_TRACE);
				if (!_newCoupon || _newCoupon.isDisposed()) return false;
				return !_readOnly && _newCoupon.getText().length > 0;
			}
			bool canAltCoupon() { mixin(S_TRACE);
				if (!_newCoupon || _newCoupon.isDisposed()) return false;
				return !_readOnly && _newCoupon.getText().length > 0 && _coupons.getSelectionIndex() != -1;
			}
			bool canDelCoupon() { mixin(S_TRACE);
				if (!_coupons || _coupons.isDisposed()) return false;
				return !_readOnly && _coupons.getSelectionIndex() != -1;
			}
			createToolItem2(_comm, _toolbar, _prop.msgs.addCoupon, _prop.images.addCoupon, &addCoupon, &canAddCoupon);
			createToolItem2(_comm, _toolbar, _prop.msgs.altCoupon, _prop.images.altCoupon, &altCoupon, &canAltCoupon);
			createToolItem2(_comm, _toolbar, _prop.msgs.delCoupon, _prop.images.couponDelete, &delCoupon, &canDelCoupon);
			new ToolItem(_toolbar, SWT.SEPARATOR);
			createToolItem(_comm, _toolbar, MenuID.Up, &upCoupon, &canUp);
			createToolItem(_comm, _toolbar, MenuID.Down, &downCoupon, &canDown);

			auto gd = new GridData(GridData.HORIZONTAL_ALIGN_END);
			gd.horizontalSpan = 2;

			static if (CVType.Cast == Type) { mixin(S_TRACE);
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
				foreach (i, type; [CouponType.Normal, CouponType.Hide, CouponType.Dur, CouponType.DurBattle, CouponType.System]) { mixin(S_TRACE);
					static if (CVType.Valued == Type) {
						if (type == CouponType.System) continue;
						_couponType.add(_prop.msgs.couponTypeName(type));
					} else { mixin(S_TRACE);
						auto typeName = _prop.msgs.couponTypeDesc(type);
						final switch (type) {
							case CouponType.Normal:
								break;
							case CouponType.Hide:
								typeName = .tryFormat(typeName, _prop.sys.couponHide);
								break;
							case CouponType.Dur:
								typeName = .tryFormat(typeName, _prop.sys.couponDur);
								break;
							case CouponType.DurBattle:
								typeName = .tryFormat(typeName, _prop.sys.couponDurBattle);
								break;
							case CouponType.System:
								typeName = .tryFormat(typeName, _prop.sys.couponSystem);
								break;
						}
						_couponType.add(typeName);
					}
					_couponTypeTable[type] = cast(int)i;
					_couponTypeTable2[cast(int)i] = type;
				}
				_couponType.select(0);
				.listener(_couponType, SWT.Selection, { mixin(S_TRACE);
					auto type = _couponTypeTable2[_couponType.getSelectionIndex()];
					_newCoupon.setText(_prop.sys.convCoupon(_newCoupon.getText(), type, false));
					uppdateCouponTypeHint();
				});
			}
		}
		if (!_readOnly) { mixin(S_TRACE);
			static if (CVType.Cast == Type) {
				_newCoupon = createCouponCombo!Combo(_comm, _summ, _uc, this, catchMod, CouponComboType.Cast, "", _newCouponTM);
				.listener(_newCoupon, SWT.Modify, &updateCouponType);
			} else static if (CVType.Valued == Type) { mixin(S_TRACE);
				_newCoupon = createCouponCombo!Combo(_comm, _summ, _uc, this, catchMod, CouponComboType.Valued, "", _newCouponTM);
				.listener(_newCoupon, SWT.Modify, &updateCouponType);
			} else { mixin(S_TRACE);
				_newCoupon = createCouponCombo!Combo(_comm, _summ, _uc, this, catchMod, CouponComboType.AllCoupons, "", _newCouponTM);
				.listener(_newCoupon, SWT.Modify, &updateCouponType);
			}
			_newCoupon.setEnabled(!_readOnly);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			static if (CVType.NoValued != Type && CVType.Branch != Type) {
				gd.horizontalSpan = 2;
			} else { mixin(S_TRACE);
				gd.horizontalSpan = 3;
			}
			_newCoupon.setLayoutData(gd);

			static if (CVType.NoValued != Type && CVType.Branch != Type) {
				_couponVal = new Spinner(this, SWT.BORDER | _readOnly);
				initSpinner(_couponVal);
				_couponVal.setMinimum(cast(int) _prop.var.etc.couponValueMax * -1);
				_couponVal.setMaximum(_prop.var.etc.couponValueMax);
				static if (CVType.Valued == Type) {
					_couponVal.setSelection(1);
				}
			}
		}
		{ mixin(S_TRACE);
			_coupons = .rangeSelectableTable(this, SWT.BORDER | SWT.MULTI | SWT.FULL_SELECTION);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.horizontalSpan = 3;
			gd.widthHint = _prop.var.etc.couponWidth;
			gd.heightHint = _prop.var.etc.couponHeight;
			_coupons.setLayoutData(gd);
			auto cc = new FullTableColumn(_coupons, SWT.NONE);
			static if (CVType.NoValued != Type && CVType.Branch != Type) {
				auto cv = new TableColumn(_coupons, SWT.NONE);
				cv.setWidth(_prop.var.etc.couponValueColumnWidth);
				saveColumnWidth!("prop.var.etc.couponValueColumn")(_prop, cv);
			}
			auto menu = new Menu(_coupons);
			if (!_readOnly) { mixin(S_TRACE);
				createMenuItem(_comm, menu, MenuID.Undo, &undoCoupons, () => !_readOnly && _undoCoupons.canUndo);
				createMenuItem(_comm, menu, MenuID.Redo, &redoCoupons, () => !_readOnly && _undoCoupons.canRedo);
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.Up, &upCoupon, &canUp);
				createMenuItem(_comm, menu, MenuID.Down, &downCoupon, &canDown);
				static if (Type is CVType.Cast) {
					if (_getFeature) { mixin(S_TRACE);
						new MenuItem(menu, SWT.SEPARATOR);
						createMenuItem(_comm, menu, MenuID.AddInitialCoupons, &addInitialCoupons, &canAddInitialCoupons);
					}
					new MenuItem(menu, SWT.SEPARATOR);
					createMenuItem(_comm, menu, MenuID.Reverse, &reverseCoupons, () => !_readOnly && 2 <= _coupons.getItemCount());
				} else static if (Type is CVType.Valued) {
					new MenuItem(menu, SWT.SEPARATOR);
					createMenuItem(_comm, menu, MenuID.ReverseSignOfValues, &reverseSignOfValues, &canReverseSignOfValues);
				}
				new MenuItem(menu, SWT.SEPARATOR);
				appendMenuTCPD(_comm, menu, new CouponTCPD, true, true, true, true, true);
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.SelectAll, &selectAll, &canSelectAll);
			} else { mixin(S_TRACE);
				appendMenuTCPD(_comm, menu, new CouponTCPD, false, true, false, false, false);
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.SelectAll, &selectAll, &canSelectAll);
			}
			_coupons.setMenu(menu);
			if (!_readOnly) { mixin(S_TRACE);
				_tte1 = new TableTCEdit(_comm, _coupons, 0, &nameCreateEditor, &nameEditEnd, (itm, column) => true);
				static if (CVType.NoValued != Type && CVType.Branch != Type) {
					_tte2 = new TableTCEdit(_comm, _coupons, 1, &valueCreateEditor, &valueEditEnd, (itm, column) => true);
				}
			}
			if (!_readOnly) { mixin(S_TRACE);
				.listener(_coupons, SWT.MouseDoubleClick, { mixin(S_TRACE);
					if (_coupons.getSelectionIndex() != -1) return;
					static if (Type is CVType.Cast) {
						_tte1.startEdit(appendCoupon(new Coupon("", 0), 0));
					} else {
						_tte1.startEdit(appendCoupon(new Coupon("", 0)));
					}
				});
			}
		}
		_coupons.addSelectionListener(new SelCoupon);
		if (!_readOnly) { mixin(S_TRACE);
			static if (CVType.NoValued != Type && CVType.Branch != Type) {
				this.setTabList([cast(Control)_toolbar, _newCoupon, _couponType, _couponVal, _coupons]);
			} else {
				this.setTabList([cast(Control)_toolbar, _newCoupon, _couponType, _coupons]);
			}
			auto drop = new DropTarget(_coupons, DND.DROP_DEFAULT | DND.DROP_MOVE | DND.DROP_COPY);
			drop.setTransfer([XMLBytesTransfer.getInstance()]);
			drop.addDropListener(new CDropListener);
		}
		auto drag = new DragSource(_coupons, DND.DROP_MOVE | DND.DROP_COPY);
		drag.setTransfer([XMLBytesTransfer.getInstance()]);
		drag.addDragListener(new CDragListener);

		static if (Type == CVType.Cast) {
			void updateSkin() { mixin(S_TRACE);
				auto skin = _comm.skin;
				_sexCoupons = null;
				foreach (sex; skin.allSexes) { mixin(S_TRACE);
					_sexCoupons[skin.sexCoupon(sex)] = true;
				}
				_periodCoupons = null;
				foreach (period; skin.allPeriods) { mixin(S_TRACE);
					_periodCoupons[skin.periodCoupon(period)] = true;
				}
				_natureCoupons = null;
				if (_prop.var.etc.showSpNature) { mixin(S_TRACE);
					foreach (nature; skin.allNatures) { mixin(S_TRACE);
						_natureCoupons[skin.natureCoupon(nature)] = true;
					}
				} else { mixin(S_TRACE);
					foreach (nature; skin.normalNatures) { mixin(S_TRACE);
						_natureCoupons[skin.natureCoupon(nature)] = true;
					}
				}
				_makingCoupons = null;
				foreach (making; skin.allMakings) { mixin(S_TRACE);
					_makingCoupons[skin.makingsCoupon(making)] = true;
				}
				refDataVersion();
			}
			updateSkin();
			_comm.refSkin.add(&updateSkin);
			_comm.refCoupons.add(&updateSkin);
			.listener(this, SWT.Dispose, { mixin(S_TRACE);
				_comm.refSkin.remove(&updateSkin);
				_comm.refCoupons.remove(&updateSkin);
			});
		}

		_comm.refMenu.add(&refMenu);
		_comm.refUndoMax.add(&refUndoMax);
		_comm.refDataVersion.add(&refDataVersion);
		this.addDisposeListener(new Dispose);
		_kdFilter = new KeyDownFilter();
		this.getDisplay().addFilter(SWT.KeyDown, _kdFilter);
	}


	private class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			_comm.refMenu.remove(&refMenu);
			_comm.refUndoMax.remove(&refUndoMax);
			_comm.refDataVersion.remove(&refDataVersion);
			e.widget.getDisplay().removeFilter(SWT.KeyDown, _kdFilter);
		}
	}
	private class KeyDownFilter : Listener {
		this () { mixin(S_TRACE);
			refMenu(MenuID.Undo);
			refMenu(MenuID.Redo);
		}
		override void handleEvent(Event e) { mixin(S_TRACE);
			if (!e.doit) return;
			auto c = cast(Control)e.widget;
			if (!c || c.isDisposed() || c.getShell() !is getShell()) return;
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
		foreach (itm; _coupons.getItems()) { mixin(S_TRACE);
			auto c = cast(Coupon)itm.getData();
			if (c.name != "") r ~= c;
		}
		return r;
	}
	@property
	void coupons(in Coupon[] coupons) { mixin(S_TRACE);
		if (coupons == this.coupons) return;
		_undoCoupons.reset();
		_coupons.removeAll();
		foreach (c; coupons) { mixin(S_TRACE);
			appendCoupon(c);
		}
	}

	@property
	string[] couponNames() { mixin(S_TRACE);
		string[] r;
		foreach (coup ; coupons()) { mixin(S_TRACE);
			r ~= coup.name;
		}
		return r;
	}

	@property
	void couponNames(in string[] couponNames) { mixin(S_TRACE);
		Coupon[] r;
		foreach(name; couponNames) { mixin(S_TRACE);
			r ~= new Coupon(name, 0);
		}
		coupons(r);
	}

	@property
	void enabled(bool e) { mixin(S_TRACE);
		_newCoupon.setEnabled(!_readOnly && e);
		_couponType.setEnabled(!_readOnly && e);
		static if (CVType.NoValued != Type && CVType.Branch != Type) {
			_couponVal.setEnabled(!_readOnly && e);
		}
		_coupons.setEnabled(e);
		_toolbar.setEnabled(!_readOnly && e);
	}
	@property
	bool enabled() { mixin(S_TRACE);
		return _coupons.isEnabled();
	}

	@property
	void toolTip(string t) { mixin(S_TRACE);
		if (t == toolTip) return;
		_coupons.setToolTipText(t);
	}
	@property
	string toolTip() { mixin(S_TRACE);
		return _coupons.getToolTipText();
	}

	@property
	Table widget() { return _coupons; }
	@property
	Combo mainNameEditor() { return _newCoupon; }

	private Control nameCreateEditor(TableItem itm, int column) { mixin(S_TRACE);
		static if (CVType.Cast == Type) {
			auto type = CouponComboType.Cast;
		} else static if (CVType.Valued == Type) { mixin(S_TRACE);
			auto type = CouponComboType.Valued;
		} else { mixin(S_TRACE);
			auto type = CouponComboType.AllCoupons;
		}
		auto combo = createCouponCombo!Combo(_comm, _summ, _uc, itm.getParent(), null, type, itm.getText());
		if (_setupNameEditor) _setupNameEditor(combo);
		return combo;
	}
	private void delegate(Combo) _setupNameEditor = null;
	@property
	void setupNameEditor(void delegate(Combo) dlg) { mixin(S_TRACE);
		_setupNameEditor = dlg;
		if (dlg) dlg(_newCoupon);
	}
	private void nameEditEnd(TableItem itm, int column, Control ctrl) { mixin(S_TRACE);
		assert (!_readOnly);
		assert (cast(Combo)ctrl !is null);
		auto newText = (cast(Combo)ctrl).getText();
		if (newText == "") { mixin(S_TRACE);
			if ((cast(Coupon)itm.getData()).name != "") storeCoupons();
			itm.dispose();
			raiseModifyEvent();
			_comm.refreshToolBar();
			return;
		}
		auto itms = itm.getParent().getSelection();
		auto edit = false;
		foreach (itm2; itms) { mixin(S_TRACE);
			auto coupon = cast(Coupon)itm2.getData();
			if (coupon.name == newText) continue;
			edit = true;
			break;
		}
		if (!edit) return;
		storeCoupons();
		foreach (itm2; itms) { mixin(S_TRACE);
			auto coupon = cast(Coupon)itm2.getData();
			auto name = createNewName(newText, (string s) { mixin(S_TRACE);
				foreach (itm; _coupons.getItems()) { mixin(S_TRACE);
					auto c = cast(Coupon)itm.getData();
					if (coupon != c && c.name == s) return false;
				}
				return true;
			}, true);
			coupon = new Coupon(name, coupon.value);
			itm2.setText(0, name);
			itm2.setData(coupon);
			updateWarning(itm2);
		}
		raiseModifyEvent();
		_comm.refreshToolBar();
	}

	private Control valueCreateEditor(TableItem itm, int column) { mixin(S_TRACE);
		assert (!_readOnly);
		auto spn = new Spinner(itm.getParent(), SWT.BORDER);
		initSpinner(spn);
		auto coupon = cast(Coupon)itm.getData();
		assert (coupon !is null);
		static if (CVType.NoValued != Type && CVType.Branch != Type) {
			spn.setMaximum(_couponVal.getMaximum());
			spn.setMinimum(_couponVal.getMinimum());
		}
		spn.setSelection(coupon.value);
		return spn;
	}
	void valueEditEnd(TableItem itm, int column, Control ctrl) { mixin(S_TRACE);
		assert (!_readOnly);
		assert (cast(Spinner)ctrl !is null);
		auto value = (cast(Spinner)ctrl).getSelection();
		auto itms = itm.getParent().getSelection();
		auto edit = false;
		foreach (itm2; itms) { mixin(S_TRACE);
			auto coupon = cast(Coupon)itm2.getData();
			if (coupon.value == value) continue;
			edit = true;
			break;
		}
		if (!edit) return;
		storeCoupons();
		foreach (itm2; itms) { mixin(S_TRACE);
			auto coupon = cast(Coupon)itm2.getData();
			coupon = new Coupon(coupon.name, value);
			static if (CVType.NoValued != Type && CVType.Branch != Type) {
				itm2.setText(1, .text(value));
			} else {
				itm2.setText(0, coupon.name);
			}
			itm2.setData(coupon);
			updateWarning(itm2);
		}
		raiseModifyEvent();
		_comm.refreshToolBar();
	}

	private void updateWarning(TableItem itm) { mixin(S_TRACE);
		auto coupon = cast(Coupon)itm.getData();
		assert (coupon !is null);

		if (warningsImpl(coupon.name).length) { mixin(S_TRACE);
			itm.setImage(0, _prop.images.warning);
		} else { mixin(S_TRACE);
			itm.setImage(0, couponImage(coupon.value));
		}
	}
	private void refDataVersion() { mixin(S_TRACE);
		if (!_coupons || _coupons.isDisposed()) return;
		foreach (itm; _coupons.getItems()) { mixin(S_TRACE);
			updateWarning(itm);
		}
	}

	@property
	string[] warnings() { mixin(S_TRACE);
		string[] ws;
		foreach (name; couponNames) { mixin(S_TRACE);
			ws ~= warningsImpl(name);
		}
		string[] ws2;
		bool[string] wSet;
		foreach (w; ws) { mixin(S_TRACE);
			if (w !in wSet) { mixin(S_TRACE);
				wSet[w] = true;
				ws2 ~= w;
			}
		}
		return ws2;
	}
	private string[] warningsImpl(string name) { mixin(S_TRACE);
		string[] ws;
		static if (Type == CVType.Cast) {
			ws ~= .sjisWarnings(_prop.parent, _summ, name, _prop.msgs.history);
			if (name in _sexCoupons) { mixin(S_TRACE);
				ws ~= .tryFormat(_prop.msgs.warningSexCoupon, name);
			}
			if (name in _periodCoupons) { mixin(S_TRACE);
				ws ~= .tryFormat(_prop.msgs.warningPeriodCoupon, name);
			}
			if (name in _natureCoupons) { mixin(S_TRACE);
				ws ~= .tryFormat(_prop.msgs.warningNatureCoupon, name);
			}
			if (name in _makingCoupons) { mixin(S_TRACE);
				ws ~= .tryFormat(_prop.msgs.warningMakingCoupon, name);
			}
			if (std.string.startsWith(name, _prop.sys.couponSystem) && name != _prop.sys.levelLimit && name != _prop.sys.ep && !_prop.sys.isGene(name)) { mixin(S_TRACE);
				ws ~= _prop.msgs.warningSystemCouponForHistory;
			}
		} else static if (Type == CVType.Valued) {
			auto isClassic = _summ && _summ.legacy;
			auto wsnVer = _summ ? _summ.dataVersion : LATEST_VERSION;
			ws ~= .couponWarnings(_prop.parent, isClassic, wsnVer, _prop.var.etc.targetVersion, name, false, _prop.msgs.valued);
		} else static if (Type == CVType.NoValued || Type == CVType.Branch) {
			auto isClassic = _summ && _summ.legacy;
			auto wsnVer = _summ ? _summ.dataVersion : LATEST_VERSION;
			ws ~= .couponWarnings(_prop.parent, isClassic, wsnVer, _prop.var.etc.targetVersion, name, Type !is CVType.Branch, _prop.msgs.couponName);
		} else static assert (0);
		return ws;
	}

	@property
	bool canSelectAll() { mixin(S_TRACE);
		if (!_coupons || _coupons.isDisposed()) return false;
		return _coupons.getSelectionCount() != _coupons.getItemCount();
	}
	void selectAll() { mixin(S_TRACE);
		if (!canSelectAll) return;
		_coupons.selectAll();
		_comm.refreshToolBar();
	}
}
