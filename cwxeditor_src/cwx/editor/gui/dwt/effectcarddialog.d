
module cwx.editor.gui.dwt.effectcarddialog;

import cwx.summary;
import cwx.card;
import cwx.types;
import cwx.motion;
import cwx.utils;
import cwx.skin;
import cwx.event;
import cwx.imagesize;
import cwx.path;

import cwx.editor.gui.sound;

import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.materialselect;
import cwx.editor.gui.dwt.imageselect;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.motionview;
import cwx.editor.gui.dwt.radarspinner;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.scales;
import cwx.editor.gui.dwt.chooser;
import cwx.editor.gui.dwt.cardpane;
import cwx.editor.gui.dwt.keycodeview;

import std.algorithm : max;
import std.array;
import std.path;

import org.eclipse.swt.all;

import java.lang.all;

public:

/// 手札カードの設定を行うダイアログ。
class EffectCardDialog(C) : AbsDialog, CardDialog {
private:
	/// アイテムの現在使用回数の設定
	/// (エンジンの仕様上ほとんど意味が無いため現在無効)
	static immutable SetUseCountCur = false;

	int _readOnly = 0;
	Commons _comm;
	Props _prop;
	Summary _summ;
	C _card;

	ImageSelect!(MtType.CARD) _imgPath;
	FixedWidthText _desc;
	GBLimitText _name;
	Button _needSpell;
	Button[EffectType] _effTyp;
	Button[Resist] _res;
	Button[Physical] _phy;
	Button[Mental] _mtl;
	static if (is (C == SkillCard)) {
		Spinner _level;
		void calcPrice(int value) { mixin(S_TRACE);
			_price.setMinimum(_prop.looks.skillPrice(value));
			_price.setMaximum(_prop.looks.skillPrice(value));
			_price.setSelection(_prop.looks.skillPrice(value));
		}
		int priceCancel(int oldVal) { mixin(S_TRACE);
			calcPrice(oldVal);
			return oldVal;
		}
	}
	static if (is (C == ItemCard)) {
		Spinner _useCount;
		static if (SetUseCountCur) {
			Spinner _useCountCur;
			Button _useCountIsMax;
			void updateUseLimitMax() { mixin(S_TRACE);
				_useCountCur.setMaximum(_useCount.getSelection());
				if (_useCountIsMax.getSelection()) { mixin(S_TRACE);
					_useCountCur.setSelection(_useCount.getSelection());
				}
			}
		}
	}
	static if (is (C == BeastCard)) {
		Spinner _useCount;
		void calcPrice(int value) { mixin(S_TRACE);
			_price.setMinimum(_prop.looks.beastPrice);
			_price.setMaximum(_prop.looks.beastPrice);
			_price.setSelection(_prop.looks.beastPrice);
		}
		int priceCancel(int oldVal) { mixin(S_TRACE);
			calcPrice(oldVal);
			return oldVal;
		}
	}
	Spinner _price;
	MotionView _motions;
	Composite _useModParent;
	RadarSpinner _useModR;
	Scales _useModS;
	size_t[Enhance] _useModTbl;
	static if (is (C == ItemCard)) {
		Composite _hasModParent;
		RadarSpinner _hasModR;
		Scales _hasModS;
		size_t[Enhance] _hasModTbl;
	}
	Button[CardTarget] _targ;
	Button _one;
	Button _all;
	Composite _oneAllGrp;
	Button[CardVisual] _vis;
	Button[Premium] _prem;
	Scale _sucRate;
	MaterialSelect!(MtType.SE, Combo, Combo) _se1;
	MaterialSelect!(MtType.SE, Combo, Combo) _se2;
	KeyCodeView _keyCodes;
	Text _scenario;
	TextMenuModify _scenarioTM;
	Text _author;
	TextMenuModify _authorTM;
	Skin _summSkin;
	@property
	Skin summSkin() { mixin(S_TRACE);
		return _summSkin ? _summSkin : _comm.skin;
	}
	class ResetSource : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			ignoreMod = true;
			scope (exit) ignoreMod = false;
			_scenario.setText(_summ.scenarioName);
			_author.setText(_summ.author);
			_scenarioTM.reset();
			_authorTM.reset();
		}
	}
	class ModSource : ModifyListener {
		override void modifyText(ModifyEvent e) { mixin(S_TRACE);
			refreshWarning();
		}
	}
	void refEventTree(EventTree et) { mixin(S_TRACE);
		if (et.owner is _card || et.owner is null) { mixin(S_TRACE);
			refreshWarning();
		}
	}
	void refreshWarning() { mixin(S_TRACE);
		string[] ws;
		if (_name.over) { mixin(S_TRACE);
			ws ~= .tryFormat(_prop.msgs.warningNameLenOver, _prop.looks.nameLimit, _prop.looks.nameLimit / 2);
		}
		ws ~= _imgPath.warnings;
		if (_effTyp[EffectType.NONE].getSelection()) { mixin(S_TRACE);
			ws ~= _prop.msgs.warningEffectTypeNone;
		}
		ws ~= _motions.warnings;
		foreach (m; _motions.motions) { mixin(S_TRACE);
			if (m.type == MType.VANISH_TARGET && m.element != cast(int) Element.MIRACLE) { mixin(S_TRACE);
				ws ~= _prop.msgs.warningVanishCast;
				break;
			}
		}
		if (_summ && _summ.legacy && _se1.filePath != "" && !_se1.selectedDefDir) { mixin(S_TRACE);
			ws ~= _prop.msgs.warningNotDefaultSE;
		}
		ws ~= summSkin.warningSE(_prop.parent, _se1.filePath, _summ.legacy, _prop.var.etc.targetVersion) ~ _se1.warnings;
		if (_summ && _summ.legacy && _se2.filePath != "" && !_se2.selectedDefDir) { mixin(S_TRACE);
			ws ~= _prop.msgs.warningNotDefaultSE;
		}
		ws ~= summSkin.warningSE(_prop.parent, _se2.filePath, _summ.legacy, _prop.var.etc.targetVersion) ~ _se2.warnings;
		if (_card && _card.trees.length) { mixin(S_TRACE);
			if (_scenario.getText() != _summ.scenarioName || _author.getText() != _summ.author) { mixin(S_TRACE);
				ws ~= _prop.msgs.diffSource;
			}
		}
		ws ~= _keyCodes.warnings;

		warning = ws;
	}

	class OASelect : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			refreshEnblOneAll();
		}
	}
	class SelEffectType : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			refreshWarning();
		}
	}

	CTabItem constructMain(CTabFolder tabf) { mixin(S_TRACE);
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(normalGridLayout(2, false));
		{ mixin(S_TRACE);
			auto comp2 = new Composite(comp, SWT.NONE);
			comp2.setLayoutData(new GridData(GridData.FILL_BOTH));
			comp2.setLayout(zeroMarginGridLayout(1, false));
			{ mixin(S_TRACE);
				auto grp = new Group(comp2, SWT.NONE);
				grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				grp.setLayout(normalGridLayout(2, false));
				grp.setText(_prop.msgs.name);
				_name = new GBLimitText(_prop.looks.monospace,
					_prop.looks.nameLimit, false, grp, SWT.BORDER | _readOnly);
				mod(_name.widget);
				createTextMenu!Text(_comm, _prop, _name.widget, &catchMod);
				_name.limitEvent ~= &refreshWarning;
				auto gd = new GridData(GridData.FILL_HORIZONTAL);
				gd.widthHint = _name.computeSize(SWT.DEFAULT, SWT.DEFAULT).x;
				_name.widget.setLayoutData(gd);
				auto l = new Label(grp, SWT.NONE);
				l.setText(.tryFormat(_prop.msgs.nameLimit, _prop.looks.nameLimit, _prop.looks.nameLimit / 2));
			}
			{ mixin(S_TRACE);
				auto skin = summSkin;
				_imgPath = new ImageSelect!(MtType.CARD)(comp2, _readOnly, _comm, _prop, _summ,
					_prop.s(_prop.looks.cardSize.width), _prop.s(_prop.looks.cardSize.height), true, &_name.getText);
				mod(_imgPath);
				_imgPath.modEvent ~= &refreshWarning;
				_imgPath.widget.setLayoutData(new GridData(GridData.FILL_BOTH));
			}
		}
		{ mixin(S_TRACE);
			auto comp2 = new Composite(comp, SWT.NONE);
			comp2.setLayoutData(new GridData(GridData.FILL_VERTICAL));
			comp2.setLayout(zeroMarginGridLayout(1, false));
			{ mixin(S_TRACE);
				auto grp = new Group(comp2, SWT.NONE);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setLayout(normalGridLayout(1, true));
				grp.setText(_prop.msgs.workConditionGroup);
				Button createCheck(string name, bool enabled) {
					auto check = new Button(grp, SWT.CHECK);
					mod(check);
					check.setEnabled(enabled);
					check.setText(name);
					auto gd = new GridData;
					gd.grabExcessVerticalSpace = true;
					check.setLayoutData(gd);
					return check;
				}
				_needSpell = createCheck(_prop.msgs.needSpell, !_readOnly);
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
					radio.setEnabled(!_readOnly);
					if (2 <= i) { mixin(S_TRACE);
						auto gd = new GridData(GridData.FILL_BOTH);
						gd.horizontalSpan = 2;
						radio.setLayoutData(gd);
					} else { mixin(S_TRACE);
						radio.setLayoutData(new GridData(GridData.FILL_BOTH));
					}
					radio.setText(.tryFormat(_prop.msgs.effectTypeElement, _prop.msgs.effectTypeName(eff)));
					radio.setToolTipText(.replace(_prop.msgs.effectTypeDesc(eff), "&", "&&"));
					radio.addSelectionListener(new SelEffectType);
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
					radio.setEnabled(!_readOnly);
					radio.setLayoutData(new GridData(GridData.FILL_BOTH));
					radio.setText(_prop.msgs.resistName(res));
					radio.setToolTipText(.replace(_prop.msgs.resistDesc(res), "&", "&&"));
					_res[res] = radio;
				}
			}
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.card);
		tab.setControl(comp);
		return tab;
	}
	CTabItem constructDesc(CTabFolder tabf) { mixin(S_TRACE);
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(normalGridLayout(1, true));
		auto top = new Composite(comp, SWT.NONE);
		top.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		top.setLayout(zeroMarginGridLayout(2, false));
		static if (is (C == SkillCard)) {
			{ mixin(S_TRACE);
				auto grp = new Group(top, SWT.NONE);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setLayout(new CenterLayout);
				grp.setText(_prop.msgs.skillLevel);
				auto comp2 = new Composite(grp, SWT.NONE);
				comp2.setLayout(normalGridLayout(2, false));
				_level = new Spinner(comp2, SWT.BORDER | _readOnly);
				initSpinner(_level);
				mod(_level);
				_level.setMaximum(_prop.var.etc.skillLevelMax);
				_level.setMinimum(0);
				auto l = new Label(comp2, SWT.NONE);
				l.setText(.tryFormat(_prop.msgs.rangeHint, 0, _prop.var.etc.skillLevelMax));
			}
		} else static if (is (C == ItemCard) || is (C == BeastCard)) {
			{ mixin(S_TRACE);
				auto grp = new Group(top, SWT.NONE);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setLayout(new CenterLayout);
				grp.setText(_prop.msgs.useCountGroup);
				auto comp2 = new Composite(grp, SWT.NONE);
				static if (SetUseCountCur && is(C:ItemCard)) {
					comp2.setLayout(zeroMarginGridLayout(3, false));
					auto l1 = new Label(comp2, SWT.NONE);
					l1.setText(_prop.msgs.useCountMax);
					_useCount = new Spinner(comp2, SWT.BORDER | _readOnly);
					initSpinner(_useCount);
					mod(_useCount);
					_useCount.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
					_useCount.setMaximum(_prop.var.etc.useCountMax);
					_useCount.setMinimum(0);
					.listener(_useCount, SWT.Selection, &updateUseLimitMax);
					auto l2 = new Label(comp2, SWT.NONE);
					l2.setText(.tryFormat(_prop.msgs.useCountRange, _prop.var.etc.useCountMax));
					auto l3 = new Label(comp2, SWT.NONE);
					l3.setText(_prop.msgs.useCountCur);
					_useCountCur = new Spinner(comp2, SWT.BORDER | _readOnly);
					initSpinner(_useCountCur);
					mod(_useCountCur);
					_useCountCur.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
					_useCountCur.setMaximum(_prop.var.etc.useCountMax);
					_useCountCur.setMinimum(0);
					_useCountIsMax = new Button(comp2, SWT.CHECK);
					_useCountIsMax.setEnabled(!_readOnly);
					_useCountIsMax.setText(_prop.msgs.useCountIsMax);
					.listener(_useCountIsMax, SWT.Selection, { mixin(S_TRACE);
						_useCountCur.setEnabled(!_readOnly && !_useCountIsMax.getSelection());
						if (_useCountIsMax.getSelection()) { mixin(S_TRACE);
							_useCountCur.setSelection(_useCount.getSelection());
						}
					});
				} else { mixin(S_TRACE);
					comp2.setLayout(normalGridLayout(2, false));
					_useCount = new Spinner(comp2, SWT.BORDER | _readOnly);
					initSpinner(_useCount);
					mod(_useCount);
					_useCount.setMaximum(_prop.var.etc.useCountMax);
					_useCount.setMinimum(0);
					auto l = new Label(comp2, SWT.NONE);
					l.setText(.tryFormat(_prop.msgs.useCountRange, _prop.var.etc.useCountMax));
				}
			}
		} else { mixin(S_TRACE);
			static assert (0);
		}
		{ mixin(S_TRACE);
			auto grp = new Group(top, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(new CenterLayout);
			grp.setText(_prop.msgs.price);
			auto comp2 = new Composite(grp, SWT.NONE);
			comp2.setLayout(normalGridLayout(2, false));
			static if (is (C == SkillCard) || is (C == BeastCard)) {
				_price = new Spinner(comp2, SWT.BORDER | SWT.READ_ONLY);
				initSpinner(_price);
				_price.setMaximum(_prop.var.etc.priceMax);
				static if (is (C == SkillCard)) {
					new SpinnerEdit(_level, &calcPrice, &calcPrice, &priceCancel);
				} else static if (is (C == BeastCard)) {
					new SpinnerEdit(_useCount, &calcPrice, &calcPrice, &priceCancel);
				} else { mixin(S_TRACE);
					static assert (0);
				}
				auto l = new Label(comp2, SWT.NONE);
				l.setText(_prop.msgs.priceAuto);
			} else static if (is (C == ItemCard)) {
				_price = new Spinner(comp2, SWT.BORDER | _readOnly);
				initSpinner(_price);
				mod(_price);
				_price.setMaximum(_prop.var.etc.priceMax);
				_price.setMinimum(0);
				auto l = new Label(comp2, SWT.NONE);
				l.setText(.tryFormat(_prop.msgs.rangeHint, 0, _prop.var.etc.priceMax));
			} else { mixin(S_TRACE);
				static assert (0);
			}
		}
		{ mixin(S_TRACE);
			auto grp = new Group(comp, SWT.NONE);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.horizontalSpan = 2;
			grp.setLayoutData(gd);
			grp.setLayout(new CenterLayout(SWT.HORIZONTAL));
			grp.setText(_prop.msgs.desc);
			_desc = new FixedWidthText(_prop.looks.cardDescFont(summSkin.legacy), _prop.looks.cardDescLen, grp, SWT.BORDER | _readOnly);
			mod(_desc.widget);
			createTextMenu!Text(_comm, _prop, _desc.widget, &catchMod);
			_desc.widget.setLayoutData(_desc.computeTextBaseSize(_prop.looks.cardDescLine));
		}
		{ mixin(S_TRACE);
			auto grp = new Group(comp, SWT.NONE);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.horizontalSpan = 2;
			grp.setLayoutData(gd);
			grp.setLayout(normalGridLayout(2, false));
			grp.setText(_prop.msgs.source);
			Text createLine(string title, out TextMenuModify tm) { mixin(S_TRACE);
				auto l = new Label(grp, SWT.NONE);
				l.setText(title);
				auto text = new Text(grp, SWT.BORDER | _readOnly);
				mod(text);
				tm = createTextMenu!Text(_comm, _prop, text, &catchMod);
				text.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				text.addModifyListener(new ModSource);
				return text;
			}
			_scenario = createLine(_prop.msgs.sourceScenario, _scenarioTM);
			_author = createLine(_prop.msgs.sourceAuthor, _authorTM);

			auto resetSource = new Button(grp, SWT.PUSH);
			resetSource.setEnabled(!_readOnly);
			auto rgd = new GridData(GridData.HORIZONTAL_ALIGN_END);
			rgd.horizontalSpan = 2;
			resetSource.setLayoutData(rgd);
			resetSource.setText(_prop.msgs.resetSource);
			resetSource.addSelectionListener(new ResetSource);
		}

		auto tab = new CTabItem(tabf, SWT.NONE);
		static if (is (C == SkillCard)) {
			tab.setText(_prop.msgs.levelAndDesc);
		} else static if (is (C == ItemCard) || is (C == BeastCard)) {
			tab.setText(_prop.msgs.useCountAndDesc);
		}
		tab.setControl(comp);
		return tab;
	}
	CTabItem constructApt(CTabFolder tabf) { mixin(S_TRACE);
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(normalGridLayout(2, false));
		{ mixin(S_TRACE);
			auto grp = new Group(comp, SWT.NONE);
			grp.setText(_prop.msgs.aptPhysical);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto cl = new CenterLayout(SWT.HORIZONTAL, 0);
			cl.fillVertical = true;
			grp.setLayout(cl);
			auto comp2 = new Composite(grp, SWT.NONE);
			comp2.setLayout(normalGridLayout(1, true));
			foreach (phy; [Physical.DEX, Physical.AGL, Physical.INT,
					Physical.STR, Physical.VIT, Physical.MIN]) { mixin(S_TRACE);
				auto radio = new Button(comp2, SWT.RADIO);
				mod(radio);
				radio.setEnabled(!_readOnly);
				radio.setLayoutData(new GridData(GridData.FILL_VERTICAL));
				radio.setText(_prop.msgs.physicalName(phy));
				_phy[phy] = radio;
			}
		}
		{ mixin(S_TRACE);
			auto grp = new Group(comp, SWT.NONE);
			grp.setText(_prop.msgs.aptMental);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto cl = new CenterLayout(SWT.HORIZONTAL, 0);
			cl.fillVertical = true;
			grp.setLayout(cl);
			auto comp2 = new Composite(grp, SWT.NONE);
			auto gl = normalGridLayout(2, true);
			gl.horizontalSpacing = _prop.var.etc.radioGroupSeparatorWidth;
			comp2.setLayout(gl);
			static const Ms = [Mental.AGGRESSIVE, Mental.UNAGGRESSIVE,
				Mental.CHEERFUL, Mental.UNCHEERFUL,
				Mental.BRAVE, Mental.UNBRAVE, Mental.CAUTIOUS, Mental.UNCAUTIOUS,
				Mental.TRICKISH, Mental.UNTRICKISH];
			foreach (i, m; Ms) { mixin(S_TRACE);
				auto radio = new Button(comp2, SWT.RADIO);
				mod(radio);
				radio.setEnabled(!_readOnly);
				radio.setLayoutData(new GridData(GridData.FILL_BOTH));
				radio.setText(_prop.msgs.mentalName(m));
				_mtl[m] = radio;
			}
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.apt);
		tab.setControl(comp);
		return tab;
	}
	Composite createModParent(Composite comp, string title) { mixin(S_TRACE);
		auto grp = new Group(comp, SWT.NONE);
		grp.setText(title);
		grp.setLayoutData(new GridData(GridData.FILL_BOTH));
		auto cl = new CenterLayout;
		cl.fillHorizontal = true;
		cl.fillVertical = true;
		grp.setLayout(cl);
		return grp;
	}
	void createMod(Composite parent, ref size_t[Enhance] tbl, ref RadarSpinner useModR, ref Scales useModS) { mixin(S_TRACE);
		int[] values = [];
		if (useModR) { mixin(S_TRACE);
			values = useModR.getValues();
			useModR.dispose();
			useModR = null;
		}
		if (useModS) { mixin(S_TRACE);
			values = useModS.getValues();
			useModS.dispose();
			useModS = null;
		}

		static const Es = [Enhance.AVOID, Enhance.RESIST, Enhance.DEFENSE];
		string[] names;
		names.length = Es.length;
		foreach (i, enh; Es) { mixin(S_TRACE);
			tbl[enh] = i;
			names[i] = .tryFormat(_prop.msgs.enhanceBonus, _prop.msgs.enhanceName(enh));
		}

		int stepC = _prop.var.etc.enhanceMax * 2 + 1;
		int min = cast(int) _prop.var.etc.enhanceMax * -1;
		int page = _prop.var.etc.enhanceMax / 2;
		if (_prop.var.etc.radarStyleParams) { mixin(S_TRACE);
			useModR = new RadarSpinner(parent, _readOnly);
			useModR.setRadar(stepC, names, min);
			useModR.antialias = true;
			useModR.borderlines = [0];
			useModR.lineStep = page;
			if (values.length) useModR.setValues(values);
			mod(useModR);
		} else { mixin(S_TRACE);
			useModS = new Scales(parent, _readOnly);
			useModS.setScales(stepC, names, page, min);
			useModS.borderlines = [0];
			if (values.length) useModS.setValues(values);
			mod(useModS);
		}
		parent.layout();
	}
	void initUseMod() { mixin(S_TRACE);
		createMod(_useModParent, _useModTbl, _useModR, _useModS);
	}
	CTabItem constructUseModify(CTabFolder tabf) { mixin(S_TRACE);
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(normalGridLayout(2, false));
		{ mixin(S_TRACE);
			_useModParent = createModParent(comp, _prop.msgs.useModify);
			initUseMod();
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.useBonus);
		tab.setControl(comp);
		return tab;
	}
	static if (is (C == ItemCard)) {
		void initHasMod() { mixin(S_TRACE);
			createMod(_hasModParent, _hasModTbl, _hasModR, _hasModS);
		}
		CTabItem constructHaveModify(CTabFolder tabf) { mixin(S_TRACE);
			auto comp = new Composite(tabf, SWT.NONE);
			comp.setLayout(normalGridLayout(2, false));
			{ mixin(S_TRACE);
				_hasModParent = createModParent(comp, _prop.msgs.haveModify);
				initHasMod();
			}
			auto tab = new CTabItem(tabf, SWT.NONE);
			tab.setText(_prop.msgs.haveBonus);
			tab.setControl(comp);
			return tab;
		}
	}
	CTabItem constructMotion(CTabFolder tabf) { mixin(S_TRACE);
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(normalGridLayout(1, false));
		{ mixin(S_TRACE);
			_motions = new MotionView(_comm, _prop, _summ, comp, _readOnly);
			mod(_motions);
			_motions.warningEvent ~= &refreshWarning;
			_motions.setLayoutData(new GridData(GridData.FILL_BOTH));
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setControl(comp);
		tab.setText(_prop.msgs.motion);
		return tab;
	}
	CTabItem constructProps(CTabFolder tabf) { mixin(S_TRACE);
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(normalGridLayout(1, false));
		{ mixin(S_TRACE);
			auto tcomp = new Composite(comp, SWT.NONE);
			tcomp.setLayoutData(new GridData(GridData.FILL_BOTH));
			tcomp.setLayout(zeroMarginGridLayout(2, false));
			{ mixin(S_TRACE);
				auto comp2 = new Composite(tcomp, SWT.NONE);
				auto gd = new GridData(GridData.FILL_BOTH);
				gd.verticalSpan = 2;
				comp2.setLayoutData(gd);
				comp2.setLayout(zeroMarginGridLayout(1, false));
				{ mixin(S_TRACE);
					auto grp = new Group(comp2, SWT.NONE);
					grp.setText(_prop.msgs.effectTarget);
					grp.setLayoutData(new GridData(GridData.FILL_BOTH));
					auto cl = new CenterLayout(SWT.HORIZONTAL, 0);
					cl.fillVertical = true;
					grp.setLayout(cl);
					auto comp3 = new Composite(grp, SWT.NONE);
					comp3.setLayout(normalGridLayout(2, false));
					foreach (t; [CardTarget.NONE, CardTarget.USER,
							CardTarget.PARTY, CardTarget.ENEMY, CardTarget.BOTH]) { mixin(S_TRACE);
						auto radio = new Button(comp3, SWT.RADIO);
						mod(radio);
						radio.setEnabled(!_readOnly);
						radio.setLayoutData(new GridData(GridData.FILL_BOTH));
						radio.setText(_prop.msgs.cardTargetName(t));
						radio.addSelectionListener(new OASelect);
						_targ[t] = radio;
					}
				}
				{ mixin(S_TRACE);
					auto grp = new Group(comp2, SWT.NONE);
					grp.setText(_prop.msgs.effectRange);
					grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
					auto cl = new CenterLayout;
					cl.fillVertical = true;
					grp.setLayout(cl);
					auto comp3 = new Composite(grp, SWT.NONE);
					comp3.setLayout(normalGridLayout(2, false));
					auto one = new Button(comp3, SWT.RADIO);
					mod(one);
					one.setEnabled(!_readOnly);
					one.setLayoutData(new GridData(GridData.FILL_BOTH));
					one.setText(_prop.msgs.cardTargetOne);
					_one = one;
					auto all = new Button(comp3, SWT.RADIO);
					mod(all);
					all.setEnabled(!_readOnly);
					all.setLayoutData(new GridData(GridData.FILL_BOTH));
					all.setText(_prop.msgs.cardTargetAll);
					_all = all;
					_oneAllGrp = grp;
				}
			}
			{ mixin(S_TRACE);
				auto grp = new Group(tcomp, SWT.NONE);
				grp.setText(_prop.msgs.effectVisual);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setLayout(normalGridLayout(2, false));
				foreach (v; [CardVisual.NONE, CardVisual.HORIZONTAL,
						CardVisual.REVERSE, CardVisual.VERTICAL]) { mixin(S_TRACE);
					auto radio = new Button(grp, SWT.RADIO);
					mod(radio);
					radio.setEnabled(!_readOnly);
					radio.setLayoutData(new GridData(GridData.FILL_BOTH));
					radio.setText(_prop.msgs.cardVisualName(v));
					_vis[v] = radio;
				}
			}
			{ mixin(S_TRACE);
				auto grp = new Group(tcomp, SWT.NONE);
				grp.setText(_prop.msgs.cardPremium);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setLayout(normalGridLayout(1, false));
				foreach (p; [Premium.NORMAL, Premium.RARE, Premium.PREMIUM]) { mixin(S_TRACE);
					auto radio = new Button(grp, SWT.RADIO);
					mod(radio);
					radio.setEnabled(!_readOnly);
					radio.setLayoutData(new GridData(GridData.FILL_BOTH));
					radio.setText(_prop.msgs.premiumName(p));
					_prem[p] = radio;
				}
			}
		}
		{ mixin(S_TRACE);
			createSuccessRateScale(_prop, comp, _sucRate)
				.setLayoutData(new GridData(GridData.FILL_BOTH));
			mod(_sucRate);
			_sucRate.setEnabled(!_readOnly);
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.cardProps);
		tab.setControl(comp);
		return tab;
	}
	CTabItem constructKeyCode(CTabFolder tabf) { mixin(S_TRACE);
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(normalGridLayout(1, true));
		auto sash = new SplitPane(comp, SWT.HORIZONTAL);
		sash.setLayoutData(new GridData(GridData.FILL_BOTH));
		auto skin = summSkin;
		{ mixin(S_TRACE);
			auto grp = new Group(sash, SWT.NONE);
			grp.setText(_prop.msgs.se);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(normalGridLayout(1, false));
			MaterialSelect!(MtType.SE, Combo, Combo) createSE(string title) { mixin(S_TRACE);
				auto comp = new Composite(grp, SWT.NONE);
				comp.setLayoutData(new GridData(GridData.FILL_BOTH));
				comp.setLayout(zeroMarginGridLayout(3, false));

				auto se = new MaterialSelect!(MtType.SE, Combo, Combo)(_comm, _prop, _summ, _readOnly != 0, null, included => [_prop.msgs.defaultSelection(_prop.msgs.soundNone)]);
				mod(se);
				se.modEvent ~= &refreshWarning;
				se.loadedEvent ~= &refreshWarning;

				auto l = new CLabel(comp, SWT.NONE);
				auto gdl = new GridData(GridData.FILL_HORIZONTAL);
				gdl.horizontalSpan = 3;
				l.setLayoutData(gdl);
				l.setImage(_prop.images.sound);
				l.setText(title);

				se.createDirsCombo(comp).setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				se.createStopButton(comp);
				se.createPlayButton(comp);

				auto gdfl = new GridData(GridData.FILL_HORIZONTAL);
				gdfl.horizontalSpan = 3;
				se.createFileList(comp).setLayoutData(gdfl);
				auto ogd = new GridData(GridData.FILL_HORIZONTAL);
				ogd.horizontalSpan = 3;
				se.createPlayingOptions(comp, false, true).setLayoutData(ogd);
				return se;
			}
			_se1 = createSE(_prop.msgs.se1);
			_se2 = createSE(_prop.msgs.se2);
		}
		{ mixin(S_TRACE);
			auto grp = new Group(sash, SWT.NONE);
			grp.setText(_prop.msgs.keyCodes);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(normalGridLayout(1, true));

			_keyCodes = new KeyCodeView(_comm, _summ, grp, _readOnly, &catchMod);
			_keyCodes.setLayoutData(new GridData(GridData.FILL_BOTH));
			mod(_keyCodes);
			_keyCodes.modEvent ~= &refreshWarning;
		}
		.setupWeights(sash, _prop.var.etc.seKeyCodeSashL, _prop.var.etc.seKeyCodeSashR);

		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.seAndKeyCode);
		tab.setControl(comp);
		return tab;
	}
	void delCard(CWXPath owner, C c) { mixin(S_TRACE);
		if (_card is c) { mixin(S_TRACE);
			forceCancel();
		}
	}
	void refScenario(Summary summ) { mixin(S_TRACE);
		forceCancel();
	}
	void refSkin() { mixin(S_TRACE);
		_desc.font = _prop.looks.cardDescFont(summSkin.legacy);
	}
	void refDataVersion() { mixin(S_TRACE);
		refreshWarning();
	}
	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			static if (is(C : SkillCard)) {
				_comm.delSkill.remove(&delCard);
			} else static if (is(C : ItemCard)) {
				_comm.delItem.remove(&delCard);
			} else static if (is(C : BeastCard)) {
				_comm.delBeast.remove(&delCard);
			} else static assert (0);
			_comm.refSkin.remove(&refSkin);
			_comm.refDataVersion.remove(&refDataVersion);
			_comm.refScenario.remove(&refScenario);
			_comm.refEventTree.remove(&refEventTree);
			_comm.delEventTree.remove(&refEventTree);
			_comm.refRadarStyle.remove(&initUseMod);
			static if (is(C:ItemCard)) {
				_comm.refRadarStyle.remove(&initHasMod);
			}
		}
	}
public:
	this(Commons comm, Props prop, Shell shell, Summary summ, C card, bool readOnly) { mixin(S_TRACE);
		assert (summ !is null);
		_comm = comm;
		_summ = summ;
		_card = card;
		_prop = prop;
		_readOnly = readOnly ? SWT.READ_ONLY : SWT.NONE;
		if (_readOnly) _summSkin = findSkin(_comm, _prop, _summ);
		static if (is (C == SkillCard)) {
			string text = _card ? .tryFormat(_prop.msgs.dlgTitSkill, _card.name) : _prop.msgs.dlgTitNewSkill;
			auto img = _prop.images.skill;
			auto size = _prop.var.skillCardDlg;
		} else static if (is (C == ItemCard)) {
			string text = _card ? .tryFormat(_prop.msgs.dlgTitItem, _card.name) : _prop.msgs.dlgTitNewItem;
			auto img = _prop.images.item;
			auto size = _prop.var.itemCardDlg;
		} else static if (is (C == BeastCard)) {
			string text = _card ? .tryFormat(_prop.msgs.dlgTitBeast, _card.name) : _prop.msgs.dlgTitNewBeast;
			auto img = _prop.images.beast;
			auto size = _prop.var.beastCardDlg;
		} else { mixin(S_TRACE);
			static assert (0);
		}
		super(prop, shell, _readOnly, false, text, img, true, size, true);
	}

	@property
	override
	C card() { mixin(S_TRACE);
		return _card;
	}
	@property
	void card(C v) { mixin(S_TRACE);
		_card = v;
	}

	bool openCWXPath(string path, bool shellActivate) { mixin(S_TRACE);
		return _motions.openCWXPath(path, shellActivate);
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(windowGridLayout(1));
		auto tabf = new CTabFolder(area, SWT.BORDER);

		constructMain(tabf);
		constructDesc(tabf);
		constructApt(tabf);
		constructUseModify(tabf);
		static if (is (C == ItemCard)) {
			constructHaveModify(tabf);
		}
		constructMotion(tabf);
		constructProps(tabf);
		constructKeyCode(tabf);

		refDataVersion();

		static if (is(C : SkillCard)) {
			_comm.delSkill.add(&delCard);
		} else static if (is(C : ItemCard)) {
			_comm.delItem.add(&delCard);
		} else static if (is(C : BeastCard)) {
			_comm.delBeast.add(&delCard);
		} else static assert (0);
		_comm.refSkin.add(&refSkin);
		_comm.refDataVersion.add(&refDataVersion);
		_comm.refScenario.add(&refScenario);
		_comm.refEventTree.add(&refEventTree);
		_comm.delEventTree.add(&refEventTree);
		_comm.refRadarStyle.add(&initUseMod);
		static if (is(C:ItemCard)) {
			_comm.refRadarStyle.add(&initHasMod);
		}
		area.addDisposeListener(new Dispose);

		// Windows Vistaだとタブの横幅が凄いことになったので必要最低限にする。
		scope maxSize = new Point(0, 0);
		foreach (tab; tabf.getItems()) { mixin(S_TRACE);
			scope size = tab.getControl().computeSize(SWT.DEFAULT, SWT.DEFAULT);
			if (maxSize.x < size.x) maxSize.x = size.x;
			if (maxSize.y < size.y) maxSize.y = size.y;
		}
		scope rect = tabf.computeTrim(SWT.DEFAULT, SWT.DEFAULT, maxSize.x, maxSize.y);
		auto gd = new GridData(GridData.FILL_BOTH);
		gd.widthHint = rect.width;
		gd.heightHint = rect.height;
		tabf.setLayoutData(gd);

		refCard(_card);
	}
	private void refCard(C card) { mixin(S_TRACE);
		if (_card && _card !is card) return;
		ignoreMod = true;
		scope (exit) ignoreMod = false;
		auto skin = summSkin;
		if (_card) { mixin(S_TRACE);
			_imgPath.images = _card.paths;
			_desc.setText(_card.desc);
			_scenario.setText(_card.scenario);
			_author.setText(_card.author);
			_name.setText(_card.name);
			_needSpell.setSelection(_card.spell);
			_effTyp[_card.effectType].setSelection(true);
			_res[_card.resist].setSelection(true);
			_phy[_card.physical].setSelection(true);
			_mtl[_card.mental].setSelection(true);
			static if (is (C == SkillCard)) {
				_level.setSelection(_card.level);
			}
			static if (is (C == ItemCard)) {
				_useCount.setSelection(_card.useLimitMax);
				static if (SetUseCountCur) {
					_useCountCur.setSelection(_card.useLimit);
					_useCountIsMax.setSelection(_card.useLimit == _card.useLimitMax);
					_useCountCur.setEnabled(!_readOnly && !_useCountIsMax.getSelection());
					updateUseLimitMax();
				}
			} else static if (is (C == BeastCard)) {
				_useCount.setSelection(_card.useLimit);
			}
			static if (is (C == ItemCard)) {
				_price.setSelection(_card.price);
			}
			_motions.motions = _card.motions;
			foreach (e, index; _useModTbl) { mixin(S_TRACE);
				if (_useModR) { mixin(S_TRACE);
					_useModR.setValue(index, _card.enhance(e));
				} else { mixin(S_TRACE);
					_useModS.setValue(index, _card.enhance(e));
				}
			}
			static if (is (C == ItemCard)) {
				foreach (e, index; _hasModTbl) { mixin(S_TRACE);
					if (_hasModR) { mixin(S_TRACE);
						_hasModR.setValue(index, _card.enhanceOwner(e));
					} else { mixin(S_TRACE);
						_hasModS.setValue(index, _card.enhanceOwner(e));
					}
				}
			}
			_targ[_card.target].setSelection(true);
			_one.setSelection(!_card.allRange);
			_all.setSelection(_card.allRange);
			refreshEnblOneAll();
			_vis[_card.visual].setSelection(true);
			_prem[_card.premium].setSelection(true);
			_sucRate.setSelection(_card.successRate + Content.successRate_max);
			string findPath(string path) { mixin(S_TRACE);
				return baseName(skin.findPath(baseName(path), skin.extSound, skin.seDir, ""));
			}
			_se1.path = _card.soundPath1;
			_se1.volume = _card.volume1;
			_se1.loopCount = _card.loopCount1;
			_se2.path = _card.soundPath2;
			_se2.volume = _card.volume2;
			_se2.loopCount = _card.loopCount2;
			_keyCodes.keyCodes = _card.keyCodes;
			refreshWarning();
		} else { mixin(S_TRACE);
			_imgPath.images = [];
			_scenario.setText(_summ.scenarioName);
			_author.setText(_summ.author);
			_effTyp[EffectType.PHYSIC].setSelection(true);
			_res[Resist.AVOID].setSelection(true);
			_phy[Physical.DEX].setSelection(true);
			_mtl[Mental.AGGRESSIVE].setSelection(true);
			static if (is (C == SkillCard)) {
				_level.setSelection(1);
			}
			foreach (e, index; _useModTbl) { mixin(S_TRACE);
				if (_useModR) { mixin(S_TRACE);
					_useModR.setValue(index, 0);
				} else { mixin(S_TRACE);
					_useModS.setValue(index, 0);
				}
			}
			static if (is (C == ItemCard)) {
				foreach (e, index; _hasModTbl) { mixin(S_TRACE);
					if (_hasModR) { mixin(S_TRACE);
						_hasModR.setValue(index, 0);
					} else { mixin(S_TRACE);
						_hasModS.setValue(index, 0);
					}
				}
			}
			_targ[CardTarget.NONE].setSelection(true);
			_one.setSelection(true);
			refreshEnblOneAll();
			_vis[CardVisual.NONE].setSelection(true);
			_prem[Premium.NORMAL].setSelection(true);
			_sucRate.setSelection(Content.successRate_max);
			_se1.path = "";
			_se2.path = "";
		}
		static if (is (C == SkillCard)) {
			calcPrice(_level.getSelection());
		} else static if (is (C == BeastCard)) {
			calcPrice(_useCount.getSelection());
		}
	}
	private void refreshEnblOneAll() { mixin(S_TRACE);
		_oneAllGrp.setEnabled(_targ[CardTarget.PARTY].getSelection()
			|| _targ[CardTarget.ENEMY].getSelection()
			|| _targ[CardTarget.BOTH].getSelection());
		_one.setEnabled(!_readOnly && _oneAllGrp.getEnabled());
		_all.setEnabled(!_readOnly && _oneAllGrp.getEnabled());
	}

	override bool apply() { mixin(S_TRACE);
		auto images = _imgPath.materialPath;
		if (images.cancel) return false;
		if (_card) { mixin(S_TRACE);
			_card.paths = images.images;
			_card.desc = wrapReturnCode(_desc.getText());
			_card.name = _name.getText();
		} else { mixin(S_TRACE);
			_card = new C(_summ.newId!(C), _name.getText(),
				images.images, wrapReturnCode(_desc.getText()));
		}
		_card.spell = _needSpell.getSelection();
		putRadioValue!(EffectType)(_effTyp, &_card.effectType);
		putRadioValue!(Resist)(_res, &_card.resist);
		putRadioValue!(Physical)(_phy, &_card.physical);
		putRadioValue!(Mental)(_mtl, &_card.mental);
		static if (is (C == SkillCard)) {
			_card.level = _level.getSelection();
		}
		static if (is (C == ItemCard)) {
			_card.useLimitMax = _useCount.getSelection();
			static if (SetUseCountCur) {
				_card.useLimit = _useCountCur.getSelection();
			} else { mixin(S_TRACE);
				_card.useLimit = _card.useLimitMax;
			}
		} else static if (is (C == BeastCard)) {
			_card.useLimit = _useCount.getSelection();
		}
		static if (is (C == ItemCard)) {
			_card.price = _price.getSelection();
		}
		_card.motions = _motions.motions;
		foreach (e, index; _useModTbl) { mixin(S_TRACE);
			if (_useModR) { mixin(S_TRACE);
				_card.enhance(e, _useModR.getValue(index));
			} else { mixin(S_TRACE);
				_card.enhance(e, _useModS.getValue(index));
			}
		}
		static if (is (C == ItemCard)) {
			foreach (e, index; _hasModTbl) { mixin(S_TRACE);
				if (_hasModR) { mixin(S_TRACE);
					_card.enhanceOwner(e, _hasModR.getValue(index));
				} else { mixin(S_TRACE);
					_card.enhanceOwner(e, _hasModS.getValue(index));
				}
			}
		}
		putRadioValue!(CardTarget)(_targ, &_card.target);
		_card.allRange = _oneAllGrp.isEnabled() && _all.getSelection();
		putRadioValue!(CardVisual)(_vis, &_card.visual);
		putRadioValue!(Premium)(_prem, &_card.premium);
		_card.successRate = cast(int) _sucRate.getSelection() - Content.successRate_max;
		_card.soundPath1 = _se1.path;
		_card.volume1 = _se1.volume;
		_card.loopCount1 = _se1.loopCount;
		_card.soundPath2 = _se2.path;
		_card.volume2 = _se2.volume;
		_card.loopCount2 = _se2.loopCount;
		_card.scenario = _scenario.getText();
		_card.author = _author.getText();
		_card.keyCodes = _keyCodes.keyCodes;

		_comm.refKeyCodes.call();

		static if (is (C == SkillCard)) {
			string text = .tryFormat(_prop.msgs.dlgTitSkill, _card.name);
		} else static if (is (C == ItemCard)) {
			string text = .tryFormat(_prop.msgs.dlgTitItem, _card.name);
		} else static if (is (C == BeastCard)) {
			string text = .tryFormat(_prop.msgs.dlgTitBeast, _card.name);
		} else { mixin(S_TRACE);
			static assert (0);
		}
		getShell().setText(text);
		return true;
	}
}
