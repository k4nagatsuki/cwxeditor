
module cwx.editor.gui.dwt.effectcarddialog;

import cwx.summary;
import cwx.card;
import cwx.types;
import cwx.motion;
import cwx.utils;
import cwx.skin;
import cwx.event;
import cwx.imagesize;

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

import std.algorithm : max;
import std.path;

import org.eclipse.swt.all;

import java.lang.all;

public:

/// 手札カードの設定を行うダイアログ。
class EffectCardDialog(C) : AbsDialog {
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
		void calcPrice(int value) {
			_price.setMinimum(_prop.looks.skillPrice(value));
			_price.setMaximum(_prop.looks.skillPrice(value));
			_price.setSelection(_prop.looks.skillPrice(value));
		}
		int priceCancel(int oldVal) {
			calcPrice(oldVal);
			return oldVal;
		}
	}
	static if (is (C == ItemCard)) {
		Spinner _useCount;
		static if (SetUseCountCur) {
			Spinner _useCountCur;
			Button _useCountIsMax;
			void updateUseLimitMax() {
				_useCountCur.setMaximum(_useCount.getSelection());
				if (_useCountIsMax.getSelection()) {
					_useCountCur.setSelection(_useCount.getSelection());
				}
			}
		}
	}
	static if (is (C == BeastCard)) {
		Spinner _useCount;
		void calcPrice(int value) {
			_price.setMinimum(_prop.looks.beastPrice);
			_price.setMaximum(_prop.looks.beastPrice);
			_price.setSelection(_prop.looks.beastPrice);
		}
		int priceCancel(int oldVal) {
			calcPrice(oldVal);
			return oldVal;
		}
	}
	Spinner _price;
	MotionView _motions;
	Composite _useModParent;
	RadarSpinner _useModR;
	Scales _useModS;
	int[Enhance] _useModTbl;
	static if (is (C == ItemCard)) {
		Composite _hasModParent;
		RadarSpinner _hasModR;
		Scales _hasModS;
		int[Enhance] _hasModTbl;
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
	Combo[] _keyCodes;
	Text _scenario;
	TextMenuModify _scenarioTM;
	Text _author;
	TextMenuModify _authorTM;
	class ResetSource : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			ignoreMod = true;
			scope (exit) ignoreMod = false;
			_scenario.setText(_summ.scenarioName);
			_author.setText(_summ.author);
			_scenarioTM.reset();
			_authorTM.reset();
		}
	}
	class ModSource : ModifyListener {
		override void modifyText(ModifyEvent e) {
			refreshWarning();
		}
	}
	void refEventTree(EventTree et) {
		if (et.owner is _card || et.owner is null) {
			refreshWarning();
		}
	}
	void refreshWarning() {
		string[] ws;
		if (_name.over) {
			ws ~= .tryFormat(_prop.msgs.warningNameLenOver, _prop.looks.nameLimit, _prop.looks.nameLimit / 2);
		}
		ws ~= _imgPath.warnings;
		if (_effTyp[EffectType.NONE].getSelection()) {
			ws ~= _prop.msgs.warningEffectTypeNone;
		}
		foreach (m; _motions.motions) {
			if (m.type == MType.VANISH_TARGET && m.element != cast(int) Element.MIRACLE) {
				ws ~= _prop.msgs.warningVanishCast;
				break;
			}
		}
		if ((_se1.path != "" && !_se1.selectedDefDir) || (_se2.path != "" && !_se2.selectedDefDir)) {
			ws ~= _prop.msgs.warningNotDefaultSE;
		}
		if (_card && _card.trees.length) {
			if (_scenario.getText() != _summ.scenarioName || _author.getText() != _summ.author) {
				ws ~= _prop.msgs.diffSource;
			}
		}

		warning = ws;
	}

	class OASelect : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			__refreshEnblOneAll();
		}
	}
	class SelEffectType : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			refreshWarning();
		}
	}

	CTabItem constructMain(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(2, false));
		{
			auto comp2 = new Composite(comp, SWT.NONE);
			comp2.setLayoutData(new GridData(GridData.FILL_BOTH));
			comp2.setLayout(zeroMarginGridLayout(1, false));
			{
				auto grp = new Group(comp2, SWT.NONE);
				grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				grp.setLayout(new GridLayout(2, false));
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
			{
				auto skin = _comm.skin;
				bool including = _card && isBinImg(_card.path);
				_imgPath = new ImageSelect!(MtType.CARD)(comp2, _readOnly, _comm, _prop, _summ,
					_prop.looks.cardSize.width, _prop.looks.cardSize.height, including, true, &_name.getText);
				mod(_imgPath);
				_imgPath.modEvent ~= &refreshWarning;
				_imgPath.widget.setLayoutData(new GridData(GridData.FILL_BOTH));
			}
		}
		{
			auto comp2 = new Composite(comp, SWT.NONE);
			comp2.setLayoutData(new GridData(GridData.FILL_VERTICAL));
			comp2.setLayout(zeroMarginGridLayout(1, false));
			{
				auto grp = new Group(comp2, SWT.NONE);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setLayout(new CenterLayout(SWT.VERTICAL));
				grp.setText(_prop.msgs.needSpellGroup);
				_needSpell = new Button(grp, SWT.CHECK);
				mod(_needSpell);
				_needSpell.setEnabled(!_readOnly);
				_needSpell.setText(_prop.msgs.needSpell);
			}
			{
				auto grp = new Group(comp2, SWT.NONE);
				grp.setText(_prop.msgs.elementProps);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setLayout(new GridLayout(2, true));
				foreach (i, eff; [EffectType.PHYSIC, EffectType.MAGIC,
						EffectType.MAGICAL_PHYSIC, EffectType.PHYSICAL_MAGIC,
						EffectType.NONE]) {
					auto radio = new Button(grp, SWT.RADIO);
					mod(radio);
					radio.setEnabled(!_readOnly);
					if (2 <= i) {
						auto gd = new GridData(GridData.FILL_BOTH);
						gd.horizontalSpan = 2;
						radio.setLayoutData(gd);
					} else {
						radio.setLayoutData(new GridData(GridData.FILL_BOTH));
					}
					radio.setText(.tryFormat(_prop.msgs.effectTypeElement, _prop.msgs.effectTypeName(eff)));
					radio.setToolTipText(_prop.msgs.effectTypeDesc(eff));
					radio.addSelectionListener(new SelEffectType);
					_effTyp[eff] = radio;
				}
			}
			{
				auto grp = new Group(comp2, SWT.NONE);
				grp.setText(_prop.msgs.resistProps);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setLayout(new GridLayout(2, true));
				foreach (res; [Resist.AVOID, Resist.RESIST, Resist.UNFAIL]) {
					auto radio = new Button(grp, SWT.RADIO);
					mod(radio);
					radio.setEnabled(!_readOnly);
					radio.setLayoutData(new GridData(GridData.FILL_BOTH));
					radio.setText(_prop.msgs.resistName(res));
					radio.setToolTipText(_prop.msgs.resistDesc(res));
					_res[res] = radio;
				}
			}
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.card);
		tab.setControl(comp);
		return tab;
	}
	CTabItem constructDesc(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, true));
		auto top = new Composite(comp, SWT.NONE);
		top.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		top.setLayout(zeroMarginGridLayout(2, false));
		static if (is (C == SkillCard)) {
			{
				auto grp = new Group(top, SWT.NONE);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setLayout(new CenterLayout);
				grp.setText(_prop.msgs.skillLevel);
				auto comp2 = new Composite(grp, SWT.NONE);
				comp2.setLayout(new GridLayout(2, false));
				_level = new Spinner(comp2, SWT.BORDER | _readOnly);
				mod(_level);
				_level.setMaximum(_prop.var.etc.skillLevelMax);
				_level.setMinimum(0);
				auto l = new Label(comp2, SWT.NONE);
				l.setText(.tryFormat(_prop.msgs.rangeHint, 0, _prop.var.etc.skillLevelMax));
			}
		} else static if (is (C == ItemCard) || is (C == BeastCard)) {
			{
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
					mod(_useCountCur);
					_useCountCur.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
					_useCountCur.setMaximum(_prop.var.etc.useCountMax);
					_useCountCur.setMinimum(0);
					_useCountIsMax = new Button(comp2, SWT.CHECK);
					_useCountIsMax.setEnabled(!_readOnly);
					_useCountIsMax.setText(_prop.msgs.useCountIsMax);
					.listener(_useCountIsMax, SWT.Selection, {
						_useCountCur.setEnabled(!_readOnly && !_useCountIsMax.getSelection());
						if (_useCountIsMax.getSelection()) {
							_useCountCur.setSelection(_useCount.getSelection());
						}
					});
				} else {
					comp2.setLayout(new GridLayout(2, false));
					_useCount = new Spinner(comp2, SWT.BORDER | _readOnly);
					mod(_useCount);
					_useCount.setMaximum(_prop.var.etc.useCountMax);
					_useCount.setMinimum(0);
					auto l = new Label(comp2, SWT.NONE);
					l.setText(.tryFormat(_prop.msgs.useCountRange, _prop.var.etc.useCountMax));
				}
			}
		} else {
			static assert (0);
		}
		{
			auto grp = new Group(top, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(new CenterLayout);
			grp.setText(_prop.msgs.price);
			auto comp2 = new Composite(grp, SWT.NONE);
			comp2.setLayout(new GridLayout(2, false));
			static if (is (C == SkillCard) || is (C == BeastCard)) {
				_price = new Spinner(comp2, SWT.BORDER | SWT.READ_ONLY);
				_price.setMaximum(_prop.var.etc.priceMax);
				static if (is (C == SkillCard)) {
					new SpinnerEdit(_level, &calcPrice, &calcPrice, &priceCancel);
				} else static if (is (C == BeastCard)) {
					new SpinnerEdit(_useCount, &calcPrice, &calcPrice, &priceCancel);
				} else {
					static assert (0);
				}
				auto l = new Label(comp2, SWT.NONE);
				l.setText(_prop.msgs.priceAuto);
			} else static if (is (C == ItemCard)) {
				_price = new Spinner(comp2, SWT.BORDER | _readOnly);
				mod(_price);
				_price.setMaximum(_prop.var.etc.priceMax);
				_price.setMinimum(0);
				auto l = new Label(comp2, SWT.NONE);
				l.setText(.tryFormat(_prop.msgs.rangeHint, 0, _prop.var.etc.priceMax));
			} else {
				static assert (0);
			}
		}
		{
			auto grp = new Group(comp, SWT.NONE);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.horizontalSpan = 2;
			grp.setLayoutData(gd);
			grp.setLayout(new CenterLayout(SWT.HORIZONTAL));
			grp.setText(_prop.msgs.desc);
			_desc = new FixedWidthText(dwtData(_prop.looks.cardDescFont(_summ.legacy)), _prop.looks.cardDescLen, grp, SWT.BORDER | _readOnly);
			mod(_desc.widget);
			createTextMenu!Text(_comm, _prop, _desc.widget, &catchMod);
			_desc.widget.setLayoutData(_desc.computeTextBaseSize(_prop.looks.cardDescLine));
		}
		{
			auto grp = new Group(comp, SWT.NONE);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.horizontalSpan = 2;
			grp.setLayoutData(gd);
			grp.setLayout(new GridLayout(2, false));
			grp.setText(_prop.msgs.source);
			Text createLine(string title, out TextMenuModify tm) {
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
	CTabItem constructApt(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(2, false));
		{
			auto grp = new Group(comp, SWT.NONE);
			grp.setText(_prop.msgs.aptPhysical);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto cl = new CenterLayout(SWT.HORIZONTAL, 0);
			cl.fillVertical = true;
			grp.setLayout(cl);
			auto comp2 = new Composite(grp, SWT.NONE);
			comp2.setLayout(new GridLayout(1, true));
			foreach (phy; [Physical.DEX, Physical.AGL, Physical.INT,
					Physical.STR, Physical.VIT, Physical.MIN]) {
				auto radio = new Button(comp2, SWT.RADIO);
				mod(radio);
				radio.setEnabled(!_readOnly);
				radio.setLayoutData(new GridData(GridData.FILL_VERTICAL));
				radio.setText(_prop.msgs.physicalName(phy));
				_phy[phy] = radio;
			}
		}
		{
			auto grp = new Group(comp, SWT.NONE);
			grp.setText(_prop.msgs.aptMental);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto cl = new CenterLayout(SWT.HORIZONTAL, 0);
			cl.fillVertical = true;
			grp.setLayout(cl);
			auto comp2 = new Composite(grp, SWT.NONE);
			auto gl = new GridLayout(2, true);
			gl.horizontalSpacing = 15;
			comp2.setLayout(gl);
			static const Ms = [Mental.AGGRESSIVE, Mental.UNAGGRESSIVE,
				Mental.CHEERFUL, Mental.UNCHEERFUL,
				Mental.BRAVE, Mental.UNBRAVE, Mental.CAUTIOUS, Mental.UNCAUTIOUS,
				Mental.TRICKISH, Mental.UNTRICKISH];
			foreach (i, m; Ms) {
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
	Composite createModParent(Composite comp, string title) {
		auto grp = new Group(comp, SWT.NONE);
		grp.setText(title);
		grp.setLayoutData(new GridData(GridData.FILL_BOTH));
		auto cl = new CenterLayout;
		cl.fillHorizontal = true;
		cl.fillVertical = true;
		grp.setLayout(cl);
		return grp;
	}
	void createMod(Composite parent, ref int[Enhance] tbl, ref RadarSpinner useModR, ref Scales useModS) {
		int[] values = [];
		if (useModR) {
			values = useModR.getValues();
			useModR.dispose();
			useModR = null;
		}
		if (useModS) {
			values = useModS.getValues();
			useModS.dispose();
			useModS = null;
		}

		static const Es = [Enhance.AVOID, Enhance.RESIST, Enhance.DEFENSE];
		string[] names;
		names.length = Es.length;
		foreach (i, enh; Es) {
			tbl[enh] = i;
			names[i] = .tryFormat(_prop.msgs.enhanceBonus, _prop.msgs.enhanceName(enh));
		}

		int stepC = _prop.var.etc.enhanceMax * 2 + 1;
		int min = cast(int) _prop.var.etc.enhanceMax * -1;
		int page = _prop.var.etc.enhanceMax / 2;
		if (_prop.var.etc.radarStyleParams) {
			useModR = new RadarSpinner(parent, _readOnly);
			useModR.setRadar(stepC, names, min);
			useModR.antialias = true;
			useModR.borderlines = [0];
			useModR.lineStep = page;
			if (values.length) useModR.setValues(values);
			mod(useModR);
		} else {
			useModS = new Scales(parent, _readOnly);
			useModS.setScales(stepC, names, page, min);
			useModS.borderlines = [0];
			if (values.length) useModS.setValues(values);
			mod(useModS);
		}
		parent.layout();
	}
	void initUseMod() {
		createMod(_useModParent, _useModTbl, _useModR, _useModS);
	}
	CTabItem constructUseModify(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(2, false));
		{
			_useModParent = createModParent(comp, _prop.msgs.useModify);
			initUseMod();
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.useBonus);
		tab.setControl(comp);
		return tab;
	}
	static if (is (C == ItemCard)) {
		void initHasMod() {
			createMod(_hasModParent, _hasModTbl, _hasModR, _hasModS);
		}
		CTabItem constructHaveModify(CTabFolder tabf) {
			auto comp = new Composite(tabf, SWT.NONE);
			comp.setLayout(new GridLayout(2, false));
			{
				_hasModParent = createModParent(comp, _prop.msgs.haveModify);
				initHasMod();
			}
			auto tab = new CTabItem(tabf, SWT.NONE);
			tab.setText(_prop.msgs.haveBonus);
			tab.setControl(comp);
			return tab;
		}
	}
	CTabItem constructMotion(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, false));
		{
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
	CTabItem constructProps(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, false));
		{
			auto tcomp = new Composite(comp, SWT.NONE);
			tcomp.setLayoutData(new GridData(GridData.FILL_BOTH));
			tcomp.setLayout(zeroMarginGridLayout(2, false));
			{
				auto comp2 = new Composite(tcomp, SWT.NONE);
				auto gd = new GridData(GridData.FILL_BOTH);
				gd.verticalSpan = 2;
				comp2.setLayoutData(gd);
				comp2.setLayout(zeroMarginGridLayout(1, false));
				{
					auto grp = new Group(comp2, SWT.NONE);
					grp.setText(_prop.msgs.effectTarget);
					grp.setLayoutData(new GridData(GridData.FILL_BOTH));
					auto cl = new CenterLayout(SWT.HORIZONTAL, 0);
					cl.fillVertical = true;
					grp.setLayout(cl);
					auto comp3 = new Composite(grp, SWT.NONE);
					comp3.setLayout(new GridLayout(2, false));
					foreach (t; [CardTarget.NONE, CardTarget.USER,
							CardTarget.PARTY, CardTarget.ENEMY, CardTarget.BOTH]) {
						auto radio = new Button(comp3, SWT.RADIO);
						mod(radio);
						radio.setEnabled(!_readOnly);
						radio.setLayoutData(new GridData(GridData.FILL_BOTH));
						radio.setText(_prop.msgs.cardTargetName(t));
						radio.addSelectionListener(new OASelect);
						_targ[t] = radio;
					}
				}
				{
					auto grp = new Group(comp2, SWT.NONE);
					grp.setText(_prop.msgs.effectRange);
					grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
					auto cl = new CenterLayout;
					cl.fillVertical = true;
					grp.setLayout(cl);
					auto comp3 = new Composite(grp, SWT.NONE);
					comp3.setLayout(new GridLayout(2, false));
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
			{
				auto grp = new Group(tcomp, SWT.NONE);
				grp.setText(_prop.msgs.effectVisual);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setLayout(new GridLayout(2, false));
				foreach (v; [CardVisual.NONE, CardVisual.HORIZONTAL,
						CardVisual.REVERSE, CardVisual.VERTICAL]) {
					auto radio = new Button(grp, SWT.RADIO);
					mod(radio);
					radio.setEnabled(!_readOnly);
					radio.setLayoutData(new GridData(GridData.FILL_BOTH));
					radio.setText(_prop.msgs.cardVisualName(v));
					_vis[v] = radio;
				}
			}
			{
				auto grp = new Group(tcomp, SWT.NONE);
				grp.setText(_prop.msgs.cardPremium);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setLayout(new GridLayout(1, false));
				foreach (p; [Premium.NORMAL, Premium.RARE, Premium.PREMIUM]) {
					auto radio = new Button(grp, SWT.RADIO);
					mod(radio);
					radio.setEnabled(!_readOnly);
					radio.setLayoutData(new GridData(GridData.FILL_BOTH));
					radio.setText(_prop.msgs.premiumName(p));
					_prem[p] = radio;
				}
			}
		}
		{
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
	CTabItem constructKeyCode(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, true));
		auto sash = new SplitPane(comp, SWT.HORIZONTAL);
		sash.setLayoutData(new GridData(GridData.FILL_BOTH));
		auto skin = _comm.skin;
		{
			auto grp = new Group(sash, SWT.NONE);
			grp.setText(_prop.msgs.se);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(new GridLayout(1, false));
			MaterialSelect!(MtType.SE, Combo, Combo) createSE(string title) {
				auto comp = new Composite(grp, SWT.NONE);
				comp.setLayoutData(new GridData(GridData.FILL_BOTH));
				comp.setLayout(zeroMarginGridLayout(2, true));

				auto l = new CLabel(comp, SWT.NONE);
				auto gdl = new GridData(GridData.FILL_HORIZONTAL);
				gdl.horizontalSpan = 2;
				l.setLayoutData(gdl);
				l.setImage(_prop.images.sound);
				l.setText(title);

				auto se = new MaterialSelect!(MtType.SE, Combo, Combo)(_comm, _prop, _summ, _readOnly != 0, null, [_prop.msgs.soundNone]);
				mod(se);
				se.modEvent ~= &refreshWarning;
				auto gddc = new GridData(GridData.FILL_HORIZONTAL);
				gddc.horizontalSpan = 2;
				se.createDirsCombo(comp).setLayoutData(gddc);
				auto gdfl = new GridData(GridData.FILL_HORIZONTAL);
				gdfl.horizontalSpan = 2;
				se.createFileList(comp).setLayoutData(gdfl);
				se.createStopButton(comp).setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				se.createPlayButton(comp).setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				return se;
			}
			_se1 = createSE(_prop.msgs.se1);
			_se2 = createSE(_prop.msgs.se2);
		}
		{
			auto grp = new Group(sash, SWT.NONE);
			grp.setText(_prop.msgs.keyCodes);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			_keyCodes.length = _prop.looks.keyCodesMax;
			grp.setLayout(new GridLayout(_keyCodes.length >= 8 ? 2 : 1, true));
			for (int i = 0; i < _keyCodes.length; i++) {
				_keyCodes[i] = createKeyCodeCombo(_comm, grp, &catchMod);
				mod(_keyCodes[i]);
				_keyCodes[i].setEnabled(!_readOnly);
				_keyCodes[i].setLayoutData(new GridData(GridData.FILL_BOTH));
			}
			setKeyCodesEnabled();
		}
		sash.setWeights([_prop.var.etc.seKeyCodeSashL, _prop.var.etc.seKeyCodeSashR]);
		class Dispose : DisposeListener {
			override void widgetDisposed(DisposeEvent e) {
				auto ws = sash.getWeights();
				_prop.var.etc.seKeyCodeSashL = ws[0];
				_prop.var.etc.seKeyCodeSashR = ws[1];
			}
		}
		sash.addDisposeListener(new Dispose);

		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.seAndKeyCode);
		tab.setControl(comp);
		return tab;
	}
	void delCard(C c) {
		if (_card is c) {
			forceCancel();
		}
	}
	void refScenario(Summary summ) {
		forceCancel();
	}
	void refSkin() {
		_desc.font = dwtData(_prop.looks.cardDescFont(_summ.legacy));
		setKeyCodesEnabled();
	}
	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			static if (is(C : SkillCard)) {
				_comm.delSkill.remove(&delCard);
			} else static if (is(C : ItemCard)) {
				_comm.delItem.remove(&delCard);
			} else static if (is(C : BeastCard)) {
				_comm.delBeast.remove(&delCard);
			} else static assert (0);
			_comm.refSkin.remove(&refSkin);
			_comm.refScenario.remove(&refScenario);
			_comm.refEventTree.remove(&refEventTree);
			_comm.delEventTree.remove(&refEventTree);
			_comm.refRadarStyle.remove(&initUseMod);
			static if (is(C:ItemCard)) {
				_comm.refRadarStyle.remove(&initHasMod);
			}
		}
	}
	void setKeyCodesEnabled() {
		int big = max(_prop.looks.keyCodesMaxLegacy, _prop.looks.keyCodesMax);
		foreach (i, kc; _keyCodes) {
			if (_summ.legacy) {
				kc.setEnabled(!_readOnly && i < _prop.looks.keyCodesMaxLegacy);
			} else {
				kc.setEnabled(!_readOnly && i < _prop.looks.keyCodesMax);
			}
		}
	}
public:
	this(Commons comm, Props prop, Shell shell, Summary summ, C card) {
		assert (summ !is null);
		_comm = comm;
		_summ = summ;
		_card = card;
		_prop = prop;
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
		} else {
			static assert (0);
		}
		super(prop, shell, _readOnly, false, text, img, true, size, true);
	}

	@property
	C card() {
		return _card;
	}
	@property
	void card(C v) {
		_card = v;
	}

	bool openCWXPath(string path, bool shellActivate) {
		return _motions.openCWXPath(path, shellActivate);
	}
protected:
	override void setup(Composite area) {
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

		static if (is(C : SkillCard)) {
			_comm.delSkill.add(&delCard);
		} else static if (is(C : ItemCard)) {
			_comm.delItem.add(&delCard);
		} else static if (is(C : BeastCard)) {
			_comm.delBeast.add(&delCard);
		} else static assert (0);
		_comm.refSkin.add(&refSkin);
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
		foreach (tab; tabf.getItems()) {
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
	private void refCard(C card) {
		if (_card && _card !is card) return;
		ignoreMod = true;
		scope (exit) ignoreMod = false;
		auto skin = _comm.skin;
		if (_card) {
			_imgPath.image = _card.path;
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
			foreach (e, index; _useModTbl) {
				if (_useModR) {
					_useModR.setValue(index, _card.enhance(e));
				} else {
					_useModS.setValue(index, _card.enhance(e));
				}
			}
			static if (is (C == ItemCard)) {
				foreach (e, index; _hasModTbl) {
					if (_hasModR) {
						_hasModR.setValue(index, _card.enhanceOwner(e));
					} else {
						_hasModS.setValue(index, _card.enhanceOwner(e));
					}
				}
			}
			_targ[_card.target].setSelection(true);
			_one.setSelection(!_card.allRange);
			_all.setSelection(_card.allRange);
			__refreshEnblOneAll();
			_vis[_card.visual].setSelection(true);
			_prem[_card.premium].setSelection(true);
			_sucRate.setSelection(_card.successRate + Content.successRate_max);
			string findPath(string path) {
				return baseName(skin.findPath(baseName(path), skin.extSound, skin.seDir, ""));
			}
			_se1.path = _card.soundPath1;
			_se2.path = _card.soundPath2;
			foreach (i, kc; _card.keyCodes) {
				_keyCodes[i].setText(kc);
				if (!contains(_keyCodes[i].getItems(), kc)) {
					_keyCodes[i].add(kc, 0);
				}
			}
			refreshWarning();
		} else {
			_imgPath.image = "";
			_scenario.setText(_summ.scenarioName);
			_author.setText(_summ.author);
			_effTyp[EffectType.PHYSIC].setSelection(true);
			_res[Resist.AVOID].setSelection(true);
			_phy[Physical.DEX].setSelection(true);
			_mtl[Mental.AGGRESSIVE].setSelection(true);
			static if (is (C == SkillCard)) {
				_level.setSelection(1);
			}
			foreach (e, index; _useModTbl) {
				if (_useModR) {
					_useModR.setValue(index, 0);
				} else {
					_useModS.setValue(index, 0);
				}
			}
			static if (is (C == ItemCard)) {
				foreach (e, index; _hasModTbl) {
					if (_hasModR) {
						_hasModR.setValue(index, 0);
					} else {
						_hasModS.setValue(index, 0);
					}
				}
			}
			_targ[CardTarget.NONE].setSelection(true);
			_one.setSelection(true);
			__refreshEnblOneAll();
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
	private void __refreshEnblOneAll() {
		_oneAllGrp.setEnabled(_targ[CardTarget.PARTY].getSelection()
			|| _targ[CardTarget.ENEMY].getSelection()
			|| _targ[CardTarget.BOTH].getSelection());
		_one.setEnabled(!_readOnly && _oneAllGrp.getEnabled());
		_all.setEnabled(!_readOnly && _oneAllGrp.getEnabled());
	}

	override bool apply() {
		if (_card) {
			_card.path = _imgPath.image;
			_card.desc = wrapReturnCode(_desc.getText());
			_card.name = _name.getText();
		} else {
			_card = new C(_summ.newId!(C), _name.getText(),
				_imgPath.image, wrapReturnCode(_desc.getText()));
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
			} else {
				_card.useLimit = _card.useLimitMax;
			}
		} else static if (is (C == BeastCard)) {
			_card.useLimit = _useCount.getSelection();
		}
		static if (is (C == ItemCard)) {
			_card.price = _price.getSelection();
		}
		_card.motions = _motions.motions;
		foreach (e, index; _useModTbl) {
			if (_useModR) {
				_card.enhance(e, _useModR.getValue(index));
			} else {
				_card.enhance(e, _useModS.getValue(index));
			}
		}
		static if (is (C == ItemCard)) {
			foreach (e, index; _hasModTbl) {
				if (_hasModR) {
					_card.enhanceOwner(e, _hasModR.getValue(index));
				} else {
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
		_card.soundPath2 = _se2.path;
		string[] keyCodes;
		int last = 0;
		foreach (i, c; _keyCodes) {
			keyCodes ~= c.getText();
			if (c.getText().length > 0) last = i + 1;
		}
		keyCodes.length = last;
		_card.scenario = _scenario.getText();
		_card.author = _author.getText();
		_card.keyCodes = keyCodes;

		_comm.refKeyCodes.call();

		static if (is (C == SkillCard)) {
			string text = .tryFormat(_prop.msgs.dlgTitSkill, _card.name);
		} else static if (is (C == ItemCard)) {
			string text = .tryFormat(_prop.msgs.dlgTitItem, _card.name);
		} else static if (is (C == BeastCard)) {
			string text = .tryFormat(_prop.msgs.dlgTitBeast, _card.name);
		} else {
			static assert (0);
		}
		getShell().setText(text);
		return true;
	}
}
