
module cwx.editor.gui.dwt.imageselect;

import cwx.utils;
import cwx.summary;
import cwx.skin;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.materialselect;
import cwx.editor.gui.dwt.imagelistwindow;

import std.file;
import std.path;

import org.eclipse.swt.SWT;
import org.eclipse.swt.SWTException;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Canvas;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.Group;
import org.eclipse.swt.widgets.Combo;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.MessageBox;
import org.eclipse.swt.widgets.FileDialog;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.ImageData;
import org.eclipse.swt.events.PaintListener;
import org.eclipse.swt.events.PaintEvent;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.dnd.DropTargetAdapter;

public:

/// 画像の選択を行うペイン。
class ImageSelect(MtType Type, C : Control = Table) {
	/// パスの変更時に呼び出される。
	void delegate()[] modEvent;
public:
	/// Params:
	/// parent = 親。
	/// style = スタイル。
	/// comm = 共有関数。
	/// prop = 設定データ。
	/// skin = スキンデータ。
	/// summ = シナリオ情報。
	/// w = 画像表示欄の幅。
	/// h = 画像表示欄の高さ。
	/// targ = ファイルパスを受取り、選択対象であればtrueを返す関数。
	/// canIncluding = 格納イメージを扱うならtrue。
	/// saveName = 格納イメージを保存する際のデフォルト名。
	/// refresh = 選択が変更された際のコールバック関数。
	/// defs = 画像以外の選択肢。nullの場合は「イメージ無し」と「格納イメージの保存」になる。
	/// createDefImage = 画像以外の選択肢が選ばれた際に表示するイメージ。
	this(Composite parent, int style, Commons comm, Props prop, Summary summ,
			int w, int h, bool canIncluding, string saveName, void delegate() refresh = null,
			string[] defs = null, ImageData delegate(size_t defIndex) createDefImage = null) {
		_comm = comm;
		_prop = prop;
		_summ = summ;
		_refresh = refresh;
		_defs = defs;
		_createDefImage = createDefImage;
		_w = w;
		_h = h;
		_saveName = saveName;
		static if (is(C == Table)) {
			// 背景イメージ選択等
			auto group = new Group(parent, style);
			group.setText = prop.msgs.image;
			_group = group;
			auto gl = new GridLayout(2, false);
			gl.verticalSpacing = 0;
			_group.setLayout = gl;

			auto compl = new Composite(_group, SWT.NONE);
			compl.setLayoutData = new GridData(GridData.FILL_VERTICAL);
			compl.setLayout = zeroMarginGridLayout(1, false);

			auto compr = new Composite(_group, SWT.NONE);
			auto cgd = new GridData(GridData.FILL_BOTH);
			cgd.verticalSpan = 2;
			compr.setLayoutData = cgd;
		} else static if (is(C == Combo) || is(C == CCombo)) {
			// 話者選択等
			_group = new Composite(parent, style);
			_group.setLayout = zeroMarginGridLayout(1, false);

			auto compr = new Composite(_group, SWT.NONE);
			auto cgd = new GridData(GridData.FILL_HORIZONTAL);
			compr.setLayoutData = cgd;

			auto compl = new Composite(_group, SWT.NONE);
			compl.setLayoutData = new GridData(GridData.FILL_BOTH);
			compl.setLayout = zeroMarginGridLayout(1, false);
		}
		{
			{
				auto comp = new Composite(compl, SWT.NONE);
				comp.setLayoutData = new GridData(GridData.FILL_BOTH);
				comp.setLayout = new CenterLayout(SWT.VERTICAL | SWT.HORIZONTAL, 0);
				_image = new Canvas(comp, SWT.BORDER | SWT.DOUBLE_BUFFERED);
				_image.setLayoutData = _image.computeSize(w, h);
				_image.addPaintListener(new PListener);
			}
			if (defs) {
				_msel = new MaterialSelect!(Type, Combo, C)
					(comm, prop, summ, &__refresh, defs);
			} else if (canIncluding) {
				_defs = [prop.msgs.imageNone, prop.msgs.imageIncluding];
				_msel = new MaterialSelect!(Type, Combo, C)
					(comm, prop, summ, &__refresh, _defs, 1);
			} else {
				_defs = [prop.msgs.imageNone];
				_msel = new MaterialSelect!(Type, Combo, C)
					(comm, prop, summ, &__refresh, _defs);
			}
			_msel.modEvent ~= {
				foreach (dlg; modEvent) dlg();
			};
			{
				auto comp = new Composite(compl, SWT.NONE);
				comp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				comp.setLayout = zeroMarginGridLayout(3, false);
				auto imgList = new Button(comp, SWT.PUSH);
				imgList.setLayoutData = new GridData(GridData.FILL_VERTICAL);
				imgList.setImage = _prop.images.menuImageList;
				imgList.setToolTipText = _prop.msgs.ttImageList;
				imgList.addSelectionListener(new SelImageList);
				_msel.createRefreshButton(comp, true).setLayoutData
					= new GridData(GridData.FILL_BOTH);
				_msel.createDirectoryButton(comp, false).setLayoutData
					= new GridData(GridData.FILL_VERTICAL);
			}
		}
		{
			compr.setLayout = zeroMarginGridLayout(canIncluding ? 2 : 1, false);
			{
				auto dirs = _msel.createDirsCombo(compr);
				dirs.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				dirs.addSelectionListener(new DirSelect);
				if (canIncluding) {
					auto saveIncludeImage = new Button(compr, SWT.PUSH);
					saveIncludeImage.setImage = _prop.images.menuSaveIncludeImage;
					saveIncludeImage.setToolTipText = _prop.msgs.ttSaveIncludeImage;
					saveIncludeImage.addSelectionListener(new SaveIncImg);
				}
			}
			{
				auto fileList = _msel.createFileList(compr);
				auto gd = new GridData(GridData.FILL_BOTH);
				if (canIncluding) {
					gd.horizontalSpan = 2;
				}
				gd.widthHint = _prop.var.etc.filesWidth;
				gd.heightHint = fileList.computeSize(SWT.DEFAULT, SWT.DEFAULT).y;
				fileList.setLayoutData = gd;
				fileList.addSelectionListener(new FileSelect);
			}
		}
	} 
	void mask(bool mask) {
		_mask = mask;
		_image.redraw;
		if (_imgList && !_imgList.shell.isDisposed) {
			_imgList.mask = mask;
		}
	}
	bool mask() {
		return _mask;
	}
	/// 画像のファイルパス。
	string image() {
		return _msel.path;
	}
	string filePath() {
		return _msel.filePath;
	}
	/// Params:
	/// path = 画像のファイルパス。
	void image(string path) {
		_msel.path = path;
		_image.redraw();
	}
	Composite widget() {
		return _group;
	}
	Point sampleSize() {
		return new Point(_w, _h);
	}
	Combo dirsCombo() {
		return _msel.dirsCombo;
	}
	C fileList() {
		return _msel.fileList;
	}
private:
	class DirSelect : SelectionAdapter {
		private int _oldSel = -1;
		override void widgetSelected(SelectionEvent e) {
			auto dirs = cast(Combo) e.widget;
			int sel = dirs.getSelectionIndex;
			if (-1 == sel && _oldSel == sel) return;
			_oldSel = sel;
			if (_imgList && !_imgList.shell.isDisposed) {
				_imgList.images(dirs.getText, _msel.showingPaths);
				_imgList.select(_msel.path);
			}
		}
	}
	class FileSelect : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			if (_imgList && !_imgList.shell.isDisposed) {
				_imgList.select(_msel.path);
			}
		}
	}
	class SelImageList : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			if (_imgList && !_imgList.shell.isDisposed) {
				_imgList.shell.setActive();
				return;
			}
			auto parent = (cast(Control) e.widget).getShell;
			_imgList = new ImageListWindow!Type(_prop, _comm, _summ, parent, &image);
			_imgList.shell.open();

			auto cloc = Display.getCurrent.getCursorLocation;
			auto p = _imgList.shell.getSize;
			intoDisplay(cloc.x, cloc.y, p.x, p.y);
			_imgList.shell.setLocation(cloc.x, cloc.y);
			_imgList.images(dirsCombo.getText, _msel.showingPaths);
			static if (Type == MtType.BG_IMG) {
				_imgList.mask = mask;
			}
			_imgList.select = _msel.path;
		}
	}
	class SaveIncImg : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			auto path = _msel.oldPath;
			if (!isBinImg(path)) return;
			ubyte[] bytes = strToBImg(path);
			auto dlg = new FileDialog(_image.getShell, SWT.APPLICATION_MODAL | SWT.SINGLE | SWT.SAVE);
			dlg.setFilterExtensions = ["*.bmp"];
			dlg.setFilterNames = [_prop.msgs.filterBitmapImage];
			dlg.setText = _prop.msgs.dlgTitSaveBitmapImage;
			auto dir = _msel.filePath;
			if (isBinImg(dir)) {
				if (_summ) {
					dir = _summ.scenarioPath;
				} else {
					dir = getcwd;
				}
			} else {
				if (!.exists(dir) || !isDir(dir)) dir = getDirName(dir);
			}
			dlg.setFilterPath = dir;
			dlg.setFileName = addExt(_saveName, "bmp");
			dlg.setOverwrite = true;
			string fname = dlg.open;
			if (fname) {
				std.file.write(fname, bytes);
			}
		}
	}
	class PListener : PaintListener {
		private ImageData _img = null;
		public override void paintControl(PaintEvent e) {
			int dirsi = dirsCombo.getSelectionIndex;
			string path = filePath;
			ImageData imgData = null;
			if (path !is null && path.length > 0) {
				if (!_paintedPath && _paintedPath == path) {
					imgData = _img;
				} else {
					_paintedPath = path;
					imgData = loadImage(_comm.skin, path, _mask);
					_img = imgData;
				}
			} else if (_createDefImage && dirsi < _defs.length) {
				imgData = _createDefImage(dirsi);
			}
			if (!imgData) return;
			scope img = new Image(Display.getCurrent, imgData);
			scope b = img.getBounds;
			scope area = _image.getClientArea;
			int x, y, w, h;
			if (area.width >= b.width) {
				x = (area.width - b.width) / 2;
				w = b.width;
			} else {
				x = 0;
				w = area.width;
			}
			if (area.height >= b.height) {
				y = (area.height - b.height) / 2;
				h = b.height;
			} else {
				y = 0;
				h = area.height;
			}
			e.gc.drawImage(img, 0, 0, b.width, b.height, x, y, w, h);
			img.dispose();
		}
	}
	void __refresh() {
		if (_refresh) _refresh();
		_paintedPath = null;
		_image.redraw;
		if (_imgList && !_imgList.shell.isDisposed) {
			_imgList.images(dirsCombo.getText, _msel.showingPaths);
			_imgList.select(_msel.path);
		}
	}
	string _paintedPath = null;
	Composite _group;
	Commons _comm;
	Props _prop;
	Summary _summ;
	Canvas _image;
	MaterialSelect!(Type, Combo, C) _msel;
	ImageListWindow!Type _imgList = null;
	ImageData delegate(size_t defIndex) _createDefImage;
	string[] _defs;
	int _w, _h;
	string _saveName;
	bool _mask = true;
	void delegate() _refresh;
}
