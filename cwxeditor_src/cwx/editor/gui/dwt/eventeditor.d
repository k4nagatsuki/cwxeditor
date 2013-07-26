
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

	EventEditor getParent() { return _parent; }

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

	void setExpanded(bool expanded) {
		auto c = cast(Content)getData();
		if (c.type == CType.START && _parent._expanded.get(c, true) != expanded) {
			_parent._expanded[c] = expanded;
			_parent.updatePos();
		}
	}
	bool getExpanded() {
		auto c = cast(Content)getData();
		return _parent._expanded.get(c, true);
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
	private Content _selected = null;
	/// yの順に整列した位置リスト。
	private PosInfo[] _pos;
	/// イベントコンテントをキーに位置を取るテーブル。
	private PosInfo[Content] _posTable;

	private Color _selectedColor = null;

	private Cursor _cursor = null;
	private bool _changeCursor = false;
	private bool _moveDetailLine = false;
	private int _detailAreaWidth = 200;
	private Image _warningImage = null;

	private Warning[] _warningRects;

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
		vbar.setSelection(0);
		vbar.setIncrement(1);
		.listener(this, SWT.Resize, &updateScrollBar);
		.listener(vbar, SWT.Selection, &redraw);

		setBackground(d.getSystemColor(SWT.COLOR_WHITE));
		auto color = new Color(d, new RGB(96, 96, 96));
		_selectedColor = new Color(d, new RGB(128, 191, 255));
		_warningImage = .warningImage(_comm.prop, d);
		setForeground(color);
		.listener(this, SWT.Dispose, {
			_selectedColor.dispose();
			color.dispose();
			_warningImage.dispose();
		});
		.listener(this, SWT.Paint, &onPaint);
		.listener(this, SWT.MouseWheel, &onMouseWheel);
		.listener(this, SWT.Traverse, &onTraverse);
		.listener(this, SWT.MouseDown, &onMouseDown);
		.listener(this, SWT.MouseUp, &onMouseUp);
		.listener(this, SWT.MouseMove, &onMouseMove);
		.listener(this, SWT.MouseDoubleClick, &onMouseDoubleClick);
		.listener(this, SWT.KeyDown, &onKeyDown);
		.listener(this, SWT.Resize, &onResize);
		updatePos();
	}

	void showSelection() {
		if (!_selected) return;
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

	private void updatePos() {
		int x = 0;
		int y = 0;
		_pos = [];
		_posTable = null;
		bool[Content] expanded2;
		void recurse(int x, Content c) {
			auto type = c.type;
			_pos ~= PosInfo(x, y, c);
			_posTable[c] = PosInfo(x, y, c);
			y += _lineHeight;
			if (type == CType.START && c.next.length && !_expanded.get(c, true)) {
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
		foreach (i, start; _et.starts) {
			recurse(x, start);
		}
		_expanded = expanded2;
		_posTable.rehash();
		while (_selected && _selected !in _posTable) {
			_selected = _selected.parent;
		}
		updateScrollBar();
		redraw();
	}
	private void updateScrollBar() {
		auto ca = getClientArea();
		auto vbar = getVerticalBar();
		vbar.setThumb(ca.height / _lineHeight);
		vbar.setPageIncrement(ca.height / _lineHeight / 2);
		vbar.setMaximum(_pos.length);
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
			if (toolTip == "" && ca.width - _detailAreaWidth <= p.x) {
				int index = getVerticalBar().getSelection() + (p.y / _lineHeight);
				if (0 <= index && index < _pos.length) {
					auto pos = _pos[index];
					auto c = pos.content;
					toolTip = .contentText(_comm, c);
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
		auto c = cast(Content)getData();
		auto items = new EventEditorItem[_et.starts.length];
		foreach (i; 0 .. _et.starts.length) {
			items[i] = getItem(i);
		}
		return items;
	}
	int getItemCount() { return _et.starts.length; }

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
	int indexOf(EventEditorItem itm) {
		return .cCountUntil(_et.starts, cast(Content)itm.getData());
	}
	EventEditorItem getTopItem() {
		if(_selected) {
			auto vbar = getVerticalBar();
			return getItem(vbar.getSelection());
		}
		return null;
	}
	void setTopItem(EventEditorItem itm) {
		if (itm) {
			auto vbar = getVerticalBar();
			vbar.setSelection(indexOf(itm));
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

	private void onKeyDown(Event e) {
		if (!_pos.length) return;
		switch (e.keyCode) {
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
		case SWT.ARROW_RIGHT:
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
		if (e.button == 1) {
			setFocus();
			if (_changeCursor) {
				_moveDetailLine = true;
			} else {
				auto sel = getContent(e.x, e.y);
				if (sel) _selected = sel;
				showSelection();
				callSelectChanged();
				redraw();
			}
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
			int w = _detailAreaWidth;
			_detailAreaWidth = ca.width - e.x;
			_detailAreaWidth = .min(_detailAreaWidth, ca.width - _imageWidth);
			_detailAreaWidth = .max(_detailAreaWidth, _imageWidth);
			w = .max(w, _detailAreaWidth);
			redraw();
		} else {
			auto linePos = ca.width - _detailAreaWidth;
			if (linePos - 10 <= e.x && e.x < linePos + 10) {
				if (!_changeCursor) {
					auto d = getDisplay();
					_cursor = getCursor();
					_changeCursor = true;
					setCursor(d.getSystemCursor(SWT.CURSOR_SIZEWE));
				}
			} else if (_changeCursor) {
				setCursor(_cursor);
				_cursor = null;
				_changeCursor = false;
			}
		}
		updateToolTip();
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
		_detailAreaWidth = .min(_detailAreaWidth, ca.width - _imageWidth);
		_detailAreaWidth = .max(_detailAreaWidth, _imageWidth);
	}

	private void onMouseWheel(Event e) {
		auto vbar = getVerticalBar();
		auto val = vbar.getSelection();
		if (e.count < 0) {
			val += 1;
		} else if (0 < e.count) {
			val -= 1;
		}
		vbar.setSelection(val);
	}

	private void onPaint(Event e) {
		if (!_pos.length) return;
		auto hw = _imageWidth / 2;
		auto hh = _lineHeight / 2;
		auto ca = getClientArea();

		auto vbar = getVerticalBar();
		int index = vbar.getSelection();
		auto poss = _pos[index .. .min($, index + ca.height / _lineHeight + 1)];
		int sy = index * _lineHeight;

		auto d = getDisplay();
		if (_selected) {
			// 選択中マーク
			auto pos = _posTable[_selected];
			e.gc.setBackground(_selectedColor);
			scope (exit) e.gc.setBackground(getBackground());
			e.gc.fillRectangle(e.x, pos.y - sy, e.width, _lineHeight);
		}

		// イベントコンテントを結ぶ線
		foreach (i, ref pos; poss) {
			auto c = pos.content;
			if (c.type == CType.START) {
				if (0 < i && _comm.prop.var.etc.drawContentTreeLine) {
					e.gc.drawLine(e.x, pos.y - sy, e.x + e.width, pos.y - sy);
				}
			} else if (c.parent) {
				auto pPos = _posTable[c.parent];
				if (pPos.x == pos.x) {
					e.gc.drawLine(pos.x + hw, pPos.y + hh - sy, pos.x + hw, pos.y + hh - sy);
				} else {
					e.gc.drawLine(pPos.x + hw, pPos.y + hh - sy, pPos.x + hw, pos.y + hh - sy);
					e.gc.drawLine(pPos.x + hw, pos.y + hh - sy, pos.x + hw, pos.y + hh - sy);
				}
			}
		}

		// イベントコンテントのアイコンとテキスト
		auto ucExtent = e.gc.textExtent(_comm.prop.msgs.startUseCount);
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
				int tx = ca.width - _detailAreaWidth - 4 - tw;
				e.gc.setForeground(getForeground());
				e.gc.drawString(_comm.prop.msgs.startUseCount, tx - ucExtent.x - 4, pos.y - sy, true);
				e.gc.setForeground(d.getSystemColor(SWT.COLOR_BLACK));
				e.gc.drawString(uc, tx, pos.y - sy, true);
			}
			if (c.type == CType.START && !_expanded.get(c, true)) {
				// スタートを畳んでいる時のマーク
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
		e.gc.drawLine(ca.width - _detailAreaWidth, e.y, ca.width - _detailAreaWidth, e.y + e.height);
		e.gc.setAlpha(192);
		e.gc.fillRectangle(ca.width - _detailAreaWidth, e.y, _detailAreaWidth, e.height);
		e.gc.setAlpha(255);

		_warningRects = [];
		foreach (ref pos; poss) {
			// イベントコンテント内容
			auto c = pos.content;
			auto s = .contentText(_comm, c);
			int x = ca.width - _detailAreaWidth + 2;
			auto image = _comm.prop.images.content(c.type);
			e.gc.setAlpha(128);
			e.gc.drawImage(image, x, pos.y + _imgPos - sy);
			e.gc.setAlpha(255);
			e.gc.drawText(s, x + 18, pos.y - sy, true);

			// 警告
			auto warnings = .warnings(_comm.prop.parent, _comm.skin, _summ, c, _comm.prop.var.etc.targetVersion);
			if (warnings.length) {
				int ww = _comm.prop.var.etc.warningImageWidth;
				int wix = .max(0, ca.width - _detailAreaWidth - ww);
				int wiw = ca.width - _detailAreaWidth - wix;
				if (wiw <= 0) continue;
				e.gc.drawImage(_warningImage, 0, 0, ww, 1, wix, pos.y - sy, wiw, _lineHeight);
				e.gc.drawImage(_comm.prop.images.warning, wix + wiw - _imageWidth - 4, pos.y + _imgPos - sy);
				auto rect = new Rectangle(ca.x, pos.y - sy, ca.width - _detailAreaWidth, _lineHeight);
				_warningRects ~= Warning(rect, warnings);
			}
		}
	}
}
