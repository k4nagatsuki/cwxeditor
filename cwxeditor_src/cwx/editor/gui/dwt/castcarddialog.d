
module cwx.editor.gui.dwt.castcarddialog;

import cwx.coupon;
import cwx.summary;
import cwx.card;
import cwx.types;
import cwx.features;
import cwx.utils;
import cwx.race;
import cwx.xml;
import cwx.skin;
import cwx.motion;
import cwx.path;
import cwx.menu;
import cwx.types;
import cwx.imagesize;

import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.materialselect;
import cwx.editor.gui.dwt.imageselect;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.radarspinner;
import cwx.editor.gui.dwt.xmlbytestransfer;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.couponview;
import cwx.editor.gui.dwt.scales;

import std.datetime;
import std.string;
import std.conv;

import org.eclipse.swt.all;

import java.lang.all;

public:

/// キャストカードの設定を行うダイアログ。
class CastCardDialog : AbsDialog {
private:
	string _id;

	Commons _comm;
	Props _prop;
	Summary _summ;
	CastCard _card;

	ImageSelect!(MtType.CARD) _imgPath;
	FixedWidthText _desc;
	GBLimitText _name;
	Spinner _level;
	Spinner _lifeMax;
	CouponView!(CVType.Cast) _couponView;
	Combo _race;
	Button[Sex] _sex;
	Button _sexU;
	Button[Period] _period;
	Button _periodU;
	Composite _natureComp;
	Button[Nature] _nature;
	Button _natureU;
	bool _showSpNature = false;
	Button[Makings] _makings;
	Button _resW;
	Button _resM;
	Button _undead;
	Button _automaton;
	Button _unholy;
	Button _constructure;
	Button _res[Element];
	Button _weak[Element];
	int[Physical] _phyTbl;
	Composite _phyParent;
	RadarSpinner _phyR = null;
	Scales _phyS = null;
	Scale[Mental] _mtl;
	Label _sumPhy;
	int[Enhance] _enhTbl;
	Composite _enhParent;
	RadarSpinner _enhR = null;
	Scales _enhS = null;

	Spinner _life;
	Button _lifeUseMax;
	Spinner[Enhance] _liveEnh;
	Spinner[Enhance] _enhRound;
	Spinner _paralyze;
	Spinner _poison;
	Spinner _bind;
	Spinner _silence;
	Spinner _faceUp;
	Spinner _antiMagic;
	Mentality[int] _mtlyTbl;
	Combo _mtly;
	Spinner _mtlyRound;

	void refreshWarning() {
		string[] ws;
		if (_name.over) {
			ws ~= .tryFormat(_prop.msgs.warningNameLenOver, _prop.looks.castNameLimit, _prop.looks.castNameLimit / 2);
		}
		ws ~= _imgPath.warnings;

		warning = ws;
	}

	@property
	Race selectedRace() {
		if (_race) {
			int index = _race.getSelectionIndex();
			if (index > 0) {
				return _comm.skin.races[index - 1];
			}
		}
		return null;
	}
	void raceToolTip() {
		if (_race) {
			auto race = selectedRace;
			_race.setToolTipText(race ? race.desc : "");
		}
	}
	class SelectRace : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			raceToolTip();
		}
	}
	class BasicResist : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			auto race = selectedRace;
			if (race) {
				_automaton.setSelection(race.automaton);
				_constructure.setSelection(race.constructure);
				_undead.setSelection(race.undead);
				_unholy.setSelection(race.unholy);
				_resW.setSelection(race.weaponResist);
				_resM.setSelection(race.magicResist);
				foreach (el; _res.keys) {
					_res[el].setSelection(race.resist(el));
					_weak[el].setSelection(race.weakness(el));
				}
			} else {
				_automaton.setSelection(false);
				_constructure.setSelection(false);
				_undead.setSelection(false);
				_unholy.setSelection(false);
				_resW.setSelection(false);
				_resM.setSelection(false);
				foreach (el; _res.keys) {
					_res[el].setSelection(false);
					_weak[el].setSelection(false);
				}
			}
		}
	}
	class BasicEnhance : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			auto race = selectedRace;
			if (race) {
				foreach (enh, i; _enhTbl) {
					if (_enhR) {
						_enhR.setValue(i, race.defaultEnhance(enh));
					} else {
						_enhS.setValue(i, race.defaultEnhance(enh));
					}
				}
			} else {
				foreach (enh, i; _enhTbl) {
					if (_enhR) {
						_enhR.setValue(i, 0);
					} else {
						_enhS.setValue(i, 0);
					}
				}
			}
		}
	}

	class SelLifeC : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			auto vit = _phyTbl[Physical.VIT];
			auto min = _phyTbl[Physical.MIN];
			_lifeMax.setSelection(_prop.looks.lifeCalc(_level.getSelection(),
				(_phyR ? _phyR.getValue(vit) : _phyS.getValue(vit)),
				(_phyR ? _phyR.getValue(min) : _phyS.getValue(min))));
		}
	}

	void constructBase(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(2, false));
		auto skin = _comm.skin;
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
					_prop.looks.castNameLimit, false, grp, SWT.BORDER);
				_name.limitEvent ~= &refreshWarning;
				mod(_name.widget);
				createTextMenu!Text(_comm, _prop, _name.widget, &catchMod);
				auto gd = new GridData(GridData.FILL_HORIZONTAL);
				gd.widthHint = _name.computeSize(SWT.DEFAULT, SWT.DEFAULT).x;
				_name.widget.setLayoutData(gd);
				auto l = new Label(grp, SWT.NONE);
				l.setText(.tryFormat(_prop.msgs.nameLimit, _prop.looks.castNameLimit, _prop.looks.castNameLimit / 2));
			}
			{
				bool including = _card && isBinImg(_card.path);
				_imgPath = new ImageSelect!(MtType.CARD)(comp2, SWT.NONE, _comm, _prop, _summ,
					_prop.looks.cardSize.width, _prop.looks.cardSize.height, including, true, &_name.getText);
				mod(_imgPath);
				_imgPath.modEvent ~= &refreshWarning;
				_imgPath.widget.setLayoutData(new GridData(GridData.FILL_BOTH));
				_imgPath.cardMode = CardMode.Cast;
			}
		}
		{
			auto compr = new Composite(comp, SWT.NONE);
			compr.setLayoutData(new GridData(GridData.FILL_VERTICAL));
			compr.setLayout(zeroMarginGridLayout(1, false));
			{
				auto grp = new Group(compr, SWT.NONE);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setLayout(new CenterLayout);
				grp.setText(_prop.msgs.level);
				auto comp2 = new Composite(grp, SWT.NONE);
				comp2.setLayout(zeroMarginGridLayout(2, false));
				_level = new Spinner(comp2, SWT.BORDER);
				mod(_level);
				_level.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				_level.setMinimum(1);
				_level.setMaximum(_prop.var.etc.castLevelMax);
				auto hint = new Label(comp2, SWT.RIGHT);
				hint.setText(.tryFormat(_prop.msgs.rangeHint, 1, _prop.var.etc.castLevelMax));
			}
			{
				auto grp = new Group(compr, SWT.NONE);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setLayout(new CenterLayout);
				grp.setText(_prop.msgs.life);
				auto comp2 = new Composite(grp, SWT.NONE);
				comp2.setLayout(zeroMarginGridLayout(2, false));
				_lifeMax = new Spinner(comp2, SWT.BORDER);
				mod(_lifeMax);
				_lifeMax.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				_lifeMax.setMinimum(1);
				_lifeMax.setMaximum(_prop.var.etc.lifeMax);
				_lifeMax.addModifyListener(new LifeMaxL);
				auto hint = new Label(comp2, SWT.RIGHT);
				hint.setText(.tryFormat(_prop.msgs.rangeHint, 1, _prop.var.etc.lifeMax));
				auto lifec = new Button(comp2, SWT.PUSH);
				mod(lifec);
				auto lgd = new GridData(GridData.FILL_HORIZONTAL);
				lgd.horizontalSpan = 2;
				lifec.setLayoutData(lgd);
				lifec.setText(_prop.msgs.lifeCalc);
				lifec.addSelectionListener(new SelLifeC);
			}
			auto grp = new Group(compr, SWT.NONE);
			grp.setText(_prop.msgs.race);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto cl = new CenterLayout;
			cl.fillHorizontal = true;
			grp.setLayout(cl);
			_race = new Combo(grp, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
			mod(_race);
			_race.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
			_race.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			_race.add(_prop.msgs.noRace);
			foreach (race; skin.races) {
				_race.add(race.name);
			}
			_race.addSelectionListener(new SelectRace);
			refreshRace();
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.card);
		tab.setControl(comp);
	}
	void setMaxLife() {
		_life.setMaximum(_lifeMax.getSelection());
		if (_lifeUseMax.getSelection()) {
			_life.setSelection(_lifeMax.getSelection());
		}
		_life.getParent().layout();
		_life.setSelection(_life.getSelection());
	}
	class LifeMaxL : ModifyListener {
		public override void modifyText(ModifyEvent e) {
			setMaxLife();
		}
	}
	void constructDesc(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(2, false));
		{
			auto grp = new Group(comp, SWT.NONE);
			auto gd = new GridData(GridData.FILL_BOTH);
			grp.setLayoutData(gd);
			gd.horizontalSpan = 2;
			auto cl = new CenterLayout(SWT.HORIZONTAL);
			cl.fillVertical = true;
			grp.setLayout(cl);
			grp.setText(_prop.msgs.desc);
			_desc = new FixedWidthText(dwtData(_prop.looks.cardDescFont(_summ.legacy)), _prop.looks.cardDescLen, grp, SWT.BORDER);
			mod(_desc.widget);
			createTextMenu!Text(_comm, _prop, _desc.widget, &catchMod);
			auto p = _desc.computeTextBaseSize(1);
			p.y = SWT.DEFAULT;
			_desc.widget.setLayoutData(p);
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.desc);
		tab.setControl(comp);
	}
	Button createR(Composite parent, string name, int hAlignHint = -1) {
		auto radio = new Button(parent, SWT.RADIO);
		mod(radio);
		auto gd = new GridData(GridData.FILL_BOTH);
		if (0 <= hAlignHint) {
			hAlignHint %= 2;
			gd.grabExcessHorizontalSpace = true;
			if (0 == hAlignHint) {
				gd.horizontalAlignment = SWT.LEFT;
			} else {
				gd.horizontalAlignment = SWT.RIGHT;
			}
		}
		radio.setLayoutData(gd);
		radio.setText(name);
		return radio;
	}
	void constructHistory(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(2, false));
		auto skin = _comm.skin;
		{
			auto grp = new Group(comp, SWT.NONE);
			grp.setText(_prop.msgs.coupons);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(new GridLayout(1, true));
			_couponView = new CouponView!(CVType.Cast)(_comm, grp, SWT.NONE, &catchMod);
			_couponView.setLayoutData(new GridData(GridData.FILL_BOTH));
			mod(_couponView);
		}
		{
			auto comp2 = new Composite(comp, SWT.NONE);
			comp2.setLayoutData(new GridData(GridData.FILL_VERTICAL));
			comp2.setLayout(zeroMarginGridLayout(2, false));
			{
				auto comp3 = createButtonGroup(comp2, _prop.msgs.sexTitle, 1, 1);
				foreach (s; SEX_ALL) {
					auto name = skin.sexName(s);
					_sex[s] = createR(comp3, _prop.msgs.sex.get(name, name));
				}
				_sexU = createR(comp3, _prop.msgs.sexUnknown);
			}
			{
				auto comp3 = createButtonGroup(comp2, _prop.msgs.periodTitle, 2, 1);
				foreach (p; PERIOD_ALL) {
					auto name = skin.periodName(p);
					_period[p] = createR(comp3, _prop.msgs.period.get(name, name));
				}
				_periodU = createR(comp3, _prop.msgs.periodUnknown);
			}
			{
				auto comp3 = new Group(comp2, SWT.NONE);
				comp3.setText(_prop.msgs.natureTitle);
				auto cgd = new GridData(GridData.FILL_BOTH);
				cgd.horizontalSpan = 2;
				comp3.setLayoutData(cgd);
				comp3.setLayout(new GridLayout(2, true));
				_natureComp = comp3;
				updateNature();
			}
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.history);
		tab.setControl(comp);
	}
	class MSListener : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			auto radio = cast(Button) e.widget;
			if (radio.getSelection()) {
				auto m = cast(Makings) (cast(Integer) radio.getData()).intValue();
				auto r = reverseMakings(m);
				_makings[r].setSelection(false);
			}
		}
	};
	void constructMakings(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, false));
		auto skin = _comm.skin;
		{
			auto comp3 = createButtonGroup(comp, _prop.msgs.coupons, 4, 1, true);
			auto sl = new MSListener;
			foreach (m; MAKINGS_LEFT) {
				void createR(Makings m) {
					auto radio = new Button(comp3, SWT.CHECK);
					mod(radio);
					radio.setLayoutData(new GridData(GridData.FILL_BOTH));
					auto name = skin.makingsName(m);
					radio.setText(_prop.msgs.makings.get(name, name));
					radio.setData(new Integer(m));
					radio.addSelectionListener(sl);
					_makings[m] = radio;
				}
				createR(m);
				createR(reverseMakings(m));
			}
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.makingsTitle);
		tab.setControl(comp);
	}
	Composite createButtonGroup(Composite parent, string name,
			int row, int horSpan = 1, bool min = false) {
		auto grp = new Group(parent, SWT.NONE);
		grp.setText(name);
		auto gd = new GridData(GridData.FILL_BOTH);
		gd.horizontalSpan = horSpan;
		grp.setLayoutData(gd);
		auto cl = new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0);
		cl.fillVertical = true;
		grp.setLayout(cl);
		auto comp3 = new Composite(grp, SWT.NONE);
		auto gl = new GridLayout(row, true);
		if (min) gl.verticalSpacing = 2;
		comp3.setLayout(gl);
		return comp3;
	}
	class ESListener : SelectionAdapter {
		private Button _targ;
		this(Button targ) {
			_targ = targ;
		}
		override void widgetSelected(SelectionEvent e) {
			auto radio = cast(Button) e.widget;
			if (radio.getSelection()) {
				_targ.setSelection(false);
			}
		}
	};
	void constructResist(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, false));
		Button createC(Composite parent, string name, string desc) {
			auto comp = new Composite(parent, SWT.NONE);
			comp.setLayoutData(new GridData(GridData.FILL_BOTH));
			comp.setLayout(zeroGridLayout(2, false));
			auto c = new Button(comp, SWT.CHECK);
			mod(c);
			auto cgd = new GridData(GridData.FILL_HORIZONTAL);
			cgd.horizontalSpan = 2;
			c.setLayoutData(cgd);
			c.setText(name);
			auto dummy = new Composite(comp, SWT.NONE);
			auto dgd = new GridData;
			dgd.widthHint = 20;
			dgd.heightHint = 0;
			dummy.setLayoutData(dgd);
			auto l = new Label(comp, SWT.NONE);
			l.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			l.setText(desc);
			return c;
		}
		{
			Composite tcomp, bcomp;
			{
				tcomp = createButtonGroup(comp, _prop.msgs.tolerantBase, 2, 1);
				auto gl = cast(GridLayout) tcomp.getLayout();
				gl.horizontalSpacing = 15;
				_resW = createC(tcomp, _prop.msgs.resistWeapon, _prop.msgs.descResistWeapon);
				_resM = createC(tcomp, _prop.msgs.resistMagic, _prop.msgs.descResistMagic);
			}
			{
				bcomp = createButtonGroup(comp, _prop.msgs.tolerantElement, 2, 1);
				auto gl = cast(GridLayout) bcomp.getLayout();
				gl.horizontalSpacing = 15;
				_undead = createC(bcomp, _prop.msgs.undead, _prop.msgs.descUndead);
				_automaton = createC(bcomp, _prop.msgs.automaton, _prop.msgs.descAutomaton);
				_unholy = createC(bcomp, _prop.msgs.unholy, _prop.msgs.descUnholy);
				_constructure = createC(bcomp, _prop.msgs.constructure, _prop.msgs.descConstructure);
				foreach (e; [Element.FIRE, Element.ICE]) {
					string eName = _prop.msgs.elementName(e);
					auto res = createC(bcomp, .tryFormat(_prop.msgs.resistText, eName), .tryFormat(_prop.msgs.descResist, eName));
					auto weak = createC(bcomp, .tryFormat(_prop.msgs.weaknessText, eName), .tryFormat(_prop.msgs.descWeakness, eName));
					res.addSelectionListener(new ESListener(weak));
					weak.addSelectionListener(new ESListener(res));
					_res[e] = res;
					_weak[e] = weak;
				}
			}
			auto ts = tcomp.computeSize(SWT.DEFAULT, SWT.DEFAULT);
			auto bs = bcomp.computeSize(SWT.DEFAULT, SWT.DEFAULT);
			int maxW = ts.x > bs.x ? ts.x : bs.x;
			ts.x = maxW;
			bs.x = maxW;
			tcomp.setLayoutData(ts);
			bcomp.setLayoutData(bs);
		}
		{
			auto basic = new Button(comp, SWT.PUSH);
			mod(basic);
			basic.setText(_prop.msgs.basicResist);
			basic.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
			basic.addSelectionListener(new BasicResist);
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.tolerant);
		tab.setControl(comp);
	}
	static immutable PHYSICALS = [Physical.DEX, Physical.AGL, Physical.INT,
		Physical.STR, Physical.VIT, Physical.MIN];
	void initPhysical() {
		int[] values = [];
		if (_phyR) {
			values = _phyR.getValues();
			_phyR.dispose();
			_phyR = null;
		}
		if (_phyS) {
			values = _phyS.getValues();
			_phyS.dispose();
			_phyS = null;
		}

		string[] names;
		names.length = PHYSICALS.length;
		int[Physical] table;
		foreach (i, p; PHYSICALS) {
			table[p] = i;
			names[i] = _prop.msgs.physicalName(p);
		}
		_phyTbl = table;
		int page = _prop.var.etc.physicalMax / 5;

		if (_prop.var.etc.radarStyleParams) {
			_phyR = new RadarSpinner(_phyParent, SWT.NONE);
			_phyR.setRadar(_prop.var.etc.physicalMax + 1, names, 0);
			_phyR.antialias = true;
			_phyR.borderlines = cast(int[]) _prop.looks.physicalBorders;
			_phyR.lineStep = page;
			if (values.length) _phyR.setValues(values);
			mod(_phyR);
			_phyR.modEvent ~= &modPhysical;
		} else {
			_phyS = new Scales(_phyParent, SWT.NONE);
			_phyS.setScales(_prop.var.etc.physicalMax + 1, names, page, 0);
			_phyS.borderlines = cast(int[]) _prop.looks.physicalBorders;
			if (values.length) _phyS.setValues(values);
			mod(_phyS);
			_phyS.modEvent ~= &modPhysical;
		}
		_phyParent.layout();
	}
	void modPhysical() {
		int[] vals;
		if (_phyR) vals = _phyR.getValues();
		if (_phyS) vals = _phyS.getValues();
		int sum = 0;
		foreach (val; vals) {
			sum += val;
		}
		_sumPhy.setText(.tryFormat(_prop.msgs.physicalSum, sum));
	}
	void constructPhysical(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(2, false));
		{
			auto grp = new Group(comp, SWT.NONE);
			grp.setText(_prop.msgs.physicalParams);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.horizontalSpan = 2;
			grp.setLayoutData(gd);
			auto cl = new CenterLayout;
			cl.fillHorizontal = true;
			cl.fillVertical = true;
			grp.setLayout(cl);
			_phyParent = grp;
			initPhysical();
		}
		{
			_sumPhy = new Label(comp, SWT.NONE);
			_sumPhy.setLayoutData(new GridData(GridData.FILL_HORIZONTAL|GridData.HORIZONTAL_ALIGN_BEGINNING));
		}
		{
			auto basic = new Button(comp, SWT.PUSH);
			mod(basic);
			basic.setText(_prop.msgs.physicalCalc);
			basic.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
			basic.addSelectionListener(new CalcPhysical);
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.physicalParams);
		tab.setControl(comp);
	}
	real calcPhy(E)(in Skin skin, Physical phy, Button[E] radios, bool all) {
		real r = 0.0;
		foreach (e, radio; radios) {
			if (radio.getSelection()) {
				r += skin.physicalMod(e, phy);
				if (!all) break;
			}
		}
		return r;
	}
	class CalcPhysical : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			real[Physical] p;
			int[Physical] min;
			int[Physical] max;
			auto race = selectedRace;
			foreach (phy; _phyTbl.keys) {
				int pmin = _prop.looks.physicalCutMin;
				int pmax;
				if (race) {
					int v = race.physical(phy);
					pmax = v + _prop.looks.physicalCutMaxBase;
					if (pmax > _prop.var.etc.physicalMax) pmax = _prop.var.etc.physicalMax;
					if (v < pmin) pmin = v;
					p[phy] = v;
				} else {
					int v = _prop.looks.physicalNormal;
					pmax = v + _prop.looks.physicalCutMaxBase;
					p[phy] = v;
				}
				min[phy] = pmin;
				max[phy] = pmax;
			}
			foreach (phy, val; p) {
				val += calcPhy!(Sex)(_comm.skin, phy, _sex, false);
				val += calcPhy!(Period)(_comm.skin, phy, _period, false);
				val += calcPhy!(Nature)(_comm.skin, phy, _nature, false);
				val += calcPhy!(Makings)(_comm.skin, phy, _makings, true);
				p[phy] = val;
			}
			int[] vals;
			vals.length = p.length;
			foreach (phy, val; p) {
				int v = cast(int) val;
				if (v < min[phy]) v = min[phy];
				if (v > max[phy]) v = max[phy];
				vals[_phyTbl[phy]] = v;
			}
			if (_phyR) {
				_phyR.setValues(vals);
			} else {
				_phyS.setValues(vals);
			}
			modPhysical();
		}
	}
	void constructMental(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, false));
		{
			auto grp = new Group(comp, SWT.NONE);
			grp.setText(_prop.msgs.mentalParams);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto ggl = new GridLayout(3, false);
			ggl.verticalSpacing = 0;
			grp.setLayout(ggl);
			static const Ms = [Mental.AGGRESSIVE, Mental.CHEERFUL, Mental.BRAVE,
				Mental.CAUTIOUS, Mental.TRICKISH];
			foreach (m; Ms) {
				auto minl = new Label(grp, SWT.NONE);
				minl.setText(_prop.msgs.mentalName(reverseMental(m)));
				auto scale = new Scale(grp, SWT.NONE);
				mod(scale);
				scale.setLayoutData(new GridData(GridData.FILL_BOTH));
				scale.setMaximum(_prop.var.etc.mentalMax * 2);
				scale.setMinimum(0);
				scale.setIncrement(1);
				scale.setPageIncrement(_prop.var.etc.mentalMax);
				auto maxl = new Label(grp, SWT.NONE);
				maxl.setText(_prop.msgs.mentalName(m));
				_mtl[m] = scale;
			}
		}
		{
			auto basic = new Button(comp, SWT.PUSH);
			mod(basic);
			basic.setText(_prop.msgs.mentalCalc);
			basic.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
			basic.addSelectionListener(new CalcMental);
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.mentalParams);
		tab.setControl(comp);
	}
	real calcMtl(E)(in Skin skin, Mental mtl, Button[E] radios, bool all) {
		real r = 0.0;
		foreach (e, radio; radios) {
			if (radio.getSelection()) {
				r += skin.mentalMod(e, mtl);
				if (!all) break;
			}
		}
		return r;
	}
	class CalcMental : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			auto race = selectedRace;
			foreach (mtl, scale; _mtl) {
				int min = cast(int) _prop.looks.mentalCut * -1;
				int max = _prop.looks.mentalCut;
				real val;
				if (race) {
					int ival = race.mental(mtl);
					val = ival;
					if (ival < min) min = ival;
					if (ival > max) max = ival;
				} else {
					val = 0.0;
				}
				val += calcMtl!(Sex)(_comm.skin, mtl, _sex, false);
				val += calcMtl!(Period)(_comm.skin, mtl, _period, false);
				val += calcMtl!(Nature)(_comm.skin, mtl, _nature, false);
				val += calcMtl!(Makings)(_comm.skin, mtl, _makings, true);
				int v = cast(int) val;
				if (v < min) v = min;
				if (v > max) v = max;
				scale.setSelection(v + _prop.var.etc.mentalMax);
			}
		}
	}
	static immutable ENHANCE = [Enhance.AVOID, Enhance.RESIST, Enhance.DEFENSE];
	void initEnhance() {
		int[] values = [];
		if (_enhR) {
			values = _enhR.getValues();
			_enhR.dispose();
			_enhR = null;
		}
		if (_enhS) {
			values = _enhS.getValues();
			_enhS.dispose();
			_enhS = null;
		}

		string[] names;
		names.length = ENHANCE.length;
		foreach (i, enh; ENHANCE) {
			_enhTbl[enh] = i;
			names[i] = .tryFormat(_prop.msgs.enhanceBonus, _prop.msgs.enhanceName(enh));
		}
		int stepC = _prop.var.etc.enhanceMax * 2 + 1;
		int min = cast(int) _prop.var.etc.enhanceMax * -1;
		int page = _prop.var.etc.enhanceMax / 2;
		if (_prop.var.etc.radarStyleParams) {
			_enhR = new RadarSpinner(_enhParent, SWT.NONE);
			_enhR.setRadar(stepC, names, min);
			_enhR.antialias = true;
			_enhR.borderlines = [0];
			_enhR.lineStep = page;
			if (values.length) _enhR.setValues(values);
			mod(_enhR);
		} else {
			_enhS = new Scales(_enhParent, SWT.NONE);
			_enhS.setScales(stepC, names, page, min);
			_enhS.borderlines = [0];
			if (values.length) _enhS.setValues(values);
			mod(_enhS);
		}
		_enhParent.layout();
	}
	void constructEnhance(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, false));
		{
			auto grp = new Group(comp, SWT.NONE);
			grp.setText(_prop.msgs.castEnhance);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto cl = new CenterLayout;
			cl.fillHorizontal = true;
			cl.fillVertical = true;
			grp.setLayout(cl);
			_enhParent = grp;
			initEnhance();
		}
		{
			auto basic = new Button(comp, SWT.PUSH);
			mod(basic);
			basic.setText(_prop.msgs.basicEnhance);
			basic.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
			basic.addSelectionListener(new BasicEnhance);
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.castEnhance);
		tab.setControl(comp);
	}
	void constructStatus(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, false));
		Label[] lbls1, lbls2;
		Composite[] spns;
		Spinner createSpn(Composite comp) {
			// なぜかCompositeを挟まなければSpinner#computeSize()が大きめの値を返す
			Composite comp2 = new Composite(comp, SWT.NONE);
			comp2.setLayout(new FillLayout);
			auto spn = new Spinner(comp2, SWT.BORDER);
			mod(spn);
			spns ~= comp2;
			return spn;
		}
		Composite createGrp(string text) {
			auto grp = new Group(comp, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto gl = new GridLayout(2, false);
			gl.horizontalSpacing = 15;
			grp.setLayout(gl);
			grp.setText(text);
			return grp;
		}
		Composite createComp(Composite grp) {
			auto comp2 = new Composite(grp, SWT.NONE);
			comp2.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto rl = new RowLayout(SWT.HORIZONTAL);
			rl.center = true;
			rl.marginLeft = 0;
			rl.marginRight = 0;
			rl.marginTop = 0;
			rl.marginBottom = 0;
			comp2.setLayout(rl);
			return comp2;
		}
		{
			auto grp = createGrp(_prop.msgs.lifeAndMentality);
			{
				auto comp2 = createComp(grp);
				auto l = new Label(comp2, SWT.NONE);
				l.setText(_prop.msgs.life);
				lbls1 ~= l;
				_life = new Spinner(comp2, SWT.BORDER);
				mod(_life);
				_lifeUseMax = new Button(comp2, SWT.CHECK);
				mod(_lifeUseMax);
				_lifeUseMax.setText(_prop.msgs.useMax);
				_lifeUseMax.addSelectionListener(new LifeUseMax);
			}
			{
				auto comp2 = createComp(grp);
				auto lm = new Label(comp2, SWT.NONE);
				lm.setText(_prop.msgs.mentality);
				lbls1 ~= lm;
				_mtly = new Combo(comp2, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
				mod(_mtly);
				_mtly.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
				foreach (i, mtly; [Mentality.NORMAL, Mentality.SLEEP, Mentality.CONFUSE,
						Mentality.OVERHEAT, Mentality.BRAVE, Mentality.PANIC]) {
					_mtly.add(_prop.msgs.mentalityName(mtly));
					_mtlyTbl[i] = mtly;
					if (_card && _card.mentality is mtly) {
						_mtly.select(i);
					}
				}
				if (_mtly.getSelectionIndex() < 0) _mtly.select(0);
				_mtly.addSelectionListener(new SelMentality);
				_mtlyRound = createSpn(comp2);
				_mtlyRound.setMaximum(_prop.var.etc.roundMax);
				_mtlyRound.setMinimum(Motion.round_min);
				spns ~= _mtlyRound;
				auto lm2  = new Label(comp2, SWT.NONE);
				lm2.setText(_prop.msgs.unitRound);
			}
		}
		{
			auto grp = createGrp(_prop.msgs.enhanceLiveBonus);
			foreach (enh; [Enhance.ACTION, Enhance.AVOID, Enhance.RESIST, Enhance.DEFENSE]) {
				auto comp2 = createComp(grp);
				auto l = new Label(comp2, SWT.NONE);
				l.setText(_prop.msgs.enhanceLiveBonusName(enh));
				lbls1 ~= l;
				auto spn = createSpn(comp2);
				spn.setMaximum(_prop.var.etc.enhanceMax);
				spn.setMinimum(-(cast(int) _prop.var.etc.enhanceMax));
				spns ~= spn;
				_liveEnh[enh] = spn;
				auto rnd = createSpn(comp2);
				rnd.setMaximum(_prop.var.etc.roundMax);
				rnd.setMinimum(Motion.round_min);
				spns ~= rnd;
				_enhRound[enh] = rnd;
				auto l2  = new Label(comp2, SWT.NONE);
				l2.setText(_prop.msgs.unitRound);
				spn.addSelectionListener(new LiveEnh);
			}
		}
		Spinner createStSpn(Composite grp, string name, uint max, string val) {
			auto comp2 = createComp(grp);
			auto l = new Label(comp2, SWT.NONE);
			l.setText(name);
			lbls1 ~= l;
			auto spn = createSpn(comp2);
			spn.setMaximum(max);
			spn.setMinimum(0);
			spns ~= spn;
			auto l2  = new Label(comp2, SWT.NONE);
			l2.setText(val);
			lbls2 ~= l2;
			return spn;
		}
		{
			auto grp = createGrp(_prop.msgs.status);
			_paralyze = createStSpn(grp, _prop.msgs.paralyze, _prop.var.etc.paralyzeMax, _prop.msgs.unitValue);
			_poison = createStSpn(grp, _prop.msgs.poison, _prop.var.etc.poisonMax, _prop.msgs.unitValue);
			_bind = createStSpn(grp, _prop.msgs.bind, _prop.var.etc.roundMax, _prop.msgs.unitRound);
			_silence = createStSpn(grp, _prop.msgs.silence, _prop.var.etc.roundMax, _prop.msgs.unitRound);
			_faceUp = createStSpn(grp, _prop.msgs.faceUp, _prop.var.etc.roundMax, _prop.msgs.unitRound);
			_antiMagic = createStSpn(grp, _prop.msgs.antiMagic, _prop.var.etc.roundMax, _prop.msgs.unitRound);
		}
		void setlblw(Control[] lbls) {
			int maxW = 0;
			foreach (lbl; lbls) {
				int w = lbl.computeSize(SWT.DEFAULT, SWT.DEFAULT).x;
				if (maxW < w) maxW = w;
			}
			foreach (lbl; lbls) {
				auto gd = new RowData(maxW, SWT.DEFAULT);
				lbl.setLayoutData(gd);
			}
		}
		setlblw(cast(Control[]) lbls1);
		setlblw(cast(Control[]) lbls2);
		setlblw(cast(Control[]) spns);
		{
			auto reset = new Button(comp, SWT.PUSH);
			mod(reset);
			reset.setText(_prop.msgs.resetLiveStatus);
			reset.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
			reset.addSelectionListener(new ResetLiveStatus);
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.liveStatus);
		tab.setControl(comp);
	}
	class LiveEnh : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			changeLiveEnhance();
		}
	}
	class SelMentality : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			changeMentality();
		}
	}
	class LifeUseMax : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			changeLifeUseMax();
		}
	}
	class ResetLiveStatus : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			resetLiveStatus();
		}
	}
	void changeLiveEnhance() {
		foreach (enh, spn; _liveEnh) {
			_enhRound[enh].setEnabled(spn.getSelection() != 0);
		}
	}
	void changeMentality() {
		_mtlyRound.setEnabled(_mtly.getSelectionIndex() != 0);
	}
	void changeLifeUseMax() {
		_life.setEnabled(!_lifeUseMax.getSelection());
	}
	void resetLiveStatus() {
		_life.setSelection(_lifeMax.getSelection());
		_lifeUseMax.setSelection(true);
		foreach (enh, spn; _liveEnh) {
			spn.setSelection(0);
		}
		foreach (enh, spn; _enhRound) {
			spn.setSelection(0);
		}
		_paralyze.setSelection(0);
		_poison.setSelection(0);
		_bind.setSelection(0);
		_silence.setSelection(0);
		_faceUp.setSelection(0);
		_antiMagic.setSelection(0);
		_mtly.select(0);
		_mtlyRound.setSelection(0);
		changeLiveEnhance();
		changeMentality();
		changeLifeUseMax();
	}
	void delCard(CastCard c) {
		if (_card is c) {
			forceCancel();
		}
	}
	void refScenario(Summary summ) {
		forceCancel();
	}
	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			_comm.refRadarStyle.remove(&initPhysical);
			_comm.refRadarStyle.remove(&initEnhance);
			_comm.delCast.remove(&delCard);
			_comm.refScenario.remove(&refScenario);
			_comm.refSkin.remove(&refSkin);
			_comm.refCoupons.remove(&updateNature);
		}
	}
	void refSkin() {
		_desc.font = dwtData(_prop.looks.cardDescFont(_summ.legacy));
		refreshRace();
		refreshSex();
		refreshPeriod();
		refreshNature();
		refreshMakings();
	}
	void refreshRace() {
		_race.setEnabled(!_summ.legacy);
	}
	void refreshSex() {
		foreach (s, b; _sex) {
			auto name = _comm.skin.sexName(s);
			b.setText(_prop.msgs.sex.get(name, name));
		}
	}
	void refreshPeriod() {
		foreach (p, b; _period) {
			auto name = _comm.skin.periodName(p);
			b.setText(_prop.msgs.period.get(name, name));
		}
	}
	void refreshNature() {
		foreach (n, b; _nature) {
			auto name = _comm.skin.natureName(n);
			b.setText(_prop.msgs.nature.get(name, name));
		}
	}
	void refreshMakings() {
		foreach (m, b; _makings) {
			auto name = _comm.skin.makingsName(m);
			b.setText(_prop.msgs.makings.get(name, name));
		}
	}

	void updateNature() {
		if (getShell().isVisible()) getShell().setRedraw(false);
		scope (exit) {
			if (getShell().isVisible()) getShell().setRedraw(true);
		}

		bool first = (0 == _natureComp.getChildren().length);
		string nature = "";
		if (first || _showSpNature != _prop.var.etc.showSpNature) {
			foreach (n, b; _nature) {
				if (b.getSelection()) {
					nature = _comm.skin.natureCoupon(n);
					break;
				}
			}
			foreach (chld; _natureComp.getChildren()) {
				chld.dispose();
			}
			typeof(_nature) tbl;
			_nature = tbl;

			bool selected = false;
			void sep() {
				auto sep = new Label(_natureComp, SWT.SEPARATOR | SWT.HORIZONTAL);
				auto gd = new GridData(GridData.FILL_HORIZONTAL);
				gd.horizontalSpan = 2;
				sep.setLayoutData(gd);
			}
			void put(Nature n) {
				auto name = _comm.skin.natureName(n);
				auto b = createR(_natureComp, _prop.msgs.nature.get(name, name), (_nature.length + 1) % 2);
				_nature[n] = b;
				if (!first && nature == _comm.skin.natureCoupon(n)) {
					b.setSelection(true);
					selected = true;
				}
			}
			foreach (n; NATURE_DEF) {
				put(n);
			}
			if (_prop.var.etc.showSpNature) {
				sep();
				foreach (n; NATURE_EXT) {
					put(n);
				}
			}
			sep();
			_natureU = createR(_natureComp, _prop.msgs.natureUnknown, 1);
			if (!first && !selected) {
				_natureU.setSelection(true);
				selected = true;
			}
		}

		if (!first && _showSpNature != _prop.var.etc.showSpNature) {
			_showSpNature = _prop.var.etc.showSpNature;
			_natureComp.layout(true);
			_natureComp.getParent().layout(true);
			_natureComp.getParent().getParent().layout(true);
			if (_showSpNature) {
				if (_natureU.getSelection()) {
					cp: foreach (i, cp; _couponView.coupons) {
						if (0 == cp.value) {
							foreach (n; NATURE_EXT) {
								if (cp.name == _comm.skin.natureCoupon(n)) {
									_nature[n].setSelection(true);
									_natureU.setSelection(false);
									_couponView.delCoupon(i);
									break cp;
								}
							}
						}
					}
				}
			} else {
				if (_natureU.getSelection() && "" != nature) {
					_couponView.addCoupon(new Coupon(nature, 0));
				}
			}
		}
	}
public:
	this(Commons comm, Props prop, Shell shell, Summary summ, CastCard card) {
		assert (summ !is null);
		_id = format("%08X", &this) ~ "-" ~ to!(string)(Clock.currTime());
		_comm = comm;
		_summ = summ;
		_card = card;
		_prop = prop;
		super(prop, shell, false, _card ? .tryFormat(_prop.msgs.dlgTitCast, _card.name) : _prop.msgs.dlgTitNewCast,
			_prop.images.casts, true, _prop.var.castCardDlg, true);
	}

	@property
	CastCard card() {
		return _card;
	}

	bool openCWXPath(string path, bool shellActivate) {
		return cpempty(path);
	}
protected:
	override void setup(Composite area) {
		area.setLayout(windowGridLayout(1));
		auto tabf = new CTabFolder(area, SWT.BORDER);
		constructBase(tabf);
		constructDesc(tabf);
		constructHistory(tabf);
		constructMakings(tabf);
		constructResist(tabf);
		constructPhysical(tabf);
		constructMental(tabf);
		constructEnhance(tabf);
		constructStatus(tabf);

		_comm.delCast.add(&delCard);
		_comm.refScenario.add(&refScenario);
		_comm.refSkin.add(&refSkin);
		_comm.refCoupons.add(&updateNature);
		_comm.refRadarStyle.add(&initPhysical);
		_comm.refRadarStyle.add(&initEnhance);
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
	private void refCard(CastCard card) {
		if (_card && _card !is card) return;
		ignoreMod = true;
		scope (exit) ignoreMod = false;
		auto skin = _comm.skin;
		if (_card) {
			_imgPath.image = _card.path;
			if (_race) _race.select(0);
			_desc.setText(_card.desc);
			_name.setText(_card.name);
			_level.setSelection(_card.level);
			_lifeMax.setSelection(_card.lifeMax);
			bool sex = false, period = false, nature = false;
			scope makings = new HashSet!(Makings);
			Coupon[] coupons;
			cp: foreach (c; _card.coupons) {
				foreach (s, b; _sex) {
					if (c.name == skin.sexCoupon(s)) {
						if (!sex) b.setSelection(true);
						sex = true;
						continue cp;
					}
				}
				foreach (per, b; _period) {
					if (c.name == skin.periodCoupon(per)) {
						if (!period) b.setSelection(true);
						period = true;
						continue cp;
					}
				}
				foreach (nat, b; _nature) {
					if (c.name == skin.natureCoupon(nat)) {
						if (!nature) b.setSelection(true);
						nature = true;
						continue cp;
					}
				}
				foreach (m, b; _makings) {
					if (c.name == skin.makingsCoupon(m)) {
						if (!makings.contains(m)) b.setSelection(true);
						makings.add(m);
						continue cp;
					}
				}
				if (_race) {
					foreach (i, r; _comm.skin.races) {
						if (c.name == _prop.sys.raceCoupon(r.name)) {
							_race.select(i + 1);
							raceToolTip();
							continue cp;
						}
					}
				}
				coupons ~= new Coupon(c);
			}
			_couponView.coupons = coupons;
			if (!sex) _sexU.setSelection(true);
			if (!period) _periodU.setSelection(true);
			if (!nature) _natureU.setSelection(true);
			_resW.setSelection(_card.weaponResist);
			_resM.setSelection(_card.magicResist);
			_undead.setSelection(_card.undead);
			_automaton.setSelection(_card.automaton);
			_unholy.setSelection(_card.unholy);
			_constructure.setSelection(_card.constructure);
			foreach (e, radio; _res) {
				radio.setSelection(_card.resist(e));
			}
			foreach (e, radio; _weak) {
				radio.setSelection(_card.weakness(e));
			}
			foreach (phy, i; _phyTbl) {
				if (_phyR) {
					_phyR.setValue(i, _card.physical(phy));
				} else {
					_phyS.setValue(i, _card.physical(phy));
				}
			}
			foreach (mtl, scale; _mtl) {
				scale.setSelection(_prop.var.etc.mentalMax + _card.mental(mtl));
			}
			foreach (enh, i; _enhTbl) {
				if (_enhR) {
					_enhR.setValue(i, _card.defaultEnhance(enh));
				} else {
					_enhS.setValue(i, _card.defaultEnhance(enh));
				}
			}

			_life.setSelection(_card.life);
			_lifeUseMax.setSelection(_card.life == _card.lifeMax);
			foreach (enh, spn; _liveEnh) {
				spn.setSelection(_card.enhance(enh));
			}
			foreach (enh, spn; _enhRound) {
				spn.setSelection(_card.enhanceRound(enh));
			}
			_paralyze.setSelection(_card.paralyze);
			_poison.setSelection(_card.poison);
			_bind.setSelection(_card.bindRound);
			_silence.setSelection(_card.silenceRound);
			_faceUp.setSelection(_card.faceUpRound);
			_antiMagic.setSelection(_card.antiMagicRound);
			_mtlyRound.setSelection(_card.mentalityRound);
			changeLiveEnhance();
			changeMentality();
			changeLifeUseMax();
		} else {
			_imgPath.image = "";
			if (_race) _race.select(0);
			_sexU.setSelection(true);
			_periodU.setSelection(true);
			_natureU.setSelection(true);
			int[] phys;
			phys.length = PHYSICALS.length;
			phys[] = _prop.looks.physicalNormal;
			if (_phyR) {
				_phyR.setValues(phys);
			} else {
				_phyS.setValues(phys);
			}
			foreach (radio; _mtl) {
				radio.setSelection(_prop.var.etc.mentalMax);
			}
			int[] bonus;
			bonus.length = ENHANCE.length;
			bonus[] = 0;
			if (_enhR) {
				_enhR.setValues(bonus);
			} else {
				_enhS.setValues(bonus);
			}

			resetLiveStatus();
		}
		setMaxLife();
		modPhysical();
	}

	private Coupon createCoupon(E)(Button[E] radios, string delegate(E) coupon) {
		foreach (e, radio; radios) {
			if (radio.getSelection()) {
				return new Coupon(coupon(e), 0);
			}
		}
		return null;
	}
	override bool apply() {
		if (_card) {
			_card.path = _imgPath.image;
			_card.desc = _desc.getRRText();
			_card.name = _name.getText();
			_card.level = _level.getSelection();
			_card.lifeMax = _lifeMax.getSelection();
			_card.life = _lifeMax.getSelection();
		} else {
			_card = new CastCard(_summ.newId!(CastCard), _name.getText(), _imgPath.image,
				_desc.getRRText(), _level.getSelection(), _lifeMax.getSelection());
		}
		auto skin = _comm.skin;
		string legacyName = skin.legacyName;
		alias contains!("a.name == b.name", Coupon, Coupon) cContains;
		auto tblCoupons = _couponView.coupons;
		Coupon[] cs;
		auto sex = createCoupon!(Sex)(_sex, &skin.sexCoupon);
		if (sex && !cContains(tblCoupons, sex)) cs ~= sex;
		auto race = selectedRace;
		if (race) {
			auto rc = new Coupon(_prop.sys.raceCoupon(race.name), 0);
			if (!cContains(tblCoupons, rc)) cs ~= rc;
		}
		auto period = createCoupon!(Period)(_period, &skin.periodCoupon);
		if (period && !cContains(tblCoupons, period)) cs ~= period;
		auto nature = createCoupon!(Nature)(_nature, &skin.natureCoupon);
		if (nature && !cContains(tblCoupons, nature)) cs ~= nature;
		foreach (m, radio; _makings) {
			if (radio.getSelection()) {
				auto mc = new Coupon(skin.makingsCoupon(m), 0);
				if (!cContains(tblCoupons, mc)) cs ~= mc;
			}
		}
		cs ~= tblCoupons;
		_card.coupons = cs;
		_card.weaponResist = _resW.getSelection();
		_card.magicResist = _resM.getSelection();
		_card.undead = _undead.getSelection();
		_card.automaton = _automaton.getSelection();
		_card.unholy = _unholy.getSelection();
		_card.constructure = _constructure.getSelection();
		foreach (e, radio; _res) {
			_card.resist(e, radio.getSelection());
		}
		foreach (e, radio; _weak) {
			_card.weakness(e, radio.getSelection());
		}
		foreach (phy, i; _phyTbl) {
			if (_phyR) {
				_card.physical(phy, _phyR.getValue(i));
			} else {
				_card.physical(phy, _phyS.getValue(i));
			}
		}
		foreach (mtl, scale; _mtl) {
			_card.mental(mtl, cast(int) scale.getSelection() - _prop.var.etc.mentalMax);
		}
		foreach (enh, i; _enhTbl) {
			if (_enhR) {
				_card.defaultEnhance(enh, _enhR.getValue(i));
			} else {
				_card.defaultEnhance(enh, _enhS.getValue(i));
			}
		}

		_card.life = _lifeUseMax.getSelection() ? _card.lifeMax : _life.getSelection();
		foreach (enh, spn; _liveEnh) {
			if (_enhRound[enh].getSelection() > 0) {
				_card.enhance(enh, spn.getSelection());
			} else {
				_card.enhance(enh, 0);
			}
		}
		foreach (enh, spn; _enhRound) {
			if (_card.enhance(enh) != 0) {
				_card.enhanceRound(enh, spn.getSelection());
			} else {
				_card.enhanceRound(enh, 0);
			}
		}
		_card.paralyze = _paralyze.getSelection();
		_card.poison = _poison.getSelection();
		_card.bindRound = _bind.getSelection();
		_card.silenceRound = _silence.getSelection();
		_card.faceUpRound = _faceUp.getSelection();
		_card.antiMagicRound = _antiMagic.getSelection();
		_card.mentality = _mtlyRound.getSelection() == 0
			? Mentality.NORMAL : _mtlyTbl[_mtly.getSelectionIndex()];
		_card.mentalityRound = _card.mentality == Mentality.NORMAL
			? 0 : _mtlyRound.getSelection();

		_comm.refCoupons.call();
		return true;
	}
}
