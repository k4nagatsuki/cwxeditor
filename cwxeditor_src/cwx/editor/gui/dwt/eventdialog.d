
module cwx.editor.gui.dwt.eventdialog;

import cwx.area;
import cwx.background;
import cwx.card;
import cwx.event;
import cwx.features;
import cwx.flag;
import cwx.menu;
import cwx.msgutils;
import cwx.path;
import cwx.skin;
import cwx.structs;
import cwx.summary;
import cwx.types;
import cwx.types;
import cwx.usecounter;
import cwx.utils;
import cwx.warning;

import cwx.editor.gui.sound;

import cwx.editor.gui.dwt.abilityview;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.areaview;
import cwx.editor.gui.dwt.areaviewutils;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.chooser;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.couponview;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.effectcarddialog;
import cwx.editor.gui.dwt.incsearch;
import cwx.editor.gui.dwt.keycodeview;
import cwx.editor.gui.dwt.materialselect;
import cwx.editor.gui.dwt.messageutils;
import cwx.editor.gui.dwt.motionview;
import cwx.editor.gui.dwt.spcarddialog;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.undo;

import std.algorithm : countUntil, max;
import std.array;
import std.conv;
import std.math;
import std.path;
import std.string : toLower, icmp;
import std.traits;

import org.eclipse.swt.all;

immutable transitionSpeedDef = Content.transitionSpeed_min + ((Content.transitionSpeed_max - Content.transitionSpeed_min) / 2);

abstract class EventDialog : AbsDialog {
	private Commons _comm;
	private Props _prop;
	private Summary _summ;
	private Content _parent;
	private Content _evt;
	private CType _type;

	private class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			_comm.delContent.remove(&delContent);
			_comm.refSkin.remove(&refSkin);
			_comm.refDataVersion.remove(&refDataVersion);
			_comm.refTargetVersion.remove(&refreshWarning);
		}
	}
	private void delContent(Content c) { mixin(S_TRACE);
		if ((_evt && _evt.isDescendant(c)) || (_parent && _parent.isDescendant(c))) { mixin(S_TRACE);
			forceCancel();
		}
	}
	protected void refreshWarning() { mixin(S_TRACE);
		// 処理無し
	}

	this (Commons comm, Props prop, Shell shell, Summary summ, CType type, Content parent, Content evt, bool resizable, DSize size, bool eClose, bool rightGroup = false) in { mixin(S_TRACE);
		assert (!evt || evt.type is type);
	} body { mixin(S_TRACE);
		super (prop, shell, false, .tryFormat(prop.msgs.dlgTitContent, prop.msgs.contentName(type)), prop.images.content(type), resizable, size, true, true, [], rightGroup);
		enterClose = eClose;
		_comm = comm;
		_prop = prop;
		_summ = summ;
		_type = type;
		_parent = parent;
		_evt = evt;
		if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
			_comm.delContent.add(&delContent);
			_comm.refSkin.add(&refSkin);
			_comm.refDataVersion.add(&refDataVersion);
			_comm.refTargetVersion.add(&refreshWarning);
			getShell().addDisposeListener(new Dispose);
		}
		// コンテントの作成時は、すぐに適用を押してコンテントを配置できるように
		// 適用ボタンを有効化する(ただしparentが無い場合は初期値設定なので除外)
		if ((!_evt || !_evt.parent) && _parent) applyEnabled(true);
	}

	@property
	Content event() { mixin(S_TRACE);
		return _evt;
	}
	@property protected Commons comm() { return _comm; }
	@property protected Props prop() { return _prop; }
	@property protected Summary summ() { return _summ; }
	@property protected Content evt() { return _evt; }
	@property protected Content parent() { return _parent; }
	@property protected void evt(Content evt) { _evt = evt; }
	@property protected CType type() { return _type; }

	protected void refSkin() { }
	protected void refDataVersion() { mixin(S_TRACE);
		refreshWarning();
	}

	bool openCWXPath(string path, bool shellActivate) { mixin(S_TRACE);
		return cpempty(path);
	}
}

class ContentCommentDialog : AbsDialog {
	private Commons _comm;
	private Props _prop;
	private Content _parent;
	private Content _evt;
	private Text _comment;

	private class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			_comm.delContent.remove(&delContent);
		}
	}
	private void delContent(Content c) { mixin(S_TRACE);
		if ((_evt && _evt.isDescendant(c)) || (_parent && _parent.isDescendant(c))) { mixin(S_TRACE);
			forceCancel();
		}
	}

	this (Commons comm, Props prop, Shell shell, Content parent, Content evt) in { mixin(S_TRACE);
		assert (evt);
	} body { mixin(S_TRACE);
		super (prop, shell, false, prop.msgs.dlgTitComment, prop.images.menu(MenuID.Comment), true, prop.var.commentDlg, true);
		_comm = comm;
		_prop = prop;
		_parent = parent;
		_evt = evt;
		_comm.delContent.add(&delContent);
		getShell().addDisposeListener(new Dispose);
	}

	override void setup(Composite area) { mixin(S_TRACE);
		auto cl = new CenterLayout;
		cl.fillHorizontal = true;
		cl.fillVertical = true;
		area.setLayout(cl);
		_comment = new Text(area, SWT.BORDER | SWT.MULTI | SWT.WRAP | SWT.V_SCROLL);
		mod(_comment);
		_comment.setTabs(_prop.var.etc.tabs);
		_comment.setText(_evt.comment);
		createTextMenu!Text(_comm, _prop, _comment, &catchMod);
		auto font = _comment.getFont();
		auto fSize = font ? cast(uint) font.getFontData()[0].height : 0;
		_comment.setFont(new Font(Display.getCurrent(), dwtData(_prop.looks.textDlgFont(fSize))));
		_comment.setSelection(cast(int)to!dstring(_comment.getText()).length);
		closeEvent ~= () { mixin(S_TRACE);
			_comment.getFont().dispose();
		};
	}

	override bool apply() { mixin(S_TRACE);
		_evt.comment = lastRet(wrapReturnCode(_comment.getText()));
		return true;
	}
}

/// 適用範囲・判定対象の設定欄。
private class RangePanel : Composite {
	private CType _type;

	private Commons _comm;
	private Summary _summ;
	private UseCounter _uc;

	private Button[Range] _range;
	private const Range[] _ranges;
	private RadioGroup!Button _radioGrp;

	private Combo _coupon = null;
	private Combo _couponType = null;
	private CouponType[] _couponTypes = [];
	private bool _couponUpdated = false;
	private string _initCoupon = "";

	string[] warnings() { mixin(S_TRACE);
		string[] ws;
		auto b = _range.get(Range.COUPON_HOLDER, null);
		if (b && b.getSelection()) { mixin(S_TRACE);
			switch (_type) {
			case CType.EFFECT:
				if (!_comm.prop.isTargetVersion(_summ, "2")) { mixin(S_TRACE);
					ws ~= .tryFormat(_comm.prop.msgs.warningCouponHolder, _comm.prop.msgs.contentName(_type), "2");
				}
				break;
			case CType.GET_COUPON:
			case CType.LOSE_COUPON:
				if (!_comm.prop.isTargetVersion(_summ, "3")) { mixin(S_TRACE);
					ws ~= .tryFormat(_comm.prop.msgs.warningCouponHolder, _comm.prop.msgs.contentName(_type), "3");
				}
				break;
			default:
				assert (0);
			}
			ws ~= .couponWarnings(_comm.prop.parent, _summ, _comm.prop.var.etc.targetVersion, _coupon.getText(), false, _comm.prop.msgs.couponForRange);
		}
		b = _range.get(Range.CARD_TARGET, null);
		if (b && b.getSelection()) { mixin(S_TRACE);
			if (!_comm.prop.isTargetVersion(_summ, "2")) { mixin(S_TRACE);
				ws ~= _comm.prop.msgs.warningCardTarget;
			}
		}
		return ws;
	}

	private void refDataVersion() { mixin(S_TRACE);
		auto range = this.range;
		if ((range is Range.COUPON_HOLDER || range is Range.CARD_TARGET) && _summ.legacy) { mixin(S_TRACE);
			_radioGrp.select(_range[_ranges[0]]);
		}
		updateEnabled();
	}
	private void updateEnabled() { mixin(S_TRACE);
		auto b = _range.get(Range.COUPON_HOLDER, null);
		if (b) { mixin(S_TRACE);
			if (b && b.getSelection()) { mixin(S_TRACE);
				_coupon.setEnabled(true);
				_couponType.setEnabled(true);
			} else { mixin(S_TRACE);
				_coupon.setEnabled(false);
				_couponType.setEnabled(false);
			}
			b.setEnabled(!_summ.legacy);
		}
		b = _range.get(Range.CARD_TARGET, null);
		if (b) { mixin(S_TRACE);
			b.setEnabled(!_summ.legacy);
		}
	}

	this (Commons comm, Summary summ, UseCounter uc, Composite parent, in Range[] ranges, string initCoupon, string title, bool horizontal, AbsDialog modDlg,
			in Content evt, bool delegate() catchMod, void delegate() refreshWarning, CType type) { mixin(S_TRACE);
		super (parent, SWT.NONE);
		_type = type;
		_comm = comm;
		_summ = summ;
		_uc = uc;
		_ranges = ranges;
		if (evt) _initCoupon = evt.holdingCoupon;
		auto prop = comm.prop;
		setLayout(new FillLayout);
		auto grp = new Group(this, SWT.NONE);
		grp.setText(title);
		auto cl = new CenterLayout;
		if (ranges.contains(Range.COUPON_HOLDER)) cl.fillHorizontal = true;
		cl.fillVertical = true;
		grp.setLayout(cl);
		auto mainComp = new Composite(grp, SWT.NONE);
		if (horizontal) { mixin(S_TRACE);
			mainComp.setLayout(zeroMarginGridLayout(cast(int)ranges.length, false));
		} else {
			mainComp.setLayout(zeroMarginGridLayout(1, false));
		}
		Composite couponComp = null;
		_radioGrp = new RadioGroup!Button;
		Button selB = null;
		foreach (i, range; ranges) { mixin(S_TRACE);
			Control[] cs;
			int fillHorizontal = SWT.NONE;
			auto radio = new Button(mainComp, SWT.RADIO);
			cs ~= radio;
			if (range is Range.COUPON_HOLDER) { mixin(S_TRACE);
				couponComp = new Composite(mainComp, SWT.NONE);
				couponComp.setLayout(zeroMarginGridLayout(1, true));
				fillHorizontal = GridData.FILL_HORIZONTAL;
				cs ~= couponComp;
			}
			modDlg.mod(radio);
			foreach (c; cs) { mixin(S_TRACE);
				if (horizontal) { mixin(S_TRACE);
					c.setLayoutData(new GridData(GridData.FILL_BOTH));
				} else { mixin(S_TRACE);
					c.setLayoutData(new GridData(GridData.GRAB_VERTICAL | fillHorizontal));
				}
			}
			radio.setText(prop.msgs.rangeName(range));
			_range[range] = radio;
			if (evt && evt.range is range) { mixin(S_TRACE);
				selB = radio;
			}
			_radioGrp.append(radio);
			if (range is Range.CARD_TARGET) { mixin(S_TRACE);
				radio.setToolTipText(prop.msgs.rangeDescCardTarget);
			}
		}
		if (!selB) { mixin(S_TRACE);
			selB = _range[_ranges[0]];
		}
		_radioGrp.select(selB);
		_radioGrp.modEvent ~= &updateEnabled;
		_radioGrp.modEvent ~= refreshWarning;

		if (Range.COUPON_HOLDER in _range) { mixin(S_TRACE);
			auto comp = new Composite(couponComp, SWT.NONE);
			auto cgd = new GridData(GridData.FILL_HORIZONTAL);
			if (horizontal) cgd.horizontalSpan = cast(int)ranges.length;
			comp.setLayoutData(cgd);

			comp.setLayout(zeroGridLayout(2, false));

			auto ccType = CouponComboType.AllCoupons;
			_coupon = createCouponCombo(comm, _summ, _uc, comp, catchMod, ccType, initCoupon);
			modDlg.mod(_coupon);
			_coupon.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));

			_couponType = new Combo(comp, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
			_couponType.setVisibleItemCount(prop.var.etc.comboVisibleItemCount);
			_couponTypes = [CouponType.Normal, CouponType.Hide, CouponType.Dur, CouponType.DurBattle, CouponType.System];
			foreach (coType; _couponTypes) { mixin(S_TRACE);
				auto typeName = prop.msgs.couponTypeShortDesc(coType);
				final switch (coType) {
				case CouponType.Normal:
					break;
				case CouponType.Hide:
					typeName = .tryFormat(typeName, prop.sys.couponHide);
					break;
				case CouponType.Dur:
					typeName = .tryFormat(typeName, prop.sys.couponDur);
					break;
				case CouponType.DurBattle:
					typeName = .tryFormat(typeName, prop.sys.couponDurBattle);
					break;
				case CouponType.System:
					typeName = .tryFormat(typeName, prop.sys.couponSystem);
					break;
				}
				_couponType.add(typeName);
			}
			.listener(_couponType, SWT.Selection, { mixin(S_TRACE);
				_coupon.setText(prop.sys.convCoupon(_coupon.getText(), _couponTypes[_couponType.getSelectionIndex()], false));
			});
			void updateCouponTypeImpl() { mixin(S_TRACE);
				auto t = prop.sys.couponType(_coupon.getText());
				foreach (i, coType; _couponTypes) { mixin(S_TRACE);
					if (coType is t) { mixin(S_TRACE);
						_couponType.select(cast(int)i);
					}
				}
			}
			void updateCouponType() { mixin(S_TRACE);
				updateCouponTypeImpl();
				refreshWarning();
			}
			.listener(_coupon, SWT.Modify, {
				updateCouponType();
				_couponUpdated = true;
			});
			updateCouponTypeImpl();
		}

		if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
			comm.refDataVersion.add(&refDataVersion);
			.listener(this, SWT.Dispose, { mixin(S_TRACE);
				comm.refDataVersion.remove(&refDataVersion);
			});
		}

		refDataVersion();
	}

	@property
	Range range() { mixin(S_TRACE);
		foreach (range, b; _range) { mixin(S_TRACE);
			if (b.getSelection()) return range;
		}
		return _ranges[0];
	}

	@property
	string holdingCoupon() { mixin(S_TRACE);
		if (_couponUpdated || range is Range.COUPON_HOLDER) { mixin(S_TRACE);
			return _coupon.getText();
		} else { mixin(S_TRACE);
			return _initCoupon;
		}
	}
}

/// 背景切替方式と背景切替速度。
class TransitionPanel : Composite {
	private Combo _ts;
	private Spinner _tsSpeed;
	private Transition[int] _tsTbl;
	private const Summary _summ;

	this (Commons comm, Summary summ, Composite parent, bool horizontal, in Content evt, AbsDialog modDlg) { mixin(S_TRACE);
		super (parent, SWT.NONE);
		auto prop = comm.prop;
		_summ = summ;
		if (horizontal) { mixin(S_TRACE);
			this.setLayout(zeroMarginGridLayout(5, false));
		} else {
			this.setLayout(zeroMarginGridLayout(3, false));
		}
		auto lt = new Label(this, SWT.NONE);
		lt.setText(prop.msgs.transition);
		_ts = new Combo(this, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
		modDlg.mod(_ts);
		if (!horizontal) { mixin(S_TRACE);
			auto tgd = new GridData;
			tgd.horizontalSpan = 2;
			_ts.setLayoutData(tgd);
		}
		_ts.setVisibleItemCount(prop.var.etc.comboVisibleItemCount);
		.listener(_ts, SWT.Selection, &refreshTS);
		foreach (i, t; ALL_TRANSITION) { mixin(S_TRACE);
			auto s = prop.msgs.transitionName(t);
			if (t is Transition.DEFAULT) s = prop.msgs.defaultSelection(s);
			_ts.add(s);
			_tsTbl[cast(int)i] = t;
			if (evt && t == evt.transition) _ts.select(cast(int)i);
		}
		auto ls = new Label(this, SWT.NONE);
		ls.setText(prop.msgs.transitionSpeed);
		_tsSpeed = new Spinner(this, SWT.BORDER);
		initSpinner(_tsSpeed);
		modDlg.mod(_tsSpeed);
		_tsSpeed.setMaximum(Content.transitionSpeed_max);
		_tsSpeed.setMinimum(Content.transitionSpeed_min);
		auto hint = new Label(this, SWT.NONE);
		hint.setText(.tryFormat(prop.msgs.rangeHint, Content.transitionSpeed_min, Content.transitionSpeed_max));

		if (evt) { mixin(S_TRACE);
			_tsSpeed.setSelection(evt.transitionSpeed);
		} else { mixin(S_TRACE);
			_ts.select(0);
			_tsSpeed.setSelection(.transitionSpeedDef);
		}
		refreshTS();
		if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
			comm.refDataVersion.add(&refreshTS);
			.listener(this, SWT.Dispose, { mixin(S_TRACE);
				comm.refDataVersion.remove(&refreshTS);
			});
		}
	}

	private void refreshTS() { mixin(S_TRACE);
		_ts.setEnabled(!_summ || !_summ.legacy);
		_tsSpeed.setEnabled((!_summ || !_summ.legacy) && transition !is Transition.DEFAULT && transition !is Transition.NONE);
	}

	@property
	Transition transition() { mixin(S_TRACE);
		return _tsTbl[_ts.getSelectionIndex()];
	}
	@property
	int transitionSpeed() { mixin(S_TRACE);
		return _tsSpeed.getSelection();
	}
}

/// エリア・バトル・パッケージ・キャスト・情報の選択を行うダイアログ。
class AreaSelectDialog(CType Type, A, string Areas) : EventDialog {
private:
	AreaChooser!(A, false) _list;

	static if (Type == CType.CHANGE_AREA) {
		TransitionPanel _transition;
	}
	static if (Type == CType.GET_CAST) {
		Combo _startAction;
		StartAction[] _startActions;
	}

	override
	protected void refreshWarning() { mixin(S_TRACE);
		static if (Type == CType.GET_CAST) {
			string[] r;
			if (summ) { mixin(S_TRACE);
				auto startAction = _startActions[_startAction.getSelectionIndex()];
				if (summ.legacy && startAction !is StartAction.NextRound) { mixin(S_TRACE);
					// クラシックなシナリオではStartAction.NextRoundがデフォルト
					r ~= .tryFormat(prop.msgs.warningStartAction);
				} else if (!summ.legacy && !prop.isTargetVersion(summ, "2") && startAction !is StartAction.Now) { mixin(S_TRACE);
					// Wsn.1以前は戦闘行動開始タイミング指定不可かつStartAction.Nowがデフォルト
					r ~= .tryFormat(prop.msgs.warningStartAction);
				}
			}
			warning = r;
		}
	}

	override
	protected void refDataVersion() { mixin(S_TRACE);
		static if (Type == CType.GET_CAST) {
			if (summ && summ.legacy) { mixin(S_TRACE);
				auto startAction = _startActions[_startAction.getSelectionIndex()];
				if (startAction !is StartAction.NextRound) { mixin(S_TRACE);
					_startAction.select(cast(int)_startActions.countUntil(StartAction.NextRound));
					applyEnabled(true);
				}
				_startAction.setEnabled(false);
			} else {
				_startAction.setEnabled(true);
			}
		}
		super.refDataVersion();
	}

	void delA(A a) { mixin(S_TRACE);
		if (!_summ) return;
		auto summary = _summ;
		auto areas = mixin(Areas);
		if (!areas.length) { mixin(S_TRACE);
			forceCancel();
		}
	}
	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			static if (is(A : Area)) {
				_comm.delArea.remove(&delA);
			} else static if (is(A : Battle)) {
				_comm.delBattle.remove(&delA);
			} else static if (is(A : Package)) {
				_comm.delPackage.remove(&delA);
			} else static if (is(A : CastCard)) {
				_comm.delCast.remove(&delA);
			} else static if (is(A : InfoCard)) {
				_comm.delInfo.remove(&delA);
			} else static assert (0);
		}
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) { mixin(S_TRACE);
		super (comm, prop, shell, summ, Type, parent, evt, true, prop.var.selEvtDlg, true);
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(zeroGridLayout(1, false));
		auto listComp = new Composite(area, SWT.NONE);
		{ mixin(S_TRACE);
			listComp.setLayout(normalGridLayout(1, true));
			listComp.setLayoutData(new GridData(GridData.FILL_BOTH));
			_list = new AreaChooser!(A, false)(comm, summ, listComp);
			mod(_list);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.widthHint = _prop.var.etc.nameTableWidth;
			gd.heightHint = _prop.var.etc.nameTableHeight;
			_list.setLayoutData(gd);
		}
		static if (Type == CType.CHANGE_AREA) {
			{ mixin(S_TRACE);
				auto sep = new Label(area, SWT.SEPARATOR | SWT.HORIZONTAL);
				sep.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			}
			{ mixin(S_TRACE);
				auto comp = new Composite(area, SWT.NONE);
				comp.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
				comp.setLayout(normalGridLayout(1, false));
				_transition = new TransitionPanel(comm, summ, comp, false, _evt, this);
			}
		}
		static if (Type == CType.GET_CAST) {
			auto comp = new Composite(listComp, SWT.NONE);
			comp.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
			comp.setLayout(zeroMarginGridLayout(2, false));
			auto l = new Label(comp, SWT.NONE);
			l.setText(prop.msgs.startAction);
			_startAction = new Combo(comp, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
			mod(_startAction);
			_startAction.setVisibleItemCount(prop.var.etc.comboVisibleItemCount);
			foreach (v; EnumMembers!StartAction) { mixin(S_TRACE);
				_startAction.add(prop.msgs.startActionName(v));
				_startActions ~= v;
			}
			.listener(_startAction, SWT.Selection, &refreshWarning);
		}
		if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
			static if (is(A : Area)) {
				_comm.delArea.add(&delA);
			} else static if (is(A : Battle)) {
				_comm.delBattle.add(&delA);
			} else static if (is(A : Package)) {
				_comm.delPackage.add(&delA);
			} else static if (is(A : CastCard)) {
				_comm.delCast.add(&delA);
			} else static if (is(A : InfoCard)) {
				_comm.delInfo.add(&delA);
			} else static assert (0);
			_list.addDisposeListener(new Dispose);
		}

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) { mixin(S_TRACE);
			static if (Type == CType.CHANGE_AREA) {
				_list.selected = _evt.area;
			} else static if (Type == CType.START_BATTLE) {
				_list.selected = _evt.battle;
			} else static if (Type == CType.CALL_PACKAGE || Type == CType.LINK_PACKAGE) {
				_list.selected = _evt.packages;
			} else static if (Type == CType.BRANCH_CAST || Type == CType.GET_CAST || Type == CType.LOSE_CAST) {
				_list.selected = _evt.casts;
			} else static if (Type == CType.BRANCH_INFO || Type == CType.GET_INFO || Type == CType.LOSE_INFO) {
				_list.selected = _evt.info;
			} else { mixin(S_TRACE);
				static assert (0);
			}
			static if (Type == CType.GET_CAST) {
				_startAction.select(cast(int)_startActions.countUntil(_evt.startAction));
			}
		} else { mixin(S_TRACE);
			static if (Type == CType.GET_CAST) {
				if (summ && (summ.legacy || prop.isTargetVersion(summ, "2"))) { mixin(S_TRACE);
					// クラシックなシナリオまたはWsn.2以降はStartAction.NextRoundがデフォルト
					_startAction.select(cast(int)_startActions.countUntil(StartAction.NextRound));
				} else { mixin(S_TRACE);
					// Wsn.1以前はStartAction.Nowがデフォルト
					_startAction.select(cast(int)_startActions.countUntil(StartAction.Now));
				}
			}
		}
		refDataVersion();
	}

	override bool apply() { mixin(S_TRACE);
		auto id = _list.selected;
		if (!_evt) { mixin(S_TRACE);
			_evt = new Content(Type, "");
		}
		static if (Type == CType.CHANGE_AREA) {
			_evt.area = id;
			_evt.transition = _transition.transition;
			_evt.transitionSpeed = _transition.transitionSpeed;
		} else static if (Type == CType.START_BATTLE) {
			_evt.battle = id;
		} else static if (Type == CType.CALL_PACKAGE || Type == CType.LINK_PACKAGE) {
			_evt.packages = id;
		} else static if (Type == CType.BRANCH_CAST || Type == CType.GET_CAST || Type == CType.LOSE_CAST) {
			_evt.casts = id;
		} else static if (Type == CType.BRANCH_INFO || Type == CType.GET_INFO || Type == CType.LOSE_INFO) {
			_evt.info = id;
		} else { mixin(S_TRACE);
			static assert (0);
		}
		static if (Type == CType.GET_CAST) {
			_evt.startAction = _startActions[_startAction.getSelectionIndex()];
		}
		return true;
	}
}

/// スタートコンテントの選択を行うダイアログ。
class StartSelectDialog(CType Type) : EventDialog {
private:
	string _selected = "";

	EventTree _et;

	Table _list;

	IncSearch _incSearch;
	void incSearch() { mixin(S_TRACE);
		.forceFocus(_list, true);
		_incSearch.startIncSearch();
	}

	void selected() { mixin(S_TRACE);
		int index = _list.getSelectionIndex();
		if (-1 == index) return;
		_selected = (cast(Content) _list.getItem(index).getData()).name;
	}

	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			_comm.refContent.remove(&refContent);
			_comm.delContent.remove(&delContent);
			_comm.replText.remove(&refreshStarts);
		}
	}
	void refContent(Content c) { mixin(S_TRACE);
		refreshStarts(null);
	}
	void delContent(Content c) { mixin(S_TRACE);
		if ((evt && evt.isDescendant(c)) || (parent && parent.isDescendant(c))) return;
		refreshStarts(c);
	}
	void refreshStarts() { mixin(S_TRACE);
		refreshStarts(null);
	}
	void refreshStarts(Content del) { mixin(S_TRACE);
		if (!_et) return;
		string sel = _selected;

		_list.removeAll();
		int i = 0;
		foreach (s; _et.starts) { mixin(S_TRACE);
			if (s is del) continue;
			if (!_incSearch.match(s.name)) continue;
			auto itm = new TableItem(_list, SWT.NONE);
			itm.setData(s);
			itm.setImage(0, _prop.images.content(CType.START));
			itm.setText(0, s.name);
			if (sel == s.name) _list.select(i);
			i++;
		}
		if (del && sel == del.name && _list.getItemCount()) { mixin(S_TRACE);
			_list.select(0);
			_selected = (cast(Content) _list.getItem(0).getData()).name;
		}
		_list.showSelection();
	}
	void openView() { mixin(S_TRACE);
		auto i = _list.getSelectionIndex();
		if (-1 == i) return;
		auto a = cast(Content) _list.getItem(i).getData();
		try { mixin(S_TRACE);
			_comm.openCWXPath(cpaddattr(a.cwxPath(true), "shallow"), false);
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
	}
	class OpenView : MouseAdapter {
		override void mouseDoubleClick(MouseEvent e) { mixin(S_TRACE);
			if (1 != e.button) return;
			openView();
		}
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) { mixin(S_TRACE);
		_et = parent ? parent.tree : null;
		super (comm, prop, shell, summ, Type, parent, evt, true, prop.var.selEvtDlg, true);
	}

protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(1, false));
		_list = .rangeSelectableTable(area, SWT.SINGLE | SWT.FULL_SELECTION | SWT.BORDER | SWT.V_SCROLL);
		mod(_list);
		auto nameCol = new FullTableColumn(_list, SWT.NONE);
		auto gd = new GridData(GridData.FILL_BOTH);
		gd.widthHint = _prop.var.etc.nameTableWidth;
		gd.heightHint = _prop.var.etc.nameTableHeight;
		_list.setLayoutData(gd);
		_list.addMouseListener(new OpenView);
		auto menu = new Menu(_list.getShell(), SWT.POP_UP);
		createMenuItem(comm, menu, MenuID.IncSearch, &incSearch, () => 0 < _et.starts.length);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(comm, menu, MenuID.OpenAtEventView, &openView, () => _list.getSelectionIndex() != -1);
		_list.setMenu(menu);
		.listener(_list, SWT.Selection, &selected);
		_incSearch = new IncSearch(comm, _list, () => 0 < _et.starts.length);
		_incSearch.modEvent ~= &refreshStarts;

		refreshStarts();
		if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
			_comm.refContent.add(&refContent);
			_comm.delContent.add(&delContent);
			_comm.replText.add(&refreshStarts);
			_list.addDisposeListener(new Dispose);
		}
		if (!summ) _list.setEnabled(false);

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) { mixin(S_TRACE);
			_selected = _evt.start;
			foreach (i, itm; _list.getItems()) { mixin(S_TRACE);
				if (_selected == (cast(Content) itm.getData()).name) { mixin(S_TRACE);
					_list.select(cast(int)i);
					break;
				}
			}
		}
		if (-1 == _list.getSelectionIndex() && _list.getItemCount()) { mixin(S_TRACE);
			_list.select(0);
			_selected = (cast(Content)_list.getItem(0).getData()).name;
		}
		_list.showSelection();
	}

	override bool apply() { mixin(S_TRACE);
		if (!_evt) _evt = new Content(Type, "");
		_evt.start = _selected;
		return true;
	}
}

/// クリアイベントの設定を行うダイアログ。
class ClearEventDialog : EventDialog {
private:
	Button _mark;
	Button _unmark;

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) { mixin(S_TRACE);
		super (comm, prop, shell, summ, CType.END, parent, evt, false, null, enterClose);
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		auto cl = new CenterLayout;
		cl.fillHorizontal = true;
		area.setLayout(cl);
		auto grp = new Group(area, SWT.NONE);
		grp.setText(_prop.msgs.afterClear);
		grp.setLayout(new CenterLayout(SWT.VERTICAL | SWT.HORIZONTAL, 0));
		auto comp = new Composite(grp, SWT.NONE);
		comp.setLayout(normalGridLayout(1, true));
		_mark = new Button(comp, SWT.RADIO);
		mod(_mark);
		_mark.setText(_prop.msgs.afterClearEndMark);
		_unmark = new Button(comp, SWT.RADIO);
		mod(_unmark);
		_unmark.setText(_prop.msgs.afterClearNoEndMark);

		if (_evt) { mixin(S_TRACE);
			if (_evt.complete) { mixin(S_TRACE);
				_mark.setSelection(true);
			} else { mixin(S_TRACE);
				_unmark.setSelection(true);
			}
		} else { mixin(S_TRACE);
			_mark.setSelection(true);
		}
	}

	override bool apply() { mixin(S_TRACE);
		if (!_evt) { mixin(S_TRACE);
			_evt = new Content(CType.END, "");
		}
		_evt.complete = _mark.getSelection();
		return true;
	}
}

/// クーポン関連イベントの設定を行うダイアログ。
class CouponEventDialog(CType Type, bool EditValue, bool Field) : EventDialog {
private:
	UseCounter _uc;
	RangePanel _range;
	Button[CouponType] _type;
	Composite _couponViewComp;
	Combo _name = null;
	Button _expandSPChars = null;
	CouponView!(CVType.NoValued) _couponView = null;
	CenterLayout _couponViewCL = null;
	Combo _nameEditor = null;
	Button[MatchingType] _matchType = null; /// マッチングタイプ(Wsn.2)
	static if (EditValue) {
		Spinner _value;
	}
	static if (Type is CType.BRANCH_COUPON) {
		Combo _invertResult;
	}

	override
	protected void refreshWarning() { mixin(S_TRACE);
		string[] ws;
		if (_couponView) { mixin(S_TRACE);
			if(!prop.isTargetVersion(summ, "2")) { mixin(S_TRACE);
				if (_couponView.couponNames.length > 1) { mixin(S_TRACE);
					ws ~= prop.msgs.warningBranchCouponMulti;
				}
			}
			ws ~= _couponView.warnings;
			if (_expandSPChars.getSelection()) { mixin(S_TRACE);
				if (!_comm.prop.isTargetVersion(_summ, "4")) { mixin(S_TRACE);
					ws ~= _comm.prop.msgs.warningExpandSPCharsInCoupon;
				}
				ws ~= .textWarnings2(comm, summ, _uc, _couponView.couponNames);
			}
		} else if (_name) { mixin(S_TRACE);
			ws ~= .couponWarnings(prop.parent, summ, prop.var.etc.targetVersion, _name.getText(), Type is CType.GET_COUPON || Type is CType.LOSE_COUPON, prop.msgs.couponName);
			if (_expandSPChars.getSelection()) { mixin(S_TRACE);
				if (!_comm.prop.isTargetVersion(_summ, "4")) { mixin(S_TRACE);
					ws ~= _comm.prop.msgs.warningExpandSPCharsInCoupon;
				}
				ws ~= .textWarnings2(comm, summ, _uc, [_name.getText()]);
			}
		}
		static if (Field) {
			if (summ && summ.legacy && !_prop.targetVersion(summ, "1.30")) { mixin(S_TRACE);
				if (_range.range is Range.FIELD) { mixin(S_TRACE);
					ws ~= prop.msgs.warningBranchCouponAtField;
				}
			}
		}
		static if (Type is CType.BRANCH_COUPON) {
			if(!prop.isTargetVersion(summ, "4") && _invertResult.getSelectionIndex() == 1) { mixin(S_TRACE);
				ws ~= prop.msgs.warningInvertResult;
			}
		}
		ws ~= _range.warnings;

		warning = ws;
	}
	override
	protected void refDataVersion() { mixin(S_TRACE);
		static if (Type is CType.BRANCH_COUPON) {
			createCouponView(false);
		}
		updateEnabled();
		super.refDataVersion();
	}

	void updateEnabled() { mixin(S_TRACE);
		_expandSPChars.setEnabled(!_summ.legacy || _expandSPChars.getSelection());
		updateToolTip();
		static if (Type is CType.BRANCH_COUPON) {
			_invertResult.setEnabled(!summ || !summ.legacy || _invertResult.getSelectionIndex() != 0);
		}
	}

	void refFlagAndStep(cwx.flag.Flag[] flags, Step[] steps, cwx.flag.Variant[] variants) { mixin(S_TRACE);
		updateToolTip();
		refreshWarning();
	}
	void refPath(string o, string n, bool isDir) { updateToolTip(); }
	void refPaths(string parent) { updateToolTip(); }
	void updateToolTip() { mixin(S_TRACE);
		if (_name && !_name.isDisposed()) { mixin(S_TRACE);
			auto toolTip = createToolTip(_name.getText());
			if (toolTip != _name.getToolTipText()) { mixin(S_TRACE);
				_name.setToolTipText(toolTip);
			}
		} else if (_couponView && !_couponView.isDisposed()) { mixin(S_TRACE);
			if (_nameEditor && !_nameEditor.isDisposed()) { mixin(S_TRACE);
				auto toolTip = createToolTip(_nameEditor.getText());
				if (toolTip != _nameEditor.getToolTipText()) { mixin(S_TRACE);
					_nameEditor.setToolTipText(toolTip);
				}
			}
			if (_couponView.mainNameEditor) { mixin(S_TRACE);
				auto toolTip = createToolTip(_couponView.mainNameEditor.getText());
				if (toolTip != _couponView.mainNameEditor.getToolTipText()) { mixin(S_TRACE);
					_couponView.mainNameEditor.setToolTipText(toolTip);
				}
			}
		}
	}
	void updateToolTipM(Event e) { mixin(S_TRACE);
		if (!_couponView || _couponView.isDisposed()) return;
		auto itm = _couponView.widget.getItem(new Point(e.x, e.y));
		auto toolTip = itm ? createToolTip(itm.getText()) : "";
		if (toolTip != _couponView.toolTip) { mixin(S_TRACE);
			_couponView.toolTip = toolTip;
		}
	}
	string createToolTip(string text) { mixin(S_TRACE);
		auto toolTip = "";
		if (_expandSPChars && _expandSPChars.getSelection()) { mixin(S_TRACE);
			toolTip = .createSPCharPreview(_comm, _summ, _uc, text, true, null, null);
			toolTip = toolTip.replace("&", "&&");
		}
		return toolTip;
	}

	class SelType : SelectionAdapter {
		private CouponType _coType;
		this (CouponType coType) { mixin(S_TRACE);
			_coType = coType;
		}
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			_name.setText(prop.sys.convCoupon(_name.getText(), _coType, false));
		}
	}

	void updateCouponName() { mixin(S_TRACE);
		if (!_name) return;
		auto t = prop.sys.couponType(_name.getText());
		bool checked = false;
		foreach (coType; _type.keys) { mixin(S_TRACE);
			_type[coType].setSelection(coType == t);
			checked |= (coType == t);
		}
		if (!checked) _type[CouponType.Normal].setSelection(true);
		refreshWarning();
	}

	void createCouponView(bool init) { mixin(S_TRACE);
		auto multi = !(summ && summ.legacy) && Type is CType.BRANCH_COUPON;
		string[] couponNames;
		if (_couponView) { mixin(S_TRACE);
			if (multi) return;
			couponNames = _couponView.couponNames;
		} else if (_name) { mixin(S_TRACE);
			if (!multi) return;
			couponNames = _name.getText() == "" ? [] : [_name.getText()];
		}
		if (!init) getShell().setRedraw(false);
		scope (exit) {
			if (!init) getShell().setRedraw(true);
		}

		foreach (ctrl; _couponViewComp.getChildren()) ctrl.dispose();
		_couponView = null;
		_name = null;
		_type = null;
		_matchType = null;

		if (multi) { mixin(S_TRACE);
			// Wsn.2
			_couponViewCL.fillVertical = true;

			_couponView = new CouponView!(CVType.NoValued)(comm, summ, _uc, _couponViewComp, SWT.NONE, &catchMod, false);
			mod(_couponView);
			_couponView.modEvent ~= &refreshWarning;
			_couponView.setLayoutData(new GridData(GridData.FILL_BOTH));
			.listener(_couponView.widget, SWT.MouseEnter, &updateToolTipM);
			.listener(_couponView.widget, SWT.MouseExit, &updateToolTipM);
			.listener(_couponView.widget, SWT.MouseMove, &updateToolTipM);

			auto radioComp = new Composite(_couponViewComp, SWT.NONE);
			radioComp.setLayout(zeroMarginGridLayout(2, false));
			radioComp.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
			foreach(type; [MatchingType.And, MatchingType.Or]){ mixin(S_TRACE);
				auto radio = new Button(radioComp, SWT.RADIO);
				mod(radio);
				radio.setText(comm.prop.msgs.matchingTypeName(type));
				_matchType[type] = radio;
			}

			_couponView.setupNameEditor = (name) { mixin(S_TRACE);
				_nameEditor = name;
				auto menu = name.getMenu();
				new MenuItem(menu, SWT.SEPARATOR);
				.setupSPCharsMenu(_comm, _summ, _uc, name, menu, false, true, () => _expandSPChars.getSelection());
				.listener(name, SWT.Modify, &updateToolTip);
			};
			if (_couponView.mainNameEditor) { mixin(S_TRACE);
				auto menu = _couponView.mainNameEditor.getMenu();
				new MenuItem(menu, SWT.SEPARATOR);
				.setupSPCharsMenu(_comm, _summ, _uc, _couponView.mainNameEditor, menu, false, true, () => _expandSPChars.getSelection());
				.listener(_couponView.mainNameEditor, SWT.Modify, &updateToolTip);
			}
		} else { mixin(S_TRACE);
			_couponViewCL.fillVertical = false;

			{ mixin(S_TRACE);
				auto comp = new Composite(_couponViewComp, SWT.NONE);
				comp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				comp.setLayout(zeroMarginGridLayout(3, false));
				{ mixin(S_TRACE);
					static if (Type is CType.GET_COUPON || Type is CType.LOSE_COUPON) {
						auto type = CouponComboType.GetLose;
					} else static if (Type is CType.BRANCH_COUPON) {
						auto type = CouponComboType.AllCoupons;
					} else static assert (0);
					_name = createCouponCombo(comm, summ, _uc, comp, &catchMod, type, _evt ? _evt.coupon : "");
					mod(_name);
					auto gd = new GridData(GridData.FILL_HORIZONTAL);
					gd.horizontalSpan = 3;
					gd.widthHint = _prop.var.etc.nameWidth;
					_name.setLayoutData(gd);

					auto menu = _name.getMenu();
					new MenuItem(menu, SWT.SEPARATOR);
					.setupSPCharsMenu(_comm, _summ, _uc, _name, menu, false, true, () => _expandSPChars.getSelection());
					.listener(_name, SWT.Modify, &updateToolTip);
				}
				foreach (coType; [CouponType.Normal, CouponType.Hide, CouponType.Dur, CouponType.DurBattle, CouponType.System]) { mixin(S_TRACE);
					auto b = new Button(comp, SWT.RADIO);
					auto typeName = _prop.msgs.couponTypeLongDesc(coType);
					final switch (coType) {
					case CouponType.Normal:
						break;
					case CouponType.Hide:
						typeName = .tryFormat(typeName, prop.sys.couponHide);
						break;
					case CouponType.Dur:
						typeName = .tryFormat(typeName, prop.sys.couponDur);
						break;
					case CouponType.DurBattle:
						typeName = .tryFormat(typeName, prop.sys.couponDurBattle);
						break;
					case CouponType.System:
						typeName = .tryFormat(typeName, prop.sys.couponSystem);
						break;
					}
					b.setText(typeName);
					auto gd = new GridData(GridData.FILL_HORIZONTAL);
					gd.horizontalSpan = 3;
					b.setLayoutData(gd);
					b.addSelectionListener(new SelType(coType));
					_type[coType] = b;
				}
				.listener(_name, SWT.Modify, &updateCouponName);
			}
		}

		if (!init) { mixin(S_TRACE);
			if (_couponView) { mixin(S_TRACE);
				_couponView.couponNames = couponNames;
				_matchType[MatchingType.And].setSelection(true);

				windowSizeInfo = prop.var.multiCouponEvtDlg;
			} else { mixin(S_TRACE);
				assert (_name !is null);
				if (couponNames.length) _name.setText(couponNames[0]);
				updateCouponName();

				windowSizeInfo = prop.var.couponEvtDlg;
			}
		}
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, UseCounter uc, Content parent, Content evt) { mixin(S_TRACE);
		_uc = uc;
		DSize dSize;
		if (!(summ && summ.legacy) && Type is CType.BRANCH_COUPON) { mixin(S_TRACE);
			dSize = prop.var.multiCouponEvtDlg;
		} else { mixin(S_TRACE);
			dSize = prop.var.couponEvtDlg;
		}
		super (comm, prop, shell, summ, Type, parent, evt, true, dSize, true);
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(2, false));
		auto skin = _comm.skin;

		static immutable HAS_COUPON_HOLDER = Type is CType.GET_COUPON || Type is CType.LOSE_COUPON;

		static if (HAS_COUPON_HOLDER) {
			auto sash = new SplitPane(area, SWT.HORIZONTAL);
			sash.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto leftComp = new Composite(sash, SWT.NONE);
		} else {
			auto leftComp = new Composite(area, SWT.NONE);
			leftComp.setLayoutData(new GridData(GridData.FILL_VERTICAL));
		}

		leftComp.setLayout(zeroMarginGridLayout(1, true));
		{ mixin(S_TRACE);
			auto ranges = RANGE_MEMBER.dup;
			static if (Field) {
				ranges ~= Range.FIELD;
			}
			static if (Type is CType.GET_COUPON || Type is CType.LOSE_COUPON) {
				ranges ~= Range.COUPON_HOLDER;
			}
			auto initCoupon = (evt && evt.holdingCoupon != "") ? evt.holdingCoupon : "";
			_range = new RangePanel(comm, summ, _uc, leftComp, ranges, initCoupon, _prop.msgs.range, false, this,
				evt, &catchMod, &refreshWarning, type);
			static if (EditValue) {
				_range.setLayoutData(new GridData(GridData.FILL_BOTH));
			} else { mixin(S_TRACE);
				_range.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			}
		}
		{ mixin(S_TRACE);
			static if (HAS_COUPON_HOLDER) {
				auto grp = new Group(sash, SWT.NONE);
			} else {
				auto grp = new Group(area, SWT.NONE);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			}
			grp.setText(_prop.msgs.couponName);
			_couponViewCL = new CenterLayout(SWT.VERTICAL, 0);
			_couponViewCL.fillHorizontal = true;
			grp.setLayout(_couponViewCL);
			auto comp = new Composite(grp, SWT.NONE);
			comp.setLayout(normalGridLayout(1, true));
			comp.setLayoutData(new GridData(GridData.FILL_BOTH));
			_couponViewComp = new Composite(comp, SWT.NONE);
			_couponViewComp.setLayout(zeroMarginGridLayout(1, true));
			_couponViewComp.setLayoutData(new GridData(GridData.FILL_BOTH));
			createCouponView(true);

			auto sep = new Label(comp, SWT.SEPARATOR | SWT.HORIZONTAL);
			auto sgd = new GridData(GridData.FILL_HORIZONTAL);
			sep.setLayoutData(sgd);

			_expandSPChars = new Button(comp, SWT.CHECK);
			mod(_expandSPChars);
			_expandSPChars.setText(_comm.prop.msgs.expandSPChars);
			_expandSPChars.setToolTipText(_comm.prop.msgs.expandSPCharsHint.replace("&", "&&"));
			_expandSPChars.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
			.listener(_expandSPChars, SWT.Selection, &updateEnabled);

			_comm.refPreviewValues.add(&updateToolTip);
			_comm.refFlagAndStep.add(&refFlagAndStep);
			_comm.delFlagAndStep.add(&refFlagAndStep);
			_comm.refPath.add(&refPath);
			_comm.refPaths.add(&refPaths);
			_comm.replText.add(&updateToolTip);
			.listener(_expandSPChars, SWT.Dispose, { mixin(S_TRACE);
				_comm.refPreviewValues.remove(&updateToolTip);
				_comm.refFlagAndStep.remove(&refFlagAndStep);
				_comm.delFlagAndStep.remove(&refFlagAndStep);
				_comm.refPath.remove(&refPath);
				_comm.refPaths.remove(&refPaths);
				_comm.replText.remove(&updateToolTip);
			});
			updateToolTip();
		}
		static if (EditValue) {
			{ mixin(S_TRACE);
				auto grp = new Group(leftComp, SWT.NONE);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setText(_prop.msgs.couponValue);
				grp.setLayout(new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL));
				auto comp = new Composite(grp, SWT.NONE);
				comp.setLayout(zeroMarginGridLayout(2, false));
				_value = new Spinner(comp, SWT.BORDER);
				initSpinner(_value);
				mod(_value);
				_value.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				_value.setMaximum(_prop.var.etc.couponValueMax);
				_value.setMinimum(-(cast(int) _prop.var.etc.couponValueMax));
				auto lr = new Label(comp, SWT.LEFT);
				lr.setText(.tryFormat(_prop.msgs.couponValueRange, -(cast(int) prop.var.etc.couponValueMax), prop.var.etc.couponValueMax));
			}
		}
		static if (Type is CType.BRANCH_COUPON) {
			{ mixin(S_TRACE);
				auto grp = new Group(leftComp, SWT.NONE);
				grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				grp.setText(_prop.msgs.resultType);
				grp.setLayout(new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL));
				_invertResult = new Combo(grp, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
				mod(_invertResult);
				_invertResult.setVisibleItemCount(prop.var.etc.comboVisibleItemCount);
				_invertResult.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				_invertResult.add(_prop.msgs.resultTypeNormal);
				_invertResult.add(_prop.msgs.resultTypeInvert);
				.listener(_invertResult, SWT.Selection, &refDataVersion);
			}
		}

		if (_evt) { mixin(S_TRACE);
			if (!(summ && summ.legacy) && Type is CType.BRANCH_COUPON) {
				_couponView.couponNames = _evt.couponNames;
				if(_evt.matchingType == MatchingType.And){
					_matchType[MatchingType.And].setSelection(true);
				} else { mixin(S_TRACE);
					_matchType[MatchingType.Or].setSelection(true);
				}
			} else { mixin(S_TRACE);
				string coupon;
				if (_evt.detail.use(CArg.COUPON_NAMES)) { mixin(S_TRACE);
					coupon = _evt.couponNames.length ? _evt.couponNames[0] : "";
				} else { mixin(S_TRACE);
					coupon = _evt.coupon;
				}
				auto cType = prop.sys.couponType(coupon);
				auto cTypeP = cType in _type;
				if (cTypeP) { mixin(S_TRACE);
					cTypeP.setSelection(true);
				} else { mixin(S_TRACE);
					_type[CouponType.Normal].setSelection(true);
				}
				_name.setText(coupon);
			}

			static if (EditValue) {
				_value.setSelection(_evt.couponValue);
			}
			static if (Type is CType.BRANCH_COUPON) {
				_invertResult.select(_evt.invertResult ? 1 : 0);
			}
			_expandSPChars.setSelection(_evt.expandSPChars);
		} else { mixin(S_TRACE);
			if ((summ && summ.legacy) || !(Type is CType.BRANCH_COUPON)) {
				_type[CouponType.Normal].setSelection(true);
			} else { mixin(S_TRACE);
				_couponView.couponNames = [];
				_matchType[MatchingType.And].setSelection(true);
			}
			static if (EditValue) {
				_value.setSelection(0);
			}
			static if (Type is CType.BRANCH_COUPON) {
				_invertResult.select(0);
			}
			_expandSPChars.setSelection(false);
		}
		refDataVersion();
		static if (HAS_COUPON_HOLDER) {
			.setupWeights(sash, _prop.var.etc.couponEventL, _prop.var.etc.couponEventR);
		}
	}

	override bool apply() { mixin(S_TRACE);
		if (!_evt) _evt = new Content(Type, "");

		_evt.range = _range.range;
		_evt.holdingCoupon = _range.holdingCoupon;

		if (_couponView) { mixin(S_TRACE);
			_evt.couponNames = _couponView.couponNames;
			_evt.matchingType = _matchType[MatchingType.And].getSelection() ? MatchingType.And : MatchingType.Or;
		} else if (_evt.detail.use(CArg.COUPON_NAMES)) { mixin(S_TRACE);
			_evt.couponNames = _name.getText().length ? [_name.getText()] : [];
		} else { mixin(S_TRACE);
			_evt.coupon = _name.getText();
		}

		static if (EditValue) {
			_evt.couponValue = _value.getSelection();
		}
		static if (Type is CType.BRANCH_COUPON) {
			_evt.invertResult = _invertResult.getSelectionIndex() == 1;
		}
		_evt.expandSPChars = _expandSPChars.getSelection();

		if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
			comm.refCoupons.call();
		}
		return true;
	}
}

alias CouponEventDialog!(CType.BRANCH_COUPON, false, true) BranchCouponDialog;
alias CouponEventDialog!(CType.GET_COUPON, true, false) GetCouponDialog;
alias CouponEventDialog!(CType.LOSE_COUPON, false, false) LoseCouponDialog;

private string[] textWarnings2(Commons comm, in Summary summ, in UseCounter uc, string[] names) { mixin(S_TRACE);
	string[] ws;
	bool[string] ws2;
	foreach (v; names) { mixin(S_TRACE);
		bool[string] wFlags;
		bool[string] wSteps;
		bool[string] wVariants;
		bool[string] wFonts;
		bool[char] wColors;
		string[] flags;
		string[] steps;
		string[] variants;
		string[] fonts;
		char[] colors;
		.textUseItems(v, flags, steps, variants, fonts, colors);
		fonts = [];
		colors = [];
		auto ws3 = .textWarnings(comm.prop.parent, comm.skin, summ, uc, comm.prop.var.etc.targetVersion,
			v, flags, steps, variants, fonts, colors, wFlags, wSteps, wVariants, wFonts, wColors).all;
		foreach (w; ws3) { mixin(S_TRACE);
			if (w in ws2) continue;
			ws2[w] = true;
			ws ~= w;
		}
	}
	return ws;
}

/// 一つのテキストの設定を行うダイアログ。
private class OneTextEventDialog(CType Type, string Name, string Get, string Set, string EngineVersion = "") : EventDialog {
private:
	Combo _name;
	UseCounter _uc;
	Button _expandSPChars = null;

	override
	protected void refreshWarning() { mixin(S_TRACE);
		string[] ws;
		ws ~= .sjisWarnings(prop.parent, summ, _name.getText(), mixin(Name));
		static if (EngineVersion != "") {
			if (!_prop.targetVersion(summ, EngineVersion)) { mixin(S_TRACE);
				ws ~= .tryFormat(_prop.msgs.warningUnknownContent, _prop.msgs.contentName(Type), EngineVersion);
			}
		}
		if (_expandSPChars && _expandSPChars.getSelection()) { mixin(S_TRACE);
			if (!_comm.prop.isTargetVersion(_summ, "4")) { mixin(S_TRACE);
				ws ~= _comm.prop.msgs.warningExpandSPCharsInGossip;
			}
			ws ~= .textWarnings2(comm, summ, _uc, [_name.getText()]);
		}
		warning = ws;
	}
	override
	protected void refDataVersion() { mixin(S_TRACE);
		if (_expandSPChars) _expandSPChars.setEnabled(!_summ.legacy || _expandSPChars.getSelection());
		updateToolTip();
		refreshWarning();
	}

	void refFlagAndStep(cwx.flag.Flag[] flags, Step[] steps, cwx.flag.Variant[] variants) { mixin(S_TRACE);
		updateToolTip();
		refreshWarning();
	}
	void refPath(string o, string n, bool isDir) { updateToolTip(); }
	void refPaths(string parent) { updateToolTip(); }
	void updateToolTip() { mixin(S_TRACE);
		if (_name && !_name.isDisposed()) { mixin(S_TRACE);
			auto toolTip = createToolTip(_name.getText());
			if (toolTip != _name.getToolTipText()) { mixin(S_TRACE);
				_name.setToolTipText(toolTip);
			}
		}
	}
	string createToolTip(string text) { mixin(S_TRACE);
		auto toolTip = "";
		if (_expandSPChars && _expandSPChars.getSelection()) { mixin(S_TRACE);
			toolTip = .createSPCharPreview(_comm, _summ, _uc, text, true, null, null);
			toolTip = toolTip.replace("&", "&&");
		}
		return toolTip;
	}

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, UseCounter uc, Content parent, Content evt) { mixin(S_TRACE);
		_uc = uc;
		if (CDetail.fromType(Type).use(CArg.GOSSIP)) { mixin(S_TRACE);
			super (comm, prop, shell, summ, Type, parent, evt, true, prop.var.gossipEvtDlg, true);
		} else { mixin(S_TRACE);
			super (comm, prop, shell, summ, Type, parent, evt, true, prop.var.inputEvtDlg, true);
		}
	}

protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(1, false));
		{ mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setText(mixin(Name));
			auto cl = new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0);
			cl.fillHorizontal = true;
			grp.setLayout(cl);
			auto comp = new Composite(grp, SWT.NONE);
			comp.setLayout(normalGridLayout(1, true));

			if (CDetail.fromType(Type).use(CArg.GOSSIP)) { mixin(S_TRACE);
				_name = createGossipCombo(comm, summ, comp, &catchMod, _evt ? mixin(Get) : "");
			} else if (CDetail.fromType(Type).use(CArg.COMPLETE_STAMP)) { mixin(S_TRACE);
				_name = createCompleteStampCombo(comm, summ, comp, &catchMod, _evt ? mixin(Get) : "");
			} else if (CDetail.fromType(Type).use(CArg.CELL_NAME)) { mixin(S_TRACE);
				_name = createCellNameCombo(comm, summ, comp, &catchMod, _evt ? mixin(Get) : "");
			} else assert (0);
			mod(_name);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.widthHint = _prop.var.etc.nameWidth;
			_name.setLayoutData(gd);
			.listener(_name, SWT.Modify, &refreshWarning);

			if (CDetail.fromType(Type).use(CArg.GOSSIP)) { mixin(S_TRACE);
				auto menu = _name.getMenu();
				new MenuItem(menu, SWT.SEPARATOR);
				.setupSPCharsMenu(_comm, _summ, _uc, _name, menu, false, true, () => _expandSPChars.getSelection());

				_expandSPChars = new Button(comp, SWT.CHECK);
				mod(_expandSPChars);
				_expandSPChars.setText(_comm.prop.msgs.expandSPChars);
				_expandSPChars.setToolTipText(_comm.prop.msgs.expandSPCharsHint.replace("&", "&&"));
				_expandSPChars.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
				.listener(_expandSPChars, SWT.Selection, &refDataVersion);

				.listener(_name, SWT.Modify, &updateToolTip);

				_comm.refPreviewValues.add(&updateToolTip);
				_comm.refFlagAndStep.add(&refFlagAndStep);
				_comm.delFlagAndStep.add(&refFlagAndStep);
				_comm.refPath.add(&refPath);
				_comm.refPaths.add(&refPaths);
				_comm.replText.add(&updateToolTip);
				.listener(_expandSPChars, SWT.Dispose, { mixin(S_TRACE);
					_comm.refPreviewValues.remove(&updateToolTip);
					_comm.refFlagAndStep.remove(&refFlagAndStep);
					_comm.delFlagAndStep.remove(&refFlagAndStep);
					_comm.refPath.remove(&refPath);
					_comm.refPaths.remove(&refPaths);
					_comm.replText.remove(&updateToolTip);
				});
				updateToolTip();
			}
		}

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) { mixin(S_TRACE);
			_name.setText(mixin(Get));
			if (_expandSPChars) _expandSPChars.setSelection(_evt.expandSPChars);
		}
		refDataVersion();
	}

	override bool apply() { mixin(S_TRACE);
		if (!_evt) _evt = new Content(Type, "");
		string text = _name.getText();
		mixin(Set);
		if (_expandSPChars) _evt.expandSPChars = _expandSPChars.getSelection();
		if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
			if (CDetail.fromType(Type).use(CArg.GOSSIP)) { mixin(S_TRACE);
				comm.refGossips.call();
			}
			if (CDetail.fromType(Type).use(CArg.COMPLETE_STAMP)) { mixin(S_TRACE);
				comm.refCompleteStamps.call();
			}
			if (CDetail.fromType(Type).use(CArg.CELL_NAME)) { mixin(S_TRACE);
				comm.refCellNames.call();
			}
		}
		return true;
	}
}

template GossipEventDialog(CType Type) {
	alias OneTextEventDialog!(Type, "_prop.msgs.gossipName",
		"_evt.gossip", "_evt.gossip = text;") GossipEventDialog;
}

template EndEventDialog(CType Type) {
	alias OneTextEventDialog!(Type, "_prop.msgs.endName",
		"_evt.completeStamp", "_evt.completeStamp = text;") EndEventDialog;
}

/// 背景変更・置換イベントの設定を行うダイアログ。
class BgImagesDialog : EventDialog {
private:
	UseCounter _uc;
	AbstractArea _refTarget;

	BgImageContainer _cont;

	BgImagesView _view;

	TransitionPanel _transition;
	Combo _cellName = null;

	Button _doAnime = null;
	Button _ignoreEffectBooster = null;

	override
	protected void refreshWarning() { mixin(S_TRACE);
		string[] ws;
		auto skin = _comm.skin;
		bool[string] tbl;
		string[] ws3;
		if (_cellName) ws ~= .sjisWarnings(prop.parent, summ, _cellName.getText(), prop.msgs.cellName);
		foreach (back; _cont.backs) { mixin(S_TRACE);
			auto ws2 = .warnings(prop.parent, skin, summ, back, _prop.var.etc.targetVersion);
			if (_ignoreEffectBooster && _ignoreEffectBooster.getSelection()) { mixin(S_TRACE);
				if (auto ic = cast(ImageCell)back) { mixin(S_TRACE);
					auto ext = ic.path.extension().toLower();
					if (ext == ".jpy1" || ext == ".jptx" || ext == ".jpdc") { mixin(S_TRACE);
						ws2 ~= _prop.msgs.warningEffectBoosterFileWithReplaceBgImage;
					}
				}
			}
			foreach (w; ws2) { mixin(S_TRACE);
				if (w !in tbl) { mixin(S_TRACE);
					ws3 ~= w;
					tbl[w] = true;
				}
			}
		}
		ws ~= ws3;
		if (type is CType.REPLACE_BG_IMAGE) { mixin(S_TRACE);
			if (!_prop.isTargetVersion(summ, "1")) { mixin(S_TRACE);
				ws ~= .tryFormat(_prop.msgs.warningUnknownContentWsn, _prop.msgs.contentName(type), "1");
			}
		}
		warning = ws;
	}

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, UseCounter uc, Content parent, Content evt, AbstractArea refTarget, CType type) { mixin(S_TRACE);
		_uc = uc;
		_refTarget = refTarget;
		super (comm, prop, shell, summ, type, parent, evt, true, prop.var.bgImagesDlg, false);

		BgImage[] bgImages;
		if (evt) { mixin(S_TRACE);
			foreach (b; evt.backs) { mixin(S_TRACE);
				bgImages ~= b.dup;
			}
		}
		_cont = new BgImageContainer(bgImages);
	}

	override
	bool openCWXPath(string path, bool shellActivate) { mixin(S_TRACE);
		return _view.openCWXPath(path, shellActivate);
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(1, false));
		auto skin = _comm.skin;
		{ mixin(S_TRACE);
			auto showInheritBacks = type !is CType.REPLACE_BG_IMAGE && _prop.var.etc.showInheritBackground;
			_view = createBgImagesViewAndMenu(_comm, _prop, _summ, _uc, _cont, area, _refTarget, showInheritBacks, false);
			mod(_view);
			_view.setLayoutData(new GridData(GridData.FILL_BOTH));
			_view.modEvent ~= &refreshWarning;
		}
		{ mixin(S_TRACE);
			if (CDetail.fromType(type).use(CArg.CELL_NAME)) {
				auto comp = new Composite(area, SWT.NONE);
				comp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				comp.setLayout(zeroMarginGridLayout(4, false));
				auto l = new Label(comp, SWT.NONE);
				l.setText(_prop.msgs.cellName);
				_cellName = createCellNameCombo(comm, summ, comp, &catchMod, _evt ? _evt.cellName : "");
				mod(_cellName);
				_cellName.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				.listener(_cellName, SWT.Modify, &refreshWarning);
				auto gd = new GridData(GridData.FILL_VERTICAL);
				gd.heightHint = 0;
				(new Label(comp, SWT.SEPARATOR | SWT.VERTICAL)).setLayoutData(gd);
				_transition = new TransitionPanel(comm, summ, comp, true, _evt, this);
			} else {
				_transition = new TransitionPanel(comm, summ, area, true, _evt, this);
				_transition.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
			}
		}
		if (CDetail.fromType(type).use(CArg.DO_ANIME)) { mixin(S_TRACE);
			auto comp = new Composite(area, SWT.NONE);
			comp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			comp.setLayout(zeroMarginGridLayout(2, false));
			_doAnime = new Button(comp, SWT.CHECK);
			_doAnime.setText(prop.msgs.doAnime);
			mod(_doAnime);
			_ignoreEffectBooster = new Button(comp, SWT.CHECK);
			_ignoreEffectBooster.setText(prop.msgs.ignoreEffectBooster);
			mod(_ignoreEffectBooster);
			comp.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
			.listener(_ignoreEffectBooster, SWT.Selection, &refreshWarning);
		}

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) { mixin(S_TRACE);
			if (_cellName) _cellName.setText(_evt.cellName);
			if (_doAnime) _doAnime.setSelection(_evt.doAnime);
			if (_ignoreEffectBooster) _ignoreEffectBooster.setSelection(_evt.ignoreEffectBooster);
		} else { mixin(S_TRACE);
			if (_cellName) _cellName.setText("");
			if (_doAnime) _doAnime.setSelection(true);
			if (_ignoreEffectBooster) _ignoreEffectBooster.setSelection(false);
		}

		refreshWarning();
	}

	override bool apply() { mixin(S_TRACE);
		_evt.backs = _cont.backs;
		_evt.transition = _transition.transition;
		_evt.transitionSpeed = _transition.transitionSpeed;
		if (_cellName) { mixin(S_TRACE);
			_evt.cellName = _cellName.getText();
		}
		if (_doAnime) { mixin(S_TRACE);
			_evt.doAnime = _doAnime.getSelection();
		}
		if (_ignoreEffectBooster) { mixin(S_TRACE);
			_evt.ignoreEffectBooster = _ignoreEffectBooster.getSelection();
		}
		return true;
	}
}

/// 背景削除コンテント。
class LoseBgImageDialog : EventDialog {
private:
	Combo _name;
	TransitionPanel _transition;

	Button _doAnime;
	Button _ignoreEffectBooster;

	override
	protected void refreshWarning() { mixin(S_TRACE);
		string[] ws;
		ws ~= .sjisWarnings(prop.parent, summ, _name.getText(), prop.msgs.cellName);
		if (!_prop.isTargetVersion(summ, "1")) { mixin(S_TRACE);
			ws ~= .tryFormat(_prop.msgs.warningUnknownContentWsn, _prop.msgs.contentName(CType.LOSE_BG_IMAGE), "1");
		}
		warning = ws;
	}

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) { mixin(S_TRACE);
		super (comm, prop, shell, summ, CType.LOSE_BG_IMAGE, parent, evt, true, prop.var.loseBgImageEvtDlg, true);
	}

protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(1, true));
		{ mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setText(_prop.msgs.cellName);
			auto cl = new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0);
			cl.fillHorizontal = true;
			grp.setLayout(cl);
			auto comp = new Composite(grp, SWT.NONE);
			comp.setLayout(normalGridLayout(1, true));

			_name = createCellNameCombo(comm, summ, comp, &catchMod, _evt ? _evt.cellName : "");
			mod(_name);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.widthHint = _prop.var.etc.nameWidth;
			_name.setLayoutData(gd);
			.listener(_name, SWT.Modify, &refreshWarning);
		}
		_transition = new TransitionPanel(comm, summ, area, true, _evt, this);
		_transition.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));

		{ mixin(S_TRACE);
			auto comp = new Composite(area, SWT.NONE);
			comp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			comp.setLayout(zeroMarginGridLayout(1, false));
			_doAnime = new Button(comp, SWT.CHECK);
			_doAnime.setText(prop.msgs.doAnime);
			mod(_doAnime);
			_ignoreEffectBooster = new Button(comp, SWT.CHECK);
			_ignoreEffectBooster.setText(prop.msgs.ignoreEffectBooster);
			mod(_ignoreEffectBooster);
			comp.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
		}

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) { mixin(S_TRACE);
			_name.setText(_evt.cellName);
			_doAnime.setSelection(_evt.doAnime);
			_ignoreEffectBooster.setSelection(_evt.ignoreEffectBooster);
		} else { mixin(S_TRACE);
			_doAnime.setSelection(true);
			_ignoreEffectBooster.setSelection(false);
		}
		refreshWarning();
	}

	override bool apply() { mixin(S_TRACE);
		if (!_evt) _evt = new Content(CType.LOSE_BG_IMAGE, "");
		_evt.cellName = _name.getText();
		_evt.transition = _transition.transition;
		_evt.transitionSpeed = _transition.transitionSpeed;
		_evt.doAnime = _doAnime.getSelection();
		_evt.ignoreEffectBooster = _ignoreEffectBooster.getSelection();
		if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
			comm.refCellNames.call();
		}
		return true;
	}
}

/// BGMイベントの設定を行うダイアログ。
class BgmDialog : EventDialog {
private:
	MaterialSelect!(MtType.BGM, Combo, Table) _msel;

	override
	protected void refreshWarning() { mixin(S_TRACE);
		auto ws = comm.skin.warningBGM(prop.parent, _msel.filePath, summ && summ.legacy, _prop.var.etc.targetVersion);
		ws ~= _msel.warnings;
		warning = ws;
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) { mixin(S_TRACE);
		super (comm, prop, shell, summ, CType.PLAY_BGM, parent, evt, true, prop.var.soundEvtDlg, true);
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(1, true));
		auto comp = new Composite(area, SWT.NONE);
		comp.setLayout(zeroMarginGridLayout(4, false));
		comp.setLayoutData(new GridData(GridData.FILL_BOTH));
		{ mixin(S_TRACE);
			auto skin = _comm.skin;
			_msel = new MaterialSelect!(MtType.BGM, Combo, Table)
				(_comm, _prop, _summ, false, null, included => [_prop.msgs.defaultSelection(_prop.msgs.bgmStop)]);
			_msel.createDirsCombo(comp).setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			mod(_msel);
			_msel.modEvent ~= &refreshWarning;

			_msel.createPlayButton(comp).setLayoutData(new GridData);
			_msel.createRefreshButton(comp, false).setLayoutData(new GridData);
			_msel.createDirectoryButton(comp, false).setLayoutData(new GridData);

			auto h4GD(int style) {
				auto gd = new GridData(style);
				gd.horizontalSpan = 4;
				return gd;
			}
			auto gd = h4GD(GridData.FILL_BOTH);
			gd.widthHint = _prop.var.etc.nameTableWidth;
			gd.heightHint = _prop.var.etc.nameTableHeight;
			auto list = _msel.createFileList(comp);
			list.setLayoutData(gd);

			_msel.createPlayingBar(comp).setLayoutData(h4GD(GridData.FILL_HORIZONTAL));
			_msel.createPlayingOptions(comp, true).setLayoutData(h4GD(GridData.HORIZONTAL_ALIGN_END));
			_msel.createFadeIn(comp).setLayoutData(h4GD(GridData.HORIZONTAL_ALIGN_END));
		}
		ignoreMod = true;
		scope (exit) ignoreMod = false;
		_msel.path = _evt ? _evt.bgmPath : "";
		if (_evt) { mixin(S_TRACE);
			_msel.volume = _evt.bgmVolume;
			_msel.loopCount = _evt.bgmLoopCount;
			_msel.fadeIn = _evt.bgmFadeIn;
			_msel.channel = _evt.bgmChannel;
		}
		refreshWarning();
	}

	override bool apply() { mixin(S_TRACE);
		if (!_evt) _evt = new Content(CType.PLAY_BGM, "");
		_evt.bgmPath = _msel.path;
		_evt.bgmVolume = _msel.volume;
		_evt.bgmLoopCount = _msel.loopCount;
		_evt.bgmFadeIn = _msel.fadeIn;
		_evt.bgmChannel = _msel.channel;
		return true;
	}
}

/// 効果音イベントの設定を行うダイアログ。
class SeDialog : EventDialog {
private:
	MaterialSelect!(MtType.SE, Combo, Table) _msel;

	override
	protected void refreshWarning() { mixin(S_TRACE);
		auto ws = comm.skin.warningSE(prop.parent, _msel.filePath, summ && summ.legacy, _prop.var.etc.targetVersion);
		ws ~= _msel.warnings;
		warning = ws;
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) { mixin(S_TRACE);
		super (comm, prop, shell, summ, CType.PLAY_SOUND, parent, evt, true, prop.var.soundEvtDlg, true);
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(1, true));
		auto comp = new Composite(area, SWT.NONE);
		comp.setLayout(zeroMarginGridLayout(5, false));
		comp.setLayoutData(new GridData(GridData.FILL_BOTH));
		{ mixin(S_TRACE);
			auto skin = _comm.skin;
			_msel = new MaterialSelect!(MtType.SE, Combo, Table)
				(_comm, _prop, _summ, false, null, included => [_prop.msgs.defaultSelection(_prop.msgs.noSelect)]);
			_msel.createDirsCombo(comp).setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			mod(_msel);
			_msel.modEvent ~= &refreshWarning;

			_msel.createStopButton(comp).setLayoutData(new GridData);
			_msel.createPlayButton(comp).setLayoutData(new GridData);
			_msel.createRefreshButton(comp, false).setLayoutData(new GridData);
			_msel.createDirectoryButton(comp, false).setLayoutData(new GridData);

			auto h5GD(int style) {
				auto gd = new GridData(style);
				gd.horizontalSpan = 5;
				return gd;
			}
			auto gd = h5GD(GridData.FILL_BOTH);
			gd.widthHint = _prop.var.etc.nameTableWidth;
			gd.heightHint = _prop.var.etc.nameTableHeight;
			auto list = _msel.createFileList(comp);
			list.setLayoutData(gd);

			_msel.createPlayingOptions(comp, true).setLayoutData(h5GD(GridData.HORIZONTAL_ALIGN_END));
			_msel.createFadeIn(comp).setLayoutData(h5GD(GridData.HORIZONTAL_ALIGN_END));
		}
		ignoreMod = true;
		scope (exit) ignoreMod = false;
		_msel.path = _evt ? _evt.soundPath : "";
		if (_evt) { mixin(S_TRACE);
			_msel.volume = _evt.soundVolume;
			_msel.loopCount = _evt.soundLoopCount;
			_msel.fadeIn = _evt.soundFadeIn;
			_msel.channel = _evt.soundChannel;
		}
		refreshWarning();
	}

	override bool apply() { mixin(S_TRACE);
		if (!_evt) _evt = new Content(CType.PLAY_SOUND, "");
		_evt.soundPath = _msel.path;
		_evt.soundVolume = _msel.volume;
		_evt.soundLoopCount = _msel.loopCount;
		_evt.soundFadeIn = _msel.fadeIn;
		_evt.soundChannel = _msel.channel;
		return true;
	}
}

/// 数値の設定を行うダイアログ。
private class NumericEventDialog(CType Type, string Name, string Max, string Get, string Set, uint Min = 0, uint Def = 0) : EventDialog {
private:
	Spinner _value;

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) { mixin(S_TRACE);
		super (comm, prop, shell, summ, Type, parent, evt, false, null, true);
	}
protected:
	private class PM : SelectionAdapter {
		private int _v;
		this (int v) { _v = v; }
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			_value.setSelection(_value.getSelection() + _v);
		}
	}
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(1, false));
		{ mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setText(mixin(Name));
			grp.setLayout(new CenterLayout(SWT.VERTICAL | SWT.HORIZONTAL, 0));
			auto comp = new Composite(grp, SWT.NONE);
			_value = new Spinner(comp, SWT.BORDER);
			initSpinner(_value);
			mod(_value);
			_value.setMinimum(Min);
			_value.setMaximum(mixin(Max));
			comp.setLayout(normalGridLayout(10 <= _value.getMaximum() ? 3 : 2, false));
			if (10 <= _value.getMaximum()) { mixin(S_TRACE);
				auto tools = new Composite(comp, SWT.NONE);
				tools.setLayout(new FillLayout(SWT.HORIZONTAL));
				for (int i = 5; i <= _value.getMaximum() && i < 10000; i*= i == 5 ? 2 : 10) { mixin(S_TRACE);
					auto ts = new Composite(tools, SWT.NONE);
					ts.setLayout(new FillLayout(SWT.VERTICAL));
					void createB(int i) { mixin(S_TRACE);
						auto r = new Button(ts, SWT.PUSH);
						auto fontd = r.getFont().getFontData();
						foreach (fd; fontd) { mixin(S_TRACE);
							fd.height /= 1.5;
						}
						r.setFont(new Font(Display.getCurrent(), fontd));
						r.addDisposeListener(new class DisposeListener {
							override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
								(cast(Control) e.widget).getFont().dispose();
							}
						});
						r.setText(i < 0 ? to!(string)(i) : "+" ~ to!(string)(i));
						r.addSelectionListener(new PM(i));
					}
					createB(i);
					createB(-i);
				}
			}
			auto l = new Label(comp, SWT.NONE);
			l.setText(.tryFormat(_prop.msgs.rangeHint, Min, _value.getMaximum()));
		}

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) { mixin(S_TRACE);
			_value.setSelection(mixin(Get));
		} else { mixin(S_TRACE);
			_value.setSelection(Def);
		}
	}

	override bool apply() { mixin(S_TRACE);
		if (!_evt) _evt = new Content(Type, "");
		int value = _value.getSelection();
		mixin(Set);
		return true;
	}
}

alias NumericEventDialog!(CType.WAIT, "_prop.msgs.waitName",
		"_prop.var.etc.waitMax", "_evt.wait", "_evt.wait = value;") WaitEventDialog;

alias NumericEventDialog!(CType.BRANCH_RANDOM, "_prop.msgs.randomName",
		"100", "_evt.percent", "_evt.percent = value;", 0, 50) BrRandomEventDialog;

alias NumericEventDialog!(CType.BRANCH_PARTY_NUMBER, "_prop.msgs.partyNumName",
		"_prop.var.etc.partyMax", "_evt.partyNumber", "_evt.partyNumber = value;", 1, 1) BrNumEventDialog;

template MoneyEventDialog(CType Type) {
	alias NumericEventDialog!(Type, "_prop.msgs.moneyName",
		"_prop.var.etc.priceMax", "_evt.money", "_evt.money = value;") MoneyEventDialog;
}

/// 効果イベントの設定を行うダイアログ。
class EffectDialog : EventDialog {
private:
	MotionView _mview;
	UseCounter _useCounter;
	Spinner _lev;
	Button _initialEffect;
	SoundSelect _se1;
	SoundSelect _se2;
	Scale _sucRate;
	Button[EffectType] _effTyp;
	Button[Resist] _res;
	Button[CardVisual] _vis;
	RangePanel _range;
	CardAnimationPanel _cardSpeed;

	Button _ignite;
	KeyCodeView _keyCodes;

	Button _refAbility;
	AbilityView _ability;

	override
	protected void refreshWarning() { mixin(S_TRACE);
		string[] ws;
		ws ~= _mview.warnings;
		ws ~= _range.warnings;

		if (summ) { mixin(S_TRACE);
			if (_refAbility.getSelection() && !prop.isTargetVersion(summ, "2")) { mixin(S_TRACE);
				// Wsn.1以前は選択メンバの能力参照は指定不可
				ws ~= prop.msgs.warningRefAbility;
			}
			if (_ignite.getSelection() && !prop.isTargetVersion(summ, "2")) { mixin(S_TRACE);
				// Wsn.1以前はイベント発火の有無は指定不可
				ws ~= .tryFormat(prop.msgs.warningIgnite);
			}
		}
		ws ~= _cardSpeed.warnings;
		if (!_ignite.getSelection() && _keyCodes.keyCodes.length) { mixin(S_TRACE);
			ws ~= prop.msgs.warningIgnoreKeyCode;
		}
		if (_keyCodes.enabled) { mixin(S_TRACE);
			ws ~= _keyCodes.warnings;
		}

		if (_initialEffect.getSelection() && !prop.isTargetVersion(summ, "4")) { mixin(S_TRACE);
			ws ~= prop.msgs.warningInitialEffect;
		}
		if (_summ && _summ.legacy && _se1.filePath != "" && !_se1.selectedDefDir) ws ~= prop.msgs.warningNotDefaultSE;
		ws ~= comm.skin.warningSE(prop.parent, _se1.filePath, summ && summ.legacy, prop.var.etc.targetVersion) ~ _se1.warnings;
		if (_summ && _summ.legacy && _se2.filePath != "" && !_se2.selectedDefDir) ws ~= prop.msgs.warningNotDefaultSE;
		ws ~= comm.skin.warningSE(prop.parent, _se2.filePath, summ && summ.legacy, prop.var.etc.targetVersion) ~ _se2.warnings;
		warning = ws;
	}

	override
	protected void refDataVersion() { mixin(S_TRACE);
		updateEnabled();
		super.refDataVersion();
	}

	void updateEnabled() { mixin(S_TRACE);
		_ignite.setEnabled(!summ || !summ.legacy);
		_keyCodes.enabled = _ignite.getSelection() || _keyCodes.keyCodes.length;
		_refAbility.setEnabled(!summ || !summ.legacy);
		_ability.enabled = _refAbility.getSelection();
		_lev.setEnabled(!_refAbility.getSelection());
		_initialEffect.setEnabled(!summ || !summ.legacy || _initialEffect.getSelection());
		_se1.enabled = _initialEffect.getSelection();
		refreshWarning();
	}

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, UseCounter uc, Content parent, Content evt) { mixin(S_TRACE);
		super (comm, prop, shell, summ, CType.EFFECT, parent, evt, true, prop.var.effEvtDlg, true);
		_useCounter = uc;
	}

	override
	bool openCWXPath(string path, bool shellActivate) { mixin(S_TRACE);
		return _mview.openCWXPath(path, shellActivate);
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		auto cl = new CenterLayout;
		cl.fillHorizontal = true;
		cl.fillVertical = true;
		area.setLayout(cl);
		auto tabf = new CTabFolder(area, SWT.BORDER);
		auto tabM = new CTabItem(tabf, SWT.NONE);
		tabM.setText(_prop.msgs.motion);
		{ mixin(S_TRACE);
			_mview = new MotionView(_comm, _prop, _summ, _useCounter, tabf, SWT.NONE);
			mod(_mview);
			_mview.warningEvent ~= &refreshWarning;
			tabM.setControl(_mview);
		}
		auto tabS = new CTabItem(tabf, SWT.NONE);
		tabS.setText(_prop.msgs.settings);
		{ mixin(S_TRACE);
			auto comp = new Composite(tabf, SWT.NONE);
			tabS.setControl(comp);
			comp.setLayout(normalGridLayout(2, false));
			{ mixin(S_TRACE);
				auto comp2 = new Composite(comp, SWT.NONE);
				comp2.setLayoutData(new GridData(GridData.FILL_VERTICAL));
				comp2.setLayout(zeroMarginGridLayout(1, true));
				{ mixin(S_TRACE);
					auto grp = new Group(comp2, SWT.NONE);
					grp.setText(_prop.msgs.targetLevel);
					grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
					grp.setLayout(normalGridLayout(2, false));
					_lev = new Spinner(grp, SWT.BORDER);
					initSpinner(_lev);
					mod(_lev);
					_lev.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
					_lev.setMinimum(-(cast(int) _prop.var.etc.castLevelMax));
					_lev.setMaximum(_prop.var.etc.castLevelMax);
					auto l = new Label(grp, SWT.NONE);
					l.setText(.tryFormat(_prop.msgs.rangeHint, _lev.getMinimum(), _lev.getMaximum()));
				}
				{ mixin(S_TRACE);
					auto grp = new Group(comp2, SWT.NONE);
					grp.setText(_prop.msgs.elementProps);
					grp.setLayoutData(new GridData(GridData.FILL_BOTH));
					grp.setLayout(normalGridLayout(2, true));
					foreach (i, eff; [EffectType.PHYSIC, EffectType.MAGIC,
							EffectType.MAGICAL_PHYSIC, EffectType.PHYSICAL_MAGIC,
							EffectType.NONE]) { mixin(S_TRACE);
						auto radio = new Button(grp, SWT.RADIO);
						mod(radio);
						auto gd = new GridData(GridData.FILL_BOTH);
						if (2 <= i) { mixin(S_TRACE);
							gd.horizontalSpan = 2;
						}
						radio.setLayoutData(gd);
						radio.setText(.tryFormat(_prop.msgs.effectTypeElement, _prop.msgs.effectTypeName(eff)));
						radio.setToolTipText(.replace(_prop.msgs.effectTypeDesc(eff), "&", "&&"));
						_effTyp[eff] = radio;
					}
				}
				{ mixin(S_TRACE);
					auto grp = new Group(comp2, SWT.NONE);
					grp.setText(_prop.msgs.resistProps);
					grp.setLayoutData(new GridData(GridData.FILL_BOTH));
					grp.setLayout(normalGridLayout(2, true));
					foreach (res; [Resist.AVOID, Resist.RESIST, Resist.UNFAIL]) { mixin(S_TRACE);
						auto radio = new Button(grp, SWT.RADIO);
						mod(radio);
						radio.setText(_prop.msgs.resistName(res));
						radio.setToolTipText(.replace(_prop.msgs.resistDesc(res), "&", "&&"));
						radio.setLayoutData(new GridData(GridData.FILL_BOTH));
						_res[res] = radio;
					}
				}
			}
			{ mixin(S_TRACE);
				auto comp2 = new Composite(comp, SWT.NONE);
				comp2.setLayoutData(new GridData(GridData.FILL_BOTH));
				comp2.setLayout(zeroMarginGridLayout(2, false));
				{ mixin(S_TRACE);
					auto grp = new Group(comp2, SWT.NONE);
					grp.setText(_prop.msgs.effectVisual);
					grp.setLayoutData(new GridData(GridData.FILL_VERTICAL));
					grp.setLayout(normalGridLayout(1, false));
					foreach (v; [CardVisual.NONE, CardVisual.REVERSE, CardVisual.HORIZONTAL, CardVisual.VERTICAL]) { mixin(S_TRACE);
						auto radio = new Button(grp, SWT.RADIO);
						mod(radio);
						radio.setLayoutData(new GridData(GridData.FILL_BOTH));
						radio.setText(_prop.msgs.cardVisualName(v));
						_vis[v] = radio;
					}
				}

				{ mixin(S_TRACE);
					auto ranges = [Range.SELECTED, Range.RANDOM, Range.PARTY, Range.COUPON_HOLDER, Range.CARD_TARGET];
					auto title = _prop.msgs.cardEventRange;
					auto initCoupon = (evt && evt.holdingCoupon != "") ? evt.holdingCoupon : prop.sys.effectTargetCoupon;
					_range = new RangePanel(comm, summ, _useCounter, comp2, ranges, initCoupon, title, false, this, evt, &catchMod, &refreshWarning, type);
					_range.setLayoutData(new GridData(GridData.FILL_BOTH));
				}
				{ mixin(S_TRACE);
					auto gd = new GridData(GridData.FILL_BOTH);
					gd.horizontalSpan = 2;
					createSuccessRateScale(_prop, comp2, _sucRate).setLayoutData(gd);
					mod(_sucRate);
				}
				{ mixin(S_TRACE);
					auto grp = new Group(comp2, SWT.NONE);
					auto gd = new GridData(GridData.FILL_BOTH);
					gd.horizontalSpan = 2;
					grp.setLayoutData(gd);
					grp.setText(prop.msgs.cardSpeed);
					grp.setLayout(new CenterLayout);
					_cardSpeed = new CardAnimationPanel(comm, summ, grp, CardAnimationPanelType.MoveCard);
					mod(_cardSpeed);
					_cardSpeed.modEvent ~= &refreshWarning;
				}
			}
		}
		auto tabA = new CTabItem(tabf, SWT.NONE);
		tabA.setText(_prop.msgs.refAbilityTitle);
		{ mixin(S_TRACE);
			auto comp = new Composite(tabf, SWT.NONE);
			tabA.setControl(comp);
			comp.setLayout(normalGridLayout(1, true));
			{ mixin(S_TRACE);
				auto grp = new Group(comp, SWT.NONE);
				grp.setText(prop.msgs.refAbilityTitle);
				grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				grp.setLayout(normalGridLayout(1, true));
				_refAbility = new Button(grp, SWT.CHECK);
				mod(_refAbility);
				_refAbility.setText(prop.msgs.refAbility);
				.listener(_refAbility, SWT.Selection, &updateEnabled);
			}
			_ability = new AbilityView(_comm, comp, SWT.NONE);
			mod(_ability);
			_ability.setLayoutData(new GridData(GridData.FILL_BOTH));
		}
		auto tabE = new CTabItem(tabf, SWT.NONE);
		tabE.setText(_prop.msgs.eventIgnite);
		{ mixin(S_TRACE);
			auto comp = new Composite(tabf, SWT.NONE);
			tabE.setControl(comp);
			comp.setLayout(normalGridLayout(1, true));
			{ mixin(S_TRACE);
				auto grp = new Group(comp, SWT.NONE);
				grp.setText(prop.msgs.igniteTitle);
				auto gd = new GridData(GridData.FILL_HORIZONTAL);
				gd.horizontalSpan = 2;
				grp.setLayoutData(gd);
				grp.setLayout(normalGridLayout(1, true));
				auto comp2 = new Composite(grp, SWT.NONE);
				comp2.setLayoutData(new GridData(GridData.FILL_BOTH));
				auto wgd = windowGridLayout(1, true);
				wgd.marginWidth = 0;
				wgd.marginHeight = 0;
				comp2.setLayout(wgd);
				_ignite = new Button(comp2, SWT.CHECK);
				mod(_ignite);
				_ignite.setText(prop.msgs.ignite);
				.listener(_ignite, SWT.Selection, &updateEnabled);
				auto l = new Label(comp2, SWT.NONE);
				l.setText(prop.msgs.igniteHint);
			}
			auto sash = new SplitPane(comp, SWT.HORIZONTAL);
			sash.setLayoutData(new GridData(GridData.FILL_BOTH));
			{ mixin(S_TRACE);
				auto grp = .createEffectSoundPanel(sash, comm, summ, prop.msgs.initialEffectAndSound, false, true, _initialEffect, _se1, _se2);
				mod(_initialEffect);
				.listener(_initialEffect, SWT.Selection, &updateEnabled);
				mod(_se1);
				_se1.modEvent ~= &refreshWarning;
				_se1.loadedEvent ~= &refreshWarning;
				mod(_se2);
				_se2.modEvent ~= &refreshWarning;
				_se2.loadedEvent ~= &refreshWarning;
			}
			{ mixin(S_TRACE);
				auto grp = new Group(sash, SWT.NONE);
				grp.setText(prop.msgs.keyCodes);
				grp.setLayout(normalGridLayout(1, true));

				_keyCodes = new KeyCodeView(comm, summ, grp, SWT.NONE, true, false, &catchMod);
				_keyCodes.setLayoutData(new GridData(GridData.FILL_BOTH));
				mod(_keyCodes);
				_keyCodes.modEvent ~= &updateEnabled;
			}
			.setupWeights(sash, _prop.var.etc.effectContentSEKeyCodeSashL, _prop.var.etc.effectContentSEKeyCodeSashR);
		}

		tabf.setLayoutData(area.computeSize(SWT.DEFAULT, SWT.DEFAULT));
		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) { mixin(S_TRACE);
			_mview.motions = _evt.motions;
			_lev.setSelection(_evt.signedLevel);
			_initialEffect.setSelection(_evt.initialEffect);
			_se1.path = _evt.initialSoundPath;
			_se1.volume = _evt.initialSoundVolume;
			_se1.loopCount = _evt.initialSoundLoopCount;
			_se2.path = _evt.soundPath;
			_se2.volume = _evt.soundVolume;
			_se2.loopCount = _evt.soundLoopCount;
			_sucRate.setSelection(_evt.successRate + Content.successRate_max);
			_effTyp[_evt.effectType].setSelection(true);
			_res[_evt.resist].setSelection(true);
			_vis[_evt.cardVisual].setSelection(true);
			_refAbility.setSelection(_evt.refAbility);
			_ability.physical = _evt.physical;
			_ability.mental = _evt.mental;
			_ignite.setSelection(_evt.ignite);
			_keyCodes.keyCodes = _evt.keyCodes;
			_cardSpeed.speed = _evt.cardSpeed;
			_cardSpeed.overrideCardSpeed = _evt.overrideCardSpeed;
		} else { mixin(S_TRACE);
			_mview.motions = [];
			_lev.setSelection(0);
			_initialEffect.setSelection(false);
			_se1.path = "";
			_se2.path = "";
			_sucRate.setSelection(Content.successRate_max + Content.successRate_max);
			_effTyp[EffectType.NONE].setSelection(true);
			_res[Resist.UNFAIL].setSelection(true);
			_vis[CardVisual.NONE].setSelection(true);
			_refAbility.setSelection(false);
			_ignite.setSelection(false);
			_keyCodes.keyCodes = [];
			_cardSpeed.speed = -1;
			_cardSpeed.overrideCardSpeed = false;
		}
		refDataVersion();
	}

	override bool apply() { mixin(S_TRACE);
		if (!_evt) _evt = new Content(CType.EFFECT, "");
		_evt.motions = _mview.motions;
		_evt.signedLevel = _lev.getSelection();
		_evt.initialEffect = _initialEffect.getSelection();
		_evt.initialSoundPath = _se1.path;
		_evt.initialSoundVolume = _se1.volume;
		_evt.initialSoundLoopCount = _se1.loopCount;
		_evt.soundPath = _se2.path;
		_evt.soundVolume = _se2.volume;
		_evt.soundLoopCount = _se2.loopCount;
		_evt.successRate = cast(int) _sucRate.getSelection() - Content.successRate_max;
		_evt.effectType = getRadioValue!(EffectType)(_effTyp);
		_evt.resist = getRadioValue!(Resist)(_res);
		_evt.cardVisual = getRadioValue!(CardVisual)(_vis);
		_evt.range = _range.range;
		_evt.holdingCoupon = _range.holdingCoupon;
		_evt.refAbility = _refAbility.getSelection();
		_evt.physical = _ability.physical;
		_evt.mental = _ability.mental;
		_evt.ignite = _ignite.getSelection();
		_evt.keyCodes = _keyCodes.keyCodes;
		if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
			comm.refKeyCodes.call();
		}
		_evt.cardSpeed = _cardSpeed.speed;
		_evt.overrideCardSpeed = _cardSpeed.overrideCardSpeed;
		return true;
	}
}

/// フラグ・ステップの選択・設定を行うダイアログ。
private class FlagStepDialog(CType Type, F, bool SelValue) : EventDialog {
private:
	override
	protected void refreshWarning() { mixin(S_TRACE);
		string[] ws;
		static if (Type is CType.CHECK_STEP) {
			if (!_prop.targetVersion(summ, "1.50")) { mixin(S_TRACE);
				ws ~= .tryFormat(_prop.msgs.warningUnknownContent, _prop.msgs.contentName(CType.CHECK_STEP), "1.50");
			}
		}
		static if (is(typeof(_cardSpeed))) {
			ws ~= _cardSpeed.warnings;
		}
		warning = ws;
	}

	FlagDir _root;
	F _flag = null;

	SplitPane _sash;
	FlagChooser!(F, false) _flags;
	UseCounter _uc;
	string _oldSel = "";
	Table _values;
	static if (Type is CType.SET_FLAG || Type is CType.REVERSE_FLAG) {
		CardAnimationPanel _cardSpeed;
	}

	@property
	uint selectedValue() { mixin(S_TRACE);
		return _values.getSelectionIndex();
	}

	void refreshValues() { mixin(S_TRACE);
		if (!summ) return;
		static if (is(F:cwx.flag.Flag)) {
			_flag = .findVar!(cwx.flag.Flag)(summ ? summ.flagDirRoot : null, _uc, _flags.selected);
		} else static if (is(F:Step)) {
			_flag = .findVar!Step(summ ? summ.flagDirRoot : null, _uc, _flags.selected);
		} else static assert (0);
		static if (SelValue) {
			int sel = _values.getSelectionIndex();
		}
		if (_flag) { mixin(S_TRACE);
			static if (is(F:cwx.flag.Flag)) {
				_values.setItemCount(2);
			} else static if (is(F:Step)) {
				_values.setItemCount(cast(int)_flag.values.length);
			} else static assert (0);
			static if (SelValue) {
				if (sel < 0) sel = 0;
				static if (is(F == Step)) {
					if (sel >= _flag.values.length) sel = cast(int)_flag.values.length - 1;
				}
				_values.select(sel);
			}
		} else { mixin(S_TRACE);
			_values.setItemCount(0);
		}
		_values.clearAll();
		updateLabel();
	}
	void selectedFlag() { mixin(S_TRACE);
		string selPath = _flags.selectedWithDir;
		if (_oldSel == selPath) { mixin(S_TRACE);
			static if (SelValue) {
				if (_values.getSelectionIndex() != 0) { mixin(S_TRACE);
					_values.select(0);
					updateLabel();
					applyEnabled();
				}
			}
		} else { mixin(S_TRACE);
			_oldSel = _flags.selectedWithDir;
			refreshValues();
		}
	}
	class ValSListener : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			updateLabel();
		}
	}
	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			_comm.refFlagAndStep.remove(&refFS);
			_comm.delFlagAndStep.remove(&delFS);
		}
	}
	void refFS(cwx.flag.Flag[] f, Step[] s, cwx.flag.Variant[] v) { mixin(S_TRACE);
		static if (is(F : cwx.flag.Flag)) {
			if (!f.length) return;
		} else { mixin(S_TRACE);
			if (!s.length) return;
		}
		int sel = _values.getSelectionIndex();
		refreshValues();
		_values.select(sel);
	}
	void delFS(cwx.flag.Flag[] f, Step[] s, cwx.flag.Variant[] v) { mixin(S_TRACE);
		if (!_root) return;
		static if (is(F : cwx.flag.Flag)) {
			if (!f.length) return;
		} else { mixin(S_TRACE);
			if (!s.length) return;
		}
		auto lDir = _uc && cast(LocalVariableOwner)_uc.owner ? (cast(LocalVariableOwner)_uc.owner).flagDirRoot : null;
		static if (is(F : cwx.flag.Flag)) {
			if (!_root.hasFlag && (!lDir || !lDir.hasFlag)) { mixin(S_TRACE);
				forceCancel();
				return;
			}
		} else static if (is(F : Step)) {
			if (!_root.hasStep && (!lDir || !lDir.hasStep)) { mixin(S_TRACE);
				forceCancel();
				return;
			}
		} else static assert (0);
		refreshValues();
	}

	static if (Type is CType.CHECK_STEP) {
		Label _cmpLabel = null;
		Combo _cmp = null;
		Comparison4[] _cmps;
		void updateLabel() { mixin(S_TRACE);
			if (!summ) return;
			static assert (is(F:Step));
			auto step = .findVar!Step(summ ? summ.flagDirRoot : null, _uc, _flags.selected);
			if (!step) return;
			uint value = selectedValue;
			_cmpLabel.setText(.tryFormat(prop.msgs.stepValueIs, step.path, step.getValue(value)));
		}
	} else {
		void updateLabel() { mixin(S_TRACE);
			// 処理無し
		}
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, UseCounter uc, Content parent, Content evt, FlagDir root) { mixin(S_TRACE);
		_root = root;
		_uc = uc;
		super (comm, prop, shell, summ, Type, parent, evt, true, prop.var.flagEvtDlg, true);
		closeEvent ~= { mixin(S_TRACE);
			auto ws = _sash.getWeights();
			_prop.var.etc.flagEventSashL = ws[0];
			_prop.var.etc.flagEventSashR = ws[1];
		};
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(1, true));
		_sash = new SplitPane(area, SWT.HORIZONTAL);
		_sash.setLayoutData(new GridData(GridData.FILL_BOTH));
		auto left = new Composite(_sash, SWT.NONE);
		left.setLayout(zeroGridLayout(1));
		auto right = new Composite(_sash, SWT.NONE);
		right.setLayout(zeroGridLayout(1));
		{ mixin(S_TRACE);
			auto l1 = new CLabel(left, SWT.NONE);
			auto l2 = new CLabel(right, SWT.NONE);
			static if (is(F == cwx.flag.Flag)) {
				l1.setText(_prop.msgs.flag);
				l1.setImage(_prop.images.flag);
				l2.setText(_prop.msgs.flagValue);
			} else static if (is(F == Step)) {
				l1.setText(_prop.msgs.step);
				l1.setImage(_prop.images.step);
				l2.setText(_prop.msgs.stepValue);
			} else { mixin(S_TRACE);
				static assert (0);
			}
			auto gd = new GridData;
			gd.heightHint = l1.computeSize(SWT.DEFAULT, SWT.DEFAULT).y;
			l2.setLayoutData(gd);
		}
		{ mixin(S_TRACE);
			_flags = new FlagChooser!(F, false, false)(comm, summ, _uc, left, true);
			mod(_flags);
			_flags.modEventWithSame ~= &selectedFlag;
			_flags.setLayoutData(new GridData(GridData.FILL_BOTH));
		}
		{ mixin(S_TRACE);
			_values = .rangeSelectableTable(right, SWT.SINGLE | SWT.FULL_SELECTION | SWT.BORDER | SWT.V_SCROLL | SWT.VIRTUAL);
			new FullTableColumn(_values, SWT.NONE);
			mod(_values);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.heightHint = _prop.var.etc.nameTableHeight;
			_values.setLayoutData(gd);
			_values.setEnabled(SelValue && summ && summ.scenarioPath != "");
			_values.addSelectionListener(new ValSListener);
			.listener(_values, SWT.SetData, (e) { mixin(S_TRACE);
				assert (_flag !is null);
				auto itm = cast(TableItem)e.item;
				static if (is(F:cwx.flag.Flag)) {
					if (e.index == 0) { mixin(S_TRACE);
						itm.setText(_flag.on);
					} else if (e.index == 1) { mixin(S_TRACE);
						itm.setText(_flag.off);
					} else assert (0);
				} else static if (is(F:Step)) {
					itm.setText(_flag.values[e.index]);
				} else static assert (0);
			});
		}
		static if (Type is CType.CHECK_STEP) {
			auto comp = new Composite(area, SWT.NONE);
			comp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			comp.setLayout(zeroMarginGridLayout(2, false));
			_cmpLabel = new Label(comp, SWT.RIGHT);
			_cmpLabel.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			_cmp = new Combo(comp, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
			mod(_cmp);
			_cmp.setVisibleItemCount(prop.var.etc.comboVisibleItemCount);
			foreach (cmp; EnumMembers!Comparison4) { mixin(S_TRACE);
				_cmp.add(prop.msgs.comparison4Name(cmp));
				_cmps ~= cmp;
			}
		}
		static if (is(typeof(_cardSpeed))) {
			_cardSpeed = new CardAnimationPanel(comm, summ, area, CardAnimationPanelType.SetFlag);
			mod(_cardSpeed);
			_cardSpeed.modEvent ~= &refreshWarning;
			_cardSpeed.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
		}

		if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
			_comm.refFlagAndStep.add(&refFS);
			_comm.delFlagAndStep.add(&delFS);
			_flags.addDisposeListener(new Dispose);
		}

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) { mixin(S_TRACE);
			static if (is(F == cwx.flag.Flag)) {
				_flags.selected = _evt.flag;
			} else static if (is(F == Step)) {
				_flags.selected = _evt.step;
			} else { mixin(S_TRACE);
				static assert (0);
			}
			_oldSel = _flags.selectedWithDir;
			refreshValues();
			static if (SelValue) {
				static if (is(F == cwx.flag.Flag)) {
					_values.select(_evt.flagValue ? 0 : 1);
				} else static if (is(F == Step)) {
					_values.select(_evt.stepValue);
				} else { mixin(S_TRACE);
					static assert (0);
				}
			}
			static if (Type is CType.CHECK_STEP) {
				_cmp.select(cast(int)_cmps.countUntil(_evt.comparison4));
			}
			static if (is(typeof(_cardSpeed))) {
				_cardSpeed.speed = _evt.cardSpeed;
				_cardSpeed.overrideCardSpeed = _evt.overrideCardSpeed;
			}
		} else { mixin(S_TRACE);
			_flags.selected = "";
			refreshValues();
			static if (Type is CType.CHECK_STEP) {
				_cmp.select(0);
			}
			static if (is(typeof(_cardSpeed))) {
				_cardSpeed.speed = -1;
				_cardSpeed.overrideCardSpeed = false;
			}
		}
		updateLabel();
		refDataVersion();
		.setupWeights(_sash, _prop.var.etc.flagEventSashL, _prop.var.etc.flagEventSashR);
	}

	override bool apply() { mixin(S_TRACE);
		if (!_evt) _evt = new Content(Type, "");
		static if (is(F == cwx.flag.Flag)) {
			_evt.flag = _flags.selected;
			static if (SelValue) {
				_evt.flagValue = _values.getSelectionIndex() == 0;
			}
		} else static if (is(F == Step)) {
			_evt.step = _flags.selected;
			static if (SelValue) {
				_evt.stepValue = _values.getSelectionIndex() == -1 ? 0 : _values.getSelectionIndex();
			}
		} else { mixin(S_TRACE);
			static assert (0);
		}
		static if (Type is CType.CHECK_STEP) {
			_evt.comparison4 = _cmps[_cmp.getSelectionIndex()];
	}
		static if (is(typeof(_cardSpeed))) {
			_evt.cardSpeed = _cardSpeed.speed;
			_evt.overrideCardSpeed = _cardSpeed.overrideCardSpeed;
		}
		return true;
	}
}

alias FlagStepDialog!(CType.BRANCH_FLAG, cwx.flag.Flag, false) BrFlagDialog;
alias FlagStepDialog!(CType.BRANCH_MULTI_STEP, Step, false) BrStepNDialog;
alias FlagStepDialog!(CType.BRANCH_STEP, Step, true) BrStepULDialog;
alias FlagStepDialog!(CType.SET_FLAG, cwx.flag.Flag, true) FlagSetDialog;
alias FlagStepDialog!(CType.SET_STEP, Step, true) StepSetDialog;
alias FlagStepDialog!(CType.SET_STEP_UP, Step, false) StepPlusDialog;
alias FlagStepDialog!(CType.SET_STEP_DOWN, Step, false) StepMinusDialog;
alias FlagStepDialog!(CType.REVERSE_FLAG, cwx.flag.Flag, false) FlagRDialog;
alias FlagStepDialog!(CType.CHECK_FLAG, cwx.flag.Flag, false) FlagJudgeDialog;
alias FlagStepDialog!(CType.CHECK_STEP, Step, true) CheckStepDialog;

/// フラグ・ステップの組み合わせを選択するダイアログ。
private class FlagStepCombiDialog(CType Type, F, bool Random) : EventDialog {
private:
	FlagDir _root;
	UseCounter _uc;

	SplitPane _sash;
	FlagChooser!(F, false, Random) _flags1;
	FlagChooser!(F, false, false) _flags2;
	static if (Type is CType.SUBSTITUTE_FLAG) {
		CardAnimationPanel _cardSpeed;
	}

	override
	protected void refreshWarning() { mixin(S_TRACE);
		string[] ws;
		if (!_prop.targetVersion(summ, "1.30")) { mixin(S_TRACE);
			ws ~= .tryFormat(_prop.msgs.warningUnknownContent, _prop.msgs.contentName(Type), "1.30");
		}
		static if (Type == CType.SUBSTITUTE_STEP) {
			if (.icmp(_flags1.selected, prop.sys.selectedPlayerCardNumber) == 0 && !prop.isTargetVersion(summ, "2")) { mixin(S_TRACE);
				ws ~= _prop.msgs.warningSelectedPlayerValue;
			}
		}
		static if (is(typeof(_cardSpeed))) {
			ws ~= _cardSpeed.warnings;
		}
		warning = ws;
	}

	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			_comm.delFlagAndStep.remove(&delFS);
		}
	}
	void delFS(cwx.flag.Flag[] f, Step[] s, cwx.flag.Variant[] v) { mixin(S_TRACE);
		if (!_root) return;
		auto lDir = _uc && cast(LocalVariableOwner)_uc.owner ? (cast(LocalVariableOwner)_uc.owner).flagDirRoot : null;
		static if (is(F : cwx.flag.Flag)) {
			if (!_root.hasFlag && (!lDir || !lDir.hasFlag)) { mixin(S_TRACE);
				forceCancel();
			}
		} else static if (is(F : Step)) {
			if (!_root.hasStep && (!lDir || !lDir.hasStep)) { mixin(S_TRACE);
				forceCancel();
			}
		} else static assert (0);
	}

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, UseCounter uc, Content parent, Content evt, FlagDir root) { mixin(S_TRACE);
		_root = root;
		_uc = uc;
		super (comm, prop, shell, summ, Type, parent, evt, true, prop.var.flagCombiDlg, true);
		closeEvent ~= { mixin(S_TRACE);
			auto ws = _sash.getWeights();
			_prop.var.etc.flagCombiSashL = ws[0];
			_prop.var.etc.flagCombiSashR = ws[1];
		};
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(1, true));
		_sash = new SplitPane(area, SWT.HORIZONTAL);
		_sash.setLayoutData(new GridData(GridData.FILL_BOTH));
		auto left = new Composite(_sash, SWT.NONE);
		left.setLayout(zeroGridLayout(1));
		auto right = new Composite(_sash, SWT.NONE);
		right.setLayout(zeroGridLayout(1));
		{ mixin(S_TRACE);
			auto l1 = new CLabel(left, SWT.NONE);
			auto l2 = new CLabel(right, SWT.NONE);
			static if (Type == CType.SUBSTITUTE_STEP || Type == CType.SUBSTITUTE_FLAG) {
				l1.setText(_prop.msgs.substituteSource);
				l2.setText(_prop.msgs.substituteTarget);
			} else static if (Type == CType.BRANCH_STEP_CMP || Type == CType.BRANCH_FLAG_CMP) {
				l1.setText(_prop.msgs.cmpSource);
				l2.setText(_prop.msgs.cmpTarget);
			} else static assert (0);
			static if (is(F == cwx.flag.Flag)) {
				l1.setImage(_prop.images.flag);
				l2.setImage(_prop.images.flag);
			} else static if (is(F == Step)) {
				l1.setImage(_prop.images.step);
				l2.setImage(_prop.images.step);
			} else { mixin(S_TRACE);
				static assert (0);
			}
		}
		_flags1 = new FlagChooser!(F, false, Random)(comm, summ, _uc, left);
		_flags1.setLayoutData(new GridData(GridData.FILL_BOTH));
		_flags1.modEvent ~= &applyEnabled;
		static if (Type == CType.SUBSTITUTE_STEP) {
			_flags1.modEvent ~= &refreshWarning;
		}
		_flags2 = new FlagChooser!(F, false, false)(comm, summ, _uc, right, false);
		_flags2.setLayoutData(new GridData(GridData.FILL_BOTH));
		_flags2.modEvent ~= &applyEnabled;

		static if (is(typeof(_cardSpeed))) {
			_cardSpeed = new CardAnimationPanel(comm, summ, area, CardAnimationPanelType.SetFlag);
			mod(_cardSpeed);
			_cardSpeed.modEvent ~= &refreshWarning;
			_cardSpeed.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
		}

		if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
			_comm.delFlagAndStep.add(&delFS);
			_sash.addDisposeListener(new Dispose);
		}

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) { mixin(S_TRACE);
			static if (is(F == cwx.flag.Flag)) {
				_flags1.selected = _evt.flag;
				_flags2.selected = _evt.flag2;
			} else static if (is(F == Step)) {
				_flags1.selected = _evt.step;
				_flags2.selected = _evt.step2;
			} else { mixin(S_TRACE);
				static assert (0);
			}
			static if (is(typeof(_cardSpeed))) {
				_cardSpeed.speed = _evt.cardSpeed;
				_cardSpeed.overrideCardSpeed = _evt.overrideCardSpeed;
			}
		} else { mixin(S_TRACE);
			_flags1.selected = "";
			_flags2.selected = "";
			static if (is(typeof(_cardSpeed))) {
				_cardSpeed.speed = -1;
				_cardSpeed.overrideCardSpeed = false;
			}
		}
		refDataVersion();
		.setupWeights(_sash, _prop.var.etc.flagCombiSashL, _prop.var.etc.flagCombiSashR);
	}

	override bool apply() { mixin(S_TRACE);
		if (!_evt) _evt = new Content(Type, "");
		static if (is(F == cwx.flag.Flag)) {
			_evt.flag = _flags1.selected;
			_evt.flag2 = _flags2.selected;
		} else static if (is(F == Step)) {
			_evt.step = _flags1.selected;
			_evt.step2 = _flags2.selected;
		} else { mixin(S_TRACE);
			static assert (0);
		}
		static if (is(typeof(_cardSpeed))) {
			_evt.cardSpeed = _cardSpeed.speed;
			_evt.overrideCardSpeed = _cardSpeed.overrideCardSpeed;
		}
		return true;
	}
}

alias FlagStepCombiDialog!(CType.SUBSTITUTE_STEP, Step, true) SubstituteStepDialog;
alias FlagStepCombiDialog!(CType.SUBSTITUTE_FLAG, cwx.flag.Flag, true) SubstituteFlagDialog;
alias FlagStepCombiDialog!(CType.BRANCH_STEP_CMP, Step, false) BrStepCmpDialog;
alias FlagStepCombiDialog!(CType.BRANCH_FLAG_CMP, cwx.flag.Flag, false) BrFlagCmpDialog;

/// メンバ選択分岐の設定を行うダイアログ。
class BrMemberDialog : EventDialog {
private:
	UseCounter _uc;

	Button[] _all;
	Button[] _method;

	CouponView!(CVType.Valued) _couponView;
	Spinner _initValue;

	protected override void refreshWarning() {
		string[] ws;
		auto valued = _method[cast(size_t)SelectionMethod.Valued];
		if (valued.getSelection() && !prop.isTargetVersion(summ, "1")) { mixin(S_TRACE);
			ws ~= prop.msgs.warningValuedSelectionMethod;
		}

		foreach (coupon; _couponView.coupons) { mixin(S_TRACE);
			ws ~= couponWarnings(prop.parent, summ, prop.var.etc.targetVersion, coupon.name, false, prop.msgs.valued);
		}

		warning = ws;
	}

	protected override void refDataVersion() { mixin(S_TRACE);
		auto valued = _method[cast(size_t)SelectionMethod.Valued];
		valued.setEnabled(!summ || !summ.legacy || valued.getSelection() || _couponView.coupons.length);
		_couponView.enabled = valued.isEnabled() && valued.getSelection();
		_initValue.setEnabled(valued.isEnabled() && valued.getSelection());
		refreshWarning();
	}

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, UseCounter uc, Content parent, Content evt) { mixin(S_TRACE);
		super (comm, prop, shell, summ, CType.BRANCH_SELECT, parent, evt, true, prop.var.brMemberDlg, true);
		_uc = uc;
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(1, true));
		void createR(Composite parent, string title, in string[] texts, ref Button[] btns) { mixin(S_TRACE);
			auto grp = new Group(parent, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setText(title);
			grp.setLayout(new CenterLayout(SWT.VERTICAL));
			auto comp = new Composite(grp, SWT.NONE);
			comp.setLayout(zeroMarginGridLayout(1, true));
			foreach (text; texts) { mixin(S_TRACE);
				auto btn = new Button(comp, SWT.RADIO);
				mod(btn);
				btn.setText(text);
				auto gd = new GridData;
				gd.grabExcessVerticalSpace = true;
				btn.setLayoutData(gd);
				btns ~= btn;
			}
		}
		{ mixin(S_TRACE);
			auto comp = new Composite(area, SWT.NONE);
			comp.setLayout(zeroMarginGridLayout(2, false));
			comp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			createR(comp, _prop.msgs.selectMember, [_prop.msgs.activeMember, _prop.msgs.allMember], _all);
			createR(comp, _prop.msgs.selectMethod, [_prop.msgs.manualMethod, _prop.msgs.randomMethod, _prop.msgs.valuedMethod], _method);
			foreach (btn; _method) { mixin(S_TRACE);
				.listener(btn, SWT.Selection, &refDataVersion);
			}
		}

		void delegate() updateValue;
		{ mixin(S_TRACE);
			auto comp = createValueEditor(comm, summ, _uc, area, &catchMod, _couponView, _initValue, updateValue, false);
			mod(_initValue);
			mod(_couponView);
			_couponView.modEvent ~= &refDataVersion;
			comp.setLayoutData(new GridData(GridData.FILL_BOTH));
		}

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) { mixin(S_TRACE);
			_all[_evt.targetAll ? 1 : 0].setSelection(true);
			_method[cast(size_t)_evt.selectionMethod].setSelection(true);
			_couponView.coupons = _evt.coupons;
			_initValue.setSelection(evt.initValue);
		} else { mixin(S_TRACE);
			_all[0].setSelection(true);
			_method[cast(size_t)SelectionMethod.Manual].setSelection(true);
		}
		updateValue();
		refDataVersion();
	}

	override bool apply() { mixin(S_TRACE);
		if (!_evt) _evt = new Content(CType.BRANCH_SELECT, "");
		_evt.targetAll = _all[1].getSelection();
		foreach (method; EnumMembers!SelectionMethod) { mixin(S_TRACE);
			if (_method[cast(size_t)method].getSelection()) { mixin(S_TRACE);
				_evt.selectionMethod = method;
			}
		}
		if (_evt.selectionMethod is SelectionMethod.Valued) { mixin(S_TRACE);
			_evt.coupons = _couponView.coupons;
			_evt.initValue = _initValue.getSelection();
		} else { mixin(S_TRACE);
			_evt.coupons = [];
			_evt.initValue = 0;
		}
		if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
			comm.refCoupons.call();
		}
		return true;
	}
}

/// 評価メンバ設定用のビューを生成する。
Composite createValueEditor(Commons comm, Summary summ, UseCounter uc, Composite parent, bool delegate() catchMod, out CouponView!(CVType.Valued) couponView, out Spinner initValue, out void delegate() updateValue, bool talker = true) { mixin(S_TRACE);
	auto grp = new Group(parent, SWT.NONE);
	grp.setText(comm.prop.msgs.valued);
	grp.setLayout(normalGridLayout(2, false));

	auto lbl = new Label(grp, SWT.NONE);
	lbl.setText(comm.prop.msgs.initValue);
	initValue = new Spinner(grp, SWT.BORDER);
	initSpinner(initValue);
	initValue.setMinimum(cast(int)comm.prop.var.etc.couponValueMax * -1);
	initValue.setMaximum(comm.prop.var.etc.couponValueMax);
	initValue.setSelection(1);
	initValue.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
	couponView = new CouponView!(CVType.Valued)(comm, summ, uc, grp, SWT.NONE, catchMod, false);
	auto gd = new GridData(GridData.FILL_BOTH);
	gd.horizontalSpan = 2;
	couponView.setLayoutData(gd);

	updateValue = { mixin(S_TRACE);
		if (talker && !couponView.coupons.length) { mixin(S_TRACE);
			couponView.toolTip = "";
			return;
		}
		int max = initValue.getSelection();
		int min = max;
		foreach (cp; couponView.coupons) { mixin(S_TRACE);
			if (cp.value < 0) { mixin(S_TRACE);
				min += cp.value;
			} else { mixin(S_TRACE);
				max += cp.value;
			}
		}
		if (0 >= max) { mixin(S_TRACE);
			if (talker) { mixin(S_TRACE);
				couponView.toolTip = .replace(.tryFormat(comm.prop.msgs.valuedTalkerMaxIsLess0, max, min), "&", "&&");
			} else { mixin(S_TRACE);
				couponView.toolTip = .replace(.tryFormat(comm.prop.msgs.selectMemberValuedMaxIsLess0, max, min), "&", "&&");
			}
		} else if (0 >= min) { mixin(S_TRACE);
			if (talker) { mixin(S_TRACE);
				couponView.toolTip = .replace(.tryFormat(comm.prop.msgs.valuedTalkerMaxMinLess0, max, min), "&", "&&");
			} else { mixin(S_TRACE);
				couponView.toolTip = .replace(.tryFormat(comm.prop.msgs.selectMemberValuedMaxMinLess0, max, min), "&", "&&");
			}
		} else { mixin(S_TRACE);
			if (talker) { mixin(S_TRACE);
				couponView.toolTip = .replace(.tryFormat(comm.prop.msgs.valuedTalkerMaxMin, max, min), "&", "&&");
			} else { mixin(S_TRACE);
				couponView.toolTip = .replace(.tryFormat(comm.prop.msgs.selectMemberValuedMaxMin, max, min), "&", "&&");
			}
		}
	};
	.listener(initValue, SWT.Modify, updateValue);
	.listener(initValue, SWT.Selection, updateValue);
	couponView.modEvent ~= updateValue;

	return grp;
}

/// 能力判定分岐の設定を行うダイアログ。
class BrPowerDialog : EventDialog {
private:
	Spinner _lev;
	Button[Target.M] _targ;
	// FIXME: KeyTypeにboolを使えない？
	Button[2] _sleep;
	AbilityView _ability;
	Button _invertResult;

	override
	protected void refreshWarning() { mixin(S_TRACE);
		string[] ws;
		if(!prop.isTargetVersion(summ, "4") && _invertResult.getSelection()) { mixin(S_TRACE);
			ws ~= prop.msgs.warningInvertResult;
		}
		warning = ws;
	}

	override
	protected void refDataVersion() { mixin(S_TRACE);
		updateEnabled();
		super.refDataVersion();
	}
	void updateEnabled() { mixin(S_TRACE);
		_invertResult.setEnabled(!summ || !summ.legacy || _invertResult.getSelection());
	}

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) { mixin(S_TRACE);
		super (comm, prop, shell, summ, CType.BRANCH_ABILITY, parent, evt, false, null, true);
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(3, false));
		{ mixin(S_TRACE);
			auto comp = new Composite(area, SWT.NONE);
			comp.setLayout(zeroMarginGridLayout(1, true));
			{ mixin(S_TRACE);
				auto grp = new Group(comp, SWT.NONE);
				grp.setText(_prop.msgs.targetLevel);
				grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				grp.setLayout(normalGridLayout(2, false));
				_lev = new Spinner(grp, SWT.BORDER);
				initSpinner(_lev);
				mod(_lev);
				_lev.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				_lev.setMinimum(-(cast(int) _prop.var.etc.castLevelMax));
				_lev.setMaximum(_prop.var.etc.castLevelMax);
				auto l = new Label(grp, SWT.NONE);
				l.setText(.tryFormat(_prop.msgs.rangeHint, _lev.getMinimum(), _lev.getMaximum()));
			}
			{ mixin(S_TRACE);
				auto grp = new Group(comp, SWT.NONE);
				grp.setText(_prop.msgs.judgeTarget);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setLayout(normalGridLayout(1, true));
				foreach (m; [Target.M.SELECTED, Target.M.RANDOM, Target.M.PARTY]) { mixin(S_TRACE);
					auto radio = new Button(grp, SWT.RADIO);
					mod(radio);
					radio.setText(_prop.msgs.targetName(m));
					radio.setLayoutData(new GridData(GridData.FILL_BOTH));
					_targ[m] = radio;
				}
			}
			{ mixin(S_TRACE);
				auto grp = new Group(comp, SWT.NONE);
				grp.setText(_prop.msgs.judgeSleep);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setLayout(normalGridLayout(1, true));
				_sleep[1] = new Button(grp, SWT.RADIO);
				mod(_sleep[1]);
				_sleep[1].setText(_prop.msgs.sleepDisabled);
				_sleep[0] = new Button(grp, SWT.RADIO);
				mod(_sleep[0]);
				_sleep[0].setText(_prop.msgs.sleepEnabled);
			}
			{ mixin(S_TRACE);
				auto grp = new Group(comp, SWT.NONE);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setText(_prop.msgs.resultType);
				grp.setLayout(normalGridLayout(1, true));
				_invertResult = new Button(grp, SWT.CHECK);
				mod(_invertResult);
				_invertResult.setText(_prop.msgs.resultTypeInvertForAbility);
				.listener(_invertResult, SWT.Selection, &refDataVersion);
			}
		}
		_ability = new AbilityView(comm, area, SWT.NONE);
		mod(_ability);
		_ability.setLayoutData(new GridData(GridData.FILL_BOTH));

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) { mixin(S_TRACE);
			_lev.setSelection(_evt.signedLevel);
			_targ[_evt.targetS.m].setSelection(true);
			_sleep[_evt.targetS.sleep ? 0 : 1].setSelection(true);
			_ability.physical = _evt.physical;
			_ability.mental = _evt.mental;
			_invertResult.setSelection(_evt.invertResult);
		} else { mixin(S_TRACE);
			_lev.setSelection(0);
			_targ[Target.M.SELECTED].setSelection(true);
			_sleep[1].setSelection(true);
			_invertResult.setSelection(true);
		}
		refDataVersion();
	}

	override bool apply() { mixin(S_TRACE);
		if (!_evt) _evt = new Content(CType.BRANCH_ABILITY, "");
		auto targ = Target(getRadioValue!(Target.M)(_targ), _sleep[0].getSelection());
		_evt.signedLevel = _lev.getSelection();
		_evt.targetS = targ;
		_evt.physical = _ability.physical;
		_evt.mental = _ability.mental;
		_evt.invertResult = _invertResult.getSelection();
		return true;
	}
}

/// レベル判定分岐の設定を行うダイアログ。
class BrLevelDialog : EventDialog {
private:
	Spinner _lev;
	Button[2] _ave;

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) { mixin(S_TRACE);
		super (comm, prop, shell, summ, CType.BRANCH_LEVEL, parent, evt, false, null, true);
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(2, false));
		{ mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			grp.setText(_prop.msgs.judgeTarget);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(new CenterLayout);
			auto comp = new Composite(grp, SWT.NONE);
			comp.setLayout(zeroMarginGridLayout(1, true));
			_ave[1] = new Button(comp, SWT.RADIO);
			mod(_ave[1]);
			_ave[1].setText(_prop.msgs.selectedLevel);
			_ave[0] = new Button(comp, SWT.RADIO);
			mod(_ave[0]);
			_ave[0].setText(_prop.msgs.allMemberLevel);
		}
		{ mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			grp.setText(_prop.msgs.judgeLevel);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(new CenterLayout);
			auto comp = new Composite(grp, SWT.NONE);
			comp.setLayout(zeroMarginGridLayout(2, false));
			_lev = new Spinner(comp, SWT.BORDER);
			initSpinner(_lev);
			mod(_lev);
			_lev.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			_lev.setMinimum(1);
			_lev.setMaximum(_prop.var.etc.castLevelMax);
			auto l = new Label(comp, SWT.NONE);
			l.setText(.tryFormat(_prop.msgs.rangeHint, _lev.getMinimum(), _lev.getMaximum()));
		}

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) { mixin(S_TRACE);
			_ave[_evt.average ? 0 : 1].setSelection(true);
			_lev.setSelection(_evt.unsignedLevel);
		} else { mixin(S_TRACE);
			_ave[1].setSelection(true);
			_lev.setSelection(1);
		}
	}

	override bool apply() { mixin(S_TRACE);
		if (!_evt) _evt = new Content(CType.BRANCH_LEVEL, "");
		_evt.average = _ave[0].getSelection();
		_evt.unsignedLevel = _lev.getSelection();
		return true;
	}
}

Composite createStatusPane(Props prop, Composite area, string title, ref Button[Status] stat, void delegate(Button) mod, int type = SWT.RADIO) { mixin(S_TRACE);
	auto grp = new Group(area, SWT.NONE);
	grp.setText(title);
	grp.setLayout(normalGridLayout(4, true));
	auto statuses = [Status.ACTIVE, Status.INACTIVE, Status.ALIVE, Status.DEAD,
			Status.FINE, Status.INJURED, Status.HEAVY_INJURED, Status.UNCONSCIOUS,
			Status.POISON, Status.SLEEP, Status.BIND, Status.PARALYZE,
			Status.CONFUSE, Status.OVERHEAT, Status.BRAVE, Status.PANIC,
			Status.SILENCE, Status.FACE_UP, Status.ANTI_MAGIC,
			Status.UP_ACTION, Status.UP_AVOID, Status.UP_RESIST, Status.UP_DEFENSE,
			Status.DOWN_ACTION, Status.DOWN_AVOID, Status.DOWN_RESIST, Status.DOWN_DEFENSE];
	foreach (s; statuses) { mixin(S_TRACE);
		auto radio = new Button(grp, type);
		mod(radio);
		radio.setText(prop.msgs.statusName(s));
		radio.setLayoutData(new GridData(GridData.FILL_BOTH));
		stat[s] = radio;
	}
	return grp;
}
Composite createStatusHint(Props prop, Composite area) { mixin(S_TRACE);
	auto grp = new Group(area, SWT.NONE);
	grp.setText(prop.msgs.stateHint);
	grp.setLayout(new CenterLayout);
	auto comp = new Composite(grp, SWT.NONE);
	comp.setLayout(zeroMarginGridLayout(1, true));
	auto hint1 = new Label(comp, SWT.NONE);
	hint1.setText(prop.msgs.statusActive);
	auto hint2 = new Label(comp, SWT.NONE);
	hint2.setText(prop.msgs.statusInactive);
	auto hint3 = new Label(comp, SWT.NONE);
	hint3.setText(prop.msgs.statusAlive);
	auto hint4 = new Label(comp, SWT.NONE);
	hint4.setText(prop.msgs.statusDead);
	return grp;
}

/// 状態分岐の設定を行うダイアログ。
class BrStateDialog : EventDialog {
private:
	UseCounter _uc;
	RangePanel _range;
	Button[Status] _stat;
	Combo _invertResult;

	override
	protected void refreshWarning() { mixin(S_TRACE);
		string[] ws;
		if (!_prop.targetVersion(summ, "1.30")) { mixin(S_TRACE);
			auto status = getRadioValue!(Status)(_stat);
			if (Status.CONFUSE <= status) { mixin(S_TRACE);
				if (Status.SILENCE <= status) { mixin(S_TRACE);
					ws ~= .tryFormat(_prop.msgs.warningBranchStatusMental, _prop.msgs.statusName(status), "1.50");
				} else { mixin(S_TRACE);
					ws ~= .tryFormat(_prop.msgs.warningBranchStatusMental, _prop.msgs.statusName(status), "1.30");
				}
			}
		} else if (!_prop.targetVersion(summ, "1.50")) { mixin(S_TRACE);
			auto status = getRadioValue!(Status)(_stat);
			if (Status.SILENCE <= status) { mixin(S_TRACE);
				ws ~= .tryFormat(_prop.msgs.warningBranchStatusMental, _prop.msgs.statusName(status), "1.50");
			}
		}
		if(!prop.isTargetVersion(summ, "4") && _invertResult.getSelectionIndex() == 1) { mixin(S_TRACE);
			ws ~= prop.msgs.warningInvertResult;
		}
		warning = ws;
	}

	override
	protected void refDataVersion() { mixin(S_TRACE);
		updateEnabled();
		super.refDataVersion();
	}
	void updateEnabled() { mixin(S_TRACE);
		_invertResult.setEnabled(!summ || !summ.legacy || _invertResult.getSelectionIndex() != 0);
	}

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, UseCounter uc, Content parent, Content evt) { mixin(S_TRACE);
		super (comm, prop, shell, summ, CType.BRANCH_STATUS, parent, evt, false, null, true);
		_uc = uc;
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(2, false));
		{ mixin(S_TRACE);
			auto ranges = [Range.SELECTED, Range.RANDOM, Range.PARTY];
			auto title = _prop.msgs.judgeTarget;
			auto initCoupon = evt ? evt.holdingCoupon : "";
			_range = new RangePanel(comm, summ, _uc, area, ranges, initCoupon, title, false, this, evt, &catchMod, &refreshWarning, type);
			_range.setLayoutData(new GridData(GridData.FILL_BOTH));
		}
		{ mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setText(_prop.msgs.resultType);
			grp.setLayout(new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL));
			_invertResult = new Combo(grp, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
			mod(_invertResult);
			_invertResult.setVisibleItemCount(prop.var.etc.comboVisibleItemCount);
			_invertResult.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			_invertResult.add(_prop.msgs.resultTypeNormalForStatus);
			_invertResult.add(_prop.msgs.resultTypeInvertForStatus);
			.listener(_invertResult, SWT.Selection, &refDataVersion);
		}
		auto status = createStatusPane(prop, area, prop.msgs.judgeState, _stat, &mod!Button);
		auto gd = new GridData(GridData.FILL_BOTH);
		gd.horizontalSpan = 2;
		status.setLayoutData(gd);
		foreach (st, b; _stat) { mixin(S_TRACE);
			.listener(b, SWT.Selection, &refreshWarning);
		}
		auto hint = createStatusHint(prop, area);
		auto hgd = new GridData(GridData.FILL_BOTH);
		hgd.horizontalSpan = 2;
		hint.setLayoutData(hgd);

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) { mixin(S_TRACE);
			_stat[_evt.status].setSelection(true);
			_invertResult.select(_evt.invertResult ? 1 : 0);
		} else { mixin(S_TRACE);
			_stat[Status.ACTIVE].setSelection(true);
			_invertResult.select(0);
		}
		refDataVersion();
	}

	override bool apply() { mixin(S_TRACE);
		if (!_evt) _evt = new Content(CType.BRANCH_STATUS, "");
		_evt.range = _range.range;
		_evt.status = getRadioValue!(Status)(_stat);
		_evt.invertResult = _invertResult.getSelectionIndex() == 1;
		return true;
	}
}

/// カード取得・喪失・所持判定の設定を行うダイアログ。
private class CardEventDialog(CType Type, C : EffectCard, string Cards, bool Delete, Range RangeDef) : EventDialog {
private:
	Spinner _num;
	static if (Delete) {
		Button _allDel;
		class DelSListener : SelectionAdapter {
			override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
				updateEnabled();
			}
		}
	}
	Button[Range] _range;
	Table _list;
	static if (Type is CType.BRANCH_SKILL || Type is CType.BRANCH_ITEM || Type is CType.BRANCH_BEAST) {
		Button _selectCard;
		Combo _invertResult;
	}
	IncSearch _incSearch;
	void incSearch() { mixin(S_TRACE);
		.forceFocus(_list, true);
		_incSearch.startIncSearch();
	}

	override
	protected void refreshWarning() { mixin(S_TRACE);
		string[] ws;
		auto range = this.range;
		if (range !is Range.SELECTED_CARD && _selectedID == 0) { mixin(S_TRACE);
			static if (is(C:SkillCard)) {
				ws ~= prop.msgs.searchErrorNoSkill;
			} else static if (is(C:ItemCard)) {
				ws ~= prop.msgs.searchErrorNoItem;
			} else static if (is(C:BeastCard)) {
				ws ~= prop.msgs.searchErrorNoBeast;
			} else static assert (0);
		}
		static if (is(typeof(_selectCard))) {
			if (!_prop.isTargetVersion(summ, "3") && _selectCard.getSelection()) { mixin(S_TRACE);
				ws ~= _prop.msgs.warningSelectCard;
			}
		}
		if (!_prop.isTargetVersion(summ, "3") && range is Range.SELECTED_CARD) { mixin(S_TRACE);
			ws ~= .tryFormat(_prop.msgs.warningRangeSelectedCard);
		}
		static if (is(typeof(_invertResult))) {
			if(!prop.isTargetVersion(summ, "4") && _invertResult.getSelectionIndex() == 1) { mixin(S_TRACE);
				ws ~= prop.msgs.warningInvertResult;
			}
		}
		warning = ws;
	}
	override
	protected void refDataVersion() { mixin(S_TRACE);
		refreshWarning();
		updateEnabled();
		static if (Delete) {
			if (summ && summ.legacy && !_list.getItemCount()) { mixin(S_TRACE);
				forceCancel();
			}
		}
	}
	void updateEnabled() { mixin(S_TRACE);
		static if (Delete) {
			_allDel.setEnabled(range !is Range.SELECTED_CARD);
			_num.setEnabled(!_allDel.getSelection() && range !is Range.SELECTED_CARD);
			_list.setEnabled(range !is Range.SELECTED_CARD && mixin(Cards).length);
		} else {
			_num.setEnabled(range !is Range.SELECTED_CARD);
			_list.setEnabled(0 < mixin(Cards).length);
		}
		auto b = _range[Range.SELECTED_CARD];
		b.setEnabled(!summ || !summ.legacy || b.getSelection());
		static if (is(typeof(_selectCard))) {
			_selectCard.setEnabled(!b.getSelection() && (!summ || !summ.legacy || _selectCard.getSelection()));
		}
		static if (is(typeof(_invertResult))) {
			_invertResult.setEnabled(!summ || !summ.legacy || _invertResult.getSelectionIndex() != 0);
		}
	}

	ulong _selectedID = 0;
	void selected() { mixin(S_TRACE);
		auto index = _list.getSelectionIndex();
		if (-1 != index) { mixin(S_TRACE);
			_selectedID = (cast(C)_list.getItem(index).getData()).id;
		} else { mixin(S_TRACE);
			_selectedID = 0;
		}
	}

	void refreshList() { mixin(S_TRACE);
		if (!summ) return;
		ulong id = _selectedID;
		_list.removeAll();
		size_t i = 0;
		foreach (c; mixin(Cards)) { mixin(S_TRACE);
			if (!_incSearch.match(c.name)) continue;
			auto itm = new TableItem(_list, SWT.NONE);
			itm.setData(c);
			static if (is(C == SkillCard)) {
				itm.setImage(0, _prop.images.skill);
			} else static if (is(C == ItemCard)) {
				itm.setImage(0, _prop.images.item);
			} else static if (is(C == BeastCard)) {
				itm.setImage(0, _prop.images.beast);
			} else { mixin(S_TRACE);
				static assert (0);
			}
			itm.setText(0, to!(string)(c.id));
			itm.setText(1, c.name);
			if (id == c.id) _list.select(cast(int)i);
			i++;
		}
		updateEnabled();
		if (-1 == _list.getSelectionIndex()) { mixin(S_TRACE);
			if (_list.getItemCount() && _list.getEnabled()) { mixin(S_TRACE);
				_list.select(0);
				_selectedID = (cast(C)_list.getItem(0).getData()).id;
			} else { mixin(S_TRACE);
				_selectedID = 0;
			}
		}
		_list.showSelection();
	}
	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			static if (is(C == SkillCard)) {
				_comm.refSkill.remove(&refCard);
				_comm.delSkill.remove(&delCard);
			} else static if (is(C == ItemCard)) {
				_comm.refItem.remove(&refCard);
				_comm.delItem.remove(&delCard);
			} else static if (is(C == BeastCard)) {
				_comm.refBeast.remove(&refCard);
				_comm.delBeast.remove(&delCard);
			} else static assert (0);
		}
	}

	void refCard(C c) { mixin(S_TRACE);
		refreshList();
	}
	void delCard(CWXPath owner, C c) { mixin(S_TRACE);
		if (!summ) return;
		auto cards = mixin(Cards);
		if (cards.length) { mixin(S_TRACE);
			refreshList();
		} else { mixin(S_TRACE);
			static if (Type is CType.LOSE_SKILL || Type is CType.LOSE_ITEM || Type is CType.LOSE_BEAST) {
				if (summ && summ.legacy) { mixin(S_TRACE);
					forceCancel();
				}
			} else { mixin(S_TRACE);
				forceCancel();
			}
		}
	}

	void openView() { mixin(S_TRACE);
		auto i = _list.getSelectionIndex();
		if (-1 == i) return;
		auto a = cast(C) _list.getItem(i).getData();
		try { mixin(S_TRACE);
			_comm.openCWXPath(cpaddattr(a.cwxPath(true), "shallow"), false);
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
	}
	class OpenView : MouseAdapter {
		override void mouseDoubleClick(MouseEvent e) { mixin(S_TRACE);
			if (1 != e.button) return;
			openView();
		}
	}

	@property
	Range range() { return getRadioValue!(Range)(_range); }

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) { mixin(S_TRACE);
		super (comm, prop, shell, summ, Type, parent, evt, true, prop.var.cardEvtDlg, true);
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(2, false));
		{ mixin(S_TRACE);
			auto comp = new Composite(area, SWT.NONE);
			comp.setLayoutData(new GridData(GridData.FILL_VERTICAL));
			comp.setLayout(zeroMarginGridLayout(1, true));
			{ mixin(S_TRACE);
				auto grp = new Group(comp, SWT.NONE);
				grp.setText(_prop.msgs.cardNumber);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				auto cl = new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0);
				cl.fillHorizontal = true;
				grp.setLayout(cl);
				auto comp2 = new Composite(grp, SWT.NONE);
				comp2.setLayout(normalGridLayout(2, false));
				_num = new Spinner(comp2, SWT.BORDER);
				initSpinner(_num);
				mod(_num);
				_num.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				_num.setMinimum(1);
				_num.setMaximum(_prop.var.etc.cardNumberMax);
				auto l = new Label(comp2, SWT.NONE);
				l.setText(.tryFormat(_prop.msgs.rangeHint, _num.getMinimum(), _num.getMaximum()));
				static if (Delete) {
					_allDel = new Button(comp2, SWT.CHECK);
					mod(_allDel);
					_allDel.setText(_prop.msgs.cardAllDelete);
					auto gd = new GridData;
					gd.horizontalSpan = 2;
					_allDel.setLayoutData(gd);
					_allDel.addSelectionListener(new DelSListener);
				}
			}
			{ mixin(S_TRACE);
				auto grp = new Group(comp, SWT.NONE);
				grp.setText(_prop.msgs.cardEventRange);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setLayout(normalGridLayout(1, true));
				foreach (r; [Range.SELECTED, Range.RANDOM, Range.PARTY,
						Range.BACKPACK, Range.PARTY_AND_BACKPACK, Range.FIELD, 
						Range.SELECTED_CARD]) { mixin(S_TRACE);
					auto radio = new Button(grp, SWT.RADIO);
					mod(radio);
					if ((Type is CType.GET_SKILL || Type is CType.GET_ITEM || Type is CType.GET_BEAST) && r is Range.SELECTED_CARD) { mixin(S_TRACE);
						radio.setText(_prop.msgs.rangeNameSelectedCardForReplace);
					} else { mixin(S_TRACE);
						radio.setText(_prop.msgs.rangeName(r));
					}
					if (r is Range.FIELD) { mixin(S_TRACE);
						radio.setToolTipText(_prop.msgs.rangeDescField);
					}
					radio.setLayoutData(new GridData(GridData.FILL_BOTH));
					.listener(radio, SWT.Selection, &refDataVersion);
					_range[r] = radio;
				}
			}
			static if (is(typeof(_invertResult))) {
				{ mixin(S_TRACE);
					auto grp = new Group(comp, SWT.NONE);
					grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
					grp.setText(_prop.msgs.resultType);
					grp.setLayout(new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL));
					_invertResult = new Combo(grp, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
					mod(_invertResult);
					_invertResult.setVisibleItemCount(prop.var.etc.comboVisibleItemCount);
					_invertResult.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
					_invertResult.add(_prop.msgs.resultTypeNormal);
					_invertResult.add(_prop.msgs.resultTypeInvert);
					.listener(_invertResult, SWT.Selection, &refDataVersion);
				}
			}
		}
		{ mixin(S_TRACE);
			_list = .rangeSelectableTable(area, SWT.SINGLE | SWT.FULL_SELECTION | SWT.BORDER | SWT.V_SCROLL);
			mod(_list);
			_incSearch = new IncSearch(comm, _list, () => 0 < mixin(Cards).length);
			_incSearch.modEvent ~= &refreshList;
			auto idCol = new TableColumn(_list, SWT.NONE);
			saveColumnWidth!("prop.var.etc.idColumn")(_prop, idCol);
			auto nameCol = new FullTableColumn(_list, SWT.NONE);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.widthHint = _prop.var.etc.nameTableWidth;
			gd.heightHint = _prop.var.etc.nameTableHeight;
			_list.setLayoutData(gd);
			.listener(_list, SWT.Selection, &selected);

			_list.addMouseListener(new OpenView);
			auto menu = new Menu(_list.getShell(), SWT.POP_UP);
			createMenuItem(comm, menu, MenuID.IncSearch, &incSearch, () => 0 < mixin(Cards).length);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(comm, menu, MenuID.OpenAtCardView, &openView, () => _list.getSelectionIndex() != -1);
			_list.setMenu(menu);
		}
		if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
			static if (is(C == SkillCard)) {
				_comm.refSkill.add(&refCard);
				_comm.delSkill.add(&delCard);
			} else static if (is(C == ItemCard)) {
				_comm.refItem.add(&refCard);
				_comm.delItem.add(&delCard);
			} else static if (is(C == BeastCard)) {
				_comm.refBeast.add(&refCard);
				_comm.delBeast.add(&delCard);
			} else static assert (0);
			_list.addDisposeListener(new Dispose);
		}
		static if (is(typeof(_selectCard))) {
			_selectCard = new Button(area, SWT.CHECK);
			mod(_selectCard);
			_selectCard.setText(_prop.msgs.selectFoundCard);
			auto gd = new GridData(GridData.HORIZONTAL_ALIGN_END);
			gd.horizontalSpan = 2;
			_selectCard.setLayoutData(gd);
			.listener(_selectCard, SWT.Selection, { mixin(S_TRACE);
				refreshWarning();
				updateEnabled();
			});
		}

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) { mixin(S_TRACE);
			static if (is(C == SkillCard)) {
				_selectedID = _evt.skill;
			} else static if (is(C == ItemCard)) {
				_selectedID = _evt.item;
			} else static if (is(C == BeastCard)) {
				_selectedID = _evt.beast;
			} else { mixin(S_TRACE);
				static assert (0);
			}
			foreach (i, itm; _list.getItems()) { mixin(S_TRACE);
				if (_selectedID == (cast(C) itm.getData()).id) { mixin(S_TRACE);
					_list.select(cast(int)i);
					break;
				}
			}

			static if (Delete) {
				if (_evt.cardNumber == 0u) { mixin(S_TRACE);
					_allDel.setSelection(true);
					_num.setSelection(1);
					_num.setEnabled(false);
				} else { mixin(S_TRACE);
					_allDel.setSelection(false);
					_num.setSelection(_evt.cardNumber);
				}
			} else { mixin(S_TRACE);
				_num.setSelection(_evt.cardNumber);
			}
			_range[_evt.range].setSelection(true);
			static if (is(typeof(_selectCard))) {
				_selectCard.setSelection(_evt.selectCard);
			}
			static if (is(typeof(_invertResult))) {
				_invertResult.select(_evt.invertResult ? 1 : 0);
			}
		} else { mixin(S_TRACE);
			static if (Delete) {
				_allDel.setSelection(false);
			}
			_num.setSelection(1);
			_range[RangeDef].setSelection(true);
			static if (is(typeof(_selectCard))) {
				_selectCard.setSelection(false);
			}
			static if (is(typeof(_invertResult))) {
				_invertResult.select(0);
			}
		}
		refreshList();
		refDataVersion();
	}

	override bool apply() { mixin(S_TRACE);
		if (!_evt) _evt = new Content(Type, "");
		static if (is(C == SkillCard)) {
			_evt.skill = _selectedID;
		} else static if (is(C == ItemCard)) {
			_evt.item = _selectedID;
		} else static if (is(C == BeastCard)) {
			_evt.beast = _selectedID;
		} else { mixin(S_TRACE);
			static assert (0);
		}
		_evt.range = this.range;
		static if (Delete) {
			if (_allDel.getSelection()) { mixin(S_TRACE);
				_evt.cardNumber = 0u;
			} else { mixin(S_TRACE);
				_evt.cardNumber = _num.getSelection();
			}
		} else { mixin(S_TRACE);
			_evt.cardNumber = _num.getSelection();
		}
		static if (is(typeof(_selectCard))) {
			_evt.selectCard = _selectCard.getSelection();
		}
		static if (is(typeof(_invertResult))) {
			_evt.invertResult = _invertResult.getSelectionIndex() == 1;
		}
		return true;
	}
}

alias CardEventDialog!(CType.BRANCH_SKILL, SkillCard, "_summ.skills", false, Range.FIELD) BrSkillDialog;
alias CardEventDialog!(CType.BRANCH_ITEM, ItemCard, "_summ.items", false, Range.FIELD) BrItemDialog;
alias CardEventDialog!(CType.BRANCH_BEAST, BeastCard, "_summ.beasts", false, Range.FIELD) BrBeastDialog;
alias CardEventDialog!(CType.GET_SKILL, SkillCard, "_summ.skills", false, Range.SELECTED) GetSkillDialog;
alias CardEventDialog!(CType.GET_ITEM, ItemCard, "_summ.items", false, Range.SELECTED) GetItemDialog;
alias CardEventDialog!(CType.GET_BEAST, BeastCard, "_summ.beasts", false, Range.SELECTED) GetBeastDialog;
alias CardEventDialog!(CType.LOSE_SKILL, SkillCard, "_summ.skills", true, Range.FIELD) LostSkillDialog;
alias CardEventDialog!(CType.LOSE_ITEM, ItemCard, "_summ.items", true, Range.FIELD) LostItemDialog;
alias CardEventDialog!(CType.LOSE_BEAST, BeastCard, "_summ.beasts", true, Range.FIELD) LostBeastDialog;

/// パーティ表示・隠蔽イベントの設定を行うダイアログ。
class ShowHidePartyDialog : EventDialog {
private:
	CardAnimationPanel _cardSpeed;

	override
	protected void refreshWarning() { mixin(S_TRACE);
		string[] ws;
		ws ~= _cardSpeed.warnings;
		warning = ws;
	}

public:
	this (CType type, Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) { mixin(S_TRACE);
		super (comm, prop, shell, summ, type, parent, evt, false, null, true);
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(1, false));
		{ mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setText(prop.msgs.cardSpeed);
			grp.setLayout(new CenterLayout);
			_cardSpeed = new CardAnimationPanel(comm, summ, grp, CardAnimationPanelType.MenuCard);
			mod(_cardSpeed);
			_cardSpeed.modEvent ~= &refreshWarning;
		}

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) { mixin(S_TRACE);
			_cardSpeed.speed = _evt.cardSpeed;
		} else { mixin(S_TRACE);
			_cardSpeed.speed = -1;
		}
		refreshWarning();
	}

	override bool apply() { mixin(S_TRACE);
		if (!_evt) _evt = new Content(type, "");
		_evt.cardSpeed = _cardSpeed.speed;
		return true;
	}
}

/// 画面再構築イベントの設定を行うダイアログ。
class RefreshDialog : EventDialog {
private:
	TransitionPanel _transition;

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) { mixin(S_TRACE);
		super (comm, prop, shell, summ, CType.REDISPLAY, parent, evt, false, null, true);
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(1, false));
		{ mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			grp.setText(_prop.msgs.transitionType);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(new CenterLayout);

			_transition = new TransitionPanel(comm, summ, grp, false, _evt, this);
		}
	}

	override bool apply() { mixin(S_TRACE);
		if (!_evt) _evt = new Content(CType.REDISPLAY, "");
		_evt.transition = _transition.transition;
		_evt.transitionSpeed = _transition.transitionSpeed;
		return true;
	}
}

/// ランダム選択分岐の設定を行うダイアログ。
class BrRandomSelectDialog : EventDialog {
private:
	Button[CastRange] _castRange;
	Button _hasLevel, _hasStatus;
	Spinner _levMin, _levMax;
	Button[Status] _status;
	Combo _invertResult;

	override
	protected void refreshWarning() { mixin(S_TRACE);
		string[] ws;
		if (!_prop.targetVersion(summ, "1.30")) { mixin(S_TRACE);
			ws ~= .tryFormat(_prop.msgs.warningUnknownContent, _prop.msgs.contentName(CType.BRANCH_RANDOM_SELECT), "1.30");
		} else if (!_prop.targetVersion(summ, "1.50")) { mixin(S_TRACE);
			auto status = getRadioValue!(Status)(_status);
			if (Status.SILENCE <= status) { mixin(S_TRACE);
				ws ~= .tryFormat(_prop.msgs.warningBranchStatusMental, _prop.msgs.statusName(status), "1.50");
			}
		}
		if(!prop.isTargetVersion(summ, "4") && _invertResult.getSelectionIndex() == 1) { mixin(S_TRACE);
			ws ~= prop.msgs.warningInvertResult;
		}
		warning = ws;
	}

	void levMaxEnter(int enter) { mixin(S_TRACE);
		if (enter > 0 && _levMin.getSelection() != 0 && enter < _levMin.getSelection()) { mixin(S_TRACE);
			_levMin.setSelection(enter);
		}
	}
	void levMinEnter(int enter) { mixin(S_TRACE);
		if (enter > 0 && _levMax.getSelection() != 0 && enter > _levMax.getSelection()) { mixin(S_TRACE);
			_levMax.setSelection(enter);
		}
	}

	override
	protected void refDataVersion() { mixin(S_TRACE);
		updateEnabled();
		super.refDataVersion();
	}
	void updateEnabled() { mixin(S_TRACE);
		_levMin.setEnabled(_hasLevel.getSelection());
		_levMax.setEnabled(_hasLevel.getSelection());
		foreach (key, b; _status) { mixin(S_TRACE);
			b.setEnabled(_hasStatus.getSelection());
		}
		_invertResult.setEnabled((!summ || !summ.legacy || _invertResult.getSelectionIndex() != 0) && (_hasLevel.getSelection() || _hasStatus.getSelection()));
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) { mixin(S_TRACE);
		super (comm, prop, shell, summ, CType.BRANCH_RANDOM_SELECT, parent, evt, false, null, true);
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(2, false));
		{ mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			grp.setText(_prop.msgs.selectMember);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(normalGridLayout(3, true));
			foreach (r; EnumMembers!CastRange) { mixin(S_TRACE);
				auto radio = new Button(grp, SWT.CHECK);
				mod(radio);
				radio.setText(prop.msgs.castRangeName(r));
				radio.setLayoutData(new GridData(GridData.FILL_BOTH));
				_castRange[r] = radio;
			}

			auto sep = new Label(grp, SWT.SEPARATOR | SWT.HORIZONTAL);
			auto sgd = new GridData(GridData.FILL_HORIZONTAL);
			sgd.horizontalSpan = 3;
			sep.setLayoutData(sgd);

			_hasLevel = new Button(grp, SWT.CHECK);
			mod(_hasLevel);
			_hasLevel.setText(prop.msgs.randomSelectHasLevel);
			_hasLevel.setLayoutData(new GridData(GridData.FILL_BOTH));
			.listener(_hasLevel, SWT.Selection, &updateEnabled);

			_hasStatus = new Button(grp, SWT.CHECK);
			mod(_hasStatus);
			_hasStatus.setText(prop.msgs.randomSelectHasStatus);
			_hasStatus.setLayoutData(new GridData(GridData.FILL_BOTH));
			.listener(_hasStatus, SWT.Selection, &updateEnabled);
		}
		{ mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setText(_prop.msgs.resultType);
			grp.setLayout(new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL));
			_invertResult = new Combo(grp, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
			mod(_invertResult);
			_invertResult.setVisibleItemCount(prop.var.etc.comboVisibleItemCount);
			_invertResult.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			_invertResult.add(_prop.msgs.resultTypeNormalForCondition);
			_invertResult.add(_prop.msgs.resultTypeInvertForCondition);
			.listener(_invertResult, SWT.Selection, &refDataVersion);
		}
		{ mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			grp.setText(_prop.msgs.targetLevel);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.horizontalSpan = 2;
			grp.setLayoutData(gd);
			grp.setLayout(new CenterLayout);
			auto comp = new Composite(grp, SWT.NONE);
			comp.setLayout(zeroMarginGridLayout(4, false));

			_levMin = new Spinner(comp, SWT.BORDER);
			initSpinner(_levMin);
			mod(_levMin);
			_levMin.setMinimum(1);
			_levMin.setMaximum(_prop.var.etc.castLevelMax);
			new SpinnerEdit(_levMin, &levMinEnter);
			auto lbl = new Label(comp, SWT.NONE);
			lbl.setText(_prop.msgs.levSep);
			_levMax = new Spinner(comp, SWT.BORDER);
			initSpinner(_levMax);
			mod(_levMax);
			_levMax.setMinimum(1);
			_levMax.setMaximum(_prop.var.etc.castLevelMax);
			new SpinnerEdit(_levMax, &levMaxEnter);
			auto lHint = new Label(comp, SWT.NONE);
			lHint.setText(.tryFormat(_prop.msgs.rangeHint, 1, _prop.var.etc.castLevelMax));
		}
		auto status = createStatusPane(prop, area, prop.msgs.judgeState, _status, &mod!Button);
		auto sgd = new GridData(GridData.FILL_BOTH);
		sgd.horizontalSpan = 2;
		status.setLayoutData(sgd);
		auto hint = createStatusHint(prop, area);
		auto hgd = new GridData(GridData.FILL_BOTH);
		hgd.horizontalSpan = 2;
		hint.setLayoutData(hgd);

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) { mixin(S_TRACE);
			foreach (e; _evt.castRange) { mixin(S_TRACE);
				_castRange[e].setSelection(true);
			}
			_hasLevel.setSelection(0 < _evt.levelMax);
			_hasStatus.setSelection(Status.NONE !is _evt.status);
			if (_hasLevel.getSelection()) { mixin(S_TRACE);
				_levMin.setSelection(_evt.levelMin);
				_levMax.setSelection(_evt.levelMax);
			} else { mixin(S_TRACE);
				_levMin.setSelection(1);
				_levMax.setSelection(1);
			}
			if (_hasStatus.getSelection()) { mixin(S_TRACE);
				_status[_evt.status].setSelection(true);
			} else { mixin(S_TRACE);
				_status[Status.ACTIVE].setSelection(true);
			}
			_invertResult.select(_evt.invertResult ? 1 : 0);
		} else { mixin(S_TRACE);
			_castRange[CastRange.PARTY].setSelection(true);
			_hasLevel.setSelection(false);
			_hasStatus.setSelection(false);
			_levMin.setSelection(1);
			_levMax.setSelection(1);
			_status[Status.ACTIVE].setSelection(true);
			_invertResult.select(0);
		}
		refDataVersion();
	}

	override bool apply() { mixin(S_TRACE);
		if (!_evt) _evt = new Content(CType.BRANCH_RANDOM_SELECT, "");
		CastRange[] range;
		foreach (e, b; _castRange) { mixin(S_TRACE);
			if (b.getSelection()) range ~= e;
		}
		_evt.castRange = range;
		bool hasLevel = _hasLevel.getSelection();
		bool hasStatus = _hasStatus.getSelection();
		if (hasLevel) { mixin(S_TRACE);
			_evt.levelMin = _levMin.getSelection();
			_evt.levelMax = _levMax.getSelection();
		} else { mixin(S_TRACE);
			_evt.levelMin = 0;
			_evt.levelMax = 0;
		}
		if (hasStatus) { mixin(S_TRACE);
			_evt.status = getRadioValue!(Status)(_status);
		} else { mixin(S_TRACE);
			_evt.status = Status.NONE;
		}
		_evt.invertResult = _invertResult.getSelectionIndex() == 1;
		return true;
	}
}

/// キーコード所持判定の設定を行うダイアログ。
class BrKeyCodeDialog : EventDialog {
private:
	Button[Range] _keyCodeRange;
	Button[EffectCardType] _effectCardTypeWsn1 = null;
	Button[EffectCardType] _effectCardTypeWsn2 = null;
	Composite _typeComp;
	Combo _invertResult;
	Combo _keyCode;
	Button _selectCard;

	override
	protected void refreshWarning() { mixin(S_TRACE);
		string[] ws;
		ws ~= .sjisWarnings(prop.parent, summ, _keyCode.getText(), prop.msgs.keyCode);
		if (_effectCardTypeWsn1.length) { mixin(S_TRACE);
			if (!_prop.targetVersion(summ, "1.50")) { mixin(S_TRACE);
				ws ~= .tryFormat(_prop.msgs.warningUnknownContent, _prop.msgs.contentName(CType.BRANCH_KEY_CODE), "1.50");
			}
			if (summ && summ.legacy && (_effectCardTypeWsn1[EffectCardType.ALL].getSelection() || _effectCardTypeWsn1[EffectCardType.ITEM].getSelection())) { mixin(S_TRACE);
				ws ~= _prop.msgs.warningBranchKeyCodeWithItem;
			}
		} else { mixin(S_TRACE);
			assert (_effectCardTypeWsn2.length);
			auto skill = _effectCardTypeWsn2[EffectCardType.SKILL].getSelection();
			auto item = _effectCardTypeWsn2[EffectCardType.ITEM].getSelection();
			auto beast = _effectCardTypeWsn2[EffectCardType.BEAST].getSelection();
			auto hand = _effectCardTypeWsn2[EffectCardType.HAND].getSelection();
			if (!_prop.isTargetVersion(summ, "2")
					&& !(skill && item && beast && !hand)
					&& !(skill && !item && !beast && !hand)
					&& !(!skill && item && !beast && !hand)
					&& !(!skill && !item && beast && !hand)) { mixin(S_TRACE);
				ws ~= _prop.msgs.warningBranchKeyCodeAtWsn1;
			}
			if (!_prop.isTargetVersion(summ, "3") && _selectCard.getSelection()) { mixin(S_TRACE);
				ws ~= _prop.msgs.warningSelectCard;
			}
		}
		if (!_prop.isTargetVersion(summ, "3") && range is Range.SELECTED_CARD) { mixin(S_TRACE);
			ws ~= .tryFormat(_prop.msgs.warningRangeSelectedCard);
		}
		if(!prop.isTargetVersion(summ, "4") && _invertResult.getSelectionIndex() == 1) { mixin(S_TRACE);
			ws ~= prop.msgs.warningInvertResult;
		}
		warning = ws;
	}

	override
	protected void refDataVersion() { mixin(S_TRACE);
		if (summ && summ.legacy && _effectCardTypeWsn2.length) { mixin(S_TRACE);
			auto skill = _effectCardTypeWsn2[EffectCardType.SKILL].getSelection();
			auto item = _effectCardTypeWsn2[EffectCardType.ITEM].getSelection();
			auto beast = _effectCardTypeWsn2[EffectCardType.BEAST].getSelection();
			auto hand = _effectCardTypeWsn2[EffectCardType.HAND].getSelection();
			foreach (radio; _effectCardTypeWsn2.byValue()) radio.dispose();
			_effectCardTypeWsn2 = null;
			createWsn1Panel();

			if (skill && item && beast && hand) { mixin(S_TRACE);
				_effectCardTypeWsn1[EffectCardType.ALL].setSelection(true);
			} else if (skill && !item && !beast && !hand) { mixin(S_TRACE);
				_effectCardTypeWsn1[EffectCardType.SKILL].setSelection(true);
			} else if (!skill && item && !beast && hand) { mixin(S_TRACE);
				_effectCardTypeWsn1[EffectCardType.ITEM].setSelection(true);
			} else if (!skill && item && !beast && !hand) { mixin(S_TRACE);
				_effectCardTypeWsn1[EffectCardType.ITEM].setSelection(true);
				applyEnabled(true);
			} else if (!skill && !item && beast && !hand) { mixin(S_TRACE);
				_effectCardTypeWsn1[EffectCardType.BEAST].setSelection(true);
			} else { mixin(S_TRACE);
				_effectCardTypeWsn1[EffectCardType.ALL].setSelection(true);
				applyEnabled(true);
			}
			getShell().layout(true, true);
			getShell().pack();
		} else if ((!summ || !summ.legacy) && _effectCardTypeWsn1.length) { mixin(S_TRACE);
			auto v = getRadioValue!(EffectCardType)(_effectCardTypeWsn1);
			foreach (radio; _effectCardTypeWsn1.byValue()) radio.dispose();
			_effectCardTypeWsn1 = null;
			createWsn2Panel();
			final switch (v) {
			case EffectCardType.ALL:
				_effectCardTypeWsn2[EffectCardType.SKILL].setSelection(true);
				_effectCardTypeWsn2[EffectCardType.ITEM].setSelection(true);
				_effectCardTypeWsn2[EffectCardType.BEAST].setSelection(true);
				_effectCardTypeWsn2[EffectCardType.HAND].setSelection(true);
				break;
			case EffectCardType.SKILL:
				_effectCardTypeWsn2[EffectCardType.SKILL].setSelection(true);
				break;
			case EffectCardType.ITEM:
				_effectCardTypeWsn2[EffectCardType.ITEM].setSelection(true);
				_effectCardTypeWsn2[EffectCardType.HAND].setSelection(true);
				break;
			case EffectCardType.BEAST:
				_effectCardTypeWsn2[EffectCardType.BEAST].setSelection(true);
				break;
			case EffectCardType.HAND:
				assert (0);
			}
			getShell().layout(true, true);
			getShell().pack();
		}

		updateEnabled();

		super.refDataVersion();
	}

	private void updateEnabled() { mixin(S_TRACE);
		auto b = _keyCodeRange[Range.SELECTED_CARD];
		b.setEnabled(!summ || !summ.legacy || b.getSelection());
		_invertResult.setEnabled(!summ || !summ.legacy || _invertResult.getSelectionIndex() != 0);
		_selectCard.setEnabled(!b.getSelection() && (!summ || !summ.legacy || _selectCard.getSelection()) && _invertResult.getSelectionIndex() == 0);
	}

	void createWsn1Panel() { mixin(S_TRACE);
		foreach (r; [EffectCardType.ALL, EffectCardType.SKILL, EffectCardType.ITEM, EffectCardType.BEAST]) { mixin(S_TRACE);
			auto radio = new Button(_typeComp, SWT.RADIO);
			mod(radio);
			radio.setText(_prop.msgs.effectCardTypeName(r));
			radio.setLayoutData(new GridData(GridData.FILL_BOTH));
			.listener(radio, SWT.Selection, &refreshWarning);
			_effectCardTypeWsn1[r] = radio;
		}
	}
	void createWsn2Panel() { mixin(S_TRACE);
		foreach (r; [EffectCardType.SKILL, EffectCardType.ITEM, EffectCardType.BEAST, EffectCardType.HAND]) { mixin(S_TRACE);
			auto check = new Button(_typeComp, SWT.CHECK);
			mod(check);
			check.setText(_prop.msgs.effectCardTypeName(r));
			check.setLayoutData(new GridData(GridData.FILL_BOTH));
			.listener(check, SWT.Selection, &refreshWarning);
			_effectCardTypeWsn2[r] = check;
		}
	}

	@property
	Range range() { return getRadioValue!(Range)(_keyCodeRange); }

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) { mixin(S_TRACE);
		super (comm, prop, shell, summ, CType.BRANCH_KEY_CODE, parent, evt, false, null, true);
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(2, false));
		{ mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			grp.setText(_prop.msgs.range);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.verticalSpan = 2;
			grp.setLayoutData(gd);
			grp.setLayout(new CenterLayout(SWT.HORIZONTAL));
			auto comp = new Composite(grp, SWT.NONE);
			comp.setLayout(zeroMarginGridLayout(1, true));
			foreach (r; [Range.SELECTED, Range.RANDOM, Range.BACKPACK,
					Range.PARTY_AND_BACKPACK, Range.SELECTED_CARD]) { mixin(S_TRACE);
				auto radio = new Button(comp, SWT.RADIO);
				mod(radio);
				radio.setText(_prop.msgs.rangeName(r));
				radio.setLayoutData(new GridData(GridData.FILL_BOTH));
				.listener(radio, SWT.Selection, { mixin(S_TRACE);
					refreshWarning();
					updateEnabled();
				});
				_keyCodeRange[r] = radio;
			}
		}
		{ mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			grp.setText(_prop.msgs.cardType);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(new CenterLayout(SWT.HORIZONTAL));
			_typeComp = new Composite(grp, SWT.NONE);
			_typeComp.setLayout(zeroMarginGridLayout(1, true));
			if (summ && summ.legacy) { mixin(S_TRACE);
				createWsn1Panel();
			} else { mixin(S_TRACE);
				createWsn2Panel();
			}
		}
		{ mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			grp.setText(_prop.msgs.resultType);
			grp.setLayout(new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL));
			_invertResult = new Combo(grp, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
			mod(_invertResult);
			_invertResult.setVisibleItemCount(prop.var.etc.comboVisibleItemCount);
			_invertResult.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			_invertResult.add(_prop.msgs.resultTypeNormal);
			_invertResult.add(_prop.msgs.resultTypeInvert);
			.listener(_invertResult, SWT.Selection, &refDataVersion);
		}
		{ mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			grp.setText(_prop.msgs.keyCode);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.horizontalSpan = 2;
			grp.setLayoutData(gd);
			grp.setLayout(normalGridLayout(1, true));

			_keyCode = createKeyCodeCombo(comm, summ, grp, &catchMod, _evt ? _evt.keyCode : "");
			mod(_keyCode);
			auto kgd = new GridData(GridData.FILL_HORIZONTAL);
			kgd.widthHint = _prop.var.etc.nameWidth;
			_keyCode.setLayoutData(kgd);
			.listener(_keyCode, SWT.Modify, &refreshWarning);
		}
		{ mixin(S_TRACE);
			_selectCard = new Button(area, SWT.CHECK);
			mod(_selectCard);
			_selectCard.setText(_prop.msgs.selectFoundCard);
			auto gd = new GridData(GridData.HORIZONTAL_ALIGN_END);
			gd.horizontalSpan = 2;
			_selectCard.setLayoutData(gd);
			.listener(_selectCard, SWT.Selection, { mixin(S_TRACE);
				refreshWarning();
				updateEnabled();
			});
		}

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) { mixin(S_TRACE);
			_keyCodeRange[_evt.keyCodeRange].setSelection(true);
			if (_effectCardTypeWsn1.length) { mixin(S_TRACE);
				if (_evt.targetIsSkill && _evt.targetIsItem && _evt.targetIsBeast) { mixin(S_TRACE);
					_effectCardTypeWsn1[EffectCardType.ALL].setSelection(true);
				} else if (_evt.targetIsSkill) { mixin(S_TRACE);
					_effectCardTypeWsn1[EffectCardType.SKILL].setSelection(true);
				} else if (_evt.targetIsItem) { mixin(S_TRACE);
					_effectCardTypeWsn1[EffectCardType.ITEM].setSelection(true);
				} else if (_evt.targetIsBeast) { mixin(S_TRACE);
					_effectCardTypeWsn1[EffectCardType.BEAST].setSelection(true);
				} else { mixin(S_TRACE);
					_effectCardTypeWsn1[EffectCardType.ALL].setSelection(true);
				}
			} else { mixin(S_TRACE);
				assert (_effectCardTypeWsn2.length);
				_effectCardTypeWsn2[EffectCardType.SKILL].setSelection(_evt.targetIsSkill);
				_effectCardTypeWsn2[EffectCardType.ITEM].setSelection(_evt.targetIsItem);
				_effectCardTypeWsn2[EffectCardType.BEAST].setSelection(_evt.targetIsBeast);
				_effectCardTypeWsn2[EffectCardType.HAND].setSelection(_evt.targetIsHand);
			}
			_invertResult.select(_evt.invertResult ? 1 : 0);
			_keyCode.setText(_evt.keyCode);
			_selectCard.setSelection(_evt.selectCard);
		} else { mixin(S_TRACE);
			_keyCodeRange[Range.SELECTED].setSelection(true);
			if (_effectCardTypeWsn1.length) { mixin(S_TRACE);
				_effectCardTypeWsn1[EffectCardType.ALL].setSelection(true);
			} else { mixin(S_TRACE);
				assert (_effectCardTypeWsn2.length);
				_effectCardTypeWsn2[EffectCardType.SKILL].setSelection(true);
				_effectCardTypeWsn2[EffectCardType.ITEM].setSelection(true);
				_effectCardTypeWsn2[EffectCardType.BEAST].setSelection(true);
				_effectCardTypeWsn2[EffectCardType.HAND].setSelection(false);
			}
			_invertResult.select(0);
			_keyCode.setText("");
			_selectCard.setSelection(false);
		}
		refreshWarning();
		updateEnabled();
	}

	override bool apply() { mixin(S_TRACE);
		if (!_evt) _evt = new Content(CType.BRANCH_KEY_CODE, "");

		_evt.keyCode = _keyCode.getText();
		_evt.keyCodeRange = this.range;
		_evt.targetIsSkill = false;
		_evt.targetIsItem = false;
		_evt.targetIsBeast = false;
		_evt.targetIsHand = false;
		if (_effectCardTypeWsn1.length) { mixin(S_TRACE);
			final switch (getRadioValue!(EffectCardType)(_effectCardTypeWsn1)) {
			case EffectCardType.ALL:
				_evt.targetIsSkill = true;
				_evt.targetIsItem = true;
				_evt.targetIsBeast = true;
				if (summ && summ.legacy) _evt.targetIsHand = true;
				break;
			case EffectCardType.SKILL:
				_evt.targetIsSkill = true;
				break;
			case EffectCardType.ITEM:
				_evt.targetIsItem = true;
				if (summ && summ.legacy) _evt.targetIsHand = true;
				break;
			case EffectCardType.BEAST:
				_evt.targetIsBeast = true;
				break;
			case EffectCardType.HAND:
				_evt.targetIsHand = true;
				break;
			}
		} else { mixin(S_TRACE);
			assert (_effectCardTypeWsn2.length);
			_evt.targetIsSkill = _effectCardTypeWsn2[EffectCardType.SKILL].getSelection();
			_evt.targetIsItem = _effectCardTypeWsn2[EffectCardType.ITEM].getSelection();
			_evt.targetIsBeast = _effectCardTypeWsn2[EffectCardType.BEAST].getSelection();
			_evt.targetIsHand = _effectCardTypeWsn2[EffectCardType.HAND].getSelection();
		}
		_evt.invertResult = _invertResult.getSelectionIndex() == 1;
		_evt.selectCard = _selectCard.getSelection();

		if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
			_comm.refKeyCodes.call();
		}
		return true;
	}
}

/// ラウンド分岐の設定を行うダイアログ。
class BranchRoundDialog : EventDialog {
private:
	override
	protected void refreshWarning() { mixin(S_TRACE);
		string[] ws;
		if (!_prop.targetVersion(summ, "1.50")) { mixin(S_TRACE);
			ws ~= .tryFormat(_prop.msgs.warningUnknownContent, _prop.msgs.contentName(CType.BRANCH_ROUND), "1.50");
		}
		warning = ws;
	}

	Spinner _value;
	Combo _cmp;
	Comparison3[] _cmps;

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) { mixin(S_TRACE);
		super (comm, prop, shell, summ, CType.BRANCH_ROUND, parent, evt, false, null, true);
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(1, false));
		{ mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setText(prop.msgs.roundCondition);
			grp.setLayout(new CenterLayout(SWT.VERTICAL | SWT.HORIZONTAL, 0));
			auto comp = new Composite(grp, SWT.NONE);
			comp.setLayout(normalGridLayout(4, false));

			auto l1 = new Label(comp, SWT.NONE);
			l1.setText(_prop.msgs.roundIs);

			_value = new Spinner(comp, SWT.BORDER);
			initSpinner(_value);
			mod(_value);
			_value.setMinimum(0);
			_value.setMaximum(_prop.var.etc.roundMax);

			auto l2 = new Label(comp, SWT.NONE);
			l2.setText(_prop.msgs.roundCmpIs);

			_cmp = new Combo(comp, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
			mod(_cmp);
			_cmp.setVisibleItemCount(prop.var.etc.comboVisibleItemCount);
			foreach (cmp; EnumMembers!Comparison3) { mixin(S_TRACE);
				_cmp.add(prop.msgs.comparison3Name(cmp));
				_cmps ~= cmp;
			}
		}

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) { mixin(S_TRACE);
			_value.setSelection(_evt.round);
			_cmp.select(cast(int)_cmps.countUntil(_evt.comparison3));
		} else { mixin(S_TRACE);
			_value.setSelection(0);
			_cmp.select(0);
		}
		refreshWarning();
	}

	override bool apply() { mixin(S_TRACE);
		if (!_evt) _evt = new Content(CType.BRANCH_ROUND, "");
		_evt.round = _value.getSelection();
		_evt.comparison3 = _cmps[_cmp.getSelectionIndex()];
		return true;
	}
}

private void createPositionOrSizePanel(Props prop, AbsDialog dlg, Composite area, GridData gd, string name, ref Button[CoordinateType] type, ref Spinner x, ref Spinner y, ref void delegate() updateEnabled, int max1, int max2, bool verticalLayout) { mixin(S_TRACE);
	auto grp = new Group(area, SWT.NONE);
	grp.setLayoutData(gd);
	grp.setText(name);
	grp.setLayout(new CenterLayout(SWT.VERTICAL | SWT.HORIZONTAL, 0));

	auto comp = new Composite(grp, SWT.NONE);
	comp.setLayout(normalGridLayout(verticalLayout ? 2 : 4, false));

	updateEnabled = { mixin(S_TRACE);
		auto p = !type[CoordinateType.None].getSelection();
		x.setEnabled(p);
		y.setEnabled(p);
	};
	void putRadio(CoordinateType ct) { mixin(S_TRACE);
		auto radio = new Button(comp, SWT.RADIO);
		dlg.mod(radio);
		radio.setText(prop.msgs.coordinateTypeName(ct));
		.listener(radio, SWT.Selection, updateEnabled);
		auto gd = new GridData;
		gd.horizontalSpan = verticalLayout ? 2 : 4;
		radio.setLayoutData(gd);
		type[ct] = radio;
	}
	foreach (ct; EnumMembers!CoordinateType) { mixin(S_TRACE);
		putRadio(ct);
	}

	Spinner putSpinner(string name, int max) { mixin(S_TRACE);
		auto l1 = new Label(comp, SWT.NONE);
		l1.setText(name);
		auto spn = new Spinner(comp, SWT.BORDER);
		initSpinner(spn);
		dlg.mod(spn);
		spn.setMinimum(-max);
		spn.setMaximum(max);
		return spn;
	}
	x = putSpinner(prop.msgs.horizontalValue, max1);
	y = putSpinner(prop.msgs.verticalValue, max2);
}

/// 背景再配置の設定を行うダイアログ(Wsn.2)。
class MoveBgImageDialog : EventDialog {
private:
	Combo _cellName;
	Button[CoordinateType] _positionType;
	Spinner _x;
	Spinner _y;
	Button[CoordinateType] _sizeType;
	Spinner _w;
	Spinner _h;

	TransitionPanel _transition;

	Button _doAnime;
	Button _ignoreEffectBooster;

	override
	protected void refreshWarning() { mixin(S_TRACE);
		string[] ws;
		ws ~= .sjisWarnings(prop.parent, summ, _cellName.getText(), prop.msgs.cellName);
		if (!_prop.isTargetVersion(summ, "1")) { mixin(S_TRACE);
			ws ~= .tryFormat(_prop.msgs.warningUnknownContentWsn, _prop.msgs.contentName(CType.MOVE_BG_IMAGE), "1");
		}
		warning = ws;
	}

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) { mixin(S_TRACE);
		super (comm, prop, shell, summ, CType.MOVE_BG_IMAGE, parent, evt, false, null, true);
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(2, true));

		{ mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			auto ggd = new GridData(GridData.FILL_HORIZONTAL);
			ggd.horizontalSpan = 2;
			grp.setLayoutData(ggd);
			grp.setLayout(normalGridLayout(1, true));
			grp.setText(prop.msgs.cellName);

			_cellName = createCellNameCombo(comm, summ, grp, &catchMod, _evt ? _evt.cellName : "");
			mod(_cellName);
			_cellName.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			.listener(_cellName, SWT.Modify, &refreshWarning);
		}

		void delegate() updateEnabledPosition;
		void delegate() updateEnabledSize;
		createPositionOrSizePanel(prop, this, area, new GridData(GridData.FILL_BOTH),
			prop.msgs.moveCell, _positionType, _x, _y,
			updateEnabledPosition, prop.var.etc.posLeftMax, prop.var.etc.posTopMax, false);
		createPositionOrSizePanel(prop, this, area, new GridData(GridData.FILL_BOTH),
			prop.msgs.resizeCell, _sizeType, _w, _h,
			updateEnabledSize, prop.var.etc.backWidthMax, prop.var.etc.backHeightMax, false);

		{ mixin(S_TRACE);
			_transition = new TransitionPanel(comm, summ, area, true, _evt, this);
			auto gd = new GridData(GridData.HORIZONTAL_ALIGN_END);
			gd.horizontalSpan = 2;
			_transition.setLayoutData(gd);
		}

		{ mixin(S_TRACE);
			auto comp = new Composite(area, SWT.NONE);
			comp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			comp.setLayout(zeroMarginGridLayout(1, false));
			_doAnime = new Button(comp, SWT.CHECK);
			_doAnime.setText(prop.msgs.doAnime);
			mod(_doAnime);
			_ignoreEffectBooster = new Button(comp, SWT.CHECK);
			_ignoreEffectBooster.setText(prop.msgs.ignoreEffectBooster);
			mod(_ignoreEffectBooster);
			auto gd = new GridData(GridData.HORIZONTAL_ALIGN_END);
			gd.horizontalSpan = 2;
			comp.setLayoutData(gd);
		}

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) { mixin(S_TRACE);
			_cellName.setText(_evt.cellName);
			_positionType[_evt.positionType].setSelection(true);
			_x.setSelection(_evt.x);
			_y.setSelection(_evt.y);
			_sizeType[_evt.sizeType].setSelection(true);
			_w.setSelection(_evt.width);
			_h.setSelection(_evt.height);
			_doAnime.setSelection(_evt.doAnime);
			_ignoreEffectBooster.setSelection(_evt.ignoreEffectBooster);
		} else { mixin(S_TRACE);
			_cellName.setText("");
			_positionType[CoordinateType.None].setSelection(true);
			_x.setSelection(0);
			_y.setSelection(0);
			_sizeType[CoordinateType.None].setSelection(true);
			_w.setSelection(0);
			_h.setSelection(0);
			_doAnime.setSelection(true);
			_ignoreEffectBooster.setSelection(false);
		}
		updateEnabledPosition();
		updateEnabledSize();
		refreshWarning();
	}

	override bool apply() { mixin(S_TRACE);
		if (!_evt) _evt = new Content(type, "");
		_evt.cellName = _cellName.getText();
		_evt.positionType = getRadioValue(_positionType);
		_evt.x = _x.getSelection();
		_evt.y = _y.getSelection();
		_evt.sizeType = getRadioValue(_sizeType);
		_evt.width = _w.getSelection();
		_evt.height = _h.getSelection();
		_evt.transition = _transition.transition;
		_evt.transitionSpeed = _transition.transitionSpeed;
		_evt.doAnime = _doAnime.getSelection();
		_evt.ignoreEffectBooster = _ignoreEffectBooster.getSelection();
		return true;
	}
}

/// 背景再配置の設定を行うダイアログ(Wsn.3)。
class MoveCardDialog : EventDialog {
private:
	Combo _cardGroup;
	Button[CoordinateType] _positionType;
	Spinner _x;
	Spinner _y;
	Button _changeLayer;
	Spinner _layer;
	Button _changeScale;
	Spinner _scale;
	CardAnimationPanel _cardSpeed;

	override
	protected void refreshWarning() { mixin(S_TRACE);
		string[] ws;
		ws ~= .sjisWarnings(prop.parent, summ, _cardGroup.getText(), prop.msgs.cardGroup);
		if (!_prop.isTargetVersion(summ, "3")) { mixin(S_TRACE);
			ws ~= .tryFormat(_prop.msgs.warningUnknownContentWsn, _prop.msgs.contentName(CType.MOVE_CARD), "3");
		}
		ws ~= _cardSpeed.warnings;
		warning = ws;
	}

	private void updateEnabled() { mixin(S_TRACE);
		_scale.setEnabled(_changeScale.getSelection());
		_layer.setEnabled(_changeLayer.getSelection());
	}

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) { mixin(S_TRACE);
		super (comm, prop, shell, summ, CType.MOVE_CARD, parent, evt, false, null, true);
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(2, false));

		{ mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			auto ggd = new GridData(GridData.FILL_HORIZONTAL);
			ggd.horizontalSpan = 2;
			grp.setLayoutData(ggd);
			grp.setLayout(normalGridLayout(1, true));
			grp.setText(prop.msgs.targetCardGroup);

			_cardGroup = createCardGroupCombo(comm, summ, grp, &catchMod, _evt ? _evt.cardGroup : "");
			mod(_cardGroup);
			_cardGroup.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			.listener(_cardGroup, SWT.Modify, &refreshWarning);
		}

		void delegate() updateEnabledPosition;
		{ mixin(S_TRACE);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.verticalSpan = 3;
			createPositionOrSizePanel(prop, this, area, gd, prop.msgs.moveCard, _positionType, _x, _y, updateEnabledPosition, prop.var.etc.posLeftMax, prop.var.etc.posTopMax, true);
		}

		{ mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setText(prop.msgs.scale);
			auto cl = new CenterLayout;
			cl.fillHorizontal = true;
			grp.setLayout(cl);

			auto comp = new Composite(grp, SWT.NONE);
			comp.setLayout(normalGridLayout(2, false));

			_changeScale = new Button(comp, SWT.CHECK);
			mod(_changeScale);
			_changeScale.setText(prop.msgs.changeScale);
			.listener(_changeScale, SWT.Selection, &updateEnabled);

			auto comp2 = new Composite(comp, SWT.NONE);
			auto wgd = windowGridLayout(2, false);
			wgd.marginWidth = 0;
			wgd.marginHeight = 0;
			comp2.setLayout(wgd);
			_scale = new Spinner(comp2, SWT.BORDER);
			initSpinner(_scale);
			mod(_scale);
			_scale.setMinimum(prop.var.etc.cardScaleMin);
			_scale.setMaximum(prop.var.etc.cardScaleMax);
			auto l = new Label(comp2, SWT.NONE);
			l.setText("%");
		}

		{ mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setText(prop.msgs.layer);
			auto cl = new CenterLayout;
			cl.fillHorizontal = true;
			grp.setLayout(cl);

			auto comp = new Composite(grp, SWT.NONE);
			comp.setLayout(normalGridLayout(2, false));

			_changeLayer = new Button(comp, SWT.CHECK);
			mod(_changeLayer);
			_changeLayer.setText(prop.msgs.changeLayer);
			.listener(_changeLayer, SWT.Selection, &updateEnabled);

			_layer = new Spinner(comp, SWT.BORDER);
			initSpinner(_layer);
			mod(_layer);
			_layer.setMinimum(LAYER_BACK_CELL);
			_layer.setMaximum(prop.var.etc.layerMax);
		}
		auto lsw = .max(_changeScale.computeSize(SWT.DEFAULT, SWT.DEFAULT).x, _changeLayer.computeSize(SWT.DEFAULT, SWT.DEFAULT).x);
		auto sgd = new GridData;
		sgd.widthHint = lsw;
		_changeScale.setLayoutData(sgd);
		auto lgd = new GridData;
		lgd.widthHint = lsw;
		_changeLayer.setLayoutData(lgd);

		{ mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setText(prop.msgs.cardSpeed);
			grp.setLayout(new CenterLayout);
			_cardSpeed = new CardAnimationPanel(comm, summ, grp, CardAnimationPanelType.MoveCard);
			mod(_cardSpeed);
			_cardSpeed.modEvent ~= &refreshWarning;
		}

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) { mixin(S_TRACE);
			_cardGroup.setText(_evt.cardGroup);
			_positionType[_evt.positionType].setSelection(true);
			_x.setSelection(_evt.x);
			_y.setSelection(_evt.y);
			_changeScale.setSelection(_evt.scale != -1);
			_scale.setSelection(_evt.scale == -1 ? 100 : _evt.scale);
			_changeLayer.setSelection(_evt.layer != -1);
			_layer.setSelection(_evt.layer == -1 ? LAYER_MENU_CARD : _evt.layer);
			_cardSpeed.speed = _evt.cardSpeed;
			_cardSpeed.overrideCardSpeed = _evt.overrideCardSpeed;
		} else { mixin(S_TRACE);
			_cardGroup.setText("");
			_positionType[CoordinateType.None].setSelection(true);
			_x.setSelection(0);
			_y.setSelection(0);
			_changeScale.setSelection(false);
			_scale.setSelection(100);
			_changeLayer.setSelection(false);
			_layer.setSelection(LAYER_MENU_CARD);
			_cardSpeed.speed = -1;
			_cardSpeed.overrideCardSpeed = false;
		}
		updateEnabledPosition();
		updateEnabled();
		refreshWarning();
	}

	override bool apply() { mixin(S_TRACE);
		if (!_evt) _evt = new Content(type, "");
		_evt.cardGroup = _cardGroup.getText();
		_evt.positionType = getRadioValue(_positionType);
		_evt.x = _x.getSelection();
		_evt.y = _y.getSelection();
		_evt.scale = _changeScale.getSelection() ? _scale.getSelection() : -1;
		_evt.layer = _changeLayer.getSelection() ? _layer.getSelection() : -1;
		_evt.cardSpeed = _cardSpeed.speed;
		_evt.overrideCardSpeed = _cardSpeed.overrideCardSpeed;
		return true;
	}
}

/// クーポン多岐分岐の設定を行うダイアログ(Wsn.2)。
class BranchMultiCouponDialog : EventDialog {
private:
	UseCounter _uc;
	RangePanel _range;
	Button _expandSPChars;

	override
	protected void refreshWarning() { mixin(S_TRACE);
		string[] ws;
		if (!prop.isTargetVersion(summ, "2")) { mixin(S_TRACE);
			ws ~= .tryFormat(prop.msgs.warningUnknownContentWsn, prop.msgs.contentName(CType.BRANCH_MULTI_COUPON), "2");
		}
		if (_expandSPChars.getSelection()) { mixin(S_TRACE);
			if (!_comm.prop.isTargetVersion(_summ, "4")) { mixin(S_TRACE);
				ws ~= _comm.prop.msgs.warningExpandSPCharsInCoupon;
			}
		}
		warning = ws;
	}

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, UseCounter uc, Content parent, Content evt) { mixin(S_TRACE);
		super (comm, prop, shell, summ, CType.BRANCH_MULTI_COUPON, parent, evt, false, null, true);
		_uc = uc;
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(2, false));

		auto ranges = [Range.SELECTED, Range.RANDOM, Range.PARTY, Range.FIELD];
		auto title = _prop.msgs.judgeTarget;
		_range = new RangePanel(comm, summ, _uc, area, ranges, "", title, false, this, evt, &catchMod, &refreshWarning, type);
		_range.setLayoutData(new GridData(GridData.FILL_BOTH));

		auto grp = new Group(area, SWT.NONE);
		grp.setLayoutData(new GridData(GridData.FILL_BOTH));
		grp.setText(_prop.msgs.spChars);
		grp.setLayout(new CenterLayout);
		_expandSPChars = new Button(grp, SWT.CHECK);
		mod(_expandSPChars);
		_expandSPChars.setText(_comm.prop.msgs.expandSPChars);
		_expandSPChars.setToolTipText(_comm.prop.msgs.expandSPCharsHint.replace("&", "&&"));
		.listener(_expandSPChars, SWT.Selection, &refreshWarning);

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) { mixin(S_TRACE);
			_expandSPChars.setSelection(_evt.expandSPChars);
		}
		refreshWarning();
	}

	override bool apply() { mixin(S_TRACE);
		if (!_evt) _evt = new Content(CType.BRANCH_MULTI_COUPON, "");
		_evt.range = _range.range;
		_evt.expandSPChars = _expandSPChars.getSelection();
		return true;
	}
}

/// 効果中断イベントの設定を行うダイアログ。
class EffectBreakDialog : EventDialog {
private:
	Button _consumeCard;

	override
	protected void refreshWarning() { mixin(S_TRACE);
		string[] ws;
		if (!_consumeCard.getSelection() && !prop.isTargetVersion(summ, "3")) { mixin(S_TRACE);
			ws ~= prop.msgs.warningConsumeCard;
		}
		warning = ws;
	}

	override
	protected void refDataVersion() { mixin(S_TRACE);
		_consumeCard.setEnabled(!(summ && summ.legacy) || !_consumeCard.getSelection());
		refreshWarning();
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) { mixin(S_TRACE);
		super (comm, prop, shell, summ, CType.EFFECT_BREAK, parent, evt, false, null, true);
	}

protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(1, false));
		{ mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			grp.setText(_prop.msgs.transitionType);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(new CenterLayout);

			_consumeCard = new Button(grp, SWT.CHECK);
			mod(_consumeCard);
			_consumeCard.setText(_prop.msgs.consumeCard);
			.listener(_consumeCard, SWT.Selection, &refDataVersion);
		}

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) { mixin(S_TRACE);
			_consumeCard.setSelection(_evt.consumeCard);
		} else { mixin(S_TRACE);
			_consumeCard.setSelection(true);
		}

		refDataVersion();
	}

	override bool apply() { mixin(S_TRACE);
		if (!_evt) _evt = new Content(CType.EFFECT_BREAK, "");
		_evt.consumeCard = _consumeCard.getSelection();
		return true;
	}
}

/// 状況設定イベントの設定を行うダイアログ(Wsn.4)。
class ChangeEnvironmentDialog : EventDialog {
private:
	Combo _backpackEnabled;
	EnvironmentStatus[] _backpackEnableds;

	override
	protected void refreshWarning() { mixin(S_TRACE);
		string[] ws;
		if (!prop.isTargetVersion(summ, "4")) { mixin(S_TRACE);
			ws ~= .tryFormat(prop.msgs.warningUnknownContentWsn, prop.msgs.contentName(CType.CHANGE_ENVIRONMENT), "4");
		}
		warning = ws;
	}

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) { mixin(S_TRACE);
		super (comm, prop, shell, summ, CType.CHANGE_ENVIRONMENT, parent, evt, false, null, true);
	}

protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(1, false));
		{ mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			grp.setText(_prop.msgs.environmentStatus);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(new CenterLayout);

			auto comp = new Composite(grp, SWT.NONE);
			comp.setLayout(zeroMarginGridLayout(2, false));

			auto l = new Label(comp, SWT.NONE);
			l.setText(prop.msgs.backpack);

			_backpackEnabled = new Combo(comp, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
			mod(_backpackEnabled);
			_backpackEnabled.setVisibleItemCount(prop.var.etc.comboVisibleItemCount);
			foreach (s; [EnvironmentStatus.NotSet, EnvironmentStatus.Enable, EnvironmentStatus.Disable]) { mixin(S_TRACE);
				_backpackEnabled.add(prop.msgs.environmentStatusName(s));
				_backpackEnableds ~= s;
			}
		}

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) { mixin(S_TRACE);
			_backpackEnabled.select(cast(int)_backpackEnableds.countUntil(_evt.backpackEnabled));
		} else { mixin(S_TRACE);
			_backpackEnabled.select(cast(int)_backpackEnableds.countUntil(EnvironmentStatus.NotSet));
		}

		refDataVersion();
	}

	override bool apply() { mixin(S_TRACE);
		if (!_evt) _evt = new Content(CType.CHANGE_ENVIRONMENT, "");
		_evt.backpackEnabled = _backpackEnableds[_backpackEnabled.getSelectionIndex()];
		return true;
	}
}
