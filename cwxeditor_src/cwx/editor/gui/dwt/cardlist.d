
module cwx.editor.gui.dwt.cardlist;

import cwx.utils;

import cwx.editor.gui.dwt.customtable : lineColor, fillColor;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dprops;

import core.thread;

import std.algorithm : countUntil, max, min, each;
import std.algorithm.sorting : sort;
import std.array;
import std.conv;
import std.datetime;

import org.eclipse.swt.all;

import java.lang.all;

public:

class CardList(C) : Composite {
public:
	/// 各カードに対して追加の描画を行う。
	void delegate(Control canvas, GC gc, in C card, Rectangle bounds)[] additionalPaint;

	/// Params:
	/// parent = 親コンポーネント。
	/// style = スタイル。使用可能なスタイルはSWT.MULTI、DWT.V_SCROLL、DWT.H_SCROLL。
	this (Composite parent, int style) { mixin(S_TRACE);
		super(parent, style | SWT.NO_BACKGROUND);
		auto d = getDisplay();
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
				auto img = new Image(Display.getCurrent(), area.width, area.height);
				auto gc = new GC(img);
				gc.setBackground(getBackground());
				gc.fillRectangle(area);
				gc = repaint(gc, img);
				e.gc.drawImage(img, 0, 0);
				gc.dispose();
				img.dispose();
			}
		});
		addListener(SWT.Resize, new class Listener {
			public override void handleEvent(Event e) { mixin(S_TRACE);
				resize();
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

		addListener(SWT.KeyUp, new class Listener {
			public override void handleEvent(Event e) { mixin(S_TRACE);
				_shift = (e.stateMask & SWT.SHIFT) != 0;
				_ctrl = (e.stateMask & SWT.CTRL) != 0;
			}
		});
		addListener(SWT.KeyDown, new class Listener {
			public override void handleEvent(Event e) { mixin(S_TRACE);
				_shift = (e.stateMask & SWT.SHIFT) != 0;
				_ctrl = (e.stateMask & SWT.CTRL) != 0;
				if (0 == count) return;
				bool multi = (getStyle() & SWT.MULTI) != 0;
				void updateCursor(int nCur) { mixin(S_TRACE);
					if (!_ctrl && !_shift) deselectAll();
					setCursor(nCur, true, !multi || !_shift);
					if (_shift && multi) { mixin(S_TRACE);
						auto minIndex = .min(_shiftP, _cur);
						auto maxIndex = .max(_shiftP, _cur);
						deselectAll();
						foreach (i; minIndex .. maxIndex + 1) { mixin(S_TRACE);
							if (0 <= i) { mixin(S_TRACE);
								select(i);
							}
						}
						callSelectChanged();
					} else { mixin(S_TRACE);
						_shiftP = _cur;
					}
				}
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
					if (_ctrl) return;
					int nCur = _cur - _wrap;
					if (nCur < 0) { mixin(S_TRACE);
						nCur = _wrap * (_line - 1) + _cur;
						if (_items.length <= nCur) nCur -= _wrap;
					}
					updateCursor(nCur);
					break;
				case SWT.ARROW_DOWN:
					if (_ctrl) return;
					int nCur = _cur + _wrap;
					if (_items.length <= nCur) { mixin(S_TRACE);
						nCur = _cur % _wrap;
					}
					updateCursor(nCur);
					break;
				case SWT.ARROW_LEFT:
					if (_ctrl) return;
					int nCur;
					if (isFirstCol(_cur)) { mixin(S_TRACE);
						nCur = _cur + _wrap - 1;
						if (_items.length <= nCur) nCur = cast(int)_items.length - 1;
					} else { mixin(S_TRACE);
						nCur = _cur - 1;
					}
					updateCursor(nCur);
					break;
				case SWT.ARROW_RIGHT:
					if (_ctrl) return;
					int nCur;
					if (_cur == _items.length - 1) { mixin(S_TRACE);
						int d = cast(int)_items.length % _wrap;
						nCur = cast(int)_items.length - (d == 0 ? _wrap : d);
					} else if (isLastCol(_cur)) { mixin(S_TRACE);
						nCur = _cur - _wrap + 1;
					} else { mixin(S_TRACE);
						nCur = _cur + 1;
					}
					updateCursor(nCur);
					break;
				default:
					e.doit = true;
				}
			}
		});
		addListener(SWT.MouseUp, new class Listener {
			public override void handleEvent(Event e) { mixin(S_TRACE);
				_shift = (e.stateMask & SWT.SHIFT) != 0;
				_ctrl = (e.stateMask & SWT.CTRL) != 0;
				if (e.button == 1 && (_startPos || _endPos)) { mixin(S_TRACE);
					mouseRelease();
					return;
				}
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
				_shift = (e.stateMask & SWT.SHIFT) != 0;
				_ctrl = (e.stateMask & SWT.CTRL) != 0;
				if (e.button == 1 || e.button == 3) { mixin(S_TRACE);
					forceFocus();
				}
				_dragging = false;
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
							if (_shift) { mixin(S_TRACE);
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
							} else if (!_ctrl) { mixin(S_TRACE);
								if (!isSelectedAt(i)) deselectAll();
								select(i);
								_shiftP = i;
								callSelectChanged();
							} else { mixin(S_TRACE);
								_shiftP = i;
							}
							setCursor(i, true, false);
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
					_shiftP = -1;
					_mouseP = -1;
					if ((getStyle() & SWT.MULTI) && e.button == 1) { mixin(S_TRACE);
						_startPos = new Point(e.x, e.y);
						if (!_ctrl && !_shift) { mixin(S_TRACE);
							deselectAll();
						}
					} else { mixin(S_TRACE);
						deselectAll();
					} mixin(S_TRACE);
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
				_shift = (e.stateMask & SWT.SHIFT) != 0;
				_ctrl = (e.stateMask & SWT.CTRL) != 0;
				int index = searchIndex(e.x, e.y);
				if (_oldMoveIndex != index) { mixin(S_TRACE);
					_oldMoveIndex = index;
					setDragDetect(index >= 0);
					refreshToolTip();
				}

				if ((getStyle() & SWT.MULTI) == 0) return;
				if (!_startPos) return;

				void redrawes() { mixin(S_TRACE);
					auto left = .min(_startPos.x, _endPos.x);
					auto top = .min(_startPos.y, _endPos.y);
					auto right = .max(_startPos.x, _endPos.x);
					auto bottom = .max(_startPos.y, _endPos.y);
					redraw(left, top, right - left + 1, bottom - top + 1, false);
				}
				if (_endPos) { mixin(S_TRACE);
					if (_endPos.x == e.x && _endPos.y == e.y) return;
					redrawes();
					_endPos.x = e.x;
					_endPos.y = e.y;
					updateRangeIndices();
				} else { mixin(S_TRACE);
					assert (_timer is null);
					if (index in _sels) { mixin(S_TRACE);
						// ドラッグが開始される場合
						mouseRelease();
						return;
					}

					startRangeSelection(e.x, e.y);
					updateRangeIndices();
				}
				redrawes();
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
				mouseRelease();
			}
		});
	}
	private void startRangeSelection(int x, int y) { mixin(S_TRACE);
		auto doAutoScroll = new class Runnable {
			private bool autoScroll(ulong pFrame, ScrollBar bar, lazy int width, ref int end, void delegate(int xy) scroll) { mixin(S_TRACE);
				if (!bar) return true;
				auto pos = bar.getSelection();
				int sIndex = 0;
				if (end < 0) { mixin(S_TRACE);
					if (pos <= 0) return true;
					auto count = end;
					sIndex = cast(int)(pFrame * 0.5 * count);
					if (0 <= sIndex) return false;
				} else { mixin(S_TRACE);
					if (end < width) return true;
					if (pos + 1 < bar.getMaximum() - bar.getThumb()) { mixin(S_TRACE);
						auto count = end - width + 1;
						sIndex = cast(int)(pFrame * 0.5 * count);
					}
					if (sIndex <= 0) return false;
				}
				if (sIndex == 0) return false;
				scroll(pos + sIndex);
				updateRangeIndices();
				return true;
			}
			override void run() { mixin(S_TRACE);
				if (_frame < _lastVFrame || _frame < _lastHFrame || isDisposed() || !_endPos || !_items.length) { mixin(S_TRACE);
					_lastVFrame = _frame;
					_lastHFrame = _frame;
					return;
				}
				auto pVFrame = _frame - _lastVFrame;
				auto pHFrame = _frame - _lastHFrame;
				if (0 < pVFrame && autoScroll(pVFrame, getVerticalBar(), getClientArea().height, _endPos.y, &scrollY)) _lastVFrame = _frame;
				if (0 < pHFrame && autoScroll(pHFrame, getHorizontalBar(), getClientArea().width, _endPos.x, &scrollX)) _lastHFrame = _frame;
			}
		};

		auto d = getDisplay();
		void autoScroll() { mixin(S_TRACE);
			while (_timerRunning) { mixin(S_TRACE);
				d.asyncExec(doAutoScroll);
				core.thread.Thread.sleep(dur!"msecs"(16));
				_frame++;
			}
		}
		_endPos = new Point(x, y);
		_timer = new core.thread.Thread(&autoScroll);
		_timerRunning = true;
		_frame = 0;
		_lastVFrame = 0;
		_lastHFrame = 0;
		if (!_ctrl && !_shift) deselectAll();
		_startSelected = null;
		.each!(i => _startSelected[i] = true)(selectionIndices);
		_timer.start();
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
	void setCursor(int index, bool scroll = false, bool select = true) { mixin(S_TRACE);
		if (_cur != index) { mixin(S_TRACE);
			if (_cur >= 0) redrawCard(_cur);
			if (index >= 0) redrawCard(index);
			_cur = index;
		}
		if (select) { mixin(S_TRACE);
			this.select(_cur);
			callSelectChanged();
		}
		if (scroll) this.scroll(_cur);
	}
	alias Composite.setCursor setCursor;
	/// カーソル位置を返す。
	@property
	int cursor() { mixin(S_TRACE);
		return _cur;
	}

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
				return cast(int)i;
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
				select(cast(int)i);
			}
		}
		resize();
		scrollX(ox);
		scrollY(oy);
		callSelectChanged();
	}
	@property
	int count() { mixin(S_TRACE);
		return cast(int)_items.length;
	}
	/// 選択中のアイテムの数。
	@property
	int selectionCount() { mixin(S_TRACE);
		return cast(int)_sels.length;
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
			if (_cur != -1 && _cur in _sels) { mixin(S_TRACE);
				return _cur;
			}
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
	/// ditto
	void refresh(int index) { mixin(S_TRACE);
		auto itm = _items[index];
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
		auto keys = _sels.keys;
		.sort(keys);
		foreach (i, key; keys) { mixin(S_TRACE);
			auto c = _sels[key];
			cs[i] = cast(C)c.getData();
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
			cardH += _titleSpace + _fontHeight + 1.ppis;
		}
		_defItmW = cardW;
		_defItmH = cardH;
		_itmW = cardW;
		_itmH = cardH;
		if (isVisible()) redraw();
	}
	void setLayoutValues(int marginX, int spaceX, int marginY, int spaceY, int titleSpace, int focusLinePadding, int defWrap) { mixin(S_TRACE);
		_marginX = marginX;
		_spaceX = spaceX;
		_marginY = marginY;
		_spaceY = spaceY;
		_titleSpace = titleSpace;
		_focusLinePadding = focusLinePadding;
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
					int colH = cast(int)_items.length / _defWrap;
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
		void scrollImpl(ScrollBar bar, int left, int width, void delegate(int) scr,
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
		scrollImpl(getVerticalBar(), itm.y, itm.height, &scrollY, &isFirstRow, &isLastRow, _marginY, _spaceY);
		scrollImpl(getHorizontalBar(), itm.x, itm.width, &scrollX, &isFirstCol, &isLastCol, _marginX, _spaceX);
	}
	void setToolTip(string delegate(C) createToolTip) { mixin(S_TRACE);
		_createToolTip = createToolTip;
		refreshToolTip();
	}
	Item getItem(int index) { mixin(S_TRACE);
		return _items[index];
	}
	int indexOf(Item item) { mixin(S_TRACE);
		return cast(int).countUntil(_items, item);
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
	void refreshToolTip() { mixin(S_TRACE);
		if (_createToolTip) { mixin(S_TRACE);
			if (0 <= _oldMoveIndex && _oldMoveIndex < _items.length) { mixin(S_TRACE);
				setToolTipText(.replace(_createToolTip(cast(C)_items[_oldMoveIndex].getData()), "&", "&&"));
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
			if (_startPos) { mixin(S_TRACE);
				if (!_endPos) { mixin(S_TRACE);
					startRangeSelection(_startPos.x, _startPos.y);
				}
				_startPos.x += _origin.x - bar.getSelection();
				updateRangeIndices();
			}
			_origin.x = bar.getSelection();
			redraw();
		}
	}
	void scrollY(int y) { mixin(S_TRACE);
		auto bar = getVerticalBar();
		if (bar !is null) { mixin(S_TRACE);
			bar.setSelection(y);
			if (_startPos) { mixin(S_TRACE);
				if (!_endPos) { mixin(S_TRACE);
					startRangeSelection(_startPos.x, _startPos.y);
				}
				_startPos.y += _origin.y - bar.getSelection();
				updateRangeIndices();
			}
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
	GC repaint(GC gc, Image canvas) { mixin(S_TRACE);
		if (_items.length == 0) return gc;
		auto rect = getClientArea();
		int w = rect.width;
		int index, iy, ix;
		int x;
		int y = _marginY - _origin.y;
		auto d = getDisplay();
		Image selBmp = null;
		{ mixin(S_TRACE);
			auto selBmp2 = new Image(d, 16, 16);
			scope (exit) selBmp2.dispose();
			auto selGC = new GC(selBmp2);
			scope (exit) selGC.dispose();
			selGC.setBackground(d.getSystemColor(SWT.COLOR_LIST_SELECTION));
			selGC.fillRectangle(0, 0, 16, 16);
			auto selData = selBmp2.getImageData();
			selData.alphaData = new byte[selData.width * selData.height];
			selData.alphaData[] = 64;
			selBmp = new Image(d, selData);
		}
		scope (exit) selBmp.dispose();
		auto selBounds = selBmp.getBounds();
		for (iy = 0; iy < _line; iy++) { mixin(S_TRACE);
			x = _marginX - _origin.x;
			for (ix = 0; ix < _wrap && (index = iy * _wrap + ix) < _items.length; ix++) { mixin(S_TRACE);
				auto itm = _items[index];
				itm.x = x;
				itm.y = y;
				if (!(getStyle() | SWT.VIRTUAL) || (y < rect.y + rect.height && rect.y <= y + _itmH)) { mixin(S_TRACE);
					if (gc) { mixin(S_TRACE);
						itm.createImage();
						auto image = itm.getImage();
						gc.drawImage(image, x, y);
						foreach (dlg; additionalPaint) { mixin(S_TRACE);
							dlg(this, gc, cast(C)itm.getData(), itm.imageBounds());
						}

						itm.createTitle();
						auto title = itm.cutText(gc);
						auto ib = itm.imageBounds();
						auto tb = itm.titleBounds();
						if (title != "") { mixin(S_TRACE);
							if (index in _sels) { mixin(S_TRACE);
								gc.setBackground(d.getSystemColor(SWT.COLOR_LIST_SELECTION));
								gc.setForeground(d.getSystemColor(SWT.COLOR_LIST_SELECTION_TEXT));
								gc.fillRectangle(tb);
								gc.wDrawText(title, tb.x, tb.y, true);
							} else { mixin(S_TRACE);
								gc.setBackground(getBackground());
								gc.setForeground(getForeground());
								gc.wDrawText(title, tb.x, tb.y, true);
							}
						}

						gc.setForeground(getForeground());
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
							gc.drawImage(selBmp, selBounds.x, selBounds.y, selBounds.width, selBounds.height, ib.x, ib.y, ib.width, ib.height);
						}
					}
				}
				x += _itmW;
				x += _spaceX;
			}
			y += _itmH;
			y += _spaceY;
		}
		if (_startPos && _endPos && gc) { mixin(S_TRACE);
			gc.dispose();
			gc = new GC(canvas);

			auto left = .min(_startPos.x, _endPos.x);
			auto top = .min(_startPos.y, _endPos.y);
			auto right = .max(_startPos.x, _endPos.x);
			auto bottom = .max(_startPos.y, _endPos.y);

			int lineAlpha;
			auto lineRGB = .dwtData(.lineColor, lineAlpha);
			int fillAlpha;
			auto fillRGB = .dwtData(.fillColor, fillAlpha);

			auto fillColor = new Color(d, fillRGB);
			scope (exit) fillColor.dispose();
			gc.setBackground(fillColor);
			gc.setAlpha(fillAlpha);
			gc.fillRectangle(left, top, right - left, bottom - top);
			auto lineColor = new Color(d, lineRGB);
			scope (exit) lineColor.dispose();
			gc.setForeground(lineColor);
			gc.setAlpha(lineAlpha);
			gc.drawRectangle(left, top, right - left, bottom - top);
		}
		return gc;
	}
	void resize() { mixin(S_TRACE);
		auto rect = getClientArea();
		int prW, prH;
		if (_items.length == 0) { mixin(S_TRACE);
			auto s = computeSize(SWT.DEFAULT, SWT.DEFAULT);
			prW = s.x;
			prH = s.y;
			_wrap = cast(int)_items.length;
			_line = 1;
		} else { mixin(S_TRACE);
			int w = rect.width;
			int colN = (w - (_marginX * 2) + _spaceX) / (_itmW + _spaceX);
			if (colN < 1) colN = 1;
			_wrap = colN;
			int colH = cast(int)_items.length / colN;
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

		refreshToolTip();
		repaint(null, null);
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

	void updateRangeIndices() { mixin(S_TRACE);
		if (!_startPos || !_endPos) return;
		if (!_ctrl) { mixin(S_TRACE);
			_startSelected = null;
			.each!(i => _startSelected[i] = true)(selectionIndices);
		}
		auto left = .min(_startPos.x, _endPos.x);
		auto top = .min(_startPos.y, _endPos.y);
		auto right = .max(_startPos.x, _endPos.x);
		auto bottom = .max(_startPos.y, _endPos.y);
		auto hbar = getHorizontalBar();
		if (hbar) { mixin(S_TRACE);
			auto hPos = hbar.getSelection();
			left += hPos;
			right += hPos;
		}
		auto vbar = getVerticalBar();
		if (vbar) { mixin(S_TRACE);
			auto vPos = vbar.getSelection();
			top += vPos;
			bottom += vPos;
		}
		bool[int] inRanges2;

		if (_marginY <= top && _marginX <= left) { mixin(S_TRACE);
			int colFrom = (left - _marginX + _spaceX) / (_itmW + _spaceX);
			int colTo = (right - _marginX) / (_itmW + _spaceX);
			if (_wrap <= colTo) colTo = _wrap - 1;
			int rowFrom = (top - _marginY + _spaceY) / (_itmH + _spaceY);
			int rowTo = (bottom - _marginY) / (_itmH + _spaceY);
			foreach (col; colFrom .. colTo + 1) { mixin(S_TRACE);
				foreach (row; rowFrom .. rowTo + 1) { mixin(S_TRACE);
					auto index = (row * _wrap) + col;
					if (0 <= index && index < _items.length) { mixin(S_TRACE);
						inRanges2[index] = true;
					}
				}
			}
		}
		if (_inRanges == inRanges2) return;

		bool[int] indices;
		foreach (i; _inRanges.byKey()) indices[i] = true;
		foreach (i; inRanges2.byKey()) indices[i] = true;

		foreach (index; indices.byKey()) { mixin(S_TRACE);
			auto inRange = (index in inRanges2) !is null;
			auto sel = false;
			if (_ctrl) { mixin(S_TRACE);
				if (index in _startSelected) { mixin(S_TRACE);
					sel = !inRange;
				} else { mixin(S_TRACE);
					sel = inRange;
				}
			} else { mixin(S_TRACE);
				sel = inRange;
			}
			if (sel) { mixin(S_TRACE);
				select(index);
			} else { mixin(S_TRACE);
				deselect(index);
			}
		}
		_inRanges = inRanges2;

		callSelectChanged();
	}
	void mouseRelease() { mixin(S_TRACE);
		if ((getStyle() & SWT.MULTI) == 0) return;
		if (!_startPos) return;
		auto sx = _startPos.x;
		auto sy = _startPos.y;
		_startPos = null;
		if (!_endPos) return;
		assert (_timer !is null);
		auto ex = _endPos.x;
		auto ey = _endPos.y;
		_endPos = null;
		auto left = .min(sx, ex);
		auto top = .min(sy, ey);
		auto right = .max(sx, ex);
		auto bottom = .max(sy, ey);
		redraw(left, top, right - left + 1, bottom - top + 1, false);
		_timerRunning = false;
		_timer.join();
		_timer = null;
		_startSelected = null;
		_inRanges = null;
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

	// 範囲選択周り
	ulong _frame = 0;
	ulong _lastVFrame = 0;
	ulong _lastHFrame = 0;
	auto _timerRunning = false;
	core.thread.Thread _timer = null;
	bool[int] _startSelected;
	bool[int] _inRanges;
	Point _startPos = null;
	Point _endPos = null;
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
			return _imgData.height + _parent._titleSpace + _parent._fontHeight + 1.ppis;
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
		auto te = gc.wTextExtent(cutText(gc));
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
		auto clist = cast(CardList!(C))getControl();
		int i = clist.searchIndex(event.x, event.y);
		if (i >= 0) { mixin(S_TRACE);
			auto ca = clist.getClientArea();
			disposeImage();
			CardListItem!C[] sels;
			foreach (itm; list.selectionItems) { mixin(S_TRACE);
				if (ca.intersects(itm.x, itm.y, itm.width, itm.height)) {
					sels ~= itm;
				}
			}

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
					gc.wDrawText(title, tb.x - left, tb.y - top, true);
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
	int tw = gc.wTextExtent(name).x;
	if (tw > maxW) { mixin(S_TRACE);
		int dotw = gc.wTextExtent("...").x;
		dstring dname = to!dstring(name);
		while (dname.length && tw + dotw > maxW) { mixin(S_TRACE);
			dname = dname[0 .. $ - 1];
			tw = gc.wTextExtent(to!string(dname)).x;
		}
		name = to!string(dname) ~ "...";
		tw = gc.wTextExtent(name).x;
	}
	return name;
}
