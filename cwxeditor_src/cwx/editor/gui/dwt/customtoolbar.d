
module cwx.editor.gui.dwt.customtoolbar;

import cwx.structs;
import cwx.types;
import cwx.menu;
import cwx.utils;
import cwx.xml;

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

import std.conv;
import std.traits;

import org.eclipse.swt.all;

/// ツールバーのカスタマイズを行う。
class ToolBarCustomizer : Composite, TCPD {
	void delegate()[] modEvent;

	private Commons _comm;
	private Props _prop;
	private ToolBarSettings _tools;
	private const ToolBarSettings _init;
	private UndoManager _undo;
	private HashSet!MenuID _added;

	private Table _menuList;
	private Tree _toolTree;
	private TreeItem _dragItm;
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
			refreshMenu();
			foreach (dlg; modEvent) dlg();
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

	private class MenuListTCPD : TCPD {
		override void cut(SelectionEvent se) { mixin(S_TRACE);
			// 処理無し
		}
		override void copy(SelectionEvent se) { mixin(S_TRACE);
			auto sels = _menuList.getSelection();
			if (sels.length) { mixin(S_TRACE);
				auto node = XNode.create("tools");
				foreach (itm; sels) { mixin(S_TRACE);
					auto m = cast(MenuData)itm.getData();
					node.newElement("tool", .to!string(m.id));
				}
				XMLtoCB(_prop, _comm.clipboard, node.text);
				_comm.refreshToolBar();
			}
		}
		override void paste(SelectionEvent se) { mixin(S_TRACE);
			// 処理無し
		}
		override void del(SelectionEvent se) { mixin(S_TRACE);
			// 処理無し
		}
		override void clone(SelectionEvent se) { mixin(S_TRACE);
			// 処理無し
		}
		@property
		override bool canDoTCPD() { mixin(S_TRACE);
			return _menuList.isFocusControl();
		}
		@property
		override bool canDoT() { mixin(S_TRACE);
			return false;
		}
		@property
		override bool canDoC() { mixin(S_TRACE);
			return _menuList.getSelectionCount() != 0;
		}
		@property
		override bool canDoP() { mixin(S_TRACE);
			return false;
		}
		@property
		override bool canDoD() { mixin(S_TRACE);
			return false;
		}
		@property
		override bool canDoClone() { mixin(S_TRACE);
			return false;
		}
	}

	private class DragMenuList : DragSourceAdapter {
		override void dragStart(DragSourceEvent e) { mixin(S_TRACE);
			e.doit = 0 < _menuList.getSelectionCount();
		}
		override void dragSetData(DragSourceEvent e) { mixin(S_TRACE);
			if (XMLBytesTransfer.getInstance().isSupportedType(e.dataType)) { mixin(S_TRACE);
				auto node = XNode.create("tools");
				foreach (itm; _menuList.getSelection()) { mixin(S_TRACE);
					auto m = cast(MenuData)itm.getData();
					node.newElement("tool", .to!string(m.id));
				}
				e.data = bytesFromXML(node.text);
			}
		}
		override void dragFinished(DragSourceEvent e) { mixin(S_TRACE);
			// Nothing
		}
	}
	private class DropRemoveMenu : DropTargetAdapter {
		private void move(DropTargetEvent e) { mixin(S_TRACE);
			e.detail = (e.item !is null && cast(TableItem)e.item) ? DND.DROP_MOVE : DND.DROP_NONE;
		}
		override void dragEnter(DropTargetEvent e){ mixin(S_TRACE);
			move(e);
		}
		override void dragOver(DropTargetEvent e){ mixin(S_TRACE);
			move(e);
		}
		override void drop(DropTargetEvent e){ mixin(S_TRACE);
			if (!isXMLBytes(e.data)) return;
			string xml = bytesToXML(e.data);
			e.detail = DND.DROP_NONE;
			try { mixin(S_TRACE);
				auto node = XNode.parse(xml);
				switch (node.name) {
				case "toolBar":
				case "toolGroup":
				case "tool":
					e.detail = DND.DROP_MOVE;
					break;
				default:
					break;
				}
			} catch (Exception e) { mixin (S_TRACE);
				printStackTrace();
				debugln(e);
			}
		}
	}
	private class DragMenu : DragSourceAdapter {
		override void dragStart(DragSourceEvent e) { mixin(S_TRACE);
			auto sels = _toolTree.getSelection();
			e.doit = 0 < sels.length;
			if (e.doit) _dragItm = sels[0];
		}
		override void dragSetData(DragSourceEvent e) { mixin(S_TRACE);
			if (XMLBytesTransfer.getInstance().isSupportedType(e.dataType)) { mixin(S_TRACE);
				assert (_dragItm !is null);
				e.data = bytesFromXML(toNode(_dragItm).text);
			}
		}
		override void dragFinished(DragSourceEvent e) { mixin(S_TRACE);
			if (e.detail == DND.DROP_MOVE) { mixin(S_TRACE);
				store();
				removeMenuImpl(_dragItm);
				updateBarAndGroupText();
				refreshMenu();
				_toolTree.showSelection();
				_comm.refreshToolBar();
				foreach (dlg; modEvent) dlg();
			}
			_dragItm = null;
		}
	}
	private class DropMenu : DropTargetAdapter {
		private void move(DropTargetEvent e) { mixin(S_TRACE);
			e.detail = (e.item !is null && cast(TreeItem)e.item) ? DND.DROP_MOVE : DND.DROP_NONE;
		}
		override void dragEnter(DropTargetEvent e){ mixin(S_TRACE);
			move(e);
		}
		override void dragOver(DropTargetEvent e){ mixin(S_TRACE);
			move(e);
		}
		override void drop(DropTargetEvent e){ mixin(S_TRACE);
			if (!isXMLBytes(e.data)) return;
			string xml = bytesToXML(e.data);
			e.detail = DND.DROP_NONE;
			try { mixin(S_TRACE);
				auto itm = cast(TreeItem)e.item;
				assert (itm !is null);
				auto node = XNode.parse(xml);
				if (_dragItm) { mixin(S_TRACE);
					_toolTree.setRedraw(false);
					scope (exit) _toolTree.setRedraw(true);
					_menuList.setRedraw(false);
					scope (exit) _menuList.setRedraw(true);
					store();
					removeMenuImpl(_dragItm);
					fromNode(node, itm, false);
					_dragItm = null;
				} else {
					fromNode(node, itm, true);
					e.detail = DND.DROP_MOVE;
				}
			} catch (Exception e) { mixin (S_TRACE);
				printStackTrace();
				debugln(e);
			}
		}
	}
	private XNode toNode(TreeItem itm) { mixin(S_TRACE);
		auto parItm = itm.getParentItem();
		if (!parItm) { mixin(S_TRACE);
			// バー
			auto bNode = XNode.create("toolBar");
			foreach (gItm; itm.getItems()) { mixin(S_TRACE);
				auto gNode = bNode.newElement("toolGroup");
				foreach (mItm; gItm.getItems()) { mixin(S_TRACE);
					auto m = cast(MenuData)mItm.getData();
					gNode.newElement("tool", .to!string(m.id));
				}
			}
			return bNode;
		} else if (auto parParItm = parItm.getParentItem()) { mixin(S_TRACE);
			// ツール
			auto m = cast(MenuData)itm.getData();
			return XNode.create("tool", .to!string(m.id));
		} else { mixin(S_TRACE);
			// グループ
			auto gNode = XNode.create("toolGroup");
			foreach (mItm; itm.getItems()) { mixin(S_TRACE);
				auto m = cast(MenuData)mItm.getData();
				gNode.newElement("tool", .to!string(m.id));
			}
			return gNode;
		}
	}
	private void fromNode(ref XNode node, TreeItem sel, bool storeBeforePaste) { mixin(S_TRACE);
		TreeItem itm = null;
		_toolTree.setRedraw(false);
		scope (exit) _toolTree.setRedraw(true);
		if (node.name == "toolBar") { mixin(S_TRACE);
			if (storeBeforePaste) store();
			itm = addBarImpl(sel);
			auto bItm = itm;
			node.onTag["toolGroup"] = (ref XNode node) { mixin(S_TRACE);
				itm = addGroupImpl(bItm);
				auto gItm = itm;
				MenuID[] itms;
				node.onTag["tool"] = (ref XNode node) { mixin(S_TRACE);
					itms ~= node.valueTo!MenuID;
				};
				node.parse();
				itm = addMenuImpl(gItm, itms);
			};
			node.parse();
		} else if (node.name == "toolGroup") { mixin(S_TRACE);
			if (!sel) return;
			if (storeBeforePaste) store();
			itm = addGroupImpl(sel);
			auto gItm = itm;
			MenuID[] itms;
			node.onTag["tool"] = (ref XNode node) { mixin(S_TRACE);
				itms ~= node.valueTo!MenuID();
			};
			node.parse();
			itm = addMenuImpl(gItm, itms);
		} else if (node.name == "tool") { mixin(S_TRACE);
			if (!sel) return;
			auto itms = [node.valueTo!MenuID()];
			if (!canAppendMenu(itms[0])) return;
			if (storeBeforePaste) store();
			itm = addMenuImpl(sel, itms);
		} else if (node.name == "tools") { mixin(S_TRACE);
			if (!sel) return;
			MenuID[] itms;
			node.onTag["tool"] = (ref XNode node) { mixin(S_TRACE);
				auto m = node.valueTo!MenuID();
				if (!canAppendMenu(m)) return;
				itms ~= m;
			};
			node.parse();
			if (!itms.length) return;
			if (storeBeforePaste) store();
			itm = addMenuImpl(sel, itms);
		}
		if (itm) { mixin(S_TRACE);
			updateBarAndGroupText();
			refreshMenu();
			_toolTree.setSelection([itm]);
			_toolTree.showSelection();
			_comm.refreshToolBar();
			foreach (dlg; modEvent) dlg();
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
			new MenuItem(menu, SWT.SEPARATOR);
			appendMenuTCPD(_comm, menu, new MenuListTCPD, false, true, false, false, false);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.SelectAll, { mixin(S_TRACE);
				_menuList.setSelection(_menuList.getItems());
			}, () => _menuList.getItemCount() != _menuList.getSelectionCount());
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

			auto drag = new DragSource(_menuList, DND.DROP_MOVE);
			drag.setTransfer([XMLBytesTransfer.getInstance()]);
			drag.addDragListener(new DragMenuList);
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
			btn(btnComp, _prop.msgs.upSelection, _prop.images.menu(MenuID.Up), &up, &canUp);
			btn(btnComp, _prop.msgs.downSelection, _prop.images.menu(MenuID.Down), &down, &canDown);

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
			appendMenuTCPD(_comm, menu, this, true, true, true, true, false);
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
					toolItm.setText(_prop.msgs.menuText(tool.menu));
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
			if (!canAppendMenu(id)) continue;
			auto image = _prop.images.menu(id);
			if (!image) continue;
			string name = _prop.msgs.menuText(id);
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
		foreach (dlg; modEvent) dlg();
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
		foreach (dlg; modEvent) dlg();
	}
	private void addBar() { mixin(S_TRACE);
		auto sels = _toolTree.getSelection();
		store();
		_toolTree.setRedraw(false);
		scope (exit) _toolTree.setRedraw(true);
		auto itm = addBarImpl(sels.length ? sels[0] : null);
		updateBarAndGroupText();
		_toolTree.setSelection([itm]);
		_toolTree.showSelection();
		_comm.refreshToolBar();
		foreach (dlg; modEvent) dlg();
	}
	private TreeItem addBarImpl(TreeItem sel) { mixin(S_TRACE);
		int index;
		if (sel) { mixin(S_TRACE);
			auto top = topItem(sel);
			index = _toolTree.indexOf(top);
		} else { mixin(S_TRACE);
			index = _toolTree.getItemCount();
		}
		auto itm = new TreeItem(_toolTree, SWT.NONE, index);
		itm.setImage(_prop.images.toolBar);
		return itm;
	}
	private void addGroup() { mixin(S_TRACE);
		auto sels = _toolTree.getSelection();
		if (!sels.length) return;
		store();
		_toolTree.setRedraw(false);
		scope (exit) _toolTree.setRedraw(true);
		auto itm = addGroupImpl(sels[0]);
		updateBarAndGroupText();
		_toolTree.setSelection([itm]);
		_toolTree.showSelection();
		_comm.refreshToolBar();
		foreach (dlg; modEvent) dlg();
	}
	private TreeItem addGroupImpl(TreeItem sel) { mixin(S_TRACE);
		auto parItm = sel.getParentItem();
		TreeItem itm;
		if (!parItm) { mixin(S_TRACE);
			itm = new TreeItem(sel, SWT.NONE, sel.getItemCount());
		} else { mixin(S_TRACE);
			auto parParItm = parItm.getParentItem();
			if (parParItm) { mixin(S_TRACE);
				auto index = parParItm.getItemCount();
				itm = new TreeItem(parParItm, SWT.NONE, index);
			} else { mixin(S_TRACE);
				auto index = parItm.indexOf(sel);
				itm = new TreeItem(parItm, SWT.NONE, index);
			}
		}
		itm.getParentItem().setExpanded(true);
		itm.setImage(_prop.images.toolGroup);
		return itm;
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
		auto itm = addMenuImpl(sels[0], _menuList.getSelection());
		if (itm) _toolTree.setSelection([itm]);
		_toolTree.showSelection();
		_comm.refreshToolBar();
		foreach (dlg; modEvent) dlg();
	}
	private TreeItem addMenuImpl(T)(TreeItem sel, T[] itms) { mixin(S_TRACE);
		auto parItm = sel.getParentItem();
		TreeItem add(TreeItem parItm, int index) { mixin(S_TRACE);
			TreeItem itm = null;
			foreach (mItm; itms) { mixin(S_TRACE);
				itm = new TreeItem(parItm, SWT.NONE, index);
				static if (is(T:TableItem)) {
					auto m = cast(MenuData)mItm.getData();
					mItm.dispose();
				} else {
					auto m = new MenuData;
					m.id = mItm;
				}
				if (!canAppendMenu(m.id)) continue;
				_added.add(m.id);
				itm.setText(_prop.msgs.menuText(m.id));
				itm.setImage(_prop.images.menu(m.id));
				itm.setData(m);
				index++;
			}
			parItm.setExpanded(true);
			return itm;
		}
		if (!parItm) { mixin(S_TRACE);
			if (!sel.getItemCount()) { mixin(S_TRACE);
				addGroupImpl(sel);
			}
			return add(sel.getItem(0), 0);
		} else { mixin(S_TRACE);
			auto parParItm = parItm.getParentItem();
			if (parParItm) { mixin(S_TRACE);
				auto index = parItm.indexOf(sel);
				return add(parItm, index);
			} else { mixin(S_TRACE);
				return add(sel, sel.getItemCount());
			}
		}
	}
	private bool canAppendMenu(MenuID id) {
		if (id == MenuID.None) return false;
		if (!isMainToolBarMenu(id)) return false;
		if (_added.contains(id)) return false;
		return true;
	}
	private void removeMenu() { mixin(S_TRACE);
		if (!canRemoveMenu) return;
		auto sels = _toolTree.getSelection();
		if (!sels.length) return;
		_toolTree.setRedraw(false);
		scope (exit) _toolTree.setRedraw(true);
		store();
		removeMenuImpl(sels[0]);
		refreshMenu();
		_comm.refreshToolBar();
		foreach (dlg; modEvent) dlg();
	}
	private void removeMenuImpl(TreeItem sel) { mixin(S_TRACE);
		void recurse(TreeItem itm) { mixin(S_TRACE);
			if (auto m = cast(MenuData)itm.getData()) { mixin(S_TRACE);
				_added.remove(m.id);
			}
			foreach (sub; itm.getItems()) recurse(sub);
		}
		recurse(sel);
		sel.dispose();
	}
	private void resetTools() { mixin(S_TRACE);
		if (_tools != _init) { mixin(S_TRACE);
			store();
			_tools = _init.dup;
			updateTree();
			foreach (dlg; modEvent) dlg();
		}
	}

	override void cut(SelectionEvent se) { mixin(S_TRACE);
		_toolTree.setRedraw(false);
		scope (exit) _toolTree.setRedraw(true);
		_menuList.setRedraw(false);
		scope (exit) _menuList.setRedraw(true);
		copy(se);
		del(se);
	}
	override void copy(SelectionEvent se) { mixin(S_TRACE);
		auto sels = _toolTree.getSelection();
		if (sels.length) { mixin(S_TRACE);
			XMLtoCB(_prop, _comm.clipboard, toNode(sels[0]).text);
			_comm.refreshToolBar();
		}
	}
	override void paste(SelectionEvent se) { mixin(S_TRACE);
		auto c = CBtoXML(_comm.clipboard);
		if (c) { mixin(S_TRACE);
			try { mixin(S_TRACE);
				auto node = XNode.parse(c);
				auto sels = _toolTree.getSelection();
				fromNode(node, sels.length ? sels[0] : null, true);
			} catch (Exception e) { mixin (S_TRACE);
				printStackTrace();
				debugln(e);
			}
		}
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
		mod(_cTools);
		_cTools.setLayoutData(new GridData(GridData.FILL_BOTH));
	}

	protected override bool apply() { mixin(S_TRACE);
		_tools = _cTools.tools;
		return true;
	}
}
