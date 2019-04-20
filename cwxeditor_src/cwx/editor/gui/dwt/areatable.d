
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
import cwx.card;
import cwx.system;
import cwx.warning;

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
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.incsearch;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.centerlayout;

import std.algorithm : max, min;
import std.algorithm.mutation : swap;
import std.range : iota;
import std.array : split, array, replace;
import std.conv;
import std.string : icmp, join, toLower;

import org.eclipse.swt.all;

import java.lang.all;

/// エリア・バトル・パッケージの一覧を表示する。
class AreaTable : TCPD {
private:
	int compType(const Object o1, const Object o2) { mixin(S_TRACE);
		if (cast(const Summary)o1) return -1;
		if (cast(const Summary)o2) return 1;
		if (cast(const Area)o1) { mixin(S_TRACE);
			if (cast(const Battle)o2) return -1;
			if (cast(const Package)o2) return -1;
		}
		if (cast(const Battle)o1) { mixin(S_TRACE);
			if (cast(const Area)o2) return 1;
			if (cast(const Package)o2) return -1;
		}
		if (cast(const Package)o1) { mixin(S_TRACE);
			if (cast(const Area)o2) return 1;
			if (cast(const Battle)o2) return 1;
		}
		return 0;
	}
	bool compID(const Object o1, const Object o2) { mixin(S_TRACE);
		auto c = compType(o1, o2);
		if (c == 0) { mixin(S_TRACE);
			auto a1 = cast(const AbstractArea)o1;
			auto a2 = cast(const AbstractArea)o2;
			if (a1.id < a2.id) return true;
			if (a1.id > a2.id) return false;
			return false;
		}
		return c < 0;
	}
	bool compName(const Object o1, const Object o2) { mixin(S_TRACE);
		auto c = compType(o1, o2);
		if (c == 0) { mixin(S_TRACE);
			auto a1 = cast(const AbstractArea)o1;
			auto a2 = cast(const AbstractArea)o2;

			if (_prop.var.etc.logicalSort) { mixin(S_TRACE);
				c = incmp(a1.name, a2.name);
			} else { mixin(S_TRACE);
				c = icmp(a1.name, a2.name);
			}
			if (c == 0) return compID(o1, o2);
		}
		return c < 0;
	}
	bool compUC(const Object o1, const Object o2) { mixin(S_TRACE);
		auto c = compType(o1, o2);
		if (c == 0) { mixin(S_TRACE);
			int uc1 = 0;
			int uc2 = 0;
			auto a1 = cast(const Area)o1;
			auto a2 = cast(const Area)o2;
			if (a1 && a2) { mixin(S_TRACE);
				uc1 = _summ.useCounter.get(toAreaId(a1.id));
				uc2 = _summ.useCounter.get(toAreaId(a2.id));
			}
			auto b1 = cast(const Battle)o1;
			auto b2 = cast(const Battle)o2;
			if (b1 && b2) { mixin(S_TRACE);
				uc1 = _summ.useCounter.get(toBattleId(b1.id));
				uc2 = _summ.useCounter.get(toBattleId(b2.id));
			}
			auto p1 = cast(const Package)o1;
			auto p2 = cast(const Package)o2;
			if (p1 && p2) { mixin(S_TRACE);
				uc1 = _summ.useCounter.get(toPackageId(p1.id));
				uc2 = _summ.useCounter.get(toPackageId(p2.id));
			}

			if (uc1 < uc2) return true;
			if (uc1 > uc2) return false;
			return compID(o1, o2);
		}
		return c < 0;
	}
	bool revCompID(const Object o1, const Object o2) { mixin(S_TRACE);
		auto c = compType(o2, o1);
		if (c == 0) { mixin(S_TRACE);
			auto a1 = cast(const AbstractArea)o2;
			auto a2 = cast(const AbstractArea)o1;
			if (a1.id < a2.id) return true;
			if (a1.id > a2.id) return false;
			return false;
		}
		return 0 < c;
	}
	bool revCompName(const Object o1, const Object o2) { mixin(S_TRACE);
		auto c = compType(o2, o1);
		if (c == 0) { mixin(S_TRACE);
			auto a1 = cast(const AbstractArea)o2;
			auto a2 = cast(const AbstractArea)o1;

			if (_prop.var.etc.logicalSort) { mixin(S_TRACE);
				c = incmp(a2.name, a1.name);
			} else { mixin(S_TRACE);
				c = icmp(a2.name, a1.name);
			}
			if (c == 0) return revCompID(o1, o2);
		}
		return 0 < c;
	}
	bool revCompUC(const Object o1, const Object o2) { mixin(S_TRACE);
		auto c = compType(o2, o1);
		if (c == 0) { mixin(S_TRACE);
			int uc1 = 0;
			int uc2 = 0;
			auto a1 = cast(const Area)o2;
			auto a2 = cast(const Area)o1;
			if (a1 && a2) { mixin(S_TRACE);
				uc1 = _summ.useCounter.get(toAreaId(a1.id));
				uc2 = _summ.useCounter.get(toAreaId(a2.id));
			}
			auto b1 = cast(const Battle)o2;
			auto b2 = cast(const Battle)o1;
			if (b1 && b2) { mixin(S_TRACE);
				uc1 = _summ.useCounter.get(toBattleId(b1.id));
				uc2 = _summ.useCounter.get(toBattleId(b2.id));
			}
			auto p1 = cast(const Package)o2;
			auto p2 = cast(const Package)o1;
			if (p1 && p2) { mixin(S_TRACE);
				uc1 = _summ.useCounter.get(toPackageId(p1.id));
				uc2 = _summ.useCounter.get(toPackageId(p2.id));
			}

			if (uc1 < uc2) return true;
			if (uc1 > uc2) return false;
			return revCompID(o1, o2);
		}
		return 0 < c;
	}

	private static void saveIDs(Summary summ, out ulong[] areaIDs, out ulong[] battleIDs, out ulong[] packageIDs) { mixin(S_TRACE);
		areaIDs.length = 0;
		foreach (a; summ.areas) areaIDs ~= a.id;
		battleIDs.length = 0;
		foreach (a; summ.battles) battleIDs ~= a.id;
		packageIDs.length = 0;
		foreach (a; summ.packages) packageIDs ~= a.id;
	}

	static class ATUndo : Undo {
		protected AreaTable _v = null;
		protected Commons comm;
		protected Summary summ;
		protected bool one = true;
		protected AbstractArea[] calls, delCalls;

		private ulong[] _areaIDs;
		private ulong[] _areaIDsB;
		private ulong[] _battleIDs;
		private ulong[] _battleIDsB;
		private ulong[] _packageIDs;
		private ulong[] _packageIDsB;
		private ulong _sel;
		private TypeInfo _selType;
		private ulong _selB;
		private TypeInfo _selTypeB;
		private DirTree _dirs, _dirsB;
		private bool[ulong] _selectionsA, _selectionsAB;
		private bool[ulong] _selectionsB, _selectionsBB;
		private bool[ulong] _selectionsP, _selectionsPB;

		this (AreaTable v, Commons comm, Summary summ) { mixin(S_TRACE);
			_v = v;
			this.comm = comm;
			this.summ = summ;

			saveIDs(v);
		}
		private void saveIDs(AreaTable v) { mixin(S_TRACE);
			AreaTable.saveIDs(summ, _areaIDs, _battleIDs, _packageIDs);
			if (v && v._areas && !v._areas.isDisposed()) { mixin(S_TRACE);
				v.getSelectionInfo(_sel, _selType);
			}
			if (v) {
				if (!v._dirs) v.constructDirTree(false);
				_dirs = v._dirs.dup;
				_selectionsA = null;
				_selectionsB = null;
				_selectionsP = null;
				foreach (id, sel; v._selectionsA) _selectionsA[id] = sel;
				foreach (id, sel; v._selectionsB) _selectionsB[id] = sel;
				foreach (id, sel; v._selectionsP) _selectionsP[id] = sel;
			}
		}
		abstract override void undo();
		abstract override void redo();
		abstract override void dispose();
		protected void udb(AreaTable v) { mixin(S_TRACE);
			_areaIDsB = _areaIDs.dup;
			_battleIDsB = _battleIDs.dup;
			_packageIDsB = _packageIDs.dup;
			_selB = _sel;
			_selTypeB = _selType;
			_dirsB = _dirs;
			_selectionsAB = null;
			_selectionsBB = null;
			_selectionsPB = null;
			foreach (id, sel; _selectionsA) _selectionsAB[id] = sel;
			foreach (id, sel; _selectionsB) _selectionsBB[id] = sel;
			foreach (id, sel; _selectionsP) _selectionsPB[id] = sel;
			saveIDs(v);
			if (!one) return;
			if (v && v._areas && !v._areas.isDisposed()) { mixin(S_TRACE);
				.forceFocus(v._areas, false);
			}
			if (v._parent) v._parent.setRedraw(false);
		}
		private void resetID(alias ToID, A)(AreaTable v, A[] arr, ulong[] ids) { mixin(S_TRACE);
			ulong[] oldIDs;
			foreach (i, a; arr) { mixin(S_TRACE);
				auto oID = a.id;
				a.id = ulong.max - arr.length + i;
				summ.useCounter.change(ToID(oID), ToID(a.id));
				oldIDs ~= oID;
			}
			foreach (i, a; arr) { mixin(S_TRACE);
				auto oID = a.id;
				a.id = ids[i];
				summ.useCounter.change(ToID(oID), ToID(a.id));
			}
			foreach (i, a; arr) { mixin(S_TRACE);
				if (a.id != oldIDs[i] || calls.contains(a)) { mixin(S_TRACE);
					staticCallRefArea(v, comm, a);
				}
			}
		}
		protected ulong uid(ulong id, TypeInfo type) { mixin(S_TRACE);
			return id;
		}
		protected void uda(AreaTable v, bool refreshDirTree = true) { mixin(S_TRACE);
			resetID!toAreaId(v, summ.areas, _areaIDsB);
			resetID!toBattleId(v, summ.battles, _battleIDsB);
			resetID!toPackageId(v, summ.packages, _packageIDsB);
			foreach (area; delCalls) {
				auto a = cast(Area)area;
				if (a) { mixin(S_TRACE);
					comm.delArea.call(v, a);
				}
				auto b = cast(Battle)area;
				if (b) { mixin(S_TRACE);
					comm.delBattle.call(v, b);
				}
				auto p = cast(Package)area;
				if (p) { mixin(S_TRACE);
					comm.delPackage.call(v, p);
				}
			}
			calls = [];
			delCalls = [];
			if (!one) return;
			if (v && refreshDirTree) { mixin(S_TRACE);
				v._dirs = _dirsB.dup;
				v.refreshDirTree();
			}
			if (v && v._areas && !v._areas.isDisposed()) { mixin(S_TRACE);
				v._selectionsA = null;
				v._selectionsB = null;
				v._selectionsP = null;
				foreach (id, sel; _selectionsAB) v._selectionsA[id] = sel;
				foreach (id, sel; _selectionsBB) v._selectionsB[id] = sel;
				foreach (id, sel; _selectionsPB) v._selectionsP[id] = sel;
				_selectionsAB = null;
				_selectionsBB = null;
				_selectionsPB = null;
				v.refreshAreas();
				v.selectFromInfo(_selB, _selTypeB);
				v.refreshStatusLine();
			}
			comm.refUseCount.call();
			comm.refreshToolBar();
			if (v._parent) v._parent.setRedraw(true);
		}
		protected AreaTable view() { mixin(S_TRACE);
			return _v;
		}
	}
	static class ATUndoArr : Undo {
		private ATUndo[] _array;
		this (ATUndo[] array) { mixin(S_TRACE);
			_array = array;
		}
		void undo() { mixin(S_TRACE);
			foreach_reverse (i, u; _array) { mixin(S_TRACE);
				u.one = (i == 0);
				u.undo();
			}
		}
		void redo() { mixin(S_TRACE);
			foreach (i, u; _array) { mixin(S_TRACE);
				u.one = (i + 1 == _array.length);
				u.redo();
			}
		}
		void dispose() { mixin(S_TRACE);
			foreach (u; _array) u.dispose();
		}
	}

	void storeEmpty() { mixin(S_TRACE);
		_undo ~= new UndoIDs(this, _comm, _summ);
	}

	static class UndoIDs : ATUndo {
		this (AreaTable v, Commons comm, Summary summ) { mixin(S_TRACE);
			super (v, comm, summ);
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
		override void dispose() { }
	}
	static class UndoEdit : ATUndo {
		private string _name;
		private ulong _id;
		private TypeInfo _type;

		static struct SummData {
			string scenarioName;
			CardImage[] imagePaths;
			string author;
			int levelMin, levelMax;
			string desc;
			string type;
			string skinName;
			string[] rCoupons;
			uint rCouponNum;
			ulong startArea;
			Skin skin;
			this (Commons comm, Summary summ) { mixin(S_TRACE);
				scenarioName = summ.scenarioName;
				imagePaths = summ.imagePaths;
				author = summ.author;
				levelMin = summ.levelMin;
				levelMax = summ.levelMax;
				desc = summ.desc;
				type = summ.type;
				skinName = summ.skinName;
				rCoupons = summ.rCoupons.dup;
				rCouponNum = summ.rCouponNum;
				startArea = summ.startArea;
				skin = comm.skin;
			}
			void toSummary(Commons comm, Summary summ) { mixin(S_TRACE);
				summ.scenarioName = scenarioName;
				summ.imagePaths = imagePaths;
				summ.author = author;
				summ.levelMin = levelMin;
				summ.levelMax = levelMax;
				summ.desc = desc;
				summ.type = type;
				summ.skinName = skinName;
				summ.rCoupons = rCoupons;
				summ.rCouponNum = rCouponNum;
				summ.startArea = startArea;
				comm.skin = skin;
			}
		}
		private SummData _summData;

		this (AreaTable v, Commons comm, Summary summ, ulong id, TypeInfo type) { mixin(S_TRACE);
			super (v, comm, summ);
			if (0 == id) { mixin(S_TRACE);
				_summData = SummData(comm, summ);
			} else { mixin(S_TRACE);
				_name = areaFromInfo(summ, id, type).name;
			}
			_id = id;
			_type = type;
		}
		private void impl() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			if (0 == _id) { mixin(S_TRACE);
				auto oldData = SummData(comm, summ);
				bool refSkin = oldData.skin !is _summData.skin;
				_summData.toSummary(comm, summ);
				_summData = oldData;
				if (v && v._areas && !v._areas.isDisposed()) { mixin(S_TRACE);
					auto itm = v.getItemFrom(uid(_id, _type), _type);
					if (itm) itm.setText(NAME, summ.scenarioName);
				}
				comm.refScenarioName.call(v);
				if (refSkin) comm.refSkin.call();
			} else { mixin(S_TRACE);
				auto area = areaFromInfo(summ, uid(_id, _type), _type);
				string oldName = area.name;
				area.name = _name;
				_name = oldName;
				if (v && v._areas && !v._areas.isDisposed()) { mixin(S_TRACE);
					auto itm = v.getItemFrom(uid(_id, _type), _type);
					if (itm) itm.setText(NAME, area.name);
				}
				calls ~= area;
			}
			comm.refUseCount.call();
		}
		override void undo() { mixin(S_TRACE);
			impl();
		}
		override void redo() { mixin(S_TRACE);
			impl();
		}
		override void dispose() { }
	}
	void storeEdit(int index) { mixin(S_TRACE);
		ulong id;
		TypeInfo type;
		getInfo(index, id, type);
		storeEdit(id, type);
	}
	void storeEdit(ulong id, TypeInfo type) { mixin(S_TRACE);
		_undo ~= new UndoEdit(this, _comm, _summ, id, type);
	}
	static class UndoMove : ATUndo {
		private int _removeIndex, _insertIndex;
		private TypeInfo _type;
		this (AreaTable v, Commons comm, Summary summ, int removeIndex, int insertIndex, TypeInfo type) { mixin(S_TRACE);
			super (v, comm, summ);
			_removeIndex = removeIndex;
			_insertIndex = insertIndex;
			if (_removeIndex < _insertIndex) _insertIndex--;
			_type = type;
		}
		private void impl() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);

			int removeIndex = _removeIndex;
			int insertIndex = _insertIndex;
			if (insertIndex < removeIndex) removeIndex++;
			if (_type is typeid(Area)) { mixin(S_TRACE);
				auto a = summ.areas[insertIndex];
				summ.insert(removeIndex, a);
			} else if (_type is typeid(Battle)) { mixin(S_TRACE);
				auto a = summ.battles[insertIndex];
				summ.insert(removeIndex, a);
			} else if (_type is typeid(Package)) { mixin(S_TRACE);
				auto a = summ.packages[insertIndex];
				summ.insert(removeIndex, a);
			}

			.swap(_removeIndex, _insertIndex);
		}
		override void undo() { mixin(S_TRACE);
			impl();
		}
		override void redo() { mixin(S_TRACE);
			impl();
		}
		override void dispose() { }
	}
	void storeMove(int removeIndex, int insertIndex, TypeInfo type) { mixin(S_TRACE);
		assert (_areas.getSortColumn() is null || _areas.getSortColumn() is _idSorter.column);
		_undo ~= new UndoMove(this, _comm, _summ, removeIndex, insertIndex, type);
	}
	static class UndoSwap : ATUndo {
		private int _index1, _index2;
		this (AreaTable v, Commons comm, Summary summ, int index1, int index2) { mixin(S_TRACE);
			super (v, comm, summ);
			_index1 = index1;
			_index2 = index2;
		}
		private void impl() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			auto area1 = areaFromIndex(summ, _index1);
			auto area2 = areaFromIndex(summ, _index2);
			auto a = cast(Area)area1;
			if (a) { mixin(S_TRACE);
				summ.swap!Area(toAreaIndex(summ, _index1), toAreaIndex(summ, _index2));
			}
			auto b = cast(Battle)area1;
			if (b) { mixin(S_TRACE);
				summ.swap!Battle(toBattleIndex(summ, _index1), toBattleIndex(summ, _index2));
			}
			auto p = cast(Package)area1;
			if (p) { mixin(S_TRACE);
				summ.swap!Package(toPackageIndex(summ, _index1), toPackageIndex(summ, _index2));
			}
			calls ~= area1;
			calls ~= area2;
			.swap(_index1, _index2);
		}
		override void undo() { mixin(S_TRACE);
			impl();
		}
		override void redo() { mixin(S_TRACE);
			impl();
		}
		override void dispose() { }
	}
	void storeSwap(int index1, int index2) { mixin(S_TRACE);
		assert (_areas.getSortColumn() is null || _areas.getSortColumn() is _idSorter.column);
		_undo ~= new UndoSwap(this, _comm, _summ, index1, index2);
	}
	static class UndoInsertDelete : ATUndo {
		private bool _insert;

		private ulong _id;
		private TypeInfo _type;

		private AbstractArea _area = null;
		private bool _isStartArea = false;
		private int _delIndex = -1;

		this (AreaTable v, Commons comm, Summary summ, ulong id, TypeInfo type, bool insert, ulong[] a, ulong[] b, ulong[] p) { mixin(S_TRACE);
			super (v, comm, summ);
			_insert = insert;
			_id = id;
			_type = type;
			if (insert) { mixin(S_TRACE);
				_areaIDs = a;
				_battleIDs = b;
				_packageIDs = p;
			} else { mixin(S_TRACE);
				initUndoDelete();
			}
		}
		private void initUndoDelete() { mixin(S_TRACE);
			auto area = areaFromInfo(summ, uid(_id, _type), _type);
			_delIndex = toIndexFrom(summ, uid(_id, _type), _type);
			_isStartArea = cast(Area)area && summ.startArea == area.id;
			_area = area.dup;
			_area.setUseCounter(summ.useCounter.sub);
		}
		private void undoInsert() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			_insert = false;
			initUndoDelete();
			if (v && v._areas && !v._areas.isDisposed()) { mixin(S_TRACE);
				auto itm = v.getItemFrom(uid(_id, _type), _type);
				if (itm) itm.dispose();
			}
			auto area = areaFromInfo(summ, uid(_id, _type), _type);
			delCalls ~= area;
			summ.remove(area);
			if (one) comm.refUseCount.call();
		}
		void undoDelete() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			scope (exit) _area = null;
			_insert = true;
			_area.removeUseCounter();
			auto a = cast(Area)_area;
			calls ~= _area;
			if (a) { mixin(S_TRACE);
				summ.insert(_delIndex, a);
				if (one && v && v._areas && !v._areas.isDisposed()) v.refreshAreas();
				if (_isStartArea) { mixin(S_TRACE);
					summ.startArea = a.id;
					_isStartArea = false;
				}
				return;
			}
			auto b = cast(Battle)_area;
			if (b) { mixin(S_TRACE);
				summ.insert(_delIndex, b);
				if (one && v && v._areas && !v._areas.isDisposed()) v.refreshAreas();
				return;
			}
			auto p = cast(Package)_area;
			if (p) { mixin(S_TRACE);
				summ.insert(_delIndex, p);
				if (one && v && v._areas && !v._areas.isDisposed()) v.refreshAreas();
				return;
			}
			assert (0);
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
			if (_area) { mixin(S_TRACE);
				_area.removeUseCounter();
			}
		}
	}
	void storeInsert(ulong id, TypeInfo type, ulong[] a, ulong[] b, ulong[] p) { mixin(S_TRACE);
		_undo ~= new UndoInsertDelete(this, _comm, _summ, id, type, true, a, b, p);
	}
	void storeDelete(int index) { mixin(S_TRACE);
		ulong id;
		TypeInfo type;
		getInfo(index, id, type);
		_undo ~= new UndoInsertDelete(this, _comm, _summ, id, type, false, [], [], []);
	}
	static class UndoRenameDir : ATUndo {
		private string _oldPath, _newPath;
		this (AreaTable v, Commons comm, Summary summ, string oldPath, string newPath) { mixin(S_TRACE);
			super (v, comm, summ);
			_oldPath = oldPath;
			_newPath = newPath;
		}
		private void impl() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v, false);
			auto newPath2 = _newPath ~ '\\';
			void put(AbstractArea area) { mixin(S_TRACE);
				if (area.dirName.istartsWith(newPath2)) {
					area.dirName = _oldPath ~ '\\' ~ area.dirName[newPath2.length .. $];
					calls ~= area;
				} else if (0 == icmp(area.dirName, _newPath)) { mixin(S_TRACE);
					area.dirName = _oldPath;
					calls ~= area;
				}
			}
			foreach (a; summ.areas) put(a);
			foreach (a; summ.battles) put(a);
			foreach (a; summ.packages) put(a);
			.swap(_oldPath, _newPath);

			if (v && v._areas && !v._areas.isDisposed()) {
				auto itm = v.findDirTree(_oldPath);
				auto dir = cast(DirTree)itm.getData();
				dir.name = .split(_newPath, "\\")[$ - 1];
				itm.setText(dir.name);
				v._dir = dir.path;
				v.sortDirTree();
			}
		}
		override void undo() { mixin(S_TRACE);
			impl();
		}
		override void redo() { mixin(S_TRACE);
			impl();
		}
		override void dispose() { }
	}
	void storeRenameDir(string oldPath, string newPath) {
		_undo ~= new UndoRenameDir(this, _comm, _summ, oldPath, newPath);
	}

	Skin _summSkin;
	@property
	Skin summSkin() { mixin(S_TRACE);
		return _summSkin ? _summSkin : _comm.skin;
	}

	void dirEditEnd(TreeItem itm, Control ctrl) { mixin(S_TRACE);
		if (_readOnly) return;
		assert (_dirMode);
		auto t = cast(Text)ctrl;
		if (!t) return;
		auto newText = .replace(t.getText(), "\\", "");
		if (newText == "") return;
		if (itm.getText() == newText) return;
		if (auto summ = cast(Summary)itm.getData()) { mixin(S_TRACE);
			storeEdit(0UL, null);
			summ.scenarioName = newText;
			itm.setText(newText);
			_comm.refScenarioName.call();
		} else { mixin(S_TRACE);
			auto dir = cast(DirTree)itm.getData();
			auto oldPath = dir.path;
			dir.name = .createNewName(newText, (s) { mixin(S_TRACE);
				foreach (n; dir.parent.subDirs) { mixin(S_TRACE);
					if (n is dir) continue;
					if (0 == icmp(n.name, s)) { mixin(S_TRACE);
						return false;
					}
				}
				return true;
			});
			auto path = dir.path;
			itm.setText(dir.name);
			storeRenameDir(oldPath, path);
			auto oldPath2 = oldPath ~ '\\';
			void put(AbstractArea area) { mixin(S_TRACE);
				if (area.dirName.istartsWith(oldPath2)) { mixin(S_TRACE);
					area.dirName = path ~ '\\' ~ area.dirName[oldPath2.length .. $];
					callRefArea(area);
				} else if (0 == icmp(area.dirName, oldPath)) { mixin(S_TRACE);
					area.dirName = path;
					callRefArea(area);
				}
			}
			foreach (a; _summ.areas) put(a);
			foreach (a; _summ.battles) put(a);
			foreach (a; _summ.packages) put(a);
			sortDirTree();
			refreshDirTree();
			updateDirSel();
		}
		_comm.refreshToolBar();
	}

	void editEnd(TableItem itm, int column, string newText) { mixin(S_TRACE);
		if (_readOnly) return;
		assert (column == 1);
		if (!newText.length) return;
		if (auto summ = cast(Summary)itm.getData()) { mixin(S_TRACE);
			if (summ.scenarioName == newText) return;
			storeEdit(0UL, null);
			summ.scenarioName = newText;
			itm.setText(NAME, newText);
			_comm.refScenarioName.call();
		} else if (auto area = cast(AbstractArea)itm.getData()) { mixin(S_TRACE);
			assert (area !is null);
			if (_dirMode) { mixin(S_TRACE);
				newText = .replace(newText, "\\", "");
				if (newText == "") return;
				if (area.baseName == newText) return;
				storeEdit(_areas.indexOf(itm));
				area.baseName = newText;
			} else { mixin(S_TRACE);
				if (area.name == newText) return;
				storeEdit(_areas.indexOf(itm));
				area.name = newText;
			}
			refreshAreas();
			callRefArea(area);
		}
		_comm.refreshToolBar();
	}
	private static const ID = 0;
	private static const NAME = 1;
	private static const UC = 2;

	int _readOnly = SWT.NONE;

	bool _dirMode = false;
	string _dir = "";

	Commons _comm;
	Props _prop;
	Composite _parent = null;
	FlagTable _flags = null;
	Summary _summ, _importTarget = null;
	TableSorter!Object _idSorter;
	TableSorter!Object _nameSorter;
	TableSorter!Object _ucSorter;
	Control _lastFocus = null;

	Tree _dirTree = null;
	Table _areas;
	TableTextEdit _areasEdit;
	bool[ulong] _selectionsA;
	bool[ulong] _selectionsB;
	bool[ulong] _selectionsP;

	TreeEdit _areaDirEdit = null;
	DirTree _dirs = null;

	bool _hasAreas = false;

	IncSearch _incSearch = null;
	private void incSearch() { mixin(S_TRACE);
		.forceFocus(_areas, true);
		_incSearch.startIncSearch();
	}

	UndoManager _undo;

	string _statusLine = "";
	void refreshStatusLine() { mixin(S_TRACE);
		string s = "";
		void put(lazy string name, size_t count) { mixin(S_TRACE);
			if (!count) return;
			if (s.length) s ~= " ";
			s ~= .tryFormat(_prop.msgs.areaStatus, name, count);
		}
		if (_summ) { mixin(S_TRACE);
			put(_prop.msgs.area, areaCount);
			put(_prop.msgs.battle, battleCount);
			put(_prop.msgs.cwPackage, packageCount);
		}
		_statusLine = s;
		_comm.setStatusLine(_areas, _statusLine);
	}
	size_t count(A)(A[] areas) { mixin(S_TRACE);
		if (_dirMode) { mixin(S_TRACE);
			size_t n = 0;
			foreach (a; areas) { mixin(S_TRACE);
				if (0 == icmp(a.dirName, _dir)) n++;
			}
			return n;
		} else { mixin(S_TRACE);
			return areas.length;
		}
	}
	@property
	size_t areaCount() { return count(_summ.areas); }
	@property
	size_t battleCount() { return count(_summ.battles); }
	@property
	size_t packageCount() { return count(_summ.packages); }

	void saveSelections() { mixin(S_TRACE);
		if (!_prop.var.etc.saveTableViewSelection) { mixin(S_TRACE);
			_selectionsA = null;
			_selectionsB = null;
			_selectionsP = null;
			return;
		}
		foreach (i, itm; _areas.getItems()) { mixin(S_TRACE);
			auto a = cast(AbstractArea)itm.getData();
			if (_areas.isSelected(cast(int)i)) { mixin(S_TRACE);
				if (cast(Area)a) _selectionsA[a.id] = true;
				if (cast(Battle)a) _selectionsB[a.id] = true;
				if (cast(Package)a) _selectionsP[a.id] = true;
			} else { mixin(S_TRACE);
				if (cast(Area)a && a.id in _selectionsA) _selectionsA.remove(a.id);
				if (cast(Battle)a && a.id in _selectionsB) _selectionsB.remove(a.id);
				if (cast(Package)a && a.id in _selectionsP) _selectionsP.remove(a.id);
			}
		}
		foreach (id; _selectionsA.keys()) {
			if (!_summ.hasAreaId(id)) _selectionsA.remove(id);
		}
		foreach (id; _selectionsB.keys()) {
			if (!_summ.hasBattleId(id)) _selectionsB.remove(id);
		}
		foreach (id; _selectionsP.keys()) {
			if (!_summ.hasPackageId(id)) _selectionsP.remove(id);
		}
	}

	void getSelectionInfo(out ulong id, out TypeInfo type) { mixin(S_TRACE);
		getInfo(_areas.getSelectionIndex(), id, type);
	}
	void getInfo(int index, out ulong id, out TypeInfo type) { mixin(S_TRACE);
		id = 0;
		type = null;
		if (0 <= index) { mixin(S_TRACE);
			auto d = _areas.getItem(index).getData();
			auto a = cast(AbstractArea)d;
			if (a) getInfoFromArea(a, id, type);
		}
	}
	void getInfoFromArea(in AbstractArea d, out ulong id, out TypeInfo type) { mixin(S_TRACE);
		auto a = cast(Area)d;
		if (a) { mixin(S_TRACE);
			id = a.id;
			type = typeid(Area);
		}
		auto b = cast(Battle)d;
		if (b) { mixin(S_TRACE);
			id = b.id;
			type = typeid(Battle);
		}
		auto p = cast(Package)d;
		if (p) { mixin(S_TRACE);
			id = p.id;
			type = typeid(Package);
		}
	}
	void selectFromInfo(ulong id, in TypeInfo type) { mixin(S_TRACE);
		if (type is typeid(Area)) { mixin(S_TRACE);
			select(_summ.area(id));
		} else if (type is typeid(Battle)) { mixin(S_TRACE);
			select(_summ.battle(id));
		} else if (type is typeid(Package)) { mixin(S_TRACE);
			select(_summ.cwPackage(id));
		} else { mixin(S_TRACE);
			if (_dirMode) { mixin(S_TRACE);
				_dirTree.setSelection([_dirTree.getItem(0)]);
			} else { mixin(S_TRACE);
				if (_areas.getItemCount()) _areas.select(0);
			}
		}
		saveSelections();
	}
	static AbstractArea areaFromInfo(Summary summ, ulong id, TypeInfo type) { mixin(S_TRACE);
		if (type is typeid(Area)) { mixin(S_TRACE);
			return summ.area(id);
		} else if (type is typeid(Battle)) { mixin(S_TRACE);
			return summ.battle(id);
		} else if (type is typeid(Package)) { mixin(S_TRACE);
			return summ.cwPackage(id);
		} else assert (0);
	}
	TableItem getItemFrom(ulong id, TypeInfo type) { mixin(S_TRACE);
		if (type is typeid(Area)) { mixin(S_TRACE);
			foreach (itm; _areas.getItems()) { mixin(S_TRACE);
				if (cast(Area)itm.getData() && (cast(AbstractArea)itm.getData()).id == id) { mixin(S_TRACE);
					return itm;
				}
			}
			return null;
		} else if (type is typeid(Battle)) { mixin(S_TRACE);
			foreach (itm; _areas.getItems()) { mixin(S_TRACE);
				if (cast(Battle)itm.getData() && (cast(AbstractArea)itm.getData()).id == id) { mixin(S_TRACE);
					return itm;
				}
			}
			return null;
		} else if (type is typeid(Package)) { mixin(S_TRACE);
			foreach (itm; _areas.getItems()) { mixin(S_TRACE);
				if (cast(Package)itm.getData() && (cast(AbstractArea)itm.getData()).id == id) { mixin(S_TRACE);
					return itm;
				}
			}
			return null;
		}
		return showSummary ? _areas.getItem(0) : null;
	}

	static int toIndexFrom(Summary summ, ulong id, TypeInfo type) { mixin(S_TRACE);
		if (type is typeid(Area)) { mixin(S_TRACE);
			foreach (i, a; summ.areas) { mixin(S_TRACE);
				if (a.id == id) return cast(int)i;
			}
		} else if (type is typeid(Battle)) { mixin(S_TRACE);
			foreach (i, a; summ.battles) { mixin(S_TRACE);
				if (a.id == id) return cast(int)i;
			}
		} else if (type is typeid(Package)) { mixin(S_TRACE);
			foreach (i, a; summ.packages) { mixin(S_TRACE);
				if (a.id == id) return cast(int)i;
			}
		} else assert (0);
		return -1;
	}
	static int indexFrom(A)(Summary summ, int index) { mixin(S_TRACE);
		static if (is(A : Area)) {
			return index;
		} else static if (is(A : Battle)) {
			return index + cast(int)summ.areas.length;
		} else static if (is(A : Package)) {
			return index + cast(int)summ.areas.length + cast(int)summ.battles.length;
		} else static assert (0);
	}
	static int toIndex(A)(Summary summ, int index) { mixin(S_TRACE);
		static if (is(A : Area)) {
			return index;
		} else static if (is(A : Battle)) {
			return index - cast(int)summ.areas.length;
		} else static if (is(A : Package)) {
			return index - cast(int)(summ.areas.length + summ.battles.length);
		} else static assert (0);
	}
	alias toIndex!Area toAreaIndex;
	alias toIndex!Battle toBattleIndex;
	alias toIndex!Package toPackageIndex;
	static AbstractArea areaFromIndex(Summary summ, int index) { mixin(S_TRACE);
		if (summ.areas.length + summ.battles.length <= index) { mixin(S_TRACE);
			return summ.packages[toPackageIndex(summ, index)];
		}
		if (summ.areas.length <= index) { mixin(S_TRACE);
			return summ.battles[toBattleIndex(summ, index)];
		}
		if (0 <= index) { mixin(S_TRACE);
			return summ.areas[toAreaIndex(summ, index)];
		}
		return null;
	}
	AbstractArea getSelectionArea() { mixin(S_TRACE);
		auto i = _areas.getSelectionIndex();
		if (0 <= i) { mixin(S_TRACE);
			return cast(AbstractArea)_areas.getItem(i).getData();
		}
		return null;
	}
	AbstractArea[] getSelectionAreas() { mixin(S_TRACE);
		AbstractArea[] areas;
		foreach (itm; _areas.getSelection()) { mixin(S_TRACE);
			if (auto a = cast(AbstractArea)itm.getData()) { mixin(S_TRACE);
				areas ~= a;
			}
		}
		return areas;
	}
	void refArea(Object sender, Area a) { mixin(S_TRACE);
		if (_readOnly) return;
		if (sender is this) return;
		foreach (itm; _areas.getItems()) { mixin(S_TRACE);
			if (itm.getData() is a) refData(a, itm);
		}
	}
	void refBattle(Object sender, Battle a) { mixin(S_TRACE);
		if (_readOnly) return;
		if (sender is this) return;
		foreach (itm; _areas.getItems()) { mixin(S_TRACE);
			if (itm.getData() is a) refData(a, itm);
		}
	}
	void refPackage(Object sender, Package a) { mixin(S_TRACE);
		if (_readOnly) return;
		if (sender is this) return;
		foreach (itm; _areas.getItems()) { mixin(S_TRACE);
			if (itm.getData() is a) refData(a, itm);
		}
	}
	static void staticCallRefArea(AreaTable v, Commons comm, AbstractArea area) { mixin(S_TRACE);
		auto a = cast(Area)area;
		if (a) { mixin(S_TRACE);
			comm.refArea.call(v, a);
			return;
		}
		auto b = cast(Battle)area;
		if (b) { mixin(S_TRACE);
			comm.refBattle.call(v, b);
			return;
		}
		auto p = cast(Package)area;
		if (p) { mixin(S_TRACE);
			comm.refPackage.call(v, p);
			return;
		}
	}
	void callRefArea(AbstractArea area) { mixin(S_TRACE);
		if (_readOnly) return;
		staticCallRefArea(this, _comm, area);
	}
	void refreshIDs(bool callRef) { mixin(S_TRACE);
		if (_readOnly) return;
		if (!_areas || _areas.isDisposed()) return;
		if (callRef) _incSearch.close();
		foreach (itm; _areas.getItems()) { mixin(S_TRACE);
			auto area = cast(AbstractArea)itm.getData();
			if (!area) continue;
			auto str = to!(string)(area.id);
			if (callRef && str != itm.getText(ID)) callRefArea(area);
			itm.setText(ID, str);
		}
	}

	void sort() { mixin(S_TRACE);
		if (_areas.getSortColumn() is null || _areas.getSortColumn() is _idSorter.column) { mixin(S_TRACE);
			_idSorter.doSort(_areas.getSortDirection());
		} else if (_areas.getSortColumn() is _nameSorter.column) { mixin(S_TRACE);
			_nameSorter.doSort(_areas.getSortDirection());
		} else if (_areas.getSortColumn() is _ucSorter.column) { mixin(S_TRACE);
			_ucSorter.doSort(_areas.getSortDirection());
		} else assert (0);
	}

	@property
	bool showSummary() { mixin(S_TRACE);
		if (!_areas || _areas.isDisposed()) return false;
		return 0 < _areas.getItemCount() && cast(Summary)_areas.getItem(0).getData();
	}
	@property
	int countAllAreas() { mixin(S_TRACE);
		auto c = areaCount + battleCount + packageCount;
		if (showSummary) { mixin(S_TRACE);
			return 1 + cast(int)c;
		}
		return cast(int)c;
	}

	class DragDir : DragSourceAdapter {
		override void dragStart(DragSourceEvent e) { mixin(S_TRACE);
			e.doit = false;
			auto tree = cast(Tree)(cast(DragSource)e.getSource()).getControl();
			if (!tree) return;
			if (!tree.isFocusControl()) return;
			auto sels = tree.getSelection();
			if (!sels.length) return;
			auto dir = cast(DirTree)sels[0].getData();
			if (!dir) return;
			if (!dir.parent) return;
			e.doit = true;
		}
		override void dragSetData(DragSourceEvent e) { mixin(S_TRACE);
			if (XMLBytesTransfer.getInstance().isSupportedType(e.dataType)) { mixin(S_TRACE);
				auto tree = cast(Tree)(cast(DragSource)e.getSource()).getControl();
				auto dir = cast(DirTree)tree.getSelection()[0].getData();
				auto doc = XNode.create("TablePath", dir.path);
				doc.newAttr("scenarioPath", .nabs(_summ.scenarioPath));
				doc.newAttr("scenarioName", _summ.scenarioName);
				doc.newAttr("scenarioAuthor", _summ.author);
				e.data = bytesFromXML(doc.text);
			}
		}
		override void dragFinished(DragSourceEvent e) { mixin(S_TRACE);
			// 処理無し
		}
	}
	class DropDir : DropTargetAdapter {
		private void move(DropTargetEvent e) { mixin(S_TRACE);
			e.detail = (!_readOnly && e.item !is null && cast(TreeItem)e.item && cast(DirTree)(cast(TreeItem)e.item).getData()) ? DND.DROP_MOVE : DND.DROP_NONE;
		}
		override void dragEnter(DropTargetEvent e){ mixin(S_TRACE);
			move(e);
		}
		override void dragOver(DropTargetEvent e){ mixin(S_TRACE);
			move(e);
		}
		override void drop(DropTargetEvent e){ mixin(S_TRACE);
			if (_readOnly) return;
			if (!isXMLBytes(e.data)) return;
			string xml = bytesToXML(e.data);
			e.detail = DND.DROP_NONE;
			try { mixin(S_TRACE);
				// フォルダ変更
				auto node = XNode.parse(xml);
				auto itm = cast(TreeItem)e.item;
				auto dir = cast(DirTree)itm.getData();
				auto path = dir.path;
				if (node.name == "TablePath") { mixin(S_TRACE);
					if (!.cfnmatch(.nabs(_summ.scenarioPath), getScenarioPath(node))) return;
					auto oldPath = node.value;
					auto removePath = node.value;
					if (oldPath == "") return;
					if (0 == icmp(path, oldPath)) return;
					auto nDir = oldPath.split("\\")[$ - 1];
					auto oldPath2 = oldPath ~ "\\";
					if (istartsWith(path, oldPath2)) return; // 下位のフォルダに移動しようとした
					// 同一名がある場合は移動禁止
					foreach (sub; dir.subDirs) {
						if (0 == icmp(sub.name, nDir)) return;
					}
					ATUndo[] undos;
					void put(AbstractArea area) { mixin(S_TRACE);
						if (area.name.istartsWith(oldPath2)) { mixin(S_TRACE);
							ulong id;
							TypeInfo type;
							getInfoFromArea(area, id, type);
							undos ~= new UndoEdit(this.outer, _comm, _summ, id, type);
							auto p = path;
							if (p != "") p ~= "\\";
							area.name = p ~ nDir ~ "\\" ~ area.name[oldPath2.length .. $];
							callRefArea(area);
						} else if (0 == icmp(area.dirName, oldPath)) { mixin(S_TRACE);
							ulong id;
							TypeInfo type;
							getInfoFromArea(area, id, type);
							undos ~= new UndoEdit(this.outer, _comm, _summ, id, type);
							area.dirName = path;
							callRefArea(area);
						}
					}
					foreach (a; _summ.areas) put(a);
					foreach (a; _summ.battles) put(a);
					foreach (a; _summ.packages) put(a);

					if (!undos.length) { mixin(S_TRACE);
						undos ~= new UndoIDs(this.outer, _comm, _summ);
					}

					auto removeItm = findDirTree(removePath);
					auto removeDir = cast(DirTree)removeItm.getData();
					removeDir.parent.subDirs.remove(removeDir);
					auto newDir = new DirTree(dir, removeDir.name, removeDir.subDirs);
					sortDirTree();
					refreshDirTree();

					_undo ~= new ATUndoArr(undos);
				} else if (.cfnmatch(.nabs(_summ.scenarioPath), getScenarioPath(node))) { mixin(S_TRACE);
					auto area = getSelectionArea();
					ulong id;
					TypeInfo type;
					getInfoFromArea(area, id, type);
					storeEdit(id, type);
					area.dirName = dir.path;
					callRefArea(area);
				} else { mixin(S_TRACE);
					_dirTree.setSelection([itm]);
					updateDirSel();
					pasteImpl(node);
				}
				refreshAreas();
				sort();
				saveSelections();
				refreshStatusLine();
				_comm.refreshToolBar();
			} catch (Exception e) { mixin(S_TRACE);
				printStackTrace();
				debugln(e);
			}
		}
	}
	class DragArea : DragSourceAdapter {
		AbstractArea _data;
		override void dragStart(DragSourceEvent e) { mixin(S_TRACE);
			auto tbl = cast(Table)(cast(DragSource)e.getSource()).getControl();
			e.doit = tbl.isFocusControl() && 0 <= tbl.getSelectionIndex() && cast(AbstractArea)tbl.getSelection()[0].getData();
		}
		override void dragSetData(DragSourceEvent e) { mixin(S_TRACE);
			if (XMLBytesTransfer.getInstance().isSupportedType(e.dataType)) { mixin(S_TRACE);
				auto tbl = cast(Table)(cast(DragSource)e.getSource()).getControl();
				int i = tbl.getSelectionIndex();
				if (i < 0) return;
				_data = cast(AbstractArea)tbl.getItem(i).getData();
				assert (_data !is null);
				auto doc = _data.toNode(new XMLOption(_prop.sys, LATEST_VERSION));
				doc.newAttr("scenarioPath", .nabs(_summ.scenarioPath));
				doc.newAttr("scenarioName", _summ.scenarioName);
				doc.newAttr("scenarioAuthor", _summ.author);
				e.data = bytesFromXML(doc.text);
			}
		}
		override void dragFinished(DragSourceEvent e) { mixin(S_TRACE);
			if (_readOnly) return;
			if (e.detail == DND.DROP_MOVE) { mixin(S_TRACE);
				auto area = _data;
				_summ.remove(area);
				delItem(area);
				if (cast(Area)area) { mixin(S_TRACE);
					_comm.delArea.call(cast(Area)area);
				} else if (cast(Battle)area) { mixin(S_TRACE);
					_comm.delBattle.call(cast(Battle)area);
				} else { mixin(S_TRACE);
					assert (cast(Package)area);
					_comm.delPackage.call(cast(Package)area);
				}
				saveSelections();
				refreshStatusLine();
				_comm.refreshToolBar();
			}
		}
	}
	class DropArea : DropTargetAdapter {
		override void dragEnter(DropTargetEvent e){ mixin(S_TRACE);
			e.detail = !_readOnly && _areas.getItemCount() == countAllAreas ? DND.DROP_MOVE : DND.DROP_NONE;
		}
		override void dragOver(DropTargetEvent e){ mixin(S_TRACE);
			e.detail = !_readOnly && _areas.getItemCount() == countAllAreas ? DND.DROP_MOVE : DND.DROP_NONE;
		}
		override void drop(DropTargetEvent e){ mixin(S_TRACE);
			if (_readOnly) return;
			if (!isXMLBytes(e.data)) return;
			e.detail = DND.DROP_NONE;
			string xml = bytesToXML(e.data);
			try { mixin(S_TRACE);
				scope node = XNode.parse(xml);
				TypeInfo tid;
				if (node.name == Area.XML_NAME) { mixin(S_TRACE);
					tid = typeid(Area);
				} else if (node.name == Battle.XML_NAME) { mixin(S_TRACE);
					tid = typeid(Battle);
				} else if (node.name == Package.XML_NAME) { mixin(S_TRACE);
					tid = typeid(Package);
				} else { mixin(S_TRACE);
					return;
				}

				bool sortedID = _areas.getSortColumn() is null || _areas.getSortColumn() is _idSorter.column;
				auto tbl = cast(Table)(cast(DropTarget)e.getSource()).getControl();
				auto toItm = tbl.getItem(tbl.toControl(e.x, e.y));
				Object toData = toItm ? toItm.getData() : null;
				int getIndex(AbstractArea area) { mixin(S_TRACE);
					int index;
					if (auto a = cast(Area)area) { mixin(S_TRACE);
						if (toItm && cast(Summary)toData) { mixin(S_TRACE);
							index = 0;
						} else if (!toItm || cast(Battle)toData || cast(Package)toData) { mixin(S_TRACE);
							index = cast(int)_summ.areas.length;
						} else { mixin(S_TRACE);
							index = cast(int)_summ.indexOf(cast(Area)toData);
						}
					} else if (auto a = cast(Battle)area) { mixin(S_TRACE);
						if (toItm && (cast(Summary)toData || cast(Area)toData)) { mixin(S_TRACE);
							index = 0;
						} else if (!toItm || cast(Package)toData) { mixin(S_TRACE);
							index = cast(int)_summ.battles.length;
						} else { mixin(S_TRACE);
							index = cast(int)_summ.indexOf(cast(Battle)toData);
						}
					} else if (auto a = cast(Package)area) { mixin(S_TRACE);
						if (toItm && (cast(Summary)toData || cast(Area)toData || cast(Battle)toData)) { mixin(S_TRACE);
							index = 0;
						} else if (!toItm) { mixin(S_TRACE);
							index = cast(int)_summ.packages.length;
						} else { mixin(S_TRACE);
							index = cast(int)_summ.indexOf(cast(Package)toData);
						}
					} else assert (0);
					return index;
				}
				if (.cfnmatch(.nabs(_summ.scenarioPath), getScenarioPath(node))) { mixin(S_TRACE);
					// 同一リスト内で移動
					if (!sortedID) return;
					int fromIndex = tbl.getSelectionIndex();
					if (showSummary && fromIndex < 1) return;

					auto area = cast(AbstractArea)tbl.getItem(fromIndex).getData();
					int index = getIndex(area);
					void put(A)(A a) { mixin(S_TRACE);
						auto moveIndex = _summ.indexOf(a);
						if (moveIndex == index) return;
						storeMove(cast(int)moveIndex, cast(int)index, typeid(typeof(a)));
						_summ.insert(index, a);
					}
					if (auto a = cast(Area)area) { mixin(S_TRACE);
						put(a);
					} else if (auto a = cast(Battle)area) { mixin(S_TRACE);
						put(a);
					} else if (auto a = cast(Package)area) { mixin(S_TRACE);
						put(a);
					} else assert (0);
					callRefArea(area);
					refreshAreas();
					sort();
					select(area);
					saveSelections();
					refreshStatusLine();
					_comm.refreshToolBar();
					e.detail = DND.DROP_NONE;
				} else { mixin(S_TRACE);
					// 他のリストからのコピー
					AbstractArea area;
					auto ver = new XMLInfo(_prop.sys, LATEST_VERSION);
					ulong[] a, b, p;
					saveIDs(_summ, a, b, p);
					if (tid == typeid(Area)) { mixin(S_TRACE);
						area = Area.createFromNode(node, ver);
						if (!qAreasMaterialCopy(node, [area])) return;
						if (_dirMode) area.dirName = _dir;
						int index = getIndex(area);
						_summ.insert(index, cast(Area)area);
						storeInsert(area.id, tid, a, b, p);
						index = cast(int)_summ.indexOf(cast(Area)area);
						newAreaItem(index);
					} else if (tid == typeid(Battle)) { mixin(S_TRACE);
						area = Battle.createFromNode(node, ver);
						if (!qAreasMaterialCopy(node, [area])) return;
						if (_dirMode) area.dirName = _dir;
						int index = getIndex(area);
						_summ.insert(index, cast(Battle)area);
						storeInsert(area.id, tid, a, b, p);
						index = cast(int)_summ.indexOf(cast(Battle)area);
						newBattleItem(index);
					} else { mixin(S_TRACE);
						assert (tid == typeid(Package));
						area = Package.createFromNode(node, ver);
						if (!qAreasMaterialCopy(node, [area])) return;
						if (_dirMode) area.dirName = _dir;
						int index = getIndex(area);
						_summ.insert(index, cast(Package)area);
						storeInsert(area.id, tid, a, b, p);
						index = cast(int)_summ.indexOf(cast(Package)area);
						newPackageItem(index);
					}
					e.detail = DND.DROP_NONE;
					refreshIDs(true);
					sort();
					select(area);
					saveSelections();
					_comm.refUseCount.call();
					refreshStatusLine();
					_comm.refreshToolBar();
				}
			} catch (Exception e) { mixin(S_TRACE);
				printStackTrace();
				debugln(e);
			}
		}
	}
	int indexOf(in AbstractArea area) { mixin(S_TRACE);
		foreach (i, itm; _areas.getItems()) { mixin(S_TRACE);
			if (itm.getData() is area) { mixin(S_TRACE);
				return cast(int)i;
			}
		}
		return -1;
	}
	void refreshUseCount() { mixin(S_TRACE);
		foreach (itm; _areas.getItems()) { mixin(S_TRACE);
			auto element = itm.getData();
			if (cast(Area)element) { mixin(S_TRACE);
				itm.setText(2, to!(string)(_summ.useCounter.get(toAreaId((cast(AbstractArea)element).id))));
			} else if (cast(Battle)element) { mixin(S_TRACE);
				itm.setText(2, to!(string)(_summ.useCounter.get(toBattleId((cast(AbstractArea)element).id))));
			} else if (cast(Package)element) { mixin(S_TRACE);
				itm.setText(2, to!(string)(_summ.useCounter.get(toPackageId((cast(AbstractArea)element).id))));
			}
		}
	}
	class TreeMListener : MouseAdapter {
		public override void mouseDoubleClick(MouseEvent e) { mixin(S_TRACE);
			if (_dirTree.isFocusControl() && e.button == 1) { mixin(S_TRACE);
				auto itm = _dirTree.getItem(new Point(e.x, e.y));
				if (itm && cast(Summary)itm.getData()) { mixin(S_TRACE);
					editSummary();
				}
			}
		}
	}
	class TreeKListener : KeyAdapter {
		public override void keyPressed(KeyEvent e) { mixin(S_TRACE);
			if (_dirTree.isFocusControl() && .isEnterKey(e.keyCode)) { mixin(S_TRACE);
				auto sels = _dirTree.getSelection();
				if (!sels.length) return;
				auto sel = sels[0];
				if (cast(Summary)sel.getData()) { mixin(S_TRACE);
					editSummary();
				}
			}
		}
	}
	class MListener : MouseAdapter {
		public override void mouseUp(MouseEvent e) { mixin(S_TRACE);
			if (e.button == 2) { mixin(S_TRACE);
				auto itm = _areas.getItem(new Point(e.x, e.y));
				if (itm && cast(Summary)itm.getData()) { mixin(S_TRACE);
					editSummary();
				} else { mixin(S_TRACE);
					if (_prop.var.etc.clickIsOpenEvent) { mixin(S_TRACE);
						openAreaScene(e.x, e.y, true);
					} else { mixin(S_TRACE);
						openAreaEvent(e.x, e.y, true);
					}
				}
			}
		}
		public override void mouseDoubleClick(MouseEvent e) { mixin(S_TRACE);
			if (_areas.isFocusControl() && e.button == 1) { mixin(S_TRACE);
				auto itm = _areas.getItem(new Point(e.x, e.y));
				if (itm && cast(Summary)itm.getData()) { mixin(S_TRACE);
					editSummary();
				} else { mixin(S_TRACE);
					bool shift = 0 != (e.stateMask & SWT.SHIFT);
					if (_prop.var.etc.clickIsOpenEvent) shift = !shift;
					if (shift) { mixin(S_TRACE);
						openAreaEvent(true);
					} else { mixin(S_TRACE);
						openAreaScene(true);
					}
				}
			}
		}
	}
	class KListener : KeyAdapter {
		public override void keyPressed(KeyEvent e) { mixin(S_TRACE);
			if (_areas.isFocusControl() && .isEnterKey(e.keyCode)) { mixin(S_TRACE);
				auto sel = _areas.getSelectionIndex();
				if (sel == -1) return;
				if (cast(Summary)_areas.getItem(sel).getData()) { mixin(S_TRACE);
					editSummary();
				} else { mixin(S_TRACE);
					bool shift = 0 != (e.stateMask & SWT.SHIFT);
					if (_prop.var.etc.clickIsOpenEvent) shift = !shift;
					if (shift) { mixin(S_TRACE);
						openAreaEvent(true);
					} else { mixin(S_TRACE);
						openAreaScene(true);
					}
				}
			}
		}
	}
	class ADListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			_dirs = null;
			_dir = "";
			_areas = null;
			_dirTree = null;
			_selectionsA = null;
			_selectionsB = null;
			_selectionsP = null;
			if (!_readOnly) {
				_comm.refArea.remove(&refArea);
				_comm.refBattle.remove(&refBattle);
				_comm.refPackage.remove(&refPackage);
				_comm.refUseCount.remove(&refreshUseCount);
				_comm.replText.remove(&replText);
				_comm.replText.remove(&refresh);
				_comm.refScenario.remove(&refScenario);
				_comm.refScenarioName.remove(&refScenarioName);
				_comm.refUndoMax.remove(&refUndoMax);
			}
			_comm.refAreaTable.remove(&refreshAreas);
		}
	}
	static class DirTree {
		DirTree parent;
		string name;
		DirTree[] subDirs;
		this (DirTree parent, string name, DirTree[] subDirs = []) { mixin(S_TRACE);
			this.parent = parent;
			this.name = name;
			if (parent) { mixin(S_TRACE);
				parent.subDirs ~= this;
			}
			foreach (subDir; subDirs) { mixin(S_TRACE);
				subDir.parent = this;
				this.subDirs ~= subDir;
			}
		}
		@property
		const
		string path() { mixin(S_TRACE);
			if (!parent) return name;
			auto path = parent.path;
			return path == "" ? name : path ~ "\\" ~ name;
		}
		@property
		const
		DirTree dup() { mixin(S_TRACE);
			DirTree recurse(DirTree parent, in DirTree dir) { mixin(S_TRACE);
				auto dir2 = new DirTree(parent, dir.name);
				foreach (sub; dir.subDirs) { mixin(S_TRACE);
					recurse(dir2, sub);
				}
				return dir2;
			}
			return recurse(null, this);
		}
	}
	private void delDirTree(string path) {
		if (_readOnly) return;
		if (path == "") return;
		auto itm = findDirTree(path);
		auto dir = cast(DirTree)itm.getData();
		assert (dir !is null);
		assert (dir.parent !is null);
		dir.parent.subDirs.remove(dir);
		itm.dispose();
	}
	private void replText() {
		if (_readOnly) return;
		constructDirTree(false);
	}
	private void constructDirTree(bool add) { mixin(S_TRACE);
		string[] stored;
		if (add && _dirs) { mixin(S_TRACE);
			void store(DirTree dir) { mixin(S_TRACE);
				stored ~= dir.path;
				foreach (sub; dir.subDirs) store(sub);
			}
			store(_dirs);
		}
		_dirs = new DirTree(null, "");
		DirTree[string] itmTable;
		itmTable[""] = _dirs;
		void put(string dirName) { mixin(S_TRACE);
			auto dirs = .split(dirName, "\\");
			auto itm = _dirs;
			foreach (i, dir; dirs) { mixin(S_TRACE);
				auto fPath = dirs[0 .. i + 1].join("\\");
				auto path = fPath.toLower();
				auto p = path in itmTable;
				if (p) { mixin(S_TRACE);
					itm = *p;
				} else { mixin(S_TRACE);
					auto sub = new DirTree(itm, dir);
					itm = sub;
					itmTable[path] = sub;
				}
			}
		}
		foreach (a; _summ.areas) put(a.dirName);
		foreach (a; _summ.battles) put(a.dirName);
		foreach (a; _summ.packages) put(a.dirName);
		foreach (s; stored) put(s);

		sortDirTree();
	}
	private string putDir(DirTree parent, string dirName) { mixin(S_TRACE);
		auto dirs = .split(dirName, "\\");
		foreach (i, dir; dirs) { mixin(S_TRACE);
			bool exists = false;
			foreach (sub; parent.subDirs) { mixin(S_TRACE);
				if (0 == icmp(sub.name, dir)) { mixin(S_TRACE);
					parent = sub;
					exists = true;
					break;
				}
			}
			if (!exists) {
				parent = new DirTree(parent, dir);
			}
		}
		return parent.path;
	}
	private void sortDirTree() {
		void recurse(DirTree dir) { mixin(S_TRACE);
			if (_prop.var.etc.logicalSort) { mixin(S_TRACE);
				.sortDlg(dir.subDirs, (DirTree a, DirTree b) => incmp(a.name, b.name) < 0);
			} else { mixin(S_TRACE);
				.sortDlg(dir.subDirs, (DirTree a, DirTree b) => icmp(a.name, b.name) < 0);
			}
			foreach (sub; dir.subDirs) recurse(sub);
		}
		recurse(_dirs);
	}
	private TreeItem findDirTree(string path) { mixin(S_TRACE);
		auto dirs = .split(path, "\\");
		auto itm = rootDir;
		foreach (i, dir; dirs) { mixin(S_TRACE);
			foreach (sub; itm.getItems()) { mixin(S_TRACE);
				auto ds = cast(DirTree)sub.getData();
				if (0 == icmp(ds.name, dir)) { mixin(S_TRACE);
					itm = sub;
					break;
				}
			}
		}
		return itm;
	}
	private void refreshDirTree() { mixin(S_TRACE);
		if (!_dirTree) return;
		if (_areaDirEdit) _areaDirEdit.cancel();
		bool selSummary = false;
		auto sel = "";
		auto sels = _dirTree.getSelection();
		if (sels.length) { mixin(S_TRACE);
			auto path = cast(DirTree)sels[0].getData();
			if (path) { mixin(S_TRACE);
				sel = path.path;
			} else { mixin(S_TRACE);
				assert (cast(Summary)sels[0].getData() !is null);
				selSummary = true;
			}
		}
		_dirTree.removeAll();
		if (!_summ) return;
		if (_prop.var.etc.showSummaryInAreaTable) { mixin(S_TRACE);
			auto itm = new TreeItem(_dirTree, SWT.NONE);
			itm.setImage(_prop.images.summary);
			itm.setText(_summ.scenarioName);
			itm.setData(_summ);
			if (selSummary) { mixin(S_TRACE);
				_dirTree.setSelection([itm]);
			}
		}

		void recurse(T)(T tree, DirTree dir) { mixin(S_TRACE);
			auto itm = new TreeItem(tree, SWT.NONE);
			static if (is(T:Tree)) {
				itm.setText(_prop.msgs.areaDirRoot);
			} else {
				itm.setText(dir.name);
			}
			itm.setImage(_prop.images.areaDir);
			itm.setData(dir);
			if (!selSummary && 0 == icmp(sel, dir.path)) { mixin(S_TRACE);
				_dirTree.setSelection([itm]);
			} else if (!_dirTree.getSelection().length) { mixin(S_TRACE);
				_dirTree.setSelection([itm]);
			}
			foreach (sub; dir.subDirs) { mixin(S_TRACE);
				recurse(itm, sub);
			}
		}
		recurse(_dirTree, _dirs);

		_dirTree.treeExpandedAll();
		_dirTree.showSelection();
	}
	private Image areaImage(in Area a) {
		return _summ.startArea == a.id ? _prop.images.startArea : _prop.images.area;
	}
	private void updateDirSel() { mixin(S_TRACE);
		auto sels = _dirTree.getSelection();
		if (!sels.length) return;
		auto sel = cast(DirTree)sels[0].getData();
		if (!sel) return;
		_dir = sel.path;
		refreshAreasImpl(true);
	}
	private void refreshAreas() { mixin(S_TRACE);
		refreshAreasImpl(false);
	}
	private void refreshAreasImpl(bool selDir) { mixin(S_TRACE);
		if (!_areas || _areas.isDisposed()) return;
		_parent.setRedraw(false);
		scope (exit) _parent.setRedraw(true);
		if (!selDir) refreshDirTree();
		int topIndex = _areas.getTopIndex();
		auto sel = _areas.getSelectionIndex();
		_hasAreas = false;
		if (_summ) { mixin(S_TRACE);
			size_t i = 0;
			if (!_dirMode && _prop.var.etc.showSummaryInAreaTable) { mixin(S_TRACE);
				refSummary();
				i++;
			}
			void put(AbstractArea a) { mixin(S_TRACE);
				if (_dirMode) { mixin(S_TRACE);
					if (0 != icmp(a.dirName, _dir)) return;
					_hasAreas = true;
					if (!_incSearch.match(a.baseName, a)) return;
				} else { mixin(S_TRACE);
					_hasAreas = true;
					if (!_incSearch.match(a.name, a)) return;
				}
				refData2(a, i < _areas.getItemCount() ? _areas.getItem(cast(int)i) : new TableItem(_areas, SWT.NONE));
				i++;
			}
			foreach (a; _summ.areas) { mixin(S_TRACE);
				put(a);
			}
			foreach (a; _summ.battles) { mixin(S_TRACE);
				put(a);
			}
			foreach (a; _summ.packages) { mixin(S_TRACE);
				put(a);
			}
			while (i < _areas.getItemCount()) { mixin(S_TRACE);
				_areas.getItem(cast(int)i).dispose();
			}
			sort();
		} else { mixin(S_TRACE);
			_areas.removeAll();
		}
		_areas.setTopIndex(topIndex);
		if (selDir && _prop.var.etc.saveTableViewSelection) { mixin(S_TRACE);
			_areas.deselectAll();
			foreach (i, itm; _areas.getItems()) { mixin(S_TRACE);
				auto a = cast(AbstractArea)itm.getData();
				if (cast(Area)a && _selectionsA.get(a.id, false)) _areas.select(cast(int)i);
				if (cast(Battle)a && _selectionsB.get(a.id, false)) _areas.select(cast(int)i);
				if (cast(Package)a && _selectionsP.get(a.id, false)) _areas.select(cast(int)i);
			}
			if (_areas.getSelectionIndex() == -1 && _areas.getItemCount()) { mixin(S_TRACE);
				_areas.select(0);
			}
		} else { mixin(S_TRACE);
			if (sel < 0 || _areas.getItemCount() <= sel) { mixin(S_TRACE);
				_areas.select(.min(_areas.getItemCount() - 1, sel));
			}
		}
		saveSelections();
		_areas.showSelection();
		refreshStatusLine();
		_comm.refreshToolBar();
	}
	void refSummary() { mixin(S_TRACE);
		if (!_summ) return;
		TableItem itm;
		if (_areas.getItemCount()) { mixin(S_TRACE);
			if (!showSummary) return;
			itm = _areas.getItem(0);
		} else { mixin(S_TRACE);
			itm = new TableItem(_areas, SWT.NONE, 0);
		}
		itm.setImage(0, _prop.images.summary);
		itm.setText(ID, "-");
		itm.setText(NAME, _summ.scenarioName);
		itm.setText(UC, "-");
		itm.setData(_summ);
	}
	void updateAreaImage() { mixin(S_TRACE);
		foreach (itm; _areas.getItems()) { mixin(S_TRACE);
			if (auto a = cast(Area)itm.getData()) { mixin(S_TRACE);
				itm.setImage(0, areaImage(a));
			}
		}
	}
	void item(AbstractArea a, Image img, int uc, int index = -1) { mixin(S_TRACE);
		TableItem itm;
		if (index >= 0) { mixin(S_TRACE);
			itm = new TableItem(_areas, SWT.NONE, index);
		} else { mixin(S_TRACE);
			itm = new TableItem(_areas, SWT.NONE);
		}
		itm.setImage(0, img);
		itm.setText(ID, to!(string)(a.id));
		itm.setText(NAME, _dirMode ? a.baseName : a.name);
		itm.setText(UC, to!(string)(uc));
		itm.setData(a);
	}
	void refData2(AbstractArea a, TableItem itm) { mixin(S_TRACE);
		if (auto area = cast(Area)a) { mixin(S_TRACE);
			itm.setImage(0, areaImage(area));
			refData(area, itm);
		} else if (auto btl = cast(Battle)a) { mixin(S_TRACE);
			itm.setImage(0, _prop.images.battle);
			refData(btl, itm);
		} else if (auto pkg = cast(Package)a) { mixin(S_TRACE);
			itm.setImage(0, _prop.images.packages);
			refData(pkg, itm);
		} else assert (0);
	}
	void refData(A)(A a, TableItem itm) { mixin(S_TRACE);
		itm.setText(ID, to!(string)(a.id));
		itm.setText(NAME, _dirMode ? a.baseName : a.name);
		itm.setText(UC, to!(string)(_summ.useCounter.get(A.toID(a.id))));
		itm.setData(a);
	}
	private int newAreaItem(int index) { mixin(S_TRACE);
		_incSearch.close();
		auto a = _summ.areas[index];
		if (showSummary) index++;
		item(a, areaImage(a), _summ.useCounter.get(toAreaId(a.id)), index);
		return index;
	}
	private int newBattleItem(int index) { mixin(S_TRACE);
		_incSearch.close();
		auto a = _summ.battles[index];
		index += _summ.areas.length;
		if (showSummary) index++;
		item(a, _prop.images.battle, _summ.useCounter.get(toBattleId(a.id)), index);
		return index;
	}
	private int newPackageItem(int index) { mixin(S_TRACE);
		_incSearch.close();
		auto a = _summ.packages[index];
		index += _summ.areas.length + _summ.battles.length;
		if (showSummary) index++;
		item(a, _prop.images.packages, _summ.useCounter.get(toPackageId(a.id)), index);
		return index;
	}
	private void addAreaItem(int index) { mixin(S_TRACE);
		auto a = _summ.areas[index];
		if (!_incSearch.match(a.name, a)) return;
		index = showSummary ? 1 : 0;
		for (; index < _areas.getItemCount(); index++) { mixin(S_TRACE);
			if (!cast(Area)_areas.getItem(index).getData()) break;
		}
		item(a, areaImage(a), _summ.useCounter.get(toAreaId(a.id)), index);
	}
	private void addBattleItem(int index) { mixin(S_TRACE);
		auto a = _summ.battles[index];
		if (!_incSearch.match(a.name, a)) return;
		index = showSummary ? 1 : 0;
		for (; index < _areas.getItemCount(); index++) { mixin(S_TRACE);
			auto data = _areas.getItem(index).getData();
			if (!cast(Area)data && !cast(Battle)data) break;
		}
		item(a, _prop.images.battle, _summ.useCounter.get(toBattleId(a.id)), index);
	}
	private void addPackageItem(int index) { mixin(S_TRACE);
		auto a = _summ.packages[index];
		if (!_incSearch.match(a.name, a)) return;
		index = _areas.getItemCount();
		item(a, _prop.images.packages, _summ.useCounter.get(toPackageId(a.id)), index);
	}
	private class SListener : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			saveSelections();
			refreshStatusLine();
			_comm.refreshToolBar();
		}
	}
	bool _sortProc = false;
	void refSortParams(Object sender, int column, int dir) { mixin(S_TRACE);
		if (sender is this) return;
		if (_sortProc) return;
		_sortProc = true;
		scope (exit) _sortProc = false;
		final switch (column) {
		case ID:
			_idSorter.doSort(dir);
			break;
		case NAME:
			_nameSorter.doSort(dir);
			break;
		case UC:
			_ucSorter.doSort(dir);
			break;
		}
	}
	void sorted() { mixin(S_TRACE);
		if (_sortProc) return;
		_sortProc = true;
		scope (exit) _sortProc = false;
		if (_areas.getSortColumn() is null) return;
		_comm.refImportAreasSort.call(_areas.indexOf(_areas.getSortColumn()), _areas.getSortDirection());
	}
	void refScenario(Summary summ) { mixin(S_TRACE);
		_undo.reset();
		_selectionsA = null;
		_selectionsB = null;
		_selectionsP = null;
	}
	void refScenarioName() { mixin(S_TRACE);
		if (!_summ) return;
		if (_dirMode) { mixin(S_TRACE);
			if (!showTreeSummary) return;
			auto itm = _dirTree.getItem(0);
			itm.setText(_summ.scenarioName);
		} else {
			if (!showSummary) return;
			auto itm = _areas.getItem(0);
			itm.setText(NAME, _summ.scenarioName);
		}
	}
	void refUndoMax() { mixin(S_TRACE);
		_undo.max = _prop.var.etc.undoMaxMainView;
	}
public:
	this (Commons comm, Props prop, bool readOnly, Summary importTarget) { mixin(S_TRACE);
		_readOnly = readOnly ? SWT.READ_ONLY : SWT.NONE;
		_comm = comm;
		_prop = prop;
		_importTarget = importTarget;
		_undo = new UndoManager(_prop.var.etc.undoMaxMainView);

		if (_readOnly) { mixin(S_TRACE);
			_summSkin = findSkin(_comm, _prop, importTarget);
		}
	}

	void construct(Composite parent, FlagTable flags) { mixin(S_TRACE);
		_flags = flags;
		if (!_readOnly) { mixin(S_TRACE);
			_comm.refArea.add(&refArea);
			_comm.refBattle.add(&refBattle);
			_comm.refPackage.add(&refPackage);
			_comm.refUseCount.add(&refreshUseCount);
			_comm.replText.add(&replText);
			_comm.replText.add(&refresh);
			_comm.refScenario.add(&refScenario);
			_comm.refScenarioName.add(&refScenarioName);
			_comm.refUndoMax.add(&refUndoMax);
		}
		_comm.refAreaTable.add(&refreshAreas);
		auto tableParent = parent;
		_parent = parent;
		_dirMode = false;
		if (_prop.var.etc.showAreaDirTree) { mixin(S_TRACE);
			_dirMode = true;
			auto sash = new SplitPane(parent, (_readOnly ? _prop.var.etc.importAreaSashV : _prop.var.etc.areaSashV) ? SWT.VERTICAL : SWT.HORIZONTAL);
			auto cl1 = new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0);
			cl1.fillHorizontal = true;
			cl1.fillVertical = true;
			auto cl2 = new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0);
			cl2.fillHorizontal = true;
			cl2.fillVertical = true;
			auto panel1 = new Composite(sash, SWT.NONE);
			panel1.setLayout(cl1);
			auto panel2 = new Composite(sash, SWT.NONE);
			panel2.setLayout(cl2);
			tableParent = panel2;
			_dirTree = new Tree(panel1, SWT.SINGLE | SWT.BORDER);
			initTree(_comm, _dirTree, false);
			.treeWarning(_prop, _dirTree, delegate string[] (TreeItem itm) { mixin(S_TRACE);
				if (auto summ = cast(Summary)itm.getData()) { mixin(S_TRACE);
					return .warnings(_prop.parent, summSkin, _summ, _summ, _prop.var.etc.targetVersion);
				}
				if (auto dt = cast(DirTree)itm.getData()) { mixin(S_TRACE);
					return .sjisWarnings(_prop.parent, _summ, dt.name, _prop.msgs.areaDirName);
				}
				return [];
			});
			.listener(_dirTree, SWT.Selection, &updateDirSel);
			if (!_readOnly) { mixin(S_TRACE);
				_areaDirEdit = new TreeEdit(_comm, _dirTree, &dirEditEnd, (itm) { mixin(S_TRACE);
					auto dir = cast(DirTree)itm.getData();
					if (dir) { mixin(S_TRACE);
						if (!dir.parent) return null;
					} else assert (cast(Summary)itm.getData() !is null);
					return createTextEditor(_comm, _prop, _dirTree, itm.getText());
				});
			}
			_dirTree.addMouseListener(new TreeMListener);
			_dirTree.addKeyListener(new TreeKListener);
			.listener(_dirTree, SWT.FocusIn, (e) { _lastFocus = cast(Control)e.widget; });
			if (!_lastFocus) _lastFocus = _dirTree;

			auto menu = new Menu(_dirTree.getShell(), SWT.POP_UP);
			if (_readOnly) { mixin(S_TRACE);
				createMenuItem(_comm, menu, MenuID.Import, &doImport, &canDoImport);
				new MenuItem(menu, SWT.SEPARATOR);
				appendMenuTCPD(_comm, menu, this, false, true, false, false, false);
			} else { mixin(S_TRACE);
				createMenuItem(_comm, menu, MenuID.NewAreaDir, &createDir, () => !_readOnly && _dirMode && _summ !is null);
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.Undo, &this.undo, () => !_readOnly && _undo.canUndo);
				createMenuItem(_comm, menu, MenuID.Redo, &this.redo, () => !_readOnly && _undo.canRedo);
				new MenuItem(menu, SWT.SEPARATOR);
				appendMenuTCPD(_comm, menu, this, true, true, true, true, true);
			}
			_dirTree.setMenu(menu);

			auto drag = new DragSource(_dirTree, DND.DROP_MOVE | DND.DROP_COPY);
			drag.setTransfer([XMLBytesTransfer.getInstance()]);
			drag.addDragListener(new DragDir);
			if (!_readOnly) { mixin(S_TRACE);
				auto drop = new DropTarget(_dirTree, DND.DROP_DEFAULT | DND.DROP_MOVE);
				drop.setTransfer([XMLBytesTransfer.getInstance()]);
				drop.addDropListener(new DropDir);
			}
		}

		_areas = .rangeSelectableTable(tableParent, (_readOnly ? SWT.MULTI : SWT.SINGLE) | SWT.BORDER | SWT.FULL_SELECTION);
		_areas.addDisposeListener(new ADListener);
		_areas.addSelectionListener(new SListener);
		.listener(_areas, SWT.FocusIn, (e) { _lastFocus = cast(Control)e.widget; });
		if (!_lastFocus) _lastFocus = _areas;
		_areas.setHeaderVisible(true);
		auto idCol = new TableColumn(_areas, SWT.NULL);
		idCol.setText(_prop.msgs.areaId);
		auto nameCol = new TableColumn(_areas, SWT.NULL);
		nameCol.setText(_prop.msgs.areaName);
		auto countCol = new TableColumn(_areas, SWT.NULL);
		countCol.setText(_prop.msgs.areaCount);
		if (_readOnly) { mixin(S_TRACE);
			saveColumnWidth!("prop.var.etc.importAreaIdColumn")(_prop, idCol);
			saveColumnWidth!("prop.var.etc.importAreaNameColumn")(_prop, nameCol);
			saveColumnWidth!("prop.var.etc.importAreaCountColumn")(_prop, countCol);
		} else { mixin(S_TRACE);
			saveColumnWidth!("prop.var.etc.areaIdColumn")(_prop, idCol);
			saveColumnWidth!("prop.var.etc.areaNameColumn")(_prop, nameCol);
			saveColumnWidth!("prop.var.etc.areaCountColumn")(_prop, countCol);
		}

		_areasEdit = new TableTextEdit(_comm, _prop, _areas, 1, &editEnd);
		updateIncSearchParent();

		auto menu = new Menu(parent.getShell(), SWT.POP_UP);
		createMenuItem(_comm, menu, MenuID.IncSearch, &incSearch, () => _hasAreas);
		new MenuItem(menu, SWT.SEPARATOR);
		if (_readOnly) {
			createMenuItem(_comm, menu, MenuID.Import, &doImport, &canDoImport);
			new MenuItem(menu, SWT.SEPARATOR);
		}
		createMenuItem(_comm, menu, MenuID.EditScene, { openAreaScene(true); }, &canOpenAreaScene);
		createMenuItem(_comm, menu, MenuID.EditEvent, { openAreaEvent(true); }, &canOpenAreaEvent);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.EditSummary, &editSummary, () => _summ !is null);
		new MenuItem(menu, SWT.SEPARATOR);
		if (!_readOnly) { mixin(S_TRACE);
			createMenuItem(_comm, menu, MenuID.NewArea, &createArea, () => !_readOnly && _summ !is null);
			createMenuItem(_comm, menu, MenuID.NewBattle, &createBattle, () => !_readOnly && _summ !is null);
			createMenuItem(_comm, menu, MenuID.NewPackage, &createPackage, () => !_readOnly && _summ !is null);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.SetStartArea, &setStartArea, &canSetStartArea);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.Undo, &undo, () => !_readOnly && _undo.canUndo);
			createMenuItem(_comm, menu, MenuID.Redo, &redo, () => !_readOnly && _undo.canRedo);
			new MenuItem(menu, SWT.SEPARATOR);
			appendMenuTCPD(_comm, menu, this, true, true, true, true, true);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.FindID, &replaceID, &canReplaceID);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.ReNumbering, &reNumbering, &canReNumbering);
		} else { mixin(S_TRACE);
			appendMenuTCPD(_comm, menu, this, false, true, false, false, false);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.SelectAll, &selectAll, &canSelectAll);
		}
		_areas.setMenu(menu);

		_areas.addMouseListener(new MListener);
		_areas.addKeyListener(new KListener);
		auto drag = new DragSource(_areas, DND.DROP_MOVE | DND.DROP_COPY);
		drag.setTransfer([XMLBytesTransfer.getInstance()]);
		drag.addDragListener(new DragArea);
		if (!_readOnly) { mixin(S_TRACE);
			auto drop = new DropTarget(_areas, DND.DROP_DEFAULT | DND.DROP_MOVE);
			drop.setTransfer([XMLBytesTransfer.getInstance()]);
			drop.addDropListener(new DropArea);
		}

		// ソート関係
		_idSorter = new TableSorter!(Object)(idCol, &compID, &revCompID);
		if (_readOnly) _idSorter.sortedEvent ~= &sorted;
		_nameSorter = new TableSorter!(Object)(nameCol, &compName, &revCompName);
		if (_readOnly) _nameSorter.sortedEvent ~= &sorted;
		_ucSorter = new TableSorter!(Object)(countCol, &compUC, &revCompUC);
		if (_readOnly) _ucSorter.sortedEvent ~= &sorted;
		auto st = _idSorter;
		int sortColumn = _readOnly ? _prop.var.etc.importAreasSortColumn : _prop.var.etc.areasSortColumn;
		switch (sortColumn) {
		case ID:
			st = _idSorter;
			break;
		case NAME:
			st = _nameSorter;
			break;
		case UC:
			st = _ucSorter;
			break;
		default:
		}
		int sortDir = _readOnly ? _prop.var.etc.importAreasSortDirection : _prop.var.etc.areasSortDirection;
		switch (sortDir) {
		case SortDir.Up:
			st.doSort(SWT.UP);
			break;
		case SortDir.Down:
			st.doSort(SWT.DOWN);
			break;
		default:
			// 必ずソートする
			st.doSort(SWT.UP);
			break;
		}
		if (_readOnly) { mixin(S_TRACE);
			_comm.refImportAreasSort.add(&refSortParams);
			.listener(_areas, SWT.Dispose, { mixin(S_TRACE);
				_comm.refImportAreasSort.remove(&refSortParams);
			});
		}
		void storeSortParams() { mixin(S_TRACE);
			if (_readOnly) { mixin(S_TRACE);
				switch (_areas.getSortDirection()) {
				case SWT.UP:
					_prop.var.etc.importAreasSortDirection = SortDir.Up;
					break;
				case SWT.DOWN:
					_prop.var.etc.importAreasSortDirection = SortDir.Down;
					break;
				default:
					// 必ずソートする
					_prop.var.etc.importAreasSortDirection = SortDir.Up;
					break;
				}
				if (_areas.getSortColumn() is _idSorter.column) { mixin(S_TRACE);
					_prop.var.etc.importAreasSortColumn = ID;
				} else if (_areas.getSortColumn() is _nameSorter.column) { mixin(S_TRACE);
					_prop.var.etc.importAreasSortColumn = NAME;
				} else if (_areas.getSortColumn() is _ucSorter.column) { mixin(S_TRACE);
					_prop.var.etc.importAreasSortColumn = UC;
				} else { mixin(S_TRACE);
					_prop.var.etc.importAreasSortColumn = -1;
				}
			} else { mixin(S_TRACE);
				switch (_areas.getSortDirection()) {
				case SWT.UP:
					_prop.var.etc.areasSortDirection = SortDir.Up;
					break;
				case SWT.DOWN:
					_prop.var.etc.areasSortDirection = SortDir.Down;
					break;
				default:
					// 必ずソートする
					_prop.var.etc.areasSortDirection = SortDir.Up;
					break;
				}
				if (_areas.getSortColumn() is _idSorter.column) { mixin(S_TRACE);
					_prop.var.etc.areasSortColumn = ID;
				} else if (_areas.getSortColumn() is _nameSorter.column) { mixin(S_TRACE);
					_prop.var.etc.areasSortColumn = NAME;
				} else if (_areas.getSortColumn() is _ucSorter.column) { mixin(S_TRACE);
					_prop.var.etc.areasSortColumn = UC;
				} else { mixin(S_TRACE);
					_prop.var.etc.areasSortColumn = -1;
				}
			}
			_comm.refreshToolBar();
		}
		_idSorter.sortedEvent ~= &storeSortParams;
		_nameSorter.sortedEvent ~= &storeSortParams;
		_ucSorter.sortedEvent ~= &storeSortParams;

		if (_dirTree) { mixin(S_TRACE);
			auto sash = cast(SplitPane)_dirTree.getParent().getParent();
			if (_readOnly) { mixin(S_TRACE);
				.setupWeights(sash, _prop.var.etc.importAreaSashL, _prop.var.etc.importAreaSashR);
			} else { mixin(S_TRACE);
				.setupWeights(sash, _prop.var.etc.areaSashL, _prop.var.etc.areaSashR);
			}
		}
	}

	private void updateIncSearchParent() { mixin(S_TRACE);
		auto matchers = [
			AdditionMatcher(MenuProps.buildMenu(.objName!Area(_prop), "A", "", false), (o) => cast(Area)o !is null),
			AdditionMatcher(MenuProps.buildMenu(.objName!Battle(_prop), "B", "", false), (o) => cast(Battle)o !is null),
			AdditionMatcher(MenuProps.buildMenu(.objName!Package(_prop), "P", "", false), (o) => cast(Package)o !is null)
		];
		if (_dirMode) { mixin(S_TRACE);
			_incSearch = new IncSearch(_comm, _dirTree.getParent().getParent(), () => _hasAreas, matchers);
		} else { mixin(S_TRACE);
			_incSearch = new IncSearch(_comm, _areas, () => _hasAreas, matchers);
		}
		_incSearch.modEvent ~= &refreshAreas;
	}

	private int toAreaIndex(int index) { mixin(S_TRACE);
		index--;
		return (index >= 0 && index < _summ.areas.length) ? index : -1;
	}
	private int toBattleIndex(int index) { mixin(S_TRACE);
		index--;
		return (index >= 0 && index < _summ.areas.length + _summ.battles.length)
			? index - cast(int)_summ.areas.length : -1;
	}
	private int toPackageIndex(int index) { mixin(S_TRACE);
		index--;
		return (index >= 0 && index < _summ.areas.length
			+ _summ.battles.length + _summ.packages.length)
			? index - cast(int)_summ.areas.length - cast(int)_summ.battles.length : -1;
	}

	@property
	bool canChangeVH() { mixin(S_TRACE);
		return _dirTree && !_dirTree.isDisposed();
	}
	void changeVHSide() { mixin(S_TRACE);
		if (!canChangeVH) return;
		auto sash = cast(SplitPane)_dirTree.getParent().getParent();
		sash = .changeVHSide(sash);
		if (_readOnly) { mixin(S_TRACE);
			_prop.var.etc.importAreaSashV = (sash.getStyle() & SWT.VERTICAL) != 0;
		} else { mixin(S_TRACE);
			_prop.var.etc.areaSashV = (sash.getStyle() & SWT.VERTICAL) != 0;
		}
		updateIncSearchParent();
	}

	@property
	bool canCreateDir() { mixin(S_TRACE);
		return !_readOnly && _summ && _dirTree && !_dirTree.isDisposed();
	}
	void createDir() { mixin(S_TRACE);
		if (_readOnly) return;
		if (!canCreateDir) return;
		_incSearch.close();
		storeEmpty();
		auto itm = findDirTree(_dir);
		auto dir = cast(DirTree)itm.getData();
		auto sub = new DirTree(dir, .createNewName(_prop.msgs.areaDirNew, (s) { mixin(S_TRACE);
			foreach (dir; dir.subDirs) { mixin(S_TRACE);
				if (0 == icmp(dir.name, s)) return false;
			}
			return true;
		}));
		.forceFocus(_dirTree, false);
		refreshDirTree();
		itm = findDirTree(sub.path);
		_dirTree.setSelection([itm]);
		updateDirSel();
		_areaDirEdit.startEdit();
	}

	void edit() { mixin(S_TRACE);
		int index = _areas.getSelectionIndex();
		if (index == -1) return;
		if (cast(Summary)_areas.getItem(index).getData()) { mixin(S_TRACE);
			editSummary();
		} else { mixin(S_TRACE);
			openAreaScene(true);
		}
	}
	@property
	bool canEdit() { mixin(S_TRACE);
		return _areas.getSelectionIndex() != -1;
	}

	@property
	bool canReNumbering() { return !_readOnly && (showSummary ? 1 : 0) <= _areas.getSelectionIndex(); }
	void reNumberingAll() { mixin(S_TRACE);
		if (_readOnly) return;
		auto undo = new UndoIDs(this, _comm, _summ);
		bool reNum = false;
		reNum |= reNumberingAreaImpl(0, 1);
		reNum |= reNumberingBattleImpl(0, 1);
		reNum |= reNumberingPackageImpl(0, 1);
		if (reNum) _undo ~= undo;
	}
	void reNumberingArea(int index, ulong newId) { mixin(S_TRACE);
		if (_readOnly) return;
		auto undo = new UndoIDs(this, _comm, _summ);
		bool reNum = reNumberingAreaImpl(index, newId);
		if (reNum) _undo ~= undo;
	}
	void reNumberingBattle(int index, ulong newId) { mixin(S_TRACE);
		if (_readOnly) return;
		auto undo = new UndoIDs(this, _comm, _summ);
		bool reNum = reNumberingBattleImpl(index, newId);
		if (reNum) _undo ~= undo;
	}
	void reNumberingPackage(int index, ulong newId) { mixin(S_TRACE);
		if (_readOnly) return;
		auto undo = new UndoIDs(this, _comm, _summ);
		bool reNum = reNumberingPackageImpl(index, newId);
		if (reNum) _undo ~= undo;
	}
	private ulong[] reNumBef(A)(A[] arr, int index) { mixin(S_TRACE);
		ulong[] oldIDs;
		for (size_t i = index; i < arr.length; i++) { mixin(S_TRACE);
			oldIDs ~= arr[i].id;
			ulong ni = ulong.max - arr.length + i;
			_summ.useCounter.change(A.toID(arr[i].id), A.toID(ni));
			arr[i].id = ni;
		}
		return oldIDs;
	}
	private bool reNumberingImpl(A)(int index, ulong newId, A[] arr, ref bool[ulong] selections) { mixin(S_TRACE);
		if (_readOnly) return false;
		if (index < 0 || arr.length <= index) return false;
		if (newId == 0) return false;
		if (index > 0 && arr[index - 1].id >= newId) return false;
		auto oldIDs = reNumBef(arr, index);
		bool reNum = false;
		bool[ulong] selectionsB;
		for (size_t i = index; i < arr.length; i++) { mixin(S_TRACE);
			if (_prop.var.etc.saveTableViewSelection) { mixin(S_TRACE);
				if (auto p = arr[i].id in selections) { mixin(S_TRACE);
					if (*p) selectionsB[newId] = *p;
				}
			}
			_summ.useCounter.change(A.toID(arr[i].id), A.toID(newId));
			arr[i].id = newId;
			if (oldIDs[i - index] != newId) { mixin(S_TRACE);
				callRefArea(arr[i]);
				reNum = true;
			}
			newId++;
		}
		refreshIDs(false);
		selections = selectionsB;
		return reNum;
	}
	private bool reNumberingAreaImpl(int index, ulong newId) { mixin(S_TRACE);
		if (_readOnly) return false;
		return reNumberingImpl(index, newId, _summ.areas, _selectionsA);
	}
	private bool reNumberingBattleImpl(int index, ulong newId) { mixin(S_TRACE);
		if (_readOnly) return false;
		return reNumberingImpl(index, newId, _summ.battles, _selectionsB);
	}
	private bool reNumberingPackageImpl(int index, ulong newId) { mixin(S_TRACE);
		if (_readOnly) return false;
		return reNumberingImpl(index, newId, _summ.packages, _selectionsP);
	}
	void reNumbering() { mixin(S_TRACE);
		if (_readOnly) return;
		if (!_summ) return;
		ulong id;
		TypeInfo type;
		getSelectionInfo(id, type);
		if (id <= 0) return;
		int index = toIndexFrom(_summ, id, type);
		_incSearch.close();
		if (type is typeid(Area)) { mixin(S_TRACE);
			auto dlg = new ReNumDialog!(Area)(_prop, _areas.getShell(), _summ, _summ.areas[index],
				index == 0 ? 1 : _summ.areas[index - 1].id + 1);
			if (dlg.open()) { mixin(S_TRACE);
				_incSearch.close();
				reNumberingArea(index, dlg.newId);
			}
			_comm.refreshToolBar();
			return;
		}
		if (type is typeid(Battle)) { mixin(S_TRACE);
			auto dlg = new ReNumDialog!(Battle)(_prop, _areas.getShell(), _summ, _summ.battles[index],
				index == 0 ? 1 : _summ.battles[index - 1].id + 1);
			if (dlg.open()) { mixin(S_TRACE);
				_incSearch.close();
				reNumberingBattle(index, dlg.newId);
			}
			_comm.refreshToolBar();
			return;
		}
		if (type is typeid(Package)) { mixin(S_TRACE);
			auto dlg = new ReNumDialog!(Package)(_prop, _areas.getShell(), _summ, _summ.packages[index],
				index == 0 ? 1 : _summ.packages[index - 1].id + 1);
			if (dlg.open()) { mixin(S_TRACE);
				_incSearch.close();
				reNumberingPackage(index, dlg.newId);
			}
			_comm.refreshToolBar();
			return;
		}
	}

	private void editSummary() { mixin(S_TRACE);
		editSummary(_areas);
	}
	private SummaryDialog _summDlg = null;
	void editSummary(Composite parent) { mixin(S_TRACE);
		if (!_summ) return;
		if (_summDlg) { mixin(S_TRACE);
			_summDlg.active();
			return;
		}
		_summDlg = new SummaryDialog(_comm, _prop, parent.getShell(), _summ, _readOnly == SWT.READ_ONLY);
		_summDlg.applyEvent ~= { mixin(S_TRACE);
			storeEdit(0UL, null);
		};
		_summDlg.appliedEvent ~= { mixin(S_TRACE);
			if (showSummary) refresh();
			if (_areas && !_areas.isDisposed()) updateAreaImage();
		};
		_summDlg.closeEvent ~= { mixin(S_TRACE);
			_summDlg = null;
		};
		_summDlg.open();
	}

	@property
	Control table() { mixin(S_TRACE);
		return _areas;
	}
	@property
	Control panel() { mixin(S_TRACE);
		return _dirMode ? _areas.getParent().getParent() : _areas;
	}

	@property
	string statusLine() { return _statusLine; }

	void refresh() { mixin(S_TRACE);
		refreshAreas();
	}

	@property
	void summary(Summary summ) { mixin(S_TRACE);
		_summ = summ;
		_dirs = null;
		_selectionsA = null;
		_selectionsB = null;
		_selectionsP = null;
		_dir = "";
		constructDirTree(false);
		refreshAreas();
		_comm.refreshToolBar();
	}

	void cancelEdit() { mixin(S_TRACE);
		if (_areasEdit) _areasEdit.cancel();
		if (_areaDirEdit) _areaDirEdit.cancel();
	}

	private string createNewName(A)(string name, in A[] areas) { mixin(S_TRACE);
		if (!_prop.var.etc.incrementNewAreaName) return name;
		bool[string] names;
		foreach (a; areas) names[a.name.toLower()] = true;
		if (_dirMode) { mixin(S_TRACE);
			return .createNewName(name, (string name) { mixin(S_TRACE);
				return (_dir == "" ? name : _dir ~ "\\" ~ name).toLower() !in names;
			}, true);
		} else { mixin(S_TRACE);
			return .createNewName(name, (string name) { mixin(S_TRACE);
				return name.toLower() !in names;
			}, true);
		}
	}

	/// 新規エリアが作成され、名前の入力待ちになる。
	void createArea() { mixin(S_TRACE);
		if (_readOnly) return;
		ulong[] a, b, p;
		saveIDs(_summ, a, b, p);
		auto area = new Area(_summ.newAreaId, createNewName(_prop.msgs.areaNew, _summ.areas));
		if (_dirMode) area.dirName = _dir;
		auto bgImages = createBgImages(_comm.skin, _prop.var.etc.bgImagesDefault);
		foreach (bg; bgImages) { mixin(S_TRACE);
			area.append(bg);
		}
		auto tree = new EventTree(_prop.msgs.enterTree);
		tree.enter = true;
		area.add(tree);
		_summ.add(area);
		storeInsert(area.id, typeid(Area), a, b, p);
		int index = cast(int)_summ.areas.length - 1;
		addAreaItem(index);
		auto sel = selArea(index);
		sort();
		_areas.showSelection();
		_comm.refArea.call(area);
		if (sel) _areasEdit.startEdit();
		refreshStatusLine();
		_comm.refreshToolBar();
	}

	/// 新規バトルが作成され、名前の入力待ちになる。
	void createBattle() { mixin(S_TRACE);
		if (_readOnly) return;
		ulong[] a, b, p;
		saveIDs(_summ, a, b, p);
		auto btl = new Battle(_summ.newBattleId, createNewName(_prop.msgs.battleNew, _summ.battles), _comm.skin.defBattle(_summ.scenarioPath, _summ.dataVersion));
		if (_dirMode) btl.dirName = _dir;
		_summ.add(btl);
		storeInsert(btl.id, typeid(Battle), a, b, p);
		int index = cast(int)_summ.battles.length - 1;
		addBattleItem(index);
		auto sel = selBattle(index);
		sort();
		_areas.showSelection();
		_comm.refBattle.call(btl);
		if (sel) _areasEdit.startEdit();
		refreshStatusLine();
		_comm.refreshToolBar();
	}

	/// 新規パッケージが作成され、名前の入力待ちになる。
	void createPackage() { mixin(S_TRACE);
		if (_readOnly) return;
		createPackageImpl(null, null, "");
	}
	/// ditto
	ulong createPackage(EventTree baseTree, string name) { mixin(S_TRACE);
		return createPackageImpl(baseTree, null, name);
	}
	/// ditto
	ulong createPackage(Content baseStart, string name) { mixin(S_TRACE);
		return createPackageImpl(null, baseStart, name);
	}
	/// ditto
	private ulong createPackageImpl(EventTree baseTree, Content baseStart, string name) { mixin(S_TRACE);
		if (_readOnly) return 0UL;
		ulong[] a, b, p;
		saveIDs(_summ, a, b, p);
		auto pkg = new Package(_summ.newPackageId, createNewName(name && name != "" ? name : _prop.msgs.packageNew, _summ.packages));
		if (_dirMode) pkg.dirName = _dir;
		EventTree et;
		if (baseTree) { mixin(S_TRACE);
			et = baseTree.dup;
			et.name = _prop.msgs.packageTree;
		} else if (baseStart) { mixin(S_TRACE);
			et = new EventTree(baseStart);
			et.name = _prop.msgs.packageTree;
		} else { mixin(S_TRACE);
			et = new EventTree(_prop.msgs.packageTree);
		}
		pkg.add(et);
		_summ.add(pkg);
		storeInsert(pkg.id, typeid(Package), a, b, p);
		int index = cast(int)_summ.packages.length - 1;
		addPackageItem(index);
		auto sel = selPackage(index);
		sort();
		_areas.showSelection();
		_comm.refPackage.call(pkg);
		if (sel) _areasEdit.startEdit();
		refreshStatusLine();
		_comm.refreshToolBar();
		return pkg.id;
	}
	@property
	private bool selArea(int index) { mixin(S_TRACE);
		return select(_summ.areas[index]);
	}
	@property
	private bool selBattle(int index) { mixin(S_TRACE);
		return select(_summ.battles[index]);
	}
	@property
	private bool selPackage(int index) { mixin(S_TRACE);
		return select(_summ.packages[index]);
	}
	void selectSummary() { mixin(S_TRACE);
		if (!_summ) return;
		if (_dirMode) { mixin(S_TRACE);
			if (!showTreeSummary) return;
			_dirTree.setSelection([_dirTree.getItem(0)]);
		} else { mixin(S_TRACE);
			if (!showSummary) return;
			_areas.select(0);
			saveSelections();
		}
	}
	@property
	private bool showTreeSummary() {
		auto itm = _dirTree.getItem(0);
		return cast(Summary)itm.getData() !is null;
	}
	@property
	private TreeItem rootDir() {
		return _dirTree.getItem(showTreeSummary ? 1 : 0);
	}
	bool select(AbstractArea a) { mixin(S_TRACE);
		if (_dirMode) { mixin(S_TRACE);
			_dirTree.setSelection([findDirTree(a.dirName)]);
			updateDirSel();
		}
		int i = cast(int)cCountUntil!("a.getData() is b")(_areas.getItems(), a);
		if (0 <= i) { mixin(S_TRACE);
			_areas.select(i);
			_areas.showSelection();
			saveSelections();
			_comm.refreshToolBar();
			return true;
		}
		return false;
	}
	private void select(AbstractArea[] areas) { mixin(S_TRACE);
		if (!areas.length) return;
		select(areas[$-1]);
		foreach (a; areas) {
			int i = cast(int)cCountUntil!("a.getData() is b")(_areas.getItems(), a);
			if (0 <= i) { mixin(S_TRACE);
				_areas.select(i);
			}
		}
		saveSelections();
		_comm.refreshToolBar();
	}

	@property
	bool canOpenAreaScene() { mixin(S_TRACE);
		return (showSummary ? 1 : 0) <= _areas.getSelectionIndex();
	}
	@property
	bool canOpenAreaEvent() { mixin(S_TRACE);
		return (showSummary ? 1 : 0) <= _areas.getSelectionIndex();
	}
	void openAreaScene(bool shellActivate, bool canDuplicate = false) { mixin(S_TRACE);
		foreach (area; getSelectionAreas()) { mixin(S_TRACE);
			if (area) { mixin(S_TRACE);
				auto a = cast(Area)area;
				if (a) { mixin(S_TRACE);
					openAreaSceneImpl(a, shellActivate, canDuplicate);
				}
				auto b = cast(Battle)area;
				if (b) { mixin(S_TRACE);
					openAreaSceneImpl(b, shellActivate, canDuplicate);
				}
				auto p = cast(Package)area;
				if (p) { mixin(S_TRACE);
					_comm.openArea(_prop, _summ, p, shellActivate, canDuplicate);
				}
			}
		}
	}
	void openAreaScene(int x, int y, bool shellActivate, bool canDuplicate = false) { mixin(S_TRACE);
		auto itm = _areas.getItem(new Point(x, y));
		if (itm) { mixin(S_TRACE);
			_areas.setSelection([itm]);
			openAreaScene(cast(AbstractArea)itm.getData(), shellActivate, canDuplicate);
		} else { mixin(S_TRACE);
			openAreaScene(shellActivate, canDuplicate);
		}
	}
	void openAreaEvent(int x, int y, bool shellActivate, bool canDuplicate = false) { mixin(S_TRACE);
		auto itm = _areas.getItem(new Point(x, y));
		if (itm) { mixin(S_TRACE);
			_areas.setSelection([itm]);
			openAreaEvent(cast(AbstractArea)itm.getData(), shellActivate, canDuplicate);
		} else { mixin(S_TRACE);
			openAreaEvent(shellActivate, canDuplicate);
		}
	}
	void openAreaEvent(bool shellActivate, bool canDuplicate = false) { mixin(S_TRACE);
		foreach (area; getSelectionAreas()) { mixin(S_TRACE);
			openAreaEvent(area, shellActivate, canDuplicate);
		}
	}
	void openAreaScene(AbstractArea area, bool shellActivate, bool canDuplicate = false) { mixin(S_TRACE);
		auto a = cast(Area)area;
		if (a) { mixin(S_TRACE);
			openAreaSceneImpl(a, shellActivate, canDuplicate);
			return;
		}
		auto b = cast(Battle)area;
		if (b) { mixin(S_TRACE);
			openAreaSceneImpl(b, shellActivate, canDuplicate);
			return;
		}
		auto p = cast(Package)area;
		if (p) { mixin(S_TRACE);
			_comm.openArea(_prop, _summ, p, shellActivate, canDuplicate);
			return;
		}
	}
	void openAreaEvent(AbstractArea area, bool shellActivate, bool canDuplicate = false) { mixin(S_TRACE);
		auto a = cast(Area)area;
		if (a) { mixin(S_TRACE);
			openAreaEventImpl(a, shellActivate, canDuplicate);
			return;
		}
		auto b = cast(Battle)area;
		if (b) { mixin(S_TRACE);
			openAreaEventImpl(b, shellActivate, canDuplicate);
			return;
		}
		auto p = cast(Package)area;
		if (p) { mixin(S_TRACE);
			_comm.openArea(_prop, _summ, p, shellActivate, canDuplicate);
			return;
		}
	}

	void openAreaSceneImpl(A)(A a, bool shellActivate, bool canDuplicate) { mixin(S_TRACE);
		_comm.openAreaScene(_prop, _summ, a, shellActivate, canDuplicate);
	}
	void openAreaEventImpl(A)(A a, bool shellActivate, bool canDuplicate = false) { mixin(S_TRACE);
		_comm.openAreaEvent(_prop, _summ, a, shellActivate, canDuplicate);
	}
	void openAreaScene(ulong id, bool shellActivate, bool canDuplicate = false) { mixin(S_TRACE);
		openAreaSceneImpl(_summ.area(id), shellActivate, canDuplicate);
	}
	void openAreaEvent(ulong id, bool shellActivate, bool canDuplicate = false) { mixin(S_TRACE);
		openAreaEventImpl(_summ.area(id), shellActivate, canDuplicate);
	}
	void openBattleScene(ulong id, bool shellActivate, bool canDuplicate = false) { mixin(S_TRACE);
		openAreaSceneImpl(_summ.battle(id), shellActivate, canDuplicate);
	}
	void openBattleEvent(ulong id, bool shellActivate, bool canDuplicate = false) { mixin(S_TRACE);
		openAreaEventImpl(_summ.area(id), shellActivate, canDuplicate);
	}
	void openPackage(ulong id, bool shellActivate, bool canDuplicate = false) { mixin(S_TRACE);
		_comm.openArea(_prop, _summ, _summ.cwPackage(id), shellActivate, canDuplicate);
	}

	private bool canUdImpl(int index1, int index2) { mixin(S_TRACE);
		if (_readOnly) return false;
		if (!_summ) return false;
		if (_areas.getItemCount() != countAllAreas) return false;
		if (index1 < (showSummary ? 1 : 0) || _areas.getItemCount() <= index1) return false;
		if (index2 < (showSummary ? 1 : 0) || _areas.getItemCount() <= index2) return false;
		auto area1 = cast(AbstractArea)_areas.getItem(index1).getData();
		auto area2 = cast(AbstractArea)_areas.getItem(index2).getData();
		if (cast(Area)area1 && cast(Area)area2) { mixin(S_TRACE);
			return canUdImpl2!Area(area1, area2);
		}
		if (cast(Battle)area1 && cast(Battle)area2) { mixin(S_TRACE);
			return canUdImpl2!Battle(area1, area2);
		}
		if (cast(Package)area1 && cast(Package)area2) { mixin(S_TRACE);
			return canUdImpl2!Package(area1, area2);
		}
		return false;
	}
	private bool canUdImpl2(A)(AbstractArea area1, AbstractArea area2) { mixin(S_TRACE);
		if (_readOnly) return false;
		auto a1 = cast(A)area1;
		auto a2 = cast(A)area2;
		return a1 && a2;
	}
	private void udImpl(int index1, int index2) { mixin(S_TRACE);
		if (_readOnly) return;
		if (!canUdImpl(index1, index2)) return;
		auto area1 = cast(AbstractArea)_areas.getItem(index1).getData();
		auto area2 = cast(AbstractArea)_areas.getItem(index2).getData();
		if (cast(Area)area1 && cast(Area)area2) { mixin(S_TRACE);
			udImpl2!Area(area1, area2);
		}
		if (cast(Battle)area1 && cast(Battle)area2) { mixin(S_TRACE);
			udImpl2!Battle(area1, area2);
		}
		if (cast(Package)area1 && cast(Package)area2) { mixin(S_TRACE);
			udImpl2!Package(area1, area2);
		}
		_comm.refreshToolBar();
	}
	private int listIndexOf(AbstractArea area) { mixin(S_TRACE);
		foreach (i, itm; _areas.getItems()) { mixin(S_TRACE);
			if (itm.getData() is area) return cast(int)i;
		}
		return -1;
	}
	private void udImpl2(A)(AbstractArea area1, AbstractArea area2) { mixin(S_TRACE);
		if (_readOnly) return;
		assert (_areas.getSortColumn() is null || _areas.getSortColumn() is _idSorter.column);
		auto a1 = cast(A)area1;
		auto a2 = cast(A)area2;
		if (!a1 || !a2) return;
		int i1 = cast(int)_summ.indexOf(a1);
		int i2 = cast(int)_summ.indexOf(a2);
		if (_dirMode) { mixin(S_TRACE);
			// 見かけ上の位置が動くまで続ける
			int li1 = listIndexOf(a1);
			static if (is(A:Area)) {
				auto array = _summ.areas;
			} else static if (is(A:Battle)) {
				auto array = _summ.battles;
			} else static if (is(A:Package)) {
				auto array = _summ.packages;
			} else static assert (0);
			int lastIndex = indexOf(a1);
			ATUndo[] undos;
			do { mixin(S_TRACE);
				undos ~= new UndoSwap(this, _comm, _summ, indexFrom!A(_summ, i1), indexFrom!A(_summ, i2));
				if (i1 < i2) { mixin(S_TRACE);
					_areas.downItem(li1);
					li1++;
				} else { mixin(S_TRACE);
					_areas.upItem(li1);
					li1--;
				}
				a2 = array[i2];
				_summ.swap!A(i1, i2);
				int mv = i2 - i1;
				i1 += mv;
				i2 += mv;
			} while (0 != icmp(a1.dirName, a2.dirName));
			_undo ~= new ATUndoArr(undos);
		} else { mixin(S_TRACE);
			auto index1 = indexFrom!A(_summ, i1);
			auto index2 = indexFrom!A(_summ, i2);
			storeSwap(index1, index2);
			if (showSummary) { mixin(S_TRACE);
				index1++;
				index2++;
			}
			if (i1 < i2) { mixin(S_TRACE);
				_areas.downItem(index1);
			} else { mixin(S_TRACE);
				_areas.upItem(index1);
			}
			_summ.swap!A(i1, i2);
		}
		int m = showSummary ? 1 : 0;
		select(a1);
		_areas.showSelection();
		saveSelections();
		_areas.redraw();
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
	bool canUp() { mixin(S_TRACE);
		if (_readOnly) return false;
		if (!_summ) return false;
		if (_areas.getItemCount() != countAllAreas) return false;
		if (!(_areas.getSortColumn() is null || _areas.getSortColumn() is _idSorter.column)) return false;
		if (_lastFocus !is _areas) return false;
		int sel = _areas.getSelectionIndex();
		if (sel < (showSummary ? 1 : 0)) return false;
		return canUdImpl(sel, sel - 1);
	}
	@property
	bool canDown() { mixin(S_TRACE);
		if (_readOnly) return false;
		if (!_summ) return false;
		if (_areas.getItemCount() != countAllAreas) return false;
		if (!(_areas.getSortColumn() is null || _areas.getSortColumn() is _idSorter.column)) return false;
		if (_lastFocus !is _areas) return false;
		int sel = _areas.getSelectionIndex();
		if (sel < (showSummary ? 1 : 0)) return false;
		return canUdImpl(sel, sel + 1);
	}
	void up() { mixin(S_TRACE);
		if (_readOnly) return;
		_parent.setRedraw(false);
		scope (exit) _parent.setRedraw(true);
		if (!canUp) return;
		if (_lastFocus !is _areas) return;
		if (_areaDirEdit) _areaDirEdit.cancel();
		_areasEdit.cancel();
		int sel = _areas.getSelectionIndex();
		if (sel < (showSummary ? 1 : 0)) return;
		udImpl(sel, sel - 1);
	}
	void down() { mixin(S_TRACE);
		if (_readOnly) return;
		_parent.setRedraw(false);
		scope (exit) _parent.setRedraw(true);
		if (!canDown) return;
		if (_lastFocus !is _areas) return;
		if (_areaDirEdit) _areaDirEdit.cancel();
		_areasEdit.cancel();
		int sel = _areas.getSelectionIndex();
		if (sel < (showSummary ? 1 : 0)) return;
		udImpl(sel, sel + 1);
	}

	@property
	bool canSetStartArea() {
		if (_readOnly) return false;
		if (auto a = cast(Area)getSelectionArea()) {
			return _summ.startArea != a.id;
		}
		return false;
	}
	void setStartArea() {
		if (_readOnly) return;
		if (auto a = cast(Area)getSelectionArea()) {
			storeEdit(0UL, null);
			_summ.startArea = a.id;
			updateAreaImage();
			refreshUseCount();
			_comm.refreshToolBar();
		}
	}

	@property
	private AbstractArea[] dirAreas() { mixin(S_TRACE);
		AbstractArea[] areas;
		auto path = _dir == "" ? _dir : _dir ~ "\\";
		void put(AbstractArea area) { mixin(S_TRACE);
			if (istartsWith(area.name, path)) { mixin(S_TRACE);
				areas ~= area;
			}
		}
		foreach (a; _summ.areas) put(a);
		foreach (a; _summ.battles) put(a);
		foreach (a; _summ.packages) put(a);
		return areas;
	}

	private string getScenarioPath(in XNode node) { mixin(S_TRACE);
		auto sPath = node.attr("scenarioPath", false);
		return sPath == "" ? "" : .nabs(sPath);
	}
	bool qAreasMaterialCopy(in XNode node, AbstractArea[] as) { mixin(S_TRACE);
		auto fromSPath = getScenarioPath(node);
		auto fromSName = node.attr("scenarioName", false);
		auto fromSAuthor = node.attr("scenarioAuthor", false);
		if (fromSPath.length > 0 && !cfnmatch(fromSPath, .nabs(_summ.scenarioPath))) { mixin(S_TRACE);
			auto uc = new UseCounter(null);
			foreach (a; as) { mixin(S_TRACE);
				a.setUseCounter(uc);
			}
			bool copy;
			bool r = qMaterialCopy(_comm, _areas.getShell(), uc, _summ.scenarioPath, fromSPath, copy, _summ.legacy,
				(in PathUser v) { mixin(S_TRACE);
					return .pathUserToExportedImageName(_prop.parent, fromSName, fromSAuthor, v);
				});
			foreach (a; as) { mixin(S_TRACE);
				a.removeUseCounter();
			}
			if (copy) { mixin(S_TRACE);
				_comm.refPaths.call(_comm.skin.materialPath);
			}
			return r;
		}
		return true;
	}

	override {
		void cut(SelectionEvent se) { mixin(S_TRACE);
			if (_dirTree && _lastFocus is _dirTree) { mixin(S_TRACE);
				if (_dir == "") return;
			}
			_parent.setRedraw(false);
			scope (exit) _parent.setRedraw(true);
			copy(se);
			del(se);
		}
		void copy(SelectionEvent se) { mixin(S_TRACE);
			_parent.setRedraw(false);
			scope (exit) _parent.setRedraw(true);
			if (_dirTree && _lastFocus is _dirTree) { mixin(S_TRACE);
				auto path = _dir == "" ? _dir : _dir ~ "\\";
				auto areas = dirAreas;
				XNode doc;
				string parentPath = _dir == "" ? _prop.msgs.areaDirRoot : _dir.split("\\")[$ - 1];
				if (areas.length) { mixin(S_TRACE);
					doc = areasToNode(parentPath, _dir, areas, new XMLOption(_prop.sys, LATEST_VERSION), _summ);
				} else { mixin(S_TRACE);
					doc = XNode.create("Table");
					doc.newAttr("scenarioPath", .nabs(_summ.scenarioPath));
					doc.newAttr("scenarioName", _summ.scenarioName);
					doc.newAttr("scenarioAuthor", _summ.author);
				}
				// フォルダ構造を転送
				auto parent = cast(DirTree)findDirTree(_dir).getData();
				void recurse(DirTree dir) { mixin(S_TRACE);
					auto p = dir.path;
					if (0 == icmp(p, _dir)) { mixin(S_TRACE);
						doc.newElement("TablePath", parentPath);
					} else { mixin(S_TRACE);
						doc.newElement("TablePath", parentPath ~ "\\" ~ p[path.length .. $]);
					}
					foreach (sub; dir.subDirs) recurse(sub);
				}
				recurse(parent);
				XMLtoCB(_prop, _comm.clipboard, doc.text);
				_comm.refreshToolBar();
			} else { mixin(S_TRACE);
				auto areas = getSelectionAreas();
				if (areas.length) { mixin(S_TRACE);
					auto doc = areasToNode("", _dir, areas, new XMLOption(_prop.sys, LATEST_VERSION), _summ);
					XMLtoCB(_prop, _comm.clipboard, doc.text);
					_comm.refreshToolBar();
				}
			}
		}
		void paste(SelectionEvent se) { mixin(S_TRACE);
			_parent.setRedraw(false);
			scope (exit) _parent.setRedraw(true);
			auto c = CBtoXML(_comm.clipboard);
			if (c) { mixin(S_TRACE);
				try { mixin(S_TRACE);
					auto node = XNode.parse(c);
					pasteImpl(node);
				} catch (Exception e) { mixin(S_TRACE);
					printStackTrace();
					debugln(e);
				}
			}
		}
		void del(SelectionEvent se) { mixin(S_TRACE);
			_parent.setRedraw(false);
			scope (exit) _parent.setRedraw(true);
			AbstractArea[] areas;
			if (_dirTree && _lastFocus is _dirTree) {
				if (_dir == "") return;
				auto path = _dir ~ "\\";
				void put(AbstractArea area) { mixin(S_TRACE);
					if (istartsWith(area.name, path)) { mixin(S_TRACE);
						areas ~= area;
					}
				}
				foreach (a; _summ.areas) put(a);
				foreach (a; _summ.battles) put(a);
				foreach (a; _summ.packages) put(a);
			} else {
				areas = getSelectionAreas();
			}
			ATUndo[] undos;
			foreach (area; areas) { mixin(S_TRACE);
				ulong id;
				TypeInfo type;
				getInfoFromArea(area, id, type);
				undos ~= new UndoInsertDelete(this, _comm, _summ, id, type, false, [], [], []);
				_summ.remove(area);
				if (cast(Area)area) { mixin(S_TRACE);
					_comm.delArea.call(cast(Area)area);
				} else if (cast(Battle)area) { mixin(S_TRACE);
					_comm.delBattle.call(cast(Battle)area);
				} else { mixin(S_TRACE);
					assert (cast(Package)area);
					_comm.delPackage.call(cast(Package)area);
				}
			}
			if (!undos.length) storeEmpty();
			if (_dirTree && _lastFocus is _dirTree) { mixin(S_TRACE);
				auto itm = findDirTree(_dir).getParentItem();
				delDirTree(_dir);
				_dirTree.setSelection([itm]);
				updateDirSel();
			}
			if (undos.length) { mixin(S_TRACE);
				refreshAreas();
				saveSelections();
				if (_flags) _flags.refresh();
				_comm.refUseCount.call();
				refreshStatusLine();
				_comm.refreshToolBar();
				_undo ~= new ATUndoArr(undos);
			}
		}
		void clone(SelectionEvent se) { mixin(S_TRACE);
			_parent.setRedraw(false);
			scope (exit) _parent.setRedraw(true);
			_comm.clipboard.memoryMode = true;
			scope (exit) _comm.clipboard.memoryMode = false;
			copy(se);
			if (_dirTree && _lastFocus is _dirTree) { mixin(S_TRACE);
				// 同じ階層にコピーするため、一つ上のディレクトリを選択
				auto sels = _dirTree.getSelection();
				assert (sels.length);
				auto itm = sels[0].getParentItem();
				if (itm) {
					_dirTree.setSelection([itm]);
					_dir = (cast(DirTree)itm.getData()).path;
				}
			}
			paste(se);
		}
		@property
		bool canDoTCPD() { mixin(S_TRACE);
			return _summ && (_lastFocus is _areas || (_dirTree && _lastFocus is _dirTree));
		}
		@property
		bool canDoT() { mixin(S_TRACE);
			return !_readOnly && canDoC && canDoD;
		}
		@property
		bool canDoC() { mixin(S_TRACE);
			if (_dirTree && _lastFocus is _dirTree) { mixin(S_TRACE);
				auto sels = _dirTree.getSelection();
				return sels.length && cast(DirTree)sels[0].getData();
			} else { mixin(S_TRACE);
				return (showSummary ? 1 : 0) <= _areas.getSelectionIndex();
			}
		}
		@property
		bool canDoP() { mixin(S_TRACE);
			return !_readOnly && _summ !is null && CBisXML(_comm.clipboard);
		}
		@property
		bool canDoClone() { mixin(S_TRACE);
			return !_readOnly && canDoC;
		}
		@property
		bool canDoD() { mixin(S_TRACE);
			if (_readOnly) return false;
			if (_dirTree && _lastFocus is _dirTree) { mixin(S_TRACE);
				auto sels = _dirTree.getSelection();
				if (!sels.length) return false;
				auto dir = cast(DirTree)sels[0].getData();
				return dir && dir.parent !is null;
			} else { mixin(S_TRACE);
				return (showSummary ? 1 : 0) <= _areas.getSelectionIndex();
			}
		}
	}
	private void pasteImpl(ref XNode node) { mixin(S_TRACE);
		if (_readOnly) return;
		_parent.setRedraw(false);
		scope (exit) _parent.setRedraw(true);
		bool sameSummary;
		auto ver = new XMLInfo(_prop.sys, LATEST_VERSION);
		bool fromTable;
		auto areas = createAreasFromNode(node, _summ.scenarioPath, sameSummary, fromTable, ver);
		if (!qAreasMaterialCopy(node, areas)) return;
		ATUndo[] undos;
		AbstractArea sel = null;
		auto existsDirs = new HashSet!string;
		void eRecurse(DirTree dir) { mixin(S_TRACE);
			existsDirs.add(dir.path.toLower());
			foreach (sub; dir.subDirs) eRecurse(sub);
		}
		if (_dirMode) eRecurse(_dirs);

		string renameDir(string dir) { mixin(S_TRACE);
			if (dir == "") return dir;
			// すでに存在するフォルダであれば(2)等をつける
			auto dirs = dir.split("\\");
			auto firstDir = dirs[0];
			firstDir = .createNewName(firstDir, (s) { mixin(S_TRACE);
				if (_dir != "") s = _dir ~ "\\" ~ s;
				return !existsDirs.contains(s.toLower());
			});
			return ([firstDir] ~ dirs[1..$]).join("\\");
		}
		string lastPutDir = "";
		if (_dirMode) {
			auto curItm = findDirTree(_dir);
			auto curDir = cast(DirTree)curItm.getData();
			node.onTag["TablePath"] = (ref XNode node) { mixin(S_TRACE);
				auto dir = renameDir(node.value);
				if (dir == "") return;
				if (!undos.length) undos ~= new UndoIDs(this, _comm, _summ);
				lastPutDir = putDir(curDir, dir);
			};
			node.parse();
		}

		bool[string] areaNames;
		bool[string] battleNames;
		bool[string] packageNames;
		foreach (a; _summ.areas) areaNames[a.name.toLower()] = true;
		foreach (a; _summ.battles) battleNames[a.name.toLower()] = true;
		foreach (a; _summ.packages) packageNames[a.name.toLower()] = true;
		foreach (area; areas) { mixin(S_TRACE);
			sel = area;
			if (_dirMode) { mixin(S_TRACE);
				if (fromTable) { mixin(S_TRACE);
					// フォルダ構造をそのまま貼り付け
					area.dirName = renameDir(area.dirName);
					if (_dir != "") { mixin(S_TRACE);
						area.name = _dir ~ "\\" ~ area.name;
					}
				} else { mixin(S_TRACE);
					area.dirName = _dir;
				}
			}
			auto oldId = area.id;
			ulong[] a, b, p;
			saveIDs(_summ, a, b, p);
			if (cast(Area)area) { mixin(S_TRACE);
				if (_prop.var.etc.incrementNewAreaName) { mixin(S_TRACE);
					area.baseName = .createNewName(area.baseName, name => (area.dirName == "" ? name : area.dirName ~ "\\" ~ name).toLower() !in areaNames);
					areaNames[area.baseName] = true;
				}
				_summ.add(cast(Area)area);
				undos ~= new UndoInsertDelete(this, _comm, _summ, area.id, typeid(Area), true, a, b, p);
				_comm.refArea.call(cast(Area)area);
				if (sameSummary && !_summ.hasAreaId(oldId)) { mixin(S_TRACE);
					_summ.useCounter.change(toAreaId(oldId), toAreaId(area.id));
				}
			} else if (cast(Battle)area) { mixin(S_TRACE);
				if (_prop.var.etc.incrementNewAreaName) { mixin(S_TRACE);
					area.baseName = .createNewName(area.baseName, name => (area.dirName == "" ? name : area.dirName ~ "\\" ~ name).toLower() !in battleNames);
					battleNames[area.baseName] = true;
				}
				_summ.add(cast(Battle)area);
				undos ~= new UndoInsertDelete(this, _comm, _summ, area.id, typeid(Battle), true, a, b, p);
				_comm.refBattle.call(cast(Battle)area);
				if (sameSummary && !_summ.hasBattleId(oldId)) { mixin(S_TRACE);
					_summ.useCounter.change(toBattleId(oldId), toBattleId(area.id));
				}
			} else if (cast(Package)area) { mixin(S_TRACE);
				if (_prop.var.etc.incrementNewAreaName) { mixin(S_TRACE);
					area.baseName = .createNewName(area.baseName, name => (area.dirName == "" ? name : area.dirName ~ "\\" ~ name).toLower() !in packageNames);
					packageNames[area.baseName] = true;
				}
				_summ.add(cast(Package)area);
				undos ~= new UndoInsertDelete(this, _comm, _summ, area.id, typeid(Package), true, a, b, p);
				_comm.refPackage.call(cast(Package)area);
				if (sameSummary && !_summ.hasPackageId(oldId)) { mixin(S_TRACE);
					_summ.useCounter.change(toPackageId(oldId), toPackageId(area.id));
				}
			} else assert (0);
		}
		if (lastPutDir != "" || sel) { mixin(S_TRACE);
			if (_dirMode) {
				constructDirTree(true);
			}
			refreshAreas();
		}
		if (sel) { mixin(S_TRACE);
			sort();
			if (_readOnly) { mixin(S_TRACE);
				select(areas);
			} else { mixin(S_TRACE);
				select(sel);
			}
			if (_flags) _flags.refresh();
			_comm.refUseCount.call();
			refreshStatusLine();
			_comm.refreshToolBar();
			_undo ~= new ATUndoArr(undos);
		}
		if (_dirMode && !sel && lastPutDir != "") {
			_dirTree.setSelection([findDirTree(lastPutDir)]);
			updateDirSel();
		}
		saveSelections();
	}
	private void delItem(in AbstractArea area) { mixin(S_TRACE);
		if (_readOnly) return;
		foreach (itm; _areas.getItems()) { mixin(S_TRACE);
			if (itm.getData() is area) { mixin(S_TRACE);
				itm.dispose();
				break;
			}
		}
	}

	/// 外部からareasを追加する。
	/// 既存のエリアとIDが重複してはいけない。
	void addAreas(AbstractArea[] areas) {
		if (_readOnly) return;
		_parent.setRedraw(false);
		scope (exit) _parent.setRedraw(true);
		ATUndo[] undos;
		AbstractArea sel = null;

		foreach (area; areas) { mixin(S_TRACE);
			sel = area;
			ulong[] a, b, p;
			saveIDs(_summ, a, b, p);
			if (cast(Area)area) { mixin(S_TRACE);
				_summ.add(cast(Area)area);
				undos ~= new UndoInsertDelete(this, _comm, _summ, area.id, typeid(Area), true, a, b, p);
				_comm.refArea.call(cast(Area)area);
			} else if (cast(Battle)area) { mixin(S_TRACE);
				_summ.add(cast(Battle)area);
				undos ~= new UndoInsertDelete(this, _comm, _summ, area.id, typeid(Battle), true, a, b, p);
				_comm.refBattle.call(cast(Battle)area);
			} else if (cast(Package)area) { mixin(S_TRACE);
				_summ.add(cast(Package)area);
				undos ~= new UndoInsertDelete(this, _comm, _summ, area.id, typeid(Package), true, a, b, p);
				_comm.refPackage.call(cast(Package)area);
			} else assert (0);
		}
		if (sel) { mixin(S_TRACE);
			if (_dirMode) {
				constructDirTree(true);
			}
			refreshAreas();
		}
		if (sel) { mixin(S_TRACE);
			sort();
			select(sel);
			if (_flags) _flags.refresh();
			_comm.refUseCount.call();
			refreshStatusLine();
			_comm.refreshToolBar();
			_undo ~= new ATUndoArr(undos);
			saveSelections();
		}
	}

	@property
	bool canUndo() { mixin(S_TRACE);
		return !_readOnly && _undo.canUndo();
	}
	@property
	bool canRedo() { mixin(S_TRACE);
		return !_readOnly && _undo.canRedo();
	}
	void undo() { mixin(S_TRACE);
		if (_readOnly) return;
		cancelEdit();
		_undo.undo();
		_comm.refreshToolBar();
	}
	void redo() { mixin(S_TRACE);
		if (_readOnly) return;
		cancelEdit();
		_undo.redo();
		_comm.refreshToolBar();
	}

	void replaceID() { mixin(S_TRACE);
		if (_readOnly) return;
		auto area = getSelectionArea();
		if (cast(Area)area) _comm.replaceID(toAreaId(area.id), true);
		if (cast(Battle)area) _comm.replaceID(toBattleId(area.id), true);
		if (cast(Package)area) _comm.replaceID(toPackageId(area.id), true);
	}
	@property
	bool canReplaceID() { mixin(S_TRACE);
		if (_readOnly) return false;
		auto area = getSelectionArea();
		return cast(Area)area || cast(Battle)area || cast(Package)area;
	}

	void doImport() { mixin(S_TRACE);
		AbstractArea[] areas;
		string[] paths;
		if (_dirTree && _lastFocus is _dirTree) { mixin(S_TRACE);
			areas = dirAreas;
		} else { mixin(S_TRACE);
			areas = getSelectionAreas();
		}
		if (!areas.length) return;
		foreach (area; areas) { mixin(S_TRACE);
			paths ~= area.cwxPath(true);
		}
		_comm.doImport(_importTarget, _summ, paths);
	}
	@property
	bool canDoImport() { mixin(S_TRACE);
		if (_dirTree && _lastFocus is _dirTree) { mixin(S_TRACE);
			return _importTarget && dirAreas.length;
		} else { mixin(S_TRACE);
			return _importTarget && getSelectionAreas().length;
		}
	}

	@property
	bool isSelected() { return _areas.getSelectionIndex() != -1; }

	void selectAll() { mixin(S_TRACE);
		if (!canSelectAll) return;
		_areas.setSelection(0.iota(_areas.getItemCount()).array());
	}

	@property
	bool canSelectAll() { mixin(S_TRACE);
		return (_areas.getStyle() | SWT.MULTI) && _areas.getItemCount() && _areas.getItemCount() != _areas.getSelectionCount();
	}

	@property
	string[] openedCWXPath() { mixin(S_TRACE);
		string[] r;
		if (_summ && showSummary && 0 == _areas.getSelectionIndex()) { mixin(S_TRACE);
			r ~= _summ.cwxPath(true);
		}
		foreach (area; getSelectionAreas()) {
			r ~= cpaddattr(area.cwxPath(true), "shallow");
		}
		return r;
	}
}
