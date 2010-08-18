
module cwx.editor.gui.dwt.customtable;

import std.compat;

import dwt.DWT;
import dwt.widgets.Event;
import dwt.widgets.Listener;
import dwt.widgets.Table;
import dwt.widgets.TableColumn;
import dwt.widgets.TableItem;
import dwt.custom.TableCursor;
import dwt.graphics.Image;

class TableSorter(DataT) {
	private TableColumn _col;
	private bool delegate(DataT, DataT) _cmp;
	private bool delegate(DataT, DataT) _revCmp;
	this(TableColumn col, bool delegate(DataT, DataT) cmp, bool delegate(DataT, DataT) revCmp = null) {
		_col = col;
		_cmp = cmp;
		_revCmp = revCmp;
		_col.addListener(DWT.Selection, new class Listener {
			override void handleEvent(Event e) {
				doSort;
			}
		});
	}
	private int __index() {
		foreach (i, c; _col.getParent.getColumns) {
			if (c is _col) {
				return i;
			}
		}
		assert (0);
	}
	private class RowData {
		Object data;
		string[] text;
		Image[] image;
		bool select;
		bool cursor;
		int opCmp(Object s) {
			return compC(this, cast(RowData) s) ? -1 : 1;
		}
	}
	private bool compC(RowData c1, RowData c2) {
		DataT a = cast(DataT) c1.data;
		DataT b = cast(DataT) c2.data;
		return _col.getParent.getSortDirection == DWT.UP
			? _cmp(a, b) : (_revCmp ? _revCmp(a, b) : _cmp(b, a));
	}
	void doSort(int dir) {
		auto tbl = _col.getParent;
		tbl.setSortDirection = dir;
		if (dir == DWT.NONE) return;
		auto itms = tbl.getItems;
		int count = tbl.getColumnCount;
		scope RowData[] arr;
		arr.length = itms.length;
		auto cursor = cast(TableCursor) tbl.getCursor;
		foreach (i, c; itms) {
			auto r = new RowData;
			for (int j = 0; j < count; j++) {
				string text = c.getText(j);
				r.text ~= text ? text : "";
				r.image ~= c.getImage(j);
			}
			r.data = c.getData;
			r.select = tbl.isSelected(i);
			r.cursor = cursor && _col is cursor.getRow;
			arr[i] = r;
		}
		arr.sort;
		for (int i = 0; i < itms.length; i++) {
			auto c = arr[i];
			auto row = tbl.getItem(i);
			row.setData = c.data;
			for (int j = 0; j < count; j++) {
				row.setImage(j, c.image[j]);
				row.setText(j, c.text[j]);
			}
			if (c.select) {
				tbl.select(i);
			} else {
				tbl.deselect(i);
			}
			if (c.cursor) {
				cursor.setSelection(i, cursor.getColumn);
			}
		}
		tbl.setSortColumn = _col;
	}
	TableColumn column() {
		return _col;
	}
	void doSortR() {
		auto tbl = _col.getParent;
		if (tbl.getSortColumn is _col && tbl.getSortDirection != DWT.NONE) {
			doSort(tbl.getSortDirection);
		}
	}
	void doSort() {
		auto tbl = _col.getParent;
		if (tbl.getSortColumn !is _col
				|| tbl.getSortDirection == DWT.NONE || tbl.getSortDirection == DWT.DOWN) {
			doSort(DWT.UP);
		} else {
			doSort(DWT.DOWN);
		}
	}
}

class FullTableColumn {
	private TableColumn _column;
	private int _packWidth = 0;
	private Listener _rl;
	this(Table tbl, int style) {
		_column = new TableColumn(tbl, style);
		_column.setResizable = false;
		_rl = new RL;
		tbl.addListener(DWT.Resize, _rl);
	}
	TableColumn column() {
		return _column;
	}
	private bool _ed = false;
	private void __resize() {
		auto tbl = _column.getParent;
		auto trim = tbl.computeTrim(DWT.DEFAULT, DWT.DEFAULT, DWT.DEFAULT, DWT.DEFAULT);
		int width = tbl.getSize.x;
		foreach (c; tbl.getColumns) {
			if (c !is this) {
				width -= c.getWidth;
			}
		}
		width += trim.x;
		width -= trim.width;
		_column.setWidth = _packWidth > width ? _packWidth : width;
		tbl.removeListener(DWT.Resize, _rl);
	}
	private class RL : Listener {
		override void handleEvent(Event e) {
			__resize;
		}
	}
}
