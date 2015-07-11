/// カードビュー。
/// カードの一覧を表示し、各種の操作を受け付ける。
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
import cwx.structs;
import cwx.system;

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
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.areaviewutils;
import cwx.editor.gui.dwt.incsearch;

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

enum CViewMode { INIT, LIFE, CARD, TABLE }
enum CardTableColumn { ID, Name, Desc, UC, Num }
enum CardType { Cast, Skill, Item, Beast, Info }
enum OwnerType { Summary, Cast }

private class CardPane(CardOwner, C : Card) : TCPD {
private:
	@property
	const
	bool editMode() { return _toc is null; }
	@property
	const
	bool canHold() { return _ownerType is OwnerType.Cast && (_cardType is CardType.Skill || _cardType is CardType.Item); }
	@property
	const
	bool useNum() { return _cardType !is CardType.Info; }

	@property
	const
	int colIndex(CardTableColumn col) { mixin(S_TRACE);
		final switch (col) {
		case CardTableColumn.ID:
			return 0;
		case CardTableColumn.Name:
			return 1;
		case CardTableColumn.Desc:
			if (useNum) { mixin(S_TRACE);
				return 3;
			} else {
				return 2;
			}
		case CardTableColumn.UC:
			static if (is(CardOwner:Summary)) {
				return colIndex(CardTableColumn.Desc) + 1;
			} else {
				return -1;
			}
		case CardTableColumn.Num:
			if (useNum) { mixin(S_TRACE);
				return 2;
			} else {
				return -1;
			}
		}
	}
	private static C[] cardsFrom(CardOwner)(CardOwner owner) { mixin(S_TRACE);
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
	private C[] cardsNarrow() { mixin(S_TRACE);
		if (_owner) { mixin(S_TRACE);
			C[] r;
			foreach (card; cards) { mixin(S_TRACE);
				if (_incSearch.match(cardName(card))) { mixin(S_TRACE);
					r ~= card;
				}
			}
			return r;
		}
		return [];
	}
	@property
	private int narrowCount() { mixin(S_TRACE);
		if (_viewMode is CViewMode.TABLE) { mixin(S_TRACE);
			return _tbl.getItemCount();
		} else { mixin(S_TRACE);
			return _list.count;
		}
	}
	public static C cardFrom(CardOwner)(CardOwner owner, ulong id) { mixin(S_TRACE);
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
	public C card(ulong id) { mixin(S_TRACE);
		return cardFrom(_owner, id);
	}
	private C localCard(ulong id) { mixin(S_TRACE);
		if (_owner) { mixin(S_TRACE);
			return card(id);
		}
		return null;
	}
	@property
	private static ulong linkId(in C card) {
		static if (is(C:EffectCard)) {
			return card.linkId;
		} else {
			return 0;
		}
	}
	private C baseCard(C card) { mixin(S_TRACE);
		if (0 != linkId(card)) { mixin(S_TRACE);
			auto c = pOwnerCard(linkId(card));
			if (c) return c;
		}
		return card;
	}
	private const(C) baseCard(const C card) { mixin(S_TRACE);
		if (0 != linkId(card)) { mixin(S_TRACE);
			auto c = pOwnerCard(linkId(card));
			if (c) return c;
		}
		return card;
	}
	private string cardName(in C card) { mixin(S_TRACE);
		return baseCard(card).name;
	}
	private string cardDesc(in C card) { mixin(S_TRACE);
		return baseCard(card).desc;
	}
	private int cardNum(in C card) { mixin(S_TRACE);
		final switch (_cardType) {
		case CardType.Cast:
			return (cast(CastCard)baseCard(card)).level;
		case CardType.Skill:
			return (cast(SkillCard)baseCard(card)).level;
		case CardType.Item:
			return (cast(ItemCard)baseCard(card)).useLimitMax;
		case CardType.Beast:
			return (cast(BeastCard)baseCard(card)).useLimit;
		case CardType.Info:
			assert (0);
		}
	}
	@property
	private C[] pOwnerCards() {return cardsFrom(_summ);}
	private C pOwnerCard(ulong id) {return cardFrom(_summ, id);}
private:
	static class CPUndo : Undo {
		protected CardPane _v = null;
		protected Commons comm;
		protected CardOwner owner;

		private ulong[] _ids;
		private ulong[] _idsB;
		private ulong _sel;
		private ulong _selB;

		this (CardPane v, Commons comm, CardOwner owner) { mixin(S_TRACE);
			_v = v;
			this.comm = comm;
			this.owner = owner;

			saveIDs(v);
		}
		private void saveIDs(CardPane v) { mixin(S_TRACE);
			_ids.length = 0;
			foreach (c; cardsFrom(owner)) _ids ~= c.id;
			if (v && v.widget && !v.widget.isDisposed()) { mixin(S_TRACE);
				_sel = v.selectionID;
			}
		}
		abstract override void undo();
		abstract override void redo();
		abstract override void dispose();
		protected void udb(CardPane v) { mixin(S_TRACE);
			_idsB = _ids.dup;
			_selB = _sel;
			saveIDs(v);
			if (v && v.widget && !v.widget.isDisposed()) { mixin(S_TRACE);
				.forceFocus(v.widget, false);
			}
		}
		private void resetID(CardPane v) { mixin(S_TRACE);
			ulong[] oldIDs;
			auto arr = cardsFrom(owner);
			foreach (i, c; arr) { mixin(S_TRACE);
				auto oID = c.id;
				c.id = ulong.max - arr.length + i;
				comm.summary.useCounter.change(C.toID(oID), C.toID(c.id));
				oldIDs ~= oID;
			}
			foreach (i, c; arr) { mixin(S_TRACE);
				auto oID = c.id;
				c.id = _idsB[i];
				comm.summary.useCounter.change(C.toID(oID), C.toID(c.id));
			}
			foreach (i, c; arr) { mixin(S_TRACE);
				if (c.id != oldIDs[i]) { mixin(S_TRACE);
					v.refCard(v, comm, c);
				}
			}
		}
		protected void uda(CardPane v) { mixin(S_TRACE);
			resetID(v);
			if (v && v.widget && !v.widget.isDisposed()) { mixin(S_TRACE);
				v.refresh();
				v.selectID(_selB);
				v.refreshStatusLine();
			}
			comm.refUseCount.call();
			comm.refreshToolBar();
		}
		protected CardPane view() { mixin(S_TRACE);
			return _v;
		}
	}
	static class UndoIDs : CPUndo {
		this (CardPane v, Commons comm, CardOwner owner) { mixin(S_TRACE);
			super (v, comm, owner);
		}
		override void undo() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);
		}
		override void redo() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);
		}
		override void dispose() {}
	}
	static class UndoEdit : CPUndo {
		private C _card;
		private ulong _id;
		this (CardPane v, Commons comm, CardOwner owner, ulong id) { mixin(S_TRACE);
			super (v, comm, owner);
			auto c = cardFrom(owner, id);
			_card = new C(c.id, c.name, c.path, c.desc);
			_card.shallowCopy(c);
			_card.setUseCounter(comm.summary.useCounter.sub);
			_id = id;
		}
		private void impl() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			auto card = _card;
			card.removeUseCounter();
			auto c = cardFrom(owner, _id);
			_card = new C(c.id, c.name, c.path, c.desc);
			_card.shallowCopy(c);
			_card.setUseCounter(comm.summary.useCounter.sub);
			c.shallowCopy(card);

			if (v && v.widget && !v.widget.isDisposed()) { mixin(S_TRACE);
				v.refresh();
			}
			refCard(v, comm, c);
			comm.refUseCount.call();
		}
		override void undo() { mixin(S_TRACE);
			impl();
		}
		override void redo() { mixin(S_TRACE);
			impl();
		}
		override void dispose() { mixin(S_TRACE);
			_card.removeUseCounter();
		}
	}
	void storeEdit(ulong id) { mixin(S_TRACE);
		assert (editMode);
		_undo ~= new UndoEdit(this, _comm, _owner, id);
	}
	static class UndoSwap : CPUndo {
		private int _index1, _index2;
		this (CardPane v, Commons comm, CardOwner owner, int index1, int index2) { mixin(S_TRACE);
			super (v, comm, owner);
			_index1 = index1;
			_index2 = index2;
		}
		private void impl() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			owner.swap!C(_index1, _index2);
			refCard(v, comm, cardsFrom(owner)[_index1]);
			refCard(v, comm, cardsFrom(owner)[_index2]);
		}
		override void undo() { mixin(S_TRACE);
			impl();
		}
		override void redo() { mixin(S_TRACE);
			impl();
		}
		override void dispose() {}
	}
	void storeSwap(int index1, int index2) { mixin(S_TRACE);
		assert (editMode);
		assert (_tbl.getSortColumn() is null || _tbl.getSortColumn() is _idSorter.column);
		_undo ~= new UndoSwap(this, _comm, _owner, index1, index2);
	}
	static class UndoMove : CPUndo {
		private int _from, _to;
		this (CardPane v, Commons comm, CardOwner owner, int from, int to) { mixin(S_TRACE);
			super (v, comm, owner);
			_from = from;
			_to = to;
		}
		private void impl() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			auto card = cardsFrom(owner)[_to];
			int from = _from;
			if (_to <= from) from++;
			owner.insert(from, card);
			std.algorithm.swap(_from, _to);
		}
		override void undo() { mixin(S_TRACE);
			impl();
		}
		override void redo() { mixin(S_TRACE);
			impl();
		}
		override void dispose() {}
	}
	void storeMove(int from, int to) { mixin(S_TRACE);
		assert (editMode);
		assert (_tbl.getSortColumn() is null || _tbl.getSortColumn() is _idSorter.column);
		_undo ~= new UndoMove(this, _comm, _owner, from, to);
	}
	static class UndoInsertDelete : CPUndo {
		private bool _insert;

		private ulong[] _ids;

		private C[] _cards = [];
		private int[] _indices;

		this (CardPane v, Commons comm, CardOwner owner, ulong[] ids, bool insert) { mixin(S_TRACE);
			super (v, comm, owner);
			_insert = insert;
			_ids = ids.dup.sort;

			if (!insert) { mixin(S_TRACE);
				initUndoDelete();
			}
		}
		private void initUndoDelete() { mixin(S_TRACE);
			foreach (c; _cards) { mixin(S_TRACE);
				c.removeUseCounter();
			}
			_cards.length = 0;
			_indices.length = 0;
			foreach (id; _ids) { mixin(S_TRACE);
				auto c = cardFrom(owner, id);
				auto card = c.dup;
				card.setUseCounter(comm.summary.useCounter.sub);
				_cards ~= card;
				_indices ~= cast(int)owner.indexOf(c);
			}
		}
		private void undoInsert() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			_insert = false;
			initUndoDelete();
			foreach_reverse (id; _ids) { mixin(S_TRACE);
				auto card = cardFrom(owner, id);
				delImpl(v, comm, owner, card);
			}
			comm.refUseCount.call();
		}
		void undoDelete() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			_insert = true;
			ulong selID = 0;
			foreach (i, id; _ids) { mixin(S_TRACE);
				assert (_indices[i] != -1);
				auto c = _cards[i];
				c.removeUseCounter();
				owner.insert(_indices[i], c);
				refCard(v, comm, c);
				selID = id;
			}
			if (v && v.widget && !v.widget.isDisposed()) { mixin(S_TRACE);
				v.refresh();
				v.selectID(selID);
				v.refreshStatusLine();
			}
			_cards.length = 0;
			comm.refUseCount.call();
		}
		override void undo() { mixin(S_TRACE);
			if (_insert) { mixin(S_TRACE);
				undoInsert();
			} else { mixin(S_TRACE);
				undoDelete();
			}
		}
		override void redo() { mixin(S_TRACE);
			undo();
		}
		override void dispose() { mixin(S_TRACE);
			foreach (c; _cards) { mixin(S_TRACE);
				c.removeUseCounter();
			}
		}
	}
	void storeInsert(ulong[] ids) { mixin(S_TRACE);
		assert (editMode);
		_undo ~= new UndoInsertDelete(this, _comm, _owner, ids, true);
	}
	void storeDelete(ulong[] ids) { mixin(S_TRACE);
		assert (editMode);
		_undo ~= new UndoInsertDelete(this, _comm, _owner, ids, false);
	}

	string _id;
	Composite _parent;
	Composite _pane;
	int _style;
	Commons _comm;
	Props _prop;
	UndoManager _undo = null;
	CardType _cardType;
	OwnerType _ownerType;
	CardOwner _owner = null;
	Summary _summ = null;
	void delegate(Shell) _save;
	CardList!(C) _list;
	Table _tbl;
	Image _cimg;
	CViewMode _viewMode = CViewMode.INIT;
	TCPD[] _tcpd;
	Summary _toc = null;
	string _statusLine = "";
	Preview _preview;
	C _previewC = null;
	PileImage _previewI = null;
	void closePreview() { mixin(S_TRACE);
		if (_previewI) { mixin(S_TRACE);
			_preview.close();
			_previewC = null;
			_previewI.dispose();
		}
	}
	static if (is(C:EventTreeOwner)) {
		C _openEventTarget = null;
	}

	TableSorter!C _idSorter;
	TableSorter!C _descSorter;
	TableSorter!C _nameSorter;

	IncSearch _incSearch = null;
	private void incSearch() { mixin(S_TRACE);
		.forceFocus(widget, true);
		_incSearch.startIncSearch();
	}

	bool compID(const C c1, const C c2) { mixin(S_TRACE);
		if (c1.id < c2.id) return true;
		if (c1.id > c2.id) return false;
		return false;
	}
	bool compName(const C c1, const C c2) { mixin(S_TRACE);
		int c;
		if (_prop.var.etc.logicalSort) { mixin(S_TRACE);
			c = incmp(cardName(c1), cardName(c2));
			if (c < 0) return true;
		} else { mixin(S_TRACE);
			c = icmp(cardName(c1), cardName(c2));
			if (c < 0) return true;
		}
		if (c == 0) { mixin(S_TRACE);
			return compID(c1, c2);
		} else { mixin(S_TRACE);
			return false;
		}
	}
	bool compDesc(const C c1, const C c2) { mixin(S_TRACE);
		int c;
		if (_prop.var.etc.logicalSort) { mixin(S_TRACE);
			c = incmp(cardDesc(c1), cardDesc(c2));
			if (c < 0) return true;
		} else { mixin(S_TRACE);
			c = icmp(cardDesc(c1), cardDesc(c2));
			if (c < 0) return true;
		}
		if (c == 0) { mixin(S_TRACE);
			return compID(c1, c2);
		} else { mixin(S_TRACE);
			return false;
		}
	}
	bool revCompID(const C c1, const C c2) { mixin(S_TRACE);
		if (c2.id < c1.id) return true;
		if (c2.id > c1.id) return false;
		return false;
	}
	bool revCompName(const C c1, const C c2) { mixin(S_TRACE);
		int c;
		if (_prop.var.etc.logicalSort) { mixin(S_TRACE);
			c = incmp(cardName(c2), cardName(c1));
			if (c < 0) return true;
		} else { mixin(S_TRACE);
			c = icmp(cardName(c2), cardName(c1));
			if (c < 0) return true;
		}
		if (c == 0) { mixin(S_TRACE);
			return revCompID(c1, c2);
		} else { mixin(S_TRACE);
			return false;
		}
	}
	bool revCompDesc(const C c1, const C c2) { mixin(S_TRACE);
		int c;
		if (_prop.var.etc.logicalSort) { mixin(S_TRACE);
			c = incmp(cardDesc(c2), cardDesc(c1));
			if (c < 0) return true;
		} else { mixin(S_TRACE);
			c = icmp(cardDesc(c2), cardDesc(c1));
			if (c < 0) return true;
		}
		if (c == 0) { mixin(S_TRACE);
			return revCompID(c1, c2);
		} else { mixin(S_TRACE);
			return false;
		}
	}
	TableSorter!C _ucSorter;
	bool compUC(const C c1, const C c2) { mixin(S_TRACE);
		assert (colIndex(CardTableColumn.UC) != -1);
		int uc1 = _summ.useCounter.get(C.toID(c1.id));
		int uc2 = _summ.useCounter.get(C.toID(c2.id));
		if (uc1 < uc2) return true;
		if (uc1 > uc2) return false;
		return compID(c1, c2);
	}
	bool revCompUC(const C c1, const C c2) { mixin(S_TRACE);
		assert (colIndex(CardTableColumn.UC) != -1);
		int uc1 = _summ.useCounter.get(C.toID(c2.id));
		int uc2 = _summ.useCounter.get(C.toID(c1.id));
		if (uc1 < uc2) return true;
		if (uc1 > uc2) return false;
		return compID(c1, c2);
	}
	TableSorter!C _numSorter = null;
	bool compNum(const C c1, const C c2) { mixin(S_TRACE);
		assert (useNum);
		int num1 = cardNum(c1);
		int num2 = cardNum(c2);
		if (num1 < num2) return true;
		if (num1 > num2) return false;
		return compID(c1, c2);
	}
	bool revCompNum(const C c1, const C c2) { mixin(S_TRACE);
		assert (useNum);
		int num1 = cardNum(c2);
		int num2 = cardNum(c1);
		if (num1 < num2) return true;
		if (num1 > num2) return false;
		return compID(c1, c2);
	}
	CardTableColumn columnVal(TableColumn column) { mixin(S_TRACE);
		int index = _tbl.indexOf(column);
		if (index == colIndex(CardTableColumn.ID)) return CardTableColumn.ID;
		if (index == colIndex(CardTableColumn.Name)) return CardTableColumn.Name;
		if (index == colIndex(CardTableColumn.Desc)) return CardTableColumn.Desc;
		if (index == colIndex(CardTableColumn.UC)) return CardTableColumn.UC;
		if (index == colIndex(CardTableColumn.Num)) return CardTableColumn.Num;
		assert (0);
	}
	static int columnToInt(CardTableColumn column) { mixin(S_TRACE);
		final switch (column) {
		case CardTableColumn.ID: return 0;
		case CardTableColumn.Name: return 1;
		case CardTableColumn.Desc: return 2;
		case CardTableColumn.UC: return 3;
		case CardTableColumn.Num: return 4;
		}
	}
	TableColumn columnFromInt(int column)
	out (value) { mixin(S_TRACE);
		assert (value !is null, column.to!string());
	} body { mixin(S_TRACE);
		switch (column) {
		case 0: return _tbl.getColumn(colIndex(CardTableColumn.ID));
		case 1: return _tbl.getColumn(colIndex(CardTableColumn.Name));
		case 2: return _tbl.getColumn(colIndex(CardTableColumn.Desc));
		case 3:
			if (colIndex(CardTableColumn.UC) != -1) { mixin(S_TRACE);
				return _tbl.getColumn(colIndex(CardTableColumn.UC));
			}
			goto default;
		case 4:
			if (useNum && colIndex(CardTableColumn.Num) != -1) { mixin(S_TRACE);
				return _tbl.getColumn(colIndex(CardTableColumn.Num));
			}
			goto default;
		default: return _tbl.getColumn(colIndex(CardTableColumn.ID));
		}
	}

	void sort() { mixin(S_TRACE);
		if (_tbl.getSortColumn() is null || _tbl.getSortColumn() is _idSorter.column) { mixin(S_TRACE);
			_idSorter.doSort(_tbl.getSortDirection());
		} else if (_tbl.getSortColumn() is _nameSorter.column) { mixin(S_TRACE);
			_nameSorter.doSort(_tbl.getSortDirection());
		} else if (_tbl.getSortColumn() is _descSorter.column) { mixin(S_TRACE);
			_descSorter.doSort(_tbl.getSortDirection());
		} else { mixin(S_TRACE);
			if (colIndex(CardTableColumn.UC) != -1) {
				if (_tbl.getSortColumn() is _ucSorter.column) { mixin(S_TRACE);
					_ucSorter.doSort(_tbl.getSortDirection());
				}
			}
			if (useNum) { mixin(S_TRACE);
				if (_tbl.getSortColumn() is _numSorter.column) { mixin(S_TRACE);
					_numSorter.doSort(_tbl.getSortDirection());
				}
			} else assert (0);
		}
	}
	void sort(ref C[] cards) { mixin(S_TRACE);
		bool delegate(const C, const C) minL = null;
		if (_tbl.getSortColumn() is null || _tbl.getSortColumn() is _idSorter.column) { mixin(S_TRACE);
			minL = _tbl.getSortDirection() == SWT.DOWN ? &revCompID : &compID;
		} else if (_tbl.getSortColumn() is _nameSorter.column) { mixin(S_TRACE);
			minL = _tbl.getSortDirection() == SWT.DOWN ? &revCompName : &compName;
		} else if (_tbl.getSortColumn() is _descSorter.column) { mixin(S_TRACE);
			minL = _tbl.getSortDirection() == SWT.DOWN ? &revCompDesc : &compDesc;
		} else { mixin(S_TRACE);
			if (colIndex(CardTableColumn.UC) != -1) {
				if (_tbl.getSortColumn() is _ucSorter.column) { mixin(S_TRACE);
					minL = _tbl.getSortDirection() == SWT.DOWN ? &revCompUC : &compUC;
				}
			}
			if (!minL) { mixin(S_TRACE);
				if (useNum) { mixin(S_TRACE);
					if (_tbl.getSortColumn() is _numSorter.column) { mixin(S_TRACE);
						minL = _tbl.getSortDirection() == SWT.DOWN ? &revCompNum : &compNum;
					}
				} else assert (0, .format("%s, %s", C.stringof, useNum.to!string()));
			}
		}
		cards = .sortDlg(cards.dup, minL);
	}

	void refreshStatusLine() { mixin(S_TRACE);
		if (!_tbl || !_list || !_comm) return;
		if (_tbl.isDisposed()) return;
		if (_owner) { mixin(S_TRACE);
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
				if (1 == s.length) { mixin(S_TRACE);
					_statusLine = .tryFormat(_prop.msgs.handCardStatusSelOne, c, vc, s[0].id);
				} else if (1 < s.length) { mixin(S_TRACE);
					_statusLine = .tryFormat(_prop.msgs.handCardStatusSelMulti, c, vc, s.length);
				} else { mixin(S_TRACE);
					_statusLine = .tryFormat(_prop.msgs.handCardStatus, c, vc);
				}
			} else { mixin(S_TRACE);
				if (1 == s.length) { mixin(S_TRACE);
					_statusLine = .tryFormat(_prop.msgs.cardStatusSelOne, c, s[0].id);
				} else if (1 < s.length) { mixin(S_TRACE);
					_statusLine = .tryFormat(_prop.msgs.cardStatusSelMulti, c, s.length);
				} else { mixin(S_TRACE);
					_statusLine = .tryFormat(_prop.msgs.cardStatus, c);
				}
			}
		} else { mixin(S_TRACE);
			_statusLine = "";
		}
		_comm.setStatusLine(_tbl, _statusLine);
	}
	void nameEditEnd(TableItem itm, int column, string newText) { mixin(S_TRACE);
		assert (editMode);
		auto c = cast(C) itm.getData();
		assert (c !is null);
		storeEdit(c.id);
		c.name = newText;
		refresh();
		refCard(c);
		_comm.refreshToolBar();
	}

	Control numCreateEditor(TableItem itm, int column) { mixin(S_TRACE);
		assert (useNum);
		assert (editMode);
		auto c = cast(C)itm.getData();
		auto spn = new Spinner(itm.getParent(), SWT.BORDER);
		initSpinner(spn);
		static if (is(C:CastCard)) {
			int max = _prop.var.etc.castLevelMax;
			int min = 1;
		} else static if (is(C:SkillCard)) {
			int max = _prop.var.etc.skillLevelMax;
			int min = 0;
		} else { mixin(S_TRACE);
			int max = _prop.var.etc.useCountMax;
			int min = 0;
		}
		spn.setMaximum(max);
		spn.setMinimum(min);
		spn.setSelection(cardNum(c));
		return spn;
	}
	void numEditEnd(TableItem itm, int column, Control ctrl) { mixin(S_TRACE);
		assert (useNum);
		assert (editMode);
		auto num = (cast(Spinner)ctrl).getSelection();
		auto c = cast(C)itm.getData();
		assert (c !is null);
		storeEdit(c.id);

		final switch (_cardType) {
		case CardType.Cast:
			(cast(CastCard)c).level = num;
			break;
		case CardType.Skill:
			(cast(SkillCard)c).level = num;
			break;
		case CardType.Item:
			auto s = cast(ItemCard)c;
			if (s.useLimitMax == s.useLimit) { mixin(S_TRACE);
				s.useLimit = num;
			}
			s.useLimitMax = num;
			s.useLimit = .min(s.useLimit, s.useLimitMax);
			break;
		case CardType.Beast:
			(cast(BeastCard)c).useLimit = num;
			break;
		case CardType.Info:
			assert (0);
		}

		refresh();
		refCard(c);
		_comm.refreshToolBar();
	}

	bool canEditT(TableItem itm, int column) { mixin(S_TRACE);
		assert (editMode);
		auto card = cast(C)itm.getData();
		return linkId(card) == 0;
	}
	void refreshR(string from, string to) { mixin(S_TRACE);
		refreshImpl();
	}
	void refresh(C c) { mixin(S_TRACE);
		if (!_tbl || _tbl.isDisposed()) return;
		void update(size_t i, C card) { mixin(S_TRACE);
			bool targ = card is c;
			if (cast(Summary)c.cwxParent && 0 != linkId(card) && linkId(card) is c.id) { mixin(S_TRACE);
				targ = true;
			}
			if (targ) { mixin(S_TRACE);
				if (_viewMode == CViewMode.TABLE) { mixin(S_TRACE);
					refreshTableItem(card, _tbl.getItem(cast(int)i));
				} else { mixin(S_TRACE);
					refreshListItem(cast(int)i, card);
				}
			}
		}
		if (_viewMode == CViewMode.TABLE) { mixin(S_TRACE);
			foreach (i, itm; _tbl.getItems()) { mixin(S_TRACE);
				update(i, cast(C)itm.getData());
			}
		} else { mixin(S_TRACE);
			foreach (i, card; _list.cards) { mixin(S_TRACE);
				update(i, card);
			}
		}
		refreshStatusLine();
	}
	void refreshImpl() { mixin(S_TRACE);
		closePreview();
		auto cards = cardsNarrow;
		sort(cards);
		if (_viewMode == CViewMode.TABLE) { mixin(S_TRACE);
			_list.refresh([], &cardImage, _prop.var.etc.showCardListTitle ? &cardTitle : null);
			C sel = null;
			auto index = _tbl.getSelectionIndex();
			if (-1 != index) { mixin(S_TRACE);
				sel = cast(C) _tbl.getItem(index).getData();
			}
			_tbl.removeAll();
			foreach (i, c; cards) { mixin(S_TRACE);
				createTableItem(c);
				if (sel is c) { mixin(S_TRACE);
					_tbl.setSelection([cast(int)i]);
				}
			}
			_tbl.showSelection();
		} else { mixin(S_TRACE);
			_tbl.removeAll();
			_list.refresh(cards, &cardImage, _prop.var.etc.showCardListTitle ? &cardTitle : null);
			int sel = _list.selection;
			if (sel >= 0) { mixin(S_TRACE);
				_list.scroll(sel);
			}
		}
		refreshStatusLine();
	}
	void createTableItem(C c, int index = -1) { mixin(S_TRACE);
		auto itm = index >= 0
			? new TableItem(_tbl, SWT.NONE, index)
			: new TableItem(_tbl, SWT.NONE);
		refreshTableItem(c, itm);
	}
	void refreshListItem(int index, C card) { mixin(S_TRACE);
		_list.refresh(index, card);
	}
	void refreshTableItem(C c, TableItem itm) { mixin(S_TRACE);
		itm.setImage(colIndex(CardTableColumn.ID), _cimg);
		itm.setText(colIndex(CardTableColumn.ID), to!(string)(c.id));
		itm.setText(colIndex(CardTableColumn.Name), cardName(c));
		string desc = cardDesc(c).singleLine;
		static if (is(C:EventTreeOwner)) {
			auto c2 = c;
			if (0 != linkId(c)) { mixin(S_TRACE);
				c2 = cardFrom(_summ, linkId(c));
			}
			if (c2 && _prop.var.etc.showEventTreeMark && ((_prop.var.etc.ignoreEmptyStart ? !c2.isEmpty : 0 < c2.trees.length))) { mixin(S_TRACE);
				itm.setImage(colIndex(CardTableColumn.Desc), _prop.images.eventTree);
			} else { mixin(S_TRACE);
				itm.setImage(colIndex(CardTableColumn.Desc), null);
			}
		}
		itm.setText(colIndex(CardTableColumn.Desc), desc);
		if (colIndex(CardTableColumn.UC) != -1) { mixin(S_TRACE);
			itm.setText(colIndex(CardTableColumn.UC), to!(string)(_summ.useCounter.get(C.toID(c.id))));
		}
		if (useNum) { mixin(S_TRACE);
			auto num = cardNum(c);
			static if (is(typeof(c.level))) {
				itm.setText(colIndex(CardTableColumn.Num), to!string(num));
			} else { mixin(S_TRACE);
				itm.setText(colIndex(CardTableColumn.Num), 0 < num ? to!string(num) : _prop.msgs.infinity);
			}
		}
		itm.setData(c);

		int w = textWidth(_prop, itm.getParent(), c.name);
		static if (is(C : CastCard)) {
			bool warn = w > _prop.looks.castNameLimit;
		} else static if (is(C : InfoCard)) {
			// 情報カード名はメッセージに表示されないため制限無し
			bool warn = false;
		} else { mixin(S_TRACE);
			bool warn = w > _prop.looks.nameLimit;
		}
		itm.setImage(colIndex(CardTableColumn.Name), warn ? _prop.images.warning : null);
	}
	template CopyAndPaste() {
		override void cut(SelectionEvent se) { mixin(S_TRACE);
			if (editMode) { mixin(S_TRACE);
				copy(se);
				del(se);
			}
		}
		override void copy(SelectionEvent se) { mixin(S_TRACE);
			auto cs = selectedCards;
			if (cs.length > 0) { mixin(S_TRACE);
				XMLtoCB(_prop, _comm.clipboard, toXML(cs));
				_comm.refreshToolBar();
			}
		}
		override void paste(SelectionEvent se) { mixin(S_TRACE);
			if (editMode) { mixin(S_TRACE);
				auto c = CBtoXML(_comm.clipboard);
				try { mixin(S_TRACE);
					if (c) { mixin(S_TRACE);
						try { mixin(S_TRACE);
							auto node = XNode.parse(c);
							if (node.name != C.XML_NAME_M) return;
							auto ver = new XMLInfo(_prop.sys, LATEST_VERSION);
							addFromNode(node, ver);
						} catch (Exception e) {
							printStackTrace();
							debugln(e);
						}
					}
					refreshStatusLine();
					_comm.refreshToolBar();
				} catch (Exception e) {
					printStackTrace();
					debugln(e);
				}
			}
		}
		override void clone(SelectionEvent se) { mixin(S_TRACE);
			if (editMode) { mixin(S_TRACE);
				_comm.clipboard.memoryMode = true;
				scope (exit) _comm.clipboard.memoryMode = false;
				copy(se);
				paste(se);
			}
		}
		@property
		override bool canDoT() { mixin(S_TRACE);
			return selectedCards.length > 0 && editMode;
		}
		@property
		override bool canDoC() { mixin(S_TRACE);
			return canDoT;
		}
		@property
		override bool canDoP() { mixin(S_TRACE);
			return _summ !is null && CBisXML(_comm.clipboard) && editMode;
		}
		@property
		override bool canDoD() { mixin(S_TRACE);
			return canDoT;
		}
		@property
		override bool canDoClone() { mixin(S_TRACE);
			return canDoC && editMode;
		}
	}
	static void delImpl(CardPane v, Commons comm, CardOwner owner, C card) { mixin(S_TRACE);
		assert (v.editMode);
		if (!card) return;
		owner.remove(card);
		if (v && v.widget && !v.widget.isDisposed()) { mixin(S_TRACE);
			if (v._viewMode == CViewMode.TABLE) { mixin(S_TRACE);
				ptrdiff_t index = -1;
				foreach (i, itm; v._tbl.getItems()) { mixin(S_TRACE);
					if (card is itm.getData()) { mixin(S_TRACE);
						index = i;
						break;
					}
				}
				assert (index != -1);
				v._tbl.remove(cast(int)index);
				v._tbl.redraw();
			} else { mixin(S_TRACE);
				v.refresh();
			}
		}
		delCard(v, comm, owner, card);
	}
	class CL : TCPD {
		@property
		CardList!(C) widget() { mixin(S_TRACE);
			return _list;
		}
		@property
		C selectionCard() { mixin(S_TRACE);
			return _list.selectionCard;
		}
		@property
		override bool canDoTCPD() { mixin(S_TRACE);
			return _summ && _viewMode !is CViewMode.TABLE;
		}
		mixin CopyAndPaste;
		override void del(SelectionEvent se) { mixin(S_TRACE);
			if (editMode) { mixin(S_TRACE);
				auto c = selectionCard;
				if (c) { mixin(S_TRACE);
					storeDelete([c.id]);
					_owner.remove(c);
					refresh();
					delCard(c);
					_comm.refreshToolBar();
				}
			}
		}
	}

	void refCard(C c) { mixin(S_TRACE);
		refCard(this, _comm, c);
	}
	static void refCard(CardPane v, Commons comm, C c) { mixin(S_TRACE);
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
		} else { mixin(S_TRACE);
			static assert (0);
		}
		if (v && v.widget && !v.widget.isDisposed()) { mixin(S_TRACE);
			v.refreshStatusLine();
		}
	}
	void delCard(C c) { mixin(S_TRACE);
		delCard(this, _comm, _owner, c);
	}
	static void delCard(CardPane v, Commons comm, CardOwner owner, C c) { mixin(S_TRACE);
		static if (is (C == CastCard)) {
			foreach (hc; c.skills) { mixin(S_TRACE);
				comm.delSkill.call(owner, hc);
			}
			foreach (hc; c.items) { mixin(S_TRACE);
				comm.delItem.call(owner, hc);
			}
			foreach (hc; c.beasts) { mixin(S_TRACE);
				comm.delBeast.call(owner, hc);
			}
			comm.delCast.call(c);
		} else static if (is (C == SkillCard)) {
			comm.delSkill.call(owner, c);
		} else static if (is (C == ItemCard)) {
			comm.delItem.call(owner, c);
		} else static if (is (C == BeastCard)) {
			comm.delBeast.call(owner, c);
		} else static if (is (C == InfoCard)) {
			comm.delInfo.call(c);
		} else { mixin(S_TRACE);
			static assert (0);
		}
		comm.refUseCount.call();
		static if (is (CardOwner : CastCard) && is (C : BeastCard)) {
			comm.refCast.call(owner);
		}
		if (v && v.widget && !v.widget.isDisposed()) { mixin(S_TRACE);
			v.refreshStatusLine();
		}
	}
	class CT : TCPD {
		@property
		Table widget() { mixin(S_TRACE);
			return _tbl;
		}
		@property
		C selectionCard() { mixin(S_TRACE);
			auto i = _tbl.getSelectionIndex();
			return -1 != i ? cast(C) _tbl.getItem(i).getData() : null;
		}
		@property
		override bool canDoTCPD() { mixin(S_TRACE);
			return _summ && _viewMode is CViewMode.TABLE;
		}
		mixin CopyAndPaste;
		override void del(SelectionEvent se) { mixin(S_TRACE);
			if (editMode) { mixin(S_TRACE);
				auto c = selectionCard;
				if (c) { mixin(S_TRACE);
					int i = _tbl.getSelectionIndex();
					if (-1 == i) return;
					storeDelete([c.id]);
					_owner.remove(c);
					_tbl.getItem(i).dispose();
					_tbl.redraw();
					delCard(c);
					_comm.refreshToolBar();
				}
			}
		}
	}
	template Drop() {
		override void drop(DropTargetEvent e){ mixin(S_TRACE);
			assert (editMode);
			if (!isXMLBytes(e.data)) return;
			e.detail = DND.DROP_NONE;
			string xml = bytesToXML(e.data);
			try { mixin(S_TRACE);
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
				bool sortedID = _tbl.getSortColumn() is null || _tbl.getSortColumn() is _idSorter.column;
				if (sameSc && samePane) { mixin(S_TRACE);
					// 同一リスト内で移動
					if (!sortedID) return;
					int count = cardCount;
					if (count < index) index = count;
					if ((index < count ? index : count - 1) == selectionIndex
							|| index == selectionIndex + 1) { mixin(S_TRACE);
						selectOnly(index);
						return;
					}
					C[] adds;
					node.onTag[C.XML_NAME] = (ref XNode cNode) { mixin(S_TRACE);
						auto id = Card.readId(cNode);
						if (id == 0UL) return;
						adds ~= this.outer.localCard(id);
						e.detail = DND.DROP_NONE;
					};
					node.parse();
					if (adds.length == 0) return;
					assert (adds.length == 1);
					auto card = adds[0];
					auto oldIndex = _owner.indexOf!C(card);

					if (_tbl.getSortDirection() is SWT.DOWN) { mixin(S_TRACE);
						// 処理を単純化するため、ID昇順でソートされた
						// 状態に対して移動処理を行う
						index = cast(int)cards.length - index;
						if (index < oldIndex) { mixin(S_TRACE);
							index--;
						}
					}

					storeMove(cast(int)oldIndex, oldIndex < index ? index - 1 : index);
					_owner.insert(index, card);
					insert(card, true);
					refCard(card);
					refreshStatusLine();
				} else { mixin(S_TRACE);
					e.detail = DND.DROP_NONE;
					// 他のリストからのコピー
					if (cardCount < index) index = cardCount;
					if (!sortedID) { mixin(S_TRACE);
						index = cardCount;
					} else if (_tbl.getSortDirection() is SWT.DOWN) { mixin(S_TRACE);
						index = cast(int)cards.length - index;
					}
					C[] adds;
					node.onTag[C.XML_NAME] = (ref XNode cNode) { mixin(S_TRACE);
						auto ver = new XMLInfo(_prop.sys, LATEST_VERSION);
						auto card = C.createFromNode(cNode, ver);
						adds ~= card;
					};
					node.parse();
					if (adds.length == 0) return;
					if (qCardMaterialCopy(node, adds)) { mixin(S_TRACE);
						ulong[] ids;
						foreach (i, card; adds) { mixin(S_TRACE);
							refreshLink(card, samePane, sameSc, topLevel);
							_owner.insert(index, card);
							ids ~= cardsFrom(_owner)[index].id;
							adds[i] = cards[index];
							index++;
						}
						storeInsert(ids);
						insert(adds[$ - 1], false);
						sort();
						foreach (i, card; adds) { mixin(S_TRACE);
							refCard(card);
						}
						_comm.refUseCount.call();
						refreshStatusLine();
					}
				}
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
			}
		}
	}
	void refreshLink(ref C card, bool samePane, bool sameSc, bool topLevel) { mixin(S_TRACE);
		assert (editMode);
		static if (is(C:EffectCard)) {
			if (sameSc && !is(CardOwner:CastCard) && 0 != linkId(card)) { mixin(S_TRACE);
				card = pOwnerCard(linkId(card));
				if (card) { mixin(S_TRACE);
					card = card.dup;
				} else { mixin(S_TRACE);
					card = new C(1UL, "", "", "");
				}
			} else if (sameSc && is(CardOwner:CastCard) && topLevel && _prop.var.etc.linkCard) { mixin(S_TRACE);
				auto id = card.id;
				card = new C(1UL, "", "", "");
				card.linkId = id;
			}
		}
	}
	class CLDTListener : DropTargetAdapter {
		override void dragEnter(DropTargetEvent e){ mixin(S_TRACE);
			assert (editMode);
			e.detail = narrowCount == cards.length ? DND.DROP_MOVE : DND.DROP_NONE;
		}
		override void dragOver(DropTargetEvent e){ mixin(S_TRACE);
			assert (editMode);
			e.detail = narrowCount == cards.length ? DND.DROP_MOVE : DND.DROP_NONE;
		}
		mixin Drop;
		@property
		private int selectionIndex() { mixin(S_TRACE);
			assert (editMode);
			return _list.selection;
		}
		private int indexOf(Point p) { mixin(S_TRACE);
			assert (editMode);
			return _list.searchIndexLoose(p.x, p.y);
		}
		@property
		private int cardCount() { mixin(S_TRACE);
			assert (editMode);
			return _list.count;
		}
		private void selectOnly(int index) { mixin(S_TRACE);
			assert (editMode);
			_list.scroll(index);
		}
		private void insert(C c, bool move) { mixin(S_TRACE);
			assert (editMode);
			refresh();
			int index = _list.indexOf(c);
			_list.select(index);
			_list.scroll(index);
			refreshStatusLine();
		}
	}
	class CTDTListener : DropTargetAdapter {
		override void dragEnter(DropTargetEvent e){ mixin(S_TRACE);
			assert (editMode);
			e.detail = _viewMode is CViewMode.TABLE && narrowCount == cards.length ? DND.DROP_MOVE : DND.DROP_NONE;
		}
		override void dragOver(DropTargetEvent e){ mixin(S_TRACE);
			assert (editMode);
			e.detail = _viewMode is CViewMode.TABLE && narrowCount == cards.length ? DND.DROP_MOVE : DND.DROP_NONE;
		}
		mixin Drop;
		@property
		private int selectionIndex() { mixin(S_TRACE);
			assert (editMode);
			return _tbl.getSelectionIndex();
		}
		private int indexOf(Point p) { mixin(S_TRACE);
			assert (editMode);
			auto itm = _tbl.getItem(p);
			return itm ? _tbl.indexOf(itm) : _tbl.getItemCount();
		}
		@property
		private int cardCount() { mixin(S_TRACE);
			assert (editMode);
			return _tbl.getItemCount();
		}
		private void selectOnly(int index) { mixin(S_TRACE);
			assert (editMode);
			_tbl.showSelection();
		}
		private void insert(C c, bool move) { mixin(S_TRACE);
			assert (editMode);
			refresh();
			foreach (i, itm; _tbl.getItems()) { mixin(S_TRACE);
				if (c is itm.getData()) { mixin(S_TRACE);
					_tbl.select(cast(int)i);
					_tbl.showSelection();
					return;
				}
			}
			assert (0);
		}
	}
	class CDSListener : DragSourceAdapter {
		override void dragStart(DragSourceEvent e) { mixin(S_TRACE);
			e.doit = (cast(DragSource) e.getSource()).getControl().isFocusControl()
				&& selectedCards.length > 0;
		}
		override void dragSetData(DragSourceEvent e){ mixin(S_TRACE);
			if (XMLBytesTransfer.getInstance().isSupportedType(e.dataType)) { mixin(S_TRACE);
				Control c = (cast(DragSource) e.getSource()).getControl();
				C[] sels = selectedCards;
				if (sels.length > 0) { mixin(S_TRACE);
					e.data = bytesFromXML(toXML(sels));
				}
			}
		}
	}
	bool qCardMaterialCopy(in XNode node, C[] cs) { mixin(S_TRACE);
		string fromSPath = node.attr("scenarioPath", false);
		if (fromSPath.length > 0 && !cfnmatch(fromSPath, nabs(ownerScenarioPath))) { mixin(S_TRACE);
			scope uc = new UseCounter;
			foreach (c; cs) { mixin(S_TRACE);
				c.setUseCounter(uc);
			}
			bool copy;
			bool r = qMaterialCopy(_comm, dlgParShl,
				uc, _summ.scenarioPath, fromSPath, copy, _summ.legacy);
			foreach (c; cs) { mixin(S_TRACE);
				c.removeUseCounter();
			}
			if (copy) { mixin(S_TRACE);
				_comm.refPaths.call(_comm.skin.materialPath);
			}
			return r;
		}
		return true;
	}

	@property
	Shell dlgParShl() { mixin(S_TRACE);
		if (_list && !_list.isDisposed()) return _list.getShell();
		return _comm.mainWin.shell.getShell();
	}

	@property
	string ownerScenarioPath() { mixin(S_TRACE);
		static if (is (CardOwner == CastCard)) {
			return _summ.scenarioPath;
		} else { mixin(S_TRACE);
			return _owner.scenarioPath;
		}
	}
	@property
	string ownerId() { mixin(S_TRACE);
		static if (is (CardOwner == CastCard)) {
			return _summ.id;
		} else { mixin(S_TRACE);
			return _owner.id;
		}
	}
	private Skin _skinTemp = null;
	ImageData cardImage(in C c) { mixin(S_TRACE);
		Skin skin = _skinTemp ? _skinTemp : _comm.skin;
		auto preview = _viewMode == CViewMode.TABLE;
		auto detail = _viewMode == CViewMode.LIFE || preview;
		static if (is (C == CastCard)) {
			return castCardImage(_prop, skin, c, ownerScenarioPath, detail);
		} else static if (!is (C == InfoCard) && is (CardOwner == CastCard)) {
			return .cardImage!(C)(_prop, skin, c, ownerScenarioPath, _owner, &pOwnerCard, detail, preview);
		} else { mixin(S_TRACE);
			return .cardImage!(C)(_prop, skin, c, ownerScenarioPath, cast(CastCard) null, &pOwnerCard, detail, preview);
		}
	}
	string cardTitle(in C c) { mixin(S_TRACE);
		return .tryFormat(_prop.msgs.cardTitle, c.id, baseCard(c).name);
	}

	void refreshIDs() { mixin(S_TRACE);
		if (_viewMode == CViewMode.TABLE) { mixin(S_TRACE);
			foreach (i, itm; _tbl.getItems()) { mixin(S_TRACE);
				auto c = cast(C)itm.getData();
				itm.setText(colIndex(CardTableColumn.ID), to!(string)(c.id));
			}
		}
	}

	void refList() { mixin(S_TRACE);
		auto sels = _tbl.getSelectionIndices();
		int index = _tbl.getSelectionIndex();
		refresh();
		if (-1 != index) { mixin(S_TRACE);
			_list.selectionIndices(sels);
			_list.scroll(index);
		} else { mixin(S_TRACE);
			_list.deselectAll();
		}
		refreshStatusLine();
	}
	void refTbl() { mixin(S_TRACE);
		auto sels = _list.selectionIndices;
		refresh();
		if (sels.length > 0) { mixin(S_TRACE);
			_tbl.setSelection(sels);
			_tbl.showSelection();
		}
		refreshStatusLine();
	}
	void toNode(ref XNode sn, C[] sels) { mixin(S_TRACE);
		if (!sels.length) return;
		if (cast(Object) sels[0].cwxParent is _summ) { mixin(S_TRACE);
			sn.newAttr("summId", _summ.id);
			sn.newAttr("paneId", _id);
			sn.newAttr("topLevel", true);
		} else { mixin(S_TRACE);
			sn.newAttr("summId", ownerId);
			sn.newAttr("paneId", _id);
			sn.newAttr("topLevel", false);
		}
		sn.newAttr("scenarioPath", nabs(ownerScenarioPath));
		auto opt = new XMLOption(_prop.sys);
		foreach (sel; sels) { mixin(S_TRACE);
			sel.toNode(sn, opt);
		}
	}
	string toXML(C[] sels) { mixin(S_TRACE);
		auto doc = XNode.create(C.XML_NAME_M);
		toNode(doc, sels);
		return doc.text;
	}
	private void editM() { mixin(S_TRACE);
		edit();
	}
	@property
	public bool canEdit() { mixin(S_TRACE);
		auto c = selection;
		if (!c) return false;
		if (0 != linkId(c) && !pOwnerCard(linkId(c))) return false;
		return true;
	}
	class LMouse : MouseAdapter {
		static if (is(C:EventTreeOwner)) {
			override void mouseUp(MouseEvent e) { mixin(S_TRACE);
				if (e.button == 1) { mixin(S_TRACE);
					if (_openEventTarget) { mixin(S_TRACE);
						editUseEvent(_openEventTarget, false);
					}
				} else if (e.button == 2) { mixin(S_TRACE);
					int index = _list.searchIndex(e.x, e.y);
					if (index >= 0) { mixin(S_TRACE);
						editUseEvent(_list.card(index), false);
					}
				}
			}
		}
		override void mouseDoubleClick(MouseEvent e) { mixin(S_TRACE);
			if (e.button != 1) return;
			int index = _list.searchIndex(e.x, e.y);
			if (index >= 0) { mixin(S_TRACE);
				edit(_list.card(index));
			}
		}
	}
	class TMouse : MouseAdapter {
		static if (is(C:EventTreeOwner)) {
			override void mouseUp(MouseEvent e) { mixin(S_TRACE);
				if (e.button == 1) { mixin(S_TRACE);
					if (_openEventTarget) { mixin(S_TRACE);
						editUseEvent(_openEventTarget, false);
					}
				} else if (e.button == 2) { mixin(S_TRACE);
					scope p = new Point(e.x, e.y);
					auto itm = _tbl.getItem(p);
					if (!itm) return;
					editUseEvent(cast(C)itm.getData(), false);
				}
			}
		}
		override void mouseDoubleClick(MouseEvent e) { mixin(S_TRACE);
			if (e.button != 1) return;
			scope p = new Point(e.x, e.y);
			auto itm = _tbl.getItem(p);
			if (!itm) return;
			edit(cast(C) itm.getData());
		}
	}
	class LKey : KeyAdapter {
		override void keyPressed(KeyEvent e) { mixin(S_TRACE);
			bool keyMatch = e.character == SWT.CR;
			if (keyMatch && _list.selection >= 0) { mixin(S_TRACE);
				edit(_list.selectionCard);
			}
		}
	}
	class TKey : KeyAdapter {
		override void keyPressed(KeyEvent e) { mixin(S_TRACE);
			bool keyMatch = e.character == SWT.CR;
			int i = _tbl.getSelectionIndex();
			if (keyMatch && -1 != i) { mixin(S_TRACE);
				edit(cast(C) _tbl.getItem(i).getData());
			}
		}
	}
	private class SelChanged : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			selectChanged();
		}
	}
	private bool _procRefColW = false;
	void refColumnWidth(Object sender, CardTableColumn c, int width) { mixin(S_TRACE);
		if (_procRefColW) return;
		if (!_tbl || _tbl.isDisposed()) return;
		if (sender is this) return;
		auto col = columnFromInt(columnToInt(c));
		col.setWidth(width);
	}
	class DisposeTable : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			closePreview();
			_preview.dispose();
			_comm.refCardTableColumnWidth.remove(&refColumnWidth);
		}
	}
	class ColResize(string WidthPropName) : ControlAdapter {
		override void controlResized(ControlEvent e) { mixin(S_TRACE);
			if (_procRefColW) return;
			_procRefColW = true;
			scope (exit) _procRefColW = false;
			auto col = cast(TableColumn) e.widget;
			int width = col.getWidth();
			static if (is(CardOwner : Summary)) {
				if (editMode) { mixin(S_TRACE);
					_comm.refCardTableColumnWidth.call(this.outer, columnVal(col), width);
				}
			}
			mixin("_prop.var.etc." ~ WidthPropName ~ " = width;");
		}
	}
	void selectChanged() { mixin(S_TRACE);
		refreshStatusLine();
		_comm.refreshToolBar();
	}

	void previewTrigger(int x, int y) { mixin(S_TRACE);
		auto itm = _tbl.getItem(new Point(x, y));
		if (!itm) { mixin(S_TRACE);
			closePreview();
			return;
		}
		assert (cast(C)itm.getData() !is null);
		auto c = cast(C)itm.getData();
		if (c is _previewC) { mixin(S_TRACE);
			return;
		}
		closePreview();
		_previewC = c;
		auto imgData = cardImage(c);
		_previewI = new PileImage(imgData, imgData.width, imgData.height);
		_previewI.createImage();

		auto b = itm.getBounds();
		auto p = _tbl.toDisplay(b.x, b.y + b.height);
		_preview.image(_previewI, p.x, p.y, b.height);
		_preview.show();
	}
	class ClosePreview : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			closePreview();
		}
	}
	class PreviewTrigger : MouseTrackAdapter, MouseMoveListener {
		override void mouseExit(MouseEvent e) { mixin(S_TRACE);
			closePreview();
		}
		override void mouseMove(MouseEvent e) { mixin(S_TRACE);
			previewTrigger(e.x, e.y);
			static if (is(C:EventTreeOwner)) {
				if (!editMode) return;
				auto itm = _tbl.getItem(new Point(e.x, e.y));
				if (!itm || !itm.getImage(colIndex(CardTableColumn.Desc))) { mixin(S_TRACE);
					_tbl.setCursor(null);
					_openEventTarget = null;
					return;
				}
				auto rect = itm.getImageBounds(colIndex(CardTableColumn.Desc));
				if (rect && rect.contains(e.x, e.y)) { mixin(S_TRACE);
					_tbl.setCursor(_list.getDisplay().getSystemCursor(SWT.CURSOR_HAND));
					_openEventTarget = cast(C)itm.getData();
				} else { mixin(S_TRACE);
					_tbl.setCursor(null);
					_openEventTarget = null;
				}
			}
		}
	}

	class ListMouseMove : MouseMoveListener {
		override void mouseMove(MouseEvent e) { mixin(S_TRACE);
			static if (is(C:EventTreeOwner)) {
				if (!editMode) return;
				if (_viewMode !is CViewMode.LIFE) { mixin(S_TRACE);
					_list.setCursor(null);
					_openEventTarget = null;
					return;
				}
				int i = _list.searchIndex(e.x, e.y);
				if (i < 0) { mixin(S_TRACE);
					_list.setCursor(null);
					_openEventTarget = null;
					return;
				}
				auto c = _list.card(i);
				auto bounds = _list.getBounds(i);
				auto rect = .eventTreeMarkRect(_prop, bounds.x, bounds.y, _summ, c);
				if (rect && rect.contains(e.x, e.y)) { mixin(S_TRACE);
					_list.setCursor(_list.getDisplay().getSystemCursor(SWT.CURSOR_HAND));
					_openEventTarget = c;
				} else { mixin(S_TRACE);
					_list.setCursor(null);
					_openEventTarget = null;
				}
			}
		}
	}

	void selectAll() { mixin(S_TRACE);
		assert (!editMode);
		if (_viewMode == CViewMode.TABLE) { mixin(S_TRACE);
			foreach (i; 0 .. _tbl.getItemCount()) { mixin(S_TRACE);
				_tbl.select(i);
			}
		} else { mixin(S_TRACE);
			foreach (i; 0 .. _list.count()) { mixin(S_TRACE);
				_list.select(i);
			}
		}
		selectChanged();
	}
	@property
	int selectionCount() { mixin(S_TRACE);
		assert (!editMode);
		if (_viewMode == CViewMode.TABLE) { mixin(S_TRACE);
			return _tbl.getSelectionCount();
		} else { mixin(S_TRACE);
			return _list.selectionCount;
		}
	}
	void refSortParams(Object sender, CardTableColumn column, int dir) { mixin(S_TRACE);
		if (sender is this) return;
		if (_sortProc) return;
		_sortProc = true;
		scope (exit) _sortProc = false;
		final switch (column) {
		case CardTableColumn.ID:
			_idSorter.doSort(dir);
			break;
		case CardTableColumn.Name:
			_nameSorter.doSort(dir);
			break;
		case CardTableColumn.Desc:
			_descSorter.doSort(dir);
			break;
		case CardTableColumn.UC:
			if (colIndex(CardTableColumn.UC) != -1) { mixin(S_TRACE);
				_ucSorter.doSort(dir);
				break;
			} else assert (0);
		case CardTableColumn.Num:
			if (useNum) { mixin(S_TRACE);
				_numSorter.doSort(dir);
				break;
			} else { mixin(S_TRACE);
				goto case CardTableColumn.ID;
			}
		}
		if (_viewMode != CViewMode.TABLE) { mixin(S_TRACE);
			refreshImpl();
		}
	}
	bool _sortProc = false;
	void sorted() { mixin(S_TRACE);
		if (_sortProc) return;
		_sortProc = true;
		scope (exit) _sortProc = false;
		if (_viewMode != CViewMode.TABLE) { mixin(S_TRACE);
			refreshImpl();
		}
		auto columnVal = columnVal(_tbl.getSortColumn());
		int column = columnToInt(columnVal);
		int dir = _tbl.getSortDirection();
		if (editMode) { mixin(S_TRACE);
			static if (is(CardOwner : Summary)) {
				_prop.var.etc.mainCardsSortColumn = column;
				_prop.var.etc.mainCardsSortDirection = dir;
				_comm.refMainCardsSort.call(this, columnVal, dir);
			} else {
				_prop.var.etc.handCardsSortColumn = column;
				_prop.var.etc.handCardsSortDirection = dir;
				_comm.refHandCardsSort.call(this, columnVal, dir);
			}
		} else { mixin(S_TRACE);
			static if (is(CardOwner:Summary)) {
				_prop.var.etc.importCardsSortColumn = column;
				_prop.var.etc.importCardsSortDirection = dir;
				_comm.refImportCardsSort.call(this, columnVal, dir);
			} else { mixin(S_TRACE);
				_prop.var.etc.importHandCardsSortColumn = column;
				_prop.var.etc.importHandCardsSortDirection = dir;
				_comm.refImportHandCardsSort.call(this, columnVal, dir);
			}
		}
	}
	void listEditEnd(C c, Control ctrl) { mixin(S_TRACE);
		assert (editMode);
		assert (c !is null);
		string newText = (cast(Text)ctrl).getText();
		if (newText == "") return;
		storeEdit(c.id);
		c.name = newText;
		refresh();
		refCard(c);
		_comm.refreshToolBar();
	}
	Control listCreateEditor(in C c) { mixin(S_TRACE);
		assert (editMode);
		if (0 != linkId(c)) return null;
		return createTextEditor(_comm, _prop, _list, c.name);
	}
	void createCardList(Composite parent) { mixin(S_TRACE);
		_pane = new Composite(parent, _style);
		_pane.setLayout(zeroGridLayout(1, true));

		auto tableComp = new Composite(_pane, SWT.NONE);
		tableComp.setLayout(zeroGridLayout(1, true));
		_tbl = new Table(tableComp, SWT.FULL_SELECTION | (editMode ? SWT.SINGLE : SWT.MULTI));
		_tbl.setLayoutData(new GridData(GridData.FILL_BOTH));
		_tbl.addSelectionListener(new SelChanged);
		_tbl.setHeaderVisible(true);
		.listener(_tbl, SWT.Resize, { mixin(S_TRACE);
			if (_tbl.getHorizontalBar()) { mixin(S_TRACE);
				_tbl.getHorizontalBar().setVisible(_viewMode is CViewMode.TABLE);
			}
		});
		.listener(_tbl, SWT.FocusIn, { mixin(S_TRACE);
			if (_viewMode !is CViewMode.TABLE) _list.setFocus();
		});

		_preview = new Preview(_prop, _tbl.getShell());
		auto closePreview = new ClosePreview;
		_tbl.getVerticalBar().addSelectionListener(closePreview);
		_tbl.getHorizontalBar().addSelectionListener(closePreview);
		auto prevTrig = new PreviewTrigger;
		_tbl.addMouseTrackListener(prevTrig);
		_tbl.addMouseMoveListener(prevTrig);

		auto idCol = new TableColumn(_tbl, SWT.NONE);
		idCol.setText(_prop.msgs.cardId);
		auto nameCol = new TableColumn(_tbl, SWT.NONE);
		nameCol.setText(_prop.msgs.cardName);
		TableColumn numCol = null;
		if (useNum) { mixin(S_TRACE);
			numCol = new TableColumn(_tbl, SWT.NONE);
			static if (is(typeof(cards[0].level))) {
				numCol.setText(_prop.msgs.level);
			} else { mixin(S_TRACE);
				numCol.setText(_prop.msgs.useCount);
			}
		}
		auto descCol = new TableColumn(_tbl, SWT.NONE);
		descCol.setText(_prop.msgs.cardDesc);

		TableColumn ucCol = null;
		if (colIndex(CardTableColumn.UC) != -1) { mixin(S_TRACE);
			ucCol = new TableColumn(_tbl, SWT.NONE);
			ucCol.setText(_prop.msgs.cardCount);
		}
		_comm.refCardTableColumnWidth.add(&refColumnWidth);
		_tbl.addDisposeListener(new DisposeTable);
		if (editMode) { mixin(S_TRACE);
			new TableTextEdit(_comm, _prop, _tbl, colIndex(CardTableColumn.Name), &nameEditEnd, &canEditT);
			if (useNum) { mixin(S_TRACE);
				new TableTCEdit(_comm, _tbl, colIndex(CardTableColumn.Num), &numCreateEditor, &numEditEnd, &canEditT);
			}
		}

		_list = new CardList!(C)(_pane, SWT.VIRTUAL | SWT.V_SCROLL | (editMode ? SWT.SINGLE : SWT.MULTI));
		void updateCardListParamsImpl() { mixin(S_TRACE);
			static if (is(C:CastCard)) {
				auto matPad = _prop.looks.castCardInsets;
			} else { mixin(S_TRACE);
				auto matPad = _prop.looks.menuCardInsets;
			}
			int w = _prop.looks.cardSize.width + matPad.e + matPad.w;
			int h = _prop.looks.cardSize.height + matPad.n + matPad.s;
			_list.setCardSize(w, h, _prop.var.etc.showCardListTitle);
			_list.setLayoutValues(_prop.var.etc.cardsMarginX, _prop.var.etc.cardsSpaceX,
				_prop.var.etc.cardsMarginY, _prop.var.etc.cardsSpaceY, _prop.var.etc.cardsTitleSpace,
				_prop.var.etc.cardsDefaultWrap);
		}
		void updateCardListParams() { mixin(S_TRACE);
			updateCardListParamsImpl();
			refreshImpl();
		}
		updateCardListParamsImpl();
		_list.addSelectionListener(new SelChanged);
		_comm.refShowCardListHeader.add(&updateLayout);
		_comm.refShowCardListTitle.add(&updateCardListParams);
		.listener(_list, SWT.Dispose, { mixin(S_TRACE);
			_comm.refShowCardListHeader.remove(&updateLayout);
			_comm.refShowCardListTitle.remove(&updateCardListParams);
		});
		if (editMode) { mixin(S_TRACE);
			new CardListEdit!C(_comm, _list, &listEditEnd, &listCreateEditor);
		}

		auto cl_ = new CL;
		_tcpd ~= cl_;

		auto ct_ = new CT;
		_tcpd ~= ct_;

		// 絞込み検索
		_incSearch = new IncSearch(_comm, _pane);
		_incSearch.modEvent ~= &refresh;

		// ソート関係
		_idSorter = new TableSorter!C(idCol, &compID, &revCompID);
		_idSorter.sortedEvent ~= &sorted;
		_nameSorter = new TableSorter!C(nameCol, &compName, &revCompName);
		_nameSorter.sortedEvent ~= &sorted;
		_descSorter = new TableSorter!C(descCol, &compDesc, &revCompDesc);
		_descSorter.sortedEvent ~= &sorted;
		if (ucCol) { mixin(S_TRACE);
			_ucSorter = new TableSorter!C(ucCol, &compUC, &revCompUC);
			_ucSorter.sortedEvent ~= &sorted;
		}
		if (numCol) { mixin(S_TRACE);
			_numSorter = new TableSorter!C(numCol, &compNum, &revCompNum);
			_numSorter.sortedEvent ~= &sorted;
		}
		int column;
		int dir;
		if (editMode) { mixin(S_TRACE);
			static if (is(CardOwner : Summary)) {
				idCol.setWidth(_prop.var.etc.cardIdColumn);
				idCol.addControlListener(new ColResize!("cardIdColumn"));
				nameCol.setWidth(_prop.var.etc.cardNameColumn);
				nameCol.addControlListener(new ColResize!("cardNameColumn"));
				descCol.setWidth(_prop.var.etc.cardDescriptionColumn);
				descCol.addControlListener(new ColResize!("cardDescriptionColumn"));
				ucCol.setWidth(_prop.var.etc.cardCountColumn);
				ucCol.addControlListener(new ColResize!("cardCountColumn"));
				if (numCol) { mixin(S_TRACE);
					numCol.setWidth(_prop.var.etc.cardNumberColumn);
					numCol.addControlListener(new ColResize!("cardNumberColumn"));
				}

				column = _prop.var.etc.mainCardsSortColumn;
				dir = _prop.var.etc.mainCardsSortDirection == SortDir.Down ? SWT.DOWN : SWT.UP;
				_comm.refMainCardsSort.add(&refSortParams);
				.listener(_tbl, SWT.Dispose, { _comm.refMainCardsSort.remove(&refSortParams); });
			} else {
				idCol.setWidth(_prop.var.etc.handCardIdColumn);
				idCol.addControlListener(new ColResize!("handCardIdColumn"));
				nameCol.setWidth(_prop.var.etc.handCardNameColumn);
				nameCol.addControlListener(new ColResize!("handCardNameColumn"));
				descCol.setWidth(_prop.var.etc.handCardDescriptionColumn);
				descCol.addControlListener(new ColResize!("handCardDescriptionColumn"));
				if (numCol) { mixin(S_TRACE);
					numCol.setWidth(_prop.var.etc.handCardNumberColumn);
					numCol.addControlListener(new ColResize!("handCardNumberColumn"));
				}

				column = _prop.var.etc.handCardsSortColumn;
				dir = _prop.var.etc.handCardsSortDirection == SortDir.Down ? SWT.DOWN : SWT.UP;
				_comm.refHandCardsSort.add(&refSortParams);
				.listener(_tbl, SWT.Dispose, { _comm.refHandCardsSort.remove(&refSortParams); });
			}
		} else { mixin(S_TRACE);
			static if (is(CardOwner:Summary)) {
				idCol.setWidth(_prop.var.etc.importCardIdColumn);
				idCol.addControlListener(new ColResize!("importCardIdColumn"));
				nameCol.setWidth(_prop.var.etc.importCardNameColumn);
				nameCol.addControlListener(new ColResize!("importCardNameColumn"));
				descCol.setWidth(_prop.var.etc.importCardDescriptionColumn);
				descCol.addControlListener(new ColResize!("importCardDescriptionColumn"));
				if (colIndex(CardTableColumn.UC) != -1) { mixin(S_TRACE);
					ucCol.setWidth(_prop.var.etc.importCardCountColumn);
					ucCol.addControlListener(new ColResize!("importCardCountColumn"));
				}
				if (numCol) { mixin(S_TRACE);
					numCol.setWidth(_prop.var.etc.importCardNumberColumn);
					numCol.addControlListener(new ColResize!("importCardNumberColumn"));
				}

				column = _prop.var.etc.importCardsSortColumn;
				dir = _prop.var.etc.importCardsSortDirection == SortDir.Down ? SWT.DOWN : SWT.UP;
				_comm.refImportCardsSort.add(&refSortParams);
				.listener(_tbl, SWT.Dispose, { _comm.refImportCardsSort.remove(&refSortParams); });
			} else {
				idCol.setWidth(_prop.var.etc.importHandCardIdColumn);
				idCol.addControlListener(new ColResize!("importHandCardIdColumn"));
				nameCol.setWidth(_prop.var.etc.importHandCardNameColumn);
				nameCol.addControlListener(new ColResize!("importHandCardNameColumn"));
				descCol.setWidth(_prop.var.etc.importHandCardDescriptionColumn);
				descCol.addControlListener(new ColResize!("importHandCardDescriptionColumn"));
				if (numCol) { mixin(S_TRACE);
					numCol.setWidth(_prop.var.etc.importHandCardNumberColumn);
					numCol.addControlListener(new ColResize!("importHandCardNumberColumn"));
				}

				column = _prop.var.etc.importHandCardsSortColumn;
				dir = _prop.var.etc.importHandCardsSortDirection == SortDir.Down ? SWT.DOWN : SWT.UP;
				_comm.refImportHandCardsSort.add(&refSortParams);
				.listener(_tbl, SWT.Dispose, { _comm.refImportHandCardsSort.remove(&refSortParams); });
			}
		}
		_tbl.setSortColumn(columnFromInt(column));
		_tbl.setSortDirection(dir);

		// マウス・キーボード操作
		void setupDrag(Control c) { mixin(S_TRACE);
			auto drag = new DragSource(c, DND.DROP_MOVE | DND.DROP_COPY | DND.DROP_LINK);
			drag.setTransfer([XMLBytesTransfer.getInstance()]);
			drag.addDragListener(new CDSListener);
		}
		setupDrag(_list);
		setupDrag(_tbl);

		_list.addMouseListener(new LMouse);
		_list.addMouseMoveListener(new ListMouseMove);
		_list.addKeyListener(new LKey);
		_tbl.addMouseListener(new TMouse);
		_tbl.addKeyListener(new TKey);
		if (editMode) { mixin(S_TRACE);
			auto dropL = new DropTarget(_list, DND.DROP_DEFAULT | DND.DROP_MOVE);
			dropL.setTransfer([XMLBytesTransfer.getInstance()]);
			dropL.addDropListener(new CLDTListener);
			auto dropT = new DropTarget(_tbl, DND.DROP_DEFAULT | DND.DROP_MOVE);
			dropT.setTransfer([XMLBytesTransfer.getInstance()]);
			dropT.addDropListener(new CTDTListener);
		}

		refList();
	}
	void refScenario(Summary summ) { mixin(S_TRACE);
		assert (editMode);
		_undo.reset();
	}
	static if (is (C == CastCard)) {
		private void delegate() _openHand;
	}
	void refUndoMax() { mixin(S_TRACE);
		assert (editMode);
		_undo.max = _prop.var.etc.undoMaxMainView;
	}
	private void construct1(Commons comm, Props prop, Summary summ, int style) { mixin(S_TRACE);
		auto o = this;
		_id = format("%08X", &o) ~ "-" ~ to!(string)(Clock.currTime());
		_comm = comm;
		_prop = prop;
		_summ = summ;
		_style = style;
		if (editMode) { mixin(S_TRACE);
			_undo = new UndoManager(_prop.var.etc.undoMaxMainView);
		}
		static if (is(CardOwner:Summary)) {
			_ownerType = OwnerType.Summary;
		} else static if (is(CardOwner:CastCard)) {
			_ownerType = OwnerType.Cast;
		} else static assert (0);
		static if (is (C == CastCard)) {
			_cardType = CardType.Cast;
			_cimg = prop.images.casts;
		} else static if (is (C == SkillCard)) {
			_cardType = CardType.Skill;
			_cimg = prop.images.skill;
		} else static if (is (C == ItemCard)) {
			_cardType = CardType.Item;
			_cimg = prop.images.item;
		} else static if (is (C == BeastCard)) {
			_cardType = CardType.Beast;
			_cimg = prop.images.beast;
		} else static if (is (C == InfoCard)) {
			_cardType = CardType.Info;
			_cimg = prop.images.info;
		}
	}
	void hold(SelectionEvent e) { mixin(S_TRACE);
		assert (canHold);
		assert (editMode);
		auto c = selection;
		if (!c) return;
		auto mi = cast(MenuItem)e.widget;
		if (auto card = cast(SkillCard)c) {
			if (card.hold is mi.getSelection()) return;
			storeEdit(card.id);
			card.hold = mi.getSelection();
		} else if (auto card = cast(ItemCard)c) {
			if (card.hold is mi.getSelection()) return;
			storeEdit(card.id);
			card.hold = mi.getSelection();
		} else assert (0);
		refresh();
	}
	static if (is(CardOwner:CastCard)) {
		Menu _addHandMenu = null;
		void refAddHandMenu(C card) { mixin(S_TRACE);
			assert (editMode);
			createMenuItem2(_comm, _addHandMenu, .format("%s.%s", card.id, card.name), _cimg, { mixin(S_TRACE);
				.forceFocus(widget, false);
				auto doc = XNode.create(C.XML_NAME_M);
				toNode(doc, [card]);
				auto ver = new XMLInfo(_prop.sys, LATEST_VERSION);
				addFromNode(doc, ver);
			}, null);
		}
		void refreshAddHand() { mixin(S_TRACE);
			assert (editMode);
			if (!_summ) return;
			foreach (itm; _addHandMenu.getItems()) { mixin(S_TRACE);
				itm.dispose();
			}
			foreach (card; pOwnerCards) { mixin(S_TRACE);
				refAddHandMenu(card);
			}
		}
		public void removeRef() { mixin(S_TRACE);
			assert (editMode);
			auto card = selection;
			if (!card || 0 == card.linkId) return;
			auto targ = pOwnerCard(card.linkId);
			if (!targ) return;
			storeEdit(card.id);
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
		@property
		public bool canRemoveRef() { mixin(S_TRACE);
			assert (editMode);
			return selection && 0 != selection.linkId && pOwnerCard(selection.linkId);
		}
	}
public:
	static if (is (C == CastCard)) {
		this (Commons comm, Props prop, Summary summ, Composite parent, int style, Summary toc, void delegate() openHand) { mixin(S_TRACE);
			_parent = parent;
			_toc = toc;
			assert (!editMode);
			_openHand = openHand;
			_skinTemp = comm.findSkinFromHistory(summ);
			construct1(comm, prop, summ, style);
		}
	} else {
		this (Commons comm, Props prop, Summary summ, Composite parent, int style, Summary toc) { mixin(S_TRACE);
			_parent = parent;
			_toc = toc;
			assert (!editMode);
			_skinTemp = comm.findSkinFromHistory(summ);
			construct1(comm, prop, summ, style);
		}
	}
	this (Commons comm, Props prop, Summary summ, Composite parent, int style) { mixin(S_TRACE);
		_parent = parent;
		construct1(comm, prop, summ, style);
		assert (editMode);
	}

	void construct() { mixin(S_TRACE);
		reconstruct(_parent, _style);
	}

	static if (is(C:EventTreeOwner)) {
		void refEventTree(EventTree et) { mixin(S_TRACE);
			assert (editMode);
			if (cast(C)et.owner || et.owner is null) { mixin(S_TRACE);
				refreshImpl();
			}
		}
	}
	void reconstruct(Composite parent, int style) { mixin(S_TRACE);
		_viewMode = CViewMode.INIT;
		_style = style;
		_parent = parent;
		createCardList(parent);
		_comm.refCardImageStatus.add(&refreshImpl);
		.listener(_list, SWT.Dispose, { mixin(S_TRACE);
			_comm.refCardImageStatus.remove(&refreshImpl);
		});
		if (editMode) { mixin(S_TRACE);
			static if (is(C:EventTreeOwner)) {
				_comm.refEventTree.add(&refEventTree);
				_comm.delEventTree.add(&refEventTree);
				.listener(_list, SWT.Dispose, { mixin(S_TRACE);
					_comm.refEventTree.remove(&refEventTree);
					_comm.delEventTree.remove(&refEventTree);
				});
			}
			_comm.refSkin.add(&refreshImpl);
			_comm.delPaths.add(&refreshImpl);
			_comm.replPath.add(&refreshR);
			_comm.replText.add(&refreshImpl);
			_list.addDisposeListener(new class DisposeListener {
				override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
					_comm.refSkin.remove(&refreshImpl);
					_comm.delPaths.remove(&refreshImpl);
					_comm.replPath.remove(&refreshR);
					_comm.replText.remove(&refreshImpl);
				}
			});
		}
		if (colIndex(CardTableColumn.UC) != -1) { mixin(S_TRACE);
			_comm.refUseCount.add(&refreshUseCount);
			_list.addDisposeListener(new class DisposeListener {
				override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
					_comm.refUseCount.remove(&refreshUseCount);
				}
			});
		}
		Menu pop;
		if (editMode) { mixin(S_TRACE);
			_comm.refScenario.add(&refScenario);
			static if (is (C == CastCard)) {
				_comm.refCast.add(&refCardCallback);
			} else static if (is (C == SkillCard)) {
				_comm.refSkill.add(&refCardCallback);
				_comm.delSkill.add(&delCardCallback);
			} else static if (is (C == ItemCard)) {
				_comm.refItem.add(&refCardCallback);
				_comm.delItem.add(&delCardCallback);
			} else static if (is (C == BeastCard)) {
				_comm.refBeast.add(&refCardCallback);
				_comm.delBeast.add(&delCardCallback);
			} else static if (is (C == InfoCard)) {
				_comm.refInfo.add(&refCardCallback);
			}
			_comm.refUndoMax.add(&refUndoMax);
			_list.addDisposeListener(new class DisposeListener {
				override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
					_comm.refScenario.remove(&refScenario);
					static if (is (C == CastCard)) {
						_comm.refCast.remove(&refCardCallback);
					} else static if (is (C == SkillCard)) {
						_comm.refSkill.remove(&refCardCallback);
						_comm.delSkill.remove(&delCardCallback);
					} else static if (is (C == ItemCard)) {
						_comm.refItem.remove(&refCardCallback);
						_comm.delItem.remove(&delCardCallback);
					} else static if (is (C == BeastCard)) {
						_comm.refBeast.remove(&refCardCallback);
						_comm.delBeast.remove(&delCardCallback);
					} else static if (is (C == InfoCard)) {
						_comm.refInfo.remove(&refCardCallback);
					}
					_comm.refUndoMax.remove(&refUndoMax);
					foreach (w; _editDlgs.values) { mixin(S_TRACE);
						w.forceCancel();
					}
				}
			});
			pop = new Menu(parent.getShell(), SWT.POP_UP);
			createMenuItem(_comm, pop, MenuID.IncSearch, &incSearch, null);
			new MenuItem(pop, SWT.SEPARATOR);
			static if (is (C == CastCard)) {
				createMenuItem(_comm, pop, MenuID.EditProp, &editM, &canEdit);
				new MenuItem(pop, SWT.SEPARATOR);
				createMenuItem(_comm, pop, MenuID.OpenHand, &editHand, &canEdit);
				new MenuItem(pop, SWT.SEPARATOR);
				createMenuItem(_comm, pop, MenuID.NewCast, &create, () => _summ !is null);
			} else static if (is (C == SkillCard) || is (C == ItemCard) || is (C == BeastCard)) {
				createMenuItem(_comm, pop, MenuID.EditProp, &editM, &canEdit);
				new MenuItem(pop, SWT.SEPARATOR);
				createMenuItem(_comm, pop, MenuID.EditEventAtTimeOfUsing, () => editUseEvent(false), &canEdit);
				new MenuItem(pop, SWT.SEPARATOR);
				static if (is(C:SkillCard)) {
					createMenuItem(_comm, pop, MenuID.NewSkill, &create, () => _summ !is null);
				} else static if (is(C:ItemCard)) {
					createMenuItem(_comm, pop, MenuID.NewItem, &create, () => _summ !is null);
				} else static if (is(C:BeastCard)) {
					createMenuItem(_comm, pop, MenuID.NewBeast, &create, () => _summ !is null);
				} else static assert (0);
			} else static if (is (C == InfoCard)) {
				createMenuItem(_comm, pop, MenuID.EditProp, &editM, &canEdit);
				new MenuItem(pop, SWT.SEPARATOR);
				createMenuItem(_comm, pop, MenuID.NewInfo, &create, () => _summ !is null);
			} else { mixin(S_TRACE);
				static assert (0);
			}
			if (canHold) { mixin(S_TRACE);
				new MenuItem(pop, SWT.SEPARATOR);
				auto holdMI = createMenuItem(_comm, pop, MenuID.Hold, &hold, () => selection !is null, SWT.CHECK);
				.listener(pop, SWT.Show, { mixin(S_TRACE);
					auto c = selection;
					if (auto card = cast(SkillCard)c) {
						holdMI.setSelection(card.hold);
					} else if (auto card = cast(ItemCard)c) {
						holdMI.setSelection(card.hold);
					} else assert (c is null);
				});
			}
			static if (is(CardOwner:CastCard)) {
				new MenuItem(pop, SWT.SEPARATOR);
				void delegate(SelectionEvent) dummy = null;
				auto addHandMI = createMenuItem(_comm, pop, MenuID.AddHand, dummy, () => _owner && _summ && pOwnerCards.length, SWT.CASCADE);
				_addHandMenu = new Menu(addHandMI);
				addHandMI.setMenu(_addHandMenu);
				new MenuItem(pop, SWT.SEPARATOR);
				createMenuItem(_comm, pop, MenuID.RemoveRef, &removeRef, &canRemoveRef);
			}
			new MenuItem(pop, SWT.SEPARATOR);
			createMenuItem(_comm, pop, MenuID.Undo, &undo, &_undo.canUndo);
			createMenuItem(_comm, pop, MenuID.Redo, &redo, &_undo.canRedo);
			new MenuItem(pop, SWT.SEPARATOR);
			appendMenuTCPD(_comm, pop, this, true, true, true, true, true);
			new MenuItem(pop, SWT.SEPARATOR);
			createMenuItem(_comm, pop, MenuID.SelectConnectedResource, &selectConnectedResource, &canSelectConnectedResource);
			static if (is(CardOwner:Summary)) {
				new MenuItem(pop, SWT.SEPARATOR);
				createMenuItem(_comm, pop, MenuID.FindID, &replaceID, &canReplaceID);
			}
			new MenuItem(pop, SWT.SEPARATOR);
			createMenuItem(_comm, pop, MenuID.ReNumbering, &reNumbering, &canReNumbering);
		} else { mixin(S_TRACE);
			pop = new Menu(parent.getShell(), SWT.POP_UP);
			createMenuItem(_comm, pop, MenuID.IncSearch, &incSearch, null);
			new MenuItem(pop, SWT.SEPARATOR);
			createMenuItem(_comm, pop, MenuID.Import, &doImport, &canDoImport);
			new MenuItem(pop, SWT.SEPARATOR);
			createMenuItem(_comm, pop, MenuID.ShowProp, &editM, &canEdit);
			new MenuItem(pop, SWT.SEPARATOR);
			static if (is (C : EffectCard)) {
				createMenuItem(_comm, pop, MenuID.EditEventAtTimeOfUsing, () => editUseEvent(false), &canEdit);
				new MenuItem(pop, SWT.SEPARATOR);
			}
			static if (is (C == CastCard)) {
				createMenuItem(_comm, pop, MenuID.OpenHand, _openHand, () => selection !is null);
				new MenuItem(pop, SWT.SEPARATOR);
			}
			appendMenuTCPD(_comm, pop, this, false, true, false, false, false);
			new MenuItem(pop, SWT.SEPARATOR);
			createMenuItem(_comm, pop, MenuID.SelectAll, &selectAll, () => cards.length && selectionCount != cards.length);
		}
		_list.setMenu(pop);
		_tbl.setMenu(pop);
		refreshStatusLine();
	}

	@property
	CardOwner owner() { mixin(S_TRACE);
		return _owner;
	}
	@property
	Summary summary() { mixin(S_TRACE);
		return _summ;
	}
	@property
	Control widget() { mixin(S_TRACE);
		if (_viewMode == CViewMode.TABLE) { mixin(S_TRACE);
			return _tbl;
		} else { mixin(S_TRACE);
			return _list;
		}
	}
	@property
	Composite pane() { mixin(S_TRACE);
		return _pane;
	}
	@property
	Table table() { mixin(S_TRACE);
		return _tbl;
	}
	@property
	CardList!C list() { mixin(S_TRACE);
		return _list;
	}
	@property
	string statusLine() {return _statusLine;}

	void refresh() { mixin(S_TRACE);
		if (!_tbl || _tbl.isDisposed()) return;
		if (_owner) { mixin(S_TRACE);
			refreshImpl();
		}
		refreshStatusLine();
	}
	private void refCardCallback(Object sender, C c) { mixin(S_TRACE);
		assert (editMode);
		if (sender is this) return;
		static if (is(CardOwner:CastCard)) {
			refreshAddHand();
		}
		refresh(c);
		sort();
	}
	static if (is(C:EffectCard)) {
		private void delCardCallback(Object sender, CWXPath owner, C c) { mixin(S_TRACE);
			assert (editMode);
			if (sender is this) return;
			if (!cast(Summary)owner) return;
			foreach (card; cards) { mixin(S_TRACE);
				if (card.linkId == c.id) { mixin(S_TRACE);
					refresh(card);
				}
			}
			sort();
		}
	}
	void showCardLife() { mixin(S_TRACE);
		showCardListImpl(CViewMode.LIFE);
	}
	void showCardList() { mixin(S_TRACE);
		showCardListImpl(CViewMode.CARD);
	}
	private void showCardListImpl(CViewMode mode) { mixin(S_TRACE);
		if (_viewMode != mode) { mixin(S_TRACE);
			_viewMode = mode;
			refList();
			updateLayout();
		}
	}
	void showCardTable() { mixin(S_TRACE);
		if (_viewMode != CViewMode.TABLE) { mixin(S_TRACE);
			_viewMode = CViewMode.TABLE;
			refTbl();
			updateLayout();
		}
	}
	private void updateLayout() { mixin(S_TRACE);
		if (_viewMode == CViewMode.TABLE) { mixin(S_TRACE);
			_tbl.getParent().setVisible(true);
			if (_tbl.getHorizontalBar()) _tbl.getHorizontalBar().setVisible(true);
			_list.setVisible(false);
			auto lgd = new GridData(GridData.FILL_HORIZONTAL);
			lgd.heightHint = 0;
			_list.setLayoutData(lgd);
			_tbl.getParent().setLayoutData(new GridData(GridData.FILL_BOTH));
			_pane.layout();
		} else if (_prop.var.etc.showCardListHeader) { mixin(S_TRACE);
			// テーブルのヘッダのみ表示する
			_tbl.getParent().setVisible(true);
			if (_tbl.getHorizontalBar()) _tbl.getHorizontalBar().setVisible(false);
			_list.setVisible(true);
			auto tgd = new GridData(GridData.FILL_HORIZONTAL);
			tgd.heightHint = _tbl.getHeaderHeight();
			_tbl.getParent().setLayoutData(tgd);
			_list.setLayoutData(new GridData(GridData.FILL_BOTH));
			_pane.layout();
		} else { mixin(S_TRACE);
			_tbl.getParent().setVisible(false);
			_list.setVisible(true);
			auto tgd = new GridData(GridData.FILL_HORIZONTAL);
			tgd.heightHint = 0;
			_tbl.getParent().setLayoutData(tgd);
			_list.setLayoutData(new GridData(GridData.FILL_BOTH));
			_pane.layout();
		}
	}

	@property
	void select(int index) { mixin(S_TRACE);
		if (!_tbl || _tbl.isDisposed()) return;
		if (0 <= index) { mixin(S_TRACE);
			selectID(cards[index].id);
		} else if (_viewMode == CViewMode.TABLE) { mixin(S_TRACE);
			_tbl.deselectAll();
		} else { mixin(S_TRACE);
			_list.deselectAll();
		}
		refreshStatusLine();
	}
	void selectID(ulong id) { mixin(S_TRACE);
		if (_viewMode == CViewMode.TABLE) { mixin(S_TRACE);
			foreach (i, itm; _tbl.getItems()) { mixin(S_TRACE);
				auto c = cast(C) itm.getData();
				if (c.id == id) { mixin(S_TRACE);
					_tbl.select(cast(int)i);
					_tbl.showSelection();
					break;
				}
			}
		} else { mixin(S_TRACE);
			foreach (i, c; _list.cards) { mixin(S_TRACE);
				if (c.id == id) { mixin(S_TRACE);
					_list.select(cast(int)i);
					_list.scroll(cast(int)i);
					break;
				}
			}
		}
	}
	@property
	C[] selectedCards() { mixin(S_TRACE);
		if (_viewMode == CViewMode.TABLE) { mixin(S_TRACE);
			C[] r;
			auto sels = _tbl.getSelection();
			r.length = sels.length;
			foreach (i, itm; sels) { mixin(S_TRACE);
				r[i] = cast(C) sels[i].getData();
			}
			return r;
		} else { mixin(S_TRACE);
			return _list.selectionCards;
		}
	}
	@property
	int selectionIndex() { mixin(S_TRACE);
		if (!_summ) return -1;
		if (_viewMode == CViewMode.TABLE) { mixin(S_TRACE);
			return _tbl.getSelectionIndex();
		} else { mixin(S_TRACE);
			return _list.selection;
		}
	}
	@property
	ulong selectionID() { mixin(S_TRACE);
		auto c = selection;
		return c ? c.id : 0;
	}
	@property
	C selection() { mixin(S_TRACE);
		if (!_summ) return null;
		if (_viewMode == CViewMode.TABLE) { mixin(S_TRACE);
			int i = _tbl.getSelectionIndex();
			return -1 != i ? cast(C) _tbl.getItem(i).getData() : null;
		} else { mixin(S_TRACE);
			return _list.selectionCard;
		}
	}

	private void refreshUseCount() { mixin(S_TRACE);
		assert (colIndex(CardTableColumn.UC) != -1);
		if (_viewMode == CViewMode.TABLE) { mixin(S_TRACE);
			foreach (itm; _tbl.getItems()) { mixin(S_TRACE);
				auto c = cast(C) itm.getData();
				itm.setText(colIndex(CardTableColumn.UC), to!(string)(_summ.useCounter.get(C.toID(c.id))));
			}
		}
	}

	void open(bool shellActivate) { mixin(S_TRACE);
		assert (editMode);
		static if (is(CardOwner : Summary)) {
			static if (is(C : CastCard)) {
				_comm.openCastWin(shellActivate);
			} else static if(is(C : SkillCard)) { mixin(S_TRACE);
				_comm.openSkillWin(shellActivate);
			} else static if(is(C : ItemCard)) { mixin(S_TRACE);
				_comm.openItemWin(shellActivate);
			} else static if(is(C : BeastCard)) { mixin(S_TRACE);
				_comm.openBeastWin(shellActivate);
			} else static if(is(C : InfoCard)) { mixin(S_TRACE);
				_comm.openInfoWin(shellActivate);
			} else static assert (0);
		} else static if (is(CardOwner : CastCard)) {
			auto cWin = _comm.handCardWindowFrom(_prop, _summ, _owner, true, shellActivate);
			static if(is(C : SkillCard)) { mixin(S_TRACE);
				cWin.open!(cWin.SKILL)(shellActivate);
			} else static if (is(C : ItemCard)) {
				cWin.open!(cWin.ITEM)(shellActivate);
			} else static if (is(C : BeastCard)) {
				cWin.open!(cWin.BEAST)(shellActivate);
			}
		} else static assert (0);
		_comm.refreshToolBar();
	}
	void create() { mixin(S_TRACE);
		assert (editMode);
		static if (is (C == CastCard)) {
			auto c = new CastCard(0, "", "", "", 1, 1);
			auto dlg = new CastCardDialog(_comm, _prop, dlgParShl, _summ, null, false);
		} else static if (is (C : EffectCard)) {
			auto c = new C(0, "", "", "");
			auto dlg = new EffectCardDialog!(C)(_comm, _prop, dlgParShl, _summ, null, false);
		} else static if (is (C == InfoCard)) {
			auto c = new InfoCard(0, "", "", "");
			auto dlg = new InfoCardDialog(_comm, _prop, dlgParShl, _summ, null, false);
		} else { mixin(S_TRACE);
			static assert (0);
		}
		dlg.appliedEvent ~= { mixin(S_TRACE);
			open(false);
			auto c = dlg.card;
			ulong id;
			static if (is(CardOwner : CastCard)) {
				// CastCardは手札追加時にコピーを生成する
				c = _owner.add(c);
				dlg.card = c;
			} else { mixin(S_TRACE);
				_owner.add(c);
			}
			storeInsert([c.id]);
			refresh();
			selectID(c.id);
			static if (is(C : CastCard)) {
				_comm.refCast.call(this, c);
			} else static if(is(C : SkillCard)) { mixin(S_TRACE);
				_comm.refSkill.call(this, c);
			} else static if(is(C : ItemCard)) { mixin(S_TRACE);
				_comm.refItem.call(this, c);
			} else static if(is(C : BeastCard)) { mixin(S_TRACE);
				_comm.refBeast.call(this, c);
			} else static if(is(C : InfoCard)) { mixin(S_TRACE);
				_comm.refInfo.call(this, c);
			} else static assert (0);
			static if (is (CardOwner : CastCard) && is (C : BeastCard)) {
				_comm.refCast.call(_owner);
			}
			_comm.refreshToolBar();
			dlg.appliedEvent.length = 0;
			dlg.applyEvent ~= { mixin(S_TRACE);
				storeEdit(c.id);
			};
			dlg.appliedEvent ~= { mixin(S_TRACE);
				refresh();
				refCard(c);
				_comm.refreshToolBar();
			};
		};
		_editDlgs[c] = dlg;
		dlg.closeEvent ~= { mixin(S_TRACE);
			_editDlgs.remove(c);
		};
		dlg.open();
	}
	bool addFromNode(ref XNode node, in XMLInfo ver) { mixin(S_TRACE);
		assert (editMode);
		C[] adds;
		bool inPane = false;
		if (node.attr("summId", false) != ownerId) { mixin(S_TRACE);
			node.onTag[C.XML_NAME] = (ref XNode cNode) { mixin(S_TRACE);
				adds ~= C.createFromNode(cNode, ver);
			};
			node.parse();
			if (!qCardMaterialCopy(node, adds)) return false;
		} else { mixin(S_TRACE);
			node.onTag[C.XML_NAME] = (ref XNode cNode) { mixin(S_TRACE);
				auto card = C.createFromNode(cNode, ver);
				if (cNode.attr("paneId", false) != _id || localCard(card.id)) { mixin(S_TRACE);
					adds ~= card;
				} else { mixin(S_TRACE);
					static if (is (CardOwner == Summary)) inPane = true;
					adds ~= card;
				}
			};
			node.parse();
		}
		if (adds.length == 0) return false;
		open(false);
		bool samePane = _id == node.attr("paneId", false);
		bool sameSc = ownerId == node.attr("summId", false);
		bool topLevel = node.attr!bool("topLevel", false, false);
		addCardsImpl(adds, inPane, samePane, sameSc, topLevel);
		return true;
	}
	void addCards(C[] cs) { mixin(S_TRACE);
		assert (editMode);
		addCardsImpl(cs, false, false, false, true);
	}
	void addCardsImpl(C[] adds, bool inPane, bool samePane, bool sameSc, bool topLevel) { mixin(S_TRACE);
		assert (editMode);
		ulong[] ids;
		foreach (card; adds) { mixin(S_TRACE);
			refreshLink(card, samePane, sameSc, topLevel);
			static if (is(CardOwner:Summary)) {
				ulong oldId = _owner.add(card);
				if (inPane) { mixin(S_TRACE);
					// 同じペイン内でコピー&ペースト
					_owner.useCounter.change(C.toID(oldId), C.toID(card.id));
				}
			} else { mixin(S_TRACE);
				card = _owner.add(card);
			}
			ids ~= card.id;
			static if (is(C : CastCard)) {
				_comm.refCast.call(this, card);
			} else static if(is(C : SkillCard)) { mixin(S_TRACE);
				_comm.refSkill.call(this, card);
			} else static if(is(C : ItemCard)) { mixin(S_TRACE);
				_comm.refItem.call(this, card);
			} else static if(is(C : BeastCard)) { mixin(S_TRACE);
				_comm.refBeast.call(this, card);
			} else static if(is(C : InfoCard)) { mixin(S_TRACE);
				_comm.refInfo.call(this, card);
			} else static assert (0);
		}
		storeInsert(ids);
		pasteRefresh(adds);
		_comm.refUseCount.call();
		static if (is (CardOwner : CastCard) && is (C : BeastCard)) {
			_comm.refCast.call(_owner);
		}
	}
	void pasteRefresh(C[] cs) { mixin(S_TRACE);
		assert (editMode);
		if (_viewMode == CViewMode.TABLE) { mixin(S_TRACE);
			foreach (c; cs) { mixin(S_TRACE);
				if (!_incSearch.match(cardName(c))) continue;
				createTableItem(c);
			}
			_tbl.setSelection([_tbl.getItemCount() - 1]);
			_tbl.showSelection();
		} else { mixin(S_TRACE);
			refresh();
			_list.select(_list.count - 1);
			_list.scroll(_list.count - 1);
		}
		refreshStatusLine();
		_comm.refreshToolBar();
	}

	void doImport() { mixin(S_TRACE);
		assert (!editMode);
		string[] paths;
		foreach (card; selectedCards) { mixin(S_TRACE);
			paths ~= card.cwxPath(true);
		}
		_comm.doImport(_toc, _summ, paths);
	}
	@property
	bool canDoImport() { mixin(S_TRACE);
		assert (!editMode);
		return selection !is null;
	}

	void refreshAll(Summary summ, CardOwner owner) { mixin(S_TRACE);
		_owner = owner;
		_summ = summ;
		refresh();
		static if (is(CardOwner:CastCard)) {
			if (editMode) { mixin(S_TRACE);
				refreshAddHand();
			}
		}
	}

	@property
	Table cardTable() { mixin(S_TRACE);
		return _tbl;
	}
	@property
	TableColumn[CardTableColumn] columns() { mixin(S_TRACE);
		TableColumn[CardTableColumn] r;
		r[CardTableColumn.ID] = _tbl.getColumn(colIndex(CardTableColumn.ID));
		r[CardTableColumn.Name] = _tbl.getColumn(colIndex(CardTableColumn.Name));
		r[CardTableColumn.Desc] = _tbl.getColumn(colIndex(CardTableColumn.Desc));
		if (colIndex(CardTableColumn.UC) != -1) { mixin(S_TRACE);
			r[CardTableColumn.UC] = _tbl.getColumn(colIndex(CardTableColumn.UC));
		}
		if (colIndex(CardTableColumn.Num) != -1) { mixin(S_TRACE);
			r[CardTableColumn.Num] = _tbl.getColumn(colIndex(CardTableColumn.Num));
		}
		return r;
	}

	@property
	bool canReNumbering() { mixin(S_TRACE);
		assert (editMode);
		return selection !is null;
	}
	void reNumbering() { mixin(S_TRACE);
		assert (editMode);
		_incSearch.close();
		auto index = selectionIndex;
		auto dlg = new ReNumDialog!(C)(_prop, dlgParShl, _summ, cards[index],
			index == 0 ? 1 : cards[index - 1].id + 1);
		if (dlg.open()) { mixin(S_TRACE);
			_incSearch.close();
			reNumbering(index, dlg.newId);
		}
	}
	void reNumbering(int index, ulong newId) { mixin(S_TRACE);
		assert (editMode);
		if (index < 0 || cards.length <= index) return;
		if (newId == 0) return;
		if (index > 0 && cards[index - 1].id >= newId) return;
		auto undo = new UndoIDs(this, _comm, _owner);
		ulong[] oldIDs;
		for (size_t i = index; i < cards.length; i++) { mixin(S_TRACE);
			oldIDs ~= cards[i].id;
			static if (is (CardOwner : Summary)) {
				ulong ni = ulong.max - cards.length + i;
				owner.useCounter.change(C.toID(cards[i].id), C.toID(ni));
				cards[i].id = ni;
			}
		}
		bool refIDs = false;
		for (size_t i = index; i < cards.length; i++) { mixin(S_TRACE);
			if (oldIDs[i - index] != newId) { mixin(S_TRACE);
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
	CardDialog edit(C c) { mixin(S_TRACE);
		auto p = c in _editDlgs;
		if (p) { mixin(S_TRACE);
			p.active();
			return *p;
		}
		if (0 != linkId(c)) { mixin(S_TRACE);
			assert (cast(EffectCard)c !is null);
			if (editMode) { mixin(S_TRACE);
				auto c2 = cardFrom(_summ, linkId(c));
				if (c2) { mixin(S_TRACE);
					_comm.openCWXPath(c2.cwxPath(true), false);
					static if (is(C:SkillCard)) {
						return _comm.openSkillWin(false).edit(c2);
					} else static if (is(C:ItemCard)) {
						return _comm.openItemWin(false).edit(c2);
					} else static if (is(C:BeastCard)) {
						return _comm.openBeastWin(false).edit(c2);
					}
				}
				return null;
			} else { mixin(S_TRACE);
				c = cardFrom(_summ, linkId(c));
				if (!c) return null;
			}
		}
		static if (is (C == CastCard)) {
			auto dlg = new CastCardDialog(_comm, _prop, dlgParShl, _summ, c, !editMode);
		} else static if (is (C : EffectCard)) {
			auto dlg = new EffectCardDialog!(C)(_comm, _prop, dlgParShl, _summ, c, !editMode);
		} else static if (is (C == InfoCard)) {
			auto dlg = new InfoCardDialog(_comm, _prop, dlgParShl, _summ, c, !editMode);
		} else static assert (0, typeof(C));
		if (editMode) { mixin(S_TRACE);
			dlg.applyEvent ~= { mixin(S_TRACE);
				storeEdit(c.id);
			};
			dlg.appliedEvent ~= { mixin(S_TRACE);
				refresh();
				refCard(c);
				_comm.refreshToolBar();
			};
		}
		dlg.closeEvent ~= { mixin(S_TRACE);
			_editDlgs.remove(c);
		};
		_editDlgs[c] = dlg;
		dlg.open();
		return dlg;
	}
	CardDialog edit() { mixin(S_TRACE);
		if (_viewMode == CViewMode.TABLE) { mixin(S_TRACE);
			int index = _tbl.getSelectionIndex();
			if (index >= 0) { mixin(S_TRACE);
				return edit(cast(C) _tbl.getItem(index).getData());
			}
		} else { mixin(S_TRACE);
			int index = _list.selection;
			if (index >= 0) { mixin(S_TRACE);
				return edit(_list.card(index));
			}
		}
		return null;
	}
	static if (is (C : EffectCard)) {
		void editUseEvent(bool canDuplicate = false) { mixin(S_TRACE);
			auto sel = selection;
			if (sel) editUseEvent(sel, canDuplicate);
		}
		void editUseEvent(C c, bool canDuplicate = false) { mixin(S_TRACE);
			if (0 != linkId(c)) { mixin(S_TRACE);
				if (editMode) { mixin(S_TRACE);
					auto c2 = cardFrom(_summ, linkId(c));
					if (c2) { mixin(S_TRACE);
						_comm.openCWXPath(c2.cwxPath(true), false);
						static if (is(C:SkillCard)) {
							_comm.openSkillWin(false).editUseEvent(c2, canDuplicate);
						} else static if (is(C:ItemCard)) {
							_comm.openItemWin(false).editUseEvent(c2, canDuplicate);
						} else static if (is(C:BeastCard)) {
							_comm.openBeastWin(false).editUseEvent(c2, canDuplicate);
						} else static assert (0);
						return;
					}
					return;
				} else { mixin(S_TRACE);
					c = cardFrom(_summ, linkId(c));
					if (!c) return;
				}
			}
			_comm.openUseEvents(_prop, _summ, c, true, canDuplicate);
		}
	}

	static if (is (C == CastCard)) {
		void editHand() { mixin(S_TRACE);
			assert (editMode);
			auto sel = selection;
			if (sel) { mixin(S_TRACE);
				_comm.openHands(_prop, _summ, sel, true);
			}
		}
	}

	private void udImpl(int index1, int index2) { mixin(S_TRACE);
		assert (editMode);
		if (!(_tbl.getSortColumn() is null || _tbl.getSortColumn() is _idSorter.column)) return;
		auto arr = cardsFrom(_owner);
		if (index1 < 0 || arr.length <= index1) return;
		if (index2 < 0 || arr.length <= index2) return;
		int selIndex = index2;
		if (_tbl.getSortDirection() is SWT.DOWN) { mixin(S_TRACE);
			// ID昇順に変更
			index1 = cast(int)arr.length - index1 - 1;
			index2 = cast(int)arr.length - index2 - 1;
		}
		storeSwap(index1, index2);
		_owner.swap!C(index1, index2);
		refresh();
		arr = cardsFrom(_owner);
		refCard(arr[index1]);
		refCard(arr[index2]);
		select(selIndex);
	}
	bool canUp() { mixin(S_TRACE);
		assert (editMode);
		if (!_summ) return false;
		if (!_tbl || !_list || !_incSearch) return false;
		if (_tbl.isDisposed()) return false;
		if (narrowCount != cards.length) return false;
		if (!(_tbl.getSortColumn() is null || _tbl.getSortColumn() is _idSorter.column)) return false;
		int sel = selectionIndex;
		return sel != -1 && 0 < sel;
	}
	bool canDown() { mixin(S_TRACE);
		assert (editMode);
		if (!_summ) return false;
		if (!_tbl || !_list || !_incSearch) return false;
		if (_tbl.isDisposed()) return false;
		if (narrowCount != cards.length) return false;
		if (!(_tbl.getSortColumn() is null || _tbl.getSortColumn() is _idSorter.column)) return false;
		int sel = selectionIndex;
		return sel != -1 && sel + 1 < cards.length;
	}
	void up() { mixin(S_TRACE);
		assert (editMode);
		if (!canUp()) return;
		int sel = selectionIndex;
		if (-1 == sel) return;
		udImpl(sel, sel - 1);
		_comm.refreshToolBar();
	}
	void down() { mixin(S_TRACE);
		assert (editMode);
		if (!canDown()) return;
		int sel = selectionIndex;
		if (-1 == sel) return;
		udImpl(sel, sel + 1);
		_comm.refreshToolBar();
	}

	bool isSelected() { mixin(S_TRACE);
		return selectionIndex != -1;
	}

	override {
		void cut(SelectionEvent se) { mixin(S_TRACE);
			if (editMode) { mixin(S_TRACE);
				foreach (c; _tcpd) { mixin(S_TRACE);
					if (c.canDoTCPD) { mixin(S_TRACE);
						c.cut(se);
					}
				}
			}
		}
		void copy(SelectionEvent se) { mixin(S_TRACE);
			foreach (c; _tcpd) { mixin(S_TRACE);
				if (c.canDoTCPD) { mixin(S_TRACE);
					c.copy(se);
				}
			}
		}
		void paste(SelectionEvent se) { mixin(S_TRACE);
			if (editMode) { mixin(S_TRACE);
				foreach (c; _tcpd) { mixin(S_TRACE);
					if (c.canDoTCPD) { mixin(S_TRACE);
						c.paste(se);
					}
				}
			}
		}
		void del(SelectionEvent se) { mixin(S_TRACE);
			if (editMode) { mixin(S_TRACE);
				foreach (c; _tcpd) { mixin(S_TRACE);
					if (c.canDoTCPD) { mixin(S_TRACE);
						c.del(se);
					}
				}
			}
		}
		void clone(SelectionEvent se) { mixin(S_TRACE);
			if (editMode) { mixin(S_TRACE);
				foreach (c; _tcpd) { mixin(S_TRACE);
					if (c.canDoTCPD) { mixin(S_TRACE);
						c.clone(se);
					}
				}
			}
		}
		@property
		bool canDoTCPD() { mixin(S_TRACE);
			return _list.isVisible() || _tbl.isVisible();
		}
		@property
		bool canDoT() { mixin(S_TRACE);
			if (!editMode) return false;
			foreach (c; _tcpd) { mixin(S_TRACE);
				if (c.canDoTCPD) return c.canDoT;
			}
			return false;
		}
		@property
		bool canDoC() { mixin(S_TRACE);
			foreach (c; _tcpd) { mixin(S_TRACE);
				if (c.canDoTCPD) return c.canDoC;
			}
			return false;
		}
		@property
		bool canDoP() { mixin(S_TRACE);
			if (!editMode) return false;
			foreach (c; _tcpd) { mixin(S_TRACE);
				if (c.canDoTCPD) return c.canDoP;
			}
			return false;
		}
		@property
		bool canDoD() { mixin(S_TRACE);
			if (!editMode) return false;
			foreach (c; _tcpd) { mixin(S_TRACE);
				if (c.canDoTCPD) return c.canDoD;
			}
			return false;
		}
		@property
		bool canDoClone() { mixin(S_TRACE);
			if (!editMode) return false;
			foreach (c; _tcpd) { mixin(S_TRACE);
				if (c.canDoTCPD) return c.canDoClone;
			}
			return false;
		}
	}

	void undo() { mixin(S_TRACE);
		assert (editMode);
		_undo.undo();
		_comm.refreshToolBar();
	}
	void redo() { mixin(S_TRACE);
		assert (editMode);
		_undo.redo();
		_comm.refreshToolBar();
	}
	bool canUndo() { mixin(S_TRACE);
		assert (editMode);
		return _undo.canUndo();
	}
	bool canRedo() { mixin(S_TRACE);
		assert (editMode);
		return _undo.canRedo();
	}

	void replaceID() {
		assert (editMode);
		auto sel = selection;
		if (sel) _comm.replaceID(C.toID(sel.id), true);
	}
	@property
	bool canReplaceID() {
		assert (editMode);
		return selection !is null;
	}

	@property
	bool canSelectConnectedResource() { mixin(S_TRACE);
		assert (editMode);
		if (!selection) return false;
		auto c = selection;
		if (0 != linkId(c)) { mixin(S_TRACE);
			c = pOwnerCard(linkId(c));
			if (!c) return false;
		}
		return _summ.hasMaterial(c.connectedFile, _prop.var.etc.ignorePaths);
	}
	void selectConnectedResource() { mixin(S_TRACE);
		assert (editMode);
		if (!selection) return;
		auto c = selection;
		if (0 != linkId(c)) { mixin(S_TRACE);
			c = pOwnerCard(linkId(c));
			if (!c) return;
		}
		auto file = c.connectedFile;
		if (_summ.hasMaterial(file, _prop.var.etc.ignorePaths)) { mixin(S_TRACE);
			_comm.openFilePath(file, false, true);
		}
	}

	@property
	string[] openedCWXPath() { mixin(S_TRACE);
		string[] r;
		foreach (c; selectedCards) { mixin(S_TRACE);
			r ~= c.cwxPath(true);
		}
		if (!r.length) { mixin(S_TRACE);
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

template CastCardPane(CardOwner) {
	alias CardPane!(CardOwner, CastCard) CastCardPane;
}
template SkillCardPane(CardOwner) {
	alias CardPane!(CardOwner, SkillCard) SkillCardPane;
}
template ItemCardPane(CardOwner) {
	alias CardPane!(CardOwner, ItemCard) ItemCardPane;
}
template BeastCardPane(CardOwner) {
	alias CardPane!(CardOwner, BeastCard) BeastCardPane;
}
template InfoCardPane(CardOwner) {
	alias CardPane!(CardOwner, InfoCard) InfoCardPane;
}
alias CastCardPane!(Summary) MainCastCardPane;
alias SkillCardPane!(Summary) MainSkillCardPane;
alias ItemCardPane!(Summary) MainItemCardPane;
alias BeastCardPane!(Summary) MainBeastCardPane;
alias InfoCardPane!(Summary) MainInfoCardPane;
