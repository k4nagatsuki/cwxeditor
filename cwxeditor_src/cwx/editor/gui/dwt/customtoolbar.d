
module cwx.editor.gui.dwt.customtoolbar;

import cwx.structs;
import cwx.types;
import cwx.menu;
import cwx.utils;

import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.incsearch;
import cwx.editor.gui.dwt.xmlbytestransfer;
import cwx.editor.gui.dwt.absdialog;

import std.traits;

import org.eclipse.swt.all;

/// ツールバーのカスタマイズを行う。
class ToolBarCustomizer : Composite, TCPD {
	private Commons _comm;
	private Props _prop;
	private ToolBarSettings _tools;
	private const ToolBarSettings _init;
	private UndoManager _undo;
	private HashSet!MenuID _added;

	private Table _menuList;
	private Tree _toolTree;
	private IncSearch _menuIncSearch;

	private class CTUndo : Undo {
		private int[] _selected;
		private ToolBarSettings _oldTools;

		this () { mixin(S_TRACE);
			save();
		}
		private void save() { mixin(S_TRACE);
			_selected = [];
			auto sels = _toolTree.getSelection();
			if (sels.length) { mixin(S_TRACE);
				auto sel = sels[0];
				while (sel) { mixin(S_TRACE);
					auto index = sel.getParentItem() ? sel.getParentItem().indexOf(sel) : _toolTree.indexOf(sel);
					_selected = [index] ~ _selected;
					sel = sel.getParentItem();
				}
			}
			_oldTools = tools;
		}
		private void impl() { mixin(S_TRACE);
			auto selected = _selected;
			auto oldTools = _oldTools;
			save();
			_tools = oldTools;
			updateTree();
			if (selected.length) { mixin(S_TRACE);
				auto itm = _toolTree.getItem(selected[0]);
				selected = selected[1..$];
				while (selected.length) { mixin(S_TRACE);
					itm = itm.getItem(selected[0]);
					selected = selected[1..$];
				}
				_toolTree.setSelection([itm]);
			}
		}
		override void undo() { impl(); }
		override void redo() { impl(); }
		override void dispose() { mixin(S_TRACE);
			// 処理無し
		}
	}
	private void store() { mixin(S_TRACE);
		_undo ~= new CTUndo();
	}

	private class DropRemoveMenu : DropTargetAdapter {
		override void dragEnter(DropTargetEvent e){ mixin(S_TRACE);
			e.detail = DND.DROP_NONE;
			// TODO
		}
		override void dragOver(DropTargetEvent e){ mixin(S_TRACE);
			// TODO
		}
		override void drop(DropTargetEvent e){ mixin(S_TRACE);
			// TODO
		}
	}
	private class DragMenu : DragSourceAdapter {
		override void dragStart(DragSourceEvent e) { mixin(S_TRACE);
			e.doit = false;
			// TODO
		}
		override void dragSetData(DragSourceEvent e) { mixin(S_TRACE);
			// TODO
		}
		override void dragFinished(DragSourceEvent e) { mixin(S_TRACE);
			// TODO
		}
	}
	private class DropMenu : DropTargetAdapter {
		override void dragEnter(DropTargetEvent e){ mixin(S_TRACE);
			// TODO
		}
		override void dragOver(DropTargetEvent e){ mixin(S_TRACE);
			// TODO
		}
		override void drop(DropTargetEvent e){ mixin(S_TRACE);
			// TODO
		}
	}

	private void refUndoMax() { mixin(S_TRACE);
		_undo.max = _prop.var.etc.undoMaxEtc;
	}

	this (Commons comm, Composite parent, int style, ToolBarSettings tools, const ToolBarSettings init) { mixin(S_TRACE);
		super (parent, style);
		_comm = comm;
		_prop = comm.prop;
		_tools = tools;
		_init = init;
		_added = new HashSet!MenuID;
		_undo = new UndoManager(_prop.var.etc.undoMaxEtc);
		_comm.refUndoMax.add(&refUndoMax);
		.listener(this, SWT.Dispose, {
			_comm.refUndoMax.remove(&refUndoMax);
		});
		construct();
	}

	private void construct() { mixin(S_TRACE);
		setLayout(new FillLayout);
		auto sash = new SplitPane(this, SWT.HORIZONTAL);
		{ mixin(S_TRACE);
			auto comp = new Composite(sash, SWT.NONE);
			comp.setLayout(zeroMarginGridLayout(2, false));

			_menuList = new Table(comp, SWT.BORDER | SWT.MULTI | SWT.V_SCROLL | SWT.FULL_SELECTION);
			_menuList.setLayoutData(new GridData(GridData.FILL_BOTH));
			.listener(_menuList, SWT.Selection, &_comm.refreshToolBar);
			new FullTableColumn(_menuList, SWT.NONE);

			_menuIncSearch = new IncSearch(_comm, _menuList);
			_menuIncSearch.modEvent ~= &refreshMenu;
			auto menu = new Menu(_menuList.getShell(), SWT.POP_UP);
			createMenuItem(_comm, menu, MenuID.IncSearch, () => _menuIncSearch.startIncSearch(), null);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.Undo, { _undo.undo(); }, &_undo.canUndo);
			createMenuItem(_comm, menu, MenuID.Redo, { _undo.redo(); }, &_undo.canRedo);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.AddTool, &addMenu, &canAddMenu);
			_menuList.setMenu(menu);

			auto btnComp = new Composite(comp, SWT.NONE);
			btnComp.setLayoutData(new GridData(GridData.VERTICAL_ALIGN_CENTER));
			btnComp.setLayout(zeroMarginGridLayout(1, true));

			auto right = new Button(btnComp, SWT.PUSH);
			right.setText(_prop.msgs.menuText(MenuID.AddTool));
			right.setImage(_prop.images.menu(MenuID.AddTool));
			.listener(right, SWT.Selection, &addMenu);
			_comm.put(right, &canAddMenu);
			auto left = new Button(btnComp, SWT.PUSH);
			left.setText(_prop.msgs.menuText(MenuID.Delete));
			left.setImage(_prop.images.menu(MenuID.Delete));
			.listener(left, SWT.Selection, &removeMenu);
			_comm.put(left, &canRemoveMenu);

			auto drop = new DropTarget(_menuList, DND.DROP_DEFAULT | DND.DROP_MOVE);
			drop.setTransfer([XMLBytesTransfer.getInstance()]);
			drop.addDropListener(new DropRemoveMenu);
		}
		{ mixin(S_TRACE);
			auto comp = new Composite(sash, SWT.NONE);
			comp.setLayout(zeroMarginGridLayout(1, false));

			_toolTree = new Tree(comp, SWT.SINGLE | SWT.BORDER | SWT.VIRTUAL);
			initTree(_comm, _toolTree, false);
			_toolTree.setLayoutData(new GridData(GridData.FILL_BOTH));
			.listener(_toolTree, SWT.Selection, &_comm.refreshToolBar);

			void btn(Composite parent, string name, Image image, void delegate() dlg, bool delegate() can) { mixin(S_TRACE);
				auto btn = new Button(parent, SWT.PUSH);
				btn.setLayoutData(new GridData(GridData.FILL_BOTH));
				btn.setText(name);
				btn.setImage(image);
				.listener(btn, SWT.Selection, dlg);
				_comm.put(btn, can);
			}
			auto btnComp = new Composite(comp, SWT.NONE);
			btnComp.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
			btnComp.setLayout(zeroMarginGridLayout(3, false));
			auto aComp = new Composite(btnComp, SWT.NONE);
			aComp.setLayout(zeroMarginGridLayout(2, true));
			btn(aComp, _prop.msgs.menuText(MenuID.AddToolBar), null, &addBar, null);
			btn(aComp, _prop.msgs.menuText(MenuID.AddToolGroup), null, &addGroup, null);
			btn(btnComp, _prop.msgs.menuText(MenuID.Up), _prop.images.menu(MenuID.Up), &up, &canUp);
			btn(btnComp, _prop.msgs.menuText(MenuID.Down), _prop.images.menu(MenuID.Down), &down, &canDown);

			auto menu = new Menu(_toolTree.getShell(), SWT.POP_UP);
			createMenuItem(_comm, menu, MenuID.Undo, { _undo.undo(); }, &_undo.canUndo);
			createMenuItem(_comm, menu, MenuID.Redo, { _undo.redo(); }, &_undo.canRedo);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.Up, &up, &canUp);
			createMenuItem(_comm, menu, MenuID.Down, &down, &canDown);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.AddToolBar, &addBar, null);
			createMenuItem(_comm, menu, MenuID.AddToolGroup, &addGroup, null);
			new MenuItem(menu, SWT.SEPARATOR);
			appendMenuTCPD(_comm, menu, this, false, false, false, true, false);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.ResetToolBarSettings, &resetTools, () => tools != _init);
			_toolTree.setMenu(menu);

			auto drag = new DragSource(_toolTree, DND.DROP_MOVE);
			drag.setTransfer([XMLBytesTransfer.getInstance()]);
			drag.addDragListener(new DragMenu);
			auto drop = new DropTarget(_toolTree, DND.DROP_DEFAULT | DND.DROP_MOVE);
			drop.setTransfer([XMLBytesTransfer.getInstance()]);
			drop.addDropListener(new DropMenu);
		}
		sash.setWeights([_prop.var.etc.mainToolBarCustomSashL, _prop.var.etc.mainToolBarCustomSashR]);
		.listener(sash, SWT.Dispose, { mixin(S_TRACE);
			auto ws = sash.getWeights();
			_prop.var.etc.mainToolBarCustomSashL = ws[0];
			_prop.var.etc.mainToolBarCustomSashR = ws[1];
		});

		updateTree();
		refreshMenu();
	}
	private void updateBarAndGroupText() { mixin(S_TRACE);
		foreach (i, bar; _toolTree.getItems()) { mixin(S_TRACE);
			bar.setText(.tryFormat(_prop.msgs.toolBarName, i + 1));
			foreach (gi, group; bar.getItems()) { mixin(S_TRACE);
				group.setText(.tryFormat(_prop.msgs.toolGroupName, gi + 1));
			}
		}
	}
	private void updateTree() { mixin(S_TRACE);
		_toolTree.setRedraw(false);
		scope (exit) _toolTree.setRedraw(true);
		_toolTree.removeAll();
		_added.clear();
		foreach (i, bar; _tools.tools) { mixin(S_TRACE);
			auto barItm = new TreeItem(_toolTree, SWT.NONE);
			barItm.setText(.tryFormat(_prop.msgs.toolBarName, i + 1));
			barItm.setImage(_prop.images.toolBar);
			size_t gi = 0;
			auto groupItm = new TreeItem(barItm, SWT.NONE);
			groupItm.setText(.tryFormat(_prop.msgs.toolGroupName, gi + 1));
			groupItm.setImage(_prop.images.toolGroup);
			foreach (tool; bar) { mixin(S_TRACE);
				if (tool.separator) { mixin(S_TRACE);
					gi++;
					groupItm.setExpanded(true);
					groupItm = new TreeItem(barItm, SWT.NONE);
					groupItm.setText(.tryFormat(_prop.msgs.toolGroupName, gi + 1));
					groupItm.setImage(_prop.images.toolGroup);
				} else { mixin(S_TRACE);
					auto toolItm = new TreeItem(groupItm, SWT.NONE);
					toolItm.setText(_prop.var.menu.buildTool(_prop.parent, tool.menu));
					auto data = new MenuData;
					data.id = tool.menu;
					toolItm.setData(data);
					_added.add(tool.menu);
					toolItm.setImage(_prop.images.menu(tool.menu));
				}
			}
			groupItm.setExpanded(true);
			barItm.setExpanded(true);
		}
		if (_toolTree.getItemCount()) _toolTree.setSelection([_toolTree.getItem(0)]);
		_comm.refreshToolBar();
	}
	private void refreshMenu() { mixin(S_TRACE);
		_menuList.setRedraw(false);
		scope (exit) _menuList.setRedraw(true);
		auto selID = MenuID.None;
		int selIndex = _menuList.getSelectionIndex();
		if (-1 != selIndex) { mixin(S_TRACE);
			selID = (cast(MenuData)_menuList.getItem(selIndex).getData()).id;
		}
		_menuList.removeAll();
		foreach (id; EnumMembers!MenuID) { mixin(S_TRACE);
			if (id == MenuID.None) continue;
			if (!isMainToolBarMenu(id)) continue;
			if (_added.contains(id)) continue;
			auto image = _prop.images.menu(id);
			if (!image) continue;
			string name = _prop.var.menu.buildTool(_prop.parent, id);
			if (!_menuIncSearch.match(name)) continue;
			auto itm = new TableItem(_menuList, SWT.NONE);
			itm.setText(name);
			itm.setImage(image);
			auto data = new MenuData();
			data.id = id;
			itm.setData(data);
			if (id == selID) { mixin(S_TRACE);
				_menuList.select(_menuList.getItemCount() - 1);
			}
		}
		if (-1 == _menuList.getSelectionIndex()) _menuList.select(0);
		_menuList.showSelection();
		_comm.refreshToolBar();
	}

	@property
	private bool canUp() { mixin(S_TRACE);
		auto sels = _toolTree.getSelection();
		if (!sels.length) return false;
		auto sel = sels[0];
		auto parItm = sel.getParentItem();
		if (parItm) { mixin(S_TRACE);
			return 0 < parItm.indexOf(sel);
		} else { mixin(S_TRACE);
			return 0 < _toolTree.indexOf(sel);
		}
	}
	@property
	private bool canDown() { mixin(S_TRACE);
		auto sels = _toolTree.getSelection();
		if (!sels.length) return false;
		auto sel = sels[0];
		auto parItm = sel.getParentItem();
		if (parItm) { mixin(S_TRACE);
			return parItm.indexOf(sel) + 1 < parItm.getItemCount();
		} else { mixin(S_TRACE);
			return _toolTree.indexOf(sel) + 1 < _toolTree.getItemCount();
		}
	}
	private void up() { mixin(S_TRACE);
		if (!canUp) return;
		auto sels = _toolTree.getSelection();
		if (!sels.length) return;
		store();
		_toolTree.setRedraw(false);
		scope (exit) _toolTree.setRedraw(true);
		treeItemUp(sels[0]);
		updateBarAndGroupText();
		_comm.refreshToolBar();
	}
	private void down() { mixin(S_TRACE);
		if (!canDown) return;
		auto sels = _toolTree.getSelection();
		if (!sels.length) return;
		store();
		_toolTree.setRedraw(false);
		scope (exit) _toolTree.setRedraw(true);
		treeItemDown(sels[0]);
		updateBarAndGroupText();
		_comm.refreshToolBar();
	}
	private void addBar() { mixin(S_TRACE);
		auto sels = _toolTree.getSelection();
		if (!sels.length) return;
		store();
		_toolTree.setRedraw(false);
		scope (exit) _toolTree.setRedraw(true);
		auto top = topItem(sels[0]);
		auto index = _toolTree.indexOf(top) + 1;
		auto itm = new TreeItem(_toolTree, SWT.NONE, index);
		itm.setImage(_prop.images.toolBar);
		updateBarAndGroupText();
		_toolTree.setSelection([itm]);
		_comm.refreshToolBar();
	}
	private void addGroup() { mixin(S_TRACE);
		auto sels = _toolTree.getSelection();
		if (!sels.length) return;
		store();
		_toolTree.setRedraw(false);
		scope (exit) _toolTree.setRedraw(true);
		auto sel = sels[0];
		auto parItm = sel.getParentItem();
		TreeItem itm;
		if (!parItm) { mixin(S_TRACE);
			itm = new TreeItem(sel, SWT.NONE, 0);
		} else { mixin(S_TRACE);
			auto parParItm = parItm.getParentItem();
			if (parParItm) { mixin(S_TRACE);
				auto index = parParItm.indexOf(parItm) + 1;
				itm = new TreeItem(parParItm, SWT.NONE, index);
			} else { mixin(S_TRACE);
				auto index = parItm.indexOf(sel) + 1;
				itm = new TreeItem(parItm, SWT.NONE, index);
			}
		}
		itm.getParentItem().setExpanded(true);
		itm.setImage(_prop.images.toolGroup);
		updateBarAndGroupText();
		_toolTree.setSelection([itm]);
		_comm.refreshToolBar();
	}
	@property
	private bool canAddMenu() { mixin(S_TRACE);
		return _menuList.getSelectionIndex() != -1;
	}
	@property
	private bool canRemoveMenu() { mixin(S_TRACE);
		auto sels = _toolTree.getSelection();
		return sels.length != 0;
	}
	private void addMenu() { mixin(S_TRACE);
		if (!canAddMenu) return;
		auto sels = _toolTree.getSelection();
		if (!sels.length) return;
		_menuList.setRedraw(false);
		scope (exit) _menuList.setRedraw(true);
		_toolTree.setRedraw(false);
		scope (exit) _toolTree.setRedraw(true);
		store();
		auto sel = sels[0];
		auto parItm = sel.getParentItem();
		void add(TreeItem parItm, int index) { mixin(S_TRACE);
			foreach (mItm; _menuList.getSelection()) { mixin(S_TRACE);
				auto itm = new TreeItem(parItm, SWT.NONE, index);
				auto m = cast(MenuData)mItm.getData();
				_added.add(m.id);
				itm.setText(_prop.var.menu.buildTool(_prop.parent, m.id));
				itm.setImage(_prop.images.menu(m.id));
				itm.setData(m);
				mItm.dispose();
				index++;
			}
			parItm.setExpanded(true);
		}
		if (!parItm) { mixin(S_TRACE);
			if (!sel.getItemCount()) { mixin(S_TRACE);
				addGroup();
			}
			add(sel.getItem(0), 0);
		} else { mixin(S_TRACE);
			auto parParItm = parItm.getParentItem();
			if (parParItm) { mixin(S_TRACE);
				auto index = parItm.indexOf(sel) + 1;
				add(parItm, index);
			} else { mixin(S_TRACE);
				add(sel, 0);
			}
		}
		_comm.refreshToolBar();
	}
	private void removeMenu() { mixin(S_TRACE);
		if (!canRemoveMenu) return;
		store();
		_toolTree.setRedraw(false);
		scope (exit) _toolTree.setRedraw(true);
		void recurse(TreeItem itm) { mixin(S_TRACE);
			if (auto m = cast(MenuData)itm.getData()) { mixin(S_TRACE);
				_added.remove(m.id);
			}
			foreach (sub; itm.getItems()) recurse(sub);
		}
		foreach (itm; _toolTree.getItems()) { mixin(S_TRACE);
			recurse(itm);
		}
		_toolTree.getSelection()[0].dispose();
		refreshMenu();
		_comm.refreshToolBar();
	}
	private void resetTools() { mixin(S_TRACE);
		store();
		_tools = _init.dup;
		updateTree();
	}

	override void cut(SelectionEvent se) { mixin(S_TRACE);
		// TODO
	}
	override void copy(SelectionEvent se) { mixin(S_TRACE);
		// TODO
	}
	override void paste(SelectionEvent se) { mixin(S_TRACE);
		// TODO
	}
	override void del(SelectionEvent se) { mixin(S_TRACE);
		removeMenu();
	}
	override void clone(SelectionEvent se) { mixin(S_TRACE);
		// 処理無し
	}
	@property
	override bool canDoTCPD() { mixin(S_TRACE);
		return _toolTree.isFocusControl();
	}
	@property
	override bool canDoT() { mixin(S_TRACE);
		return _toolTree.getSelection().length != 0;
	}
	@property
	override bool canDoC() { mixin(S_TRACE);
		return _toolTree.getSelection().length != 0;
	}
	@property
	override bool canDoP() { mixin(S_TRACE);
		return CBisXML(_comm.clipboard);
	}
	@property
	override bool canDoD() { mixin(S_TRACE);
		return _toolTree.getSelection().length != 0;
	}
	@property
	override bool canDoClone() { mixin(S_TRACE);
		return false;
	}

	@property
	ToolBarSettings tools() { mixin(S_TRACE);
		ToolBarSettings tools;
		foreach (barItm; _toolTree.getItems()) { mixin(S_TRACE);
			Tool[] bar;
			foreach (i, groupItm; barItm.getItems()) {
				if (0 < i) bar ~= Tool();
				foreach (itm; groupItm.getItems()) {
					bar ~= Tool((cast(MenuData)itm.getData()).id);
				}
			}
			tools.tools ~= bar;
		}
		return tools;
	}
}

class ToolBarCustomDialog : AbsDialog {
	private Commons _comm;
	private ToolBarCustomizer _cTools;
	private ToolBarSettings _tools;
	private const ToolBarSettings _init;

	this (Commons comm, Shell shell, ToolBarSettings tools, const ToolBarSettings init) { mixin(S_TRACE);
		_comm = comm;
		_tools = tools;
		_init = init;
		auto prop = comm.prop;
		auto size = comm.prop.var.toolBarCustomDlg;
		super (prop, shell, false, prop.msgs.dlgTitCustomizeToolBar, prop.images.menu(MenuID.CustomizeToolBar), true, size, true, true);
	}

	@property
	ToolBarSettings tools() { return _tools; }

	protected override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(windowGridLayout(1, true));
		_cTools = new ToolBarCustomizer(_comm, area, SWT.NONE, _tools, _init);
		_cTools.setLayoutData(new GridData(GridData.FILL_BOTH));
	}

	protected override bool apply() { mixin(S_TRACE);
		_tools = _cTools.tools;
		return true;
	}
}
