
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
import cwx.editor.gui.dwt.cardpane;

import std.algorithm : sort;
import std.array;
import std.datetime;
import std.string;
import std.conv;

import org.eclipse.swt.all;

import java.lang.all;

public:

/// キャストカードの設定を行うダイアログ。
class CastCardDialog : AbsDialog, CardDialog {
private:
	string _id;

	int _readOnly = 0;
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

	Skin _summSkin;
	@property
	Skin summSkin() { mixin(S_TRACE);
		return _summSkin ? _summSkin : _comm.skin;
	}

	void refreshWarning() { mixin(S_TRACE);
		string[] ws;
		if (_name.over) { mixin(S_TRACE);
			ws ~= .tryFormat(_prop.msgs.warningNameLenOver, _prop.looks.castNameLimit, _prop.looks.castNameLimit / 2);
		}
		ws ~= _imgPath.warnings;

		warning = ws;
	}

	@property
	Race selectedRace() { mixin(S_TRACE);
		if (_race) { mixin(S_TRACE);
			int index = _race.getSelectionIndex();
			if (index > 0) { mixin(S_TRACE);
				return summSkin.races[index - 1];
			}
		}
		return null;
	}
	void raceToolTip() { mixin(S_TRACE);
		if (_race) { mixin(S_TRACE);
			auto race = selectedRace;
			_race.setToolTipText(race ? .replace(race.desc, "&", "&&") : "");
		}
	}
	class SelectRace : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			raceToolTip();
		}
	}
	class BasicResist : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			auto race = selectedRace;
			if (race) { mixin(S_TRACE);
				_automaton.setSelection(race.automaton);
				_constructure.setSelection(race.constructure);
				_undead.setSelection(race.undead);
				_unholy.setSelection(race.unholy);
				_resW.setSelection(race.weaponResist);
				_resM.setSelection(race.magicResist);
				foreach (el; _res.keys) { mixin(S_TRACE);
					_res[el].setSelection(race.resist(el));
					_weak[el].setSelection(race.weakness(el));
				}
			} else { mixin(S_TRACE);
				_automaton.setSelection(false);
				_constructure.setSelection(false);
				_undead.setSelection(false);
				_unholy.setSelection(false);
				_resW.setSelection(false);
				_resM.setSelection(false);
				foreach (el; _res.keys) { mixin(S_TRACE);
					_res[el].setSelection(false);
					_weak[el].setSelection(false);
				}
			}
		}
	}
	class BasicEnhance : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			auto race = selectedRace;
			if (race) { mixin(S_TRACE);
				foreach (enh, i; _enhTbl) { mixin(S_TRACE);
					if (_enhR) { mixin(S_TRACE);
						_enhR.setValue(i, race.defaultEnhance(enh));
					} else { mixin(S_TRACE);
						_enhS.setValue(i, race.defaultEnhance(enh));
					}
				}
			} else { mixin(S_TRACE);
				foreach (enh, i; _enhTbl) { mixin(S_TRACE);
					if (_enhR) { mixin(S_TRACE);
						_enhR.setValue(i, 0);
					} else { mixin(S_TRACE);
						_enhS.setValue(i, 0);
					}
				}
			}
		}
	}

	class SelLifeC : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			auto vit = _phyTbl[Physical.VIT];
			auto min = _phyTbl[Physical.MIN];
			_lifeMax.setSelection(_prop.looks.lifeCalc(_level.getSelection(),
				(_phyR ? _phyR.getValue(vit) : _phyS.getValue(vit)),
				(_phyR ? _phyR.getValue(min) : _phyS.getValue(min))));
		}
	}

	void constructBase(CTabFolder tabf) { mixin(S_TRACE);
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(2, false));
		auto skin = summSkin;
		{ mixin(S_TRACE);
			auto comp2 = new Composite(comp, SWT.NONE);
			comp2.setLayoutData(new GridData(GridData.FILL_BOTH));
			comp2.setLayout(zeroMarginGridLayout(1, false));
			{ mixin(S_TRACE);
				auto grp = new Group(comp2, SWT.NONE);
				grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				grp.setLayout(new GridLayout(2, false));
				grp.setText(_prop.msgs.name);
				_name = new GBLimitText(_prop.looks.monospace,
					_prop.looks.castNameLimit, false, grp, SWT.BORDER | _readOnly);
				_name.limitEvent ~= &refreshWarning;
				mod(_name.widget);
				createTextMenu!Text(_comm, _prop, _name.widget, &catchMod);
				auto gd = new GridData(GridData.FILL_HORIZONTAL);
				gd.widthHint = _name.computeSize(SWT.DEFAULT, SWT.DEFAULT).x;
				_name.widget.setLayoutData(gd);
				auto l = new Label(grp, SWT.NONE);
				l.setText(.tryFormat(_prop.msgs.nameLimit, _prop.looks.castNameLimit, _prop.looks.castNameLimit / 2));
			}
			{ mixin(S_TRACE);
				_imgPath = new ImageSelect!(MtType.CARD)(comp2, _readOnly, _comm, _prop, _summ,
					_prop.looks.cardSize.width, _prop.looks.cardSize.height, true, &_name.getText);
				mod(_imgPath);
				_imgPath.modEvent ~= &refreshWarning;
				_imgPath.widget.setLayoutData(new GridData(GridData.FILL_BOTH));
				_imgPath.cardMode = CardMode.Cast;
			}
		}
		{ mixin(S_TRACE);
			auto compr = new Composite(comp, SWT.NONE);
			compr.setLayoutData(new GridData(GridData.FILL_VERTICAL));
			compr.setLayout(zeroMarginGridLayout(1, false));
			{ mixin(S_TRACE);
				auto grp = new Group(compr, SWT.NONE);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setLayout(new CenterLayout);
				grp.setText(_prop.msgs.level);
				auto comp2 = new Composite(grp, SWT.NONE);
				comp2.setLayout(zeroMarginGridLayout(2, false));
				_level = new Spinner(comp2, SWT.BORDER | _readOnly);
				initSpinner(_level);
				mod(_level);
				_level.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				_level.setMinimum(1);
				_level.setMaximum(_prop.var.etc.castLevelMax);
				auto hint = new Label(comp2, SWT.RIGHT);
				hint.setText(.tryFormat(_prop.msgs.rangeHint, 1, _prop.var.etc.castLevelMax));
			}
			{ mixin(S_TRACE);
				auto grp = new Group(compr, SWT.NONE);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setLayout(new CenterLayout);
				grp.setText(_prop.msgs.life);
				auto comp2 = new Composite(grp, SWT.NONE);
				comp2.setLayout(zeroMarginGridLayout(2, false));
				_lifeMax = new Spinner(comp2, SWT.BORDER | _readOnly);
				initSpinner(_lifeMax);
				mod(_lifeMax);
				_lifeMax.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				_lifeMax.setMinimum(1);
				_lifeMax.setMaximum(_prop.var.etc.lifeMax);
				_lifeMax.addModifyListener(new LifeMaxL);
				auto hint = new Label(comp2, SWT.RIGHT);
				hint.setText(.tryFormat(_prop.msgs.rangeHint, 1, _prop.var.etc.lifeMax));
				auto lifec = new Button(comp2, SWT.PUSH);
				mod(lifec);
				lifec.setEnabled(!_readOnly);
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
			_race.setEnabled(!_readOnly);
			_race.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
			_race.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			_race.add(_prop.msgs.defaultSelection(_prop.msgs.noRace));
			foreach (race; skin.races) { mixin(S_TRACE);
				_race.add(race.name);
			}
			_race.addSelectionListener(new SelectRace);
			refDataVersion();
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.card);
		tab.setControl(comp);
	}
	void setMaxLife() { mixin(S_TRACE);
		_life.setMaximum(_lifeMax.getSelection());
		if (_lifeUseMax.getSelection()) { mixin(S_TRACE);
			_life.setSelection(_lifeMax.getSelection());
		}
		_life.getParent().layout();
		_life.setSelection(_life.getSelection());
	}
	class LifeMaxL : ModifyListener {
		public override void modifyText(ModifyEvent e) { mixin(S_TRACE);
			setMaxLife();
		}
	}
	void constructDesc(CTabFolder tabf) { mixin(S_TRACE);
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(2, false));
		{ mixin(S_TRACE);
			auto grp = new Group(comp, SWT.NONE);
			auto gd = new GridData(GridData.FILL_BOTH);
			grp.setLayoutData(gd);
			gd.horizontalSpan = 2;
			auto cl = new CenterLayout(SWT.HORIZONTAL);
			cl.fillVertical = true;
			grp.setLayout(cl);
			grp.setText(_prop.msgs.desc);
			_desc = new FixedWidthText(dwtData(_prop.looks.cardDescFont(summSkin.legacy)), _prop.looks.cardDescLen, grp, SWT.BORDER | _readOnly);
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
	Button createR(Composite parent, string name, int hAlignHint = -1) { mixin(S_TRACE);
		auto radio = new Button(parent, SWT.RADIO);
		mod(radio);
		radio.setEnabled(!_readOnly);
		auto gd = new GridData(GridData.FILL_BOTH);
		if (0 <= hAlignHint) { mixin(S_TRACE);
			hAlignHint %= 2;
			gd.grabExcessHorizontalSpace = true;
			if (0 == hAlignHint) { mixin(S_TRACE);
				gd.horizontalAlignment = SWT.LEFT;
			} else { mixin(S_TRACE);
				gd.horizontalAlignment = SWT.RIGHT;
			}
		}
		radio.setLayoutData(gd);
		radio.setText(name);
		return radio;
	}
	void constructHistory(CTabFolder tabf) { mixin(S_TRACE);
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(2, false));
		auto skin = summSkin;
		{ mixin(S_TRACE);
			auto grp = new Group(comp, SWT.NONE);
			grp.setText(_prop.msgs.coupons);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(new GridLayout(1, true));
			_couponView = new CouponView!(CVType.Cast)(_comm, _summ, grp, _readOnly, &catchMod, true);
			_couponView.setLayoutData(new GridData(GridData.FILL_BOTH));
			mod(_couponView);
		}
		{ mixin(S_TRACE);
			auto comp2 = new Composite(comp, SWT.NONE);
			comp2.setLayoutData(new GridData(GridData.FILL_VERTICAL));
			comp2.setLayout(zeroMarginGridLayout(2, false));
			{ mixin(S_TRACE);
				auto comp3 = createButtonGroup(comp2, _prop.msgs.sexTitle, 1, 1);
				foreach (s; skin.allSexes) { mixin(S_TRACE);
					auto name = skin.sexName(s);
					_sex[s] = createR(comp3, _prop.msgs.sex.get(name, name));
				}
				_sexU = createR(comp3, _prop.msgs.sexUnknown);
			}
			{ mixin(S_TRACE);
				auto comp3 = createButtonGroup(comp2, _prop.msgs.periodTitle, 2, 1);
				foreach (p; skin.allPeriods) { mixin(S_TRACE);
					auto name = skin.periodName(p);
					_period[p] = createR(comp3, _prop.msgs.period.get(name, name));
				}
				_periodU = createR(comp3, _prop.msgs.periodUnknown);
			}
			{ mixin(S_TRACE);
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
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			auto radio = cast(Button) e.widget;
			if (radio.getSelection()) { mixin(S_TRACE);
				auto skin = summSkin;
				auto m = cast(Makings) (cast(Integer) radio.getData()).intValue();
				auto r = skin.reverseMakings(m);
				_makings[r].setSelection(false);
			}
		}
	};
	void constructMakings(CTabFolder tabf) { mixin(S_TRACE);
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, false));
		auto skin = summSkin;
		{ mixin(S_TRACE);
			auto comp3 = createButtonGroup(comp, _prop.msgs.coupons, 4, 1, true);
			auto sl = new MSListener;
			foreach (m; skin.leftMakings) { mixin(S_TRACE);
				void createR(Makings m) { mixin(S_TRACE);
					auto radio = new Button(comp3, SWT.CHECK);
					mod(radio);
					radio.setEnabled(!_readOnly);
					radio.setLayoutData(new GridData(GridData.FILL_BOTH));
					auto name = skin.makingsName(m);
					radio.setText(_prop.msgs.makings.get(name, name));
					radio.setData(new Integer(cast(int)m));
					radio.addSelectionListener(sl);
					_makings[m] = radio;
				}
				createR(m);
				createR(skin.reverseMakings(m));
			}
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.makingsTitle);
		tab.setControl(comp);
	}
	Composite createButtonGroup(Composite parent, string name,
			int row, int horSpan = 1, bool min = false) { mixin(S_TRACE);
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
		this(Button targ) { mixin(S_TRACE);
			_targ = targ;
		}
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			auto radio = cast(Button) e.widget;
			if (radio.getSelection()) { mixin(S_TRACE);
				_targ.setSelection(false);
			}
		}
	};
	void constructResist(CTabFolder tabf) { mixin(S_TRACE);
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, false));
		Button createC(Composite parent, string name, string desc) { mixin(S_TRACE);
			auto comp = new Composite(parent, SWT.NONE);
			comp.setLayoutData(new GridData(GridData.FILL_BOTH));
			comp.setLayout(zeroGridLayout(2, false));
			auto c = new Button(comp, SWT.CHECK);
			mod(c);
			c.setEnabled(!_readOnly);
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
		{ mixin(S_TRACE);
			Composite tcomp, bcomp;
			{ mixin(S_TRACE);
				tcomp = createButtonGroup(comp, _prop.msgs.tolerantBase, 2, 1);
				auto gl = cast(GridLayout) tcomp.getLayout();
				gl.horizontalSpacing = 15;
				_resW = createC(tcomp, _prop.msgs.resistWeapon, _prop.msgs.descResistWeapon);
				_resM = createC(tcomp, _prop.msgs.resistMagic, _prop.msgs.descResistMagic);
			}
			{ mixin(S_TRACE);
				bcomp = createButtonGroup(comp, _prop.msgs.tolerantElement, 2, 1);
				auto gl = cast(GridLayout) bcomp.getLayout();
				gl.horizontalSpacing = 15;
				_undead = createC(bcomp, _prop.msgs.undead, _prop.msgs.descUndead);
				_automaton = createC(bcomp, _prop.msgs.automaton, _prop.msgs.descAutomaton);
				_unholy = createC(bcomp, _prop.msgs.unholy, _prop.msgs.descUnholy);
				_constructure = createC(bcomp, _prop.msgs.constructure, _prop.msgs.descConstructure);
				foreach (e; [Element.FIRE, Element.ICE]) { mixin(S_TRACE);
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
		{ mixin(S_TRACE);
			auto basic = new Button(comp, SWT.PUSH);
			mod(basic);
			basic.setEnabled(!_readOnly);
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
	void initPhysical() { mixin(S_TRACE);
		int[] values = [];
		if (_phyR) { mixin(S_TRACE);
			values = _phyR.getValues();
			_phyR.dispose();
			_phyR = null;
		}
		if (_phyS) { mixin(S_TRACE);
			values = _phyS.getValues();
			_phyS.dispose();
			_phyS = null;
		}

		string[] names;
		names.length = PHYSICALS.length;
		int[Physical] table;
		foreach (i, p; PHYSICALS) { mixin(S_TRACE);
			table[p] = cast(int)i;
			names[i] = _prop.msgs.physicalName(p);
		}
		_phyTbl = table;
		int page = _prop.var.etc.physicalMax / 5;

		if (_prop.var.etc.radarStyleParams) { mixin(S_TRACE);
			_phyR = new RadarSpinner(_phyParent, _readOnly);
			_phyR.setRadar(_prop.var.etc.physicalMax + 1, names, 0);
			_phyR.antialias = true;
			_phyR.borderlines = cast(int[]) _prop.looks.physicalBorders;
			_phyR.lineStep = page;
			if (values.length) _phyR.setValues(values);
			mod(_phyR);
			_phyR.modEvent ~= &modPhysical;
		} else { mixin(S_TRACE);
			_phyS = new Scales(_phyParent, _readOnly);
			_phyS.setScales(_prop.var.etc.physicalMax + 1, names, page, 0);
			_phyS.borderlines = cast(int[]) _prop.looks.physicalBorders;
			if (values.length) _phyS.setValues(values);
			mod(_phyS);
			_phyS.modEvent ~= &modPhysical;
		}
		_phyParent.layout();
	}
	void modPhysical() { mixin(S_TRACE);
		int[] vals;
		if (_phyR) vals = _phyR.getValues();
		if (_phyS) vals = _phyS.getValues();
		int sum = 0;
		foreach (val; vals) { mixin(S_TRACE);
			sum += val;
		}
		_sumPhy.setText(.tryFormat(_prop.msgs.physicalSum, sum));
	}
	void constructPhysical(CTabFolder tabf) { mixin(S_TRACE);
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(2, false));
		{ mixin(S_TRACE);
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
		{ mixin(S_TRACE);
			_sumPhy = new Label(comp, SWT.NONE);
			_sumPhy.setLayoutData(new GridData(GridData.FILL_HORIZONTAL|GridData.HORIZONTAL_ALIGN_BEGINNING));
		}
		{ mixin(S_TRACE);
			auto basic = new Button(comp, SWT.PUSH);
			mod(basic);
			basic.setEnabled(!_readOnly);
			basic.setText(_prop.msgs.physicalCalc);
			basic.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
			basic.addSelectionListener(new CalcPhysical);
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.physicalParams);
		tab.setControl(comp);
	}
	real calcPhy(E)(in Skin skin, Physical phy, Button[E] radios, bool all) { mixin(S_TRACE);
		real r = 0.0;
		foreach (e, radio; radios) { mixin(S_TRACE);
			if (radio.getSelection()) { mixin(S_TRACE);
				r += skin.physicalMod(e, phy);
				if (!all) break;
			}
		}
		return r;
	}
	class CalcPhysical : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			real[Physical] p;
			int[Physical] min;
			int[Physical] max;
			auto race = selectedRace;
			foreach (phy; _phyTbl.keys) { mixin(S_TRACE);
				int pmin = _prop.looks.physicalCutMin;
				int pmax;
				if (race) { mixin(S_TRACE);
					int v = race.physical(phy);
					pmax = v + _prop.looks.physicalCutMaxBase;
					if (pmax > _prop.var.etc.physicalMax) pmax = _prop.var.etc.physicalMax;
					if (v < pmin) pmin = v;
					p[phy] = v;
				} else { mixin(S_TRACE);
					int v = _prop.looks.physicalNormal;
					pmax = v + _prop.looks.physicalCutMaxBase;
					p[phy] = v;
				}
				min[phy] = pmin;
				max[phy] = pmax;
			}
			foreach (phy, val; p) { mixin(S_TRACE);
				val += calcPhy!(Sex)(summSkin, phy, _sex, false);
				val += calcPhy!(Period)(summSkin, phy, _period, false);
				val += calcPhy!(Nature)(summSkin, phy, _nature, false);
				val += calcPhy!(Makings)(summSkin, phy, _makings, true);
				p[phy] = val;
			}
			int[] vals;
			vals.length = p.length;
			foreach (phy, val; p) { mixin(S_TRACE);
				int v = cast(int) val;
				if (v < min[phy]) v = min[phy];
				if (v > max[phy]) v = max[phy];
				vals[_phyTbl[phy]] = v;
			}
			if (_phyR) { mixin(S_TRACE);
				_phyR.setValues(vals);
			} else { mixin(S_TRACE);
				_phyS.setValues(vals);
			}
			modPhysical();
		}
	}
	void constructMental(CTabFolder tabf) { mixin(S_TRACE);
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, false));
		{ mixin(S_TRACE);
			auto grp = new Group(comp, SWT.NONE);
			grp.setText(_prop.msgs.mentalParams);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto ggl = new GridLayout(3, false);
			ggl.verticalSpacing = 0;
			grp.setLayout(ggl);
			static const Ms = [Mental.AGGRESSIVE, Mental.CHEERFUL, Mental.BRAVE,
				Mental.CAUTIOUS, Mental.TRICKISH];
			foreach (m; Ms) { mixin(S_TRACE);
				auto minl = new Label(grp, SWT.NONE);
				minl.setText(_prop.msgs.mentalName(reverseMental(m)));
				auto scale = new Scale(grp, SWT.NONE);
				mod(scale);
				scale.setEnabled(!_readOnly);
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
		{ mixin(S_TRACE);
			auto basic = new Button(comp, SWT.PUSH);
			mod(basic);
			basic.setEnabled(!_readOnly);
			basic.setText(_prop.msgs.mentalCalc);
			basic.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
			basic.addSelectionListener(new CalcMental);
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.mentalParams);
		tab.setControl(comp);
	}
	real calcMtl(E)(in Skin skin, Mental mtl, Button[E] radios, bool all) { mixin(S_TRACE);
		real r = 0.0;
		foreach (e, radio; radios) { mixin(S_TRACE);
			if (radio.getSelection()) { mixin(S_TRACE);
				r += skin.mentalMod(e, mtl);
				if (!all) break;
			}
		}
		return r;
	}
	class CalcMental : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			auto race = selectedRace;
			foreach (mtl, scale; _mtl) { mixin(S_TRACE);
				int min = cast(int) _prop.looks.mentalCut * -1;
				int max = _prop.looks.mentalCut;
				real val;
				if (race) { mixin(S_TRACE);
					val = race.mental(mtl);
					auto iVal = cast(int)(val < 0 ? val + 0.5 : val - 0.5);
					if (iVal < min) min = iVal;
					if (iVal > max) max = iVal;
				} else { mixin(S_TRACE);
					val = 0.0;
				}
				val += calcMtl!(Sex)(summSkin, mtl, _sex, false);
				val += calcMtl!(Period)(summSkin, mtl, _period, false);
				val += calcMtl!(Nature)(summSkin, mtl, _nature, false);
				val += calcMtl!(Makings)(summSkin, mtl, _makings, true);
				auto v = cast(int)(val < 0 ? val + 0.5 : val - 0.5);
				if (v < min) v = min;
				if (v > max) v = max;
				scale.setSelection(v + _prop.var.etc.mentalMax);
			}
		}
	}
	static immutable ENHANCE = [Enhance.AVOID, Enhance.RESIST, Enhance.DEFENSE];
	void initEnhance() { mixin(S_TRACE);
		int[] values = [];
		if (_enhR) { mixin(S_TRACE);
			values = _enhR.getValues();
			_enhR.dispose();
			_enhR = null;
		}
		if (_enhS) { mixin(S_TRACE);
			values = _enhS.getValues();
			_enhS.dispose();
			_enhS = null;
		}

		string[] names;
		names.length = ENHANCE.length;
		foreach (i, enh; ENHANCE) { mixin(S_TRACE);
			_enhTbl[enh] = cast(int)i;
			names[i] = .tryFormat(_prop.msgs.enhanceBonus, _prop.msgs.enhanceName(enh));
		}
		int stepC = _prop.var.etc.enhanceMax * 2 + 1;
		int min = cast(int) _prop.var.etc.enhanceMax * -1;
		int page = _prop.var.etc.enhanceMax / 2;
		if (_prop.var.etc.radarStyleParams) { mixin(S_TRACE);
			_enhR = new RadarSpinner(_enhParent, _readOnly);
			_enhR.setRadar(stepC, names, min);
			_enhR.antialias = true;
			_enhR.borderlines = [0];
			_enhR.lineStep = page;
			if (values.length) _enhR.setValues(values);
			mod(_enhR);
		} else { mixin(S_TRACE);
			_enhS = new Scales(_enhParent, _readOnly);
			_enhS.setScales(stepC, names, page, min);
			_enhS.borderlines = [0];
			if (values.length) _enhS.setValues(values);
			mod(_enhS);
		}
		_enhParent.layout();
	}
	void constructEnhance(CTabFolder tabf) { mixin(S_TRACE);
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, false));
		{ mixin(S_TRACE);
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
		{ mixin(S_TRACE);
			auto basic = new Button(comp, SWT.PUSH);
			mod(basic);
			basic.setEnabled(!_readOnly);
			basic.setText(_prop.msgs.basicEnhance);
			basic.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
			basic.addSelectionListener(new BasicEnhance);
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.castEnhance);
		tab.setControl(comp);
	}
	void constructStatus(CTabFolder tabf) { mixin(S_TRACE);
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, false));
		Label[] lbls1, lbls2;
		Spinner createSpn(Composite comp, int max, int min) { mixin(S_TRACE);
			auto spn = new Spinner(comp, SWT.BORDER | _readOnly);
			initSpinner(spn);
			mod(spn);
			spn.setMaximum(max);
			spn.setMinimum(min);
			return spn;
		}
		Composite createGrp(string text) { mixin(S_TRACE);
			auto grp = new Group(comp, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto gl = new GridLayout(2, false);
			gl.horizontalSpacing = 15;
			grp.setLayout(gl);
			grp.setText(text);
			return grp;
		}
		Composite createComp(Composite grp) { mixin(S_TRACE);
			auto comp2 = new Composite(grp, SWT.NONE);
			comp2.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto rl = new RowLayout(SWT.HORIZONTAL);
			rl.center = true;
			rl.wrap = false;
			rl.marginLeft = 0;
			rl.marginRight = 0;
			rl.marginTop = 0;
			rl.marginBottom = 0;
			comp2.setLayout(rl);
			return comp2;
		}
		{ mixin(S_TRACE);
			auto grp = createGrp(_prop.msgs.lifeAndMentality);
			{ mixin(S_TRACE);
				auto comp2 = createComp(grp);
				auto l = new Label(comp2, SWT.NONE);
				l.setText(_prop.msgs.life);
				lbls1 ~= l;
				_life = new Spinner(comp2, SWT.BORDER | _readOnly);
				initSpinner(_life);
				mod(_life);
				_lifeUseMax = new Button(comp2, SWT.CHECK);
				mod(_lifeUseMax);
				_lifeUseMax.setEnabled(!_readOnly);
				_lifeUseMax.setText(_prop.msgs.useMax);
				_lifeUseMax.addSelectionListener(new LifeUseMax);
			}
			{ mixin(S_TRACE);
				auto comp2 = createComp(grp);
				auto lm = new Label(comp2, SWT.NONE);
				lm.setText(_prop.msgs.mentality);
				lbls1 ~= lm;
				_mtly = new Combo(comp2, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
				mod(_mtly);
				_mtly.setEnabled(!_readOnly);
				_mtly.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
				foreach (i, mtly; [Mentality.NORMAL, Mentality.SLEEP, Mentality.CONFUSE,
						Mentality.OVERHEAT, Mentality.BRAVE, Mentality.PANIC]) { mixin(S_TRACE);
					_mtly.add(_prop.msgs.mentalityName(mtly));
					_mtlyTbl[cast(int)i] = mtly;
					if (_card && _card.mentality is mtly) { mixin(S_TRACE);
						_mtly.select(cast(int)i);
					}
				}
				if (_mtly.getSelectionIndex() < 0) _mtly.select(0);
				_mtly.addSelectionListener(new SelMentality);
				_mtlyRound = createSpn(comp2, _prop.var.etc.roundMax, Motion.round_min);
				auto lm2  = new Label(comp2, SWT.NONE);
				lm2.setText(_prop.msgs.unitRound);
			}
		}
		{ mixin(S_TRACE);
			auto grp = createGrp(_prop.msgs.enhanceLiveBonus);
			foreach (enh; [Enhance.ACTION, Enhance.AVOID, Enhance.RESIST, Enhance.DEFENSE]) { mixin(S_TRACE);
				auto comp2 = createComp(grp);
				auto l = new Label(comp2, SWT.NONE);
				l.setText(_prop.msgs.enhanceLiveBonusName(enh));
				lbls1 ~= l;
				auto spn = createSpn(comp2, _prop.var.etc.enhanceMax, -(cast(int) _prop.var.etc.enhanceMax));
				_liveEnh[enh] = spn;
				auto rnd = createSpn(comp2, _prop.var.etc.roundMax, Motion.round_min);
				_enhRound[enh] = rnd;
				auto l2  = new Label(comp2, SWT.NONE);
				l2.setText(_prop.msgs.unitRound);
				spn.addSelectionListener(new LiveEnh);
			}
		}
		Spinner createStSpn(Composite grp, string name, uint max, string val) { mixin(S_TRACE);
			auto comp2 = createComp(grp);
			auto l = new Label(comp2, SWT.NONE);
			l.setText(name);
			lbls1 ~= l;
			auto spn = createSpn(comp2, max, 0);
			auto l2  = new Label(comp2, SWT.NONE);
			l2.setText(val);
			lbls2 ~= l2;
			return spn;
		}
		{ mixin(S_TRACE);
			auto grp = createGrp(_prop.msgs.status);
			_paralyze = createStSpn(grp, _prop.msgs.paralyze, _prop.var.etc.paralyzeMax, _prop.msgs.unitValue);
			_poison = createStSpn(grp, _prop.msgs.poison, _prop.var.etc.poisonMax, _prop.msgs.unitValue);
			_bind = createStSpn(grp, _prop.msgs.bind, _prop.var.etc.roundMax, _prop.msgs.unitRound);
			_silence = createStSpn(grp, _prop.msgs.silence, _prop.var.etc.roundMax, _prop.msgs.unitRound);
			_faceUp = createStSpn(grp, _prop.msgs.faceUp, _prop.var.etc.roundMax, _prop.msgs.unitRound);
			_antiMagic = createStSpn(grp, _prop.msgs.antiMagic, _prop.var.etc.roundMax, _prop.msgs.unitRound);
		}
		void setlblw(Label[] lbls) { mixin(S_TRACE);
			int maxW = 0;
			foreach (lbl; lbls) { mixin(S_TRACE);
				int w = lbl.computeSize(SWT.DEFAULT, SWT.DEFAULT).x;
				if (maxW < w) maxW = w;
			}
			foreach (lbl; lbls) { mixin(S_TRACE);
				auto gd = new RowData(maxW, SWT.DEFAULT);
				lbl.setLayoutData(gd);
			}
		}
		setlblw(lbls1);
		setlblw(lbls2);
		{ mixin(S_TRACE);
			auto reset = new Button(comp, SWT.PUSH);
			mod(reset);
			reset.setEnabled(!_readOnly);
			reset.setText(_prop.msgs.resetLiveStatus);
			reset.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
			reset.addSelectionListener(new ResetLiveStatus);
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.liveStatus);
		tab.setControl(comp);
	}
	class LiveEnh : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			changeLiveEnhance();
		}
	}
	class SelMentality : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			changeMentality();
		}
	}
	class LifeUseMax : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			changeLifeUseMax();
		}
	}
	class ResetLiveStatus : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			resetLiveStatus();
		}
	}
	void changeLiveEnhance() { mixin(S_TRACE);
		foreach (enh, spn; _liveEnh) { mixin(S_TRACE);
			_enhRound[enh].setEnabled(!_readOnly && spn.getSelection() != 0);
		}
	}
	void changeMentality() { mixin(S_TRACE);
		_mtlyRound.setEnabled(!_readOnly && _mtly.getSelectionIndex() != 0);
	}
	void changeLifeUseMax() { mixin(S_TRACE);
		_life.setEnabled(!_readOnly && !_lifeUseMax.getSelection());
	}
	void resetLiveStatus() { mixin(S_TRACE);
		_life.setSelection(_lifeMax.getSelection());
		_lifeUseMax.setSelection(true);
		foreach (enh, spn; _liveEnh) { mixin(S_TRACE);
			spn.setSelection(0);
		}
		foreach (enh, spn; _enhRound) { mixin(S_TRACE);
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
	void delCard(CastCard c) { mixin(S_TRACE);
		if (_card is c) { mixin(S_TRACE);
			forceCancel();
		}
	}
	void refScenario(Summary summ) { mixin(S_TRACE);
		forceCancel();
	}
	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			_comm.refRadarStyle.remove(&initPhysical);
			_comm.refRadarStyle.remove(&initEnhance);
			_comm.delCast.remove(&delCard);
			_comm.refScenario.remove(&refScenario);
			_comm.refSkin.remove(&refSkin);
			_comm.refDataVersion.remove(&refDataVersion);
			_comm.refCoupons.remove(&updateNature);
		}
	}
	void refSkin() { mixin(S_TRACE);
		_desc.font = dwtData(_prop.looks.cardDescFont(summSkin.legacy));
		refreshSex();
		refreshPeriod();
		refreshNature();
		refreshMakings();
	}
	void refDataVersion() { mixin(S_TRACE);
		refreshWarning();
		_race.setEnabled(!_readOnly && !_summ.legacy);
	}
	void refreshSex() { mixin(S_TRACE);
		foreach (s, b; _sex) { mixin(S_TRACE);
			auto name = summSkin.sexName(s);
			b.setText(_prop.msgs.sex.get(name, name));
		}
	}
	void refreshPeriod() { mixin(S_TRACE);
		foreach (p, b; _period) { mixin(S_TRACE);
			auto name = summSkin.periodName(p);
			b.setText(_prop.msgs.period.get(name, name));
		}
	}
	void refreshNature() { mixin(S_TRACE);
		foreach (n, b; _nature) { mixin(S_TRACE);
			auto name = summSkin.natureName(n);
			b.setText(_prop.msgs.nature.get(name, name));
		}
	}
	void refreshMakings() { mixin(S_TRACE);
		foreach (m, b; _makings) { mixin(S_TRACE);
			auto name = summSkin.makingsName(m);
			b.setText(_prop.msgs.makings.get(name, name));
		}
	}

	void updateNature() { mixin(S_TRACE);
		if (getShell().isVisible()) getShell().setRedraw(false);
		scope (exit) {
			if (getShell().isVisible()) getShell().setRedraw(true);
		}

		bool first = (0 == _natureComp.getChildren().length);
		string nature = "";
		auto skin = summSkin;
		if (first || _showSpNature != _prop.var.etc.showSpNature) { mixin(S_TRACE);
			foreach (n, b; _nature) { mixin(S_TRACE);
				if (b.getSelection()) { mixin(S_TRACE);
					nature = summSkin.natureCoupon(n);
					break;
				}
			}
			foreach (chld; _natureComp.getChildren()) { mixin(S_TRACE);
				chld.dispose();
			}
			typeof(_nature) tbl;
			_nature = tbl;

			bool selected = false;
			void sep() { mixin(S_TRACE);
				auto sep = new Label(_natureComp, SWT.SEPARATOR | SWT.HORIZONTAL);
				auto gd = new GridData(GridData.FILL_HORIZONTAL);
				gd.horizontalSpan = 2;
				sep.setLayoutData(gd);
			}
			void put(Nature n) { mixin(S_TRACE);
				auto name = summSkin.natureName(n);
				auto b = createR(_natureComp, _prop.msgs.nature.get(name, name), (_nature.length + 1) % 2);
				_nature[n] = b;
				if (!first && nature == summSkin.natureCoupon(n)) { mixin(S_TRACE);
					b.setSelection(true);
					selected = true;
				}
			}
			foreach (n; skin.normalNatures) { mixin(S_TRACE);
				put(n);
			}
			if (_prop.var.etc.showSpNature) { mixin(S_TRACE);
				sep();
				foreach (n; skin.extraNatures) { mixin(S_TRACE);
					put(n);
				}
			}
			sep();
			_natureU = createR(_natureComp, _prop.msgs.natureUnknown, 1);
			if (!first && !selected) { mixin(S_TRACE);
				_natureU.setSelection(true);
				selected = true;
			}
		}

		if (!first && _showSpNature != _prop.var.etc.showSpNature) { mixin(S_TRACE);
			_showSpNature = _prop.var.etc.showSpNature;
			_natureComp.layout(true);
			_natureComp.getParent().layout(true);
			_natureComp.getParent().getParent().layout(true);
			if (_showSpNature) { mixin(S_TRACE);
				if (_natureU.getSelection()) { mixin(S_TRACE);
					cp: foreach (i, cp; _couponView.coupons) { mixin(S_TRACE);
						if (0 == cp.value) { mixin(S_TRACE);
							foreach (n; skin.extraNatures) { mixin(S_TRACE);
								if (cp.name == summSkin.natureCoupon(n)) { mixin(S_TRACE);
									_nature[n].setSelection(true);
									_natureU.setSelection(false);
									_couponView.delCoupon([cast(int)i]);
									break cp;
								}
							}
						}
					}
				}
			} else { mixin(S_TRACE);
				if (_natureU.getSelection() && "" != nature) { mixin(S_TRACE);
					_couponView.addCoupon(new Coupon(nature, 0));
				}
			}
		}
	}

public:
	this(Commons comm, Props prop, Shell shell, Summary summ, CastCard card, bool readOnly) { mixin(S_TRACE);
		assert (summ !is null);
		auto o = this;
		_id = format("%08X", &o) ~ "-" ~ to!(string)(Clock.currTime());
		_comm = comm;
		_summ = summ;
		_card = card;
		_prop = prop;
		_readOnly = readOnly ? SWT.READ_ONLY : SWT.NONE;
		if (_readOnly) _summSkin = findSkin(_comm, _prop, _summ);
		super(prop, shell, _readOnly, false, _card ? .tryFormat(_prop.msgs.dlgTitCast, _card.name) : _prop.msgs.dlgTitNewCast,
			_prop.images.casts, true, _prop.var.castCardDlg, true);
	}

	@property
	override
	CastCard card() { mixin(S_TRACE);
		return _card;
	}

	bool openCWXPath(string path, bool shellActivate) { mixin(S_TRACE);
		return cpempty(path);
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
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
		_comm.refDataVersion.add(&refDataVersion);
		_comm.refCoupons.add(&updateNature);
		_comm.refRadarStyle.add(&initPhysical);
		_comm.refRadarStyle.add(&initEnhance);
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
	private void refCard(CastCard card) { mixin(S_TRACE);
		if (_card && _card !is card) return;
		ignoreMod = true;
		scope (exit) ignoreMod = false;
		auto skin = summSkin;
		if (_card) { mixin(S_TRACE);
			_imgPath.images = _card.paths;
			if (_race) _race.select(0);
			_desc.setText(_card.desc);
			_name.setText(_card.name);
			_level.setSelection(_card.level);
			_lifeMax.setSelection(_card.lifeMax);
			bool sex = false, period = false, nature = false;
			scope makings = new HashSet!(Makings);
			Coupon[] coupons;
			cp: foreach (c; _card.coupons) { mixin(S_TRACE);
				foreach (s, b; _sex) { mixin(S_TRACE);
					if (c.name == skin.sexCoupon(s)) { mixin(S_TRACE);
						if (!sex) b.setSelection(true);
						sex = true;
						continue cp;
					}
				}
				foreach (per, b; _period) { mixin(S_TRACE);
					if (c.name == skin.periodCoupon(per)) { mixin(S_TRACE);
						if (!period) b.setSelection(true);
						period = true;
						continue cp;
					}
				}
				foreach (nat, b; _nature) { mixin(S_TRACE);
					if (c.name == skin.natureCoupon(nat)) { mixin(S_TRACE);
						if (!nature) b.setSelection(true);
						nature = true;
						continue cp;
					}
				}
				foreach (m, b; _makings) { mixin(S_TRACE);
					if (c.name == skin.makingsCoupon(m)) { mixin(S_TRACE);
						if (!makings.contains(m)) b.setSelection(true);
						makings.add(m);
						continue cp;
					}
				}
				if (_race) { mixin(S_TRACE);
					foreach (i, r; summSkin.races) { mixin(S_TRACE);
						if (c.name == _prop.sys.raceCoupon(r.name)) { mixin(S_TRACE);
							_race.select(cast(int)i + 1);
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
			foreach (e, radio; _res) { mixin(S_TRACE);
				radio.setSelection(_card.resist(e));
			}
			foreach (e, radio; _weak) { mixin(S_TRACE);
				radio.setSelection(_card.weakness(e));
			}
			foreach (phy, i; _phyTbl) { mixin(S_TRACE);
				if (_phyR) { mixin(S_TRACE);
					_phyR.setValue(i, _card.physical(phy));
				} else { mixin(S_TRACE);
					_phyS.setValue(i, _card.physical(phy));
				}
			}
			foreach (mtl, scale; _mtl) { mixin(S_TRACE);
				auto mVal = _card.mental(mtl);
				if (cast(int)mVal != mVal) { mixin(S_TRACE);
					mVal = mVal < 0 ? mVal + 0.5 : mVal - 0.5;
				}
				scale.setSelection(_prop.var.etc.mentalMax + cast(int)mVal);
			}
			foreach (enh, i; _enhTbl) { mixin(S_TRACE);
				if (_enhR) { mixin(S_TRACE);
					_enhR.setValue(i, _card.defaultEnhance(enh));
				} else { mixin(S_TRACE);
					_enhS.setValue(i, _card.defaultEnhance(enh));
				}
			}

			_life.setSelection(_card.life);
			_lifeUseMax.setSelection(_card.life == _card.lifeMax);
			foreach (enh, spn; _liveEnh) { mixin(S_TRACE);
				spn.setSelection(_card.enhance(enh));
			}
			foreach (enh, spn; _enhRound) { mixin(S_TRACE);
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
		} else { mixin(S_TRACE);
			_imgPath.images = [];
			if (_race) _race.select(0);
			_sexU.setSelection(true);
			_periodU.setSelection(true);
			_natureU.setSelection(true);
			int[] phys;
			phys.length = PHYSICALS.length;
			phys[] = _prop.looks.physicalNormal;
			if (_phyR) { mixin(S_TRACE);
				_phyR.setValues(phys);
			} else { mixin(S_TRACE);
				_phyS.setValues(phys);
			}
			foreach (radio; _mtl) { mixin(S_TRACE);
				radio.setSelection(_prop.var.etc.mentalMax);
			}
			int[] bonus;
			bonus.length = ENHANCE.length;
			bonus[] = 0;
			if (_enhR) { mixin(S_TRACE);
				_enhR.setValues(bonus);
			} else { mixin(S_TRACE);
				_enhS.setValues(bonus);
			}

			resetLiveStatus();
		}
		setMaxLife();
		modPhysical();
	}

	private Coupon createCoupon(E)(Button[E] radios, string delegate(E) coupon) { mixin(S_TRACE);
		auto keys = radios.keys();
		.sort(keys);
		foreach (e; keys) { mixin(S_TRACE);
			auto radio = radios.get(e, null);
			if (!radio) continue;
			if (radio.getSelection()) { mixin(S_TRACE);
				return new Coupon(coupon(e), 0);
			}
		}
		return null;
	}
	override bool apply() { mixin(S_TRACE);
		auto images = _imgPath.materialPath;
		if (images.cancel) return false;
		if (_card) { mixin(S_TRACE);
			_card.paths = images.images;
			_card.desc = _desc.getRRText();
			_card.name = _name.getText();
			_card.level = _level.getSelection();
			_card.lifeMax = _lifeMax.getSelection();
			_card.life = _lifeMax.getSelection();
		} else { mixin(S_TRACE);
			_card = new CastCard(_summ.newId!(CastCard), _name.getText(), images.images,
				_desc.getRRText(), _level.getSelection(), _lifeMax.getSelection());
		}
		auto skin = summSkin;
		string legacyName = skin.legacyName;
		alias contains!("a.name == b.name", Coupon, Coupon) cContains;
		auto tblCoupons = _couponView.coupons;
		Coupon[] cs;
		auto sex = createCoupon!(Sex)(_sex, &skin.sexCoupon);
		if (sex && !cContains(tblCoupons, sex)) cs ~= sex;
		auto race = selectedRace;
		if (race) { mixin(S_TRACE);
			auto rc = new Coupon(_prop.sys.raceCoupon(race.name), 0);
			if (!cContains(tblCoupons, rc)) cs ~= rc;
		}
		auto period = createCoupon!(Period)(_period, &skin.periodCoupon);
		if (period && !cContains(tblCoupons, period)) cs ~= period;
		auto nature = createCoupon!(Nature)(_nature, &skin.natureCoupon);
		if (nature && !cContains(tblCoupons, nature)) cs ~= nature;
		foreach (m, radio; _makings) { mixin(S_TRACE);
			if (radio.getSelection()) { mixin(S_TRACE);
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
		foreach (e, radio; _res) { mixin(S_TRACE);
			_card.resist(e, radio.getSelection());
		}
		foreach (e, radio; _weak) { mixin(S_TRACE);
			_card.weakness(e, radio.getSelection());
		}
		foreach (phy, i; _phyTbl) { mixin(S_TRACE);
			if (_phyR) { mixin(S_TRACE);
				_card.physical(phy, _phyR.getValue(i));
			} else { mixin(S_TRACE);
				_card.physical(phy, _phyS.getValue(i));
			}
		}
		foreach (mtl, scale; _mtl) { mixin(S_TRACE);
			_card.mental(mtl, cast(int)scale.getSelection() - cast(int)_prop.var.etc.mentalMax);
		}
		foreach (enh, i; _enhTbl) { mixin(S_TRACE);
			if (_enhR) { mixin(S_TRACE);
				_card.defaultEnhance(enh, _enhR.getValue(i));
			} else { mixin(S_TRACE);
				_card.defaultEnhance(enh, _enhS.getValue(i));
			}
		}

		_card.life = _lifeUseMax.getSelection() ? _card.lifeMax : _life.getSelection();
		foreach (enh, spn; _liveEnh) { mixin(S_TRACE);
			if (_enhRound[enh].getSelection() > 0) { mixin(S_TRACE);
				_card.enhance(enh, spn.getSelection());
			} else { mixin(S_TRACE);
				_card.enhance(enh, 0);
			}
		}
		foreach (enh, spn; _enhRound) { mixin(S_TRACE);
			if (_card.enhance(enh) != 0) { mixin(S_TRACE);
				_card.enhanceRound(enh, spn.getSelection());
			} else { mixin(S_TRACE);
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
		getShell().setText(.tryFormat(_prop.msgs.dlgTitCast, _card.name));
		return true;
	}
}
