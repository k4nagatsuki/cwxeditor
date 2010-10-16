
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

import dwt.DWT;
import dwt.DWTException;
import dwt.widgets.Composite;
import dwt.widgets.Control;
import dwt.widgets.Canvas;
import dwt.widgets.Display;
import dwt.widgets.List;
import dwt.widgets.Group;
import dwt.widgets.Combo;
import dwt.widgets.Button;
import dwt.widgets.MessageBox;
import dwt.layout.GridLayout;
import dwt.layout.GridData;
import dwt.graphics.Image;
import dwt.graphics.ImageData;
import dwt.events.PaintListener;
import dwt.events.PaintEvent;
import dwt.events.SelectionAdapter;
import dwt.events.SelectionEvent;
import dwt.events.DisposeListener;
import dwt.events.DisposeEvent;
import dwt.dnd.DropTargetAdapter;

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
	/// refresh = 選択が変更された際のコールバック関数。
	this(Composite parent, int style, Commons comm, Props prop, Summary summ,
			int w, int h, bool canIncluding, void delegate() refresh = null) {
		_group = new Group(parent, style);
		_prop = prop;
		_summ = summ;
		_refresh = refresh;
		_w = w;
		_h = h;
		{
			auto gl = new GridLayout(2, false);
			gl.verticalSpacing = 0;
			_group.setLayout = gl;
			_group.setText = prop.msgs.image;
		}
		{
			auto compl = new Composite(_group, DWT.NONE);
			compl.setLayoutData = new GridData(GridData.FILL_VERTICAL);
			compl.setLayout = zeroMarginGridLayout(1, false);
			{
				auto comp = new Composite(compl, DWT.NONE);
				comp.setLayoutData = new GridData(GridData.FILL_BOTH);
				comp.setLayout = new CenterLayout(DWT.VERTICAL | DWT.HORIZONTAL, 0);
				_image = new Canvas(comp, DWT.BORDER | DWT.DOUBLE_BUFFERED);
				_image.setLayoutData = _image.computeSize(w, h);
				_image.addPaintListener(new PListener);
			}
			auto skin = findSkin(_prop, _summ);
			if (canIncluding) {
				_msel = new MaterialSelect!(Type, Combo, List)
					(comm, prop, _summ, &__refresh,
					[prop.msgs.imageNone, prop.msgs.imageIncluding], 1);
			} else {
				_msel = new MaterialSelect!(Type, Combo, List)
					(comm, prop, _summ, &__refresh, [prop.msgs.imageNone]);
			}
			{
				auto comp = new Composite(compl, DWT.NONE);
				comp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				comp.setLayout = zeroMarginGridLayout(2, false);
				_msel.createRefreshButton(comp, true).setLayoutData
					= new GridData(GridData.FILL_BOTH);
				_msel.createDirectoryButton(comp, false).setLayoutData
					= new GridData(GridData.FILL_VERTICAL);
			}
		}
		{
			auto comp = new Composite(_group, DWT.NONE);
			auto cgd = new GridData(GridData.FILL_BOTH);
			cgd.verticalSpan = 2;
			comp.setLayoutData = cgd;
			comp.setLayout = zeroMarginGridLayout(1, false);
			{
				_msel.createDirsCombo(comp).setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			}
			{
				auto fileList = _msel.createFileList(comp);
				auto gd = new GridData(GridData.FILL_BOTH);
				gd.widthHint = _prop.var.etc.filesWidth;
				gd.heightHint = fileList.computeSize(DWT.DEFAULT, DWT.DEFAULT).y;
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
	class PListener : PaintListener {
		public override void paintControl(PaintEvent e) {
			auto path = filePath;
			if (path !is null && path.length > 0) {
				scope data = loadImage(path, _mask);
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
	Props _prop;
	Summary _summ;
	Canvas _image;
	MaterialSelect!(Type, Combo, List) _msel;
	int _w, _h;
	bool _mask = true;
	void delegate() _refresh;
}
