
module cwx.editor.gui.dwt.imagelistwindow;

import cwx.summary;
import cwx.utils;
import cwx.structs;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.materialselect;

import std.algorithm;
import std.conv;
import std.exception;
import std.path;

import org.eclipse.swt.all;

/// イメージの一覧を表示し、選択を促す。
class ImageListWindow(MtType Type) {
	private Props _prop;
	private Commons _comm;

	private Summary _summ;

	private Shell _shl;
	private ImageList _list;

	private void delegate(string) _selection;

	this (Props prop, Commons comm, Summary summ, Shell parent, void delegate(string) selection) {
		_prop = prop;
		_comm = comm;
		_summ = summ;
		_selection = selection;
		_shl = new Shell(parent, SWT.RESIZE | SWT.MODELESS);
		_shl.setSize(_prop.var.etc.imageListWidth, _prop.var.etc.imageListHeight);
		_shl.setLayout(new FillLayout);
		_shl.addDisposeListener(new Dispose);
		_list = new ImageList(_shl, SWT.NONE);
		static if (Type == MtType.CARD) {
			auto s = _prop.looks.cardSize;
			_list.init(s.width, s.height, &createImage);
			_list.mask = true;
		} else {
			_list.init(_prop.var.etc.bgImageSampleWidth, _prop.var.etc.bgImageSampleHeight, &createImage);
		}
		_list.addMouseListener(new MouseDown);
	}
	private class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			auto size = _shl.getSize();
			_prop.var.etc.imageListWidth = size.x;
			_prop.var.etc.imageListHeight = size.y;
		}
	}

	@property
	Shell shell() {return _shl;}
	@property
	ImageList widget() {return _list;}

	private ImageData createImage(string path, bool mask) {
		bool def;
		auto imgPath = _comm.skin.findPathF(path, defExt, defDir, _summ ? _summ.scenarioPath : "", def);
		return loadImage(imgPath, mask);
	}
	static if (Type == MtType.CARD) {
		@property
		private string defExt() {return _comm.skin.extImage;}
		@property
		private string defDir() {return _comm.skin.tableDir;}
	} else static if (Type == MtType.BG_IMG) {
		@property
		private string defExt() {return _comm.skin.extImage;}
		@property
		private string defDir() {return _comm.skin.tableDir;}
	}

	void images(string dir, string[] path) {
		_shl.setRedraw(false);
		scope (exit) _shl.setRedraw(true);

		_shl.setText(dir);
		_list.removeAll();
		_list.add(path);
	}
	@property
	void select(string path) {
		_list.select(path);
		_list.showSelection();
	}

	@property
	void mask(bool mask) {_list.mask = mask;}

	private class MouseDown : MouseAdapter {
		override void mouseDown(MouseEvent e) {
			if (1 != e.button) return;
			int i = _list.indexOf(e.x, e.y);
			if (-1 != i) {
				_selection(_list.path(i));
			}
			_shl.close();
			_shl.dispose();
		}
	}
}

class ImageList : Composite {
	private const SPACING = 10;
	private string[] _path;
	private ImageData[] _image;
	private CRect[] _bounds;
	private int _imgW, _imgH;
	private bool _mask;
	private int _sel = -1;
	private ImageData delegate(string path, bool mask) _createImage;

	this (Composite parent, int style) {
		super (parent, style | SWT.V_SCROLL | SWT.DOUBLE_BUFFERED);
		addControlListener(new Resize);
		addPaintListener(new Paint);
		addMouseMoveListener(new MouseMove);
		setForeground(getDisplay().getSystemColor(SWT.COLOR_LIST_FOREGROUND));
		setBackground(getDisplay().getSystemColor(SWT.COLOR_LIST_BACKGROUND));
	}
	void init(int imgW, int imgH, ImageData delegate(string path, bool mask) createImage) {
		_imgW = imgW;
		_imgH = imgH;
		_createImage = createImage;

		auto vs = getVerticalBar();
		vs.setIncrement(_imgH / 4);
	}
	private int calcCountPerLine() {
		auto ca = getClientArea();

		int w = SPACING + _imgW;
		int countPerLine = ca.width / w;
		if (ca.width % w < SPACING) countPerLine--;
		return max(1, countPerLine);
	}
	private void calcScrollParams() {
		auto ca = getClientArea();
		auto vs = getVerticalBar();
		vs.setPageIncrement(max(vs.getIncrement(), ca.height / 2));

		auto gc = new GC(this);
		scope (exit) gc.dispose();
		int fh = gc.getFontMetrics().getHeight();
		int h = SPACING + _imgH + fh;
		int countPerLine = calcCountPerLine();
		int row = _path.length / countPerLine;
		if (_path.length % countPerLine) row++;
		vs.setMinimum(0);
		vs.setMaximum(row * h + SPACING);
		vs.setThumb(ca.height);
		vs.addSelectionListener(new Redraw);
	}

	private class MouseMove : MouseMoveListener {
		override void mouseMove(MouseEvent e) {
			int i = indexOf(e.x, e.y);
			if (-1 == i) {
				setCursor(null);
				setToolTipText("");
			} else {
				setCursor(getDisplay().getSystemCursor(SWT.CURSOR_HAND));
				setToolTipText(_path[i]);
			}
		}
	}
	private class Redraw : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			redraw();
		}
	}
	private class Resize : ControlAdapter {
		override void controlResized(ControlEvent e) {
			calcScrollParams();
		}
	}
	private class Paint : PaintListener {
		override void paintControl(PaintEvent e) {
			onPaint(e);
		}
	}
	private void onPaint(PaintEvent e) {
		auto ca = getClientArea();
		int x = SPACING;
		int y = SPACING - getVerticalBar().getSelection();
		int fh = e.gc.getFontMetrics().getHeight();
		int dotw = e.gc.textExtent("...").x;
		foreach (i, ref imgData; _image) {
			if (ca.intersects(x, y, _imgW, fh + _imgH)) {
				int iw, ih;
				if (imgData) {
					iw = imgData.width;
					ih = imgData.height;
				} else {
					imgData = _createImage(_path[i], _mask);
					if (_imgW < imgData.width || _imgH < imgData.height) {
						real wr = cast(real) _imgW / imgData.width;
						real hr = cast(real) _imgH / imgData.height;
						iw = cast(int) (imgData.width * min(wr, hr));
						ih = cast(int) (imgData.height * min(wr, hr));
						imgData = imgData.scaledTo(iw, ih);
					} else {
						iw = imgData.width;
						ih = imgData.height;
					}
				}
				auto img = new Image(getDisplay(), imgData);
				scope (exit) img.dispose();
				string name = _path[i].baseName();
				int tw = e.gc.textExtent(name).x;
				if (tw > _imgW) {
					dstring dname = to!dstring(name);
					while (dname.length && tw + dotw > _imgW) {
						dname = dname[0 .. $ - 1];
						tw = e.gc.textExtent(to!string(dname)).x;
					}
					name = to!string(dname) ~ "...";
					tw = e.gc.textExtent(name).x;
				}
				e.gc.drawText(name, x, y);
				int ix = (_imgW - iw) / 2;
				int iy = (_imgH - ih) / 2;
				e.gc.drawImage(img, x + ix, y + fh + iy);
				if (i == _sel) {
					e.gc.drawRectangle(x - 2, y - 2, _imgW + 3, _imgH + fh + 3);
				}
			}
			_bounds[i].x = x;
			_bounds[i].y = y;
			_bounds[i].width = _imgW;
			_bounds[i].height = fh + _imgH;
			x += _imgW + SPACING;
			if (ca.width < x + _imgW + SPACING) {
				x = SPACING;
				y += fh + _imgH + SPACING;
			}
		}
	}

	@property
	const
	string path(size_t index) {
		return _path[index];
	}
	@property
	void select(string path) {
		if (path == "") {
			_sel = -1;
		}
		int i = countUntil(_path, path);
		if (-1 == i) return;
		_sel = i;
	}
	void showSelection() {
		if (-1 == _sel) return;
		auto vs = getVerticalBar();

		int countPerLine = calcCountPerLine();

		auto gc = new GC(this);
		scope (exit) gc.dispose();
		int fh = gc.getFontMetrics().getHeight();

		int h = SPACING + _imgH + fh;
		int y = _sel / countPerLine * h;
		if (y < vs.getSelection()) {
			vs.setSelection(y);
		} else if (vs.getSelection() + vs.getThumb() < y + h + SPACING) {
			vs.setSelection(y + h + SPACING - vs.getThumb());
		}
		redraw();
	}

	int indexOf(int x, int y) {
		auto vs = getVerticalBar();
		y += vs.getSelection();

		int countPerLine = calcCountPerLine();

		auto gc = new GC(this);
		scope (exit) gc.dispose();
		int fh = gc.getFontMetrics().getHeight();
		int h = SPACING + _imgH + fh;
		int w = SPACING + _imgW;
		int colp = x % w;
		if (colp <= SPACING) return -1;
		int rowp = y % h;
		if (rowp <= SPACING) return -1;
		if (countPerLine <= x / w) return -1;
		int index = y / h * countPerLine + x / w;
		return index < _path.length ? index : -1;
	}

	@property
	void mask(bool mask) {
		if (_mask == mask) return;
		_mask = mask;
		foreach (ref imgData; _image) {
			imgData = null;
		}
		redraw();
	}

	void add(string[] path) {
		_path ~= path;
		_image.length += path.length;
		_bounds.length += path.length;
		calcScrollParams();
		redraw();
	}
	void removeAll() {
		_path.length = 0;
		_image.length = 0;
		_bounds.length = 0;
		calcScrollParams();
		redraw();
	}
}
