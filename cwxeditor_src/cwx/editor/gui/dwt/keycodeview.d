
module cwx.editor.gui.dwt.keycodeview;

import cwx.summary;
import cwx.xml;
import cwx.menu;
import cwx.types;
import cwx.utils;
import cwx.card;
import cwx.system;

import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.xmlbytestransfer;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.chooser;

import std.algorithm;
import std.array;
import std.conv;
import std.datetime;
import std.string;

import org.eclipse.swt.all;

import java.lang.all;

public:

/// カードが持つキーコードのビュー。
class KeyCodeView : Composite {
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

	private UndoManager _undo;

	private Table _keyCodes;
	private ToolBar _toolbar = null;
	private TableTextEdit _tte;

	private bool delegate() _catchMod;

	class UndoName : Undo {
		private int _index;
		private string _oldName;
		private string _newName;
		this (int index, string oldName, string newName) { mixin(S_TRACE);
			_index = index;
			_oldName = oldName;
			_newName = newName;
		}
		private void impl() { mixin(S_TRACE);
			if (_tte.isEditing) _tte.cancel();
			_keyCodes.getItem(_index).setText(_oldName);
			auto temp = _oldName;
			_oldName = _newName;
			_newName = temp;
			raiseModifyEvent();
			_comm.refreshToolBar();
		}
		void undo() { impl(); }
		void redo() { impl(); }
		void dispose() { }
	}
	void storeSingle(int index, string oldName, string newName) { mixin(S_TRACE);
		_undo ~= new UndoName(index, oldName, newName);
	}
	private class UndoKeyCodes : Undo {
		private string[] _keyCodes;
		this () { mixin(S_TRACE);
			save();
		}
		private void save() { mixin(S_TRACE);
			_keyCodes = this.outer._keyCodes.getItems().map!(itm => itm.getText())().array();
		}
		private void impl() { mixin(S_TRACE);
			if (_tte.isEditing) _tte.cancel();
			auto keyCodes = _keyCodes;
			save();
			this.outer._keyCodes.setRedraw(false);
			scope (exit) this.outer._keyCodes.setRedraw(true);

			auto n = this.outer._keyCodes.getItemCount();
			this.outer._keyCodes.setItemCount(cast(int)keyCodes.length);
			foreach (i, keyCode; keyCodes) { mixin(S_TRACE);
				auto itm = this.outer._keyCodes.getItem(cast(int)i);
				itm.setText(keyCode);
				itm.setImage(_prop.images.keyCode);
			}
			raiseModifyEvent();
			_comm.refreshToolBar();
		}
		override void undo() { impl(); }
		override void redo() { impl(); }
		override void dispose() { mixin(S_TRACE);
			// Nothing
		}
	}
	private void storeKeyCodes() { mixin(S_TRACE);
		_undo ~= new UndoKeyCodes;
	}
	private void undo() { mixin(S_TRACE);
		_undo.undo();
	}
	private void redo() { mixin(S_TRACE);
		_undo.redo();
	}

	private Control createEditor(TableItem itm, int editC) { mixin(S_TRACE);
		auto combo = createKeyCodeCombo!Combo(_comm, _summ, _keyCodes, _catchMod, itm.getText());
		combo.setText(itm.getText());
		return combo;
	}
	private void editEnd(TableItem itm, int column, string newText) { mixin(S_TRACE);
		auto oldText = itm.getText();
		if (newText == oldText) return;
		storeSingle(_keyCodes.indexOf(itm), oldText, newText);
		itm.setText(newText);
		raiseModifyEvent();
		_comm.refreshToolBar();
	}

	private TableItem append(string keyCode, int index = -1) { mixin(S_TRACE);
		if (_tte.isEditing) _tte.enter();
		TableItem itm;
		if (index != -1) { mixin(S_TRACE);
			itm = new TableItem(_keyCodes, SWT.NONE, index);
		} else { mixin(S_TRACE);
			itm = new TableItem(_keyCodes, SWT.NONE);
		}
		itm.setImage(_prop.images.keyCode);
		itm.setText(keyCode);
		return itm;
	}
	private void add() { mixin(S_TRACE);
		if (_tte.isEditing) _tte.enter();
		storeKeyCodes();
		auto itm = append("", -1);
		_keyCodes.deselectAll();
		_keyCodes.setSelection([itm]);
		_keyCodes.showSelection();
		raiseModifyEvent();
		_comm.refreshToolBar();
		.forceFocus(_keyCodes, false);
		_tte.startEdit();
	}
	private void del() { mixin(S_TRACE);
		if (_tte.isEditing) _tte.enter();
		storeKeyCodes();
		_keyCodes.remove(_keyCodes.getSelectionIndices());
		raiseModifyEvent();
		_comm.refreshToolBar();
	}
	private void swap(int index1, int index2) { mixin(S_TRACE);
		auto itm1 = _keyCodes.getItem(index1);
		auto itm2 = _keyCodes.getItem(index2);
		auto text1 = itm1.getText();
		itm1.setText(itm2.getText());
		itm2.setText(text1);
	}
	private void up() { mixin(S_TRACE);
		if (_tte.isEditing) _tte.enter();
		auto indices = _keyCodes.getSelectionIndices();
		std.algorithm.sort(indices);
		if (!indices.length || indices[0] <= 0) return;

		storeKeyCodes();
		foreach (index; indices) { mixin(S_TRACE);
			swap(index, index - 1);
		}
		indices = indices.map!(a => a - 1)().array();
		_keyCodes.deselectAll();
		_keyCodes.select(indices);
		raiseModifyEvent();
		_comm.refreshToolBar();
	}
	private void down() { mixin(S_TRACE);
		if (_tte.isEditing) _tte.enter();
		auto indices = _keyCodes.getSelectionIndices();
		std.algorithm.sort(indices);
		if (!indices.length || _keyCodes.getItemCount() <= indices[$ - 1] + 1) return;

		storeKeyCodes();
		foreach_reverse (index; indices) { mixin(S_TRACE);
			swap(index, index + 1);
		}
		indices = indices.map!(a => a + 1)().array();
		_keyCodes.deselectAll();
		_keyCodes.select(indices);
		raiseModifyEvent();
		_comm.refreshToolBar();
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
				auto t = _keyCodes.getItem(p);
				int index = t ? _keyCodes.indexOf(t) : _keyCodes.getItemCount();
				auto samePane = _id == node.attr("paneId", false);
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
	bool appendFromNode(ref XNode node, int index, bool force) { mixin(S_TRACE);
		if (node.name != KEY_CODES_XML_NAME) return false;
		if (!force && _summ.legacy && _prop.looks.keyCodesMaxLegacy <= _keyCodes.getItemCount()) return false;
		auto ver = new XMLInfo(_prop.sys, LATEST_VERSION);
		auto keyCodes = keyCodesFromNode(node, ver);
		if (!keyCodes.length) return false;
		if (_tte.isEditing) _tte.enter();
		storeKeyCodes();
		TableItem[] itms = [];
		foreach (keyCode; keyCodes) { mixin(S_TRACE);
			if (!force && _summ.legacy && _prop.looks.keyCodesMaxLegacy <= _keyCodes.getItemCount()) break;
			itms ~= append(keyCode, index);
			index++;
		}
		_keyCodes.deselectAll();
		_keyCodes.setSelection(itms);
		_keyCodes.showSelection();
		raiseModifyEvent();
		_comm.refreshToolBar();
		return true;
	}
	private class CDragListener : DragSourceAdapter {
		private TableItem[] _itms;
		override void dragStart(DragSourceEvent e) { mixin(S_TRACE);
			auto c = cast(Table)(cast(DragSource)e.getSource()).getControl();
			e.doit = c.isFocusControl() && c.getSelectionIndex() != -1;
		}
		override void dragSetData(DragSourceEvent e){ mixin(S_TRACE);
			if (XMLBytesTransfer.getInstance().isSupportedType(e.dataType)) { mixin(S_TRACE);
				if (_tte.isEditing) _tte.enter();
				auto c = cast(Table)(cast(DragSource)e.getSource()).getControl();
				_itms = c.getSelection();
				auto keyCodes = _itms.map!(itm => itm.getText())().array();
				auto node = keyCodesToNode(keyCodes);
				node.newAttr("paneId", _id);
				e.data = bytesFromXML(node.text);
			}
		}
		override void dragFinished(DragSourceEvent e) { mixin(S_TRACE);
			if (!_readOnly && e.detail == DND.DROP_MOVE) { mixin(S_TRACE);
				if (_tte.isEditing) _tte.enter();
				_keyCodes.setRedraw(false);
				scope (exit) _keyCodes.setRedraw(true);
				foreach_reverse (itm; _itms) itm.dispose();
				raiseModifyEvent();
				_comm.refreshToolBar();
			}
		}
	}
	private class KeyCodeTCPD : TCPD {
		override void cut(SelectionEvent se) { mixin(S_TRACE);
			if (canDoT) { mixin(S_TRACE);
				copy(se);
				del(se);
			}
		}
		override void copy(SelectionEvent se) { mixin(S_TRACE);
			if (canDoC) { mixin(S_TRACE);
				if (_tte.isEditing) _tte.enter();
				auto keyCodes = _keyCodes.getSelection().map!(itm => itm.getText())().array();
				XMLtoCB(_prop, _comm.clipboard, keyCodesToXML(keyCodes));
				_comm.refreshToolBar();
			}
		}
		override void paste(SelectionEvent se) { mixin(S_TRACE);
			auto xml = CBtoXML(_comm.clipboard);
			if (xml) { mixin(S_TRACE);
				if (_tte.isEditing) _tte.enter();
				try { mixin(S_TRACE);
					auto node = XNode.parse(xml);
					appendFromNode(node, _keyCodes.getItemCount(), false);
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
			return !_readOnly && _keyCodes.getSelectionIndex() != -1;
		}
		@property
		bool canDoC() { mixin(S_TRACE);
			return _keyCodes.getSelectionIndex() != -1;
		}
		@property
		bool canDoP() { mixin(S_TRACE);
			return !_readOnly && CBisXML(_comm.clipboard) && (!_summ.legacy || _keyCodes.getItemCount() < _prop.looks.keyCodesMaxLegacy);
		}
		@property
		bool canDoD() { mixin(S_TRACE);
			return !_readOnly && _keyCodes.getSelectionIndex() != -1;
		}
		@property
		bool canDoClone() { mixin(S_TRACE);
			return !_readOnly && canDoC;
		}
	}

	@property
	bool canUp() { mixin(S_TRACE);
		if (_readOnly || _keyCodes.getSelectionIndex() == -1) return false;
		auto indices = _keyCodes.getSelectionIndices();
		foreach (index; indices) { mixin(S_TRACE);
			if (index <= 0) return false;
		}
		return true;
	}
	@property
	bool canDown() { mixin(S_TRACE);
		if (_readOnly || _keyCodes.getSelectionIndex() == -1) return false;
		auto indices = _keyCodes.getSelectionIndices();
		foreach (index; indices) { mixin(S_TRACE);
			if (_keyCodes.getItemCount() <= index + 1) return false;
		}
		return true;
	}

	private class HTBTraverse : Listener {
		override void handleEvent(Event e) { e.doit = true; }
	}
	private class HTBKeyDown : Listener {
		override void handleEvent(Event e) { e.doit = true; }
	}

	this (Commons comm, Summary summ, Composite parent, int style, bool delegate() catchMod) { mixin(S_TRACE);
		super (parent, style);

		auto o = this;
		_id = format("%08X", &o) ~ "-" ~ to!(string)(Clock.currTime());

		_readOnly = style & SWT.READ_ONLY;
		_comm = comm;
		_summ = summ;
		_prop = comm.prop;
		_catchMod = catchMod;
		_undo = new UndoManager(_prop.var.etc.undoMaxEtc);
		this.setLayout(zeroMarginGridLayout(1, true));
		if (!_readOnly) { mixin(S_TRACE);
			_toolbar = new ToolBar(this, SWT.FLAT);
			_comm.put(_toolbar);
			_toolbar.addListener(SWT.Traverse, new HTBTraverse);
			_toolbar.addListener(SWT.KeyDown, new HTBKeyDown);
			createToolItem2(_comm, _toolbar, _prop.msgs.addCoupon, _prop.images.addKeyCode, &add, () => !_readOnly && (_keyCodes.getItemCount() < _prop.looks.keyCodesMaxLegacy || !_summ || !_summ.legacy));
			createToolItem2(_comm, _toolbar, _prop.msgs.delCoupon, _prop.images.delKeyCode, &del, () => !_readOnly && _keyCodes.getSelectionIndex() != -1);
			new ToolItem(_toolbar, SWT.SEPARATOR);
			createToolItem(_comm, _toolbar, MenuID.Up, &up, &canUp);
			createToolItem(_comm, _toolbar, MenuID.Down, &down, &canDown);
		}
		{ mixin(S_TRACE);
			_keyCodes = new Table(this, SWT.BORDER | SWT.MULTI | SWT.FULL_SELECTION);
			_keyCodes.setLayoutData(new GridData(GridData.FILL_BOTH));
			new FullTableColumn(_keyCodes, SWT.NONE);
			auto menu = new Menu(_keyCodes);
			if (!_readOnly) { mixin(S_TRACE);
				createMenuItem(_comm, menu, MenuID.Undo, &undo, () => !_readOnly && _undo.canUndo);
				createMenuItem(_comm, menu, MenuID.Redo, &redo, () => !_readOnly && _undo.canRedo);
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.Up, &up, &canUp);
				createMenuItem(_comm, menu, MenuID.Down, &down, &canDown);
				new MenuItem(menu, SWT.SEPARATOR);
				appendMenuTCPD(_comm, menu, new KeyCodeTCPD, true, true, true, true, false);
			} else { mixin(S_TRACE);
				appendMenuTCPD(_comm, menu, new KeyCodeTCPD, false, true, false, false, false);
			}
			_keyCodes.setMenu(menu);
			.listener(_keyCodes, SWT.Selection, { _comm.refreshToolBar(); });
		}

		auto drag = new DragSource(_keyCodes, DND.DROP_MOVE | DND.DROP_COPY);
		drag.setTransfer([XMLBytesTransfer.getInstance()]);
		drag.addDragListener(new CDragListener);
		if (!_readOnly) { mixin(S_TRACE);
			auto drop = new DropTarget(_keyCodes, DND.DROP_DEFAULT | DND.DROP_MOVE | DND.DROP_COPY);
			drop.setTransfer([XMLBytesTransfer.getInstance()]);
			drop.addDropListener(new CDropListener);
		}

		_tte = new TableTextEdit(_comm, _prop, _keyCodes, 0, &editEnd, (itm, column) => true, &createEditor);

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
			auto c = cast(Control)e.widget;
			if (!c || c.getShell() !is getShell()) return;
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
		if (id == MenuID.Undo) _undoAcc = convertAccelerator(_prop.buildMenu(MenuID.Undo));
		if (id == MenuID.Redo) _redoAcc = convertAccelerator(_prop.buildMenu(MenuID.Redo));
	}

	private void refUndoMax() { mixin(S_TRACE);
		_undo.max = _prop.var.etc.undoMaxEtc;
	}

	@property
	string[] keyCodes() { mixin(S_TRACE);
		string[] r;
		r.length = _keyCodes.getItemCount();
		size_t count = 0;
		foreach (i, itm; _keyCodes.getItems()) { mixin(S_TRACE);
			r[i] = itm.getText();
			if (r[i] != "") count = i + 1;
		}
		r.length = count;
		return r;
	}
	@property
	void keyCodes(in string[] keyCodes) { mixin(S_TRACE);
		_undo.reset();
		foreach (c; keyCodes) { mixin(S_TRACE);
			append(c, -1);
		}
	}

	@property
	void enabled(bool e) { mixin(S_TRACE);
		_keyCodes.setEnabled(e);
		if (_toolbar) _toolbar.setEnabled(!_readOnly && e);
	}
	@property
	bool enabled() { mixin(S_TRACE);
		return _keyCodes.isEnabled();
	}

	@property
	string[] warnings() { mixin(S_TRACE);
		string[] ws;
		if (_summ && _summ.legacy && _prop.looks.keyCodesMaxLegacy < keyCodes.length) { mixin(S_TRACE);
			ws ~= .tryFormat(_prop.msgs.warningKeyCodeCount, _prop.looks.keyCodesMaxLegacy);
		}
		return ws;
	}
}
