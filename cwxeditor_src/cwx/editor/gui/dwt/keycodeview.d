
module cwx.editor.gui.dwt.keycodeview;

import cwx.summary;
import cwx.xml;
import cwx.menu;
import cwx.types;
import cwx.utils;
import cwx.card;
import cwx.system;
import cwx.warning;

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
import std.traits;

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
	private bool _canDuplicate = true;
	private bool _withIgnitionType = false;

	private Commons _comm;
	private Props _prop;
	private Summary _summ;
	private KeyDownFilter _kdFilter;

	private UndoManager _undo;

	private Table _keyCodes;
	private ToolBar _toolbar = null;
	private TableTextEdit _tte = null;
	private TableComboEdit!Combo _tce = null;

	private bool delegate() _catchMod;

	void setKeyCode(int index, string name) { mixin(S_TRACE);
		auto itm = _keyCodes.getItem(index);
		assert (itm !is null);
		setKeyCode(itm, name);
	}
	void setKeyCode(TableItem itm, string name) { mixin(S_TRACE);
		itm.setText(name);
		auto image = _prop.images.keyCode;
		if (_withIgnitionType) { mixin(S_TRACE);
			auto fkc = _prop.sys.toFKeyCode(name);
			itm.setText(1, name == "" ? "" : _prop.msgs.keyCodeTiming(fkc.kind));
			if (!_prop.targetVersion(_summ, "1.50") && fkc.kind is FKCKind.HasNot) { mixin(S_TRACE);
				image = _prop.images.warning;
			} else { mixin(S_TRACE);
				image = _prop.images.keyCodeTiming(fkc.kind);
			}
		}

		if (!_canDuplicate && _keyCodes.getItem(0) is itm && name == "MatchingType=All") { mixin(S_TRACE);
			image = _prop.images.warning;
		} else if (_canDuplicate && _prop.sys.isRunaway([name])) { mixin(S_TRACE);
			image = _prop.images.warning;
		} else if (.sjisWarnings(_prop.parent, _summ, name, "").length) { mixin(S_TRACE);
			image = _prop.images.warning;
		}
		itm.setImage(image);
	}
	void refDataVersion() { mixin(S_TRACE);
		foreach (itm; _keyCodes.getItems()) { mixin(S_TRACE);
			setKeyCode(itm, itm.getText());
		}
	}

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
			if (_tte && _tte.isEditing) _tte.cancel();
			if (_tce && _tce.isEditing) _tce.cancel();
			setKeyCode(_index, _oldName);
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
			_keyCodes = this.outer.getKeyCodes(false);
		}
		private void impl() { mixin(S_TRACE);
			if (_tte && _tte.isEditing) _tte.cancel();
			if (_tce && _tce.isEditing) _tce.cancel();
			auto keyCodes = _keyCodes;
			save();
			this.outer._keyCodes.setRedraw(false);
			scope (exit) this.outer._keyCodes.setRedraw(true);

			auto n = this.outer._keyCodes.getItemCount();
			this.outer._keyCodes.setItemCount(cast(int)keyCodes.length);
			foreach (i, keyCode; keyCodes) { mixin(S_TRACE);
				setKeyCode(cast(int)i, keyCode);
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

	private void refreshWarning() { mixin(S_TRACE);
		foreach (itm; _keyCodes.getItems()) { mixin(S_TRACE);
			// 警告アイコンの更新
			if (itm.getText() == "MatchingType=All") setKeyCode(itm, itm.getText());
		}
	}

	private Control createEditor(TableItem itm, int editC) { mixin(S_TRACE);
		auto combo = createKeyCodeCombo!Combo(_comm, _summ, _keyCodes, _catchMod, itm.getText());
		combo.setText(itm.getText());
		return combo;
	}
	private void editEnd(TableItem itm, int column, string newText) { mixin(S_TRACE);
		auto oldText = itm.getText();
		if (newText == oldText && !_startAdd) return;
		scope (exit) _startAdd = null;
		if (!_canDuplicate && (_withIgnitionType ? _prop.sys.toFKeyCode(newText).keyCode : newText) == "") { mixin(S_TRACE);
			// 空白名を許さない場合は、空文字列入力で削除を行う
			if (!_startAdd) storeKeyCodes();
			itm.dispose();
			if (_startAdd) return;
		} else { mixin(S_TRACE);
			if (existsKeyCode(itm, newText)) { mixin(S_TRACE);
				_startAdd = null;
				return;
			}
			if (_startAdd) { mixin(S_TRACE);
				storeKeyCodes();
				_startAdd = null;
			} else { mixin(S_TRACE);
				storeSingle(_keyCodes.indexOf(itm), oldText, newText);
			}
			setKeyCode(itm, newText);
		}
		_startAdd = null;
		raiseModifyEvent();
		_comm.refreshToolBar();
	}
	private void exitEdit(bool cancel) { mixin(S_TRACE);
		if (cancel && _startAdd) { mixin(S_TRACE);
			_startAdd.dispose();
			_comm.refreshToolBar();
		}
		_startAdd = null;
	}

	private FKCKind[] _ignitionTypeTable;
	void ignitionTypeCombo(TableItem itm, int column, out string[] strs, out string str) { mixin(S_TRACE);
		_ignitionTypeTable = [];
		foreach (i, kind; EnumMembers!FKCKind) { mixin(S_TRACE);
			_ignitionTypeTable ~= kind;
			auto v = _prop.msgs.keyCodeTiming(kind);
			strs ~= v;
			if (kind is _prop.sys.fireKeyCodeKind(itm.getText())) { mixin(S_TRACE);
				str = v;
			}
		}
	}
	void ignitionTypeEditEnd(TableItem selItm, int column, Combo combo) { mixin(S_TRACE);
		int i = combo.getSelectionIndex();
		if (-1 == i) return;
		assert (i < _ignitionTypeTable.length);
		auto oldText = selItm.getText();
		auto kind = _ignitionTypeTable[i];
		auto newText = _prop.sys.convFireKeyCode(oldText, kind);
		if (oldText == newText) return;
		if (existsKeyCode(selItm, newText)) return;
		foreach (itm2; _keyCodes.getItems()) { mixin(S_TRACE);
			if (itm2 !is selItm && itm2.getText() == newText) { mixin(S_TRACE);
				_keyCodes.deselectAll();
				_keyCodes.setSelection([itm2]);
				_keyCodes.showSelection();
				return;
			}
		}
		storeSingle(_keyCodes.indexOf(selItm), oldText, newText);
		setKeyCode(selItm, newText);
		raiseModifyEvent();
		_comm.refreshToolBar();
	}
	private bool existsKeyCode(TableItem itm, string keyCode) { mixin(S_TRACE);
		if (_canDuplicate) return false;
		foreach (itm2; _keyCodes.getItems()) { mixin(S_TRACE);
			if (itm2 !is itm && itm2.getText() == keyCode) { mixin(S_TRACE);
				_keyCodes.deselectAll();
				_keyCodes.setSelection([itm2]);
				if (_startAdd) _startAdd.dispose();
				_keyCodes.showSelection();
				return true;
			}
		}
		return false;
	}

	private TableItem append(string keyCode, int index = -1) { mixin(S_TRACE);
		if (_tte && _tte.isEditing) _tte.enter();
		if (_tce && _tce.isEditing) _tce.enter();
		TableItem itm;
		if (index != -1) { mixin(S_TRACE);
			itm = new TableItem(_keyCodes, SWT.NONE, index);
		} else { mixin(S_TRACE);
			itm = new TableItem(_keyCodes, SWT.NONE);
		}
		setKeyCode(itm, keyCode);
		return itm;
	}
	private TableItem _startAdd = null;
	private void add() { mixin(S_TRACE);
		if (_tte && _tte.isEditing) _tte.enter();
		if (_tce && _tce.isEditing) _tce.enter();
		auto itm = append("", -1);
		_keyCodes.deselectAll();
		_keyCodes.setSelection([itm]);
		_keyCodes.showSelection();
		_comm.refreshToolBar();
		.forceFocus(_keyCodes, false);
		_startAdd = itm;
		_tte.startEdit();
	}
	private void del() { mixin(S_TRACE);
		if (_tte && _tte.isEditing) _tte.enter();
		if (_tce && _tce.isEditing) _tce.enter();
		storeKeyCodes();
		_keyCodes.remove(_keyCodes.getSelectionIndices());
		refreshWarning();
		raiseModifyEvent();
		_comm.refreshToolBar();
	}
	private void up() { mixin(S_TRACE);
		if (_tte && _tte.isEditing) _tte.enter();
		if (_tce && _tce.isEditing) _tce.enter();
		auto indices = _keyCodes.getSelectionIndices();
		std.algorithm.sort(indices);
		if (!indices.length || indices[0] <= 0) return;

		storeKeyCodes();
		foreach (index; indices) { mixin(S_TRACE);
			_keyCodes.upItem(index);
		}
		indices = indices.map!(a => a - 1)().array();
		_keyCodes.deselectAll();
		_keyCodes.select(indices);
		_keyCodes.showSelection();
		refreshWarning();
		_keyCodes.redraw();
		raiseModifyEvent();
		_comm.refreshToolBar();
	}
	private void down() { mixin(S_TRACE);
		if (_tte && _tte.isEditing) _tte.enter();
		if (_tce && _tce.isEditing) _tce.enter();
		auto indices = _keyCodes.getSelectionIndices();
		std.algorithm.sort(indices);
		if (!indices.length || _keyCodes.getItemCount() <= indices[$ - 1] + 1) return;

		storeKeyCodes();
		foreach_reverse (index; indices) { mixin(S_TRACE);
			_keyCodes.downItem(index);
		}
		indices = indices.map!(a => a + 1)().array();
		_keyCodes.deselectAll();
		_keyCodes.select(indices);
		_keyCodes.showSelection();
		refreshWarning();
		_keyCodes.redraw();
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
	bool appendFromNode(ref XNode node, int index, bool force) { mixin(S_TRACE);
		if (node.name != KEY_CODES_XML_NAME) return false;
		if (!force && _summ && _summ.legacy && _prop.looks.keyCodesMaxLegacy <= _keyCodes.getItemCount()) return false;
		auto ver = new XMLInfo(_prop.sys, LATEST_VERSION);
		auto keyCodes = keyCodesFromNode(node, ver);
		if (!keyCodes.length) return false;

		string[] keyCodes2;
		if (_canDuplicate || force) { mixin(S_TRACE);
			keyCodes2 = keyCodes;
		} else { mixin(S_TRACE);
			bool[string] eKeyCodes;
			foreach (keyCode; this.keyCodes) eKeyCodes[keyCode] = true;
			foreach (keyCode; keyCodes) { mixin(S_TRACE);
				if (keyCode in eKeyCodes) continue;
				if (_withIgnitionType) { mixin(S_TRACE);
					if (_prop.sys.toFKeyCode(keyCode).keyCode == "") continue;
				} else { mixin(S_TRACE);
					if (keyCode == "") continue;
				}
				keyCodes2 ~= keyCode;
			}
			if (!keyCodes2.length) return false;
		}

		_keyCodes.setRedraw(false);
		scope (exit) _keyCodes.setRedraw(true);
		if (_tte && _tte.isEditing) _tte.enter();
		if (_tce && _tce.isEditing) _tce.enter();
		storeKeyCodes();
		TableItem[] itms = [];
		foreach (keyCode; keyCodes2) { mixin(S_TRACE);
			if (!force && _summ && _summ.legacy && _prop.looks.keyCodesMaxLegacy <= _keyCodes.getItemCount()) break;
			itms ~= append(keyCode, index);
			index++;
		}
		_keyCodes.deselectAll();
		_keyCodes.setSelection(itms);
		_keyCodes.showSelection();
		refreshWarning();
		raiseModifyEvent();
		_comm.refreshToolBar();
		return true;
	}
	private int _dragIndex = -1;
	private class CDragListener : DragSourceAdapter {
		private TableItem[] _itms;
		override void dragStart(DragSourceEvent e) { mixin(S_TRACE);
			auto c = cast(Table)(cast(DragSource)e.getSource()).getControl();
			e.doit = c.isFocusControl() && c.getSelectionIndex() != -1;
		}
		override void dragSetData(DragSourceEvent e){ mixin(S_TRACE);
			if (XMLBytesTransfer.getInstance().isSupportedType(e.dataType)) { mixin(S_TRACE);
				if (_tte && _tte.isEditing) _tte.enter();
				if (_tce && _tce.isEditing) _tce.enter();
				auto c = cast(Table)(cast(DragSource)e.getSource()).getControl();
				_itms = c.getSelection();
				if (!_itms.length) return;
				_dragIndex = c.getSelectionIndex();
				if (_dragIndex == -1) return;
				auto keyCodes = _itms.map!(itm => itm.getText())().array();
				auto node = keyCodesToNode(keyCodes);
				node.newAttr("paneId", _id);
				e.data = bytesFromXML(node.text);
			}
		}
		override void dragFinished(DragSourceEvent e) { mixin(S_TRACE);
			if (!_readOnly && e.detail == DND.DROP_MOVE) { mixin(S_TRACE);
				if (_tte && _tte.isEditing) _tte.enter();
				if (_tce && _tce.isEditing) _tce.enter();
				_keyCodes.setRedraw(false);
				scope (exit) _keyCodes.setRedraw(true);
				foreach_reverse (itm; _itms) itm.dispose();
				refreshWarning();
				raiseModifyEvent();
				_comm.refreshToolBar();
			}
			_dragIndex = -1;
			_itms = [];
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
				if (_tte && _tte.isEditing) _tte.enter();
				if (_tce && _tce.isEditing) _tce.enter();
				auto keyCodes = _keyCodes.getSelection().map!(itm => itm.getText())().array();
				XMLtoCB(_prop, _comm.clipboard, keyCodesToXML(keyCodes));
				_comm.refreshToolBar();
			}
		}
		override void paste(SelectionEvent se) { mixin(S_TRACE);
			auto xml = CBtoXML(_comm.clipboard);
			if (xml) { mixin(S_TRACE);
				if (_tte && _tte.isEditing) _tte.enter();
				if (_tce && _tce.isEditing) _tce.enter();
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
			return !_readOnly && CBisXML(_comm.clipboard) && (!_summ || !_summ.legacy || _keyCodes.getItemCount() < _prop.looks.keyCodesMaxLegacy);
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

	this (Commons comm, Summary summ, Composite parent, int style, bool canDuplicate, bool withIgnitionType, bool delegate() catchMod) { mixin(S_TRACE);
		super (parent, style);

		_id = .objectIDValue(this);

		_readOnly = style & SWT.READ_ONLY;
		_comm = comm;
		_summ = summ;
		_prop = comm.prop;
		_canDuplicate = canDuplicate;
		_withIgnitionType = withIgnitionType;
		_catchMod = catchMod;
		_undo = new UndoManager(_prop.var.etc.undoMaxEtc);
		this.setLayout(zeroMarginGridLayout(1, true));
		if (!_readOnly) { mixin(S_TRACE);
			_toolbar = new ToolBar(this, SWT.FLAT);
			_comm.put(_toolbar);
			_toolbar.addListener(SWT.Traverse, new HTBTraverse);
			_toolbar.addListener(SWT.KeyDown, new HTBKeyDown);
			createToolItem2(_comm, _toolbar, _prop.msgs.addKeyCode, _prop.images.addKeyCode, &add, () => !_readOnly && (_keyCodes.getItemCount() < _prop.looks.keyCodesMaxLegacy || !_summ || !_summ.legacy));
			createToolItem2(_comm, _toolbar, _prop.msgs.delKeyCode, _prop.images.delKeyCode, &del, () => !_readOnly && _keyCodes.getSelectionIndex() != -1);
			new ToolItem(_toolbar, SWT.SEPARATOR);
			createToolItem(_comm, _toolbar, MenuID.Up, &up, &canUp);
			createToolItem(_comm, _toolbar, MenuID.Down, &down, &canDown);
		}
		{ mixin(S_TRACE);
			_keyCodes = .rangeSelectableTable(this, SWT.BORDER | SWT.MULTI | SWT.FULL_SELECTION);
			_keyCodes.setLayoutData(new GridData(GridData.FILL_BOTH));

			new FullTableColumn(_keyCodes, SWT.NONE);
			if (_withIgnitionType) { mixin(S_TRACE);
				auto col = new TableColumn(_keyCodes, SWT.NONE);
				auto gc = new GC(_keyCodes);
				scope (exit) gc.dispose();
				auto w = 0;
				auto t = "";
				foreach (kind; EnumMembers!FKCKind) { mixin(S_TRACE);
					auto t2 = _prop.msgs.keyCodeTiming(kind);
					auto w2 = gc.wTextExtent(t2).x;
					if (w < w2) { mixin(S_TRACE);
						w = w2;
						t = t2;
					}
				}
				auto itm = new TableItem(_keyCodes, SWT.NONE);
				itm.setText(1, t);
				col.pack();
				itm.dispose();
			}

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
			if (!_readOnly) { mixin(S_TRACE);
				.listener(_keyCodes, SWT.MouseDoubleClick, { mixin(S_TRACE);
					if (_keyCodes.getSelectionIndex() != -1) return;
					add();
				});
			}
		}

		auto drag = new DragSource(_keyCodes, DND.DROP_MOVE | DND.DROP_COPY);
		drag.setTransfer([XMLBytesTransfer.getInstance()]);
		drag.addDragListener(new CDragListener);
		if (!_readOnly) { mixin(S_TRACE);
			auto drop = new DropTarget(_keyCodes, DND.DROP_DEFAULT | DND.DROP_MOVE | DND.DROP_COPY);
			drop.setTransfer([XMLBytesTransfer.getInstance()]);
			drop.addDropListener(new CDropListener);
		}

		if (!_readOnly) { mixin(S_TRACE);
			_tte = new TableTextEdit(_comm, _prop, _keyCodes, 0, &editEnd, (itm, column) => true, &createEditor);
			_tte.exitEvent ~= &exitEdit;
			if (_withIgnitionType) { mixin(S_TRACE);
				_tce = new TableComboEdit!Combo(_comm, _prop, _keyCodes, 1, &ignitionTypeCombo, &ignitionTypeEditEnd, null);
			}
		}

		auto d = this.getDisplay();
		_comm.refMenu.add(&refMenu);
		_comm.refUndoMax.add(&refUndoMax);
		_comm.refDataVersion.add(&refDataVersion);
		_kdFilter = new KeyDownFilter();
		d.addFilter(SWT.KeyDown, _kdFilter);
		.listener(this, SWT.Dispose, { mixin(S_TRACE);
			_comm.refMenu.remove(&refMenu);
			_comm.refUndoMax.remove(&refUndoMax);
			_comm.refDataVersion.remove(&refDataVersion);
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
		if (id == MenuID.Undo) _undoAcc = convertAccelerator(_prop.buildMenu(MenuID.Undo));
		if (id == MenuID.Redo) _redoAcc = convertAccelerator(_prop.buildMenu(MenuID.Redo));
	}

	private void refUndoMax() { mixin(S_TRACE);
		_undo.max = _prop.var.etc.undoMaxEtc;
	}

	@property
	bool isNewItemEditing() { return _startAdd !is null; }

	@property
	string[] keyCodes() { mixin(S_TRACE);
		return getKeyCodes(true);
	}
	private string[] getKeyCodes(bool strip) { mixin(S_TRACE);
		string[] r;
		if (_canDuplicate) { mixin(S_TRACE);
			size_t count = 0;
			foreach (itm; _keyCodes.getItems()) { mixin(S_TRACE);
				if (_startAdd is itm) continue;
				r ~= itm.getText();
				if (r[$ - 1] != "") count = r.length;
			}
			if (strip) r.length = count;
		} else { mixin(S_TRACE);
			foreach (i, itm; _keyCodes.getItems()) { mixin(S_TRACE);
				if (_startAdd is itm) continue;
				auto keyCode = itm.getText();
				if (keyCode != "") r ~= keyCode;
			}
		}
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
		foreach (keyCode; keyCodes) { mixin(S_TRACE);
			ws ~= .sjisWarnings(_prop.parent, _summ, keyCode, _prop.msgs.keyCode);
			if (_withIgnitionType && !_prop.targetVersion(_summ, "1.50")) { mixin(S_TRACE);
				if (_prop.sys.fireKeyCodeKind(keyCode) is FKCKind.HasNot) { mixin(S_TRACE);
					ws ~= _prop.msgs.warningHasNotKeyCode;
					break;
				}
			}
		}
		if (!_canDuplicate) { mixin(S_TRACE);
			foreach (keyCode; keyCodes) { mixin(S_TRACE);
				if (keyCode == "MatchingType=All") { mixin(S_TRACE);
					ws ~= _prop.msgs.searchErrorKeyCodeMatchingAll;
				}
				break;
			}
		}
		if (_canDuplicate && _prop.sys.isRunaway(keyCodes)) { mixin(S_TRACE);
			ws ~= .tryFormat(_prop.msgs.warningRunawayCard, _prop.sys.runaway);
		}
		if (_summ && _summ.legacy && _prop.looks.keyCodesMaxLegacy < keyCodes.length) { mixin(S_TRACE);
			ws ~= .tryFormat(_prop.msgs.warningKeyCodeCount, _prop.looks.keyCodesMaxLegacy);
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
}
