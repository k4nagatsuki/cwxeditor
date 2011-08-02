
module cwx.editor.gui.dwt.spcarddialog;

import cwx.area;
import cwx.flag;
import cwx.utils;
import cwx.summary;
import cwx.card;

import cwx.editor.gui.sound;

import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.skin;
import cwx.editor.gui.dwt.utils;
import cwx.editor.gui.dwt.materialselect;
import cwx.editor.gui.dwt.imageselect;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.splitpane;

import std.conv;
import std.math;

import org.eclipse.swt.SWT;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Canvas;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Combo;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.swt.widgets.Group;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Spinner;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableColumn;
import org.eclipse.swt.widgets.TableItem;
import org.eclipse.swt.widgets.Text;
import org.eclipse.swt.widgets.Menu;
import org.eclipse.swt.widgets.MenuItem;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.events.PaintListener;
import org.eclipse.swt.events.PaintEvent;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
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
	} else static if (is (C == EnemyCard)) {
		Combo _casts;
		Button _escape;
		Canvas _image;
		class CardPaint : PaintListener {
			override void paintControl(PaintEvent e) {
				if (_casts.getSelectionIndex >= 0) {
					auto canv = cast(Canvas) e.widget;
					string path = "";
					if (_summ) {
						path = _comm.skin.findImagePath
							(_summ.casts[_casts.getSelectionIndex].path, _summ.scenarioPath);
					}
					if (path.length > 0) {
						auto skin = _comm.skin;
						scope img = new Image(Display.getCurrent, loadImage(skin, path));
						scope (exit) img.dispose;
						e.gc.drawImage(img, 0, 0);
					}
				}
			}
		}
		class Repaint : SelectionAdapter {
			override void widgetSelected(SelectionEvent e) {
				_image.redraw;
			}
		}
	} else {
		static assert (0);
	}
	Table _flag;
	Spinner _x;
	Spinner _y;
	Spinner _scale;

	class SDListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			auto sash = cast(SplitPane) e.widget;
			auto ws = sash.getWeights;
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
				ulong old = 0;
				if (_card) {
					auto c = _summ.casts(_card.id);
					if (c) old = c.id;
				}
				_casts.removeAll();
				foreach (i, c; _summ.casts) {
					_casts.add(to!string(c.id) ~ "." ~ c.name);
					if (old == c.id) _casts.select = i;
				}
			} else {
				_casts.removeAll();
			}
			_image.redraw();
		}
	}
	void delMenuCard(string cwxPath) {
		if (_card && _card.cwxPath == cwxPath) {
			forceCancel();
		}
	}
	void refSkin() {
		static if (is (C == MenuCard)) {
			_desc.font = dwtData(_prop.looks.cardDescFont(_summ.legacy));
		}
	}
public:
	this(Commons comm, Props prop, Shell shell, Summary summ, C card) {
		_comm = comm;
		_summ = summ;
		_card = card;
		_prop = prop;
		static if (is (C == MenuCard)) {
			string text = _card ? _prop.msgs.dlgTitMenuCard(_card.name) : _prop.msgs.dlgTitNewMenuCard;
			auto size = _prop.var.menuCardDlg;
		} else static if (is (C == EnemyCard)) {
			auto size = _prop.var.enemyCardDlg;
			string text;
			if (_card) {
				auto c = _summ ? _summ.casts(_card.id) : null;
				text = c ? _prop.msgs.dlgTitEnemyCard(c.name) : _prop.msgs.dlgTitNewEnemyCard;
			} else {
				text = _prop.msgs.dlgTitNewEnemyCard;
			}
		} else {
			static assert (0);
		}
		super(prop, shell, false, text, _prop.images.cards, true, size, true);
		enterClose = true;
	}

	C card() {
		return _card;
	}
protected:
	override void setup(Composite area) {
		auto cl = new CenterLayout(SWT.NONE, 0);
		cl.fillHorizontal = true;
		cl.fillVertical = true;
		area.setLayout = cl;
		{
			auto comp = new Composite(area, SWT.NONE);
			comp.setLayout = new GridLayout(1, false);
			{
				auto sash = new SplitPane(comp, SWT.HORIZONTAL);
				sash.setLayoutData = new GridData(GridData.FILL_BOTH);
				{
					auto comp2 = new Composite(sash, SWT.NONE);
					comp2.setLayout = zeroMarginGridLayout(1, false);
					{
						auto grp = new Group(comp2, SWT.NONE);
						grp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
						static if (is (C == MenuCard)) {
							grp.setLayout = new GridLayout(1, false);
							grp.setText = _prop.msgs.name;
							_name = new Text(grp, SWT.BORDER);
							mod(_name);
							_name.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
						} else static if (is (C == EnemyCard)) {
							grp.setLayout = new GridLayout(2, false);
							grp.setText = _prop.msgs.enemyCardBase;
							_casts = new Combo(grp, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
							mod(_casts);
							auto gd = new GridData(GridData.FILL_HORIZONTAL);
							gd.widthHint = _prop.var.etc.nameWidth;
							_casts.setLayoutData = gd;
							_casts.addSelectionListener(new Repaint);
							_escape = new Button(grp, SWT.TOGGLE);
							mod(_escape);
							_escape.setImage = _prop.images.menuDoEscape;

							_escape.setToolTipText = _prop.msgs.ttDoEscape;
						} else {
							static assert (0);
						}
					}
					{
						static if (is (C == MenuCard)) {
							auto skin = _comm.skin;
							bool including = _card && isBinImg(_card.path);
							string saveName = including ? _card.name : "";
							_imgPath = new ImageSelect!(MtType.CARD)(comp2, SWT.NONE, _comm, _prop, _summ,
								_prop.looks.cardSize.width, _prop.looks.cardSize.height, including, saveName);
							mod(_imgPath);
							_imgPath.widget.setLayoutData = new GridData(GridData.FILL_BOTH);
						} else static if (is (C == EnemyCard)) {
							auto grp = new Group(comp2, SWT.NONE);
							grp.setLayoutData = new GridData(GridData.FILL_BOTH);
							grp.setLayout = new CenterLayout;
							grp.setText = _prop.msgs.image;
							_image = new Canvas(grp, SWT.BORDER | SWT.DOUBLE_BUFFERED);
							auto rect = _image.computeTrim(SWT.DEFAULT, SWT.DEFAULT,
								_prop.looks.cardSize.width, _prop.looks.cardSize.height);
							_image.setLayoutData = new Point(rect.width, rect.height);
							_image.addPaintListener(new CardPaint);
						} else {
							static assert (0);
						}
					}
				}
				{
					auto grp = new Group(sash, SWT.NONE);
					grp.setLayout = new GridLayout(2, false);
					grp.setText = _prop.msgs.refFlag;
					_flag = new Table(grp, SWT.SINGLE | SWT.FULL_SELECTION | SWT.BORDER);
					mod(_flag);
					auto gd = new GridData(GridData.FILL_BOTH);
					gd.widthHint = _prop.var.etc.flagsWidth;
					gd.heightHint = _prop.var.etc.flagsHeight;
					_flag.setLayoutData = gd;
					auto colN = new FullTableColumn(_flag, SWT.NONE);
				}
				static if (is (C == MenuCard)) {
					sash.setWeights = [_prop.var.etc.menuCardSashL, _prop.var.etc.menuCardSashR];
				} else static if (is (C == EnemyCard)) {
					sash.setWeights = [_prop.var.etc.enemyCardSashL, _prop.var.etc.enemyCardSashR];
				} else static assert (0);
				sash.addDisposeListener(new SDListener);
			}
			{
				auto grp = new Group(comp, SWT.NONE);
				grp.setText = _prop.msgs.cardPosition;
				grp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				grp.setLayout = new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0);
				auto comp2 = new Composite(grp, SWT.NONE);
				comp2.setLayout = new GridLayout(3, false);
				Spinner createS(string name, int max, int min, bool percent = false) {
					auto comp3 = new Composite(comp2, SWT.NONE);
					auto gl = new GridLayout(percent ? 3 : 2, false);
					gl.marginHeight = 0;
					comp3.setLayout = gl;
					auto l = new Label(comp3, SWT.NONE);
					l.setText = name;
					auto spn = new Spinner(comp3, SWT.BORDER);
					mod(spn);
					spn.setMaximum = max;
					spn.setMinimum = min;
					if (percent) {
						auto lp = new Label(comp3, SWT.NONE);
						lp.setText = "%";
					}
					return spn;
				}
				_x = createS(_prop.msgs.left, _prop.looks.posLeftMax, _prop.looks.posLeftMin);
				_y = createS(_prop.msgs.top, _prop.looks.posTopMax, _prop.looks.posTopMin);
				_scale = createS(_prop.msgs.scale,
					cast(int) rndtol(_prop.looks.cardSizeMax * 100), cast(int) rndtol(_prop.looks.cardSizeMin * 100),
					true);
			}
			static if (is (C == MenuCard)) {
				{
					auto grp = new Group(comp, SWT.NONE);
					grp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
					grp.setLayout = new CenterLayout(SWT.HORIZONTAL);
					grp.setText = _prop.msgs.desc;
					_desc = new FixedWidthText(dwtData(_prop.looks.cardDescFont(_summ ? _summ.legacy : false)), _prop.looks.cardDescLen, grp, SWT.BORDER);
					mod(_desc.widget);
					_desc.widget.setLayoutData = _desc.computeTextBaseSize(_prop.looks.cardDescLine);
				}
			}
			comp.setLayoutData = area.computeSize(SWT.DEFAULT, SWT.DEFAULT);
		}

		auto nof = new TableItem(_flag, SWT.NONE);
		nof.setText = _prop.msgs.noFlag;
		if (_summ) {
			foreach (flag; _summ.flagDirRoot.allFlags) {
				auto itm = new TableItem(_flag, SWT.NONE);
				itm.setImage = _prop.images.flag;
				itm.setText = flag.path;
				itm.setData = flag;
			}
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
				_desc.setText = _card.desc;
				_name.setText = _card.name;
			} else static if (is (C == EnemyCard)) {
				if (_summ) {
					foreach (i, c; _summ.casts) {
						if (c.id == _card.id) {
							_casts.select = i;
							break;
						}
					}
				}
				_escape.setSelection = _card.escape;
			} else {
				static assert (0);
			}
			if (_card.flag.length > 0) {
				foreach (i, itm; _flag.getItems) {
					if (itm.getText == _card.flag) {
						_flag.select(i);
						break;
					}
				}
			} else {
				_flag.select(0);
			}
			_x.setSelection = _card.x;
			_y.setSelection = _card.y;
			_scale.setSelection = cast(int) rndtol(_card.scale * 100);
		} else {
			static if (is (C == MenuCard)) {
				_imgPath.image = "";
				_desc.setText = "";
				_name.setText = "";
			} else static if (is (C == EnemyCard)) {
				_casts.select = 0;
				_escape.setSelection = false;
			} else {
				static assert (0);
			}
			_flag.select(0);
			_x.setSelection = 0;
			_y.setSelection = 0;
			_scale.setSelection = 100;
		}
		_flag.showSelection;
	}

	override bool apply() {
		int fidx = _flag.getSelectionIndex;
		string flag = fidx > 0 ? _flag.getItem(fidx).getText : "";
		if (_card) {
			static if (is (C == MenuCard)) {
				_card.path = _imgPath.image;
				_card.desc = wrapReturnCode(_desc.getText);
				_card.name = _name.getText;
			} else static if (is (C == EnemyCard)) {
				if (_summ && _casts.getSelectionIndex >= 0) {
					_card.id = _summ.casts[_casts.getSelectionIndex].id;
				} else {
					_card.id = 0;
				}
				_card.escape = _escape.getSelection;
			} else {
				static assert (0);
			}
			_card.flag = flag;
			_card.x = _x.getSelection;
			_card.y = _y.getSelection;
			_card.scale = _scale.getSelection / 100.0;
		} else {
			static if (is (C == MenuCard)) {
				_card = new C(_name.getText, _imgPath.image,
					wrapReturnCode(_desc.getText), flag,
					_x.getSelection, _y.getSelection, _scale.getSelection / 100.0);
			} else static if (is (C == EnemyCard)) {
				ulong id;
				if (_summ && _casts.getSelectionIndex >= 0) {
					id = _summ.casts[_casts.getSelectionIndex].id;
				}
				_card = new C(id, _escape.getSelection,
					flag, _x.getSelection, _y.getSelection, _scale.getSelection / 100.0);
			} else {
				static assert (0);
			}
		}
		return true;
	}
}
