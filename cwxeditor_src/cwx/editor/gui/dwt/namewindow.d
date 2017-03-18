
module cwx.editor.gui.dwt.namewindow;

import cwx.menu;
import cwx.path;
import cwx.structs;
import cwx.summary;
import cwx.types;
import cwx.usecounter;
import cwx.utils;

import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.incsearch;
import cwx.editor.gui.dwt.replacedialog;
import cwx.editor.gui.dwt.undo;

import std.algorithm;
import std.ascii;
import std.conv;
import std.string;

import org.eclipse.swt.all;

import java.lang.all;

class NameWindow(ID) : TopLevelPanel, TCPD {
private:
	Commons _comm;

	NameView!ID _view;

public:
	this (Commons comm, Shell parentShell, Composite parent, UndoManager undo, bool readOnly) { mixin(S_TRACE);
		_comm = comm;
		_view = new NameView!ID(_comm, parentShell, parent, undo, readOnly);
		appendMenuTCPD(_comm, this, this, false, true, false, false, false);
		putMenuAction(MenuID.IncSearch, &_view.incSearch, null);
		putMenuAction(MenuID.EditProp, &_view.editName, &_view.canEditName);
		putMenuAction(MenuID.Undo, &_view.undo, &_view.canUndo);
		putMenuAction(MenuID.Redo, &_view.redo, &_view.canRedo);
		putMenuAction(MenuID.CopyAsText, &_view.copy, &_view.canDoC);
		putMenuAction(MenuID.SelectAll, &_view.selectAll, &_view.canSelectAll);
		putMenuAction(MenuID.FindID, &_view.findID, &_view.canFindID);
		if (parent) reconstruct(parent);
	}

	void reconstruct(Composite parent) { mixin(S_TRACE);
		_view.reconstruct(parent);
		_view.widget.setData(new TLPData(this));
	}

	void select(in ID[] ids) { mixin(S_TRACE);
		_view.select(ids);
	}

	@property
	override
	Composite shell() { mixin(S_TRACE);
		return _view.widget;
	}
	@property
	UndoManager undoManager() { mixin(S_TRACE);
		return _view.undoManager;
	}

	@property
	void summary(Summary summ) { _view.summary = summ; }

	@property
	override
	Image image() { mixin(S_TRACE);
		static if (is(ID:CouponId)) {
			return _comm.prop.images.couponView;
		} else static if (is(ID:GossipId)) {
			return _comm.prop.images.gossipView;
		} else static if (is(ID:CompleteStampId)) {
			return _comm.prop.images.completeStampView;
		} else static if (is(ID:KeyCodeId)) {
			return _comm.prop.images.keyCodeView;
		} else static if (is(ID:CellNameId)) {
			return _comm.prop.images.cellNameView;
		} else static assert (0);
	}
	@property
	override
	string title() { mixin(S_TRACE);
		static if (is(ID:CouponId)) {
			return _comm.prop.msgs.couponTabName;
		} else static if (is(ID:GossipId)) {
			return _comm.prop.msgs.gossipTabName;
		} else static if (is(ID:CompleteStampId)) {
			return _comm.prop.msgs.completeStampTabName;
		} else static if (is(ID:KeyCodeId)) {
			return _comm.prop.msgs.keyCodeTabName;
		} else static if (is(ID:CellNameId)) {
			return _comm.prop.msgs.cellNameTabName;
		} else static assert (0);
	}

	@property
	override
	void delegate(string) statusText() { return null; }

	override
	void cut(SelectionEvent se) { mixin(S_TRACE);
		_view.cut(se);
	}
	override
	void copy(SelectionEvent se) { mixin(S_TRACE);
		_view.copy(se);
	}
	override
	void paste(SelectionEvent se) { mixin(S_TRACE);
		_view.paste(se);
	}
	override
	void del(SelectionEvent se) { mixin(S_TRACE);
		_view.del(se);
	}
	override
	void clone(SelectionEvent se) { mixin(S_TRACE);
		_view.clone(se);
	}
	@property
	override
	bool canDoTCPD() { mixin(S_TRACE);
		return _view.canDoTCPD;
	}
	@property
	override
	bool canDoT() { mixin(S_TRACE);
		return _view.canDoT;
	}
	@property
	override
	bool canDoC() { mixin(S_TRACE);
		return _view.canDoC;
	}
	@property
	override
	bool canDoP() { mixin(S_TRACE);
		return _view.canDoP;
	}
	@property
	override
	bool canDoD() { mixin(S_TRACE);
		return _view.canDoD;
	}
	@property
	override
	bool canDoClone() { mixin(S_TRACE);
		return _view.canDoClone;
	}

	override
	bool openCWXPath(string path, bool shellActivate) { mixin(S_TRACE);
		auto cate = cpcategory(path);
		auto name = openedCWXPath[0];
		if (cate == name) { mixin(S_TRACE);
			.forceFocus(_view._list, shellActivate);
			return true;
		} else { mixin(S_TRACE);
			return false;
		}
	}
	@property
	override
	string[] openedCWXPath() { mixin(S_TRACE);
		static if (is(ID:CouponId)) {
			return ["couponview"];
		} else static if (is(ID:GossipId)) {
			return ["gossipview"];
		} else static if (is(ID:CompleteStampId)) {
			return ["completestampview"];
		} else static if (is(ID:KeyCodeId)) {
			return ["keycodeview"];
		} else static if (is(ID:CellNameId)) {
			return ["cellnameview"];
		} else static assert (0);
	}
}

class NameView(ID) : TCPD {
private:
	private class IDObj {
		ID id;
		this (ID id) {
			this.id = id;
		}
	}

	static if (is(ID:CouponId)) {
		alias toCouponId ToID;
	} else static if (is(ID:GossipId)) {
		alias toGossipId ToID;
	} else static if (is(ID:CompleteStampId)) {
		alias toCompleteStampId ToID;
	} else static if (is(ID:KeyCodeId)) {
		alias toKeyCodeId ToID;
	} else static if (is(ID:CellNameId)) {
		alias toCellNameId ToID;
	} else static assert (0);

	int _readOnly = 0;
	Summary _summ = null;

	bool _inProc = false;

	Commons _comm;
	UndoManager _undo;

	Table _list;
	TableTextEdit _nameEdit;
	TableSorter!Object _nameSorter;
	TableSorter!Object _ucSorter;

	IncSearch _incSearch = null;
	private void incSearch() { mixin(S_TRACE);
		if (!_list || _list.isDisposed()) return;

		.forceFocus(_list, true);
		_incSearch.startIncSearch();
	}

	bool compName(const Object o1, const Object o2) { mixin(S_TRACE);
		auto a1 = cast(const IDObj)o1;
		auto a2 = cast(const IDObj)o2;

		int c;
		if (_comm.prop.var.etc.logicalSort) { mixin(S_TRACE);
			c = incmp(cast(string)a1.id, cast(string)a2.id);
		} else { mixin(S_TRACE);
			c = icmp(cast(string)a1.id, cast(string)a2.id);
		}
		return c < 0;
	}
	bool compUC(const Object o1, const Object o2) { mixin(S_TRACE);
		int uc1 = 0;
		int uc2 = 0;
		auto a1 = cast(const IDObj)o1;
		auto a2 = cast(const IDObj)o2;
		if (a1 && a2) { mixin(S_TRACE);
			uc1 = _summ.useCounter.get(a1.id);
			uc2 = _summ.useCounter.get(a2.id);
		}
		if (uc1 < uc2) return true;
		if (uc1 > uc2) return false;
		return compName(o1, o2);
	}
	bool revCompName(const Object o1, const Object o2) { mixin(S_TRACE);
		auto a1 = cast(const IDObj)o1;
		auto a2 = cast(const IDObj)o2;

		int c;
		if (_comm.prop.var.etc.logicalSort) { mixin(S_TRACE);
			c = incmp(cast(string)a2.id, cast(string)a1.id);
		} else { mixin(S_TRACE);
			c = icmp(cast(string)a2.id, cast(string)a1.id);
		}
		return c < 0;
	}
	bool revCompUC(const Object o1, const Object o2) { mixin(S_TRACE);
		int uc1 = 0;
		int uc2 = 0;
		auto a1 = cast(const IDObj)o1;
		auto a2 = cast(const IDObj)o2;
		if (a1 && a2) { mixin(S_TRACE);
			uc1 = _summ.useCounter.get(a1.id);
			uc2 = _summ.useCounter.get(a2.id);
		}
		if (uc2 < uc1) return true;
		if (uc2 > uc1) return false;
		return revCompName(o1, o2);
	}

	void editEnd(TableItem itm, int column, string newText) { mixin(S_TRACE);
		if (!_list || _list.isDisposed()) return;

		if (_readOnly) return;
		assert (column == 0);
		if (!newText.length) return;

		_inProc = true;
		scope (exit) _inProc = false;

		static if (is(ID:CouponId)) {
			auto uc = _summ.useCounter.coupon;
		} else static if (is(ID:GossipId)) {
			auto uc = _summ.useCounter.gossip;
		} else static if (is(ID:CompleteStampId)) {
			auto uc = _summ.useCounter.completeStamp;
		} else static if (is(ID:KeyCodeId)) {
			auto uc = _summ.useCounter.keyCode;
		} else static if (is(ID:CellNameId)) {
			auto uc = _summ.useCounter.cellName;
		} else static assert (0);

		ReplaceDialog.renameCoupon(_comm, _summ, itm, ToID(itm.getText(0)), ToID(newText), uc, _undo, null, false, _list, null);
		itm.setData(new IDObj(ToID(newText)));

		static if (is(ID:CouponId)) { mixin(S_TRACE);
			_comm.refCoupons.call(this);
		} else static if (is(ID:GossipId)) { mixin(S_TRACE);
			_comm.refGossips.call(this);
		} else static if (is(ID:CompleteStampId)) { mixin(S_TRACE);
			_comm.refCompleteStamps.call(this);
		} else static if (is(ID:KeyCodeId)) { mixin(S_TRACE);
			_comm.refKeyCodes.call(this);
		} else static if (is(ID:CellNameId)) { mixin(S_TRACE);
			_comm.refCellNames.call(this);
		} else static assert (0);
		_summ.changed();
		_comm.replText.call();
		sort();
		_list.showSelection();
	}

	bool _refUndo = false;
	void refUndoMax() { mixin(S_TRACE);
		if (!_refUndo) return;
		_undo.max = _comm.prop.var.etc.undoMaxReplace;
	}
public:
	this (Commons comm, Composite parentShell, Composite parent, UndoManager undo, bool readOnly) { mixin(S_TRACE);
		_comm = comm;
		_readOnly = readOnly ? SWT.READ_ONLY : SWT.NONE;
		_refUndo = undo is null;
		_undo = undo ? undo : new UndoManager(_comm.prop.var.etc.undoMaxEvent);

		_comm.refUndoMax.add(&refUndoMax);
		_comm.changed.add(&changed);
		.listener(parentShell, SWT.Dispose, { mixin(S_TRACE);
			_comm.refUndoMax.remove(&refUndoMax);
			_comm.changed.remove(&changed);
		});
	}

	void reconstruct(Composite parent) { mixin(S_TRACE);
		if (_list && !_list.isDisposed()) return;

		auto comp = new Composite(parent, SWT.NONE);
		comp.setLayout(windowGridLayout(1, true));
		_list = .rangeSelectableTable(comp, SWT.MULTI | SWT.BORDER | SWT.FULL_SELECTION | SWT.VIRTUAL);
		_list.setLayoutData(new GridData(GridData.FILL_BOTH));
		_list.setHeaderVisible(true);
		auto nameCol = new TableColumn(_list, SWT.NULL);
		nameCol.setText(_comm.prop.msgs.idName);
		auto countCol = new TableColumn(_list, SWT.NULL);
		countCol.setText(_comm.prop.msgs.idCount);
		saveColumnWidth!("prop.var.etc.idNameColumn")(_comm.prop, nameCol);
		saveColumnWidth!("prop.var.etc.idCountColumn")(_comm.prop, countCol);
		.listener(_list, SWT.Selection, &refreshStatusLine);

		_nameEdit = new TableTextEdit(_comm, _comm.prop, _list, 0, &editEnd);

		_incSearch = new IncSearch(_comm, _list);
		_incSearch.modEvent ~= &updateList;

		auto menu = new Menu(parent.getShell(), SWT.POP_UP);
		createMenuItem(_comm, menu, MenuID.IncSearch, &incSearch, null);
		new MenuItem(menu, SWT.SEPARATOR);
		if (!_readOnly) { mixin(S_TRACE);
			createMenuItem(_comm, menu, MenuID.EditProp, &editName, &canEditName);
			new MenuItem(menu, SWT.SEPARATOR);
		}

		createMenuItem(_comm, menu, MenuID.Undo, &this.undo, &canUndo);
		createMenuItem(_comm, menu, MenuID.Redo, &this.redo, &canRedo);
		new MenuItem(menu, SWT.SEPARATOR);
		appendMenuTCPD(_comm, menu, this, false, true, false, false, false);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.SelectAll, &selectAll, &canSelectAll);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.FindID, &findID, &canFindID);
		_list.setMenu(menu);

		_comm.refUseCount.add(&refUseCount);
		static if (is(ID:CouponId)) { mixin(S_TRACE);
			_comm.refCoupons.add(&refID);
		} else static if (is(ID:GossipId)) { mixin(S_TRACE);
			_comm.refGossips.add(&refID);
		} else static if (is(ID:CompleteStampId)) { mixin(S_TRACE);
			_comm.refCompleteStamps.add(&refID);
		} else static if (is(ID:KeyCodeId)) { mixin(S_TRACE);
			_comm.refKeyCodes.add(&refID);
		} else static if (is(ID:CellNameId)) { mixin(S_TRACE);
			_comm.refCellNames.add(&refID);
		}

		.listener(_list, SWT.Dispose, { mixin(S_TRACE);
			_comm.refUseCount.remove(&refUseCount);
			static if (is(ID:CouponId)) { mixin(S_TRACE);
				_comm.refCoupons.remove(&refID);
			} else static if (is(ID:GossipId)) { mixin(S_TRACE);
				_comm.refGossips.remove(&refID);
			} else static if (is(ID:CompleteStampId)) { mixin(S_TRACE);
				_comm.refCompleteStamps.remove(&refID);
			} else static if (is(ID:KeyCodeId)) { mixin(S_TRACE);
				_comm.refKeyCodes.remove(&refID);
			} else static if (is(ID:CellNameId)) { mixin(S_TRACE);
				_comm.refCellNames.remove(&refID);
			} else static assert (0);
		});

		_nameSorter = new TableSorter!(Object)(nameCol, &compName, &revCompName);
		_ucSorter = new TableSorter!(Object)(countCol, &compUC, &revCompUC);
		auto st = _nameSorter;
		static if (is(ID:CouponId)) { mixin(S_TRACE);
			auto sortColumn = _comm.prop.var.etc.couponSortColumn;
			auto sortDir = _comm.prop.var.etc.couponSortDirection;
		} else static if (is(ID:GossipId)) { mixin(S_TRACE);
			auto sortColumn = _comm.prop.var.etc.gossipSortColumn;
			auto sortDir = _comm.prop.var.etc.gossipSortDirection;
		} else static if (is(ID:CompleteStampId)) { mixin(S_TRACE);
			auto sortColumn = _comm.prop.var.etc.completeStampSortColumn;
			auto sortDir = _comm.prop.var.etc.completeStampSortDirection;
		} else static if (is(ID:KeyCodeId)) { mixin(S_TRACE);
			auto sortColumn = _comm.prop.var.etc.keyCodeSortColumn;
			auto sortDir = _comm.prop.var.etc.keyCodeSortDirection;
		} else static if (is(ID:CellNameId)) { mixin(S_TRACE);
			auto sortColumn = _comm.prop.var.etc.cellNameSortColumn;
			auto sortDir = _comm.prop.var.etc.cellNameSortDirection;
		} else static assert (0);
		switch (sortColumn) {
		case 0:
			st = _nameSorter;
			break;
		case 1:
			st = _ucSorter;
			break;
		default:
		}
		switch (sortDir) {
		case SortDir.Up:
			st.doSort(SWT.UP);
			break;
		case SortDir.Down:
			st.doSort(SWT.DOWN);
			break;
		default:
			// 必ずソートする
			st.doSort(SWT.UP);
			break;
		}
		void storeSortParams() { mixin (S_TRACE);
			int sortDir;
			switch (_list.getSortDirection()) {
			case SWT.UP:
				sortDir = SortDir.Up;
				break;
			case SWT.DOWN:
				sortDir = SortDir.Down;
				break;
			default:
				// 必ずソートする
				sortDir = SortDir.Up;
				break;
			}
			int sortColumn;
			if (_list.getSortColumn() is _nameSorter.column) { mixin(S_TRACE);
				sortColumn = 0;
			} else if (_list.getSortColumn() is _ucSorter.column) { mixin(S_TRACE);
				sortColumn = 1;
			} else { mixin(S_TRACE);
				sortColumn = -1;
			}
			static if (is(ID:CouponId)) { mixin(S_TRACE);
				_comm.prop.var.etc.couponSortColumn = sortColumn;
				_comm.prop.var.etc.couponSortDirection = sortDir;
			} else static if (is(ID:GossipId)) { mixin(S_TRACE);
				_comm.prop.var.etc.gossipSortColumn = sortColumn;
				_comm.prop.var.etc.gossipSortDirection = sortDir;
			} else static if (is(ID:CompleteStampId)) { mixin(S_TRACE);
				_comm.prop.var.etc.completeStampSortColumn = sortColumn;
				_comm.prop.var.etc.completeStampSortDirection = sortDir;
			} else static if (is(ID:KeyCodeId)) { mixin(S_TRACE);
				_comm.prop.var.etc.keyCodeSortColumn = sortColumn;
				_comm.prop.var.etc.keyCodeSortDirection = sortDir;
			} else static if (is(ID:CellNameId)) { mixin(S_TRACE);
				_comm.prop.var.etc.cellNameSortColumn = sortColumn;
				_comm.prop.var.etc.cellNameSortDirection = sortDir;
			} else static assert (0);

			_comm.refreshToolBar();
		}
		_nameSorter.sortedEvent ~= &storeSortParams;
		_ucSorter.sortedEvent ~= &storeSortParams;

		updateList();
	}

	@property
	Composite widget() { mixin(S_TRACE);
		if (!_list || _list.isDisposed()) return null;
		return _list.getParent();
	}

	@property
	UndoManager undoManager() { mixin(S_TRACE);
		return _undo;
	}

	private void refreshStatusLine() { mixin(S_TRACE);
		if (!_list || _list.isDisposed()) return;

		auto count = _list.getItemCount();
		auto selCount = _list.getSelectionCount();
		static if (is(ID:CouponId)) { mixin(S_TRACE);
			auto typeName = _comm.prop.msgs.coupon;
		} else static if (is(ID:GossipId)) { mixin(S_TRACE);
			auto typeName = _comm.prop.msgs.gossip;
		} else static if (is(ID:CompleteStampId)) { mixin(S_TRACE);
			auto typeName = _comm.prop.msgs.completeStamp;
		} else static if (is(ID:KeyCodeId)) { mixin(S_TRACE);
			auto typeName = _comm.prop.msgs.keyCode;
		} else static if (is(ID:CellNameId)) { mixin(S_TRACE);
			auto typeName = _comm.prop.msgs.cellName;
		} else static assert (0);
		auto statusLine = .tryFormat(_comm.prop.msgs.idStatus, typeName, count);
		if (0 < selCount) { mixin(S_TRACE);
			statusLine = .tryFormat(_comm.prop.msgs.idStatusSel, statusLine, selCount);
		}
		_comm.setStatusLine(widget, statusLine);
	}

	@property
	void summary(Summary summ) { mixin(S_TRACE);
		if (summ is _summ) return;
		_undo.reset();
		_summ = summ;
		updateList();
	}

	@property
	bool canEditName() { mixin(S_TRACE);
		if (!_list || _list.isDisposed()) return false;
		return _list.getSelectionIndex() != -1;
	}
	void editName() { mixin(S_TRACE);
		if (!canEditName) return;
		_nameEdit.startEdit();
	}

	@property
	bool canUndo() { mixin(S_TRACE);
		if (!_list || _list.isDisposed()) return false;
		return !_readOnly && _undo.canUndo;
	}
	void undo() { mixin(S_TRACE);
		if (!canUndo) return;
		_inProc = true;
		scope (exit) _inProc = false;

		_undo.undo();
	}

	@property
	bool canRedo() { mixin(S_TRACE);
		if (!_list || _list.isDisposed()) return false;
		return !_readOnly && _undo.canRedo;
	}
	void redo() { mixin(S_TRACE);
		if (!canRedo) return;
		_inProc = true;
		scope (exit) _inProc = false;

		_undo.redo();
	}

	@property
	bool canSelectAll() { mixin(S_TRACE);
		if (!_list || _list.isDisposed()) return false;
		return _list.getSelectionCount() != _list.getItemCount();
	}
	void selectAll() { mixin(S_TRACE);
		if (!canSelectAll) return;
		_list.selectAll();
		_comm.refreshToolBar();
	}

	@property
	bool canFindID() { mixin(S_TRACE);
		if (!_list || _list.isDisposed()) return false;
		return _list.getSelectionIndex() != -1;
	}
	void findID() { mixin(S_TRACE);
		if (!canFindID) return;
		auto sels = _list.getSelection();
		assert (sels.length);
		_comm.replaceID(ToID(sels[0].getText(0)), true);
	}

	void select(in ID[] ids) { mixin(S_TRACE);
		if (!_list || _list.isDisposed()) return;
		bool[string] sels;
		foreach (id; ids) sels[cast(string)id] = true;
		_incSearch.close();

		_list.deselectAll();
		int[] indices;
		foreach (i, itm; _list.getItems()) { mixin(S_TRACE);
			if (sels.get(itm.getText(0), false)) { mixin(S_TRACE);
				indices ~= cast(int)i;
			}
		}
		_list.select(indices);
		_list.showSelection();
		_comm.refreshToolBar();
	}

	private void changed() { mixin(S_TRACE);
		if (!_inProc) _undo.reset();
	}

	private void refID(Object sender) { mixin(S_TRACE);
		if (!_list || _list.isDisposed()) return;
		if (sender is this) return;
		if (!_inProc) _undo.reset();
		updateList();
	}

	void sort() { mixin(S_TRACE);
		if (_list.getSortColumn() is _nameSorter.column) { mixin(S_TRACE);
			_nameSorter.doSort(_list.getSortDirection());
		} else if (_list.getSortColumn() is _ucSorter.column) { mixin(S_TRACE);
			_ucSorter.doSort(_list.getSortDirection());
		} else assert (0);
	}

	private void updateList() { mixin(S_TRACE);
		if (!_list || _list.isDisposed()) return;
		_list.setRedraw(false);
		scope (exit) _list.setRedraw(true);
		if (_summ) { mixin(S_TRACE);
			bool[string] sels;
			foreach (itm; _list.getSelection()) { mixin(S_TRACE);
				sels[itm.getText(0)] = true;
			}
			_list.deselectAll();
			static if (is(ID:CouponId)) {
				auto keys = _summ.useCounter.coupon.keys;
				auto image = _comm.prop.images.couponNormal;
			} else static if (is(ID:GossipId)) {
				auto keys = _summ.useCounter.gossip.keys;
				auto image = _comm.prop.images.gossip;
			} else static if (is(ID:CompleteStampId)) {
				auto keys = _summ.useCounter.completeStamp.keys;
				auto image = _comm.prop.images.endScenario;
			} else static if (is(ID:KeyCodeId)) {
				auto keys = _summ.useCounter.keyCode.keys;
				auto image = _comm.prop.images.keyCode;
			} else static if (is(ID:CellNameId)) {
				auto keys = _summ.useCounter.cellName.keys;
				auto image = _comm.prop.images.backs;
			} else static assert (0);

			int i = 0;
			int[] selIndices;
			// 後からsort()を呼び出すと重いので事前にソートする
			bool cmp(ID a, ID b) { mixin(S_TRACE);
				if (_list.getSortDirection() is SWT.DOWN) { mixin(S_TRACE);
					if (_list.getSortColumn() is _ucSorter.column) {
						auto uc1 = _summ.useCounter.get(a);
						auto uc2 = _summ.useCounter.get(b);
						if (uc2 < uc1) return true;
						if (uc2 > uc1) return false;
					}
					if (_comm.prop.var.etc.logicalSort) { mixin(S_TRACE);
						return incmp(cast(string)b, cast(string)a) < 0;
					} else { mixin(S_TRACE);
						return icmp(cast(string)b, cast(string)a) < 0;
					}
				} else { mixin(S_TRACE);
					if (_list.getSortColumn() is _ucSorter.column) {
						auto uc1 = _summ.useCounter.get(a);
						auto uc2 = _summ.useCounter.get(b);
						if (uc1 < uc2) return true;
						if (uc1 > uc2) return false;
					}
					if (_comm.prop.var.etc.logicalSort) { mixin(S_TRACE);
						return incmp(cast(string)a, cast(string)b) < 0;
					} else { mixin(S_TRACE);
						return icmp(cast(string)a, cast(string)b) < 0;
					}
				}
			}
			foreach (key; std.algorithm.sort!cmp(keys)) { mixin(S_TRACE);
				if (!_incSearch.match(cast(string)key)) continue;
				auto itm = i < _list.getItemCount() ? _list.getItem(i) : new TableItem(_list, SWT.NONE);
				itm.setImage(0, image);
				itm.setText(0, cast(string)key);
				itm.setText(1, .to!string(_summ.useCounter.get(key)));
				itm.setData(new IDObj(key));
				if (sels.get(cast(string)key, false)) { mixin(S_TRACE);
					selIndices ~= i;
				}
				i++;
			}
			if (i < _list.getItemCount()) { mixin(S_TRACE);
				foreach_reverse (i2; i .. _list.getItemCount()) { mixin(S_TRACE);
					_list.remove(i2);
				}
			}
			_list.select(selIndices);
		} else { mixin(S_TRACE);
			_list.removeAll();
		}
		refreshStatusLine();
	}

	private void refUseCount() { mixin(S_TRACE);
		if (!_list || _list.isDisposed()) return;
		if (!_summ) return;
		updateList();
	}

	override
	void cut(SelectionEvent se) { mixin(S_TRACE);
		assert (0);
	}
	override
	void copy(SelectionEvent se) { mixin(S_TRACE);
		string[] t;
		foreach (itm; _list.getSelection()) { mixin(S_TRACE);
			t ~= itm.getText(0).replace("\n", .newline);
		}
		if (!t.length) return;
		auto text = new ArrayWrapperString(std.string.join(t, .newline));
		_comm.clipboard.setContents([text], [TextTransfer.getInstance()]);
		_comm.refreshToolBar();
	}
	override
	void paste(SelectionEvent se) { mixin(S_TRACE);
		assert (0);
	}
	override
	void del(SelectionEvent se) { mixin(S_TRACE);
		assert (0);
	}
	override
	void clone(SelectionEvent se) { mixin(S_TRACE);
		assert (0);
	}
	@property
	override
	bool canDoTCPD() { mixin(S_TRACE);
		return _list.getSelectionIndex() != -1;
	}
	@property
	override
	bool canDoT() { mixin(S_TRACE);
		return false;
	}
	@property
	override
	bool canDoC() { mixin(S_TRACE);
		if (!_list || _list.isDisposed()) return false;
		return _list.getSelectionIndex() != -1;
	}
	@property
	override
	bool canDoP() { mixin(S_TRACE);
		return false;
	}
	@property
	override
	bool canDoD() { mixin(S_TRACE);
		return false;
	}
	@property
	override
	bool canDoClone() { mixin(S_TRACE);
		return false;
	}
}

alias NameWindow!CouponId CouponWindow;
alias NameWindow!GossipId GossipWindow;
alias NameWindow!CompleteStampId CompleteStampWindow;
alias NameWindow!KeyCodeId KeyCodeWindow;
alias NameWindow!CellNameId CellNameWindow;
