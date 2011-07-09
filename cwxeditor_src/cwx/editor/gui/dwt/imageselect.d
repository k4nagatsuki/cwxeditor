
module cwx.editor.gui.dwt.imageselect;

import cwx.utils;
import cwx.summary;
import cwx.skin;
import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.utils;
import cwx.editor.gui.dwt.skin;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.materialselect;

import std.file;
import std.path;

import org.eclipse.swt.SWT;
import org.eclipse.swt.SWTException;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Canvas;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.List;
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
class ImageSelect(MtType Type) {
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
	this(Composite parent, int style, Commons comm, Props prop, Summary summ,
			int w, int h, bool canIncluding, string saveName, void delegate() refresh = null) {
		_group = new Group(parent, style);
		_comm = comm;
		_prop = prop;
		_summ = summ;
		_refresh = refresh;
		_w = w;
		_h = h;
		_saveName = saveName;
		{
			auto gl = new GridLayout(2, false);
			gl.verticalSpacing = 0;
			_group.setLayout = gl;
			_group.setText = prop.msgs.image;
		}
		{
			auto compl = new Composite(_group, SWT.NONE);
			compl.setLayoutData = new GridData(GridData.FILL_VERTICAL);
			compl.setLayout = zeroMarginGridLayout(1, false);
			{
				auto comp = new Composite(compl, SWT.NONE);
				comp.setLayoutData = new GridData(GridData.FILL_BOTH);
				comp.setLayout = new CenterLayout(SWT.VERTICAL | SWT.HORIZONTAL, 0);
				_image = new Canvas(comp, SWT.BORDER | SWT.DOUBLE_BUFFERED);
				_image.setLayoutData = _image.computeSize(w, h);
				_image.addPaintListener(new PListener);
			}
			if (canIncluding) {
				_msel = new MaterialSelect!(Type, Combo, List)
					(comm, prop, summ, &__refresh,
					[prop.msgs.imageNone, prop.msgs.imageIncluding], 1);
			} else {
				_msel = new MaterialSelect!(Type, Combo, List)
					(comm, prop, summ, &__refresh, [prop.msgs.imageNone]);
			}
			{
				auto comp = new Composite(compl, SWT.NONE);
				comp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				comp.setLayout = zeroMarginGridLayout(2, false);
				_msel.createRefreshButton(comp, true).setLayoutData
					= new GridData(GridData.FILL_BOTH);
				_msel.createDirectoryButton(comp, false).setLayoutData
					= new GridData(GridData.FILL_VERTICAL);
			}
		}
		{
			auto comp = new Composite(_group, SWT.NONE);
			auto cgd = new GridData(GridData.FILL_BOTH);
			cgd.verticalSpan = 2;
			comp.setLayoutData = cgd;
			comp.setLayout = zeroMarginGridLayout(canIncluding ? 2 : 1, false);
			{
				_msel.createDirsCombo(comp).setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				if (canIncluding) {
					auto saveIncludeImage = new Button(comp, SWT.PUSH);
					saveIncludeImage.setImage = _prop.images.menuSaveIncludeImage;
					saveIncludeImage.setToolTipText = _prop.msgs.ttSaveIncludeImage;
					saveIncludeImage.addSelectionListener(new SaveIncImg);
				}
			}
			{
				auto fileList = _msel.createFileList(comp);
				auto gd = new GridData(GridData.FILL_BOTH);
				if (canIncluding) {
					gd.horizontalSpan = 2;
				}
				gd.widthHint = _prop.var.etc.filesWidth;
				gd.heightHint = fileList.computeSize(SWT.DEFAULT, SWT.DEFAULT).y;
				fileList.setLayoutData = gd;
			}
		}
	}
	void mask(bool mask) {
		_mask = mask;
		_image.redraw;
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
	List fileList() {
		return _msel.fileList;
	}
private:
	class SaveIncImg : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			auto path = _msel.oldPath;
			if (!isBinImg(path)) return;
			ubyte[] bytes = strToBImg(path);
			auto dlg = new FileDialog(_image.getShell, SWT.PRIMARY_MODAL | SWT.APPLICATION_MODAL | SWT.SINGLE | SWT.SAVE);
			dlg.setFilterExtensions = ["*.bmp"];
			dlg.setFilterNames = [_prop.msgs.filterBitmapImage];
			dlg.setText = _prop.msgs.dlgTitSaveBitmapImage;
			auto dir = _msel.filePath;
			if (isBinImg(dir)) {
				dir = _summ.scenarioPath;
			} else {
				if (!.exists(dir) || !isdir(dir)) dir = getDirName(dir);
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
		public override void paintControl(PaintEvent e) {
			auto path = filePath;
			if (path !is null && path.length > 0) {
				scope data = loadImage(_comm.skin, path, _mask);
				scope img = new Image(Display.getCurrent, data);
				scope area = _image.getClientArea;
				int x, y, w, h;
				if (area.width >= data.width) {
					x = (area.width - data.width) / 2;
					w = data.width;
				} else {
					x = 0;
					w = area.width;
				}
				if (area.height >= data.height) {
					y = (area.height - data.height) / 2;
					h = data.height;
				} else {
					y = 0;
					h = area.height;
				}
				e.gc.drawImage(img, 0, 0, data.width, data.height, x, y, w, h);
				img.dispose;
			}
		}
	}
	void __refresh() {
		if (_refresh) _refresh();
		_image.redraw;
	}
	Group _group;
	Commons _comm;
	Props _prop;
	Summary _summ;
	Canvas _image;
	MaterialSelect!(Type, Combo, List) _msel;
	int _w, _h;
	string _saveName;
	bool _mask = true;
	void delegate() _refresh;
}
