/// イベントを編集するためのビュー。
/// 左側にイベントと発火条件を設定するビューを、右側にEventTreeViewを配置する。
module cwx.editor.gui.dwt.eventview;

import cwx.area;
import cwx.card;
import cwx.event;
import cwx.flag;
import cwx.menu;
import cwx.path;
import cwx.script;
import cwx.skin;
import cwx.summary;
import cwx.system;
import cwx.types;
import cwx.usecounter;
import cwx.utils;
import cwx.warning;
import cwx.xml;

import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.areaviewutils;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.chooser;
import cwx.editor.gui.dwt.comment;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.eventtreedialog;
import cwx.editor.gui.dwt.eventtreeview;
import cwx.editor.gui.dwt.eventwindow;
import cwx.editor.gui.dwt.flagtable;
import cwx.editor.gui.dwt.images;
import cwx.editor.gui.dwt.messageutils;
import cwx.editor.gui.dwt.roundview;
import cwx.editor.gui.dwt.scripterrordialog;
import cwx.editor.gui.dwt.smalldialogs;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.xmlbytestransfer;

static import std.algorithm;
import std.algorithm : map, max, remove, sort, uniq;
import std.array;
import std.ascii;
import std.conv;
import std.datetime;
import std.exception;
import std.string;
import std.traits;
import std.typecons;

import org.eclipse.swt.all;

import java.lang.all;

public:

alias ArrayWrapperString KeyCodeObj;

class EventView : Composite, TCPD {
private:
	int _readOnly = 0;
	string _id = "";
	Commons _comm;
	Props _prop;
	Summary _summ;
	EventTreeOwner _area;
	UndoManager _undo;

	Skin _summSkin;
	@property
	Skin summSkin() { mixin(S_TRACE);
		return _summSkin ? _summSkin : _comm.skin;
	}

	SplitPane _sash;
	Tree _cards;
	FlagTable _flags = null;
	TreeEdit _edit;
	EventTreeView _etree;
	Object _lastFocus = null;

	Warning[] _warningRects;

	ToolBar _toolbar;
	CCombo _treeKind;
	ToolItem _fireItm;
	CCombo _keyCodeTim = null;
	ToolItem _showEventTreeDetailItm;
	ToolItem _showLineNumberItm;
	Spinner _slope = null;

	TCPD[] _tcpd;
	TreeItem _oldSelP = null;
	TreeItem _selItm = null;

	Preview _preview = null;
	AbstractSpCard _previewC = null;
	PileImage _previewI = null;
	void closePreview() { mixin(S_TRACE);
		if (_previewI) { mixin(S_TRACE);
			_preview.close();
			_previewC = null;
			_previewI.dispose();
		}
	}
	void previewTrigger(int x, int y) { mixin(S_TRACE);
		auto itm = _cards.getItem(new Point(x, y));
		if (!itm) { mixin(S_TRACE);
			closePreview();
			return;
		}
		auto c = cast(AbstractSpCard)itm.getData();
		if (!c) { mixin(S_TRACE);
			closePreview();
			return;
		}
		if (c is _previewC) { mixin(S_TRACE);
			return;
		}
		closePreview();
		_previewC = c;
		_previewI = createCardImage(c);

		auto b = itm.getBounds();
		auto p = _cards.toDisplay(b.x, b.y + b.height);
		if (_preview.getImage()) _preview.getImage().dispose();
		_preview.image(_previewI, p.x, p.y, b.height);
		_preview.show();
	}
	PileImage createCardImage(in AbstractSpCard spCard) { mixin(S_TRACE);
		if (auto card = cast(MenuCard)spCard) {
			auto name = card.name;
			if (card.expandSPChars) { mixin(S_TRACE);
				name = .createSPCharPreview(_comm, _summ, card.useCounter, name, false, null, null);
			}
			return createMenuCardImage!PileImage(_prop, _comm.skin, _summ, name,
				card.paths, 0, 0, 100, _prop.var.etc.smoothingCard, spCard.layer);
		} else if (auto card = cast(EnemyCard)spCard) {
			auto skin = _comm.skin;
			auto castCard = _summ.cwCast(card.id);
			bool dbgMode = _prop.var.etc.viewEnemyCardDebug;
			foreach (areaView; _comm.areaViewsFrom!(Battle, EnemyCard, true, is(typeof(_area.backs)))(_area.cwxPath(true), false)) { mixin(S_TRACE);
				dbgMode |= areaView.debugMode;
			}
			if (castCard) { mixin(S_TRACE);
				return createCastCardImage!PileImage(_comm, skin, _summ, card, castCard,
					0, 0, 100, _prop.var.etc.smoothingCard, dbgMode, spCard.layer);
			} else { mixin(S_TRACE);
				return createCastCardImage!PileImage(_comm, skin, _summ, card, null,
					0, 0, 100, _prop.var.etc.smoothingCard, dbgMode, spCard.layer);
			}
		} else assert (0);
	}
	class ClosePreview : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			closePreview();
		}
	}
	class PreviewTrigger : MouseTrackAdapter, MouseMoveListener {
		private Object _lastData = null;
		override void mouseEnter(MouseEvent e) { mixin(S_TRACE);
			if (_prop.var.etc.showCardStatusUnderPointer) _etree.refreshStatusLine();
		}
		override void mouseExit(MouseEvent e) { mixin(S_TRACE);
			closePreview();
			if (_prop.var.etc.showCardStatusUnderPointer) _etree.refreshStatusLine();
		}
		override void mouseMove(MouseEvent e) { mixin(S_TRACE);
			previewTrigger(e.x, e.y);

			auto itm = _cards.getItem(new Point(e.x, e.y));
			auto d = itm ? itm.getData() : null;
			if (d !is _lastData) { mixin(S_TRACE);
				_lastData = d;
				if (_prop.var.etc.showCardStatusUnderPointer) { mixin(S_TRACE);
					if (auto card = cast(MenuCard)d) { mixin(S_TRACE);
						_etree.statusLine = .createAreaViewStatusLine(_comm, _summ, summSkin, card);
					} else if (auto card = cast(EnemyCard)d) { mixin(S_TRACE);
						_etree.statusLine = .createAreaViewStatusLine(_comm, _summ, summSkin, card);
					} else { mixin(S_TRACE);
						_etree.refreshStatusLine();
					}
				}
			}
		}
	}

	static EventTreeOwner[] etos(EventTreeOwner eto) { mixin(S_TRACE);
		EventTreeOwner[] r;
		r ~= eto;
		if (auto area = cast(Area)eto) { mixin(S_TRACE);
			r ~= area.playerEvents;
			foreach (c; area.cards) { mixin(S_TRACE);
				r ~= c;
			}
		} else if (auto area = cast(Battle)eto) { mixin(S_TRACE);
			r ~= area.playerEvents;
			foreach (c; area.cards) { mixin(S_TRACE);
				r ~= c;
			}
		}
		return r;
	}

	static EventView mainEventView(EventView[] vs) { mixin(S_TRACE);
		if (!vs.length) return null;
		auto ct = Display.getCurrent().getFocusControl();
		if (!ct) return vs[0];
		foreach (v; vs) { mixin(S_TRACE);
			while (ct.getParent()) { mixin(S_TRACE);
				if (ct is v) { mixin(S_TRACE);
					return v;
				}
				ct = ct.getParent();
			}
		}
		return vs[0];
	}

	abstract static class EVUndo : Undo {
		abstract override void undo();
		abstract override void redo();
		abstract override void dispose();
		protected Commons comm;
		protected EventTreeOwner area;
		protected bool doBefore = true;
		protected bool doAfter = true;
		private int[] _selPath = [], _selPath2 = [];
		private int[] getSelPath(EventView v) { mixin(S_TRACE);
			if (!v) return null;
			auto itm = v.selection;
			if (itm) { mixin(S_TRACE);
				int[] selPath;
				while (itm.getParentItem()) { mixin(S_TRACE);
					selPath = [itm.getParentItem().indexOf(itm)] ~ selPath;
					itm = itm.getParentItem();
				}
				return [v._cards.indexOf(itm)] ~ selPath;
			} else { mixin(S_TRACE);
				return null;
			}
		}
		this (Commons comm, EventTreeOwner area) { mixin(S_TRACE);
			this.comm = comm;
			this.area = area;
			auto vs = views();
			if (vs.length) _selPath = getSelPath(mainEventView(vs));
		}
		protected void udb(EventView[] vs) { mixin(S_TRACE);
			if (!vs.length) return;
			auto mainV = mainEventView(vs);
			_selPath2 = getSelPath(mainV);
			if (!doBefore) return;
			auto ct = Display.getCurrent().getFocusControl();
			if (!ct) return;
			foreach (v; vs) { mixin(S_TRACE);
				while (ct.getParent()) { mixin(S_TRACE);
					if (ct is v) { mixin(S_TRACE);
						return;
					}
					ct = ct.getParent();
				}
			}
			.forceFocus(mainV._cards, false);
		}
		protected void uda(EventView[] vs) { mixin(S_TRACE);
			if (doAfter) { mixin(S_TRACE);
				scope (exit) comm.refreshToolBar();
				foreach (v; vs) { mixin(S_TRACE);
					auto selPath = _selPath.dup;
					if (selPath) { mixin(S_TRACE);
						auto itm = v._cards.getItem(selPath[0]);
						selPath = selPath[1 .. $];
						while (selPath.length) { mixin(S_TRACE);
							if (itm.getItemCount() <= selPath[0]) { mixin(S_TRACE);
								// キーコードを空白で置換した時に項目が減っており、
								// 選択状態を再現できない場合がある
								break;
							}
							itm = itm.getItem(selPath[0]);
							selPath = selPath[1 .. $];
						}
						auto eti = v.selectionEventTree;
						v._cards.select(itm);
						auto eti2 = v.selectionEventTree;
						if (eti !is eti2) { mixin(S_TRACE);
							if (eti2) { mixin(S_TRACE);
								v.selectImpl(eti2);
							} else if (!eti) { mixin(S_TRACE);
								v._etree.refresh(null);
							}
						}
					} else { mixin(S_TRACE);
						v._cards.deselectAll();
					}
				}
			}
			_selPath = _selPath2;
		}
		protected EventView[] views() { mixin(S_TRACE);
			return comm.eventViewsFrom(area, false);
		}
	}
	static class UndoSeq : EVUndo {
		private EVUndo[] _undos;
		this (Commons comm, EventTreeOwner area, EVUndo[] undos) { mixin(S_TRACE);
			super (comm, area);
			_undos = undos;
		}
		override void undo() { mixin(S_TRACE);
			auto vs = views();
			foreach (v; vs) v._cards.setRedraw(false);
			scope (exit) {
				foreach (v; vs) v._cards.setRedraw(true);
			}
			foreach_reverse (i, undo; _undos) { mixin(S_TRACE);
				undo.doBefore = (i + 1 == _undos.length);
				undo.doAfter = (i == 0);
				undo.undo();
			}
		}
		override void redo() { mixin(S_TRACE);
			auto vs = views();
			foreach (v; vs) v._cards.setRedraw(false);
			scope (exit) {
				foreach (v; vs) v._cards.setRedraw(true);
			}
			foreach (i, undo; _undos) { mixin(S_TRACE);
				undo.doBefore = (i == 0);
				undo.doAfter = (i + 1 == _undos.length);
				undo.redo();
			}
		}
		override void dispose() { mixin(S_TRACE);
			foreach (undo; _undos) undo.dispose();
		}
	}
	static class UndoTreeData : EVUndo {
		private size_t _ownerIndex;
		private size_t _index;
		private static struct Vals {
			string name;
			bool enter;
			bool escape;
			bool lose;
			bool everyRound;
			bool roundEnd;
			bool round0;
			FKeyCode[] keyCodes;
			MatchingType keyCodeMatchingType;
			uint[] rounds;
		}
		private Vals _vals;
		private bool[EventTreeOwner] _expand;
		this (Commons comm, EventTreeOwner area, EventTree tree) { mixin(S_TRACE);
			super (comm, area);
			auto eto = tree.owner;
			_index = .cCountUntil!("a is b")(tree.owner.trees, tree);
			_ownerIndex = .cCountUntil!("a is b")(etos(area), eto);
			foreach (v; views()) { mixin(S_TRACE);
				_expand[v._area] = getItem(v).getExpanded();
			}
			save(tree);
		}
		private void save(EventTree tree) { mixin(S_TRACE);
			_vals.name = tree.name;
			_vals.enter = tree.fireEnter;
			_vals.escape = tree.fireEscape;
			_vals.lose = tree.fireLose;
			_vals.everyRound = tree.fireEveryRound;
			_vals.roundEnd = tree.fireRoundEnd;
			_vals.round0 = tree.fireRound0;
			_vals.keyCodes = tree.keyCodes.dup;
			_vals.keyCodeMatchingType = tree.keyCodeMatchingType;
			_vals.rounds = tree.rounds.dup;
		}
		private TreeItem getItem(EventView v) { mixin(S_TRACE);
			enforce(v);
			return v._cards.getItem(cast(int)_ownerIndex).getItem(cast(int)_index);
		}
		private void impl() { mixin(S_TRACE);
			auto vs = views();
			udb(vs);
			scope (exit) uda(vs);
			auto tree = etos(area)[_ownerIndex].trees[_index];
			auto vals = _vals;
			save(tree);
			tree.name = vals.name;
			tree.enter = vals.enter;
			tree.escape = vals.escape;
			tree.lose = vals.lose;
			tree.everyRound = vals.everyRound;
			tree.roundEnd = vals.roundEnd;
			tree.round0 = vals.round0;
			tree.removeKeyCodesAll();
			foreach (kc; vals.keyCodes) tree.addKeyCode(kc);
			tree.keyCodeMatchingType = vals.keyCodeMatchingType;
			tree.removeRoundsAll();
			foreach (rnd; vals.rounds) tree.addRound(rnd);
			tree.sortRounds();
			foreach (v; vs) { mixin(S_TRACE);
				auto itm = getItem(v);
				auto expand = _expand[v._area];
				_expand[v._area] = getItem(v).getExpanded();
				itm.setExpanded(expand);
				itm.setText(vals.name);
				itm.setImage(v.etImage(tree));
				v._etree.refreshTreeName();
				v.refreshFires(itm);
				auto p = tree.objectId in v._commentDlgs;
				if (p) p.title = .tryFormat(comm.prop.msgs.dlgTitCommentWith, tree.name);
			}
			comm.refEventTree.call(tree);
			comm.refKeyCodes.call();
		}
		override void undo() { impl(); }
		override void redo() { impl(); }
		override void dispose() { }
	}
	EVUndo store(EventTree tree, bool put = true) { mixin(S_TRACE);
		auto undo = new UndoTreeData(_comm, _area, tree);
		if (put) _undo ~= undo;
		return undo;
	}
	static class UndoContents : EVUndo {
		private size_t _ownerIndex;
		private size_t _index;
		private Content[] _starts;
		private Summary _summ;
		this (Commons comm, EventTreeOwner area, Summary summ, EventTree tree) { mixin(S_TRACE);
			super (comm, area);
			auto eto = tree.owner;
			_index = .cCountUntil!("a is b")(tree.owner.trees, tree);
			_ownerIndex = .cCountUntil!("a is b")(etos(area), eto);
			_summ = summ;
			save(tree);
		}
		private void save(EventTree tree) { mixin(S_TRACE);
			_starts = new Content[tree.starts.length];
			foreach (i, s; tree.starts) { mixin(S_TRACE);
				_starts[i] = s.dup;
				_starts[i].setUseCounter(s.useCounter.sub, s);
			}
		}
		private TreeItem getItem(EventView v) { mixin(S_TRACE);
			enforce(v);
			return v._cards.getItem(cast(int)_ownerIndex).getItem(cast(int)_index);
		}
		private void impl() { mixin(S_TRACE);
			auto vs = views();
			udb(vs);
			scope (exit) uda(vs);
			auto tree = etos(area)[_ownerIndex].trees[_index];
			foreach (s; tree.starts) { mixin(S_TRACE);
				comm.delContent.call(s);
			}
			auto starts = _starts;
			save(tree);
			tree.starts = starts;
			foreach (v; vs) { mixin(S_TRACE);
				if (v._etree && v._etree.eventTree is tree) { mixin(S_TRACE);
					v._etree.refresh(null);
					v._etree.refresh(tree);
				}
			}
			comm.refEventTree.call(tree);
			comm.refKeyCodes.call();
		}
		override void undo() { impl(); }
		override void redo() { impl(); }
		override void dispose() { mixin(S_TRACE);
			foreach (s; _starts) s.removeUseCounter();
		}
	}
	EVUndo storeContents(EventTree tree, bool put = true) { mixin(S_TRACE);
		auto undo = new UndoContents(_comm, _area, _summ, tree);
		if (put) _undo ~= undo;
		return undo;
	}
	static class UndoInsert : EVUndo {
		private size_t _ownerIndex;
		private size_t _insertIndex;
		private UndoDelete _delUndo = null;
		private Summary _summ;
		this (Commons comm, EventTreeOwner area, Summary summ, size_t ownerIndex, size_t insertIndex) { mixin(S_TRACE);
			super (comm, area);
			_ownerIndex = ownerIndex;
			_insertIndex = insertIndex;
			_summ = summ;
		}
		override void undo() { mixin(S_TRACE);
			auto vs = views();
			udb(vs);
			scope (exit) uda(vs);
			undoImpl(vs);
		}
		void undoImpl(EventView[] vs) { mixin(S_TRACE);
			auto owner = etos(area)[_ownerIndex];
			auto tree = owner.trees[_insertIndex];
			_delUndo = new UndoDelete(comm, area, _summ, tree);
			owner.removeEvent(_insertIndex);
			foreach (v; vs) { mixin(S_TRACE);
				if (v._etree.eventTree && v._etree.eventTree.areaPath == tree.areaPath) { mixin(S_TRACE);
					v._etree.refresh(null);
				}
				auto ownItm = v._cards.getItem(cast(int)_ownerIndex);
				auto itm = ownItm.getItem(cast(int)_insertIndex);
				if (v._selItm is itm) { mixin(S_TRACE);
					v._selItm.setImage(v.etImage(tree));
					v._selItm = null;
				}
				foreach (dlg; v._editDlgs.values) { mixin(S_TRACE);
					if (dlg.eventTree is tree) dlg.forceCancel();
				}
				foreach (key; v._commentDlgs.keys) { mixin(S_TRACE);
					if (key == tree.objectId) v._commentDlgs[key].forceCancel();
				}
				itm.dispose();
			}
			comm.delEventTree.call(tree);
			comm.refUseCount.call();
		}
		override void redo() { mixin(S_TRACE);
			auto vs = views();
			udb(vs);
			scope (exit) uda(vs);
			_delUndo.undoImpl(vs);
			_delUndo = null;
		}
		override void dispose() { mixin(S_TRACE);
			if (_delUndo) _delUndo.dispose();
		}
	}
	EVUndo storeI(size_t ownerIndex, size_t insertIndex, bool put = true) { mixin(S_TRACE);
		auto undo = new UndoInsert(_comm, _area, _summ, ownerIndex, insertIndex);
		if (put) _undo ~= undo;
		return undo;
	}
	static class UndoDelete : EVUndo {
		private int _ownerIndex;
		private int _treeIndex;
		private EventTree _tree;
		private UndoInsert _istUndo = null;
		private Summary _summ;
		this (Commons comm, EventTreeOwner area, Summary summ, EventTree tree) { mixin(S_TRACE);
			super (comm, area);
			_summ = summ;
			auto owner = tree.owner;
			_ownerIndex = cast(int).cCountUntil!("a is b")(etos(area), owner);
			_treeIndex = cast(int).cCountUntil!("a is b")(owner.trees, tree);
			_tree = tree.dup;
			_tree.setUseCounter(tree.useCounter.sub, tree);
		}
		override void undo() { mixin(S_TRACE);
			auto vs = views();
			udb(vs);
			scope (exit) uda(vs);
			undoImpl(vs);
		}
		void undoImpl(EventView[] vs) { mixin(S_TRACE);
			_istUndo = new UndoInsert(comm, area, _summ, _ownerIndex, _treeIndex);
			if (vs.length) { mixin(S_TRACE);
				TreeItem[] itms;
				foreach (v; vs) itms ~= v._cards.getItem(_ownerIndex);
				auto tree = _tree.dup;
				foreach (i, v; vs) v.appendTree(itms[i], tree, _treeIndex, null, false, 0 < i, true);
			} else { mixin(S_TRACE);
				auto eto = etos(area)[_ownerIndex];
				appendTreeImpl(comm, eto, _tree.dup, _treeIndex);
			}
		}
		override void redo() { mixin(S_TRACE);
			auto vs = views();
			udb(vs);
			scope (exit) uda(vs);
			_istUndo.undoImpl(vs);
			_istUndo = null;
		}
		override void dispose() { mixin(S_TRACE);
			_tree.removeUseCounter();
			if (_istUndo) _istUndo.dispose();
			foreach (v; views()) { mixin(S_TRACE);
				v.removeStoredLine(_tree.objectId);
			}
		}
	}
	EVUndo storeD(EventTree tree, bool put = true) { mixin(S_TRACE);
		auto undo = new UndoDelete(_comm, _area, _summ, tree);
		if (put) _undo ~= undo;
		return undo;
	}
	static class UndoSwap : EVUndo {
		private int _ownerIndex;
		private int _swapIndex1;
		private int _swapIndex2;
		this (Commons comm, EventTreeOwner area, int ownerIndex, int swapIndex1, int swapIndex2) { mixin(S_TRACE);
			super (comm, area);
			_ownerIndex = ownerIndex;
			_swapIndex1 = swapIndex1;
			_swapIndex2 = swapIndex2;
		}
		private void impl() { mixin(S_TRACE);
			auto vs = views();
			udb(vs);
			scope (exit) uda(vs);
			if (vs.length) { mixin(S_TRACE);
				auto mainV = mainEventView(vs);
				auto itm = mainV._cards.getItem(_ownerIndex).getItem(max(_swapIndex1, _swapIndex2));
				mainV.up(itm, false, true, false);
			} else { mixin(S_TRACE);
				staticUDImpl(comm, etos(area)[_ownerIndex], _swapIndex1, _swapIndex2);
			}
		}
		override void undo() { impl(); }
		override void redo() { impl(); }
		override void dispose() { }
	}
	EVUndo store(int ownerIndex, int swapIndex1, int swapIndex2, bool put = true) { mixin(S_TRACE);
		auto undo = new UndoSwap(_comm, _area, ownerIndex, swapIndex1, swapIndex2);
		if (put) _undo ~= undo;
		return undo;
	}
	static class UndoComment : EVUndo {
		private ObjectId _obj;
		private string _comment;
		this (Commons comm, EventTreeOwner area, ObjectId obj) { mixin(S_TRACE);
			super (comm, area);
			_obj = obj;
			save();
		}
		private void save() { mixin(S_TRACE);
			if (auto eto = cast(EventTreeOwner)_obj) { mixin(S_TRACE);
				_comment = eto.commentForEvents;
			} else if (auto ct = cast(Commentable)_obj) { mixin(S_TRACE);
				_comment = ct.comment;
			} else assert (0);
		}
		private void impl() { mixin(S_TRACE);
			auto vs = views();
			udb(vs);
			scope (exit) uda(vs);

			auto comment = _comment;
			save();
			if (auto eto = cast(EventTreeOwner)_obj) { mixin(S_TRACE);
				eto.commentForEvents = comment;
			} else if (auto ct = cast(Commentable)_obj) { mixin(S_TRACE);
				ct.comment = comment;
			}

			foreach (v; vs) { mixin(S_TRACE);
				v._cards.redraw();
			}
		}
		override void undo() { impl(); }
		override void redo() { impl(); }
		override void dispose() { }
	}

	private EventView[] views() { mixin(S_TRACE);
		auto vs = _comm.eventViewsFrom(_area, false);
		foreach (v; vs) { mixin(S_TRACE);
			if (v.setupToolBar()) _comm.refreshToolBar();
		}
		return vs;
	}

	void forceSel(size_t[] etAreaPath) { mixin(S_TRACE);
		auto eet = _etree.eventTree;
		if (eet && eet.areaPath == etAreaPath) return;
		size_t[] eta;
		if (auto area = cast(AbstractArea)_area) { mixin(S_TRACE);
			eta = area.etFromPath(etAreaPath).areaPath;
		} else if (auto card = cast(EffectCard)_area) { mixin(S_TRACE);
			eta = card.etFromPath(etAreaPath).areaPath;
		} else assert (0);
		foreach (i, itm; _cards.getItems()) { mixin(S_TRACE);
			foreach (j, tItm; itm.getItems()) { mixin(S_TRACE);
				auto cet = cast(EventTree)tItm.getData();
				assert (cet);
				if (cet.areaPath == eta) { mixin(S_TRACE);
					selectImpl(tItm);
					return;
				}
			}
		}
		assert (0);
	}

	void removeStoredLine(string objectId) { mixin(S_TRACE);
		_etree.removeStoredLine(objectId);
	}

	void selectImpl(TreeItem itm, bool sel = true, bool forceRefresh = false) { mixin(S_TRACE);
		if (sel) _cards.setSelection([itm]);
		if (auto et = cast(EventTree)itm.getData()) { mixin(S_TRACE);
			auto old = _etree.eventTree;
			_etree.refresh(et);
			if (_selItm && !_selItm.isDisposed() && old) { mixin(S_TRACE);
				assert (old !is null);
				_selItm.setImage(etImage(old));
			}
			_selItm = itm;
			_selItm.setImage(etImage(et));
		}
		if (_fireItm) { mixin(S_TRACE);
			auto parItm = selectionParent;
			if (parItm && (!_oldSelP || _oldSelP != parItm) && _treeKind.getSelectionIndex() == 0) { mixin(S_TRACE);
				auto c = cast(CCombo)_fireItm.getControl();
				auto oldText = c.getText();
				c.removeAll();
				string[] vals;
				if (cast(EventTreeOwner)parItm.getData()) { mixin(S_TRACE);
					vals = startDefVals;
				}
				foreach (i, v; vals) { mixin(S_TRACE);
					c.add(v);
					if (oldText == v) c.setText(v);
				}
				if (c.getSelectionIndex() == -1) c.select(0);
			}
		}
		_comm.refreshToolBar();
	}

	void refreshTopStart() { mixin(S_TRACE);
		assert (_selItm);
		assert (_selItm.getData() is _etree.eventTree);
		_selItm.setText(_etree.eventTree.name);
		auto p = _etree.eventTree.objectId in _commentDlgs;
		if (p) p.title = .tryFormat(_prop.msgs.dlgTitCommentWith, _etree.eventTree.name);
	}
	class SListener : SelectionAdapter {
		public override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			selectImpl(cast(TreeItem) e.item, false);
		}
	}
	static int before(T)(T parent, int index) { mixin(S_TRACE);
		if (index > 0) { mixin(S_TRACE);
			return index - 1;
		}
		return -1;
	}
	static int after(T)(T parent, int index) { mixin(S_TRACE);
		if (index + 1 < parent.getItemCount()) { mixin(S_TRACE);
			return index + 1;
		}
		return -1;
	}
	@property
	TreeItem selection() { mixin(S_TRACE);
		auto sels = _cards.getSelection();
		if (sels.length > 0) { mixin(S_TRACE);
			return sels[0];
		}
		return null;
	}
	@property
	void selection(int index) { mixin(S_TRACE);
		selectImpl(_cards.getItems()[index]);
	}
	@property
	private TreeItem selectionParent() { mixin(S_TRACE);
		return topParent(selection);
	}
	@property
	private TreeItem topParent(TreeItem itm) { mixin(S_TRACE);
		if (!itm) return null;
		auto data = itm.getData();
		if (cast(EventTreeOwner)data) return itm;
		if (cast(EventTree)data) { mixin(S_TRACE);
			return itm.getParentItem();
		} else { mixin(S_TRACE);
			return itm.getParentItem().getParentItem();
		}
	}
	@property
	private TreeItem selectionEventTree() { mixin(S_TRACE);
		auto itm = selection;
		if (!itm) return null;
		return eventItemFrom(itm);
	}
	private TreeItem eventItemFrom(TreeItem itm) { mixin(S_TRACE);
		auto data = itm.getData();
		if (cast(EventTreeOwner)data) return null;
		if (cast(EventTree)data) { mixin(S_TRACE);
			return itm;
		} else { mixin(S_TRACE);
			return itm.getParentItem();
		}
	}
	private TreeItem findItem(in EventTree et) { mixin(S_TRACE);
		auto eto = et.owner;
		foreach (itm; _cards.getItems()) { mixin(S_TRACE);
			if (cast(EventTreeOwner)itm.getData() is eto) { mixin(S_TRACE);
				foreach (itm2; itm.getItems()) {mixin(S_TRACE);
					if (itm2.getData() is et) return itm2;
				}
				break;
			}
		}
		return null;
	}
	@property
	private TreeItem selectionKeyCode() { mixin(S_TRACE);
		auto itm = selection;
		if (!itm) return null;
		auto data = itm.getData();
		return cast(KeyCodeObj)data ? itm : null;
	}
	public static string[] eventTreeNames(in Props prop, in EventTree tree) { mixin(S_TRACE);
		auto owner = tree.owner;
		string[] treeName = [];
		if (tree.fireEnter) { mixin(S_TRACE);
			if (cast(MenuCard)owner) {
				treeName ~= prop.msgs.selectTree;
			} else if (cast(EnemyCard)owner) { mixin(S_TRACE);
				treeName ~= prop.msgs.deadTree;
			} else if (cast(Area)owner) { mixin(S_TRACE);
				treeName ~= prop.msgs.enterTree;
			} else if (cast(Battle)owner) { mixin(S_TRACE);
				treeName ~= prop.msgs.victoryTree;
			} else if (cast(Package)owner) { mixin(S_TRACE);
				treeName ~= prop.msgs.packageTree;
			} else if (cast(PlayerCardEvents)owner) { mixin(S_TRACE);
				// Wsn.2
				treeName ~= prop.msgs.playerCard;
			} else { mixin(S_TRACE);
				treeName ~= prop.msgs.useTree;
			}
		}
		if (tree.fireEscape) { mixin(S_TRACE);
			treeName ~= prop.msgs.escapeTree;
		}
		if (tree.fireLose) { mixin(S_TRACE);
			treeName ~= prop.msgs.loseTree;
		}
		if (tree.fireEveryRound) { mixin(S_TRACE);
			treeName ~= prop.msgs.everyRoundTree;
		}
		if (tree.fireRoundEnd) { mixin(S_TRACE);
			treeName ~= prop.msgs.roundEndTree;
		}
		if (tree.fireRound0) { mixin(S_TRACE);
			treeName ~= prop.msgs.round0Tree;
		}
		foreach (keyCode; tree.keyCodes) { mixin(S_TRACE);
			treeName ~= .tryFormat(prop.msgs.keyCodeTree, keyCode);
		}
		if (tree.rounds.length == 1) { mixin(S_TRACE);
			foreach (round; tree.rounds) { mixin(S_TRACE);
				treeName ~= .tryFormat(prop.msgs.roundTree, round);
			}
		}
		return treeName;
	}
	private EventTreeDialog[string] _editDlgs;
	private void appliedEditTree(TreeItem itm, EVUndo undo) in (itm !is null && undo !is null) { mixin(S_TRACE);
		auto et = cast(EventTree)itm.getData();
		_undo ~= undo;
		auto vs = views();
		foreach (v; vs) { mixin(S_TRACE);
			auto itm2 = .anotherTreeItem(v._cards, itm);
			if (itm2.getText() != et.name) { mixin(S_TRACE);
				itm2.setText(et.name);
				v._etree.refreshTreeName();
				auto p = et.objectId in v._commentDlgs;
				if (p) p.title = .tryFormat(_prop.msgs.dlgTitCommentWith, et.name);
			}
			v.refreshFires(itm2);
		}
	}
	void editEvent() { mixin(S_TRACE);
		auto itm = selectionEventTree;
		if (!itm) return;
		auto et = cast(EventTree)itm.getData();
		auto dlg = new EventTreeDialog(_comm, getShell(), _summ, et.owner, et, false, _readOnly != SWT.NONE);
		EVUndo undo = null;
		dlg.applyEvent ~= { mixin(S_TRACE);
			undo = store(et, false);
		};
		dlg.appliedEvent ~= { mixin(S_TRACE);
			appliedEditTree(findItem(et), undo);
		};
		_editDlgs[et.objectId] = dlg;
		dlg.closeEvent ~= { mixin(S_TRACE);
			_editDlgs.remove(et.objectId);
		};
		dlg.open();
	}
	@property
	bool canCreateEvent() { mixin(S_TRACE);
		return !_readOnly && selectionParent && !(cast(PlayerCardEvents)selectionParent.getData() && _summ.legacy);
	}
	void createEvent() { mixin(S_TRACE);
		if (!canCreateEvent) return;
		auto parItm = selectionParent;
		auto owner = cast(EventTreeOwner)parItm.getData();
		auto sys = owner.canHasFireEnter || owner.canHasFireLose || owner.canHasFireEscape || owner.canHasFireEveryRound || owner.canHasFireRoundEnd || owner.canHasFireRound0;
		auto kc = owner.canHasFireKeyCode;
		auto round = owner.canHasFireRound;
		if (!(sys || kc || round)) { mixin(S_TRACE);
			createEventWithIgnition();
			return;
		}
		auto et = new EventTree("");
		auto dlg = new EventTreeDialog(_comm, getShell(), _summ, owner, et, true, _readOnly != SWT.NONE);
		dlg.appliedEvent ~= { mixin(S_TRACE);
			auto index = parItm.getParent().indexOf(parItm);
			auto appendIndex = owner.trees.length;
			auto vs = views();
			TreeItem[] parItms;
			foreach (i, v; vs) { mixin(S_TRACE);
				v.editEnter();
				parItms ~= v._cards.getItem(index);
				v.appendTree(parItms[i], et, cast(int)appendIndex, null, true, 0 < i, true);
			}
			if (et.keyCodes.length) { mixin(S_TRACE);
				_comm.refKeyCodes.call();
			}
			_comm.refreshToolBar();

			dlg.appliedEvent.length = 0;

			EVUndo undo = null;
			dlg.applyEvent ~= { mixin(S_TRACE);
				undo = store(et, false);
			};
			dlg.appliedEvent ~= { mixin(S_TRACE);
				appliedEditTree(findItem(et), undo);
			};
		};
		_editDlgs[et.objectId] = dlg;
		dlg.closeEvent ~= { mixin(S_TRACE);
			_editDlgs.remove(et.objectId);
		};
		dlg.open();
	}
	void createEventWithIgnition() { mixin(S_TRACE);
		createEventWithIgnition([]);
	}
	void createEventWithIgnition(Content[] starts) { mixin(S_TRACE);
		if (_readOnly) return;
		foreach (s; starts) { mixin(S_TRACE);
			if (s.type !is CType.Start) return;
		}
		auto parItm = selectionParent;
		if (!parItm) return;
		auto a = parItm.getData();
		if (cast(PlayerCardEvents)a && _summ.legacy) return;
		auto index = parItm.getParent().indexOf(parItm);
		auto vs = views();
		TreeItem[] parItms;
		foreach (v; vs) { mixin(S_TRACE);
			v.editEnter();
			parItms ~= v._cards.getItem(index);
		}
		string treeName = "";
		auto fire = addingFire(parItm.getData());
		if (!fire) return;
		if (fire is ENTER) { mixin(S_TRACE);
			if (cast(MenuCard)a) { mixin(S_TRACE);
				treeName = _prop.msgs.selectTree;
			} else if (cast(EnemyCard)a) { mixin(S_TRACE);
				treeName = _prop.msgs.deadTree;
			} else if (cast(Area)a) { mixin(S_TRACE);
				treeName = _prop.msgs.enterTree;
			} else if (cast(Battle)a) { mixin(S_TRACE);
				treeName = _prop.msgs.victoryTree;
			} else if (cast(Package)a) { mixin(S_TRACE);
				treeName = _prop.msgs.packageTree;
			} else if (cast(PlayerCardEvents)a) { mixin(S_TRACE);
				treeName = _prop.msgs.deadTree;
			} else { mixin(S_TRACE);
				treeName = _prop.msgs.useTree;
			}
		} else if (fire is ESCAPE) { mixin(S_TRACE);
			treeName = _prop.msgs.escapeTree;
		} else if (fire is LOSE) { mixin(S_TRACE);
			treeName = _prop.msgs.loseTree;
		} else if (fire is EVERY_ROUND) { mixin(S_TRACE);
			treeName = _prop.msgs.everyRoundTree;
		} else if (fire is ROUND_END) { mixin(S_TRACE);
			treeName = _prop.msgs.roundEndTree;
		} else if (fire is ROUND_0) { mixin(S_TRACE);
			treeName = _prop.msgs.round0Tree;
		} else if (cast(KeyCodeObj)fire) { mixin(S_TRACE);
			treeName = .tryFormat(_prop.msgs.keyCodeTree, (cast(KeyCodeObj)fire).array.idup);
		} else { mixin(S_TRACE);
			assert (cast(RoundObj)fire);
			treeName = .tryFormat(_prop.msgs.roundTree, (cast(RoundObj)fire).intValue());
		}
		auto owner = cast(EventTreeOwner)parItm.getData();
		EventTree tree;
		if (starts.length) { mixin(S_TRACE);
			tree = new EventTree(starts[0]);
			foreach (s; starts[1 .. $]) { mixin(S_TRACE);
				tree.add(s);
			}
		} else { mixin(S_TRACE);
			tree = new EventTree(treeName);
		}
		auto appendIndex = owner.trees.length;
		foreach (i, v; vs) { mixin(S_TRACE);
			v.appendTree(parItms[i], tree, cast(int)appendIndex, fire, true, 0 < i, true);
		}
		if (starts.length) { mixin(S_TRACE);
			_comm.refUseCount.call();
		}
		_comm.refreshToolBar();
	}

	private CommentDialog[string] _commentDlgs;
	@property
	private bool canWriteCommentL() { mixin(S_TRACE);
		if (_readOnly) return false;
		auto sel = selection;
		if (!sel) return false;
		if (_summ && _summ.legacy && cast(PlayerCardEvents)sel.getData()) return false;
		return cast(EventTreeOwner)sel.getData() || cast(EventTree)sel.getData();
	}
	private void writeCommentL() { mixin(S_TRACE);
		if (!canWriteCommentL) return;
		editEnter();
		auto sel = selection;
		assert (sel !is null);
		auto obj = cast(ObjectId)sel.getData();
		assert (obj !is null);
		auto p = obj.objectId in _commentDlgs;
		if (p) { mixin(S_TRACE);
			p.active();
			return;
		}
		string comment;
		string name;
		if (auto eto = cast(EventTreeOwner)obj) { mixin(S_TRACE);
			comment = eto.commentForEvents;
			if (auto area = cast(AbstractArea)eto) { mixin(S_TRACE);
				name = area.name;
			} else if (auto card = cast(EffectCard)eto) { mixin(S_TRACE);
				name = card.name;
			} else if (auto card = cast(AbstractSpCard)eto) { mixin(S_TRACE);
				name = cardName(card);
			} else if (cast(PlayerCardEvents)eto) { mixin(S_TRACE);
				name = _prop.msgs.playerCard;
			} else assert (0);
		} else if (auto et = cast(EventTree)obj) { mixin(S_TRACE);
			comment = et.comment;
			name = et.name;
		} else assert (0);
		auto dlg = new CommentDialog(_comm, _cards.getShell(), comment);
		dlg.title = .tryFormat(_prop.msgs.dlgTitCommentWith, name);
		dlg.appliedEvent ~= { mixin(S_TRACE);
			_undo ~= new UndoComment(_comm, _area, obj);
			if (auto eto = cast(EventTreeOwner)obj) { mixin(S_TRACE);
				eto.commentForEvents = dlg.comment;
			} else if (auto et = cast(EventTree)obj) { mixin(S_TRACE);
				et.comment = dlg.comment;
			} else assert (0);
			_cards.redraw();
		};
		_commentDlgs[obj.objectId] = dlg;
		dlg.closeEvent ~= { mixin(S_TRACE);
			_commentDlgs.remove(obj.objectId);
		};
		dlg.open();
	}

	private static void appendTreeImpl(Commons comm, EventTreeOwner eto, EventTree tree, int index) { mixin(S_TRACE);
		eto.insert(index, tree);
		comm.refEventTree.call(tree);
		comm.refUseCount.call();
	}
	void appendTree(TreeItem parItm, EventTree tree, int index, Object defFire, bool store, bool viewOnly, bool thisOnly) { mixin(S_TRACE);
		EVUndo undo = null;
		appendTree(parItm, tree, index, defFire, store, viewOnly, thisOnly, undo);
	}
	void appendTree(TreeItem parItm, EventTree tree, int index, Object defFire, bool store, bool viewOnly, bool thisOnly, out EVUndo undo) { mixin(S_TRACE);
		if (_readOnly) return;
		auto eto = cast(EventTreeOwner)parItm.getData();
		if (!viewOnly) { mixin(S_TRACE);
			undo = storeI(_cards.indexOf(parItm), eto.trees.length, store);
			appendTreeImpl(_comm, eto, tree, index);
		}
		auto treeItm = appendTreeItem(parItm, index, defFire, thisOnly);
		selectImpl(treeItm);
	}
	void refreshTrees(TreeItem parItm) { mixin(S_TRACE);
		auto par = cast(EventTreeOwner) parItm.getData();
		parItm.removeAll();
		foreach (index, tree; par.trees) { mixin(S_TRACE);
			appendTreeItem(parItm, cast(int)index, null, true);
		}
		parItm.setExpanded(true);
		_comm.refreshToolBar();
	}
	Image etImage(in EventTree tree) { mixin(S_TRACE);
		if (_prop.var.etc.specifySelectedEventTree && _etree.eventTree is tree) { mixin(S_TRACE);
			final switch (tree.keyCodeMatchingType) {
			case MatchingType.Or: return _prop.images.eventTreeSelected;
			case MatchingType.And: return _prop.images.eventTreeAndSelected;
			}
		} else { mixin(S_TRACE);
			final switch (tree.keyCodeMatchingType) {
			case MatchingType.Or: return _prop.images.eventTree;
			case MatchingType.And: return _prop.images.eventTreeAnd;
			}
		}
	}
	TreeItem appendTreeItem(TreeItem parItm, int index, Object defFire, bool thisOnly) { mixin(S_TRACE);
		auto par = cast(EventTreeOwner)parItm.getData();
		auto tree = par.trees[index];
		auto treeItm = createTreeItem(parItm, tree, tree.name, etImage(tree), index);
		if (defFire) addFire(treeItm, defFire);
		refreshFires(treeItm, null, thisOnly);
		return treeItm;
	}
	Control createEditor(TreeItem itm) { mixin(S_TRACE);
		if (_readOnly) return null;
		if (cast(EventTree)itm.getData()) { mixin(S_TRACE);
			return .createTextEditor(_comm, _prop, _cards, itm.getText());
		} else if (cast(KeyCodeObj)itm.getData()) { mixin(S_TRACE);
			auto combo = .createKeyCodeCombo!Combo(_comm, _summ, _cards, null, itm.getText(), true);
			combo.setText(itm.getText());
			return combo;
		}
		return null;
	}
	void editEnd(TreeItem itm, Control c) { mixin(S_TRACE);
		if (_readOnly) return;
		string text;
		if (auto t = cast(Text)c) { mixin(S_TRACE);
			text = t.getText();
		} else if (auto t = cast(Combo)c) { mixin(S_TRACE);
			text = t.getText();
		} else assert (0);
		if (!text) text = "";
		auto tree = cast(EventTree)itm.getData();
		if (tree) { mixin(S_TRACE);
			if (text == tree.name) return;
			store(tree);
			text = createNewName(text, (string name) { mixin(S_TRACE);
				if (!tree.starts.length) return true;
				foreach (s; tree.starts[1..$]) { mixin(S_TRACE);
					if (s.name == name) { mixin(S_TRACE);
						return false;
					}
				}
				return true;
			}, true);
			tree.name = text;
			foreach (v; views()) { mixin(S_TRACE);
				v._etree.refreshTreeName();
				.anotherTreeItem(v._cards, itm).setText(text);
				auto p = tree.objectId in v._commentDlgs;
				if (p) p.title = .tryFormat(_prop.msgs.dlgTitCommentWith, tree.name);
			}
			_comm.refEventTree.call(tree);
			_comm.refreshToolBar();
			return;
		}
		if ("" == text) return;
		auto obj = cast(KeyCodeObj)itm.getData();
		assert (obj);
		auto p = itm.getParentItem();
		foreach (child; p.getItems()) { mixin(S_TRACE);
			if (itm is child) continue;
			auto kco = cast(KeyCodeObj)child.getData();
			if (!kco) continue;
			if (kco.array == text) { mixin(S_TRACE);
				_cards.setSelection([child]);
				return;
			}
		}
		tree = cast(EventTree) p.getData();
		auto kcIndex = p.indexOf(itm) - keyCodesIndex(p);
		auto old = tree.keyCodes[kcIndex];
		if (_prop.sys.convFireKeyCode(old) == text) return;
		if (_prop.sys.toFKeyCode(text).keyCode == "") return;
		store(tree);
		tree.setKeyCode(kcIndex, _prop.sys.toFKeyCode(text));
		foreach (v; views()) { mixin(S_TRACE);
			auto another = .anotherTreeItem(v._cards, itm);
			auto obj2 = cast(KeyCodeObj)another.getData();
			another.setImage(v.keyCodeImage(text));
			another.setText(text);
			obj2.array = text.dup;
		}
		_comm.refEventTree.call(tree);
		_comm.refKeyCodes.call();
		_comm.refreshToolBar();
	}
	void refreshFires(TreeItem eItm, Object sel = null, bool thisOnly = false) { mixin(S_TRACE);
		// パッケージイベントと使用時イベントは発火条件無し
		if (cast(Package)_area) return;
		if (cast(EffectCard)_area) return;

		scope (exit) _comm.refreshToolBar();
		auto t = cast(EventTree)eItm.getData();
		auto vs = views();
		auto initialize = !vs.contains!("a is b")(this);
		if (thisOnly || initialize) vs = [this];
		foreach (v; vs) { mixin(S_TRACE);
			eItm = .anotherTreeItem(v._cards, eItm);
			bool expand = eItm.getExpanded();
			scope (exit) {
				if (!sel) eItm.setExpanded(expand);
			}
			eItm.removeAll();
			if (cast(Area)_area) {
				if (t.fireEnter) { mixin(S_TRACE);
					if (cast(Area)eItm.getParentItem().getData()) { mixin(S_TRACE);
						createTreeItem(eItm, ENTER, _prop.msgs.startEnter, _prop.images.defStart);
					} else if (cast(PlayerCardEvents)eItm.getParentItem().getData()) { mixin(S_TRACE);
						createTreeItem(eItm, ENTER, _prop.msgs.startDead, _prop.images.defStart);
					} else { mixin(S_TRACE);
						assert (cast(AbstractSpCard)eItm.getParentItem().getData());
						createTreeItem(eItm, ENTER, _prop.msgs.startSelect, _prop.images.defStart);
					}
				}
				v.createKeyCodeItem(eItm, t);
			} else if (cast(Battle)_area) {
				if (cast(Battle)eItm.getParentItem().getData()) { mixin(S_TRACE);
					if (t.fireEnter) { mixin(S_TRACE);
						createTreeItem(eItm, ENTER, _prop.msgs.startVictory, _prop.images.defStart);
					}
					if (t.fireEscape) { mixin(S_TRACE);
						createTreeItem(eItm, ESCAPE, _prop.msgs.startEscape, _prop.images.defStart);
					}
					if (t.fireLose) { mixin(S_TRACE);
						createTreeItem(eItm, LOSE, _prop.msgs.startLose, _prop.images.defStart);
					}
					if (t.fireEveryRound) { mixin(S_TRACE);
						createTreeItem(eItm, EVERY_ROUND, _prop.msgs.startEveryRound, _prop.images.defStart);
					}
					if (t.fireRoundEnd) { mixin(S_TRACE);
						createTreeItem(eItm, ROUND_END, _prop.msgs.startRoundEnd, _prop.images.defStart);
					}
					if (t.fireRound0) { mixin(S_TRACE);
						createTreeItem(eItm, ROUND_0, _prop.msgs.startRound0, _prop.images.defStart);
					}
				} else if (cast(PlayerCardEvents)eItm.getParentItem().getData()) { mixin(S_TRACE);
					if (t.fireEnter) { mixin(S_TRACE);
						createTreeItem(eItm, ENTER, _prop.msgs.startDead, _prop.images.defStart);
					}
				} else { mixin(S_TRACE);
					assert (cast(AbstractSpCard)eItm.getParentItem().getData());
					if (t.fireEnter) { mixin(S_TRACE);
						createTreeItem(eItm, ENTER, _prop.msgs.startDead, _prop.images.defStart);
					}
				}
				v.createKeyCodeItem(eItm, t);
				if (cast(Battle)eItm.getParentItem().getData()) { mixin(S_TRACE);
					foreach (r; t.rounds) { mixin(S_TRACE);
						createTreeItem(eItm, new RoundObj(r), .tryFormat(_prop.msgs.startRound, r), _prop.images.round);
					}
				}
			}
			if (sel) { mixin(S_TRACE);
				foreach (itm; eItm.getItems()) { mixin(S_TRACE);
					auto data = itm.getData();
					if (cast(KeyCodeObj)data && cast(KeyCodeObj)sel) { mixin(S_TRACE);
						if ((cast(KeyCodeObj)data).array == (cast(KeyCodeObj)sel).array) { mixin(S_TRACE);
							if (v is this) v._cards.setSelection([itm]);
							break;
						}
					} else if (cast(RoundObj)data && cast(RoundObj)sel) { mixin(S_TRACE);
						if ((cast(RoundObj)data).intValue() == (cast(RoundObj)sel).intValue()) { mixin(S_TRACE);
							if (v is this) v._cards.setSelection([itm]);
							break;
						}
					} else if (data is sel) { mixin(S_TRACE);
						assert (data is ENTER || data is LOSE || data is ESCAPE || data is EVERY_ROUND || data is ROUND_END || data is ROUND_0);
						if (v is this) v._cards.setSelection([itm]);
						break;
					}
				}
				eItm.setExpanded(true);
			}
		}
	}

	Object addKeyCodes() { mixin(S_TRACE);
		auto kc = (cast(CCombo)_fireItm.getControl()).getText();
		final switch (_keyCodeTim.getSelectionIndex()) {
		case 0:
			// 入力値をそのまま使用
			break;
		case 1:
			kc = _prop.sys.convFireKeyCode(kc, FKCKind.Success);
			break;
		case 2:
			kc = _prop.sys.convFireKeyCode(kc, FKCKind.Failure);
			break;
		case 3:
			kc = _prop.sys.convFireKeyCode(kc, FKCKind.HasNot);
			break;
		}
		return _prop.sys.toFKeyCode(kc).keyCode != "" ? new KeyCodeObj(kc) : null;
	}
	Object addingFire(Object areaOrCard) { mixin(S_TRACE);
		if (_readOnly) return null;
		Object addAreaAndEtc() { mixin(S_TRACE);
			switch (_treeKind.getSelectionIndex()) {
			case 0:
				return ENTER;
			case 1:
				return addKeyCodes();
			default:
				return null;
			}
		}
		if (cast(AbstractSpCard)areaOrCard) { mixin(S_TRACE);
			return addAreaAndEtc();
		} else if (cast(Area)areaOrCard) { mixin(S_TRACE);
			return addAreaAndEtc();
		} else if (cast(Battle)areaOrCard) { mixin(S_TRACE);
			switch (_treeKind.getSelectionIndex()) {
			case 0:
				switch ((cast(CCombo)_fireItm.getControl()).getSelectionIndex()) {
				case 0:
					return ENTER;
				case 1:
					return ESCAPE;
				case 2:
					return LOSE;
				case 3:
					return EVERY_ROUND;
				case 4:
					return ROUND_END;
				case 5:
					return ROUND_0;
				default: assert (0);
				}
			case 1:
				return addKeyCodes();
			case 2:
				int round = (cast(Spinner)_fireItm.getControl()).getSelection();
				return new RoundObj(round);
			default: assert (0);
			}
		} else if (cast(PlayerCardEvents)areaOrCard) { mixin(S_TRACE);
			return addAreaAndEtc();
		} else { mixin(S_TRACE);
			return ENTER;
		}
	}
	void createEventFire() { mixin(S_TRACE);
		if (_readOnly) return;
		auto treeItm = selectionEventTree;
		if (!treeItm) return;
		auto tree = cast(EventTree)treeItm.getData();
		auto fire = addingFire(treeItm.getParentItem().getData());
		if (!fire) return;
		foreach (v; views()) v.editEnter();
		store(tree);
		addFire(treeItm, fire);
		refreshFires(treeItm, fire);
		_comm.refreshToolBar();
	}
	void addFire(TreeItem treeItm, Object fire) { mixin(S_TRACE);
		auto tree = cast(EventTree) treeItm.getData();
		if (fire is ENTER) { mixin(S_TRACE);
			tree.enter = true;
		} else if (fire is ESCAPE) { mixin(S_TRACE);
			tree.escape = true;
		} else if (fire is LOSE) { mixin(S_TRACE);
			tree.lose = true;
		} else if (fire is EVERY_ROUND) { mixin(S_TRACE);
			tree.everyRound = true;
		} else if (fire is ROUND_END) { mixin(S_TRACE);
			tree.roundEnd = true;
		} else if (fire is ROUND_0) { mixin(S_TRACE);
			tree.round0 = true;
		} else if (cast(KeyCodeObj)fire) { mixin(S_TRACE);
			tree.addKeyCode(_prop.sys.toFKeyCode((cast(KeyCodeObj)fire).array.idup));
			_comm.refKeyCodes.call();
		} else { mixin(S_TRACE);
			assert (cast(RoundObj)fire);
			tree.addRound((cast(RoundObj)fire).intValue());
			tree.sortRounds();
		}
		_comm.refEventTree.call(tree);
	}
	static __gshared Object ENTER;
	static __gshared Object ESCAPE;
	static __gshared Object LOSE;
	static __gshared Object EVERY_ROUND;
	static __gshared Object ROUND_END;
	static __gshared Object ROUND_0;
	shared static this () { mixin(S_TRACE);
		ENTER = new Object;
		ESCAPE = new Object;
		LOSE = new Object;
		EVERY_ROUND = new Object;
		ROUND_END = new Object;
		ROUND_0 = new Object;
	}
	int keyCodesIndex(TreeItem itm) { mixin(S_TRACE);
		assert (cast(EventTree)itm.getData());
		auto o = itm.getParentItem().getData();
		if (cast(AbstractSpCard)o || cast(PlayerCardEvents)o) { mixin(S_TRACE);
			return (cast(EventTree)itm.getData()).fireEnter ? 1 : 0;
		} else { mixin(S_TRACE);
			auto tree = cast(EventTree)itm.getData();
			if (cast(Battle)o) {
				int r = 0;
				if (tree.fireEnter) r++;
				if (tree.fireLose) r++;
				if (tree.fireEscape) r++;
				if (tree.fireEveryRound) r++;
				if (tree.fireRoundEnd) r++;
				if (tree.fireRound0) r++;
				return r;
			} else { mixin(S_TRACE);
				return (cast(EventTree)itm.getData()).fireEnter ? 1 : 0;
			}
		}
	}
	Image keyCodeImage(string keyCode) { mixin(S_TRACE);
		final switch (_prop.sys.fireKeyCodeKind(keyCode)) {
		case FKCKind.Use: return _prop.images.keyCode;
		case FKCKind.Success: return _prop.images.menu(MenuID.KeyCodeTimingSuccess);
		case FKCKind.Failure: return _prop.images.menu(MenuID.KeyCodeTimingFailure);
		case FKCKind.HasNot: return _prop.images.menu(MenuID.KeyCodeTimingHasNot);
		}
	}
	void createKeyCodeItem(T)(TreeItem parent, T a) { mixin(S_TRACE);
		foreach (keyCode; a.keyCodes) { mixin(S_TRACE);
			string kc = _prop.sys.convFireKeyCode(keyCode);
			createTreeItem(parent, new KeyCodeObj(kc), kc, keyCodeImage(kc));
		}
	}
	void replText() { mixin(S_TRACE);
		if (_readOnly) return;
		foreach (itm; _cards.getItems()) { mixin(S_TRACE);
			auto data = itm.getData();
			auto objId = "";
			if (auto a = cast(AbstractArea)data) { mixin(S_TRACE);
				itm.setText(a.name);
				objId = a.objectId;
			} else if (auto c = cast(EffectCard)data) { mixin(S_TRACE);
				itm.setText(c.name);
				objId = c.objectId;
			} else if (auto c = cast(MenuCard)data) {
				itm.setText(c.name);
				objId = c.objectId;
			} else if (auto c = cast(EnemyCard)data) {
				auto castCard = _summ.cwCast(c.id);
				itm.setText(castCard ? castCard.name : "");
				objId = c.objectId;
			} else { mixin(S_TRACE);
				assert (cast(PlayerCardEvents)data);
			}
			if (objId) { mixin(S_TRACE);
				auto p = objId in _commentDlgs;
				if (p) p.title = .tryFormat(_prop.msgs.dlgTitCommentWith, itm.getText());
			}
			foreach (itm2; itm.getItems()) { mixin(S_TRACE);
				auto et = cast(EventTree)itm2.getData();
				bool chg = false;
				if (itm2.getText() != et.name) { mixin(S_TRACE);
					itm2.setText(et.name);
					auto p2 = et.objectId in _commentDlgs;
					if (p2) p2.title = .tryFormat(_prop.msgs.dlgTitCommentWith, et.name);
					chg = true;
				}
				ptrdiff_t startKC = -1;
				auto keyCodes = 0;
				foreach (i, itm3; itm2.getItems()) { mixin(S_TRACE);
					auto kc = cast(KeyCodeObj)itm3.getData();
					if (!kc) continue;
					if (startKC < 0) startKC = i;
					keyCodes++;
					if (et.keyCodes.length <= i - startKC) { mixin(S_TRACE);
						itm3.dispose();
						chg = true;
					} else if (itm3.getText() != _prop.sys.convFireKeyCode(et.keyCodes[i - startKC])) { mixin(S_TRACE);
						auto kcWithTiming = _prop.sys.convFireKeyCode(et.keyCodes[i - startKC]);
						itm3.setText(kcWithTiming);
						kc.array = kcWithTiming.dup;
						itm3.setImage(keyCodeImage(kcWithTiming));
						chg = true;
					}
				}
				if (keyCodes < et.keyCodes.length) { mixin(S_TRACE);
					foreach (keyCode; et.keyCodes[keyCodes .. $]) { mixin(S_TRACE);
						auto kc = _prop.sys.convFireKeyCode(keyCode);
						createTreeItem(itm2, new KeyCodeObj(kc), kc, keyCodeImage(kc));
					}
				}
				if (chg) { mixin(S_TRACE);
					_comm.refEventTree.call(et);
					_comm.refKeyCodes.call();
				}
			}
		}
	}
	void addManyRounds() { mixin(S_TRACE);
		assert (cast(Battle)_area !is null);
		if (_readOnly) return;
		auto etItm = selectionEventTree;
		if (!etItm) return;
		auto parItm = selectionParent;
		if (!parItm || !(cast(Battle) parItm.getData())) return;
		foreach (v; views()) v.editEnter();
		auto dlg = new ManyRoundsDialog(_prop, _cards.getShell());
		if (dlg.open()) { mixin(S_TRACE);
			auto et = cast(EventTree) etItm.getData();
			store(et);
			assert (et);
			et.addRounds(dlg.rounds);
			refreshFires(etItm);
			etItm.setExpanded(true);
			_comm.refEventTree.call(et);
			_comm.refreshToolBar();
		}
	}
	void keyCodeTimImpl(FKCKind kind) { mixin(S_TRACE);
		assert (cast(Area)_area || cast(Battle)_area);
		if (_readOnly) return;
		auto itm = selection;
		if (!itm) return;
		auto kc = cast(KeyCodeObj)itm.getData();
		if (!kc) return;
		foreach (v; views()) v.editEnter();
		auto old = _prop.sys.toFKeyCode(kc.array.idup);
		string keyCode = _prop.sys.convFireKeyCode(old.keyCode, kind);
		auto etItm = selectionEventTree;
		assert (etItm);
		auto et = cast(EventTree)etItm.getData();
		assert (et);
		store(et);
		auto i = .cCountUntil(et.keyCodes, old);
		assert (-1 != i);
		et.setKeyCode(i, _prop.sys.toFKeyCode(keyCode));
		foreach (v; views()) { mixin(S_TRACE);
			auto itm2 = .anotherTreeItem(v._cards, itm);
			itm2.setText(keyCode);
			itm2.setImage(keyCodeImage(keyCode));
			auto kc2 = cast(KeyCodeObj)itm2.getData();
			kc2.array = keyCode.dup;
		}
		_comm.refKeyCodes.call();
		_comm.refreshToolBar();
	}
	void keyCodeTimUse() { mixin(S_TRACE);
		keyCodeTimImpl(FKCKind.Use);
	}
	void keyCodeTimSuccess() { mixin(S_TRACE);
		keyCodeTimImpl(FKCKind.Success);
	}
	void keyCodeTimFailure() { mixin(S_TRACE);
		keyCodeTimImpl(FKCKind.Failure);
	}
	void keyCodeTimHasNot() { mixin(S_TRACE);
		keyCodeTimImpl(FKCKind.HasNot);
	}
	bool canConvKeyCode(FKCKind Kind)() { mixin(S_TRACE);
		if (_readOnly) return false;
		auto itm = selectionKeyCode;
		if (!itm) return false;
		auto keyCode = (cast(KeyCodeObj)itm.getData()).array.idup;
		if (Kind is _prop.sys.fireKeyCodeKind(keyCode)) { mixin(S_TRACE);
			return false;
		}
		auto parItm = itm.getParentItem();
		auto conv = _prop.sys.convFireKeyCode(keyCode, Kind);
		foreach (child; parItm.getItems()) { mixin(S_TRACE);
			if (child is itm) continue;
			auto kco = cast(KeyCodeObj)child.getData();
			if (!kco) continue;
			if (conv == kco.array) { mixin(S_TRACE);
				return false;
			}
		}
		return true;
	}
	void copyKeyCodeTim(FKCKind Kind)() { mixin(S_TRACE);
		auto itm = selectionKeyCode;
		if (!itm) return;
		auto keyCode = (cast(KeyCodeObj)itm.getData()).array.idup;
		auto conv = _prop.sys.convFireKeyCode(keyCode, Kind);
		auto node = EventTree.keyCodeToNode(_prop.sys.toFKeyCode(conv), _prop.sys);
		XMLtoCB(_prop, _comm.clipboard, node.text);
		_comm.refreshToolBar();
	}
	void setKeyCodeCond(MatchingType Type)() { mixin(S_TRACE);
		if (_readOnly) return;
		auto eItm = selectionEventTree;
		if (!eItm) return;
		auto et = cast(EventTree)eItm.getData();
		assert (et !is null);
		store(et);
		et.keyCodeMatchingType = Type;
		foreach (v; views()) { mixin(S_TRACE);
			auto itm = .anotherTreeItem(v._cards, eItm);
			itm.setImage(v.etImage(et));
		}
	}
	bool canSetKeyCodeCond(MatchingType Type)() { mixin(S_TRACE);
		if (_readOnly) return false;
		auto eItm = selectionEventTree;
		if (!eItm) return false;
		auto et = cast(EventTree) eItm.getData();
		assert (et !is null);
		return et.keyCodeMatchingType !is Type;
	}

	void refShowToolBar() { mixin(S_TRACE);
		auto gl = windowGridLayout(1, true);
		gl.marginWidth = 0;
		gl.marginHeight = 0;
		auto gd = new GridData(GridData.FILL_HORIZONTAL);
		if (!_prop.var.etc.showEventToolBar) { mixin(S_TRACE);
			gl.verticalSpacing = 0;
			gd.heightHint = 0;
		}
		setLayout(gl);
		_toolbar.setVisible(_prop.var.etc.showEventToolBar);
		_toolbar.setLayoutData(gd);
		layout();
	}
public:
	this (Commons comm, Props prop, Summary summ, EventTreeOwner area, Composite parent, UndoManager undo, bool readOnly) { mixin(S_TRACE);
		super (parent, SWT.NONE);
		_id = .objectIDValue(this);
		_comm = comm;
		_prop = prop;
		_summ = summ;
		_area = area;
		_undo = undo;
		_readOnly = readOnly ? SWT.READ_ONLY : SWT.NONE;
		if (_readOnly || !_summ || _summ.scenarioPath == "") { mixin(S_TRACE);
			_summSkin = findSkin(_comm, _prop, _summ);
		}

		_toolbar = new ToolBar(this, SWT.FLAT);
		_comm.put(_toolbar);

		_sash = new SplitPane(this, SWT.HORIZONTAL);
		_comm.refEventTreeSlope.add(&refEventTreeSlope);
		if (!_readOnly) { mixin(S_TRACE);
			_comm.replText.add(&replText);
			_comm.replID.add(&replText);
			if (cast(Area)_area || cast(Battle)_area) { mixin(S_TRACE);
				_comm.addMenuCard.add(&addCard);
				_comm.refMenuCard.add(&refCard);
				_comm.delMenuCard.add(&delCard);
				_comm.upMenuCard.add(&upCard);
				_comm.downMenuCard.add(&downCard);
			}
			if (cast(Battle)_area) { mixin(S_TRACE);
				_comm.refCast.add(&refCast);
				_comm.delCast.add(&refCast);
			}
			if (cast(Area)_area) {
				_comm.refArea.add(&refreshTitleArea);
			} else if (cast(Battle)_area) {
				_comm.refBattle.add(&refreshTitleBattle);
			} else if (cast(Package)_area) {
				_comm.refPackage.add(&refreshTitlePackage);
			} else if (cast(SkillCard)_area) {
				_comm.refSkill.add(&refreshTitleSkill);
			} else if (cast(ItemCard)_area) {
				_comm.refItem.add(&refreshTitleItem);
			} else if (cast(BeastCard)_area) {
				_comm.refBeast.add(&refreshTitleBeast);
			} else assert (0);
		}
		_sash.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
				if (_preview) { mixin(S_TRACE);
					closePreview();
					_preview.dispose();
				}

				_comm.refEventTreeSlope.remove(&refEventTreeSlope);
				if (!_readOnly) { mixin(S_TRACE);
					_comm.replText.remove(&replText);
					_comm.replID.remove(&replText);
					if (cast(Area)_area || cast(Battle)_area) { mixin(S_TRACE);
						_comm.addMenuCard.remove(&addCard);
						_comm.refMenuCard.remove(&refCard);
						_comm.delMenuCard.remove(&delCard);
						_comm.upMenuCard.remove(&upCard);
						_comm.downMenuCard.remove(&downCard);
					}
					if (cast(Battle)_area) { mixin(S_TRACE);
						_comm.refCast.remove(&refCast);
						_comm.delCast.remove(&refCast);
					}
					if (cast(Area)_area) {
						_comm.refArea.remove(&refreshTitleArea);
					} else if (cast(Battle)_area) {
						_comm.refBattle.remove(&refreshTitleBattle);
					} else if (cast(Package)_area) {
						_comm.refPackage.remove(&refreshTitlePackage);
					} else if (cast(SkillCard)_area) {
						_comm.refSkill.remove(&refreshTitleSkill);
					} else if (cast(ItemCard)_area) {
						_comm.refItem.remove(&refreshTitleItem);
					} else if (cast(BeastCard)_area) {
						_comm.refBeast.remove(&refreshTitleBeast);
					} else assert (0);
				}
				foreach (dlg; _editDlgs.values) dlg.forceCancel();
				foreach (dlg; _commentDlgs.values) dlg.forceCancel();
			}
		});
		_sash.setLayoutData(new GridData(GridData.FILL_BOTH));
		Composite leftComp = _sash;
		SplitPane leftSash = null;
		if (cast(LocalVariableOwner)_area) { mixin(S_TRACE);
			leftSash = new SplitPane(_sash, SWT.VERTICAL);
			leftComp = leftSash;
		}
		{ mixin(S_TRACE);
			_cards = new Tree(leftComp, SWT.SINGLE | SWT.BORDER);
			initTree(_comm, _cards, false);
			_cards.addSelectionListener(new SListener);
			.listener(_cards, SWT.FocusIn, { _lastFocus = _cards; });
			.treeWarning(_prop, _cards, true, &getWarning);
			.setupComment(_comm, _cards, true);
			_lastFocus = _cards;
			_comm.refDataVersion.add(&_cards.redraw);
			.listener(_cards, SWT.Dispose, { mixin(S_TRACE);
				_comm.refDataVersion.remove(&_cards.redraw);
			});
			if (cast(Area)_area || cast(Battle)_area) { mixin(S_TRACE);
				auto ib = _prop.images.menu(MenuID.Comment).getBounds();
				.listener(_cards, SWT.Paint, (e) { mixin(S_TRACE);
					if (_prop.var.etc.showItemNumberOfSceneAndEventView) { mixin(S_TRACE);
						auto ti = .topItem(_cards.getTopItem());
						auto count = _cards.getItemCount();
						auto h = _cards.getSize().y;
						auto ca = _cards.getClientArea();
						e.gc.setForeground(_cards.getDisplay().getSystemColor(SWT.COLOR_GRAY));
						for (auto i = _cards.indexOf(ti); i < count; i++) { mixin(S_TRACE);
							auto itm = _cards.getItem(i);
							if (itm.isDisposed()) continue;
							if (!cast(AbstractSpCard)itm.getData()) continue;
							auto b = itm.getBounds();
							if (b.y + b.height < ca.y) { mixin(S_TRACE);
								continue;
							}
							if (h <= b.y) { mixin(S_TRACE);
								break;
							}
							auto s = .text(i - 1);
							auto te = e.gc.wTextExtent(s);
							auto x = ca.width - 5.ppis - te.x;
							if (.commentText(cast(CWXPath)itm.getData(), true)) x -= ib.width + 5.ppis;
							auto y = b.y + (b.height - te.y) / 2;
							e.gc.wDrawText(s, x, y, true);
						}
					}
				});
				_comm.refMenuCardAndBgImageList.add(&_cards.redraw);
				_comm.refMenuCardIndices.add(&refMenuCardIndices);
				.listener(_cards, SWT.Dispose, { mixin(S_TRACE);
					_comm.refMenuCardAndBgImageList.remove(&_cards.redraw);
					_comm.refMenuCardIndices.remove(&refMenuCardIndices);
				});
			}

			auto shell = _cards.getShell();
			auto menu = new Menu(shell, SWT.POP_UP);
			void createCopyKeyCodeMenu() { mixin(S_TRACE);
				void delegate() dlg = null;
				auto cascade = createMenuItem(_comm, menu, MenuID.CopyTimingConvertedKeyCode, dlg, () => selectionKeyCode !is null, SWT.CASCADE);
				auto sub = new Menu(parent.getShell(), SWT.DROP_DOWN);
				cascade.setMenu(sub);
				createMenuItem(_comm, sub, MenuID.CopyTimingConvertedKeyCodeUse, &copyKeyCodeTim!(FKCKind.Use), () => selectionKeyCode !is null);
				createMenuItem(_comm, sub, MenuID.CopyTimingConvertedKeyCodeSuccess, &copyKeyCodeTim!(FKCKind.Success), () => selectionKeyCode !is null);
				createMenuItem(_comm, sub, MenuID.CopyTimingConvertedKeyCodeFailure, &copyKeyCodeTim!(FKCKind.Failure), () => selectionKeyCode !is null);
				createMenuItem(_comm, sub, MenuID.CopyTimingConvertedKeyCodeHasNot, &copyKeyCodeTim!(FKCKind.HasNot), () => selectionKeyCode !is null);
			}
			if (!_readOnly) { mixin(S_TRACE);
				auto sys = _area.canHasFireEnter || _area.canHasFireLose || _area.canHasFireEscape || _area.canHasFireEveryRound || _area.canHasFireRoundEnd || _area.canHasFireRound0;
				auto kc = _area.canHasFireKeyCode;
				auto round = _area.canHasFireRound;
				if (sys || kc || round) { mixin(S_TRACE);
					createMenuItem(_comm, menu, MenuID.EditProp, &editEvent, () => selectionEventTree !is null);
					new MenuItem(menu, SWT.SEPARATOR);
				}
				createMenuItem(_comm, menu, MenuID.NewEventWithDialog, &createEvent, &canCreateEvent);
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.Comment, &writeCommentL, &canWriteCommentL);
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.Undo, &this.undo, () => _undo.canUndo && !_readOnly);
				createMenuItem(_comm, menu, MenuID.Redo, &this.redo, () => _undo.canRedo && !_readOnly);
				new MenuItem(menu, SWT.SEPARATOR);
				appendMenuTCPD(_comm, menu, this, true, true, true, true, true);

				if (cast(Area)_area || cast(Battle)_area) { mixin(S_TRACE);
					new MenuItem(menu, SWT.SEPARATOR);
					void delegate() dlg = null;
					auto cascade = createMenuItem(_comm, menu, MenuID.KeyCodeTiming, dlg, () => canConvKeyCode!(FKCKind.Use) || canConvKeyCode!(FKCKind.Success) || canConvKeyCode!(FKCKind.Failure) || canConvKeyCode!(FKCKind.HasNot), SWT.CASCADE);
					auto sub = new Menu(parent.getShell(), SWT.DROP_DOWN);
					cascade.setMenu(sub);
					createMenuItem(_comm, sub, MenuID.KeyCodeTimingUse, &keyCodeTimUse, &canConvKeyCode!(FKCKind.Use));
					createMenuItem(_comm, sub, MenuID.KeyCodeTimingSuccess, &keyCodeTimSuccess, &canConvKeyCode!(FKCKind.Success));
					createMenuItem(_comm, sub, MenuID.KeyCodeTimingFailure, &keyCodeTimFailure, &canConvKeyCode!(FKCKind.Failure));
					createMenuItem(_comm, sub, MenuID.KeyCodeTimingHasNot, &keyCodeTimHasNot, &canConvKeyCode!(FKCKind.HasNot));

					createCopyKeyCodeMenu();

					new MenuItem(menu, SWT.SEPARATOR);
					auto cascade2 = createMenuItem(_comm, menu, MenuID.KeyCodeCond, dlg, () => !_readOnly && selectionEventTree !is null, SWT.CASCADE);
					auto sub2 = new Menu(parent.getShell(), SWT.DROP_DOWN);
					cascade2.setMenu(sub2);
					createMenuItem(_comm, sub2, MenuID.KeyCodeCondOr, &setKeyCodeCond!(MatchingType.Or), &canSetKeyCodeCond!(MatchingType.Or));
					createMenuItem(_comm, sub2, MenuID.KeyCodeCondAnd, &setKeyCodeCond!(MatchingType.And), &canSetKeyCodeCond!(MatchingType.And));
				}
				new MenuItem(menu, SWT.SEPARATOR);
			} else { mixin(S_TRACE);
				appendMenuTCPD(_comm, menu, this, false, true, false, false, false);
				new MenuItem(menu, SWT.SEPARATOR);
				createCopyKeyCodeMenu();
				new MenuItem(menu, SWT.SEPARATOR);
			}
			createMenuItem(_comm, menu, MenuID.ToScript, &toScript, &canToScript);
			createMenuItem(_comm, menu, MenuID.ToScriptAll, &toScriptAll, &canToScriptAll);
			if (!_readOnly) { mixin(S_TRACE);
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.EventToPackage, &eventToPackage, &canEventToPackage);
			}
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.SelectConnectedResource, &selectConnectedResource, &canSelectConnectedResource);
			if (cast(Battle)_area) { mixin(S_TRACE);
				if (!_readOnly) { mixin(S_TRACE);
					new MenuItem(menu, SWT.SEPARATOR);
					createMenuItem(_comm, menu, MenuID.AddRangeOfRound, &addManyRounds, { mixin(S_TRACE);
						if (_readOnly) return false;
						auto etItm = selectionEventTree;
						if (!etItm) return false;
						return (cast(EventTree)etItm.getData()).owner is _area;
					});
				}
			}
			_cards.setMenu(menu);

			if (cast(Area)_area || cast(Battle)_area) {
				_preview = new Preview(_prop, _cards);
				auto closePreview = new ClosePreview;
				_cards.getVerticalBar().addSelectionListener(closePreview);
				_cards.getHorizontalBar().addSelectionListener(closePreview);
				auto prevTrig = new PreviewTrigger;
				_cards.addMouseTrackListener(prevTrig);
				_cards.addMouseMoveListener(prevTrig);
			}
		}
		if (auto ec = cast(LocalVariableOwner)_area) { mixin(S_TRACE);
			assert (leftSash !is null);
			auto comp = new Composite(leftSash, SWT.NONE);
			auto vgd = windowGridLayout(1, true);
			vgd.marginWidth = 0.ppis;
			vgd.marginHeight = 0.ppis;
			comp.setLayout(vgd);
			auto l = new CLabel(comp, SWT.NONE);
			l.setText(_prop.msgs.localVariables);
			l.setImage(_prop.images.flagDir);
			_flags = new FlagTable(comm, prop, _undo, true, readOnly);
			_flags.useCounter = ec.useCounter;
			_flags.createControl(comp, comp, null);
			_flags.widget.setLayoutData(new GridData(GridData.FILL_BOTH));
			_flags.setDir(ec.flagDirRoot, true);

			void createOrDelete() { mixin(S_TRACE);
				if (auto c = cast(SkillCard)_area) {
					_comm.refSkill.call(c);
				} else if (auto c = cast(ItemCard)_area) {
					_comm.refItem.call(c);
				} else if (auto c = cast(BeastCard)_area) {
					_comm.refBeast.call(c);
				}
			}
			_flags.createEvent ~= &createOrDelete;
			_flags.deleteEvent ~= &createOrDelete;

			.setupWeights(leftSash, _prop.var.etc.localVariablesSashL, _prop.var.etc.localVariablesSashR);
		}
		{ mixin(S_TRACE);
			auto viewArea = new Composite(_sash, SWT.NONE);
			viewArea.setLayout(zeroGridLayout(1, true));
			_etree = new EventTreeView(comm, prop, summ, _area, viewArea, _undo, &forceSel, &refreshTopStart, _toolbar, _readOnly != SWT.NONE);
			_etree.widget.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto hint = new Label(viewArea, SWT.NONE);
			hint.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			hint.setText(_prop.msgs.eventTreeViewHint);
			if (!_readOnly) { mixin(S_TRACE);
				_edit = new TreeEdit(_comm, _cards, &editEnd, &createEditor);
			}
			auto fi = new class Listener {
				override void handleEvent(Event e) { mixin(S_TRACE);
					if (!cast(Control)e.widget) return;
					if (isDescendant(_etree.widget, cast(Control)e.widget)) { mixin(S_TRACE);
						_lastFocus = _etree;
					}
				}
			};
			getDisplay().addFilter(SWT.FocusIn, fi);
			.listener(this, SWT.Dispose, { getDisplay().removeFilter(SWT.FocusIn, fi); });
			if (_prop.var.etc.useCoolBar) { mixin(S_TRACE);
				// 遅延実行
				auto initTools = new class PaintListener {
					override void paintControl(PaintEvent e) { mixin(S_TRACE);
						_cards.removePaintListener(this);
						_toolbar.setRedraw(false);
						scope (exit) _toolbar.setRedraw(true);
						if (setupToolBar()) { mixin(S_TRACE);
							_comm.refreshToolBar();
						}
					}
				};
				_cards.addPaintListener(initTools);
				setupToolBar0(); // レイアウトのため最初のアイテムだけ生成しておく
			} else { mixin(S_TRACE);
				setupToolBar0();
				setupToolBar();
			}
		}
		if (cast(Area)_area) { mixin(S_TRACE);
			.setupWeights(_sash, _prop.var.areaEventWin.eventSashL, _prop.var.areaEventWin.eventSashR);
		} else if (cast(Battle)_area) { mixin(S_TRACE);
			.setupWeights(_sash, _prop.var.battleEventWin.eventSashL, _prop.var.battleEventWin.eventSashR);
		} else if (cast(Package)_area) { mixin(S_TRACE);
			.setupWeights(_sash, _prop.var.packageWin.eventSashL, _prop.var.packageWin.eventSashR);
		} else if (cast(EffectCard)_area) { mixin(S_TRACE);
			.setupWeights(_sash, _prop.var.cardEventWin.eventSashL, _prop.var.cardEventWin.eventSashR);
		} else { mixin(S_TRACE);
			 assert (0);
		}
		refShowToolBar();

		if (!_readOnly) { mixin(S_TRACE);
			auto dt = new DropTarget(_cards, DND.DROP_DEFAULT | DND.DROP_MOVE);
			dt.setTransfer([XMLBytesTransfer.getInstance()]);
			dt.addDropListener(new EventViewDropTarget);
		}
		auto ds = new DragSource(_cards, DND.DROP_MOVE);
		ds.setTransfer([XMLBytesTransfer.getInstance()]);
		ds.addDragListener(new EventViewDragSource);

		auto track = new class Listener {
			override void handleEvent(Event e) { mixin(S_TRACE);
				if (_prop.var.etc.contentsAutoHide || _prop.var.etc.contentsFloat) {
					auto c = cast(Control)e.widget;
					if (c && .isDescendant(this.outer, c)) {
						_etree.openToolWindow(true);
					}
				}
			}
		};
		auto d = getDisplay();
		d.addFilter(SWT.MouseEnter, track);
		.listener(this, SWT.Dispose, {
			d.removeFilter(SWT.MouseEnter, track);
		});
	}
	@property
	EventTreeView eventTreeView() { mixin(S_TRACE);
		return _etree;
	}

	/// エリアの名称表示を更新する。
	void refreshTitle() { mixin(S_TRACE);
		initial();
		if (auto area = cast(AbstractArea)_area) {
			_cards.getItems()[0].setText(area.name);
			auto p = area.objectId in _commentDlgs;
			if (p) p.title = .tryFormat(_prop.msgs.dlgTitCommentWith, area.name);
		} else if (auto card = cast(EffectCard)_area) {
			_cards.getItems()[0].setText(card.name);
			auto p = card.objectId in _commentDlgs;
			if (p) p.title = .tryFormat(_prop.msgs.dlgTitCommentWith, card.name);
		} else assert (0);
	}
	private void refreshTitleArea(Area area) { refreshTitle!Area(area); }
	private void refreshTitleBattle(Battle area) { refreshTitle!Battle(area); }
	private void refreshTitlePackage(Package area) { refreshTitle!Package(area); }
	private void refreshTitleSkill(SkillCard area) { refreshTitle!SkillCard(area); }
	private void refreshTitleItem(ItemCard area) { refreshTitle!ItemCard(area); }
	private void refreshTitleBeast(BeastCard area) { refreshTitle!BeastCard(area); }
	private void refreshTitle(A)(A area) { mixin(S_TRACE);
		initial();
		if (area is _area) { mixin(S_TRACE);
			_cards.getItems()[0].setText(area.name);
			auto p = area.objectId in _commentDlgs;
			if (p) p.title = .tryFormat(_prop.msgs.dlgTitCommentWith, area.name);
		}
	}
	private string cardName(AbstractSpCard c) { mixin(S_TRACE);
		if (auto card = cast(MenuCard)c) { mixin(S_TRACE);
			return card.name;
		} else if (auto card = cast(EnemyCard)c) { mixin(S_TRACE);
			if (card.isOverrideName) return card.overrideName;
			auto castCard = _summ.cwCast(card.id);
			return castCard ? castCard.name : "";
		} else assert (0);
	}
	private void addCard(string cwxPath) { mixin(S_TRACE);
		if (!cpeq(_area.cwxPath(true), cpparent(cwxPath))) return;
		size_t i = cpindex(cpbottom(cwxPath));
		if (auto area = cast(Area)_area) {
			appendCard(cast(int)i, area.cards[i]);
		} else if (auto area = cast(Battle)_area) {
			appendCard(cast(int)i, area.cards[i]);
		} else assert (0);
	}
	private void refCard(string cwxPath) { mixin(S_TRACE);
		if (!cpeq(_area.cwxPath(true), cpparent(cwxPath))) return;
		size_t i = cpindex(cpbottom(cwxPath));
		renameCard(cast(int)i);
	}
	private void delCard(string cwxPath) { mixin(S_TRACE);
		if (!cpeq(_area.cwxPath(true), cpparent(cwxPath))) return;
		size_t i = cpindex(cpbottom(cwxPath));
		removeCard(cast(int)i);
	}
	private void upCard(string cwxPath, int[] indices, int count) { mixin(S_TRACE);
		if (!cpeq(_area.cwxPath(true), cwxPath)) return;
		upCard(indices, count);
	}
	private void downCard(string cwxPath, int[] indices, int count) { mixin(S_TRACE);
		if (!cpeq(_area.cwxPath(true), cwxPath)) return;
		downCard(indices, count);
	}
	private void appendCard(int index, AbstractSpCard c) { mixin(S_TRACE);
		initial();
		auto itm = createTreeItem(_cards, c, cardName(c), cardIcon(c), index + cardsIndex);
		refreshTrees(itm);
	}
	private void removeCard(int index) { mixin(S_TRACE);
		initial();
		auto itm = _cards.getItem(index + cardsIndex);
		if (_selItm && !_selItm.isDisposed() && _selItm.getParentItem() is itm) { mixin(S_TRACE);
			_etree.refresh(null);
			_selItm.setImage(etImage(cast(EventTree)_selItm.getData()));
			_selItm = null;
		}
		auto eto = cast(EventTreeOwner)itm.getData();
		foreach (dlg; _editDlgs.values) { mixin(S_TRACE);
			if (dlg.eventTreeOwner is eto) dlg.forceCancel();
		}
		foreach (key; _commentDlgs.keys) { mixin(S_TRACE);
			auto oid = cast(ObjectId)eto;
			auto dlg = _commentDlgs[key];
			assert (oid !is null);
			if (oid.objectId == key) { mixin(S_TRACE);
				dlg.forceCancel();
				continue;
			}
			foreach (tree; eto.trees) { mixin(S_TRACE);
				if (tree.objectId == key) { mixin(S_TRACE);
					dlg.forceCancel();
					break;
				}
			}
		}
		itm.dispose();
	}
	private void renameCard(int index) { mixin(S_TRACE);
		initial();
		auto itm = _cards.getItems()[index + cardsIndex];
		auto card = cast(AbstractSpCard)itm.getData();
		itm.setText(cardName(card));
		itm.setImage(cardIcon(card));
		auto p = card.objectId in _commentDlgs;
		if (p) p.title = .tryFormat(_prop.msgs.dlgTitCommentWith, cardName(card));
	}
	private void refCast(CastCard card) { mixin(S_TRACE);
		assert (cast(Battle)_area !is null);
		foreach (itm; _cards.getItems()[2 .. $]) { mixin(S_TRACE);
			auto c = cast(EnemyCard)itm.getData();
			assert (c !is null);
			if (c.id == card.id) { mixin(S_TRACE);
				itm.setText(cardName(c));
				auto p = c.objectId in _commentDlgs;
				if (p) p.title = .tryFormat(_prop.msgs.dlgTitCommentWith, cardName(c));
			}
		}
	}
	private void udCard(int[] indices, int function(TreeItem) ud, int udVal, int count) { mixin(S_TRACE);
		foreach (j; 0 .. count) { mixin(S_TRACE);
			foreach (i; indices) { mixin(S_TRACE);
				i += udVal * j;
				if (_selItm && _selItm.getParentItem() is _cards.getItems()[i + cardsIndex]) { mixin(S_TRACE);
					int s = _selItm.getParentItem().indexOf(_selItm);
					int newI = ud(_cards.getItems()[i + cardsIndex]) + udVal;
					_selItm = null;
					selectImpl(_cards.getItems()[newI].getItems()[s]);
				} else { mixin(S_TRACE);
					ud(_cards.getItems()[i + cardsIndex]);
				}
			}
		}
	}
	private void upCard(int[] indices, int count) { mixin(S_TRACE);
		initial();
		udCard(indices, &treeItemUp, -1, count);
	}
	private void downCard(int[] indices, int count) { mixin(S_TRACE);
		initial();
		std.algorithm.reverse(indices);
		udCard(indices, &treeItemDown, 1, count);
	}
	private void refMenuCardIndices(const(AbstractArea) area, const(Tuple!(size_t, size_t))[] indices) { mixin(S_TRACE);
		if (area !is _area) return;
		_cards.setRedraw(false);
		scope (exit) _cards.setRedraw(true);
		auto parItm = selectionParent;
		auto par = parItm ? cast(EventTreeOwner)parItm.getData() : null;
		auto etItm = selectionEventTree;
		auto igItm = etItm && selection && selection.getParentItem() is etItm ? selection : null;
		auto eventTreeIndex = parItm && etItm ? parItm.indexOf(etItm) : -1;
		auto ignitionIndex = igItm ? etItm.indexOf(igItm) : -1;

		void impl(C)(C[] cards) { mixin(S_TRACE);
			bool[size_t] expanded;
			bool[string] etExpanded;
			foreach (t; indices) { mixin(S_TRACE);
				auto cItm = _cards.getItem(cardsIndex + cast(int)t[0]);
				expanded[t[1]] = cItm.getExpanded();
				foreach (i, et; (cast(C)cItm.getData()).trees) { mixin(S_TRACE);
					etExpanded[et.objectId] = cItm.getItem(cast(int)i).getExpanded();
				}
			}
			auto selItm = selection;
			selectImpl(_cards.getItem(0));
			foreach (t; indices) { mixin(S_TRACE);
				auto c = cards[t[0]];
				auto cItm = _cards.getItem(cardsIndex + cast(int)t[0]);
				cItm.setText(cardName(c));
				cItm.setImage(cardIcon(c));
				cItm.setData(c);
				cItm.removeAll();
				foreach (et; c.trees) { mixin(S_TRACE);
					auto eItm = .createTreeItem(cItm, et, et.name, etImage(et));
					refreshFires(eItm);
					eItm.setExpanded(etExpanded.get(et.objectId, false));
				}
				cItm.setExpanded(expanded.get(t[0], true));
			}
			if (par) { mixin(S_TRACE);
				foreach (parItm2; _cards.getItems()) { mixin(S_TRACE);
					if (cast(EventTreeOwner)parItm2.getData() is par) { mixin(S_TRACE);
						auto sel = parItm2;
						if (eventTreeIndex != -1) sel = sel.getItem(eventTreeIndex);
						if (ignitionIndex != -1) sel = sel.getItem(ignitionIndex);
						selectImpl(sel);
						_cards.showSelection();
						return;
					}
				}
			}
			if (selItm && !selItm.isDisposed()) { mixin(S_TRACE);
				selectImpl(selItm);
				_cards.showSelection();
				return;
			}
		}
		if (auto a = cast(Area)_area) { mixin(S_TRACE);
			impl(a.cards);
		} else if (auto a = cast(Battle)_area) { mixin(S_TRACE);
			impl(a.cards);
		} else assert (0);
	}

	private bool _initialed = false;
	bool initial() { mixin(S_TRACE);
		if (!_initialed) { mixin(S_TRACE);
			refresh();
			return true;
		}
		return false;
	}
	void refresh() { mixin(S_TRACE);
		_initialed = true;
		foreach (v; views()) v.editCancel();
		_cards.removeAll();
		{ mixin(S_TRACE);
			Image imgArea;
			string name;
			if (auto a = cast(Area)_area) {
				imgArea = _prop.images.area;
				name = a.name;
			} else if (auto a = cast(Battle)_area) {
				imgArea = _prop.images.battle;
				name = a.name;
			} else if (auto a = cast(Package)_area) {
				imgArea = _prop.images.packages;
				name = a.name;
			} else if (auto a = cast(SkillCard)_area) {
				imgArea = _prop.images.skill;
				name = a.name;
			} else if (auto a = cast(ItemCard)_area) {
				imgArea = _prop.images.item;
				name = a.name;
			} else if (auto a = cast(BeastCard)_area) {
				imgArea = _prop.images.beast;
				name = a.name;
			} else { mixin(S_TRACE);
				assert (0);
			}
			auto aItm = createTreeItem(_cards, cast(Object)_area, name, imgArea);
			foreach (i, t; _area.trees) { mixin(S_TRACE);
				auto eItm = createTreeItem(aItm, t, t.name, etImage(t));
				refreshFires(eItm);
				if (i == 0) { mixin(S_TRACE);
					selectImpl(eItm);
				}
			}
			if (_area.trees.length == 0) { mixin(S_TRACE);
				selectImpl(aItm);
			}
			aItm.setExpanded(true);
		}
		PlayerCardEvents playerEvents = null;
		if (auto a = cast(Area)_area) { mixin(S_TRACE);
			playerEvents = a.playerEvents;
		} else if (auto a = cast(Battle)_area) { mixin(S_TRACE);
			playerEvents = a.playerEvents;
		}
		if (playerEvents) { mixin(S_TRACE);
			auto aItm = createTreeItem(_cards, playerEvents, _prop.msgs.playerCard, _prop.images.playerCard);
			foreach (i, t; playerEvents.trees) { mixin(S_TRACE);
				auto eItm = createTreeItem(aItm, t, t.name, etImage(t));
				refreshFires(eItm);
			}
			aItm.setExpanded(true);
		}

		void spCardItm(AbstractSpCard c) { mixin(S_TRACE);
			auto cItm = createTreeItem(_cards, c, cardName(c), cardIcon(c));
			foreach (t; c.trees) { mixin(S_TRACE);
				auto eItm = createTreeItem(cItm, t, t.name, etImage(t));
				refreshFires(eItm);
			}
			cItm.setExpanded(true);
		}
		if (auto a = cast(Area)_area) { mixin(S_TRACE);
			foreach (c; a.cards) { mixin(S_TRACE);
				spCardItm(c);
			}
		} else if (auto a = cast(Battle)_area) { mixin(S_TRACE);
			foreach (c; a.cards) { mixin(S_TRACE);
				spCardItm(c);
			}
		}
		_comm.refreshToolBar();
	}
	private Image cardIcon(AbstractSpCard card) { mixin(S_TRACE);
		return .cardIcon(_prop, card);
	}

	void editEnter() { mixin(S_TRACE);
		if (_edit) _edit.enter();
		_etree.editEnter();
	}
	void editCancel() { mixin(S_TRACE);
		if (_edit) _edit.cancel();
		_etree.editCancel();
	}

	private bool _resetToolBar = false;
	private bool _showEventTreeDetail = false;
	private bool _showLineNumber = false;
	private string _treeKindSel = "";
	private string _fireSel = "";
	private int _fireSelInt = 0;
	private string _keyCodeTimSel = "";
	void movingShell() { mixin(S_TRACE);
		_toolbar.setRedraw(false);
		if (_setupToolBar) { mixin(S_TRACE);
			_resetToolBar = true;
			_setupToolBar = false;
			_showEventTreeDetail = _showEventTreeDetailItm.getSelection();
			_showLineNumber = _showLineNumberItm.getSelection();
			_prop.var.etc.eventTreeSlope = _slope.getSelection();
			if (!_readOnly) { mixin(S_TRACE);
				_treeKindSel = _treeKind.getText();
				if (auto c = cast(CCombo)_fireItm.getControl()) { mixin(S_TRACE);
					_fireSel = c.getText();
				} else if (auto c = cast(Spinner)_fireItm.getControl()) { mixin(S_TRACE);
					_fireSelInt = c.getSelection();
				}
				if (_keyCodeTim) {
					_keyCodeTimSel = _keyCodeTim.getText();
				}
			}
		} else { mixin(S_TRACE);
			_resetToolBar = false;
		}
		while (_toolbar.getChildren()) _toolbar.getChildren()[0].dispose();
		while (_toolbar.getItemCount()) _toolbar.getItem(0).dispose();
		setupToolBar0();

		_etree.movingShell();
	}
	void moveShell() { mixin(S_TRACE);
		scope (exit) _toolbar.setRedraw(true);
		if (setupToolBar()) { mixin(S_TRACE);
			refShowToolBar();
			if (_resetToolBar) { mixin(S_TRACE);
				_showEventTreeDetailItm.setSelection(_showEventTreeDetail);
				_showLineNumberItm.setSelection(_showLineNumber);
				_slope.setSelection(_prop.var.etc.eventTreeSlope);
				if (!_readOnly) { mixin(S_TRACE);
					_treeKind.setText(_treeKindSel);
					kindSelected();
					if (auto c = cast(CCombo)_fireItm.getControl()) { mixin(S_TRACE);
						c.setText(_fireSel);
					} else if (auto c = cast(Spinner)_fireItm.getControl()) { mixin(S_TRACE);
						c.setSelection(_fireSelInt);
					}
					if (_keyCodeTim) {
						_keyCodeTim.setText(_keyCodeTimSel);
					}
				}
			}
			_comm.refreshToolBar();
		}
	}

	private bool canUdImpl(string BeforeAfter, string CanSwapKeyCode)(TreeItem itm) { mixin(S_TRACE);
		if (_readOnly) return false;
		if (itm && itm.getParentItem()) { mixin(S_TRACE);
			auto data = itm.getData();
			auto parent = itm.getParentItem();
			int from = parent.indexOf(itm);
			int to = mixin(BeforeAfter);
			if (to >= 0) { mixin(S_TRACE);
				if (cast(EventTree)data) { mixin(S_TRACE);
					return true;
				} else { mixin(S_TRACE);
					if (cast(KeyCodeObj)data) { mixin(S_TRACE);
						// キーコード
						auto tree = cast(EventTree) parent.getData();
						int keyCodeLen = cast(int)tree.keyCodes.length;
						from -= keyCodesIndex(parent);
						to -= keyCodesIndex(parent);
						return mixin(CanSwapKeyCode);
					}
				}
			}
		}
		return false;
	}
	private void udImpl(string BeforeAfter, string CanSwapKeyCode)
			(TreeItem itm, int function(TreeItem) treeSwap, bool store, bool viewOnly, uint count) { mixin(S_TRACE);
		if (_readOnly) return;
		if (itm && itm.getParentItem()) { mixin(S_TRACE);
			if (store) { mixin(S_TRACE);
				foreach (v; views()) v.editCancel();
			} else { mixin(S_TRACE);
				foreach (v; views()) v.editEnter();
			}
			auto data = itm.getData();
			auto parent = itm.getParentItem();
			if (cast(EventTree)data) { mixin(S_TRACE);
				_cards.setRedraw(false);
				scope (exit) _cards.setRedraw(true);
				// イベントツリー
				EVUndo[] undos;
				int from = parent.indexOf(itm);
				foreach (i; 0 .. count) { mixin(S_TRACE);
					int to = mixin(BeforeAfter);
					if (to < 0) break;
					auto eto = (cast(EventTreeOwner)parent.getData());
					if (!viewOnly) { mixin(S_TRACE);
						if (store) undos ~= this.store(_cards.indexOf(parent), from, to, false);
						eto.swapEventTree(from, to);
						_comm.refEventTree.call(eto.trees[from]);
						if (i == 0) { mixin(S_TRACE);
							_comm.refEventTree.call(eto.trees[to]);
						}
					}
					auto tPath = .toTreePath(itm);
					foreach (v; views()) {
						auto itm2 = .fromTreePath(v._cards, tPath);
						treeSwap(itm2);
						v._selItm = v.selection;
						if (i + 1 == count && v is this) v._cards.showSelection();
					}
					from = to;
					itm = parent.getItem(from);
				}
				if (undos.length == 1) { mixin(S_TRACE);
					_undo ~= undos[0];
				} else if (undos.length) { mixin(S_TRACE);
					_undo ~= new UndoSeq(_comm, _area, undos);
				}
			} else if (cast(KeyCodeObj)data) { mixin(S_TRACE);
				_cards.setRedraw(false);
				scope (exit) _cards.setRedraw(true);
				// キーコード
				assert (count == 1);
				int from = parent.indexOf(itm);
				int to = mixin(BeforeAfter);
				auto tree = cast(EventTree)parent.getData();
				int keyCodeLen = cast(int)tree.keyCodes.length;
				from -= keyCodesIndex(parent);
				to -= keyCodesIndex(parent);
				if (mixin(CanSwapKeyCode)) { mixin(S_TRACE);
					if (!viewOnly) { mixin(S_TRACE);
						if (store) this.store(tree);
						tree.swapKeyCode(from, to);
						_comm.refEventTree.call(tree);
					}
					auto tPath = .toTreePath(itm);
					foreach (v; views()) {
						auto itm2 = .fromTreePath(v._cards, tPath);
						treeSwap(itm2);
						if (v is this) v._cards.showSelection();
					}
				}
			}
		}
	}
	private static void staticUDImpl(Commons comm, EventTreeOwner eto, int from, int to) { mixin(S_TRACE);
		eto.swapEventTree(from, to);
		comm.refEventTree.call(eto.trees[from]);
		comm.refEventTree.call(eto.trees[to]);
	}
	@property
	bool canUp() { mixin(S_TRACE);
		if (_readOnly) return false;
		if (_lastFocus is _etree) { mixin(S_TRACE);
			return _etree.canUp();
		} else if (_lastFocus is _cards) { mixin(S_TRACE);
			return canUdImpl!("before(parent, from)", "to >= 0")(selection);
		}
		return false;
	}
	@property
	bool canDown() { mixin(S_TRACE);
		if (_readOnly) return false;
		if (_lastFocus is _etree) { mixin(S_TRACE);
			return _etree.canDown();
		} else if (_lastFocus is _cards) { mixin(S_TRACE);
			return canUdImpl!("after(parent, from)", "to < keyCodeLen")(selection);
		}
		return false;
	}
	void up() { mixin(S_TRACE);
		if (!canUp) return;
		initial();
		up(selection, true, false, false);
	}
	private void up(TreeItem itm, bool store, bool cards, bool viewOnly) { mixin(S_TRACE);
		if (_readOnly) return;
		if (!cards && _lastFocus is _etree) { mixin(S_TRACE);
			_etree.up();
		} else if (cards || _lastFocus is _cards) { mixin(S_TRACE);
			upImpl(itm, store, viewOnly, 1);
		}
	}
	private void upImpl(TreeItem itm, bool store, bool viewOnly, int count) { mixin(S_TRACE);
		udImpl!("before(parent, from)", "to >= 0")(itm, &treeItemUp, store, viewOnly, count);
		_comm.refreshToolBar();
	}
	void down() { mixin(S_TRACE);
		if (!canDown) return;
		initial();
		down(selection, true, false, false);
	}
	private void down(TreeItem itm, bool store, bool cards, bool viewOnly) { mixin(S_TRACE);
		if (_readOnly) return;
		if (!cards && _lastFocus is _etree) { mixin(S_TRACE);
			_etree.down();
		} else if (cards || _lastFocus is _cards) { mixin(S_TRACE);
			downImpl(itm, store, viewOnly, 1);
		}
	}
	private void downImpl(TreeItem itm, bool store, bool viewOnly, int count) { mixin(S_TRACE);
		udImpl!("after(parent, from)", "to < keyCodeLen")(itm, &treeItemDown, store, viewOnly, count);
		_comm.refreshToolBar();
	}

	private void openScene(bool canDuplicate = false) { mixin(S_TRACE);
		if (auto area = cast(Area)_area) { mixin(S_TRACE);
			_comm.openAreaScene(_prop, _summ, area, true, canDuplicate);
		} else if (auto area = cast(Battle)_area) { mixin(S_TRACE);
			_comm.openAreaScene(_prop, _summ, area, true, canDuplicate);
		}
	}
	void openDup() { mixin(S_TRACE);
		if (auto area = cast(Area)_area) { mixin(S_TRACE);
			_comm.openAreaEvent(_prop, _summ, area, true, true);
		} else if (auto area = cast(Battle)_area) { mixin(S_TRACE);
			_comm.openAreaEvent(_prop, _summ, area, true, true);
		} else if (auto area = cast(Package)_area) { mixin(S_TRACE);
			_comm.openArea(_prop, _summ, area, true, true);
		} else if (auto card = cast(EffectCard)_area) {
			_comm.openUseEvents(_prop, _summ, card, true, true);
		} else assert (0);
	}

	private bool _setupToolBar = false;
	private void setupToolBar0() { mixin(S_TRACE);
		auto bar = _toolbar;
		if (cast(EventWindow)tlpData(this).tlp) { mixin(S_TRACE);
			if (cast(Area)_area) {
				createToolItem(_comm, bar, MenuID.EditScene, () => openScene(false), null);
				if (_prop.var.etc.showDuplicateViewInToolBar) { mixin(S_TRACE);
					new ToolItem(bar, SWT.SEPARATOR);
					createToolItem(_comm, bar, MenuID.EditEventDup, &openDup, null);
				}
				new ToolItem(bar, SWT.SEPARATOR);
			} else if (cast(Battle)_area) {
				auto itm = createToolItem(_comm, bar, MenuID.EditScene, () => openScene(false), null);
				itm.setImage(_prop.images.editSceneBattle);
				if (_prop.var.etc.showDuplicateViewInToolBar) { mixin(S_TRACE);
					new ToolItem(bar, SWT.SEPARATOR);
					itm = createToolItem(_comm, bar, MenuID.EditEventDup, &openDup, null);
					itm.setImage(_prop.images.battleEventTreeViewDup);
				}
				new ToolItem(bar, SWT.SEPARATOR);
			} else if (_prop.var.etc.showDuplicateViewInToolBar) { mixin(S_TRACE);
				if (cast(Package)_area) {
					auto itm = createToolItem(_comm, bar, MenuID.EditEventDup, &openDup, null);
					itm.setImage(_prop.images.packageDup);
				} else if (cast(SkillCard)_area) {
					auto itm = createToolItem(_comm, bar, MenuID.EditEventDup, &openDup, null);
					itm.setImage(_prop.images.skillDup);
				} else if (cast(ItemCard)_area) {
					auto itm = createToolItem(_comm, bar, MenuID.EditEventDup, &openDup, null);
					itm.setImage(_prop.images.itemDup);
				} else if (cast(BeastCard)_area) {
					auto itm = createToolItem(_comm, bar, MenuID.EditEventDup, &openDup, null);
					itm.setImage(_prop.images.beastDup);
				}
				new ToolItem(bar, SWT.SEPARATOR);
			}
		}
	}
	private bool setupToolBar() { mixin(S_TRACE);
		if (_setupToolBar) return false;
		_setupToolBar = true;
		auto bar = _toolbar;
		if (!_readOnly) { mixin(S_TRACE);
			createToolItem(_comm, bar, MenuID.Undo, &undo, () => !_readOnly && _undo.canUndo);
			createToolItem(_comm, bar, MenuID.Redo, &redo, () => !_readOnly && _undo.canRedo);
			new ToolItem(bar, SWT.SEPARATOR);
			createToolItem(_comm, bar, MenuID.Up, &up, &canUp);
			createToolItem(_comm, bar, MenuID.Down, &down, &canDown);
			new ToolItem(bar, SWT.SEPARATOR);
		}
		if (!_readOnly) { mixin(S_TRACE);
			auto treeKindItm = new ToolItem(bar, SWT.SEPARATOR);
			_treeKind = new CCombo(bar, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
			_treeKind.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
			_comm.put(_treeKind, { mixin(S_TRACE);
				if (_readOnly) return false;
				auto itm = selection;
				if (itm && cast(PlayerCardEvents)itm.getData() && _summ.legacy) return false;
				return true;
			});
			createTextMenu!CCombo(_comm, _prop, _treeKind, null);
			_treeKind.add(_prop.msgs.eventTreeKindSystem);
			_treeKind.setText(_prop.msgs.eventTreeKindSystem);
			if (cast(Area)_area || cast(Battle)_area) {
				_treeKind.add(_prop.msgs.eventTreeKindKeyCode);
			}
			if (cast(Battle)_area) {
				_treeKind.add(_prop.msgs.eventTreeKindRound);
			}
			treeKindItm.setControl(_treeKind);
			treeKindItm.setWidth(_treeKind.computeSize(SWT.DEFAULT, SWT.DEFAULT).x);
			_treeKind.addSelectionListener(new KSListener);
			new ToolItem(bar, SWT.SEPARATOR);
		}
		if (!_readOnly) { mixin(S_TRACE);
			_fireItm = new ToolItem(bar, SWT.SEPARATOR);
			_fireItm.setWidth(_prop.var.etc.firesWidth);
			auto fireCombo = createCombo(true, areaDefVals);
			_comm.put(fireCombo, { mixin(S_TRACE);
				if (_readOnly) return false;
				auto itm = selection;
				if (itm && cast(PlayerCardEvents)itm.getData() && _summ.legacy) return false;
				return true;
			});
			if (cast(Area)_area || cast(Battle)_area) { mixin(S_TRACE);
				new ToolItem(bar, SWT.SEPARATOR);
				auto keyCodeTimItm = new ToolItem(bar, SWT.SEPARATOR);
				_keyCodeTim = new CCombo(bar, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
				_keyCodeTim.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
				createTextMenu!CCombo(_comm, _prop, _keyCodeTim, null);
				_keyCodeTim.setEnabled(false);
				_keyCodeTim.add(_prop.msgs.keyCodeTimingUse);
				_keyCodeTim.add(_prop.msgs.keyCodeTimingSuccess);
				_keyCodeTim.add(_prop.msgs.keyCodeTimingFailure);
				_keyCodeTim.add(_prop.msgs.keyCodeTimingHasNot);
				_keyCodeTim.select(0);
				keyCodeTimItm.setControl(_keyCodeTim);
				keyCodeTimItm.setWidth(_keyCodeTim.computeSize(SWT.DEFAULT, SWT.DEFAULT).x);
			}
			new ToolItem(bar, SWT.SEPARATOR);
		}
		if (!_readOnly) { mixin(S_TRACE);
			createToolItem2(_comm, bar, _prop.msgs.menuText(MenuID.NewEvent), _prop.images.menu(MenuID.NewEvent), &createEventWithIgnition, { mixin(S_TRACE);
				if (_readOnly) return false;
				auto par = selectionParent;
				if (!par) return false;
				if ((cast(Area)_area || cast(Battle)_area) && 1 == _treeKind.getSelectionIndex()) { mixin(S_TRACE);
					// キーコード発火条件
					if (!addKeyCodes()) return false;
				}
				if (cast(Battle)_area) { mixin(S_TRACE);
					auto eto = cast(EventTreeOwner)par.getData();
					assert (eto !is null);
					if (cast(AbstractSpCard)eto && 2 == _treeKind.getSelectionIndex()) { mixin(S_TRACE);
						// エネミーカード選択中、かつラウンド条件選択中
						return false;
					}
				}
				if (cast(PlayerCardEvents)par.getData() && _summ.legacy) { mixin(S_TRACE);
					// プレイヤーカードのキーコード・死亡時イベント(Wsn.2)
					return false;
				}
				return true;
			});
			if (cast(Area)_area || cast(Battle)_area) { mixin(S_TRACE);
				createToolItem2(_comm, bar, _prop.msgs.newIgnition, _prop.images.newIgnition, &createEventFire, { mixin(S_TRACE);
					if (_readOnly) return false;
					if (selectionEventTree is null) return false;
					if ((cast(Area)_area || cast(Battle)_area) && 1 == _treeKind.getSelectionIndex()) { mixin(S_TRACE);
						// キーコード発火条件
						if (!addKeyCodes()) return false;
					}
					if (cast(Battle)_area) { mixin(S_TRACE);
						auto par = selectionParent;
						assert (par !is null);
						auto eto = cast(EventTreeOwner)par.getData();
						assert (eto !is null);
						if (cast(AbstractSpCard)eto && 2 == _treeKind.getSelectionIndex()) { mixin(S_TRACE);
							// エネミーカード選択中、かつラウンド条件選択中
							return false;
						}
					}
					return true;
				});
			}
			new ToolItem(bar, SWT.SEPARATOR);
			createToolItem(_comm, bar, MenuID.EditSelection, &_etree.editSelection, &_etree.canEditSelection);
			new ToolItem(bar, SWT.SEPARATOR);
		}
		createToolItem2(_comm, bar, _prop.msgs.expandTree, _prop.images.expandTree, &_etree.treeOpen, &_etree.canExpandTree);
		createToolItem2(_comm, bar,_prop.msgs.foldTree,  _prop.images.foldTree, &_etree.treeClose, &_etree.canFoldTree);
		new ToolItem(bar, SWT.SEPARATOR);
		_showEventTreeDetailItm = createToolItem2(_comm, bar,_prop.msgs.showEventTreeDetail, _prop.images.showEventTreeDetail, &_etree.reverseShowEventTreeDetail, () => _prop.var.etc.straightEventTreeView.value, SWT.CHECK);
		_showEventTreeDetailItm.setSelection(_prop.var.etc.showEventTreeDetail);
		_showLineNumberItm = createToolItem2(_comm, bar,_prop.msgs.showEventTreeLineNumber, _prop.images.showEventTreeLineNumber, &_etree.reverseShowLineNumber, () => _prop.var.etc.straightEventTreeView.value, SWT.CHECK);
		_showLineNumberItm.setSelection(_prop.var.etc.showEventTreeLineNumber);
		new ToolItem(bar, SWT.SEPARATOR);
		auto imgW = _prop.var.etc.eventTreeSlope.INIT.ppis;
		_slope = createSpinner(bar, _prop.msgs.eventTreeSlope, imgW, 0, _prop.var.etc.eventTreeSlope,
			&editEventTreeSlope, null, &cancelEventTreeSlope, SWT.NONE);
		void refEventTreeViewStyle() { mixin(S_TRACE);
			_slope.setEnabled(_prop.var.etc.straightEventTreeView);
		}
		refEventTreeViewStyle();
		_comm.refEventTreeViewStyle.add(&refEventTreeViewStyle);
		.listener(_slope, SWT.Dispose, { mixin(S_TRACE);
			_comm.refEventTreeViewStyle.remove(&refEventTreeViewStyle);
		});
		new ToolItem(bar, SWT.SEPARATOR);
		createToolItem(_comm, bar, MenuID.SelectCurrentEvent, &selectCurrentEvent, &canSelectCurrentEvent);
		bar.getParent().layout();
		return true;
	}
	private void refEventTreeSlope(Object sender, int slope) { mixin(S_TRACE);
		if (sender !is this) { mixin(S_TRACE);
			_etree.eventTreeSlope = slope;
			if (_slope) _slope.setSelection(slope);
		}
	}
	private void editEventTreeSlope(int value) { mixin(S_TRACE);
		_prop.var.etc.eventTreeSlope = value;
		_etree.eventTreeSlope = value;
		_comm.refEventTreeSlope.call(this, value);
	}
	private int cancelEventTreeSlope(int oldVal) { mixin(S_TRACE);
		editEventTreeSlope(oldVal);
		return oldVal;
	}
	private void setFireControl(Control c) { mixin(S_TRACE);
		if (_readOnly) return;
		if (_fireItm.getControl()) _fireItm.getControl().dispose();
		_fireItm.setControl(c);
		_comm.refreshToolBar();
	}
	@property
	private string[] areaDefVals() { mixin(S_TRACE);
		if (cast(Area)_area) {
			return [_prop.msgs.startEnter];
		} else if (cast(Battle)_area) {
			return [_prop.msgs.startVictory, _prop.msgs.startEscape, _prop.msgs.startLose, _prop.msgs.startEveryRound, _prop.msgs.startRoundEnd, _prop.msgs.startRound0];
		} else if (cast(Package)_area) {
			return [_prop.msgs.startPackage];
		} else { mixin(S_TRACE);
			return [_prop.msgs.startUse];
		}
	}
	@property
	private string[] startDefVals() { mixin(S_TRACE);
		auto itm = selectionParent;
		if (!itm) return [];
		auto data = itm.getData();
		string[] vals;
		if (cast(MenuCard)data) {
			return [_prop.msgs.startSelect];
		} else if (cast(EnemyCard)data || cast(PlayerCardEvents)data) { mixin(S_TRACE);
			return [_prop.msgs.startDead];
		} else { mixin(S_TRACE);
			return areaDefVals;
		}
	}
	private CCombo createCombo(bool readOnly, string[] vals) { mixin(S_TRACE);
		int style = SWT.BORDER | SWT.DROP_DOWN;
		if (readOnly) style |= SWT.READ_ONLY;
		auto c = new CCombo(_toolbar, style);
		c.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
		c.setEnabled(!_readOnly);
		foreach (i, v; vals) { mixin(S_TRACE);
			c.add(v);
			if (i == 0) c.setText(v);
		}
		createTextMenu!CCombo(_comm, _prop, c, null);
		setFireControl(c);
		return c;
	}
	private void createKCCombo() { mixin(S_TRACE);
		auto combo = createKeyCodeCombo!CCombo(_comm, _summ, _toolbar, null, "", true);
		combo.setEnabled(!_readOnly);
		setFireControl(combo);
		if (combo.getItemCount()) { mixin(S_TRACE);
			combo.select(0);
		}
	}
	private class KSListener : SelectionAdapter {
	public:
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			kindSelected();
		}
	}
	private void kindSelected() { mixin(S_TRACE);
		if (cast(Area)_area) {
			switch (_treeKind.getSelectionIndex()) {
			case 0:
				createCombo(true, startDefVals);
				_keyCodeTim.setEnabled(false);
				break;
			case 1:
				createKCCombo();
				_keyCodeTim.setEnabled(!_readOnly);
				break;
			default: assert (0);
			}
		} else if (cast(Battle)_area) {
			switch (_treeKind.getSelectionIndex()) {
			case 0:
				createCombo(true, startDefVals);
				_keyCodeTim.setEnabled(false);
				break;
			case 1:
				createKCCombo();
				_keyCodeTim.setEnabled(!_readOnly);
				break;
			case 2:
				auto spn = new Spinner(_toolbar, SWT.BORDER);
				initSpinner(spn);
				spn.setMaximum(9999);
				spn.setMinimum(1);
				spn.setSelection(1);
				setFireControl(spn);
				_keyCodeTim.setEnabled(false);
				break;
			default: assert (0);
			}
		}
	}

	private string[] getWarning(TreeItem itm) { mixin(S_TRACE);
		if (!cast(Area)_area && !cast(Battle)_area) return [];

		if (auto playerEvents = cast(PlayerCardEvents)itm.getData()) { mixin(S_TRACE);
			auto isClassic = _summ && _summ.legacy;
			auto wsnVer = _summ ? _summ.dataVersion : LATEST_VERSION;
			return .warnings(_prop.parent, summSkin, _summ, playerEvents, isClassic, wsnVer, _prop.var.etc.targetVersion);
		}
		if (auto btl = cast(Battle)_area) { mixin(S_TRACE);
			if (!btl.possibleToRunAway && itm.getData() is ESCAPE) { mixin(S_TRACE);
				return [cast(string)_prop.msgs.warningNoIgniteRunAway];
			}
		}

		if (auto et = cast(EventTree)itm.getData()) { mixin(S_TRACE);
			if (et.keyCodeMatchingType is MatchingType.And && !_prop.targetVersion(_summ, "1.50")) { mixin(S_TRACE);
				return [cast(string)_prop.msgs.warningKeyCodeMatchingTypeAnd];
			}
		}

		if (auto kco = cast(KeyCodeObj)itm.getData()) { mixin(S_TRACE);
			auto keyCode = kco.array.idup;
			string[] kcw;
			kcw ~= .sjisWarnings(_prop.parent, _summ, keyCode, _prop.msgs.keyCode);
			if (keyCode == "MatchingType=All") { mixin(S_TRACE);
				auto et = cast(EventTree)itm.getParentItem().getData();
				assert (et !is null);
				assert (et.keyCodes.length);
				if (_prop.sys.convFireKeyCode(et.keyCodes[0]) == keyCode) { mixin(S_TRACE);
					kcw ~= _prop.msgs.searchErrorKeyCodeMatchingAll;
				}
			}
			if (_prop.sys.fireKeyCodeKind(keyCode) is FKCKind.HasNot && !_prop.targetVersion(_summ, "1.50")) { mixin(S_TRACE);
				kcw ~= _prop.msgs.warningHasNotKeyCode;
			}
			return kcw;
		}

		if (itm.getData() is EVERY_ROUND) { mixin(S_TRACE);
			if (!_prop.targetVersion(_summ, "1.50")) { mixin(S_TRACE);
				return [cast(string)_prop.msgs.warningEveryRound];
			}
		}
		if (itm.getData() is ROUND_END) { mixin(S_TRACE);
			if (!_prop.isTargetVersion(_summ, "4")) { mixin(S_TRACE);
				return [cast(string)_prop.msgs.warningRoundEnd];
			}
		}
		if (itm.getData() is ROUND_0) { mixin(S_TRACE);
			if (!_prop.targetVersion(_summ, "1.50")) { mixin(S_TRACE);
				return [cast(string)_prop.msgs.warningRound0];
			}
		}
		return [];
	}

	void openToolWindow() { mixin(S_TRACE);
		auto fc = this.getDisplay().getFocusControl();
		bool focusInEventView = this.isDescendant(fc);
		_etree.openToolWindow(focusInEventView);
	}
	void closeToolWindow() { mixin(S_TRACE);
		_etree.closeToolWindow();
	}

	@property
	string statusLine() { mixin(S_TRACE);
		return _etree.statusLine;
	}

	void edit() { mixin(S_TRACE);
		_etree.edit();
	}
	@property
	bool canEdit() { mixin(S_TRACE);
		return _etree.canEdit();
	}

	@property
	bool canCut1Content() { return _etree.canCut1Content; }
	@property
	bool canDel1Content() { return _etree.canDel1Content; }
	@property
	bool canCopy1Content() { return _etree.canCopy1Content; }
	@property
	bool canPasteInsert() { return _etree.canPasteInsert; }
	@property
	bool canSwapToParent() { return _etree.canSwapToParent; }
	@property
	bool canSwapToChild() { return _etree.canSwapToChild; }
	void cut1Content() { _etree.cut1Content(); }
	void copy1Content() { _etree.copy1Content(); }
	void pasteInsert() { _etree.pasteInsert(); }
	void del1Content() { _etree.del1Content(); }
	void swapToParent() { _etree.swapToParent(); }
	void swapToChild() { _etree.swapToChild(); }

	void toScript() { mixin(S_TRACE);
		_etree.toScript();
	}
	void toScript1Content() { mixin(S_TRACE);
		_etree.toScript1Content();
	}
	void toScriptAll() { mixin(S_TRACE);
		_etree.toScriptAll();
	}
	@property
	bool canToScript() { mixin(S_TRACE);
		return _etree.canToScript();
	}
	@property
	bool canToScriptAll() { mixin(S_TRACE);
		return _etree.canToScriptAll();
	}
	@property
	bool canWriteComment() { mixin(S_TRACE);
		if (_cards.isFocusControl()) { mixin(S_TRACE);
			return canWriteCommentL;
		} else { mixin(S_TRACE);
			return _etree.canWriteComment;
		}
	}
	void writeComment() { mixin(S_TRACE);
		if (_cards.isFocusControl()) { mixin(S_TRACE);
			writeCommentL();
		} else { mixin(S_TRACE);
			_etree.writeComment();
		}
	}
	@property
	bool canStartToPackage() { mixin(S_TRACE);
		return _etree.canStartToPackage();
	}
	void startToPackage() { mixin(S_TRACE);
		return _etree.startToPackage();
	}
	@property
	bool canWrapTree() { mixin(S_TRACE);
		return _etree.canWrapTree();
	}
	void wrapTree() { mixin(S_TRACE);
		return _etree.wrapTree();
	}
	@property
	bool canFindStartUsers() { mixin(S_TRACE);
		return _etree.canFindStartUsers();
	}
	void findStartUsers() { mixin(S_TRACE);
		return _etree.findStartUsers();
	}

	@property
	bool canEventToPackage() { mixin(S_TRACE);
		return selectionEventTree !is null;
	}
	void eventToPackage() { mixin(S_TRACE);
		auto etItm = selectionEventTree;
		if (!etItm) return;
		auto et = cast(EventTree)etItm.getData();
		auto parItm = etItm.getParentItem();
		assert (et !is null);
		auto index = parItm.indexOf(etItm);

		auto id = _comm.createPackage(et, .tryFormat("%1$s-%2$s", parItm.getText(), et.name), false);
		if (id == 0) { mixin(S_TRACE);
			return;
		}
		storeContents(et);
		auto vs = views();
		foreach (s; et.starts) { mixin(S_TRACE);
			_comm.delContent.call(s);
		}

		auto c = new Content(CType.LinkPackage, "");
		c.packages = id;
		auto s = new Content(CType.Start, et.name);
		s.add(_prop.parent, c);
		et.starts = [s];

		foreach (v; vs) { mixin(S_TRACE);
			if (v._etree && v._etree.eventTree is et) { mixin(S_TRACE);
				v._etree.refresh(null);
				v._etree.refresh(et);
			}
		}
	}

	@property
	bool canSelectCurrentEvent() { mixin(S_TRACE);
		auto sel = selection;
		auto et = _etree.eventTree;
		return et && (!sel || sel.getData() !is et);
	}
	void selectCurrentEvent() { mixin(S_TRACE);
		auto et = _etree.eventTree;
		if (!et) return;
		foreach (itm; _cards.getItems()) { mixin(S_TRACE);
			foreach (etItm; itm.getItems()) { mixin(S_TRACE);
				if (etItm.getData() is et) { mixin(S_TRACE);
					selectImpl(etItm);
					break;
				}
			}
		}
	}

	@property
	bool canSelectConnectedResource() { mixin(S_TRACE);
		auto sel = selection;
		return sel && cast(EventTreeOwner)sel.getData() && !cast(PlayerCardEvents)sel.getData();
	}
	void selectConnectedResource() { mixin(S_TRACE);
		if (!canSelectConnectedResource) return;
		auto eto = cast(EventTreeOwner)selection.getData();
		assert (eto !is null);
		if (cast(PlayerCardEvents)eto) return;
		_comm.openCWXPath(.cpaddattr(.cpaddattr(eto.cwxPath(true), "shallow"), "only"), false);
	}

	private TreeItem _dragItm = null;
	private EVUndo _dropUndo = null;
	class EventViewDragSource : DragSourceListener {
	private:
		TreeItem _targ;
	public:
		override void dragStart(DragSourceEvent e) { mixin(S_TRACE);
			auto itm = selection;
			e.doit = !_readOnly && itm && !cast(EventTreeOwner)itm.getData()
				&& (cast(DragSource) e.getSource()).getControl().isFocusControl();
			if (e.doit) { mixin(S_TRACE);
				_targ = itm;
				_dragItm = _targ;
				_dropUndo = null;
			}
		}
		override void dragSetData(DragSourceEvent e) { mixin(S_TRACE);
			auto itm = selection;
			if (itm && XMLBytesTransfer.getInstance().isSupportedType(e.dataType)) { mixin(S_TRACE);
				auto xml = itemToXML(itm, true, true);
				if (xml == "") return;
				e.data = bytesFromXML(xml);
			}
		}
		override void dragFinished(DragSourceEvent e) { mixin(S_TRACE);
			foreach (v; views()) v.editCancel();
			_dragItm = null;
			auto itm = _targ;
			if (itm && e.detail == DND.DROP_MOVE) { mixin(S_TRACE);
				EVUndo undo;
				delItem(itm, false, undo);
				if (_dropUndo) { mixin(S_TRACE);
					_undo ~= new UndoSeq(_comm, _area, [_dropUndo, undo]);
				} else { mixin(S_TRACE);
					_undo ~= undo;
				}
			}
			_dropUndo = null;
		}
	}
	class EventViewDropTarget : DropTargetAdapter {
	private:
		void move(DropTargetEvent e) { mixin(S_TRACE);
			e.detail = DND.DROP_NONE;
			if (_readOnly || !e.item) return;
			if (cast(PlayerCardEvents)e.item.getData() && _summ.legacy) return;
			e.detail = DND.DROP_MOVE;
		}
	public:
		override void dragEnter(DropTargetEvent e){ mixin(S_TRACE);
			move(e);
		}
		override void dragOver(DropTargetEvent e){ mixin(S_TRACE);
			move(e);
		}
		override void drop(DropTargetEvent e){ mixin(S_TRACE);
			if (_readOnly || !e.item) return;
			if (cast(PlayerCardEvents)e.item.getData() && _summ.legacy) return;
			e.detail = DND.DROP_NONE;
			if (!isXMLBytes(e.data)) return;
			assert (cast(TreeItem)e.item);
			foreach (v; views()) v.editEnter();
			auto ti = cast(TreeItem)e.item;
			if (!ti) return;
			if (_dragItm) { mixin(S_TRACE);
				if (ti is _dragItm) return;
				if (auto tree = cast(EventTree)_dragItm.getData()) { mixin(S_TRACE);
					auto fromTop = topParent(_dragItm);
					auto toTop = topParent(ti);
					if (fromTop is toTop) { mixin(S_TRACE);
						// 単一のオーナー内でイベントツリーを移動する場合
						auto fromIndex = fromTop.indexOf(_dragItm);
						int toIndex;
						if (toTop is ti) { mixin(S_TRACE);
							toIndex = toTop.getItemCount();
						} else { mixin(S_TRACE);
							auto treeItm = cast(EventTree)ti.getData() ? ti : ti.getParentItem();
							toIndex = toTop.indexOf(treeItm);
						}
						if (fromIndex == toIndex) return;
						if (fromIndex < toIndex) { mixin(S_TRACE);
							if (fromIndex + 1 == toIndex) return;
							downImpl(_dragItm, true, false, toIndex - fromIndex - 1);
						} else { mixin(S_TRACE);
							assert (toIndex < fromIndex);
							upImpl(_dragItm, true, false, fromIndex - toIndex);
						}
						return;
					}
				}
				auto tip = eventItemFrom(ti);
				auto dip = eventItemFrom(_dragItm);
				if (cast(KeyCodeObj)_dragItm.getData() && tip is dip) { mixin(S_TRACE);
					// 単一のイベントツリー内でキーコードを移動する場合
					auto kco = cast(KeyCodeObj)_dragItm.getData();
					if (cast(EventTreeOwner)ti.getData()) return;
					auto keyCode = kco.array.idup;
					auto fromTreeItm = _dragItm.getParentItem();
					ptrdiff_t fromIndex = fromTreeItm.indexOf(_dragItm) - keyCodesIndex(fromTreeItm);
					ptrdiff_t toIndex;
					if (auto toTree = cast(EventTree)ti.getData()) { mixin(S_TRACE);
						toIndex = toTree.keyCodes.length;
					} else { mixin(S_TRACE);
						auto treeItm = ti.getParentItem();
						toIndex = .max(0, treeItm.indexOf(ti) - keyCodesIndex(treeItm));
					}
					if (fromIndex == toIndex) return;
					auto tree = cast(EventTree)fromTreeItm.getData();
					store(tree);
					auto array = tree.keyCodes.dup;
					auto kc = array[fromIndex];
					array = array.remove(fromIndex);
					if (fromIndex < toIndex) toIndex--;
					array.insertInPlace(toIndex, kc);
					tree.keyCodes = array;
					refreshFires(fromTreeItm);

					auto selItm = fromTreeItm.getItem(keyCodesIndex(fromTreeItm) + cast(int)toIndex);
					_cards.setSelection([selItm]);
					_cards.showSelection();
					return;
				}
			}
			try { mixin(S_TRACE);
				auto xml = bytesToXML(e.data);
				auto node = XNode.parse(xml);
				auto samePane = node.attr("paneId", false, "") == _id;
				EVUndo undo = null;
				if (pasteXML(node, ti, false, !samePane || !_dragItm, undo)) {
					e.detail = samePane ? DND.DROP_MOVE : DND.DROP_COPY;
					if (samePane && _dragItm) _dropUndo = undo;
				}
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
			}
		}
	}

	private void pasteScript(Clipboard cb) { mixin(S_TRACE);
		if (_readOnly) return;
		auto array = cast(ArrayWrapperString)cb.getContents(TextTransfer.getInstance());
		if (!array) return;
		CompileOption opt;
		string script = array.array.idup;
		string base = script;
		try { mixin(S_TRACE);
			opt.linkId = (_prop.var.etc.linkCard || !_summ || !_summ.legacy);

			void put(Content[] cs) { mixin(S_TRACE);
				if (!cs.length) return;
				if (cs[0].type !is CType.Start) return;
				createEventWithIgnition(cs);
			}
			auto compiler = new CWXScript(_prop.parent, _summ);
			auto vars = compiler.eatEmptyVars(script, opt);
			if (vars.length) { mixin(S_TRACE);
				auto ec = cast(LocalVariableOwner)_area;
				auto dlg = new ScriptVarSetDialog(_comm, _summ, ec ? ec.useCounter : _summ.useCounter, _cards.getShell(), vars, script, base, opt);
				dlg.appliedEvent ~= { mixin(S_TRACE);
					put(dlg.contents);
				};
				dlg.open();
			} else { mixin(S_TRACE);
				put(cwx.script.compile(_prop.parent, _summ, script, opt));
			}
		} catch (CWXScriptException e) {
			printStackTrace();
			debugln(e);
			auto dlg = new ScriptErrorDialog(_comm, _prop, _cards, e, base, opt);
			dlg.open();
		}
	}
	override void cut(SelectionEvent se) { mixin(S_TRACE);
		if (_readOnly) return;
		initial();
		if (_lastFocus is _etree) { mixin(S_TRACE);
			_etree.cut(se);
		} else { mixin(S_TRACE);
			copy(se);
			del(se);
		}
	}
	override void copy(SelectionEvent se) { mixin(S_TRACE);
		copyImpl(se, true);
	}
	private void copyImpl(SelectionEvent se, bool canFire) { mixin(S_TRACE);
		initial();
		if (_lastFocus is _etree) { mixin(S_TRACE);
			_etree.copy(se);
		} else { mixin(S_TRACE);
			auto itm = selection;
			if (!itm) return;
			auto xml = itemToXML(itm, canFire, false);
			if (xml == "") return;
			XMLtoCB(_prop, _comm.clipboard, xml);
			_comm.refreshToolBar();
		}
	}
	private string itemToXML(TreeItem itm, bool canFire, bool paneId) { mixin(S_TRACE);
		if (!itm) return "";
		auto parItm = itm.getParentItem();
		if (!parItm) return "";
		auto par = parItm.getData();
		auto data = itm.getData();
		XNode node;
		if (cast(EventTree) data) { mixin(S_TRACE);
			node = (cast(EventTree)data).toNode(new XMLOption(_prop.sys, LATEST_VERSION));
		} else if (!canFire) { mixin(S_TRACE);
			assert (cast(EventTree)par !is null);
			node = (cast(EventTree)par).toNode(new XMLOption(_prop.sys, LATEST_VERSION));
		} else if (ENTER is data) { mixin(S_TRACE);
			node = EventTree.enterToNode();
		} else if (ESCAPE is data) { mixin(S_TRACE);
			node = EventTree.escapeToNode();
		} else if (LOSE is data) { mixin(S_TRACE);
			node = EventTree.loseToNode();
		} else if (EVERY_ROUND is data) { mixin(S_TRACE);
			node = EventTree.everyRoundToNode();
		} else if (ROUND_END is data) { mixin(S_TRACE);
			node = EventTree.roundEndToNode();
		} else if (ROUND_0 is data) { mixin(S_TRACE);
			node = EventTree.round0ToNode();
		} else if (cast(KeyCodeObj)data) { mixin(S_TRACE);
			node = EventTree.keyCodeToNode(_prop.sys.toFKeyCode((cast(KeyCodeObj)data).array.idup), _prop.sys);
		} else if (cast(RoundObj)data) { mixin(S_TRACE);
			node = EventTree.roundToNode((cast(RoundObj)data).intValue());
		} else { mixin(S_TRACE);
			assert (0);
		}
		if (paneId) { mixin(S_TRACE);
			node.newAttr("paneId", _id);
		}
		return node.text;
	}
	override void paste(SelectionEvent se) { mixin(S_TRACE);
		if (_readOnly) return;
		initial();
		foreach (v; views()) v.editEnter();
		if (_lastFocus is _etree) { mixin(S_TRACE);
			_etree.paste(se);
		} else { mixin(S_TRACE);
			auto itm = selection;
			if (!itm) return;
			auto xml = CBtoXML(_comm.clipboard);
			if (!xml) { mixin(S_TRACE);
				pasteScript(_comm.clipboard);
				return;
			}
			try { mixin(S_TRACE);
				auto node = XNode.parse(xml);
				EVUndo undo;
				pasteXML(node, selection, true, true, undo);
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
			}
		}
	}
	private bool pasteXML(ref XNode node, TreeItem itm, bool appendToLast, bool store, out EVUndo undo) { mixin(S_TRACE);
		if (!itm) return false;
		auto parItm = topParent(itm);
		if (!parItm) return false;
		try { mixin(S_TRACE);
			auto par = cast(EventTreeOwner)parItm.getData();
			auto ver = new XMLInfo(_prop.sys, LATEST_VERSION);
			if (node.name == "Event") { mixin(S_TRACE);
				if (cast(PlayerCardEvents)par && _summ.legacy) return false;
				EventTree tree = EventTree.createFromNode(node, ver);
				ptrdiff_t index = par.trees.length;
				if (!appendToLast && parItm !is itm) { mixin(S_TRACE);
					auto treeItm = cast(EventTree)itm.getData() ? itm : itm.getParentItem();
					index = parItm.indexOf(treeItm);
				}
				undo = storeI(_cards.indexOf(parItm), index, store);
				// イベントツリー
				par.insert(index, tree);
				TreeItem ti = null;
				foreach (v; views()) { mixin(S_TRACE);
					auto parItm2 = .anotherTreeItem(v._cards, parItm);
					auto treeItm = .createTreeItem(parItm2, tree, tree.name, v.etImage(tree), cast(int)index);
					if (v is this) v.selectImpl(treeItm);
					if (v is this) ti = treeItm;
				}
				refreshFires(ti);
				_comm.refEventTree.call(tree);
				_comm.refUseCount.call();
				_comm.refreshToolBar();
				return true;
			} else { mixin(S_TRACE);
				if (cast(Area)_area || cast(Battle)_area) { mixin(S_TRACE);
					if (!(cast(EventTreeOwner)itm.getData())) { mixin(S_TRACE);
						// 開始条件
						auto treeItm = cast(EventTree)itm.getData() ? itm : itm.getParentItem();
						auto tree = cast(EventTree)treeItm.getData();
						undo = this.store(tree, store);
						bool r = false;
						void putFire(Object o) { mixin(S_TRACE);
							foreach (v; views()) { mixin(S_TRACE);
								auto treeItm2 = .anotherTreeItem(v._cards, treeItm);
								v.refreshFires(treeItm2, o, true);
							}
							r = true;
						}
						if (tree.enterFromNode(par, node)) { mixin(S_TRACE);
							putFire(ENTER);
						} else if (tree.escapeFromNode(par, node)) { mixin(S_TRACE);
							putFire(ESCAPE);
						} else if (tree.loseFromNode(par, node)) { mixin(S_TRACE);
							putFire(LOSE);
						} else if (tree.everyRoundFromNode(par, node)) { mixin(S_TRACE);
							putFire(EVERY_ROUND);
						} else if (tree.roundEndFromNode(par, node)) { mixin(S_TRACE);
							putFire(ROUND_END);
						} else if (tree.round0FromNode(par, node)) { mixin(S_TRACE);
							putFire(ROUND_0);
						} else { mixin(S_TRACE);
							auto rounds = tree.roundsFromNode(par, node, ver);
							foreach (round; rounds) { mixin(S_TRACE);
								putFire(new RoundObj(round));
							}
							FKeyCode[] keyCodes;
							if (appendToLast || treeItm is itm) { mixin(S_TRACE);
								keyCodes = tree.keyCodesFromNode(par, node, ver, _prop.sys);
							} else { mixin(S_TRACE);
								auto index = treeItm.indexOf(itm) - keyCodesIndex(treeItm);
								if (index < 0) index = 0;
								keyCodes = tree.keyCodesFromNode(par, node, ver, _prop.sys, index);
							}
							foreach (keyCode; keyCodes) { mixin(S_TRACE);
								putFire(new KeyCodeObj(_prop.sys.convFireKeyCode(keyCode)));
							}
						}
						if (r) { mixin(S_TRACE);
							_comm.refEventTree.call(tree);
							_comm.refKeyCodes.call();
						}
						return r;
					}
				}
			}
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
		return false;
	}
	override void del(SelectionEvent se) { mixin(S_TRACE);
		if (_readOnly) return;
		initial();
		foreach (v; views()) v.editEnter();
		if (_lastFocus is _etree) { mixin(S_TRACE);
			_etree.del(se);
		} else { mixin(S_TRACE);
			auto itm = selection;
			if (!itm) return;
			EVUndo undo = null;
			delItem(itm, true, undo);
		}
	}
	private void delItem(TreeItem itm, bool store, out EVUndo undo) { mixin(S_TRACE);
		if (!itm) return;
		auto parItm = itm.getParentItem();
		if (!parItm) return;
		auto par = parItm.getData();
		auto data = itm.getData();
		auto tree = cast(EventTree)data;
		auto vs = views();
		foreach (v; vs) v.editCancel();
		if (tree) { mixin(S_TRACE);
			undo = storeD(tree, store);
			(cast(EventTreeOwner)par).remove(tree);
			foreach (v; vs) { mixin(S_TRACE);
				auto itm2 = .anotherTreeItem(v._cards, itm);
				if (v._selItm is itm2) { mixin(S_TRACE);
					v._etree.refresh(null);
					v._selItm.setImage(etImage(tree));
					v._selItm = null;
				}
				foreach (dlg; v._editDlgs.values) { mixin(S_TRACE);
					if (dlg.eventTree is tree) dlg.forceCancel();
				}
				foreach (key; v._commentDlgs.keys) { mixin(S_TRACE);
					if (tree.objectId == key) v._commentDlgs[key].forceCancel();
				}
			}
			_comm.delEventTree.call(tree);
		} else { mixin(S_TRACE);
			if (cast(Area)_area || cast(Battle)_area) { mixin(S_TRACE);
				tree = cast(EventTree)par;
				undo = this.store(tree, store);
				if (ENTER is data) { mixin(S_TRACE);
					tree.enter = false;
				} else if (ESCAPE is data) { mixin(S_TRACE);
					tree.escape = false;
				} else if (LOSE is data) { mixin(S_TRACE);
					tree.lose = false;
				} else if (EVERY_ROUND is data) { mixin(S_TRACE);
					tree.everyRound = false;
				} else if (ROUND_END is data) { mixin(S_TRACE);
					tree.roundEnd = false;
				} else if (ROUND_0 is data) { mixin(S_TRACE);
					tree.round0 = false;
				} else if (cast(KeyCodeObj)data) { mixin(S_TRACE);
					tree.removeKeyCode(_prop.sys.toFKeyCode((cast(KeyCodeObj)data).array.idup));
				} else if (cast(RoundObj)data) { mixin(S_TRACE);
					tree.removeRound((cast(RoundObj)data).intValue());
				} else { mixin(S_TRACE);
					assert (0);
				}
				_comm.refEventTree.call(tree);
			}
		}
		auto tPath = .toTreePath(itm);
		foreach (v; vs) { mixin(S_TRACE);
			auto itm2 = .fromTreePath(v._cards, tPath);
			itm2.dispose();
		}
		_comm.refUseCount.call();
		_comm.refreshToolBar();
	}
	override void clone(SelectionEvent se) { mixin(S_TRACE);
		if (_readOnly) return;
		foreach (v; views()) v.editEnter();
		if (_lastFocus is _etree) { mixin(S_TRACE);
			_etree.clone(se);
		} else { mixin(S_TRACE);
			_comm.clipboard.memoryMode = true;
			scope (exit) _comm.clipboard.memoryMode = false;
			copyImpl(se, false);
			paste(se);
		}
	}
	@property
	override bool canDoTCPD() { mixin(S_TRACE);
		if (_readOnly) return false;
		return true;
	}
	@property
	override bool canDoT() { mixin(S_TRACE);
		if (_readOnly) return false;
		if (_lastFocus is _cards) { mixin(S_TRACE);
			return selection && selection.getParentItem();
		} else if (_lastFocus is _etree) { mixin(S_TRACE);
			return _etree.canDoT;
		}
		return false;
	}
	@property
	override bool canDoC() { mixin(S_TRACE);
		if (_lastFocus is _cards) { mixin(S_TRACE);
			return selection && selection.getParentItem();
		} else if (_lastFocus is _etree) { mixin(S_TRACE);
			return _etree.canDoC;
		}
		return false;
	}
	@property
	override bool canDoP() { mixin(S_TRACE);
		if (_readOnly) return false;
		if (_lastFocus is _cards) { mixin(S_TRACE);
			auto parItm = selectionParent;
			if (parItm && cast(PlayerCardEvents)parItm.getData() && _summ.legacy) return false;
			return CBisXML(_comm.clipboard) || CBisText(_comm.clipboard);
		} else if (_lastFocus is _etree) { mixin(S_TRACE);
			return _etree.canDoP;
		}
		return false;
	}
	@property
	override bool canDoD() { mixin(S_TRACE);
		if (_readOnly) return false;
		if (_lastFocus is _cards) { mixin(S_TRACE);
			return canDoT;
		} else if (_lastFocus is _etree) { mixin(S_TRACE);
			return _etree.canDoD;
		}
		return false;
	}
	@property
	override bool canDoClone() { mixin(S_TRACE);
		if (_readOnly) return false;
		return canDoC;
	}
	void undo() { mixin(S_TRACE);
		if (_readOnly) return;
		foreach (v; views()) v.editCancel();
		_undo.undo();
		_comm.refreshToolBar();
	}
	void redo() { mixin(S_TRACE);
		if (_readOnly) return;
		foreach (v; views()) v.editCancel();
		_undo.redo();
		_comm.refreshToolBar();
	}

	@property
	const
	private int cardsIndex() { return (cast(Area)_area || cast(Battle)_area) ? 2 : 1; }

	bool openCWXPath(string path, bool shellActivate) { mixin(S_TRACE);
		initial();
		auto cate = cpcategory(path);
		auto index = cpindex(path);
		bool open(TreeItem itm) { mixin(S_TRACE);
			if (index >= itm.getItemCount()) { mixin(S_TRACE);
				return false;
			}
			selectImpl(itm.getItem(cast(int)index));
			return _etree.openCWXPath(cpbottom(path), shellActivate);
		}
		bool card() { mixin(S_TRACE);
			if (index + cardsIndex >= _cards.getItemCount()) { mixin(S_TRACE);
				return false;
			}
			auto itm = _cards.getItem(cast(int)index + cardsIndex);
			path = cpbottom(path);
			if (cpempty(path)) { mixin(S_TRACE);
				if (!cphasattr(path, "nofocus")) .forceFocus(_cards, shellActivate);
				selectImpl(itm);
				return true;
			} else { mixin(S_TRACE);
				cate = cpcategory(path);
				index = cpindex(path);
				return open(itm);
			}
		}
		switch (cate) {
		case "variable": { mixin(S_TRACE);
			if (!_flags) return false;
			return _flags.openCWXPath(.cpbottom(path), shellActivate);
		}
		case "event": { mixin(S_TRACE);
			return open(_cards.getItem(0));
		}
		case "playercard": { mixin(S_TRACE);
			path = cpbottom(path);
			if (cpempty(path)) {
				selectImpl(_cards.getItem(1));
				return true;
			} else { mixin(S_TRACE);
				cate = cpcategory(path);
				if (cate == "event") { mixin(S_TRACE);
					index = cpindex(path);
					return open(_cards.getItem(1));
				}
				return false;
			}
		}
		case "menucard": { mixin(S_TRACE);
			if (cast(Area)_area) { mixin(S_TRACE);
				return card();
			}
		} break;
		case "enemycard": { mixin(S_TRACE);
			if (cast(Battle)_area) { mixin(S_TRACE);
				return card();
			}
		} break;
		case "": { mixin(S_TRACE);
			.forceFocus(_cards, shellActivate);
			_comm.refreshToolBar();
			return true;
		}
		default: break;
		}
		return false;
	}
	@property
	string[] openedCWXPath() { mixin(S_TRACE);
		string[] r;
		auto etItm = selectionEventTree;
		if (!etItm) { mixin(S_TRACE);
			auto cardItm = selectionParent;
			if (cardItm) { mixin(S_TRACE);
				auto d = cardItm.getData();
				auto area = cast(EventTreeOwner)d;
				if (area) { mixin(S_TRACE);
					r ~= cpaddattr(area.cwxPath(true), "eventview");
				}
				if (cast(Area)_area || cast(Battle)_area) { mixin(S_TRACE);
					auto card = cast(AbstractSpCard)d;
					if (card) { mixin(S_TRACE);
						r ~= cpaddattr(card.cwxPath(true), "eventview");
					}
				}
			} else { mixin(S_TRACE);
				r ~= cpaddattr(_area.cwxPath(true), "eventview");
			}
		}
		r ~= _etree.openedCWXPath;
		return r;
	}
}
