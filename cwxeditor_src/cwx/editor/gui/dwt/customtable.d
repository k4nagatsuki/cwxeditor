
module cwx.editor.gui.dwt.customtable;

import cwx.utils : debugln, cdebugln;

import org.eclipse.swt.all;

class TableSorter(DataT) {
	private TableColumn _col;
	private bool delegate(in DataT, in DataT) _cmp;
	private bool delegate(in DataT, in DataT) _revCmp;
	this(TableColumn col, bool delegate(in DataT, in DataT) cmp, bool delegate(in DataT, in DataT) revCmp = null) {
		_col = col;
		_cmp = cmp;
		_revCmp = revCmp;
		_col.addListener(SWT.Selection, new class Listener {
			override void handleEvent(Event e) {
				doSort();
			}
		});
	}
	private int __index() {
		foreach (i, c; _col.getParent().getColumns()) {
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
		return _col.getParent().getSortDirection() == SWT.UP
			? _cmp(a, b) : (_revCmp ? _revCmp(a, b) : _cmp(b, a));
	}
	void doSort(int dir) {
		auto tbl = _col.getParent();
		tbl.setSortDirection(dir);
		if (dir == SWT.NONE) return;
		auto itms = tbl.getItems();
		int count = tbl.getColumnCount();
		scope RowData[] arr;
		arr.length = itms.length;
		auto cursor = cast(TableCursor) tbl.getCursor();
		foreach (i, c; itms) {
			auto r = new RowData;
			for (int j = 0; j < count; j++) {
				string text = c.getText(j);
				r.text ~= text ? text : "";
				r.image ~= c.getImage(j);
			}
			r.data = c.getData();
			r.select = tbl.isSelected(i);
			r.cursor = cursor && _col is cursor.getRow();
			arr[i] = r;
		}
		arr.sort;
		for (int i = 0; i < itms.length; i++) {
			auto c = arr[i];
			auto row = tbl.getItem(i);
			row.setData(c.data);
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
				cursor.setSelection(i, cursor.getColumn());
			}
		}
		tbl.setSortColumn(_col);
	}
	@property
	TableColumn column() {
		return _col;
	}
	void doSortR() {
		auto tbl = _col.getParent();
		if (tbl.getSortColumn() is _col && tbl.getSortDirection() != SWT.NONE) {
			doSort(tbl.getSortDirection());
		}
	}
	void doSort() {
		auto tbl = _col.getParent();
		if (tbl.getSortColumn() !is _col
				|| tbl.getSortDirection() == SWT.NONE || tbl.getSortDirection() == SWT.DOWN) {
			doSort(SWT.UP);
		} else {
			doSort(SWT.DOWN);
		}
	}
}

class FullTableColumn {
	private TableColumn _column;
	private int _packWidth = 50;
	private Listener _rl;
	this (Table tbl, int style) {
		_column = new TableColumn(tbl, style);
		_column.setResizable(false);
		_rl = new RL;
		tbl.addListener(SWT.Resize, _rl);
	}
	@property
	TableColumn column() {
		return _column;
	}
	private bool _ed = false;
	private void resize() {
		auto tbl = _column.getParent();
		auto trim = tbl.computeTrim(SWT.DEFAULT, SWT.DEFAULT, SWT.DEFAULT, SWT.DEFAULT);
		int width = tbl.getSize().x;
		if (1 < tbl.getColumnCount()) {
			foreach (c; tbl.getColumns()) {
				if (c !is _column) {
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
		override void handleEvent(Event e) {
			resize();
		}
	}
}
