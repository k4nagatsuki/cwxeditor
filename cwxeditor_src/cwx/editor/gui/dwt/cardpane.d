
module cwx.editor.gui.dwt.cardpane;

import cwx.card;
import cwx.summary;
import cwx.utils;
import cwx.usecounter;
import cwx.types;
import cwx.xml;
import cwx.skin;
import cwx.path;
import cwx.motion;
import cwx.menu;
import cwx.types;
import cwx.event;

import cwx.editor.gui.dwt.smalldialogs;
import cwx.editor.gui.dwt.images;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.cardlist;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.eventwindow;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.castcarddialog;
import cwx.editor.gui.dwt.effectcarddialog;
import cwx.editor.gui.dwt.infocarddialog;
import cwx.editor.gui.dwt.xmlbytestransfer;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.sbshell;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.cardpane;
import cwx.editor.gui.dwt.dmenu;

import std.algorithm;
import std.array;
import std.utf;
import std.string;
import std.datetime;
import std.typetuple;
import std.path;
import std.conv;

import org.eclipse.swt.all;

import java.lang.all;

private enum CViewMode {INIT, LIFE, CARD, TABLE}

private class CardPane(PCardOwner, CardOwner, C : Card, ToCardOwner) : TCPD {
private:
	static immutable EditMode = is (ToCardOwner == void);
	static immutable CanHold = is(CardOwner:CastCard) && (is(C:SkillCard) || is(C:ItemCard));
	private static C[] cardsFrom(CardOwner)(CardOwner owner) {
		static if (is(C:CastCard)) {
			return owner.casts;
		} else static if (is(C:SkillCard)) {
			return owner.skills;
		} else static if (is(C:ItemCard)) {
			return owner.items;
		} else static if (is(C:BeastCard)) {
			return owner.beasts;
		} else static if (is(C:InfoCard)) {
			return owner.infos;
		} else static assert (0);
	}
	@property
	public C[] cards() {return cardsFrom(owner);}
	@property
	private C[] __cards() {
		if (_owner) {
			return cards;
		}
		return [];
	}
	public C cardFrom(CardOwner)(CardOwner owner, ulong id) {
		static if (is(C:CastCard)) {
			return owner.cwCast(id);
		} else static if (is(C:SkillCard)) {
			return owner.skill(id);
		} else static if (is(C:ItemCard)) {
			return owner.item(id);
		} else static if (is(C:BeastCard)) {
			return owner.beast(id);
		} else static if (is(C:InfoCard)) {
			return owner.info(id);
		} else static assert (0);
	}
	public C card(ulong id) {
		return cardFrom(_owner, id);
	}
	private C __card(ulong id) {
		if (_owner) {
			return card(id);
		}
		return null;
	}
	@property
	private C[] pOwnerCards() {return cardsFrom(_summ);}
	private C pOwnerCard(ulong id) {return cardFrom(_summ, id);}
private:
	static if (EditMode) {
		static class CPUndo : Undo {
			protected CardPane _v = null;
			protected Commons comm;
			protected CardOwner owner;

			private ulong[] _ids;
			private ulong[] _idsB;
			private int _sel;
			private int _selB;

			this (CardPane v, Commons comm, CardOwner owner) {
				_v = v;
				this.comm = comm;
				this.owner = owner;

				saveIDs(v);
			}
			private void saveIDs(CardPane v) {
				_ids.length = 0;
				foreach (c; cardsFrom(owner)) _ids ~= c.id;
				if (v && v.widget && !v.widget.isDisposed()) {
					_sel = v.selectionIndex;
				}
			}
			abstract override void undo();
			abstract override void redo();
			abstract override void dispose();
			protected void udb(CardPane v) {
				_idsB = _ids.dup;
				_selB = _sel;
				saveIDs(v);
				if (v && v.widget && !v.widget.isDisposed()) {
					.forceFocus(v.widget, false);
				}
			}
			private void resetID(CardPane v) {
				ulong[] oldIDs;
				auto arr = cardsFrom(owner);
				foreach (i, c; arr) {
					auto oID = c.id;
					c.id = ulong.max - arr.length + i;
					comm.summary.useCounter.change(C.toID(oID), C.toID(c.id));
					oldIDs ~= oID;
				}
				foreach (i, c; arr) {
					auto oID = c.id;
					c.id = _idsB[i];
					comm.summary.useCounter.change(C.toID(oID), C.toID(c.id));
				}
				foreach (i, c; arr) {
					if (c.id != oldIDs[i]) {
						v.refCard(v, comm, c);
					}
				}
			}
			protected void uda(CardPane v) {
				resetID(v);
				if (v && v.widget && !v.widget.isDisposed()) {
					v.refresh();
					v.select(_selB);
					v.refreshStatusLine();
				}
				comm.refUseCount.call();
				comm.refreshToolBar();
			}
			protected CardPane view() {
				return _v;
			}
		}
		static class UndoIDs : CPUndo {
			this (CardPane v, Commons comm, CardOwner owner) {
				super (v, comm, owner);
			}
			override void undo() {
				auto v = view();
				udb(v);
				scope (exit) uda(v);
			}
			override void redo() {
				auto v = view();
				udb(v);
				scope (exit) uda(v);
			}
			override void dispose() {}
		}
		static class UndoEdit : CPUndo {
			private C _card;
			private int _index;
			this (CardPane v, Commons comm, CardOwner owner, int index) {
				super (v, comm, owner);
				auto c = cardsFrom(owner)[index];
				_card = new C(c.id, c.name, c.path, c.desc);
				_card.shallowCopy(c);
				_card.setUseCounter(comm.summary.useCounter.sub);
				_index = index;
			}
			private void impl() {
				auto v = view();
				udb(v);
				scope (exit) uda(v);
				auto card = _card;
				card.removeUseCounter();
				auto c = cardsFrom(owner)[_index];
				_card = new C(c.id, c.name, c.path, c.desc);
				_card.shallowCopy(c);
				_card.setUseCounter(comm.summary.useCounter.sub);
				c.shallowCopy(card);

				if (v && v.widget && !v.widget.isDisposed()) {
					v.refresh();
				}
				refCard(v, comm, c);
				comm.refUseCount.call();
			}
			override void undo() {
				impl();
			}
			override void redo() {
				impl();
			}
			override void dispose() {
				_card.removeUseCounter();
			}
		}
		void storeEdit(int index) {
			_undo ~= new UndoEdit(this, _comm, _owner, index);
		}
		static class UndoSwap : CPUndo {
			private int _index1, _index2;
			this (CardPane v, Commons comm, CardOwner owner, int index1, int index2) {
				super (v, comm, owner);
				_index1 = index1;
				_index2 = index2;
			}
			private void impl() {
				auto v = view();
				udb(v);
				scope (exit) uda(v);
				owner.swap!C(_index1, _index2);
				refCard(v, comm, cardsFrom(owner)[_index1]);
				refCard(v, comm, cardsFrom(owner)[_index2]);
			}
			override void undo() {
				impl();
			}
			override void redo() {
				impl();
			}
			override void dispose() {}
		}
		void storeSwap(int index1, int index2) {
			_undo ~= new UndoSwap(this, _comm, _owner, index1, index2);
		}
		static class UndoMove : CPUndo {
			private int _from, _to;
			this (CardPane v, Commons comm, CardOwner owner, int from, int to) {
				super (v, comm, owner);
				_from = from;
				_to = to;
			}
			private void impl() {
				auto v = view();
				udb(v);
				scope (exit) uda(v);
				auto card = cardsFrom(owner)[_to];
				int from = _from;
				if (_to <= from) from++;
				owner.insert(from, card);
				std.algorithm.swap(_from, _to);
			}
			override void undo() {
				impl();
			}
			override void redo() {
				impl();
			}
			override void dispose() {}
		}
		void storeMove(int from, int to) {
			_undo ~= new UndoMove(this, _comm, _owner, from, to);
		}
		static class UndoInsertDelete : CPUndo {
			private bool _insert;

			private int[] _indices;

			private C[] _cards = [];

			this (CardPane v, Commons comm, CardOwner owner, int[] indices, bool insert) {
				super (v, comm, owner);
				_insert = insert;
				_indices = indices.dup.sort;

				if (!insert) {
					initUndoDelete();
				}
			}
			private void initUndoDelete() {
				foreach (c; _cards) {
					c.removeUseCounter();
				}
				_cards.length = 0;
				foreach (index; _indices) {
					auto c = cardsFrom(owner)[index];
					auto card = c.dup;
					card.setUseCounter(comm.summary.useCounter.sub);
					_cards ~= card;
				}
			}
			private void undoInsert() {
				auto v = view();
				udb(v);
				scope (exit) uda(v);
				_insert = false;
				initUndoDelete();
				foreach_reverse (i, index; _indices) {
					auto card = cardsFrom(owner)[index];
					delImpl(v, comm, owner, card);
				}
				comm.refUseCount.call();
			}
			void undoDelete() {
				auto v = view();
				udb(v);
				scope (exit) uda(v);
				_insert = true;
				foreach (i, index; _indices) {
					auto c = _cards[i];
					c.removeUseCounter();
					owner.insert(index, c);
					refCard(v, comm, c);
				}
				if (v && v.widget && !v.widget.isDisposed()) {
					if (v._viewMode == CViewMode.TABLE) {
						foreach (i, c; _cards) {
							v.createTableItem(c, _indices[i]);
						}
						v._tbl.setSelection([_indices[$ - 1]]);
						v._tbl.showSelection();
					} else {
						v.refresh();
						v._list.select(_indices[$ - 1]);
						v._list.scroll(_indices[$ - 1]);
					}
					v.refreshStatusLine();
				}
				_cards.length = 0;
				comm.refUseCount.call();
			}
			override void undo() {
				if (_insert) {
					undoInsert();
				} else {
					undoDelete();
				}
			}
			override void redo() {
				undo();
			}
			override void dispose() {
				foreach (c; _cards) {
					c.removeUseCounter();
				}
			}
		}
		void storeInsert(int[] indices) {
			_undo ~= new UndoInsertDelete(this, _comm, _owner, indices, true);
		}
		void storeDelete(int[] indices) {
			_undo ~= new UndoInsertDelete(this, _comm, _owner, indices, false);
		}
	}

	string _id;
	Composite _parent;
	Commons _comm;
	Props _prop;
	static if (EditMode) {
		UndoManager _undo;
	}
	CardOwner _owner = null;
	PCardOwner _summ = null;
	void delegate(Shell) _save;
	CardList!(C) _list;
	Table _tbl;
	Image _cimg;
	CViewMode _viewMode = CViewMode.INIT;
	TCPD[] _tcpd;
	static if (!EditMode) {
		ToCardOwner _toc;
	}
	string _statusLine = "";

	void refreshStatusLine() {
		if (!_tbl || !_list || !_comm) return;
		if (_tbl.isDisposed()) return;
		if (_owner) {
			auto c = cards.length;
			auto s = selectedCards;
			static if (is(CardOwner:CastCard)) {
				static if (is (C == SkillCard)) {
					int vc = _prop.looks.skillCardMaxNum(owner.level);
				} else static if (is (C == ItemCard)) {
					int vc = _prop.looks.itemCardMaxNum(owner.level);
				} else static if (is (C == BeastCard)) {
					int vc = _prop.looks.beastCardMaxNum(owner.level);
				}
				if (1 == s.length) {
					_statusLine = .tryFormat(_prop.msgs.handCardStatusSelOne, c, vc, s[0].id);
				} else if (1 < s.length) {
					_statusLine = .tryFormat(_prop.msgs.handCardStatusSelMulti, c, vc, s.length);
				} else {
					_statusLine = .tryFormat(_prop.msgs.handCardStatus, c, vc);
				}
			} else {
				if (1 == s.length) {
					_statusLine = .tryFormat(_prop.msgs.cardStatusSelOne, c, s[0].id);
				} else if (1 < s.length) {
					_statusLine = .tryFormat(_prop.msgs.cardStatusSelMulti, c, s.length);
				} else {
					_statusLine = .tryFormat(_prop.msgs.cardStatus, c);
				}
			}
		} else {
			_statusLine = "";
		}
		_comm.setStatusLine(_tbl, _statusLine);
	}
	static if (EditMode) {
		void nameEditEnd(TableItem itm, int column, string newText) {
			auto c = cast(C) itm.getData();
			assert (c);
			storeEdit(itm.getParent().indexOf(itm));
			c.name = newText;
			refresh();
			refCard(c);
			_comm.refreshToolBar();
		}
	}
	void __refreshR(string from, string to) {
		__refresh();
	}
	void refresh(C c) {
		if (!_tbl || _tbl.isDisposed()) return;
		int i;
		for (i = 0; i < cards.length; i++) {
			bool targ = cards[i] is c;
			static if (is(CardOwner:CastCard) && is(typeof(c.linkId))) {
				if (cast(Summary) c.cwxParent && 0 != cards[i].linkId && cards[i].linkId is c.id) {
					targ = true;
				}
			}
			if (targ) {
				if (_viewMode == CViewMode.TABLE) {
					refreshTableItem(cards[i], _tbl.getItem(i));
				} else {
					refreshListItem(i, cards[i]);
				}
			}
		}
		refreshStatusLine();
	}
	void __refresh() {
		if (_viewMode == CViewMode.TABLE) {
			C sel = null;
			auto index = _tbl.getSelectionIndex();
			if (-1 != index) {
				sel = cast(C) _tbl.getItem(index).getData();
			}
			_tbl.removeAll();
			foreach (i, c; __cards) {
				createTableItem(c);
				if (sel is c) {
					_tbl.setSelection([i]);
				}
			}
			_tbl.showSelection();
		} else {
			_list.refresh(__cards, &cardImage);
			int sel = _list.selection;
			if (sel >= 0) {
				_list.scroll(sel);
			}
		}
		refreshStatusLine();
	}
	void createTableItem(C c, int index = -1) {
		auto itm = index >= 0
			? new TableItem(_tbl, SWT.NONE, index)
			: new TableItem(_tbl, SWT.NONE);
		refreshTableItem(c, itm);
	}
	void refreshListItem(int index, C card) {
		_list.refresh(index, card);
	}
	void refreshTableItem(C c, TableItem itm) {
		itm.setImage(0, _cimg);
		itm.setText(0, to!(string)(c.id));
		itm.setText(1, c.name);
		string desc = c.desc.singleLine;
		static if (is(C:EventTreeOwner)) {
			if (_prop.var.etc.showEventTreeMark && ((_prop.var.etc.ignoreEmptyStart ? !c.isEmpty : 0 < c.trees.length))) {
				itm.setImage(2, _prop.images.eventTree);
			} else {
				itm.setImage(2, null);
			}
		}
		itm.setText(2, desc);
		static if (EditMode && is (CardOwner == Summary)) {
			itm.setText(3, to!(string)(_summ.useCounter.get(C.toID(c.id))));
		}
		itm.setData(c);

		int w = textWidth(_prop, itm.getParent(), c.name);
		static if (is(C : CastCard)) {
			bool warn = w > _prop.looks.castNameLimit;
		} else static if (is(C : InfoCard)) {
			// 情報カード名はメッセージに表示されないため制限無し
			bool warn = false;
		} else {
			bool warn = w > _prop.looks.nameLimit;
		}
		itm.setImage(1, warn ? _prop.images.warning : null);
	}
	template CopyAndPaste() {
		override void cut(SelectionEvent se) {
			static if (EditMode) {
				copy(se);
				del(se);
			}
		}
		override void copy(SelectionEvent se) {
			auto cs = selectedCards;
			if (cs.length > 0) {
				XMLtoCB(_prop, _comm.clipboard, toXML(cs));
				_comm.refreshToolBar();
			}
		}
		override void paste(SelectionEvent se) {
			static if (EditMode) {
				auto c = CBtoXML(_comm.clipboard);
				try {
					if (c) {
						try {
							auto node = XNode.parse(c);
							if (node.name != C.XML_NAME_M) return;
							addFromNode(node, LATEST_VERSION);
						} catch {}
					}
					refreshStatusLine();
					_comm.refreshToolBar();
				} catch (Exception e) {
					debugln(e);
				}
			}
		}
		override void clone(SelectionEvent se) {
			_comm.clipboard.memoryMode = true;
			scope (exit) _comm.clipboard.memoryMode = false;
			copy(se);
			paste(se);
		}
		@property
		override bool canDoTCPD() {
			return _summ && widget.isFocusControl();
		}
		@property
		override bool canDoT() {
			return selectedCards.length > 0;
		}
		@property
		override bool canDoC() {
			return canDoT;
		}
		@property
		override bool canDoP() {
			return _summ !is null && CBisXML(_comm.clipboard);
		}
		@property
		override bool canDoD() {
			return canDoT;
		}
		@property
		override bool canDoClone() {
			return canDoC;
		}
	}
	static if (EditMode) {
		static void delImpl(CardPane v, Commons comm, CardOwner owner, C card) {
			if (!card) return;
			int index = cCountUntil!("a is b")(cardsFrom(owner), card);
			owner.remove(card);
			if (v && v.widget && !v.widget.isDisposed()) {
				if (v._viewMode == CViewMode.TABLE) {
					v._tbl.remove(index);
					v._tbl.redraw();
				} else {
					v.refresh();
				}
			}
			delCard(v, comm, owner, card);
		}
	}
	class CL : TCPD {
		@property
		CardList!(C) widget() {
			return _list;
		}
		@property
		C selectionCard() {
			return _list.selectionCard;
		}
		mixin CopyAndPaste;
		override void del(SelectionEvent se) {
			static if (EditMode) {
				auto c = selectionCard;
				if (c) {
					storeDelete([_list.selection]);
					_owner.remove(c);
					refresh();
					delCard(c);
					_comm.refreshToolBar();
				}
			}
		}
	}

	void refCard(C c) {
		refCard(this, _comm, c);
	}
	static void refCard(CardPane v, Commons comm, C c) {
		static if (is (C == CastCard)) {
			comm.refCast.call(v, c);
		} else static if (is (C == SkillCard)) {
			comm.refSkill.call(v, c);
		} else static if (is (C == ItemCard)) {
			comm.refItem.call(v, c);
		} else static if (is (C == BeastCard)) {
			comm.refBeast.call(v, c);
		} else static if (is (C == InfoCard)) {
			comm.refInfo.call(v, c);
		} else {
			static assert (0);
		}
		if (v && v.widget && !v.widget.isDisposed()) {
			v.refreshStatusLine();
		}
	}
	void delCard(C c) {
		delCard(this, _comm, _owner, c);
	}
	static void delCard(CardPane v, Commons comm, CardOwner owner, C c) {
		static if (is (C == CastCard)) {
			foreach (hc; c.skills) {
				comm.delSkill.call(hc);
			}
			foreach (hc; c.items) {
				comm.delItem.call(hc);
			}
			foreach (hc; c.beasts) {
				comm.delBeast.call(hc);
			}
			comm.delCast.call(c);
		} else static if (is (C == SkillCard)) {
			comm.delSkill.call(c);
		} else static if (is (C == ItemCard)) {
			comm.delItem.call(c);
		} else static if (is (C == BeastCard)) {
			comm.delBeast.call(c);
		} else static if (is (C == InfoCard)) {
			comm.delInfo.call(c);
		} else {
			static assert (0);
		}
		comm.refUseCount.call();
		static if (is (CardOwner : CastCard) && is (C : BeastCard)) {
			comm.refCast.call(owner);
		}
		if (v && v.widget && !v.widget.isDisposed()) {
			v.refreshStatusLine();
		}
	}
	class CT : TCPD {
		@property
		Table widget() {
			return _tbl;
		}
		@property
		C selectionCard() {
			auto i = _tbl.getSelectionIndex();
			return -1 != i ? cast(C) _tbl.getItem(i).getData() : null;
		}
		mixin CopyAndPaste;
		override void del(SelectionEvent se) {
			static if (EditMode) {
				auto c = selectionCard;
				if (c) {
					int i = _tbl.getSelectionIndex();
					if (-1 == i) return;
					storeDelete([i]);
					_owner.remove(c);
					_tbl.getItem(i).dispose();
					_tbl.redraw();
					delCard(c);
					_comm.refreshToolBar();
				}
			}
		}
	}
	static if (EditMode) {
		template Drop() {
			override void drop(DropTargetEvent e){
				if (!isXMLBytes(e.data)) return;
				e.detail = DND.DROP_NONE;
				string xml = bytesToXML(e.data);
				try {
					auto node = XNode.parse(xml);
					if (node.name != C.XML_NAME_M) return;
					scope p = (cast(DropTarget) e.getSource()).getControl().toControl(e.x, e.y);
					int index = indexOf(p);
					bool samePane = _id == node.attr("paneId", false);
					bool sameSc = ownerId == node.attr("summId", false);
					bool topLevel = node.attr!bool("topLevel", false, false);
					ulong[C] oldIDs;
					foreach (card; cards) oldIDs[card] = card.id;
					scope (exit) {
						foreach (card; cards) {
							auto pc = card in oldIDs;
							if (pc && *pc != card.id) refCard(card); 
						}
						_comm.refreshToolBar();
					}
					if (sameSc && samePane) {
						// 同一リスト内で移動。
						int count = cardCount;
						if (count < index) index = count;
						if ((index < count ? index : count - 1) == selectionIndex
								|| index == selectionIndex + 1) {
							selectOnly(index);
							return;
						}
						C[] adds;
						node.onTag[C.XML_NAME] = (ref XNode cNode) {
							auto id = Card.readId(cNode);
							if (id == 0UL) return;
							adds ~= this.outer.__card(id);
							e.detail = DND.DROP_NONE;
						};
						node.parse();
						if (adds.length == 0) return;
						assert (adds.length == 1);
						auto card = adds[0];
						int oldIndex = _owner.indexOf!C(card);
						storeMove(oldIndex, oldIndex < index ? index - 1 : index);
						_owner.insert(index, card);
						insert(card, true);
						refreshStatusLine();
					} else {
						e.detail = DND.DROP_NONE;
						// 他のリストからのコピー
						if (cardCount < index) index = cardCount;
						C[] adds;
						node.onTag[C.XML_NAME] = (ref XNode cNode) {
							auto card = C.createFromNode(cNode, LATEST_VERSION);
							adds ~= card;
						};
						node.parse();
						if (adds.length == 0) return;
						if (qCardMaterialCopy(node, adds)) {
							int[] indices;
							foreach (i, card; adds) {
								refreshLink(card, samePane, sameSc, topLevel);
								_owner.insert(index, card);
								adds[i] = cards[index];
								indices ~= index;
								index++;
							}
							storeInsert(indices);
							insert(adds[$ - 1], false);
							_comm.refUseCount.call();
							refreshStatusLine();
						}
					}
				} catch (Exception e) {
					debugln(e);
				}
			}
		}
		void refreshLink(ref C card, bool samePane, bool sameSc, bool topLevel) {
			static if (is(typeof(card.linkId))) {
				if (sameSc && !is(CardOwner:CastCard) && 0 != card.linkId) {
					card = pOwnerCard(card.linkId);
					if (card) {
						card = card.dup;
					} else {
						card = new C(1UL, "", "", "");
					}
				} else if (sameSc && is(CardOwner:CastCard) && topLevel && _prop.var.etc.linkCard) {
					auto id = card.id;
					card = new C(1UL, "", "", "");
					card.linkId = id;
				}
			}
		}
		class CLDTListener : DropTargetAdapter {
			override void dragEnter(DropTargetEvent e){
				e.detail = DND.DROP_MOVE;
			}
			override void dragOver(DropTargetEvent e){
				e.detail = DND.DROP_MOVE;
			}
			mixin Drop;
			@property
			private int selectionIndex() {
				return _list.selection;
			}
			private int indexOf(Point p) {
				return _list.searchIndexLoose(p.x, p.y);
			}
			@property
			private int cardCount() {
				return _list.count;
			}
			private void selectOnly(int index) {
				_list.scroll(index);
			}
			private void insert(C c, bool move) {
				refresh();
				int index = _list.indexOf(c);
				_list.select(index);
				_list.scroll(index);
				refreshStatusLine();
			}
		}
		class CTDTListener : DropTargetAdapter {
			override void dragEnter(DropTargetEvent e){
				e.detail = DND.DROP_MOVE;
			}
			override void dragOver(DropTargetEvent e){
				e.detail = DND.DROP_MOVE;
			}
			mixin Drop;
			@property
			private int selectionIndex() {
				return _tbl.getSelectionIndex();
			}
			private int indexOf(Point p) {
				auto itm = _tbl.getItem(p);
				return itm ? _tbl.indexOf(itm) : _tbl.getItemCount();
			}
			@property
			private int cardCount() {
				return _tbl.getItemCount();
			}
			private void selectOnly(int index) {
				_tbl.showSelection();
			}
			private void insert(C c, bool move) {
				refresh();
				foreach (i, itm; _tbl.getItems()) {
					if (c is itm.getData()) {
						_tbl.setSelection([i]);
						_tbl.showSelection();
						return;
					}
				}
				assert (0);
			}
		}
	}
	class CDSListener : DragSourceAdapter {
		override void dragStart(DragSourceEvent e) {
			e.doit = (cast(DragSource) e.getSource()).getControl().isFocusControl()
				&& selectedCards.length > 0;
		}
		override void dragSetData(DragSourceEvent e){
			if (XMLBytesTransfer.getInstance().isSupportedType(e.dataType)) {
				Control c = (cast(DragSource) e.getSource()).getControl();
				C[] sels = selectedCards;
				if (sels.length > 0) {
					e.data = bytesFromXML(toXML(sels));
				}
			}
		}
	}
	bool qCardMaterialCopy(in XNode node, C[] cs) {
		string fromSPath = node.attr("scenarioPath", false);
		if (fromSPath.length > 0 && !cfnmatch(fromSPath, nabs(ownerScenarioPath))) {
			scope uc = new UseCounter;
			foreach (c; cs) {
				c.setUseCounter(uc);
			}
			bool copy;
			bool r = qMaterialCopy(_comm, dlgParShl,
				uc, _summ.scenarioPath, fromSPath, copy, _summ.legacy);
			foreach (c; cs) {
				c.removeUseCounter();
			}
			if (copy) {
				_comm.refPaths.call(_comm.skin.materialPath);
			}
			return r;
		}
		return true;
	}

	@property
	Shell dlgParShl() {
		if (_list && !_list.isDisposed()) return _list.getShell();
		return _comm.mainWin.shell.getShell();
	}

	@property
	string ownerScenarioPath() {
		static if (is (CardOwner == CastCard)) {
			return _summ.scenarioPath;
		} else {
			return _owner.scenarioPath;
		}
	}
	@property
	string ownerId() {
		static if (is (CardOwner == CastCard)) {
			return _summ.id;
		} else {
			return _owner.id;
		}
	}
	private Skin _skinTemp = null;
	ImageData cardImage(C c) {
		Skin skin = _skinTemp ? _skinTemp : _comm.skin;
		auto detail = _viewMode == CViewMode.LIFE;
		static if (is (C == CastCard)) {
			return castCardImage(_prop, skin, c, ownerScenarioPath, detail);
		} else static if (!is (C == InfoCard) && is (CardOwner == CastCard)) {
			return .cardImage!(C)(_prop, skin, c, ownerScenarioPath, _owner, &pOwnerCard, detail);
		} else {
			return .cardImage!(C)(_prop, skin, c, ownerScenarioPath, cast(CastCard) null, &pOwnerCard, detail);
		}
	}

	void refreshIDs() {
		if (_viewMode == CViewMode.TABLE) {
			foreach (i, c; cards) {
				_tbl.getItem(i).setText(0, to!(string)(c.id));
			}
		}
	}

	void __refList() {
		auto sels = _tbl.getSelectionIndices();
		int index = _tbl.getSelectionIndex();
		refresh();
		if (-1 != index) {
			_list.selectionIndices(sels);
			_list.scroll(index);
		} else {
			_list.deselectAll();
		}
		refreshStatusLine();
	}
	void __refTbl() {
		auto sels = _list.selectionIndices;
		refresh();
		if (sels.length > 0) {
			_tbl.setSelection(sels);
			_tbl.showSelection();
		}
		refreshStatusLine();
	}
	void toNode(ref XNode sn, C[] sels) {
		if (!sels.length) return;
		if (cast(Object) sels[0].cwxParent is _summ) {
			sn.newAttr("summId", _summ.id);
			sn.newAttr("paneId", _id);
			sn.newAttr("topLevel", true);
		} else {
			sn.newAttr("summId", ownerId);
			sn.newAttr("paneId", _id);
			sn.newAttr("topLevel", false);
		}
		sn.newAttr("scenarioPath", nabs(ownerScenarioPath));
		auto opt = new XMLOption;
		static if (!is(ToCardOwner == void)) {
			if (1 == _prop.var.etc.importLinkCondition) {
				// 参照先を格納
				opt.includeCard = true;
				opt.noLinkId = true;
				opt.skill = &_summ.skill;
				opt.item = &_summ.item;
				opt.beast = &_summ.beast;
			}
		}
		foreach (sel; sels) {
			sel.toNode(sn, opt);
		}
	}
	string toXML(C[] sels) {
		auto doc = XNode.create(C.XML_NAME_M);
		toNode(doc, sels);
		return doc.text;
	}
	static if (EditMode) {
		private void editM() {
			edit();
		}
		private bool canEdit() {
			auto c = selection;
			if (!c) return false;
			static if (is(typeof(c.linkId))) {
				if (0 != c.linkId && !pOwnerCard(c.linkId)) return false;
			}
			return true;
		}
	}
	class LMouse : MouseAdapter {
		static if (EditMode && is(C:EventTreeOwner)) {
			override void mouseDown(MouseEvent e) {
				if (e.button != 2) return;
				int index = _list.selection;
				if (index >= 0) {
					scope p = _list.toControl(e.x, e.y);
					if (_list.getBounds(index).contains(e.x, e.y)) {
						editUseEvent(_list.card(index));
					}
				}
			}
		}
		override void mouseDoubleClick(MouseEvent e) {
			if (e.button != 1) return;
			int index = _list.selection;
			if (index >= 0) {
				scope p = _list.toControl(e.x, e.y);
				if (_list.getBounds(index).contains(e.x, e.y)) {
					static if (EditMode) {
						edit(_list.card(index));
					} else {
						addCard();
					}
				}
			}
		}
	}
	class TMouse : MouseAdapter {
		static if (EditMode && is(C:EventTreeOwner)) {
			override void mouseDown(MouseEvent e) {
				if (e.button != 2) return;
				scope p = new Point(e.x, e.y);
				auto itm = _tbl.getItem(p);
				if (!itm) return;
				editUseEvent(cast(C) itm.getData());
			}
		}
		override void mouseDoubleClick(MouseEvent e) {
			if (e.button != 1) return;
			scope p = new Point(e.x, e.y);
			auto itm = _tbl.getItem(p);
			if (!itm) return;
			static if (EditMode) {
				edit(cast(C) itm.getData());
			} else {
				addCard();
			}
		}
	}
	class LKey : KeyAdapter {
		override void keyPressed(KeyEvent e) {
			static if (EditMode) {
				bool keyMatch = (e.keyCode == SWT.F2 && _viewMode != CViewMode.TABLE) || e.character == SWT.CR;
			} else {
				bool keyMatch = e.character == SWT.CR;
			}
			if (keyMatch && _list.selection >= 0) {
				static if (EditMode) {
					edit(_list.selectionCard);
				} else {
					addCard();
				}
			}
		}
	}
	class TKey : KeyAdapter {
		override void keyPressed(KeyEvent e) {
			static if (EditMode) {
				bool keyMatch = (e.keyCode == SWT.F2 && _viewMode != CViewMode.TABLE) || e.character == SWT.CR;
			} else {
				bool keyMatch = e.character == SWT.CR;
			}
			int i = _tbl.getSelectionIndex();
			if (keyMatch && -1 != i) {
				static if (EditMode) {
					edit(cast(C) _tbl.getItem(i).getData());
				} else {
					addCard();
				}
			}
		}
	}
	private class SelChanged : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			selectChanged();
		}
	}
	static if (EditMode && is(CardOwner : Summary)) {
		private bool _procRefColW = false;
		void refColumnWidth(TableColumn c, int width) {
			if (_procRefColW) return;
			if (!_tbl || _tbl.isDisposed()) return;
			if (_tbl is c.getParent()) return;
			int i = c.getParent().indexOf(c);
			auto col = _tbl.getColumn(i);
			col.setWidth(width);
		}
		class DisposeTable : DisposeListener {
			override void widgetDisposed(DisposeEvent e) {
				_comm.refCardTableColumnWidth.remove(&refColumnWidth);
			}
		}
		class ColResize(string WidthPropName) : ControlAdapter {
			override void controlResized(ControlEvent e) {
				if (_procRefColW) return;
				_procRefColW = true;
				scope (exit) _procRefColW = false;
				auto col = cast(TableColumn) e.widget;
				int width = col.getWidth();
				_comm.refCardTableColumnWidth.call(col, width);
				mixin("_prop.var.etc." ~ WidthPropName ~ " = width;");
			}
		}
	}
	void selectChanged() {
		refreshStatusLine();
		_comm.refreshToolBar();
	}
	static if (!EditMode) {
		void selectAll() {
			if (_viewMode == CViewMode.TABLE) {
				foreach (i; 0 .. _tbl.getItemCount()) {
					_tbl.select(i);
				}
			} else {
				foreach (i; 0 .. _list.count()) {
					_list.select(i);
				}
			}
			selectChanged();
		}
		@property
		int selectionCount() {
			if (_viewMode == CViewMode.TABLE) {
				return _tbl.getSelectionCount();
			} else {
				return _list.selectionCount;
			}
		}
	}
	void createCardList(Composite parent) {
		_list = new CardList!(C)(parent, SWT.VIRTUAL | SWT.V_SCROLL | (EditMode ? SWT.SINGLE : SWT.MULTI) | SWT.BORDER);
		_list.setLayoutValues(_prop.var.etc.cardsMarginX, _prop.var.etc.cardsSpaceX,
			_prop.var.etc.cardsMarginY, _prop.var.etc.cardsSpaceY, _prop.var.etc.cardsDefaultWrap);
		_list.selectChanged(&selectChanged);
		_tbl = new Table(parent, SWT.FULL_SELECTION | (EditMode ? SWT.SINGLE : SWT.MULTI) | SWT.BORDER);
		_tbl.addSelectionListener(new SelChanged);
		_tbl.setHeaderVisible(true);
		auto idCol = new TableColumn(_tbl, SWT.NONE);
		idCol.setText(_prop.msgs.cardId);
		idCol.setWidth(_prop.var.etc.cardIdColumn);
		static if (EditMode && is(CardOwner : Summary)) {
			idCol.addControlListener(new ColResize!("cardIdColumn"));
		}
		auto nameCol = new TableColumn(_tbl, SWT.NONE);
		nameCol.setText(_prop.msgs.cardName);
		nameCol.setWidth(_prop.var.etc.cardNameColumn);
		static if (EditMode && is(CardOwner : Summary)) {
			nameCol.addControlListener(new ColResize!("cardNameColumn"));
		}
		auto descCol = new TableColumn(_tbl, SWT.NONE);
		descCol.setText(_prop.msgs.cardDesc);
		descCol.setWidth(_prop.var.etc.cardDescriptionColumn);
		static if (EditMode && is(CardOwner : Summary)) {
			descCol.addControlListener(new ColResize!("cardDescriptionColumn"));
		}
		static if (EditMode && is (CardOwner == Summary)) {
			auto ucCol = new TableColumn(_tbl, SWT.NONE);
			ucCol.setText(_prop.msgs.cardCount);
			ucCol.setWidth(_prop.var.etc.cardCountColumn);
			ucCol.addControlListener(new ColResize!("cardCountColumn"));
		}
		static if (EditMode && is(CardOwner : Summary)) {
			_comm.refCardTableColumnWidth.add(&refColumnWidth);
			_tbl.addDisposeListener(new DisposeTable);
		}
		static if (EditMode) {
			new TableTextEdit(_comm, _prop, _tbl, 1, &nameEditEnd, null);
		}

		static if (is (C == CastCard)) {
			auto matPad = _prop.looks.castCardInsets;
		} else {
			auto matPad = _prop.looks.menuCardInsets;
		}
		auto cl_ = new CL;
		_tcpd ~= cl_;
		int w = _prop.looks.cardSize.width + matPad.e + matPad.w;
		int h = _prop.looks.cardSize.height + matPad.n + matPad.s;
		_list.setCardSize(w, h);

		auto ct_ = new CT;
		_tcpd ~= ct_;

		void setupDrag(Control c) {
			auto drag = new DragSource(c, DND.DROP_MOVE | DND.DROP_COPY | DND.DROP_LINK);
			drag.setTransfer([XMLBytesTransfer.getInstance()]);
			drag.addDragListener(new CDSListener);
		}
		setupDrag(_list);
		setupDrag(_tbl);

		_list.addMouseListener(new LMouse);
		_list.addKeyListener(new LKey);
		_tbl.addMouseListener(new TMouse);
		_tbl.addKeyListener(new TKey);
		static if (EditMode) {
			auto dropL = new DropTarget(_list, DND.DROP_DEFAULT | DND.DROP_MOVE);
			dropL.setTransfer([XMLBytesTransfer.getInstance()]);
			dropL.addDropListener(new CLDTListener);
			auto dropT = new DropTarget(_tbl, DND.DROP_DEFAULT | DND.DROP_MOVE);
			dropT.setTransfer([XMLBytesTransfer.getInstance()]);
			dropT.addDropListener(new CTDTListener);
		}
		__refList();
	}
	static if (EditMode) {
		void refScenario(Summary summ) {
			_undo.reset();
		}
	}
	static if (is (C == CastCard) && !EditMode) {
		private void delegate() _openHand;
	}
	static if (EditMode) {
		void refUndoMax() {
			_undo.max = _prop.var.etc.undoMaxMainView;
		}
	}
	private void construct1(Commons comm, Props prop, PCardOwner summ) {
		_id = format("%08X", &this) ~ "-" ~ to!(string)(Clock.currTime());
		_comm = comm;
		_prop = prop;
		_summ = summ;
		static if (EditMode) {
			_undo = new UndoManager(_prop.var.etc.undoMaxMainView);
		}
		static if (is (C == CastCard)) {
			_cimg = prop.images.casts;
		} else static if (is (C == SkillCard)) {
			_cimg = prop.images.skill;
		} else static if (is (C == ItemCard)) {
			_cimg = prop.images.item;
		} else static if (is (C == BeastCard)) {
			_cimg = prop.images.beast;
		} else static if (is (C == InfoCard)) {
			_cimg = prop.images.info;
		}
	}
	static if (CanHold && EditMode) {
		void hold(SelectionEvent e) {
			auto card = selection;
			if (!card) return;
			auto mi = cast(MenuItem) e.widget;
			if (card.hold is mi.getSelection()) return;
			storeEdit(_owner.indexOf(card));
			card.hold = mi.getSelection();
			refresh();
		}
	}
	static if (is(CardOwner:CastCard) && EditMode) {
		Menu _addHandMenu;
		void refAddHandMenu(C card) {
			createMenuItem2(_comm, _addHandMenu, .format("%s.%s", card.id, card.name), _cimg, {
				.forceFocus(widget, false);
				auto doc = XNode.create(C.XML_NAME_M);
				toNode(doc, [card]);
				addFromNode(doc, LATEST_VERSION);
			}, null);
		}
		void refreshAddHand() {
			if (!_summ) return;
			foreach (itm; _addHandMenu.getItems()) {
				itm.dispose();
			}
			foreach (card; pOwnerCards) {
				refAddHandMenu(card);
			}
		}
		void removeRef() {
			auto card = selection;
			if (!card || 0 == card.linkId) return;
			auto targ = pOwnerCard(card.linkId);
			if (!targ) return;
			auto id = card.id;
			static if (is(typeof(card.hold))) auto hold = card.hold;
			card.deepCopy(targ);
			card.id = id;
			card.linkId = 0;
			static if (is(typeof(card.hold))) card.hold = hold;

			refresh();
			refCard(card);
			_comm.refreshToolBar();
		}
	}
public:
	static if (!EditMode) {
		static if (is (C == CastCard)) {
			this (Commons comm, Props prop, PCardOwner summ, Composite parent, ToCardOwner toc, void delegate() openHand) {
				_parent = parent;
				_toc = toc;
				_openHand = openHand;
				_skinTemp = comm.findSkinFromHistory(summ);
				construct1(comm, prop, summ);
			}
		} else {
			this (Commons comm, Props prop, PCardOwner summ, Composite parent, ToCardOwner toc) {
				_parent = parent;
				_toc = toc;
				_skinTemp = comm.findSkinFromHistory(summ);
				construct1(comm, prop, summ);
			}
		}
		void construct() {
			reconstruct(_parent);
		}
	} else static if (is (C : Card)) {
		this (Commons comm, Props prop, PCardOwner summ, Composite parent) {
			_parent = parent;
			construct1(comm, prop, summ);
		}
		void construct() {
			reconstruct(_parent);
		}
	} else {
		static assert (0);
	}

	static if (EditMode && is(C:EventTreeOwner)) {
		void refEventTree(EventTree et) {
			if (cast(C) et.owner || et.owner is null) {
				__refresh();
			}
		}
	}
	void reconstruct(Composite parent) {
		_parent = parent;
		createCardList(parent);
		_comm.refCardImageStatus.add(&__refresh);
		.listener(_list, SWT.Dispose, {
			_comm.refCardImageStatus.remove(&__refresh);
		});
		static if (EditMode && is(C:EventTreeOwner)) {
			_comm.refEventTree.add(&refEventTree);
			_comm.delEventTree.add(&refEventTree);
			.listener(_list, SWT.Dispose, {
				_comm.refEventTree.remove(&refEventTree);
				_comm.delEventTree.remove(&refEventTree);
			});
		}
		static if (EditMode && is(PCardOwner == Summary)) {
			_comm.refSkin.add(&__refresh);
			_comm.delPaths.add(&__refresh);
			_comm.replPath.add(&__refreshR);
			_comm.replText.add(&__refresh);
			_list.addDisposeListener(new class DisposeListener {
				override void widgetDisposed(DisposeEvent e) {
					_comm.refSkin.remove(&__refresh);
					_comm.delPaths.remove(&__refresh);
					_comm.replPath.remove(&__refreshR);
					_comm.replText.remove(&__refresh);
				}
			});
		}
		static if (EditMode && is (CardOwner == Summary)) {
			_comm.refUseCount.add(&__refreshUseCount);
			_list.addDisposeListener(new class DisposeListener {
				override void widgetDisposed(DisposeEvent e) {
					_comm.refUseCount.remove(&__refreshUseCount);
				}
			});
		}
		static if (EditMode) {
			_comm.refScenario.add(&refScenario);
			static if (is (C == CastCard)) {
				_comm.refCast.add(&refCardCallback);
			} else static if (is (C == SkillCard)) {
				_comm.refSkill.add(&refCardCallback);
			} else static if (is (C == ItemCard)) {
				_comm.refItem.add(&refCardCallback);
			} else static if (is (C == BeastCard)) {
				_comm.refBeast.add(&refCardCallback);
			} else static if (is (C == InfoCard)) {
				_comm.refInfo.add(&refCardCallback);
			}
			_comm.refUndoMax.add(&refUndoMax);
			_list.addDisposeListener(new class DisposeListener {
				override void widgetDisposed(DisposeEvent e) {
					_comm.refScenario.remove(&refScenario);
					static if (is (C == CastCard)) {
						_comm.refCast.remove(&refCardCallback);
					} else static if (is (C == SkillCard)) {
						_comm.refSkill.remove(&refCardCallback);
					} else static if (is (C == ItemCard)) {
						_comm.refItem.remove(&refCardCallback);
					} else static if (is (C == BeastCard)) {
						_comm.refBeast.remove(&refCardCallback);
					} else static if (is (C == InfoCard)) {
						_comm.refInfo.remove(&refCardCallback);
					}
					_comm.refUndoMax.remove(&refUndoMax);
					foreach (w; _editDlgs.values) {
						w.forceCancel();
					}
				}
			});
			auto pop = new Menu(parent.getShell(), SWT.POP_UP);
			static if (is (C == CastCard)) {
				createMenuItem(_comm, pop, MenuID.EditProp, &editM, &canEdit);
				new MenuItem(pop, SWT.SEPARATOR);
				createMenuItem(_comm, pop, MenuID.OpenHand, &editHand, &canEdit);
			} else static if (is (C == SkillCard) || is (C == ItemCard) || is (C == BeastCard)) {
				createMenuItem(_comm, pop, MenuID.EditProp, &editM, &canEdit);
				new MenuItem(pop, SWT.SEPARATOR);
				createMenuItem(_comm, pop, MenuID.EditEventAtTimeOfUsing, &editUseEvent, &canEdit);
			} else static if (is (C == InfoCard)) {
				createMenuItem(_comm, pop, MenuID.EditProp, &editM, &canEdit);
			} else {
				static assert (0);
			}
			static if (CanHold && EditMode) {
				new MenuItem(pop, SWT.SEPARATOR);
				auto holdMI = createMenuItem(_comm, pop, MenuID.Hold, &hold, () => selection !is null, SWT.CHECK);
				.listener(pop, SWT.Show, {
					auto card = selection;
					holdMI.setSelection(card && card.hold);
				});
			}
			static if (is(CardOwner:CastCard) && EditMode) {
				new MenuItem(pop, SWT.SEPARATOR);
				void delegate(SelectionEvent) dummy = null;
				auto addHandMI = createMenuItem(_comm, pop, MenuID.AddHand, dummy, () => _owner && _summ && pOwnerCards.length, SWT.CASCADE);
				_addHandMenu = new Menu(addHandMI);
				addHandMI.setMenu(_addHandMenu);
				new MenuItem(pop, SWT.SEPARATOR);
				createMenuItem(_comm, pop, MenuID.RemoveRef, &removeRef, () => selection && 0 != selection.linkId && pOwnerCard(selection.linkId));
			}
			new MenuItem(pop, SWT.SEPARATOR);
			createMenuItem(_comm, pop, MenuID.Undo, &undo, &_undo.canUndo);
			createMenuItem(_comm, pop, MenuID.Redo, &redo, &_undo.canRedo);
			new MenuItem(pop, SWT.SEPARATOR);
			appendMenuTCPD(_comm, pop, this, true, true, true, true, true);
			new MenuItem(pop, SWT.SEPARATOR);
			createMenuItem(_comm, pop, MenuID.ReNumbering, &reNumbering, () => selection !is null);
		} else {
			auto pop = new Menu(parent.getShell(), SWT.POP_UP);
			static if (is (C == CastCard)) {
				createMenuItem(_comm, pop, MenuID.OpenHand, _openHand, () => selection !is null);
				new MenuItem(pop, SWT.SEPARATOR);
			}
			createMenuItem(_comm, pop, MenuID.Import, &addCard, () => selection !is null);
			new MenuItem(pop, SWT.SEPARATOR);
			appendMenuTCPD(_comm, pop, this, false, true, false, false, false);
			new MenuItem(pop, SWT.SEPARATOR);
			createMenuItem(_comm, pop, MenuID.SelectAll, &selectAll, () => cards.length && selectionCount != cards.length);
		}
		_list.setMenu(pop);
		_tbl.setMenu(pop);
		refreshStatusLine();
	}

	@property
	CardOwner owner() {
		return _owner;
	}
	@property
	PCardOwner summary() {
		return _summ;
	}
	@property
	Control widget() {
		if (_viewMode == CViewMode.TABLE) {
			return _tbl;
		} else {
			return _list;
		}
	}
	@property
	string statusLine() {return _statusLine;}

	void refresh() {
		if (!_tbl || _tbl.isDisposed()) return;
		if (_owner) {
			__refresh();
		}
		refreshStatusLine();
	}
	static if (EditMode){
		private void refCardCallback(Object sender, C c) {
			if (sender is this) return;
			static if (is(CardOwner:CastCard) && EditMode) {
				refreshAddHand();
			}
			refresh(c);
		}
	}
	void showCardLife() {
		if (_viewMode != CViewMode.LIFE) {
			_viewMode = CViewMode.LIFE;
			__refList();
		}
	}
	void showCardList() {
		if (_viewMode != CViewMode.CARD) {
			_viewMode = CViewMode.CARD;
			__refList();
		}
	}
	void showCardTable() {
		if (_viewMode != CViewMode.TABLE) {
			_viewMode = CViewMode.TABLE;
			__refTbl();
		}
	}

	@property
	void select(int index) {
		if (!_tbl || _tbl.isDisposed()) return;
		if (_viewMode == CViewMode.TABLE) {
			if (-1 == index) {
				_tbl.deselectAll();
			} else {
				_tbl.select(index);
				_tbl.showSelection();
			}
		} else {
			if (-1 == index) {
				_list.deselectAll();
			} else {
				_list.select(index);
				_list.scroll(index);
			}
		}
		refreshStatusLine();
	}
	@property
	C[] selectedCards() {
		if (_viewMode == CViewMode.TABLE) {
			C[] r;
			auto sels = _tbl.getSelection();
			r.length = sels.length;
			foreach (i, itm; sels) {
				r[i] = cast(C) sels[i].getData();
			}
			return r;
		} else {
			return _list.selectionCards;
		}
	}
	@property
	int selectionIndex() {
		if (!_summ) return -1;
		if (_viewMode == CViewMode.TABLE) {
			return _tbl.getSelectionIndex();
		} else {
			return _list.selection;
		}
	}
	@property
	C selection() {
		if (!_summ) return null;
		if (_viewMode == CViewMode.TABLE) {
			int i = _tbl.getSelectionIndex();
			return -1 != i ? cast(C) _tbl.getItem(i).getData() : null;
		} else {
			return _list.selectionCard;
		}
	}

	static if (EditMode) {
		void open(bool shellActivate) {
			static if (is(CardOwner : Summary)) {
				static if (is(C : CastCard)) {
					_comm.openCastWin(shellActivate);
				} else static if(is(C : SkillCard)) {
					_comm.openSkillWin(shellActivate);
				} else static if(is(C : ItemCard)) {
					_comm.openItemWin(shellActivate);
				} else static if(is(C : BeastCard)) {
					_comm.openBeastWin(shellActivate);
				} else static if(is(C : InfoCard)) {
					_comm.openInfoWin(shellActivate);
				} else static assert (0);
			} else static if (is(CardOwner : CastCard)) {
				auto cWin = _comm.handCardWindowFrom(_prop, _summ, _owner, true, shellActivate);
				static if(is(C : SkillCard)) {
					cWin.open!(cWin.SKILL)(shellActivate);
				} else static if (is(C : ItemCard)) {
					cWin.open!(cWin.ITEM)(shellActivate);
				} else static if (is(C : BeastCard)) {
					cWin.open!(cWin.BEAST)(shellActivate);
				}
			} else static assert (0);
			_comm.refreshToolBar();
		}
		void create() {
			static if (is (C == CastCard)) {
				auto c = new CastCard(0, "", "", "", 1, 1);
				auto dlg = new CastCardDialog(_comm, _prop, dlgParShl, _summ, null);
			} else static if (is (C : EffectCard)) {
				auto c = new C(0, "", "", "");
				auto dlg = new EffectCardDialog!(C)(_comm, _prop, dlgParShl, _summ, null);
			} else static if (is (C == InfoCard)) {
				auto c = new InfoCard(0, "", "", "");
				auto dlg = new InfoCardDialog(_comm, _prop, dlgParShl, _summ, null);
			} else {
				static assert (0);
			}
			dlg.appliedEvent ~= {
				open(false);
				auto c = dlg.card;
				storeInsert([cards.length]);
				static if (is(CardOwner : CastCard)) {
					// CastCardは手札追加時にコピーを生成する
					c = _owner.add(c);
					dlg.card = c;
				} else {
					_owner.add(c);
				}
				refresh();
				select(__cards.length - 1);
				static if (is(C : CastCard)) {
					_comm.refCast.call(this, c);
				} else static if(is(C : SkillCard)) {
					_comm.refSkill.call(this, c);
				} else static if(is(C : ItemCard)) {
					_comm.refItem.call(this, c);
				} else static if(is(C : BeastCard)) {
					_comm.refBeast.call(this, c);
				} else static if(is(C : InfoCard)) {
					_comm.refInfo.call(this, c);
				} else static assert (0);
				static if (is (CardOwner : CastCard) && is (C : BeastCard)) {
					_comm.refCast.call(_owner);
				}
				_comm.refreshToolBar();
				dlg.appliedEvent.length = 0;
				dlg.applyEvent ~= {
					storeEdit(_owner.indexOf(c));
				};
				dlg.appliedEvent ~= {
					refresh();
					refCard(c);
					_comm.refreshToolBar();
				};
			};
			_editDlgs[c] = dlg;
			dlg.closeEvent ~= {
				_editDlgs.remove(c);
			};
			dlg.open();
		}
		static if (is (CardOwner == Summary)) {
			private void __refreshUseCount() {
				if (_viewMode == CViewMode.TABLE) {
					foreach (itm; _tbl.getItems()) {
						auto c = cast(C) itm.getData();
						itm.setText(3, to!(string)(_summ.useCounter.get(C.toID(c.id))));
					}
				}
			}
		}
		bool addFromNode(ref XNode node, string ver) {
			C[] adds;
			static if (is (CardOwner == Summary)) bool ids = false;
			if (node.attr("summId", false) != ownerId) {
				node.onTag[C.XML_NAME] = (ref XNode cNode) {
					adds ~= C.createFromNode(cNode, ver);
				};
				node.parse();
				if (!qCardMaterialCopy(node, adds)) return false;
			} else {
				node.onTag[C.XML_NAME] = (ref XNode cNode) {
					auto card = C.createFromNode(cNode, ver);
					if (cNode.attr("paneId", false) != _id || __card(card.id)) {
						adds ~= card;
					} else {
						static if (is (CardOwner == Summary)) ids = true;
						adds ~= card;
					}
				};
				node.parse();
			}
			if (adds.length == 0) return false;
			open(false);
			int[] indices;
			bool samePane = _id == node.attr("paneId", false);
			bool sameSc = ownerId == node.attr("summId", false);
			bool topLevel = node.attr!bool("topLevel", false, false);
			foreach (card; adds) {
				indices ~= cards.length;
				refreshLink(card, samePane, sameSc, topLevel);
				static if (is(CardOwner:Summary)) {
					ulong oldId = _owner.add(card);
					if (ids) {
						// 同じペイン内でコピー&ペースト
						_owner.useCounter.change(C.toID(oldId), C.toID(card.id));
					}
				} else {
					_owner.add(card);
				}
				static if (is(C : CastCard)) {
					_comm.refCast.call(this, card);
				} else static if(is(C : SkillCard)) {
					_comm.refSkill.call(this, card);
				} else static if(is(C : ItemCard)) {
					_comm.refItem.call(this, card);
				} else static if(is(C : BeastCard)) {
					_comm.refBeast.call(this, card);
				} else static if(is(C : InfoCard)) {
					_comm.refInfo.call(this, card);
				} else static assert (0);
			}
			storeInsert(indices);
			pasteRefresh(adds);
			_comm.refUseCount.call();
			static if (is (CardOwner : CastCard) && is (C : BeastCard)) {
				_comm.refCast.call(_owner);
			}
			return true;
		}
		void pasteRefresh(C[] cs) {
			if (_viewMode == CViewMode.TABLE) {
				foreach (c; cs) {
					createTableItem(c);
				}
				_tbl.setSelection([_tbl.getItemCount() - 1]);
				_tbl.showSelection();
			} else {
				refresh();
				_list.select(_list.count - 1);
				_list.scroll(_list.count - 1);
			}
			refreshStatusLine();
			_comm.refreshToolBar();
		}
	} else {
		private void delegate(ref XNode, string) _addc;
		void setAddCard(void delegate(ref XNode, string) addc) {
			_addc = addc;
		}
		void delegate(ref XNode, string) getAddCard() {
			return _addc;
		}
		void addCard() {
			C[] cs = selectedCards;
			auto doc = XNode.create(C.XML_NAME_M);
			toNode(doc, cs);
			_addc(doc, LATEST_VERSION);
			_comm.refreshToolBar();
		}
	}
	void refreshAll(PCardOwner summ, CardOwner owner) {
		_owner = owner;
		_summ = summ;
		refresh();
		static if (is(CardOwner:CastCard) && EditMode) {
			refreshAddHand();
		}
	}

	@property
	Table cardTable() {
		return _tbl;
	}

	static if (EditMode) {
		void reNumbering() {
			auto index = selectionIndex;
			auto dlg = new ReNumDialog!(C)(_prop, dlgParShl, cards[index],
				index == 0 ? 1 : cards[index - 1].id + 1);
			if (dlg.open()) {
				reNumbering(index, dlg.newId);
			}
		}
		void reNumbering(int index, ulong newId) {
			if (index < 0 || cards.length <= index) return;
			if (newId == 0) return;
			if (index > 0 && cards[index - 1].id >= newId) return;
			auto undo = new UndoIDs(this, _comm, _owner);
			ulong[] oldIDs;
			for (size_t i = index; i < cards.length; i++) {
				oldIDs ~= cards[i].id;
				static if (is (CardOwner : Summary)) {
					ulong ni = ulong.max - cards.length + i;
					owner.useCounter.change(C.toID(cards[i].id), C.toID(ni));
					cards[i].id = ni;
				}
			}
			bool refIDs = false;
			for (size_t i = index; i < cards.length; i++) {
				if (oldIDs[i - index] != newId) {
					refIDs = true;
				}
				static if (is (CardOwner : Summary)) {
					owner.useCounter.change(C.toID(cards[i].id), C.toID(newId));
				}
				cards[i].id = newId;
				refCard(cards[i]);
				newId++;
			}
			refreshIDs();
			if (refIDs) _undo ~= undo;
			_comm.refreshToolBar();
		}

		static if (is (C == CastCard)) {
			alias CastCardDialog CardDialog;
		} else static if (is (C : EffectCard)) {
			alias EffectCardDialog!C CardDialog;
		} else static if (is (C == InfoCard)) {
			alias InfoCardDialog CardDialog;
		} else static assert (0, typeof(C));
		private CardDialog[C] _editDlgs;
		CardDialog edit(C c) {
			auto p = c in _editDlgs;
			if (p) {
				p.active();
				return *p;
			}
			static if (is(typeof(c.linkId))) {
				if (0 != c.linkId) {
					auto c2 = card(c.linkId);
					if (c2) {
						_comm.openCWXPath(c2.cwxPath(true), false);
						static if (is(C:SkillCard)) {
							return _comm.openSkillWin(false).edit(c2);
						} else static if (is(C:ItemCard)) {
							return _comm.openItemWin(false).edit(c2);
						} else static if (is(C:BeastCard)) {
							return _comm.openBeastWin(false).edit(c2);
						} else static assert (0);
					}
					return null;
				}
			}
			static if (is (C == CastCard)) {
				auto dlg = new CastCardDialog(_comm, _prop, dlgParShl, _summ, c);
			} else static if (is (C : EffectCard)) {
				auto dlg = new EffectCardDialog!(C)(_comm, _prop, dlgParShl, _summ, c);
			} else static if (is (C == InfoCard)) {
				auto dlg = new InfoCardDialog(_comm, _prop, dlgParShl, _summ, c);
			} else static assert (0, typeof(C));
			dlg.applyEvent ~= {
				storeEdit(_owner.indexOf(c));
			};
			dlg.appliedEvent ~= {
				refresh();
				refCard(c);
				_comm.refreshToolBar();
			};
			dlg.closeEvent ~= {
				_editDlgs.remove(c);
			};
			_editDlgs[c] = dlg;
			dlg.open();
			return dlg;
		}
		CardDialog edit() {
			if (_viewMode == CViewMode.TABLE) {
				int index = _tbl.getSelectionIndex();
				if (index >= 0) {
					return edit(cast(C) _tbl.getItem(index).getData());
				}
			} else {
				int index = _list.selection;
				if (index >= 0) {
					return edit(_list.card(index));
				}
			}
			return null;
		}
		static if (is (C == CastCard)) {
			void editHand() {
				auto sel = selection;
				if (sel) {
					_comm.openHands(_prop, _summ, sel, true);
				}
			}
		}
		static if (is (C : EffectCard)) {
			void editUseEvent() {
				auto sel = selection;
				if (sel) editUseEvent(sel);
			}
			void editUseEvent(C c) {
				static if (is(typeof(c.linkId))) {
					if (0 != c.linkId) {
						auto c2 = card(c.linkId);
						if (c2) {
							_comm.openCWXPath(c2.cwxPath(true), false);
							static if (is(C:SkillCard)) {
								_comm.openSkillWin(false).editUseEvent(c2);
							} else static if (is(C:ItemCard)) {
								_comm.openItemWin(false).editUseEvent(c2);
							} else static if (is(C:BeastCard)) {
								_comm.openBeastWin(false).editUseEvent(c2);
							} else static assert (0);
							return;
						}
						return;
					}
				}
				_comm.openUseEvents(_prop, _summ, c, true);
			}
		}

		private void udImpl(int index1, int index2) {
			auto arr = cardsFrom(_owner);
			if (index1 < 0 || arr.length <= index1) return;
			if (index2 < 0 || arr.length <= index2) return;
			storeSwap(index1, index2);
			_owner.swap!C(index1, index2);
			refresh();
			arr = cardsFrom(_owner);
			refCard(arr[index1]);
			refCard(arr[index2]);
			select(index2);
		}
		bool canUp() {
			if (!_list.isFocusControl() && !_tbl.isFocusControl()) return false;
			int sel = selectionIndex;
			return sel != -1 && 0 < sel;
		}
		bool canDown() {
			if (!_list.isFocusControl() && !_tbl.isFocusControl()) return false;
			int sel = selectionIndex;
			return sel != -1 && sel + 1 < cards.length;
		}
		void up() {
			if (!_list.isFocusControl() && !_tbl.isFocusControl()) return;
			int sel = selectionIndex;
			if (-1 == sel) return;
			udImpl(sel, sel - 1);
			_comm.refreshToolBar();
		}
		void down() {
			if (!_list.isFocusControl() && !_tbl.isFocusControl()) return;
			int sel = selectionIndex;
			if (-1 == sel) return;
			udImpl(sel, sel + 1);
			_comm.refreshToolBar();
		}
	}
	bool isSelected() {
		return selectionIndex != -1;
	}

	override {
		void cut(SelectionEvent se) {
			static if (EditMode) {
				foreach (c; _tcpd) {
					if (c.canDoTCPD) {
						c.cut(se);
					}
				}
			}
		}
		void copy(SelectionEvent se) {
			foreach (c; _tcpd) {
				if (c.canDoTCPD) {
					c.copy(se);
				}
			}
		}
		void paste(SelectionEvent se) {
			static if (EditMode) {
				foreach (c; _tcpd) {
					if (c.canDoTCPD) {
						c.paste(se);
					}
				}
			}
		}
		void del(SelectionEvent se) {
			static if (EditMode) {
				foreach (c; _tcpd) {
					if (c.canDoTCPD) {
						c.del(se);
					}
				}
			}
		}
		void clone(SelectionEvent se) {
			static if (EditMode) {
				foreach (c; _tcpd) {
					if (c.canDoTCPD) {
						c.clone(se);
					}
				}
			}
		}
		@property
		bool canDoTCPD() {
			return _list.isVisible() || _tbl.isVisible();
		}
		@property
		bool canDoT() {
			foreach (c; _tcpd) {
				if (c.canDoTCPD) return c.canDoT;
			}
			return false;
		}
		@property
		bool canDoC() {
			foreach (c; _tcpd) {
				if (c.canDoTCPD) return c.canDoC;
			}
			return false;
		}
		@property
		bool canDoP() {
			foreach (c; _tcpd) {
				if (c.canDoTCPD) return c.canDoP;
			}
			return false;
		}
		@property
		bool canDoD() {
			foreach (c; _tcpd) {
				if (c.canDoTCPD) return c.canDoD;
			}
			return false;
		}
		@property
		bool canDoClone() {
			foreach (c; _tcpd) {
				if (c.canDoTCPD) return c.canDoClone;
			}
			return false;
		}
	}
	static if (EditMode) {
		void undo() {
			_undo.undo();
			_comm.refreshToolBar();
		}
		void redo() {
			_undo.redo();
			_comm.refreshToolBar();
		}
		bool canUndo() {
			return _undo.canUndo();
		}
		bool canRedo() {
			return _undo.canRedo();
		}
	}

	@property
	string[] openedCWXPath() {
		string[] r;
		foreach (c; selectedCards) {
			r ~= c.cwxPath(true);
		}
		if (!r.length) {
			static if (is(C:CastCard)) {
				r ~= .cpjoin(owner, "castcardview", true);
			} else static if (is(C:SkillCard)) {
				r ~= .cpjoin(owner, "skillcardview", true);
			} else static if (is(C:ItemCard)) {
				r ~= .cpjoin(owner, "itemcardview", true);
			} else static if (is(C:BeastCard)) {
				r ~= .cpjoin(owner, "beastcardview", true);
			} else static if (is(C:InfoCard)) {
				r ~= .cpjoin(owner, "infocardview", true);
			} else static assert (0);
		}
		return r;
	}
}

template CastCardPane(PCardOwner, CardOwner, ToCardOwner) {
	alias CardPane!(PCardOwner, CardOwner, CastCard, ToCardOwner) CastCardPane;
}
template SkillCardPane(PCardOwner, CardOwner, ToCardOwner) {
	alias CardPane!(PCardOwner, CardOwner, SkillCard, ToCardOwner) SkillCardPane;
}
template ItemCardPane(PCardOwner, CardOwner, ToCardOwner) {
	alias CardPane!(PCardOwner, CardOwner, ItemCard, ToCardOwner) ItemCardPane;
}
template BeastCardPane(PCardOwner, CardOwner, ToCardOwner) {
	alias CardPane!(PCardOwner, CardOwner, BeastCard, ToCardOwner) BeastCardPane;
}
template InfoCardPane(PCardOwner, CardOwner, ToCardOwner) {
	alias CardPane!(PCardOwner, CardOwner, InfoCard, ToCardOwner) InfoCardPane;
}
alias CastCardPane!(Summary, Summary, void) MainCastCardPane;
alias SkillCardPane!(Summary, Summary, void) MainSkillCardPane;
alias ItemCardPane!(Summary, Summary, void) MainItemCardPane;
alias BeastCardPane!(Summary, Summary, void) MainBeastCardPane;
alias InfoCardPane!(Summary, Summary, void) MainInfoCardPane;
