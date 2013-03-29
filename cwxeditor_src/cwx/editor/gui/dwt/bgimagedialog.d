
module cwx.editor.gui.dwt.bgimagedialog;

import cwx.area;
import cwx.flag;
import cwx.utils;
import cwx.summary;
import cwx.background;
import cwx.imagesize;
import cwx.skin;
import cwx.structs;
import cwx.menu;
import cwx.types;
import cwx.path;

import cwx.editor.gui.dwt.properties;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.materialselect;
import cwx.editor.gui.dwt.imageselect;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.incsearch;

import org.eclipse.swt.all;

import java.lang.all;

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

	string _selectedFlag = "";
	IncSearch _flagIncSearch;
	void flagIncSearch() {
		.forceFocus(_flag, true);
		_flagIncSearch.startIncSearch();
	}

	void refreshWarning() {
		warning = _comm.skin.warningImage(_prop.parent, _imgPath.filePath, _summ ? _summ.legacy : false);
	}

	void select() {
		if (!_selected || _easy.getSelectionIndex() == 1) {
			string file = _imgPath.filePath;
			if (file.length > 0) {
				try {
					uint x, y;
					dwtImageSize(_comm.skin, file, x, y);
					_w.setSelection(x);
					_h.setSelection(y);
					_selected = true;
					_comm.refreshToolBar();
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
			_imgPath.mask = (cast(Button) e.widget).getSelection();
		}
	}
	class SettingsListener : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			auto c = cast(Combo) e.widget;
			int i = c.getSelectionIndex();
			switch (i) {
			case 0:
				break;
			case 1:
				select();
				applyEnabled();
				break;
			default:
				_selected = true;
				auto s = _prop.var.etc.bgImageSettings[i - 2];
				_x.setSelection(s.x);
				_y.setSelection(s.y);
				_w.setSelection(s.width);
				_h.setSelection(s.height);
				_mask.setSelection(s.mask);
				_imgPath.mask = s.mask;
				applyEnabled();
			}
			_comm.refreshToolBar();
		}
	}
	class SDListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			auto sash = cast(SplitPane) e.widget;
			auto ws = sash.getWeights();
			_prop.var.etc.backSashL = ws[0];
			_prop.var.etc.backSashR = ws[1];
		}
	}
	void delBgImage(string cwxPath) {
		if (_back && _back.cwxPath(true) == cwxPath) {
			forceCancel();
		}
	}
	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			_comm.delBgImage.remove(&delBgImage);
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
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, BgImage back, bool create) {
		_comm = comm;
		_summ = summ;
		_back = back;
		_prop = prop;
		_selected = !create;
		DSize size;
		if (_summ) {
			size = _prop.var.areaBackgroundDlg;
		} else {
			size = _prop.var.areaBackgroundNFDlg;
		}
		super(prop, shell, false,
			_back ? _prop.msgs.dlgTitBgImage : _prop.msgs.dlgTitNewBgImage,
			_prop.images.backs, true, size, true);
		enterClose = true;
	}

	@property
	BgImage back() {
		return _back;
	}
protected:
	override void setup(Composite area) {
		area.setLayout(zeroGridLayout(1));
		auto skin = _comm.skin;
		{
			auto comp = new Composite(area, SWT.NONE);
			comp.setLayout(new GridLayout(1, false));
			void imgs(Composite parent) {
				_imgPath = new ImageSelect!(MtType.BG_IMG)(parent, SWT.NONE, _comm, _prop, _summ,
					_prop.var.etc.bgImageSampleWidth, _prop.var.etc.bgImageSampleHeight, false, false, () => "", &select);
				mod(_imgPath);
				_imgPath.modEvent ~= &refreshWarning;
			}
			if (_summ) {
				auto sash = new SplitPane(comp, SWT.HORIZONTAL);
				sash.setLayoutData(new GridData(GridData.FILL_BOTH));
				{
					imgs(sash);
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
					createMenuItem(_comm, menu, MenuID.OpenAtVarView, &openFlagView, () => _flag.getSelectionIndex() != -1);
					_flag.setMenu(menu);
				}
				sash.setWeights([_prop.var.etc.backSashL, _prop.var.etc.backSashR]);
				sash.addDisposeListener(new SDListener);

				_comm.refFlagAndStep.add(&refFlags);
				_comm.delFlagAndStep.add(&delFlags);
				.listener(_flag, SWT.Dispose, {
					_comm.refFlagAndStep.remove(&refFlags);
					_comm.delFlagAndStep.remove(&delFlags);
				});
			} else {
				// フラグ無し
				imgs(comp);
				_imgPath.widget.setLayoutData(new GridData(GridData.FILL_BOTH));
			}
			{
				auto grp = new Group(comp, SWT.NONE);
				grp.setText(_prop.msgs.cardPosition);
				grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				grp.setLayout(new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0));
				auto comp2 = new Composite(grp, SWT.NONE);
				comp2.setLayout(new GridLayout(5, false));
				Spinner createS(string name, int max, int min) {
					auto comp3 = new Composite(comp2, SWT.NONE);
					auto gl = new GridLayout(2, false);
					gl.marginHeight = 0;
					comp3.setLayout(gl);
					auto l = new Label(comp3, SWT.NONE);
					l.setText(name);
					auto spn = new Spinner(comp3, SWT.BORDER);
					mod(spn);
					spn.setMaximum(max);
					spn.setMinimum(min);
					spn.setSelection(0);
					return spn;
				}
				_x = createS(_prop.msgs.left, _prop.var.etc.posLeftMax, -(cast(int) _prop.var.etc.posLeftMax));
				_y = createS(_prop.msgs.top, _prop.var.etc.posTopMax, -(cast(int) _prop.var.etc.posTopMax));
				_w = createS(_prop.msgs.width, _prop.var.etc.backWidthMax, 0);
				_h = createS(_prop.msgs.height, _prop.var.etc.backHeightMax, 0);
				_mask = new Button(comp2, SWT.TOGGLE);
				mod(_mask);
				_mask.setImage(_prop.images.menu(MenuID.Mask));
				_mask.setToolTipText(_prop.buildTool(MenuID.Mask));
				_mask.addSelectionListener(new MaskListener);
			}
			{
				auto comp2 = new Composite(comp, SWT.NONE);
				comp2.setLayout(new GridLayout(2, false));
				comp2.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
				auto l = new Label(comp2, SWT.NONE);
				l.setText(_prop.msgs.bgImageSettings);
				_easy = new Combo(comp2, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
				_easy.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
				_easy.add(_prop.msgs.bgImageSettingCustom);
				_easy.add(_prop.msgs.bgImageSettingOriginal);
				foreach (bs; _prop.var.etc.bgImageSettings) {
					_easy.add(bs.name);
				}
				_easy.addSelectionListener(new SettingsListener);
				_easy.select(0);
			}
			scope p = comp.computeSize(SWT.DEFAULT, SWT.DEFAULT);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.widthHint = p.x;
			gd.heightHint = p.y;
			comp.setLayoutData(gd);
		}

		if (_flag) {
			refreshFlags();
		}
		area.addDisposeListener(new Dispose);
		_comm.delBgImage.add(&delBgImage);

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_back) {
			_imgPath.image = _back.path;
			_imgPath.mask = _back.mask;
			if (_flag) {
				_flag.select(0);
				_selectedFlag = "";
				if (_back.flag.length > 0) {
					foreach (i, itm; _flag.getItems()) {
						auto flag = cast(Flag) itm.getData();
						if (!flag) continue;
						string path = flag.path;
						if (path == _back.flag) {
							_flag.select(i);
							_selectedFlag = path;
							break;
						}
					}
				}
			}
			_x.setSelection(_back.x);
			_y.setSelection(_back.y);
			_w.setSelection(_back.width);
			_h.setSelection(_back.height);
			_mask.setSelection(_back.mask);
		} else {
			_imgPath.image = "";
			_imgPath.mask = false;
			if (_flag) {
				_flag.select(0);
				_selectedFlag = "";
			}
			_x.setSelection(0);
			_y.setSelection(0);
			_w.setSelection(0);
			_h.setSelection(0);
			_mask.setSelection(false);
		}
		if (_flag) _flag.showSelection();
		auto spnl = new SModL;
		_w.addModifyListener(spnl);
		_h.addModifyListener(spnl);
	}

	override bool apply() {
		if (_back) {
			_back.path = _imgPath.image;
			_back.flag = _selectedFlag;
			_back.x = _x.getSelection();
			_back.y = _y.getSelection();
			_back.width = _w.getSelection();
			_back.height = _h.getSelection();
			_back.mask = _mask.getSelection();
		} else {
			_back = new BgImage(_imgPath.image, _selectedFlag,
				_x.getSelection(), _y.getSelection(), _w.getSelection(), _h.getSelection(),
				_mask.getSelection());
		}
		return true;
	}
}
