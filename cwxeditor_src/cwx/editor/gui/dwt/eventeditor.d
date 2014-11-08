
module cwx.editor.gui.dwt.eventeditor;

import cwx.summary;
import cwx.utils;
import cwx.event;
import cwx.types;
import cwx.warning;

import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.image;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.eventtreeview;

import std.algorithm;
import std.ascii;
import std.conv;
import std.datetime;
import std.string;

import org.eclipse.swt.all;
import java.lang.all;

struct PosInfo {
	int x;
	int y;
	int height;
	int index;
	Content content;
	string eventText;
	int commentLineX = 0;
	Rectangle commentRect = null;
}

class EventEditorItem : Item {
	private EventEditor _parent;

	private this (EventEditor parent, Content c) { mixin(S_TRACE);
		super (parent, style);
		_parent = parent;
		setData(c);
	}
	static EventEditorItem valueOf(EventEditor parent, Content c) { mixin(S_TRACE);
		auto itm = parent._items.get(c.eventId, null);
		if (!itm) { mixin(S_TRACE);
			itm = new EventEditorItem(parent, c);
			parent._items[c.eventId] = itm;
		}
		return itm;
	}

	EventEditor getParent() { return _parent; }

	EventEditorItem getParentItem() { mixin(S_TRACE);
		auto c = cast(Content)getData();
		if (c.parent) { mixin(S_TRACE);
			return EventEditorItem.valueOf(getParent(), c.parent);
		}
		return null;
	}
	EventEditorItem getItem(int index) { mixin(S_TRACE);
		auto c = cast(Content)getData();
		return EventEditorItem.valueOf(getParent(), c.next[index]);
	}
	EventEditorItem[] getItems() { mixin(S_TRACE);
		auto c = cast(Content)getData();
		auto items = new EventEditorItem[c.next.length];
		foreach (i; 0 .. c.next.length) { mixin(S_TRACE);
			items[i] = getItem(i);
		}
		return items;
	}
	int getItemCount() { mixin(S_TRACE);
		auto c = cast(Content)getData();
		return c.next.length;
	}
	int indexOf(EventEditorItem itm) { mixin(S_TRACE);
		auto targ = cast(Content)itm.getData();
		auto c = cast(Content)getData();
		foreach (i, child; c.next) { mixin(S_TRACE);
			if (child is targ) { mixin(S_TRACE);
				return i;
			}
		}
		return -1;
	}

	void setExpanded(bool expanded) { mixin(S_TRACE);
		auto c = cast(Content)getData();
		if (_parent._expanded.get(c.eventId, true) != expanded) { mixin(S_TRACE);
			_parent._expanded[c.eventId] = expanded;
			_parent.updatePosImpl();
		}
	}
	bool getExpanded() { mixin(S_TRACE);
		auto c = cast(Content)getData();
		return _parent._expanded.get(c.eventId, true);
	}
	Rectangle getBounds() { mixin(S_TRACE);
		auto c = cast(Content)getData();
		if (c.eventId !in _parent._posTable) return null;
		auto gc = new GC(_parent);
		scope (exit) gc.dispose();
		auto pos = _parent._posTable[c.eventId];
		auto sy = _parent.getVerticalBar().getSelection() * _parent._lineHeight;
		return new Rectangle(0, pos.y - sy, 20 + gc.textExtent(pos.eventText).x + 4, pos.height);
	}
	Rectangle getImageBounds() { mixin(S_TRACE);
		auto c = cast(Content)getData();
		auto index = _parent.indexOf(c);
		auto pos = _parent._pos[index];
		auto sx = _parent.getHorizontalBar().getSelection();
		auto sy = _parent.getVerticalBar().getSelection() * _parent._lineHeight;
		return new Rectangle(pos.x - sx, pos.y + _parent._imgPos - sy, _parent._imageWidth, _parent._lineHeight - _parent._imgPos - _parent._imgPos);
	}
}

class EventEditor : Composite {
	private Commons _comm;
	private Summary _summ;
	private EventTree _et;
	private bool[string] _expanded;
	private int _splitter;
	private int _imageWidth = 16;
	private int _lineHeight = 16;
	private int _imgPos = 0;
	private int _heightSum = 0;
	private int _widthSum = 0;
	private Content _selected = null, _lightup = null;
	/// yの順に整列した位置リスト。
	private PosInfo[] _pos;
	/// イベントコンテントをキーに位置を取るテーブル。
	private PosInfo[string] _posTable;
	private EventEditorItem[string] _items;

	private Color _lineColor = null;
	private Color _selectedColor = null;
	private Color _lightupColor = null;

	private Cursor _cursor = null;
	private bool _changeCursor = false;
	private bool _moveDetailLine = false;
	private Image _warningImage = null;

	private Warning[] _warningRects;

	private bool _expandedOperation = false;
	private bool _showEventTreeDetail = true;

	private bool _updatePos = true;
	private bool _showSelection = false;

	this (Commons comm, Composite parent, int style, Summary summ, EventTree et) { mixin(S_TRACE);
		super (parent, style | SWT.V_SCROLL | SWT.H_SCROLL | SWT.DOUBLE_BUFFERED);
		auto d = getDisplay();
		_comm = comm;
		_summ = summ;
		_et = et;
		auto gc = new GC(this);
		scope (exit) gc.dispose();
		_lineHeight = gc.getFontMetrics().getHeight();
		_imgPos = (_lineHeight - _comm.prop.images.content(CType.START).getBounds().height) / 2;

		auto vbar = getVerticalBar();
		vbar.setMinimum(0);
		vbar.setMaximum(1);
		vbar.setSelection(0);
		vbar.setIncrement(1);
		vbar.setPageIncrement(1);
		vbar.setThumb(1);
		auto hbar = getHorizontalBar();
		hbar.setMinimum(0);
		hbar.setMaximum(32);
		hbar.setSelection(0);
		hbar.setIncrement(16);
		hbar.setPageIncrement(32);
		hbar.setThumb(32);
		.listener(this, SWT.Resize, &updateScrollBar);
		.listener(hbar, SWT.Selection, &redraw);
		.listener(vbar, SWT.Selection, &redraw);

		setBackground(d.getSystemColor(SWT.COLOR_WHITE));
		auto color = new Color(d, new RGB(96, 96, 96));
		_lineColor = new Color(d, new RGB(192, 192, 192));
		_selectedColor = new Color(d, new RGB(128, 191, 255));
		_lightupColor = new Color(d, new RGB(191, 224, 255));
		_warningImage = .warningImage(_comm.prop, d);
		setForeground(color);
		if (_summ) _comm.refTerminalMark.add(&updatePosImpl);
		.listener(this, SWT.Dispose, { mixin(S_TRACE);
			_lineColor.dispose();
			_selectedColor.dispose();
			_lightupColor.dispose();
			color.dispose();
			_warningImage.dispose();
			_expanded = null;
			_selected = null;
			_lightup = null;
			_pos = [];
			_posTable = null;
			_items = null;
			_warningRects = [];
			if (_summ) _comm.refTerminalMark.remove(&updatePosImpl);
		});
		.listener(this, SWT.Paint, &onPaint);
		.listener(this, SWT.MouseWheel, &onMouseWheel);
		.listener(this, SWT.Traverse, &onTraverse);
		.listener(this, SWT.MouseDown, &onMouseDown);
		.listener(this, SWT.MouseUp, &onMouseUp);
		.listener(this, SWT.MouseMove, &onMouseMove);
		.listener(this, SWT.MouseEnter, &onMouseEnter);
		.listener(this, SWT.MouseExit, &onMouseExit);
		.listener(this, SWT.MouseDoubleClick, &onMouseDoubleClick);
		.listener(this, SWT.KeyDown, &onKeyDown);
		.listener(this, SWT.FocusIn, &onFocusInOut);
		.listener(this, SWT.FocusOut, &onFocusInOut);
		setDragDetect(true);
		updateEventTree();
	}

	@property
	inout
	inout(EventTree) eventTree() { return _et; }
	@property
	void eventTree(EventTree et) { mixin(S_TRACE);
		_et = et;
		updateEventTree();
	}

	void expandAll() { mixin(S_TRACE);
		_expanded = null;
		updatePosImpl();
	}

	void showSelection() { mixin(S_TRACE);
		if (_showSelection || _updatePos) { mixin(S_TRACE);
			_showSelection = true;
			return;
		}
		_showSelection = false;
		updatePosImpl2();
		if (!_selected) return;
		if (_selected.eventId !in _posTable) return;
		scroll(_posTable[_selected.eventId].y / _lineHeight, _posTable[_selected.eventId].height);
	}
	private void scroll(int pos, int height) { mixin(S_TRACE);
		_showSelection = false;
		updatePosImpl2();
		auto vbar = getVerticalBar();
		int vPos = vbar.getSelection();
		int thumb = getClientArea().height / _lineHeight;
		if (pos < vPos) { mixin(S_TRACE);
			vbar.setSelection(pos);
		} else if (vPos + thumb <= pos) { mixin(S_TRACE);
			vbar.setSelection(pos - thumb + (height / _lineHeight));
		}
	}

	@property
	const
	bool showEventTreeDetail() { mixin(S_TRACE);
		return _showEventTreeDetail;
	}
	@property
	void showEventTreeDetail(bool v) { mixin(S_TRACE);
		_showEventTreeDetail = v;
		redraw();
	}

	void updateEventTree() { mixin(S_TRACE);
		_items = null;
		updatePosImpl();
	}
	private void updatePosImpl() { mixin(S_TRACE);
		_updatePos = true;
		redraw();
	}
	private void updatePosImpl2() { mixin(S_TRACE);
		if (!_updatePos) return;
		_updatePos = false;
		int x = 0;
		int y = 0;
		int selIndex = 0;
		auto oldSel = _selected;
		if (_selected && _selected.eventId in _posTable) { mixin(S_TRACE);
			selIndex = indexOf(_selected);
		}
		_pos = [];
		_posTable = null;
		_lightup = null;
		_heightSum = 0;
		_widthSum = 0;
		int index = 0;
		bool[string] expanded2;
		auto gc = new GC(this);
		scope (exit) gc.dispose();
		void recurse(int x, Content c) { mixin(S_TRACE);
			auto type = c.type;
			int height = _lineHeight;
			_heightSum++;
			if ((_summ ? _comm.prop.var.etc.showTerminalMark : showTerminalMark) && type != CType.START && !c.next.length) { mixin(S_TRACE);
				height = _lineHeight * 2;
				_heightSum++;
			}
			auto s = .eventText(_comm, _summ, c.parent, c, !(getStyle() & SWT.READ_ONLY));
			_pos ~= PosInfo(x, y, height, index, c, s, 0, null);
			_posTable[c.eventId] = PosInfo(x, y, height, index, c, s, 0, null);
			y += height;
			index++;

			// 幅計算
			if (c.name == "" && c.parent && c.parent.detail.nextType == CNextType.TEXT) { mixin(S_TRACE);
				s = _comm.skin.evtChildOK;
			}
			if (s == "") { mixin(S_TRACE);
				_widthSum = .max(x + 16, _widthSum);
			} else { mixin(S_TRACE);
				_widthSum = .max(x + 20 + gc.textExtent(s).x, _widthSum);
			}

			if (c.next.length && !_expanded.get(c.eventId, true)) { mixin(S_TRACE);
				expanded2[c.eventId] = false;
				return;
			}
			auto d = c.detail;
			if (type != CType.START && c.next.length == 1 && (!(_summ ? _comm.prop.var.etc.forceIndentBranchContent : forceIndentBranchContent) || d.nextType == CNextType.NONE || d.nextType == CNextType.TEXT)) { mixin(S_TRACE);
				recurse(x + slope, c.next[0]);
			} else if (c.next.length) { mixin(S_TRACE);
				foreach (next; c.next) { mixin(S_TRACE);
					recurse(x + _imageWidth, next);
				}
			}
		}
		if (_et) { mixin(S_TRACE);
			foreach (i, start; _et.starts) { mixin(S_TRACE);
				recurse(x, start);
			}
			if (_selected && _selected.eventId !in _posTable && 0 < selIndex) { mixin(S_TRACE);
				if (_selected.type !is CType.START) selIndex -= 1;
				_selected = null;
			}
		} else { mixin(S_TRACE);
			_selected = null;
		}
		if (!_selected && _pos.length) { mixin(S_TRACE);
			_selected = _pos[.min(selIndex, $ - 1)].content;
		}
		_expanded = expanded2;
		_posTable.rehash();

		// コメント位置
		Rectangle[] boxes;
		Rectangle[string] cBoxes;
		string[] comments;
		Rectangle itemRect(ref PosInfo pos) { mixin(S_TRACE);
			auto c = pos.content;
			if (auto p = c.eventId in cBoxes) { mixin(S_TRACE);
				return *p;
			}
			auto s = pos.eventText;
			if (c.name == "" && c.parent && c.parent.detail.nextType == CNextType.TEXT) { mixin(S_TRACE);
				s = _comm.skin.evtChildOK;
			}
			int rx = 20 + gc.textExtent(s).x;
			auto rect = new Rectangle(pos.x, pos.y, rx, pos.height);
			cBoxes[c.eventId] = rect;
			return rect;
		}
		auto hh = _lineHeight / 2;
		foreach (i, ref pos; _pos) { mixin(S_TRACE);
			auto c = pos.content;
			if (c.comment == "") continue;
			auto cRect = itemRect(pos);
			int rx = cRect.x + cRect.width;
			if (!_expanded.get(c.eventId, true)) { mixin(S_TRACE);
				rx += 14 + gc.textExtent("...").x + 3;
			} else { mixin(S_TRACE);
				rx += 2;
			}
			auto cm = std.string.chomp(.lastRet(c.comment));
			auto te = gc.textExtent(cm);
			// 改行文字があると横幅がおかしくなるため
			// 測り直す
			te.x = 0;
			auto lines = splitLines!string(cm);
			foreach (line; lines) { mixin(S_TRACE);
				te.x = max(gc.textExtent(line).x, te.x);
			}
			// 前後n件のイベントコンテントに被らないようにする
			int ba = lines.length;
			Rectangle[] boxes2;
			if (0 < ba) { mixin(S_TRACE);
				foreach (j; .max(i - ba, 0) .. i) { mixin(S_TRACE);
					boxes2 ~= itemRect(_pos[j]);
				}
				foreach (j; i + 1 .. .min(_pos.length, i + ba + 1)) { mixin(S_TRACE);
					boxes2 ~= itemRect(_pos[j]);
				}
			}

			int dis = 15;
			int tw = te.x + 10;
			int th = te.y + 6;

			// 画面外へ出ないようにY座標の調節
			int ty = pos.y - th / 2 + hh;
			ty = .min(ty, _heightSum * _lineHeight - th);
			ty = .max(ty, 0);

			auto box = new Rectangle(rx + dis, ty, tw, th);
			foreach (b; boxes2 ~ boxes) { mixin(S_TRACE);
				if (b.intersects(box)) { mixin(S_TRACE);
					box.x = b.x + b.width + 4;
				}
			}
			boxes ~= box;
			comments ~= cm;
			_pos[i].commentLineX = rx;
			_pos[i].commentRect = box;
			_posTable[c.eventId].commentLineX = rx;
			_posTable[c.eventId].commentRect = box;
			_widthSum = .max(box.x + box.width, _widthSum);
		}
		_widthSum += 2;

		updateScrollBar();
		redraw();
		if (_selected !is oldSel && _selected) { mixin(S_TRACE);
			callSelectChanged();
		}
	}
	private void updateScrollBar() { mixin(S_TRACE);
		auto ca = getClientArea();

		auto hbar = getHorizontalBar();
		auto cw = ca.width - detailAreaWidth;
		hbar.setVisible(cw < _widthSum);
		hbar.setMaximum(_widthSum);
		hbar.setThumb(cw);
		hbar.setPageIncrement(cw / 2);

		auto vbar = getVerticalBar();
		vbar.setMaximum(_heightSum);
		vbar.setThumb(ca.height / _lineHeight);
		vbar.setPageIncrement(ca.height / _lineHeight / 2);
	}

	private void updateToolTip() { mixin(S_TRACE);
		auto p = getDisplay().getCursorLocation();
		p = toControl(p);
		string toolTip = "";
		auto ca = getClientArea();
		if (!_moveDetailLine && !_changeCursor && ca.contains(p)) { mixin(S_TRACE);
			foreach (warn; _warningRects) { mixin(S_TRACE);
				if (warn.rect.contains(p)) { mixin(S_TRACE);
					toolTip = std.string.join(warn.warnings, .newline);
					break;
				}
			}
			if (toolTip == "" && ca.width - detailAreaWidth <= p.x) { mixin(S_TRACE);
				int index = indexOf(p.y);
				if (0 <= index && index < _pos.length) { mixin(S_TRACE);
					auto pos = _pos[index];
					if (p.y - pos.y < _lineHeight) { mixin(S_TRACE);
						auto c = pos.content;
						auto s = .contentText(_comm, c, _summ);
						auto gc = new GC(this);
						scope (exit) gc.dispose();
						int dw = detailAreaWidth - 2 - 18;
						if (dw < gc.textExtent(s).x) { mixin(S_TRACE);
							toolTip = s;
						}
					}
				}
			}
		}
		toolTip = std.array.replace(toolTip, "&", "&&");
		if (getToolTipText() != toolTip) { mixin(S_TRACE);
			setToolTipText(toolTip);
		}
	}

	EventEditorItem getItem(int index) { mixin(S_TRACE);
		return EventEditorItem.valueOf(this, _et.starts[index]);
	}

	EventEditorItem getItem(Point p) { mixin(S_TRACE);
		auto c = getContent(p.x, p.y);
		if (c) { mixin(S_TRACE);
			return EventEditorItem.valueOf(this, c);
		}
		return null;
	}
	EventEditorItem[] getItems() { mixin(S_TRACE);
		if (!_et) return [];
		auto c = cast(Content)getData();
		auto items = new EventEditorItem[_et.starts.length];
		foreach (i; 0 .. _et.starts.length) { mixin(S_TRACE);
			items[i] = getItem(i);
		}
		return items;
	}
	int getItemCount() { mixin(S_TRACE);
		if (!_et) return 0;
		return _et.starts.length;
	}

	EventEditorItem[] getSelection() { mixin(S_TRACE);
		if (_selected) { mixin(S_TRACE);
			return [EventEditorItem.valueOf(this, _selected)];
		}
		return [];
	}
	void setSelection(EventEditorItem[] items) { mixin(S_TRACE);
		foreach (itm; items) { mixin(S_TRACE);
			select(itm);
		}
	}
	void select(EventEditorItem itm) { mixin(S_TRACE);
		auto c = cast(Content)itm.getData();
		if (c) { mixin(S_TRACE);
			_selected = c;
			redraw();
		}
	}
	void select(Content c) { mixin(S_TRACE);
		_selected = c;
		redraw();
	}
	int indexOf(EventEditorItem itm) { mixin(S_TRACE);
		if (!_et) return -1;
		return .cCountUntil(_et.starts, cast(Content)itm.getData());
	}
	EventEditorItem getTopItem() { mixin(S_TRACE);
		auto vbar = getVerticalBar();
		auto index = indexOf(vbar.getSelection() * _lineHeight);
		if (0 <= index && index < _pos.length) { mixin(S_TRACE);
			return EventEditorItem.valueOf(this, _pos[index].content);
		}
		return null;
	}
	void setTopItem(EventEditorItem itm) { mixin(S_TRACE);
		if (itm && (cast(Content)itm.getData()).eventId in _posTable) { mixin(S_TRACE);
			auto vbar = getVerticalBar();
			auto pos = _posTable[(cast(Content)itm.getData()).eventId];
			vbar.setSelection(pos.y / _lineHeight);
		}
	}

	Content getContent(int x, int y) { mixin(S_TRACE);
		auto index = indexOf(y);
		if (index < 0 || _pos.length <= index) return null;
		return _pos[index].content;
	}

	private void onTraverse(Event e) { mixin(S_TRACE);
		switch (e.detail) {
		case SWT.TRAVERSE_ARROW_NEXT, SWT.TRAVERSE_ARROW_PREVIOUS:
			e.doit = false;
			break;
		default:
			e.doit = true;
		}
	}

	private int indexOf(Content c) { mixin(S_TRACE);
		if (c.eventId !in _posTable) return -1;
		return _posTable[c.eventId].index;
	}
	private int indexOf(int y) { mixin(S_TRACE);
		if (y < 0) return -1;
		auto ca = getClientArea();
		if (ca.height <= y) return -1;

		auto vbar = getVerticalBar();
		auto sy = vbar.getSelection() * _lineHeight;
		y += sy;

		return find(y, 0, _pos.length);
	}
	private int find(int y, int from, int to) { mixin(S_TRACE);
		if (to <= from) return -1;
		auto mid = (from + to) / 2;
		auto pos = _pos[mid];
		assert (mid == pos.index);
		if (y < pos.y) { mixin(S_TRACE);
			return find(y, from, mid);
		} else if (pos.y + pos.height <= y) { mixin(S_TRACE);
			return find(y, mid + 1, to);
		} else { mixin(S_TRACE);
			return pos.index;
		}
	}
	private void select(int index) { mixin(S_TRACE);
		_selected = _pos[index].content;
		redraw();
	}

	/// 選択の変更をlistenerに通知する。
	void addSelectionListener(SelectionListener listener) { mixin(S_TRACE);
		auto tl = new TypedListener(listener);
		addListener(SWT.Selection, tl);
		addListener(SWT.DefaultSelection, tl);
	}
	/// ditto
	void removeSelectionListener(SelectionListener listener) { mixin(S_TRACE);
		removeListener(SWT.Selection, listener);
		removeListener(SWT.DefaultSelection, listener);
	}
	private void callSelectChanged() { mixin(S_TRACE);
		if (isDisposed()) return;
		auto se = new Event;
		auto sels = getSelection();
		se.item = sels.length ? sels[0] : null;
		se.time = cast(int)(0xFFFFFFFFL & Clock.currStdTime());
		se.stateMask = 0;
		se.doit = true;
		notifyListeners(SWT.Selection, se);
	}

	/// 選択の変更をlistenerに通知する。
	void addTreeListener(TreeListener listener) { mixin(S_TRACE);
		auto tl = new TypedListener(listener);
		addListener(SWT.Expand, tl);
		addListener(SWT.Collapse, tl);
	}
	/// ditto
	void removeTreeListener(TreeListener listener) { mixin(S_TRACE);
		removeListener(SWT.Expand, listener);
		removeListener(SWT.Collapse, listener);
	}
	private void callExpandedChanged(EventEditorItem itm) { mixin(S_TRACE);
		getDisplay().asyncExec(new class Runnable {
			override void run() { mixin(S_TRACE);
				if (isDisposed()) return;
				auto se = new Event;
				se.item = itm;
				se.time = cast(int)(0xFFFFFFFFL & Clock.currStdTime());
				se.stateMask = 0;
				se.doit = true;
				notifyListeners(itm.getExpanded() ? SWT.Expand : SWT.Collapse, se);
			}
		});
	}

	/// キーボード操作による開閉操作が可能か。
	@property
	void expandedOperation(bool enabled) { mixin(S_TRACE);
		_expandedOperation = true;
	}
	/// ditto
	@property
	const
	bool expandedOperation() { return _expandedOperation; }

	private void onKeyDown(Event e) { mixin(S_TRACE);
		if (!_pos.length) return;
		if (e.stateMask != SWT.NONE) return;
		switch (e.keyCode) {
		case SWT.ARROW_LEFT:
			if (expandedOperation && _selected && _selected.next.length && _expanded.get(_selected.eventId, true)) { mixin(S_TRACE);
				_expanded[_selected.eventId] = false;
				updatePosImpl();
				return;
			}
			goto case SWT.ARROW_UP;
		case SWT.ARROW_RIGHT:
			if (expandedOperation && _selected && _selected.next.length && !_expanded.get(_selected.eventId, true)) { mixin(S_TRACE);
				_expanded[_selected.eventId] = true;
				updatePosImpl();
				return;
			}
			goto case SWT.ARROW_DOWN;
		case SWT.ARROW_UP:
			if (_selected) { mixin(S_TRACE);
				int i = indexOf(_selected);
				if (0 < i) select(i - 1);
			} else { mixin(S_TRACE);
				select(0);
			}
			showSelection();
			callSelectChanged();
			break;
		case SWT.ARROW_DOWN:
			if (_selected) { mixin(S_TRACE);
				int i = indexOf(_selected);
				if (i + 1 < _pos.length) { mixin(S_TRACE);
					select(i + 1);
				}
			} else { mixin(S_TRACE);
				select(0);
			}
			showSelection();
			callSelectChanged();
			break;
		default:
			break;
		}
	}

	private void onMouseDown(Event e) { mixin(S_TRACE);
		if (e.button == 1 || e.button == 3) { mixin(S_TRACE);
			forceFocus();
			if (e.button == 1 && _changeCursor) { mixin(S_TRACE);
				_moveDetailLine = true;
			} else { mixin(S_TRACE);
				auto sel = getContent(e.x, e.y);
				if (sel) _selected = sel;
				if (sel) { mixin(S_TRACE);
					showSelection();
					callSelectChanged();
				}
				redraw();
			}
			e.doit = false;
		}
	}

	private void onMouseUp(Event e) { mixin(S_TRACE);
		if (e.button == 1 && _moveDetailLine) { mixin(S_TRACE);
			_moveDetailLine = false;
		}
	}

	private void onMouseMove(Event e) { mixin(S_TRACE);
		auto ca = getClientArea();
		if (_moveDetailLine) { mixin(S_TRACE);
			int w = detailAreaWidth;
			_comm.prop.var.etc.detailAreaWidth = ca.width - e.x;
			_comm.prop.var.etc.detailAreaWidth = .min(detailAreaWidth, ca.width - _imageWidth);
			_comm.prop.var.etc.detailAreaWidth = .max(detailAreaWidth, _imageWidth);
			w = .max(w, detailAreaWidth);
			updateScrollBar();
			redraw();
		} else { mixin(S_TRACE);
			auto linePos = ca.width - detailAreaWidth;
			if (linePos - 10 <= e.x && e.x < linePos + 10) { mixin(S_TRACE);
				if (!_changeCursor) { mixin(S_TRACE);
					auto d = getDisplay();
					_cursor = getCursor();
					_changeCursor = true;
					setCursor(d.getSystemCursor(SWT.CURSOR_SIZEWE));
					setDragDetect(false);
				}
			} else if (_changeCursor) { mixin(S_TRACE);
				setCursor(_cursor);
				setDragDetect(true);
				_cursor = null;
				_changeCursor = false;
			}
		}
		updateLightup();
		updateToolTip();
	}
	private void onMouseEnter(Event e) { mixin(S_TRACE);
		updateLightup();
	}
	private void onMouseExit(Event e) { mixin(S_TRACE);
		clearLightup();
	}
	private void onFocusInOut(Event e) { mixin(S_TRACE);
		auto ca = getClientArea();
		if (_selected && _selected.eventId in _posTable) { mixin(S_TRACE);
			auto pos = _posTable[_selected.eventId];
			auto sy = getVerticalBar().getSelection() * _lineHeight;
			redraw(ca.x, pos.y - sy, ca.width, _lineHeight + 1, true);
		}
	}

	private void clearLightup() { mixin(S_TRACE);
		if (_lightup && _lightup.eventId in _posTable) { mixin(S_TRACE);
			auto ca = getClientArea();
			auto sy = getVerticalBar().getSelection() * _lineHeight;
			auto pos = _posTable[_lightup.eventId];
			redraw(ca.x, pos.y - sy, ca.width, _lineHeight + 1, true);
		}
		_lightup = null;
	}
	void updateLightup() { mixin(S_TRACE);
		auto ca = getClientArea();
		auto p = getDisplay().getCursorLocation();
		p = toControl(p);
		auto sy = getVerticalBar().getSelection() * _lineHeight;
		clearLightup();
		_lightup = ca.contains(p) ? getContent(p.x, p.y) : null;
		if (_lightup && _lightup.eventId in _posTable) { mixin(S_TRACE);
			auto pos = _posTable[_lightup.eventId];
			redraw(ca.x, pos.y - sy, ca.width, _lineHeight + 1, true);
		}
	}

	private void onMouseDoubleClick(Event e) { mixin(S_TRACE);
		auto itm = getItem(new Point(e.x, e.y));
		if (!itm) return;
		auto c = cast(Content)itm.getData();
		if (itm && c.type == CType.START && c.next.length) { mixin(S_TRACE);
			itm.setExpanded(!itm.getExpanded());
			callExpandedChanged(itm);
		}
	}

	private void onMouseWheel(Event e) { mixin(S_TRACE);
		clearLightup();
		auto vbar = getVerticalBar();
		auto val = vbar.getSelection();
		if (e.count < 0) { mixin(S_TRACE);
			val += 1;
		} else if (0 < e.count) { mixin(S_TRACE);
			val -= 1;
		}
		vbar.setSelection(val);
		updateLightup();
	}

	@property
	private int detailAreaWidth() {
		if (!_showEventTreeDetail) return 0;
		auto ca = getClientArea();
		int detailAreaWidth = min(_comm.prop.var.etc.detailAreaWidth.value, ca.width - _imageWidth);
		return .max(detailAreaWidth, _imageWidth);
	}

	private void onPaint(Event e) { mixin(S_TRACE);
		if (!_et) return;
		updatePosImpl2();
		if (!_pos.length) return;
		auto hw = _imageWidth / 2;
		auto hh = _lineHeight / 2;
		auto ca = getClientArea();

		int detailAreaWidth = this.detailAreaWidth;

		auto hbar = getHorizontalBar();
		auto vbar = getVerticalBar();
		int index = .max(0, find(vbar.getSelection() * _lineHeight, 0, _pos.length));
		int to = .min(_pos.length, index + ca.height / _lineHeight + 1);
		auto poss = _pos[index .. to];
		int sx = hbar.getSelection();
		int sy = vbar.getSelection() * _lineHeight;

		auto d = getDisplay();
		if (_lightup && _lightup.eventId in _posTable) { mixin(S_TRACE);
			// マウスオーバー中のイベントコンテント
			auto pos = _posTable[_lightup.eventId];
			e.gc.setBackground(_lightupColor);
			scope (exit) e.gc.setBackground(getBackground());
			e.gc.fillRectangle(e.x, pos.y - sy, e.width, _lineHeight + 1);
		}
		if (_selected && _selected.eventId in _posTable) { mixin(S_TRACE);
			// 選択中マーク
			// FIXME: e.gcで直接描画するとフォーカス線が出ない場合がある
			//        一度でもキー操作をすると改善するが、確実に回避する
			//        ためには別のGCを作成して描画を行う必要がある
			auto buf = new Image(d, e.width, _lineHeight + 1);
			scope (exit) buf.dispose();
			auto gc = new GC(buf);
			scope (exit) gc.dispose();

			auto pos = _posTable[_selected.eventId];
			gc.setBackground(_selectedColor);
			scope (exit) gc.setBackground(getBackground());
			gc.fillRectangle(0, 0, e.width, _lineHeight + 1);
			if (isFocusControl()) { mixin(S_TRACE);
				gc.setForeground(d.getSystemColor(SWT.COLOR_BLACK));
				auto cw = .max(ca.width, _widthSum + detailAreaWidth);
				gc.drawFocus(2 - sx, 2, cw - 4, _lineHeight + 1 - 4);
			}
			e.gc.drawImage(buf, e.x, pos.y - sy);
		}

		// イベントコンテントを結ぶ線
		e.gc.setLineWidth(4);
		e.gc.setForeground(_lineColor);
		e.gc.setBackground(_lineColor);
		foreach (i, ref pos; _pos[index .. $]) { mixin(S_TRACE);
			auto c = pos.content;
			if (c.type == CType.START) { mixin(S_TRACE);
				if (poss.length <= i) break;
				if (0 < i && (_summ ? _comm.prop.var.etc.drawContentTreeLine : drawContentTreeLine)) { mixin(S_TRACE);
					e.gc.setLineWidth(1);
					e.gc.setForeground(_lineColor);
					e.gc.drawLine(e.x - sx, pos.y - sy, e.x + e.width - sx, pos.y - sy);
					e.gc.setLineWidth(4);
					e.gc.setForeground(_lineColor);
				}
			} else if (c.parent && c.parent.eventId in _posTable) { mixin(S_TRACE);
				auto pPos = _posTable[c.parent.eventId];
				if (pPos.x == pos.x) { mixin(S_TRACE);
					e.gc.drawLine(pos.x + hw - sx, pPos.y + hh - sy, pos.x + hw - sx, pos.y + hh - sy);
				} else { mixin(S_TRACE);
					if (pPos.y + hh - sy < pos.y - sy) { mixin(S_TRACE);
						e.gc.drawLine(pPos.x + hw - sx, pPos.y + hh - sy, pPos.x + hw - sx, pos.y - sy);
					}
					e.gc.setAntialias(SWT.ON);
					auto cap = e.gc.getLineCap();
					e.gc.setLineCap(SWT.CAP_ROUND);
					e.gc.drawArc(pPos.x + hw - sx, pos.y - sy - _lineHeight, pos.x - pPos.x + hw, _lineHeight + hh, 180, 90);
					e.gc.setLineCap(cap);
					e.gc.setAntialias(SWT.OFF);
				}
			}
			if ((_summ ? _comm.prop.var.etc.showTerminalMark : showTerminalMark) && c.type != CType.START && !c.next.length) { mixin(S_TRACE);
				// 後続コンテントが置かれるであろう位置を示す
				// (終端の場合は後続コンテントが置けない事を示す)
				int terX = pos.x + hw - sx;
				int terY = pos.y + hh + _lineHeight - sy + 1;
				if (c.detail.owner) { mixin(S_TRACE);
					e.gc.drawLine(pos.x + hw - sx, pos.y + hh - sy, terX, terY - 8);
					e.gc.drawLine(terX, terY - 6, terX, terY - 2);
					e.gc.drawLine(terX, terY, terX, terY + 3);
				} else { mixin(S_TRACE);
					e.gc.drawLine(pos.x + hw - sx, pos.y + hh - sy, terX, terY - 5);
					e.gc.fillRectangle(terX - 6, terY - 5, 12, 4);
				}
			}
		}
		// イベントコンテント分岐点
		e.gc.setBackground(getBackground());
		e.gc.setAntialias(SWT.ON);
		e.gc.setLineWidth(4);
		foreach (i, ref pos; poss) { mixin(S_TRACE);
			auto c = pos.content;
			if (c.parent && c.parent.eventId in _posTable) { mixin(S_TRACE);
				auto pPos = _posTable[c.parent.eventId];
				if (pPos.x != pos.x && pPos.y != pos.y - _lineHeight) { mixin(S_TRACE);
					e.gc.fillOval(pPos.x + hw - 6 - sx, pos.y - hh - sy - 2, 12, 12);
					e.gc.drawOval(pPos.x + hw - 6 - sx, pos.y - hh - sy - 2, 12, 12);
				}
			}
		}
		e.gc.setAntialias(SWT.OFF);
		e.gc.setLineWidth(1);

		// イベントコンテントのアイコンとテキスト
		auto ucExtent = e.gc.textExtent(_comm.prop.msgs.startUseCount);
		e.gc.setForeground(getForeground());
		foreach (ref pos; poss) { mixin(S_TRACE);
			auto c = pos.content;
			auto image = _comm.prop.images.content(c.type);
			e.gc.drawImage(image, pos.x - sx, pos.y + _imgPos - sy);
			string s;
			if (c.name == "" && c.parent && c.parent.detail.nextType == CNextType.TEXT) { mixin(S_TRACE);
				e.gc.setForeground(d.getSystemColor(SWT.COLOR_GRAY));
				s = _comm.skin.evtChildOK;
			} else { mixin(S_TRACE);
				e.gc.setForeground(d.getSystemColor(SWT.COLOR_BLACK));
				s = .eventText(_comm, _summ, c.parent, c, !(getStyle() & SWT.READ_ONLY));
			}
			auto ctx = pos.x + 20;
			e.gc.drawText(s, ctx - sx, pos.y - sy, true);
			if ((_summ ? _comm.prop.var.etc.drawCountOfUseOfStart : drawCountOfUseOfStart) && c.type == CType.START) { mixin(S_TRACE);
				// スタート使用数
				auto count = _et.startUseCounter.get(toStartId(c.name));
				if (_pos[0].content is c) count++;
				auto uc = .text(count);
				auto tw = e.gc.textExtent(uc).x;
				int tx = ca.width - detailAreaWidth - 4 - tw;
				e.gc.setForeground(getForeground());
				e.gc.drawString(_comm.prop.msgs.startUseCount, tx - ucExtent.x - 4, pos.y - sy, true);
				e.gc.setForeground(d.getSystemColor(SWT.COLOR_BLACK));
				e.gc.drawString(uc, tx, pos.y - sy, true);
			}
			if (!_expanded.get(c.eventId, true)) { mixin(S_TRACE);
				// ツリーを畳んでいる時のマーク
				e.gc.setForeground(getForeground());
				auto tw = e.gc.textExtent(s).x;
				auto te = e.gc.textExtent("...");
				e.gc.drawLine(ctx + tw + 2 - sx, pos.y - sy + hh, ctx + tw + 10 - sx, pos.y - sy + hh);
				e.gc.drawString("...", ctx + tw + 14 - sx, pos.y - sy, true);
				e.gc.setAntialias(SWT.ON);
				e.gc.drawRoundRectangle(ctx + tw + 10 - sx, pos.y - sy, te.x + 8, te.y, 10, 10);
				e.gc.setAntialias(SWT.OFF);
			}
		}

		// イベントコンテントの内容領域、警告
		e.gc.setForeground(d.getSystemColor(SWT.COLOR_BLACK));
		e.gc.setBackground(getBackground());
		if (detailAreaWidth) {
			e.gc.drawLine(ca.width - detailAreaWidth, e.y, ca.width - detailAreaWidth, e.y + e.height);
			e.gc.setAlpha(192);
			e.gc.fillRectangle(ca.width - detailAreaWidth, e.y, detailAreaWidth, e.height);
			e.gc.setAlpha(255);
		}

		_warningRects = [];
		foreach (ref pos; poss) { mixin(S_TRACE);
			// イベントコンテント内容
			auto c = pos.content;
			if (detailAreaWidth) {
				auto s = .contentText(_comm, c, _summ);
				int x = ca.width - detailAreaWidth + 2;
				auto image = _comm.prop.images.content(c.type);
				e.gc.setAlpha(128);
				e.gc.drawImage(image, x, pos.y + _imgPos - sy);
				e.gc.setAlpha(255);
				e.gc.drawText(s, x + 18, pos.y - sy, true);
			}

			// 警告
			if (_summ ? _comm.prop.var.etc.drawContentWarnings : drawContentWarnings) { mixin(S_TRACE);
				auto warnings = .warnings(_comm.prop.parent, _comm.skin, _summ, c, _comm.prop.var.etc.targetVersion);
				if (warnings.length) { mixin(S_TRACE);
					int ww = _comm.prop.var.etc.warningImageWidth;
					int wix = .max(0, ca.width - detailAreaWidth - ww);
					int wiw = ca.width - detailAreaWidth - wix;
					if (wiw <= 0) continue;
					e.gc.drawImage(_warningImage, 0, 0, ww, 1, wix, pos.y - sy, wiw, _lineHeight + 1);
					e.gc.drawImage(_comm.prop.images.warning, wix + wiw - _imageWidth - 4, pos.y + _imgPos - sy);
					auto rect = new Rectangle(ca.x, pos.y - sy, ca.width - detailAreaWidth, _lineHeight);
					_warningRects ~= Warning(rect, warnings);
				}
			}
		}

		// コメント
		e.gc.setBackground(getBackground());
		e.gc.setForeground(getForeground());
		foreach (i, ref pos; _pos) { mixin(S_TRACE);
			if (!pos.commentRect) continue;
			e.gc.drawLine(pos.commentLineX - sx, pos.y + hh - sy, pos.commentRect.x - sx, pos.y + hh - sy);
		}
		e.gc.setAntialias(SWT.ON);
		foreach (i, ref pos; _pos) { mixin(S_TRACE);
			if (!pos.commentRect) continue;
			auto box = pos.commentRect;
			e.gc.setAlpha(192);
			e.gc.fillRoundRectangle(box.x - sx, box.y - sy, box.width, box.height, 12, 12);
			e.gc.setAlpha(255);
			e.gc.setForeground(getForeground());
			e.gc.drawRoundRectangle(box.x - sx, box.y - sy, box.width, box.height, 12, 12);
			e.gc.setForeground(d.getSystemColor(SWT.COLOR_BLACK));
			e.gc.drawString(pos.content.comment, box.x + 5 - sx, box.y + 3 - sy, true);
		}
		e.gc.setAntialias(SWT.OFF);

		if (_showSelection) { mixin(S_TRACE);
			_showSelection = false;
			showSelection();
		}
	}

	private bool _showTerminalMark = false;
	private bool _forceIndentBranchContent = false;
	private bool _drawContentTreeLine = false;
	private bool _drawCountOfUseOfStart = false;
	private bool _drawContentWarnings = false;
	private int _slope = 0;
	/// 表示オプション。
	/// シナリオ編集中であればCommons#propの値が、
	/// 表示テスト中であればここで設定された値が採用される。
	@property
	const
	bool showTerminalMark() { return _showTerminalMark; }
	/// ditto
	@property
	void showTerminalMark(bool v) { mixin(S_TRACE);
		_showTerminalMark = v;
		updatePosImpl();
	}
	/// ditto
	@property
	const
	bool forceIndentBranchContent() { return _forceIndentBranchContent; }
	/// ditto
	@property
	void forceIndentBranchContent(bool v) { mixin(S_TRACE);
		_forceIndentBranchContent = v;
		updatePosImpl();
	}
	/// ditto
	@property
	const
	int slope() { return _slope; }
	/// ditto
	@property
	void slope(int v) { mixin(S_TRACE);
		_slope = v;
		updatePosImpl();
	}
	/// ditto
	@property
	const
	bool drawContentTreeLine() { return _drawContentTreeLine; }
	/// ditto
	@property
	void drawContentTreeLine(bool v) { mixin(S_TRACE);
		_drawContentTreeLine = v;
		redraw();
	}
	/// ditto
	@property
	const
	bool drawCountOfUseOfStart() { return _drawCountOfUseOfStart; }
	/// ditto
	@property
	void drawCountOfUseOfStart(bool v) { mixin(S_TRACE);
		_drawCountOfUseOfStart = v;
		redraw();
	}
	/// ditto
	@property
	const
	bool drawContentWarnings() { return _drawContentWarnings; }
	/// ditto
	@property
	void drawContentWarnings(bool v) { mixin(S_TRACE);
		_drawContentWarnings = v;
		redraw();
	}
}

package struct TreeViewWrapper {
	Tree tree;
	EventEditor editor;

	@property
	Composite control() { mixin(S_TRACE);
		if (tree) { mixin(S_TRACE);
			return tree;
		} else { mixin(S_TRACE);
			return editor;
		}
	}

	private Item[] array(T)(T[] itms) { mixin(S_TRACE);
		auto a = new Item[itms.length];
		foreach (i, itm; itms) { mixin(S_TRACE);
			a[i] = itm;
		}
		return a;
	}
	private T[] items(T)(Item[] itms) { mixin(S_TRACE);
		auto a = new T[itms.length];
		foreach (i, itm; itms) { mixin(S_TRACE);
			a[i] = cast(T)itm;
		}
		return a;
	}

	Item getTopItem() { mixin(S_TRACE);
		if (tree) { mixin(S_TRACE);
			return tree.getTopItem();
		} else { mixin(S_TRACE);
			return editor.getTopItem();
		}
	}
	void setTopItem(Item itm) { mixin(S_TRACE);
		if (tree) { mixin(S_TRACE);
			tree.setTopItem(cast(TreeItem)itm);
		} else { mixin(S_TRACE);
			editor.setTopItem(cast(EventEditorItem)itm);
		}
	}

	Item[] getSelection() { mixin(S_TRACE);
		if (tree) { mixin(S_TRACE);
			return array(tree.getSelection());
		} else { mixin(S_TRACE);
			return array(editor.getSelection());
		}
	}
	void setSelection(Item[] itms) { mixin(S_TRACE);
		if (tree) { mixin(S_TRACE);
			tree.setSelection(items!TreeItem(itms));
		} else { mixin(S_TRACE);
			editor.setSelection(items!EventEditorItem(itms));
		}
	}
	void select(Item itm) { mixin(S_TRACE);
		if (tree) { mixin(S_TRACE);
			tree.select(cast(TreeItem)itm);
		} else { mixin(S_TRACE);
			editor.select(cast(EventEditorItem)itm);
		}
	}

	Item getItem(int index) { mixin(S_TRACE);
		if (tree) { mixin(S_TRACE);
			return tree.getItem(index);
		} else { mixin(S_TRACE);
			return editor.getItem(index);
		}
	}
	Item getItem(Point p) { mixin(S_TRACE);
		if (tree) { mixin(S_TRACE);
			return tree.getItem(p);
		} else { mixin(S_TRACE);
			return editor.getItem(p);
		}
	}

	int getItemCount() { mixin(S_TRACE);
		if (tree) { mixin(S_TRACE);
			return tree.getItemCount();
		} else { mixin(S_TRACE);
			return editor.getItemCount();
		}
	}
	int getItemCount(Item itm) { mixin(S_TRACE);
		if (auto b = cast(TreeItem)itm) return b.getItemCount();
		return (cast(EventEditorItem)itm).getItemCount();
	}
	int getItemCount(ref TreeViewWrapper view) { mixin(S_TRACE);
		return view.getItemCount();
	}

	void showSelection() { mixin(S_TRACE);
		if (tree) { mixin(S_TRACE);
			return tree.showSelection();
		} else { mixin(S_TRACE);
			return editor.showSelection();
		}
	}

	void addSelectionListener(SelectionListener listener) { mixin(S_TRACE);
		if (tree) { mixin(S_TRACE);
			return tree.addSelectionListener(listener);
		} else { mixin(S_TRACE);
			return editor.addSelectionListener(listener);
		}
	}
	void addTreeListener(TreeListener listener) { mixin(S_TRACE);
		if (tree) { mixin(S_TRACE);
			return tree.addTreeListener(listener);
		} else { mixin(S_TRACE);
			return editor.addTreeListener(listener);
		}
	}
	Item[] getItems() { mixin(S_TRACE);
		if (tree) { mixin(S_TRACE);
			return array(tree.getItems());
		} else { mixin(S_TRACE);
			return array(editor.getItems());
		}
	}
	Item[] getItems(Item itm) { mixin(S_TRACE);
		if (auto b = cast(TreeItem)itm) return array(b.getItems());
		return array((cast(EventEditorItem)itm).getItems());
	}
	Item getItem(Item itm, int index) { mixin(S_TRACE);
		if (auto b = cast(TreeItem)itm) return b.getItem(index);
		return (cast(EventEditorItem)itm).getItem(index);
	}
	bool getExpanded(Item itm) { mixin(S_TRACE);
		if (auto b = cast(TreeItem)itm) return b.getExpanded();
		return (cast(EventEditorItem)itm).getExpanded();
	}
	void setExpanded(Item itm, bool expanded) { mixin(S_TRACE);
		if (auto b = cast(TreeItem)itm) { mixin(S_TRACE);
			b.setExpanded(expanded);
		} else { mixin(S_TRACE);
			(cast(EventEditorItem)itm).setExpanded(expanded);
		}
	}
	Item getParentItem(Item itm) { mixin(S_TRACE);
		if (auto b = cast(TreeItem)itm) return b.getParentItem();
		return (cast(EventEditorItem)itm).getParentItem();
	}
	Item getItem(ref TreeViewWrapper view, int index) { mixin(S_TRACE);
		return getItem(index);
	}

	int indexOf(Item itm) { mixin(S_TRACE);
		if (tree) { mixin(S_TRACE);
			return tree.indexOf(cast(TreeItem)itm);
		} else { mixin(S_TRACE);
			return editor.indexOf(cast(EventEditorItem)itm);
		}
	}
	int indexOf(Item itm, Item child) { mixin(S_TRACE);
		if (auto b = cast(TreeItem)itm) return b.indexOf(cast(TreeItem)child);
		return (cast(EventEditorItem)itm).indexOf(cast(EventEditorItem)child);
	}

	Item topItem(Item itm) { mixin(S_TRACE);
		if (auto b = cast(TreeItem)itm) return .topItem(b);
		auto c = cast(Content)itm.getData();
		if (c.parent) return EventEditorItem.valueOf(editor, c.parentStart);
		return itm;
	}

	void treeExpandedAll() { mixin(S_TRACE);
		if (tree) { mixin(S_TRACE);
			.treeExpandedAll(tree);
		} else { mixin(S_TRACE);
			editor.expandAll();
		}
	}

	Rectangle getImageBounds(Item itm) { mixin(S_TRACE);
		if (auto b = cast(TreeItem)itm) return b.getImageBounds(0);
		return (cast(EventEditorItem)itm).getImageBounds();
	}
}

/// EventEditorのテキストを編集可能にする。
/// ダブルクリック、またはF2キーの押下で編集開始。
class EventEdit {
private:
	Commons _comm;
	EventEditor _list;
	EditEnd _tee;
	Control _editor = null;
	EventEditorItem _edit = null;
	int _oldIndex = -1;

	void delegate(EventEditorItem itm, Control ctrl) _editEnd;
	Control delegate(EventEditorItem itm) _createEditor;

	Item selectionM(int x, int y) { mixin(S_TRACE);
		if (!_list.getDragDetect()) return null;
		auto c = _list.getContent(x, y);
		if (!c) return null;
		int index = _list.indexOf(c);
		if (x < _list._pos[index].x + 20) return null;
		auto ca = _list.getClientArea();
		if (ca.width - _list.detailAreaWidth <= x) return null;
		return _list.getItem(new Point(x, y));
	}
	Item selectionK() { mixin(S_TRACE);
		auto sels = _list.getSelection();
		if (sels.length) { mixin(S_TRACE);
			return sels[0];
		}
		return null;
	}

	void end(Control ctrl) { mixin(S_TRACE);
		assert (_edit !is null);
		_editEnd(_edit, ctrl);
		_tee = null;
		_edit = null;
		_editor = null;
		_oldIndex = -1;
	}

	void startEdit(Item itm) { mixin(S_TRACE);
		if (_tee !is null && !_tee.isExit) _tee.enter();
		_editor = _createEditor(cast(EventEditorItem)itm);
		if (_editor) { mixin(S_TRACE);
			_edit = cast(EventEditorItem)itm;
			_list.showSelection();
			_tee = new EditEnd(_comm, _list, _editor, &end);
			layout();
			_tee.setFocus();
		}
	}
	void layout() { mixin(S_TRACE);
		if (!_edit) return;
		int scrPos = _list.getVerticalBar().getSelection();
		if (scrPos == _oldIndex) return;
		_oldIndex = scrPos;
		auto index = _list.indexOf(cast(Content)_edit.getData());
		auto size = _editor.computeSize(SWT.DEFAULT, SWT.DEFAULT);
		auto pos = _list._pos[index];
		auto sy = _list.getVerticalBar().getSelection() * _list._lineHeight;
		int x = pos.x + 20;
		int w;
		if (cast(Combo)_editor || cast(CCombo)_editor) { mixin(S_TRACE);
			w = size.x;
		} else { mixin(S_TRACE);
			auto ca = _list.getClientArea();
			w = ca.width - _list.detailAreaWidth - pos.x - 20;
			w = .max(_comm.prop.var.etc.nameWidth.value, w);
		}
		int h = size.y;
		int y = pos.y + (_list._lineHeight - h) / 2 - sy;
		_editor.setBounds(x, y, w, h);
	}
public:
	/// list = テキスト編集対象のEventEditor。
	/// editEnd = 編集終了時に実行される関数。
	/// createEditor = アイテムを編集するコンポーネントを生成する関数。
	///                nullを返した場合、編集は開始されない。
	this(Commons comm, EventEditor list, void delegate(EventEditorItem itm, Control ctrl) editEnd,
			Control delegate(EventEditorItem itm) createEditor = null) { mixin(S_TRACE);
		_comm = comm;
		_list = list;
		_editEnd = editEnd;
		_createEditor = createEditor;

		auto mf = new TextEditMFListener(comm, list, &startEdit, &selectionK, &selectionM);
		list.addMouseListener(mf);
		list.addSelectionListener(mf);
		list.addFocusListener(mf);
		list.addKeyListener(new TextEditKListener(&startEdit, &selectionK));
		.listener(list, SWT.Paint, &layout);
	}
	/// 選択されているセルの編集を開始する。
	void startEdit() { mixin(S_TRACE);
		auto sels = _list.getSelection();
		if (sels.length == 1) { mixin(S_TRACE);
			startEdit(sels[0]);
		}
	}
	bool isEditing() { mixin(S_TRACE);
		return _tee !is null;
	}
}
