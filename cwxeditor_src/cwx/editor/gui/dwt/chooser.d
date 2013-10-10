
module cwx.editor.gui.dwt.chooser;

import cwx.utils;
import cwx.types;
import cwx.summary;
import cwx.flag;
import cwx.path;
import cwx.area;
import cwx.card;
import cwx.usecounter;

import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.incsearch;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dprops;

import std.algorithm;
import std.array;
import std.conv;
import std.string;
import std.typecons : Tuple;

import org.eclipse.swt.all;

import java.lang.all;

enum CouponComboType {
	AllCoupons, /// 全てのクーポンを選択肢とする。
	Talker, /// 話者用のクーポンを選択肢とする。
	Cast, /// キャストの経歴用のクーポンを選択肢とする。
}
T createCouponCombo(T = Combo)(Commons comm, Summary summ, Composite parent, bool delegate() catchMod, CouponComboType type) { mixin(S_TRACE);
	TextMenuModify tmm;
	return createCouponCombo!T(comm, summ, parent, catchMod, type, tmm);
}
T createCouponCombo(T = Combo)(Commons comm, Summary summ, Composite parent, bool delegate() catchMod, CouponComboType type, out TextMenuModify tmm) { mixin(S_TRACE);
	auto combo = new T(parent, SWT.BORDER | SWT.DROP_DOWN);
	combo.setVisibleItemCount(comm.prop.var.etc.comboVisibleItemCount);
	auto incSearch = new IncSearch(comm, combo);

	void refreshCoupons() { mixin(S_TRACE);
		string id = combo.getText();
		combo.removeAll();

		foreach (coupon; allCoupons(comm, summ, type)) { mixin(S_TRACE);
			if (!incSearch.match(coupon)) continue;
			combo.add(coupon);
		}
		combo.setText(id);
	}

	incSearch.modEvent ~= &refreshCoupons;
	comm.refSkin.add(&refreshCoupons);
	comm.refCoupons.add(&refreshCoupons);
	.listener(combo, SWT.Dispose, { mixin(S_TRACE);
		comm.refSkin.remove(&refreshCoupons);
		comm.refCoupons.remove(&refreshCoupons);
	});

	auto menu = new Menu(combo.getShell(), SWT.POP_UP);
	createMenuItem(comm, menu, MenuID.IncSearch, { mixin(S_TRACE);
		.forceFocus(combo, true);
		incSearch.startIncSearch();
	}, null);
	new MenuItem(menu, SWT.SEPARATOR);
	combo.setMenu(menu);
	tmm = createTextMenu!T(comm, comm.prop, combo, catchMod);

	refreshCoupons();

	return combo;
}

string[] allCoupons(Commons comm, Summary summ, CouponComboType type) {
	string[] cs;
	if (type !is CouponComboType.Cast) { mixin(S_TRACE);
		cs = castCoupons(comm, type is CouponComboType.Talker, comm.skin.legacyName);
	}

	string[] dcs;
	if (comm.prop.var.etc.usedCouponToCombo) { mixin(S_TRACE);
		bool delegate(CouponId a, CouponId b) cmps;
		if (comm.prop.var.etc.logicalSort) { mixin(S_TRACE);
			cmps = (a, b) => incmp(cast(string)a, cast(string)b) < 0;
		} else { mixin(S_TRACE);
			cmps = (a, b) => icmp(cast(string)a, cast(string)b) < 0;
		}
		foreach (coupon; .sortDlg(summ.useCounter.coupon.keys, cmps)) { mixin(S_TRACE);
			if (!.contains(cs, coupon.id)) dcs ~= coupon;
		}
	}
	if (comm.prop.var.etc.useNamesAfterStandard) { mixin(S_TRACE);
		if (dcs.length && cs.length) { mixin(S_TRACE);
			cs ~= "";
		}
		dcs = cs ~ dcs;
	} else { mixin(S_TRACE);
		if (dcs.length && cs.length) { mixin(S_TRACE);
			dcs ~= "";
		}
		dcs ~= cs;
	}
	return dcs;
}

T createGossipCombo(T = Combo)(Commons comm, Summary summ, Composite parent, bool delegate() catchMod) { mixin(S_TRACE);
	auto combo = new T(parent, SWT.BORDER | SWT.DROP_DOWN);
	combo.setVisibleItemCount(comm.prop.var.etc.comboVisibleItemCount);
	auto incSearch = new IncSearch(comm, combo);

	void refGossip() { mixin(S_TRACE);
		string id = combo.getText();
		combo.removeAll();

		foreach (gossip; allGossips(comm, summ)) { mixin(S_TRACE);
			if (!incSearch.match(gossip)) continue;
			combo.add(gossip);
		}
		combo.setText(id);
	}

	incSearch.modEvent ~= &refGossip;
	comm.refGossips.add(&refGossip);
	.listener(combo, SWT.Dispose, { mixin(S_TRACE);
		comm.refGossips.remove(&refGossip);
	});

	auto menu = new Menu(combo.getShell(), SWT.POP_UP);
	createMenuItem(comm, menu, MenuID.IncSearch, { mixin(S_TRACE);
		.forceFocus(combo, true);
		incSearch.startIncSearch();
	}, null);
	new MenuItem(menu, SWT.SEPARATOR);
	combo.setMenu(menu);
	createTextMenu!T(comm, comm.prop, combo, catchMod);

	refGossip();

	return combo;
}

string[] allGossips(Commons comm, Summary summ) {
	string[] cs;

	bool delegate(GossipId a, GossipId b) cmps;
	if (comm.prop.var.etc.logicalSort) { mixin(S_TRACE);
		cmps = (a, b) => incmp(cast(string)a, cast(string)b) < 0;
	} else { mixin(S_TRACE);
		cmps = (a, b) => icmp(cast(string)a, cast(string)b) < 0;
	}
	foreach (gossip; .sortDlg(summ.useCounter.gossip.keys, cmps)) { mixin(S_TRACE);
		cs ~= gossip;
	}
	return cs;
}

T createCompleteStampCombo(T = Combo)(Commons comm, Summary summ, Composite parent, bool delegate() catchMod) { mixin(S_TRACE);
	auto combo = new T(parent, SWT.BORDER | SWT.DROP_DOWN);
	combo.setVisibleItemCount(comm.prop.var.etc.comboVisibleItemCount);
	auto incSearch = new IncSearch(comm, combo);

	void refCompleteStamp() { mixin(S_TRACE);
		string id = combo.getText();
		combo.removeAll();

		foreach (stamp; allCompleteStamps(comm, summ)) { mixin(S_TRACE);
			if (!incSearch.match(stamp)) continue;
			combo.add(stamp);
		}
		combo.setText(id);
	}

	incSearch.modEvent ~= &refCompleteStamp;
	comm.refCompleteStamps.add(&refCompleteStamp);
	.listener(combo, SWT.Dispose, { mixin(S_TRACE);
		comm.refCompleteStamps.remove(&refCompleteStamp);
	});

	auto menu = new Menu(combo.getShell(), SWT.POP_UP);
	createMenuItem(comm, menu, MenuID.IncSearch, { mixin(S_TRACE);
		.forceFocus(combo, true);
		incSearch.startIncSearch();
	}, null);
	new MenuItem(menu, SWT.SEPARATOR);
	combo.setMenu(menu);
	createTextMenu!T(comm, comm.prop, combo, catchMod);

	refCompleteStamp();

	return combo;
}

string[] allCompleteStamps(Commons comm, Summary summ) {
	string[] cs;

	bool delegate(CompleteStampId a, CompleteStampId b) cmps;
	if (comm.prop.var.etc.logicalSort) { mixin(S_TRACE);
		cmps = (a, b) => incmp(cast(string)a, cast(string)b) < 0;
	} else { mixin(S_TRACE);
		cmps = (a, b) => icmp(cast(string)a, cast(string)b) < 0;
	}
	foreach (compStamp; .sortDlg(summ.useCounter.completeStamp.keys, cmps)) { mixin(S_TRACE);
		cs ~= compStamp;
	}
	return cs;
}

T createKeyCodeCombo(T = Combo)(Commons comm, Summary summ, Composite parent, bool delegate() catchMod) { mixin(S_TRACE);
	auto combo = new T(parent, SWT.BORDER | SWT.DROP_DOWN);
	combo.setVisibleItemCount(comm.prop.var.etc.comboVisibleItemCount);
	auto incSearch = new IncSearch(comm, combo);

	void refStandardKeyCodes() { mixin(S_TRACE);
		string id = combo.getText();
		combo.removeAll();

		string[] stdKCs = comm.prop.var.etc.standardKeyCodes.dup;

		auto kcs = summ.useCounter.keyCode.keys;
		string[] kcs2;
		foreach (string kc; kcs.sort) { mixin(S_TRACE);
			if (!.contains(stdKCs, kc)) { mixin(S_TRACE);
				kcs2 ~= kc;
			}
		}

		if (comm.prop.var.etc.useNamesAfterStandard) { mixin(S_TRACE);
			if (kcs2.length && stdKCs.length) { mixin(S_TRACE);
				stdKCs ~= "";
			}
			kcs2 = stdKCs ~ kcs2;
		} else { mixin(S_TRACE);
			if (kcs2.length) { mixin(S_TRACE);
				kcs2 ~= "";
			}
			kcs2 ~= stdKCs;
		}
		foreach (kc; kcs2) { mixin(S_TRACE);
			if (!incSearch.match(kc)) continue;
			combo.add(kc);
		}
		combo.setText(id);
	}

	incSearch.modEvent ~= &refStandardKeyCodes;
	comm.refStandardKeyCodes.add(&refStandardKeyCodes);
	comm.refKeyCodes.add(&refStandardKeyCodes);
	.listener(combo, SWT.Dispose, { mixin(S_TRACE);
		comm.refStandardKeyCodes.remove(&refStandardKeyCodes);
		comm.refKeyCodes.remove(&refStandardKeyCodes);
	});

	auto menu = new Menu(combo.getShell(), SWT.POP_UP);
	createMenuItem(comm, menu, MenuID.IncSearch, { mixin(S_TRACE);
		.forceFocus(combo, true);
		incSearch.startIncSearch();
	}, null);
	new MenuItem(menu, SWT.SEPARATOR);
	combo.setMenu(menu);
	createTextMenu!T(comm, comm.prop, combo, catchMod);

	refStandardKeyCodes();

	return combo;
}

string[] allKeyCodes(Commons comm, Summary summ) {
	string[] stdKCs = comm.prop.var.etc.standardKeyCodes.dup;

	bool delegate(KeyCodeId a, KeyCodeId b) cmps;
	if (comm.prop.var.etc.logicalSort) {
		cmps = (a, b) => incmp(cast(string)a, cast(string)b) < 0;
	} else {
		cmps = (a, b) => icmp(cast(string)a, cast(string)b) < 0;
	}
	auto kcs = summ.useCounter.keyCode.keys;
	string[] kcs2;
	foreach (string kc; .sortDlg(kcs, cmps)) { mixin(S_TRACE);
		if (!.contains(stdKCs, kc)) { mixin(S_TRACE);
			kcs2 ~= kc;
		}
	}

	if (comm.prop.var.etc.useNamesAfterStandard) { mixin(S_TRACE);
		if (kcs2.length && stdKCs.length) { mixin(S_TRACE);
			stdKCs ~= "";
		}
		kcs2 = stdKCs ~ kcs2;
	} else { mixin(S_TRACE);
		if (kcs2.length) { mixin(S_TRACE);
			kcs2 ~= "";
		}
		kcs2 ~= stdKCs;
	}
	return kcs2;
}

T createCellNameCombo(T = Combo)(Commons comm, Summary summ, Composite parent, bool delegate() catchMod) { mixin(S_TRACE);
	auto combo = new T(parent, SWT.BORDER | SWT.DROP_DOWN);
	combo.setVisibleItemCount(comm.prop.var.etc.comboVisibleItemCount);
	auto incSearch = new IncSearch(comm, combo);

	void refCellNames() { mixin(S_TRACE);
		string id = combo.getText();
		combo.removeAll();

		foreach (kc; allCellNames(comm, summ)) { mixin(S_TRACE);
			if (!incSearch.match(kc)) continue;
			combo.add(kc);
		}
		combo.setText(id);
	}

	incSearch.modEvent ~= &refCellNames;
	comm.refCellNames.add(&refCellNames);
	.listener(combo, SWT.Dispose, { mixin(S_TRACE);
		comm.refCellNames.remove(&refCellNames);
	});

	auto menu = new Menu(combo.getShell(), SWT.POP_UP);
	createMenuItem(comm, menu, MenuID.IncSearch, { mixin(S_TRACE);
		.forceFocus(combo, true);
		incSearch.startIncSearch();
	}, null);
	new MenuItem(menu, SWT.SEPARATOR);
	combo.setMenu(menu);
	createTextMenu!T(comm, comm.prop, combo, catchMod);

	refCellNames();

	return combo;
}

string[] allCellNames(Commons comm, Summary summ) {
	bool delegate(CellNameId a, CellNameId b) cmps;
	if (comm.prop.var.etc.logicalSort) {
		cmps = (a, b) => incmp(cast(string)a, cast(string)b) < 0;
	} else {
		cmps = (a, b) => icmp(cast(string)a, cast(string)b) < 0;
	}
	auto s = .sortDlg(summ.useCounter.cellName.keys, cmps);
	return .map!((a) => cast(string)a)(s).array();
}

class FlagChooser(F, bool CanSelNothing, bool Random = false) : Composite {
	void delegate()[] modEvent;

	private Tree _tree = null;
	private Table _list = null;
	private Button _allExpanded = null;

	static if (Random) {
		private Item _random = null;
	}

	private Commons _comm;
	private Props _prop;
	private Summary _summ = null;
	private string _selected = "";
	private IncSearch _flagIncSearch;
	private bool _canIncSearch = false;
	private bool _saveExpanded = false;

	@property
	private Control widget() { mixin(S_TRACE);
		return _tree ? _tree : _list;
	}

	private void flagIncSearch() { mixin(S_TRACE);
		.forceFocus(widget, true);
		_flagIncSearch.startIncSearch();
	}

	private void refFlags(Flag[] f, Step[] s) { mixin(S_TRACE);
		if (!_summ) return;
		static if (is(F:Flag)) {
			if (!f.length) return;
		} else static if (is(F:Step)) {
			if (!s.length) return;
		} else static assert (0);
		auto exp = expandedTable.dup;
		scope (exit) expandedTable = exp;
		saveExpanded();
		refreshFlags();
	}
	private void delFlags(Flag[] f, Step[] s) { mixin(S_TRACE);
		if (!_summ) return;
		static if (is(F:Flag)) {
			if (!f.length) return;
		} else static if (is(F:Step)) {
			if (!s.length) return;
		} else static assert (0);
		auto exp = expandedTable.dup;
		scope (exit) expandedTable = exp;
		saveExpanded();
		refreshFlags();
	}
	@property
	private ref bool[string] expandedTable() {
		static if (is(F:Flag)) {
			return _comm.flagDirExpanded;
		} else static if (is(F:Step)) {
			return _comm.stepDirExpanded;
		} else static assert (0);
	}
	private void refreshFlags() { mixin(S_TRACE);
		static if (is(F:Flag)) {
			auto icon = _prop.images.flag;
		} else static if (is(F:Step)) {
			auto icon = _prop.images.step;
		} else static assert (0);
		string sel = _selected;
		_selected = "";
		if (_tree) { mixin(S_TRACE);
			_tree.removeAll();
		} else { mixin(S_TRACE);
			_list.removeAll();
		}
		_canIncSearch = false;
		bool has = false;
		Item firstItem = null;
		static if (CanSelNothing) {
			Item nof;
			if (_tree) { mixin(S_TRACE);
				nof = new TreeItem(_tree, SWT.NONE);
			} else { mixin(S_TRACE);
				nof = new TableItem(_list, SWT.NONE);
			}
			nof.setText(_prop.msgs.noFlagRef);
			nof.setImage(_prop.images.emptyIcon);
			if (!firstItem) firstItem = nof;
		}
		static if (Random) {
			if (_tree) { mixin(S_TRACE);
				_random = new TreeItem(_tree, SWT.NONE);
			} else { mixin(S_TRACE);
				_random = new TableItem(_list, SWT.NONE);
			}
			_random.setText(_prop.msgs.randomValue);
			_random.setImage(_prop.images.emptyIcon);
			if (sel == _prop.sys.randomValue) { mixin(S_TRACE);
				has = true;
				if (_tree) { mixin(S_TRACE);
					_tree.setSelection([cast(TreeItem)_random]);
				} else { mixin(S_TRACE);
					_list.select(_list.getItemCount() - 1);
				}
				_selected = sel;
			}
			if (!firstItem) firstItem = _random;
		}
		if (_tree) { mixin(S_TRACE);
			bool recurse(T)(T parent, FlagDir dir, string name) { mixin(S_TRACE);
				bool selItm = false;
				TreeItem dirItm = null;
				if (dir !is _summ.flagDirRoot) {
					if (parent) {
						dirItm = new TreeItem(parent, SWT.NONE);
					} else {
						dirItm = new TreeItem(_tree, SWT.NONE);
					}
					dirItm.setData(dir);
					dirItm.setImage(_prop.images.flagDir);
					dirItm.setText(name);
				}
				foreach (child; dir.subDirs) { mixin(S_TRACE);
					static if (is(F:Flag)) {
						auto flags = child.allFlags;
					} else static if (is(F:Step)) {
						auto flags = child.allSteps;
					} else static assert (0);
					bool hasChild = false;
					foreach (flag; flags) { mixin(S_TRACE);
						if (!_flagIncSearch.match(flag.path)) continue;
						hasChild = true;
						break;
					}
					if (!hasChild) continue;
					selItm |= recurse(dirItm, child, child.name);
				}
				static if (is(F:Flag)) {
					auto flags = dir.flags;
				} else static if (is(F:Step)) {
					auto flags = dir.steps;
				} else static assert (0);
				foreach (flag; flags) { mixin(S_TRACE);
					auto path = flag.path;
					if (!has && path == sel) { mixin(S_TRACE);
						has = true;
					}
					if (!_flagIncSearch.match(path)) continue;
					TreeItem itm;
					if (dirItm) {
						itm = new TreeItem(dirItm, SWT.NONE);
					} else {
						itm = new TreeItem(_tree, SWT.NONE);
					}
					itm.setData(flag);
					itm.setImage(icon);
					itm.setText(flag.name);
					if (!_tree.getSelectionCount() && path == sel) { mixin(S_TRACE);
						selItm = true;
						_tree.setSelection([itm]);
						_selected = path;
					}
					_canIncSearch = true;
				}
				if (dirItm) {
					dirItm.setExpanded(selItm || expandedTable.get(dir.path, true));
				}
				return selItm;
			}
			recurse(_tree, _summ.flagDirRoot, _prop.msgs.flagDirRoot);
			checkAllExpanded(_allExpanded, _tree);

			void selRecurse(TreeItem itm, bool forceExpand) { mixin(S_TRACE);
				if (firstItem) return;
				if (cast(F)itm.getData()) { mixin(S_TRACE);
					firstItem = itm;
					return;
				}
				if (forceExpand || itm.getExpanded()) {
					foreach (child; itm.getItems()) selRecurse(child, forceExpand);
				}
			}
			if (!firstItem) { mixin(S_TRACE);
				foreach (itm; _tree.getItems()) selRecurse(itm, false);
			}
			if (!firstItem) { mixin(S_TRACE);
				foreach (itm; _tree.getItems()) selRecurse(itm, true);
			}

		} else { mixin(S_TRACE);
			static if (is(F:Flag)) {
				auto flags = _summ.flagDirRoot.allFlags;
			} else static if (is(F:Step)) {
				auto flags = _summ.flagDirRoot.allSteps;
			} else static assert (0);
			foreach (flag; flags) { mixin(S_TRACE);
				auto path = flag.path;
				if (!has && path == sel) { mixin(S_TRACE);
					has = true;
				}
				if (!_flagIncSearch.match(path)) continue;
				auto itm = new TableItem(_list, SWT.NONE);
				itm.setData(flag);
				itm.setImage(icon);
				itm.setText(path);
				if (!_list.getSelectionCount() && path == sel) { mixin(S_TRACE);
					_list.select(_list.getItemCount() - 1);
					_selected = path;
				}
				if (!firstItem) firstItem = itm;
				_canIncSearch = true;
			}
		}
		if (!has && firstItem) { mixin(S_TRACE);
			if (_tree) { mixin(S_TRACE);
				_tree.setSelection([cast(TreeItem)firstItem]);
			} else { mixin(S_TRACE);
				_list.setSelection([cast(TableItem)firstItem]);
			}
			auto flag = cast(F)firstItem.getData();
			if (flag) { mixin(S_TRACE);
				_selected = flag.path;
			} else { mixin(S_TRACE);
				_selected = "";
				static if (Random) {
					if (firstItem is _random) { mixin(S_TRACE);
						_selected = _prop.sys.randomValue;
					}
				}
			}
		}
		if (_selected != sel) { mixin(S_TRACE);
			foreach (dlg; modEvent) dlg();
		}
	}
	private void openFlagView() { mixin(S_TRACE);
		Item[] sels;
		if (_tree) { mixin(S_TRACE);
			sels = cast(Item[])_tree.getSelection();
		} else { mixin(S_TRACE);
			sels = cast(Item[])_list.getSelection();
		}
		if (!sels.length) return;
		string cwxPath = "";
		auto a = cast(F)sels[0].getData();
		if (a) cwxPath = a.cwxPath(true);
		auto d = cast(FlagDir)sels[0].getData();
		if (d) cwxPath = d.cwxPath(true);
		try { mixin(S_TRACE);
			_comm.openCWXPath(cpaddattr(cwxPath, "shallow"), false);
		} catch (Exception e) {
			debugln(e);
		}
	}
	private bool canOpenView() { mixin(S_TRACE);
		Item[] sels;
		if (_tree) { mixin(S_TRACE);
			sels = cast(Item[])_tree.getSelection();
		} else { mixin(S_TRACE);
			sels = cast(Item[])_list.getSelection();
		}
		if (!sels.length) return false;
		auto a = cast(F)sels[0].getData();
		auto d = cast(FlagDir)sels[0].getData();
		return a || d;
	}

	private void saveExpanded() { mixin(S_TRACE);
		bool[string] flagDirExpanded;
		void recurse(TreeItem itm) { mixin(S_TRACE);
			auto dir = cast(FlagDir)itm.getData();
			if (dir && dir.path != "") { mixin(S_TRACE);
				flagDirExpanded[dir.path] = itm.getExpanded();
			}
			foreach (child; itm.getItems()) recurse(child);
		}
		foreach (itm; _tree.getItems()) { mixin(S_TRACE);
			recurse(itm);
		}
		expandedTable = flagDirExpanded;
	}
	private void initControl() { mixin(S_TRACE);
		if (_tree) { mixin(S_TRACE);
			_tree.dispose();
			_tree = null;
			_allExpanded.dispose();
			_allExpanded = null;
		}
		if (_list) { mixin(S_TRACE);
			_list.dispose();
			_list = null;
		}
		if (_prop.var.etc.selectVariableWithTree) { mixin(S_TRACE);
			_tree = new Tree(this, SWT.SINGLE | SWT.BORDER | SWT.VIRTUAL);
			initTree(_comm, _tree, false, false);
			if (_saveExpanded) { mixin(S_TRACE);
				.listener(_tree, SWT.Dispose, &saveExpanded);
			}
			_allExpanded = createAllExpandedButton(_comm.prop, this, _tree);
		} else { mixin(S_TRACE);
			_list = new Table(this, SWT.SINGLE | SWT.FULL_SELECTION | SWT.BORDER);
			auto colN = new FullTableColumn(_list, SWT.NONE);
		}
		auto gd = new GridData(GridData.FILL_BOTH);
		gd.widthHint = _prop.var.etc.flagsWidth;
		gd.heightHint = _prop.var.etc.flagsHeight;
		widget.setLayoutData(gd);

		.listener(widget, SWT.Selection, { mixin(S_TRACE);
			Item[] sels;
			if (_tree) { mixin(S_TRACE);
				sels = cast(Item[])_tree.getSelection();
			} else { mixin(S_TRACE);
				sels = cast(Item[])_list.getSelection();
			}
			if (sels.length && !cast(FlagDir)sels[0].getData()) { mixin(S_TRACE);
				auto f = cast(F)sels[0].getData();
				if (f) { mixin(S_TRACE);
					_selected = f.path;
				} else { mixin(S_TRACE);
					_selected = "";
					static if (Random) {
						if (sels[0] is _random) { mixin(S_TRACE);
							_selected = _prop.sys.randomValue;
						}
					}
				}
			}
			foreach (dlg; modEvent) dlg();
		});
		.listener(widget, SWT.MouseDoubleClick, &openFlagView);

		auto menu = new Menu(getShell(), SWT.POP_UP);
		createMenuItem(_comm, menu, MenuID.IncSearch, &flagIncSearch, () => _canIncSearch);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.OpenAtVarView, &openFlagView, &canOpenView);
		widget.setMenu(menu);

		refreshFlags();
		layout();
	}

	this (Commons comm, Summary summ, Composite parent, bool saveExpanded = true) { mixin(S_TRACE);
		super (parent, SWT.NONE);
		_comm = comm;
		_prop = comm.prop;
		_summ = summ;
		_saveExpanded = saveExpanded;
		setLayout(zeroMarginGridLayout(1, true));
		_flagIncSearch = new IncSearch(_comm, this);
		_flagIncSearch.modEvent ~= &refreshFlags;

		initControl();

		_comm.refVarSelectStyle.add(&initControl);
		_comm.refFlagAndStep.add(&refFlags);
		_comm.delFlagAndStep.add(&delFlags);
		.listener(this, SWT.Dispose, { mixin(S_TRACE);
			_comm.refVarSelectStyle.remove(&initControl);
			_comm.refFlagAndStep.remove(&refFlags);
			_comm.delFlagAndStep.remove(&delFlags);
		});
	}

	@property
	void selected(string path) { mixin(S_TRACE);
		_selected = path;
		refreshFlags();
	}
	@property
	const
	string selected() { return _selected; }

	@property
	string selectedWithDir() { mixin(S_TRACE);
		if (_tree) { mixin(S_TRACE);
			auto sels = _tree.getSelection();
			if (sels.length && cast(FlagDir)sels[0].getData()) { mixin(S_TRACE);
				return (cast(FlagDir)sels[0].getData()).path;
			}
		}
		return _selected;
	}
}

class AreaChooser(A, bool StartArea) : Composite {
	void delegate()[] modEvent;

	private Tree _tree = null;
	private Table _list = null;
	private Button _allExpanded = null;

	private Commons _comm;
	private Props _prop;
	private Summary _summ = null;
	private ulong _selected = 0UL;
	private IncSearch _areaIncSearch;
	private bool _canIncSearch = false;

	@property
	private Control widget() { mixin(S_TRACE);
		return _tree ? _tree : _list;
	}

	private void areaIncSearch() { mixin(S_TRACE);
		.forceFocus(widget, true);
		_areaIncSearch.startIncSearch();
	}

	private void refA(A a) { mixin(S_TRACE);
		if (!_summ) return;
		static if (is(A:AbstractArea)) {
			auto exp = expandedTable.dup;
			scope (exit) expandedTable = exp;
			saveExpanded();
		}
		refreshAreas();
	}
	static if (is(A:AbstractArea)) {
		@property
		private ref bool[string] expandedTable() { mixin(S_TRACE);
			static if (is(A:Area)) {
				return _comm.flagAreaExpanded;
			} else static if (is(A:Battle)) {
				return _comm.flagBattleExpanded;
			} else static if (is(A:Package)) {
				return _comm.flagPackageExpanded;
			} else static assert (0);
		}
		private void saveExpanded() { mixin(S_TRACE);
			if (!_tree) return;
			expandedTable = null;
			void saveExpandedImpl(string parentPath, TreeItem itm) { mixin(S_TRACE);
				if (cast(A)itm.getData()) return;
				auto dirName = parentPath == "" ? itm.getText() : parentPath ~ "\\" ~ itm.getText();
				dirName = dirName.toLower();
				expandedTable[dirName] = itm.getExpanded();
				foreach (child; itm.getItems()) { mixin(S_TRACE);
					saveExpandedImpl(dirName, child);
				}
			}
			foreach (itm; _tree.getItems()) saveExpandedImpl("", itm);
		}
	}
	private void refreshAreas() { mixin(S_TRACE);
		ulong sel = _selected;
		_selected = 0UL;
		if (_tree) { mixin(S_TRACE);
			_tree.removeAll();
		} else { mixin(S_TRACE);
			_list.removeAll();
		}
		_canIncSearch = false;
		bool has = false;
		Item firstItem = null;
		static if (is(A:Area)) {
			auto arr = _summ.areas;
		} else static if (is(A:Battle)) {
			auto arr = _summ.battles;
		} else static if (is(A:Package)) {
			auto arr = _summ.packages;
		} else static if (is(A:CastCard)) {
			auto arr = _summ.casts;
		} else static if (is(A:InfoCard)) {
			auto arr = _summ.infos;
		} else static assert (0);
		if (_tree) { mixin(S_TRACE);
			static if (is(A:AbstractArea)) {
				TreeItem[string] itmTable;
				auto dirSet = new HashSet!string;
				auto dirSet2 = new HashSet!string;
				foreach (a; arr) {
					if (!has && a.id == sel) { mixin(S_TRACE);
						has = true;
					}
					if (!_areaIncSearch.match(a.name)) continue;
					auto dirName = a.dirName;
					auto l = dirName.toLower();
					if (dirSet2.contains(l)) continue;
					dirSet.add(dirName);
					dirSet2.add(l);
				}
				bool delegate(string, string) cmps;
				if (_prop.var.etc.logicalSort) { mixin(S_TRACE);
					cmps = (a, b) => incmp(a, b) < 0;
				} else { mixin(S_TRACE);
					cmps = (a, b) => icmp(a, b) < 0;
				}
				foreach (dirName; .sortDlg(dirSet.toArray(), cmps)) { mixin(S_TRACE);
					auto dirs = .split(dirName, "\\");
					TreeItem itm = null;
					foreach (i, dir; dirs) { mixin (S_TRACE);
						auto fPath = dirs[0 .. i + 1].join("\\");
						auto path = fPath.toLower();
						auto p = path in itmTable;
						if (p) { mixin (S_TRACE);
							itm = *p;
						} else { mixin (S_TRACE);
							TreeItem sub;
							if (itm) {
								sub = new TreeItem(itm, SWT.NONE);
							} else {
								sub = new TreeItem(_tree, SWT.NONE);
							}
							sub.setText(dir);
							sub.setImage(_prop.images.areaDir);
							sub.setData(null);
							itm = sub;
							itmTable[path] = sub;
						}
					}
					itmTable[dirName.toLower()] = itm;
				}
				foreach (a; arr) { mixin(S_TRACE);
					if (!_areaIncSearch.match(a.name)) continue;

					auto itm = itmTable[a.dirName().toLower()];
					TreeItem aItm;
					if (itm) {
						aItm = new TreeItem(itm, SWT.NONE);
					} else {
						aItm = new TreeItem(_tree, SWT.NONE);
					}
					aItm.setData(a);
					aItm.setText(.tryFormat("%s.%s", a.id, a.baseName));
					if (!_tree.getSelection().length && a.id == sel) { mixin(S_TRACE);
						_tree.setSelection([aItm]);
						_selected = a.id;
					}
					_canIncSearch = true;
					aItm.setImage(image(aItm));
				}
				foreach (dirName, itm; itmTable) {
					if (!itm) continue;
					itm.setExpanded(expandedTable.get(dirName, true));
				}
				void selRecurse(TreeItem itm, bool forceExpand) { mixin(S_TRACE);
					if (firstItem) return;
					if (cast(A)itm.getData()) { mixin(S_TRACE);
						firstItem = itm;
						return;
					}
					if (itm.getExpanded() || forceExpand) { mixin(S_TRACE);
						foreach (child; itm.getItems()) selRecurse(child, forceExpand);
					}
				}
				if (!firstItem) { mixin(S_TRACE);
					foreach (itm; _tree.getItems()) selRecurse(itm, false);
				}
				if (!firstItem) { mixin(S_TRACE);
					foreach (itm; _tree.getItems()) selRecurse(itm, true);
				}
				checkAllExpanded(_allExpanded, _tree);
			} else {
				assert (0);
			}
		} else { mixin(S_TRACE);
			foreach (a; arr) { mixin(S_TRACE);
				if (!has && a.id == sel) { mixin(S_TRACE);
					has = true;
				}
				if (!_areaIncSearch.match(a.name)) continue;
				auto itm = new TableItem(_list, SWT.NONE);
				itm.setData(a);
				itm.setText(0, .to!string(a.id));
				itm.setText(1, a.name);
				if (!_list.getSelectionCount() && a.id == sel) { mixin(S_TRACE);
					_list.select(_list.getItemCount() - 1);
					_selected = a.id;
				}
				itm.setImage(image(itm));
				if (!firstItem) firstItem = itm;
				_canIncSearch = true;
			}
		}
		if (!has && firstItem) { mixin(S_TRACE);
			if (_tree) { mixin(S_TRACE);
				_tree.setSelection([cast(TreeItem)firstItem]);
				_tree.showSelection();
			} else { mixin(S_TRACE);
				_list.setSelection([cast(TableItem)firstItem]);
				_list.showSelection();
			}
			auto a = cast(A)firstItem.getData();
			if (a) { mixin(S_TRACE);
				_selected = a.id;
			} else { mixin(S_TRACE);
				_selected = 0UL;
			}
			firstItem.setImage(image(firstItem));
		}
		if (_selected != sel) { mixin(S_TRACE);
			foreach (dlg; modEvent) dlg();
		}
	}
	private void updateImages() { mixin(S_TRACE);
		static if (StartArea) {
			if (_tree) {
				void recurse(T)(T tree) {
					foreach (itm; tree.getItems()) {
						if (!itm.getData()) continue;
						itm.setImage(image(itm));
						recurse(itm);
					}
				}
				recurse(_tree);
			} else {
				foreach (itm; _list.getItems()) {
					itm.setImage(image(itm));
				}
			}
		}
	}
	private Image image(Item itm) { mixin(S_TRACE);
		if (!itm.getData()) return _prop.images.areaDir;
		static if (is(A:Area)) {
			static if (StartArea) {
				if (_tree) { mixin(S_TRACE);
					if (_tree.getSelection().contains(itm)) { mixin(S_TRACE);
						return _prop.images.startArea;
					}
				} else { mixin(S_TRACE);
					if (_list.getSelection().contains(itm)) { mixin(S_TRACE);
						return _prop.images.startArea;
					}
				}
			}
			return _prop.images.area;
		} else static if (is(A:Battle)) {
			return _prop.images.battle;
		} else static if (is(A:Package)) {
			return _prop.images.packages;
		} else static if (is(A:CastCard)) {
			return _prop.images.casts;
		} else static if (is(A:InfoCard)) {
			return _prop.images.info;
		} else static assert (0);
	}

	private void openAreaView() { mixin(S_TRACE);
		Item[] sels;
		if (_tree) { mixin(S_TRACE);
			sels = cast(Item[])_tree.getSelection();
		} else { mixin(S_TRACE);
			sels = cast(Item[])_list.getSelection();
		}
		if (!sels.length) return;
		string cwxPath = "";
		auto a = cast(A)sels[0].getData();
		if (a) cwxPath = a.cwxPath(true);
		try { mixin(S_TRACE);
			_comm.openCWXPath(cpaddattr(cwxPath, "shallow"), false);
		} catch (Exception e) {
			debugln(e);
		}
	}
	private bool canOpenView() { mixin(S_TRACE);
		Item[] sels;
		if (_tree) { mixin(S_TRACE);
			sels = cast(Item[])_tree.getSelection();
		} else { mixin(S_TRACE);
			sels = cast(Item[])_list.getSelection();
		}
		if (!sels.length) return false;
		return cast(A)sels[0].getData() !is null;
	}

	private void initControl() { mixin(S_TRACE);
		if (_tree) { mixin(S_TRACE);
			_tree.dispose();
			_tree = null;
			_allExpanded.dispose();
			_allExpanded = null;
		}
		if (_list) { mixin(S_TRACE);
			_list.dispose();
			_list = null;
		}
		if (is(A:AbstractArea) && _prop.var.etc.showAreaDirTree) { mixin(S_TRACE);
			_tree = new Tree(this, SWT.SINGLE | SWT.BORDER | SWT.VIRTUAL);
			initTree(_comm, _tree, false, false);
			_allExpanded = createAllExpandedButton(_comm.prop, this, _tree);
		} else { mixin(S_TRACE);
			_list = new Table(this, SWT.SINGLE | SWT.FULL_SELECTION | SWT.BORDER);
			auto idCol = new TableColumn(_list, SWT.NONE);
			saveColumnWidth!("prop.var.etc.idColumn")(_prop, idCol);
			auto nameCol = new FullTableColumn(_list, SWT.NONE);
		}
		auto gd = new GridData(GridData.FILL_BOTH);
		gd.widthHint = _prop.var.etc.nameTableWidth;
		gd.heightHint = _prop.var.etc.nameTableHeight;
		widget.setLayoutData(gd);

		.listener(widget, SWT.Selection, { mixin(S_TRACE);
			Item[] sels;
			if (_tree) { mixin(S_TRACE);
				sels = cast(Item[])_tree.getSelection();
			} else { mixin(S_TRACE);
				sels = cast(Item[])_list.getSelection();
			}
			if (sels.length && cast(A)sels[0].getData()) { mixin(S_TRACE);
				auto a = cast(A)sels[0].getData();
				if (a) {
					_selected = a.id;
					updateImages();
				}
			}
			foreach (dlg; modEvent) dlg();
		});
		.listener(widget, SWT.MouseDoubleClick, &openAreaView);

		auto menu = new Menu(getShell(), SWT.POP_UP);
		createMenuItem(_comm, menu, MenuID.IncSearch, &areaIncSearch, () => _canIncSearch);
		new MenuItem(menu, SWT.SEPARATOR);
		static if (is(A:AbstractArea)) {
			createMenuItem(_comm, menu, MenuID.OpenAtTableView, &openAreaView, &canOpenView);
		} else static if (is(A : CastCard) || is(A : InfoCard)) {
			createMenuItem(_comm, menu, MenuID.OpenAtCardView, &openAreaView, &canOpenView);
		} else static assert (0);
		widget.setMenu(menu);

		refreshAreas();
		layout();
	}

	this (Commons comm, Summary summ, Composite parent) { mixin(S_TRACE);
		super (parent, SWT.NONE);
		_comm = comm;
		_prop = comm.prop;
		_summ = summ;
		setLayout(zeroMarginGridLayout(1, true));
		_areaIncSearch = new IncSearch(_comm, this);
		_areaIncSearch.modEvent ~= &refreshAreas;

		initControl();

		_comm.refTableViewStyle.add(&initControl);
		static if (is(A : Area)) {
			_comm.refArea.add(&refA);
			_comm.delArea.add(&refA);
		} else static if (is(A : Battle)) {
			_comm.refBattle.add(&refA);
			_comm.delBattle.add(&refA);
		} else static if (is(A : Package)) {
			_comm.refPackage.add(&refA);
			_comm.delPackage.add(&refA);
		} else static if (is(A : CastCard)) {
			_comm.refCast.add(&refA);
			_comm.delCast.add(&refA);
		} else static if (is(A : InfoCard)) {
			_comm.refInfo.add(&refA);
			_comm.delInfo.add(&refA);
		} else static assert (0);
		.listener(this, SWT.Dispose, { mixin(S_TRACE);
			static if (is(A:AbstractArea)) {
				saveExpanded();
			}
			_comm.refTableViewStyle.remove(&initControl);
			static if (is(A : Area)) {
				_comm.refArea.remove(&refA);
				_comm.delArea.remove(&refA);
			} else static if (is(A : Battle)) {
				_comm.refBattle.remove(&refA);
				_comm.delBattle.remove(&refA);
			} else static if (is(A : Package)) {
				_comm.refPackage.remove(&refA);
				_comm.delPackage.remove(&refA);
			} else static if (is(A : CastCard)) {
				_comm.refCast.remove(&refA);
				_comm.delCast.remove(&refA);
			} else static if (is(A : InfoCard)) {
				_comm.refInfo.remove(&refA);
				_comm.delInfo.remove(&refA);
			} else static assert (0);
		});
	}

	@property
	void selected(ulong id) { mixin(S_TRACE);
		_selected = id;
		refreshAreas();
	}
	@property
	const
	ulong selected() { return _selected; }
}

void checkAllExpanded(Button b, Tree tree) { mixin(S_TRACE);
	bool expanded = true;
	void recurse(TreeItem itm) { mixin(S_TRACE);
		if (itm.getItems().length && !itm.getExpanded()) { mixin(S_TRACE);
			expanded = false;
			return;
		}
		foreach (child; itm.getItems()) recurse(child);
	}
	foreach (itm; tree.getItems()) recurse(itm);
	b.setSelection(expanded);
}

Button createAllExpandedButton(Props prop, Composite parent, Tree tree) { mixin(S_TRACE);
	auto b = new Button(parent, SWT.CHECK);
	b.setText(prop.msgs.allExpanded);
	void check() { mixin(S_TRACE);
		tree.getDisplay().asyncExec(new class Runnable {
			override void run () { mixin(S_TRACE);
				if (tree.isDisposed()) return;
				checkAllExpanded(b, tree);
			}
		});
	}
	.listener(tree, SWT.Expand, &check);
	.listener(tree, SWT.Collapse, &check);
	.listener(b, SWT.Selection, { mixin(S_TRACE);
		void recurse(TreeItem itm) { mixin(S_TRACE);
			itm.setExpanded(b.getSelection());
			foreach (child; itm.getItems()) recurse(child);
		}
		foreach (itm; tree.getItems()) recurse(itm);
	});
	return b;
}
