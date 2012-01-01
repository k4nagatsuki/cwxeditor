
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

import cwx.editor.gui.dwt.commondialog;
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

import std.algorithm;
import std.array;
import std.utf;
import std.string;
import std.datetime;
import std.typetuple;
import std.path;

import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.ToolBar;
import org.eclipse.swt.widgets.ToolItem;
import org.eclipse.swt.widgets.Menu;
import org.eclipse.swt.widgets.MenuItem;
import org.eclipse.swt.widgets.MessageBox;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableColumn;
import org.eclipse.swt.widgets.TableItem;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.ImageData;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.FillLayout;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.ShellAdapter;
import org.eclipse.swt.events.ShellEvent;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.events.MouseAdapter;
import org.eclipse.swt.events.MouseEvent;
import org.eclipse.swt.events.KeyAdapter;
import org.eclipse.swt.events.KeyEvent;
import org.eclipse.swt.events.ControlAdapter;
import org.eclipse.swt.events.ControlEvent;
import org.eclipse.swt.custom.StackLayout;
import org.eclipse.swt.custom.CTabFolder;
import org.eclipse.swt.custom.CTabItem;
import org.eclipse.swt.dnd.DND;
import org.eclipse.swt.dnd.ByteArrayTransfer;
import org.eclipse.swt.dnd.FileTransfer;
import org.eclipse.swt.dnd.DragSource;
import org.eclipse.swt.dnd.DragSourceAdapter;
import org.eclipse.swt.dnd.DragSourceEvent;
import org.eclipse.swt.dnd.DropTarget;
import org.eclipse.swt.dnd.DropTargetAdapter;
import org.eclipse.swt.dnd.DropTargetEvent;
import org.eclipse.swt.dnd.Clipboard;

import java.lang.all;

private enum CViewMode {INIT, LIFE, CARD, TABLE}

private class CardPane(PCardOwner, CardOwner, C : Card, ToCardOwner, string GetAll, string GetFromId) : TCPD {
private:
	static const bool EditMode = is (ToCardOwner == void);
	private static C[] cardsFrom(CardOwner owner) {mixin ("return owner." ~ GetAll ~ ";");}
	@property
	public C[] cards() {return cardsFrom(owner);}
	@property
	private C[] __cards() {
		if (_owner) {
			return cards;
		}
		return [];
	}
	public C card(ulong id) {mixin ("return owner." ~ GetFromId ~ "(id);");}
	private C __card(ulong id) {
		if (_owner) {
			return card(id);
		}
		return null;
	}
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
					v.select = _selB;
					v.refreshStatusLine();
				}
				comm.refUseCount.call();
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
				_sel = _from;
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
					auto node = c.toNode();
					auto card = C.createFromNode(node, LATEST_VERSION);
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
			static if (is (C == SkillCard) && is (CardOwner == CastCard)) {
				_statusLine = _prop.msgs.handCardStatus(c, s, _prop.looks.skillCardMaxNum(owner.level));
			} else static if (is (C == ItemCard) && is (CardOwner == CastCard)) {
				_statusLine = _prop.msgs.handCardStatus(c, s, _prop.looks.itemCardMaxNum(owner.level));
			} else static if (is (C == BeastCard) && is (CardOwner == CastCard)) {
				_statusLine = _prop.msgs.handCardStatus(c, s, _prop.looks.beastCardMaxNum(owner.level));
			} else {
				_statusLine = _prop.msgs.cardStatus(c, s);
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
		}
	}
	void __refreshR(string from, string to) {
		__refresh();
	}
	void refresh(C c) {
		if (!_tbl || _tbl.isDisposed()) return;
		int i;
		for (i = 0; i < cards.length; i++) {
			if (cards[i] is c) {
				break;
			}
		}
		if (i >= cards.length) return;
		if (_viewMode == CViewMode.TABLE) {
			refreshTableItem(c, _tbl.getItem(i));
		} else {
			refreshListItem(i);
		}
		refreshStatusLine();
	}
	void __refresh() {
		if (_viewMode == CViewMode.TABLE) {
			C sel = null;
			auto sels = _tbl.getSelection();
			if (sels.length > 0) {
				sel = cast(C) sels[0].getData();
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
			_list.refresh(__cards, &__cardImage);
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
	void refreshListItem(int index) {
		_list.refresh(index);
	}
	void refreshTableItem(C c, TableItem itm) {
		itm.setImage(0, _cimg);
		itm.setText(0, to!(string)(c.id));
		itm.setText(1, c.name);
		if (c.desc.length > 0) {
			// FIXME: セルの値が長すぎると表示されないことがあるので自らカット
			string desc = std.array.replace(c.desc, "\n", "");
			dstring ddesc = toUTF32(desc);
			if (ddesc.length > 50) {
				desc = toUTF8(ddesc[0 .. 50] ~ "...");
			}
			itm.setText(2, desc);
		}
		static if (is (CardOwner == Summary)) {
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
				} catch (Exception e) {
					debugln(e);
				}
			}
		}
		override bool canDoTCPD() {
			return widget.isFocusControl();
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
			auto sels = _tbl.getSelection();
			return sels.length > 0 ? cast(C) sels[0].getData() : null;
		}
		mixin CopyAndPaste;
		override void del(SelectionEvent se) {
			static if (EditMode) {
				auto c = selectionCard;
				if (c) {
					storeDelete([_tbl.getSelectionIndex()]);
					_owner.remove(c);
					_tbl.getSelection()[0].dispose();
					_tbl.redraw();
					delCard(c);
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
					ulong[C] oldIDs;
					foreach (card; cards) oldIDs[card] = card.id;
					scope (exit) {
						foreach (card; cards) {
							auto pc = card in oldIDs;
							if (pc && *pc != card.id) refCard(card); 
						}
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
						storeMove(_owner.indexOf!C(card), index);
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
			auto skin = _comm.skin;
			bool r = qMaterialCopy(_prop, skin, dlgParShl,
				uc, _summ.scenarioPath, fromSPath, copy, _summ.legacy);
			foreach (c; cs) {
				c.removeUseCounter();
			}
			if (copy) {
				_comm.refPaths.call(skin.materialPath);
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
	ImageData __cardImage(C c) {
		Skin skin = _skinTemp ? _skinTemp : _comm.skin;
		static if (is (C == CastCard)) {
			return castCardImage(_prop, skin, c, ownerScenarioPath, _viewMode == CViewMode.LIFE);
		} else static if (!is (C == InfoCard) && is (CardOwner == CastCard)) {
			return cardImage!(C)(_prop, skin, c, ownerScenarioPath, _owner);
		} else {
			return cardImage!(C)(_prop, skin, c, ownerScenarioPath, cast(CastCard) null);
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
		int index = -1;
		if (sels.length > 0) {
			index = sels[0];
		}
		refresh();
		if (index >= 0) {
			_list.select(index);
			_list.scroll(index);
		} else {
			_list.deselectAll();
		}
		refreshStatusLine();
	}
	void __refTbl() {
		int index = _list.selection;
		refresh();
		if (index >= 0) {
			_tbl.setSelection([index]);
			_tbl.showSelection();
		}
		refreshStatusLine();
	}
	void toNode(ref XNode sn, C[] sels) {
		sn.newAttr("summId", ownerId);
		sn.newAttr("paneId", _id);
		sn.newAttr("scenarioPath", nabs(ownerScenarioPath));
		foreach (sel; sels) {
			sel.toNode(sn);
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
	}
	class LMouse : MouseAdapter {
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
		override void mouseDoubleClick(MouseEvent e) {
			if (e.button != 1) return;
			int index = _tbl.getSelectionIndex();
			if (index >= 0) {
				scope p = _tbl.toControl(e.x, e.y);
				auto itm = _tbl.getItem(index);
				for (int i = 0; i < _tbl.getColumnCount(); i++) {
					if (itm.getBounds(i).contains(e.x, e.y)) {
						static if (EditMode) {
							edit(cast(C) _tbl.getSelection()[0].getData());
						} else {
							addCard();
						}
						break;
					}
				}
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
			if (keyMatch && _tbl.getSelectionIndex() >= 0) {
				static if (EditMode) {
					edit(cast(C) _tbl.getSelection()[0].getData());
				} else {
					addCard();
				}
			}
		}
	}
	private class SelChanged : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			refreshStatusLine();
		}
	}
	static if (is(CardOwner : Summary)) {
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
	void createCardList(Composite parent) {
		_list = new CardList!(C)(parent, SWT.VIRTUAL | SWT.V_SCROLL | (EditMode ? SWT.SINGLE : SWT.MULTI) | SWT.BORDER);
		_list.setLayoutValues(_prop.var.etc.cardsMarginX, _prop.var.etc.cardsSpaceX,
			_prop.var.etc.cardsMarginY, _prop.var.etc.cardsSpaceY, _prop.var.etc.cardsDefaultWrap);
		_list.selectChanged(&refreshStatusLine);
		_tbl = new Table(parent, SWT.FULL_SELECTION | (EditMode ? SWT.SINGLE : SWT.MULTI) | SWT.BORDER);
		_tbl.addSelectionListener(new SelChanged);
		_tbl.setHeaderVisible(true);
		auto idCol = new TableColumn(_tbl, SWT.NONE);
		idCol.setText(_prop.msgs.cardId);
		idCol.setWidth(_prop.var.etc.cardIdColumn);
		static if (is(CardOwner : Summary)) {
			idCol.addControlListener(new ColResize!("cardIdColumn"));
		}
		auto nameCol = new TableColumn(_tbl, SWT.NONE);
		nameCol.setText(_prop.msgs.cardName);
		nameCol.setWidth(_prop.var.etc.cardNameColumn);
		static if (is(CardOwner : Summary)) {
			nameCol.addControlListener(new ColResize!("cardNameColumn"));
		}
		auto descCol = new TableColumn(_tbl, SWT.NONE);
		descCol.setText(_prop.msgs.cardDesc);
		descCol.setWidth(_prop.var.etc.cardDescriptionColumn);
		static if (is(CardOwner : Summary)) {
			descCol.addControlListener(new ColResize!("cardDescriptionColumn"));
		}
		static if (is (CardOwner == Summary)) {
			auto ucCol = new TableColumn(_tbl, SWT.NONE);
			ucCol.setText(_prop.msgs.cardCount);
			ucCol.setWidth(_prop.var.etc.cardCountColumn);
			static if (is(CardOwner : Summary)) {
				ucCol.addControlListener(new ColResize!("cardCountColumn"));
			}
		}
		static if (is(CardOwner : Summary)) {
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
			static if (is (C == CastCard)) {
				auto drag = new DragSource(c, DND.DROP_MOVE | DND.DROP_COPY | DND.DROP_LINK);
			} else {
				auto drag = new DragSource(c, DND.DROP_MOVE | DND.DROP_COPY);
			}
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
public:
	static if (!EditMode) {
		static if (is (C == CastCard)) {
			this(Commons comm, Props prop, PCardOwner summ, Composite parent, ToCardOwner toc, void delegate() openHand) {
				_parent = parent;
				_toc = toc;
				_openHand = openHand;
				_skinTemp = findSkin(comm, prop, summ);
				construct1(comm, prop, summ);
			}
		} else {
			this(Commons comm, Props prop, PCardOwner summ, Composite parent, ToCardOwner toc) {
				_parent = parent;
				_toc = toc;
				_skinTemp = findSkin(comm, prop, summ);
				construct1(comm, prop, summ);
			}
		}
		void construct() {
			reconstruct(_parent);
		}
	} else static if (is (C : Card)) {
		this(Commons comm, Props prop, PCardOwner summ, Composite parent) {
			_parent = parent;
			construct1(comm, prop, summ);
		}
		void construct() {
			reconstruct(_parent);
		}
	} else {
		static assert (0);
	}
	
	void reconstruct(Composite parent) {
		_parent = parent;
		createCardList(parent);
		static if (is (PCardOwner == Summary)) {
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
		static if (is (CardOwner == Summary)) {
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
				createMenuItem(pop, _prop.msgs.menuCEdit, _prop.images.menuCEdit, &editM);
				new MenuItem(pop, SWT.SEPARATOR);
				createMenuItem(pop, _prop.msgs.menuEditHand, _prop.images.menuEditHand, &editHand);
			} else static if (is (C == SkillCard) || is (C == ItemCard) || is (C == BeastCard)) {
				createMenuItem(pop, _prop.msgs.menuCEdit, _prop.images.menuCEdit, &editM);
				new MenuItem(pop, SWT.SEPARATOR);
				createMenuItem(pop, _prop.msgs.menuEditUseEvent, _prop.images.menuEditUseEvent, &editUseEvent);
			} else static if (is (C == InfoCard)) {
				createMenuItem(pop, _prop.msgs.menuCEdit, _prop.images.menuCEdit, &editM);
			} else {
				static assert (0);
			}
			new MenuItem(pop, SWT.SEPARATOR);
			createMenuItem(pop, _prop.msgs.menuUndo, _prop.images.menuUndo, &undo);
			createMenuItem(pop, _prop.msgs.menuRedo, _prop.images.menuRedo, &redo);
			new MenuItem(pop, SWT.SEPARATOR);
			appendMenuTCPD(_prop, pop, this, true, true, true, true);
			new MenuItem(pop, SWT.SEPARATOR);
			createMenuItem(pop, _prop.msgs.menuReNumbering, _prop.images.menuReNumbering, &reNumbering);
		} else {
			auto pop = new Menu(parent.getShell(), SWT.POP_UP);
			static if (is (C == CastCard)) {
				createMenuItem(pop, _prop.msgs.menuOpenHand, _prop.images.menuOpenHand, _openHand);
				new MenuItem(pop, SWT.SEPARATOR);
			}
			createMenuItem(pop, _prop.msgs.menuAdd, _prop.images.menuAdd, &addCard);
			new MenuItem(pop, SWT.SEPARATOR);
			appendMenuTCPD(_prop, pop, this, false, true, false, false);
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
		if (_viewMode == CViewMode.TABLE) {
			return _tbl.getSelectionIndex();
		} else {
			return _list.selection;
		}
	}
	@property
	C selection() {
		if (_viewMode == CViewMode.TABLE) {
			return _tbl.getSelectionIndex() >= 0 ? cast(C) _tbl.getSelection()[0].getData() : null;
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
				dlg.appliedEvent.length = 0;
				dlg.applyEvent ~= {
					storeEdit(_owner.indexOf(c));
				};
				dlg.appliedEvent ~= {
					refresh();
					refCard(c);
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
			foreach (card; adds) {
				indices ~= cards.length;
				static if (is (CardOwner == Summary)) {
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
		}
	}
	void refreshAll(PCardOwner summ, CardOwner owner) {
		_owner = owner;
		_summ = summ;
		refresh();
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
				if (sel) {
					_comm.openUseEvents(_prop, _summ, sel, true);
				}
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
			select = index2;
		}
		void up() {
			int sel = selectionIndex;
			if (-1 == sel) return;
			udImpl(sel, sel - 1);
		}
		void down() {
			int sel = selectionIndex;
			if (-1 == sel) return;
			udImpl(sel, sel + 1);
		}
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
		@property
		bool canDoTCPD() {
			return _list.isVisible() || _tbl.isVisible();
		}
	}
	static if (EditMode) {
		void undo() {
			_undo.undo();
		}
		void redo() {
			_undo.redo();
		}
	}

	@property
	string[] openedCWXPath() {
		string[] r;
		foreach (c; selectedCards) {
			r ~= c.cwxPath;
		}
		return r;
	}
}

template CastCardPane(PCardOwner, CardOwner, ToCardOwner) {
	alias CardPane!(PCardOwner, CardOwner, CastCard, ToCardOwner, "casts", "cwCast") CastCardPane;
}
template SkillCardPane(PCardOwner, CardOwner, ToCardOwner) {
	alias CardPane!(PCardOwner, CardOwner, SkillCard, ToCardOwner, "skills", "skill") SkillCardPane;
}
template ItemCardPane(PCardOwner, CardOwner, ToCardOwner) {
	alias CardPane!(PCardOwner, CardOwner, ItemCard, ToCardOwner, "items", "item") ItemCardPane;
}
template BeastCardPane(PCardOwner, CardOwner, ToCardOwner) {
	alias CardPane!(PCardOwner, CardOwner, BeastCard, ToCardOwner, "beasts", "beast") BeastCardPane;
}
template InfoCardPane(PCardOwner, CardOwner, ToCardOwner) {
	alias CardPane!(PCardOwner, CardOwner, InfoCard, ToCardOwner, "infos", "info") InfoCardPane;
}
