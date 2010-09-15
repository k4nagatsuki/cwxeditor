
module cwx.editor.gui.dwt.dockingfolder;

import dwt.all;

import cwx.utils;
import cwx.xml;

import std.file;
import std.compat;
import std.string;

alias DockingFolder!(TabFolder, DWT.NONE) DockingFolderT;
alias DockingFolder!(CTabFolder, DWT.BORDER | DWT.FLAT) DockingFolderCT;
alias DockingFolder!(CTabFolder, DWT.BORDER | DWT.FLAT | DWT.CLOSE) DockingFolderCTC;

class DockingFolder(TabF, int Style) {
	static if (is(TabF == TabFolder)) {
		alias TabItem Tab;
	} else static if (is(TabF == CTabFolder)) {
		alias CTabItem Tab;
	} else static assert (0);
	private static const CLOSE = is(TabF == CTabFolder) && (Style & DWT.CLOSE);
	private enum DPos {
		N, E, S, W, C, NONE
	}
	private Composite _area;
	private string[Control] _ctrls;
	private Control[string] _keys;
	private this (Composite parent, int style, bool createTabf) {
		_area = new Composite(parent, style);
		_area.setLayout = new FillLayout;
		if (createTabf) newTabf(_area);
	}
	this (Composite parent, int style) {
		this (parent, style, true);
	}
	Composite parentFromKey(string key) {
		auto p = key in _keys;
		return p ? p.getParent : null;
	}
	Control control(string key) {
		auto p = key in _keys;
		return p ? *p : null;
	}
	private Tab tab(string key) {
		auto p = key in _keys;
		if (!p) return null;
		foreach (tab; (cast(TabF) p.getParent).getItems) {
			if (tab.getControl is *p) {
				return tab;
			}
		}
		assert (0);
	}
	bool tabText(string key, string text) {
		auto t = tab(key);
		if (t) {
			t.setText = text;
			return true;
		}
		return false;
	}
	string tabText(string key) {
		auto t = tab(key);
		return t ? t.getText : null;
	}
	Composite first() {return composites[0];}
	Composite area() {return _area;}
	private TabF newTabf(Composite parent) {
		auto tabf = new TabF(parent, Style);
		_tabfs ~= tabf;

		static if (CLOSE) {
			tabf.addCTabFolderListener(new CTFL);
		}
		tabf.addPaintListener(new PLT);
		auto drag = new DragSource(tabf, DND.DROP_MOVE);
		drag.setTransfer = [TextTransfer.getInstance];
		drag.addDragListener(new DSL(tabf));
		auto drop = new DropTarget(tabf, DND.DROP_MOVE);
		drop.setTransfer = [TextTransfer.getInstance];
		drop.addDropListener(new DTL(tabf));

		return tabf;
	}
	private Tab _dragItm = null;
	private DPos _dropPos = DPos.NONE;
	private DPos _drawPos = DPos.NONE;
	private TabF _drawTabf = null;
	private class CTFL :  CTabFolderListener {
		void itemClosed(CTabFolderEvent e) {
			auto tabf = cast(TabF) e.widget;
			if (tabf.getItemCount == 1 && area.getChildren[0] !is tabf) {
				tabf.dispose;
				_tabfs = .remove!("a is b")(_tabfs, tabf);
				reconstruct;
				area.layout(true);
			}
		}
	}
	/// Controlツリーの再構築。
	private void reconstruct() {
		void tree(Control ctrl) {
			auto comp = cast(SashForm) ctrl;
			if (!comp) return;
			Control[] children;
			foreach (ch; comp.getChildren) {
				if (!ch.isDisposed && !(cast(Sash) ch)) {
					children ~= ch;
				}
			}
			if (children.length == 1) {
				auto aft = afters(comp);
				children[0].setParent = comp.getParent;
				addAfters(aft);
				comp.dispose;
				tree(children[0]);
			} else if (children.length == 2) {
				// area.layout(true)が効かない事があるので
				// SashFormを作り直さなければならない
				auto aft = afters(comp);
				auto weights = comp.getWeights;
				auto sash = new SashForm(comp.getParent, comp.getStyle);
				addAfters(aft);
				foreach (c; children) c.setParent = sash;
				comp.dispose;
				foreach (child; children) tree(child);
				sash.setWeights = weights;
			} else {
				assert (!children.length);
				comp.dispose;
			}
		}
		tree(area.getChildren[0]);
	}
	private void drawDropMark(GC gc, int x, int y, int w, int h) {
		auto d = Display.getCurrent;
		gc.setBackground = d.getSystemColor(DWT.COLOR_BLACK);
		gc.setAlpha = 0xff / 2;
		gc.setLineWidth = 5;
		switch (_drawPos) {
		case DPos.C: gc.fillRectangle(x, y, w, h); break;
		case DPos.N: gc.fillRectangle(x, y, w, h / 2); break;
		case DPos.E: gc.fillRectangle(x + w / 2, y, w / 2, h); break;
		case DPos.S: gc.fillRectangle(x, y + h / 2, w, h / 2); break;
		case DPos.W: gc.fillRectangle(x, y, w / 2, h); break;
		case DPos.NONE: break;
		}
	}
	private class PLT : PaintListener {
		override void paintControl(PaintEvent e) {
			auto tabf = cast(TabF) e.widget;
			if (tabf.getItemCount > 0) return;
			if (tabf !is _drawTabf) return;
			auto ca = tabf.getClientArea;
			drawDropMark(e.gc, ca.x, ca.y, ca.width, ca.height);
		}
	}
	private class PL : PaintListener {
		override void paintControl(PaintEvent e) {
			auto tabf = (cast(Control) e.widget).getParent;
			if (tabf !is _drawTabf) return;
			drawDropMark(e.gc, e.x, e.y, e.width, e.height);
		}
	}
	private class DSL : DragSourceListener {
		private TabF _tabf;
		this (TabF tabf) {_tabf = tabf;}
		override void dragStart(DragSourceEvent e) {
			e.doit = false;
			auto itm = _tabf.getItem(new Point(e.x, e.y));
			if (itm) {
				_dragItm = itm;
				e.doit = true;
			}
		}
		override void dragSetData(DragSourceEvent e) {
			if (_dragItm) {
				e.data = new ArrayWrapperString(_dragItm.getText);
			}
		}
		override void dragFinished(DragSourceEvent e) {
			if (e.detail == DND.DROP_MOVE) {
				auto tabf = _dragItm.getParent;
				_dragItm.dispose;
				_dragItm = null;
				if (tabf.getItemCount == 0) {
					tabf.dispose;
					_tabfs = .remove!("a is b")(_tabfs, tabf);
					reconstruct;
				}
				area.layout(true);
			}
		}
	}
	private static Control[] afters(Control targ) {
		auto pcs = targ.getParent.getChildren;
		int pi = cwx.utils.indexOf!("a is b")(pcs, targ);
		assert (pi != -1);
		return pcs[pi + 1 .. $];
	}
	private static void addAfters(Control[] afters) {
		foreach (ac; afters) {
			auto par = ac.getParent;
			ac.setParent = ac.getParent.getParent;
			ac.setParent = par;
		}
	}
	private static void setInsertMark(TabF tabf, Tab tab, bool after) {
		static if (is(typeof(tabf.setInsertMark(tab, after)))) {
			tabf.setInsertMark(tab, after);
		}
	}
	private static void redrawTab(TabF tabf) {
		static if (is(typeof(tabf.getSelection()) == Tab)) {
			auto tab = tabf.getSelection;
			if (tab) {
				tab.getControl.redraw;
			} else {
				tabf.redraw;
			}
		} else {
			auto tabs = tabf.getSelection;
			if (tabs.length) {
				tabs[0].getControl.redraw;
			} else {
				tabf.redraw;
			}
		}
	}
	private class DTL : DropTargetAdapter {
		private TabF _tabf;
		this (TabF tabf) {_tabf = tabf;}
		override void dragEnter(DropTargetEvent e) {
			dragOver(e);
		}
		override void dragLeave(DropTargetEvent e) {
			e.detail = DND.DROP_NONE;
			_drawPos = DPos.NONE;
			redrawTab(_tabf);
		}
		override void dragOver(DropTargetEvent e) {
			if (!_dragItm) return;
			_drawTabf = _tabf;
			auto p = _tabf.toControl(e.x, e.y);
			auto itm = _tabf.getItem(p);
			auto dropPos = _dropPos;
			_dropPos = DPos.NONE;
			e.detail = DND.DROP_NONE;
			if (itm) {
				setInsertMark(_tabf, itm, false);
				_dropPos = DPos.C;
			} else {
				setInsertMark(_tabf, null, false);
				auto ca = _tabf.getClientArea;
				auto size = _tabf.getSize;
				int x = p.x, y = p.y;
				int w = size.x, h = size.y;
				int xn = w - x, yn = h - y;
				if (y < ca.y || (_tabf is _dragItm.getParent && _tabf.getItemCount == 1)) {
					_dropPos = DPos.C;
					if (_tabf.getItemCount > 0) {
						int index = _tabf.getItemCount - 1;
						setInsertMark(_tabf, _tabf.getItem(index), true);
					}
				} else if (y <= x && y <= xn && y < h / 3) {
					_dropPos = DPos.N;
				} else if (xn <= y && xn <= yn && x > w - w / 3) {
					_dropPos = DPos.E;
				} else if (yn <= x && yn <= xn && y > h - h / 3) {
					_dropPos = DPos.S;
				} else if (x <= y && x <= yn && x < w / 3) {
					_dropPos = DPos.W;
				} else if (0 <= x && 0 <= y && x < w && y < h) {
					_dropPos = DPos.C;
				}
			}
			if (_dropPos != DPos.NONE) e.detail = DND.DROP_MOVE;
			if (_dropPos != dropPos) {
				_drawPos = _dropPos;
				redrawTab(_tabf);
			}
		}
		override void drop(DropTargetEvent e) {
			e.detail = DND.DROP_NONE;
			scope (exit) {
				_drawTabf = null;
				_drawPos = DPos.NONE;
				_dropPos = DPos.NONE;
			}
			if (_dropPos == DPos.NONE || !e.data || !_dragItm) return;
			auto sash = _tabf.getParent;
			void newTab(TabF tabf, int index) {
				auto tab = index != -1
					? new Tab(tabf, _dragItm.getStyle, index)
					: new Tab(tabf, _dragItm.getStyle);
				auto c = _dragItm.getControl;
				c.setParent = tabf;
				tab.setControl = c;
				_dragItm.setControl = null;
				tab.setText = _dragItm.getText;
				tabf.setSelection = tab;
			}
			int putCenter() {
				auto dropItm = _tabf.getItem(_tabf.toControl(e.x, e.y));
				if (dropItm is _dragItm) return DND.DROP_NONE;
				int i1 = dropItm ? cwx.utils.indexOf!("a is b")(_tabf.getItems, dropItm) : _tabf.getItemCount;
				if (_tabf is _dragItm.getParent) {
					int i2 = cwx.utils.indexOf!("a is b")(_tabf.getItems, _dragItm);
					if (i2 + 1 == i1) return DND.DROP_NONE;
				}
				newTab(_tabf, dropItm ? i1 : -1);
				return DND.DROP_MOVE;
			}
			int newSash(int style, bool before) {
				if (_tabf is _dragItm.getParent && _tabf.getItemCount == 1) {
					return DND.DROP_NONE;
				}
				int[] weights;
				auto sashf = cast(SashForm) sash;
				if (sashf) weights = sashf.getWeights;
				scope (exit) if(sashf) sashf.setWeights = weights;
				auto aft = afters(_tabf);
				auto nSash = new SashForm(sash, style);
				addAfters(aft);
				if (before) {
					newTab(newTabf(nSash), -1);
					_tabf.setParent = nSash;
				} else {
					_tabf.setParent = nSash;
					newTab(newTabf(nSash), -1);
				}
				nSash.setWeights([1, 1]);
				return DND.DROP_MOVE;
			}
			switch (_dropPos) {
			case DPos.N: {
				e.detail = newSash(DWT.VERTICAL, true);
			} break;
			case DPos.E: {
				e.detail = newSash(DWT.HORIZONTAL, false);
			} break;
			case DPos.S: {
				e.detail = newSash(DWT.VERTICAL, false);
			} break;
			case DPos.W: {
				e.detail = newSash(DWT.HORIZONTAL, true);
			} break;
			case DPos.C: {
				e.detail = putCenter;
			} break;
			default: break;
			}
		}
	}
	private TabF[] _tabfs;

	XNode toNode() {
		auto r = XNode.create("dockingFolder");
		toNode(r, area.getChildren[0]);
		return r;
	}
	XNode toNode(ref XNode parent) {
		auto r = parent.newElement("dockingFolder");
		toNode(r, area.getChildren[0]);
		return r;
	}
	private XNode toNode(ref XNode parent, Control c) {
		auto sash = cast(SashForm) c;
		if (sash) {
			auto r = parent.newElement("sash");
			r.newAttr("type", (sash.getStyle & DWT.VERTICAL) ? "vertical" : "horizontal");
			auto weights = sash.getWeights;
			r.newAttr("lWeight", weights[0]);
			r.newAttr("rWeight", weights[1]);
			foreach (child; sash.getChildren) {
				if (!(cast(Sash) child)) {
					toNode(r, child);
				}
			}
			return r;
		} else {
			auto tabf = cast(TabF) c;
			assert (tabf);
			auto r = parent.newElement("tabs");
			r.newAttr("select", tabf.getSelectionIndex);
			foreach (tab; tabf.getItems) {
				auto t = r.newElement("tab");
				t.newAttr("key", _ctrls[tab.getControl]);
				t.newAttr("name", tab.getText);
			}
			return r;
		}
	}
	static DockingFolder fromNode(ref XNode node, Composite parent, int style,
			Control delegate(Composite, string) create) {
		assert (node.name == "dockingFolder");
		DockingFolder r = new DockingFolder(parent, style, false);
		Composite par = r.area;
		void proc(ref XNode node) {
			switch (node.name) {
			case "sash": {
				auto oldPar = par;
				scope (exit) par = oldPar;
				auto type = node.attr("type", true);
				auto sash = new SashForm(par, type == "vertical" ? DWT.VERTICAL : DWT.HORIZONTAL);
				par = sash;
				node.onTag[null] = &proc;
				node.parse;
				sash.setWeights([node.attr!(int)("lWeight", true), node.attr!(int)("rWeight", true)]);
			} break;
			case "tabs": {
				auto tabf = r.newTabf(par);
				node.onTag["tab"] = (ref XNode node) {
					auto key = node.attr("key", true);
					r.add(create(tabf, key), node.attr("name", true), key);
				};
				node.parse;
				tabf.setSelection = node.attr!(int)("select", true);
			} break;
			default: break;
			}
		}
		node.onTag[null] = &proc;
		node.parse;
		return r;
	}

	Composite[] composites() {return cast(Composite[]) _tabfs;}
	void addAll(Control[string] ctrls, string[string] titles) {
		foreach (key, ctrl; ctrls) {
			add(ctrl, titles[key], key);
		}
	}
	void add(Control ctrl, string tabText, string key) {
		auto tabf = cast(TabF) ctrl.getParent;
		if (!tabf) throw new Exception("no tabfolder");
		auto tab = new Tab(tabf, DWT.NONE);
		tab.setText = tabText;
		tab.setControl = ctrl;
		ctrl.addPaintListener(new PL);
		_ctrls[ctrl] = key;
		_keys[key] = ctrl;
	}
}
