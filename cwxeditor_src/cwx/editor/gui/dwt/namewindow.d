
module cwx.editor.gui.dwt.namewindow;

import cwx.card;
import cwx.coupon;
import cwx.features;
import cwx.flag;
import cwx.menu;
import cwx.path;
import cwx.structs;
import cwx.summary;
import cwx.textholder;
import cwx.types;
import cwx.usecounter;
import cwx.utils;
import cwx.xml;

import cwx.editor.gui.dwt.chooser;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.incsearch;
import cwx.editor.gui.dwt.replacedialog;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.xmlbytestransfer;

import std.algorithm;
import std.array;
import std.ascii;
import std.conv;
import std.string;
import std.typecons;

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
		putMenuAction(MenuID.IncSearch, &_view.incSearch, &_view.canIncSearch);
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
		} else static if (is(ID:CardGroupId)) {
			return _comm.prop.images.cardGroupView;
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
		} else static if (is(ID:CardGroupId)) {
			return _comm.prop.msgs.cardGroupTabName;
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
		} else static if (is(ID:CardGroupId)) {
			return ["cardgroupview"];
		} else static assert (0);
	}
}

class NameView(ID) : TCPD {
private:
	int _readOnly = 0;
	Summary _summ = null;

	bool _inProc = false;

	Commons _comm;
	UndoManager _undo;

	Table _list;
	TableTextEdit _nameEdit;
	TableSorter!Object _nameSorter;
	TableSorter!Object _ucSorter;
	ID[] _nameList = [];

	bool _hasName = false;

	IncSearch _incSearch = null;
	private void incSearch() { mixin(S_TRACE);
		if (!_list || _list.isDisposed()) return;

		.forceFocus(_list, true);
		_incSearch.startIncSearch();
	}
	@property
	private bool canIncSearch() { return _hasName; }

	Control createEditor(TableItem itm, int editC) { mixin(S_TRACE);
		auto t = .createTextEditor(_comm, _comm.prop, itm.getParent(), itm.getText(editC));
		static if (is(ID:CouponId)) {
			new MenuItem(t.getMenu(), SWT.SEPARATOR);
			.createCouponTypeMenu(_comm, t, true, true);
		}
		static if (is(ID:KeyCodeId)) {
			new MenuItem(t.getMenu(), SWT.SEPARATOR);
			.createKeyCodeTimingMenu(_comm, t, false, true);
		}
		return t;
	}
	void editEnd(TableItem itm, int column, string newText) { mixin(S_TRACE);
		if (!_list || _list.isDisposed()) return;

		if (_readOnly) return;
		assert (column == 0);
		if (!newText.length) return;
		auto oldText = itm.getText(0);
		if (newText == oldText) return;

		_inProc = true;
		scope (exit) _inProc = false;

		ReplaceDialog.renameCoupon(_comm, _summ, itm, ToID!ID(oldText), ToID!ID(newText), _undo, null, false, _list, null, _nameList);
		assert (_summ.useCounter.get(ToID!ID(oldText)) == 0);

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
		} else static if (is(ID:CardGroupId)) { mixin(S_TRACE);
			_comm.refCardGroups.call(this);
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
		.listener(_list, SWT.SetData, &setData);
		auto nameCol = new TableColumn(_list, SWT.NULL);
		nameCol.setText(_comm.prop.msgs.idName);
		auto countCol = new TableColumn(_list, SWT.NULL);
		countCol.setText(_comm.prop.msgs.idCount);
		saveColumnWidth!("prop.var.etc.idNameColumn")(_comm.prop, nameCol);
		saveColumnWidth!("prop.var.etc.idCountColumn")(_comm.prop, countCol);
		.listener(_list, SWT.Selection, &refreshStatusLine);

		_nameEdit = new TableTextEdit(_comm, _comm.prop, _list, 0, &editEnd, null, &createEditor);

		_incSearch = new IncSearch(_comm, _list, &canIncSearch);
		_incSearch.modEvent ~= &updateList;

		auto menu = new Menu(parent.getShell(), SWT.POP_UP);
		createMenuItem(_comm, menu, MenuID.IncSearch, &incSearch, &canIncSearch);
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
		static if (is(ID:CouponId)) {
			new MenuItem(menu, SWT.SEPARATOR);
			{ mixin(S_TRACE);
				void delegate() dlg = null;
				auto cascade = createMenuItem(_comm, menu, MenuID.ConvertCouponType, dlg, () => canConvType!(CouponType.Normal) || canConvType!(CouponType.Hide) || canConvType!(CouponType.System) || canConvType!(CouponType.Dur) || canConvType!(CouponType.DurBattle), SWT.CASCADE);
				auto sub = new Menu(parent.getShell(), SWT.DROP_DOWN);
				cascade.setMenu(sub);
				createMenuItem(_comm, sub, MenuID.ConvertCouponTypeNormal, &convType!(CouponType.Normal), &canConvType!(CouponType.Normal));
				createMenuItem(_comm, sub, MenuID.ConvertCouponTypeHide, &convType!(CouponType.Hide), &canConvType!(CouponType.Hide));
				createMenuItem(_comm, sub, MenuID.ConvertCouponTypeDur, &convType!(CouponType.Dur), &canConvType!(CouponType.Dur));
				createMenuItem(_comm, sub, MenuID.ConvertCouponTypeDurBattle, &convType!(CouponType.DurBattle), &canConvType!(CouponType.DurBattle));
				createMenuItem(_comm, sub, MenuID.ConvertCouponTypeSystem, &convType!(CouponType.System), &canConvType!(CouponType.System));
			}
			{ mixin(S_TRACE);
				void delegate() dlg = null;
				auto cascade = createMenuItem(_comm, menu, MenuID.CopyTypeConvertedCoupon, dlg, &canCopyWith, SWT.CASCADE);
				auto sub = new Menu(parent.getShell(), SWT.DROP_DOWN);
				cascade.setMenu(sub);
				createMenuItem(_comm, sub, MenuID.CopyTypeConvertedCouponNormal, &copyWithType!(CouponType.Normal), &canCopyWith);
				createMenuItem(_comm, sub, MenuID.CopyTypeConvertedCouponHide, &copyWithType!(CouponType.Hide), &canCopyWith);
				createMenuItem(_comm, sub, MenuID.CopyTypeConvertedCouponDur, &copyWithType!(CouponType.Dur), &canCopyWith);
				createMenuItem(_comm, sub, MenuID.CopyTypeConvertedCouponDurBattle, &copyWithType!(CouponType.DurBattle), &canCopyWith);
				createMenuItem(_comm, sub, MenuID.CopyTypeConvertedCouponSystem, &copyWithType!(CouponType.System), &canCopyWith);
			}
		}
		static if (is(ID:KeyCodeId)) {
			new MenuItem(menu, SWT.SEPARATOR);
			void delegate() dlg = null;
			auto cascade = createMenuItem(_comm, menu, MenuID.CopyTimingConvertedKeyCode, dlg, &canCopyWith, SWT.CASCADE);
			auto sub = new Menu(parent.getShell(), SWT.DROP_DOWN);
			cascade.setMenu(sub);
			createMenuItem(_comm, sub, MenuID.CopyTimingConvertedKeyCodeUse, &copyKeyCodeWith!(FKCKind.Use), &canCopyWith);
			createMenuItem(_comm, sub, MenuID.CopyTimingConvertedKeyCodeSuccess, &copyKeyCodeWith!(FKCKind.Success), &canCopyWith);
			createMenuItem(_comm, sub, MenuID.CopyTimingConvertedKeyCodeFailure, &copyKeyCodeWith!(FKCKind.Failure), &canCopyWith);
			createMenuItem(_comm, sub, MenuID.CopyTimingConvertedKeyCodeHasNot, &copyKeyCodeWith!(FKCKind.HasNot), &canCopyWith);
		}
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.FindID, &findID, &canFindID);
		_list.setMenu(menu);

		_comm.refUseCount.add(&refUseCount);
		static if (is(ID:CouponId)) { mixin(S_TRACE);
			_comm.refCoupons.add(&refID);
			_comm.refFlagAndStep.add(&refIDFS);
		} else static if (is(ID:GossipId)) { mixin(S_TRACE);
			_comm.refGossips.add(&refID);
			_comm.refFlagAndStep.add(&refIDFS);
		} else static if (is(ID:CompleteStampId)) { mixin(S_TRACE);
			_comm.refCompleteStamps.add(&refID);
		} else static if (is(ID:KeyCodeId)) { mixin(S_TRACE);
			_comm.refKeyCodes.add(&refID);
		} else static if (is(ID:CellNameId)) { mixin(S_TRACE);
			_comm.refCellNames.add(&refID);
		} else static if (is(ID:CardGroupId)) { mixin(S_TRACE);
			_comm.refCardGroups.add(&refID);
		}
		_comm.replText.add(&refID);

		.listener(_list, SWT.Dispose, { mixin(S_TRACE);
			_comm.refUseCount.remove(&refUseCount);
			static if (is(ID:CouponId)) { mixin(S_TRACE);
				_comm.refCoupons.remove(&refID);
				_comm.refFlagAndStep.remove(&refIDFS);
			} else static if (is(ID:GossipId)) { mixin(S_TRACE);
				_comm.refGossips.remove(&refID);
				_comm.refFlagAndStep.remove(&refIDFS);
			} else static if (is(ID:CompleteStampId)) { mixin(S_TRACE);
				_comm.refCompleteStamps.remove(&refID);
			} else static if (is(ID:KeyCodeId)) { mixin(S_TRACE);
				_comm.refKeyCodes.remove(&refID);
			} else static if (is(ID:CellNameId)) { mixin(S_TRACE);
				_comm.refCellNames.remove(&refID);
			} else static if (is(ID:CardGroupId)) { mixin(S_TRACE);
				_comm.refCardGroups.remove(&refID);
			} else static assert (0);
			_comm.replText.remove(&refID);
		});

		_nameSorter = new TableSorter!(Object)(nameCol, null, null);
		_ucSorter = new TableSorter!(Object)(countCol, null, null);
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
		} else static if (is(ID:CardGroupId)) { mixin(S_TRACE);
			auto sortColumn = _comm.prop.var.etc.cardGroupSortColumn;
			auto sortDir = _comm.prop.var.etc.cardGroupSortDirection;
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
		void storeSortParams() { mixin(S_TRACE);
			updateList();
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
			} else static if (is(ID:CardGroupId)) { mixin(S_TRACE);
				_comm.prop.var.etc.cardGroupSortColumn = sortColumn;
				_comm.prop.var.etc.cardGroupSortDirection = sortDir;
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
		} else static if (is(ID:CardGroupId)) { mixin(S_TRACE);
			auto typeName = _comm.prop.msgs.cardGroup;
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
		_comm.replaceID(ToID!ID(sels[0].getText(0)), true);
	}

	void select(in ID[] ids) { mixin(S_TRACE);
		if (!_list || _list.isDisposed()) return;
		bool[ID] sels;
		foreach (id; ids) sels[id] = true;
		_incSearch.close();

		_list.deselectAll();
		int[] indices;
		foreach (i, key; _nameList) { mixin(S_TRACE);
			if (sels.get(key, false)) { mixin(S_TRACE);
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
	static if (is(ID:CouponId) || is(ID:GossipId)) {
		private void refIDFS(cwx.flag.Flag[] flags, Step[] steps, cwx.flag.Variant[] variants) { mixin(S_TRACE);
			if (!_list || _list.isDisposed()) return;
			if (!_summ) return;
			bool update(F)(F[] list) { mixin(S_TRACE);
				foreach (f; list) { mixin(S_TRACE);
					auto path = f.path;
					foreach (u; _summ.useCounter.values(F.toID(path))) { mixin(S_TRACE);
						if (auto th = cast(SimpleTextHolder)u.owner) { mixin(S_TRACE);
							static if (is(ID:CouponId)) static immutable TYPE = TextHolderType.Coupon;
							static if (is(ID:GossipId)) static immutable TYPE = TextHolderType.Gossip;
							if (th.type is TYPE) { mixin(S_TRACE);
								refID(null);
								return true;
							}
						}
					}
				}
				return false;
			}
			if (update(flags)) return;
			if (update(steps)) return;
			if (update(variants)) return;
		}
	}

	void sort() { mixin(S_TRACE);
		if (_list.getSortColumn() is _nameSorter.column) { mixin(S_TRACE);
			_nameSorter.doSort(_list.getSortDirection());
		} else if (_list.getSortColumn() is _ucSorter.column) { mixin(S_TRACE);
			_ucSorter.doSort(_list.getSortDirection());
		} else assert (0);
	}
	private auto getKeys() { mixin(S_TRACE);
		if (_summ) { mixin(S_TRACE);
			return _summ.useCounter.keys!ID;
		} else { mixin(S_TRACE);
			return typeof(return).init;
		}
	}

	private void updateList() { mixin(S_TRACE);
		if (!_list || _list.isDisposed()) return;
		_list.setRedraw(false);
		scope (exit) _list.setRedraw(true);
		if (_nameEdit && _nameEdit.isEditing) _nameEdit.cancel();
		_hasName = false;
		if (_summ) { mixin(S_TRACE);
			bool[string] sels;
			foreach (itm; _list.getSelection()) { mixin(S_TRACE);
				sels[itm.getText(0)] = true;
			}
			_list.deselectAll();
			_list.clearAll();
			auto keys = getKeys();

			auto topIndex = _list.getTopIndex();
			int i = 0;
			int[] selIndices;

			auto down = _list.getSortDirection() is SWT.DOWN;
			auto isUC = _list.getSortColumn() is _ucSorter.column;
			bool cmp(ref const Tuple!(NCompare, uint) a, ref const Tuple!(NCompare, uint) b) { mixin(S_TRACE);
				auto r = 0;
				if (down) { mixin(S_TRACE);
					if (isUC) { mixin(S_TRACE);
						if (b[1] < a[1]) r = -1;
						if (b[1] > a[1]) r = 1;
					}
					if (!r) { mixin(S_TRACE);
						return b[0] < a[0];
					}
				} else { mixin(S_TRACE);
					if (isUC) { mixin(S_TRACE);
						if (a[1] < b[1]) r = -1;
						if (a[1] > b[1]) r = 1;
					}
					if (!r) { mixin(S_TRACE);
						return a[0] < b[0];
					}
				}
				return r < 0;
			}

			_nameList = [];
			Tuple!(NCompare, uint)[] keys2;
			foreach (key; keys) { mixin(S_TRACE);
				_hasName = true;
				if (!_incSearch.match(cast(string)key)) continue;
				keys2 ~= .tuple(NCompare(cast(string)key, true, _comm.prop.var.etc.logicalSort), isUC ? _summ.useCounter.get(key) : 0);
			}
			auto sorted = std.algorithm.sort!cmp(keys2);
			foreach (key; sorted) { mixin(S_TRACE);
				_nameList ~= ToID!ID(key[0].value);
				if (sels.get(key[0].value, false)) { mixin(S_TRACE);
					selIndices ~= i;
				}
				i++;
			}
			_list.setItemCount(cast(int)_nameList.length);
			if (selIndices.length) _list.select(selIndices);
			_list.setTopIndex(topIndex);
		} else { mixin(S_TRACE);
			_list.setItemCount(0);
		}
		refreshStatusLine();
	}

	private void setData(Event e) { mixin(S_TRACE);
		if (!_summ) return;
		auto itm = cast(TableItem)e.item;
		auto i = e.index;
		auto key = _nameList[i];
		static if (is(ID:CouponId)) {
			auto image = _comm.prop.images.couponNormal;
		} else static if (is(ID:GossipId)) {
			auto image = _comm.prop.images.gossip;
		} else static if (is(ID:CompleteStampId)) {
			auto image = _comm.prop.images.endScenario;
		} else static if (is(ID:KeyCodeId)) {
			auto image = _comm.prop.images.keyCode;
		} else static if (is(ID:CellNameId)) {
			auto image = _comm.prop.images.backs;
		} else static if (is(ID:CardGroupId)) {
			auto image = _comm.prop.images.cards;
		} else static assert (0);
		itm.setImage(0, image);
		itm.setText(0, cast(string)key);
		itm.setText(1, .to!string(_summ.useCounter.get(key)));
	}

	private void refUseCount() { mixin(S_TRACE);
		if (!_list || _list.isDisposed()) return;
		if (!_summ) return;
		if (_nameList.length == getKeys().length) { mixin(S_TRACE);
			_list.clearAll();
		} else { mixin(S_TRACE);
			updateList();
		}
	}

	override
	void cut(SelectionEvent se) { mixin(S_TRACE);
		assert (0);
	}
	override
	void copy(SelectionEvent se) { mixin(S_TRACE);
		if (_nameEdit && _nameEdit.isEditing) _nameEdit.enter();
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

	static if (is(ID:CouponId)) {
		@property
		private bool canConvType(CouponType Type)() { mixin(S_TRACE);
			if (!_list || _list.isDisposed()) return false;
			foreach (name; _list.getSelection().map!(itm => itm.getText())) { mixin(S_TRACE);
				auto name2 = _comm.prop.sys.convCoupon(name, Type, false);
				if (_summ.useCounter.get(toCouponId(name2)) == 0) return true;
			}
			return false;
		}
		private void convType(CouponType Type)() { mixin(S_TRACE);
			if (!canConvType!Type) return;

			_inProc = true;
			scope (exit) _inProc = false;

			Undo[] us;
			foreach (itm; _list.getSelection()) { mixin(S_TRACE);
				auto name = itm.getText();
				auto name2 = _comm.prop.sys.convCoupon(name, Type, false);
				if (0 < _summ.useCounter.get(toCouponId(name2))) continue;

				auto u = ReplaceDialog.renameCoupon(_comm, _summ, itm, CouponId(name), CouponId(name2), null, null, false, _list, null, _nameList, false);
				assert (u !is null);
				assert (_summ.useCounter.get(CouponId(name)) == 0);
				us ~= u;
			}
			_undo ~= new UndoArr(us, true, { mixin(S_TRACE);
				_summ.changed();
				_comm.replText.call();
				_comm.refCoupons.call();
			});

			_comm.refCoupons.call(this);
			_summ.changed();
			_comm.replText.call();
			sort();
			_list.showSelection();
		}

		@property
		private bool canCopyWith() { mixin(S_TRACE);
			if (!_list || _list.isDisposed()) return false;
			return _list.getSelectionIndex() != -1;
		}
		private void copyWithType(CouponType Type)() { mixin(S_TRACE);
			if (!canCopyWith) return;
			if (_nameEdit && _nameEdit.isEditing) _nameEdit.enter();
			// 当面、変換の結果重複が起こる場合でも排除せず重複したままコピーする
			auto cs = _list.getSelection().map!(itm => new Coupon(_comm.prop.sys.convCoupon(itm.getText(), Type, false), 0))().array();
			if (cs.length) { mixin(S_TRACE);
				auto node = XNode.create(Coupon.XML_NAME_M);
				foreach (c; cs) { mixin(S_TRACE);
					c.toNode(node);
				}
				XMLtoCB(_comm.prop, _comm.clipboard, node.text);
				_comm.refreshToolBar();
			}
		}
	}
	static if (is(ID:KeyCodeId)) {
		@property
		private bool canCopyWith() { mixin(S_TRACE);
			if (!_list || _list.isDisposed()) return false;
			assert (_list.getSelectionIndex() == -1 || _list.getItem(_list.getSelectionIndex()).getText() != "");
			return _list.getSelectionIndex() != -1;
		}
		private void copyKeyCodeWith(FKCKind Kind)() { mixin(S_TRACE);
			if (!canCopyWith) return;
			if (_nameEdit && _nameEdit.isEditing) _nameEdit.enter();
			auto keyCodes = _list.getSelection().map!(itm => _comm.prop.sys.convFireKeyCode(itm.getText(), Kind))().array();
			if (keyCodes.length) { mixin(S_TRACE);
				XMLtoCB(_comm.prop, _comm.clipboard, .keyCodesToXML(keyCodes));
				_comm.refreshToolBar();
			}
		}
	}
}

alias NameWindow!CouponId CouponWindow;
alias NameWindow!GossipId GossipWindow;
alias NameWindow!CompleteStampId CompleteStampWindow;
alias NameWindow!KeyCodeId KeyCodeWindow;
alias NameWindow!CellNameId CellNameWindow;
alias NameWindow!CardGroupId CardGroupWindow;
