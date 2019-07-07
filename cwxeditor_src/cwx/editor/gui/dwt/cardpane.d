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
import cwx.editor.gui.dwt.absdialog;

import std.algorithm;
import std.array;
import std.utf;
import std.string;
import std.datetime;
import std.typetuple;
import std.path;
import std.conv;
import std.range : zip, iota;

import org.eclipse.swt.all;

import java.lang.all;

enum CViewMode { INIT, LIFE, CARD, TABLE }
enum CardTableColumn { ID, Name, Desc, UC, Num }
enum CardType { Cast, Skill, Item, Beast, Info }
enum OwnerType { Summary, Cast }

interface CardDialog {
	@property
	Card card();

	bool openCWXPath(string cwxPath, bool shellActivate);
}

class CardPane : TCPD {
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
			if (_ownerType is OwnerType.Summary) { mixin(S_TRACE);
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
	private static inout(Card)[] cardsFrom(CardType cardType, inout CWXPath owner) { mixin(S_TRACE);
		if (!owner) return [];
		final switch (cardType) {
		case CardType.Cast:
			if (auto o = cast(inout CastOwner)owner) {
				return cast(inout(Card)[])(o.casts);
			}
			break;
		case CardType.Skill:
			if (auto o = cast(inout SkillOwner)owner) {
				return cast(inout(Card)[])(o.skills);
			}
			break;
		case CardType.Item:
			if (auto o = cast(inout ItemOwner)owner) {
				return cast(inout(Card)[])(o.items);
			}
			break;
		case CardType.Beast:
			if (auto o = cast(inout BeastOwner)owner) {
				return cast(inout(Card)[])(o.beasts);
			}
			break;
		case CardType.Info:
			if (auto o = cast(inout InfoOwner)owner) {
				return cast(inout(Card)[])(o.infos);
			}
			break;
		}
		assert (0);
	}
	@property
	public Card[] cards() { return cardsFrom(_cardType, owner); }
	@property
	private Card[] cardsNarrow() { mixin(S_TRACE);
		if (_owner) { mixin(S_TRACE);
			Card[] r;
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
	public static inout(Card) cardFrom(inout CWXPath owner, CardType cardType, ulong id) { mixin(S_TRACE);
		if (!owner) return null;
		final switch (cardType) {
		case CardType.Cast:
			if (auto o = cast(inout CastOwner)owner) return o.cwCast(id);
			break;
		case CardType.Skill:
			if (auto o = cast(inout SkillOwner)owner) return o.skill(id);
			break;
		case CardType.Item:
			if (auto o = cast(inout ItemOwner)owner) return o.item(id);
			break;
		case CardType.Beast:
			if (auto o = cast(inout BeastOwner)owner) return o.beast(id);
			break;
		case CardType.Info:
			if (auto o = cast(inout InfoOwner)owner) return o.info(id);
			break;
		}
		assert (0);
	}
	public Card card(ulong id) { mixin(S_TRACE);
		return cardFrom(_owner, _cardType, id);
	}
	private Card localCard(ulong id) { mixin(S_TRACE);
		if (_owner) { mixin(S_TRACE);
			return card(id);
		}
		return null;
	}
	@property
	private static ulong linkId(in Card card) {
		if (auto eff = cast(const EffectCard)card) {
			return eff.linkId;
		} else {
			return 0;
		}
	}
	private inout(Card) baseCard(inout(Card) card) { mixin(S_TRACE);
		if (0 != linkId(card)) { mixin(S_TRACE);
			auto c = cast(inout Card)pOwnerCard(linkId(card));
			if (c) return c;
		}
		return card;
	}
	private string cardName(in Card card) { mixin(S_TRACE);
		return baseCard(card).name;
	}
	private string cardDesc(in Card card) { mixin(S_TRACE);
		return baseCard(card).desc;
	}
	private int cardNum(in Card card) { mixin(S_TRACE);
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
	inout
	private inout(Card)[] pOwnerCards() { return cardsFrom(_cardType, _summ); }
	inout
	private inout(Card) pOwnerCard(ulong id) { return cardFrom(_summ, _cardType, id); }

	@property
	const
	private const(CardType)[] types() { mixin(S_TRACE);
		return _ownerType is OwnerType.Summary
			? [CardType.Cast, CardType.Skill, CardType.Item, CardType.Beast, CardType.Info]
			: [CardType.Skill, CardType.Item, CardType.Beast];
	}
	static string xmlNameFrom(CardType cardType) { mixin(S_TRACE);
		final switch (cardType) {
		case CardType.Cast:
			return CastCard.XML_NAME;
		case CardType.Skill:
			return SkillCard.XML_NAME;
		case CardType.Item:
			return ItemCard.XML_NAME;
		case CardType.Beast:
			return BeastCard.XML_NAME;
		case CardType.Info:
			return InfoCard.XML_NAME;
		}
	}
	@property
	const
	string xmlName() { mixin(S_TRACE);
		final switch (_cardType) {
		case CardType.Cast:
			return CastCard.XML_NAME;
		case CardType.Skill:
			return SkillCard.XML_NAME;
		case CardType.Item:
			return ItemCard.XML_NAME;
		case CardType.Beast:
			return BeastCard.XML_NAME;
		case CardType.Info:
			return InfoCard.XML_NAME;
		}
	}
	@property
	const
	string xmlNameM() { mixin(S_TRACE);
		final switch (_cardType) {
		case CardType.Cast:
			return CastCard.XML_NAME_M;
		case CardType.Skill:
			return SkillCard.XML_NAME_M;
		case CardType.Item:
			return ItemCard.XML_NAME_M;
		case CardType.Beast:
			return BeastCard.XML_NAME_M;
		case CardType.Info:
			return InfoCard.XML_NAME_M;
		}
	}
	@property
	const
	Card createFromNode(ref XNode node, in XMLInfo ver) { mixin(S_TRACE);
		if (node.name == CastCard.XML_NAME) { mixin(S_TRACE);
			return CastCard.createFromNode(node, ver);
		} else if (node.name == SkillCard.XML_NAME) { mixin(S_TRACE);
			return SkillCard.createFromNode(node, ver);
		} else if (node.name == ItemCard.XML_NAME) { mixin(S_TRACE);
			return ItemCard.createFromNode(node, ver);
		} else if (node.name == BeastCard.XML_NAME) { mixin(S_TRACE);
			return BeastCard.createFromNode(node, ver);
		} else if (node.name == InfoCard.XML_NAME) { mixin(S_TRACE);
			return InfoCard.createFromNode(node, ver);
		} else assert (0);
	}
	static void change(UseCounter uc, CardType cardType, ulong from, ulong to) { mixin(S_TRACE);
		final switch (cardType) {
		case CardType.Cast:
			uc.change(CastCard.toID(from), CastCard.toID(to));
			break;
		case CardType.Skill:
			uc.change(SkillCard.toID(from), SkillCard.toID(to));
			break;
		case CardType.Item:
			uc.change(ItemCard.toID(from), ItemCard.toID(to));
			break;
		case CardType.Beast:
			uc.change(BeastCard.toID(from), BeastCard.toID(to));
			break;
		case CardType.Info:
			uc.change(InfoCard.toID(from), InfoCard.toID(to));
			break;
		}
	}
	static int ucGet(in UseCounter uc, CardType cardType, ulong id) { mixin(S_TRACE);
		final switch (cardType) {
		case CardType.Cast:
			return uc.get(CastCard.toID(id));
		case CardType.Skill:
			return uc.get(SkillCard.toID(id));
		case CardType.Item:
			return uc.get(ItemCard.toID(id));
		case CardType.Beast:
			return uc.get(BeastCard.toID(id));
		case CardType.Info:
			return uc.get(InfoCard.toID(id));
		}
	}
	static ptrdiff_t indexOf(in CWXPath owner, CardType cardType, in Card card) { mixin(S_TRACE);
		if (auto c = cast(Summary)owner) { mixin(S_TRACE);
			final switch (cardType) {
			case CardType.Cast:
				return c.indexOf(cast(CastCard)card);
			case CardType.Skill:
				return c.indexOf(cast(SkillCard)card);
			case CardType.Item:
				return c.indexOf(cast(ItemCard)card);
			case CardType.Beast:
				return c.indexOf(cast(BeastCard)card);
			case CardType.Info:
				return c.indexOf(cast(InfoCard)card);
			}
		} else if (auto c = cast(CastCard)owner) { mixin(S_TRACE);
			final switch (cardType) {
			case CardType.Cast:
				assert (0);
			case CardType.Skill:
				return c.indexOf(cast(SkillCard)card);
			case CardType.Item:
				return c.indexOf(cast(ItemCard)card);
			case CardType.Beast:
				return c.indexOf(cast(BeastCard)card);
			case CardType.Info:
				assert (0);
			}
		} else assert (0);
	}

	static void insert(CWXPath owner, int index, Card card) {
		if (auto c = cast(Summary)owner) { mixin(S_TRACE);
			if (auto c2 = cast(CastCard)card) {
				c.insert(index, c2);
			} else if (auto c2 = cast(SkillCard)card) {
				c.insert(index, c2);
			} else if (auto c2 = cast(ItemCard)card) {
				c.insert(index, c2);
			} else if (auto c2 = cast(BeastCard)card) {
				c.insert(index, c2);
			} else if (auto c2 = cast(InfoCard)card) {
				c.insert(index, c2);
			} else assert (0);
		} else if (auto c = cast(CastCard)owner) { mixin(S_TRACE);
			if (auto c2 = cast(SkillCard)card) {
				c.insert(index, c2);
			} else if (auto c2 = cast(ItemCard)card) {
				c.insert(index, c2);
			} else if (auto c2 = cast(BeastCard)card) {
				c.insert(index, c2);
			} else assert (0);
		} else assert (0);
	}

	static void remove(CWXPath owner, in Card card) {
		if (auto c = cast(Summary)owner) { mixin(S_TRACE);
			if (auto c2 = cast(CastCard)card) {
				c.remove(c2);
			} else if (auto c2 = cast(SkillCard)card) {
				c.remove(c2);
			} else if (auto c2 = cast(ItemCard)card) {
				c.remove(c2);
			} else if (auto c2 = cast(BeastCard)card) {
				c.remove(c2);
			} else if (auto c2 = cast(InfoCard)card) {
				c.remove(c2);
			} else assert (0);
		} else if (auto c = cast(CastCard)owner) { mixin(S_TRACE);
			if (auto c2 = cast(SkillCard)card) {
				c.remove(c2);
			} else if (auto c2 = cast(ItemCard)card) {
				c.remove(c2);
			} else if (auto c2 = cast(BeastCard)card) {
				c.remove(c2);
			} else assert (0);
		} else assert (0);
	}

	static ulong add(Summary owner, Card card) {
		if (auto c = cast(CastCard)card) {
			return owner.add(c);
		} else if (auto c = cast(SkillCard)card) {
			return owner.add(c);
		} else if (auto c = cast(ItemCard)card) {
			return owner.add(c);
		} else if (auto c = cast(BeastCard)card) {
			return owner.add(c);
		} else if (auto c = cast(InfoCard)card) {
			return owner.add(c);
		} else assert (0);
	}
	static Card add(CastCard owner, Card card) {
		if (auto c = cast(SkillCard)card) {
			return owner.add(c);
		} else if (auto c = cast(ItemCard)card) {
			return owner.add(c);
		} else if (auto c = cast(BeastCard)card) {
			return owner.add(c);
		} else assert (0);
	}
	CardPane openSameLevelPane(CardType cardType, bool shellActivate) {
		if (_ownerType is OwnerType.Summary) { mixin(S_TRACE);
			return _comm.openCardPane(cardType, shellActivate);
		} else if (_ownerType is OwnerType.Cast) { mixin(S_TRACE);
			assert (cardType !is CardType.Cast && cardType !is CardType.Info);
			auto win = _comm.openHands(_prop, _summ, cast(CastCard)_owner, shellActivate);
			return win.openPane(cardType, shellActivate);
		} else assert (0);
	}
	static CardType cardTypeFrom(in Card card) {
		if (cast(CastCard)card) {
			return CardType.Cast;
		} else if (cast(SkillCard)card) {
			return CardType.Skill;
		} else if (cast(ItemCard)card) {
			return CardType.Item;
		} else if (cast(BeastCard)card) {
			return CardType.Beast;
		} else if (cast(InfoCard)card) {
			return CardType.Info;
		} else assert (0);
	}
private:
	static class CPUndo : Undo {
		protected CardPane _v = null;
		protected Commons comm;
		protected CWXPath owner;
		protected immutable OwnerType ownerType;
		protected immutable CardType cardType;

		private ulong[] _ids;
		private ulong[] _idsB;
		private ulong[] _sel;
		private ulong[] _selB;

		this (CardPane v, Commons comm, CWXPath owner) { mixin(S_TRACE);
			_v = v;
			this.comm = comm;
			this.owner = owner;
			this.ownerType = v._ownerType;
			this.cardType = v._cardType;

			saveIDs(v);
		}
		private void saveIDs(CardPane v) { mixin(S_TRACE);
			_ids.length = 0;
			foreach (c; cardsFrom(cardType, owner)) _ids ~= c.id;
			if (v && v.widget && !v.widget.isDisposed()) { mixin(S_TRACE);
				_sel = v.selectionIDs;
			}
		}
		abstract override void undo();
		abstract override void redo();
		abstract override void dispose();
		protected void udb(CardPane v) { mixin(S_TRACE);
			_idsB = _ids.dup;
			_selB = _sel.dup;
			saveIDs(v);
			if (v && v.widget && !v.widget.isDisposed()) { mixin(S_TRACE);
				.forceFocus(v.widget, false);
			}
		}
		private void resetID(CardPane v) { mixin(S_TRACE);
			ulong[] oldIDs;
			auto arr = cardsFrom(cardType, owner);
			foreach (i, c; arr) { mixin(S_TRACE);
				auto oID = c.id;
				c.id = ulong.max - arr.length + i;
				if (ownerType is OwnerType.Summary) change(comm.summary.useCounter, cardType, oID, c.id);
				oldIDs ~= oID;
			}
			foreach (i, c; arr) { mixin(S_TRACE);
				auto oID = c.id;
				c.id = _idsB[i];
				if (ownerType is OwnerType.Summary) change(comm.summary.useCounter, cardType, oID, c.id);
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
		this (CardPane v, Commons comm, CWXPath owner) { mixin(S_TRACE);
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
		private Card[] _card;
		private ulong[] _id;
		private Card create(in Card c) { mixin(S_TRACE);
			if (cast(CastCard)c) {
				return new CastCard(c.id, c.name, c.paths, c.desc);
			} else if (cast(SkillCard)c) {
				return new SkillCard(comm.prop.sys, c.id, c.name, c.paths, c.desc);
			} else if (cast(ItemCard)c) {
				return new ItemCard(comm.prop.sys, c.id, c.name, c.paths, c.desc);
			} else if (cast(BeastCard)c) {
				return new BeastCard(comm.prop.sys, c.id, c.name, c.paths, c.desc);
			} else if (cast(InfoCard)c) {
				return new InfoCard(c.id, c.name, c.paths, c.desc);
			} else assert (0);
		}
		private void shallowCopy(Card dest, in Card base) { mixin(S_TRACE);
			final switch (cardType) {
			case CardType.Cast:
				(cast(CastCard)dest).shallowCopy(cast(CastCard)base);
				break;
			case CardType.Skill:
				(cast(SkillCard)dest).shallowCopy(cast(SkillCard)base);
				break;
			case CardType.Item:
				(cast(ItemCard)dest).shallowCopy(cast(ItemCard)base);
				break;
			case CardType.Beast:
				(cast(BeastCard)dest).shallowCopy(cast(BeastCard)base);
				break;
			case CardType.Info:
				(cast(InfoCard)dest).shallowCopy(cast(InfoCard)base);
				break;
			}
		}
		this (CardPane v, Commons comm, CWXPath owner, in ulong[] ids) { mixin(S_TRACE);
			super (v, comm, owner);
			foreach (id; ids) {
				auto c = cardFrom(owner, cardType, id);
				auto card = create(c);
				shallowCopy(card, c);
				card.setUseCounter(c.useCounter.sub, c);
				_card ~= card;
			}
			_id = ids.dup;
		}
		private void impl() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			foreach (i, id; _id) { mixin(S_TRACE);
				auto card = _card[i];
				card.removeUseCounter();
				auto c = cardFrom(owner, cardType, id);
				_card[i] = create(c);
				shallowCopy(_card[i], c);
				_card[i].setUseCounter(c.useCounter.sub, c);
				shallowCopy(c, card);

				refCard(v, comm, c);
			}
			if (v && v.widget && !v.widget.isDisposed()) { mixin(S_TRACE);
				v.refresh();
			}
			comm.refUseCount.call();
		}
		override void undo() { mixin(S_TRACE);
			impl();
		}
		override void redo() { mixin(S_TRACE);
			impl();
		}
		override void dispose() { mixin(S_TRACE);
			foreach (card; _card) card.removeUseCounter();
		}
	}
	void storeEdit(ulong[] id) { mixin(S_TRACE);
		assert (editMode);
		_undo ~= new UndoEdit(this, _comm, _owner, id);
	}
	static void swap(CWXPath owner, CardType cardType, int index1, int index2) { mixin(S_TRACE);
		if (auto c = cast(Summary)owner) { mixin(S_TRACE);
			final switch (cardType) {
			case CardType.Cast:
				c.swap!CastCard(index1, index2);
				break;
			case CardType.Skill:
				c.swap!SkillCard(index1, index2);
				break;
			case CardType.Item:
				c.swap!ItemCard(index1, index2);
				break;
			case CardType.Beast:
				c.swap!BeastCard(index1, index2);
				break;
			case CardType.Info:
				c.swap!InfoCard(index1, index2);
				break;
			}
		} else if (auto c = cast(CastCard)owner) { mixin(S_TRACE);
			final switch (cardType) {
			case CardType.Cast:
				assert (0);
			case CardType.Skill:
				c.swap!SkillCard(index1, index2);
				break;
			case CardType.Item:
				c.swap!ItemCard(index1, index2);
				break;
			case CardType.Beast:
				c.swap!BeastCard(index1, index2);
				break;
			case CardType.Info:
				assert (0);
			}
		} else assert (0);
	}
	static class UndoSwap : CPUndo {
		private int[] _indices;
		private bool _up;
		this (CardPane v, Commons comm, CWXPath owner, in int[] indices, bool up) { mixin(S_TRACE);
			super (v, comm, owner);
			_indices = indices.dup;
			_up = up;
		}
		private void impl() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);

			if (_up) {
				_indices[] -= 1;
			} else {
				_indices[] += 1;
			}
			_up = !_up;

			udImpl(v, comm, owner, cardType, _indices, _up);
		}
		override void undo() { mixin(S_TRACE);
			impl();
		}
		override void redo() { mixin(S_TRACE);
			impl();
		}
		override void dispose() { }
	}
	void storeUp(in int[] indices) { mixin(S_TRACE);
		assert (editMode);
		assert (_tbl.getSortColumn() is null || _tbl.getSortColumn() is _idSorter.column);
		_undo ~= new UndoSwap(this, _comm, _owner, indices, true);
	}
	void storeDown(in int[] indices) { mixin(S_TRACE);
		assert (editMode);
		assert (_tbl.getSortColumn() is null || _tbl.getSortColumn() is _idSorter.column);
		_undo ~= new UndoSwap(this, _comm, _owner, indices, false);
	}
	static class UndoMove : CPUndo {
		private const(int)[] _from;
		private int _to;
		this (CardPane v, Commons comm, CWXPath owner, const(int)[] from, int to) { mixin(S_TRACE);
			super (v, comm, owner);
			_from = from;
			_to = to;
		}
		override void undo() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);

			auto array = cardsFrom(cardType, owner);
			Card[] cards;
			auto toIndex = _to;
			foreach (index; _from) { mixin(S_TRACE);
				if (index < _to) { mixin(S_TRACE);
					toIndex--;
				} else { mixin(S_TRACE);
					break;
				}
			}
			foreach (i; toIndex .. toIndex + _from.length) { mixin(S_TRACE);
				cards ~= array[i];
			}
			foreach (i, card, fIndex; .zip(0.iota(_from.length), cards, _from)) { mixin(S_TRACE);
				int index = fIndex;
				if (_to < index) { mixin(S_TRACE);
					index += _from.length;
					index -= i;
				}
				insert(owner, index, card);
			}
		}
		override void redo() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);

			auto array = cardsFrom(cardType, owner);
			Card[] adds;
			foreach (i; _from) { mixin(S_TRACE);
				adds ~= array[i];
			}
			moveCards(owner, cardType, adds, _to);
			if (v && v.widget && !v.widget.isDisposed()) { mixin(S_TRACE);
				v.selectMovedCards(adds);
			}
		}
		override void dispose() { }
	}
	void storeMove(const(int)[] from, int to) { mixin(S_TRACE);
		assert (editMode);
		assert (_tbl.getSortColumn() is null || _tbl.getSortColumn() is _idSorter.column);
		_undo ~= new UndoMove(this, _comm, _owner, from, to);
	}
	static class UndoInsertDelete : CPUndo {
		private bool _insert;

		private ulong[] _ids;

		private Card[] _cards = [];
		private int[] _indices;

		this (CardPane v, Commons comm, CWXPath owner, ulong[] ids, bool insert) { mixin(S_TRACE);
			super (v, comm, owner);
			_insert = insert;
			_ids = ids.dup;
			std.algorithm.sort(_ids);

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
				auto c = cardFrom(owner, cardType, id);
				auto card = c.dup;
				card.setUseCounter(c.useCounter.sub, c);
				_cards ~= card;
				_indices ~= cast(int)indexOf(owner, cardType, c);
			}
		}
		private void undoInsert() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			_insert = false;
			initUndoDelete();
			foreach_reverse (id; _ids) { mixin(S_TRACE);
				auto card = cardFrom(owner, cardType, id);
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
			bool[CastCard] casts;
			foreach (i, id; _ids) { mixin(S_TRACE);
				assert (_indices[i] != -1);
				auto c = _cards[i];
				c.removeUseCounter();
				insert(owner, _indices[i], c);
				if (auto cc = cast(CastCard)owner) casts[cc] = true;
				selID = id;
			}
			if (v && v.widget && !v.widget.isDisposed()) { mixin(S_TRACE);
				v.refresh();
				v.selectID(selID);
				v.refreshStatusLine();
			}
			foreach (cc; casts.byKey()) refCard(v, comm, cc);
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
	CWXPath _owner = null;
	Summary _summ = null;
	void delegate(Shell) _save;
	CardList!Card _list;
	CardListEdit!Card _cle = null;
	Table _tbl;
	TableTextEdit _tte = null;
	TableTCEdit _ttce = null;
	Image _cimg;
	CViewMode _viewMode = CViewMode.INIT;
	TCPD[] _tcpd;
	Summary _toc = null;
	string _statusLine = "";
	Preview _preview;
	Card _previewC = null;
	PileImage _previewI = null;
	void closePreview() { mixin(S_TRACE);
		if (_previewI) { mixin(S_TRACE);
			_preview.close();
			_previewC = null;
			_previewI.dispose();
		}
	}
	Card _openEventTarget = null;

	TableSorter!Card _idSorter;
	TableSorter!Card _descSorter;
	TableSorter!Card _nameSorter;

	IncSearch _incSearch = null;
	private void incSearch() { mixin(S_TRACE);
		.forceFocus(widget, true);
		_incSearch.startIncSearch();
	}

	bool compID(const Card c1, const Card c2) { mixin(S_TRACE);
		if (c1.id < c2.id) return true;
		if (c1.id > c2.id) return false;
		return false;
	}
	bool compName(const Card c1, const Card c2) { mixin(S_TRACE);
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
	bool compDesc(const Card c1, const Card c2) { mixin(S_TRACE);
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
	bool revCompID(const Card c1, const Card c2) { mixin(S_TRACE);
		if (c2.id < c1.id) return true;
		if (c2.id > c1.id) return false;
		return false;
	}
	bool revCompName(const Card c1, const Card c2) { mixin(S_TRACE);
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
	bool revCompDesc(const Card c1, const Card c2) { mixin(S_TRACE);
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
	TableSorter!Card _ucSorter;
	bool compUC(const Card c1, const Card c2) { mixin(S_TRACE);
		assert (colIndex(CardTableColumn.UC) != -1);
		int uc1 = ucGet(summary.useCounter, _cardType, c1.id);
		int uc2 = ucGet(summary.useCounter, _cardType, c2.id);
		if (uc1 < uc2) return true;
		if (uc1 > uc2) return false;
		return compID(c1, c2);
	}
	bool revCompUC(const Card c1, const Card c2) { mixin(S_TRACE);
		assert (colIndex(CardTableColumn.UC) != -1);
		int uc1 = ucGet(summary.useCounter, _cardType, c2.id);
		int uc2 = ucGet(summary.useCounter, _cardType, c1.id);
		if (uc1 < uc2) return true;
		if (uc1 > uc2) return false;
		return compID(c1, c2);
	}
	TableSorter!Card _numSorter = null;
	bool compNum(const Card c1, const Card c2) { mixin(S_TRACE);
		assert (useNum);
		int num1 = cardNum(c1);
		int num2 = cardNum(c2);
		if (num1 < num2) return true;
		if (num1 > num2) return false;
		return compID(c1, c2);
	}
	bool revCompNum(const Card c1, const Card c2) { mixin(S_TRACE);
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
	void sort(ref Card[] cards) { mixin(S_TRACE);
		bool delegate(const Card, const Card) minL = null;
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
				} else assert (0, .format("%s, %s", _cardType.to!string(), useNum.to!string()));
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
			if (_ownerType is OwnerType.Cast) { mixin(S_TRACE);
				int vc;
				auto o = cast(CastCard)owner;
				final switch (_cardType) {
				case CardType.Cast:
					assert (0);
				case CardType.Skill:
					vc = _prop.looks.skillCardMaxNum(o.level);
					break;
				case CardType.Item:
					vc = _prop.looks.itemCardMaxNum(o.level);
					break;
				case CardType.Beast:
					vc = _prop.looks.beastCardMaxNum(o.level);
					break;
				case CardType.Info:
					assert (0);
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
		auto itms = itm.getParent().getSelection();
		Card[] cards;
		foreach (itm2; itms) { mixin(S_TRACE);
			auto c = cast(Card)itm2.getData();
			if (c.name == newText) continue;
			cards ~= c;
		}
		if (!cards.length) return;
		storeEdit(.map!(card => card.id)(cards).array());
		foreach (c; cards) { mixin(S_TRACE);
			c.name = newText;
			refCard(c);
		}
		refresh();
		_comm.refreshToolBar();
	}

	Control numCreateEditor(TableItem itm, int column) { mixin(S_TRACE);
		assert (useNum);
		assert (editMode);
		auto c = cast(Card)itm.getData();
		auto spn = new Spinner(itm.getParent(), SWT.BORDER);
		initSpinner(spn);
		int max, min;
		final switch (_cardType) {
		case CardType.Cast:
			max = _prop.var.etc.castLevelMax;
			min = 1;
			break;
		case CardType.Skill:
			max = _prop.var.etc.skillLevelMax;
			min = 0;
			break;
		case CardType.Item:
			max = _prop.var.etc.useCountMax;
			min = 0;
			break;
		case CardType.Beast:
			max = _prop.var.etc.useCountMax;
			min = 0;
			break;
		case CardType.Info:
			assert (0);
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
		auto itms = itm.getParent().getSelection();
		Card[] cards;
		foreach (itm2; itms) { mixin(S_TRACE);
			auto c = cast(Card)itm2.getData();
			final switch (_cardType) {
			case CardType.Cast:
				if ((cast(CastCard)c).level == num) continue;
				break;
			case CardType.Skill:
				if ((cast(SkillCard)c).level == num) continue;
				break;
			case CardType.Item:
				auto s = cast(ItemCard)c;
				int useLimit = s.useLimit, useLimitMax = s.useLimitMax;
				if (useLimitMax == useLimit) { mixin(S_TRACE);
					useLimit = num;
				}
				useLimitMax = num;
				useLimit = .min(useLimit, useLimitMax);
				if (s.useLimit == useLimit && s.useLimitMax == useLimitMax) continue;
				break;
			case CardType.Beast:
				if ((cast(BeastCard)c).useLimit == num) continue;
				break;
			case CardType.Info:
				assert (0);
			}
			cards ~= c;
		}
		if (!cards.length) return;
		storeEdit(.map!(card => card.id)(cards).array());
		foreach (c; cards) { mixin(S_TRACE);
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
			refCard(c);
		}
		refresh();
		_comm.refreshToolBar();
	}

	bool canEditT(TableItem itm, int column) { mixin(S_TRACE);
		assert (editMode);
		auto card = cast(Card)itm.getData();
		return linkId(card) == 0;
	}
	void refreshR(string from, string to) { mixin(S_TRACE);
		refreshImpl();
	}
	void refresh(Card c, bool updateStatus = true) { mixin(S_TRACE);
		if (!_tbl || _tbl.isDisposed()) return;
		void update(size_t i, Card card) { mixin(S_TRACE);
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
				update(i, cast(Card)itm.getData());
			}
		} else { mixin(S_TRACE);
			foreach (i, card; _list.cards) { mixin(S_TRACE);
				update(i, card);
			}
		}
		if (updateStatus) refreshStatusLine();
	}
	void refreshImpl() { mixin(S_TRACE);
		closePreview();
		auto cards = cardsNarrow;
		sort(cards);
		if (_cle) _cle.cancel();
		if (_viewMode == CViewMode.TABLE) { mixin(S_TRACE);
			_list.refresh([], &cardImage, _prop.var.etc.showCardListTitle ? &cardTitle : null);
			Card sel = null;
			auto index = _tbl.getSelectionIndex();
			if (-1 != index) { mixin(S_TRACE);
				sel = cast(Card)_tbl.getItem(index).getData();
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
	void createTableItem(Card c, int index = -1) { mixin(S_TRACE);
		auto itm = index >= 0
			? new TableItem(_tbl, SWT.NONE, index)
			: new TableItem(_tbl, SWT.NONE);
		refreshTableItem(c, itm);
	}
	void refreshListItem(int index, Card card) { mixin(S_TRACE);
		if (_cle) _cle.cancel();
		_list.refresh(index, card);
	}
	void refreshTableItem(Card c, TableItem itm) { mixin(S_TRACE);
		itm.setImage(colIndex(CardTableColumn.ID), _cimg);
		itm.setText(colIndex(CardTableColumn.ID), to!(string)(c.id));
		itm.setText(colIndex(CardTableColumn.Name), cardName(c));
		string desc = cardDesc(c).singleLine;
		if (auto c2 = cast(CastCard)c) { mixin(S_TRACE);
			if (c2 && _prop.var.etc.showHandMark && (c2.skills.length || c2.items.length || c2.beasts.length)) { mixin(S_TRACE);
				itm.setImage(colIndex(CardTableColumn.Desc), _prop.images.hand);
			} else if (c2 && _prop.var.etc.showHandMark) { mixin(S_TRACE);
				itm.setImage(colIndex(CardTableColumn.Desc), _prop.images.handEmpty);
			} else { mixin(S_TRACE);
				itm.setImage(colIndex(CardTableColumn.Desc), null);
			}
		} else if (cast(EffectCard)c) { mixin(S_TRACE);
			auto c2 = cast(EffectCard)c;
			if (0 != linkId(c)) { mixin(S_TRACE);
				c2 = cast(EffectCard)cardFrom(_summ, _cardType, linkId(c));
			}
			if (c2 && _prop.var.etc.showEventTreeMark && (c2.flagDirRoot.hasFlag || c2.flagDirRoot.hasStep || c2.flagDirRoot.hasVariant || (_prop.var.etc.ignoreEmptyStart ? !c2.isEmpty : 0 < c2.trees.length))) { mixin(S_TRACE);
				itm.setImage(colIndex(CardTableColumn.Desc), _prop.images.eventTree);
			} else if (c2 && _prop.var.etc.showEventTreeMark) { mixin(S_TRACE);
				itm.setImage(colIndex(CardTableColumn.Desc), _prop.images.eventTreeEmpty);
			} else { mixin(S_TRACE);
				itm.setImage(colIndex(CardTableColumn.Desc), null);
			}
		}
		itm.setText(colIndex(CardTableColumn.Desc), desc);
		if (colIndex(CardTableColumn.UC) != -1) { mixin(S_TRACE);
			itm.setText(colIndex(CardTableColumn.UC), to!(string)(ucGet(c.useCounter, _cardType, c.id)));
		}
		if (useNum) { mixin(S_TRACE);
			auto num = cardNum(c);
			if (cast(CastCard)c || cast(SkillCard)c) {
				itm.setText(colIndex(CardTableColumn.Num), to!string(num));
			} else { mixin(S_TRACE);
				itm.setText(colIndex(CardTableColumn.Num), 0 < num ? to!string(num) : _prop.msgs.infinity);
			}
		}
		itm.setData(c);

		int w = textWidth(_prop, itm.getParent(), c.name);
		bool warn = false;
		if (cast(CastCard)c) {
			warn = w > _prop.looks.castNameLimit;
		} else if (cast(InfoCard)c) {
			// 情報カード名はメッセージに表示されないため制限無し
			warn = false;
		} else { mixin(S_TRACE);
			warn = w > _prop.looks.nameLimit;
		}
		itm.setImage(colIndex(CardTableColumn.Name), warn ? _prop.images.warning : null);
	}
	template CopyAndPaste() {
		override void cut(SelectionEvent se) { mixin(S_TRACE);
			if (editMode) { mixin(S_TRACE);
				copyImpl(true);
				del(se);
			}
		}
		override void copy(SelectionEvent se) { mixin(S_TRACE);
			copyImpl(false);
		}
		override void paste(SelectionEvent se) { mixin(S_TRACE);
			if (editMode) { mixin(S_TRACE);
				auto c = CBtoXML(_comm.clipboard);
				try { mixin(S_TRACE);
					if (c) { mixin(S_TRACE);
						try { mixin(S_TRACE);
							auto node = XNode.parse(c);
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
				copyImpl(false);
				paste(se);
			}
		}
		@property
		override bool canDoT() { mixin(S_TRACE);
			return selectedCards.length > 0 && editMode;
		}
		@property
		override bool canDoC() { mixin(S_TRACE);
			return selectedCards.length > 0;
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
	private void copyImpl(bool del) { mixin(S_TRACE);
		auto cs = selectedCards;
		if (cs.length > 0) { mixin(S_TRACE);
			XMLtoCB(_prop, _comm.clipboard, toXML(cs, del));
			_comm.refreshToolBar();
		}
	}
	static void delImpl(CardPane v, Commons comm, CWXPath owner, Card card) { mixin(S_TRACE);
		assert (v.editMode);
		if (!card) return;
		remove(owner, card);
		if (v && v.widget && !v.widget.isDisposed()) { mixin(S_TRACE);
			v.enterEdit();
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
		CardList!(Card) widget() { mixin(S_TRACE);
			return _list;
		}
		@property
		Card selectionCard() { mixin(S_TRACE);
			return _list.selectionCard;
		}
		@property
		override bool canDoTCPD() { mixin(S_TRACE);
			return _summ && _viewMode !is CViewMode.TABLE;
		}
		mixin CopyAndPaste;
		override void del(SelectionEvent se) { mixin(S_TRACE);
			if (editMode) { mixin(S_TRACE);
				enterEdit();
				auto cards = selectedCards;
				auto ids = .map!(card => card.id)(cards).array();
				storeDelete(ids);
				foreach (card; cards) { mixin(S_TRACE);
					remove(_owner, card);
					delCard(card);
				}
				refresh();
				_comm.refreshToolBar();
			}
		}
	}

	void refCard(Card c, bool updateStatus = true) { mixin(S_TRACE);
		refCard(this, _comm, c);
	}
	static void refCard(CardPane v, Commons comm, Card c, bool updateStatus = true) { mixin(S_TRACE);
		if (auto c2 = cast(CastCard)c) {
			comm.refCast.call(v, c2);
		} else if (auto c2 = cast(SkillCard)c) {
			comm.refSkill.call(v, c2);
		} else if (auto c2 = cast(ItemCard)c) {
			comm.refItem.call(v, c2);
		} else if (auto c2 = cast(BeastCard)c) {
			comm.refBeast.call(v, c2);
		} else if (auto c2 = cast(InfoCard)c) {
			comm.refInfo.call(v, c2);
		} else assert (0);
		if (updateStatus && v && v.widget && !v.widget.isDisposed()) { mixin(S_TRACE);
			v.refreshStatusLine();
		}
	}
	void delCard(Card c) { mixin(S_TRACE);
		delCard(this, _comm, _owner, c);
	}
	static void delCard(CardPane v, Commons comm, CWXPath owner, Card card) { mixin(S_TRACE);
		if (v) v.enterEdit();
		if (auto c = cast(CastCard)card) {
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
		} else if (auto c = cast(SkillCard)card) {
			comm.delSkill.call(owner, c);
		} else if (auto c = cast(ItemCard)card) {
			comm.delItem.call(owner, c);
		} else if (auto c = cast(BeastCard)card) {
			comm.delBeast.call(owner, c);
		} else if (auto c = cast(InfoCard)card) {
			comm.delInfo.call(c);
		} else assert (0);
		comm.refUseCount.call();
		if (cast(CastCard)owner && cast(EffectCard)card) { mixin(S_TRACE);
			comm.refCast.call(cast(CastCard)owner);
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
		Card selectionCard() { mixin(S_TRACE);
			auto i = _tbl.getSelectionIndex();
			return -1 != i ? cast(Card)_tbl.getItem(i).getData() : null;
		}
		@property
		override bool canDoTCPD() { mixin(S_TRACE);
			return _summ && _viewMode is CViewMode.TABLE;
		}
		mixin CopyAndPaste;
		override void del(SelectionEvent se) { mixin(S_TRACE);
			if (editMode) { mixin(S_TRACE);
				auto indices = _tbl.getSelectionIndices();
				if (!indices.length) return;
				enterEdit();
				.sort(indices);
				TableItem[] itms;
				Card[] cards;
				ulong[] ids;
				foreach (index; indices) { mixin(S_TRACE);
					auto itm = _tbl.getItem(index);
					itms ~= itm;
					auto card = cast(Card)itm.getData();
					cards ~= card;
					ids ~= card.id;
				}
				storeDelete(ids);
				foreach (itm, card; .zip(itms, cards)) { mixin(S_TRACE);
					remove(_owner, card);
					itm.dispose();
					delCard(card);
				}
				_tbl.redraw();
				_comm.refreshToolBar();
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
				enterEdit();
				auto p = (cast(DropTarget)e.getSource()).getControl().toControl(e.x, e.y);
				int index = indexOf(p);
				bool samePane = _id == node.attr("paneId", false);
				bool sameSc = ownerId == node.attr("summId", false);
				bool topLevel = node.attr!bool("topLevel", false, false);
				ulong[Card] oldIDs;
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
					if (node.name != xmlNameM) return;
					if (!sortedID) return;
					int count = cardCount;
					if (count < index) index = count;
					if ((index < count ? index : count - 1) == selectionIndex
							|| index == selectionIndex + 1) { mixin(S_TRACE);
						selectOnly(index);
						return;
					}
					if (_tbl.getSortDirection() is SWT.DOWN) { mixin(S_TRACE);
						// 処理を単純化するため、ID昇順でソートされた
						// 状態に対して移動処理を行う
						index = cast(int)cards.length - index - 1;
					}

					Card[] adds;
					node.onTag[xmlName] = (ref XNode cNode) { mixin(S_TRACE);
						auto id = Card.readId(cNode);
						if (id == 0UL) return;
						adds ~= this.outer.localCard(id);
						e.detail = DND.DROP_NONE;
					};
					node.parse();
					if (adds.length == 0) return;
					moveCards(adds, index, true);
				} else { mixin(S_TRACE);
					e.detail = DND.DROP_NONE;
					// 他のリストからのコピー
					if (cardCount < index) index = cardCount;
					if (!sortedID) { mixin(S_TRACE);
						index = cardCount;
					} else if (_tbl.getSortDirection() is SWT.DOWN) { mixin(S_TRACE);
						index = cast(int)cards.length - index;
					}
					Card[] allAdds;
					Card[][CardType] adds;
					auto lastType = _cardType;
					foreach (cardType; types) { mixin(S_TRACE);
						void f(CardType cardType) { mixin(S_TRACE);
							node.onTag[xmlNameFrom(cardType)] = (ref XNode cNode) { mixin(S_TRACE);
								auto ver = new XMLInfo(_prop.sys, LATEST_VERSION);
								auto card = createFromNode(cNode, ver);
								auto arr = adds.get(cardType, []);
								arr ~= card;
								allAdds ~= card;
								lastType = cardType;
								adds[cardType] = arr;
							};
						}
						f(cardType);
					}
					node.parse();
					if (allAdds.length == 0) return;
					if (qCardMaterialCopy(node, allAdds)) { mixin(S_TRACE);
						foreach (cardType, arr; adds) { mixin(S_TRACE);
							auto pane = openSameLevelPane(cardType, lastType is cardType);
							assert (pane._cardType is cardType);
							ulong[] ids;
							auto paneIndex = pane is this.outer ? index : cast(int)pane.cards.length;
							foreach (i, card; arr) { mixin(S_TRACE);
								pane.refreshLink(card, samePane, sameSc, topLevel);
								pane.insert(pane._owner, paneIndex, card);
								ids ~= pane.cardsFrom(cardType, pane._owner)[paneIndex].id;
								arr[i] = pane.cards[paneIndex];
								paneIndex++;
							}
							pane.storeInsert(ids);
							pane.insert(arr[$ - 1], false);
							pane.sort();
							foreach (i, card; arr) { mixin(S_TRACE);
								pane.refCard(card);
							}
							pane.selectID(ids);
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
	void moveCards(Card[] adds, int index, bool store) { mixin(S_TRACE);
		enterEdit();
		if (store) { mixin(S_TRACE);
			int[] oldIndexes;
			foreach (card; adds) { mixin(S_TRACE);
				oldIndexes ~= cast(int)CardPane.indexOf(owner, cardType, card);
			}
			.sort(oldIndexes);
			storeMove(oldIndexes, index);
		}
		std.algorithm.sort!((a, b) => a.id < b.id)(adds);

		moveCards(_owner, _cardType, adds, index);
		selectMovedCards(adds);
	}
	void selectMovedCards(Card[] adds) { mixin(S_TRACE);
		ulong[] ids;
		foreach (card; adds) { mixin(S_TRACE);
			refCard(card, false);
			ids ~= card.id;
		}
		insert(adds[$ - 1], true);
		selectID(ids);
	}
	static void moveCards(CWXPath owner, CardType cardType, Card[] adds, int index) { mixin(S_TRACE);
		foreach (card; adds) { mixin(S_TRACE);
			CardPane.insert(owner, index, card);
			index = cast(int)CardPane.indexOf(owner, cardType, card) + 1;
		}
	}
	void refreshLink(ref Card card, bool samePane, bool sameSc, bool topLevel) { mixin(S_TRACE);
		assert (editMode);
		if (cast(EffectCard)card) { mixin(S_TRACE);
			enterEdit();
			if (sameSc && _ownerType is OwnerType.Summary && 0 != linkId(card)) { mixin(S_TRACE);
				card = pOwnerCard(linkId(card));
				if (card) { mixin(S_TRACE);
					if (auto c = cast(SkillCard)card) { mixin(S_TRACE);
						card = c.dup;
 					} else if (auto c = cast(ItemCard)card) { mixin(S_TRACE);
						card = c.dup;
					} else if (auto c = cast(BeastCard)card) { mixin(S_TRACE);
						card = c.dup;
					} else assert (0);
				} else { mixin(S_TRACE);
					final switch (_cardType) {
					case CardType.Cast:
						assert (0);
					case CardType.Skill:
						card = new SkillCard(_prop.sys, 1UL, "", [], "");
						break;
					case CardType.Item:
						card = new ItemCard(_prop.sys, 1UL, "", [], "");
						break;
					case CardType.Beast:
						card = new BeastCard(_prop.sys, 1UL, "", [], "");
						break;
					case CardType.Info:
						assert (0);
					}
				}
			} else if (sameSc && _ownerType is OwnerType.Cast && topLevel && (_prop.var.etc.linkCard || !_summ || !_summ.legacy)) { mixin(S_TRACE);
				auto id = card.id;
				final switch (_cardType) {
				case CardType.Cast:
					assert (0);
				case CardType.Skill:
					auto card2 = new SkillCard(_prop.sys, 1UL, "", [], "");
					card2.linkId = id;
					card = card2;
					break;
				case CardType.Item:
					auto card2 = new ItemCard(_prop.sys, 1UL, "", [], "");
					card2.linkId = id;
					card = card2;
					break;
				case CardType.Beast:
					auto card2 = new BeastCard(_prop.sys, 1UL, "", [], "");
					card2.linkId = id;
					card = card2;
					break;
				case CardType.Info:
					assert (0);
				}
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
	}
	private void insert(Card c, bool move) { mixin(S_TRACE);
		assert (editMode);
		enterEdit();
		refresh();
		int index = cast(int)indexOf(_owner, _cardType, c);
		if (_viewMode == CViewMode.TABLE) { mixin(S_TRACE);
			_tbl.select(index);
			_tbl.showSelection();
		} else { mixin(S_TRACE);
			_list.select(index);
			_list.scroll(index);
		}
		refreshStatusLine();
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
		private void insert(Card c, bool move) { mixin(S_TRACE);
			assert (editMode);
			enterEdit();
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
				auto sels = selectedCards;
				if (sels.length > 0) { mixin(S_TRACE);
					e.data = bytesFromXML(toXML(sels, false));
				}
			}
		}
	}
	bool qCardMaterialCopy(in XNode node, Card[] cs) { mixin(S_TRACE);
		auto fromSPath = node.attr("scenarioPath", false);
		if (fromSPath != "") fromSPath = .nabs(fromSPath);
		auto fromSName = node.attr("scenarioName", false);
		auto fromSAuthor = node.attr("scenarioAuthor", false);
		if (fromSPath.length > 0 && !cfnmatch(fromSPath, nabs(ownerScenarioPath))) { mixin(S_TRACE);
			auto uc = new UseCounter(null);
			foreach (c; cs) { mixin(S_TRACE);
				c.setUseCounter(uc, null);
			}
			bool copy;
			bool r = qMaterialCopy(_comm, dlgParShl, uc, _summ.scenarioPath, fromSPath, copy, _summ.legacy,
				(in PathUser v) { mixin(S_TRACE);
					return .pathUserToExportedImageName(_prop.parent, fromSName, fromSAuthor, v);
				});
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
	const
	const(Summary) ownerScenario() { mixin(S_TRACE);
		if (_ownerType is OwnerType.Cast) { mixin(S_TRACE);
			return _summ;
		} else { mixin(S_TRACE);
			assert (cast(Summary)_owner !is null);
			return cast(Summary)_owner;
		}
	}
	@property
	const
	string ownerScenarioPath() { mixin(S_TRACE);
		return ownerScenario.scenarioPath;
	}
	@property
	const
	string ownerScenarioName() { mixin(S_TRACE);
		return ownerScenario.scenarioName;
	}
	@property
	const
	string ownerScenarioAuthor() { mixin(S_TRACE);
		return ownerScenario.author;
	}
	@property
	string ownerWsnVersion() { mixin(S_TRACE);
		if (_ownerType is OwnerType.Cast) { mixin(S_TRACE);
			return _summ.dataVersion;
		} else { mixin(S_TRACE);
			assert (cast(Summary)_owner !is null);
			return (cast(Summary)_owner).dataVersion;
		}
	}
	@property
	string ownerId() { mixin(S_TRACE);
		if (_ownerType is OwnerType.Cast) { mixin(S_TRACE);
			return _summ.id;
		} else { mixin(S_TRACE);
			assert (cast(Summary)_owner !is null);
			return (cast(Summary)_owner).id;
		}
	}
	private Skin _skinTemp = null;
	ImageDataWithScale cardImageWithScale(in Card c) { mixin(S_TRACE);
		Skin skin = _skinTemp ? _skinTemp : _comm.skin;
		auto preview = _viewMode == CViewMode.TABLE;
		auto detail = _viewMode == CViewMode.LIFE || preview;
		ImageDataWithScale data;
		if (cast(CastCard)c) { mixin(S_TRACE);
			data = .castCardImage(_prop, skin, ownerScenario, cast(CastCard)c, detail);
		} else if (!cast(InfoCard)c && _ownerType is OwnerType.Cast) { mixin(S_TRACE);
			final switch (_cardType) {
			case CardType.Cast:
				assert (0);
			case CardType.Skill:
				data = .cardImage(_prop, skin, ownerScenario, cast(const SkillCard)c, cast(CastCard)_owner, (id) => cast(const SkillCard)pOwnerCard(id), detail, preview);
				break;
			case CardType.Item:
				data = .cardImage(_prop, skin, ownerScenario, cast(const ItemCard)c, cast(CastCard)_owner, (id) => cast(const ItemCard)pOwnerCard(id), detail, preview);
				break;
			case CardType.Beast:
				data = .cardImage(_prop, skin, ownerScenario, cast(const BeastCard)c, cast(CastCard)_owner, (id) => cast(const BeastCard)pOwnerCard(id), detail, preview);
				break;
			case CardType.Info:
				assert (0);
			}
		} else { mixin(S_TRACE);
			final switch (_cardType) {
			case CardType.Cast:
				assert (0);
			case CardType.Skill:
				data = .cardImage(_prop, skin, ownerScenario, cast(const SkillCard)c, cast(CastCard)null, (id) => cast(const SkillCard)pOwnerCard(id), detail, preview);
				break;
			case CardType.Item:
				data = .cardImage(_prop, skin, ownerScenario, cast(const ItemCard)c, cast(CastCard)null, (id) => cast(const ItemCard)pOwnerCard(id), detail, preview);
				break;
			case CardType.Beast:
				data = .cardImage(_prop, skin, ownerScenario, cast(const BeastCard)c, cast(CastCard)null, (id) => cast(const BeastCard)pOwnerCard(id), detail, preview);
				break;
			case CardType.Info:
				data = .cardImage(_prop, skin, ownerScenario, cast(const InfoCard)c, cast(CastCard)null, (id) => cast(const InfoCard)pOwnerCard(id), detail, preview);
				break;
			}
		}
		return data;
	}
	ImageData cardImage(in Card c) { mixin(S_TRACE);
		return cardImageWithScale(c).scaled(_prop.var.etc.imageScale);
	}

	string cardTitle(in Card c) { mixin(S_TRACE);
		return .tryFormat(_prop.msgs.cardTitle, c.id, baseCard(c).name);
	}

	void refreshIDs() { mixin(S_TRACE);
		if (_viewMode == CViewMode.TABLE) { mixin(S_TRACE);
			foreach (i, itm; _tbl.getItems()) { mixin(S_TRACE);
				auto c = cast(Card)itm.getData();
				itm.setText(colIndex(CardTableColumn.ID), to!(string)(c.id));
			}
		}
	}

	void refList() { mixin(S_TRACE);
		auto sels = _tbl.getSelectionIndices();
		int index = _tbl.getSelectionIndex();
		enterEdit();
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
		enterEdit();
		refresh();
		if (sels.length > 0) { mixin(S_TRACE);
			_tbl.setSelection(sels);
			_tbl.showSelection();
		}
		refreshStatusLine();
	}
	void toNode(ref XNode sn, Card[] sels, bool del) { mixin(S_TRACE);
		if (!sels.length) return;
		if (!del) { mixin(S_TRACE);
			if (cast(Object) sels[0].cwxParent is _summ) { mixin(S_TRACE);
				sn.newAttr("summId", _summ.id);
				sn.newAttr("paneId", _id);
				sn.newAttr("topLevel", true);
			} else { mixin(S_TRACE);
				sn.newAttr("summId", ownerId);
				sn.newAttr("paneId", _id);
				sn.newAttr("topLevel", false);
			}
		}
		sn.newAttr("scenarioPath", nabs(ownerScenarioPath));
		sn.newAttr("scenarioName", ownerScenarioName);
		sn.newAttr("scenarioAuthor", ownerScenarioAuthor);
		auto opt = new XMLOption(_prop.sys, LATEST_VERSION);
		foreach (sel; sels) { mixin(S_TRACE);
			sel.toNode(sn, opt);
		}
	}
	string toXML(Card[] sels, bool del) { mixin(S_TRACE);
		auto doc = XNode.create(xmlNameM);
		toNode(doc, sels, del);
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
		override void mouseUp(MouseEvent e) { mixin(S_TRACE);
			Card c = null;
			if (e.button == 1) { mixin(S_TRACE);
				c = _openEventTarget;
			} else if (e.button == 2) { mixin(S_TRACE);
				int index = _list.searchIndex(e.x, e.y);
				if (index >= 0) { mixin(S_TRACE);
					c = _list.card(index);
				}
			}
			if (auto castCard = cast(CastCard)c) { mixin(S_TRACE);
				editHandWith(castCard);
			} else if (auto effCard = cast(EffectCard)c) { mixin(S_TRACE);
				editUseEvent(effCard, false);
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
		override void mouseUp(MouseEvent e) { mixin(S_TRACE);
			Card c = null;
			if (e.button == 1) { mixin(S_TRACE);
				c = _openEventTarget;
			} else if (e.button == 2) { mixin(S_TRACE);
				scope p = new Point(e.x, e.y);
				auto itm = _tbl.getItem(p);
				if (!itm) return;
				c = cast(Card)itm.getData();
			}
			if (auto castCard = cast(CastCard)c) { mixin(S_TRACE);
				editHandWith(castCard);
			} else if (auto effCard = cast(EffectCard)c) { mixin(S_TRACE);
				editUseEvent(effCard, false);
			}
		}
		override void mouseDoubleClick(MouseEvent e) { mixin(S_TRACE);
			if (e.button != 1) return;
			scope p = new Point(e.x, e.y);
			auto itm = _tbl.getItem(p);
			if (!itm) return;
			edit(cast(Card)itm.getData());
		}
	}
	class LKey : KeyAdapter {
		override void keyPressed(KeyEvent e) { mixin(S_TRACE);
			bool keyMatch = .isEnterKey(e.keyCode);
			if (keyMatch && _list.selection >= 0) { mixin(S_TRACE);
				edit(_list.selectionCard);
			}
		}
	}
	class TKey : KeyAdapter {
		override void keyPressed(KeyEvent e) { mixin(S_TRACE);
			bool keyMatch = .isEnterKey(e.keyCode);
			int i = _tbl.getSelectionIndex();
			if (keyMatch && -1 != i) { mixin(S_TRACE);
				edit(cast(Card)_tbl.getItem(i).getData());
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
			if (_ownerType is OwnerType.Summary) { mixin(S_TRACE);
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
		assert (cast(Card)itm.getData() !is null);
		auto c = cast(Card)itm.getData();
		if (c is _previewC) { mixin(S_TRACE);
			return;
		}
		closePreview();
		_previewC = c;
		auto imgData = cardImageWithScale(c);
		_previewI = new PileImage(imgData, _prop.drawingScale, imgData.getWidth(NORMAL_SCALE), imgData.getHeight(NORMAL_SCALE), false);
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
			if (_cardType is CardType.Cast || _cardType is CardType.Skill || _cardType is CardType.Item || _cardType is CardType.Beast) { mixin(S_TRACE);
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
					_openEventTarget = cast(Card)itm.getData();
				} else { mixin(S_TRACE);
					_tbl.setCursor(null);
					_openEventTarget = null;
				}
			}
		}
	}

	class ListMouseMove : MouseMoveListener {
		private int _index = -1;

		override void mouseMove(MouseEvent e) { mixin(S_TRACE);
			if (_cardType is CardType.Cast || _cardType is CardType.Skill || _cardType is CardType.Item || _cardType is CardType.Beast) { mixin(S_TRACE);
				if (_viewMode !is CViewMode.LIFE) { mixin(S_TRACE);
					_list.setCursor(null);
					_openEventTarget = null;
					return;
				}
				int i = _list.searchIndex(e.x, e.y);
				if (_index != i) { mixin(S_TRACE);
					if (0 <= _index && _index < _list.count) _list.refresh(_index);
					if (0 <= i && i < _list.count) _list.refresh(i);
					_index = i;
				}
				if (i < 0 || _list.count <= i) { mixin(S_TRACE);
					_list.setCursor(null);
					_openEventTarget = null;
					return;
				}
				auto c = _list.card(i);
				auto bounds = _list.getBounds(i);
				Rectangle rect = null;
				final switch (_cardType) {
				case CardType.Cast:
					auto detail = _viewMode == CViewMode.LIFE;
					rect = .handMarkRect(_prop, true, bounds.x, bounds.y, cast(CastCard)c, detail);
					break;
				case CardType.Skill:
					rect = .eventTreeMarkRect(_prop, true, bounds.x, bounds.y, _summ, cast(SkillCard)c);
					break;
				case CardType.Item:
					rect = .eventTreeMarkRect(_prop, true, bounds.x, bounds.y, _summ, cast(ItemCard)c);
					break;
				case CardType.Beast:
					rect = .eventTreeMarkRect(_prop, true, bounds.x, bounds.y, _summ, cast(BeastCard)c);
					break;
				case CardType.Info:
					assert (0);
				}
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

	public void selectAll() { mixin(S_TRACE);
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
	public bool canSelectAll() { mixin(S_TRACE);
		return cards.length && selectionCount != cards.length;
	}
	@property
	int selectionCount() { mixin(S_TRACE);
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
			if (_ownerType is OwnerType.Summary) { mixin(S_TRACE);
				_prop.var.etc.mainCardsSortColumn = column;
				_prop.var.etc.mainCardsSortDirection = dir;
				_comm.refMainCardsSort.call(this, columnVal, dir);
			} else {
				_prop.var.etc.handCardsSortColumn = column;
				_prop.var.etc.handCardsSortDirection = dir;
				_comm.refHandCardsSort.call(this, columnVal, dir);
			}
		} else { mixin(S_TRACE);
			if (_ownerType is OwnerType.Summary) { mixin(S_TRACE);
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
	void listEditEnd(Card c, Control ctrl) { mixin(S_TRACE);
		assert (editMode);
		assert (c !is null);
		string newText = (cast(Text)ctrl).getText();
		if (newText == "") return;

		Card[] cards;
		foreach (card; selectedCards) { mixin(S_TRACE);
			if (card.name == newText) continue;
			cards ~= card;
		}
		if (!cards.length) return;
		storeEdit(.map!(card => card.id)(cards).array());
		foreach (card; cards) { mixin(S_TRACE);
			card.name = newText;
			refCard(card);
		}
		refresh();
		_comm.refreshToolBar();
	}
	Control listCreateEditor(in Card c) { mixin(S_TRACE);
		assert (editMode);
		if (0 != linkId(c)) return null;
		return createTextEditor(_comm, _prop, _list, c.name);
	}
	string toolTip(Card card) { mixin(S_TRACE);
		if (!card) return "";
		auto id = linkId(card);
		if (!id) return "";
		auto c = pOwnerCard(id);
		if (c) { mixin(S_TRACE);
			return .tryFormat(_prop.msgs.cardIsReference, id, c.name);
		} else { mixin(S_TRACE);
			return .tryFormat(_prop.msgs.referencedCardIsNotFound, id);
		}
	}
	void updateToolTip(Event e) { mixin(S_TRACE);
		if (_viewMode !is CViewMode.TABLE) return;
		auto itm = _tbl.getItem(new Point(e.x, e.y));
		if (itm) { mixin(S_TRACE);
			auto card = cast(Card)itm.getData();
			_tbl.setToolTipText(toolTip(card));
		} else { mixin(S_TRACE);
			_tbl.setToolTipText("");
		}
	}
	void createCardList(Composite parent) { mixin(S_TRACE);
		_pane = new Composite(parent, _style);
		_pane.setLayout(zeroGridLayout(1, true));

		auto tableComp = new Composite(_pane, SWT.NONE);
		tableComp.setLayout(zeroGridLayout(1, true));
		_tbl = .rangeSelectableTable(tableComp, SWT.FULL_SELECTION | SWT.MULTI);
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
		.listener(_tbl, SWT.MouseMove, &updateToolTip);
		.listener(_tbl, SWT.MouseEnter, &updateToolTip);
		.listener(_tbl, SWT.MouseExit, &updateToolTip);
		.listener(_tbl, SWT.Paint, &updateToolTip);

		_preview = new Preview(_prop, _tbl);
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
			if (_cardType is CardType.Cast || _cardType is CardType.Skill) { mixin(S_TRACE);
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
			_tte = new TableTextEdit(_comm, _prop, _tbl, colIndex(CardTableColumn.Name), &nameEditEnd, &canEditT);
			if (useNum) { mixin(S_TRACE);
				_ttce = new TableTCEdit(_comm, _tbl, colIndex(CardTableColumn.Num), &numCreateEditor, &numEditEnd, &canEditT);
			}
		}
		TableTextEdit _tte = null;
		TableTCEdit _ttce = null;

		_list = new CardList!Card(_pane, SWT.VIRTUAL | SWT.V_SCROLL | SWT.MULTI);
		void updateCardListParamsImpl() { mixin(S_TRACE);
			CInsets matPad;
			if (_cardType is CardType.Cast) { mixin(S_TRACE);
				matPad = _prop.looks.castCardInsets;
			} else { mixin(S_TRACE);
				matPad = _prop.looks.menuCardInsets;
			}
			int w = _prop.looks.cardSize.width + matPad.e + matPad.w;
			int h = _prop.looks.cardSize.height + matPad.n + matPad.s;
			_list.setCardSize(_prop.s(w), _prop.s(h), _prop.var.etc.showCardListTitle);
			_list.setLayoutValues(_prop.var.etc.cardsMarginX, _prop.var.etc.cardsSpaceX,
				_prop.var.etc.cardsMarginY, _prop.var.etc.cardsSpaceY, _prop.var.etc.cardsTitleSpace,
				_prop.var.etc.cardsFocusLinePadding, _prop.var.etc.cardsDefaultWrap);
		}
		void updateCardListParams() { mixin(S_TRACE);
			updateCardListParamsImpl();
			refreshImpl();
		}
		updateCardListParamsImpl();
		_list.addSelectionListener(new SelChanged);
		_comm.refShowCardListHeader.add(&updateLayout);
		_comm.refShowCardListTitle.add(&updateCardListParams);
		_comm.refImageScale.add(&updateCardListParams);
		.listener(_list, SWT.Dispose, { mixin(S_TRACE);
			_comm.refShowCardListHeader.remove(&updateLayout);
			_comm.refShowCardListTitle.remove(&updateCardListParams);
			_comm.refImageScale.remove(&updateCardListParams);
		});
		_list.additionalPaint ~= (canvas, gc, c, bounds) { mixin(S_TRACE);
			auto detail = _viewMode == CViewMode.LIFE;
			if (auto card = cast(CastCard)c) { mixin(S_TRACE);
				.putHand(canvas, gc, _prop, detail, card, bounds);
			} else if (auto card = cast(SkillCard)c) { mixin(S_TRACE);
				.putEventTree(canvas, gc, _prop, _summ, detail, card, bounds);
			} else if (auto card = cast(ItemCard)c) { mixin(S_TRACE);
				.putEventTree(canvas, gc, _prop, _summ, detail, card, bounds);
			} else if (auto card = cast(BeastCard)c) { mixin(S_TRACE);
				.putEventTree(canvas, gc, _prop, _summ, detail, card, bounds);
			}
		};
		if (editMode) { mixin(S_TRACE);
			_cle = new CardListEdit!Card(_comm, _list, &listEditEnd, &listCreateEditor);
		}

		_list.setToolTip(&toolTip);

		_tcpd = [];
		auto cl_ = new CL;
		_tcpd ~= cl_;
		auto ct_ = new CT;
		_tcpd ~= ct_;

		// 絞込み検索
		_incSearch = new IncSearch(_comm, _pane, () => 0 < cards.length);
		_incSearch.modEvent ~= &refresh;

		// ソート関係
		_idSorter = new TableSorter!Card(idCol, &compID, &revCompID);
		_idSorter.sortedEvent ~= &sorted;
		_nameSorter = new TableSorter!Card(nameCol, &compName, &revCompName);
		_nameSorter.sortedEvent ~= &sorted;
		_descSorter = new TableSorter!Card(descCol, &compDesc, &revCompDesc);
		_descSorter.sortedEvent ~= &sorted;
		if (ucCol) { mixin(S_TRACE);
			_ucSorter = new TableSorter!Card(ucCol, &compUC, &revCompUC);
			_ucSorter.sortedEvent ~= &sorted;
		}
		if (numCol) { mixin(S_TRACE);
			_numSorter = new TableSorter!Card(numCol, &compNum, &revCompNum);
			_numSorter.sortedEvent ~= &sorted;
		}
		int column;
		int dir;
		if (editMode) { mixin(S_TRACE);
			if (_ownerType is OwnerType.Summary) { mixin(S_TRACE);
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
			if (_ownerType is OwnerType.Summary) { mixin(S_TRACE);
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
		cancelEdit();
		_undo.reset();
	}
	private void delegate(CastCard) _openHand = null;
	void refUndoMax() { mixin(S_TRACE);
		assert (editMode);
		_undo.max = _prop.var.etc.undoMaxMainView;
	}
	private void construct1(Commons comm, Props prop, Summary summ, OwnerType ownerType, CardType cardType, int style) { mixin(S_TRACE);
		_id = .objectIDValue(this);
		_comm = comm;
		_prop = prop;
		_summ = summ;
		_style = style;
		if (editMode) { mixin(S_TRACE);
			_undo = new UndoManager(_prop.var.etc.undoMaxMainView);
		}
		_ownerType = ownerType;
		_cardType = cardType;
		final switch (_cardType) {
		case CardType.Cast:
			_cimg = prop.images.casts;
			break;
		case CardType.Skill:
			_cimg = prop.images.skill;
			break;
		case CardType.Item:
			_cimg = prop.images.item;
			break;
		case CardType.Beast:
			_cimg = prop.images.beast;
			break;
		case CardType.Info:
			_cimg = prop.images.info;
			break;
		}
	}
	void hold(SelectionEvent e) { mixin(S_TRACE);
		assert (canHold);
		assert (editMode);
		enterEdit();
		Card[] cards;
		auto mi = cast(MenuItem)e.widget;
		foreach (c; selectedCards) { mixin(S_TRACE);
			if (auto card = cast(SkillCard)c) {
				if (card.hold is mi.getSelection()) continue;
			} else if (auto card = cast(ItemCard)c) {
				if (card.hold is mi.getSelection()) continue;
			} else assert (0);
			cards ~= c;
		}
		storeEdit(.map!(card => card.id)(cards).array());
		foreach (c; selectedCards) { mixin(S_TRACE);
			if (auto card = cast(SkillCard)c) {
				card.hold = mi.getSelection();
			} else if (auto card = cast(ItemCard)c) {
				card.hold = mi.getSelection();
			} else assert (0);
		}
		refresh();
	}
	Menu _addHandMenu = null;
	void refAddHandMenu(Card card) { mixin(S_TRACE);
		assert (_ownerType is OwnerType.Cast);
		assert (editMode);
		createMenuItem2(_comm, _addHandMenu, .format("%s.%s", card.id, card.name), _cimg, { mixin(S_TRACE);
			.forceFocus(widget, false);
			auto doc = XNode.create(xmlNameM);
			toNode(doc, [card], false);
			auto ver = new XMLInfo(_prop.sys, LATEST_VERSION);
			addFromNode(doc, ver);
		}, null);
	}
	void refreshAddHand() { mixin(S_TRACE);
		assert (_ownerType is OwnerType.Cast);
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
		assert (_ownerType is OwnerType.Cast);
		assert (editMode);
		enterEdit();
		Card[] cards;
		Card[] targs;
		foreach (card; selectedCards) { mixin(S_TRACE);
			if (!card || 0 == linkId(card)) continue;
			auto targ = pOwnerCard(linkId(card));
			if (!targ) continue;
			cards ~= card;
			targs ~= targ;
		}
		storeEdit(map!(card => card.id)(cards).array());
		foreach (card, targ; .zip(cards, targs)) { mixin(S_TRACE);
			auto id = card.id;
			bool hold = false;
			if (auto c = cast(SkillCard)card) { mixin(S_TRACE);
				hold = c.hold;
				c.deepCopy(cast(SkillCard)targ);
				c.id = id;
				c.linkId = 0;
				c.hold = hold;
			} else if (auto c = cast(ItemCard)card) { mixin(S_TRACE);
				hold = c.hold;
				c.deepCopy(cast(ItemCard)targ);
				c.id = id;
				c.linkId = 0;
				c.hold = hold;
			} else if (auto c = cast(BeastCard)card) { mixin(S_TRACE);
				c.deepCopy(cast(BeastCard)targ);
				c.id = id;
				c.linkId = 0;
			} else assert (0);
			refCard(card);
		}
		refresh();
		_comm.refreshToolBar();
	}
	@property
	public bool canRemoveRef() { mixin(S_TRACE);
		assert (_ownerType is OwnerType.Cast);
		assert (editMode);
		foreach (card; selectedCards) { mixin(S_TRACE);
			if (0 != linkId(card) && pOwnerCard(linkId(card))) return true;
		}
		return false;
	}
public:
	this (Commons comm, Props prop, Summary summ, Composite parent, OwnerType ownerType, CardType cardType, int style, Summary toc, void delegate(CastCard) openHand = null) { mixin(S_TRACE);
		_parent = parent;
		_toc = toc;
		assert (!editMode);
		_openHand = openHand;
		_skinTemp = comm.findSkinFromHistory(summ);
		construct1(comm, prop, summ, ownerType, cardType, style);
	}
	this (Commons comm, Props prop, Summary summ, Composite parent, OwnerType ownerType, CardType cardType, int style) { mixin(S_TRACE);
		_parent = parent;
		construct1(comm, prop, summ, ownerType, cardType, style);
		assert (editMode);
	}

	void construct() { mixin(S_TRACE);
		reconstruct(_parent, _style);
	}

	void refEventTree(EventTree et) { mixin(S_TRACE);
		assert (editMode);
		auto match = (_cardType.Skill && cast(SkillCard)et.owner)
			|| (_cardType.Item && cast(ItemCard)et.owner)
			|| (_cardType.Beast && cast(BeastCard)et.owner)
			|| et.owner is null;
		if (match) { mixin(S_TRACE);
			refreshImpl();
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
			if (_cardType is CardType.Skill || _cardType is CardType.Item || _cardType is CardType.Beast) { mixin(S_TRACE);
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
			final switch (_cardType) {
			case CardType.Cast:
				_comm.refCast.add(&refCardCallbackCast);
				break;
			case CardType.Skill:
				_comm.refSkill.add(&refCardCallbackSkill);
				_comm.delSkill.add(&delCardCallbackSkill);
				break;
			case CardType.Item:
				_comm.refItem.add(&refCardCallbackItem);
				_comm.delItem.add(&delCardCallbackItem);
				break;
			case CardType.Beast:
				_comm.refBeast.add(&refCardCallbackBeast);
				_comm.delBeast.add(&delCardCallbackBeast);
				break;
			case CardType.Info:
				_comm.refInfo.add(&refCardCallbackInfo);
				break;
			}
			_comm.refUndoMax.add(&refUndoMax);
			_list.addDisposeListener(new class DisposeListener {
				override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
					_comm.refScenario.remove(&refScenario);
					final switch (_cardType) {
					case CardType.Cast:
						_comm.refCast.remove(&refCardCallbackCast);
						break;
					case CardType.Skill:
						_comm.refSkill.remove(&refCardCallbackSkill);
						_comm.delSkill.remove(&delCardCallbackSkill);
						break;
					case CardType.Item:
						_comm.refItem.remove(&refCardCallbackItem);
						_comm.delItem.remove(&delCardCallbackItem);
						break;
					case CardType.Beast:
						_comm.refBeast.remove(&refCardCallbackBeast);
						_comm.delBeast.remove(&delCardCallbackBeast);
						break;
					case CardType.Info:
						_comm.refInfo.remove(&refCardCallbackInfo);
						break;
					}
					_comm.refUndoMax.remove(&refUndoMax);
					foreach (w; _editDlgs.values) { mixin(S_TRACE);
						(cast(AbsDialog)w).forceCancel();
					}
				}
			});
			pop = new Menu(parent.getShell(), SWT.POP_UP);
			createMenuItem(_comm, pop, MenuID.IncSearch, &incSearch, () => 0 < cards.length);
			new MenuItem(pop, SWT.SEPARATOR);
			if (_cardType is CardType.Cast) { mixin(S_TRACE);
				createMenuItem(_comm, pop, MenuID.EditProp, &editM, &canEdit);
				new MenuItem(pop, SWT.SEPARATOR);
				createMenuItem(_comm, pop, MenuID.OpenHand, &editHand, &canEdit);
				new MenuItem(pop, SWT.SEPARATOR);
				createMenuItem(_comm, pop, MenuID.NewCast, &create, () => _summ !is null);
			} else if (_cardType is CardType.Skill || _cardType is CardType.Item || _cardType is CardType.Beast) { mixin(S_TRACE);
				createMenuItem(_comm, pop, MenuID.EditProp, &editM, &canEdit);
				new MenuItem(pop, SWT.SEPARATOR);
				createMenuItem(_comm, pop, MenuID.EditEventAtTimeOfUsing, () => editUseEvent(false), &canEdit);
				new MenuItem(pop, SWT.SEPARATOR);
				if (_cardType is CardType.Skill) { mixin(S_TRACE);
					createMenuItem(_comm, pop, MenuID.NewSkill, &create, () => _summ !is null);
				} else if (_cardType is CardType.Item) { mixin(S_TRACE);
					createMenuItem(_comm, pop, MenuID.NewItem, &create, () => _summ !is null);
				} else if (_cardType is CardType.Beast) { mixin(S_TRACE);
					createMenuItem(_comm, pop, MenuID.NewBeast, &create, () => _summ !is null);
				} else assert (0);
			} else if (_cardType is CardType.Info) {
				createMenuItem(_comm, pop, MenuID.EditProp, &editM, &canEdit);
				new MenuItem(pop, SWT.SEPARATOR);
				createMenuItem(_comm, pop, MenuID.NewInfo, &create, () => _summ !is null);
			} else { mixin(S_TRACE);
				assert (0);
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
			if (_ownerType is OwnerType.Cast) { mixin(S_TRACE);
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
			createMenuItem(_comm, pop, MenuID.SelectAll, &selectAll, &canSelectAll);
			new MenuItem(pop, SWT.SEPARATOR);
			createMenuItem(_comm, pop, MenuID.SelectConnectedResource, &selectConnectedResource, &canSelectConnectedResource);
			if (_ownerType is OwnerType.Summary) { mixin(S_TRACE);
				new MenuItem(pop, SWT.SEPARATOR);
				createMenuItem(_comm, pop, MenuID.FindID, &replaceID, &canReplaceID);
			}
			new MenuItem(pop, SWT.SEPARATOR);
			createMenuItem(_comm, pop, MenuID.ReNumbering, &reNumbering, &canReNumbering);
		} else { mixin(S_TRACE);
			pop = new Menu(parent.getShell(), SWT.POP_UP);
			createMenuItem(_comm, pop, MenuID.IncSearch, &incSearch, () => 0 < cards.length);
			new MenuItem(pop, SWT.SEPARATOR);
			createMenuItem(_comm, pop, MenuID.Import, &doImport, &canDoImport);
			new MenuItem(pop, SWT.SEPARATOR);
			createMenuItem(_comm, pop, MenuID.ShowProp, &editM, &canEdit);
			new MenuItem(pop, SWT.SEPARATOR);
			if (_cardType is CardType.Skill || _cardType is CardType.Item || _cardType is CardType.Beast) { mixin(S_TRACE);
				createMenuItem(_comm, pop, MenuID.EditEventAtTimeOfUsing, () => editUseEvent(false), &canEdit);
				new MenuItem(pop, SWT.SEPARATOR);
			}
			if (_cardType is CardType.Cast) { mixin(S_TRACE);
				createMenuItem(_comm, pop, MenuID.OpenHand, { mixin(S_TRACE);
					foreach (card; selectedCards) { mixin(S_TRACE);
						assert (cast(CastCard)card);
						_openHand(cast(CastCard)card);
					}
				}, () => selection !is null);
				new MenuItem(pop, SWT.SEPARATOR);
			}
			appendMenuTCPD(_comm, pop, this, false, true, false, false, false);
			new MenuItem(pop, SWT.SEPARATOR);
			createMenuItem(_comm, pop, MenuID.SelectAll, &selectAll, &canSelectAll);
		}
		_list.setMenu(pop);
		_tbl.setMenu(pop);
		refreshStatusLine();
	}

	@property
	CWXPath owner() { mixin(S_TRACE);
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
	CardList!Card list() { mixin(S_TRACE);
		return _list;
	}
	@property
	string statusLine() { return _statusLine; }
	@property
	const
	CardType cardType() { return _cardType; }

	void refresh() { mixin(S_TRACE);
		if (!_tbl || _tbl.isDisposed()) return;
		enterEdit();
		if (_owner) { mixin(S_TRACE);
			refreshImpl();
		}
		refreshStatusLine();
	}
	private void refCardCallback(Object sender, Card c) { mixin(S_TRACE);
		assert (editMode);
		if (sender is this) return;
		if (_ownerType is OwnerType.Cast) { mixin(S_TRACE);
			refreshAddHand();
		}
		refresh(c);
		sort();
	}
	private void refCardCallbackCast(Object sender, CastCard c) { refCardCallback(sender, c); }
	private void refCardCallbackSkill(Object sender, SkillCard c) { refCardCallback(sender, c); }
	private void refCardCallbackItem(Object sender, ItemCard c) { refCardCallback(sender, c); }
	private void refCardCallbackBeast(Object sender, BeastCard c) { refCardCallback(sender, c); }
	private void refCardCallbackInfo(Object sender, InfoCard c) { refCardCallback(sender, c); }

	private void delCardCallback(Object sender, CWXPath owner, Card c) { mixin(S_TRACE);
		assert (editMode);
		if (sender is this) return;
		if (!cast(Summary)owner) return;
		foreach (card; cards) { mixin(S_TRACE);
			if (linkId(card) == c.id) { mixin(S_TRACE);
				refresh(card);
			}
		}
		sort();
	}
	private void delCardCallbackCast(Object sender, CWXPath owner, CastCard c) { delCardCallback(sender, owner, c); }
	private void delCardCallbackSkill(Object sender, CWXPath owner, SkillCard c) { delCardCallback(sender, owner, c); }
	private void delCardCallbackItem(Object sender, CWXPath owner, ItemCard c) { delCardCallback(sender, owner, c); }
	private void delCardCallbackBeast(Object sender, CWXPath owner, BeastCard c) { delCardCallback(sender, owner, c); }
	private void delCardCallbackInfo(Object sender, CWXPath owner, InfoCard c) { delCardCallback(sender, owner, c); }

	void showCardLife() { mixin(S_TRACE);
		showCardListImpl(CViewMode.LIFE);
	}
	void showCardList() { mixin(S_TRACE);
		showCardListImpl(CViewMode.CARD);
	}
	private void showCardListImpl(CViewMode mode) { mixin(S_TRACE);
		if (_viewMode != mode) { mixin(S_TRACE);
			enterEdit();
			_viewMode = mode;
			refList();
			updateLayout();
		}
	}
	void showCardTable() { mixin(S_TRACE);
		if (_viewMode != CViewMode.TABLE) { mixin(S_TRACE);
			enterEdit();
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
	void select(int[] indices) { mixin(S_TRACE);
		if (_viewMode == CViewMode.TABLE) { mixin(S_TRACE);
			_tbl.deselectAll();
			_tbl.select(indices);
		} else { mixin(S_TRACE);
			_list.deselectAll();
			_list.selectionIndices = indices;
		}
		refreshStatusLine();
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
				auto c = cast(Card)itm.getData();
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
	void selectID(in ulong[] ids) { mixin(S_TRACE);
		int[ulong] indexTable;
		if (_viewMode == CViewMode.TABLE) { mixin(S_TRACE);
			foreach (i, itm; _tbl.getItems()) { mixin(S_TRACE);
				auto c = cast(Card)itm.getData();
				indexTable[c.id] = cast(int)i;
			}
		} else { mixin(S_TRACE);
			foreach (i, c; _list.cards) { mixin(S_TRACE);
				indexTable[c.id] = cast(int)i;
			}
		}
		int[] indexes;
		foreach (id; ids) { mixin(S_TRACE);
			indexes ~= indexTable[id];
		}
		select(indexes);
	}
	@property
	Card[] selectedCards() { mixin(S_TRACE);
		if (_viewMode == CViewMode.TABLE) { mixin(S_TRACE);
			Card[] r;
			auto sels = _tbl.getSelection();
			r.length = sels.length;
			foreach (i, itm; sels) { mixin(S_TRACE);
				r[i] = cast(Card)sels[i].getData();
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
	int[] selectionIndices() { mixin(S_TRACE);
		if (_viewMode == CViewMode.TABLE) { mixin(S_TRACE);
			return _tbl.getSelectionIndices();
		} else { mixin(S_TRACE);
			return _list.selectionIndices;
		}
	}
	@property
	ulong[] selectionIDs() { mixin(S_TRACE);
		return .map!(c => c.id)(selectedCards).array();
	}
	@property
	Card selection() { mixin(S_TRACE);
		if (!_summ) return null;
		if (_viewMode == CViewMode.TABLE) { mixin(S_TRACE);
			int i = _tbl.getSelectionIndex();
			return -1 != i ? cast(Card)_tbl.getItem(i).getData() : null;
		} else { mixin(S_TRACE);
			return _list.selectionCard;
		}
	}
	void deselectAll() { mixin(S_TRACE);
		if (_viewMode == CViewMode.TABLE) { mixin(S_TRACE);
			_tbl.deselectAll();
		} else { mixin(S_TRACE);
			_list.deselectAll();
		}
	}

	private void refreshUseCount() { mixin(S_TRACE);
		assert (colIndex(CardTableColumn.UC) != -1);
		if (_viewMode == CViewMode.TABLE) { mixin(S_TRACE);
			foreach (itm; _tbl.getItems()) { mixin(S_TRACE);
				auto c = cast(Card)itm.getData();
				itm.setText(colIndex(CardTableColumn.UC), to!(string)(ucGet(_summ.useCounter, _cardType, c.id)));
			}
		}
	}

	void open(bool shellActivate) { mixin(S_TRACE);
		assert (editMode);
		if (_ownerType is OwnerType.Summary) { mixin(S_TRACE);
			final switch (_cardType) {
			case CardType.Cast:
				_comm.openCastWin(shellActivate);
				break;
			case CardType.Skill:
				_comm.openSkillWin(shellActivate);
				break;
			case CardType.Item:
				_comm.openItemWin(shellActivate);
				break;
			case CardType.Beast:
				_comm.openBeastWin(shellActivate);
				break;
			case CardType.Info:
				_comm.openInfoWin(shellActivate);
				break;
			}
		} else if (_ownerType is OwnerType.Cast) { mixin(S_TRACE);
			assert (cast(CastCard)_owner !is null);
			auto cWin = _comm.handCardWindowFrom(_prop, _summ, cast(CastCard)_owner, true, shellActivate);
			cWin.open(_cardType, shellActivate);
		} else assert (0);
		_comm.refreshToolBar();
	}
	void create() { mixin(S_TRACE);
		assert (editMode);
		enterEdit();
		Card c;
		CardDialog dlg;
		final switch (_cardType) {
		case CardType.Cast:
			c = new CastCard(0, "", [], "", 1, 1);
			dlg = new CastCardDialog(_comm, _prop, dlgParShl, _summ, null, false);
			break;
		case CardType.Skill:
			c = new SkillCard(_prop.sys, 0, "", [], "");
			dlg = new EffectCardDialog!SkillCard(_comm, _prop, dlgParShl, _summ, _owner, _summ.useCounter, null, false);
			break;
		case CardType.Item:
			c = new ItemCard(_prop.sys, 0, "", [], "");
			dlg = new EffectCardDialog!ItemCard(_comm, _prop, dlgParShl, _summ, _owner, _summ.useCounter, null, false);
			break;
		case CardType.Beast:
			c = new BeastCard(_prop.sys, 0, "", [], "");
			dlg = new EffectCardDialog!BeastCard(_comm, _prop, dlgParShl, _summ, _owner, _summ.useCounter, null, false);
			break;
		case CardType.Info:
			c = new InfoCard(0, "", [], "");
			dlg = new InfoCardDialog(_comm, _prop, dlgParShl, _summ, null, false);
			break;
		}
		auto absDlg = cast(AbsDialog)dlg;
		assert (absDlg !is null);
		absDlg.appliedEvent ~= { mixin(S_TRACE);
			open(false);
			auto c = dlg.card;
			ulong id;
			if (_ownerType is OwnerType.Cast) { mixin(S_TRACE);
				// CastCardは手札追加時にコピーを生成する
				assert (cast(CastCard)_owner !is null);
				c = add(cast(CastCard)_owner, c);
				if (auto effDlg = cast(EffectCardDialog!SkillCard)dlg) { mixin(S_TRACE);
					effDlg.card = cast(SkillCard)c;
				} else if (auto effDlg = cast(EffectCardDialog!ItemCard)dlg) { mixin(S_TRACE);
					effDlg.card = cast(ItemCard)c;
				} else if (auto effDlg = cast(EffectCardDialog!BeastCard)dlg) { mixin(S_TRACE);
					effDlg.card = cast(BeastCard)c;
				}
			} else { mixin(S_TRACE);
				add(cast(Summary)_owner, c);
			}
			storeInsert([c.id]);
			refresh();
			deselectAll();
			selectID(c.id);
			final switch (_cardType) {
			case CardType.Cast:
				_comm.refCast.call(this, cast(CastCard)c);
				break;
			case CardType.Skill:
				_comm.refSkill.call(this, cast(SkillCard)c);
				break;
			case CardType.Item:
				_comm.refItem.call(this, cast(ItemCard)c);
				break;
			case CardType.Beast:
				_comm.refBeast.call(this, cast(BeastCard)c);
				break;
			case CardType.Info:
				_comm.refInfo.call(this, cast(InfoCard)c);
				break;
			}
			refOwnerCastCard(c);
			_comm.refreshToolBar();
			_comm.refUseCount.call();
			absDlg.appliedEvent.length = 0;
			absDlg.applyEvent ~= { mixin(S_TRACE);
				storeEdit([c.id]);
			};
			absDlg.appliedEvent ~= { mixin(S_TRACE);
				refresh();
				refCard(c);
				refOwnerCastCard(c);
				_comm.refreshToolBar();
			};
		};
		_editDlgs[c] = dlg;
		absDlg.closeEvent ~= { mixin(S_TRACE);
			_editDlgs.remove(c);
		};
		absDlg.open();
	}
	private void refOwnerCastCard(in Card c) { mixin(S_TRACE);
		if (_cardType !is CardType.Skill && _cardType !is CardType.Item && _cardType !is CardType.Beast) return;
		if (_ownerType is OwnerType.Cast) { mixin(S_TRACE);
			_comm.refCast.call(cast(CastCard)_owner);
		}
		if (_ownerType is OwnerType.Summary) { mixin(S_TRACE);
			bool[CastCard] casts;
			if (_cardType is CardType.Skill) { mixin(S_TRACE);
				foreach (o; _summ.useCounter.values(toSkillId(c.id))) { mixin(S_TRACE);
					if (auto ec = cast(SkillCard)o.owner) { mixin(S_TRACE);
						if (auto cc = cast(CastCard)ec.cwxParent) casts[cc] = true;
					}
				}
			} else if (_cardType is CardType.Item) { mixin(S_TRACE);
				foreach (o; _summ.useCounter.values(toItemId(c.id))) { mixin(S_TRACE);
					if (auto ec = cast(ItemCard)o.owner) { mixin(S_TRACE);
						if (auto cc = cast(CastCard)ec.cwxParent) casts[cc] = true;
					}
				}
			} else if (_cardType is CardType.Beast) { mixin(S_TRACE);
				foreach (o; _summ.useCounter.values(toBeastId(c.id))) { mixin(S_TRACE);
					if (auto ec = cast(BeastCard)o.owner) { mixin(S_TRACE);
						if (auto cc = cast(CastCard)ec.cwxParent) casts[cc] = true;
					}
				}
			} else assert (0);
			foreach (cc; casts.byKey()) { mixin(S_TRACE);
				_comm.refCast.call(cc);
			}
		}
	}
	bool addFromNode(ref XNode node, in XMLInfo ver) { mixin(S_TRACE);
		assert (editMode);
		enterEdit();
		Card[] adds;
		bool inPane = false;
		auto sameSumm = node.attr("summId", false) == ownerId;
		foreach (cardType; types) { mixin(S_TRACE);
			void f(CardType cardType) { mixin(S_TRACE);
				if (sameSumm) { mixin(S_TRACE);
					node.onTag[xmlNameFrom(cardType)] = (ref XNode cNode) { mixin(S_TRACE);
						auto card = createFromNode(cNode, ver);
						if (cNode.attr("paneId", false) != _id || localCard(card.id)) { mixin(S_TRACE);
							adds ~= card;
						} else { mixin(S_TRACE);
							if (_ownerType is OwnerType.Summary) inPane = true;
							adds ~= card;
						}
					};
					node.parse();
				} else { mixin(S_TRACE);
					node.onTag[xmlNameFrom(cardType)] = (ref XNode cNode) { mixin(S_TRACE);
						adds ~= createFromNode(cNode, ver);
					};
					node.parse();
				}
			}
			f(cardType);
		}
		if (adds.length == 0) return false;
		if (!sameSumm && !qCardMaterialCopy(node, adds)) return false;
		bool samePane = _id == node.attr("paneId", false);
		bool sameSc = ownerId == node.attr("summId", false);
		bool topLevel = node.attr!bool("topLevel", false, false);
		addCardsImpl(adds, inPane, samePane, sameSc, topLevel);
		return true;
	}
	void addCards(Card[] cs) { mixin(S_TRACE);
		assert (editMode);
		addCardsImpl(cs, false, false, false, true);
	}
	void addCardsImpl(Card[] allAdds, bool inPane, bool samePane, bool sameSc, bool topLevel) { mixin(S_TRACE);
		assert (editMode);
		enterEdit();
		Card[][CardType] adds;
		auto lastType = _cardType;
		foreach (card; allAdds) { mixin(S_TRACE);
			auto cardType = cardTypeFrom(card);
			adds[cardType] ~= card;
			lastType = cardType;
		}

		foreach (cardType, arr; adds) { mixin(S_TRACE);
			if (!arr.length) continue;
			auto pane = openSameLevelPane(cardType, lastType is cardType);
			ulong[] ids;
			foreach (ref card; arr) { mixin(S_TRACE);
				pane.refreshLink(card, samePane, sameSc, topLevel);
				if (pane._ownerType is OwnerType.Summary) { mixin(S_TRACE);
					ulong oldId = pane.add(cast(Summary)_owner, card);
					if (inPane) { mixin(S_TRACE);
						// 同じペイン内でコピー&ペースト
						if (_ownerType is OwnerType.Summary) change(pane.summary.useCounter, pane._cardType, oldId, card.id);
					}
				} else { mixin(S_TRACE);
					card = pane.add(cast(CastCard)_owner, card);
				}
				ids ~= card.id;
				pane.refCard(card);
			}
			pane.storeInsert(ids);
			pane.pasteRefresh(arr);
			_comm.refUseCount.call();
			if (pane._ownerType is OwnerType.Cast && (pane._cardType is CardType.Skill || pane._cardType is CardType.Item || pane._cardType is CardType.Beast)) { mixin(S_TRACE);
				_comm.refCast.call(cast(CastCard)pane._owner);
			}
		}
	}
	void pasteRefresh(Card[] cs) { mixin(S_TRACE);
		assert (editMode);
		assert (cs.length);
		enterEdit();
		deselectAll();
		if (_viewMode == CViewMode.TABLE) { mixin(S_TRACE);
			foreach (c; cs) { mixin(S_TRACE);
				if (!_incSearch.match(cardName(c))) continue;
				createTableItem(c);
			}
			auto count = _tbl.getItemCount();
			_tbl.select(.iota(count - cast(int)cs.length, count).array());
			_tbl.showSelection();
		} else { mixin(S_TRACE);
			refresh();
			auto count = _list.count;
			_list.selectionIndices = .iota(count - cast(int)cs.length, count).array();
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

	void refreshAll(Summary summ, CWXPath owner) { mixin(S_TRACE);
		enterEdit();
		_owner = owner;
		_summ = summ;
		refresh();
		if (_ownerType is OwnerType.Cast) { mixin(S_TRACE);
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
		enterEdit();
		_incSearch.close();
		auto index = selectionIndex;
		auto dlg = new ReNumDialog!(Card)(_prop, dlgParShl, _summ, cards[index],
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
		enterEdit();
		auto undo = new UndoIDs(this, _comm, _owner);
		ulong[] oldIDs;
		for (size_t i = index; i < cards.length; i++) { mixin(S_TRACE);
			oldIDs ~= cards[i].id;
			if (_ownerType is OwnerType.Summary) { mixin(S_TRACE);
				ulong ni = ulong.max - cards.length + i;
				if (_ownerType is OwnerType.Summary) change(summary.useCounter, _cardType, cards[i].id, ni);
				cards[i].id = ni;
			}
		}
		bool refIDs = false;
		for (size_t i = index; i < cards.length; i++) { mixin(S_TRACE);
			if (oldIDs[i - index] != newId) { mixin(S_TRACE);
				refIDs = true;
			}
			if (_ownerType is OwnerType.Summary) { mixin(S_TRACE);
				if (_ownerType is OwnerType.Summary) change(summary.useCounter, _cardType, cards[i].id, newId);
			}
			cards[i].id = newId;
			refCard(cards[i]);
			refresh(cards[i]);
			newId++;
		}
		refreshIDs();
		if (refIDs) _undo ~= undo;
		refreshStatusLine();
		_comm.refreshToolBar();
	}

	private CardDialog[Card] _editDlgs;
	CardDialog edit(Card c) { mixin(S_TRACE);
		enterEdit();
		auto p = c in _editDlgs;
		if (p) { mixin(S_TRACE);
			(cast(AbsDialog)(*p)).active();
			return *p;
		}
		if (0 != linkId(c)) { mixin(S_TRACE);
			assert (cast(EffectCard)c !is null);
			if (editMode) { mixin(S_TRACE);
				auto c2 = cardFrom(_summ, _cardType, linkId(c));
				if (c2) { mixin(S_TRACE);
					_comm.openCWXPath(c2.cwxPath(true), false);
					final switch (_cardType) {
					case CardType.Cast:
						assert (0);
					case CardType.Skill:
						return _comm.openSkillWin(false).edit(c2);
					case CardType.Item:
						return _comm.openItemWin(false).edit(c2);
					case CardType.Beast:
						return _comm.openBeastWin(false).edit(c2);
					case CardType.Info:
						assert (0);
					}
				}
				return null;
			} else { mixin(S_TRACE);
				c = cardFrom(_summ, _cardType, linkId(c));
				if (!c) return null;
			}
		}
		CardDialog dlg;
		final switch (_cardType) {
		case CardType.Cast:
			dlg = new CastCardDialog(_comm, _prop, dlgParShl, _summ, cast(CastCard)c, !editMode);
			break;
		case CardType.Skill:
			dlg = new EffectCardDialog!SkillCard(_comm, _prop, dlgParShl, _summ, _owner, _summ.useCounter, cast(SkillCard)c, !editMode);
			break;
		case CardType.Item:
			dlg = new EffectCardDialog!ItemCard(_comm, _prop, dlgParShl, _summ, _owner, _summ.useCounter, cast(ItemCard)c, !editMode);
			break;
		case CardType.Beast:
			dlg = new EffectCardDialog!BeastCard(_comm, _prop, dlgParShl, _summ, _owner, _summ.useCounter, cast(BeastCard)c, !editMode);
			break;
		case CardType.Info:
			dlg = new InfoCardDialog(_comm, _prop, dlgParShl, _summ, cast(InfoCard)c, !editMode);
			break;
		}
		auto absDlg = cast(AbsDialog)dlg;
		assert (absDlg !is null);
		if (editMode) { mixin(S_TRACE);
			absDlg.applyEvent ~= { mixin(S_TRACE);
				storeEdit([c.id]);
			};
			absDlg.appliedEvent ~= { mixin(S_TRACE);
				refresh();
				refCard(c);
				refOwnerCastCard(c);
				_comm.refreshToolBar();
				_comm.refUseCount.call();
			};
		}
		absDlg.closeEvent ~= { mixin(S_TRACE);
			_editDlgs.remove(c);
		};
		_editDlgs[c] = dlg;
		absDlg.open();
		return dlg;
	}
	CardDialog edit(int index = -1) { mixin(S_TRACE);
		CardDialog dlg = null;
		if (index == -1) { mixin(S_TRACE);
			foreach (card; selectedCards) { mixin(S_TRACE);
				dlg = edit(card);
			}
		} else { mixin(S_TRACE);
			dlg = edit(cards[index]);
		}
		return dlg;
	}
	void editUseEvent(bool canDuplicate = false) { mixin(S_TRACE);
		assert (_cardType is CardType.Skill || _cardType is CardType.Item || _cardType is CardType.Beast);
		auto sel = selection;
		if (sel) editUseEvent(sel, canDuplicate);
	}
	void editUseEvent(Card c, bool canDuplicate = false) { mixin(S_TRACE);
		assert (_cardType is CardType.Skill || _cardType is CardType.Item || _cardType is CardType.Beast);
		enterEdit();
		if (0 != linkId(c)) { mixin(S_TRACE);
			if (editMode) { mixin(S_TRACE);
				auto c2 = cardFrom(_summ, _cardType, linkId(c));
				if (c2) { mixin(S_TRACE);
					_comm.openCWXPath(c2.cwxPath(true), false);
					final switch (_cardType) {
					case CardType.Cast:
						assert (0);
					case CardType.Skill:
						_comm.openSkillWin(false).editUseEvent(c2, canDuplicate);
						break;
					case CardType.Item:
						_comm.openItemWin(false).editUseEvent(c2, canDuplicate);
						break;
					case CardType.Beast:
						_comm.openBeastWin(false).editUseEvent(c2, canDuplicate);
						break;
					case CardType.Info:
						assert (0);
					}
					return;
				}
				return;
			} else { mixin(S_TRACE);
				c = cardFrom(_summ, _cardType, linkId(c));
				if (!c) return;
			}
		}
		_comm.openUseEvents(_prop, _summ, cast(EffectCard)c, true, canDuplicate);
	}

	void editHand() { mixin(S_TRACE);
		assert (_cardType is CardType.Cast);
		assert (editMode);
		enterEdit();
		foreach (card; selectedCards) { mixin(S_TRACE);
			assert(cast(CastCard)card !is null);
			_comm.openHands(_prop, _summ, cast(CastCard)card, true);
		}
	}
	void editHandWith(CastCard card) { mixin(S_TRACE);
		assert (_cardType is CardType.Cast);
		if (_openHand) { mixin(S_TRACE);
			_openHand(card);
		} else { mixin(S_TRACE);
			assert (editMode);
			enterEdit();
			_comm.openHands(_prop, _summ, card, true);
		}
	}

	private void udImpl(bool up) { mixin(S_TRACE);
		assert (editMode);
		if (!(_tbl.getSortColumn() is null || _tbl.getSortColumn() is _idSorter.column)) return;
		enterEdit();
		int[] indices;
		auto arr = cardsFrom(_cardType, _owner);
		foreach (index; selectionIndices) { mixin(S_TRACE);
			if (_tbl.getSortDirection() is SWT.DOWN) { mixin(S_TRACE);
				// ID昇順に変更
				index = cast(int)arr.length - index - 1;
			}
			indices ~= index;
		}
		.sort(indices);
		auto selIndices = indices.dup;
		if (up) { mixin(S_TRACE);
			// 上へ移動
			if (indices[0] <= 0) return;
			storeUp(indices);
			selIndices[] -= 1;
		} else { mixin(S_TRACE);
			// 下へ移動
			if (arr.length <= indices[$ - 1] + 1) return;
			storeDown(indices);
			selIndices[] += 1;
		}
		udImpl(this, _comm, _owner, _cardType, indices, up);
		if (_viewMode == CViewMode.TABLE) { mixin(S_TRACE);
			if (up) { mixin(S_TRACE);
				foreach (index; indices) { mixin(S_TRACE);
					_tbl.upItem(index);
				}
			} else { mixin(S_TRACE);
				foreach_reverse (index; indices) { mixin(S_TRACE);
					_tbl.downItem(index);
				}
			}
			select(selIndices);
			_tbl.showSelection();
			_tbl.redraw();
		} else { mixin(S_TRACE);
			auto cursor = _list.cursor;
			refresh();
			cursor += up ? -1 : 1;
			_list.setCursor(cursor, true, false);
			select(selIndices);
		}
		_comm.refreshToolBar();
	}
	private static void udImpl(CardPane v, Commons comm, CWXPath owner, CardType cardType, in int[] indices, bool up) { mixin(S_TRACE);
		if (v) v.enterEdit();
		bool[int] refIndices;
		int[] selIndices;
		if (up) { mixin(S_TRACE);
			// 上へ移動
			foreach (index1; indices) { mixin(S_TRACE);
				auto index2 = index1 - 1;
				swap(owner, cardType, index1, index2);
				refIndices[index1] = true;
				refIndices[index2] = true;
				selIndices ~= index2;
			}
		} else { mixin(S_TRACE);
			// 下へ移動
			foreach_reverse (index1; indices) { mixin(S_TRACE);
				auto index2 = index1 + 1;
				swap(owner, cardType, index1, index2);
				refIndices[index1] = true;
				refIndices[index2] = true;
				selIndices ~= index2;
			}
		}
		auto arr = cardsFrom(cardType, owner);
		foreach (index; refIndices.byKey()) { mixin(S_TRACE);
			refCard(v, comm, arr[index]);
		}
	}
	bool canUp() { mixin(S_TRACE);
		assert (editMode);
		if (!_summ) return false;
		if (!_tbl || !_list || !_incSearch) return false;
		if (_tbl.isDisposed()) return false;
		if (narrowCount != cards.length) return false;
		if (!(_tbl.getSortColumn() is null || _tbl.getSortColumn() is _idSorter.column)) return false;
		auto sel = selectionIndices;
		if (!sel.length) return false;
		.sort(sel);
		return 0 < sel[0];
	}
	bool canDown() { mixin(S_TRACE);
		assert (editMode);
		if (!_summ) return false;
		if (!_tbl || !_list || !_incSearch) return false;
		if (_tbl.isDisposed()) return false;
		if (narrowCount != cards.length) return false;
		if (!(_tbl.getSortColumn() is null || _tbl.getSortColumn() is _idSorter.column)) return false;
		auto sel = selectionIndices;
		if (!sel.length) return false;
		.sort(sel);
		return sel[$ - 1] + 1 < cards.length;
	}
	void up() { mixin(S_TRACE);
		assert (editMode);
		if (!canUp()) return;
		udImpl(true);
	}
	void down() { mixin(S_TRACE);
		assert (editMode);
		if (!canDown()) return;
		udImpl(false);
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
		cancelEdit();
		_undo.undo();
		_comm.refreshToolBar();
	}
	void redo() { mixin(S_TRACE);
		assert (editMode);
		cancelEdit();
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

	void replaceID() { mixin(S_TRACE);
		assert (editMode);
		enterEdit();
		auto sel = selection;
		if (sel) { mixin(S_TRACE);
			final switch (_cardType) {
			case CardType.Cast:
				_comm.replaceID(CastCard.toID(sel.id), true);
				break;
			case CardType.Skill:
				_comm.replaceID(SkillCard.toID(sel.id), true);
				break;
			case CardType.Item:
				_comm.replaceID(ItemCard.toID(sel.id), true);
				break;
			case CardType.Beast:
				_comm.replaceID(BeastCard.toID(sel.id), true);
				break;
			case CardType.Info:
				_comm.replaceID(InfoCard.toID(sel.id), true);
				break;
			}
		}
	}
	@property
	bool canReplaceID() { mixin(S_TRACE);
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

	void enterEdit() {
		if (_cle) _cle.enter();
		if (_tte) _tte.enter();
		if (_ttce) _ttce.enter();
	}

	void cancelEdit() {
		if (_cle) _cle.cancel();
		if (_tte) _tte.cancel();
		if (_ttce) _ttce.cancel();
	}

	@property
	string[] openedCWXPath() { mixin(S_TRACE);
		string[] r;
		foreach (c; selectedCards) { mixin(S_TRACE);
			r ~= c.cwxPath(true);
		}
		if (!r.length) { mixin(S_TRACE);
			final switch (_cardType) {
			case CardType.Cast:
				r ~= .cpjoin(owner, "castcardview", true);
				break;
			case CardType.Skill:
				r ~= .cpjoin(owner, "skillcardview", true);
				break;
			case CardType.Item:
				r ~= .cpjoin(owner, "itemcardview", true);
				break;
			case CardType.Beast:
				r ~= .cpjoin(owner, "beastcardview", true);
				break;
			case CardType.Info:
				r ~= .cpjoin(owner, "infocardview", true);
				break;
			}
		}
		return r;
	}
}
