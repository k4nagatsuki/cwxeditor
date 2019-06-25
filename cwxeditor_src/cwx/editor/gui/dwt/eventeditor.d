
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
import cwx.editor.gui.dwt.cardlist : cutText;

import std.algorithm;
import std.array : array, replace;
import std.ascii;
import std.conv;
import std.datetime;
import std.string;
import std.typecons;

import org.eclipse.swt.all;
import java.lang.all;

private class PosInfo {
	int depth1;
	int depth2;
	int relY;
	int height;
	int index;
	int lineNumber;
	Content content;
	string eventText;
	int eventTextWidth;
	int commentLineX = 0;
	Rectangle commentRect = null;
	bool nameVisible = true;

	this (int depth1, int depth2, int relY, int height, int index, int lineNumber, Content content, string eventText, int eventTextWidth) {
		this.depth1 = depth1;
		this.depth2 = depth2;
		this.relY = relY;
		this.height = height;
		this.index = index;
		this.lineNumber = lineNumber;
		this.content = content;
		this.eventText = eventText;
		this.eventTextWidth = eventTextWidth;
	}
}
private class StartInfo {
	Content start;
	int y = 0;
	int cHeight = 0;
	ulong updateCounter = 0;
	size_t fromIndex = 0;
	size_t toIndex = 0;
	StartInfo prev = null;
	StartInfo next = null;

	@property
	const
	size_t count() { mixin(S_TRACE);
		return toIndex - fromIndex;
	}
}

class EventEditorItem : Item {
	private EventEditor _parent;

	private this (EventEditor parent, Content c) { mixin(S_TRACE);
		super (parent, style);
		_parent = parent;
		setData(c);
	}
	static EventEditorItem valueOf(EventEditor parent, Content c) { mixin(S_TRACE);
		auto itm = parent._items.get(c.eventId, null);
		if (!itm) { mixin(S_TRACE);
			itm = new EventEditorItem(parent, c);
			parent._items[c.eventId] = itm;
		}
		return itm;
	}

	EventEditor getParent() { return _parent; }

	EventEditorItem getParentItem() { mixin(S_TRACE);
		auto c = cast(Content)getData();
		if (c.parent) { mixin(S_TRACE);
			return EventEditorItem.valueOf(getParent(), c.parent);
		}
		return null;
	}
	EventEditorItem getItem(int index) { mixin(S_TRACE);
		auto c = cast(Content)getData();
		return EventEditorItem.valueOf(getParent(), c.next[index]);
	}
	EventEditorItem[] getItems() { mixin(S_TRACE);
		auto c = cast(Content)getData();
		auto items = new EventEditorItem[c.next.length];
		foreach (i; 0 .. c.next.length) { mixin(S_TRACE);
			items[i] = getItem(cast(int)i);
		}
		return items;
	}
	int getItemCount() { mixin(S_TRACE);
		auto c = cast(Content)getData();
		return cast(int)c.next.length;
	}
	int indexOf(EventEditorItem itm) { mixin(S_TRACE);
		auto targ = cast(Content)itm.getData();
		auto c = cast(Content)getData();
		foreach (i, child; c.next) { mixin(S_TRACE);
			if (child is targ) { mixin(S_TRACE);
				return cast(int)i;
			}
		}
		return -1;
	}

	void setExpanded(bool expanded) { mixin(S_TRACE);
		auto c = cast(Content)getData();
		if (_parent._expanded.get(c.eventId, true) != expanded) { mixin(S_TRACE);
			_parent._expanded[c.eventId] = expanded;
			_parent.updatePosOne(c);
		}
	}
	bool getExpanded() { mixin(S_TRACE);
		auto c = cast(Content)getData();
		return _parent._expanded.get(c.eventId, true);
	}
	Rectangle getBounds() { mixin(S_TRACE);
		auto c = cast(Content)getData();
		if (c.eventId !in _parent._posTable) return null;
		auto gc = new GC(_parent);
		scope (exit) gc.dispose();
		auto pos = _parent._posTable[c.eventId];
		auto sy = _parent.getVerticalBar().getSelection() * _parent._lineHeight;
		auto startInfo = _parent._startInfos[pos.content.parentStart.eventId];
		return new Rectangle(0, (startInfo.y + pos.relY) - sy, pos.eventTextWidth + 4.ppis, pos.height);
	}
	Rectangle getImageBounds() { mixin(S_TRACE);
		auto c = cast(Content)getData();
		auto index = _parent.indexOf(c);
		auto pos = _parent._pos[index];
		auto sx = _parent.getHorizontalBar().getSelection();
		auto sy = _parent.getVerticalBar().getSelection() * _parent._lineHeight;
		auto startInfo = _parent._startInfos[pos.content.parentStart.eventId];
		return new Rectangle(_parent.calcX(pos) - sx, (startInfo.y + pos.relY) + _parent._imgPos - sy, _parent._imageWidth, _parent._lineHeight - _parent._imgPos - _parent._imgPos);
	}
}

class EventEditor : Composite {
	private Commons _comm;
	private Summary _summ;
	private EventTree _et;
	private bool[string] _expanded;
	private int _splitter;
	private int _imageWidth = 16;
	private int _lineHeight = 16;
	private int _lineTextY = 0;
	private int _imgPos = 0;
	private int _heightSum = 0;
	private int _widthSum = 0;
	private int _lineNumWidth = 0;
	private Content _selected = null, _lightup = null;
	private Content _selectedParentStart = null, _lightupParentStart = null;
	private int _selectedIndex = -1;
	/// yの順に整列した位置リスト。
	private PosInfo[] _pos;
	/// イベントコンテントをキーに位置を取るテーブル。
	private PosInfo[string] _posTable;
	private EventEditorItem[string] _items;
	/// スタートコンテントの位置と前後情報。
	private StartInfo[string] _startInfos;
	private StartInfo _firstStartInfo = null;
	/// 名前をキーにしたスタートコンテントのテーブル。
	private StartInfo[string] _startInfoWithName;

	private Color _lineColor = null;
	private Color _selectedColor = null;
	private Color _lightupColor = null;

	private Cursor _cursor = null;
	private bool _changeCursor = false;
	private bool _moveDetailLine = false;
	private Image _warningImage = null;

	private Warning[] _warningRects;

	private bool _expandedOperation = false;
	private bool _showEventTreeDetail = true;
	private bool _showLineNumber = false;
	private int _detailAreaWidth = 0;

	private bool[string] _updateContents; /// 次の描画で位置計算をやり直すスタートコンテント。
	private bool _updatePosAll = true; /// 次の描画で全ての位置計算をやり直す。
	private bool _updateEventText = true; /// 次の描画でイベントテキストの位置計算のみやり直す。
	private bool _showSelection = false;
	private bool _updateCommentPos = false; /// 次の描画でコメントの位置計算のみやり直す。
	private bool _updatedPos = false; /// 位置計算を行って再描画が完了するまでの間はtrue。

	this (Commons comm, Composite parent, int style, Summary summ, EventTree et) { mixin(S_TRACE);
		super (parent, style | SWT.V_SCROLL | SWT.H_SCROLL | SWT.DOUBLE_BUFFERED);
		auto d = getDisplay();
		_comm = comm;
		_summ = summ;
		_et = et;
		auto gc = new GC(this);
		scope (exit) gc.dispose();
		auto th = gc.getFontMetrics().getHeight();
		_imageWidth = _imageWidth.ppis;
		_lineHeight = .max(_lineHeight, th);
		_lineTextY = (_lineHeight - th) / 2;
		_imgPos = (_lineHeight - _comm.prop.images.content(CType.Start).getBounds().height) / 2;
		_detailAreaWidth = _comm.prop.var.etc.detailAreaWidth;

		auto vbar = getVerticalBar();
		vbar.setMinimum(0);
		vbar.setMaximum(1);
		vbar.setSelection(0);
		vbar.setIncrement(1);
		vbar.setPageIncrement(1);
		vbar.setThumb(1);
		auto hbar = getHorizontalBar();
		hbar.setMinimum(0);
		hbar.setMaximum(32.ppis);
		hbar.setSelection(0);
		hbar.setIncrement(16.ppis);
		hbar.setPageIncrement(32.ppis);
		hbar.setThumb(32.ppis);
		.listener(this, SWT.Resize, &updateScrollBar);
		.listener(hbar, SWT.Selection, &redraw);
		.listener(vbar, SWT.Selection, &redraw);

		setBackground(d.getSystemColor(SWT.COLOR_WHITE));
		auto color = new Color(d, new RGB(96, 96, 96));
		_lineColor = new Color(d, new RGB(192, 192, 192));
		_selectedColor = new Color(d, new RGB(128, 191, 255));
		_lightupColor = new Color(d, new RGB(191, 224, 255));
		_warningImage = .warningImage(_comm.prop, d);
		setForeground(color);
		if (_summ) _comm.refEventEditorStyle.add(&updatePosAll);
		.listener(this, SWT.Dispose, { mixin(S_TRACE);
			_lineColor.dispose();
			_selectedColor.dispose();
			_lightupColor.dispose();
			color.dispose();
			_warningImage.dispose();
			clearInfo();
			if (_summ) _comm.refEventEditorStyle.remove(&updatePosAll);
		});
		.listener(this, SWT.Paint, &onPaint);
		.listener(this, SWT.MouseWheel, &onMouseWheel);
		.listener(this, SWT.Traverse, &onTraverse);
		.listener(this, SWT.MouseDown, &onMouseDown);
		.listener(this, SWT.MouseUp, &onMouseUp);
		.listener(this, SWT.MouseMove, &onMouseMove);
		.listener(this, SWT.MouseEnter, &onMouseEnter);
		.listener(this, SWT.MouseExit, &onMouseExit);
		.listener(this, SWT.MouseDoubleClick, &onMouseDoubleClick);
		.listener(this, SWT.KeyDown, &onKeyDown);
		.listener(this, SWT.FocusIn, &onFocusInOut);
		.listener(this, SWT.FocusOut, &onFocusInOut);
		.listener(this, SWT.Resize, { mixin(S_TRACE);
			_updateCommentPos = true;
			redraw();
		});
		setDragDetect(true);
		updateEventTree();
	}

	@property
	inout
	inout(EventTree) eventTree() { return _et; }
	@property
	void eventTree(EventTree et) { mixin(S_TRACE);
		if (_et is et) return;
		if (_et) { mixin(S_TRACE);
			auto lineNumber = getVerticalBar().getSelection();
			if (_selectedIndex == -1 || (lineNumber == 0 && _selectedIndex == 0)) { mixin(S_TRACE);
				removeStoredLine(_et.eventTreeId);
			} else { mixin(S_TRACE);
				_storedLine[_et.eventTreeId] = StoredLine(lineNumber, _selectedIndex);
			}
		}
		_et = et;

		if (_et && _comm.prop.var.etc.restorePositionOfEventTreeView && _et.eventTreeId in _storedLine) { mixin(S_TRACE);
			_restoreLine = true;
		}
		updateEventTree();
	}
	void removeStoredLine(string eventTreeId) { mixin(S_TRACE);
		if (eventTreeId in _storedLine) _storedLine.remove(eventTreeId);
	}
	private alias Tuple!(int, "lineNumber", int, "selected") StoredLine;
	private StoredLine[string] _storedLine;
	private bool _restoreLine = false;

	private void clearInfo() { mixin(S_TRACE);
		_expanded = null;
		_selected = null;
		_selectedParentStart = null;
		_selectedIndex = -1;
		_lightup = null;
		_lightupParentStart = null;
		_pos = [];
		_posTable = null;
		_startInfos = null;
		_startInfoWithName = null;
		_firstStartInfo = null;
		_items = null;
		_warningRects = [];
	}

	void expandAll() { mixin(S_TRACE);
		if (!_startInfos.length) return;
		_expanded = null;
		updatePosAll();
	}
	void foldAll() { mixin(S_TRACE);
		if (!_startInfos.length) return;
		bool update = false;
		foreach (start; _et.starts) { mixin(S_TRACE);
			if (_expanded.get(start.eventId, true)) { mixin(S_TRACE);
				_expanded[start.eventId] = false;
				update = true;
			}
		}
		if (update) updatePosAll();
	}

	void showSelection() { mixin(S_TRACE);
		if (_showSelection || _updatePosAll || _updatedPos || _updateContents.length) { mixin(S_TRACE);
			_showSelection = true;
			return;
		}
		_showSelection = false;
		updatePosImpl2(false);
		showSelectionImpl();
	}
	private void showSelectionImpl() { mixin(S_TRACE);
		if (!_selected) return;
		if (_selected.eventId !in _posTable) return;
		auto pos = _posTable[_selected.eventId];
		auto startInfo = _startInfos[_selectedParentStart.eventId];
		scroll((startInfo.y + pos.relY) / _lineHeight, pos.height);
	}
	private void scroll(int pos, int height) { mixin(S_TRACE);
		_showSelection = false;
		updatePosImpl2(false);
		auto vbar = getVerticalBar();
		int vPos = vbar.getSelection();
		int thumb = getClientArea().height / _lineHeight;
		if (pos < vPos) { mixin(S_TRACE);
			vbar.setSelection(pos);
		} else if (vPos + thumb <= pos + (height / _lineHeight)) { mixin(S_TRACE);
			vbar.setSelection(pos - thumb + (height / _lineHeight));
		}
	}

	@property
	const
	bool showEventTreeDetail() { mixin(S_TRACE);
		return _showEventTreeDetail;
	}
	@property
	void showEventTreeDetail(bool v) { mixin(S_TRACE);
		_showEventTreeDetail = v;
		updateScrollBar();
		redraw();
	}

	@property
	const
	bool showLineNumber() { mixin(S_TRACE);
		return _showLineNumber;
	}
	@property
	void showLineNumber(bool v) { mixin(S_TRACE);
		_showLineNumber = v;
		updateWidthSum();
		updateScrollBar();
		redraw();
	}

	private void updateEventTree() { mixin(S_TRACE);
		_items = null;
		updatePosAll();
		.asyncExec(getDisplay(), { mixin(S_TRACE);
			if (isDisposed()) return;
			redraw();
		});
	}
	void updateEventText() { mixin(S_TRACE);
		_updateEventText = true;
		getDisplay.asyncExec(new class Runnable {
			override void run() { mixin(S_TRACE);
				if (isDisposed()) return;
				updatePosImpl2(false);
				redraw();
			}
		});
	}

	private void updateEventTextImpl() { mixin(S_TRACE);
		if (!_updateEventText) return;
		_updateEventText = false;
		if (!_et) return;
		if (!_startInfos.length) return;
		auto gc = new GC(this);
		scope (exit) gc.dispose();
		auto posY = new int[_pos.length];
		auto startInfo = _firstStartInfo;
		_startInfoWithName = null;
		while (startInfo) { mixin(S_TRACE);
			_startInfoWithName[startInfo.start.name] = startInfo;
			assert (startInfo.start.tree is _et);
			// テキストが更新されたイベントコンテントの位置は
			// スタートコンテントのupdateCounterで検知できる
			// いくつかのイベントコンテントに限っては外的要因(ステップ値の編集など)で
			// updateCounterが更新されずにテキストが変化する可能性がある。
			auto update = startInfo.updateCounter != startInfo.start.updateCounter;
			for (auto i = startInfo.fromIndex; i < startInfo.toIndex; i++) { mixin(S_TRACE);
				auto c = _pos[i].content;
				auto branch = false;
				if (c.parent) { mixin(S_TRACE);
					switch (c.parent.type) {
					case CType.BranchFlag:
					case CType.BranchMultiStep:
					case CType.BranchStep:
					case CType.BranchArea:
					case CType.BranchBattle:
					case CType.BranchCast:
					case CType.BranchItem:
					case CType.BranchSkill:
					case CType.BranchInfo:
					case CType.BranchBeast:
					case CType.BranchCoupon:
					case CType.BranchMultiCoupon:
					case CType.BranchGossip:
						branch = true;
						break;
					default:
						break;
					}
				}
				if (update || branch || (c.parent && c.parent.detail.nextType is CNextType.Text)) { mixin(S_TRACE);
					_posTable[c.eventId] = _pos[i];
				}

				posY[i] = startInfo.y + _pos[i].relY;
			}
			startInfo.updateCounter = startInfo.start.updateCounter;

			startInfo = startInfo.next;
		}
		updateCommentPos(gc, posY);
		updateScrollBar();
	}

	/// cの情報のみ更新する。
	void updateContentInfo(in Content c) { mixin(S_TRACE);
		assert (c.tree is _et);
		auto startInfo = _startInfos[c.parentStart.eventId];
		// updateCounterの値をずらしてupdateEventText()の処理を流用する
		startInfo.updateCounter--;
		updateEventText();
	}

	/// 次の再描画でcが属するツリーの位置計算をやり直す事を通知する。
	void updatePosOne(in Content c) { mixin(S_TRACE);
		auto eventId = c.parentStart.eventId;
		_updateContents[eventId] = true;
		getDisplay.asyncExec(new class Runnable {
			override void run() { mixin(S_TRACE);
				if (isDisposed()) return;
				updatePosImpl2(false);
				redraw();
			}
		});
	}
	/// 次の再描画で全ての位置計算をやり直す事を通知する。
	private void updatePosAll() { mixin(S_TRACE);
		_updatePosAll = true;
		getDisplay.asyncExec(new class Runnable {
			override void run() { mixin(S_TRACE);
				if (isDisposed()) return;
				updatePosImpl2(false);
				redraw();
			}
		});
	}

	private int calcEventTextWidth(GC gc, Content c, out string s) { mixin(S_TRACE);
		auto eventTextWidth = 0;
		s = .eventText(_comm, _summ, c.parent, c, !(getStyle() & SWT.READ_ONLY));
		StartInfo *p = null;
		if (c.name == "" && c.parent && c.parent.detail.nextType is CNextType.Text) { mixin(S_TRACE);
			s = _comm.skin.evtChildOK;
		}
		if (s.length) eventTextWidth = gc.wTextExtent(s).x;
		if (_comm.prop.var.etc.showTargetStartLineNumber && c.detail.use(CArg.Start)) { mixin(S_TRACE);
			// リンク先スタートコンテントの行
			p = c.start in _startInfoWithName;
			if (p) { mixin(S_TRACE);
				auto startInfo = *p;
				auto line = _posTable[startInfo.start.eventId].lineNumber;
				eventTextWidth += gc.wTextExtent(.text(line)).x;
				auto ay = _lineHeight / 4;
				if (s.length) eventTextWidth += ay * 2;
				eventTextWidth += ay * 3;
			}
		}
		if (_comm.prop.var.etc.showTargetStartLineNumber && c.type is CType.Start) { mixin(S_TRACE);
			// スタートコンテントへのリンク元の行
			auto ay = _lineHeight / 4;
			auto userWidth = ay * 4;
			foreach (i, u; c.startUseCounter.values(toStartId(c.name))) { mixin(S_TRACE);
				auto cu = cast(Content)u;
				if (!cu) continue;
				assert (cu.eventId in _posTable);
				auto pos = _posTable[cu.eventId];
				auto line = pos.lineNumber;
				if (0 < i) userWidth += ay * 2;
				userWidth += gc.wTextExtent(.text(line)).x;
			}
			eventTextWidth += userWidth;
		}
		return eventTextWidth;
	}

	private void createPosInfoRecurse(GC gc, int x, int depth1, int depth2, Content c, ref PosInfo[] pos, ref int[] posY, ref int index, ref int lineNumber, ref int relY, ref int heightSum, ref int width, ref bool[string] expanded2) { mixin(S_TRACE);
		while (true) { mixin(S_TRACE);
			auto type = c.type;
			int height = _lineHeight;
			int y = heightSum * _lineHeight;
			heightSum++;
			if ((_summ ? _comm.prop.var.etc.showTerminalMark : showTerminalMark) && type != CType.Start && !c.next.length) { mixin(S_TRACE);
				height = _lineHeight * 2;
				heightSum++;
			}

			pos ~= new PosInfo(depth1, depth2, relY, height, index, lineNumber, c, "", 0);
			posY ~= y;
			_posTable[c.eventId] = pos[$ - 1];
			relY += height;
			index++;
			lineNumber++;

			// 幅計算
			width = .max(width, calcRight(pos[$ - 1], x));

			if (c.next.length && !_expanded.get(c.eventId, true)) { mixin(S_TRACE);
				// 折りたたまれている
				expanded2[c.eventId] = false;
				foreach (n; c.allChildren) { mixin(S_TRACE);
					// スタートへのリンク元を出すため、行番号情報のみテーブルに入れておく
					_posTable[n.eventId] = new PosInfo(-1, -1, -1, -1, -1, lineNumber, n, "", 0);
					lineNumber++;
				}
				break;
			}
			if (type != CType.Start && c.next.length == 1 && (!(_summ ? _comm.prop.var.etc.forceIndentBranchContent : forceIndentBranchContent) || !c.type.isBranchContent)) { mixin(S_TRACE);
				x += slope;
				depth2++;
				c = c.next[0];
				continue; // 再帰回避
			} else if (c.next.length == 1) { mixin(S_TRACE);
				x += _imageWidth;
				depth1++;
				c = c.next[0];
				continue; // 再帰回避
			} else { mixin(S_TRACE);
				foreach (next; c.next) { mixin(S_TRACE);
					createPosInfoRecurse(gc, x + _imageWidth, depth1 + 1, depth2, next, pos, posY, index, lineNumber, relY, heightSum, width, expanded2);
				}
			}
			break;
		}
	}
	/// 位置計算をやり直す。
	private void updatePosImpl2(bool fromRedraw) { mixin(S_TRACE);
		if (!_updatePosAll && !_updateContents.length) { mixin(S_TRACE);
			if (_updateEventText) { mixin(S_TRACE);
				updateEventTextImpl();
			}
			return;
		}
		int selIndex = 0;
		auto oldSel = _selected;
		selIndex = _selectedIndex;
		_selectedIndex = -1;

		_lightup = null;
		_lightupParentStart = null;

		auto gc = new GC(this);
		scope (exit) gc.dispose();
		int[] posY;
		updateStartInfo(gc, posY);

		if (oldSel && oldSel.eventId in _posTable && _posTable[oldSel.eventId].index != -1) { mixin(S_TRACE);
			_selected = oldSel;
			_selectedParentStart = oldSel.parentStart;
			_selectedIndex = _posTable[oldSel.eventId].index;
		} else if (_pos.length) { mixin(S_TRACE);
			_selectedIndex = .max(0, .min(selIndex, _pos.length - 1));
			_selected = _pos[_selectedIndex].content;
			_selectedParentStart = _selected.parentStart;
		} else { mixin(S_TRACE);
			_selected = null;
			_selectedParentStart = null;
			_selectedIndex = -1;
		}

		updateCommentPos(gc, posY);
		updateScrollBar();
		if (_pos.length && _pos[$ - 1].content.type is CType.Start) { mixin(S_TRACE);
			// FIXME: 末尾にスタートコンテントがあると縦スクロールバーの幅がおかしくなる事があるので
			auto isShowSelection = _showSelection;
			getDisplay.asyncExec(new class Runnable {
				override void run() { mixin(S_TRACE);
					if (isDisposed()) return;
					updateScrollBar();
					if (isShowSelection) { mixin(S_TRACE);
						showSelection();
					}
					redraw();
				}
			});
		}
		if (!fromRedraw) redraw();
		if (_selected !is oldSel && _selected) { mixin(S_TRACE);
			callSelectChanged();
		}
	}

	/// 部分再描画処理。スタートコンテントを挿入・更新する。
	private void updateStartInfo(GC gc, ref int[] posY) { mixin(S_TRACE);
		if (!_et || !_et.starts.length) { mixin(S_TRACE);
			clearInfo();
			_updatePosAll = false;
			_updateContents = null;
			return;
		}
		if (!_updatePosAll && !_updateContents.length) { mixin(S_TRACE);
			return;
		}
		if (_updatePosAll) { mixin(S_TRACE);
			_startInfos = null;
		} else { mixin(S_TRACE);
			removeStarts();
			assert (_startInfos.length <= _et.starts.length);
		}

		_heightSum = 0;
		PosInfo[] pos;
		_posTable = null;
		int index = 0;
		int lineNumber = 1;
		bool[string] expanded2;
		StartInfo beforeInfo = null;
		StartInfo[string] newStartInfos;
		_firstStartInfo = null;
		_startInfoWithName = null;
		foreach (start; _et.starts) { mixin(S_TRACE);
			StartInfo startInfo = null;
			auto fromIndex = pos.length;
			auto heightSumB = _heightSum;
			auto y = heightSumB * _lineHeight;
			void createInfos() { mixin(S_TRACE);
				int width = 0;
				int relY = 0;
				createPosInfoRecurse(gc, 0, 0, 0, start, pos, posY, index, lineNumber, relY, _heightSum, width, expanded2);
				startInfo.cHeight = _heightSum - heightSumB;
			}
			auto p = _startInfos.length ? start.eventId in _startInfos : null;
			if (!p) { mixin(S_TRACE);
				// 挿入
				startInfo = new StartInfo;
				createInfos();
			} else { mixin(S_TRACE);
				startInfo = *p;
				void addPoss(StartInfo startInfo) { mixin(S_TRACE);
					foreach (ref info; _pos[startInfo.fromIndex .. startInfo.toIndex]) { mixin(S_TRACE);
						posY ~= y + info.relY;
						info.index = index;
						info.lineNumber = lineNumber;
						_posTable[info.content.eventId] = info;
						index++;
						lineNumber++;
						auto expand = _expanded.get(info.content.eventId, true);
						if (!expand) { mixin(S_TRACE);
							expanded2[info.content.eventId] = false;
							foreach (n; info.content.allChildren) { mixin(S_TRACE);
								_posTable[n.eventId] = new PosInfo(-1, -1, -1, -1, -1, lineNumber, n, "", 0);
								lineNumber++;
							}
						}
					}
					pos ~= _pos[startInfo.fromIndex .. startInfo.toIndex];
					_heightSum += startInfo.cHeight;
				}
				if (start !is startInfo.start || startInfo.updateCounter != startInfo.start.updateCounter || start.eventId in _updateContents) { mixin(S_TRACE);
					// 更新
					if (start !is startInfo.start && start.eventId in _startInfos) { mixin(S_TRACE);
						// スタートの位置の入れ替えなどが発生している
						auto s = _startInfos[start.eventId];
						addPoss(s);
						startInfo.cHeight = s.cHeight;
					} else { mixin(S_TRACE);
						// ツリーの内容が更新されている
						createInfos();
					}
				} else { mixin(S_TRACE);
					// 何もしない
					addPoss(startInfo);
				}
			}
			startInfo.start = start;
			startInfo.y = y;
			startInfo.updateCounter = start.updateCounter;
			startInfo.fromIndex = fromIndex;
			startInfo.toIndex = pos.length;
			newStartInfos[start.eventId] = startInfo;
			startInfo.prev = beforeInfo;
			if (beforeInfo) { mixin(S_TRACE);
				beforeInfo.next = startInfo;
			}

			beforeInfo = startInfo;
			if (!_firstStartInfo) _firstStartInfo = startInfo;

			_startInfoWithName[start.name] = startInfo;
		}
		if (beforeInfo) beforeInfo.next = null;

		assert (index == pos.length);
		assert (pos.length <= _posTable.length); // _posTableには行番号のみ保持しているアイテムがある
		assert (posY.length == pos.length);
		assert (_et.starts.length == newStartInfos.length);

		_posTable.rehash();
		newStartInfos.rehash();

		_pos = pos;
		_startInfos = newStartInfos;
		_expanded = expanded2;

		_updatePosAll = false;
		_updateContents = null;
		_updatedPos = true;
	}

	/// 部分再描画処理。ツリーから取り除かれたスタートコンテントを削除する。
	private void removeStarts() { mixin(S_TRACE);
		if (!_et) return;
		if (!_startInfos.length) return;

		auto startInfo = _firstStartInfo;
		size_t removedPosCount = 0;
		int removedHeight = 0;
		while (startInfo) { mixin(S_TRACE);
			startInfo.fromIndex -= removedPosCount;
			startInfo.toIndex -= removedPosCount;

			if (startInfo.start.tree is _et) { mixin(S_TRACE);
				startInfo.y -= removedHeight * _lineHeight;
				startInfo = startInfo.next;
				continue;
			}
			assert (startInfo.start.tree is null);

			if (startInfo.prev) startInfo.prev.next = startInfo.next;
			if (startInfo.next) startInfo.next.prev = startInfo.prev;
			removedPosCount += startInfo.count;
			removedHeight += startInfo.cHeight;

			_pos = _pos[0 .. startInfo.fromIndex] ~ _pos[startInfo.toIndex .. $];
			_updateContents.remove(startInfo.start.eventId);
			_startInfos.remove(startInfo.start.eventId);

			startInfo = startInfo.next;
		}
	}

	/// コメント位置を計算する。
	private void updateCommentPos(GC gc, in int[] posY) { mixin(S_TRACE);
		if (!isVisible()) { mixin(S_TRACE);
			_updateCommentPos = true;
			return;
		}

		_widthSum = 0;
		foreach (ptrdiff_t i, ref pos; _pos) { mixin(S_TRACE);
			pos.eventTextWidth = calcEventTextWidth(gc, pos.content, pos.eventText);
			_widthSum = .max(_widthSum, calcRight(pos));
		}

		_updateCommentPos = false;
		auto ca = getClientArea();
		Rectangle[] boxes;
		Rectangle[string] cBoxes;
		string[] comments;
		Rectangle itemRect(int y, ref PosInfo pos) { mixin(S_TRACE);
			auto c = pos.content;
			if (auto p = c.eventId in cBoxes) { mixin(S_TRACE);
				return *p;
			}
			int rx = 20.ppis + pos.eventTextWidth;

			auto height = _lineHeight;
			auto rect = new Rectangle(calcX(pos), y, rx, height);
			cBoxes[c.eventId] = rect;
			return rect;
		}
		auto hh = _lineHeight / 2;
		auto ucExtent = gc.wTextExtent(_comm.prop.msgs.startUseCount);
		foreach (ptrdiff_t i, ref pos; _pos) { mixin(S_TRACE);
			auto c = pos.content;
			if (c.type is CType.Start) { mixin(S_TRACE);
				auto startInfo = _startInfos[c.eventId];
				auto count = _et.startUseCounter.get(toStartId(c.name));
				if (_pos[0].content is c) count++;
				auto uc = .text(count);
				auto tw = gc.wTextExtent(uc).x;
				auto tw2 = ucExtent.x;
				_widthSum = .max(_widthSum, calcRight(pos) + 4.ppis + tw + 4.ppis + tw2 + 4.ppis);
			}
			if (c.comment == "") { mixin(S_TRACE);
				_pos[i].commentLineX = 0;
				_pos[i].commentRect = null;
				continue;
			}
			auto cRect = itemRect(posY[i], pos);
			int rx = cRect.x + cRect.width;
			if (!_expanded.get(c.eventId, true)) { mixin(S_TRACE);
				rx += 14.ppis + gc.wTextExtent("...").x + 3.ppis;
			} else { mixin(S_TRACE);
				rx += 2.ppis;
			}
			auto cm = std.string.chomp(.lastRet(c.comment));
			auto te = gc.wTextExtent(cm);
			// 改行文字があると横幅がおかしくなるため
			// 測り直す
			te.x = 0.ppis;
			auto lines = splitLines(cm);
			foreach (line; lines) { mixin(S_TRACE);
				te.x = max(gc.wTextExtent(line).x, te.x);
			}
			// 前後n件のイベントコンテントに被らないようにする
			int ba = cast(int)lines.length;
			Rectangle[] boxes2;
			if (0 < ba) { mixin(S_TRACE);
				foreach (j; .max(i - ba, 0) .. i) { mixin(S_TRACE);
					boxes2 ~= itemRect(posY[j], _pos[j]);
				}
				foreach (j; i + 1 .. .min(_pos.length, i + ba + 1)) { mixin(S_TRACE);
					boxes2 ~= itemRect(posY[j], _pos[j]);
				}
			}

			int dis = 15.ppis;
			int tw = te.x + 10.ppis;
			int th = te.y + 6.ppis;

			// 画面外へ出ないようにY座標の調節
			int ty = posY[i] - th / 2 + hh;
			ty = .min(ty, .max(_heightSum * _lineHeight, ca.height) - th);
			ty = .max(ty, 0);

			auto box = new Rectangle(rx + dis, ty, tw, th);
			foreach (b; boxes2 ~ boxes) { mixin(S_TRACE);
				if (b.intersects(box)) { mixin(S_TRACE);
					box.x = b.x + b.width + 4.ppis;
				}
			}
			boxes ~= box;
			comments ~= cm;
			_pos[i].commentLineX = rx;
			_pos[i].commentRect = box;
			_posTable[c.eventId].commentLineX = rx;
			_posTable[c.eventId].commentRect = box;
			_widthSum = .max(box.x + box.width + 2.ppis, _widthSum);
		}

		// 行番号表示幅を計算する
		_lineNumWidth = 0;
		if (_pos.length) { mixin(S_TRACE);
			foreach  (i; 0 .. 10) { mixin(S_TRACE);
				_lineNumWidth =  .max(_lineNumWidth, gc.textExtent(.text(i)).x);
			}
			_lineNumWidth *= .text(_pos[$ - 1].lineNumber).length;
			_lineNumWidth += (5 + 5 + 1).ppis; // 余白と区切り線の幅
		}
	}

	private void updateScrollBar() { mixin(S_TRACE);
		auto ca = getClientArea();

		auto hbar = getHorizontalBar();
		auto cw = ca.width - detailAreaWidth;
		hbar.setVisible(cw < _widthSum);
		hbar.setMaximum(_widthSum);
		hbar.setThumb(cw);
		hbar.setPageIncrement(cw / 2);

		auto vbar = getVerticalBar();
		vbar.setMaximum(_heightSum);
		vbar.setThumb(ca.height / _lineHeight);
		vbar.setPageIncrement(ca.height / _lineHeight / 2);
	}

	private void updateToolTip() { mixin(S_TRACE);
		auto p = getDisplay().getCursorLocation();
		p = toControl(p);
		string toolTip = "";
		auto ca = getClientArea();
		if (!_moveDetailLine && !_changeCursor && ca.contains(p)) { mixin(S_TRACE);
			foreach (warn; _warningRects) { mixin(S_TRACE);
				if (warn.rect.contains(p)) { mixin(S_TRACE);
					toolTip = std.string.join(warn.warnings, .newline);
					break;
				}
			}
			if (toolTip == "" && ca.width - detailAreaWidth <= p.x) { mixin(S_TRACE);
				int index = indexOf(p.y);
				if (0 <= index && index < _pos.length) { mixin(S_TRACE);
					auto pos = _pos[index];
					auto c = pos.content;
					auto startInfo = _startInfos[c.parentStart.eventId];
					if (p.y - (startInfo.y + pos.relY) < _lineHeight) { mixin(S_TRACE);
						auto gc = new GC(this);
						auto s = .cutText(.contentText(_comm, c, _summ), gc, getDisplay().getBounds().width);
						scope (exit) gc.dispose();
						int dw = detailAreaWidth - 2.ppis - 18.ppis;
						if (dw < gc.wTextExtent(s).x) { mixin(S_TRACE);
							toolTip = s;
						}
					}
				}
			}
		}
		toolTip = .replace(toolTip, "&", "&&");
		if (getToolTipText() != toolTip) { mixin(S_TRACE);
			setToolTipText(toolTip);
		}
	}

	private int calcX(in PosInfo pos) { mixin(S_TRACE);
		auto x = (pos.depth1 * _imageWidth) + (pos.depth2 * _slope);
		if (_showLineNumber && _pos.length) { mixin(S_TRACE);
			x += _lineNumWidth;
		}
		return x;
	}

	private int calcRight(in PosInfo pos) { mixin(S_TRACE);
		auto x = calcX(pos);
		return calcRight(pos, x);
	}
	private int calcRight(in PosInfo pos, int x) { mixin(S_TRACE);
		if (pos.eventTextWidth) { mixin(S_TRACE);
			return x + 20.ppis + pos.eventTextWidth;
		} else { mixin(S_TRACE);
			return x + 16.ppis;
		}
	}

	EventEditorItem getItem(int index) { mixin(S_TRACE);
		updatePosImpl2(false);
		return EventEditorItem.valueOf(this, _et.starts[index]);
	}

	EventEditorItem getItem(Point p) { mixin(S_TRACE);
		auto c = getContent(p.x, p.y);
		updatePosImpl2(false);
		if (c) { mixin(S_TRACE);
			return EventEditorItem.valueOf(this, c);
		}
		return null;
	}
	EventEditorItem[] getItems() { mixin(S_TRACE);
		if (!_et) return [];
		updatePosImpl2(false);
		auto c = cast(Content)getData();
		auto items = new EventEditorItem[_et.starts.length];
		foreach (i; 0 .. _et.starts.length) { mixin(S_TRACE);
			items[i] = getItem(cast(int)i);
		}
		return items;
	}
	int getItemCount() { mixin(S_TRACE);
		if (!_et) return 0;
		return cast(int)_et.starts.length;
	}

	EventEditorItem[] getSelection() { mixin(S_TRACE);
		updatePosImpl2(false);
		if (_selected) { mixin(S_TRACE);
			return [EventEditorItem.valueOf(this, _selected)];
		}
		return [];
	}
	void setSelection(EventEditorItem[] items) { mixin(S_TRACE);
		foreach (itm; items) { mixin(S_TRACE);
			select(itm);
		}
	}
	void select(EventEditorItem itm) { mixin(S_TRACE);
		auto c = cast(Content)itm.getData();
		if (c) { mixin(S_TRACE);
			_selected = c;
			_selectedParentStart = c.parentStart;
			_selectedIndex = indexOf(c);
			redraw();
		}
	}
	void select(Content c) { mixin(S_TRACE);
		_selected = c;
		_selectedParentStart = c ? c.parentStart : null;
		_selectedIndex = indexOf(c);
		redraw();
	}
	void clearRestore() { mixin(S_TRACE);
		_restoreLine = false;
	}

	int indexOf(EventEditorItem itm) { mixin(S_TRACE);
		if (!_et) return -1;
		return cast(int).cCountUntil(_et.starts, cast(Content)itm.getData());
	}
	EventEditorItem getTopItem() { mixin(S_TRACE);
		updatePosImpl2(false);
		auto vbar = getVerticalBar();
		auto index = indexOf(vbar.getSelection() * _lineHeight);
		if (0 <= index && index < _pos.length) { mixin(S_TRACE);
			return EventEditorItem.valueOf(this, _pos[index].content);
		}
		return null;
	}
	void setTopItem(EventEditorItem itm) { mixin(S_TRACE);
		if (itm && (cast(Content)itm.getData()).eventId in _posTable) { mixin(S_TRACE);
			auto vbar = getVerticalBar();
			auto c = cast(Content)itm.getData();
			auto pos = _posTable[c.eventId];
			if (pos.index == -1) return; // 折りたたまれている
			auto startInfo = _startInfos[c.parentStart.eventId];
			vbar.setSelection((startInfo.y + pos.relY) / _lineHeight);
		}
	}

	Content getContent(int x, int y) { mixin(S_TRACE);
		auto index = indexOf(y);
		if (index < 0 || _pos.length <= index) return null;
		return _pos[index].content;
	}

	private void onTraverse(Event e) { mixin(S_TRACE);
		switch (e.detail) {
		case SWT.TRAVERSE_ARROW_NEXT, SWT.TRAVERSE_ARROW_PREVIOUS:
			e.doit = false;
			break;
		default:
			e.doit = true;
		}
	}

	private int indexOf(Content c) { mixin(S_TRACE);
		if (c.eventId !in _posTable) return -1;
		return _posTable[c.eventId].index;
	}
	private int indexOf(int y) { mixin(S_TRACE);
		if (y < 0) return -1;
		auto ca = getClientArea();
		if (ca.height <= y) return -1;

		auto vbar = getVerticalBar();
		auto sy = vbar.getSelection() * _lineHeight;
		y += sy;

		updatePosImpl2(false);
		return find(y, 0, cast(int)_pos.length);
	}
	private int find(int y, int from, int to) { mixin(S_TRACE);
		if (to <= from) return -1;
		auto mid = (from + to) / 2;
		auto pos = _pos[mid];
		assert (mid == pos.index);
		assert (pos.content.parentStart !is null);
		auto startInfo = _startInfos[pos.content.parentStart.eventId];
		if (y < (startInfo.y + pos.relY)) { mixin(S_TRACE);
			return find(y, from, mid);
		} else if ((startInfo.y + pos.relY) + pos.height <= y) { mixin(S_TRACE);
			return find(y, mid + 1, to);
		} else { mixin(S_TRACE);
			return pos.index;
		}
	}
	private void select(int index, bool redraw) { mixin(S_TRACE);
		auto c = _pos[index].content;
		_selected = c;
		_selectedParentStart = c ? c.parentStart : null;
		_selectedIndex = c ? indexOf(c) : -1;
		if (redraw) this.redraw();
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
		auto sels = getSelection();
		se.item = sels.length ? sels[0] : null;
		se.time = cast(int)(0xFFFFFFFFL & Clock.currStdTime());
		se.stateMask = 0;
		se.doit = true;
		notifyListeners(SWT.Selection, se);
	}

	/// 選択の変更をlistenerに通知する。
	void addTreeListener(TreeListener listener) { mixin(S_TRACE);
		auto tl = new TypedListener(listener);
		addListener(SWT.Expand, tl);
		addListener(SWT.Collapse, tl);
	}
	/// ditto
	void removeTreeListener(TreeListener listener) { mixin(S_TRACE);
		removeListener(SWT.Expand, listener);
		removeListener(SWT.Collapse, listener);
	}
	private void callExpandedChanged(EventEditorItem itm) { mixin(S_TRACE);
		getDisplay().asyncExec(new class Runnable {
			override void run() { mixin(S_TRACE);
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

	/// ツリーを全て開く・閉じる操作が可能か。
	/// 例えば全て閉じられていた場合は全て閉じる操作は行えない
	/// (行っても意味が無い)。
	@property
	const
	bool canAllExpand() { mixin(S_TRACE);
		if (!_et) return false;
		foreach (value; _expanded.byValue()) {
			if (!value) return true;
		}
		return false;
	}
	/// ditto
	@property
	const
	bool canAllFoldStart() { mixin(S_TRACE);
		if (!_et) return false;
		foreach (c; _et.starts) {
			if (_expanded.get(c.eventId, true)) return true;
		}
		return false;
	}

	/// キーボード操作による開閉操作が可能か。
	@property
	void expandedOperation(bool enabled) { mixin(S_TRACE);
		_expandedOperation = true;
	}
	/// ditto
	@property
	const
	bool expandedOperation() { return _expandedOperation; }

	private void onKeyDown(Event e) { mixin(S_TRACE);
		if (!_pos.length) return;
		if (e.stateMask != SWT.NONE) return;
		switch (e.keyCode) {
		case SWT.ARROW_LEFT:
			if (expandedOperation && _selected && _selected.next.length && _expanded.get(_selected.eventId, true)) { mixin(S_TRACE);
				_expanded[_selected.eventId] = false;
				updatePosOne(_selected);
				return;
			}
			goto case SWT.ARROW_UP;
		case SWT.ARROW_RIGHT:
			if (expandedOperation && _selected && _selected.next.length && !_expanded.get(_selected.eventId, true)) { mixin(S_TRACE);
				_expanded[_selected.eventId] = true;
				updatePosOne(_selected);
				return;
			}
			goto case SWT.ARROW_DOWN;
		case SWT.ARROW_UP:
			if (_selected) { mixin(S_TRACE);
				int i = _selectedIndex;
				if (0 < i) select(i - 1, true);
			} else { mixin(S_TRACE);
				select(0, true);
			}
			showSelection();
			callSelectChanged();
			break;
		case SWT.ARROW_DOWN:
			if (_selected) { mixin(S_TRACE);
				int i = _selectedIndex;
				if (i + 1 < _pos.length) { mixin(S_TRACE);
					select(i + 1, true);
				}
			} else { mixin(S_TRACE);
				select(0, true);
			}
			showSelection();
			callSelectChanged();
			break;
		default:
			break;
		}
	}

	private void onMouseDown(Event e) { mixin(S_TRACE);
		if (e.button == 1 || e.button == 3) { mixin(S_TRACE);
			forceFocus();
			if (e.button == 1 && _changeCursor) { mixin(S_TRACE);
				_moveDetailLine = true;
			} else { mixin(S_TRACE);
				auto sel = getContent(e.x, e.y);
				if (sel) { mixin(S_TRACE);
					_selected = sel;
					_selectedParentStart = sel.parentStart;
					_selectedIndex = indexOf(sel);
				}
				if (sel) { mixin(S_TRACE);
					showSelection();
					callSelectChanged();
				}
				redraw();
			}
			e.doit = false;
		}
	}

	private void onMouseUp(Event e) { mixin(S_TRACE);
		if (e.button == 1 && _moveDetailLine) { mixin(S_TRACE);
			_moveDetailLine = false;
		}
	}

	@property
	const
	private int detailAreaWidth() {
		return _showEventTreeDetail ? _detailAreaWidth : 0;
	}

	private void onMouseMove(Event e) { mixin(S_TRACE);
		auto ca = getClientArea();
		if (_moveDetailLine) { mixin(S_TRACE);
			_detailAreaWidth = ca.width - e.x;
			_detailAreaWidth = .min(_detailAreaWidth, ca.width - _imageWidth);
			_detailAreaWidth = .max(_detailAreaWidth, _imageWidth);
			_comm.prop.var.etc.detailAreaWidth = _detailAreaWidth;
			updateScrollBar();
			redraw();
		} else { mixin(S_TRACE);
			auto linePos = ca.width - detailAreaWidth;
			if (linePos - 10.ppis <= e.x && e.x < linePos + 10.ppis) { mixin(S_TRACE);
				if (!_changeCursor) { mixin(S_TRACE);
					auto d = getDisplay();
					_cursor = getCursor();
					_changeCursor = true;
					setCursor(d.getSystemCursor(SWT.CURSOR_SIZEWE));
					setDragDetect(false);
				}
			} else if (_changeCursor) { mixin(S_TRACE);
				setCursor(_cursor);
				setDragDetect(true);
				_cursor = null;
				_changeCursor = false;
			}
		}
		updateLightup();
		updateToolTip();
	}
	private void onMouseEnter(Event e) { mixin(S_TRACE);
		updateLightup();
	}
	private void onMouseExit(Event e) { mixin(S_TRACE);
		clearLightup();
	}
	private void onFocusInOut(Event e) { mixin(S_TRACE);
		auto ca = getClientArea();
		if (_selected && _selected.eventId in _posTable) { mixin(S_TRACE);
			auto pos = _posTable[_selected.eventId];
			if (pos.index == -1) return; // 折りたたまれている
			auto startInfo = _startInfos[_selectedParentStart.eventId];
			redrawItem(startInfo, pos);
		}
	}

	private void redrawItem(in StartInfo startInfo, in PosInfo pos) { mixin(S_TRACE);
		auto ca = getClientArea();
		auto sy = getVerticalBar().getSelection() * _lineHeight;
		auto y = (startInfo.y + pos.relY) - sy - 2;
		auto h = _lineHeight + 5;
		version (Windows) {
			// FIXME: 環境によって再描画範囲に左上からの部分が描画されるので
			//        再描画範囲を左上からにする(issue #296)
			alias org.eclipse.swt.internal.win32.OS.OS OS;
			if (OS.WIN32_VERSION <= OS.VERSION(6, 1)) { mixin(S_TRACE);
				h += y;
				y = 0;
			}
		}
		redraw(ca.x, y, ca.width, h, true);
	}
	private void clearLightup() { mixin(S_TRACE);
		if (_lightup && _lightup.eventId in _posTable) { mixin(S_TRACE);
			auto ca = getClientArea();
			auto pos = _posTable[_lightup.eventId];
			if (pos.index == -1) return; // 折りたたまれている
			auto startInfo = _startInfos[_lightupParentStart.eventId];
			redrawItem(startInfo, pos);
		}
		_lightup = null;
		_lightupParentStart = null;
	}
	void updateLightup() { mixin(S_TRACE);
		auto ca = getClientArea();
		auto p = getDisplay().getCursorLocation();
		p = toControl(p);
		auto old = _lightup;
		auto lightup = ca.contains(p) ? getContent(p.x, p.y) : null;
		if (old is lightup) return;
		clearLightup();
		_lightup = lightup;
		_lightupParentStart = _lightup ? _lightup.parentStart : null;
		if (_lightup && _lightup.eventId in _posTable) { mixin(S_TRACE);
			auto pos = _posTable[_lightup.eventId];
			if (pos.index == -1) return; // 折りたたまれている
			auto startInfo = _startInfos[_lightupParentStart.eventId];
			redrawItem(startInfo, pos);
		}
	}

	private void onMouseDoubleClick(Event e) { mixin(S_TRACE);
		auto itm = getItem(new Point(e.x, e.y));
		if (!itm) return;
		auto c = cast(Content)itm.getData();
		if (itm && c.type == CType.Start && c.next.length) { mixin(S_TRACE);
			itm.setExpanded(!itm.getExpanded());
			callExpandedChanged(itm);
		}
	}

	private void onMouseWheel(Event e) { mixin(S_TRACE);
		setRedraw(false);
		clearLightup();
		auto vbar = getVerticalBar();
		auto val = vbar.getSelection();
		if (e.count < 0) { mixin(S_TRACE);
			val += 1;
		} else if (0 < e.count) { mixin(S_TRACE);
			val -= 1;
		}
		vbar.setSelection(val);
		.asyncExec(getDisplay(), { mixin(S_TRACE);
			if (isDisposed()) return;
			setRedraw(true);
			updateLightup();
		});
	}

	private void nameVisible(int index, bool visible) { mixin(S_TRACE);
		_pos[index].nameVisible = visible;
		redraw();
	}

	private void onPaint(Event e) { mixin(S_TRACE);
		if (!_et) return;
		updatePosImpl2(true);
		if (_pos.length) { mixin(S_TRACE);
			if (_restoreLine) { mixin(S_TRACE);
				if (auto p = _et.eventTreeId in _storedLine) { mixin(S_TRACE);
					getVerticalBar().setSelection(p.lineNumber);
					auto index = p.selected;
					if (index < 0) index = 0;
					if (_pos.length <= index) index = cast(int)_pos.length - 1;
					select(index, false);
				}
			} else if (_showSelection) { mixin(S_TRACE);
				showSelectionImpl();
			}
		}
		_restoreLine = false;
		_showSelection = false;
		if (!_pos.length) return;
		if (_updateCommentPos) { mixin(S_TRACE);
			auto posY = new int[_pos.length];
			size_t i = 0;
			auto startInfo = _firstStartInfo;
			while (startInfo) { mixin(S_TRACE);
				for (auto index = startInfo.fromIndex; index < startInfo.toIndex; index++) { mixin(S_TRACE);
					posY[i] = startInfo.y + _pos[index].relY;
					i++;
				}
				startInfo = startInfo.next;
			}
			updateCommentPos(e.gc, posY);
		}
		auto hw = _imageWidth / 2;
		auto hh = _lineHeight / 2;
		auto ca = getClientArea();

		void setAntialias(int antialias) { mixin(S_TRACE);
			version (Windows) {
				alias org.eclipse.swt.internal.win32.OS.OS OS;
				if (OS.VERSION(6, 0) <= OS.WIN32_VERSION) e.gc.setAntialias(antialias);
			} else {
				e.gc.setAntialias(antialias);
			}
		}
		void setAlpha(int alpha) {mixin(S_TRACE);
			version (Windows) {
				alias org.eclipse.swt.internal.win32.OS.OS OS;
				if (OS.VERSION(6, 0) <= OS.WIN32_VERSION) e.gc.setAlpha(alpha);
			} else {
				e.gc.setAlpha(alpha);
			}
		}

		int detailAreaWidth = this.detailAreaWidth;

		auto hbar = getHorizontalBar();
		auto vbar = getVerticalBar();
		int index = .max(0, find(vbar.getSelection() * _lineHeight, 0, cast(int)_pos.length));
		int to = .min(cast(int)_pos.length, index + ca.height / _lineHeight + 1);
		auto poss = _pos[index .. to];
		int sx = hbar.getSelection();
		int sy = vbar.getSelection() * _lineHeight;

		auto d = getDisplay();

		auto grayColorSelected = new Color(d, 96, 96, 96);
		scope (exit) grayColorSelected.dispose();
		auto grayColorLightup = new Color(d, 128, 128, 128);
		scope (exit) grayColorLightup.dispose();
		Color textColor(in Content c) { mixin(S_TRACE);
			if (c is _selected) { mixin(S_TRACE);
				return grayColorSelected;
			} else if (c is _lightup) { mixin(S_TRACE);
				return grayColorLightup;
			} else { mixin(S_TRACE);
				return d.getSystemColor(SWT.COLOR_GRAY);
			}
		}

		if (_lightup && _lightup.eventId in _posTable) { mixin(S_TRACE);
			// マウスオーバー中のイベントコンテント
			auto pos = _posTable[_lightup.eventId];
			if (pos.index != -1) { mixin(S_TRACE);
				auto startInfo = _startInfos[_lightupParentStart.eventId];
				e.gc.setBackground(_lightupColor);
				scope (exit) e.gc.setBackground(getBackground());
				e.gc.fillRectangle(ca.x, (startInfo.y + pos.relY) - sy, ca.width, _lineHeight + 1);
			}
		}
		if (_selected && _selected.eventId in _posTable) { mixin(S_TRACE);
			auto pos = _posTable[_selected.eventId];
			if (pos.index != -1) { mixin(S_TRACE);
				// 選択中マーク
				// FIXME: e.gcで直接描画するとフォーカス線が出ない場合がある
				//        一度でもキー操作をすると改善するが、確実に回避する
				//        ためには別のGCを作成して描画を行う必要がある
				auto buf = new Image(d, ca.width, _lineHeight + 1);
				scope (exit) buf.dispose();
				auto gc = new GC(buf);
				scope (exit) gc.dispose();

				auto startInfo = _startInfos[_selectedParentStart.eventId];
				gc.setBackground(_selectedColor);
				scope (exit) gc.setBackground(getBackground());
				gc.fillRectangle(0, 0, ca.width, _lineHeight + 1);
				if (isFocusControl()) { mixin(S_TRACE);
					gc.setForeground(d.getSystemColor(SWT.COLOR_BLACK));
					auto cw = .max(ca.width, _widthSum + detailAreaWidth);
					gc.drawFocus(2 - sx, 2, cw - 4, _lineHeight + 1 - 4);
				}
				e.gc.drawImage(buf, ca.x, (startInfo.y + pos.relY) - sy);
			}
		}

		// イベントコンテントを結ぶ線
		e.gc.setLineWidth(4.ppis);
		e.gc.setForeground(_lineColor);
		e.gc.setBackground(_lineColor);
		StartInfo[] possInfo;
		foreach (i, ref pos; _pos[index .. $]) { mixin(S_TRACE);
			auto c = pos.content;
			auto startInfo = _startInfos[c.parentStart.eventId];
			possInfo ~= startInfo;
			if (c.type == CType.Start) { mixin(S_TRACE);
				if (poss.length <= i) break;
				if (0 < i && (_summ ? _comm.prop.var.etc.drawContentTreeLine : drawContentTreeLine)) { mixin(S_TRACE);
					e.gc.setLineWidth(1);
					e.gc.setForeground(_lineColor);
					e.gc.drawLine(0, (startInfo.y + pos.relY) - sy, ca.width, (startInfo.y + pos.relY) - sy);
					e.gc.setLineWidth(4.ppis);
					e.gc.setForeground(_lineColor);
				}
			} else if (c.parent && c.parent.eventId in _posTable) { mixin(S_TRACE);
				auto pPos = _posTable[c.parent.eventId];
				if (calcX(pPos) == calcX(pos)) { mixin(S_TRACE);
					e.gc.drawLine(calcX(pos) + hw - sx, (startInfo.y + pPos.relY) + hh - sy, calcX(pos) + hw - sx, (startInfo.y + pos.relY) + hh - sy);
				} else { mixin(S_TRACE);
					if ((startInfo.y + pPos.relY) + hh - sy < (startInfo.y + pos.relY) - sy - hh) { mixin(S_TRACE);
						e.gc.drawLine(calcX(pPos) + hw - sx, (startInfo.y + pPos.relY) + hh - sy, calcX(pPos) + hw - sx, (startInfo.y + pos.relY) - sy - hh);
					}
					setAntialias(SWT.ON);
					auto cap = e.gc.getLineCap();
					e.gc.setLineCap(SWT.CAP_ROUND);
					e.gc.drawArc(calcX(pPos) + hw - sx, (startInfo.y + pos.relY) - sy - _lineHeight, calcX(pos) - calcX(pPos) + hw, _lineHeight + hh, 180, 90);
					e.gc.setLineCap(cap);
					setAntialias(SWT.OFF);
				}
			}
			if ((_summ ? _comm.prop.var.etc.showTerminalMark : showTerminalMark) && c.type != CType.Start && !c.next.length) { mixin(S_TRACE);
				// 後続コンテントが置かれるであろう位置を示す
				// (終端の場合は後続コンテントが置けない事を示す)
				int terX = calcX(pos) + hw - sx;
				int terY = (startInfo.y + pos.relY) + hh + _lineHeight - sy + 1.ppis;
				if (c.detail.owner) { mixin(S_TRACE);
					e.gc.drawLine(calcX(pos) + hw - sx, (startInfo.y + pos.relY) + hh - sy, terX, terY - 8.ppis);
					e.gc.drawLine(terX, terY - 6.ppis, terX, terY - 2.ppis);
					e.gc.drawLine(terX, terY, terX, terY + 3.ppis);
				} else { mixin(S_TRACE);
					e.gc.drawLine(calcX(pos) + hw - sx, (startInfo.y + pos.relY) + hh - sy, terX, terY - 5.ppis);
					e.gc.fillRectangle(terX - 6.ppis, terY - 5.ppis, 12.ppis, 4.ppis);
				}
			}
		}

		// イベントコンテント分岐点
		e.gc.setBackground(getBackground());
		setAntialias(SWT.ON);
		e.gc.setLineWidth(4.ppis);
		foreach (i, ref pos; poss) { mixin(S_TRACE);
			auto c = pos.content;
			auto startInfo = possInfo[i];
			if (c.parent && c.parent.eventId in _posTable) { mixin(S_TRACE);
				auto pPos = _posTable[c.parent.eventId];
				if (calcX(pPos) != calcX(pos) && (startInfo.y + pPos.relY) != (startInfo.y + pos.relY) - _lineHeight) { mixin(S_TRACE);
					e.gc.fillOval(calcX(pPos) + hw - 6.ppis - sx, (startInfo.y + pos.relY) - hh - sy - 2.ppis, 12.ppis, 12.ppis);
					e.gc.drawOval(calcX(pPos) + hw - 6.ppis - sx, (startInfo.y + pos.relY) - hh - sy - 2.ppis, 12.ppis, 12.ppis);
				}
			}
		}
		setAntialias(SWT.OFF);
		e.gc.setLineWidth(1);

		// イベントコンテントのアイコンとテキスト
		auto ucExtent = e.gc.wTextExtent(_comm.prop.msgs.startUseCount);
		e.gc.setForeground(getForeground());
		foreach (i, ref pos; poss) { mixin(S_TRACE);
			auto c = pos.content;
			auto startInfo = possInfo[i];
			auto image = _comm.prop.images.content(c.type);
			e.gc.drawImage(image, calcX(pos) - sx, (startInfo.y + pos.relY) + _imgPos - sy);
			if (!pos.nameVisible) continue;
			string s;
			StartInfo *p = null;
			auto ctx = 0.ppis;
			auto cy = (startInfo.y + pos.relY) - sy;
			if (c.name == "" && c.parent && c.parent.detail.nextType == CNextType.Text) { mixin(S_TRACE);
				e.gc.setForeground(textColor(c));
				s = _comm.skin.evtChildOK;
			} else { mixin(S_TRACE);
				e.gc.setForeground(d.getSystemColor(SWT.COLOR_BLACK));
				s = pos.eventText;
			}
			ctx = calcX(pos) + 20.ppis;
			if (s.length) { mixin(S_TRACE);
				e.gc.wDrawText(s, ctx - sx, cy + _lineTextY, true);
				ctx += e.gc.wTextExtent(s).x;
			}
			if (_comm.prop.var.etc.showTargetStartLineNumber && c.detail.use(CArg.Start)) { mixin(S_TRACE);
				p = c.start in _startInfoWithName;
				if (p) { mixin(S_TRACE);
					// 対象スタートコンテントと行番号と矢印
					e.gc.setForeground(textColor(c));
					auto line = _posTable[p.start.eventId].lineNumber;
					e.gc.setLineWidth(2.ppis);
					scope (exit) e.gc.setLineWidth(1);
					auto ay = _lineHeight / 4;
					if (s.length) ctx += ay * 2;
					auto ps = [
						ctx - sx, cy + (_lineHeight / 2) - ay,
						ctx - sx + ay, cy + (_lineHeight / 2),
						ctx - sx, cy + (_lineHeight / 2) + ay,
					];
					e.gc.drawPolyline(ps);
					ps[0] += ay;
					ps[2] += ay;
					ps[4] += ay;
					e.gc.drawPolyline(ps);
					ctx += ay * 3;
					e.gc.wDrawText(.text(line), ctx - sx, (startInfo.y + pos.relY) - sy + _lineTextY, true);
				}
			}

			if (_comm.prop.var.etc.showTargetStartLineNumber && c.type is CType.Start) { mixin(S_TRACE);
				// スタートコンテントへのリンク元の行番号
				auto ay = _lineHeight / 4;
				int[] lines = [];
				foreach (u; c.startUseCounter.values(toStartId(c.name))) { mixin(S_TRACE);
					auto cu = cast(Content)u;
					if (!cu) continue;
					assert (cu.eventId in _posTable);
					lines ~= _posTable[cu.eventId].lineNumber;
				}
				if (lines.length) { mixin(S_TRACE);
					e.gc.setForeground(textColor(c));
					e.gc.setBackground(textColor(c));
					e.gc.setLineWidth(2.ppis);
					scope (exit) e.gc.setLineWidth(1);
					ctx += ay;
					std.algorithm.sort(lines);
					auto ps = [
						ctx - sx + ay, cy + (_lineHeight / 2) - ay,
						ctx - sx, cy + (_lineHeight / 2),
						ctx - sx + ay, cy + (_lineHeight / 2) + ay,
					];
					e.gc.drawPolyline(ps);
					ps[0] += ay;
					ps[2] += ay;
					ps[4] += ay;
					e.gc.drawPolyline(ps);
					ctx += ay * 3;
					foreach (j, l; lines) { mixin(S_TRACE);
						if (0 < j) { mixin(S_TRACE);
							ctx += ay * 2;
							e.gc.fillOval(ctx - sx - ay - 1.ppis, (startInfo.y + pos.relY) - sy + _lineHeight / 2 - 1.ppis, 3.ppis, 3.ppis);
						}
						auto ls = .text(l);
						e.gc.wDrawText(ls, ctx - sx, (startInfo.y + pos.relY) - sy + _lineTextY, true);
						ctx += e.gc.wTextExtent(ls).x;
					}
				}
			}

			if ((_summ ? _comm.prop.var.etc.drawCountOfUseOfStart : drawCountOfUseOfStart) && c.type == CType.Start) { mixin(S_TRACE);
				// スタート使用数
				auto count = _et.startUseCounter.get(toStartId(c.name));
				if (_pos[0].content is c) count++;
				auto uc = .text(count);
				auto tw = e.gc.wTextExtent(uc).x;
				int tx = ca.width - detailAreaWidth - 4.ppis - tw;
				setAlpha(192);
				if (c is _selected) { mixin(S_TRACE);
					e.gc.setBackground(_selectedColor);
				} else if (c is _lightup) { mixin(S_TRACE);
					e.gc.setBackground(_lightupColor);
				} else { mixin(S_TRACE);
					e.gc.setBackground(getBackground());
				}
				auto ucx = tx - ucExtent.x - 4.ppis;
				auto ucy = (startInfo.y + pos.relY) - sy + _lineTextY;
				e.gc.fillRectangle(ucx - 4.ppis, ucy + 1, 4.ppis + ucExtent.x + 4.ppis + ucExtent.x + 4.ppis, _lineHeight);
				setAlpha(255);
				e.gc.setForeground(getForeground());
				e.gc.wDrawText(_comm.prop.msgs.startUseCount, ucx, ucy, true);
				e.gc.setForeground(d.getSystemColor(SWT.COLOR_BLACK));
				e.gc.wDrawText(uc, tx, (startInfo.y + pos.relY) - sy + _lineTextY, true);
			}
			if (!_expanded.get(c.eventId, true)) { mixin(S_TRACE);
				// ツリーを畳んでいる時のマーク
				e.gc.setForeground(getForeground());
				auto te = e.gc.wTextExtent("...");
				e.gc.drawLine(ctx + 2.ppis - sx, (startInfo.y + pos.relY) - sy + hh, ctx + 10.ppis - sx, (startInfo.y + pos.relY) - sy + hh);
				e.gc.wDrawText("...", ctx + 14.ppis - sx, (startInfo.y + pos.relY) - sy + _lineTextY, true);
				setAntialias(SWT.ON);
				e.gc.drawRoundRectangle(ctx + 10.ppis - sx, (startInfo.y + pos.relY) - sy, te.x + 8.ppis, te.y, 10.ppis, 10.ppis);
				setAntialias(SWT.OFF);
			}
		}

		e.gc.setForeground(d.getSystemColor(SWT.COLOR_BLACK));
		e.gc.setBackground(getBackground());

		// 行番号
		if (_showLineNumber && _pos.length) { mixin(S_TRACE);
			setAlpha(192);
			auto w = _lineNumWidth;
			e.gc.fillRectangle(0, 0, w, ca.height);
			e.gc.setForeground(d.getSystemColor(SWT.COLOR_GRAY));
			e.gc.drawLine(w, ca.y, w, ca.y + ca.height);
			setAlpha(255);
			e.gc.setForeground(d.getSystemColor(SWT.COLOR_BLACK));
			foreach (i, ref pos; poss) { mixin(S_TRACE);
				auto startInfo = possInfo[i];
				auto line = .text(pos.lineNumber);
				auto te = e.gc.wTextExtent(line);
				e.gc.wDrawText(line, _lineNumWidth - (1 + 5).ppis - te.x, (startInfo.y + pos.relY) - sy + (_lineHeight - te.y) / 2, true);
			}
		}

		// イベントコンテントの内容領域、警告
		if (detailAreaWidth) { mixin(S_TRACE);
			setAlpha(192);
			e.gc.fillRectangle(ca.width - detailAreaWidth + 1.ppis, ca.y, detailAreaWidth - 1.ppis, ca.height);
			e.gc.setForeground(d.getSystemColor(SWT.COLOR_GRAY));
			e.gc.drawLine(ca.width - detailAreaWidth, ca.y, ca.width - detailAreaWidth, ca.y + ca.height);
			setAlpha(255);
		}

		e.gc.setForeground(d.getSystemColor(SWT.COLOR_BLACK));
		_warningRects = [];
		foreach (i, ref pos; poss) { mixin(S_TRACE);
			// イベントコンテント内容
			auto c = pos.content;
			auto startInfo = possInfo[i];
			if (detailAreaWidth) { mixin(S_TRACE);
				auto iconW = _comm.prop.var.etc.drawContentIconOnDetail ? 18.ppis : 4.ppis;
				auto s = .cutText(.contentText(_comm, c, _summ), e.gc, detailAreaWidth - 2.ppis - iconW, "", true);
				int x = ca.width - detailAreaWidth + 2.ppis;
				if (_comm.prop.var.etc.drawContentIconOnDetail) { mixin(S_TRACE);
					auto image = _comm.prop.images.content(c.type);
					setAlpha(128);
					e.gc.drawImage(image, x, (startInfo.y + pos.relY) + _imgPos - sy);
					setAlpha(255);
				}
				e.gc.wDrawText(s, x + iconW, (startInfo.y + pos.relY) - sy + _lineTextY, true);
			}

			// 警告
			if (_summ ? _comm.prop.var.etc.drawContentWarnings : drawContentWarnings) { mixin(S_TRACE);
				auto isClassic = _summ && _summ.legacy;
				auto wsnVer = _summ ? _summ.dataVersion : LATEST_VERSION;
				auto warnings = .warnings(_comm.prop.parent, _comm.skin, _summ, c, isClassic, wsnVer, _comm.prop.var.etc.targetVersion);
				if (warnings.length) { mixin(S_TRACE);
					warnings = warnings.sort().uniq().array();
					int ww = _comm.prop.var.etc.warningImageWidth;
					int wix = .max(0, ca.width - detailAreaWidth - ww);
					int wiw = ca.width - detailAreaWidth - wix;
					if (wiw <= 0) continue;
					e.gc.drawImage(_warningImage, 0, 0, ww, 1, wix, (startInfo.y + pos.relY) - sy, wiw, _lineHeight + 1);
					e.gc.drawImage(_comm.prop.images.warning, wix + wiw - _imageWidth - 4.ppis, (startInfo.y + pos.relY) + _imgPos - sy);
					auto rect = new Rectangle(ca.x, (startInfo.y + pos.relY) - sy, ca.width - detailAreaWidth, _lineHeight);
					_warningRects ~= Warning(rect, warnings);
				}
			}
		}

		// コメント
		e.gc.setBackground(getBackground());
		e.gc.setForeground(getForeground());
		foreach (i, ref pos; _pos) { mixin(S_TRACE);
			if (!pos.commentRect) continue;
			auto startInfo = _startInfos[pos.content.parentStart.eventId];
			e.gc.drawLine(pos.commentLineX - sx, (startInfo.y + pos.relY) + hh - sy, pos.commentRect.x - sx, (startInfo.y + pos.relY) + hh - sy);
		}
		setAntialias(SWT.ON);
		foreach (i, ref pos; _pos) { mixin(S_TRACE);
			if (!pos.commentRect) continue;
			auto box = pos.commentRect;
			setAlpha(192);
			e.gc.fillRoundRectangle(box.x - sx, box.y - sy, box.width, box.height, 12.ppis, 12.ppis);
			setAlpha(255);
			e.gc.setForeground(getForeground());
			e.gc.drawRoundRectangle(box.x - sx, box.y - sy, box.width, box.height, 12.ppis, 12.ppis);
			e.gc.setForeground(d.getSystemColor(SWT.COLOR_BLACK));
			e.gc.wDrawText(pos.content.comment, box.x + 5.ppis - sx, box.y + 3.ppis - sy, true);
		}
		setAntialias(SWT.OFF);
		_updatedPos = false;
	}

	private bool _showTerminalMark = false;
	private bool _forceIndentBranchContent = false;
	private bool _drawContentTreeLine = false;
	private bool _drawCountOfUseOfStart = false;
	private bool _drawContentWarnings = false;
	private int _slope = 0;
	/// 表示オプション。
	/// シナリオ編集中であればCommons#propの値が、
	/// 表示テスト中であればここで設定された値が採用される。
	@property
	const
	bool showTerminalMark() { return _showTerminalMark; }
	/// ditto
	@property
	void showTerminalMark(bool v) { mixin(S_TRACE);
		_showTerminalMark = v;
		updatePosAll();
	}
	/// ditto
	@property
	const
	bool forceIndentBranchContent() { return _forceIndentBranchContent; }
	/// ditto
	@property
	void forceIndentBranchContent(bool v) { mixin(S_TRACE);
		_forceIndentBranchContent = v;
		updatePosAll();
	}
	/// ditto
	@property
	const
	int slope() { return _slope; }
	/// ditto
	@property
	void slope(int v) { mixin(S_TRACE);
		_slope = v;
		if (!_et) return;
		if (!_et.starts.length) return;
		if (!_startInfos.length) return;

		// コメント位置と水平方向スクロールバーを更新して再描画
		updateWidthSum();
		updateScrollBar();
		redraw();
	}
	private void updateWidthSum() { mixin(S_TRACE);
		auto gc = new GC(this);
		scope (exit) gc.dispose();
		_widthSum = 0;
		auto startInfo = _firstStartInfo;
		auto posY = new int[_pos.length];
		while (startInfo) { mixin(S_TRACE);
			for (auto i = startInfo.fromIndex; i < startInfo.toIndex; i++) {
				_widthSum = .max(_widthSum, calcRight(_pos[i]));
				posY[i] = startInfo.y + _pos[i].relY;
			}
			startInfo = startInfo.next;
		}
		updateCommentPos(gc, posY);
	}

	/// ditto
	@property
	const
	bool drawContentTreeLine() { return _drawContentTreeLine; }
	/// ditto
	@property
	void drawContentTreeLine(bool v) { mixin(S_TRACE);
		_drawContentTreeLine = v;
		redraw();
	}
	/// ditto
	@property
	const
	bool drawCountOfUseOfStart() { return _drawCountOfUseOfStart; }
	/// ditto
	@property
	void drawCountOfUseOfStart(bool v) { mixin(S_TRACE);
		_drawCountOfUseOfStart = v;
		redraw();
	}
	/// ditto
	@property
	const
	bool drawContentWarnings() { return _drawContentWarnings; }
	/// ditto
	@property
	void drawContentWarnings(bool v) { mixin(S_TRACE);
		_drawContentWarnings = v;
		redraw();
	}
}

package struct TreeViewWrapper {
	Tree tree;
	EventEditor editor;

	@property
	Composite control() { mixin(S_TRACE);
		if (tree) { mixin(S_TRACE);
			return tree;
		} else { mixin(S_TRACE);
			return editor;
		}
	}

	private Item[] array(T)(T[] itms) { mixin(S_TRACE);
		auto a = new Item[itms.length];
		foreach (i, itm; itms) { mixin(S_TRACE);
			a[i] = itm;
		}
		return a;
	}
	private T[] items(T)(Item[] itms) { mixin(S_TRACE);
		auto a = new T[itms.length];
		foreach (i, itm; itms) { mixin(S_TRACE);
			a[i] = cast(T)itm;
		}
		return a;
	}

	Item getTopItem() { mixin(S_TRACE);
		if (tree) { mixin(S_TRACE);
			return tree.getTopItem();
		} else { mixin(S_TRACE);
			return editor.getTopItem();
		}
	}
	void setTopItem(Item itm) { mixin(S_TRACE);
		if (tree) { mixin(S_TRACE);
			tree.setTopItem(cast(TreeItem)itm);
		} else { mixin(S_TRACE);
			editor.setTopItem(cast(EventEditorItem)itm);
		}
	}

	Item[] getSelection() { mixin(S_TRACE);
		if (tree) { mixin(S_TRACE);
			return array(tree.getSelection());
		} else { mixin(S_TRACE);
			return array(editor.getSelection());
		}
	}
	void setSelection(Item[] itms) { mixin(S_TRACE);
		if (tree) { mixin(S_TRACE);
			tree.setSelection(items!TreeItem(itms));
		} else { mixin(S_TRACE);
			editor.setSelection(items!EventEditorItem(itms));
		}
	}
	void select(Item itm) { mixin(S_TRACE);
		if (tree) { mixin(S_TRACE);
			tree.select(cast(TreeItem)itm);
		} else { mixin(S_TRACE);
			editor.select(cast(EventEditorItem)itm);
		}
	}

	Item getItem(int index) { mixin(S_TRACE);
		if (tree) { mixin(S_TRACE);
			return tree.getItem(index);
		} else { mixin(S_TRACE);
			return editor.getItem(index);
		}
	}
	Item getItem(Point p) { mixin(S_TRACE);
		if (tree) { mixin(S_TRACE);
			return tree.getItem(p);
		} else { mixin(S_TRACE);
			return editor.getItem(p);
		}
	}

	int getItemCount() { mixin(S_TRACE);
		if (tree) { mixin(S_TRACE);
			return tree.getItemCount();
		} else { mixin(S_TRACE);
			return editor.getItemCount();
		}
	}
	int getItemCount(Item itm) { mixin(S_TRACE);
		if (auto b = cast(TreeItem)itm) return b.getItemCount();
		return (cast(EventEditorItem)itm).getItemCount();
	}
	int getItemCount(ref TreeViewWrapper view) { mixin(S_TRACE);
		return view.getItemCount();
	}

	void showSelection() { mixin(S_TRACE);
		if (tree) { mixin(S_TRACE);
			return tree.showSelection();
		} else { mixin(S_TRACE);
			return editor.showSelection();
		}
	}

	void addSelectionListener(SelectionListener listener) { mixin(S_TRACE);
		if (tree) { mixin(S_TRACE);
			return tree.addSelectionListener(listener);
		} else { mixin(S_TRACE);
			return editor.addSelectionListener(listener);
		}
	}
	void addTreeListener(TreeListener listener) { mixin(S_TRACE);
		if (tree) { mixin(S_TRACE);
			return tree.addTreeListener(listener);
		} else { mixin(S_TRACE);
			return editor.addTreeListener(listener);
		}
	}
	Item[] getItems() { mixin(S_TRACE);
		if (tree) { mixin(S_TRACE);
			return array(tree.getItems());
		} else { mixin(S_TRACE);
			return array(editor.getItems());
		}
	}
	Item[] getItems(Item itm) { mixin(S_TRACE);
		if (auto b = cast(TreeItem)itm) return array(b.getItems());
		return array((cast(EventEditorItem)itm).getItems());
	}
	Item getItem(Item itm, int index) { mixin(S_TRACE);
		if (auto b = cast(TreeItem)itm) return b.getItem(index);
		return (cast(EventEditorItem)itm).getItem(index);
	}
	bool getExpanded(Item itm) { mixin(S_TRACE);
		if (auto b = cast(TreeItem)itm) return b.getExpanded();
		return (cast(EventEditorItem)itm).getExpanded();
	}
	void setExpanded(Item itm, bool expanded) { mixin(S_TRACE);
		if (auto b = cast(TreeItem)itm) { mixin(S_TRACE);
			b.setExpanded(expanded);
		} else { mixin(S_TRACE);
			(cast(EventEditorItem)itm).setExpanded(expanded);
		}
	}
	Item getParentItem(Item itm) { mixin(S_TRACE);
		if (auto b = cast(TreeItem)itm) return b.getParentItem();
		return (cast(EventEditorItem)itm).getParentItem();
	}
	Item getItem(ref TreeViewWrapper view, int index) { mixin(S_TRACE);
		return getItem(index);
	}

	int indexOf(Item itm) { mixin(S_TRACE);
		if (tree) { mixin(S_TRACE);
			return tree.indexOf(cast(TreeItem)itm);
		} else { mixin(S_TRACE);
			return editor.indexOf(cast(EventEditorItem)itm);
		}
	}
	int indexOf(Item itm, Item child) { mixin(S_TRACE);
		if (auto b = cast(TreeItem)itm) return b.indexOf(cast(TreeItem)child);
		return (cast(EventEditorItem)itm).indexOf(cast(EventEditorItem)child);
	}

	Item topItem(Item itm) { mixin(S_TRACE);
		if (auto b = cast(TreeItem)itm) return .topItem(b);
		auto c = cast(Content)itm.getData();
		if (c.parent) return EventEditorItem.valueOf(editor, c.parentStart);
		return itm;
	}

	void treeExpandedAll() { mixin(S_TRACE);
		if (tree) { mixin(S_TRACE);
			.treeExpandedAll(tree);
		} else { mixin(S_TRACE);
			editor.expandAll();
		}
	}

	Rectangle getImageBounds(Item itm) { mixin(S_TRACE);
		if (auto b = cast(TreeItem)itm) return b.getImageBounds(0);
		return (cast(EventEditorItem)itm).getImageBounds();
	}
}

/// EventEditorのテキストを編集可能にする。
/// ダブルクリック、またはF2キーの押下で編集開始。
class EventEdit {
private:
	Commons _comm;
	EventEditor _list;
	EditEnd _tee;
	Control _editor = null;
	EventEditorItem _edit = null;
	int _oldIndex = -1;
	int _editIndex = -1;
	int _minimumWidth = SWT.DEFAULT;

	void delegate(EventEditorItem itm, Control ctrl) _editEnd;
	Control delegate(EventEditorItem itm) _createEditor;

	Item selectionM(int x, int y) { mixin(S_TRACE);
		if (!_list.getDragDetect()) return null;
		auto c = _list.getContent(x, y);
		if (!c) return null;
		int index = _list.indexOf(c);
		if (x < _list.calcX(_list._pos[index]) + 20.ppis) return null;
		auto ca = _list.getClientArea();
		if (ca.width - _list.detailAreaWidth <= x) return null;
		return _list.getItem(new Point(x, y));
	}
	Item selectionK() { mixin(S_TRACE);
		auto sels = _list.getSelection();
		if (sels.length) { mixin(S_TRACE);
			return sels[0];
		}
		return null;
	}

	void end(Control ctrl) { mixin(S_TRACE);
		assert (_edit !is null);
		_editEnd(_edit, ctrl);
	}

	void clearEdit(bool cancel) { mixin(S_TRACE);
		_tee = null;
		_edit = null;
		_editor = null;
		_oldIndex = -1;
		_list.nameVisible(_editIndex, true);
		_editIndex = -1;
	}

	void startEdit(Item itm) { mixin(S_TRACE);
		if (_tee !is null && !_tee.isExit) _tee.enter();
		_editor = _createEditor(cast(EventEditorItem)itm);
		if (_editor) { mixin(S_TRACE);
			_edit = cast(EventEditorItem)itm;
			_list.showSelection();
			_tee = new EditEnd(_comm, _list, _editor, &end);
			_tee.exitEvent ~= &clearEdit;
			layout();
			_tee.setFocus();
		}
	}
	void layout() { mixin(S_TRACE);
		if (!_edit) return;
		int scrPos = _list.getVerticalBar().getSelection();
		if (scrPos == _oldIndex) return;
		_oldIndex = scrPos;
		_editIndex = _list.indexOf(cast(Content)_edit.getData());
		auto size = _editor.computeSize(_minimumWidth, SWT.DEFAULT);
		auto pos = _list._pos[_editIndex];
		auto sy = _list.getVerticalBar().getSelection() * _list._lineHeight;
		int x = _list.calcX(pos) + 20.ppis;
		int w;
		if ((cast(Combo)_editor || cast(CCombo)_editor) && (_editor.getStyle() & SWT.READ_ONLY)) { mixin(S_TRACE);
			w = size.x;
		} else { mixin(S_TRACE);
			auto ca = _list.getClientArea();
			w = ca.width - _list.detailAreaWidth - _list.calcX(pos) - 20.ppis;
			w = .max(_comm.prop.var.etc.nameWidth.value, w);
		}
		int h = size.y;
		auto startInfo = _list._startInfos[pos.content.parentStart.eventId];
		int y = (startInfo.y + pos.relY) + (_list._lineHeight - h) / 2 - sy;
		_editor.setBounds(x, y, w, h);
		_list.nameVisible(_editIndex, false);
	}
public:
	/// list = テキスト編集対象のEventEditor。
	/// editEnd = 編集終了時に実行される関数。
	/// createEditor = アイテムを編集するコンポーネントを生成する関数。
	///                nullを返した場合、編集は開始されない。
	this(Commons comm, EventEditor list, void delegate(EventEditorItem itm, Control ctrl) editEnd,
			Control delegate(EventEditorItem itm) createEditor = null) { mixin(S_TRACE);
		_comm = comm;
		_list = list;
		_editEnd = editEnd;
		_createEditor = createEditor;

		auto mf = new TextEditMFListener(comm, list, &startEdit, &selectionK, &selectionM);
		list.addMouseListener(mf);
		list.addSelectionListener(mf);
		list.addFocusListener(mf);
		list.addKeyListener(new TextEditKListener(&startEdit, &selectionK));
		.listener(list, SWT.Paint, &layout);
	}
	/// 選択されているセルの編集を開始する。
	void startEdit() { mixin(S_TRACE);
		auto sels = _list.getSelection();
		if (sels.length == 1) { mixin(S_TRACE);
			startEdit(sels[0]);
		}
	}
	void minimumWidth(int minimumWidth) {
		_minimumWidth = minimumWidth;
	}
	bool isEditing() { mixin(S_TRACE);
		return _tee !is null;
	}
	void cancel() { mixin(S_TRACE);
		if (!isEditing) return;
		_tee.cancel();
	}
	void enter() { mixin(S_TRACE);
		if (!isEditing) return;
		_tee.enter();
	}
}
