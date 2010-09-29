
module cwx.editor.gui.dwt.bgimagedialog;

import cwx.area;
import cwx.flag;
import cwx.utils;
import cwx.summary;
import cwx.background;
import cwx.imagesize;
import cwx.skin;

import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.skin;
import cwx.editor.gui.dwt.utils;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.materialselect;
import cwx.editor.gui.dwt.imageselect;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.absdialog;

import dwt.DWT;
import dwt.widgets.Display;
import dwt.widgets.Shell;
import dwt.widgets.Control;
import dwt.widgets.Combo;
import dwt.widgets.Composite;
import dwt.widgets.Event;
import dwt.widgets.Label;
import dwt.widgets.Listener;
import dwt.widgets.Group;
import dwt.widgets.Button;
import dwt.widgets.TabFolder;
import dwt.widgets.TabItem;
import dwt.widgets.Spinner;
import dwt.widgets.Table;
import dwt.widgets.TableColumn;
import dwt.widgets.TableItem;
import dwt.widgets.Text;
import dwt.widgets.Menu;
import dwt.widgets.MenuItem;
import dwt.layout.GridLayout;
import dwt.layout.GridData;
import dwt.graphics.Image;
import dwt.graphics.ImageData;
import dwt.events.DisposeListener;
import dwt.events.DisposeEvent;
import dwt.events.ModifyListener;
import dwt.events.ModifyEvent;
import dwt.events.SelectionAdapter;
import dwt.events.SelectionEvent;
import dwt.dwthelper.utils;

public:

/// 背景画像の設定を行うダイアログ。
class BgImageDialog : AbsDialog {
private:
	Commons _comm;
	Props _prop;
	Summary _summ;
	BgImage _back;

	ImageSelect!(MtType.BG_IMG) _imgPath;
	Table _flag;
	Spinner _x;
	Spinner _y;
	Spinner _w;
	Spinner _h;
	Button _mask;
	Combo _easy;
	bool _selected;

	void select() {
		if (!_selected || _easy.getSelectionIndex == 1) {
			string file = _imgPath.filePath;
			if (file.length > 0) {
				try {
					uint x, y;
					imageSize(file, x, y);
					_w.setSelection = x;
					_h.setSelection = y;
					_selected = true;
				} catch {}
			}
		}
	}
	class SModL : ModifyListener {
		override void modifyText(ModifyEvent e) {
			_selected = true;
		}
	};
	class MaskListener : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			_imgPath.mask = (cast(Button) e.widget).getSelection;
		}
	}
	class SettingsListener : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			auto c = cast(Combo) e.widget;
			int i = c.getSelectionIndex;
			switch (i) {
			case 0:
				break;
			case 1:
				select;
				break;
			default:
				_selected = true;
				auto s = _prop.var.etc.bgImageSettings[i - 2];
				_x.setSelection = s.x;
				_y.setSelection = s.y;
				_w.setSelection = s.width;
				_h.setSelection = s.height;
				_mask.setSelection = s.mask;
				_imgPath.mask = s.mask;
			}
		}
	}
public:
	this(Commons comm, Props prop, Shell shell, Summary summ, BgImage back) {
		assert (summ !is null);
		_comm = comm;
		_summ = summ;
		_back = back;
		_prop = prop;
		_selected = back !is null;
		super(prop, shell,
			_back ? _prop.msgs.dlgTitBgImage : _prop.msgs.dlgTitNewBgImage,
			_prop.images.backs, true, _prop.var.areaBackgroundDlg);
	}

	BgImage back() {
		return _back;
	}
protected:
	override void setup(Composite area) {
		area.setLayout = zeroGridLayout(1);
		{
			auto comp = new Composite(area, DWT.NONE);
			comp.setLayout = new GridLayout(2, false);
			{
				auto skin = findSkin(_prop, _summ);
				_imgPath = new ImageSelect!(MtType.BG_IMG)(comp, DWT.NONE, _comm, _prop, _summ,
					_prop.var.etc.bgImageSampleWidth, _prop.var.etc.bgImageSampleHeight, false, &select);
				_imgPath.widget.setLayoutData = new GridData(GridData.FILL_BOTH);
			}
			{
				auto grp = new Group(comp, DWT.NONE);
				grp.setLayoutData = new GridData(GridData.FILL_BOTH);
				grp.setLayout = new GridLayout(2, false);
				grp.setText = _prop.msgs.refFlag;
				_flag = new Table(grp, DWT.SINGLE | DWT.FULL_SELECTION | DWT.BORDER);
				auto gd = new GridData(GridData.FILL_BOTH);
				gd.widthHint = _prop.var.etc.flagsWidth;
				_flag.setLayoutData = gd;
				auto colN = new FullTableColumn(_flag, DWT.NONE);
			}
			{
				auto grp = new Group(comp, DWT.NONE);
				grp.setText = _prop.msgs.cardPosition;
				auto ggd = new GridData(GridData.FILL_HORIZONTAL);
				ggd.horizontalSpan = 2;
				grp.setLayoutData = ggd;
				grp.setLayout = new CenterLayout(DWT.HORIZONTAL | DWT.VERTICAL, 0);
				auto comp2 = new Composite(grp, DWT.NONE);
				comp2.setLayout = new GridLayout(5, false);
				Spinner createS(string name, int max, int min) {
					auto comp3 = new Composite(comp2, DWT.NONE);
					auto gl = new GridLayout(2, false);
					gl.marginHeight = 0;
					comp3.setLayout = gl;
					auto l = new Label(comp3, DWT.NONE);
					l.setText = name;
					auto spn = new Spinner(comp3, DWT.BORDER);
					spn.setMaximum = max;
					spn.setMinimum = min;
					spn.setSelection = 0;
					return spn;
				}
				_x = createS(_prop.msgs.left, _prop.looks.posLeftMax, _prop.looks.posLeftMin);
				_y = createS(_prop.msgs.top, _prop.looks.posTopMax, _prop.looks.posTopMin);
				_w = createS(_prop.msgs.width, _prop.looks.backWidthMax, _prop.looks.backWidthMin);
				_h = createS(_prop.msgs.height, _prop.looks.backHeightMax, _prop.looks.backHeightMin);
				_mask = new Button(comp2, DWT.TOGGLE);
				_mask.setImage = _prop.images.menuMask;
				_mask.setToolTipText = _prop.msgs.ttMask;
				_mask.addSelectionListener(new MaskListener);
			}
			{
				auto comp2 = new Composite(comp, DWT.NONE);
				comp2.setLayout = new GridLayout(2, false);
				auto cgd = new GridData(GridData.HORIZONTAL_ALIGN_END);
				cgd.horizontalSpan = 2;
				comp2.setLayoutData = cgd;
				auto l = new Label(comp2, DWT.NONE);
				l.setText = _prop.msgs.bgImageSettings;
				_easy = new Combo(comp2, DWT.BORDER | DWT.DROP_DOWN | DWT.READ_ONLY);
				_easy.setVisibleItemCount = 20;
				_easy.add(_prop.msgs.bgImageSettingCustom);
				_easy.add(_prop.msgs.bgImageSettingOriginal);
				foreach (bs; _prop.var.etc.bgImageSettings) {
					_easy.add(bs.name);
				}
				_easy.addSelectionListener(new SettingsListener);
				_easy.select = 0;
			}
			scope p = comp.computeSize(DWT.DEFAULT, DWT.DEFAULT);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.widthHint = p.x;
			gd.heightHint = p.y;
			comp.setLayoutData = gd;
		}
		{
			auto l = new Label(area, DWT.SEPARATOR | DWT.HORIZONTAL);
			auto cgd = new GridData(GridData.FILL_HORIZONTAL);
			cgd.horizontalSpan = 2;
			l.setLayoutData = cgd;
		}

		auto nof = new TableItem(_flag, DWT.NONE);
		nof.setText = _prop.msgs.noFlag;
		foreach (flag; _summ.flagDirRoot.allFlags) {
			auto itm = new TableItem(_flag, DWT.NONE);
			itm.setImage = _prop.images.flag;
			itm.setText = flag.path;
			itm.setData = flag;
		}
		if (_back) {
			_imgPath.image = _back.path;
			_imgPath.mask = _back.mask;
			if (_back.flag.length > 0) {
				foreach (i, itm; _flag.getItems) {
					if (itm.getText == _back.flag) {
						_flag.select(i);
						break;
					}
				}
			} else {
				_flag.select(0);
			}
			_x.setSelection = _back.x;
			_y.setSelection = _back.y;
			_w.setSelection = _back.width;
			_h.setSelection = _back.height;
			_mask.setSelection = _back.mask;
		} else {
			_imgPath.image = "";
			_imgPath.mask = false;
			_flag.select(0);
			_x.setSelection = 0;
			_y.setSelection = 0;
			_w.setSelection = 0;
			_h.setSelection = 0;
			_mask.setSelection = false;
		}
		_flag.showSelection;
		auto spnl = new SModL;
		_w.addModifyListener(spnl);
		_h.addModifyListener(spnl);
	}

	override bool close(bool ok) {
		if (ok && _imgPath.image.length > 0) {
			int fidx = _flag.getSelectionIndex;
			string flag = fidx > 0 ? _flag.getItem(fidx).getText : "";
			if (_back) {
				_back.path = _imgPath.image;
				_back.flag = flag;
				_back.x = _x.getSelection;
				_back.y = _y.getSelection;
				_back.width = _w.getSelection;
				_back.height = _h.getSelection;
				_back.mask = _mask.getSelection;
			} else {
				_back = new BgImage(_imgPath.image, flag,
					_x.getSelection, _y.getSelection, _w.getSelection, _h.getSelection,
					_mask.getSelection);
			}
			return true;
		}
		return false;
	}
}
