
module cwx.editor.gui.dwt.customtable;

import cwx.perf;
import cwx.utils : debugln, cdebugln;

import org.eclipse.swt.all;

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
	private int __index() { mixin(S_TRACE);
		foreach (i, c; _col.getParent().getColumns()) { mixin(S_TRACE);
			if (c is _col) { mixin(S_TRACE);
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
			r.select = tbl.isSelected(i);
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
