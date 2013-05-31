
module cwx.editor.gui.dwt.chooser;

import cwx.utils;
import cwx.types;

import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.incsearch;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.dutils;

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
