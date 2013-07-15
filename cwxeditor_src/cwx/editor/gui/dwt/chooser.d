
module cwx.editor.gui.dwt.chooser;

import cwx.utils;
import cwx.types;
import cwx.summary;
import cwx.flag;
import cwx.path;

import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.incsearch;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dprops;

import org.eclipse.swt.all;

enum CouponComboType {
	AllCoupons, /// 全てのクーポンを選択肢とする。
	Talker, /// 話者用のクーポンを選択肢とする。
	Cast, /// キャストの経歴用のクーポンを選択肢とする。
}
T createCouponCombo(T = Combo)(Commons comm, Composite parent, bool delegate() catchMod, CouponComboType type) {
	TextMenuModify tmm;
	return createCouponCombo!T(comm, parent, catchMod, type, tmm);
}
T createCouponCombo(T = Combo)(Commons comm, Composite parent, bool delegate() catchMod, CouponComboType type, out TextMenuModify tmm) {
	auto combo = new T(parent, SWT.BORDER | SWT.DROP_DOWN);
	combo.setVisibleItemCount(comm.prop.var.etc.comboVisibleItemCount);
	auto incSearch = new IncSearch(comm, combo);

	void refreshCoupons() {
		string id = combo.getText();
		combo.removeAll();

		string[] cs;
		if (type !is CouponComboType.Cast) {
			cs = castCoupons(comm, type is CouponComboType.Talker, comm.skin.legacyName);
		}

		string[] dcs;
		if (comm.prop.var.etc.usedCouponToCombo) {
			foreach (coupon; comm.summary.useCounter.coupon.keys.sort) {
				if (!.contains(cs, coupon.id)) dcs ~= coupon;
			}
		}
		if (comm.prop.var.etc.useNamesAfterStandard) {
			if (dcs.length && cs.length) {
				cs ~= "";
			}
			dcs = cs ~ dcs;
		} else {
			if (dcs.length && cs.length) {
				dcs ~= "";
			}
			dcs ~= cs;
		}
		foreach (coupon; dcs) {
			if (!incSearch.match(coupon)) continue;
			combo.add(coupon);
		}
		combo.setText(id);
	}

	incSearch.modEvent ~= &refreshCoupons;
	comm.refSkin.add(&refreshCoupons);
	comm.refCoupons.add(&refreshCoupons);
	.listener(combo, SWT.Dispose, {
		comm.refSkin.remove(&refreshCoupons);
		comm.refCoupons.remove(&refreshCoupons);
	});

	auto menu = new Menu(combo.getShell(), SWT.POP_UP);
	createMenuItem(comm, menu, MenuID.IncSearch, {
		.forceFocus(combo, true);
		incSearch.startIncSearch();
	}, null);
	new MenuItem(menu, SWT.SEPARATOR);
	combo.setMenu(menu);
	tmm = createTextMenu!T(comm, comm.prop, combo, catchMod);

	refreshCoupons();

	return combo;
}

T createGossipCombo(T = Combo)(Commons comm, Composite parent, bool delegate() catchMod) {
	auto combo = new T(parent, SWT.BORDER | SWT.DROP_DOWN);
	combo.setVisibleItemCount(comm.prop.var.etc.comboVisibleItemCount);
	auto incSearch = new IncSearch(comm, combo);

	void refGossip() {
		string id = combo.getText();
		combo.removeAll();

		foreach (gossip; comm.summary.useCounter.gossip.keys.sort) {
			if (!incSearch.match(gossip)) continue;
			combo.add(gossip);
		}
		combo.setText(id);
	}

	incSearch.modEvent ~= &refGossip;
	comm.refGossips.add(&refGossip);
	.listener(combo, SWT.Dispose, {
		comm.refGossips.remove(&refGossip);
	});

	auto menu = new Menu(combo.getShell(), SWT.POP_UP);
	createMenuItem(comm, menu, MenuID.IncSearch, {
		.forceFocus(combo, true);
		incSearch.startIncSearch();
	}, null);
	new MenuItem(menu, SWT.SEPARATOR);
	combo.setMenu(menu);
	createTextMenu!T(comm, comm.prop, combo, catchMod);

	refGossip();

	return combo;
}

T createCompleteStampCombo(T = Combo)(Commons comm, Composite parent, bool delegate() catchMod) {
	auto combo = new T(parent, SWT.BORDER | SWT.DROP_DOWN);
	combo.setVisibleItemCount(comm.prop.var.etc.comboVisibleItemCount);
	auto incSearch = new IncSearch(comm, combo);

	void refCompleteStamp() {
		string id = combo.getText();
		combo.removeAll();

		foreach (stamp; comm.summary.useCounter.completeStamp.keys.sort) {
			if (!incSearch.match(stamp)) continue;
			combo.add(stamp);
		}
		combo.setText(id);
	}

	incSearch.modEvent ~= &refCompleteStamp;
	comm.refCompleteStamps.add(&refCompleteStamp);
	.listener(combo, SWT.Dispose, {
		comm.refCompleteStamps.remove(&refCompleteStamp);
	});

	auto menu = new Menu(combo.getShell(), SWT.POP_UP);
	createMenuItem(comm, menu, MenuID.IncSearch, {
		.forceFocus(combo, true);
		incSearch.startIncSearch();
	}, null);
	new MenuItem(menu, SWT.SEPARATOR);
	combo.setMenu(menu);
	createTextMenu!T(comm, comm.prop, combo, catchMod);

	refCompleteStamp();

	return combo;
}

T createKeyCodeCombo(T = Combo)(Commons comm, Composite parent, bool delegate() catchMod) {
	auto combo = new T(parent, SWT.BORDER | SWT.DROP_DOWN);
	combo.setVisibleItemCount(comm.prop.var.etc.comboVisibleItemCount);
	auto incSearch = new IncSearch(comm, combo);

	void refStandardKeyCodes() {
		string id = combo.getText();
		combo.removeAll();

		string[] stdKCs = comm.prop.var.etc.standardKeyCodes.dup;

		auto kcs = comm.summary.useCounter.keyCode.keys;
		string[] kcs2;
		foreach (string kc; kcs.sort) {
			if (!.contains(stdKCs, kc)) {
				kcs2 ~= kc;
			}
		}

		if (comm.prop.var.etc.useNamesAfterStandard) {
			if (kcs2.length && stdKCs.length) {
				stdKCs ~= "";
			}
			kcs2 = stdKCs ~ kcs2;
		} else {
			if (kcs2.length) {
				kcs2 ~= "";
			}
			kcs2 ~= stdKCs;
		}
		foreach (kc; kcs2) {
			if (!incSearch.match(kc)) continue;
			combo.add(kc);
		}
		combo.setText(id);
	}

	incSearch.modEvent ~= &refStandardKeyCodes;
	comm.refStandardKeyCodes.add(&refStandardKeyCodes);
	comm.refKeyCodes.add(&refStandardKeyCodes);
	.listener(combo, SWT.Dispose, {
		comm.refStandardKeyCodes.remove(&refStandardKeyCodes);
		comm.refKeyCodes.remove(&refStandardKeyCodes);
	});

	auto menu = new Menu(combo.getShell(), SWT.POP_UP);
	createMenuItem(comm, menu, MenuID.IncSearch, {
		.forceFocus(combo, true);
		incSearch.startIncSearch();
	}, null);
	new MenuItem(menu, SWT.SEPARATOR);
	combo.setMenu(menu);
	createTextMenu!T(comm, comm.prop, combo, catchMod);

	refStandardKeyCodes();

	return combo;
}

class FlagChooser(F, bool CanSelNothing, bool Random = false) : Composite {
	void delegate()[] modEvent;

	private Tree _tree = null;
	private Table _list = null;

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
	private Control widget() {
		return _tree ? _tree : _list;
	}

	private void flagIncSearch() {
		.forceFocus(widget, true);
		_flagIncSearch.startIncSearch();
	}

	private void refFlags(Flag[] f, Step[] s) {
		if (!_summ) return;
		static if (is(F:Flag)) {
			if (!f.length) return;
		} else static if (is(F:Step)) {
			if (!s.length) return;
		} else static assert (0);
		refreshFlags();
	}
	private void delFlags(Flag[] f, Step[] s) {
		if (!_summ) return;
		static if (is(F:Flag)) {
			if (!f.length) return;
		} else static if (is(F:Step)) {
			if (!s.length) return;
		} else static assert (0);
		refreshFlags();
	}
	private void refreshFlags() {
		static if (is(F:Flag)) {
			auto icon = _prop.images.flag;
		} else static if (is(F:Step)) {
			auto icon = _prop.images.step;
		} else static assert (0);
		string sel = _selected;
		_selected = "";
		if (_tree) {
			_tree.removeAll();
		} else {
			_list.removeAll();
		}
		_canIncSearch = false;
		bool has = false;
		Item firstItem = null;
		static if (CanSelNothing) {
			Item nof;
			if (_tree) {
				nof = new TreeItem(_tree, SWT.NONE);
			} else {
				nof = new TableItem(_list, SWT.NONE);
			}
			nof.setText(_prop.msgs.noFlagRef);
			nof.setImage(_prop.images.emptyIcon);
			if (!firstItem) firstItem = nof;
		}
		static if (Random) {
			if (_tree) {
				_random = new TreeItem(_tree, SWT.NONE);
			} else {
				_random = new TableItem(_list, SWT.NONE);
			}
			_random.setText(_prop.msgs.randomValue);
			_random.setImage(_prop.images.emptyIcon);
			if (sel == _prop.sys.randomValue) {
				has = true;
				if (_tree) {
					_tree.setSelection([cast(TreeItem)_random]);
				} else {
					_list.select(_list.getItemCount() - 1);
				}
				_selected = sel;
			}
			if (!firstItem) firstItem = _random;
		}
		if (_tree) {
			bool recurse(T)(T parent, FlagDir dir, string name) {
				bool selItm = false;
				auto dirItm = new TreeItem(parent, SWT.NONE);
				dirItm.setData(dir);
				dirItm.setImage(_prop.images.flagDir);
				dirItm.setText(name);
				foreach (child; dir.subDirs) {
					static if (is(F:Flag)) {
						auto flags = child.allFlags;
					} else static if (is(F:Step)) {
						auto flags = child.allSteps;
					} else static assert (0);
					bool hasChild = false;
					foreach (flag; flags) {
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
				foreach (flag; flags) {
					auto path = flag.path;
					if (!has && path == sel) {
						has = true;
					}
					if (!_flagIncSearch.match(path)) continue;
					auto itm = new TreeItem(dirItm, SWT.NONE);
					itm.setData(flag);
					itm.setImage(icon);
					itm.setText(flag.name);
					if (!_tree.getSelectionCount() && path == sel) {
						selItm = true;
						_tree.setSelection([itm]);
						_selected = path;
					}
					if (!firstItem) firstItem = itm;
					_canIncSearch = true;
				}
				dirItm.setExpanded(selItm || _comm.flagDirExpanded.get(dir.path, true));
				return selItm;
			}
			recurse(_tree, _summ.flagDirRoot, _prop.msgs.flagDirRoot);
		} else {
			static if (is(F:Flag)) {
				auto flags = _summ.flagDirRoot.allFlags;
			} else static if (is(F:Step)) {
				auto flags = _summ.flagDirRoot.allSteps;
			} else static assert (0);
			foreach (flag; flags) {
				auto path = flag.path;
				if (!has && path == sel) {
					has = true;
				}
				if (!_flagIncSearch.match(path)) continue;
				auto itm = new TableItem(_list, SWT.NONE);
				itm.setData(flag);
				itm.setImage(icon);
				itm.setText(path);
				if (!_list.getSelectionCount() && path == sel) {
					_list.select(_list.getItemCount() - 1);
					_selected = path;
				}
				if (!firstItem) firstItem = itm;
				_canIncSearch = true;
			}
		}
		if (!has && firstItem) {
			if (_tree) {
				_tree.setSelection([cast(TreeItem)firstItem]);
			} else {
				_list.setSelection([cast(TableItem)firstItem]);
			}
			auto flag = cast(F)firstItem.getData();
			if (flag) {
				_selected = flag.path;
			} else {
				_selected = "";
				static if (Random) {
					if (firstItem is _random) {
						_selected = _prop.sys.randomValue;
					}
				}
			}
		}
		if (_selected != sel) {
			foreach (dlg; modEvent) dlg();
		}
	}
	private void openFlagView() {
		Item[] sels;
		if (_tree) {
			sels = cast(Item[])_tree.getSelection();
		} else {
			sels = cast(Item[])_list.getSelection();
		}
		if (!sels.length) return;
		string cwxPath = "";
		auto a = cast(F)sels[0].getData();
		if (a) cwxPath = a.cwxPath(true);
		auto d = cast(FlagDir)sels[0].getData();
		if (d) cwxPath = d.cwxPath(true);
		try {
			_comm.openCWXPath(cpaddattr(cwxPath, "shallow"), false);
		} catch (Exception e) {
			debugln(e);
		}
	}
	private bool canOpenView() {
		Item[] sels;
		if (_tree) {
			sels = cast(Item[])_tree.getSelection();
		} else {
			sels = cast(Item[])_list.getSelection();
		}
		if (!sels.length) return false;
		auto a = cast(F)sels[0].getData();
		auto d = cast(FlagDir)sels[0].getData();
		return a || d;
	}

	private void initControl() {
		if (_tree) {
			_tree.dispose();
			_tree = null;
		}
		if (_list) {
			_list.dispose();
			_list = null;
		}
		if (_prop.var.etc.selectVariableWithTree) {
			_tree = new Tree(this, SWT.SINGLE | SWT.BORDER | SWT.VIRTUAL);
			initTree(_comm, _tree, false);
			if (_saveExpanded) {
				.listener(_tree, SWT.Dispose, {
					bool[string] flagDirExpanded;
					void recurse(TreeItem itm) {
						auto dir = cast(FlagDir)itm.getData();
						if (dir && dir.path != "") {
							flagDirExpanded[dir.path] = itm.getExpanded();
						}
						foreach (child; itm.getItems()) recurse(child);
					}
					foreach (itm; _tree.getItems()) {
						recurse(itm);
					}
					_comm.flagDirExpanded = flagDirExpanded;
				});
			}
		} else {
			_list = new Table(this, SWT.SINGLE | SWT.FULL_SELECTION | SWT.BORDER);
			auto colN = new FullTableColumn(_list, SWT.NONE);
		}
		auto gd = new GridData(GridData.FILL_BOTH);
		gd.widthHint = _prop.var.etc.flagsWidth;
		gd.heightHint = _prop.var.etc.flagsHeight;
		widget.setLayoutData(gd);

		.listener(widget, SWT.Selection, {
			Item[] sels;
			if (_tree) {
				sels = cast(Item[])_tree.getSelection();
			} else {
				sels = cast(Item[])_list.getSelection();
			}
			if (sels.length && !cast(FlagDir)sels[0].getData()) {
				auto f = cast(F)sels[0].getData();
				if (f) {
					_selected = f.path;
				} else {
					_selected = "";
					static if (Random) {
						if (sels[0] is _random) {
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

	this (Commons comm, Composite parent, bool saveExpanded = true) {
		super (parent, SWT.NONE);
		_comm = comm;
		_prop = comm.prop;
		_summ = comm.summary;
		_saveExpanded = saveExpanded;
		setLayout(zeroMarginGridLayout(1, true));
		_flagIncSearch = new IncSearch(_comm, this);
		_flagIncSearch.modEvent ~= &refreshFlags;

		initControl();

		_comm.refVarSelectStyle.add(&initControl);
		_comm.refFlagAndStep.add(&refFlags);
		_comm.delFlagAndStep.add(&delFlags);
		.listener(this, SWT.Dispose, {
			_comm.refVarSelectStyle.remove(&initControl);
			_comm.refFlagAndStep.remove(&refFlags);
			_comm.delFlagAndStep.remove(&delFlags);
		});
	}

	@property
	void selected(string path) {
		_selected = path;
		refreshFlags();
	}
	@property
	const
	string selected() { return _selected; }

	@property
	string selectedWithDir() {
		if (_tree) {
			auto sels = _tree.getSelection();
			if (sels.length && cast(FlagDir)sels[0].getData()) {
				return (cast(FlagDir)sels[0].getData()).path;
			}
		}
		return _selected;
	}
}
