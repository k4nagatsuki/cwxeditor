
module cwx.editor.gui.dwt.editablelistview;

import cwx.menu;
import cwx.system;
import cwx.types;
import cwx.utils;
import cwx.xml;

import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.xmlbytestransfer;

import std.algorithm;
import std.array;
import std.range;

import org.eclipse.swt.all;

import java.lang.all;

abstract class AbstractEditableListView(T, bool Sort = false) : Composite {
	void delegate()[] modEvent;
	protected void raiseModifyEvent() { mixin(S_TRACE);
		foreach (dlg; modEvent) { mixin(S_TRACE);
			dlg();
		}
	}
	private string _id;

	private int _readOnly;
	private bool _canDuplicate;

	private Commons _comm;
	private KeyDownFilter _kdFilter;

	private UndoManager _undo;

	private Table _table;
	private T[] _list;

	private ToolBar _toolbar = null;

	private class UndoEdit : Undo {
		private int _index;
		private T _oldVal;
		this (int index) { mixin(S_TRACE);
			_index = index;
			_oldVal = _list[index];
		}
		private void impl() { mixin(S_TRACE);
			foreach (e; editors) { mixin(S_TRACE);
				if (e && e.isEditing) e.cancel();
			}
			auto temp = _list[_index];
			_list[_index] = _oldVal;
			_oldVal = temp;
			_table.clear(_index);
			raiseModifyEvent();
			_comm.refreshToolBar();
		}
		void undo() { impl(); }
		void redo() { impl(); }
		void dispose() { }
	}
	protected void storeSingle(int index) { mixin(S_TRACE);
		_undo ~= new UndoEdit(index);
	}
	private class UndoAll : Undo {
		private T[] _list;
		this () { mixin(S_TRACE);
			_list = this.outer._list.dup;
		}
		private void impl() { mixin(S_TRACE);
			foreach (e; editors) { mixin(S_TRACE);
				if (e && e.isEditing) e.cancel();
			}
			auto list = _list;
			_list = this.outer._list.dup;
			this.outer._list = list;
			_table.setItemCount(cast(int)list.length);
			_table.clearAll();
			raiseModifyEvent();
			_comm.refreshToolBar();
		}
		override void undo() { impl(); }
		override void redo() { impl(); }
		override void dispose() { mixin(S_TRACE);
			// Nothing
		}
	}
	protected void storeAll() { mixin(S_TRACE);
		_undo ~= new UndoAll;
	}
	private void undo() { mixin(S_TRACE);
		_undo.undo();
	}
	private void redo() { mixin(S_TRACE);
		_undo.redo();
	}

	protected void mainValueEditEnd(TableItem itm, in T value) { mixin(S_TRACE);
		auto index = itm.getParent().indexOf(itm);
		if (!_startAdd && equals(_list[index], value)) return;
		scope (exit) _startAdd = null;
		scope (exit) _comm.refreshToolBar();
		auto exists = existsValue(index, value);
		if (!isValidValue(value) || exists != -1) { mixin(S_TRACE);
			// 空文字列等、データ無しに相当する値
			scope (exit) {
				if (exists != -1) {
					_table.deselectAll();
					_table.select(exists);
					_table.showSelection();
				}
			}
			if (_startAdd) { mixin(S_TRACE);
				assert (itm is _startAdd);
				delSelection(index);
				_list = std.algorithm.remove(_list, index);
				_table.setItemCount(cast(int)_list.length);
				if (index < exists) exists--;
				_table.clearAll();
				return;
			}
			if (!isValidValue(value)) { mixin(S_TRACE);
				storeAll();
				delSelection(index);
				_list = std.algorithm.remove(_list, index);
				_table.setItemCount(cast(int)_list.length);
				_table.clearAll();
			}
		} else if (_startAdd) { mixin(S_TRACE);
			// 追加
			assert (itm is _startAdd);
			delSelection(index);
			_list = std.algorithm.remove(_list, index);
			storeAll();
			_list.insertInPlace(index, value);
			static if (Sort) {
				sortValues([index]);
			} else {
				_table.clearAll();
				_table.deselectAll();
				_table.select(index);
				_table.showSelection();
			}
		} else { mixin(S_TRACE);
			// 編集
			static if (Sort) {
				storeAll();
				_list[index] = value;
				sortValues([index]);
				_table.clearAll();
			} else {
				storeSingle(index);
				_list[index] = value;
				_table.clear(index);
				_table.deselectAll();
				_table.select(index);
				_table.showSelection();
			}
		}
		raiseModifyEvent();
	}
	protected void subValueEditEnd(TableItem itm, in T value) { mixin(S_TRACE);
		auto index = itm.getParent().indexOf(itm);
		if (equals(_list[index], value)) return;
		auto exists = existsValue(index, value);
		if (exists != -1) { mixin(S_TRACE);
			_table.deselectAll();
			_table.select(exists);
			_table.showSelection();
			return;
		}
		static if (Sort) {
			storeAll();
			_list[index] = value;
			sortValues([index]);
			_table.clearAll();
		} else {
			storeSingle(index);
			_list[index] = value;
			_table.clear(index);
			_table.deselectAll();
			_table.select(index);
			_table.showSelection();
		}
		raiseModifyEvent();
		_comm.refreshToolBar();
	}
	private int existsValue(int index, in T value) { mixin(S_TRACE);
		if (_canDuplicate) return -1;
		foreach (i; 0 .. valueCount) { mixin(S_TRACE);
			if (i != index && equals(this.value(i), value)) { mixin(S_TRACE);
				_table.deselectAll();
				_table.select(cast(int)i);
				_table.showSelection();
				return cast(int)i;
			}
		}
		return -1;
	}
	private void exitEdit(bool cancel) { mixin(S_TRACE);
		if (cancel && _startAdd) { mixin(S_TRACE);
			auto index = _table.indexOf(_startAdd);
			delSelection(index);
			_list = std.algorithm.remove(_list, index);
			_table.setItemCount(cast(int)_list.length);
			_table.clearAll();
			_comm.refreshToolBar();
		}
		_startAdd = null;
	}

	private void append(in T value, int index = -1) { mixin(S_TRACE);
		foreach (e; editors) { mixin(S_TRACE);
			if (e && e.isEditing) e.enter();
		}
		if (index != -1) { mixin(S_TRACE);
			_list.insertInPlace(index, value);
			_table.setItemCount(cast(int)_list.length);
			_table.clear(index, _table.getItemCount() - 1);
		} else { mixin(S_TRACE);
			_list ~= value;
			_table.setItemCount(cast(int)_list.length);
		}
	}
	private TableItem _startAdd = null;
	private void add() { mixin(S_TRACE);
		foreach (e; editors) { mixin(S_TRACE);
			if (e && e.isEditing) e.enter();
		}
		if (maxCount <= valueCount) return;
		int index;
		bool cancel;
		auto value = createNewValue(index, cancel);
		if (cancel) return;
		append(value, index);
		index = index == -1 ? _table.getItemCount() - 1 : index;
		_table.deselectAll();
		_table.select(index);
		_table.showSelection();
		_comm.refreshToolBar();
		.forceFocus(_table, false);
		_startAdd = _table.getItem(index);
		mainEditor.startEdit();
	}
	private void del() { mixin(S_TRACE);
		foreach (e; editors) { mixin(S_TRACE);
			if (e && e.isEditing) e.enter();
		}
		delImpl(_table.getSelectionIndices());
	}
	private void delImpl(int[] indices) { mixin(S_TRACE);
		storeAll();
		bool[T] sels;
		foreach (i; indices) sels[_list[i]] = true;
		foreach_reverse (i; indices.sort()) { mixin(S_TRACE);
			_list = std.algorithm.remove(_list, i);
		}
		foreach (i, ref value; _list) { mixin(S_TRACE);
			if (value in sels) { mixin(S_TRACE);
				_table.select(cast(int)i);
			} else { mixin(S_TRACE);
				_table.deselect(cast(int)i);
			}
		}
		_table.setItemCount(cast(int)_list.length);
		_table.clearAll();
		raiseModifyEvent();
		_comm.refreshToolBar();
	}
	private void delSelection(int index) { mixin(S_TRACE);
		auto indices = _table.getSelectionIndices();
		foreach (ref i; indices) { mixin(S_TRACE);
			if (index < i) i--;
		}
		_table.setSelection(indices);
	}

	static if (Sort) {
		private void sortValues(in int[] selIndices) { mixin(S_TRACE);
			bool[T] selValues;
			foreach (i; selIndices) selValues[_list[i]] = true;
			_list.sort();
			foreach (i, ref value; _list) { mixin(S_TRACE);
				if (value in selValues) { mixin(S_TRACE);
					_table.select(cast(int)i);
				} else { mixin(S_TRACE);
					_table.deselect(cast(int)i);
				}
			}
			_table.clearAll();
			_table.showSelection();
		}
	} else {
		private void up() { mixin(S_TRACE);
			foreach (e; editors) { mixin(S_TRACE);
				if (e && e.isEditing) e.enter();
			}
			auto indices = _table.getSelectionIndices();
			std.algorithm.sort(indices);
			if (!indices.length || indices[0] <= 0) return;

			storeAll();
			foreach (index; indices) { mixin(S_TRACE);
				auto temp = _list[index - 1];
				_list[index - 1] = _list[index];
				_list[index] = temp;
			}
			_table.clearAll();
			indices = indices.map!(a => a - 1)().array();
			_table.deselectAll();
			_table.select(indices);
			_table.showSelection();
			raiseModifyEvent();
			_comm.refreshToolBar();
		}
		private void down() { mixin(S_TRACE);
			foreach (e; editors) { mixin(S_TRACE);
				if (e && e.isEditing) e.enter();
			}
			auto indices = _table.getSelectionIndices();
			std.algorithm.sort(indices);
			if (!indices.length || _table.getItemCount() <= indices[$ - 1] + 1) return;

			storeAll();
			foreach_reverse (index; indices) { mixin(S_TRACE);
				auto temp = _list[index + 1];
				_list[index + 1] = _list[index];
				_list[index] = temp;
			}
			_table.clearAll();
			indices = indices.map!(a => a + 1)().array();
			_table.deselectAll();
			_table.select(indices);
			_table.showSelection();
			raiseModifyEvent();
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
				auto p = (cast(DropTarget)e.getSource()).getControl().toControl(e.x, e.y);
				auto t = _table.getItem(p);
				int index = t ? _table.indexOf(t) : _table.getItemCount();
				auto samePane = _id == node.attr("paneId", false);
				static if (Sort) {
					if (samePane) return;
				} else {
					if (samePane && index == _dragIndex) return;
				}
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

	private bool appendFromNode(ref XNode node, int index, bool force) { mixin(S_TRACE);
		if (node.name != xmlName) return false;
		return appendValuesImpl(createFromNode(node), index, force);
	}
	protected bool appendValues(const(T)[] values) { mixin(S_TRACE);
		return appendValuesImpl(values, -1, false);
	}
	private bool appendValuesImpl(const(T)[] list, int index, bool force) { mixin(S_TRACE);
		if (!force && maxCount <= _list.length) return false;
		if (!force && !_canDuplicate) { mixin(S_TRACE);
			bool[T] eValues;
			foreach (ref value; _list) eValues[value] = true;
			const(T)[] list2;
			foreach (ref value; list) { mixin(S_TRACE);
				if (value in eValues) continue;
				if (!isValidValue(value)) continue;
				list2 ~= value;
				eValues[value] = true;
			}
			list = list2;
		}
		if (!force && maxCount < _list.length + list.length) { mixin(S_TRACE);
			list.length -= valueCount + list.length - maxCount;
		}
		if (!list.length) return false;

		foreach (e; editors) { mixin(S_TRACE);
			if (e && e.isEditing) e.enter();
		}
		storeAll();
		if (index == -1) { mixin(S_TRACE);
			index = cast(int)_list.length;
			_list ~= list;
		} else { mixin(S_TRACE);
			_list.insertInPlace(index, list);
		}
		_table.setItemCount(cast(int)_list.length);
		_table.clearAll();
		auto addIndices = .iota(index, index + cast(int)list.length).array();
		static if (Sort) {
			sortValues(addIndices);
		} else {
			_table.setSelection(addIndices);
		}
		_table.showSelection();
		raiseModifyEvent();
		_comm.refreshToolBar();
		return true;
	}
	private int _dragIndex = -1;
	private class CDragListener : DragSourceAdapter {
		private int[] _itms;
		override void dragStart(DragSourceEvent e) { mixin(S_TRACE);
			auto c = cast(Table)(cast(DragSource)e.getSource()).getControl();
			e.doit = c.isFocusControl() && c.getSelectionIndex() != -1;
		}
		override void dragSetData(DragSourceEvent e){ mixin(S_TRACE);
			if (XMLBytesTransfer.getInstance().isSupportedType(e.dataType)) { mixin(S_TRACE);
				foreach (editor; editors) { mixin(S_TRACE);
					if (editor && editor.isEditing) editor.enter();
				}
				auto c = cast(Table)(cast(DragSource)e.getSource()).getControl();
				_itms = c.getSelectionIndices();
				if (!_itms.length) return;
				_dragIndex = c.getSelectionIndex();
				if (_dragIndex == -1) return;
				auto node = toNode(_itms);
				node.newAttr("paneId", _id);
				e.data = bytesFromXML(node.text);
			}
		}
		override void dragFinished(DragSourceEvent e) { mixin(S_TRACE);
			if (!_readOnly && e.detail == DND.DROP_MOVE) { mixin(S_TRACE);
				foreach (editor; editors) { mixin(S_TRACE);
					if (editor && editor.isEditing) editor.cancel();
				}
				delImpl(_itms);
			}
			_dragIndex = -1;
			_itms = [];
		}
	}
	private class LTCPD : TCPD {
		override void cut(SelectionEvent se) { mixin(S_TRACE);
			if (canDoT) { mixin(S_TRACE);
				copy(se);
				del(se);
			}
		}
		override void copy(SelectionEvent se) { mixin(S_TRACE);
			if (canDoC) { mixin(S_TRACE);
				foreach (e; editors) { mixin(S_TRACE);
					if (e && e.isEditing) e.enter();
				}
				auto node = toNode(_table.getSelectionIndices());
				XMLtoCB(_comm.prop, _comm.clipboard, node.text);
				_comm.refreshToolBar();
			}
		}
		override void paste(SelectionEvent se) { mixin(S_TRACE);
			auto xml = CBtoXML(_comm.clipboard);
			if (xml) { mixin(S_TRACE);
				foreach (e; editors) { mixin(S_TRACE);
					if (e && e.isEditing) e.enter();
				}
				try { mixin(S_TRACE);
					auto node = XNode.parse(xml);
					appendFromNode(node, _table.getItemCount(), false);
				} catch (Exception e) {
					printStackTrace();
					debugln(e);
				}
			}
		}
		override void del(SelectionEvent se) { mixin(S_TRACE);
			this.outer.del();
		}
		override void clone(SelectionEvent se) { mixin(S_TRACE);
			assert (0);
		}
		@property
		override bool canDoTCPD() { mixin(S_TRACE);
			return true;
		}
		@property
		bool canDoT() { mixin(S_TRACE);
			return !_readOnly && _table.getSelectionIndex() != -1;
		}
		@property
		bool canDoC() { mixin(S_TRACE);
			return _table.getSelectionIndex() != -1;
		}
		@property
		bool canDoP() { mixin(S_TRACE);
			return !_readOnly && CBisXML(_comm.clipboard);
		}
		@property
		bool canDoD() { mixin(S_TRACE);
			return !_readOnly && _table.getSelectionIndex() != -1;
		}
		@property
		bool canDoClone() { mixin(S_TRACE);
			return !_readOnly && canDoC;
		}
	}

	static if (!Sort) {
		@property
		bool canUp() { mixin(S_TRACE);
			if (_readOnly || _table.getSelectionIndex() == -1) return false;
			auto indices = _table.getSelectionIndices();
			foreach (index; indices) { mixin(S_TRACE);
				if (index <= 0) return false;
			}
			return true;
		}
		@property
		bool canDown() { mixin(S_TRACE);
			if (_readOnly || _table.getSelectionIndex() == -1) return false;
			auto indices = _table.getSelectionIndices();
			foreach (index; indices) { mixin(S_TRACE);
				if (_table.getItemCount() <= index + 1) return false;
			}
			return true;
		}
	}

	@property
	bool canSelectAll() { mixin(S_TRACE);
		if (!_table || _table.isDisposed()) return false;
		return _table.getSelectionCount() != _table.getItemCount();
	}
	void selectAll() { mixin(S_TRACE);
		if (!canSelectAll) return;
		_table.selectAll();
		_comm.refreshToolBar();
	}

	private class HTBTraverse : Listener {
		override void handleEvent(Event e) { e.doit = true; }
	}
	private class HTBKeyDown : Listener {
		override void handleEvent(Event e) { e.doit = true; }
	}

	this (Commons comm, Composite parent, int style, bool canDuplicate) { mixin(S_TRACE);
		super (parent, style);

		_id = .objectIDValue(this);

		_readOnly = style & SWT.READ_ONLY;
		_canDuplicate = canDuplicate;
		_comm = comm;
		_undo = new UndoManager(_comm.prop.var.etc.undoMaxEtc);
		this.setLayout(zeroMarginGridLayout(1, true));
		if (!_readOnly) { mixin(S_TRACE);
			_toolbar = new ToolBar(this, SWT.FLAT);
			_comm.put(_toolbar);
			_toolbar.addListener(SWT.Traverse, new HTBTraverse);
			_toolbar.addListener(SWT.KeyDown, new HTBKeyDown);
			createToolItem2(_comm, _toolbar, addText, addIcon, &add, () => !_readOnly && valueCount < maxCount);
			createToolItem2(_comm, _toolbar, delText, delIcon, &del, () => !_readOnly && _table.getSelectionIndex() != -1);
			static if (!Sort) {
				new ToolItem(_toolbar, SWT.SEPARATOR);
				createToolItem(_comm, _toolbar, MenuID.Up, &up, &canUp);
				createToolItem(_comm, _toolbar, MenuID.Down, &down, &canDown);
			}
			initToolBar(_toolbar);
		}
		{ mixin(S_TRACE);
			_table = .rangeSelectableTable(this, SWT.BORDER | SWT.MULTI | SWT.FULL_SELECTION | SWT.VIRTUAL);
			_table.setLayoutData(new GridData(GridData.FILL_BOTH));

			initColumns(_table);
			.listener(_table, SWT.SetData, (e) { mixin(S_TRACE);
				updateItem(_list[e.index], cast(TableItem)e.item);
			});

			auto menu = new Menu(_table);
			if (!_readOnly) { mixin(S_TRACE);
				createMenuItem(_comm, menu, MenuID.Undo, &undo, () => !_readOnly && _undo.canUndo);
				createMenuItem(_comm, menu, MenuID.Redo, &redo, () => !_readOnly && _undo.canRedo);
				static if (!Sort) {
					new MenuItem(menu, SWT.SEPARATOR);
					createMenuItem(_comm, menu, MenuID.Up, &up, &canUp);
					createMenuItem(_comm, menu, MenuID.Down, &down, &canDown);
				}
				new MenuItem(menu, SWT.SEPARATOR);
				appendMenuTCPD(_comm, menu, new LTCPD, true, true, true, true, false);
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.SelectAll, &selectAll, &canSelectAll);
			} else { mixin(S_TRACE);
				appendMenuTCPD(_comm, menu, new LTCPD, false, true, false, false, false);
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.SelectAll, &selectAll, &canSelectAll);
			}
			initPopupMenu(menu);
			_table.setMenu(menu);
			.listener(_table, SWT.Selection, { _comm.refreshToolBar(); });
			if (!_readOnly) { mixin(S_TRACE);
				.listener(_table, SWT.MouseDoubleClick, { mixin(S_TRACE);
					if (_table.getSelectionIndex() != -1) return;
					add();
				});
			}
		}

		auto drag = new DragSource(_table, DND.DROP_MOVE | DND.DROP_COPY);
		drag.setTransfer([XMLBytesTransfer.getInstance()]);
		drag.addDragListener(new CDragListener);
		if (!_readOnly) { mixin(S_TRACE);
			auto drop = new DropTarget(_table, DND.DROP_DEFAULT | DND.DROP_MOVE | DND.DROP_COPY);
			drop.setTransfer([XMLBytesTransfer.getInstance()]);
			drop.addDropListener(new CDropListener);
		}

		if (!_readOnly) { mixin(S_TRACE);
			initEditors(_table);
			if (mainEditor) mainEditor.exitEvent ~= &exitEdit;
		}

		auto d = this.getDisplay();
		_comm.refMenu.add(&refMenu);
		_comm.refUndoMax.add(&refUndoMax);
		_kdFilter = new KeyDownFilter();
		d.addFilter(SWT.KeyDown, _kdFilter);
		.listener(this, SWT.Dispose, { mixin(S_TRACE);
			_comm.refMenu.remove(&refMenu);
			_comm.refUndoMax.remove(&refUndoMax);
			d.removeFilter(SWT.KeyDown, _kdFilter);
		});
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
					_undo.undo();
					e.doit = false;
				} else if (eqAcc(_redoAcc, e.keyCode, e.character, e.stateMask)) { mixin(S_TRACE);
					_undo.redo();
					e.doit = false;
				}
			}
		}
	}
	private int _undoAcc;
	private int _redoAcc;
	private void refMenu(MenuID id) { mixin(S_TRACE);
		if (id == MenuID.Undo) _undoAcc = convertAccelerator(_comm.prop.buildMenu(MenuID.Undo));
		if (id == MenuID.Redo) _redoAcc = convertAccelerator(_comm.prop.buildMenu(MenuID.Redo));
	}

	private void refUndoMax() { mixin(S_TRACE);
		_undo.max = _comm.prop.var.etc.undoMaxEtc;
	}

	@property
	bool isNewItemEditing() { return _startAdd !is null; }

	protected void clearAll() { _table.clearAll(); }

	@property
	T[] values() { mixin(S_TRACE);
		auto r = _list.dup;
		if (_startAdd) { mixin(S_TRACE);
			r = std.algorithm.remove(r, _table.indexOf(_startAdd));
		}
		return r;
	}
	@property
	void values(in T[] list) { mixin(S_TRACE);
		foreach (e; editors) { mixin(S_TRACE);
			if (e && e.isEditing) e.cancel();
		}
		_undo.reset();
		_list = list.dup;
		static if (Sort) {
			_list.sort();
		}
		_table.setItemCount(cast(int)_list.length);
		_table.clearAll();
	}
	@property
	const
	protected size_t valueCount() { return _list.length; }
	@property
	protected int[] selectionIndices() { return _table.getSelectionIndices(); }
	@property
	inout
	protected inout(T) value(size_t index) { return _list[index]; }
	protected void setValue(size_t index, in T value) { mixin(S_TRACE);
		_list[index] = value;
		_table.clear(cast(int)index);
	}

	@property
	protected Control table() { return _table; }
	@property
	const
	bool readOnly() { return _readOnly != 0; }
	@property
	const
	protected bool canDuplicate() { return _canDuplicate; }

	@property
	void enabled(bool e) { mixin(S_TRACE);
		_table.setEnabled(e);
		if (_toolbar) _toolbar.setEnabled(!_readOnly && e);
	}
	@property
	bool enabled() { mixin(S_TRACE);
		return _table.isEnabled();
	}

	protected T[] createFromNode(ref XNode node);
	protected XNode toNode(in int[] indices);
	@property
	const
	protected string xmlName();

	protected
	Image addIcon() { return _comm.prop.images.addItem; }
	protected
	const
	string addText() { return _comm.prop.msgs.addItem; }
	protected
	Image delIcon() { return _comm.prop.images.delItem; }
	protected
	const
	string delText() { return _comm.prop.msgs.delItem; }

	protected void initColumns(Table table);
	protected void initEditors(Table table);
	protected void initToolBar(ToolBar bar) { }
	protected void initPopupMenu(Menu menu) { }
	@property
	protected AbstractTableEdit[] editors();
	@property
	protected AbstractTableEdit mainEditor();

	protected void updateItem(in T value, TableItem itm);

	protected bool equals(in T value1, in T value2) { return value1 == value2; }
	protected bool isValidValue(in T value) { return true; }
	protected size_t maxCount() { return size_t.max; }
	protected const(T) createNewValue(out int index, out bool cancel) { mixin(S_TRACE);
		index = -1;
		cancel = false;
		return T.init;
	}
}
