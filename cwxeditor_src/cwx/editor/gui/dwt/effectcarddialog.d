
module cwx.editor.gui.dwt.effectcarddialog;

import cwx.summary;
import cwx.card;
import cwx.types;
import cwx.motion;
import cwx.utils;
import cwx.skin;

import cwx.editor.gui.sound;

import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.skin;
import cwx.editor.gui.dwt.utils;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.materialselect;
import cwx.editor.gui.dwt.imageselect;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.motionview;
import cwx.editor.gui.dwt.radarspinner;
import cwx.editor.gui.dwt.absdialog;

import std.path;

import dwt.DWT;
import dwt.widgets.Display;
import dwt.widgets.Shell;
import dwt.widgets.Canvas;
import dwt.widgets.Control;
import dwt.widgets.Composite;
import dwt.widgets.Combo;
import dwt.widgets.Label;
import dwt.widgets.Group;
import dwt.widgets.Button;
import dwt.widgets.MessageBox;
import dwt.widgets.Spinner;
import dwt.widgets.Scale;
import dwt.widgets.Table;
import dwt.widgets.TableColumn;
import dwt.widgets.TableItem;
import dwt.custom.CTabFolder;
import dwt.custom.CTabItem;
import dwt.custom.CLabel;
import dwt.custom.CTabFolder;
import dwt.custom.CTabItem;
import dwt.custom.StackLayout;
import dwt.layout.GridLayout;
import dwt.layout.GridData;
import dwt.graphics.Image;
import dwt.events.DisposeListener;
import dwt.events.DisposeEvent;
import dwt.events.SelectionAdapter;
import dwt.events.SelectionEvent;
import dwt.dwthelper.utils;

public:

/// 手札カードの設定を行うダイアログ。
class EffectCardDialog(C) : AbsDialog {
private:
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
			_price.setMinimum = _prop.looks.skillPrice(value);
			_price.setMaximum = _prop.looks.skillPrice(value);
			_price.setSelection = _prop.looks.skillPrice(value);
		}
		int priceCancel(int oldVal) {
			calcPrice(oldVal);
			return oldVal;
		}
	}
	static if (is (C == ItemCard)) {
		Spinner _useCount;
	}
	static if (is (C == BeastCard)) {
		Spinner _useCount;
		void calcPrice(int value) {
			_price.setMinimum = _prop.looks.beastPrice;
			_price.setMaximum = _prop.looks.beastPrice;
			_price.setSelection = _prop.looks.beastPrice;
		}
		int priceCancel(int oldVal) {
			calcPrice(oldVal);
			return oldVal;
		}
	}
	Spinner _price;
	MotionView _motions;
	RadarSpinner _useMod;
	int[Enhance] _useModTbl;
	static if (is (C == ItemCard)) {
		RadarSpinner _hasMod;
		int[Enhance] _hasModTbl;
	}
	Button[CardTarget] _targ;
	Button _one;
	Button _all;
	Composite _oneAllGrp;
	Button[CardVisual] _vis;
	Button[Premium] _prem;
	Scale _sucRate;
	Combo _se1;
	Combo _se2;
	Combo[] _keyCodes;

	class OASelect : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			__refreshEnblOneAll;
		}
	}

	CTabItem constructMain(CTabFolder tabf) {
		auto comp = new Composite(tabf, DWT.NONE);
		comp.setLayout = new GridLayout(2, false);
		{
			auto comp2 = new Composite(comp, DWT.NONE);
			comp2.setLayoutData = new GridData(GridData.FILL_BOTH);
			comp2.setLayout = zeroMarginGridLayout(1, false);
			{
				auto grp = new Group(comp2, DWT.NONE);
				grp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				grp.setLayout = new GridLayout(2, false);
				grp.setText = _prop.msgs.name;
				_name = new GBLimitText(_prop.looks.messageFont(_summ.legacy).name,
					_prop.looks.nameLimit, grp, DWT.BORDER);
				auto gd = new GridData(GridData.FILL_HORIZONTAL);
				gd.widthHint = _name.computeSize(DWT.DEFAULT, DWT.DEFAULT).x;
				_name.widget.setLayoutData = gd;
				auto l = new Label(grp, DWT.NONE);
				l.setText = _prop.msgs.nameLimit(_prop.looks.nameLimit);
				checker(_name.widget);
			}
			{
				auto skin = findSkin(_prop, _summ);
				_imgPath = new ImageSelect!(MtType.CARD)(comp2, DWT.NONE, _comm, _prop, _summ,
					_prop.looks.cardSize.width, _prop.looks.cardSize.height, _summ.legacy);
				_imgPath.widget.setLayoutData = new GridData(GridData.FILL_BOTH);
			}
		}
		{
			auto comp2 = new Composite(comp, DWT.NONE);
			comp2.setLayoutData = new GridData(GridData.FILL_VERTICAL);
			comp2.setLayout = zeroMarginGridLayout(1, false);
			{
				auto grp = new Group(comp2, DWT.NONE);
				grp.setLayoutData = new GridData(GridData.FILL_BOTH);
				grp.setLayout = new CenterLayout(DWT.VERTICAL);
				grp.setText = _prop.msgs.needSpellGroup;
				_needSpell = new Button(grp, DWT.CHECK);
				_needSpell.setText = _prop.msgs.needSpell;
			}
			{
				auto grp = new Group(comp2, DWT.NONE);
				grp.setText = _prop.msgs.elementProps;
				grp.setLayoutData = new GridData(GridData.FILL_BOTH);
				grp.setLayout = new GridLayout(2, true);
				foreach (i, eff; [EffectType.PHYSIC, EffectType.MAGIC,
						EffectType.MAGICAL_PHYSIC, EffectType.PHYSICAL_MAGIC,
						EffectType.NONE]) {
					auto radio = new Button(grp, DWT.RADIO);
					if (2 <= i) {
						auto gd = new GridData(GridData.FILL_BOTH);
						gd.horizontalSpan = 2;
						radio.setLayoutData = gd;
					} else {
						radio.setLayoutData = new GridData(GridData.FILL_BOTH);
					}
					radio.setText = _prop.msgs.effectType(eff);
					_effTyp[eff] = radio;
				}
			}
			{
				auto grp = new Group(comp2, DWT.NONE);
				grp.setText = _prop.msgs.resistProps;
				grp.setLayoutData = new GridData(GridData.FILL_BOTH);
				grp.setLayout = new GridLayout(2, true);
				foreach (res; [Resist.AVOID, Resist.RESIST, Resist.UNFAIL]) {
					auto radio = new Button(grp, DWT.RADIO);
					radio.setLayoutData = new GridData(GridData.FILL_BOTH);
					radio.setText = _prop.msgs.resist(res);
					_res[res] = radio;
				}
			}
		}
		auto tab = new CTabItem(tabf, DWT.NONE);
		tab.setText = _prop.msgs.card;
		tab.setControl = comp;
		return tab;
	}
	CTabItem constructDesc(CTabFolder tabf) {
		auto comp = new Composite(tabf, DWT.NONE);
		comp.setLayout = new GridLayout(2, false);
		static if (is (C == SkillCard)) {
			{
				auto grp = new Group(comp, DWT.NONE);
				grp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				grp.setLayout = new CenterLayout;
				grp.setText = _prop.msgs.skillLevel;
				auto comp2 = new Composite(grp, DWT.NONE);
				comp2.setLayout = new GridLayout(2, false);
				_level = new Spinner(comp2, DWT.BORDER);
				_level.setMaximum = _prop.looks.skillLevelMax;
				_level.setMinimum = 0;
				auto l = new Label(comp2, DWT.NONE);
				l.setText = _prop.msgs.rangeHint(0, _prop.looks.skillLevelMax);
			}
		} else static if (is (C == ItemCard) || is (C == BeastCard)) {
			{
				auto grp = new Group(comp, DWT.NONE);
				grp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				grp.setLayout = new CenterLayout;
				grp.setText = _prop.msgs.useCountGroup;
				auto comp2 = new Composite(grp, DWT.NONE);
				comp2.setLayout = new GridLayout(2, false);
				_useCount = new Spinner(comp2, DWT.BORDER);
				_useCount.setMaximum = _prop.looks.useCountMax;
				_useCount.setMinimum = 0;
				auto l = new Label(comp2, DWT.NONE);
				l.setText = _prop.msgs.useCountRange(_prop.looks.useCountMax);
			}
		} else {
			static assert (0);
		}
		{
			auto grp = new Group(comp, DWT.NONE);
			grp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			grp.setLayout = new CenterLayout;
			grp.setText = _prop.msgs.price;
			auto comp2 = new Composite(grp, DWT.NONE);
			comp2.setLayout = new GridLayout(2, false);
			static if (is (C == SkillCard) || is (C == BeastCard)) {
				_price = new Spinner(comp2, DWT.BORDER | DWT.READ_ONLY);
				_price.setMaximum = _prop.looks.priceMax;
				static if (is (C == SkillCard)) {
					new SpinnerEdit(_level, &calcPrice, &calcPrice, &priceCancel);
				} else static if (is (C == BeastCard)) {
					new SpinnerEdit(_useCount, &calcPrice, &calcPrice, &priceCancel);
				} else {
					static assert (0);
				}
				auto l = new Label(comp2, DWT.NONE);
				l.setText = _prop.msgs.priceAuto;
			} else static if (is (C == ItemCard)) {
				_price = new Spinner(comp2, DWT.BORDER);
				_price.setMaximum = _prop.looks.priceMax;
				_price.setMinimum = 0;
				auto l = new Label(comp2, DWT.NONE);
				l.setText = _prop.msgs.rangeHint(0, _prop.looks.priceMax);
			} else {
				static assert (0);
			}
		}
		{
			auto grp = new Group(comp, DWT.NONE);
			auto gd = new GridData(GridData.FILL_BOTH);
			grp.setLayoutData = gd;
			gd.horizontalSpan = 2;
			grp.setLayout = new CenterLayout(DWT.HORIZONTAL);
			grp.setText = _prop.msgs.desc;
			_desc = new FixedWidthText(dwtData(_prop.looks.cardDescFont(_summ.legacy)), _prop.looks.cardDescLen, grp, DWT.BORDER);
			_desc.widget.setLayoutData = _desc.computeTextBaseSize(_prop.looks.cardDescLine);
		}
		auto tab = new CTabItem(tabf, DWT.NONE);
		static if (is (C == SkillCard)) {
			tab.setText = _prop.msgs.levelAndDesc;
		} else static if (is (C == ItemCard) || is (C == BeastCard)) {
			tab.setText = _prop.msgs.useCountAndDesc;
		}
		tab.setControl = comp;
		return tab;
	}
	CTabItem constructApt(CTabFolder tabf) {
		auto comp = new Composite(tabf, DWT.NONE);
		comp.setLayout = new GridLayout(2, false);
		{
			auto grp = new Group(comp, DWT.NONE);
			grp.setText = _prop.msgs.aptPhysical;
			grp.setLayoutData = new GridData(GridData.FILL_BOTH);
			auto cl = new CenterLayout(DWT.HORIZONTAL, 0);
			cl.fillVertical = true;
			grp.setLayout = cl;
			auto comp2 = new Composite(grp, DWT.NONE);
			comp2.setLayout = new GridLayout(1, true);
			foreach (phy; [Physical.DEX, Physical.AGL, Physical.INT,
					Physical.STR, Physical.VIT, Physical.MIN]) {
				auto radio = new Button(comp2, DWT.RADIO);
				radio.setLayoutData = new GridData(GridData.FILL_VERTICAL);
				radio.setText = _prop.msgs.physical(phy);
				_phy[phy] = radio;
			}
		}
		{
			auto grp = new Group(comp, DWT.NONE);
			grp.setText = _prop.msgs.aptMental;
			grp.setLayoutData = new GridData(GridData.FILL_BOTH);
			auto cl = new CenterLayout(DWT.HORIZONTAL, 0);
			cl.fillVertical = true;
			grp.setLayout = cl;
			auto comp2 = new Composite(grp, DWT.NONE);
			auto gl = new GridLayout(2, true);
			gl.horizontalSpacing = 15;
			comp2.setLayout = gl;
			static const Ms = [Mental.AGGRESSIVE, Mental.UNAGGRESSIVE,
				Mental.CHEERFUL, Mental.UNCHEERFUL,
				Mental.BRAVE, Mental.UNBRAVE, Mental.CAUTIOUS, Mental.UNCAUTIOUS,
				Mental.TRICKISH, Mental.UNTRICKISH];
			foreach (i, m; Ms) {
				auto radio = new Button(comp2, DWT.RADIO);
				radio.setLayoutData = new GridData(GridData.FILL_BOTH);
				radio.setText = _prop.msgs.mental(m);
				_mtl[m] = radio;
			}
		}
		auto tab = new CTabItem(tabf, DWT.NONE);
		tab.setText = _prop.msgs.apt;
		tab.setControl = comp;
		return tab;
	}
	RadarSpinner createMod(Composite comp, string title, ref int[Enhance] tbl) {
		auto grp = new Group(comp, DWT.NONE);
		grp.setText = title;
		grp.setLayoutData = new GridData(GridData.FILL_BOTH);
		grp.setLayout = new CenterLayout;
		auto useMod = new RadarSpinner(grp, DWT.NONE);
		static const Es = [Enhance.AVOID, Enhance.RESIST, Enhance.DEFENSE];
		string[] names;
		names.length = Es.length;
		foreach (i, enh; Es) {
			tbl[enh] = i;
			names[i] = _prop.msgs.enhanceBonus(enh);
		}
		useMod.setRadar(_prop.looks.enhanceMax * 2 + 1,
			names, cast(int) _prop.looks.enhanceMax * -1);
		useMod.setRadarSize(_prop.var.etc.enhanceRadarWidth, _prop.var.etc.enhanceRadarHeight);
		useMod.antialias = true;
		useMod.borderlines = [0];
		useMod.lineStep = _prop.looks.enhanceMax / 2;
		return useMod;
	}
	CTabItem constructUseModify(CTabFolder tabf) {
		auto comp = new Composite(tabf, DWT.NONE);
		comp.setLayout = new GridLayout(2, false);
		{
			_useMod = createMod(comp, _prop.msgs.useModify, _useModTbl);
		}
		auto tab = new CTabItem(tabf, DWT.NONE);
		tab.setText = _prop.msgs.useBonus;
		tab.setControl = comp;
		return tab;
	}
	static if (is (C == ItemCard)) {
		CTabItem constructHaveModify(CTabFolder tabf) {
			auto comp = new Composite(tabf, DWT.NONE);
			comp.setLayout = new GridLayout(2, false);
			{
				_hasMod = createMod(comp, _prop.msgs.haveModify, _hasModTbl);
			}
			auto tab = new CTabItem(tabf, DWT.NONE);
			tab.setText = _prop.msgs.haveBonus;
			tab.setControl = comp;
			return tab;
		}
	}
	CTabItem constructMotion(CTabFolder tabf) {
		auto comp = new Composite(tabf, DWT.NONE);
		comp.setLayout = new GridLayout(1, false);
		{
			_motions = new MotionView(_comm, _prop, _summ, comp);
			_motions.setLayoutData = new GridData(GridData.FILL_BOTH);
		}
		auto tab = new CTabItem(tabf, DWT.NONE);
		tab.setControl = comp;
		tab.setText = _prop.msgs.motion;
		return tab;
	}
	CTabItem constructProps(CTabFolder tabf) {
		auto comp = new Composite(tabf, DWT.NONE);
		comp.setLayout = new GridLayout(1, false);
		{
			auto tcomp = new Composite(comp, DWT.NONE);
			tcomp.setLayoutData = new GridData(GridData.FILL_BOTH);
			tcomp.setLayout = zeroMarginGridLayout(2, false);
			{
				auto comp2 = new Composite(tcomp, DWT.NONE);
				auto gd = new GridData(GridData.FILL_BOTH);
				gd.verticalSpan = 2;
				comp2.setLayoutData = gd;
				comp2.setLayout = zeroMarginGridLayout(1, false);
				{
					auto grp = new Group(comp2, DWT.NONE);
					grp.setText = _prop.msgs.effectTarget;
					grp.setLayoutData = new GridData(GridData.FILL_BOTH);
					auto cl = new CenterLayout(DWT.HORIZONTAL, 0);
					cl.fillVertical = true;
					grp.setLayout = cl;
					auto comp3 = new Composite(grp, DWT.NONE);
					comp3.setLayout = new GridLayout(2, false);
					foreach (t; [CardTarget.NONE, CardTarget.USER,
							CardTarget.PARTY, CardTarget.ENEMY, CardTarget.BOTH]) {
						auto radio = new Button(comp3, DWT.RADIO);
						radio.setLayoutData = new GridData(GridData.FILL_BOTH);
						radio.setText = _prop.msgs.cardTarget(t);
						radio.addSelectionListener(new OASelect);
						_targ[t] = radio;
					}
				}
				{
					auto grp = new Group(comp2, DWT.NONE);
					grp.setText = _prop.msgs.effectRange;
					grp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
					auto cl = new CenterLayout;
					cl.fillVertical = true;
					grp.setLayout = cl;
					auto comp3 = new Composite(grp, DWT.NONE);
					comp3.setLayout = new GridLayout(2, false);
					auto one = new Button(comp3, DWT.RADIO);
					one.setLayoutData = new GridData(GridData.FILL_BOTH);
					one.setText = _prop.msgs.cardTargetOne;
					_one = one;
					auto all = new Button(comp3, DWT.RADIO);
					all.setLayoutData = new GridData(GridData.FILL_BOTH);
					all.setText = _prop.msgs.cardTargetAll;
					_all = all;
					_oneAllGrp = grp;
				}
			}
			{
				auto grp = new Group(tcomp, DWT.NONE);
				grp.setText = _prop.msgs.effectVisual;
				grp.setLayoutData = new GridData(GridData.FILL_BOTH);
				grp.setLayout = new GridLayout(2, false);
				foreach (v; [CardVisual.NONE, CardVisual.HORIZONTAL,
						CardVisual.REVERSE, CardVisual.VERTICAL]) {
					auto radio = new Button(grp, DWT.RADIO);
					radio.setLayoutData = new GridData(GridData.FILL_BOTH);
					radio.setText = _prop.msgs.cardVisual(v);
					_vis[v] = radio;
				}
			}
			{
				auto grp = new Group(tcomp, DWT.NONE);
				grp.setText = _prop.msgs.cardPremium;
				grp.setLayoutData = new GridData(GridData.FILL_BOTH);
				grp.setLayout = new GridLayout(1, false);
				foreach (p; [Premium.NORMAL, Premium.RARE, Premium.PREMIUM]) {
					auto radio = new Button(grp, DWT.RADIO);
					radio.setLayoutData = new GridData(GridData.FILL_BOTH);
					radio.setText = _prop.msgs.premium(p);
					_prem[p] = radio;
				}
			}
		}
		{
			createSuccessRateScale(_prop, comp, _sucRate)
				.setLayoutData = new GridData(GridData.FILL_BOTH);
		}
		auto tab = new CTabItem(tabf, DWT.NONE);
		tab.setText = _prop.msgs.cardProps;
		tab.setControl = comp;
		return tab;
	}
	CTabItem constructKeyCode(CTabFolder tabf) {
		auto comp = new Composite(tabf, DWT.NONE);
		comp.setLayout = new GridLayout(2, false);
		auto skin = findSkin(_prop, _summ);
		{
			auto grp = new Group(comp, DWT.NONE);
			grp.setText = _prop.msgs.se;
			grp.setLayoutData = new GridData(GridData.FILL_BOTH);
			grp.setLayout = new GridLayout(1, false);
			createDefSoundCombo(_prop, skin, grp, _se1, _prop.msgs.se1).setLayoutData
				= new GridData(GridData.FILL_BOTH);
			createDefSoundCombo(_prop, skin, grp, _se2, _prop.msgs.se2).setLayoutData
				= new GridData(GridData.FILL_BOTH);
		}
		{
			auto grp = new Group(comp, DWT.NONE);
			grp.setText = _prop.msgs.keyCodes;
			grp.setLayoutData = new GridData(GridData.FILL_BOTH);
			if (_summ.legacy) {
				_keyCodes.length = _prop.looks.keyCodesMaxLegacy;
			} else {
				_keyCodes.length = _prop.looks.keyCodesMax;
			}
			grp.setLayout = new GridLayout(_keyCodes.length >= 8 ? 2 : 1, true);
			for (int i = 0; i < _keyCodes.length; i++) {
				_keyCodes[i] = new Combo(grp, DWT.BORDER | DWT.DROP_DOWN);
				_keyCodes[i].setVisibleItemCount = 20;
				_keyCodes[i].setLayoutData = new GridData(GridData.FILL_BOTH);
				_keyCodes[i].setItems(_prop.var.etc.standardKeyCodes);
			}
		}
		auto tab = new CTabItem(tabf, DWT.NONE);
		tab.setText = _prop.msgs.seAndKeyCode;
		tab.setControl = comp;
		return tab;
	}
public:
	this(Commons comm, Props prop, Shell shell, Summary summ, C card) {
		assert (summ !is null);
		_comm = comm;
		_summ = summ;
		_card = card;
		_prop = prop;
		static if (is (C == SkillCard)) {
			string text = _card ? _prop.msgs.dlgTitSkill(_card.name) : _prop.msgs.dlgTitNewSkill;
			auto img = _prop.images.skill;
			auto size = _prop.var.skillCardDlg;
		} else static if (is (C == ItemCard)) {
			string text = _card ? _prop.msgs.dlgTitItem(_card.name) : _prop.msgs.dlgTitNewItem;
			auto img = _prop.images.item;
			auto size = _prop.var.itemCardDlg;
		} else static if (is (C == BeastCard)) {
			string text = _card ? _prop.msgs.dlgTitBeast(_card.name) : _prop.msgs.dlgTitNewBeast;
			auto img = _prop.images.beast;
			auto size = _prop.var.beastCardDlg;
		} else {
			static assert (0);
		}
		super(prop, shell, text, img, true, size);
	}

	C card() {
		return _card;
	}
protected:
	override void setup(Composite area) {
		area.setLayout = windowGridLayout(1);
		auto tabf = new CTabFolder(area, DWT.BORDER);

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

		auto skin = findSkin(_prop, _summ);
		// Windows Vistaだとタブの横幅が凄いことになったので必要最低限にする。
		scope maxSize = new Point(0, 0);
		foreach (tab; tabf.getItems) {
			scope size = tab.getControl.computeSize(DWT.DEFAULT, DWT.DEFAULT);
			if (maxSize.x < size.x) maxSize.x = size.x;
			if (maxSize.y < size.y) maxSize.y = size.y;
		}
		scope rect = tabf.computeTrim(DWT.DEFAULT, DWT.DEFAULT, maxSize.x, maxSize.y);
		auto gd = new GridData(GridData.FILL_BOTH);
		gd.widthHint = rect.width;
		gd.heightHint = rect.height;
		tabf.setLayoutData = gd;

		if (_card) {
			_imgPath.image = _card.path;
			_desc.setText = _card.desc;
			_name.setText = _card.name;
			_needSpell.setSelection = _card.spell;
			_effTyp[_card.effectType].setSelection = true;
			_res[_card.resist].setSelection = true;
			_phy[_card.physical].setSelection = true;
			_mtl[_card.mental].setSelection = true;
			static if (is (C == SkillCard)) {
				_level.setSelection = _card.level;
			}
			static if (is (C == ItemCard)) {
				_useCount.setSelection = _card.useLimitMax;
			} else static if (is (C == BeastCard)) {
				_useCount.setSelection = _card.useLimit;
			}
			static if (is (C == ItemCard)) {
				_price.setSelection = _card.price;
			}
			_motions.motions = _card.motions;
			foreach (e, index; _useModTbl) {
				_useMod.setValue(index, _card.enhance(e));
			}
			static if (is (C == ItemCard)) {
				foreach (e, index; _hasModTbl) {
					_hasMod.setValue(index, _card.enhanceOwner(e));
				}
			}
			_targ[_card.target].setSelection = true;
			_one.setSelection = !_card.allRange;
			_all.setSelection = _card.allRange;
			__refreshEnblOneAll;
			_vis[_card.visual].setSelection = true;
			_prem[_card.premium].setSelection = true;
			_sucRate.setSelection = _card.successRate + _prop.looks.successRateMax;
			string findPath(string path) {
				return getBaseName(skin.findPath(getBaseName(path), skin.extSound, skin.seDir, ""));
			}
			int se1i = _se1.indexOf(findPath(_card.soundPath1));
			_se1.select = se1i >= 0 ? se1i : 0;
			int se2i = _se2.indexOf(findPath(_card.soundPath2));
			_se2.select = se2i >= 0 ? se2i : 0;
			foreach (i, kc; _card.keyCodes) {
				_keyCodes[i].setText = kc;
			}
		} else {
			_imgPath.image = "";
			_effTyp[EffectType.PHYSIC].setSelection = true;
			_res[Resist.AVOID].setSelection = true;
			_phy[Physical.DEX].setSelection = true;
			_mtl[Mental.AGGRESSIVE].setSelection = true;
			static if (is (C == SkillCard)) {
				_level.setSelection = 1;
			}
			foreach (e, index; _useModTbl) {
				_useMod.setValue(index, 0);
			}
			static if (is (C == ItemCard)) {
				foreach (e, index; _hasModTbl) {
					_hasMod.setValue(index, 0);
				}
			}
			_targ[CardTarget.NONE].setSelection = true;
			_one.setSelection = true;
			__refreshEnblOneAll;
			_vis[CardVisual.NONE].setSelection = true;
			_prem[Premium.NORMAL].setSelection = true;
			_sucRate.setSelection = _prop.looks.successRateMax;
			_se1.select = 0;
			_se2.select = 0;
		}
		static if (is (C == SkillCard)) {
			calcPrice(_level.getSelection);
		} else static if (is (C == BeastCard)) {
			calcPrice(_useCount.getSelection);
		}
	}
	private void __refreshEnblOneAll() {
		_oneAllGrp.setEnabled
			= _targ[CardTarget.PARTY].getSelection
			|| _targ[CardTarget.ENEMY].getSelection
			|| _targ[CardTarget.BOTH].getSelection;
		_one.setEnabled = _oneAllGrp.getEnabled;
		_all.setEnabled = _oneAllGrp.getEnabled;
	}

	override bool close(bool ok, out bool cancel) {
		if (ok) {
			if (_effTyp[EffectType.NONE].getSelection
					&& (!_card || _card.effectType != EffectType.NONE)) {
				auto dlg = new MessageBox(getShell, DWT.ICON_QUESTION | DWT.OK | DWT.CANCEL);
				scope (exit) dlg.dispose;
				dlg.setMessage = _prop.msgs.warningEffectTypeNone;
				dlg.setText = _prop.msgs.dlgTitQuestion;
				if (DWT.CANCEL == dlg.open) {
					cancel = true;
					return false;
				}
			}
			bool hasVanishCast(Motion[] ms) {
				foreach (m; ms) {
					if (m.type == MType.VANISH_TARGET && m.element != cast(int) Element.MIRACLE) {
						return true;
					}
				}
				return false;
			}
			auto motions = _motions.motions;
			if (hasVanishCast(motions) && (!_card || !hasVanishCast(_card.motions))) {
				auto dlg = new MessageBox(getShell, DWT.ICON_QUESTION | DWT.OK | DWT.CANCEL);
				scope (exit) dlg.dispose;
				dlg.setMessage = _prop.msgs.warningVanishCast;
				dlg.setText = _prop.msgs.dlgTitQuestion;
				if (DWT.CANCEL == dlg.open) {
					cancel = true;
					return false;
				}
			}
			if (_card) {
				_card.path = _imgPath.image;
				_card.desc = wrapReturnCode(_desc.getText);
				_card.name = _name.getText;
			} else {
				_card = new C(_summ.newId!(C), _name.getText,
					_imgPath.image, wrapReturnCode(_desc.getText));
			}
			_card.spell = _needSpell.getSelection;
			putRadioValue!(EffectType)(_effTyp, &_card.effectType);
			putRadioValue!(Resist)(_res, &_card.resist);
			putRadioValue!(Physical)(_phy, &_card.physical);
			putRadioValue!(Mental)(_mtl, &_card.mental);
			static if (is (C == SkillCard)) {
				_card.level = _level.getSelection;
			}
			static if (is (C == ItemCard)) {
				_card.useLimitMax = _useCount.getSelection;
				_card.useLimit = _useCount.getSelection;
			} else static if (is (C == BeastCard)) {
				_card.useLimit = _useCount.getSelection;
			}
			static if (is (C == ItemCard)) {
				_card.price = _price.getSelection;
			}
			_card.motions = motions;
			foreach (e, index; _useModTbl) {
				_card.enhance(e, _useMod.getValue(index));
			}
			static if (is (C == ItemCard)) {
				foreach (e, index; _hasModTbl) {
					_card.enhanceOwner(e, _hasMod.getValue(index));
				}
			}
			putRadioValue!(CardTarget)(_targ, &_card.target);
			_card.allRange = _oneAllGrp.isEnabled && _all.getSelection;
			putRadioValue!(CardVisual)(_vis, &_card.visual);
			putRadioValue!(Premium)(_prem, &_card.premium);
			_card.successRate = cast(int) _sucRate.getSelection - _prop.looks.successRateMax;
			_card.soundPath1 = _se1.getSelectionIndex > 0 ? _se1.getText : "";
			_card.soundPath2 = _se2.getSelectionIndex > 0 ? _se2.getText : "";
			string[] keyCodes;
			int last = 0;
			foreach (i, c; _keyCodes) {
				keyCodes ~= c.getText;
				if (c.getText.length > 0) last = i + 1;
			}
			keyCodes.length = last;
			_card.scenario = _summ.scenarioName;
			_card.author = _summ.author;
			_card.keyCodes = keyCodes;
		}
		return ok;
	}
}
