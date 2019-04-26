
module cwx.editor.gui.dwt.chooser;

import cwx.utils;
import cwx.types;
import cwx.summary;
import cwx.flag;
import cwx.path;
import cwx.area;
import cwx.card;
import cwx.usecounter;
import cwx.features;

import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.incsearch;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.messageutils;

import std.algorithm;
import std.array;
import std.conv;
import std.string;
import std.typecons : Tuple;

import org.eclipse.swt.all;

import java.lang.all;

enum CouponComboType {
	AllCoupons, /// 全てのクーポンを選択肢とする。
	GetLose, /// 獲得・喪失が可能なクーポンを選択肢とする。
	Talker, /// 話者用のクーポンを選択肢とする。
	Cast, /// キャストの経歴用のクーポンを選択肢とする。
	Valued, /// 評価条件のクーポンを選択肢とする。
}
T createCouponCombo(T = Combo)(Commons comm, Summary summ, UseCounter uc, Composite parent, bool delegate() catchMod, CouponComboType type, string initValue, bool expandSPChars = false) { mixin(S_TRACE);
	TextMenuModify tmm;
	return createCouponCombo!T(comm, summ, uc, parent, catchMod, type, initValue, tmm, expandSPChars);
}
T createCouponCombo(T = Combo)(Commons comm, Summary summ, UseCounter uc, Composite parent, bool delegate() catchMod, CouponComboType type, string initValue, out TextMenuModify tmm, bool expandSPChars = false) { mixin(S_TRACE);
	auto combo = new T(parent, SWT.BORDER | SWT.DROP_DOWN);
	combo.setVisibleItemCount(comm.prop.var.etc.comboVisibleItemCount);
	combo.setText(initValue);
	auto hasItem = false;
	auto incSearch = new IncSearch(comm, combo, () => hasItem);

	void refreshCoupons() { mixin(S_TRACE);
		if (combo.isDisposed()) return;
		string id = combo.getText();
		combo.removeAll();
		hasItem = false;

		auto values = .addInitValue(comm, allCoupons(comm, summ, type), initValue);
		foreach (i, coupon; values) { mixin(S_TRACE);
			hasItem = true;
			if (!incSearch.match(coupon)) continue;
			combo.add(coupon);
		}
		combo.setText(id);
	}

	incSearch.modEvent ~= &refreshCoupons;
	if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
		comm.refSkin.add(&refreshCoupons);
		comm.refCoupons.add(&refreshCoupons);
		comm.replText.add(&refreshCoupons);
		comm.refDataVersion.add(&refreshCoupons);
		.listener(combo, SWT.Dispose, { mixin(S_TRACE);
			comm.refSkin.remove(&refreshCoupons);
			comm.refCoupons.remove(&refreshCoupons);
			comm.replText.remove(&refreshCoupons);
			comm.refDataVersion.remove(&refreshCoupons);
		});
	}

	auto menu = new Menu(combo.getShell(), SWT.POP_UP);
	createMenuItem(comm, menu, MenuID.IncSearch, { mixin(S_TRACE);
		.forceFocus(combo, true);
		incSearch.startIncSearch();
	}, () => hasItem);
	new MenuItem(menu, SWT.SEPARATOR);
	combo.setMenu(menu);
	tmm = createTextMenu!T(comm, comm.prop, combo, catchMod);

	if (expandSPChars) { mixin(S_TRACE);
		new MenuItem(menu, SWT.SEPARATOR);
		.setupSPCharsMenu(comm, summ, uc, combo, menu, false, true, () => true);

		void updateToolTip() { mixin(S_TRACE);
			if (combo && !combo.isDisposed()) { mixin(S_TRACE);
				auto toolTip = .createSPCharPreview(comm, summ, uc, combo.getText(), true, null, null);
				toolTip = toolTip.replace("&", "&&");
				if (toolTip != combo.getToolTipText()) { mixin(S_TRACE);
					combo.setToolTipText(toolTip);
				}
			}
		}
		void refFlagAndStep(cwx.flag.Flag[] flags, Step[] steps, cwx.flag.Variant[] variants) { updateToolTip(); }
		void refPath(string o, string n, bool isDir) { updateToolTip(); }
		void refPaths(string parent) { updateToolTip(); }

		.listener(combo, SWT.Modify, &updateToolTip);

		comm.refPreviewValues.add(&updateToolTip);
		comm.refFlagAndStep.add(&refFlagAndStep);
		comm.delFlagAndStep.add(&refFlagAndStep);
		comm.refPath.add(&refPath);
		comm.refPaths.add(&refPaths);
		comm.replText.add(&updateToolTip);
		.listener(combo, SWT.Dispose, { mixin(S_TRACE);
			comm.refPreviewValues.remove(&updateToolTip);
			comm.refFlagAndStep.remove(&refFlagAndStep);
			comm.delFlagAndStep.remove(&refFlagAndStep);
			comm.refPath.remove(&refPath);
			comm.refPaths.remove(&refPaths);
			comm.replText.remove(&updateToolTip);
		});
		updateToolTip();
	}

	refreshCoupons();

	return combo;
}

private string[] addInitValue(Commons comm, string[] values, string initValue) { mixin(S_TRACE);
	if (initValue != "") { mixin(S_TRACE);
		if (comm.prop.var.etc.showCurrentValueOnTopAlways) { mixin(S_TRACE);
			values = cwx.utils.remove(values, initValue);
			values = values.length && values[0] != "" ? ([initValue, ""] ~ values) : [initValue] ~ values;
		} else if (!cwx.utils.contains(values, initValue)) { mixin(S_TRACE);
			values = values.length && values[0] != "" ? ([initValue, ""] ~ values) : [initValue] ~ values;
		}
	}
	return values;
}

string[] allCoupons(Commons comm, Summary summ, CouponComboType type) { mixin(S_TRACE);
	string[] cs;
	if (type !is CouponComboType.Cast) { mixin(S_TRACE);
		cs = castCoupons(comm, type is CouponComboType.Talker, comm.skin.legacyName,
			type is CouponComboType.GetLose, type is CouponComboType.Valued);
	}

	string[] dcs;
	if (comm.prop.var.etc.usedCouponToCombo) { mixin(S_TRACE);
		bool delegate(CouponId a, CouponId b) cmps;
		if (comm.prop.var.etc.logicalSort) { mixin(S_TRACE);
			cmps = (a, b) => incmp(cast(string)a, cast(string)b) < 0;
		} else { mixin(S_TRACE);
			cmps = (a, b) => icmp(cast(string)a, cast(string)b) < 0;
		}
		bool[string] sysCoupons;
		auto stds = type is CouponComboType.Valued ? comm.prop.var.etc.standardCouponsForValued : comm.prop.var.etc.standardCoupons;
		foreach (coupon; stds) { mixin(S_TRACE);
			coupon = comm.skin.replaceSystemCouponName(comm.prop.sys, coupon);
			sysCoupons[coupon] = true;
		}
		foreach (e; comm.skin.allSexes) { mixin(S_TRACE);
			sysCoupons[comm.skin.sexCoupon(e)] = true;
		}
		foreach (e; comm.skin.allPeriods) { mixin(S_TRACE);
			sysCoupons[comm.skin.periodCoupon(e)] = true;
		}
		if (comm.prop.var.etc.showSpNature) { mixin(S_TRACE);
			foreach (e; comm.skin.allNatures) { mixin(S_TRACE);
				sysCoupons[comm.skin.natureCoupon(e)] = true;
			}
		} else { mixin(S_TRACE);
			foreach (e; comm.skin.normalNatures) { mixin(S_TRACE);
				sysCoupons[comm.skin.natureCoupon(e)] = true;
			}
		}
		foreach (e; comm.skin.leftMakings) { mixin(S_TRACE);
			sysCoupons[comm.skin.makingsCoupon(e)] = true;
			sysCoupons[comm.skin.makingsCoupon(comm.skin.reverseMakings(e))] = true;
		}
		if (summ) { mixin(S_TRACE);
			foreach (coupon; .sortDlg(summ.useCounter.keys!CouponId, cmps)) { mixin(S_TRACE);
				if (coupon.id in sysCoupons || comm.prop.sys.isCouponType(coupon.id, CouponType.System)) continue;
				if (!.contains(cs, coupon.id)) dcs ~= coupon;
			}
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

T createGossipCombo(T = Combo)(Commons comm, Summary summ, Composite parent, bool delegate() catchMod, string initValue) { mixin(S_TRACE);
	auto combo = new T(parent, SWT.BORDER | SWT.DROP_DOWN);
	combo.setVisibleItemCount(comm.prop.var.etc.comboVisibleItemCount);
	auto hasItem = false;
	auto incSearch = new IncSearch(comm, combo, () => hasItem);

	void refGossip() { mixin(S_TRACE);
		string id = combo.getText();
		combo.removeAll();
		hasItem = false;

		auto values = .addInitValue(comm, allGossips(comm, summ), initValue);
		foreach (i, gossip; values) { mixin(S_TRACE);
			hasItem = true;
			if (!incSearch.match(gossip)) continue;
			combo.add(gossip);
		}
		combo.setText(id);
	}

	incSearch.modEvent ~= &refGossip;
	if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
		comm.refGossips.add(&refGossip);
		comm.replText.add(&refGossip);
		.listener(combo, SWT.Dispose, { mixin(S_TRACE);
			comm.refGossips.remove(&refGossip);
			comm.replText.remove(&refGossip);
		});
	}

	auto menu = new Menu(combo.getShell(), SWT.POP_UP);
	createMenuItem(comm, menu, MenuID.IncSearch, { mixin(S_TRACE);
		.forceFocus(combo, true);
		incSearch.startIncSearch();
	}, () => hasItem);
	new MenuItem(menu, SWT.SEPARATOR);
	combo.setMenu(menu);
	createTextMenu!T(comm, comm.prop, combo, catchMod);

	refGossip();

	return combo;
}

string[] allGossips(Commons comm, Summary summ) { mixin(S_TRACE);
	string[] cs;

	bool delegate(GossipId a, GossipId b) cmps;
	if (comm.prop.var.etc.logicalSort) { mixin(S_TRACE);
		cmps = (a, b) => incmp(cast(string)a, cast(string)b) < 0;
	} else { mixin(S_TRACE);
		cmps = (a, b) => icmp(cast(string)a, cast(string)b) < 0;
	}
	if (summ) { mixin(S_TRACE);
		foreach (gossip; .sortDlg(summ.useCounter.keys!GossipId, cmps)) { mixin(S_TRACE);
			cs ~= gossip;
		}
	}
	return cs;
}

T createCompleteStampCombo(T = Combo)(Commons comm, Summary summ, Composite parent, bool delegate() catchMod, string initValue) { mixin(S_TRACE);
	auto combo = new T(parent, SWT.BORDER | SWT.DROP_DOWN);
	combo.setVisibleItemCount(comm.prop.var.etc.comboVisibleItemCount);
	auto hasItem = false;
	auto incSearch = new IncSearch(comm, combo, () => hasItem);

	void refCompleteStamp() { mixin(S_TRACE);
		string id = combo.getText();
		combo.removeAll();
		hasItem = false;

		auto values = .addInitValue(comm, allCompleteStamps(comm, summ), initValue);
		foreach (i, stamp; values) { mixin(S_TRACE);
			hasItem = true;
			if (!incSearch.match(stamp)) continue;
			combo.add(stamp);
		}
		combo.setText(id);
	}

	incSearch.modEvent ~= &refCompleteStamp;
	if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
		comm.refCompleteStamps.add(&refCompleteStamp);
		comm.replText.add(&refCompleteStamp);
		.listener(combo, SWT.Dispose, { mixin(S_TRACE);
			comm.refCompleteStamps.remove(&refCompleteStamp);
			comm.replText.remove(&refCompleteStamp);
		});
	}

	auto menu = new Menu(combo.getShell(), SWT.POP_UP);
	createMenuItem(comm, menu, MenuID.IncSearch, { mixin(S_TRACE);
		.forceFocus(combo, true);
		incSearch.startIncSearch();
	}, () => hasItem);
	new MenuItem(menu, SWT.SEPARATOR);
	combo.setMenu(menu);
	createTextMenu!T(comm, comm.prop, combo, catchMod);

	refCompleteStamp();

	return combo;
}

string[] allCompleteStamps(Commons comm, Summary summ) { mixin(S_TRACE);
	string[] cs;

	bool delegate(CompleteStampId a, CompleteStampId b) cmps;
	if (comm.prop.var.etc.logicalSort) { mixin(S_TRACE);
		cmps = (a, b) => incmp(cast(string)a, cast(string)b) < 0;
	} else { mixin(S_TRACE);
		cmps = (a, b) => icmp(cast(string)a, cast(string)b) < 0;
	}
	if (summ) { mixin(S_TRACE);
		foreach (compStamp; .sortDlg(summ.useCounter.keys!CompleteStampId, cmps)) { mixin(S_TRACE);
			cs ~= compStamp;
		}
	}
	return cs;
}

T createKeyCodeCombo(T = Combo)(Commons comm, Summary summ, Composite parent, bool delegate() catchMod, string initValue) { mixin(S_TRACE);
	auto combo = new T(parent, SWT.BORDER | SWT.DROP_DOWN);
	combo.setVisibleItemCount(comm.prop.var.etc.comboVisibleItemCount);
	auto hasItem = false;
	auto incSearch = new IncSearch(comm, combo, () => hasItem);

	void refStandardKeyCodes() { mixin(S_TRACE);
		string id = combo.getText();
		combo.removeAll();
		hasItem = false;

		string[] stdKCs = comm.prop.var.etc.standardKeyCodes.dup;

		auto kcs = summ ? summ.useCounter.keys!KeyCodeId : [];
		string[] kcs2;
		foreach (string kc; std.algorithm.sort(kcs)) { mixin(S_TRACE);
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
		auto values = .addInitValue(comm, kcs2, initValue);
		foreach (i, kc; values) { mixin(S_TRACE);
			hasItem = true;
			if (!incSearch.match(kc)) continue;
			combo.add(kc);
		}
		combo.setText(id);
	}

	incSearch.modEvent ~= &refStandardKeyCodes;
	comm.refStandardKeyCodes.add(&refStandardKeyCodes);
	if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
		comm.refKeyCodes.add(&refStandardKeyCodes);
		comm.replText.add(&refStandardKeyCodes);
	}
	.listener(combo, SWT.Dispose, { mixin(S_TRACE);
		comm.refStandardKeyCodes.remove(&refStandardKeyCodes);
		if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
			comm.refKeyCodes.remove(&refStandardKeyCodes);
			comm.replText.remove(&refStandardKeyCodes);
		}
	});

	auto menu = new Menu(combo.getShell(), SWT.POP_UP);
	createMenuItem(comm, menu, MenuID.IncSearch, { mixin(S_TRACE);
		.forceFocus(combo, true);
		incSearch.startIncSearch();
	}, () => hasItem);
	new MenuItem(menu, SWT.SEPARATOR);
	combo.setMenu(menu);
	createTextMenu!T(comm, comm.prop, combo, catchMod);

	refStandardKeyCodes();

	return combo;
}

string[] allKeyCodes(Commons comm, Summary summ) { mixin(S_TRACE);
	string[] stdKCs = comm.prop.var.etc.standardKeyCodes.dup;

	bool delegate(KeyCodeId a, KeyCodeId b) cmps;
	if (comm.prop.var.etc.logicalSort) {
		cmps = (a, b) => incmp(cast(string)a, cast(string)b) < 0;
	} else {
		cmps = (a, b) => icmp(cast(string)a, cast(string)b) < 0;
	}
	string[] kcs2;
	if (summ) { mixin(S_TRACE);
		auto kcs = summ.useCounter.keys!KeyCodeId;
		foreach (string kc; .sortDlg(kcs, cmps)) { mixin(S_TRACE);
			if (!.contains(stdKCs, kc)) { mixin(S_TRACE);
				kcs2 ~= kc;
			}
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

T createCellNameCombo(T = Combo)(Commons comm, Summary summ, Composite parent, bool delegate() catchMod, string initValue) { mixin(S_TRACE);
	auto combo = new T(parent, SWT.BORDER | SWT.DROP_DOWN);
	combo.setVisibleItemCount(comm.prop.var.etc.comboVisibleItemCount);
	auto hasItem = false;
	auto incSearch = new IncSearch(comm, combo, () => hasItem);

	void refCellNames() { mixin(S_TRACE);
		if (!summ) return;
		string id = combo.getText();
		combo.removeAll();
		hasItem = false;

		auto values = .addInitValue(comm, allCellNames(comm, summ), initValue);
		foreach (i, kc; values) { mixin(S_TRACE);
			hasItem = true;
			if (!incSearch.match(kc)) continue;
			combo.add(kc);
		}
		combo.setText(id);
	}

	incSearch.modEvent ~= &refCellNames;
	if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
		comm.refCellNames.add(&refCellNames);
		comm.replText.add(&refCellNames);
		.listener(combo, SWT.Dispose, { mixin(S_TRACE);
			comm.refCellNames.remove(&refCellNames);
			comm.replText.remove(&refCellNames);
		});
	}

	auto menu = new Menu(combo.getShell(), SWT.POP_UP);
	createMenuItem(comm, menu, MenuID.IncSearch, { mixin(S_TRACE);
		.forceFocus(combo, true);
		incSearch.startIncSearch();
	}, () => hasItem);
	new MenuItem(menu, SWT.SEPARATOR);
	combo.setMenu(menu);
	createTextMenu!T(comm, comm.prop, combo, catchMod);

	refCellNames();

	return combo;
}

string[] allCellNames(Commons comm, Summary summ) { mixin(S_TRACE);
	if (!summ) return [];
	bool delegate(CellNameId a, CellNameId b) cmps;
	if (comm.prop.var.etc.logicalSort) {
		cmps = (a, b) => incmp(cast(string)a, cast(string)b) < 0;
	} else {
		cmps = (a, b) => icmp(cast(string)a, cast(string)b) < 0;
	}
	auto s = .sortDlg(summ.useCounter.keys!CellNameId, cmps);
	return .map!((a) => cast(string)a)(s).array();
}

T createCardGroupCombo(T = Combo)(Commons comm, Summary summ, Composite parent, bool delegate() catchMod, string initValue) { mixin(S_TRACE);
	auto combo = new T(parent, SWT.BORDER | SWT.DROP_DOWN);
	combo.setVisibleItemCount(comm.prop.var.etc.comboVisibleItemCount);
	auto hasItem = false;
	auto incSearch = new IncSearch(comm, combo, () => hasItem);

	void refCardGroups() { mixin(S_TRACE);
		if (!summ) return;
		string id = combo.getText();
		combo.removeAll();
		hasItem = false;

		auto values = .addInitValue(comm, allCardGroups(comm, summ), initValue);
		foreach (i, kc; values) { mixin(S_TRACE);
			hasItem = true;
			if (!incSearch.match(kc)) continue;
			combo.add(kc);
		}
		combo.setText(id);
	}

	incSearch.modEvent ~= &refCardGroups;
	if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
		comm.refCardGroups.add(&refCardGroups);
		comm.replText.add(&refCardGroups);
		.listener(combo, SWT.Dispose, { mixin(S_TRACE);
			comm.refCardGroups.remove(&refCardGroups);
			comm.replText.remove(&refCardGroups);
		});
	}

	auto menu = new Menu(combo.getShell(), SWT.POP_UP);
	createMenuItem(comm, menu, MenuID.IncSearch, { mixin(S_TRACE);
		.forceFocus(combo, true);
		incSearch.startIncSearch();
	}, () => hasItem);
	new MenuItem(menu, SWT.SEPARATOR);
	combo.setMenu(menu);
	createTextMenu!T(comm, comm.prop, combo, catchMod);

	refCardGroups();

	return combo;
}

string[] allCardGroups(Commons comm, Summary summ) { mixin(S_TRACE);
	if (!summ) return [];
	bool delegate(CardGroupId a, CardGroupId b) cmps;
	if (comm.prop.var.etc.logicalSort) {
		cmps = (a, b) => incmp(cast(string)a, cast(string)b) < 0;
	} else {
		cmps = (a, b) => icmp(cast(string)a, cast(string)b) < 0;
	}
	auto s = .sortDlg(summ.useCounter.keys!CardGroupId, cmps);
	return .map!((a) => cast(string)a)(s).array();
}

class FlagChooser(F, bool CanSelNothing, bool Random = false) : Composite {
	void delegate()[] modEvent;
	void delegate()[] modEventWithSame;

	private Tree _tree = null;
	private Table _list = null;
	private Button _allExpanded = null;

	static if (Random) {
		private Item _random = null;
		static if (is(F:Step)) {
			private Item _selectedPlayer = null;
		}
	}

	private Commons _comm;
	private Props _prop;
	private Summary _summ = null;
	private UseCounter _uc = null;
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

	private void refFlags(cwx.flag.Flag[] f, Step[] s, cwx.flag.Variant[] v) { mixin(S_TRACE);
		if (!_summ) return;
		static if (is(F:cwx.flag.Flag)) {
			if (!f.length) return;
		} else static if (is(F:Step)) {
			if (!s.length) return;
		} else static if (is(F:cwx.flag.Variant)) {
			if (!v.length) return;
		} else static assert (0);
		auto exp = expandedTable.dup();
		scope (exit) expandedTable = exp;
		saveExpanded();
		refreshFlags();
	}
	private void delFlags(cwx.flag.Flag[] f, Step[] s, cwx.flag.Variant[] v) { mixin(S_TRACE);
		if (!_summ) return;
		static if (is(F:cwx.flag.Flag)) {
			if (!f.length) return;
		} else static if (is(F:Step)) {
			if (!s.length) return;
		} else static if (is(F:cwx.flag.Variant)) {
			if (!v.length) return;
		} else static assert (0);
		auto exp = expandedTable.dup();
		scope (exit) expandedTable = exp;
		saveExpanded();
		refreshFlags();
	}
	@property
	private ref bool[string] expandedTable() { mixin(S_TRACE);
		static if (is(F:cwx.flag.Flag)) {
			return _comm.flagDirExpanded;
		} else static if (is(F:Step)) {
			return _comm.stepDirExpanded;
		} else static if (is(F:cwx.flag.Variant)) {
			return _comm.variantDirExpanded;
		} else static assert (0);
	}
	private F[] flags(FlagDir dir) { mixin(S_TRACE);
		static if (is(F:cwx.flag.Flag)) {
			return dir.flags;
		} else static if (is(F:Step)) {
			return dir.steps;
		} else static if (is(F:cwx.flag.Variant)) {
			return dir.variants;
		} else static assert (0);
	}
	private F[] allFlags(FlagDir dir) { mixin(S_TRACE);
		static if (is(F:cwx.flag.Flag)) {
			return dir.allFlags;
		} else static if (is(F:Step)) {
			return dir.allSteps;
		} else static if (is(F:cwx.flag.Variant)) {
			return dir.allVariants;
		} else static assert (0);
	}
	private bool hasVar(FlagDir dir) { mixin(S_TRACE);
		static if (is(F:cwx.flag.Flag)) {
			return dir.hasFlag;
		} else static if (is(F:Step)) {
			return dir.hasStep;
		} else static if (is(F:cwx.flag.Variant)) {
			return dir.hasVariant;
		} else static assert (0);
	}
	private void refreshFlags() { mixin(S_TRACE);
		static if (is(F:cwx.flag.Flag)) {
			auto icon = _prop.images.flag;
			auto lIcon = _prop.images.localFlag;
		} else static if (is(F:Step)) {
			auto icon = _prop.images.step;
			auto lIcon = _prop.images.localStep;
		} else static if (is(F:cwx.flag.Variant)) {
			auto icon = _prop.images.variant;
			auto lIcon = _prop.images.localVariant;
		} else static assert (0);
		string sel = _selected;
		_selected = "";
		if (_tree) { mixin(S_TRACE);
			if (_tree.isDisposed()) return;
			_tree.setRedraw(false);
			_tree.removeAll();
		} else { mixin(S_TRACE);
			if (_list.isDisposed()) return;
			_list.setRedraw(false);
			_list.removeAll();
		}
		scope (exit) {
			if (_tree) {
				_tree.setRedraw(true);
			} else {
				_list.setRedraw(true);
			}
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
			nof.setText(_prop.msgs.defaultSelection(_prop.msgs.noFlagRef));
			nof.setImage(_prop.images.emptyIcon);
			if (!firstItem) firstItem = nof;
		}
		static if (Random) {
			// ランダム値(代入元)
			if (_tree) { mixin(S_TRACE);
				_random = new TreeItem(_tree, SWT.NONE);
			} else { mixin(S_TRACE);
				_random = new TableItem(_list, SWT.NONE);
			}
			_random.setText(_prop.msgs.defaultSelection(_prop.msgs.randomValue));
			_random.setImage(_prop.images.randomValue);
			// システム値は大文字・小文字を区別しない
			if (.icmp(sel, _prop.sys.randomValue) == 0) { mixin(S_TRACE);
				has = true;
				if (_tree) { mixin(S_TRACE);
					_tree.setSelection([cast(TreeItem)_random]);
				} else { mixin(S_TRACE);
					_list.select(_list.getItemCount() - 1);
				}
				_selected = sel;
			}
			if (!firstItem) firstItem = _random;

			static if (is(F:Step)) {
				if (!_summ || !_summ.legacy) { mixin(S_TRACE);
					// 選択メンバ番号(Wsn.2)
					if (_tree) { mixin(S_TRACE);
						_selectedPlayer = new TreeItem(_tree, SWT.NONE);
					} else { mixin(S_TRACE);
						_selectedPlayer = new TableItem(_list, SWT.NONE);
					}
					_selectedPlayer.setText(_prop.msgs.defaultSelection(_prop.msgs.selectedPlayerValue));
					_selectedPlayer.setImage(_prop.images.selectedPlayerCardNumber);
					if (.icmp(sel, _prop.sys.selectedPlayerCardNumber) == 0) { mixin(S_TRACE);
						has = true;
						if (_tree) { mixin(S_TRACE);
							_tree.setSelection([cast(TreeItem)_selectedPlayer]);
						} else { mixin(S_TRACE);
							_list.select(_list.getItemCount() - 1);
						}
						_selected = sel;
					}
				}
			}
		}
		FlagDir localDir = null;
		auto localName = "";
		if (_uc) { mixin(S_TRACE);
			if (auto ec = cast(LocalVariableOwner)_uc.owner) { mixin(S_TRACE);
				localDir = ec.flagDirRoot;
				localName = .tryFormat(_prop.msgs.localVariablesOwner, ec.id, ec.name);
			}
		}
		if (_tree) { mixin(S_TRACE);
			bool recurse(T)(T parent, FlagDir dir, string name) { mixin(S_TRACE);
				bool selItm = false;
				TreeItem dirItm = null;
				if (dir !is _summ.flagDirRoot) { mixin(S_TRACE);
					if (parent) {
						dirItm = new TreeItem(parent, SWT.NONE);
					} else {
						dirItm = new TreeItem(_tree, SWT.NONE);
					}
					dirItm.setData(dir);
					dirItm.setImage(_prop.images.flagDir);
					dirItm.setText(name);
				}
				auto dirs = dir.subDirs;
				sortedWithName(dirs, _prop.var.etc.logicalSort, (FlagDir child) { mixin(S_TRACE);
					auto flags = this.allFlags(child);
					bool hasChild = false;
					foreach (flag; flags) { mixin(S_TRACE);
						if (!_flagIncSearch.match(flag.path)) continue;
						hasChild = true;
						break;
					}
					if (!hasChild) return;
					selItm |= recurse(dirItm, child, child.name);
				});
				auto flags = this.flags(dir);
				.sortedWithName(flags, _prop.var.etc.logicalSort, (F flag) { mixin(S_TRACE);
					auto path = flag.path;
					if (!has && path == sel) { mixin(S_TRACE);
						has = true;
					}
					_canIncSearch = true;
					if (!_flagIncSearch.match(path)) return;
					TreeItem itm;
					if (dirItm) {
						itm = new TreeItem(dirItm, SWT.NONE);
					} else {
						itm = new TreeItem(_tree, SWT.NONE);
					}
					itm.setData(flag);
					itm.setImage(_uc && _uc.hasID(F.toID(path)) ? lIcon : icon);
					itm.setText(flag.name);
					if (!_tree.getSelectionCount() && path == sel) { mixin(S_TRACE);
						selItm = true;
						_tree.setSelection([itm]);
						_selected = path;
					}
				});
				if (dirItm) { mixin(S_TRACE);
					dirItm.setExpanded(selItm || expandedTable.get(dir.path, _prop.var.etc.expandChooserItems));
				}
				return selItm;
			}
			if (localDir && hasVar(localDir)) { mixin(S_TRACE);
				recurse(_tree, localDir, localName);
			}
			if (_summ) { mixin(S_TRACE);
				recurse(_tree, _summ.flagDirRoot, _prop.msgs.flagDirRoot);
			}
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
			auto flags = _summ ? this.allFlags(_summ.flagDirRoot) : [];
			if (localDir) flags ~= this.allFlags(localDir);
			.sortedWithPath(flags, _prop.var.etc.logicalSort, (F flag) { mixin(S_TRACE);
				auto path = flag.path;
				if (!has && path == sel) { mixin(S_TRACE);
					has = true;
				}
				_canIncSearch = true;
				if (!_flagIncSearch.match(path)) return;
				auto itm = new TableItem(_list, SWT.NONE);
				itm.setData(flag);
				itm.setImage(_uc && _uc.hasID(F.toID(path)) ? lIcon : icon);
				itm.setText(path);
				if (!_list.getSelectionCount() && path == sel) { mixin(S_TRACE);
					_list.select(_list.getItemCount() - 1);
					_selected = path;
				}
				if (!firstItem) firstItem = itm;
			});
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
					} else { mixin(S_TRACE);
						static if (is(F:Step)) {
							if (_selectedPlayer && firstItem is _selectedPlayer) { mixin(S_TRACE);
								_selected = _prop.sys.selectedPlayerCardNumber;
							}
						}
					}
				}
			}
		}

		if (_tree && !_tree.isDisposed()) { mixin(S_TRACE);
			_tree.setEnabled(_canIncSearch);
			_allExpanded.setEnabled(_canIncSearch);
		} else if (_list && !_list.isDisposed()) { mixin(S_TRACE);
			_list.setEnabled(_canIncSearch);
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
			printStackTrace();
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
		if (_tree.isDisposed()) return;
		auto local = FlagDir.SEPARATOR ~ _prop.sys.localVariablePrefix ~ FlagDir.SEPARATOR;
		auto localDirExpanded = expandedTable.get(local, true);
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
		if (local !in flagDirExpanded) flagDirExpanded[local] = localDirExpanded;
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
			_tree = new Tree(this, SWT.SINGLE | SWT.BORDER);
			initTree(_comm, _tree, false, false);
			if (_saveExpanded) { mixin(S_TRACE);
				.listener(_tree, SWT.Dispose, &saveExpanded);
			}
			_allExpanded = createAllExpandedButton(_comm.prop, this, _tree);
		} else { mixin(S_TRACE);
			_list = .rangeSelectableTable(this, SWT.SINGLE | SWT.FULL_SELECTION | SWT.BORDER);
			auto colN = new FullTableColumn(_list, SWT.NONE);
		}
		auto gd = new GridData(GridData.FILL_BOTH);
		gd.widthHint = _prop.var.etc.flagsWidth;
		gd.heightHint = _prop.var.etc.flagsHeight;
		widget.setLayoutData(gd);

		.listener(widget, SWT.Selection, { mixin(S_TRACE);
			Item[] sels;
			auto sel = _selected;
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
						} else { mixin(S_TRACE);
							static if (is(F:Step)) {
								if (_selectedPlayer && sels[0] is _selectedPlayer) { mixin(S_TRACE);
									_selected = _prop.sys.selectedPlayerCardNumber;
								}
							}
						}
					}
				}
			}
			if (_selected != sel) { mixin(S_TRACE);
				foreach (dlg; modEvent) dlg();
			}
			foreach (dlg; modEventWithSame) dlg();
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

	this (Commons comm, Summary summ, UseCounter uc, Composite parent, bool saveExpanded = true) { mixin(S_TRACE);
		super (parent, SWT.NONE);
		_comm = comm;
		_prop = comm.prop;
		_summ = summ;
		_uc = uc;
		_saveExpanded = saveExpanded;
		setLayout(zeroMarginGridLayout(1, true));
		_flagIncSearch = new IncSearch(_comm, this, () => _canIncSearch);
		_flagIncSearch.modEvent ~= &refreshFlags;

		initControl();

		if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
			_comm.refVarSelectStyle.add(&initControl);
			_comm.refFlagAndStep.add(&refFlags);
			_comm.delFlagAndStep.add(&delFlags);
			.listener(this, SWT.Dispose, { mixin(S_TRACE);
				_comm.refVarSelectStyle.remove(&initControl);
				_comm.refFlagAndStep.remove(&refFlags);
				_comm.delFlagAndStep.remove(&delFlags);
			});
		}
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

T createSelectionCombo(T = Combo)(Commons comm, Composite parent, bool delegate() catchMod, string initValue) { mixin(S_TRACE);
	auto combo = new T(parent, SWT.BORDER | SWT.DROP_DOWN);
	combo.setVisibleItemCount(comm.prop.var.etc.comboVisibleItemCount);
	combo.setText(initValue);
	auto hasItem = false;
	auto incSearch = new IncSearch(comm, combo, () => hasItem);

	void refStandardSelections() { mixin(S_TRACE);
		string id = combo.getText();
		combo.removeAll();
		hasItem = false;

		auto values = initValue == "" ? [""] : [];
		values ~= .addInitValue(comm, comm.prop.var.etc.standardSelections.dup, initValue);
		foreach (i, kc; values) { mixin(S_TRACE);
			hasItem = true;
			if (!incSearch.match(kc)) continue;
			combo.add(kc);
		}
		combo.setText(id);
	}

	incSearch.modEvent ~= &refStandardSelections;
	comm.refStandardSelections.add(&refStandardSelections);
	.listener(combo, SWT.Dispose, { mixin(S_TRACE);
		comm.refStandardSelections.remove(&refStandardSelections);
	});

	auto menu = new Menu(combo.getShell(), SWT.POP_UP);
	createMenuItem(comm, menu, MenuID.IncSearch, { mixin(S_TRACE);
		.forceFocus(combo, true);
		incSearch.startIncSearch();
	}, () => hasItem);
	new MenuItem(menu, SWT.SEPARATOR);
	combo.setMenu(menu);
	createTextMenu!T(comm, comm.prop, combo, catchMod);

	refStandardSelections();

	return combo;
}

T createVariableCombo(T = Combo, F)(Commons comm, in Summary summ, in UseCounter uc, Composite parent, bool delegate() catchMod, string initValue) { mixin(S_TRACE);
	auto combo = new T(parent, SWT.BORDER | SWT.DROP_DOWN);
	combo.setVisibleItemCount(comm.prop.var.etc.comboVisibleItemCount);
	combo.setText(initValue);
	auto hasItem = false;
	auto incSearch = new IncSearch(comm, combo, () => hasItem);

	void refVariables() { mixin(S_TRACE);
		string id = combo.getText();
		combo.removeAll();
		hasItem = false;

		const(F)[] vars(in FlagDir dir) { mixin(S_TRACE);
			static if (is(F:cwx.flag.Flag)) {
				return dir.allFlags;
			} else static if (is(F:Step)) {
				return dir.allSteps;
			} else static if (is(F:cwx.flag.Variant)) {
				return dir.allVariants;
			} else static assert (0);
		}
		auto list = .allVars!F(summ.flagDirRoot, uc);
		// BUG: list.dupが機能しないのでキャストが必要 dmd 2.085.0
		sortedWithPath(cast(F[])list, comm.prop.var.etc.logicalSort, (F v) { mixin(S_TRACE);
			hasItem = true;
			auto path = v.path;
			if (!incSearch.match(path)) return;
			combo.add(path);
		});
		combo.setText(id);
	}
	void refFlagAndStep(cwx.flag.Flag[] flags, Step[] steps, cwx.flag.Variant[] variants) { mixin(S_TRACE);
		static if (is(F:cwx.flag.Flag)) {
			if (flags.length) refVariables();
		} else static if (is(F:Step)) {
			if (steps.length) refVariables();
		} else static if (is(F:cwx.flag.Variant)) {
			if (variants.length) refVariables();
		}
	}

	incSearch.modEvent ~= &refVariables;
	comm.refFlagAndStep.add(&refFlagAndStep);
	.listener(combo, SWT.Dispose, { mixin(S_TRACE);
		comm.refFlagAndStep.remove(&refFlagAndStep);
	});

	auto menu = new Menu(combo.getShell(), SWT.POP_UP);
	createMenuItem(comm, menu, MenuID.IncSearch, { mixin(S_TRACE);
		.forceFocus(combo, true);
		incSearch.startIncSearch();
	}, () => hasItem);
	new MenuItem(menu, SWT.SEPARATOR);
	combo.setMenu(menu);
	createTextMenu!T(comm, comm.prop, combo, catchMod);

	refVariables();

	return combo;
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
	static if (StartArea) {
		private ulong _startArea = 0UL;
	}
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
			auto exp = expandedTable.dup();
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
		auto sel = _selected;
		_selected = 0UL;
		static if (StartArea) auto existsStartArea = false;
		if (_tree) { mixin(S_TRACE);
			_tree.setRedraw(false);
			_tree.removeAll();
		} else { mixin(S_TRACE);
			_list.setRedraw(false);
			_list.removeAll();
		}
		scope (exit) {
			if (_tree) {
				_tree.setRedraw(true);
			} else {
				_list.setRedraw(true);
			}
		}
		_canIncSearch = false;
		bool has = false;
		Item firstItem = null;
		static if (is(A:Area)) {
			auto arr = _summ ? _summ.areas : [];
		} else static if (is(A:Battle)) {
			auto arr = _summ ? _summ.battles : [];
		} else static if (is(A:Package)) {
			auto arr = _summ ? _summ.packages : [];
		} else static if (is(A:CastCard)) {
			auto arr = _summ ? _summ.casts : [];
		} else static if (is(A:InfoCard)) {
			auto arr = _summ ? _summ.infos : [];
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
					foreach (i, dir; dirs) { mixin(S_TRACE);
						auto fPath = dirs[0 .. i + 1].join("\\");
						auto path = fPath.toLower();
						auto p = path in itmTable;
						if (p) { mixin(S_TRACE);
							itm = *p;
						} else { mixin(S_TRACE);
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
					static if (StartArea) {
						if (a.id == _startArea) existsStartArea = true;
					}
					_canIncSearch = true;
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
					aItm.setImage(image(aItm));
				}
				foreach (dirName, itm; itmTable) {
					if (!itm) continue;
					itm.setExpanded(expandedTable.get(dirName, _prop.var.etc.expandChooserItems));
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
				static if (StartArea) {
					if (a.id == _startArea) existsStartArea = true;
				}
				_canIncSearch = true;
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

		if (_tree && !_tree.isDisposed()) { mixin(S_TRACE);
			_tree.setEnabled(_canIncSearch);
			_allExpanded.setEnabled(_canIncSearch);
		} else if (_list && !_list.isDisposed()) { mixin(S_TRACE);
			_list.setEnabled(_canIncSearch);
		}

		static if (StartArea) {
			if (!existsStartArea) { mixin(S_TRACE);
				_startArea = arr.length ? arr[0].id : 0UL;
				foreach (dlg; modEvent) dlg();
			}
		} else {
			if (_selected != sel) { mixin(S_TRACE);
				foreach (dlg; modEvent) dlg();
			}
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
				auto a = cast(Area)itm.getData();
				if (a.id == _startArea) { mixin(S_TRACE);
					return _prop.images.startArea;
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
			printStackTrace();
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
			_tree = new Tree(this, SWT.SINGLE | SWT.BORDER);
			initTree(_comm, _tree, false, false);
			_allExpanded = createAllExpandedButton(_comm.prop, this, _tree);
		} else { mixin(S_TRACE);
			_list = .rangeSelectableTable(this, SWT.SINGLE | SWT.FULL_SELECTION | SWT.BORDER);
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
			static if (!StartArea) {
				foreach (dlg; modEvent) dlg();
			}
		});
		static if (StartArea) {
			static assert (is(A:Area));
			void selected(Item itm) { mixin(S_TRACE);
				auto a = cast(A)itm.getData();
				if (!a) return;
				if (_startArea != a.id) { mixin(S_TRACE);
					_startArea = a.id;
					updateImages();
					foreach (dlg; modEvent) dlg();
				}
			}
			.listener(widget, SWT.MouseDoubleClick, (e) { mixin(S_TRACE);
				Item itm;
				if (_tree) { mixin(S_TRACE);
					itm = _tree.getItem(new Point(e.x, e.y));
				} else { mixin(S_TRACE);
					itm = _list.getItem(new Point(e.x, e.y));
				}
				if (!itm) return;
				selected(itm);
			});
			.listener(widget, SWT.KeyDown, (e) { mixin(S_TRACE);
				if (.isEnterKey(e.keyCode)) { mixin(S_TRACE);
					if (_tree) { mixin(S_TRACE);
						auto sels = _tree.getSelection();
						if (!sels.length) return;
						selected(sels[0]);
					} else { mixin(S_TRACE);
						auto sels = _list.getSelection();
						if (!sels.length) return;
						selected(sels[0]);
					}
				}
			});
		} else {
			.listener(widget, SWT.MouseDoubleClick, &openAreaView);
		}

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
		_areaIncSearch = new IncSearch(_comm, this, () => _canIncSearch);
		_areaIncSearch.modEvent ~= &refreshAreas;

		initControl();

		if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
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
	}

	@property
	void selected(ulong id) { mixin(S_TRACE);
		_selected = id;
		refreshAreas();
	}
	@property
	const
	ulong selected() { return _selected; }

	static if (StartArea) {
		@property
		void startArea(ulong id) { mixin(S_TRACE);
			_startArea = id;
			updateImages();
		}
		@property
		const
		ulong startArea() { return _startArea; }
	}
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
