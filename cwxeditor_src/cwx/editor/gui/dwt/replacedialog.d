
module cwx.editor.gui.dwt.replacedialog;

import cwx.summary;
import cwx.event;
import cwx.coupon;
import cwx.utils;
import cwx.card;
import cwx.motion;
import cwx.flag;
import cwx.usecounter;

import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.utils;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.commons;

import std.string;

import dwt.widgets.Shell;
import dwt.widgets.Text;
import dwt.widgets.Button;
import dwt.widgets.Composite;
import dwt.widgets.Control;
import dwt.widgets.Group;
import dwt.widgets.Label;
import dwt.widgets.MessageBox;
import dwt.layout.GridLayout;
import dwt.layout.GridData;

import dwtx.jface.dialogs.IDialogConstants;
import dwtx.jface.dialogs.Dialog;

/// テキストの置換を行うダイアログ。
class ReplaceDialog : dwtx.jface.dialogs.Dialog.Dialog {
private:
	Commons _comm;
	Props _prop;
	Summary _summ;

	Text _from;
	Text _to;

	/// 貼り紙
	Button _summary;
	/// シナリオ出現条件
	Button _rCoupon;
	/// メッセージ
	Button _msg;
	/// カード名
	Button _cardName;
	/// カード解説
	Button _cardDesc;
	/// イベントテキスト
	Button _event;
	/// フラグ/ステップ
	Button _flag;
	/// クーポン
	Button _coupon;
	/// ゴシップ
	Button _gossip;
	/// 終了印
	Button _end;
	/// エリア/バトル/パッケージ名
	Button _area;
	/// キーコード
	Button _keyCode;

	bool summary() {return _summary.getSelection;}
	bool msg() {return _msg.getSelection;}
	bool cardName() {return _cardName.getSelection;}
	bool cardDesc() {return _cardDesc.getSelection;}
	bool event() {return _event.getSelection;}
	bool flag() {return _flag.getSelection;}
	bool coupon() {return _coupon.getSelection;}
	bool gossip() {return _gossip.getSelection;}
	bool end() {return _end.getSelection;}
	bool area() {return _area.getSelection;}
	bool keyCode() {return _keyCode.getSelection;}
public:
	this(Commons comm, Props prop, Shell shell, Summary summ) {
		super(shell);
		_comm = comm;
		_prop = prop;
		_summ = summ;
	}

protected:
	override void configureShell(Shell shell) {
		super.configureShell(shell);
		shell.setText = _prop.msgs.dlgTitReplaceText;
	}

	override Control createDialogArea(Composite parent) {
		auto area = cast(Composite) super.createDialogArea(parent);
		area.setLayout = new GridLayout(1, true);
		{
			auto grp = new Group(area, DWT.NONE);
			grp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			grp.setText = _prop.msgs.replText;
			grp.setLayout = new GridLayout(2, false);
			auto lf = new Label(grp, DWT.NONE);
			lf.setText = _prop.msgs.replTextFrom;
			_from = new Text(grp, DWT.BORDER);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.widthHint = _prop.var.etc.nameWidth;
			_from.setLayoutData = gd;
			auto lt = new Label(grp, DWT.NONE);
			lt.setText = _prop.msgs.replTextTo;
			_to = new Text(grp, DWT.BORDER);
			_to.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
		}
		{
			auto grp = new Group(area, DWT.NONE);
			grp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			grp.setText = _prop.msgs.replTextTarget;
			grp.setLayout = new CenterLayout;
			auto comp = new Composite(grp, DWT.NONE);
			comp.setLayout = zeroGridLayout(2, true);
			Button createB(string text) {
				auto b = new Button(comp, DWT.CHECK);
				b.setText = text;
				b.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				return b;
			}
			_summary = createB(_prop.msgs.replTextSummary);
			_msg = createB(_prop.msgs.replTextMessage);
			_cardName = createB(_prop.msgs.replTextCardName);
			_cardDesc = createB(_prop.msgs.replTextCardDesc);
			_event = createB(_prop.msgs.replTextEventText);
			_flag = createB(_prop.msgs.replTextFlagAndStep);
			_coupon = createB(_prop.msgs.replTextCoupon);
			_gossip = createB(_prop.msgs.replTextGossip);
			_end = createB(_prop.msgs.replTextEndScenario);
			_area = createB(_prop.msgs.replTextAreaName);
			_keyCode = createB(_prop.msgs.replTextKeyCode);
		}
		_summary.setSelection = _prop.var.etc.replaceTextSummary;
		_msg.setSelection = _prop.var.etc.replaceTextMessage;
		_cardName.setSelection = _prop.var.etc.replaceTextCardName;
		_cardDesc.setSelection = _prop.var.etc.replaceTextCardDescription;
		_event.setSelection = _prop.var.etc.replaceTextEventText;
		_flag.setSelection = _prop.var.etc.replaceTextFlagAndStep;
		_coupon.setSelection = _prop.var.etc.replaceTextCoupon;
		_gossip.setSelection = _prop.var.etc.replaceTextGossip;
		_end.setSelection = _prop.var.etc.replaceTextEndScenario;
		_area.setSelection = _prop.var.etc.replaceTextAreaName;
		_keyCode.setSelection = _prop.var.etc.replaceTextKeyCode;
		return area;
	}

	override void createButtonsForButtonBar(Composite parent) {
		createButton(parent, IDialogConstants.OK_ID, _prop.msgs.replace, true);
		createButton(parent, IDialogConstants.CLOSE_ID, _prop.msgs.replaceExit, false);
	}

	private void repl(string delegate() get, void delegate(string) set, ref size_t count) {
		string from = _from.getText;
		string to = _to.getText;
		string text = get();
		count += .count(text, from);
		set(.replace(text, from, to));
	}

	private void replFlagName(F)(FlagDir parent, F flag, ref size_t count) {
		string from = _from.getText;
		string to = _to.getText;
		string text = flag.name;
		count += .count(text, from);
		flag.name = parent.validName(.replace(text, from, to));
	}

	private void replRqCoupons(C)(C targ, ref size_t count) {
		auto coupons = targ.rCoupons;
		foreach (ref cp; coupons) {
			repl({return cp;}, (string t) {cp = t;}, count);
		}
		targ.rCoupons = coupons;
	}

	private void replKeyCode(C)(C targ, ref size_t count) {
		if (keyCode) {
			auto kcs = targ.keyCodes.dup;
			foreach (ref kc; kcs) {
				repl({return kc;}, (string t) {kc = t;}, count);
			}
			targ.keyCodes = kcs;
		}
	}

	private void replCard(C)(C card, ref size_t count) {
		string from = _from.getText;
		string to = _to.getText;
		if (cardName) {
			repl(&card.name, &card.name, count);
		}
		if (cardDesc) {
			repl(&card.desc, &card.desc, count);
		}
		static if (is (C : EffectCard)) {
			replKeyCode(card, count);
		}
	}
	private void replEvent(EventTreeOwner owner, ref size_t count) {
		string from = _from.getText;
		string to = _to.getText;
		void replE(Content eo, Content e) {
			assert (eo.detail.owner);
			if (event && (!eo || eo.type == CType.TALK_MESSAGE || eo.type == CType.TALK_DIALOG)) {
				repl(&e.name, &e.name, count);
			}
			if (coupon) {
				repl(&e.coupon, &e.coupon, count);
			}
			if (gossip) {
				repl(&e.gossip, &e.gossip, count);
			}
			if (end) {
				repl(&e.completeStamp, &e.completeStamp, count);
			}
			if (msg) {
				repl(&e.text, &e.text, count);
				auto dlgs = e.dialogs;
				foreach (dlg; dlgs) {
					if (msg) {
						repl(&dlg.text, &dlg.text, count);
					}
					if (coupon) {
						replRqCoupons(dlg, count);
					}
				}
				e.dialogs = dlgs;
			}
			foreach (m; e.motions) {
				if (m.beast) {
					replCard(m.beast, count);
				}
			}
			if (e.detail.owner) {
				foreach (child; e.next) {
					replE(e, child);
				}
			}
		}
		foreach (et; owner.trees) {
			foreach (e; et.starts) {
				replE(null, e);
			}
			replKeyCode(et, count);
		}
	}
	override void buttonPressed(int buttonId) {
		if (buttonId == IDialogConstants.OK_ID) {
			string from = _from.getText;
			if (from.length == 0) return;
			string to = _to.getText;
			if (from == to) return;
			size_t count = 0;
			if (summary) {
				repl(&_summ.scenarioName, &_summ.scenarioName, count);
				repl(&_summ.desc, &_summ.desc, count);
			}
			if (coupon) {
				replRqCoupons(_summ, count);
			}
			foreach (cc; _summ.casts) {
				replCard(cc, count);
				if (coupon) {
					auto coupons = cc.coupons.dup;
					foreach (ref cp; coupons) {
						repl({return cp.name;},
							(string t) {cp = new Coupon(t, cp.value);}, count);
					}
					cc.coupons = coupons;
				}
				foreach (c; cc.skills) {
					replCard(c, count);
					replEvent(c, count);
				}
				foreach (c; cc.items) {
					replCard(c, count);
					replEvent(c, count);
				}
				foreach (c; cc.beasts) {
					replCard(c, count);
					replEvent(c, count);
				}
			}
			foreach (c; _summ.skills) {
				replCard(c, count);
				replEvent(c, count);
			}
			foreach (c; _summ.items) {
				replCard(c, count);
				replEvent(c, count);
			}
			foreach (c; _summ.beasts) {
				replCard(c, count);
				replEvent(c, count);
			}
			foreach (c; _summ.infos) {
				replCard(c, count);
			}
			foreach (a; _summ.areas) {
				if (area) {
					repl(&a.name, &a.name, count);
				}
				foreach (c; a.cards) {
					replCard(c, count);
				}
				replEvent(a, count);
			}
			foreach (b; _summ.battles) {
				if (area) {
					repl(&b.name, &b.name, count);
				}
				replEvent(b, count);
			}
			foreach (p; _summ.packages) {
				if (area) {
					repl(&p.name, &p.name, count);
				}
				replEvent(p, count);
			}
			if (flag) {
				void replFS(FlagDir dir) {
					foreach (f; dir.flags) {
						string old = f.name;
						replFlagName(dir, f, count);
						_summ.useCounter.change(toFlagId(old), toFlagId(f.name));
						repl(&f.on, &f.on, count);
						repl(&f.off, &f.off, count);
					}
					foreach (s; dir.steps) {
						string old = s.name;
						replFlagName(dir, s, count);
						_summ.useCounter.change(toStepId(old), toStepId(s.name));
						foreach (i, v; s.values) {
							repl({return v;}, (string t) {s.setValue(i, t);}, count);
						}
					}
					foreach (c; dir.subDirs) {
						replFS(c);
					}
				}
				replFS(_summ.flagDirRoot);
			}
			if (count > 0) {
				_comm.refUseCount.call;
				_comm.replText.call;
			}
			MessageBox.showInfo(_prop.msgs.dlgMsgReplTextResult(count),
				_prop.msgs.dlgTitReplTextResult, getShell);
			return;
		} else {
			_prop.var.etc.replaceTextSummary = _summary.getSelection;
			_prop.var.etc.replaceTextMessage = _msg.getSelection;
			_prop.var.etc.replaceTextCardName = _cardName.getSelection;
			_prop.var.etc.replaceTextCardDescription = _cardDesc.getSelection;
			_prop.var.etc.replaceTextEventText = _event.getSelection;
			_prop.var.etc.replaceTextFlagAndStep = _flag.getSelection;
			_prop.var.etc.replaceTextCoupon = _coupon.getSelection;
			_prop.var.etc.replaceTextGossip = _gossip.getSelection;
			_prop.var.etc.replaceTextEndScenario = _end.getSelection;
			_prop.var.etc.replaceTextAreaName = _area.getSelection;
			_prop.var.etc.replaceTextKeyCode = _keyCode.getSelection;

			setReturnCode(IDialogConstants.OK_ID);
			close;
			super.buttonPressed(IDialogConstants.OK_ID);
		}
	}
}
