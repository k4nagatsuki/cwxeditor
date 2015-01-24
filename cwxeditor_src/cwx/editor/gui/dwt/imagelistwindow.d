
module cwx.editor.gui.dwt.imagelistwindow;

import cwx.summary;
import cwx.utils;
import cwx.structs;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.materialselect;
import cwx.editor.gui.dwt.cardlist : cutText;

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

	this (Props prop, Commons comm, Summary summ, Shell parent, void delegate(string) selection, Control baseControl) { mixin(S_TRACE);
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
		} else { mixin(S_TRACE);
			_list.init(_prop.var.etc.bgImageSampleWidth, _prop.var.etc.bgImageSampleHeight, &createImage);
		}
		_list.addMouseListener(new MouseDown);

		auto d = parent.getDisplay();
		auto focusFilter = new class Listener {
			override void handleEvent(Event e) { mixin(S_TRACE);
				if (!baseControl.isVisible() && !shell.isDisposed()) { mixin(S_TRACE);
					shell.close();
					shell.dispose();
				}
			}
		};
		d.addFilter(SWT.FocusOut, focusFilter);
		d.addFilter(SWT.Selection, focusFilter);
		.listener(baseControl, SWT.Dispose, { mixin(S_TRACE);
			d.removeFilter(SWT.FocusOut, focusFilter);
			d.removeFilter(SWT.Selection, focusFilter);
		});
	}
	private class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			auto size = _shl.getSize();
			_prop.var.etc.imageListWidth = size.x;
			_prop.var.etc.imageListHeight = size.y;
		}
	}

	@property
	Shell shell() {return _shl;}
	@property
	ImageList widget() {return _list;}

	private ImageData createImage(string path, bool mask) { mixin(S_TRACE);
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

	void images(string dir, string[] path) { mixin(S_TRACE);
		if (_shl.isVisible()) _shl.setRedraw(false);
		scope (exit) {
			if (_shl.isVisible()) _shl.setRedraw(true);
		}

		_shl.setText(dir);
		_list.removeAll();
		_list.add(path);
	}
	@property
	void select(string path) { mixin(S_TRACE);
		_list.select(path);
		_list.showSelection();
	}

	@property
	void mask(bool mask) {_list.mask = mask;}

	private class MouseDown : MouseAdapter {
		override void mouseDown(MouseEvent e) { mixin(S_TRACE);
			if (1 != e.button) return;
			int i = _list.indexOf(e.x, e.y);
			if (-1 != i) { mixin(S_TRACE);
				_selection(_list.path(i));
			}
			_shl.close();
			_shl.dispose();
		}
	}
}

class ImageList : Composite {
	private static immutable SPACING = 10;
	private string[] _path;
	private ImageData[] _image;
	private CRect[] _bounds;
	private int _imgW, _imgH;
	private bool _mask;
	private ptrdiff_t _sel = -1;
	private ImageData delegate(string path, bool mask) _createImage;

	private bool _showSelection = false;

	this (Composite parent, int style) { mixin(S_TRACE);
		super (parent, style | SWT.V_SCROLL | SWT.DOUBLE_BUFFERED);
		addControlListener(new Resize);
		addPaintListener(new Paint);
		addMouseMoveListener(new MouseMove);
		setForeground(getDisplay().getSystemColor(SWT.COLOR_LIST_FOREGROUND));
		setBackground(getDisplay().getSystemColor(SWT.COLOR_LIST_BACKGROUND));
	}
	void init(int imgW, int imgH, ImageData delegate(string path, bool mask) createImage) { mixin(S_TRACE);
		_imgW = imgW;
		_imgH = imgH;
		_createImage = createImage;

		auto vs = getVerticalBar();
		vs.setIncrement(_imgH / 4);
	}
	private int calcCountPerLine() { mixin(S_TRACE);
		auto ca = getClientArea();

		int w = SPACING + _imgW;
		int countPerLine = ca.width / w;
		if (ca.width % w < SPACING) countPerLine--;
		return max(1, countPerLine);
	}
	private void calcScrollParams() { mixin(S_TRACE);
		auto ca = getClientArea();
		auto vs = getVerticalBar();
		vs.setPageIncrement(max(vs.getIncrement(), ca.height / 2));

		auto gc = new GC(this);
		scope (exit) gc.dispose();
		int fh = gc.getFontMetrics().getHeight();
		int h = SPACING + _imgH + fh;
		int countPerLine = calcCountPerLine();
		auto row = _path.length / countPerLine;
		if (_path.length % countPerLine) row++;
		vs.setMinimum(0);
		vs.setMaximum(cast(int)row * h + SPACING);
		vs.setThumb(ca.height);
		vs.addSelectionListener(new Redraw);
	}

	private class MouseMove : MouseMoveListener {
		override void mouseMove(MouseEvent e) { mixin(S_TRACE);
			int i = indexOf(e.x, e.y);
			if (-1 == i) { mixin(S_TRACE);
				setCursor(null);
				setToolTipText("");
			} else { mixin(S_TRACE);
				setCursor(getDisplay().getSystemCursor(SWT.CURSOR_HAND));
				setToolTipText(std.array.replace(_path[i], "&", "&&"));
			}
		}
	}
	private class Redraw : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			redraw();
		}
	}
	private class Resize : ControlAdapter {
		override void controlResized(ControlEvent e) { mixin(S_TRACE);
			calcScrollParams();
			if (isVisible() && _showSelection) { mixin(S_TRACE);
				showSelection();
				_showSelection = false;
			}
		}
	}
	private class Paint : PaintListener {
		override void paintControl(PaintEvent e) { mixin(S_TRACE);
			onPaint(e);
		}
	}
	private void onPaint(PaintEvent e) { mixin(S_TRACE);
		auto ca = getClientArea();
		int x = SPACING;
		int y = SPACING - getVerticalBar().getSelection();
		int fh = e.gc.getFontMetrics().getHeight();
		foreach (i, ref imgData; _image) { mixin(S_TRACE);
			if (ca.intersects(x, y, _imgW, fh + _imgH)) { mixin(S_TRACE);
				int iw, ih;
				if (imgData) { mixin(S_TRACE);
					iw = imgData.width;
					ih = imgData.height;
				} else { mixin(S_TRACE);
					imgData = _createImage(_path[i], _mask);
					if (_imgW < imgData.width || _imgH < imgData.height) { mixin(S_TRACE);
						real wr = cast(real) _imgW / imgData.width;
						real hr = cast(real) _imgH / imgData.height;
						iw = cast(int) (imgData.width * min(wr, hr));
						ih = cast(int) (imgData.height * min(wr, hr));
						auto data2 = imgData;
						imgData = imgData.scaledTo(iw, ih);
						data2.data[] = 0;
						delete data2.data;
					} else { mixin(S_TRACE);
						iw = imgData.width;
						ih = imgData.height;
					}
				}
				auto img = new Image(getDisplay(), imgData);
				scope (exit) img.dispose();
				int ix = (_imgW - iw) / 2;
				int iy = (_imgH - ih) / 2;
				e.gc.drawImage(img, x + ix, y + iy);
				string name = .cutText(_path[i].baseName(), e.gc, _imgW);
				auto te = e.gc.wTextExtent(name);
				e.gc.wDrawText(name, x + (_imgW - te.x) / 2, y + _imgH);
				if (i == _sel) { mixin(S_TRACE);
					e.gc.drawRectangle(x - 2, y - 2, _imgW + 3, _imgH + fh + 3);
				}
			}
			_bounds[i].x = x;
			_bounds[i].y = y;
			_bounds[i].width = _imgW;
			_bounds[i].height = fh + _imgH;
			x += _imgW + SPACING;
			if (ca.width < x + _imgW + SPACING) { mixin(S_TRACE);
				x = SPACING;
				y += fh + _imgH + SPACING;
			}
		}
	}

	@property
	const
	string path(size_t index) { mixin(S_TRACE);
		return _path[index];
	}
	@property
	void select(string path) { mixin(S_TRACE);
		if (path == "") { mixin(S_TRACE);
			_sel = -1;
		}
		auto i = countUntil(_path, path);
		if (-1 == i) return;
		_sel = i;
	}
	void showSelection() { mixin(S_TRACE);
		if (-1 == _sel) return;
		if (!isVisible()) { mixin(S_TRACE);
			_showSelection = true;
			return;
		}
		auto vs = getVerticalBar();

		int countPerLine = calcCountPerLine();

		auto gc = new GC(this);
		scope (exit) gc.dispose();
		int fh = gc.getFontMetrics().getHeight();

		int h = SPACING + _imgH + fh;
		auto y = _sel / countPerLine * h;
		if (y < vs.getSelection()) { mixin(S_TRACE);
			vs.setSelection(cast(int)y);
		} else if (vs.getSelection() + vs.getThumb() < y + h + SPACING) { mixin(S_TRACE);
			vs.setSelection(cast(int)y + h + SPACING - vs.getThumb());
		}
		redraw();
	}

	int indexOf(int x, int y) { mixin(S_TRACE);
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
	void mask(bool mask) { mixin(S_TRACE);
		if (_mask == mask) return;
		_mask = mask;
		foreach (ref imgData; _image) { mixin(S_TRACE);
			imgData = null;
		}
		redraw();
	}

	void add(string[] path) { mixin(S_TRACE);
		_path ~= path;
		_image.length += path.length;
		_bounds.length += path.length;
		calcScrollParams();
		redraw();
	}
	void removeAll() { mixin(S_TRACE);
		_path.length = 0;
		_image.length = 0;
		_bounds.length = 0;
		calcScrollParams();
		redraw();
	}
}
