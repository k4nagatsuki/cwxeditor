
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
import cwx.skin;

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
import cwx.editor.gui.dwt.chooser;

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

	Skin _summSkin;
	@property
	Skin summSkin() { mixin(S_TRACE);
		return _summSkin ? _summSkin : _comm.skin;
	}

	void refreshWarning() { mixin(S_TRACE);
		string[] ws;
		static if (is (C == MenuCard)) {
			ws ~= _imgPath.warnings;
		}
		if (_layer.getEnabled() && _layer.getSelection() != LAYER_MENU_CARD && !_prop.isTargetVersion(_summ, "1")) {
			ws ~= _prop.msgs.warningLayer;
		}
		warning = ws;
	}
	void refDataVersion() { mixin(S_TRACE);
		_layer.setEnabled(!_summ || !_summ.legacy);
		refreshWarning();
	}

	static if (is (C == MenuCard)) {
		ImageSelect!(MtType.CARD) _imgPath;
		FixedWidthText _desc;
		Text _name;

	} else static if (is (C == EnemyCard)) {
		Combo _casts;
		Button _escape;
		Canvas _image;
		class CardPaint : PaintListener {
			override void paintControl(PaintEvent e) { mixin(S_TRACE);
				if (0 != _selectedID) { mixin(S_TRACE);
					auto ec = _summ.cwCast(_selectedID);
					if (!ec) return;
					auto canv = cast(Canvas)e.widget;
					auto skin = _comm.skin;
					auto imgData = castCardImage(_prop, skin, ec, _summ.scenarioPath, true);
					scope img = new Image(Display.getCurrent(), imgData);
					scope (exit) img.dispose();
					auto ca = canv.getClientArea();
					auto x = (ca.width - imgData.width) / 2 + ca.x;
					auto y = (ca.height - imgData.height) / 2 + ca.y;
					e.gc.drawImage(img, x, y);
				}
			}
		}
		class Repaint : SelectionAdapter {
			override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
				_image.redraw();
			}
		}
		ulong _selectedID = 0;
		IncSearch _cardIncSearch;
		void cardIncSearch() { mixin(S_TRACE);
			.forceFocus(_casts, true);
			_cardIncSearch.startIncSearch();
		}
	} else { mixin(S_TRACE);
		static assert (0);
	}
	FlagChooser!(cwx.flag.Flag, true) _flag = null;
	Spinner _x;
	Spinner _y;
	Spinner _scale;
	Spinner _layer;

	class SDListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
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
			_comm.refDataVersion.remove(&refDataVersion);
			_comm.refTargetVersion.remove(&refDataVersion);
		}
	}
	static if (is (C == EnemyCard)) {
		void refCast(CastCard c) { mixin(S_TRACE);
			refreshCasts();
		}
		void refreshCasts() { mixin(S_TRACE);
			ignoreMod = true;
			scope (exit) ignoreMod = false;
			if (_summ) { mixin(S_TRACE);
				if (!_summ.casts.length) { mixin(S_TRACE);
					forceCancel();
					return;
				}
				_casts.removeAll();
				bool has = false;
				foreach (i, c; _summ.casts) { mixin(S_TRACE);
					if (!has && _selectedID == c.id) { mixin(S_TRACE);
						has = true;
					}
					if (!_cardIncSearch.match(c.name)) continue;
					_casts.add(to!string(c.id) ~ "." ~ c.name);
					if (_selectedID == c.id) _casts.select(_casts.getItemCount() - 1);
				}
				if (!has && _casts.getItemCount()) { mixin(S_TRACE);
					_casts.select(0);
					_selectedID = _summ.casts[0].id;
				}
			} else { mixin(S_TRACE);
				_casts.removeAll();
				_selectedID = 0;
			}
			_image.redraw();
		}
	}
	void delMenuCard(string cwxPath) { mixin(S_TRACE);
		if (_card && _card.cwxPath(true) == cwxPath) { mixin(S_TRACE);
			forceCancel();
		}
	}
	void refSkin() { mixin(S_TRACE);
		static if (is (C == MenuCard)) {
			_desc.font = dwtData(_prop.looks.cardDescFont(_comm.skin.legacy));
		}
	}
	static if (is(C:EnemyCard)) {
		void openCardView() { mixin(S_TRACE);
			auto i = _casts.getSelectionIndex();
			if (-1 == i) return;
			auto a = _summ.casts[i];
			try { mixin(S_TRACE);
				_comm.openCWXPath(cpaddattr(a.cwxPath(true), "shallow"), false);
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
			}
		}
	}
public:
	this(Commons comm, Props prop, Shell shell, Summary summ, C card, bool create) { mixin(S_TRACE);
		_comm = comm;
		_summ = summ;
		_card = card;
		_prop = prop;
		static if (is (C == MenuCard)) {
			string text = create ? _prop.msgs.dlgTitNewMenuCard : .tryFormat(_prop.msgs.dlgTitMenuCard, _card.name);
			auto size = _prop.var.menuCardDlg;
		} else static if (is (C == EnemyCard)) {
			auto size = _prop.var.enemyCardDlg;
			string text;
			if (_card) { mixin(S_TRACE);
				auto c = _summ ? _summ.cwCast(_card.id) : null;
				auto name = c ? c.name : .tryFormat(_prop.msgs.noCast, _card.id);
				text = create ? _prop.msgs.dlgTitNewEnemyCard : .tryFormat(_prop.msgs.dlgTitEnemyCard, name);
			} else { mixin(S_TRACE);
				text = _prop.msgs.dlgTitNewEnemyCard;
			}
		} else { mixin(S_TRACE);
			static assert (0);
		}
		super(prop, shell, false, text, _prop.images.cards, true, size, true);
		enterClose = true;
	}

	@property
	C card() { mixin(S_TRACE);
		return _card;
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		auto cl = new CenterLayout(SWT.NONE, 0);
		cl.fillHorizontal = true;
		cl.fillVertical = true;
		area.setLayout(cl);
		{ mixin(S_TRACE);
			auto comp = new Composite(area, SWT.NONE);
			comp.setLayout(new GridLayout(1, false));
			{ mixin(S_TRACE);
				auto sash = new SplitPane(comp, SWT.HORIZONTAL);
				sash.resizeControl1 = true;
				sash.setLayoutData(new GridData(GridData.FILL_BOTH));
				{ mixin(S_TRACE);
					auto comp2 = new Composite(sash, SWT.NONE);
					comp2.setLayout(zeroMarginGridLayout(1, false));
					{ mixin(S_TRACE);
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
							_casts.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
							mod(_casts);
							auto gd = new GridData(GridData.FILL_HORIZONTAL);
							gd.widthHint = _prop.var.etc.nameWidth;
							_casts.setLayoutData(gd);
							_casts.addSelectionListener(new Repaint);
							_escape = new Button(grp, SWT.TOGGLE);
							mod(_escape);
							_escape.setImage(_prop.images.menu(MenuID.Escape));
							_escape.setToolTipText(_prop.msgs.menuText(MenuID.Escape));

							_cardIncSearch = new IncSearch(_comm, _casts);
							_cardIncSearch.modEvent ~= &refreshCasts;

							.listener(_casts, SWT.Selection, { mixin(S_TRACE);
								int index = _casts.getSelectionIndex();
								if (-1 != index) { mixin(S_TRACE);
									_selectedID = _summ.casts[index].id;
								}
							});

							auto menu = new Menu(_casts.getShell(), SWT.POP_UP);
							createMenuItem(_comm, menu, MenuID.IncSearch, &cardIncSearch, () => 0 < _casts.getItemCount());
							new MenuItem(menu, SWT.SEPARATOR);
							createMenuItem(_comm, menu, MenuID.OpenAtCardView, &openCardView, () => _casts.getSelectionIndex() != -1);
							_casts.setMenu(menu);
						} else { mixin(S_TRACE);
							static assert (0);
						}
					}
					{ mixin(S_TRACE);
						static if (is (C == MenuCard)) {
							auto skin = _comm.skin;
							string[] defs(bool included) { mixin(S_TRACE);
								string[] defs = [_prop.msgs.defaultSelection(_prop.msgs.imageNone)];
								if (included) defs ~= _prop.msgs.defaultSelection(_prop.msgs.imageIncluding);
								foreach (pcNum; 0 .. _prop.var.etc.partyMax) {
									defs ~= _prop.msgs.defaultSelection(.tryFormat(_prop.msgs.pcNumber, pcNum + 1));
								}
								return defs;
							}
							_imgPath = new ImageSelect!(MtType.CARD)(comp2, SWT.NONE, _comm, _prop, _summ,
								_prop.looks.cardSize.width, _prop.looks.cardSize.height, true, &_name.getText, null, &defs, true);
							_imgPath.valueFromDef = (defIndex, included, binPath) { mixin(S_TRACE);
								if (defIndex <= 0) return new CardImage("");
								if (included) { mixin(S_TRACE);
									if (defIndex == 1) return new CardImage(binPath);
									defIndex--;
								}
								return new CardImage(cast(uint)defIndex);
							};
							_imgPath.valueToDef = (imgPath, included) { mixin(S_TRACE);
								final switch (imgPath.type) {
								case CardImageType.File:
									if (imgPath.path == "") return 0;
									if (included && imgPath.path.isBinImg) return 1;
									return -1;
								case CardImageType.PCNumber:
									auto pcNum = cast(int)imgPath.pcNumber;
									if (included) pcNum++;
									return pcNum;
								case CardImageType.Talker:
									return -1; // 非対応
								}
							};
							_imgPath.indexOfBinPath = (included) => included ? 1 : -1;
							mod(_imgPath);
							_imgPath.modEvent ~= &refreshWarning;
							_imgPath.widget.setLayoutData(new GridData(GridData.FILL_BOTH));
						} else static if (is (C == EnemyCard)) {
							auto grp = new Group(comp2, SWT.NONE);
							grp.setLayoutData(new GridData(GridData.FILL_BOTH));
							grp.setLayout(new FillLayout);
							grp.setText(_prop.msgs.image);
							_image = new Canvas(grp, SWT.DOUBLE_BUFFERED);
							_image.addPaintListener(new CardPaint);
						} else { mixin(S_TRACE);
							static assert (0);
						}
					}
				}
				{ mixin(S_TRACE);
					auto grp = new Group(sash, SWT.NONE);
					grp.setLayout(new GridLayout(2, false));
					grp.setText(_prop.msgs.refFlag);
					_flag = new FlagChooser!(Flag, true)(_comm, _summ, grp);
					mod(_flag);
					_flag.setLayoutData(new GridData(GridData.FILL_BOTH));
				}
				static if (is (C == MenuCard)) {
					sash.setWeights([_prop.var.etc.menuCardSashL, _prop.var.etc.menuCardSashR]);
				} else static if (is (C == EnemyCard)) {
					sash.setWeights([_prop.var.etc.enemyCardSashL, _prop.var.etc.enemyCardSashR]);
				} else static assert (0);
				sash.addDisposeListener(new SDListener);
			}
			{ mixin(S_TRACE);
				auto grp = new Group(comp, SWT.NONE);
				grp.setText(_prop.msgs.cardPosition);
				grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				grp.setLayout(new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0));
				auto comp2 = new Composite(grp, SWT.NONE);
				comp2.setLayout(new GridLayout(4, false));
				Spinner createS(string name, int max, int min, string hint = "") { mixin(S_TRACE);
					auto comp3 = new Composite(comp2, SWT.NONE);
					auto gl = new GridLayout((hint != "") ? 3 : 2, false);
					gl.marginHeight = 0;
					comp3.setLayout(gl);
					auto l = new Label(comp3, SWT.NONE);
					l.setText(name);
					auto spn = new Spinner(comp3, SWT.BORDER);
					initSpinner(spn);
					mod(spn);
					spn.setMaximum(max);
					spn.setMinimum(min);
					if (hint != "") { mixin(S_TRACE);
						auto lp = new Label(comp3, SWT.NONE);
						lp.setText(hint);
					}
					return spn;
				}
				_x = createS(_prop.msgs.left, _prop.var.etc.posLeftMax, -(cast(int) _prop.var.etc.posLeftMax));
				_y = createS(_prop.msgs.top, _prop.var.etc.posTopMax, -(cast(int) _prop.var.etc.posTopMax));
				_scale = createS(_prop.msgs.scale, _prop.var.etc.cardScaleMax, _prop.var.etc.cardScaleMin, _prop.msgs.scalePer);
				_layer = createS(_prop.msgs.layer, _prop.var.etc.layerMax, LAYER_BACK_CELL, .tryFormat(_prop.msgs.layerHint, LAYER_MENU_CARD));
				_layer.setToolTipText(.tryFormat(_prop.msgs.layerValues, LAYER_BACK_CELL, LAYER_MENU_CARD, LAYER_PLAYER_CARD, LAYER_MESSAGE));
			}
			static if (is (C == MenuCard)) {
				{ mixin(S_TRACE);
					auto grp = new Group(comp, SWT.NONE);
					grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
					grp.setLayout(new CenterLayout(SWT.HORIZONTAL));
					grp.setText(_prop.msgs.desc);
					_desc = new FixedWidthText(dwtData(_prop.looks.cardDescFont(summSkin.legacy)), _prop.looks.cardDescLen, grp, SWT.BORDER);
					createTextMenu!Text(_comm, _prop, _desc.widget, &catchMod);
					mod(_desc.widget);
					_desc.widget.setLayoutData(_desc.computeTextBaseSize(_prop.looks.cardDescLine));
				}
			}
			comp.setLayoutData(area.computeSize(SWT.DEFAULT, SWT.DEFAULT));
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
		_comm.refDataVersion.add(&refDataVersion);
		_comm.refTargetVersion.add(&refDataVersion);
		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_card) { mixin(S_TRACE);
			static if (is (C == MenuCard)) {
				_imgPath.images = _card.paths;
				_desc.setText(_card.desc);
				_name.setText(_card.name);
			} else static if (is (C == EnemyCard)) {
				if (_summ) { mixin(S_TRACE);
					assert (_casts.getItemCount());
					foreach (i, c; _summ.casts) { mixin(S_TRACE);
						if (c.id == _card.id) { mixin(S_TRACE);
							_casts.select(cast(int)i);
							_selectedID = c.id;
							break;
						}
					}
					if (-1 == _casts.getSelectionIndex()) { mixin(S_TRACE);
						_casts.select(0);
						_selectedID = _summ.casts[0].id;
					}
				}
				_escape.setSelection(_card.escape);
			} else { mixin(S_TRACE);
				static assert (0);
			}
			if (_flag) { mixin(S_TRACE);
				_flag.selected = _card.flag;
			}
			_x.setSelection(_card.x);
			_y.setSelection(_card.y);
			_scale.setSelection(_card.scale);
			_layer.setSelection(_card.layer);
		} else { mixin(S_TRACE);
			static if (is (C == MenuCard)) {
				_imgPath.images = [];
				_desc.setText("");
				_name.setText("");
			} else static if (is (C == EnemyCard)) {
				assert (_casts.getItemCount());
				_casts.select(0);
				_selectedID = _summ.casts[0].id;
				_escape.setSelection(false);
			} else { mixin(S_TRACE);
				static assert (0);
			}
			if (_flag) { mixin(S_TRACE);
				_flag.selected = "";
			}
			_x.setSelection(0);
			_y.setSelection(0);
			_scale.setSelection(100);
			_layer.setSelection(LAYER_MENU_CARD);
		}
		refDataVersion();
	}

	override bool apply() { mixin(S_TRACE);
		if (_card) { mixin(S_TRACE);
			static if (is (C == MenuCard)) {
				auto images = _imgPath.materialPath;
				if (images.cancel) return false;
				_card.paths = images.images;
				_card.desc = wrapReturnCode(_desc.getText());
				_card.name = _name.getText();
			} else static if (is (C == EnemyCard)) {
				_card.id = _selectedID;
				_card.escape = _escape.getSelection();
			} else { mixin(S_TRACE);
				static assert (0);
			}
			_card.flag = _flag.selected;
			_card.x = _x.getSelection();
			_card.y = _y.getSelection();
			_card.scale = _scale.getSelection();
			_card.layer = _layer.getSelection();
		} else { mixin(S_TRACE);
			static if (is (C == MenuCard)) {
				auto images = _imgPath.materialPath;
				if (images.cancel) return false;
				_card = new C(_name.getText(), images.images,
					wrapReturnCode(_desc.getText()), _flag.selected,
					_x.getSelection(), _y.getSelection(), _scale.getSelection(), _layer.getSelection());
			} else static if (is (C == EnemyCard)) {
				_card = new C(_selectedID, _escape.getSelection(),
					_flag.selected, _x.getSelection(), _y.getSelection(), _scale.getSelection(), _layer.getSelection());
			} else { mixin(S_TRACE);
				static assert (0);
			}
		}
		static if (is (C == MenuCard)) {
			string text = .tryFormat(_prop.msgs.dlgTitMenuCard, _card.name);
		} else static if (is (C == EnemyCard)) {
			auto c = _summ ? _summ.cwCast(_card.id) : null;
			auto name = c ? c.name : .tryFormat(_prop.msgs.noCast, _card.id);
			auto text = .tryFormat(_prop.msgs.dlgTitEnemyCard, name);
		} else static assert (0);
		getShell().setText(text);
		return true;
	}
}
