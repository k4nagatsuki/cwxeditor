
module cwx.editor.gui.dwt.cardlist;

import cwx.utils;

import org.eclipse.swt.SWT;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.ScrollBar;
import org.eclipse.swt.widgets.Item;
import org.eclipse.swt.graphics.ImageData;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.graphics.Rectangle;
import org.eclipse.swt.dnd.DragSource;
import org.eclipse.swt.dnd.DragSourceEvent;
import org.eclipse.swt.dnd.DragSourceEffect;

public:

class CardList(C) : Composite {
public:
	/// Params:
	/// parent = 親コンポーネント。
	/// style = スタイル。使用可能なスタイルはSWT.MULTI、DWT.V_SCROLL、DWT.H_SCROLL。
	this (Composite parent, int style) {
		super(parent, style | SWT.NO_BACKGROUND);
		_origin = new Point(0, 0);
		setBackground(Display.getCurrent().getSystemColor(SWT.COLOR_LIST_BACKGROUND));
		void setupBar(ScrollBar scr, void delegate(int) setOrigin) {
			if (scr !is null) {
				scr.addListener(SWT.Selection, new class(scr, setOrigin) Listener {
					private ScrollBar _bar;
					private void delegate(int) _setOrigin;
					public this(ScrollBar bar, void delegate(int) setOrigin) {
						_bar = bar;
						_setOrigin = setOrigin;
					}
					public override void handleEvent(Event e) {
						_setOrigin(_bar.getSelection());
					}
				});
			}
		}
		setupBar(getVerticalBar(), &scrollY);
		setupBar(getHorizontalBar(), &scrollX);
		addListener(SWT.Dispose, new class Listener {
			public override void handleEvent(Event e) {
				disposeItems();
			}
		});
		addListener(SWT.Paint, new class Listener {
			public override void handleEvent(Event e) {
				auto area = getClientArea();
				scope img = new Image(Display.getCurrent(), area.width, area.height);
				scope gc = new GC(img);
				gc.setBackground(getBackground());
				gc.fillRectangle(area);
				__repaint(gc);
				e.gc.drawImage(img, 0, 0);
				gc.dispose();
				img.dispose();
			}
		});
		addListener(SWT.Resize, new class Listener {
			public override void handleEvent(Event e) {
				__resize();
			}
		});
		addListener(SWT.Traverse, new class Listener {
			public override void handleEvent(Event e) {
				switch (e.detail) {
				case SWT.TRAVERSE_ARROW_NEXT, SWT.TRAVERSE_ARROW_PREVIOUS:
					e.doit = false;
					break;
				default:
					e.doit = true;
				}
			}
		});
		addListener(SWT.KeyDown, new class Listener {
			public override void handleEvent(Event e) {
				bool ctrl = (e.stateMask & SWT.CTRL) != 0;
				if (e.character == SWT.CR && (getStyle() & SWT.MULTI) != 0) {
					if (_cur in _sels) {
						deselect(_cur);
					} else {
						select(_cur);
					}
					callSelectChanged();
				} else {
					switch (e.keyCode) {
					case SWT.PAGE_UP:
						auto bar = getVerticalBar();
						if (bar !is null) {
							scrollY(bar.getSelection() - bar.getPageIncrement());
						}
						break;
					case SWT.PAGE_DOWN:
						auto bar = getVerticalBar();
						if (bar !is null) {
							scrollY(bar.getSelection() + bar.getPageIncrement());
						}
						break;
					case SWT.HOME:
						auto bar = getVerticalBar();
						if (bar !is null) {
							scrollY(bar.getMinimum());
						}
						break;
					case SWT.END:
						auto bar = getVerticalBar();
						if (bar !is null) {
							scrollY(bar.getMaximum() - bar.getThumb());
						}
						break;
					case SWT.ARROW_UP:
						if (ctrl) return;
						int nCur = _cur - _wrap;
						if (nCur < 0) {
							nCur = _wrap * (_line - 1) + _cur;
							if (_items.length <= nCur) nCur -= _wrap;
						}
						setCursor(nCur, true);
						break;
					case SWT.ARROW_DOWN:
						if (ctrl) return;
						int nCur = _cur + _wrap;
						if (_items.length <= nCur) {
							nCur = _cur % _wrap;
						}
						setCursor(nCur, true);
						break;
					case SWT.ARROW_LEFT:
						if (ctrl) return;
						int nCur;
						if (isFirstCol(_cur)) {
							nCur = _cur + _wrap - 1;
							if (_items.length <= nCur) nCur = _items.length - 1;
						} else {
							nCur = _cur - 1;
						}
						setCursor(nCur, true);
						break;
					case SWT.ARROW_RIGHT:
						if (ctrl) return;
						int nCur;
						if (_cur == _items.length - 1) {
							int d = _items.length % _wrap;
							nCur = _items.length - (d == 0 ? _wrap : d);
						} else if (isLastCol(_cur)) {
							nCur = _cur - _wrap + 1;
						} else {
							nCur = _cur + 1;
						}
						setCursor(nCur, true);
						break;
					default:
						e.doit = true;
					}
				}
			}
		});
		addListener(SWT.MouseUp, new class Listener {
			public override void handleEvent(Event e) {
				if (!_dragging && (getStyle() & SWT.MULTI) != 0 && e.button == 1 && _mouseP >= 0) {
					if (_ctrl) {
						if (isSelectedAt(_mouseP)) {
							deselect(_mouseP);
							callSelectChanged();
						} else {
							select(_mouseP);
							callSelectChanged();
						}
					} else if (!_shift) {
						deselectAll();
						select(_mouseP);
						callSelectChanged();
					}
				}
				_dragging = false;
				_mouseP = -1;
			}
		});
		addListener(SWT.MouseDown, new class Listener {
			public override void handleEvent(Event e) {
				_dragging = false;
				_shift = (e.stateMask & SWT.SHIFT) != 0;
				_ctrl = (e.stateMask & SWT.CTRL) != 0;
				int i = searchIndex(e.x, e.y);
				if (i >= 0) {
					_mouseP = i;
					if ((getStyle() & SWT.MULTI) == 0) {
						if (e.button == 1 || e.button == 3) {
							_mouseP = i;
							// SINGLEモードではsetCursor()で同時に選択が行われる
							setCursor(i);
						}
					} else {
						if (e.button == 1) {
							if (_ctrl) {
								_shiftP = i;
							} else if (_shift) {
								if (_shiftP >= 0) {
									int i1, i2;
									if (_shiftP < i) {
										i1 = _shiftP;
										i2 = i;
									} else {
										i1 = i;
										i2 = _shiftP;
									}
									deselectAll();
									for (int j = i1; j <= i2; j++) {
										select(j);
									}
								} else {
									select(i);
									_shiftP = i;
								}
								callSelectChanged();
							} else {
								if (!isSelectedAt(i)) deselectAll();
								select(i);
								_shiftP = i;
								callSelectChanged();
							}
							setCursor(i);
						} else if (e.button == 3) {
							if (!_ctrl) {
								if (!isSelectedAt(i)) deselectAll();
								_shiftP = i;
								select(i);
								setCursor(i);
								callSelectChanged();
							}
						}
					}
				} else if (e.button == 1 || e.button == 3) {
					deselectAll();
					_shiftP = -1;
					_mouseP = -1;
					callSelectChanged();
				}
			}
		});
		addListener(SWT.DragDetect, new class Listener {
			public override void handleEvent(Event e) {
				if ((getStyle() & SWT.MULTI) != 0) {
					if (_ctrl && _mouseP >= 0) {
						select(_mouseP);
						callSelectChanged();
					}
				}
				_dragging = true;
			}
		});
		setDragDetect(false);
		setData(DragSource.DEFAULT_DRAG_SOURCE_EFFECT, new CardListDragSourceEffect!(C)(this));
		addListener(SWT.MouseMove, new class Listener {
			public override void handleEvent(Event e) {
				int index = searchIndex(e.x, e.y);
				if (_oldMoveIndex != index) {
					_oldMoveIndex = index;
					setDragDetect(index >= 0);
					__refreshToolTip();
				}
			}
		});
		addListener(SWT.FocusIn, new class Listener {
			public override void handleEvent(Event e) {
				if ((getStyle() & SWT.MULTI) == 0 && _sels.length == 0 && _items.length > 0) {
					select(0);
					callSelectChanged();
				}
				if (_cur >= 0) redrawCard(_cur);
			}
		});
		addListener(SWT.FocusOut, new class Listener {
			public override void handleEvent(Event e) {
				if (_cur >= 0) redrawCard(_cur);
			}
		});
	}
	/// 選択の変更をdlgに通知する。
	@property
	void selectChanged(void delegate() dlg) {
		_selected ~= dlg;
	}
	private void delegate()[] _selected;
	private void callSelectChanged() {
		foreach (dlg; _selected) dlg();
	}
	/// 指定されたインデックスをカーソル位置にする。
	/// Params:
	/// index = インデックス。
	/// scroll = カーソル位置までスクロールするか。
	/// select = 選択するか。
	void setCursor(int index, bool scroll = false) {
		if (_cur != index) {
			if (_cur >= 0) redrawCard(_cur);
			if (index >= 0) redrawCard(index);
			_cur = index;
		}
		if ((getStyle() & SWT.MULTI) == 0) {
			this.select(_cur);
			callSelectChanged();
		}
		if (scroll) this.scroll(_cur);
	}
	/// 指定されたインデックスの領域を再描画するよう指示する。
	/// Params:
	/// index = インデックス。
	void redrawCard(int index) {
		auto itm = _items[index];
		super.redraw(itm.x, itm.y, itm.width, itm.height, false);
	}
	/// 指定されたカードのインデックスを返す。
	/// Params:
	/// c = カード。
	/// Returns: インデックス。見つからなかった場合は-1。
	int indexOf(C c) {
		foreach (i, itm; _items) {
			if (itm.getData() is c) {
				return i;
			}
		}
		return -1;
	}
	/// 指定されたカードを選択する。
	/// Params:
	/// c = カード。
	@property
	void select(C c) {
		int i = indexOf(c);
		if (i >= 0) select(i);
	}
	/// 指定されたインデックスを選択する。
	/// Params:
	/// index = インデックス。
	@property
	void select(int index) {
		if (!(index in _sels)) {
			if ((getStyle() & SWT.MULTI) == 0) {
				deselectAll();
				_sels[index] = _items[index];
				_cur = index;
				redraw();
			} else {
				_sels[index] = _items[index];
				redrawCard(index);
			}
		}
	}
	/// 指定されたインデックスの選択を解除する。
	/// Params:
	/// index = インデックス。
	void deselect(int index) {
		if (index in _sels) {
			_sels.remove(index);
			redrawCard(index);
		}
	}
	/// すべての選択を解除する。
	void deselectAll() {
		foreach (key; _sels.keys) {
			_sels.remove(key);
			redrawCard(key);
		}
	}
	/// リストを更新する。
	/// Params:
	/// cards = 表示する要素の配列。
	/// createImage = 要素から画像を作成する関数。
	void refresh(C[] cards, ImageData delegate(C) createImage) {
		int ox = _origin.x;
		int oy = _origin.y;
		scope sels = new HashSet!(C);
		foreach (itm; _sels.values) {
			sels.add(cast(C) itm.getData());
		}
		deselectAll();
		disposeItems();
		foreach (c; cards) {
			auto itm = new CardListItem!(C)(this, SWT.NONE, c, createImage);
			_items ~= itm;
			if (_defItmW < 0 && _itmW < itm.width) _itmW = itm.width;
			if (_defItmH < 0 && _itmH < itm.height) _itmH = itm.height;
		}
		if (_defItmW >= 0) _itmW = _defItmW;
		if (_defItmH >= 0) _itmH = _defItmH;
		auto vScr = getVerticalBar();
		if (vScr) vScr.setIncrement(_itmH / 4);
		auto hScr = getHorizontalBar();
		if (hScr) hScr.setIncrement(_itmW / 4);
		if (_items.length > 0) {
			scroll(0);
			_cur = 0;
		} else {
			_cur = -1;
		}
		foreach (i, itm; _items) {
			if (sels.contains(cast(C) itm.getData())) {
				select(i);
			}
		}
		__resize();
		scrollX(ox);
		scrollY(oy);
		callSelectChanged();
	}
	@property
	int count() {
		return _items.length;
	}
	/// Returns: 選択中のアイテムの配列。
	@property
	protected CardListItem!(C)[] selectionItems() {
		return _sels.values;
	}
	/// Returns: 選択されているインデックスの配列。ソートされているとは限らない。
	@property
	int[] selectionIndices() {
		return _sels.keys;
	}
	/// ditto
	@property
	void selectionIndices(int[] indices) {
		foreach (i; indices) {
			select = i;
		}
	}
	/// Returns: 選択されているインデックスの最初の一件。選択が無い場合は-1。
	@property
	int selection() {
		if (isSelected) {
			int i = int.max;
			foreach (s; selectionIndices) {
				if (s < i) i = s;
			}
			return i;
		} else {
			return -1;
		}
	}
	/// indexの画像を更新する。
	void refresh(int index) {
		_items[index].createImage(true);
		redraw();
	}
	/// Returns: 選択されているカードの配列。
	@property
	C[] selectionCards() {
		C[] cs;
		cs.length = _sels.length;
		foreach (i, c; _sels.values) {
			cs[i] = cast(C) c.getData();
		}
		return cs;
	}
	/// Returns: 選択されているカードの最初の一件。選択が無い場合はnull。
	@property
	C selectionCard() {
		int index = selection;
		return index >= 0 ? cast(C) _items[index].getData() : null;
	}
	C card(int index) {
		return cast(C) _items[index].getData();
	}
	/// Returns: 選択があるか。
	@property
	bool isSelected() {
		return _sels.length > 0;
	}
	/// Returns: 選択されているか。
	bool isSelectedAt(int index) {
		return (index in _sels) !is null;
	}
	/// Returns: 指定された座標に存在するカード。
	C search(int x, int y) {
		int i = searchIndex(x, y);
		return i >= 0 ? (cast(C) _items[i].getData()) : null;
	}
	/// Returns: 指定された座標に存在するカードのインデックス。
	int searchIndex(int x, int y) {
		int index = searchIndexLoose(x, y);
		if (index < _items.length) {
			auto i = _items[index];
			if (i.x <= x && x <= i.x + i.width && i.y <= y && y <= i.y + i.height) {
				return index;
			}
		}
		return -1;
	}
	/// Returns: 指定された座標に近いカードのインデックス。
	///          そのインデックスのカードは存在しない可能性がある。
	int searchIndexLoose(int x, int y) {
		int col = ((x + _origin.x) - _marginX + _spaceX) / (_itmW + _spaceX);
		int row = ((y + _origin.y) - _marginY + _spaceY) / (_itmH + _spaceY);
		return row * _wrap + col;
	}
	void setCardSize(int itmW, int itmH) {
		_defItmW = itmW;
		_defItmH = itmH;
		_itmW = itmW;
		_itmH = itmH;
	}
	void setLayoutValues(int marginX, int spaceX, int marginY, int spaceY, int defWrap) {
		_marginX = marginX;
		_spaceX = spaceX;
		_marginY = marginY;
		_spaceY = spaceY;
		_defWrap = defWrap;
		if (isVisible()) redraw();
	}
	override {
		Point computeSize(int wHint, int hHint) {
			return computeSize(wHint, hHint, true);
		}
		Point computeSize(int wHint, int hHint, bool change) {
			int x, y;
			if (wHint != SWT.DEFAULT) {
				x = wHint;
			} else {
				x = _marginX * 2 + (_itmW * _defWrap) + (_spaceX * (_defWrap - 1));
			}
			if (hHint != SWT.DEFAULT) {
				y = hHint;
			} else {
				if (_items.length > 0) {
					int colH = _items.length / _defWrap;
					if (_items.length % _defWrap > 0) colH++;
					y = _marginY * 2 + (_itmH * colH) + (_spaceY * (colH - 1));
				} else {
					y = _marginY * 2;
				}
			}
			scope rect = computeTrim(SWT.DEFAULT, SWT.DEFAULT, x, y);
			return new Point(rect.width, rect.height);
		}
	}
	/// 指定されたインデックスのカードが表示されるようにスクロールする。
	/// Params:
	/// index = インデックス。
	void scroll(int index) {
		if (index < 0 || _items.length <= index) return;
		calcBounds();
		auto itm = _items[index];
		void __scroll(ScrollBar bar, int left, int width, void delegate(int) scr,
				bool delegate(int) isFirst, bool delegate(int) isLast, int margin, int space) {
			if (bar !is null) {
				int scLeft = bar.getSelection();
				left += scLeft;
				int right = left + width;
				left -= isFirst(index) ? margin : space;
				right += isLast(index) ? margin : space;
				int scWidth = bar.getThumb();
				int scRight = scLeft + scWidth;
				if (left <= scLeft && right >= scRight) {
					// 両側にはみ出している
					return;
				}
				// 片側のみはみ出しているならはみ出た分を描画領域に納める
				if (left < scLeft) {
					scr(left);
				} else if (right > scRight) {
					if (right - left > bar.getThumb()) {
						// スクロールした結果、左側がはみ出てしまうようなら
						scr(left);
					} else {
						int rs = right - scWidth;
						scr(rs);
					}
				}
			}
		}
		__scroll(getVerticalBar(), itm.y, itm.height, &scrollY, &isFirstRow, &isLastRow, _marginY, _spaceY);
		__scroll(getHorizontalBar(), itm.x, itm.width, &scrollX, &isFirstCol, &isLastCol, _marginX, _spaceX);
	}
	void setToolTip(string delegate(C) createToolTip) {
		_createToolTip = createToolTip;
		__refreshToolTip();
	}
	Rectangle getBounds(int index) {
		auto itm = _items[index];
		return new Rectangle(itm.x, itm.y, itm.width, itm.height);
	}
private:
	void __refreshToolTip() {
		if (_createToolTip) {
			if (0 <= _oldMoveIndex && _oldMoveIndex < _items.length) {
				setToolTipText(_createToolTip(cast(C) _items[_oldMoveIndex].getData()));
			} else {
				setToolTipText(_createToolTip(null));
			}
		}
	}
	bool isFirstCol(int index) {
		return index % _wrap == 0;
	}
	bool isFirstRow(int index) {
		return index < _wrap;
	}
	bool isLastRow(int index) {
		return index >= (_line - 1) * _wrap;
	}
	bool isLastCol(int index) {
		return index % _wrap == _wrap - 1;
	}
	void scrollX(int x) {
		auto bar = getHorizontalBar();
		if (bar !is null) {
			bar.setSelection(x);
			_origin.x = bar.getSelection();
			redraw();
		}
	}
	void scrollY(int y) {
		auto bar = getVerticalBar();
		if (bar !is null) {
			bar.setSelection(y);
			_origin.y = bar.getSelection();
			redraw();
		}
	}
	void calcBounds() {
		if (_items.length == 0) return;
		auto rect = getClientArea();
		int w = rect.width;
		int index, iy, ix;
		int x;
		int y = _marginY - _origin.y;
		for (iy = 0; iy < _line; iy++) {
			x = _marginX - _origin.x;
			for (ix = 0; ix < _wrap && (index = iy * _wrap + ix) < _items.length; ix++) {
				auto itm = _items[index];
				itm.x = x;
				itm.y = y;
				x += _itmW;
				x += _spaceX;
			}
			y += _itmH;
			y += _spaceY;
		}
	}
	void __repaint(GC gc) {
		if (_items.length == 0) return;
		auto rect = getClientArea();
		int w = rect.width;
		int index, iy, ix;
		int x;
		int y = _marginY - _origin.y;
		if (gc) gc.setBackground(Display.getCurrent().getSystemColor(SWT.COLOR_LIST_SELECTION));
		for (iy = 0; iy < _line; iy++) {
			x = _marginX - _origin.x;
			for (ix = 0; ix < _wrap && (index = iy * _wrap + ix) < _items.length; ix++) {
				auto itm = _items[index];
				itm.x = x;
				itm.y = y;
				if ((getStyle() | SWT.VIRTUAL) || y < rect.y + rect.height) {
					if (gc) {
						itm.createImage();
						gc.drawImage(itm.getImage(), x, y);
						if (isFocusControl() && _cur == index) {
							int fx = x + _focusLinePadding;
							int fy = y + _focusLinePadding;
							int fw = itm.width - _focusLinePadding * 2;
							int fh = itm.height - _focusLinePadding * 2;
							gc.drawFocus(fx, fy, fw, fh);
						}
						if (index in _sels) {
							gc.setAlpha(64);
							gc.fillRectangle(x, y, itm.width, itm.height);
							gc.setAlpha(255);
						}
					}
				}
				x += _itmW;
				x += _spaceX;
			}
			y += _itmH;
			y += _spaceY;
		}
	}
	void __resize() {
		auto rect = getClientArea();
		int prW, prH;
		if (_items.length == 0) {
			auto s = computeSize(SWT.DEFAULT, SWT.DEFAULT);
			prW = s.x;
			prH = s.y;
			_wrap = _items.length;
			_line = 1;
		} else {
			int w = rect.width;
			int colN = (w - (_marginX * 2) + _spaceX) / (_itmW + _spaceX);
			if (colN < 1) colN = 1;
			_wrap = colN;
			int colH = _items.length / colN;
			if (_items.length % colN > 0) colH++;
			_line = colH;
			prW = (_marginX * 2) + (_itmW * colN) + (_spaceX * (colN - 1));
			prH = (_marginY * 2) + (_itmH * colH) + (_spaceY * (colH - 1));
		}

		void setupBar(ScrollBar bar, int pr, int size, void delegate(int) scr) {
			if (bar !is null) {
				bar.setMaximum(pr);
				bar.setThumb(pr < size ? pr : size);
				bar.setPageIncrement(size - bar.getIncrement());

				scr(bar.getSelection());
			}
		}
		setupBar(getVerticalBar(), prH, rect.height, &scrollY);
		setupBar(getHorizontalBar(), prW, rect.width, &scrollX);

		__refreshToolTip();
		__repaint(null);
		redraw();
	}
	void disposeItems() {
		foreach (itm; _items) {
			itm.dispose();
		}
		_items.length = 0;
		if (_defItmW >= 0) _itmW = 0;
		if (_defItmH >= 0) _itmH = 0;
		_cur = -1;
	}
	string delegate(C) _createToolTip = null;
	CardListItem!(C)[] _items;
	CardListItem!(C)[int] _sels;
	Point _origin;
	int _cur = -1;
	int _itmW = 0, _itmH = 0;
	int _defItmW = -1, _defItmH = -1;
	int _wrap = 0;
	int _line = 0;
	int _marginX = 25;
	int _spaceX = 25;
	int _marginY = 20;
	int _spaceY = 20;
	int _defWrap = 4;
	int _focusLinePadding = 2;
	int _oldMoveIndex = -1;
	int _shiftP = -1;
	int _mouseP = -1;
	bool _dragging = false;
	bool _shift = false;
	bool _ctrl = false;
}

private class CardListItem(C) : Item {
private:
	ImageData _imgData;
	ImageData delegate(C) _createImage;
	int _x, _y;
public:
	this (CardList!(C) parent, int style, C c, ImageData delegate(C) createImage) {
		super(parent, style);
		setData(c);
		_createImage = createImage;
	}
	void createImage(bool force = false) {
		if (!_imgData || force) {
			_imgData = _createImage(cast(C) getData());
			auto img = getImage();
			if (img) img.dispose();
			setImage(new Image(Display.getCurrent(), _imgData));
		}
	}
	@property
	int x() {
		return _x;
	}
	@property
	protected void x(int x) {
		_x = x;
	}
	@property
	int y() {
		return _y;
	}
	@property
	protected void y(int y) {
		_y = y;
	}
	@property
	int width() {
		createImage();
		return _imgData.width;
	}
	@property
	int height() {
		createImage();
		return _imgData.height;
	}
	override void dispose() {
		auto img = getImage();
		if (img) img.dispose();
	}
}

private class CardListDragSourceEffect(C) : DragSourceEffect {
public:
	this (CardList!(C) list) {
		super (list);
	}
private:
	Image _dImg;
	@property
	CardList!(C) list() {
		return cast(CardList!(C)) getControl();
	}
	void disposeImage() {
		if (_dImg !is null) {
			_dImg.dispose();
			_dImg = null;
		}
	}
public override:
	void dragFinished(DragSourceEvent event) {
		disposeImage();
	}
	void dragStart(DragSourceEvent event) {
		auto clist = cast(CardList!(C)) getControl();
		int i = clist.searchIndex(event.x, event.y);
		if (i >= 0) {
			disposeImage();
			auto sels = list.selectionItems;
			int left = int.max;
			int right = int.min;
			int top = int.max;
			int bottom = int.min;
			foreach (s; sels) {
				if (left > s.x) left = s.x;
				if (right < s.x + s.width) right = s.x + s.width;
				if (top > s.y) top = s.y;
				if (bottom < s.y + s.height) bottom = s.y + s.height;
			}
			int w = right - left;
			int h = bottom - top;

			auto img = new Image(Display.getCurrent(), w, h);
			scope (exit) img.dispose();
			scope gc = new GC(img);
			scope (exit) gc.dispose();
			int maxW = 0;
			foreach (s; sels) {
				s.createImage();
				gc.drawImage(s.getImage(), s.x - left, s.y - top);
				if (maxW < s.width) maxW = s.width;
			}
			scope data = img.getImageData();
			scope byte[] alphas;
			alphas.length = maxW;
			alphas[] = cast(byte) 255;
			foreach (s; sels) {
				for (int y = s.y - top; y < s.y - top + s.height; y++) {
					data.setAlphas(s.x - left, y, s.width, alphas, 0);
				}
			}
			_dImg = new Image(Display.getCurrent(), data);
			event.image = _dImg;
			event.x += event.x - left;
			event.y += event.y - top;
		}
	}
}
