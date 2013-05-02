
module cwx.editor.gui.dwt.spcarddialog;

import cwx.area;
import cwx.flag;
import cwx.utils;
import cwx.summary;
import cwx.card;
import cwx.menu;
import cwx.types;
import cwx.path;
import cwx.imagesize;

import cwx.editor.gui.sound;

import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.materialselect;
import cwx.editor.gui.dwt.imageselect;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.incsearch;

import std.conv;
import std.math;

import org.eclipse.swt.all;

import java.lang.all;

public:

/// メニューカードの設定を行うダイアログ。
class SpCardDialog(C : AbstractSpCard) : AbsDialog {
private:
	Commons _comm;
	Props _prop;
	Summary _summ;
	C _card;

	static if (is (C == MenuCard)) {
		ImageSelect!(MtType.CARD) _imgPath;
		FixedWidthText _desc;
		Text _name;

		void refreshWarning() {
			string[] ws;
			ws ~= _imgPath.warnings;
			if (0 != _imgPath.pcNumber && _summ) {
				if (_summ.legacy) {
					ws ~= _prop.msgs.warningPCNumberClassic;
				} else {
					ws ~= _prop.msgs.warningPCNumberXML;
				}
			}

			warning = ws;
		}
	} else static if (is (C == EnemyCard)) {
		Combo _casts;
		Button _escape;
		Canvas _image;
		class CardPaint : PaintListener {
			override void paintControl(PaintEvent e) {
				if (0 != _selectedID) {
					auto ec = _summ.cwCast(_selectedID);
					if (!ec) return;
					auto canv = cast(Canvas) e.widget;
					string path = "";
					if (_summ) {
						path = _comm.skin.findImagePath(ec.path, _summ.scenarioPath);
					}
					if (path.length > 0) {
						auto skin = _comm.skin;
						scope img = new Image(Display.getCurrent(), loadImage(skin, path));
						scope (exit) img.dispose();
						e.gc.drawImage(img, 0, 0);
					}
				}
			}
		}
		class Repaint : SelectionAdapter {
			override void widgetSelected(SelectionEvent e) {
				_image.redraw();
			}
		}
		ulong _selectedID = 0;
		IncSearch _cardIncSearch;
		void cardIncSearch() {
			.forceFocus(_casts, true);
			_cardIncSearch.startIncSearch();
		}
	} else {
		static assert (0);
	}
	Table _flag;
	Spinner _x;
	Spinner _y;
	Spinner _scale;

	string _selectedFlag = "";
	IncSearch _flagIncSearch;
	void flagIncSearch() {
		.forceFocus(_flag, true);
		_flagIncSearch.startIncSearch();
	}

	class SDListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			auto sash = cast(SplitPane) e.widget;
			auto ws = sash.getWeights();
			static if (is (C == MenuCard)) {
				_prop.var.etc.menuCardSashL = ws[0];
				_prop.var.etc.menuCardSashR = ws[1];
			} else static if (is (C == EnemyCard)) {
				_prop.var.etc.enemyCardSashL = ws[0];
				_prop.var.etc.enemyCardSashR = ws[1];
			} else static assert (0);
			_comm.delMenuCard.remove(&delMenuCard);
			static if (is (C == EnemyCard)) {
				_comm.refCast.remove(&refCast);
				_comm.delCast.remove(&refCast);
			}
			_comm.refSkin.remove(&refSkin);
		}
	}
	static if (is (C == EnemyCard)) {
		void refCast(CastCard c) {
			refreshCasts();
		}
		void refreshCasts() {
			ignoreMod = true;
			scope (exit) ignoreMod = false;
			if (_summ) {
				if (!_summ.casts.length) {
					forceCancel();
					return;
				}
				_casts.removeAll();
				bool has = false;
				foreach (i, c; _summ.casts) {
					if (!has && _selectedID == c.id) {
						has = true;
					}
					if (!_cardIncSearch.match(c.name)) continue;
					_casts.add(to!string(c.id) ~ "." ~ c.name);
					if (_selectedID == c.id) _casts.select(_casts.getItemCount() - 1);
				}
				if (!has && _casts.getItemCount()) {
					_casts.select(0);
					_selectedID = _summ.casts[0].id;
				}
			} else {
				_casts.removeAll();
				_selectedID = 0;
			}
			_image.redraw();
		}
	}
	void delMenuCard(string cwxPath) {
		if (_card && _card.cwxPath(true) == cwxPath) {
			forceCancel();
		}
	}
	void refSkin() {
		static if (is (C == MenuCard)) {
			_desc.font = dwtData(_prop.looks.cardDescFont(_summ.legacy));
		}
	}
	void refFlags(Flag[] f, Step[] s) {
		if (!_summ) return;
		if (!f.length) return;
		refreshFlags();
	}
	void delFlags(Flag[] f, Step[] s) {
		if (!_summ) return;
		if (!f.length) return;
		refreshFlags();
	}
	void refreshFlags() {
		if (!_flag) return;
		auto flags = _summ.flagDirRoot.allFlags;
		string sel = _selectedFlag;
		_flag.removeAll();
		auto nof = new TableItem(_flag, SWT.NONE);
		nof.setText(_prop.msgs.noFlagRef);
		nof.setImage(_prop.images.emptyIcon);
		bool has = false;
		foreach (flag; flags) {
			auto path = flag.path;
			if (!has && path == sel) {
				has = true;
			}
			if (!_flagIncSearch.match(path)) continue;
			auto itm = new TableItem(_flag, SWT.NONE);
			itm.setData(flag);
			itm.setImage(_prop.images.flag);
			itm.setText(path);
			if (path == sel) _flag.select(_flag.getItemCount() - 1);
		}
		if (!has) {
			_flag.select(0);
			_selectedFlag = "";
		}
	}
	void openFlagView() {
		if (!_flag) return;
		auto i = _flag.getSelectionIndex();
		if (-1 == i) return;
		auto a = cast(Flag) _flag.getItem(i).getData();
		if (!a) return;
		try {
			_comm.openCWXPath(cpaddattr(a.cwxPath(true), "shallow"), false);
		} catch (Exception e) {
			debugln(e);
		}
	}
	static if (is(C:EnemyCard)) {
		void openCardView() {
			auto i = _casts.getSelectionIndex();
			if (-1 == i) return;
			auto a = _summ.casts[i];
			try {
				_comm.openCWXPath(cpaddattr(a.cwxPath(true), "shallow"), false);
			} catch (Exception e) {
				debugln(e);
			}
		}
	}
public:
	this(Commons comm, Props prop, Shell shell, Summary summ, C card) {
		_comm = comm;
		_summ = summ;
		_card = card;
		_prop = prop;
		static if (is (C == MenuCard)) {
			string text = _card ? .tryFormat(_prop.msgs.dlgTitMenuCard, _card.name) : _prop.msgs.dlgTitNewMenuCard;
			auto size = _prop.var.menuCardDlg;
		} else static if (is (C == EnemyCard)) {
			auto size = _prop.var.enemyCardDlg;
			string text;
			if (_card) {
				auto c = _summ ? _summ.cwCast(_card.id) : null;
				text = c ? .tryFormat(_prop.msgs.dlgTitEnemyCard, c.name) : _prop.msgs.dlgTitNewEnemyCard;
			} else {
				text = _prop.msgs.dlgTitNewEnemyCard;
			}
		} else {
			static assert (0);
		}
		super(prop, shell, false, text, _prop.images.cards, true, size, true);
		enterClose = true;
	}

	@property
	C card() {
		return _card;
	}
protected:
	override void setup(Composite area) {
		auto cl = new CenterLayout(SWT.NONE, 0);
		cl.fillHorizontal = true;
		cl.fillVertical = true;
		area.setLayout(cl);
		{
			auto comp = new Composite(area, SWT.NONE);
			comp.setLayout(new GridLayout(1, false));
			{
				auto sash = new SplitPane(comp, SWT.HORIZONTAL);
				sash.setLayoutData(new GridData(GridData.FILL_BOTH));
				{
					auto comp2 = new Composite(sash, SWT.NONE);
					comp2.setLayout(zeroMarginGridLayout(1, false));
					{
						auto grp = new Group(comp2, SWT.NONE);
						grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
						static if (is (C == MenuCard)) {
							grp.setLayout(new GridLayout(1, false));
							grp.setText(_prop.msgs.name);
							_name = new Text(grp, SWT.BORDER);
							createTextMenu!Text(_comm, _prop, _name, &catchMod);
							mod(_name);
							_name.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
						} else static if (is (C == EnemyCard)) {
							grp.setLayout(new GridLayout(2, false));
							grp.setText(_prop.msgs.enemyCardBase);
							_casts = new Combo(grp, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
							mod(_casts);
							auto gd = new GridData(GridData.FILL_HORIZONTAL);
							gd.widthHint = _prop.var.etc.nameWidth;
							_casts.setLayoutData(gd);
							_casts.addSelectionListener(new Repaint);
							_escape = new Button(grp, SWT.TOGGLE);
							mod(_escape);
							_escape.setImage(_prop.images.menu(MenuID.Escape));
							_escape.setToolTipText(_prop.buildTool(MenuID.Escape));

							_cardIncSearch = new IncSearch(_comm, _casts);
							_cardIncSearch.modEvent ~= &refreshCasts;

							.listener(_casts, SWT.Selection, {
								int index = _casts.getSelectionIndex();
								if (-1 != index) {
									_selectedID = _summ.casts[index].id;
								}
							});

							auto menu = new Menu(_casts.getShell(), SWT.POP_UP);
							createMenuItem(_comm, menu, MenuID.IncSearch, &cardIncSearch, () => 0 < _casts.getItemCount());
							new MenuItem(menu, SWT.SEPARATOR);
							createMenuItem(_comm, menu, MenuID.OpenAtCardView, &openCardView, () => _casts.getSelectionIndex() != -1);
							_casts.setMenu(menu);
						} else {
							static assert (0);
						}
					}
					{
						static if (is (C == MenuCard)) {
							auto skin = _comm.skin;
							bool including = _card && isBinImg(_card.path);
							_imgPath = new ImageSelect!(MtType.CARD)(comp2, SWT.NONE, _comm, _prop, _summ,
								_prop.looks.cardSize.width, _prop.looks.cardSize.height, including, true, &_name.getText, null, null, null, true);
							mod(_imgPath);
							_imgPath.modEvent ~= &refreshWarning;
							_imgPath.widget.setLayoutData(new GridData(GridData.FILL_BOTH));
						} else static if (is (C == EnemyCard)) {
							auto grp = new Group(comp2, SWT.NONE);
							grp.setLayoutData(new GridData(GridData.FILL_BOTH));
							grp.setLayout(new CenterLayout);
							grp.setText(_prop.msgs.image);
							_image = new Canvas(grp, SWT.BORDER | SWT.DOUBLE_BUFFERED);
							auto rect = _image.computeTrim(SWT.DEFAULT, SWT.DEFAULT,
								_prop.looks.cardSize.width, _prop.looks.cardSize.height);
							_image.setLayoutData(new Point(rect.width, rect.height));
							_image.addPaintListener(new CardPaint);
						} else {
							static assert (0);
						}
					}
				}
				{
					auto grp = new Group(sash, SWT.NONE);
					grp.setLayout(new GridLayout(2, false));
					grp.setText(_prop.msgs.refFlag);
					_flag = new Table(grp, SWT.SINGLE | SWT.FULL_SELECTION | SWT.BORDER);
					mod(_flag);
					_flagIncSearch = new IncSearch(_comm, _flag);
					_flagIncSearch.modEvent ~= &refreshFlags;
					auto gd = new GridData(GridData.FILL_BOTH);
					gd.widthHint = _prop.var.etc.flagsWidth;
					gd.heightHint = _prop.var.etc.flagsHeight;
					_flag.setLayoutData(gd);
					auto colN = new FullTableColumn(_flag, SWT.NONE);

					.listener(_flag, SWT.Selection, {
						int index = _flag.getSelectionIndex();
						if (-1 != index) {
							auto f = cast(Flag) _flag.getItem(index).getData();
							_selectedFlag = f ? f.path : "";
						}
					});

					auto menu = new Menu(_flag.getShell(), SWT.POP_UP);
					createMenuItem(_comm, menu, MenuID.IncSearch, &flagIncSearch, () => 1 < _flag.getItemCount());
					new MenuItem(menu, SWT.SEPARATOR);
					createMenuItem(_comm, menu, MenuID.OpenAtVarView, &openFlagView, () => 0 < _flag.getSelectionIndex());
					_flag.setMenu(menu);
				}
				static if (is (C == MenuCard)) {
					sash.setWeights([_prop.var.etc.menuCardSashL, _prop.var.etc.menuCardSashR]);
				} else static if (is (C == EnemyCard)) {
					sash.setWeights([_prop.var.etc.enemyCardSashL, _prop.var.etc.enemyCardSashR]);
				} else static assert (0);
				sash.addDisposeListener(new SDListener);

				_comm.refFlagAndStep.add(&refFlags);
				_comm.delFlagAndStep.add(&delFlags);
				.listener(_flag, SWT.Dispose, {
					_comm.refFlagAndStep.remove(&refFlags);
					_comm.delFlagAndStep.remove(&delFlags);
				});
			}
			{
				auto grp = new Group(comp, SWT.NONE);
				grp.setText(_prop.msgs.cardPosition);
				grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				grp.setLayout(new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0));
				auto comp2 = new Composite(grp, SWT.NONE);
				comp2.setLayout(new GridLayout(3, false));
				Spinner createS(string name, int max, int min, bool percent = false) {
					auto comp3 = new Composite(comp2, SWT.NONE);
					auto gl = new GridLayout(percent ? 3 : 2, false);
					gl.marginHeight = 0;
					comp3.setLayout(gl);
					auto l = new Label(comp3, SWT.NONE);
					l.setText(name);
					auto spn = new Spinner(comp3, SWT.BORDER);
					mod(spn);
					spn.setMaximum(max);
					spn.setMinimum(min);
					if (percent) {
						auto lp = new Label(comp3, SWT.NONE);
						lp.setText("%");
					}
					return spn;
				}
				_x = createS(_prop.msgs.left, _prop.var.etc.posLeftMax, -(cast(int) _prop.var.etc.posLeftMax));
				_y = createS(_prop.msgs.top, _prop.var.etc.posTopMax, -(cast(int) _prop.var.etc.posTopMax));
				_scale = createS(_prop.msgs.scale, _prop.var.etc.cardScaleMax, _prop.var.etc.cardScaleMin, true);
			}
			static if (is (C == MenuCard)) {
				{
					auto grp = new Group(comp, SWT.NONE);
					grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
					grp.setLayout(new CenterLayout(SWT.HORIZONTAL));
					grp.setText(_prop.msgs.desc);
					_desc = new FixedWidthText(dwtData(_prop.looks.cardDescFont(_summ ? _summ.legacy : false)), _prop.looks.cardDescLen, grp, SWT.BORDER);
					createTextMenu!Text(_comm, _prop, _desc.widget, &catchMod);
					mod(_desc.widget);
					_desc.widget.setLayoutData(_desc.computeTextBaseSize(_prop.looks.cardDescLine));
				}
			}
			comp.setLayoutData(area.computeSize(SWT.DEFAULT, SWT.DEFAULT));
		}

		if (_flag) {
			refreshFlags();
		}
		static if (is(C : EnemyCard)) {
			refreshCasts();
		}

		_comm.delMenuCard.add(&delMenuCard);
		static if (is (C == EnemyCard)) {
			_comm.refCast.add(&refCast);
			_comm.delCast.add(&refCast);
		}
		_comm.refSkin.add(&refSkin);
		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_card) {
			static if (is (C == MenuCard)) {
				_imgPath.image = _card.path;
				_desc.setText(_card.desc);
				_name.setText(_card.name);
				_imgPath.pcNumber = _card.pcNumber;
			} else static if (is (C == EnemyCard)) {
				if (_summ) {
					assert (_casts.getItemCount());
					foreach (i, c; _summ.casts) {
						if (c.id == _card.id) {
							_casts.select(i);
							_selectedID = c.id;
							break;
						}
					}
					if (-1 == _casts.getSelectionIndex()) {
						_casts.select(0);
						_selectedID = _summ.casts[0].id;
					}
				}
				_escape.setSelection(_card.escape);
			} else {
				static assert (0);
			}
			if (_flag) {
				_flag.select(0);
				_selectedFlag = "";
				if (_card.flag.length > 0) {
					foreach (i, itm; _flag.getItems()) {
						auto flag = cast(Flag) itm.getData();
						if (!flag) continue;
						string path = flag.path;
						if (path == _card.flag) {
							_flag.select(i);
							_selectedFlag = path;
							break;
						}
					}
				}
			}
			_x.setSelection(_card.x);
			_y.setSelection(_card.y);
			_scale.setSelection(cast(int) rndtol(_card.scale * 100));
		} else {
			static if (is (C == MenuCard)) {
				_imgPath.image = "";
				_desc.setText("");
				_name.setText("");
			} else static if (is (C == EnemyCard)) {
				assert (_casts.getItemCount());
				_casts.select(0);
				_selectedID = _summ.casts[0].id;
				_escape.setSelection(false);
			} else {
				static assert (0);
			}
			if (_flag) {
				_flag.select(0);
				_selectedFlag = "";
			}
			_x.setSelection(0);
			_y.setSelection(0);
			_scale.setSelection(100);
		}
		if (_flag) _flag.showSelection();
		static if (is(typeof(refreshWarning))) {
			refreshWarning();
		}
	}

	override bool apply() {
		if (_card) {
			static if (is (C == MenuCard)) {
				_card.path = _imgPath.image;
				_card.desc = wrapReturnCode(_desc.getText());
				_card.name = _name.getText();
				_card.pcNumber = _imgPath.pcNumber;
			} else static if (is (C == EnemyCard)) {
				_card.id = _selectedID;
				_card.escape = _escape.getSelection();
			} else {
				static assert (0);
			}
			_card.flag = _selectedFlag;
			_card.x = _x.getSelection();
			_card.y = _y.getSelection();
			_card.scale = _scale.getSelection() / 100.0;
		} else {
			static if (is (C == MenuCard)) {
				_card = new C(_name.getText(), _imgPath.image,
					wrapReturnCode(_desc.getText()), _selectedFlag,
					_x.getSelection(), _y.getSelection(), _scale.getSelection() / 100.0);
			} else static if (is (C == EnemyCard)) {
				_card = new C(_selectedID, _escape.getSelection(),
					_selectedFlag, _x.getSelection(), _y.getSelection(), _scale.getSelection() / 100.0);
			} else {
				static assert (0);
			}
		}
		return true;
	}
}
