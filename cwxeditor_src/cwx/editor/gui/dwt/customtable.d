
module cwx.editor.gui.dwt.customtable;

import cwx.perf;
import cwx.structs;
import cwx.utils : debugln, cdebugln;

import cwx.editor.gui.dwt.dutils : dwtData;

import core.thread;

import std.algorithm;
import std.datetime;

import org.eclipse.swt.all;

import java.lang.all;

immutable lineColor = CRGB(64, 160, 222, 255);
immutable fillColor = CRGB(64, 160, 222, 96);

/// WindowsExplorerのように範囲選択が可能なテーブルを生成する。
Table rangeSelectableTable(Composite parent, int style) { mixin(S_TRACE);
	if (!(style & SWT.MULTI)) return new Table(parent, style);
	version (Windows) {
		import org.eclipse.swt.internal.win32.OS;
		static class RSTable : Table {
			private GC _gc;
			private bool _down = false;

			this (Composite parent, int style) { mixin(S_TRACE);
				super (parent, style);
				_gc = new GC(this);
				addDisposeListener(new class DisposeListener {
					override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
						_gc.dispose();
					}
				});
			}

			protected
			override
			LRESULT WM_MOUSEMOVE(WPARAM wParam, LPARAM lParam) { mixin(S_TRACE);
				_down = false;
				return super.WM_MOUSEMOVE(wParam, lParam);
			}

			protected
			override
			LRESULT WM_LBUTTONUP(WPARAM wParam, LPARAM lParam) { mixin(S_TRACE);
				if (_down) { mixin(S_TRACE);
					super.sendMouseDownEvent(SWT.MouseDown, 1, OS.WM_LBUTTONDOWN, wParam, lParam);
				}
				_down = false;
				return super.WM_LBUTTONUP(wParam, lParam);
			}

			protected
			override
			LRESULT sendMouseDownEvent(int type, int button, int msg, WPARAM wParam, LPARAM lParam) { mixin(S_TRACE);
				if (_down || type !is SWT.MouseDown || button != 1 || msg !is OS.WM_LBUTTONDOWN) { mixin(S_TRACE);
					return super.sendMouseDownEvent(type, button, msg, wParam, lParam);
				}
				auto x = OS.GET_X_LPARAM(lParam);
				auto y = OS.GET_Y_LPARAM(lParam);
				auto itm = getItem(new Point(x, y));
				if (!itm) return super.sendMouseDownEvent(type, button, msg, wParam, lParam);
				auto index = indexOf(itm);
				if (isSelected(index)) return super.sendMouseDownEvent(type, button, msg, wParam, lParam);
				foreach (i; 0 .. getColumnCount()) { mixin(S_TRACE);
					// カーソル下のアイテムのアイコンかテキストをクリックした場合はそのアイテムを選択する
					if (itm.getImageBounds(i).contains(x, y)) { mixin(S_TRACE);
						return super.sendMouseDownEvent(type, button, msg, wParam, lParam);
					}
					auto tRect = itm.getTextBounds(i);
					// 幅の値がセル幅一杯のものになってしまうので再測定
					tRect.width = _gc.textExtent(itm.getText(i)).x;
					if (tRect.contains(x, y)) { mixin(S_TRACE);
						return super.sendMouseDownEvent(type, button, msg, wParam, lParam);
					}
				}
				OS.SetFocus(handle);
				if (!getDisplay().captureChanged && OS.GetCapture() !is handle) {
					OS.SetCapture(handle);
				}
				// 範囲選択開始
				_down = true;
				LVITEM lvItem;
				lvItem.state = OS.LVNI_FOCUSED;
				lvItem.stateMask = OS.LVNI_FOCUSED;
				OS.SendMessage(handle, OS.LVM_SETITEMSTATE, index, &lvItem);
				sendMouseEvent(SWT.MouseDown, 1, handle, OS.WM_LBUTTONDOWN, wParam, lParam);
				return LRESULT.ZERO;
			}
		}
		auto table = new RSTable(parent, style);
	} else {
		auto table = new Table(parent, style);
	}
	ulong frame = 0;
	ulong lastVFrame = 0;
	ulong lastHFrame = 0;
	auto d = table.getDisplay();
	auto timerRunning = false;
	core.thread.Thread timer = null;
	Point startPos = null;
	Point endPos = null;
	int stateMask = 0;
	bool[int] selected;
	int rangeFrom = -1;
	int rangeTo = -1;
	int vBarValue = 0;
	int hBarValue = 0;

	void notifySelection() { mixin(S_TRACE);
		auto se = new Event;
		se.type = SWT.Selection;
		se.widget = table;
		se.time = cast(int)(0xFFFFFFFFL & Clock.currStdTime());
		se.stateMask = stateMask;
		se.doit = true;
		table.notifyListeners(SWT.Selection, se);
	}
	void updateRangeIndices() { mixin(S_TRACE);
		auto ctrl = (stateMask & SWT.CTRL) != 0;
		auto shift = (stateMask & SWT.SHIFT) != 0;
		if (!ctrl) { mixin(S_TRACE);
			selected = null;
			.each!(i => selected[i] = true)(table.getSelectionIndices());
		}
		auto oldSels = table.getSelectionIndices();
		auto left = .min(startPos.x, endPos.x);
		auto top = .min(startPos.y, endPos.y);
		auto right = .max(startPos.x, endPos.x);
		auto bottom = .max(startPos.y, endPos.y);
		auto hbar = table.getHorizontalBar();
		if (hbar) { mixin(S_TRACE);
			auto hPos = hbar.getSelection() * hbar.getIncrement();
			left += hPos;
			right += hPos;
		}
		auto vbar = table.getVerticalBar();
		if (vbar) { mixin(S_TRACE);
			auto vPos = vbar.getSelection() * table.getItemHeight();
			top += vPos;
			bottom += vPos;
		}
		if (table.getHeaderVisible()) { mixin(S_TRACE);
			top -= table.getHeaderHeight();
			bottom -= table.getHeaderHeight();
		}
		auto oldFrom = rangeFrom;
		auto oldTo = rangeTo;

		if (right < 0) { mixin(S_TRACE);
			rangeFrom = -1;
			rangeTo = -1;
		} else if (.reduce!((a, b) => a + b)(.map!(col => col.getWidth())(table.getColumns())) <= left) { mixin(S_TRACE);
			rangeFrom = -1;
			rangeTo = -1;
		} else { mixin(S_TRACE);
			rangeFrom = top / table.getItemHeight();
			rangeTo = bottom / table.getItemHeight();
			if (rangeTo < 0 || table.getItemCount() <= rangeFrom) { mixin(S_TRACE);
				rangeFrom = -1;
				rangeTo = -1;
			} else { mixin(S_TRACE); mixin(S_TRACE);
				rangeFrom = .max(rangeFrom, 0);
				rangeTo = .min(rangeTo, table.getItemCount() - 1);
			}
		}

		void updateSelection(int index) { mixin(S_TRACE);
			auto inRange = rangeFrom != -1 && rangeFrom <= index && index <= rangeTo;
			auto sel = false;
			if (ctrl) { mixin(S_TRACE);
				if (index in selected) { mixin(S_TRACE);
					sel = !inRange;
				} else { mixin(S_TRACE);
					sel = true;
				}
			} else { mixin(S_TRACE);
				sel = inRange;
			}
			if (sel) { mixin(S_TRACE);
				table.select(index);
			} else { mixin(S_TRACE);
				table.deselect(index);
			}
		}

		if (rangeFrom != -1 && oldFrom != -1) { mixin(S_TRACE);
			foreach (i; .min(oldFrom, rangeFrom) .. .max(oldTo, rangeTo) + 1) { mixin(S_TRACE);
				if (i < .max(oldFrom, rangeFrom) || .min(oldTo, rangeTo) < i) { mixin(S_TRACE);
					updateSelection(i);
				}
			}
		} else if (rangeFrom != -1) { mixin(S_TRACE);
			foreach (i; rangeFrom .. rangeTo + 1) { mixin(S_TRACE);
				updateSelection(i);
			}
		} else if (oldFrom != -1) { mixin(S_TRACE);
			foreach (i; oldFrom .. oldTo + 1) { mixin(S_TRACE);
				updateSelection(i);
			}
		}
		if (oldSels != table.getSelectionIndices()) { mixin(S_TRACE);
			notifySelection();
		}
	}
	void mouseRelease() { mixin(S_TRACE);
		if (!startPos) return;
		auto sx = startPos.x;
		auto sy = startPos.y;
		startPos = null;
		if (!endPos) return;
		assert (timer !is null);
		auto ex = endPos.x;
		auto ey = endPos.y;
		endPos = null;
		auto left = .min(sx, ex);
		auto top = .min(sy, ey);
		auto right = .max(sx, ex);
		auto bottom = .max(sy, ey);
		table.redraw(left, top, right - left + 1, bottom - top + 1, false);
		timerRunning = false;
		timer.join();
		timer = null;
		stateMask = 0;
		selected = null;
		rangeFrom = -1;
		rangeTo = -1;
	}
	void updateVerticalBar() { mixin(S_TRACE);
		auto bar = table.getVerticalBar();
		if (!bar) return;
		auto newPos = bar.getSelection();
		if (newPos == vBarValue) return;
		if (startPos) { mixin(S_TRACE);
			startPos.y += (vBarValue - newPos) * table.getItemHeight();
			updateRangeIndices();
			table.redraw();
		}
		vBarValue = newPos;
	}
	void updateHorizontalBar() {
		auto bar = table.getHorizontalBar();
		if (!bar) return;
		auto newPos = bar.getSelection();
		if (newPos == hBarValue) return;
		if (startPos) { mixin(S_TRACE);
			startPos.x += vBarValue - newPos;
			updateRangeIndices();
			table.redraw();
		}
		hBarValue = newPos;
	}
	auto doAutoScroll = new class Runnable {
		/// 縦スクロール位置を調節し、調節が完了した場合はtrueを返す。
		private bool vertical(ulong pFrame) { mixin(S_TRACE);
			auto top = 0;
			if (table.getHeaderVisible()) top += table.getHeaderHeight();
			auto ti = table.getTopIndex();
			if (endPos.y < top) { mixin(S_TRACE);
				if (ti <= 0) return true;
				auto count = (top - endPos.y) * 2;
				auto sIndex = cast(int)(pFrame / 60.0 * count);
				if (sIndex <= 0) return false;
				table.setTopIndex(.max(0, ti - sIndex));
				updateVerticalBar();
			} else { mixin(S_TRACE);
				auto ca = table.getClientArea();
				auto hc = (ca.height - top) / table.getItemHeight();
				auto bi = ti + hc;
				if (table.getItemCount() <= bi) return true;
				if (ca.height <= endPos.y) { mixin(S_TRACE);
					auto count = (endPos.y - ca.height + 1) * 2;
					auto sIndex = cast(int)(pFrame / 60.0 * count);
					if (sIndex <= 0) return false;
					table.setTopIndex(.min(table.getItemCount() - 1, ti + sIndex));
					updateVerticalBar();
				}
			}
			return true;
		}
		private bool horizontal(ulong pFrame) { mixin(S_TRACE);
			version (Windows) {
				auto hbar = table.getHorizontalBar();
				if (!hbar) return true;
				auto pos = hbar.getSelection();
				int sIndex = 0;
				if (endPos.x < 0) { mixin(S_TRACE);
					if (pos <= 0) return true;
					auto count = endPos.x;
					sIndex = cast(int)(pFrame * 1.0 * count);
					if (0 <= sIndex) return false;
				} else { mixin(S_TRACE);
					auto ca = table.getClientArea();
					if (endPos.x < ca.width) return true;
					if (pos + 1 < hbar.getMaximum() - hbar.getThumb()) { mixin(S_TRACE);
						auto count = endPos.x - ca.width + 1;
						sIndex = cast(int)(pFrame * 1.0 * count);
					}
					if (sIndex <= 0) return false;
				}
				if (sIndex == 0) return false;
				OS.SendMessage(table.handle, OS.LVM_SCROLL, sIndex, 0);
				updateHorizontalBar();
				return true;
			} else {
				return true;
			}
		}
		override void run() { mixin(S_TRACE);
			if (frame < lastVFrame || frame < lastHFrame || table.isDisposed() || !endPos || !table.getItemCount()) { mixin(S_TRACE);
				lastVFrame = frame;
				lastHFrame = frame;
				return;
			}
			auto pVFrame = frame - lastVFrame;
			auto pHFrame = frame - lastHFrame;
			if (0 < pVFrame && vertical(pVFrame)) lastVFrame = frame;
			if (0 < pHFrame && horizontal(pHFrame)) lastHFrame = frame;
		}
	};
	void autoScroll() { mixin(S_TRACE);
		while (timerRunning) { mixin(S_TRACE);
			d.asyncExec(doAutoScroll);
			core.thread.Thread.sleep(dur!"msecs"(16));
			frame++;
		}
	}
	table.addMouseListener(new class MouseAdapter {
		override void mouseUp(MouseEvent e) { mixin(S_TRACE);
			if (e.button == 1) { mixin(S_TRACE);
				auto rangeSelection = endPos !is null;
				mouseRelease();
				auto ctrl = (e.stateMask & SWT.CTRL) != 0;
				auto shift = (e.stateMask & SWT.SHIFT) != 0;
				if (!ctrl && !shift && !rangeSelection) { mixin(S_TRACE);
					auto itm = table.getItem(new Point(e.x, e.y));
					auto indices = table.getSelectionIndices();
					if (itm) { mixin(S_TRACE);
						table.setSelection([itm]);
					} else { mixin(S_TRACE);
						table.deselectAll();
					}
					if (indices != table.getSelectionIndices()) { mixin(S_TRACE);
						notifySelection();
					}
				}
			}
		}
		override void mouseDown(MouseEvent e) { mixin(S_TRACE);
			startPos = new Point(e.x, e.y);
		}
	});
	table.addDragDetectListener(new class DragDetectListener {
		override void dragDetected(DragDetectEvent e) { mixin(S_TRACE);
			mouseRelease();
		}
	});
	table.addFocusListener(new class FocusAdapter {
		override void focusLost(FocusEvent e) { mixin(S_TRACE);
			mouseRelease();
		}
	});
	table.addMouseMoveListener(new class MouseMoveListener {
		override void mouseMove(MouseEvent e) { mixin(S_TRACE);
			if (!startPos) return;

			void redraw() { mixin(S_TRACE);
				auto left = .min(startPos.x, endPos.x);
				auto top = .min(startPos.y, endPos.y);
				auto right = .max(startPos.x, endPos.x);
				auto bottom = .max(startPos.y, endPos.y);
				table.redraw(left, top, right - left + 1, bottom - top + 1, false);
			}
			if (endPos) { mixin(S_TRACE);
				if (endPos.x == e.x && endPos.y == e.y) return;
				redraw();
				endPos.x = e.x;
				endPos.y = e.y;
				stateMask = e.stateMask;
				updateRangeIndices();
			} else { mixin(S_TRACE);
				assert (timer is null);
				auto itm = table.getItem(startPos);
				if (itm && table.isSelected(table.indexOf(itm)) && table.getListeners(SWT.DragDetect).length) { mixin(S_TRACE);
					// ドラッグが開始される場合
					mouseRelease();
					return;
				}

				endPos = new Point(e.x, e.y);
				timer = new core.thread.Thread(&autoScroll);
				timerRunning = true;
				frame = 0;
				lastVFrame = 0;
				lastHFrame = 0;
				stateMask = e.stateMask;
				auto ctrl = (stateMask & SWT.CTRL) != 0;
				auto shift = (stateMask & SWT.SHIFT) != 0;
				if (!ctrl && !shift) table.deselectAll();
				selected = null;
				.each!(i => selected[i] = true)(table.getSelectionIndices());
				updateRangeIndices();
				timer.start();
			}
			redraw();
		}
	});
	table.addKeyListener(new class KeyAdapter {
		private void common(KeyEvent e) { mixin(S_TRACE);
			stateMask = e.stateMask;
		}
		override void keyPressed(KeyEvent e) { mixin(S_TRACE);
			common(e);
		}
		override void keyReleased(KeyEvent e) { mixin(S_TRACE);
			common(e);
		}
	});
	table.addPaintListener(new class PaintListener {
		override void paintControl(PaintEvent e) { mixin(S_TRACE);
			if (!startPos) return;
			if (!endPos) return;
			auto left = .min(startPos.x, endPos.x);
			auto top = .min(startPos.y, endPos.y);
			auto right = .max(startPos.x, endPos.x);
			auto bottom = .max(startPos.y, endPos.y);

			int lineAlpha;
			auto lineRGB = .dwtData(.lineColor, lineAlpha);
			int fillAlpha;
			auto fillRGB = .dwtData(.fillColor, fillAlpha);

			auto fillColor = new Color(d, fillRGB);
			scope (exit) fillColor.dispose();
			e.gc.setBackground(fillColor);
			e.gc.setAlpha(fillAlpha);
			e.gc.fillRectangle(left, top, right - left, bottom - top);
			auto lineColor = new Color(d, lineRGB);
			scope (exit) lineColor.dispose();
			e.gc.setForeground(lineColor);
			e.gc.setAlpha(lineAlpha);
			e.gc.drawRectangle(left, top, right - left, bottom - top);
		}
	});
	auto hBar = table.getHorizontalBar();
	if (hBar) { mixin(S_TRACE);
		hBarValue = hBar.getSelection();
		hBar.addSelectionListener(new class SelectionAdapter {
			override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
				updateHorizontalBar();
			}
		});
	}
	auto vBar = table.getVerticalBar();
	if (vBar) { mixin(S_TRACE);
		vBarValue = vBar.getSelection();
		vBar.addSelectionListener(new class SelectionAdapter {
			override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
				updateVerticalBar();
			}
		});
	}
	return table;
}

class TableSorter(DataT) {
	void delegate()[] sortedEvent;
	private TableColumn _col;
	private bool delegate(in DataT, in DataT) _cmp;
	private bool delegate(in DataT, in DataT) _revCmp;
	this(TableColumn col, bool delegate(in DataT, in DataT) cmp, bool delegate(in DataT, in DataT) revCmp = null) { mixin(S_TRACE);
		_col = col;
		_cmp = cmp;
		_revCmp = revCmp;
		_col.addListener(SWT.Selection, new class Listener {
			override void handleEvent(Event e) { mixin(S_TRACE);
				doSort();
			}
		});
	}
	private class RowData {
		Object data;
		string[] text;
		Image[] image;
		bool select;
		bool cursor;
		override
		int opCmp(Object s) { mixin(S_TRACE);
			return compC(this, cast(RowData) s) ? -1 : 1;
		}
	}
	private bool compC(in RowData c1, in RowData c2) { mixin(S_TRACE);
		auto a = cast(const DataT) c1.data;
		auto b = cast(const DataT) c2.data;
		return _col.getParent().getSortDirection() == SWT.UP
			? _cmp(a, b) : (_revCmp ? _revCmp(a, b) : _cmp(b, a));
	}
	void doSort(int dir) { mixin(S_TRACE);
		auto tbl = _col.getParent();
		tbl.setSortDirection(dir);
		if (dir == SWT.NONE) return;
		auto itms = tbl.getItems();
		int count = tbl.getColumnCount();
		scope RowData[] arr;
		arr.length = itms.length;
		auto cursor = cast(TableCursor) tbl.getCursor();
		foreach (i, c; itms) { mixin(S_TRACE);
			auto r = new RowData;
			for (int j = 0; j < count; j++) { mixin(S_TRACE);
				string text = c.getText(j);
				r.text ~= text ? text : "";
				r.image ~= c.getImage(j);
			}
			r.data = c.getData();
			r.select = tbl.isSelected(cast(int)i);
			r.cursor = cursor && _col is cursor.getRow();
			arr[i] = r;
		}
		arr.sort;
		for (int i = 0; i < itms.length; i++) { mixin(S_TRACE);
			auto c = arr[i];
			auto row = tbl.getItem(i);
			row.setData(c.data);
			for (int j = 0; j < count; j++) { mixin(S_TRACE);
				row.setImage(j, c.image[j]);
				row.setText(j, c.text[j]);
			}
			if (c.select) { mixin(S_TRACE);
				tbl.select(i);
			} else { mixin(S_TRACE);
				tbl.deselect(i);
			}
			if (c.cursor) { mixin(S_TRACE);
				cursor.setSelection(i, cursor.getColumn());
			}
		}
		tbl.setSortColumn(_col);
		foreach (dlg; sortedEvent) dlg();
	}
	@property
	TableColumn column() { mixin(S_TRACE);
		return _col;
	}
	void doSortR() { mixin(S_TRACE);
		auto tbl = _col.getParent();
		if (tbl.getSortColumn() is _col && tbl.getSortDirection() != SWT.NONE) { mixin(S_TRACE);
			doSort(tbl.getSortDirection());
		}
	}
	void doSort() { mixin(S_TRACE);
		auto tbl = _col.getParent();
		if (tbl.getSortColumn() !is _col
				|| tbl.getSortDirection() == SWT.NONE || tbl.getSortDirection() == SWT.DOWN) { mixin(S_TRACE);
			doSort(SWT.UP);
		} else { mixin(S_TRACE);
			doSort(SWT.DOWN);
		}
	}
}

class FullTableColumn {
	private TableColumn _column;
	private int _packWidth = 50;
	private Listener _rl;
	this (Table tbl, int style) { mixin(S_TRACE);
		_column = new TableColumn(tbl, style);
		_column.setResizable(false);
		_rl = new RL;
		tbl.addListener(SWT.Resize, _rl);
		_column.addListener(SWT.Dispose, new class Listener {
			override void handleEvent(Event e) { mixin(S_TRACE);
				tbl.removeListener(SWT.Resize, _rl);
			}
		});
		if (tbl.isVisible()) { mixin(S_TRACE);
			resize();
		}
	}
	@property
	TableColumn column() { mixin(S_TRACE);
		return _column;
	}
	private bool _ed = false;
	private void resize() { mixin(S_TRACE);
		auto tbl = _column.getParent();
		auto trim = tbl.computeTrim(SWT.DEFAULT, SWT.DEFAULT, SWT.DEFAULT, SWT.DEFAULT);
		int width = tbl.getSize().x;
		if (1 < tbl.getColumnCount()) { mixin(S_TRACE);
			foreach (c; tbl.getColumns()) { mixin(S_TRACE);
				if (c !is _column) { mixin(S_TRACE);
					width -= c.getWidth();
				}
			}
		}
		width += trim.x;
		width -= trim.width;
		_column.setWidth(_packWidth > width ? _packWidth : width);
		tbl.redraw();
	}
	private class RL : Listener {
		override void handleEvent(Event e) { mixin(S_TRACE);
			resize();
		}
	}
}

void upItem(Table table, int index) { mixin(S_TRACE);
	if (index - 1 < 0) return;
	table.setRedraw(false);
	scope (exit) table.setRedraw(true);
	auto itmTo = table.getItem(index - 1);

	auto toStyle = itmTo.getStyle();
	auto toData = itmTo.getData();
	auto toChecked = itmTo.getChecked();
	string[] toText;
	Image[] toImage;
	foreach (ci; 0 .. table.getColumnCount()) { mixin(S_TRACE);
		toText ~= itmTo.getText(ci);
		toImage ~= itmTo.getImage(ci);
	}
	itmTo.dispose();

	itmTo = new TableItem(table, toStyle, index);
	itmTo.setData(toData);
	itmTo.setChecked(toChecked);
	foreach (ci; 0 .. table.getColumnCount()) { mixin(S_TRACE);
		itmTo.setText(ci, toText[ci]);
		itmTo.setImage(ci, toImage[ci]);
	}
}

void downItem(Table table, int index) { mixin(S_TRACE);
	if (table.getItemCount() <= index + 1) return;
	table.setRedraw(false);
	scope (exit) table.setRedraw(true);
	auto itmTo = table.getItem(index + 1);

	auto toStyle = itmTo.getStyle();
	auto toData = itmTo.getData();
	auto toChecked = itmTo.getChecked();
	string[] toText;
	Image[] toImage;
	foreach (ci; 0 .. table.getColumnCount()) { mixin(S_TRACE);
		toText ~= itmTo.getText(ci);
		toImage ~= itmTo.getImage(ci);
	}
	itmTo.dispose();

	itmTo = new TableItem(table, toStyle, index);
	itmTo.setData(toData);
	itmTo.setChecked(toChecked);
	foreach (ci; 0 .. table.getColumnCount()) { mixin(S_TRACE);
		itmTo.setText(ci, toText[ci]);
		itmTo.setImage(ci, toImage[ci]);
	}
}
