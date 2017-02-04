
module cwx.editor.gui.dwt.eventdialog;

import cwx.summary;
import cwx.area;
import cwx.background;
import cwx.card;
import cwx.utils;
import cwx.event;
import cwx.types;
import cwx.flag;
import cwx.features;
import cwx.usecounter;
import cwx.skin;
import cwx.path;
import cwx.structs;
import cwx.menu;
import cwx.types;
import cwx.warning;

import cwx.editor.gui.sound;

import cwx.editor.gui.dwt.areaview;
import cwx.editor.gui.dwt.areaviewutils;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.materialselect;
import cwx.editor.gui.dwt.motionview;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.incsearch;
import cwx.editor.gui.dwt.chooser;
import cwx.editor.gui.dwt.couponview;
import cwx.editor.gui.dwt.keycodeview;
import cwx.editor.gui.dwt.abilityview;

import std.algorithm : countUntil;
import std.array;
import std.conv;
import std.math;
import std.path;
import std.traits;
import std.string : toLower;

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
		assert (summ);
	} body { mixin(S_TRACE);
		super (prop, shell, false, .tryFormat(prop.msgs.dlgTitContent, prop.msgs.contentName(type)), prop.images.content(type), resizable, size, true, true, [], rightGroup);
		enterClose = eClose;
		_comm = comm;
		_prop = prop;
		_summ = summ;
		_type = type;
		_parent = parent;
		_evt = evt;
		_comm.delContent.add(&delContent);
		_comm.refSkin.add(&refSkin);
		_comm.refDataVersion.add(&refDataVersion);
		_comm.refTargetVersion.add(&refreshWarning);
		getShell().addDisposeListener(new Dispose);
	}

	@property
	Content event() { mixin(S_TRACE);
		return _evt;
	}
	@property protected Commons comm() {return _comm;}
	@property protected Props prop() {return _prop;}
	@property protected Summary summ() {return _summ;}
	@property protected Content evt() {return _evt;}
	@property protected void evt(Content evt) {_evt = evt;}
	@property protected CType type() {return _type;}

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
	private Commons _comm;
	private Summary _summ;

	private Button[Range] _range;
	private const Range[] _ranges;

	private Combo _coupon = null;
	private Combo _couponType = null;
	private CouponType[] _couponTypes = [];
	private bool _couponUpdated = false;
	private string _initCoupon = "";

	string[] warnings() { mixin(S_TRACE);
		string[] ws;
		auto b = _range.get(Range.COUPON_HOLDER, null);
		if (b && b.getSelection()) { mixin(S_TRACE);
			if (!_comm.prop.isTargetVersion(_summ, "2")) { mixin(S_TRACE);
				ws ~= _comm.prop.msgs.warningCouponHolder;
			}
			ws ~= couponWarnings(_comm.prop.parent, _summ, _comm.prop.var.etc.targetVersion, _coupon.getText(), false);
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
			_range[range].setSelection(false);
			_range[_ranges[0]].setSelection(true);
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

	this (Commons comm, Composite parent, in Range[] ranges, string initCoupon, string title, bool horizontal, AbsDialog modDlg,
			in Content evt, bool delegate() catchMod, void delegate() refreshWarning) { mixin(S_TRACE);
		super (parent, SWT.NONE);
		_comm = comm;
		_summ = comm.summary;
		_ranges = ranges;
		if (evt) _initCoupon = evt.holdingCoupon;
		auto prop = comm.prop;
		setLayout(new FillLayout);
		auto grp = new Group(this, SWT.NONE);
		grp.setText(title);
		grp.setLayout(new CenterLayout);
		auto mainComp = new Composite(grp, SWT.NONE);
		if (horizontal) { mixin(S_TRACE);
			mainComp.setLayout(zeroMarginGridLayout(cast(int)ranges.length, false));
		} else {
			mainComp.setLayout(zeroMarginGridLayout(1, false));
		}
		Composite couponComp = null;
		auto radioGrp = new RadioGroup!Button;
		foreach (range; ranges) { mixin(S_TRACE);
			Button radio;
			Control c;
			int fillHorizontal = SWT.NONE;
			if (range is Range.COUPON_HOLDER) { mixin(S_TRACE);
				couponComp = new Composite(mainComp, SWT.NONE);
				couponComp.setLayout(zeroMarginGridLayout(1, true));
				fillHorizontal = GridData.FILL_HORIZONTAL;
				radio = new Button(couponComp, SWT.RADIO);
				c = couponComp;
			} else { mixin(S_TRACE);
				radio = new Button(mainComp, SWT.RADIO);
				c = radio;
			}
			modDlg.mod(radio);
			if (horizontal) { mixin(S_TRACE);
				c.setLayoutData(new GridData(GridData.FILL_BOTH));
			} else { mixin(S_TRACE);
				c.setLayoutData(new GridData(GridData.GRAB_VERTICAL | fillHorizontal));
			}
			radio.setText(prop.msgs.rangeName(range));
			.listener(radio, SWT.Selection, &updateEnabled);
			.listener(radio, SWT.Selection, refreshWarning);
			_range[range] = radio;
			if (evt && evt.range is range) { mixin(S_TRACE);
				radio.setSelection(true);
			}
			radioGrp.append(radio);
			if (range is Range.CARD_TARGET) { mixin(S_TRACE);
				radio.setToolTipText(prop.msgs.rangeDescCardTarget);
			}
		}
		if (!evt || evt.range !in _range) { mixin(S_TRACE);
			_range[_ranges[0]].setSelection(true);
		}
		if (Range.COUPON_HOLDER in _range) { mixin(S_TRACE);
			auto comp = new Composite(couponComp, SWT.NONE);
			auto cgd = new GridData(GridData.FILL_HORIZONTAL);
			if (horizontal) cgd.horizontalSpan = cast(int)ranges.length;
			comp.setLayoutData(cgd);

			comp.setLayout(zeroGridLayout(2, false));

			auto type = CouponComboType.AllCoupons;
			_coupon = createCouponCombo(comm, _summ, comp, catchMod, type, initCoupon);
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

		comm.refDataVersion.add(&refDataVersion);
		.listener(this, SWT.Dispose, { mixin(S_TRACE);
			comm.refDataVersion.remove(&refDataVersion);
		});

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

	this (Commons comm, Composite parent, bool horizontal, in Content evt, AbsDialog modDlg) { mixin(S_TRACE);
		super (parent, SWT.NONE);
		auto prop = comm.prop;
		_summ = comm.summary;
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
		comm.refDataVersion.add(&refreshTS);
		.listener(this, SWT.Dispose, { mixin(S_TRACE);
			comm.refDataVersion.remove(&refreshTS);
		});
	}

	private void refreshTS() { mixin(S_TRACE);
		_ts.setEnabled(!_summ.legacy);
		_tsSpeed.setEnabled(!_summ.legacy && transition !is Transition.DEFAULT && transition !is Transition.NONE);
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
		auto summary = _summ;
		auto areas = mixin (Areas);
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
				_transition = new TransitionPanel(comm, comp, false, _evt, this);
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
		assert (_list.selected != 0UL);
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
		refreshStarts(c);
	}
	void refreshStarts() { mixin(S_TRACE);
		refreshStarts(null);
	}
	void refreshStarts(Content del) { mixin(S_TRACE);
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
		_et = parent.tree;
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
		createMenuItem(comm, menu, MenuID.IncSearch, &incSearch, null);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(comm, menu, MenuID.OpenAtEventView, &openView, () => _list.getSelectionIndex() != -1);
		_list.setMenu(menu);
		.listener(_list, SWT.Selection, &selected);
		_incSearch = new IncSearch(comm, _list);
		_incSearch.modEvent ~= &refreshStarts;

		refreshStarts();
		_comm.refContent.add(&refContent);
		_comm.delContent.add(&delContent);
		_comm.replText.add(&refreshStarts);
		_list.addDisposeListener(new Dispose);

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
		if (-1 == _list.getSelectionIndex()) { mixin(S_TRACE);
			_list.select(0);
			_selected = (cast(Content) _list.getItem(0).getData()).name;
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
	Button[Range] _range;
	Button[CouponType] _type;
	Combo _name;
	static if (EditValue) {
		Spinner _value;
	}

	override
	protected void refreshWarning() { mixin(S_TRACE);
		string[] ws;
		ws ~= couponWarnings(prop.parent, summ, prop.var.etc.targetVersion, _name.getText(), Type is CType.GET_COUPON || Type is CType.LOSE_COUPON);
		static if (Field) {
			if (summ && summ.legacy && !_prop.targetVersion(summ, "1.30")) { mixin(S_TRACE);
				if (_range[Range.FIELD].getSelection()) { mixin(S_TRACE);
					ws ~= prop.msgs.warningBranchCouponAtField;
				}
			}
		}
		warning = ws;
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

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) { mixin(S_TRACE);
		super (comm, prop, shell, summ, Type, parent, evt, true, prop.var.couponEvtDlg, true);
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(2, false));
		auto skin = _comm.skin;

		auto leftComp = new Composite(area, SWT.NONE);
		leftComp.setLayout(zeroMarginGridLayout(1, true));
		leftComp.setLayoutData(new GridData(GridData.FILL_VERTICAL));
		{ mixin(S_TRACE);
			auto grp = new Group(leftComp, SWT.NONE);
			static if (EditValue) {
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			} else { mixin(S_TRACE);
				grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			}
			grp.setText(_prop.msgs.range);
			grp.setLayout(normalGridLayout(1, true));
			auto ranges = RANGE_MEMBER.dup;
			static if (Field) {
				ranges ~= Range.FIELD;
			}
			foreach (r; ranges) { mixin(S_TRACE);
				auto radio = new Button(grp, SWT.RADIO);
				mod(radio);
				radio.setLayoutData(new GridData(GridData.FILL_BOTH));
				radio.setText(_prop.msgs.rangeName(r));
				.listener(radio, SWT.Selection, &refreshWarning);
				_range[r] = radio;
			}
		}
		{ mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto cl = new CenterLayout(SWT.VERTICAL, 0);
			cl.fillHorizontal = true;
			grp.setLayout(cl);
			grp.setText(_prop.msgs.couponName);
			{ mixin(S_TRACE);
				auto comp = new Composite(grp, SWT.NONE);
				comp.setLayout(normalGridLayout(3, false));
				{ mixin(S_TRACE);
					static if (Type is CType.GET_COUPON || Type is CType.LOSE_COUPON) {
						auto type = CouponComboType.GetLose;
					} else static if (Type is CType.BRANCH_COUPON) {
						auto type = CouponComboType.AllCoupons;
					} else static assert (0);
					_name = createCouponCombo(comm, summ, comp, &catchMod, type, _evt ? _evt.coupon : "");
					mod(_name);
					auto gd = new GridData(GridData.FILL_HORIZONTAL);
					gd.horizontalSpan = 3;
					gd.widthHint = _prop.var.etc.nameWidth;
					_name.setLayoutData(gd);
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
				.listener(_name, SWT.Modify, { mixin(S_TRACE);
					auto t = prop.sys.couponType(_name.getText());
					bool checked = false;
					foreach (coType; _type.keys) { mixin(S_TRACE);
						_type[coType].setSelection(coType == t);
						checked |= (coType == t);
					}
					if (!checked) _type[CouponType.Normal].setSelection(true);
					refreshWarning();
				});
			}
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

		if (_evt) { mixin(S_TRACE);
			if (_evt.range in _range) { mixin(S_TRACE);
				_range[_evt.range].setSelection(true);
			} else { mixin(S_TRACE);
				_range[Range.SELECTED].setSelection(true);
			}
			auto cType = prop.sys.couponType(_evt.coupon);
			auto cTypeP = cType in _type;
			if (cTypeP) { mixin(S_TRACE);
				cTypeP.setSelection(true);
			} else { mixin(S_TRACE);
				_type[CouponType.Normal].setSelection(true);
			}
			_name.setText(_evt.coupon);
			static if (EditValue) {
				_value.setSelection(_evt.couponValue);
			}
		} else { mixin(S_TRACE);
			_range[Range.SELECTED].setSelection(true);
			_type[CouponType.Normal].setSelection(true);
			static if (EditValue) {
				_value.setSelection(0);
			}
		}
		refreshWarning();
	}

	override bool apply() { mixin(S_TRACE);
		if (!_evt) _evt = new Content(Type, "");
		foreach (range, radio; _range) { mixin(S_TRACE);
			if (radio.getSelection()) { mixin(S_TRACE);
				_evt.range = range;
				_evt.coupon = _name.getText();
				static if (EditValue) {
					_evt.couponValue = _value.getSelection();
				}
				break;
			}
		}
		comm.refCoupons.call();
		return true;
	}
}

alias CouponEventDialog!(CType.BRANCH_COUPON, false, true) BranchCouponDialog;
alias CouponEventDialog!(CType.GET_COUPON, true, false) GetCouponDialog;
alias CouponEventDialog!(CType.LOSE_COUPON, false, false) LoseCouponDialog;

/// 一つのテキストの設定を行うダイアログ。
private class OneTextEventDialog(CType Type, string Name, string Get, string Set, string EngineVersion = "") : EventDialog {
private:
	Combo _name;

	override
	protected void refreshWarning() { mixin(S_TRACE);
		string[] ws;
		static if (EngineVersion != "") {
			if (!_prop.targetVersion(summ, EngineVersion)) { mixin(S_TRACE);
				ws ~= .tryFormat(_prop.msgs.warningUnknownContent, _prop.msgs.contentName(Type), EngineVersion);
			}
		}
		warning = ws;
	}

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) { mixin(S_TRACE);
		super (comm, prop, shell, summ, Type, parent, evt, true, prop.var.inputEvtDlg, true);
	}

protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(1, false));
		{ mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setText(mixin (Name));
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
		}

		if (_evt) { mixin(S_TRACE);
			_name.setText(mixin (Get));
		}
		refreshWarning();
	}

	override bool apply() { mixin(S_TRACE);
		if (!_evt) _evt = new Content(Type, "");
		string text = _name.getText();
		mixin (Set);
		if (CDetail.fromType(Type).use(CArg.GOSSIP)) { mixin(S_TRACE);
			comm.refGossips.call();
		}
		if (CDetail.fromType(Type).use(CArg.COMPLETE_STAMP)) { mixin(S_TRACE);
			comm.refCompleteStamps.call();
		}
		if (CDetail.fromType(Type).use(CArg.CELL_NAME)) { mixin(S_TRACE);
			comm.refCellNames.call();
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
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt, AbstractArea refTarget, CType type) { mixin(S_TRACE);
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
			_view = createBgImagesViewAndMenu(_comm, _prop, _summ, _cont, area, _refTarget, false);
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
				auto gd = new GridData(GridData.FILL_VERTICAL);
				gd.heightHint = 0;
				(new Label(comp, SWT.SEPARATOR | SWT.VERTICAL)).setLayoutData(gd);
				_transition = new TransitionPanel(comm, comp, true, _evt, this);
			} else {
				_transition = new TransitionPanel(comm, area, true, _evt, this);
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
		}
		_transition = new TransitionPanel(comm, area, true, _evt, this);
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
		comm.refCellNames.call();
		return true;
	}
}

/// BGMイベントの設定を行うダイアログ。
class BgmDialog : EventDialog {
private:
	MaterialSelect!(MtType.BGM, Combo, Table) _msel;

	override
	protected void refreshWarning() { mixin(S_TRACE);
		auto ws = comm.skin.warningBGM(prop.parent, _msel.filePath, summ.legacy, _prop.var.etc.targetVersion);
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
		auto ws = comm.skin.warningSE(prop.parent, _msel.filePath, summ.legacy, _prop.var.etc.targetVersion);
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
				(_comm, _prop, _summ, false, null, included => cast(string[])[]);
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
		this (int v) {_v = v;}
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			_value.setSelection(_value.getSelection() + _v);
		}
	}
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(1, false));
		{ mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setText(mixin (Name));
			grp.setLayout(new CenterLayout(SWT.VERTICAL | SWT.HORIZONTAL, 0));
			auto comp = new Composite(grp, SWT.NONE);
			_value = new Spinner(comp, SWT.BORDER);
			initSpinner(_value);
			mod(_value);
			_value.setMinimum(Min);
			_value.setMaximum(mixin (Max));
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
			_value.setSelection(mixin (Get));
		} else { mixin(S_TRACE);
			_value.setSelection(Def);
		}
	}

	override bool apply() { mixin(S_TRACE);
		if (!_evt) _evt = new Content(Type, "");
		int value = _value.getSelection();
		mixin (Set);
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
	Spinner _lev;
	MaterialSelect!(MtType.SE, Combo, Combo) _se;
	Scale _sucRate;
	Button[EffectType] _effTyp;
	Button[Resist] _res;
	Button[CardVisual] _vis;
	RangePanel _range;

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
		if (!_ignite.getSelection() && _keyCodes.keyCodes.length) { mixin(S_TRACE);
			ws ~= prop.msgs.warningIgnoreKeyCode;
		}
		if (_keyCodes.enabled) { mixin(S_TRACE);
			ws ~= _keyCodes.warnings;
		}

		if (_summ && _summ.legacy && _se.filePath != "" && !_se.selectedDefDir) ws ~= prop.msgs.warningNotDefaultSE;
		ws ~= comm.skin.warningSE(prop.parent, _se.filePath, summ.legacy, _prop.var.etc.targetVersion) ~ _se.warnings;
		warning = ws;
	}

	override
	protected void refDataVersion() { mixin(S_TRACE);
		if (summ && summ.legacy) { mixin(S_TRACE);
			if (_refAbility.getSelection()) { mixin(S_TRACE);
				_refAbility.setSelection(false);
				applyEnabled(true);
			}
			if (_ignite.getSelection()) { mixin(S_TRACE);
				_ignite.setSelection(false);
				applyEnabled(true);
			}
		}
		updateEnabled();
		super.refDataVersion();
	}

	void updateEnabled() { mixin(S_TRACE);
		_ignite.setEnabled(!summ || !summ.legacy);
		_keyCodes.enabled = _ignite.getSelection() || _keyCodes.keyCodes.length;
		_refAbility.setEnabled(!summ || !summ.legacy);
		_ability.enabled = _refAbility.getSelection();
		_lev.setEnabled(!_refAbility.getSelection());
		refreshWarning();
	}

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) { mixin(S_TRACE);
		super (comm, prop, shell, summ, CType.EFFECT, parent, evt, true, prop.var.effEvtDlg, true);
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
			_mview = new MotionView(_comm, _prop, _summ, tabf, SWT.NONE);
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
					_range = new RangePanel(comm, comp2, ranges, initCoupon, title, false, this, evt, &catchMod, &refreshWarning);
					_range.setLayoutData(new GridData(GridData.FILL_BOTH));
				}
				{ mixin(S_TRACE);
					auto grp = new Group(comp2, SWT.NONE);
					grp.setText(_prop.msgs.se);
					auto gd = new GridData(GridData.FILL_HORIZONTAL);
					gd.horizontalSpan = 2;
					grp.setLayoutData(gd);
					grp.setLayout(normalGridLayout(3, false));
					_se = new MaterialSelect!(MtType.SE, Combo, Combo)(comm, prop, summ, false, null, included => [prop.msgs.defaultSelection(prop.msgs.soundNone)]);
					mod(_se);
					_se.modEvent ~= &refreshWarning;
					_se.loadedEvent ~= &refreshWarning;
					_se.createDirsCombo(grp).setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
					_se.createStopButton(grp);
					_se.createPlayButton(grp);
					auto gdfl = new GridData(GridData.FILL_HORIZONTAL);
					gdfl.horizontalSpan = 4;
					_se.createFileList(grp).setLayoutData(gdfl);
					auto ogd = new GridData(GridData.HORIZONTAL_ALIGN_END);
					ogd.horizontalSpan = 4;
					_se.createPlayingOptions(grp).setLayoutData(ogd);
				}
				{ mixin(S_TRACE);
					auto gd = new GridData(GridData.FILL_BOTH);
					gd.horizontalSpan = 2;
					createSuccessRateScale(_prop, comp2, _sucRate).setLayoutData(gd);
					mod(_sucRate);
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
				grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
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
			{ mixin(S_TRACE);
				auto grp = new Group(comp, SWT.NONE);
				grp.setText(prop.msgs.keyCodes);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setLayout(normalGridLayout(1, true));

				_keyCodes = new KeyCodeView(comm, summ, grp, false, &catchMod);
				_keyCodes.setLayoutData(new GridData(GridData.FILL_BOTH));
				mod(_keyCodes);
				_keyCodes.modEvent ~= &updateEnabled;
			}
		}

		tabf.setLayoutData(area.computeSize(SWT.DEFAULT, SWT.DEFAULT));
		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) { mixin(S_TRACE);
			_mview.motions = _evt.motions;
			_lev.setSelection(_evt.signedLevel);
			_se.path = _evt.soundPath;
			_se.volume = _evt.soundVolume;
			_se.loopCount = _evt.soundLoopCount;
			_sucRate.setSelection(_evt.successRate + Content.successRate_max);
			_effTyp[_evt.effectType].setSelection(true);
			_res[_evt.resist].setSelection(true);
			_vis[_evt.cardVisual].setSelection(true);
			_refAbility.setSelection(_evt.refAbility);
			_ability.physical = _evt.physical;
			_ability.mental = _evt.mental;
			_ignite.setSelection(_evt.ignite);
			_keyCodes.keyCodes = _evt.keyCodes;
		} else { mixin(S_TRACE);
			_mview.motions = [];
			_lev.setSelection(0);
			_se.path = "";
			_sucRate.setSelection(Content.successRate_max + Content.successRate_max);
			_effTyp[EffectType.NONE].setSelection(true);
			_res[Resist.UNFAIL].setSelection(true);
			_vis[CardVisual.NONE].setSelection(true);
			_refAbility.setSelection(false);
			_ignite.setSelection(false);
			_keyCodes.keyCodes = [];
		}
		refDataVersion();
	}

	override bool apply() { mixin(S_TRACE);
		if (!_evt) _evt = new Content(CType.EFFECT, "");
		_evt.motions = _mview.motions;
		_evt.signedLevel = _lev.getSelection();
		_evt.soundPath = _se.path;
		_evt.soundVolume = _se.volume;
		_evt.soundLoopCount = _se.loopCount;
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
		warning = ws;
	}

	FlagDir _root;

	SplitPane _sash;
	FlagChooser!(F, false) _flags;
	string _oldSel = "";
	Table _values;

	@property
	uint selectedValue() { mixin(S_TRACE);
		return _values.getSelectionIndex();
	}

	void refreshValues() { mixin(S_TRACE);
		static if (is(F:cwx.flag.Flag)) {
			F flag = summ.flagDirRoot.findFlag(_flags.selected);
		} else static if (is(F:Step)) {
			F flag = summ.flagDirRoot.findStep(_flags.selected);
		} else static assert (0);
		static if (SelValue) {
			int sel = _values.getSelectionIndex();
		}
		_values.removeAll();
		if (flag) { mixin(S_TRACE);
			static if (is (F == cwx.flag.Flag)) {
				auto itm1 = new TableItem(_values, SWT.NONE);
				itm1.setText(flag.on);
				auto itm2 = new TableItem(_values, SWT.NONE);
				itm2.setText(flag.off);
			} else static if (is (F == Step)) {
				foreach (val; flag.values) { mixin(S_TRACE);
					auto itm = new TableItem(_values, SWT.NONE);
					itm.setText(val);
				}
			} else { mixin(S_TRACE);
				static assert (0);
			}
			static if (SelValue) {
				if (sel < 0) sel = 0;
				static if (is (F == Step)) {
					if (sel >= flag.values.length) sel = cast(int)flag.values.length - 1;
				}
				_values.select(sel);
			}
		}
		updateLabel();
	}
	void selectedFlag() { mixin(S_TRACE);
		string selPath = _flags.selectedWithDir;
		if (_oldSel == selPath) { mixin(S_TRACE);
			static if (SelValue) {
				_values.select(0);
				updateLabel();
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
	void refFS(cwx.flag.Flag[] f, Step[] s) { mixin(S_TRACE);
		static if (is(F : cwx.flag.Flag)) {
			if (!f.length) return;
		} else { mixin(S_TRACE);
			if (!s.length) return;
		}
		int sel = _values.getSelectionIndex();
		refreshValues();
		_values.select(sel);
	}
	void delFS(cwx.flag.Flag[] f, Step[] s) { mixin(S_TRACE);
		static if (is(F : cwx.flag.Flag)) {
			if (!f.length) return;
		} else { mixin(S_TRACE);
			if (!s.length) return;
		}
		static if (is(F : cwx.flag.Flag)) {
			if (!_root.allFlags.length) { mixin(S_TRACE);
				forceCancel();
				return;
			}
		} else static if (is(F : Step)) {
			if (!_root.allSteps.length) { mixin(S_TRACE);
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
			static if (is(F:cwx.flag.Flag)) {
				F step = summ.flagDirRoot.findFlag(_flags.selected);
			} else static if (is(F:Step)) {
				F step = summ.flagDirRoot.findStep(_flags.selected);
			} else static assert (0);
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
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt, FlagDir root) { mixin(S_TRACE);
		_root = root;
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
			static if (is (F == cwx.flag.Flag)) {
				l1.setText(_prop.msgs.flag);
				l1.setImage(_prop.images.flag);
				l2.setText(_prop.msgs.flagValue);
			} else static if (is (F == Step)) {
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
			_flags = new FlagChooser!(F, false, false)(comm, summ, left);
			mod(_flags);
			_flags.modEvent ~= &selectedFlag;
			_flags.setLayoutData(new GridData(GridData.FILL_BOTH));
		}
		{ mixin(S_TRACE);
			_values = .rangeSelectableTable(right, SWT.SINGLE | SWT.FULL_SELECTION | SWT.BORDER | SWT.V_SCROLL);
			new FullTableColumn(_values, SWT.NONE);
			mod(_values);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.heightHint = _prop.var.etc.nameTableHeight;
			_values.setLayoutData(gd);
			_values.setEnabled(SelValue);
			_values.addSelectionListener(new ValSListener);
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

		_comm.refFlagAndStep.add(&refFS);
		_comm.delFlagAndStep.add(&delFS);
		_flags.addDisposeListener(new Dispose);

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) { mixin(S_TRACE);
			static if (is (F == cwx.flag.Flag)) {
				_flags.selected = _evt.flag;
			} else static if (is (F == Step)) {
				_flags.selected = _evt.step;
			} else { mixin(S_TRACE);
				static assert (0);
			}
			_oldSel = _flags.selectedWithDir;
			refreshValues();
			static if (SelValue) {
				static if (is (F == cwx.flag.Flag)) {
					_values.select(_evt.flagValue ? 0 : 1);
				} else static if (is (F == Step)) {
					_values.select(_evt.stepValue);
				} else { mixin(S_TRACE);
					static assert (0);
				}
			}
			static if (Type is CType.CHECK_STEP) {
				_cmp.select(cast(int)_cmps.countUntil(_evt.comparison4));
			}
		} else { mixin(S_TRACE);
			_flags.selected = "";
			refreshValues();
			static if (Type is CType.CHECK_STEP) {
				_cmp.select(0);
			}
		}
		updateLabel();
		refreshWarning();
		.setupWeights(_sash, _prop.var.etc.flagEventSashL, _prop.var.etc.flagEventSashR);
	}

	override bool apply() { mixin(S_TRACE);
		assert (_flags.selected != "");
		if (!_evt) _evt = new Content(Type, "");
		static if (is (F == cwx.flag.Flag)) {
			_evt.flag = _flags.selected;
			static if (SelValue) {
				_evt.flagValue = _values.getSelectionIndex() == 0;
			}
		} else static if (is (F == Step)) {
			_evt.step = _flags.selected;
			static if (SelValue) {
				_evt.stepValue = _values.getSelectionIndex();
			}
		} else { mixin(S_TRACE);
			static assert (0);
		}
		static if (Type is CType.CHECK_STEP) {
			_evt.comparison4 = _cmps[_cmp.getSelectionIndex()];
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

	SplitPane _sash;
	FlagChooser!(F, false, Random) _flags1;
	FlagChooser!(F, false, false) _flags2;

	override
	protected void refreshWarning() { mixin(S_TRACE);
		string[] ws;
		if (!_prop.targetVersion(summ, "1.30")) { mixin(S_TRACE);
			ws ~= .tryFormat(_prop.msgs.warningUnknownContent, _prop.msgs.contentName(Type), "1.30");
		}
		warning = ws;
	}

	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			_comm.delFlagAndStep.remove(&delFS);
		}
	}
	void delFS(cwx.flag.Flag[] f, Step[] s) { mixin(S_TRACE);
		static if (is(F : cwx.flag.Flag)) {
			if (!_root.allFlags.length) { mixin(S_TRACE);
				forceCancel();
			}
		} else static if (is(F : Step)) {
			if (!_root.allSteps.length) { mixin(S_TRACE);
				forceCancel();
			}
		} else static assert (0);
	}

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt, FlagDir root) { mixin(S_TRACE);
		_root = root;
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
			static if (is (F == cwx.flag.Flag)) {
				l1.setImage(_prop.images.flag);
				l2.setImage(_prop.images.flag);
			} else static if (is (F == Step)) {
				l1.setImage(_prop.images.step);
				l2.setImage(_prop.images.step);
			} else { mixin(S_TRACE);
				static assert (0);
			}
		}
		_flags1 = new FlagChooser!(F, false, Random)(comm, summ, left);
		_flags1.setLayoutData(new GridData(GridData.FILL_BOTH));
		_flags2 = new FlagChooser!(F, false, false)(comm, summ, right, false);
		_flags2.setLayoutData(new GridData(GridData.FILL_BOTH));

		_comm.delFlagAndStep.add(&delFS);
		_sash.addDisposeListener(new Dispose);

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) { mixin(S_TRACE);
			static if (is (F == cwx.flag.Flag)) {
				_flags1.selected = _evt.flag;
				_flags2.selected = _evt.flag2;
			} else static if (is (F == Step)) {
				_flags1.selected = _evt.step;
				_flags2.selected = _evt.step2;
			} else { mixin(S_TRACE);
				static assert (0);
			}
		} else { mixin(S_TRACE);
			_flags1.selected = "";
			_flags2.selected = "";
		}
		refreshWarning();
		.setupWeights(_sash, _prop.var.etc.flagCombiSashL, _prop.var.etc.flagCombiSashR);
	}

	override bool apply() { mixin(S_TRACE);
		if (!_evt) _evt = new Content(Type, "");
		static if (is (F == cwx.flag.Flag)) {
			_evt.flag = _flags1.selected;
			_evt.flag2 = _flags2.selected;
		} else static if (is (F == Step)) {
			_evt.step = _flags1.selected;
			_evt.step2 = _flags2.selected;
		} else { mixin(S_TRACE);
			static assert (0);
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
			ws ~= couponWarnings(prop.parent, summ, prop.var.etc.targetVersion, coupon.name, false);
		}

		warning = ws;
	}

	protected override void refDataVersion() { mixin(S_TRACE);
		auto valued = _method[cast(size_t)SelectionMethod.Valued];
		valued.setEnabled(!summ.legacy);
		if (!valued.isEnabled() && valued.getSelection()) { mixin(S_TRACE);
			valued.setSelection(false);
			_method[cast(size_t)SelectionMethod.Manual].setSelection(true);
			applyEnabled(true);
		}
		_couponView.enabled = !summ.legacy && valued.getSelection();
		_initValue.setEnabled(!summ.legacy && valued.getSelection());
		refreshWarning();
	}

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) { mixin(S_TRACE);
		super (comm, prop, shell, summ, CType.BRANCH_SELECT, parent, evt, true, prop.var.brMemberDlg, true);
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
			auto comp = createValueEditor(comm, summ, area, &catchMod, _couponView, _initValue, updateValue, false);
			mod(_initValue);
			mod(_couponView);
			_couponView.modEvent ~= &refreshWarning;
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
			_evt.initValue = 1;
		}
		return true;
	}
}

/// 評価メンバ設定用のビューを生成する。
Composite createValueEditor(Commons comm, Summary summ, Composite parent, bool delegate() catchMod, out CouponView!(CVType.Valued) couponView, out Spinner initValue, out void delegate() updateValue, bool talker = true) { mixin(S_TRACE);
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
	couponView = new CouponView!(CVType.Valued)(comm, summ, grp, SWT.NONE, catchMod, false);
	auto gd = new GridData(GridData.FILL_BOTH);
	gd.horizontalSpan = 2;
	couponView.setLayoutData(gd);

	updateValue = { mixin(S_TRACE);
		int max = initValue.getSelection();
		int min = max;
		foreach (cp; couponView.coupons) { mixin(S_TRACE);
			if (cp.value < 0) { mixin(S_TRACE);
				min += cp.value;
			} else { mixin(S_TRACE);
				max += cp.value;
			}
		}
		if (0 >= max) {
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
		}
		_ability = new AbilityView(comm, area, SWT.NONE);
		_ability.setLayoutData(new GridData(GridData.FILL_BOTH));

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) { mixin(S_TRACE);
			_lev.setSelection(_evt.signedLevel);
			_targ[_evt.targetS.m].setSelection(true);
			_sleep[_evt.targetS.sleep ? 0 : 1].setSelection(true);
			_ability.physical = _evt.physical;
			_ability.mental = _evt.mental;
		} else { mixin(S_TRACE);
			_lev.setSelection(0);
			_targ[Target.M.SELECTED].setSelection(true);
			_sleep[1].setSelection(true);
		}
	}

	override bool apply() { mixin(S_TRACE);
		if (!_evt) _evt = new Content(CType.BRANCH_ABILITY, "");
		auto targ = Target(getRadioValue!(Target.M)(_targ), _sleep[0].getSelection());
		_evt.signedLevel = _lev.getSelection();
		_evt.targetS = targ;
		_evt.physical = _ability.physical;
		_evt.mental = _ability.mental;
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

private Composite createStatusPane(Props prop, Composite area, ref Button[Status] stat, void delegate(Button) mod) { mixin(S_TRACE);
	auto grp = new Group(area, SWT.NONE);
	grp.setText(prop.msgs.judgeState);
	grp.setLayout(normalGridLayout(4, true));
	auto statuses = [Status.ACTIVE, Status.INACTIVE, Status.ALIVE, Status.DEAD,
			Status.FINE, Status.INJURED, Status.HEAVY_INJURED, Status.UNCONSCIOUS,
			Status.POISON, Status.SLEEP, Status.BIND, Status.PARALYZE,
			Status.CONFUSE, Status.OVERHEAT, Status.BRAVE, Status.PANIC,
			Status.SILENCE, Status.FACE_UP, Status.ANTI_MAGIC,
			Status.UP_ACTION, Status.UP_AVOID, Status.UP_RESIST, Status.UP_DEFENSE,
			Status.DOWN_ACTION, Status.DOWN_AVOID, Status.DOWN_RESIST, Status.DOWN_DEFENSE];
	foreach (s; statuses) { mixin(S_TRACE);
		auto radio = new Button(grp, SWT.RADIO);
		mod(radio);
		radio.setText(prop.msgs.statusName(s));
		radio.setLayoutData(new GridData(GridData.FILL_BOTH));
		stat[s] = radio;
	}
	return grp;
}
private Composite createStatusHint(Props prop, Composite area) { mixin(S_TRACE);
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
	RangePanel _range;
	Button[Status] _stat;

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
		warning = ws;
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) { mixin(S_TRACE);
		super (comm, prop, shell, summ, CType.BRANCH_STATUS, parent, evt, false, null, true);
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(1, false));
		{ mixin(S_TRACE);
			auto ranges = [Range.SELECTED, Range.RANDOM, Range.PARTY];
			auto title = _prop.msgs.judgeTarget;
			auto initCoupon = evt ? evt.holdingCoupon : "";
			_range = new RangePanel(comm, area, ranges, initCoupon, title, true, this, evt, &catchMod, &refreshWarning);
			_range.setLayoutData(new GridData(GridData.FILL_BOTH));
		}
		auto status = createStatusPane(prop, area, _stat, &mod!Button);
		status.setLayoutData(new GridData(GridData.FILL_BOTH));
		foreach (st, b; _stat) { mixin(S_TRACE);
			.listener(b, SWT.Selection, &refreshWarning);
		}
		auto hint = createStatusHint(prop, area);
		hint.setLayoutData(new GridData(GridData.FILL_BOTH));

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) { mixin(S_TRACE);
			_stat[_evt.status].setSelection(true);
		} else { mixin(S_TRACE);
			_stat[Status.ACTIVE].setSelection(true);
		}
		refreshWarning();
	}

	override bool apply() { mixin(S_TRACE);
		if (!_evt) _evt = new Content(CType.BRANCH_STATUS, "");
		_evt.range = _range.range;
		_evt.status = getRadioValue!(Status)(_stat);
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
				_num.setEnabled(!_allDel.getSelection());
			}
		}
	}
	Button[Range] _range;
	Table _list;
	IncSearch _incSearch;
	void incSearch() { mixin(S_TRACE);
		.forceFocus(_list, true);
		_incSearch.startIncSearch();
	}

	ulong _selectedID = 0;
	void selected() { mixin(S_TRACE);
		auto index = _list.getSelectionIndex();
		if (-1 != index) { mixin(S_TRACE);
			_selectedID = (cast(C) _list.getItem(index).getData()).id;
		}
	}

	void refreshList() { mixin(S_TRACE);
		ulong id = _selectedID;
		_list.removeAll();
		size_t i = 0;
		foreach (c; mixin (Cards)) { mixin(S_TRACE);
			if (!_incSearch.match(c.name)) continue;
			auto itm = new TableItem(_list, SWT.NONE);
			itm.setData(c);
			static if (is (C == SkillCard)) {
				itm.setImage(0, _prop.images.skill);
			} else static if (is (C == ItemCard)) {
				itm.setImage(0, _prop.images.item);
			} else static if (is (C == BeastCard)) {
				itm.setImage(0, _prop.images.beast);
			} else { mixin(S_TRACE);
				static assert (0);
			}
			itm.setText(0, to!(string)(c.id));
			itm.setText(1, c.name);
			if (id == c.id) _list.select(cast(int)i);
			i++;
		}
		_list.showSelection();
	}
	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			static if (is (C == SkillCard)) {
				_comm.refSkill.remove(&refCard);
				_comm.delSkill.remove(&delCard);
			} else static if (is (C == ItemCard)) {
				_comm.refItem.remove(&refCard);
				_comm.delItem.remove(&delCard);
			} else static if (is (C == BeastCard)) {
				_comm.refBeast.remove(&refCard);
				_comm.delBeast.remove(&delCard);
			} else static assert (0);
		}
	}

	void refCard(C c) { mixin(S_TRACE);
		refreshList();
	}
	void delCard(CWXPath owner, C c) { mixin(S_TRACE);
		auto cards = mixin (Cards);
		if (cards.length) { mixin(S_TRACE);
			refreshList();
		} else { mixin(S_TRACE);
			forceCancel();
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
						Range.BACKPACK, Range.PARTY_AND_BACKPACK, Range.FIELD]) { mixin(S_TRACE);
					auto radio = new Button(grp, SWT.RADIO);
					mod(radio);
					radio.setText(_prop.msgs.rangeName(r));
					if (r is Range.FIELD) { mixin(S_TRACE);
						radio.setToolTipText(_prop.msgs.rangeDescField);
					}
					radio.setLayoutData(new GridData(GridData.FILL_BOTH));
					_range[r] = radio;
				}
			}
		}
		{ mixin(S_TRACE);
			_list = .rangeSelectableTable(area, SWT.SINGLE | SWT.FULL_SELECTION | SWT.BORDER | SWT.V_SCROLL);
			mod(_list);
			_incSearch = new IncSearch(comm, _list);
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
			createMenuItem(comm, menu, MenuID.IncSearch, &incSearch, null);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(comm, menu, MenuID.OpenAtCardView, &openView, () => _list.getSelectionIndex() != -1);
			_list.setMenu(menu);

			refreshList();
		}
		static if (is (C == SkillCard)) {
			_comm.refSkill.add(&refCard);
			_comm.delSkill.add(&delCard);
		} else static if (is (C == ItemCard)) {
			_comm.refItem.add(&refCard);
			_comm.delItem.add(&delCard);
		} else static if (is (C == BeastCard)) {
			_comm.refBeast.add(&refCard);
			_comm.delBeast.add(&delCard);
		} else static assert (0);
		_list.addDisposeListener(new Dispose);

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_evt) { mixin(S_TRACE);
			static if (is (C == SkillCard)) {
				_selectedID = _evt.skill;
			} else static if (is (C == ItemCard)) {
				_selectedID = _evt.item;
			} else static if (is (C == BeastCard)) {
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
		} else { mixin(S_TRACE);
			static if (Delete) {
				_allDel.setSelection(false);
			}
			_num.setSelection(1);
			_range[RangeDef].setSelection(true);
		}
		assert (_list.getItemCount());
		if (-1 == _list.getSelectionIndex()) { mixin(S_TRACE);
			_list.select(0);
			_selectedID = (cast(C) _list.getItem(0).getData()).id;
		}
	}

	override bool apply() { mixin(S_TRACE);
		assert (_list.getItemCount());
		if (!_evt) _evt = new Content(Type, "");
		static if (is (C == SkillCard)) {
			_evt.skill = _selectedID;
		} else static if (is (C == ItemCard)) {
			_evt.item = _selectedID;
		} else static if (is (C == BeastCard)) {
			_evt.beast = _selectedID;
		} else { mixin(S_TRACE);
			static assert (0);
		}
		_evt.range = getRadioValue!(Range)(_range);
		static if (Delete) {
			if (_allDel.getSelection()) { mixin(S_TRACE);
				_evt.cardNumber = 0u;
			} else { mixin(S_TRACE);
				_evt.cardNumber = _num.getSelection();
			}
		} else { mixin(S_TRACE);
			_evt.cardNumber = _num.getSelection();
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

			_transition = new TransitionPanel(comm, grp, false, _evt, this);
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

	void updateEnabled() { mixin(S_TRACE);
		_levMin.setEnabled(_hasLevel.getSelection());
		_levMax.setEnabled(_hasLevel.getSelection());
		foreach (key, b; _status) { mixin(S_TRACE);
			b.setEnabled(_hasStatus.getSelection());
		}
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) { mixin(S_TRACE);
		super (comm, prop, shell, summ, CType.BRANCH_RANDOM_SELECT, parent, evt, false, null, true);
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(1, false));
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
			grp.setText(_prop.msgs.targetLevel);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
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
		auto status = createStatusPane(prop, area, _status, &mod!Button);
		status.setLayoutData(new GridData(GridData.FILL_BOTH));
		auto hint = createStatusHint(prop, area);
		hint.setLayoutData(new GridData(GridData.FILL_BOTH));

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
		} else { mixin(S_TRACE);
			_castRange[CastRange.PARTY].setSelection(true);
			_hasLevel.setSelection(false);
			_hasStatus.setSelection(false);
			_levMin.setSelection(1);
			_levMax.setSelection(1);
			_status[Status.ACTIVE].setSelection(true);
		}
		updateEnabled();
		refreshWarning();
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
	Combo _keyCode;

	override
	protected void refreshWarning() { mixin(S_TRACE);
		string[] ws;
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
		super.refDataVersion();
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
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(new CenterLayout(SWT.HORIZONTAL));
			auto comp = new Composite(grp, SWT.NONE);
			comp.setLayout(zeroMarginGridLayout(1, true));
			foreach (r; [Range.SELECTED, Range.RANDOM, Range.BACKPACK, Range.PARTY_AND_BACKPACK]) { mixin(S_TRACE);
				auto radio = new Button(comp, SWT.RADIO);
				mod(radio);
				radio.setText(_prop.msgs.rangeName(r));
				radio.setLayoutData(new GridData(GridData.FILL_BOTH));
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
			_keyCode.setText(_evt.keyCode);
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
			_keyCode.setText("");
		}
		refreshWarning();
	}

	override bool apply() { mixin(S_TRACE);
		if (!_evt) _evt = new Content(CType.BRANCH_KEY_CODE, "");

		_evt.keyCode = _keyCode.getText();
		_evt.keyCodeRange = getRadioValue!(Range)(_keyCodeRange);
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

		_comm.refKeyCodes.call();
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

/// 背景再配置の設定を行うダイアログ。
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
		if (!_prop.isTargetVersion(summ, "1")) { mixin(S_TRACE);
			ws ~= .tryFormat(_prop.msgs.warningUnknownContentWsn, _prop.msgs.contentName(CType.MOVE_BG_IMAGE), "1");
		}
		warning = ws;
	}

	private void updateEnabled() { mixin(S_TRACE);
		auto p = !_positionType[CoordinateType.None].getSelection();
		_x.setEnabled(p);
		_y.setEnabled(p);
		auto s = !_sizeType[CoordinateType.None].getSelection();
		_w.setEnabled(s);
		_h.setEnabled(s);
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
		}

		void createGrp(string name, ref Button[CoordinateType] type, ref Spinner x, ref Spinner y, int max1, int max2) { mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setText(name);
			grp.setLayout(new CenterLayout(SWT.VERTICAL | SWT.HORIZONTAL, 0));

			auto comp = new Composite(grp, SWT.NONE);
			comp.setLayout(normalGridLayout(4, false));

			void putRadio(CoordinateType ct) { mixin(S_TRACE);
				auto radio = new Button(comp, SWT.RADIO);
				mod(radio);
				radio.setText(_prop.msgs.coordinateTypeName(ct));
				.listener(radio, SWT.Selection, &updateEnabled);
				auto gd = new GridData;
				gd.horizontalSpan = 4;
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
				mod(spn);
				spn.setMinimum(-max);
				spn.setMaximum(max);
				return spn;
			}
			x = putSpinner(prop.msgs.horizontalValue, max1);
			y = putSpinner(prop.msgs.verticalValue, max2);
		}
		createGrp(prop.msgs.moveCell, _positionType, _x, _y, prop.var.etc.posLeftMax, prop.var.etc.posTopMax);
		createGrp(prop.msgs.resizeCell, _sizeType, _w, _h, prop.var.etc.backWidthMax, prop.var.etc.backHeightMax);

		{ mixin(S_TRACE);
			_transition = new TransitionPanel(comm, area, true, _evt, this);
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
		updateEnabled();
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

/// クーポン多岐分岐の設定を行うダイアログ(Wsn.2)。
class BranchMultiCouponDialog : EventDialog {
private:
	RangePanel _range;

	override
	protected void refreshWarning() { mixin(S_TRACE);
		string[] ws;
		if (!prop.isTargetVersion(summ, "2")) { mixin(S_TRACE);
			ws ~= .tryFormat(prop.msgs.warningUnknownContentWsn, prop.msgs.contentName(CType.BRANCH_MULTI_COUPON), "2");
		}
		warning = ws;
	}

public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) { mixin(S_TRACE);
		super (comm, prop, shell, summ, CType.BRANCH_MULTI_COUPON, parent, evt, false, null, true);
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(1, true));

		auto ranges = [Range.SELECTED, Range.RANDOM, Range.PARTY, Range.FIELD];
		auto title = _prop.msgs.judgeTarget;
		_range = new RangePanel(comm, area, ranges, "", title, false, this, evt, &catchMod, &refreshWarning);
		_range.setLayoutData(new GridData(GridData.FILL_BOTH));

		refreshWarning();
	}

	override bool apply() { mixin(S_TRACE);
		if (!_evt) _evt = new Content(CType.BRANCH_MULTI_COUPON, "");
		_evt.range = _range.range;
		return true;
	}
}
