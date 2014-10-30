
module cwx.editor.gui.dwt.cardlist;

import cwx.utils;

import std.algorithm : countUntil;
import std.conv;
import std.datetime;

import org.eclipse.swt.all;
import java.lang.all;

public:

class CardList(C) : Composite {
public:
	/// Params:
	/// parent = 親コンポーネント。
	/// style = スタイル。使用可能なスタイルはSWT.MULTI、DWT.V_SCROLL、DWT.H_SCROLL。
	this (Composite parent, int style) { mixin(S_TRACE);
		super(parent, style | SWT.NO_BACKGROUND);
		_origin = new Point(0, 0);
		setBackground(Display.getCurrent().getSystemColor(SWT.COLOR_LIST_BACKGROUND));
		void setupBar(ScrollBar scr, void delegate(int) setOrigin) { mixin(S_TRACE);
			if (scr !is null) { mixin(S_TRACE);
				scr.addListener(SWT.Selection, new class(scr, setOrigin) Listener {
					private ScrollBar _bar;
					private void delegate(int) _setOrigin;
					public this(ScrollBar bar, void delegate(int) setOrigin) { mixin(S_TRACE);
						_bar = bar;
						_setOrigin = setOrigin;
					}
					public override void handleEvent(Event e) { mixin(S_TRACE);
						_setOrigin(_bar.getSelection());
					}
				});
			}
		}
		setupBar(getVerticalBar(), &scrollY);
		setupBar(getHorizontalBar(), &scrollX);
		addListener(SWT.Dispose, new class Listener {
			public override void handleEvent(Event e) { mixin(S_TRACE);
				disposeItems();
			}
		});
		addListener(SWT.Paint, new class Listener {
			public override void handleEvent(Event e) { mixin(S_TRACE);
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
			public override void handleEvent(Event e) { mixin(S_TRACE);
				__resize();
			}
		});
		addListener(SWT.Traverse, new class Listener {
			public override void handleEvent(Event e) { mixin(S_TRACE);
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
			public override void handleEvent(Event e) { mixin(S_TRACE);
				if (0 == count) return;
				bool ctrl = (e.stateMask & SWT.CTRL) != 0;
				if (e.character == SWT.CR && (getStyle() & SWT.MULTI) != 0) { mixin(S_TRACE);
					if (_cur in _sels) { mixin(S_TRACE);
						deselect(_cur);
					} else { mixin(S_TRACE);
						select(_cur);
					}
					callSelectChanged();
				} else { mixin(S_TRACE);
					switch (e.keyCode) {
					case SWT.PAGE_UP:
						auto bar = getVerticalBar();
						if (bar !is null) { mixin(S_TRACE);
							scrollY(bar.getSelection() - bar.getPageIncrement());
						}
						break;
					case SWT.PAGE_DOWN:
						auto bar = getVerticalBar();
						if (bar !is null) { mixin(S_TRACE);
							scrollY(bar.getSelection() + bar.getPageIncrement());
						}
						break;
					case SWT.HOME:
						auto bar = getVerticalBar();
						if (bar !is null) { mixin(S_TRACE);
							scrollY(bar.getMinimum());
						}
						break;
					case SWT.END:
						auto bar = getVerticalBar();
						if (bar !is null) { mixin(S_TRACE);
							scrollY(bar.getMaximum() - bar.getThumb());
						}
						break;
					case SWT.ARROW_UP:
						if (ctrl) return;
						int nCur = _cur - _wrap;
						if (nCur < 0) { mixin(S_TRACE);
							nCur = _wrap * (_line - 1) + _cur;
							if (_items.length <= nCur) nCur -= _wrap;
						}
						setCursor(nCur, true);
						break;
					case SWT.ARROW_DOWN:
						if (ctrl) return;
						int nCur = _cur + _wrap;
						if (_items.length <= nCur) { mixin(S_TRACE);
							nCur = _cur % _wrap;
						}
						setCursor(nCur, true);
						break;
					case SWT.ARROW_LEFT:
						if (ctrl) return;
						int nCur;
						if (isFirstCol(_cur)) { mixin(S_TRACE);
							nCur = _cur + _wrap - 1;
							if (_items.length <= nCur) nCur = _items.length - 1;
						} else { mixin(S_TRACE);
							nCur = _cur - 1;
						}
						setCursor(nCur, true);
						break;
					case SWT.ARROW_RIGHT:
						if (ctrl) return;
						int nCur;
						if (_cur == _items.length - 1) { mixin(S_TRACE);
							int d = _items.length % _wrap;
							nCur = _items.length - (d == 0 ? _wrap : d);
						} else if (isLastCol(_cur)) { mixin(S_TRACE);
							nCur = _cur - _wrap + 1;
						} else { mixin(S_TRACE);
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
			public override void handleEvent(Event e) { mixin(S_TRACE);
				if (!_dragging && (getStyle() & SWT.MULTI) != 0 && e.button == 1 && _mouseP >= 0) { mixin(S_TRACE);
					if (_ctrl) { mixin(S_TRACE);
						if (isSelectedAt(_mouseP)) { mixin(S_TRACE);
							deselect(_mouseP);
							callSelectChanged();
						} else { mixin(S_TRACE);
							select(_mouseP);
							callSelectChanged();
						}
					} else if (!_shift) { mixin(S_TRACE);
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
			public override void handleEvent(Event e) { mixin(S_TRACE);
				if (e.button == 1 || e.button == 3) { mixin(S_TRACE);
					forceFocus();
				}
				_dragging = false;
				_shift = (e.stateMask & SWT.SHIFT) != 0;
				_ctrl = (e.stateMask & SWT.CTRL) != 0;
				int i = searchIndex(e.x, e.y);
				if (i >= 0) { mixin(S_TRACE);
					_mouseP = i;
					if ((getStyle() & SWT.MULTI) == 0) { mixin(S_TRACE);
						if (e.button == 1 || e.button == 3) { mixin(S_TRACE);
							_mouseP = i;
							// SINGLEモードではsetCursor()で同時に選択が行われる
							setCursor(i);
						}
					} else { mixin(S_TRACE);
						if (e.button == 1) { mixin(S_TRACE);
							if (_ctrl) { mixin(S_TRACE);
								_shiftP = i;
							} else if (_shift) { mixin(S_TRACE);
								if (_shiftP >= 0) { mixin(S_TRACE);
									int i1, i2;
									if (_shiftP < i) { mixin(S_TRACE);
										i1 = _shiftP;
										i2 = i;
									} else { mixin(S_TRACE);
										i1 = i;
										i2 = _shiftP;
									}
									deselectAll();
									for (int j = i1; j <= i2; j++) { mixin(S_TRACE);
										select(j);
									}
								} else { mixin(S_TRACE);
									select(i);
									_shiftP = i;
								}
								callSelectChanged();
							} else { mixin(S_TRACE);
								if (!isSelectedAt(i)) deselectAll();
								select(i);
								_shiftP = i;
								callSelectChanged();
							}
							setCursor(i);
						} else if (e.button == 3) { mixin(S_TRACE);
							if (!_ctrl) { mixin(S_TRACE);
								if (!isSelectedAt(i)) deselectAll();
								_shiftP = i;
								select(i);
								setCursor(i);
								callSelectChanged();
							}
						}
					}
				} else if (e.button == 1 || e.button == 3) { mixin(S_TRACE);
					deselectAll();
					_shiftP = -1;
					_mouseP = -1;
					callSelectChanged();
				}
			}
		});
		addListener(SWT.DragDetect, new class Listener {
			public override void handleEvent(Event e) { mixin(S_TRACE);
				if ((getStyle() & SWT.MULTI) != 0) { mixin(S_TRACE);
					if (_ctrl && _mouseP >= 0) { mixin(S_TRACE);
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
			public override void handleEvent(Event e) { mixin(S_TRACE);
				int index = searchIndex(e.x, e.y);
				if (_oldMoveIndex != index) { mixin(S_TRACE);
					_oldMoveIndex = index;
					setDragDetect(index >= 0);
					__refreshToolTip();
				}
			}
		});
		addListener(SWT.FocusIn, new class Listener {
			public override void handleEvent(Event e) { mixin(S_TRACE);
				if ((getStyle() & SWT.MULTI) == 0 && _sels.length == 0 && _items.length > 0) { mixin(S_TRACE);
					select(0);
					callSelectChanged();
				}
				if (_cur >= 0) redrawCard(_cur);
			}
		});
		addListener(SWT.FocusOut, new class Listener {
			public override void handleEvent(Event e) { mixin(S_TRACE);
				if (_cur >= 0) redrawCard(_cur);
			}
		});
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
		int index = selection;
		se.item = 0 <= index ? _items[index] : null;
		se.time = cast(int)(0xFFFFFFFFL & Clock.currStdTime());
		se.stateMask = 0;
		se.doit = true;
		notifyListeners(SWT.Selection, se);
	}
	/// 指定されたインデックスをカーソル位置にする。
	/// Params:
	/// index = インデックス。
	/// scroll = カーソル位置までスクロールするか。
	/// select = 選択するか。
	void setCursor(int index, bool scroll = false) { mixin(S_TRACE);
		if (_cur != index) { mixin(S_TRACE);
			if (_cur >= 0) redrawCard(_cur);
			if (index >= 0) redrawCard(index);
			_cur = index;
		}
		if ((getStyle() & SWT.MULTI) == 0) { mixin(S_TRACE);
			this.select(_cur);
			callSelectChanged();
		}
		if (scroll) this.scroll(_cur);
	}
	alias Composite.setCursor setCursor;
	/// 指定されたインデックスの領域を再描画するよう指示する。
	/// Params:
	/// index = インデックス。
	void redrawCard(int index) { mixin(S_TRACE);
		auto itm = _items[index];
		super.redraw(itm.x - 1, itm.y, itm.width + 2, itm.height + 1, false);
	}
	/// 指定されたカードのインデックスを返す。
	/// Params:
	/// c = カード。
	/// Returns: インデックス。見つからなかった場合は-1。
	int indexOf(C c) { mixin(S_TRACE);
		foreach (i, itm; _items) { mixin(S_TRACE);
			if (itm.getData() is c) { mixin(S_TRACE);
				return i;
			}
		}
		return -1;
	}
	/// 指定されたカードを選択する。
	/// Params:
	/// c = カード。
	@property
	void select(C c) { mixin(S_TRACE);
		int i = indexOf(c);
		if (i >= 0) select(i);
	}
	/// 指定されたインデックスを選択する。
	/// Params:
	/// index = インデックス。
	@property
	void select(int index) { mixin(S_TRACE);
		if (!(index in _sels)) { mixin(S_TRACE);
			if ((getStyle() & SWT.MULTI) == 0) { mixin(S_TRACE);
				deselectAll();
				_sels[index] = _items[index];
				_cur = index;
				redraw();
			} else { mixin(S_TRACE);
				_sels[index] = _items[index];
				redrawCard(index);
			}
		}
	}
	/// 指定されたインデックスの選択を解除する。
	/// Params:
	/// index = インデックス。
	void deselect(int index) { mixin(S_TRACE);
		if (index in _sels) { mixin(S_TRACE);
			_sels.remove(index);
			redrawCard(index);
		}
	}
	/// すべての選択を解除する。
	void deselectAll() { mixin(S_TRACE);
		foreach (key; _sels.keys) { mixin(S_TRACE);
			_sels.remove(key);
			redrawCard(key);
		}
	}
	/// リストを更新する。
	/// Params:
	/// cards = 表示する要素の配列。
	/// createImage = 要素から画像を作成する関数。
	/// createTitle = 要素から画像タイトルを作成する関数。
	///               タイトルが不要な場合はnullを指定する。
	void refresh(C[] cards, ImageData delegate(in C) createImage, string delegate(in C) createTitle) { mixin(S_TRACE);
		int ox = _origin.x;
		int oy = _origin.y;
		auto sels = new HashSet!(C);
		foreach (itm; _sels.values) { mixin(S_TRACE);
			sels.add(cast(C) itm.getData());
		}
		deselectAll();
		disposeItems();
		foreach (c; cards) { mixin(S_TRACE);
			auto itm = new CardListItem!(C)(this, SWT.NONE, c, createImage, createTitle);
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
		if (_items.length > 0) { mixin(S_TRACE);
			scroll(0);
			_cur = 0;
		} else { mixin(S_TRACE);
			_cur = -1;
		}
		foreach (i, itm; _items) { mixin(S_TRACE);
			if (sels.contains(cast(C) itm.getData())) { mixin(S_TRACE);
				select(i);
			}
		}
		__resize();
		scrollX(ox);
		scrollY(oy);
		callSelectChanged();
	}
	@property
	int count() { mixin(S_TRACE);
		return _items.length;
	}
	/// 選択中のアイテムの数。
	@property
	int selectionCount() { mixin(S_TRACE);
		return _sels.length;
	}
	/// Returns: 選択中のアイテムの配列。
	@property
	protected CardListItem!(C)[] selectionItems() { mixin(S_TRACE);
		return _sels.values;
	}
	/// Returns: 選択されているインデックスの配列。ソートされているとは限らない。
	@property
	int[] selectionIndices() { mixin(S_TRACE);
		return _sels.keys;
	}
	/// ditto
	@property
	void selectionIndices(int[] indices) { mixin(S_TRACE);
		foreach (i; indices) { mixin(S_TRACE);
			select(i);
		}
	}
	/// Returns: 選択されているインデックスの最初の一件。選択が無い場合は-1。
	@property
	int selection() { mixin(S_TRACE);
		if (isSelected) { mixin(S_TRACE);
			int i = int.max;
			foreach (s; selectionIndices) { mixin(S_TRACE);
				if (s < i) i = s;
			}
			return i;
		} else { mixin(S_TRACE);
			return -1;
		}
	}
	/// indexの画像を更新する。
	void refresh(int index, C card) { mixin(S_TRACE);
		auto itm = _items[index];
		itm.setData(card);
		itm.createImage(true);
		itm.createTitle();
		redraw(itm.x, itm.y, itm.width, itm.height, false);
	}
	/// Returns: カードの配列。
	@property
	C[] cards() { mixin(S_TRACE);
		C[] cs;
		cs.length = _items.length;
		foreach (i, c; _items) { mixin(S_TRACE);
			cs[i] = cast(C) c.getData();
		}
		return cs;
	}
	/// Returns: 選択されているカードの配列。
	@property
	C[] selectionCards() { mixin(S_TRACE);
		C[] cs;
		cs.length = _sels.length;
		foreach (i, c; _sels.values) { mixin(S_TRACE);
			cs[i] = cast(C) c.getData();
		}
		return cs;
	}
	/// Returns: 選択されているカードの最初の一件。選択が無い場合はnull。
	@property
	C selectionCard() { mixin(S_TRACE);
		int index = selection;
		return index >= 0 ? cast(C) _items[index].getData() : null;
	}
	C card(int index) { mixin(S_TRACE);
		return cast(C) _items[index].getData();
	}
	/// Returns: 選択があるか。
	@property
	bool isSelected() { mixin(S_TRACE);
		return _sels.length > 0;
	}
	/// Returns: 選択されているか。
	bool isSelectedAt(int index) { mixin(S_TRACE);
		return (index in _sels) !is null;
	}
	/// Returns: 指定された座標に存在するカード。
	C search(int x, int y) { mixin(S_TRACE);
		int i = searchIndex(x, y);
		return i >= 0 ? (cast(C) _items[i].getData()) : null;
	}
	/// Returns: 指定された座標に存在するカードのインデックス。
	int searchIndex(int x, int y) { mixin(S_TRACE);
		int index = searchIndexLoose(x, y);
		if (index < _items.length) { mixin(S_TRACE);
			auto itm = _items[index];
			if (itm.imageBounds.contains(x, y)) return index;
			if (itm.titleBounds.contains(x, y)) return index;
		}
		return -1;
	}
	/// Returns: 指定された座標に近いカードのインデックス。
	///          そのインデックスのカードは存在しない可能性がある。
	int searchIndexLoose(int x, int y) { mixin(S_TRACE);
		int col = ((x + _origin.x) - _marginX + _spaceX) / (_itmW + _spaceX);
		int row = ((y + _origin.y) - _marginY + _spaceY) / (_itmH + _spaceY);
		return row * _wrap + col;
	}
	void setCardSize(int cardW, int cardH, bool showTitle) { mixin(S_TRACE);
		_cardW = cardW;
		_cardH = cardH;
		_showTitle = showTitle;
		if (showTitle) { mixin(S_TRACE);
			auto gc = new GC(this);
			scope (exit) gc.dispose();
			_fontHeight = gc.getFontMetrics().getHeight();
			cardH += _titleSpace + _fontHeight + 1;
		}
		_defItmW = cardW;
		_defItmH = cardH;
		_itmW = cardW;
		_itmH = cardH;
		if (isVisible()) redraw();
	}
	void setLayoutValues(int marginX, int spaceX, int marginY, int spaceY, int titleSpace, int defWrap) { mixin(S_TRACE);
		_marginX = marginX;
		_spaceX = spaceX;
		_marginY = marginY;
		_spaceY = spaceY;
		_titleSpace = titleSpace;
		_defWrap = defWrap;
		setCardSize(_cardW, _cardH, _showTitle);
	}
	override {
		Point computeSize(int wHint, int hHint) { mixin(S_TRACE);
			return computeSize(wHint, hHint, true);
		}
		Point computeSize(int wHint, int hHint, bool change) { mixin(S_TRACE);
			int x, y;
			if (wHint != SWT.DEFAULT) { mixin(S_TRACE);
				x = wHint;
			} else { mixin(S_TRACE);
				x = _marginX * 2 + (_itmW * _defWrap) + (_spaceX * (_defWrap - 1));
			}
			if (hHint != SWT.DEFAULT) { mixin(S_TRACE);
				y = hHint;
			} else { mixin(S_TRACE);
				if (_items.length > 0) { mixin(S_TRACE);
					int colH = _items.length / _defWrap;
					if (_items.length % _defWrap > 0) colH++;
					y = _marginY * 2 + (_itmH * colH) + (_spaceY * (colH - 1));
				} else { mixin(S_TRACE);
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
	void scroll(int index) { mixin(S_TRACE);
		if (index < 0 || _items.length <= index) return;
		calcBounds();
		auto itm = _items[index];
		void __scroll(ScrollBar bar, int left, int width, void delegate(int) scr,
				bool delegate(int) isFirst, bool delegate(int) isLast, int margin, int space) { mixin(S_TRACE);
			if (bar !is null) { mixin(S_TRACE);
				int scLeft = bar.getSelection();
				left += scLeft;
				int right = left + width;
				left -= isFirst(index) ? margin : space;
				right += isLast(index) ? margin : space;
				int scWidth = bar.getThumb();
				int scRight = scLeft + scWidth;
				if (left <= scLeft && right >= scRight) { mixin(S_TRACE);
					// 両側にはみ出している
					return;
				}
				// 片側のみはみ出しているならはみ出た分を描画領域に納める
				if (left < scLeft) { mixin(S_TRACE);
					scr(left);
				} else if (right > scRight) { mixin(S_TRACE);
					if (right - left > bar.getThumb()) { mixin(S_TRACE);
						// スクロールした結果、左側がはみ出てしまうようなら
						scr(left);
					} else { mixin(S_TRACE);
						int rs = right - scWidth;
						scr(rs);
					}
				}
			}
		}
		__scroll(getVerticalBar(), itm.y, itm.height, &scrollY, &isFirstRow, &isLastRow, _marginY, _spaceY);
		__scroll(getHorizontalBar(), itm.x, itm.width, &scrollX, &isFirstCol, &isLastCol, _marginX, _spaceX);
	}
	void setToolTip(string delegate(C) createToolTip) { mixin(S_TRACE);
		_createToolTip = createToolTip;
		__refreshToolTip();
	}
	Item getItem(int index) { mixin(S_TRACE);
		return _items[index];
	}
	int indexOf(Item item) { mixin(S_TRACE);
		return .countUntil(_items, item);
	}
	Rectangle getBounds(int index) { mixin(S_TRACE);
		auto itm = _items[index];
		return new Rectangle(itm.x, itm.y, itm.width, itm.height);
	}
	Rectangle getImageBounds(int index) { mixin(S_TRACE);
		return _items[index].imageBounds();
	}
	Rectangle getTitleBounds(int index) { mixin(S_TRACE);
		return _items[index].titleBounds();
	}
private:
	void __refreshToolTip() { mixin(S_TRACE);
		if (_createToolTip) { mixin(S_TRACE);
			if (0 <= _oldMoveIndex && _oldMoveIndex < _items.length) { mixin(S_TRACE);
				setToolTipText(std.array.replace(_createToolTip(cast(C) _items[_oldMoveIndex].getData()), "&", "&&"));
			} else { mixin(S_TRACE);
				setToolTipText(_createToolTip(null));
			}
		}
	}
	bool isFirstCol(int index) { mixin(S_TRACE);
		return index % _wrap == 0;
	}
	bool isFirstRow(int index) { mixin(S_TRACE);
		return index < _wrap;
	}
	bool isLastRow(int index) { mixin(S_TRACE);
		return index >= (_line - 1) * _wrap;
	}
	bool isLastCol(int index) { mixin(S_TRACE);
		return index % _wrap == _wrap - 1;
	}
	void scrollX(int x) { mixin(S_TRACE);
		auto bar = getHorizontalBar();
		if (bar !is null) { mixin(S_TRACE);
			bar.setSelection(x);
			_origin.x = bar.getSelection();
			redraw();
		}
	}
	void scrollY(int y) { mixin(S_TRACE);
		auto bar = getVerticalBar();
		if (bar !is null) { mixin(S_TRACE);
			bar.setSelection(y);
			_origin.y = bar.getSelection();
			redraw();
		}
	}
	void calcBounds() { mixin(S_TRACE);
		if (_items.length == 0) return;
		auto rect = getClientArea();
		int w = rect.width;
		int index, iy, ix;
		int x;
		int y = _marginY - _origin.y;
		for (iy = 0; iy < _line; iy++) { mixin(S_TRACE);
			x = _marginX - _origin.x;
			for (ix = 0; ix < _wrap && (index = iy * _wrap + ix) < _items.length; ix++) { mixin(S_TRACE);
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
	void __repaint(GC gc) { mixin(S_TRACE);
		if (_items.length == 0) return;
		auto rect = getClientArea();
		int w = rect.width;
		int index, iy, ix;
		int x;
		int y = _marginY - _origin.y;
		auto d = getDisplay();
		for (iy = 0; iy < _line; iy++) { mixin(S_TRACE);
			x = _marginX - _origin.x;
			for (ix = 0; ix < _wrap && (index = iy * _wrap + ix) < _items.length; ix++) { mixin(S_TRACE);
				auto itm = _items[index];
				itm.x = x;
				itm.y = y;
				if ((getStyle() | SWT.VIRTUAL) || y < rect.y + rect.height) { mixin(S_TRACE);
					if (gc) { mixin(S_TRACE);
						itm.createImage();
						auto image = itm.getImage();
						gc.drawImage(image, x, y);

						itm.createTitle();
						auto title = itm.cutText(gc);
						auto ib = itm.imageBounds();
						auto tb = itm.titleBounds();
						if (title != "") { mixin(S_TRACE);
							if (index in _sels) { mixin(S_TRACE);
								gc.setBackground(d.getSystemColor(SWT.COLOR_LIST_SELECTION));
								gc.setForeground(d.getSystemColor(SWT.COLOR_LIST_SELECTION_TEXT));
								gc.fillRectangle(tb);
								gc.drawText(title, tb.x, tb.y, true);
							} else { mixin(S_TRACE);
								gc.setBackground(getBackground());
								gc.setForeground(getForeground());
								gc.drawText(title, tb.x, tb.y, true);
							}
						}

						gc.setForeground(getForeground());
						gc.setBackground(d.getSystemColor(SWT.COLOR_LIST_SELECTION));
						if (isFocusControl() && _cur == index) { mixin(S_TRACE);
							int fx = ib.x + _focusLinePadding;
							int fy = ib.y + _focusLinePadding;
							int fw = ib.width - _focusLinePadding * 2;
							int fh = ib.height - _focusLinePadding * 2;
							gc.drawFocus(fx, fy, fw, fh);
							if (title != "") { mixin(S_TRACE);
								gc.drawFocus(tb.x - 1, tb.y - 1, tb.width + 2, tb.height + 2);
							}
						}
						if (index in _sels) { mixin(S_TRACE);
							gc.setAlpha(64);
							gc.fillRectangle(ib);
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
	void __resize() { mixin(S_TRACE);
		auto rect = getClientArea();
		int prW, prH;
		if (_items.length == 0) { mixin(S_TRACE);
			auto s = computeSize(SWT.DEFAULT, SWT.DEFAULT);
			prW = s.x;
			prH = s.y;
			_wrap = _items.length;
			_line = 1;
		} else { mixin(S_TRACE);
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

		void setupBar(ScrollBar bar, int pr, int size, void delegate(int) scr) { mixin(S_TRACE);
			if (bar !is null) { mixin(S_TRACE);
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
	void disposeItems() { mixin(S_TRACE);
		foreach (itm; _items) { mixin(S_TRACE);
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
	int _cardW = 0, _cardH = 0;
	bool _showTitle = false;
	int _itmW = 0, _itmH = 0;
	int _defItmW = -1, _defItmH = -1;
	int _wrap = 0;
	int _line = 0;
	int _marginX = 25;
	int _spaceX = 25;
	int _marginY = 20;
	int _spaceY = 20;
	int _titleSpace = 5;
	int _defWrap = 4;
	int _fontHeight = 12;
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
	CardList!C _parent;
	ImageData _imgData;
	ImageData delegate(in C) _createImage;
	string delegate(in C) _createTitle;
	int _x, _y;
public:
	this (CardList!(C) parent, int style, C c, ImageData delegate(in C) createImage, string delegate(in C) createTitle) { mixin(S_TRACE);
		super(parent, style);
		setData(c);
		_parent = parent;
		_createImage = createImage;
		_createTitle = createTitle;
		this.createTitle();
	}
	void createImage(bool force = false) { mixin(S_TRACE);
		if (!_imgData || force) { mixin(S_TRACE);
			_imgData = _createImage(cast(C)getData());
			auto img = getImage();
			if (img) img.dispose();
			setImage(new Image(Display.getCurrent(), _imgData));
		}
	}
	void createTitle() { mixin(S_TRACE);
		if (_createTitle) { mixin(S_TRACE);
			setText(_createTitle(cast(C)getData()));
		} else { mixin(S_TRACE);
			setText("");
		}
	}

	@property
	int x() { mixin(S_TRACE);
		return _x;
	}
	@property
	protected void x(int x) { mixin(S_TRACE);
		_x = x;
	}
	@property
	int y() { mixin(S_TRACE);
		return _y;
	}
	@property
	protected void y(int y) { mixin(S_TRACE);
		_y = y;
	}
	@property
	int width() { mixin(S_TRACE);
		createImage();
		return _imgData.width;
	}
	@property
	int height() { mixin(S_TRACE);
		createImage();
		createTitle();
		if (_createTitle) { mixin(S_TRACE);
			return _imgData.height + _parent._titleSpace + _parent._fontHeight + 1;
		} else { mixin(S_TRACE);
			return _imgData.height;
		}
	}

	@property
	Rectangle imageBounds() { mixin(S_TRACE);
		createImage();
		return new Rectangle(x, y, _imgData.width, _imgData.height);
	}
	@property
	Rectangle titleBounds() { mixin(S_TRACE);
		createImage();
		createTitle();
		if (getText() == "") return new Rectangle(0, 0, 0, 0);
		auto gc = new GC(_parent);
		scope (exit) gc.dispose();
		auto te = gc.textExtent(cutText(gc));
		int tx = (width - te.x) / 2 + x;
		int ty = y + _imgData.height + _parent._titleSpace;
		return new Rectangle(tx, ty, te.x, te.y);
	}

	string cutText(GC gc) { mixin(S_TRACE);
		return .cutText(getText(), gc, width);
	}

	override void dispose() { mixin(S_TRACE);
		auto img = getImage();
		if (img) img.dispose();
	}
}

private class CardListDragSourceEffect(C) : DragSourceEffect {
public:
	this (CardList!(C) list) { mixin(S_TRACE);
		super (list);
	}
private:
	Image _dImg;
	@property
	CardList!(C) list() { mixin(S_TRACE);
		return cast(CardList!(C)) getControl();
	}
	void disposeImage() { mixin(S_TRACE);
		if (_dImg !is null) { mixin(S_TRACE);
			_dImg.dispose();
			_dImg = null;
		}
	}
public override:
	void dragFinished(DragSourceEvent event) { mixin(S_TRACE);
		disposeImage();
	}
	void dragStart(DragSourceEvent event) { mixin(S_TRACE);
		auto clist = cast(CardList!(C)) getControl();
		int i = clist.searchIndex(event.x, event.y);
		if (i >= 0) { mixin(S_TRACE);
			disposeImage();
			auto sels = list.selectionItems;
			int left = int.max;
			int right = int.min;
			int top = int.max;
			int bottom = int.min;
			foreach (s; sels) { mixin(S_TRACE);
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
			auto d = clist.getDisplay();
			gc.setBackground(d.getSystemColor(SWT.COLOR_LIST_SELECTION));
			gc.setForeground(d.getSystemColor(SWT.COLOR_LIST_SELECTION_TEXT));
			foreach (s; sels) { mixin(S_TRACE);
				s.createImage();
				auto image = s.getImage();
				gc.drawImage(image, s.x - left, s.y - top);

				s.createTitle();
				if (s.getText() != "") { mixin(S_TRACE);
					auto tb = s.titleBounds();
					string title = s.cutText(gc);
					gc.fillRectangle(tb.x - left, tb.y - top, tb.width, tb.height);
					gc.drawText(title, tb.x - left, tb.y - top, true);
				}

				if (maxW < s.width) maxW = s.width;
			}
			scope data = img.getImageData();
			scope byte[] alphas;
			alphas.length = maxW;
			alphas[] = cast(byte) 255;
			foreach (s; sels) { mixin(S_TRACE);
				auto ib = s.imageBounds();
				auto tb = s.titleBounds();
				for (int y = ib.y - top; y < ib.y - top + ib.height; y++) { mixin(S_TRACE);
					data.setAlphas(ib.x - left, y, ib.width, alphas, 0);
				}
				if (s.getText() != "") { mixin(S_TRACE);
					for (int y = tb.y - top; y < tb.y - top + tb.height; y++) { mixin(S_TRACE);
						data.setAlphas(tb.x - left, y, tb.width, alphas, 0);
					}
				}
			}
			_dImg = new Image(Display.getCurrent(), data);
			event.image = _dImg;
			event.x += event.x - left;
			event.y += event.y - top;
		}
	}
}

/// nameの表示幅がmaxWより大きくなる場合、
/// はみ出す分を"..."に置換する。
string cutText(string name, GC gc, int maxW) { mixin(S_TRACE);
	int tw = gc.textExtent(name).x;
	if (tw > maxW) { mixin(S_TRACE);
		int dotw = gc.textExtent("...").x;
		dstring dname = to!dstring(name);
		while (dname.length && tw + dotw > maxW) { mixin(S_TRACE);
			dname = dname[0 .. $ - 1];
			tw = gc.textExtent(to!string(dname)).x;
		}
		name = to!string(dname) ~ "...";
		tw = gc.textExtent(name).x;
	}
	return name;
}
