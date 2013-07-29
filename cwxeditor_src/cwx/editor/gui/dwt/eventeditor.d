
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
	Content content;
}

class EventEditorItem : Item {
	private EventEditor _parent;

	this (EventEditor parent, Content c) {
		super (parent, style);
		_parent = parent;
		setData(c);
	}

	override
	bool opEquals(Object obj) {
		if (auto itm = cast(Item)obj) {
			return getData() is itm.getData();
		}
		return false;
	}

	EventEditor getParent() { return _parent; }

	EventEditorItem getParentItem() {
		auto c = cast(Content)getData();
		if (c.parent) {
			return new EventEditorItem(getParent(), c.parent);
		}
		return null;
	}
	EventEditorItem getItem(int index) {
		auto c = cast(Content)getData();
		return new EventEditorItem(getParent(), c.next[index]);
	}
	EventEditorItem[] getItems() {
		auto c = cast(Content)getData();
		auto items = new EventEditorItem[c.next.length];
		foreach (i; 0 .. c.next.length) {
			items[i] = getItem(i);
		}
		return items;
	}
	int getItemCount() {
		auto c = cast(Content)getData();
		return c.next.length;
	}
	int indexOf(EventEditorItem itm) {
		auto targ = cast(Content)itm.getData();
		auto c = cast(Content)getData();
		foreach (i, child; c.next) {
			if (child is targ) {
				return i;
			}
		}
		return -1;
	}

	void setExpanded(bool expanded) {
		auto c = cast(Content)getData();
		if (_parent._expanded.get(c, true) != expanded) {
			_parent._expanded[c] = expanded;
			_parent.updateEventTree();
		}
	}
	bool getExpanded() {
		auto c = cast(Content)getData();
		return _parent._expanded.get(c, true);
	}
	Rectangle getBounds() {
		auto c = cast(Content)getData();
		if (c !in _parent._posTable) return null;
		auto gc = new GC(_parent);
		scope (exit) gc.dispose();
		auto s = .eventText(_parent._comm, _parent._summ, c.parent, c);
		auto pos = _parent._posTable[c];
		auto sy = _parent.getVerticalBar().getSelection() * _parent._lineHeight;
		return new Rectangle(0, pos.y - sy, 20 + gc.textExtent(s).x + 4, _parent._lineHeight);
	}
	Rectangle getImageBounds() {
		auto c = cast(Content)getData();
		auto index = _parent.indexOf(c);
		auto pos = _parent._pos[index];
		auto sy = _parent.getVerticalBar().getSelection() * _parent._lineHeight;
		return new Rectangle(pos.x, pos.y + _parent._imgPos - sy, _parent._imageWidth, _parent._lineHeight - _parent._imgPos - _parent._imgPos);
	}
}

class EventEditor : Composite {
	private Commons _comm;
	private Summary _summ;
	private EventTree _et;
	private bool[Content] _expanded;
	private int _splitter;
	private int _imageWidth = 16;
	private int _lineHeight = 16;
	private int _imgPos = 0;
	private Content _selected = null, _lightup = null;
	/// yの順に整列した位置リスト。
	private PosInfo[] _pos;
	/// イベントコンテントをキーに位置を取るテーブル。
	private PosInfo[Content] _posTable;

	private Color _lineColor = null;
	private Color _selectedColor = null;
	private Color _lightupColor = null;

	private Cursor _cursor = null;
	private bool _changeCursor = false;
	private bool _moveDetailLine = false;
	private Image _warningImage = null;

	private Warning[] _warningRects;

	private bool _expandedOperation = false;

	this (Commons comm, Composite parent, int style, Summary summ, EventTree et) {
		super (parent, style | SWT.VERTICAL | SWT.DOUBLE_BUFFERED);
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
		.listener(this, SWT.Resize, &updateScrollBar);
		.listener(vbar, SWT.Selection, &redraw);

		setBackground(d.getSystemColor(SWT.COLOR_WHITE));
		auto color = new Color(d, new RGB(96, 96, 96));
		_lineColor = new Color(d, new RGB(160, 160, 160));
		_selectedColor = new Color(d, new RGB(128, 191, 255));
		_lightupColor = new Color(d, new RGB(191, 224, 255));
		_warningImage = .warningImage(_comm.prop, d);
		setForeground(color);
		.listener(this, SWT.Dispose, {
			_lineColor.dispose();
			_selectedColor.dispose();
			_lightupColor.dispose();
			color.dispose();
			_warningImage.dispose();
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
		.listener(this, SWT.Resize, &onResize);
		.listener(this, SWT.FocusIn, &onFocusInOut);
		.listener(this, SWT.FocusOut, &onFocusInOut);
		setDragDetect(true);
		updateEventTree();
	}

	@property
	EventTree eventTree() { return _et; }
	@property
	void eventTree(EventTree et) {
		_et = et;
		updateEventTree();
	}

	void expandAll() {
		_expanded = null;
		updateEventTree();
	}

	void showSelection() {
		if (!_selected) return;
		if (_selected !in _posTable) return;
		auto pos = _posTable[_selected];
		auto index = pos.y / _lineHeight;
		scroll(index);
	}
	private void scroll(int pos) {
		auto vbar = getVerticalBar();
		int vPos = vbar.getSelection();
		if (pos < vPos) {
			vbar.setSelection(pos);
		} else if (vPos + vbar.getThumb() <= pos) {
			vbar.setSelection(pos - vbar.getThumb() + 1);
		}
	}

	void updateEventTree() {
		updatePosImpl();
		redraw();
	}
	private void updatePosImpl() {
		int x = 0;
		int y = 0;
		int selIndex = 0;
		if (_selected && _selected in _posTable) {
			auto selPos = _posTable[_selected];
			selIndex = selPos.y / _lineHeight;
		}
		_pos = [];
		_posTable = null;
		_lightup = null;
		bool[Content] expanded2;
		void recurse(int x, Content c) {
			auto type = c.type;
			_pos ~= PosInfo(x, y, c);
			_posTable[c] = PosInfo(x, y, c);
			y += _lineHeight;
			if (c.next.length && !_expanded.get(c, true)) {
				expanded2[c] = false;
				return;
			}
			if (type != CType.START && c.next.length == 1) {
				recurse(x, c.next[0]);
			} else if (c.next.length) {
				foreach (next; c.next) {
					recurse(x + _imageWidth, next);
				}
			}
		}
		if (_et) {
			foreach (i, start; _et.starts) {
				recurse(x, start);
			}
			if (_selected && _selected !in _posTable && 0 < selIndex) {
				selIndex -= 1;
				_selected = null;
			}
		} else {
			_selected = null;
		}
		if (!_selected && _pos.length) {
			_selected = _pos[.min(selIndex, $ - 1)].content;
		}
		_expanded = expanded2;
		_posTable.rehash();
		updateScrollBar();
	}
	private void updateScrollBar() {
		auto ca = getClientArea();
		auto vbar = getVerticalBar();
		vbar.setMaximum(_pos.length);
		vbar.setThumb(ca.height / _lineHeight);
		vbar.setPageIncrement(ca.height / _lineHeight / 2);
	}

	private void updateToolTip() {
		auto p = getDisplay().getCursorLocation();
		p = toControl(p);
		string toolTip = "";
		auto ca = getClientArea();
		if (!_moveDetailLine && !_changeCursor && ca.contains(p)) {
			foreach (warn; _warningRects) {
				if (warn.rect.contains(p)) {
					toolTip = std.string.join(warn.warnings, .newline);
					break;
				}
			}
			if (toolTip == "" && ca.width - _comm.prop.var.etc.detailAreaWidth <= p.x) {
				int index = getVerticalBar().getSelection() + (p.y / _lineHeight);
				if (0 <= index && index < _pos.length) {
					auto pos = _pos[index];
					auto c = pos.content;
					auto s = .contentText(_comm, c);
					auto gc = new GC(this);
					scope (exit) gc.dispose();
					int dw = _comm.prop.var.etc.detailAreaWidth - 2 - 18;
					if (dw < gc.textExtent(s).x) {
						toolTip = s;
					}
				}
			}
		}
		if (getToolTipText() != toolTip) {
			setToolTipText(toolTip);
		}
	}

	EventEditorItem getItem(int index) {
		return new EventEditorItem(this, _et.starts[index]);
	}

	EventEditorItem getItem(Point p) {
		auto c = getContent(p.x, p.y);
		if (c) {
			return new EventEditorItem(this, c);
		}
		return null;
	}
	EventEditorItem[] getItems() {
		if (!_et) return [];
		auto c = cast(Content)getData();
		auto items = new EventEditorItem[_et.starts.length];
		foreach (i; 0 .. _et.starts.length) {
			items[i] = getItem(i);
		}
		return items;
	}
	int getItemCount() {
		if (!_et) return 0;
		return _et.starts.length;
	}

	EventEditorItem[] getSelection() {
		if (_selected) {
			return [new EventEditorItem(this, _selected)];
		}
		return [];
	}
	void setSelection(EventEditorItem[] items) {
		foreach (itm; items) {
			select(itm);
		}
	}
	void select(EventEditorItem itm) {
		auto c = cast(Content)itm.getData();
		if (c) {
			_selected = c;
			redraw();
		}
	}
	void select(Content c) {
		_selected = c;
		redraw();
	}
	int indexOf(EventEditorItem itm) {
		if (!_et) return -1;
		return .cCountUntil(_et.starts, cast(Content)itm.getData());
	}
	EventEditorItem getTopItem() {
		auto vbar = getVerticalBar();
		auto index = vbar.getSelection();
		if (0 <= index && index < _pos.length) {
			return new EventEditorItem(this, _pos[index].content);
		}
		return null;
	}
	void setTopItem(EventEditorItem itm) {
		if (itm) {
			auto vbar = getVerticalBar();
			vbar.setSelection(indexOf(cast(Content)itm.getData()));
		}
	}

	Content getContent(int x, int y) {
		auto vbar = getVerticalBar();
		auto index = (y / _lineHeight + vbar.getSelection());
		if (index < 0 || _pos.length <= index) return null;
		return _pos[index].content;
	}

	private void onTraverse(Event e) {
		switch (e.detail) {
		case SWT.TRAVERSE_ARROW_NEXT, SWT.TRAVERSE_ARROW_PREVIOUS:
			e.doit = false;
			break;
		default:
			e.doit = true;
		}
	}

	private int indexOf(Content c) {
		if (c !in _posTable) return -1;
		return _posTable[c].y / _lineHeight;
	}
	private void select(int index) {
		_selected = _pos[index].content;
		redraw();
	}

	/// 選択の変更をlistenerに通知する。
	void addSelectionListener(SelectionListener listener) {
		auto tl = new TypedListener(listener);
		addListener(SWT.Selection, tl);
		addListener(SWT.DefaultSelection, tl);
	}
	/// ditto
	void removeSelectionListener(SelectionListener listener) {
		removeListener(SWT.Selection, listener);
		removeListener(SWT.DefaultSelection, listener);
	}
	private void callSelectChanged() {
		getDisplay().asyncExec(new class Runnable {
			override void run() {
				if (isDisposed()) return;
				auto se = new Event;
				auto sels = getSelection();
				se.item = sels.length ? sels[0] : null;
				se.time = cast(int)(0xFFFFFFFFL & Clock.currStdTime());
				se.stateMask = 0;
				se.doit = true;
				notifyListeners(SWT.Selection, se);
			}
		});
	}

	/// 選択の変更をlistenerに通知する。
	void addTreeListener(TreeListener listener) {
		auto tl = new TypedListener(listener);
		addListener(SWT.Expand, tl);
		addListener(SWT.Collapse, tl);
	}
	/// ditto
	void removeTreeListener(TreeListener listener) {
		removeListener(SWT.Expand, listener);
		removeListener(SWT.Collapse, listener);
	}
	private void callExpandedChanged(EventEditorItem itm) {
		getDisplay().asyncExec(new class Runnable {
			override void run() {
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
	void expandedOperation(bool enabled) {
		_expandedOperation = true;
	}
	/// ditto
	@property
	const
	bool expandedOperation() { return _expandedOperation; }

	private void onKeyDown(Event e) {
		if (!_pos.length) return;
		if (e.stateMask != SWT.NONE) return;
		switch (e.keyCode) {
		case SWT.ARROW_LEFT:
			if (expandedOperation && _selected && _selected.next.length && _expanded.get(_selected, true)) {
				_expanded[_selected] = false;
				updateEventTree();
				return;
			}
			goto case SWT.ARROW_UP;
		case SWT.ARROW_RIGHT:
			if (expandedOperation && _selected && _selected.next.length && !_expanded.get(_selected, true)) {
				_expanded[_selected] = true;
				updateEventTree();
				return;
			}
			goto case SWT.ARROW_DOWN;
		case SWT.ARROW_UP:
			if (_selected) {
				int i = indexOf(_selected);
				if (0 < i) select(i - 1);
			} else {
				select(0);
			}
			showSelection();
			callSelectChanged();
			break;
		case SWT.ARROW_DOWN:
			if (_selected) {
				int i = indexOf(_selected);
				if (i + 1 < _pos.length) {
					select(i + 1);
				}
			} else {
				select(0);
			}
			showSelection();
			callSelectChanged();
			break;
		default:
			break;
		}
	}

	private void onMouseDown(Event e) {
		if (e.button == 1 || e.button == 3) {
			forceFocus();
			if (e.button == 1 && _changeCursor) {
				_moveDetailLine = true;
			} else {
				auto sel = getContent(e.x, e.y);
				if (sel) _selected = sel;
				showSelection();
				callSelectChanged();
				redraw();
			}
			e.doit = false;
		}
	}

	private void onMouseUp(Event e) {
		if (e.button == 1 && _moveDetailLine) {
			_moveDetailLine = false;
		}
	}

	private void onMouseMove(Event e) {
		auto ca = getClientArea();
		if (_moveDetailLine) {
			int w = _comm.prop.var.etc.detailAreaWidth;
			_comm.prop.var.etc.detailAreaWidth = ca.width - e.x;
			_comm.prop.var.etc.detailAreaWidth = .min(_comm.prop.var.etc.detailAreaWidth.value, ca.width - _imageWidth);
			_comm.prop.var.etc.detailAreaWidth = .max(_comm.prop.var.etc.detailAreaWidth.value, _imageWidth);
			w = .max(w, _comm.prop.var.etc.detailAreaWidth.value);
			redraw();
		} else {
			auto linePos = ca.width - _comm.prop.var.etc.detailAreaWidth;
			if (linePos - 10 <= e.x && e.x < linePos + 10) {
				if (!_changeCursor) {
					auto d = getDisplay();
					_cursor = getCursor();
					_changeCursor = true;
					setCursor(d.getSystemCursor(SWT.CURSOR_SIZEWE));
					setDragDetect(false);
				}
			} else if (_changeCursor) {
				setCursor(_cursor);
				setDragDetect(true);
				_cursor = null;
				_changeCursor = false;
			}
		}
		updateLightup();
		updateToolTip();
	}
	private void onMouseEnter(Event e) {
		updateLightup();
	}
	private void onMouseExit(Event e) {
		clearLightup();
	}
	private void onFocusInOut(Event e) {
		auto ca = getClientArea();
		if (_selected && _selected in _posTable) {
			auto pos = _posTable[_selected];
			auto sy = getVerticalBar().getSelection() * _lineHeight;
			redraw(ca.x, pos.y - sy, ca.width, _lineHeight + 1, true);
		}
	}
	private void clearLightup() {
		if (_lightup && _lightup in _posTable) {
			auto ca = getClientArea();
			auto sy = getVerticalBar().getSelection() * _lineHeight;
			auto pos = _posTable[_lightup];
			redraw(ca.x, pos.y - sy, ca.width, _lineHeight + 1, true);
		}
		_lightup = null;
	}
	void updateLightup() {
		auto ca = getClientArea();
		auto p = getDisplay().getCursorLocation();
		p = toControl(p);
		auto sy = getVerticalBar().getSelection() * _lineHeight;
		clearLightup();
		_lightup = ca.contains(p) ? getContent(p.x, p.y) : null;
		if (_lightup && _lightup in _posTable) {
			auto pos = _posTable[_lightup];
			redraw(ca.x, pos.y - sy, ca.width, _lineHeight + 1, true);
		}
	}

	private void onMouseDoubleClick(Event e) {
		auto itm = getItem(new Point(e.x, e.y));
		if (!itm) return;
		auto c = cast(Content)itm.getData();
		if (itm && c.type == CType.START && c.next.length) {
			itm.setExpanded(!itm.getExpanded());
			callExpandedChanged(itm);
		}
	}

	private void onResize(Event e) {
		auto ca = getClientArea();
		_comm.prop.var.etc.detailAreaWidth = .min(_comm.prop.var.etc.detailAreaWidth.value, ca.width - _imageWidth);
		_comm.prop.var.etc.detailAreaWidth = .max(_comm.prop.var.etc.detailAreaWidth.value, _imageWidth);
	}

	private void onMouseWheel(Event e) {
		clearLightup();
		auto vbar = getVerticalBar();
		auto val = vbar.getSelection();
		if (e.count < 0) {
			val += 1;
		} else if (0 < e.count) {
			val -= 1;
		}
		vbar.setSelection(val);
		updateLightup();
	}

	private void onPaint(Event e) {
		if (!_et) return;
		if (!_pos.length) return;
		auto hw = _imageWidth / 2;
		auto hh = _lineHeight / 2;
		auto ca = getClientArea();

		auto vbar = getVerticalBar();
		int index = vbar.getSelection();
		auto poss = _pos[index .. .min($, index + ca.height / _lineHeight + 1)];
		int sy = index * _lineHeight;

		auto d = getDisplay();
		if (_lightup && _lightup in _posTable) {
			// マウスオーバー中のイベントコンテント
			auto pos = _posTable[_lightup];
			e.gc.setBackground(_lightupColor);
			scope (exit) e.gc.setBackground(getBackground());
			e.gc.fillRectangle(e.x, pos.y - sy, e.width, _lineHeight + 1);
		}
		if (_selected && _selected in _posTable) {
			// 選択中マーク
			auto pos = _posTable[_selected];
			e.gc.setBackground(_selectedColor);
			scope (exit) e.gc.setBackground(getBackground());
			e.gc.fillRectangle(e.x, pos.y - sy, e.width, _lineHeight + 1);
			if (isFocusControl()) {
				e.gc.setForeground(d.getSystemColor(SWT.COLOR_BLACK));
				e.gc.drawFocus(2, pos.y - sy + 2, ca.width - 4, _lineHeight + 1 - 4);
			}
		}

		// イベントコンテントを結ぶ線
		e.gc.setLineWidth(2);
		e.gc.setForeground(_lineColor);
		foreach (i, ref pos; poss) {
			auto c = pos.content;
			if (c.type == CType.START) {
				if (0 < i && _comm.prop.var.etc.drawContentTreeLine) {
					e.gc.setLineWidth(1);
					e.gc.setForeground(_lineColor);
					e.gc.drawLine(e.x, pos.y - sy, e.x + e.width, pos.y - sy);
					e.gc.setLineWidth(2);
					e.gc.setForeground(_lineColor);
				}
			} else if (c.parent && c.parent in _posTable) {
				auto pPos = _posTable[c.parent];
				if (pPos.x == pos.x) {
					e.gc.drawLine(pos.x + hw, pPos.y + hh - sy, pos.x + hw, pos.y + hh - sy);
				} else {
					e.gc.drawLine(pPos.x + hw, pPos.y + hh - sy, pPos.x + hw, pos.y - sy);
					e.gc.drawLine(pPos.x + _imageWidth, pos.y + hh - sy, pos.x + hw, pos.y + hh - sy);
					e.gc.setAntialias(SWT.ON);
					e.gc.drawArc(pPos.x + hw, pos.y - sy - hh, _imageWidth, _lineHeight, 180, 90);
					e.gc.setAntialias(SWT.OFF);
				}
			}
		}
		// イベントコンテント分岐点
		e.gc.setAntialias(SWT.ON);
		foreach (i, ref pos; poss) {
			auto c = pos.content;
			if (c.parent && c.parent in _posTable) {
				auto pPos = _posTable[c.parent];
				if (pPos.x != pos.x && pPos.y != pos.y - _lineHeight) {
					e.gc.fillOval(pPos.x + hw - 4, pos.y - sy - 2, 8, 8);
					e.gc.drawOval(pPos.x + hw - 4, pos.y - sy - 2, 8, 8);
				}
			}
		}
		e.gc.setAntialias(SWT.OFF);
		e.gc.setLineWidth(1);

		// イベントコンテントのアイコンとテキスト
		auto ucExtent = e.gc.textExtent(_comm.prop.msgs.startUseCount);
		e.gc.setForeground(getForeground());
		foreach (ref pos; poss) {
			auto c = pos.content;
			auto image = _comm.prop.images.content(c.type);
			e.gc.drawImage(image, pos.x, pos.y + _imgPos - sy);
			string s;
			if (c.name == "" && c.parent && c.parent.detail.nextType == CNextType.TEXT) {
				e.gc.setForeground(d.getSystemColor(SWT.COLOR_GRAY));
				s = _comm.skin.evtChildOK;
			} else {
				e.gc.setForeground(d.getSystemColor(SWT.COLOR_BLACK));
				s = .eventText(_comm, _summ, c.parent, c);
			}
			auto ctx = pos.x + 20;
			e.gc.drawText(s, ctx, pos.y - sy, true);
			if (_comm.prop.var.etc.drawCountOfUseOfStart && c.type == CType.START) {
				// スタート使用数
				auto count = _et.startUseCounter.get(toStartId(c.name));
				if (_pos[0].content is c) count++;
				auto uc = .text(count);
				auto tw = e.gc.textExtent(uc).x;
				int tx = ca.width - _comm.prop.var.etc.detailAreaWidth - 4 - tw;
				e.gc.setForeground(getForeground());
				e.gc.drawString(_comm.prop.msgs.startUseCount, tx - ucExtent.x - 4, pos.y - sy, true);
				e.gc.setForeground(d.getSystemColor(SWT.COLOR_BLACK));
				e.gc.drawString(uc, tx, pos.y - sy, true);
			}
			if (!_expanded.get(c, true)) {
				// ツリーを畳んでいる時のマーク
				e.gc.setForeground(getForeground());
				auto tw = e.gc.textExtent(s).x;
				auto te = e.gc.textExtent("...");
				e.gc.drawLine(ctx + tw + 2, pos.y - sy + hh, ctx + tw + 10, pos.y - sy + hh);
				e.gc.drawString("...", ctx + tw + 14, pos.y - sy, true);
				e.gc.setAntialias(SWT.ON);
				e.gc.drawRoundRectangle(ctx + tw + 10, pos.y - sy, te.x + 8, te.y, 10, 10);
				e.gc.setAntialias(SWT.OFF);
			}
		}

		// イベントコンテントの内容領域、警告
		e.gc.setForeground(d.getSystemColor(SWT.COLOR_BLACK));
		e.gc.setBackground(getBackground());
		e.gc.drawLine(ca.width - _comm.prop.var.etc.detailAreaWidth, e.y, ca.width - _comm.prop.var.etc.detailAreaWidth, e.y + e.height);
		e.gc.setAlpha(192);
		e.gc.fillRectangle(ca.width - _comm.prop.var.etc.detailAreaWidth, e.y, _comm.prop.var.etc.detailAreaWidth, e.height);
		e.gc.setAlpha(255);

		_warningRects = [];
		foreach (ref pos; poss) {
			// イベントコンテント内容
			auto c = pos.content;
			auto s = .contentText(_comm, c);
			int x = ca.width - _comm.prop.var.etc.detailAreaWidth + 2;
			auto image = _comm.prop.images.content(c.type);
			e.gc.setAlpha(128);
			e.gc.drawImage(image, x, pos.y + _imgPos - sy);
			e.gc.setAlpha(255);
			e.gc.drawText(s, x + 18, pos.y - sy, true);

			// 警告
			auto warnings = .warnings(_comm.prop.parent, _comm.skin, _summ, c, _comm.prop.var.etc.targetVersion);
			if (warnings.length) {
				int ww = _comm.prop.var.etc.warningImageWidth;
				int wix = .max(0, ca.width - _comm.prop.var.etc.detailAreaWidth - ww);
				int wiw = ca.width - _comm.prop.var.etc.detailAreaWidth - wix;
				if (wiw <= 0) continue;
				e.gc.drawImage(_warningImage, 0, 0, ww, 1, wix, pos.y - sy, wiw, _lineHeight);
				e.gc.drawImage(_comm.prop.images.warning, wix + wiw - _imageWidth - 4, pos.y + _imgPos - sy);
				auto rect = new Rectangle(ca.x, pos.y - sy, ca.width - _comm.prop.var.etc.detailAreaWidth, _lineHeight);
				_warningRects ~= Warning(rect, warnings);
			}
		}

		// コメント
		e.gc.setBackground(getBackground());
		e.gc.setForeground(getForeground());
		Rectangle[] boxes;
		string[] comments;
		foreach (ref pos; _pos) {
			auto c = pos.content;
			if (c.comment == "") continue;
			auto s = .eventText(_comm, _summ, c.parent, c);
			if (c.name == "" && c.parent && c.parent.detail.nextType == CNextType.TEXT) {
				s = _comm.skin.evtChildOK;
			}
			int rx = pos.x + 20 + e.gc.textExtent(s).x;
			if (!_expanded.get(c, true)) {
				rx += 14 + e.gc.textExtent("...").x + 3;
			} else {
				rx += 2;
			}
			auto cm = std.string.chomp(c.comment);
			auto te = e.gc.textExtent(cm);
			// 改行文字があると横幅がおかしくなるため
			// 測り直す
			te.x = 0;
			auto lines = splitLines!string(cm);
			foreach (line; lines) {
				te.x = max(e.gc.textExtent(line).x, te.x);
			}

			int tw = te.x + 10;
			int th = te.y + 6;
			int dis = 15;
			auto box = new Rectangle(rx + dis, pos.y - th / 2 + hh - sy, tw, th);
			foreach (b; boxes) {
				if (b.intersects(box)) {
					box.x = b.x + b.width + 4;
				}
			}
			boxes ~= box;
			comments ~= cm;

			int hy = box.y + th / 2;
			e.gc.drawLine(rx, hy, box.x, hy);
		}
		foreach (i, box; boxes) {
			e.gc.setAlpha(192);
			e.gc.fillRoundRectangle(box.x, box.y, box.width, box.height, 12, 12);
			e.gc.setAlpha(255);
			e.gc.setForeground(getForeground());
			e.gc.drawRoundRectangle(box.x, box.y, box.width, box.height, 12, 12);
			e.gc.setForeground(d.getSystemColor(SWT.COLOR_BLACK));
			e.gc.drawString(comments[i], box.x + 5, box.y + 5, true);
		}
	}
}

package struct TreeViewWrapper {
	Tree tree;
	EventEditor editor;

	@property
	Composite control() {
		if (tree) {
			return tree;
		} else {
			return editor;
		}
	}

	private Item[] array(T)(T[] itms) {
		auto a = new Item[itms.length];
		foreach (i, itm; itms) {
			a[i] = itm;
		}
		return a;
	}
	private T[] items(T)(Item[] itms) {
		auto a = new T[itms.length];
		foreach (i, itm; itms) {
			a[i] = cast(T)itm;
		}
		return a;
	}

	Item getTopItem() {
		if (tree) {
			return tree.getTopItem();
		} else {
			return editor.getTopItem();
		}
	}
	void setTopItem(Item itm) {
		if (tree) {
			tree.setTopItem(cast(TreeItem)itm);
		} else {
			editor.setTopItem(cast(EventEditorItem)itm);
		}
	}

	Item[] getSelection() {
		if (tree) {
			return array(tree.getSelection());
		} else {
			return array(editor.getSelection());
		}
	}
	void setSelection(Item[] itms) {
		if (tree) {
			tree.setSelection(items!TreeItem(itms));
		} else {
			editor.setSelection(items!EventEditorItem(itms));
		}
	}
	void select(Item itm) {
		if (tree) {
			tree.select(cast(TreeItem)itm);
		} else {
			editor.select(cast(EventEditorItem)itm);
		}
	}

	Item getItem(int index) {
		if (tree) {
			return tree.getItem(index);
		} else {
			return editor.getItem(index);
		}
	}
	Item getItem(Point p) {
		if (tree) {
			return tree.getItem(p);
		} else {
			return editor.getItem(p);
		}
	}

	int getItemCount() {
		if (tree) {
			return tree.getItemCount();
		} else {
			return editor.getItemCount();
		}
	}
	int getItemCount(Item itm) {
		if (auto b = cast(TreeItem)itm) return b.getItemCount();
		return (cast(EventEditorItem)itm).getItemCount();
	}
	int getItemCount(ref TreeViewWrapper view) {
		return view.getItemCount();
	}

	void showSelection() {
		if (tree) {
			return tree.showSelection();
		} else {
			return editor.showSelection();
		}
	}

	void addSelectionListener(SelectionListener listener) {
		if (tree) {
			return tree.addSelectionListener(listener);
		} else {
			return editor.addSelectionListener(listener);
		}
	}
	void addTreeListener(TreeListener listener) {
		if (tree) {
			return tree.addTreeListener(listener);
		} else {
			return editor.addTreeListener(listener);
		}
	}
	Item[] getItems() {
		if (tree) {
			return array(tree.getItems());
		} else {
			return array(editor.getItems());
		}
	}
	Item[] getItems(Item itm) {
		if (auto b = cast(TreeItem)itm) return array(b.getItems());
		return array((cast(EventEditorItem)itm).getItems());
	}
	Item getItem(Item itm, int index) {
		if (auto b = cast(TreeItem)itm) return b.getItem(index);
		return (cast(EventEditorItem)itm).getItem(index);
	}
	bool getExpanded(Item itm) {
		if (auto b = cast(TreeItem)itm) return b.getExpanded();
		return (cast(EventEditorItem)itm).getExpanded();
	}
	void setExpanded(Item itm, bool expanded) {
		if (auto b = cast(TreeItem)itm) {
			b.setExpanded(expanded);
		} else {
			(cast(EventEditorItem)itm).setExpanded(expanded);
		}
	}
	Item getParentItem(Item itm) {
		if (auto b = cast(TreeItem)itm) return b.getParentItem();
		return (cast(EventEditorItem)itm).getParentItem();
	}
	Item getItem(ref TreeViewWrapper view, int index) {
		return getItem(index);
	}

	int indexOf(Item itm) {
		if (tree) {
			return tree.indexOf(cast(TreeItem)itm);
		} else {
			return editor.indexOf(cast(EventEditorItem)itm);
		}
	}
	int indexOf(Item itm, Item child) {
		if (auto b = cast(TreeItem)itm) return b.indexOf(cast(TreeItem)child);
		return (cast(EventEditorItem)itm).indexOf(cast(EventEditorItem)child);
	}

	Item topItem(Item itm) {
		if (auto b = cast(TreeItem)itm) return .topItem(b);
		auto c = cast(Content)itm.getData();
		if (c.parent) return new EventEditorItem(editor, c.parentStart);
		return itm;
	}

	void treeExpandedAll() {
		if (tree) {
			.treeExpandedAll(tree);
		} else {
			editor.expandAll();
		}
	}

	Rectangle getImageBounds(Item itm) {
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

	Item selectionM(int x, int y) {
		if (!_list.getDragDetect()) return null;
		auto c = _list.getContent(x, y);
		if (!c) return null;
		int index = _list.indexOf(c);
		if (x < _list._pos[index].x + 20) return null;
		auto ca = _list.getClientArea();
		if (ca.width - _comm.prop.var.etc.detailAreaWidth <= x) return null;
		return _list.getItem(new Point(x, y));
	}
	Item selectionK() {
		auto sels = _list.getSelection();
		if (sels.length) {
			return sels[0];
		}
		return null;
	}

	void end(Control ctrl) {
		assert (_edit !is null);
		_editEnd(_edit, ctrl);
		_tee = null;
		_edit = null;
		_editor = null;
		_oldIndex = -1;
	}

	void startEdit(Item itm) {
		if (_tee !is null && !_tee.isExit) _tee.enter();
		_editor = _createEditor(cast(EventEditorItem)itm);
		if (_editor) {
			_edit = cast(EventEditorItem)itm;
			_list.scroll(_list.indexOf(cast(Content)_edit.getData()));
			_tee = new EditEnd(_comm, _list, _editor, &end);
			layout();
			_tee.setFocus();
		}
	}
	void layout() {
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
		if (cast(Combo)_editor || cast(CCombo)_editor) {
			w = size.x;
		} else {
			auto ca = _list.getClientArea();
			w = ca.width - _comm.prop.var.etc.detailAreaWidth - pos.x - 20;
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
			Control delegate(EventEditorItem itm) createEditor = null) {
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
	void startEdit() {
		auto sels = _list.getSelection();
		if (sels.length == 1) {
			startEdit(sels[0]);
		}
	}
	bool isEditing() {
		return _tee !is null;
	}
}
