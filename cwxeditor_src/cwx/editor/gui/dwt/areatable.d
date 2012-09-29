
module cwx.editor.gui.dwt.areatable;

import cwx.flag;
import cwx.area;
import cwx.event;
import cwx.utils;
import cwx.summary;
import cwx.background;
import cwx.usecounter;
import cwx.xml;
import cwx.skin;
import cwx.path;
import cwx.structs;
import cwx.menu;
import cwx.types;

import cwx.editor.gui.dwt.smalldialogs;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.flagtable;
import cwx.editor.gui.dwt.areaview;
import cwx.editor.gui.dwt.areawindow;
import cwx.editor.gui.dwt.eventwindow;
import cwx.editor.gui.dwt.summarydialog;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.properties;
import cwx.editor.gui.dwt.xmlbytestransfer;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.dmenu;

import std.conv;

import org.eclipse.swt.all;

import java.lang.all;

/// エリア・バトル・パッケージの一覧を表示する。
class AreaTable : TCPD {
private:
	static class ATUndo : Undo {
		protected AreaTable _v = null;
		protected Commons comm;
		protected Summary summ;

		private ulong[] _areaIDs;
		private ulong[] _areaIDsB;
		private ulong[] _battleIDsB;
		private ulong[] _battleIDs;
		private ulong[] _packageIDs;
		private ulong[] _packageIDsB;
		private int _sel;
		private int _selB;

		this (AreaTable v, Commons comm, Summary summ) {
			_v = v;
			this.comm = comm;
			this.summ = summ;

			saveIDs(v);
		}
		private void saveIDs(AreaTable v) {
			_areaIDs.length = 0;
			foreach (a; summ.areas) _areaIDs ~= a.id;
			_battleIDs.length = 0;
			foreach (a; summ.battles) _battleIDs ~= a.id;
			_packageIDs.length = 0;
			foreach (a; summ.packages) _packageIDs ~= a.id;
			if (v && v._areas && !v._areas.isDisposed()) {
				_sel = v._areas.getSelectionIndex();
			}
		}
		abstract override void undo();
		abstract override void redo();
		abstract override void dispose();
		protected void udb(AreaTable v) {
			_areaIDsB = _areaIDs.dup;
			_battleIDsB = _battleIDs.dup;
			_packageIDsB = _packageIDs.dup;
			_selB = _sel;
			saveIDs(v);
			if (v && v._areas && !v._areas.isDisposed()) {
				.forceFocus(v._areas, false);
			}
		}
		private void resetID(alias ToID, A)(AreaTable v, A[] arr, ulong[] ids) {
			ulong[] oldIDs;
			foreach (i, a; arr) {
				auto oID = a.id;
				a.id = ulong.max - arr.length + i;
				summ.useCounter.change(ToID(oID), ToID(a.id));
				oldIDs ~= oID;
			}
			foreach (i, a; arr) {
				auto oID = a.id;
				a.id = ids[i];
				summ.useCounter.change(ToID(oID), ToID(a.id));
			}
			foreach (i, a; arr) {
				if (a.id != oldIDs[i]) {
					static if (is(A : Area)) {
						comm.refArea.call(v, a);
					} else static if (is(A : Battle)) {
						comm.refBattle.call(v, a);
					} else static if (is(A : Package)) {
						comm.refPackage.call(v, a);
					} else static assert (0);
				}
			}
		}
		protected void uda(AreaTable v) {
			resetID!toAreaId(v, summ.areas, _areaIDsB);
			resetID!toBattleId(v, summ.battles, _battleIDsB);
			resetID!toPackageId(v, summ.packages, _packageIDsB);
			if (v && v._areas && !v._areas.isDisposed()) {
				int i = 0;
				foreach (a; summ.areas) {
					v.refData(a, v._areas.getItem(i));
					i++;
				}
				foreach (a; summ.battles) {
					v.refData(a, v._areas.getItem(i));
					i++;
				}
				foreach (a; summ.packages) {
					v.refData(a, v._areas.getItem(i));
					i++;
				}
				v._areas.select(_selB);
				v._areas.showSelection();
				v.refreshStatusLine();
			}
			comm.refUseCount.call();
			comm.refreshToolBar();
		}
		protected AreaTable view() {
			return _v;
		}
	}
	static class UndoIDs : ATUndo {
		this (AreaTable v, Commons comm, Summary summ) {
			super (v, comm, summ);
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
	static class UndoEdit : ATUndo {
		private string _name;
		private int _index;
		this (AreaTable v, Commons comm, Summary summ, int index) {
			super (v, comm, summ);
			_name = areaFromIndex(summ, index).name;
			_index = index;
		}
		private void impl() {
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			auto area = areaFromIndex(summ, _index);
			string oldName = area.name;
			area.name = _name;
			_name = oldName;
			if (v && v._areas && !v._areas.isDisposed()) {
				v._areas.getItem(_index).setText(NAME, area.name);
			}
			auto a = cast(Area) area;
			if (a) {
				comm.refArea.call(v, a);
			}
			auto b = cast(Battle) area;
			if (b) {
				comm.refBattle.call(v, b);
			}
			auto p = cast(Package) area;
			if (p) {
				comm.refPackage.call(v, p);
			}
			comm.refUseCount.call();
		}
		override void undo() {
			impl();
		}
		override void redo() {
			impl();
		}
		override void dispose() {}
	}
	void storeEdit(int index) {
		_undo ~= new UndoEdit(this, _comm, _summ, index);
	}
	static class UndoMove : ATUndo {
		private int _from, _to;
		this (AreaTable v, Commons comm, Summary summ, int from, int to) {
			super (v, comm, summ);
			_from = from;
			_to = to;
		}
		private void impl() {
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			auto area = areaFromIndex(summ, _to);
			int from = _from;
			if (_to <= from) from++;
			auto a = cast(Area) area;
			if (a) summ.insert(toAreaIndex(summ, from), a);
			auto b = cast(Battle) area;
			if (b) summ.insert(toBattleIndex(summ, from), b);
			auto p = cast(Package) area;
			if (p) summ.insert(toPackageIndex(summ, from), p);
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
		_undo ~= new UndoMove(this, _comm, _summ, from, to);
	}
	static class UndoSwap : ATUndo {
		private int _index1, _index2;
		this (AreaTable v, Commons comm, Summary summ, int index1, int index2) {
			super (v, comm, summ);
			_index1 = index1;
			_index2 = index2;
		}
		private void impl() {
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			auto area1 = areaFromIndex(summ, _index1);
			auto area2 = areaFromIndex(summ, _index2);
			auto a = cast(Area) area1;
			if (a) {
				summ.swap!Area(toAreaIndex(summ, _index1), toAreaIndex(summ, _index2));
				comm.refArea.call(cast(Area) area1);
				comm.refArea.call(cast(Area) area2);
			}
			auto b = cast(Battle) area1;
			if (b) {
				summ.swap!Battle(toBattleIndex(summ, _index1), toBattleIndex(summ, _index2));
				comm.refBattle.call(cast(Battle) area1);
				comm.refBattle.call(cast(Battle) area2);
			}
			auto p = cast(Package) area1;
			if (p) {
				summ.swap!Package(toPackageIndex(summ, _index1), toPackageIndex(summ, _index2));
				comm.refPackage.call(cast(Package) area1);
				comm.refPackage.call(cast(Package) area2);
			}
			std.algorithm.swap(_index1, _index2);
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
		_undo ~= new UndoSwap(this, _comm, _summ, index1, index2);
	}
	static class UndoInsertDelete : ATUndo {
		private bool _insert;

		private int _index;

		private AbstractArea _area = null;
		private bool _isStartArea = false;

		this (AreaTable v, Commons comm, Summary summ, int index, bool insert) {
			super (v, comm, summ);
			_insert = insert;
			_index = index;

			if (!insert) {
				initUndoDelete();
			}
		}
		private void initUndoDelete() {
			auto area = areaFromIndex(summ, _index);
			_isStartArea = cast(Area) area && summ.startArea == area.id;
			auto node = area.toNode(null);
			auto a = cast(Area) area;
			if (a) {
				_area = Area.createFromNode(node, LATEST_VERSION);
			}
			auto b = cast(Battle) area;
			if (b) {
				_area = Battle.createFromNode(node, LATEST_VERSION);
			}
			auto p = cast(Package) area;
			if (p) {
				_area = Package.createFromNode(node, LATEST_VERSION);
			}
			assert (_area);
			_area.setUseCounter(summ.useCounter.sub);
		}
		private void undoInsert() {
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			_insert = false;
			initUndoDelete();
			auto area = areaFromIndex(summ, _index);
			summ.remove(area);
			if (v && v._areas && !v._areas.isDisposed()) {
				v._areas.remove(_index);
			}
			auto a = cast(Area) area;
			if (a) {
				comm.delArea.call(v, a);
			}
			auto b = cast(Battle) area;
			if (b) {
				comm.delBattle.call(v, b);
			}
			auto p = cast(Package) area;
			if (p) {
				comm.delPackage.call(v, p);
			}
			comm.refUseCount.call();
		}
		void undoDelete() {
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			scope (exit) {
				_area.removeUseCounter();
				_area = null;
			}
			_insert = true;
			auto a = cast(Area) _area;
			if (a) {
				int i = toAreaIndex(summ, _index);
				summ.insert(i, a);
				if (v && v._areas && !v._areas.isDisposed()) v.newAreaItem(i);
				if (_isStartArea) {
					summ.startArea = a.id;
					_isStartArea = false;
				}
				comm.refArea.call(v, a);
				return;
			}
			auto b = cast(Battle) _area;
			if (b) {
				int i = toBattleIndex(summ, _index);
				summ.insert(i, b);
				if (v && v._areas && !v._areas.isDisposed()) v.newBattleItem(i);
				comm.refBattle.call(v, b);
				return;
			}
			auto p = cast(Package) _area;
			if (p) {
				int i = toPackageIndex(summ, _index);
				summ.insert(i, p);
				if (v && v._areas && !v._areas.isDisposed()) v.newPackageItem(i);
				comm.refPackage.call(v, p);
				return;
			}
			assert (0);
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
			if (_area) {
				_area.removeUseCounter();
			}
		}
	}
	void storeInsert(int index) {
		_undo ~= new UndoInsertDelete(this, _comm, _summ, index, true);
	}
	void storeDelete(int index) {
		_undo ~= new UndoInsertDelete(this, _comm, _summ, index, false);
	}

	void editEnd(TableItem itm, int column, string newText) {
		assert (column == 1);
		if (newText.length > 0) {
			auto area = cast(AbstractArea) itm.getData();
			if (area.name == newText) return;
			storeEdit(_areas.indexOf(itm));
			area.name = newText;
			itm.setText(NAME, newText);
			if (cast(Area) area) {
				_comm.refArea.call(cast(Area) area);
			} else if (cast(Battle) area) {
				_comm.refBattle.call(cast(Battle) area);
			} else {
				assert (cast(Package) area);
				_comm.refPackage.call(cast(Package) area);
			}
			_comm.refreshToolBar();
		}
	}
	private static const ID = 0;
	private static const NAME = 1;
	private static const UC = 2;

	Commons _comm;
	Props _prop;
	FlagTable _flags = null;
	Summary _summ;

	Table _areas;
	TableTextEdit _areasEdit;

	UndoManager _undo;

	string _statusLine = "";
	void refreshStatusLine() {
		string s = "";
		void put(lazy string name, size_t count) {
			if (!count) return;
			if (s.length) s ~= " ";
			s ~= .tryFormat(_prop.msgs.areaStatus, name, count);
		}
		if (_summ) {
			put(_prop.msgs.area, _summ.areas.length);
			put(_prop.msgs.battle, _summ.battles.length);
			put(_prop.msgs.cwPackage, _summ.packages.length);
		}
		_statusLine = s;
		_comm.setStatusLine(_areas, _statusLine);
	}

	static int toIndex(A)(Summary summ, int index) {
		static if (is(A : Area)) {
			return index;
		} else static if (is(A : Battle)) {
			return index - summ.areas.length;
		} else static if (is(A : Package)) {
			return index - (summ.areas.length + summ.battles.length);
		} else static assert (0);
	}
	alias toIndex!Area toAreaIndex;
	alias toIndex!Battle toBattleIndex;
	alias toIndex!Package toPackageIndex;
	static AbstractArea areaFromIndex(Summary summ, int index) {
		if (summ.areas.length + summ.battles.length <= index) {
			return summ.packages[toPackageIndex(summ, index)];
		}
		if (summ.areas.length <= index) {
			return summ.battles[toBattleIndex(summ, index)];
		}
		return summ.areas[toAreaIndex(summ, index)];
	}
	AbstractArea getSelectionArea() {
		auto i = _areas.getSelectionIndex();
		if (-1 != i) {
			return cast(AbstractArea) _areas.getItem(i).getData();
		}
		return null;
	}
	void refArea(Object sender, Area a) {
		if (sender is this) return;
		foreach (itm; _areas.getItems()[0 .. _summ.areas.length]) {
			if (itm.getData() is a) refData(a, itm);
		}
	}
	void refBattle(Object sender, Battle a) {
		if (sender is this) return;
		size_t ai = _summ.areas.length;
		foreach (itm; _areas.getItems()[ai .. ai + _summ.battles.length]) {
			if (itm.getData() is a) refData(a, itm);
		}
	}
	void refPackage(Object sender, Package a) {
		if (sender is this) return;
		size_t ai = _summ.areas.length;
		size_t bi = _summ.battles.length;
		foreach (itm; _areas.getItems()[ai + bi .. ai + bi + _summ.packages.length]) {
			if (itm.getData() is a) refData(a, itm);
		}
	}
	void callRefArea(AbstractArea area) {
		auto a = cast(Area) area;
		if (a) {
			_comm.refArea.call(this, a);
			return;
		}
		auto b = cast(Battle) area;
		if (b) {
			_comm.refBattle.call(this, b);
			return;
		}
		auto p = cast(Package) area;
		if (p) {
			_comm.refPackage.call(this, p);
			return;
		}
	}
	void refreshIDs(bool callRef) {
		if (!_areas || _areas.isDisposed()) return;
		foreach (itm; _areas.getItems()) {
			auto area = cast(AbstractArea) itm.getData();
			auto str = to!(string)(area.id);
			if (callRef && str != itm.getText(ID)) callRefArea(area);
			itm.setText(ID, str);
		}
	}

	class DragArea : DragSourceAdapter {
		AbstractArea _data;
		override void dragStart(DragSourceEvent e) {
			auto tbl = cast(Table) (cast(DragSource) e.getSource()).getControl();
			e.doit = tbl.isFocusControl() && tbl.getSelectionIndex() != -1;
		}
		override void dragSetData(DragSourceEvent e){
			if (XMLBytesTransfer.getInstance().isSupportedType(e.dataType)) {
				auto tbl = cast(Table) (cast(DragSource) e.getSource()).getControl();
				int i = tbl.getSelectionIndex();
				assert (-1 != i);
				_data = cast(AbstractArea) tbl.getItem(i).getData();
				e.data = bytesFromXML(_data.toXML(null, _summ.id));
			}
		}
		override void dragFinished(DragSourceEvent e) {
			if (e.detail == DND.DROP_MOVE) {
				auto area = _data;
				_summ.remove(area);
				delItem(area);
				if (cast(Area) area) {
					_comm.delArea.call(cast(Area) area);
				} else if (cast(Battle) area) {
					_comm.delBattle.call(cast(Battle) area);
				} else {
					assert (cast(Package) area);
					_comm.delPackage.call(cast(Package) area);
				}
				refreshStatusLine();
				_comm.refreshToolBar();
			}
		}
	}
	class DropArea : DropTargetAdapter {
		override void dragEnter(DropTargetEvent e){
			e.detail = DND.DROP_MOVE;
		}
		override void dragOver(DropTargetEvent e){
			e.detail = DND.DROP_MOVE;
		}
		override void drop(DropTargetEvent e){
			if (!isXMLBytes(e.data)) return;
			e.detail = DND.DROP_NONE;
			string xml = bytesToXML(e.data);
			try {
				scope node = XNode.parse(xml);
				TypeInfo tid;
				if (node.name == Area.XML_NAME) {
					tid = typeid(Area);
				} else if (node.name == Battle.XML_NAME) {
					tid = typeid(Battle);
				} else if (node.name == Package.XML_NAME) {
					tid = typeid(Package);
				} else {
					return;
				}

				auto tbl = cast(Table) (cast(DropTarget) e.getSource()).getControl();
				auto toItm = tbl.getItem(tbl.toControl(e.x, e.y));
				int count = tbl.getItemCount();
				int index = toItm ? tbl.indexOf(toItm) : count;
				int revId(int index) {
					if (tid == typeid(Area)) {
						if (_summ.areas.length < index) {
							index = _summ.areas.length;
						}
					} else if (tid == typeid(Battle)) {
						index -= _summ.areas.length;
						if (index < 0) {
							index = 0;
						} else if (_summ.battles.length < index) {
							index = _summ.battles.length;
						}
					} else {
						assert (tid == typeid(Package));
						index -= _summ.areas.length + _summ.battles.length;
						if (index < 0) {
							index = 0;
						} else if (_summ.packages.length < index) {
							index = _summ.packages.length;
						}
					}
					return index;
				}
				if (_summ.id == AbstractArea.summaryId(node)) {
					// 同一リスト内で移動。
					if ((index < count ? index : count - 1) == tbl.getSelectionIndex()
							|| index == tbl.getSelectionIndex() + 1) {
						tbl.showSelection();
						return;
					}
					index = revId(index);
					int fromIndex = tbl.getSelectionIndex();
					if (-1 == fromIndex) return;
					auto area = cast(AbstractArea) tbl.getItem(fromIndex).getData();
					tbl.getItem(fromIndex).dispose();
					int toIndex;
					if (tid == typeid(Area)) {
						_summ.insert(index, cast(Area) area);
						index = _summ.indexOf(cast(Area) area);
						toIndex = newAreaItem(index);
					} else if (tid == typeid(Battle)) {
						_summ.insert(index, cast(Battle) area);
						index = _summ.indexOf(cast(Battle) area);
						toIndex = newBattleItem(index);
					} else {
						assert (tid == typeid(Package));
						_summ.insert(index, cast(Package) area);
						index = _summ.indexOf(cast(Package) area);
						toIndex = newPackageItem(index);
					}
					storeMove(fromIndex, toIndex);
					callRefArea(area);
					refreshIDs(true);
					refreshStatusLine();
					_comm.refreshToolBar();
					e.detail = DND.DROP_NONE;
				} else {
					// 他のリストからのコピー
					index = revId(index);
					AbstractArea area;
					int tblIndex;
					if (tid == typeid(Area)) {
						storeInsert(index);
						area = Area.createFromNode(node, LATEST_VERSION);
						_summ.insert(index, cast(Area) area);
						index = _summ.indexOf(cast(Area) area);
						newAreaItem(index);
					} else if (tid == typeid(Battle)) {
						storeInsert(_summ.areas.length + index);
						area = Battle.createFromNode(node, LATEST_VERSION);
						_summ.insert(index, cast(Battle) area);
						index = _summ.indexOf(cast(Battle) area);
						newBattleItem(index);
					} else {
						assert (tid == typeid(Package));
						storeInsert(_summ.areas.length + _summ.battles.length + index);
						area = Package.createFromNode(node, LATEST_VERSION);
						_summ.insert(index, cast(Package) area);
						index = _summ.indexOf(cast(Package) area);
						newPackageItem(index);
					}
					e.detail = DND.DROP_NONE;
					refreshIDs(true);
					_comm.refUseCount.call();
					refreshStatusLine();
					_comm.refreshToolBar();
				}
			} catch (Exception e) {
				debugln(e);
			}
		}
	}
	void __refreshUseCount() {
		foreach (itm; _areas.getItems()) {
			auto element = itm.getData();
			if (cast(Area) element) {
				itm.setText(2, to!(string)(_summ.useCounter.area.get(toAreaId((cast(AbstractArea) element).id))));
			} else if (cast(Battle) element) {
				itm.setText(2, to!(string)(_summ.useCounter.battle.get(toBattleId((cast(AbstractArea) element).id))));
			} else {
				assert (cast(Package) element);
				itm.setText(2, to!(string)(_summ.useCounter.packages.get(toPackageId((cast(AbstractArea) element).id))));
			}
		}
	}
	class MListener : MouseAdapter {
		public override void mouseDown(MouseEvent e) {
			if (e.button == 2) {
				openAreaEvent(e.x, e.y, true);
			}
		}
		public override void mouseDoubleClick(MouseEvent e) {
			if (_areas.isFocusControl() && e.button == 1) {
				if (e.stateMask & SWT.SHIFT) {
					openAreaEvent(true);
				} else {
					openAreaScene(true);
				}
			}
		}
	}
	class KListener : KeyAdapter {
		public override void keyPressed(KeyEvent e) {
			if (_areas.isFocusControl() && e.character == SWT.CR) {
				if (e.stateMask & SWT.SHIFT) {
					openAreaEvent(true);
				} else {
					openAreaScene(true);
				}
			}
		}
	}
	class ADListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			_comm.refArea.remove(&refArea);
			_comm.refBattle.remove(&refBattle);
			_comm.refPackage.remove(&refPackage);
			_comm.refUseCount.remove(&__refreshUseCount);
			_comm.replText.remove(&refresh);
			_comm.refScenario.remove(&refScenario);
			_comm.refUndoMax.remove(&refUndoMax);
		}
	}
	private void refreshAreas() {
		if (!_areas || _areas.isDisposed()) return;
		_areas.removeAll();
		if (_summ) {
			foreach (i, a; _summ.areas) {
				newAreaItem(i);
			}
			foreach (i, a; _summ.battles) {
				newBattleItem(i);
			}
			foreach (i, a; _summ.packages) {
				newPackageItem(i);
			}
		}
		refreshStatusLine();
	}
	void item(AbstractArea a, Image img, int uc, int index = -1) {
		TableItem itm;
		if (index >= 0) {
			itm = new TableItem(_areas, SWT.NONE, index);
		} else {
			itm = new TableItem(_areas, SWT.NONE);
		}
		itm.setImage(0, img);
		itm.setText(ID, to!(string)(a.id));
		itm.setText(NAME, a.name);
		itm.setText(UC, to!(string)(uc));
		itm.setData(a);
	}
	void refData(A)(A a, TableItem itm) {
		itm.setText(ID, to!(string)(a.id));
		itm.setText(NAME, a.name);
		itm.setText(UC, to!(string)(_summ.useCounter.get(A.toID(a.id))));
		itm.setData(a);
	}
	private int newAreaItem(int index) {
		auto a = _summ.areas[index];
		item(a, _prop.images.area, _summ.useCounter.get(toAreaId(a.id)), index);
		return index;
	}
	private int newBattleItem(int index) {
		auto a = _summ.battles[index];
		index += _summ.areas.length;
		item(a, _prop.images.battle, _summ.useCounter.get(toBattleId(a.id)), index);
		return index;
	}
	private int newPackageItem(int index) {
		auto a = _summ.packages[index];
		index += _summ.areas.length + _summ.battles.length;
		item(a, _prop.images.packages, _summ.useCounter.get(toPackageId(a.id)), index);
		return index;
	}
	private class SListener : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			refreshStatusLine();
			_comm.refreshToolBar();
		}
	}
	void refScenario(Summary summ) {
		_undo.reset();
	}
	void refUndoMax() {
		_undo.max = _prop.var.etc.undoMaxMainView;
	}
public:
	this (Commons comm, Props prop) {
		_comm = comm;
		_prop = prop;
		_undo = new UndoManager(_prop.var.etc.undoMaxMainView);
	}

	void construct(Composite parent, FlagTable flags) {
		_flags = flags;
		_comm.refArea.add(&refArea);
		_comm.refBattle.add(&refBattle);
		_comm.refPackage.add(&refPackage);
		_comm.refUseCount.add(&__refreshUseCount);
		_comm.replText.add(&refresh);
		_comm.refScenario.add(&refScenario);
		_comm.refUndoMax.add(&refUndoMax);
		_areas = new Table(parent, SWT.BORDER | SWT.FULL_SELECTION);
		_areas.addDisposeListener(new ADListener);
		_areas.addSelectionListener(new SListener);
		_areas.setHeaderVisible(true);
		auto idCol = new TableColumn(_areas, SWT.NULL);
		idCol.setText(_prop.msgs.areaId);
		saveColumnWidth!("prop.var.etc.areaIdColumn")(_prop, idCol);
		auto nameCol = new TableColumn(_areas, SWT.NULL);
		nameCol.setText(_prop.msgs.areaName);
		saveColumnWidth!("prop.var.etc.areaNameColumn")(_prop, nameCol);
		auto countCol = new TableColumn(_areas, SWT.NULL);
		countCol.setText(_prop.msgs.areaCount);
		saveColumnWidth!("prop.var.etc.areaCountColumn")(_prop, countCol);

		_areasEdit = new TableTextEdit(_comm, _prop, _areas, 1, &editEnd);

		auto menu = new Menu(parent.getShell(), SWT.POP_UP);
		if (!_comm.singleWindowMode(_prop) || _prop.var.etc.bindSceneWithEvent) {
			createMenuItem(_comm, menu, MenuID.EditProp, {openAreaScene(true);}, () => _areas.getSelectionIndex() != -1);
		} else {
			createMenuItem(_comm, menu, MenuID.EditScene, {openAreaScene(true);}, &canOpenAreaScene);
			createMenuItem(_comm, menu, MenuID.EditEvent, {openAreaEvent(true);}, &canOpenAreaEvent);
		}
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.EditSummary, &editSummary, () => _summ !is null);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.Undo, &undo, &_undo.canUndo);
		createMenuItem(_comm, menu, MenuID.Redo, &redo, &_undo.canRedo);
		new MenuItem(menu, SWT.SEPARATOR);
		appendMenuTCPD(_comm, menu, this, true, true, true, true, true);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.ReNumbering, &reNumbering, () => _areas.getSelectionIndex() != -1);
		_areas.setMenu(menu);

		_areas.addMouseListener(new MListener);
		_areas.addKeyListener(new KListener);
		auto drag = new DragSource(_areas, DND.DROP_MOVE | DND.DROP_COPY);
		drag.setTransfer([XMLBytesTransfer.getInstance()]);
		drag.addDragListener(new DragArea);
		auto drop = new DropTarget(_areas, DND.DROP_DEFAULT | DND.DROP_MOVE);
		drop.setTransfer([XMLBytesTransfer.getInstance()]);
		drop.addDropListener(new DropArea);
	}

	private int toAreaIndex(int index) {
		return (index >= 0 && index < _summ.areas.length) ? index : -1;
	}
	private int toBattleIndex(int index) {
		return (index >= 0 && index < _summ.areas.length + _summ.battles.length)
			? index - _summ.areas.length : -1;
	}
	private int toPackageIndex(int index) {
		return (index >= 0 && index < _summ.areas.length
			+ _summ.battles.length + _summ.packages.length)
			? index - _summ.areas.length - _summ.battles.length : -1;
	}

	void reNumberingAll() {
		auto undo = new UndoIDs(this, _comm, _summ);
		bool reNum = false;
		reNum |= reNumberingAreaImpl(0, 1);
		reNum |= reNumberingBattleImpl(0, 1);
		reNum |= reNumberingPackageImpl(0, 1);
		if (reNum) _undo ~= undo;
	}
	void reNumberingArea(int index, ulong newId) {
		auto undo = new UndoIDs(this, _comm, _summ);
		bool reNum = reNumberingAreaImpl(index, newId);
		if (reNum) _undo ~= undo;
	}
	void reNumberingBattle(int index, ulong newId) {
		auto undo = new UndoIDs(this, _comm, _summ);
		bool reNum = reNumberingBattleImpl(index, newId);
		if (reNum) _undo ~= undo;
	}
	void reNumberingPackage(int index, ulong newId) {
		auto undo = new UndoIDs(this, _comm, _summ);
		bool reNum = reNumberingPackageImpl(index, newId);
		if (reNum) _undo ~= undo;
	}
	private ulong[] reNumBef(A)(A[] arr, int index) {
		ulong[] oldIDs;
		for (size_t i = index; i < arr.length; i++) {
			oldIDs ~= arr[i].id;
			ulong ni = ulong.max - arr.length + i;
			_summ.useCounter.change(A.toID(arr[i].id), A.toID(ni));
			arr[i].id = ni;
		}
		return oldIDs;
	}
	private bool reNumberingImpl(A)(int index, ulong newId, A[] arr) {
		if (index < 0 || arr.length <= index) return false;
		if (newId == 0) return false;
		if (index > 0 && arr[index - 1].id >= newId) return false;
		auto oldIDs = reNumBef(arr, index);
		bool reNum = false;
		for (size_t i = index; i < arr.length; i++) {
			_summ.useCounter.change(A.toID(arr[i].id), A.toID(newId));
			arr[i].id = newId;
			if (oldIDs[i - index] != newId) {
				callRefArea(arr[i]);
				reNum = true;
			}
			newId++;
		}
		refreshIDs(false);
		return reNum;
	}
	private bool reNumberingAreaImpl(int index, ulong newId) {
		return reNumberingImpl(index, newId, _summ.areas);
	}
	private bool reNumberingBattleImpl(int index, ulong newId) {
		return reNumberingImpl(index, newId, _summ.battles);
	}
	private bool reNumberingPackageImpl(int index, ulong newId) {
		return reNumberingImpl(index, newId, _summ.packages);
	}
	void reNumbering() {
		if (!_summ) return;
		int index = _areas.getSelectionIndex();
		if (index < 0) return;
		int ai = toAreaIndex(index);
		if (ai >= 0) {
			auto dlg = new ReNumDialog!(Area)(_prop, _areas.getShell(), _summ.areas[ai],
				ai == 0 ? 1 : _summ.areas[ai - 1].id + 1);
			if (dlg.open()) {
				reNumberingArea(ai, dlg.newId);
			}
			_comm.refreshToolBar();
			return;
		}
		int bi = toBattleIndex(index);
		if (bi >= 0) {
			auto dlg = new ReNumDialog!(Battle)(_prop, _areas.getShell(), _summ.battles[bi],
				bi == 0 ? 1 : _summ.battles[bi - 1].id + 1);
			if (dlg.open()) {
				reNumberingBattle(bi, dlg.newId);
			}
			_comm.refreshToolBar();
			return;
		}
		int pi = toPackageIndex(index);
		if (pi >= 0) {
			auto dlg = new ReNumDialog!(Package)(_prop, _areas.getShell(), _summ.packages[pi],
				pi == 0 ? 1 : _summ.packages[pi - 1].id + 1);
			if (dlg.open()) {
				reNumberingPackage(pi, dlg.newId);
			}
			_comm.refreshToolBar();
			return;
		}
	}

	private void editSummary() {
		editSummary(_areas);
	}
	private SummaryDialog _summDlg = null;
	void editSummary(Composite parent) {
		if (!_summ) return;
		if (_summDlg) {
			_summDlg.active();
			return;
		}
		_summDlg = new SummaryDialog(_comm, _prop, parent.getShell(), _summ);
		_summDlg.appliedEvent ~= {
			refresh();
		};
		_summDlg.closeEvent ~= {
			_summDlg = null;
		};
		_summDlg.open();
	}

	@property
	Control table() {
		return _areas;
	}

	@property
	string statusLine() {return _statusLine;}

	void refresh() {
		refreshAreas();
	}

	@property
	void summary(Summary summ) {
		_summ = summ;
		refreshAreas();
		_comm.refreshToolBar();
	}

	/// 新規エリアが作成され、名前の入力待ちになる。
	void createArea() {
		storeInsert(_summ.areas.length);
		auto area = new Area(_summ.newAreaId, _prop.msgs.areaNew);
		auto bgImages = createBgImages(_comm.skin, _prop.var.etc.bgImagesDefault);
		foreach (b; bgImages) {
			area.append(b);
		}
		auto tree = new EventTree(_prop.msgs.enterTree);
		tree.enter = true;
		area.add(tree);
		_summ.add(area);
		int index = _summ.areas.length - 1;
		newAreaItem(index);
		selArea(index);
		_comm.refArea.call(area);
		_areasEdit.startEdit();
		refreshStatusLine();
		_comm.refreshToolBar();
	}

	/// 新規バトルが作成され、名前の入力待ちになる。
	void createBattle() {
		storeInsert(_summ.areas.length + _summ.battles.length);
		auto btl = new Battle(_summ.newBattleId, _prop.msgs.battleNew, _comm.skin.defBattle);
		_summ.add(btl);
		int index = _summ.battles.length - 1;
		newBattleItem(index);
		selBattle(index);
		_comm.refBattle.call(btl);
		_areasEdit.startEdit();
		refreshStatusLine();
		_comm.refreshToolBar();
	}

	/// 新規パッケージが作成され、名前の入力待ちになる。
	ulong createPackage(Content baseStart = null) {
		storeInsert(_summ.areas.length + _summ.battles.length + _summ.packages.length);
		auto pkg = new Package(_summ.newPackageId, baseStart ? baseStart.name : _prop.msgs.packageNew);
		EventTree et;
		if (baseStart) {
			et = new EventTree(baseStart);
		} else {
			et = new EventTree(_prop.msgs.packageTree);
		}
		pkg.add(et);
		_summ.add(pkg);
		int index = _summ.packages.length - 1;
		newPackageItem(index);
		selPackage(index);
		_comm.refPackage.call(pkg);
		_areasEdit.startEdit();
		refreshStatusLine();
		_comm.refreshToolBar();
		return pkg.id;
	}
	@property
	private void selArea(int index) {
		_areas.setSelection(index);
		_areas.showSelection();
		_comm.refreshToolBar();
	}
	@property
	private void selBattle(int index) {
		_areas.setSelection(_summ.areas.length + index);
		_areas.showSelection();
		_comm.refreshToolBar();
	}
	@property
	private void selPackage(int index) {
		_areas.setSelection(_summ.areas.length + _summ.battles.length + index);
		_areas.showSelection();
		_comm.refreshToolBar();
	}
	@property
	void select(AbstractArea a) {
		int i = cCountUntil!("a.getData() is b")(_areas.getItems(), a);
		if (0 <= i) {
			_areas.select(i);
			_areas.showSelection();
			_comm.refreshToolBar();
		}
	}

	@property
	bool canOpenAreaScene() {
		return _areas.getSelectionIndex() != -1;
	}
	@property
	bool canOpenAreaEvent() {
		return _areas.getSelectionIndex() != -1;
	}
	void openAreaScene(bool shellActivate) {
		auto area = getSelectionArea();
		if (area) {
			auto a = cast(Area) area;
			if (a) {
				openAreaSceneImpl(a, shellActivate);
				return;
			}
			auto b = cast(Battle) area;
			if (b) {
				openAreaSceneImpl(b, shellActivate);
				return;
			}
			auto p = cast(Package) area;
			if (p) {
				_comm.openArea(_prop, _summ, p, shellActivate);
				return;
			}
		}
	}
	void openAreaEvent(int x, int y, bool shellActivate) {
		auto itm = _areas.getItem(new Point(x, y));
		if (itm) {
			_areas.setSelection([itm]);
			openAreaEvent(cast(AbstractArea) itm.getData(), shellActivate);
		} else {
			openAreaEvent(shellActivate);
		}
	}
	void openAreaEvent(bool shellActivate) {
		auto area = getSelectionArea();
		if (area) {
			openAreaEvent(area, shellActivate);
		}
	}
	void openAreaEvent(AbstractArea area, bool shellActivate) {
		auto a = cast(Area) area;
		if (a) {
			openAreaEventImpl(a, shellActivate);
			return;
		}
		auto b = cast(Battle) area;
		if (b) {
			openAreaEventImpl(b, shellActivate);
			return;
		}
		auto p = cast(Package) area;
		if (p) {
			_comm.openArea(_prop, _summ, p, shellActivate);
			return;
		}
	}

	void openAreaSceneImpl(A)(A a, bool shellActivate) {
		if (!_comm.singleWindowMode(_prop) || _prop.var.etc.bindSceneWithEvent) {
			_comm.openArea(_prop, _summ, a, shellActivate);
		} else {
			_comm.openAreaScene(_prop, _summ, a, shellActivate);
		}
	}
	void openAreaEventImpl(A)(A a, bool shellActivate) {
		if (!_comm.singleWindowMode(_prop) || _prop.var.etc.bindSceneWithEvent) {
			auto w = _comm.openArea(_prop, _summ, a, shellActivate);
			w.selectEventView();
		} else {
			_comm.openAreaEvent(_prop, _summ, a, shellActivate);
		}
	}
	void openAreaScene(ulong id, bool shellActivate) {
		openAreaSceneImpl(_summ.area(id), shellActivate);
	}
	void openAreaEvent(ulong id, bool shellActivate) {
		openAreaEventImpl(_summ.area(id), shellActivate);
	}
	void openBattleScene(ulong id, bool shellActivate) {
		openAreaSceneImpl(_summ.battle(id), shellActivate);
	}
	void openBattleEvent(ulong id, bool shellActivate) {
		openAreaEventImpl(_summ.area(id), shellActivate);
	}
	void openPackage(ulong id, bool shellActivate) {
		_comm.openArea(_prop, _summ, _summ.cwPackage(id), shellActivate);
	}

	private bool canUdImpl(int index1, int index2) {
		if (index1 < 0 || _areas.getItemCount() <= index1) return false;
		if (index2 < 0 || _areas.getItemCount() <= index2) return false;
		auto area1 = areaFromIndex(_summ, index1);
		auto area2 = areaFromIndex(_summ, index2);
		if (cast(Area) area1 && cast(Area) area2) {
			return canUdImpl2!Area(index1, index2);
		}
		if (cast(Battle) area1 && cast(Battle) area2) {
			return canUdImpl2!Battle(index1, index2);
		}
		if (cast(Package) area1 && cast(Package) area2) {
			return canUdImpl2!Package(index1, index2);
		}
		return false;
	}
	private bool canUdImpl2(A)(int index1, int index2) {
		auto a1 = cast(A) areaFromIndex(_summ, index1);
		auto a2 = cast(A) areaFromIndex(_summ, index2);
		return a1 && a2;
	}
	private void udImpl(int index1, int index2) {
		if (index1 < 0 || _areas.getItemCount() <= index1) return;
		if (index2 < 0 || _areas.getItemCount() <= index2) return;
		auto area1 = areaFromIndex(_summ, index1);
		auto area2 = areaFromIndex(_summ, index2);
		if (cast(Area) area1 && cast(Area) area2) {
			udImpl2!Area(index1, index2);
		}
		if (cast(Battle) area1 && cast(Battle) area2) {
			udImpl2!Battle(index1, index2);
		}
		if (cast(Package) area1 && cast(Package) area2) {
			udImpl2!Package(index1, index2);
		}
		_comm.refreshToolBar();
	}
	private void udImpl2(A)(int index1, int index2) {
		auto a1 = cast(A) areaFromIndex(_summ, index1);
		auto a2 = cast(A) areaFromIndex(_summ, index2);
		if (!a1 || !a2) return;
		storeSwap(index1, index2);
		int i1 = toIndex!A(_summ, index1);
		int i2 = toIndex!A(_summ, index2);
		_summ.swap!A(i1, i2);
		refData(a2, _areas.getItem(index1));
		refData(a1, _areas.getItem(index2));
		_areas.select(index2);
		_areas.showSelection();
		static if (is(A : Area)) {
			_comm.refArea.call(a1);
			_comm.refArea.call(a2);
		} else static if (is(A : Battle)) {
			_comm.refBattle.call(a1);
			_comm.refBattle.call(a2);
		} else static if (is(A : Package)) {
			_comm.refPackage.call(a1);
			_comm.refPackage.call(a2);
		} else static assert (0);
	}
	@property
	bool canUp() {
		if (!_areas.isFocusControl()) return false;
		int sel = _areas.getSelectionIndex();
		if (-1 == sel) return false;
		return canUdImpl(sel, sel - 1);
	}
	@property
	bool canDown() {
		if (!_areas.isFocusControl()) return false;
		int sel = _areas.getSelectionIndex();
		if (-1 == sel) return false;
		return canUdImpl(sel, sel + 1);
	}
	void up() {
		if (!_areas.isFocusControl()) return;
		_areasEdit.cancel();
		int sel = _areas.getSelectionIndex();
		if (-1 == sel) return;
		udImpl(sel, sel - 1);
	}
	void down() {
		if (!_areas.isFocusControl()) return;
		_areasEdit.cancel();
		int sel = _areas.getSelectionIndex();
		if (-1 == sel) return;
		udImpl(sel, sel + 1);
	}

	override {
		void cut(SelectionEvent se) {
			copy(se);
			del(se);
		}
		void copy(SelectionEvent se) {
			auto area = getSelectionArea();
			if (area !is null) {
				XMLtoCB(_prop, _comm.clipboard, area.toXML(null, _summ.id));
				_comm.refreshToolBar();
			}
		}
		void paste(SelectionEvent se) {
			auto c = CBtoXML(_comm.clipboard);
			if (c) {
				try {
					bool sameSummary;
					auto area = createAreaFromXML(c, _summ.id, sameSummary, LATEST_VERSION);
					if (area !is null) {
						auto oldId = area.id;
						if (cast(Area) area) {
							storeInsert(_summ.areas.length);
							auto newId = _summ.add(cast(Area) area);
							int index = _summ.areas.length - 1;
							newAreaItem(index);
							selArea(index);
							_comm.refArea.call(cast(Area) area);
							if (sameSummary && !_summ.hasAreaId(oldId)) {
								_summ.useCounter.change(toAreaId(oldId), toAreaId(newId));
							}
						} else if (cast(Battle) area) {
							storeInsert(_summ.areas.length + _summ.battles.length);
							auto newId = _summ.add(cast(Battle) area);
							int index = _summ.battles.length - 1;
							newBattleItem(index);
							selBattle(index);
							_comm.refBattle.call(cast(Battle) area);
							if (sameSummary && !_summ.hasBattleId(oldId)) {
								_summ.useCounter.change(toBattleId(oldId), toBattleId(newId));
							}
						} else if (cast(Package) area) {
							storeInsert(_summ.areas.length + _summ.battles.length + _summ.packages.length);
							auto newId = _summ.add(cast(Package) area);
							int index = _summ.packages.length - 1;
							newPackageItem(index);
							selPackage(index);
							_comm.refPackage.call(cast(Package) area);
							if (sameSummary && !_summ.hasPackageId(oldId)) {
								_summ.useCounter.change(toPackageId(oldId), toPackageId(newId));
							}
						} else assert (0);
						if (_flags) _flags.refresh();
						_comm.refUseCount.call();
						refreshStatusLine();
						_comm.refreshToolBar();
					}
				} catch (Exception e) {
					debugln(e);
				}
			}
		}
		void del(SelectionEvent se) {
			auto area = getSelectionArea();
			if (area) {
				storeDelete(_areas.getSelectionIndex());
				_summ.remove(area);
				delItem(area);
				if (cast(Area) area) {
					_comm.delArea.call(cast(Area) area);
				} else if (cast(Battle) area) {
					_comm.delBattle.call(cast(Battle) area);
				} else {
					assert (cast(Package) area);
					_comm.delPackage.call(cast(Package) area);
				}
				if (_flags) _flags.refresh();
				_comm.refUseCount.call();
				refreshStatusLine();
				_comm.refreshToolBar();
			}
		}
		void clone(SelectionEvent se) {
			_comm.clipboard.memoryMode = true;
			scope (exit) _comm.clipboard.memoryMode = false;
			copy(se);
			paste(se);
		}
		@property
		bool canDoTCPD() {
			return _summ && _areas.isFocusControl();
		}
		@property
		bool canDoT() {
			return _areas.getSelectionIndex() != -1;
		}
		@property
		bool canDoC() {
			return _areas.getSelectionIndex() != -1;
		}
		@property
		bool canDoP() {
			return _summ !is null && CBisXML(_comm.clipboard);
		}
		@property
		bool canDoClone() {
			return canDoC;
		}
		@property
		bool canDoD() {
			return _areas.getSelectionIndex() != -1;
		}
	}
	private void delItem(AbstractArea area) {
		foreach (itm; _areas.getItems()) {
			if (itm.getData() is area) {
				itm.dispose();
				break;
			}
		}
	}
	@property
	bool canUndo() {
		return _undo.canUndo();
	}
	@property
	bool canRedo() {
		return _undo.canRedo();
	}
	void undo() {
		_undo.undo();
		_comm.refreshToolBar();
	}
	void redo() {
		_undo.redo();
		_comm.refreshToolBar();
	}

	@property
	string[] openedCWXPath() {
		string[] r;
		auto a = getSelectionArea();
		if (a) {
			r ~= cpaddattr(a.cwxPath(true), "shallow");
		}
		return r;
	}
}
