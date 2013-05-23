
module cwx.editor.gui.dwt.imageselect;

import cwx.utils;
import cwx.summary;
import cwx.skin;
import cwx.menu;
import cwx.types;
import cwx.imagesize;

import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.materialselect;
import cwx.editor.gui.dwt.imagelistwindow;
import cwx.editor.gui.dwt.dmenu;

import std.algorithm : min;
import std.file;
import std.path;
import std.string;
import std.conv;

import org.eclipse.swt.all;

public:

enum CardMode {
	Message,
	Cast,
	Normal,
}

/// 画像の選択を行うペイン。
class ImageSelect(MtType Type, C : Control = Table) {
	/// パスの変更時に呼び出される。
	void delegate()[] modEvent;
	/// 画像の更新時に呼び出される。
	void delegate()[] updateImageEvent;
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
	/// included = 格納イメージを扱うならtrue。
	/// saveName = 格納イメージを保存する際のデフォルト名。
	/// refresh = 選択が変更された際のコールバック関数。
	/// defs = 画像以外の選択肢。nullの場合は「イメージ無し」と「格納イメージの保存」になる。
	/// createDefImage = 画像以外の選択肢が選ばれた際に表示するイメージ。
	this (Composite parent, int style, Commons comm, Props prop, Summary summ,
			int w, int h, bool included, bool canInclude, string delegate() saveName, void delegate() refresh = null,
			string[] defs = null, ImageData delegate(size_t defIndex) createDefImage = null, bool isMenuCard = false) {
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
			group.setText(prop.msgs.image);
			_group = group;
			auto gl = new GridLayout(2, false);
			gl.verticalSpacing = 0;
			_group.setLayout(gl);

			auto compl = new Composite(_group, SWT.NONE);
			compl.setLayoutData(new GridData(GridData.FILL_VERTICAL));
			compl.setLayout(zeroMarginGridLayout(1, false));

			auto compr = new Composite(_group, SWT.NONE);
			auto cgd = new GridData(GridData.FILL_BOTH);
			cgd.verticalSpan = 2;
			compr.setLayoutData(cgd);
		} else static if (is(C == Combo) || is(C == CCombo)) {
			// 話者選択等
			_group = new Composite(parent, style);
			_group.setLayout(zeroMarginGridLayout(1, false));

			auto compr = new Composite(_group, SWT.NONE);
			auto cgd = new GridData(GridData.FILL_HORIZONTAL);
			compr.setLayoutData(cgd);

			auto compl = new Composite(_group, SWT.NONE);
			compl.setLayoutData(new GridData(GridData.FILL_BOTH));
			compl.setLayout(zeroMarginGridLayout(1, false));
		}
		{
			{
				auto comp = new Composite(compl, SWT.NONE);
				comp.setLayoutData(new GridData(GridData.FILL_BOTH));
				comp.setLayout(new CenterLayout(SWT.VERTICAL | SWT.HORIZONTAL, 0));
				_image = new Canvas(comp, SWT.BORDER | SWT.DOUBLE_BUFFERED);
				_image.setLayoutData(_image.computeSize(w, h));
				_image.addPaintListener(new PListener);
			}
			if (defs) {
				_msel = new MaterialSelect!(Type, Combo, C)
					(comm, prop, summ, &__refresh, defs, -1, canInclude, isMenuCard);
			} else if (included) {
				_defs = [prop.msgs.imageNone, prop.msgs.imageIncluding];
				_msel = new MaterialSelect!(Type, Combo, C)
					(comm, prop, summ, &__refresh, _defs, 1, canInclude, isMenuCard);
			} else {
				_defs = [prop.msgs.imageNone];
				_msel = new MaterialSelect!(Type, Combo, C)
					(comm, prop, summ, &__refresh, _defs, -1, canInclude, isMenuCard);
			}
			_msel.modEvent ~= {
				foreach (dlg; modEvent) dlg();
			};
			{
				auto comp = new Composite(compl, SWT.NONE);
				comp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				comp.setLayout(zeroMarginGridLayout(3, false));
				auto imgList = new Button(comp, SWT.TOGGLE);
				imgList.setLayoutData(new GridData(GridData.FILL_VERTICAL));
				imgList.setImage(_prop.images.menu(MenuID.LookImages));
				imgList.setToolTipText(_prop.buildTool(MenuID.LookImages));
				imgList.addSelectionListener(new SelImageList);
				_msel.createRefreshButton(comp, true).setLayoutData(new GridData(GridData.FILL_BOTH));
				_msel.createDirectoryButton(comp, false).setLayoutData(new GridData(GridData.FILL_VERTICAL));
				static if (Type is MtType.CARD) {
					_noCardSize = new Button(compl, SWT.CHECK);
					_noCardSize.setText(prop.msgs.useNoCardSizeImage);
					auto ncsgd = new GridData(GridData.HORIZONTAL_ALIGN_END);
					ncsgd.horizontalSpan = 3;
					_noCardSize.setLayoutData(ncsgd);
					_noCardSize.setSelection(_msel.useNoCardSizeImage);
					.listener(_noCardSize, SWT.Selection, {
						_msel.useNoCardSizeImage = _noCardSize.getSelection();
					});
				}
			}
		}
		{
			compr.setLayout(zeroMarginGridLayout(1, true));
			{
				auto dirsComp = new Composite(compr, SWT.NONE);
				dirsComp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));

				Button saveIncludeImage = null;
				void createSaveButton() {
					if (saveIncludeImage) return;
					saveIncludeImage = new Button(dirsComp, SWT.PUSH);
					saveIncludeImage.setImage(_prop.images.menu(MenuID.SaveImage));
					saveIncludeImage.setToolTipText(_prop.buildTool(MenuID.SaveImage));
					saveIncludeImage.addSelectionListener(new SaveIncImg);
				}

				auto dirs = _msel.createDirsCombo(dirsComp);
				dirs.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				dirs.addSelectionListener(new DirSelect);
				if (included) {
					dirsComp.setLayout(zeroMarginGridLayout(2, false));
					createSaveButton();
				} else {
					dirsComp.setLayout(zeroMarginGridLayout(1, false));
					_msel.includeEvent ~= (string fname) {
						if (saveIncludeImage) return;
						dirsComp.setLayout(zeroMarginGridLayout(2, false));
						createSaveButton();
						dirsComp.layout();
						compr.layout();
					};
				}
			}
			{
				auto fileList = _msel.createFileList(compr);
				auto gd = new GridData(GridData.FILL_BOTH);
				gd.widthHint = _prop.var.etc.filesWidth;
				gd.heightHint = fileList.computeSize(SWT.DEFAULT, SWT.DEFAULT).y;
				fileList.setLayoutData(gd);
				fileList.addSelectionListener(new FileSelect);
				_msel.incSearch.modEvent ~= &refreshImageList;
			}
		}
	} 
	@property
	void mask(bool mask) {
		_mask = mask;
		_image.redraw();
		if (_imgList && !_imgList.shell.isDisposed()) {
			_imgList.mask = mask;
		}
	}
	@property
	bool mask() {
		return _mask;
	}
	/// 画像のファイルパス。
	@property
	string image() {
		return _msel.path;
	}
	@property
	string filePath() {
		return _msel.filePath;
	}
	/// Params:
	/// path = 画像のファイルパス。
	@property
	void image(string path) {
		_msel.path = path;
		_image.redraw();
	}
	@property
	Composite widget() {
		return _group;
	}
	@property
	Point sampleSize() {
		return new Point(_w, _h);
	}
	@property
	Combo dirsCombo() {
		return _msel.dirsCombo;
	}
	@property
	C fileList() {
		return _msel.fileList;
	}
	@property
	void selectDir(int sel) {
		_msel.selectDir(sel);
		selectDirImpl(sel);
	}
	static if (Type == MtType.CARD) {
		@property
		uint pcNumber() {
			return _msel.pcNumber;
		}
		@property
		void pcNumber(uint pcNum) {
			_msel.pcNumber = pcNum;
			__refresh();
		}
	}

	@property
	string[] warnings() {
		string[] ws;
		auto img = filePath;
		if (isBinImg(img)) {
			auto bin =  cast(ubyte[]) strToBImg(img);
			auto type = imageType(bin);
			if ("" != type) {
				img = "image".setExtension(type);
				ws ~= _comm.skin.warningImage(_prop.parent, img, _summ ? false : _summ.legacy);
				static if (Type is MtType.CARD) {
					uint w, h;
					imageSize(bin, w, h);
					auto cs = _prop.looks.cardSize;
					if (cs.width != w && cs.height != h) {
						ws ~= _prop.msgs.warningNoCardSizeImage;
					}
				}
			}
		} else {
			ws ~= _comm.skin.warningImage(_prop.parent, img, _summ ? false : _summ.legacy);
			static if (Type is MtType.CARD) {
				if (img.length) {
					uint w, h;
					imageSize(img, w, h);
					auto cs = _prop.looks.cardSize;
					if (cs.width != w && cs.height != h) {
						ws ~= _prop.msgs.warningNoCardSizeImage;
					}
				}
			}
		}
		return ws;
	}

	static if (Type is MtType.CARD) {
		@property
		void cardMode(CardMode cardMode) {
			_cardMode = cardMode;
			_image.redraw();
		}
	}
private:
	void selectDirImpl(int sel) {
		auto dirs = dirsCombo;
		if (-1 == sel && _oldDirSel == sel) return;
		_oldDirSel = sel;
		refreshImageList();
	}
	void refreshImageList() {
		if (_imgList && !_imgList.shell.isDisposed()) {
			_imgList.images(dirsCombo.getText(), _msel.showingPaths);
			_imgList.select(_msel.path);
		}
	}
	class DirSelect : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			selectDirImpl(dirsCombo.getSelectionIndex());
		}
	}
	class FileSelect : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			if (_imgList && !_imgList.shell.isDisposed()) {
				_imgList.select(_msel.path);
			}
		}
	}
	class SelImageList : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			auto b = cast(Button) e.widget;
			if (b.getSelection()) {
				if (_imgList && !_imgList.shell.isDisposed()) {
					_imgList.shell.setActive();
					return;
				}
				auto parent = (cast(Control) e.widget).getShell();
				_imgList = new ImageListWindow!Type(_prop, _comm, _summ, parent, (string path) {
					image(path);
					__refresh();
				});
				.listener(_imgList.shell, SWT.Dispose, {
					b.setSelection(false);
				});
				auto menu = new Menu(_imgList.shell, SWT.POP_UP);
				createMenuItem(_comm, menu, MenuID.IncSearch, &_msel.startIncSearch, null);
				_imgList.widget.setMenu(menu);

				auto cloc = Display.getCurrent().getCursorLocation();
				cloc.x++;
				cloc.y++;
				auto p = new Point(_prop.var.etc.imageListWidth, _prop.var.etc.imageListHeight);
				intoDisplay(cloc.x, cloc.y, p.x, p.y);
				_imgList.shell.setBounds(cloc.x, cloc.y, p.x, p.y);
				_imgList.images(dirsCombo.getText(), _msel.showingPaths);
				static if (Type == MtType.BG_IMG) {
					_imgList.mask = mask;
				}
				_imgList.select(_msel.path);
				_imgList.shell.open();
			} else {
				if (!_imgList || _imgList.shell.isDisposed()) {
					return;
				}
				_imgList.shell.close();
				_imgList.shell.dispose();
			}
		}
	}
	class SaveIncImg : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			auto path = _msel.binPath;
			if (!isBinImg(path)) return;
			ubyte[] bytes = strToBImg(path);
			auto dlg = new FileDialog(_image.getShell(), SWT.APPLICATION_MODAL | SWT.SINGLE | SWT.SAVE);
			dlg.setFilterExtensions(["*.bmp"]);
			dlg.setFilterNames([_prop.msgs.filterBitmapImage]);
			dlg.setText(_prop.msgs.dlgTitSaveBitmapImage);
			auto dir = _msel.filePath;
			if (isBinImg(dir)) {
				if (_summ) {
					dir = _summ.scenarioPath;
				} else {
					dir = getcwd();
				}
			} else {
				if (!.exists(dir) || !isDir(dir)) dir = dirName(dir);
			}
			dlg.setFilterPath(dir);
			string s = _saveName().strip().toFileName();
			if (!s.length) s = _prop.var.etc.noFileName;
			dlg.setFileName(setExtension(s, ".bmp"));
			dlg.setOverwrite(true);
			string fname = dlg.open();
			if (fname) {
				std.file.write(fname, bytes);
			}
		}
	}
	class PListener : PaintListener {
		private ImageData _img = null;
		public override void paintControl(PaintEvent e) {
			static if (is(typeof(_msel.pcNumber))) {
				auto pcNum = _msel.pcNumber;
				if (0 != pcNum) {
					drawCenterText(dwtData(_prop.looks.pcNumberFont(_comm.skin.legacy)), e.gc, _image.getClientArea(), .text(pcNum));
					return;
				}
			}
			int dirsi = dirsCombo.getSelectionIndex();
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
			scope img = new Image(Display.getCurrent(), imgData);
			scope b = img.getBounds();
			scope area = _image.getClientArea();
			int x, y, w, h, fw, fh;
			static if (Type is MtType.CARD) {
				final switch (_cardMode) {
				case CardMode.Message:
					x = 0;
					w = .min(b.width, area.width);
					fw = w;
					fh = b.height;
					h = fh;
					y = (area.height - fh) / 2;
					break;
				case CardMode.Cast:
					fw = b.width;
					fh = b.height;
					w = fw;
					h = fh;
					x = (area.width - fw) / 2;
					y = (area.height - fh) / 2;
					break;
				case CardMode.Normal:
					x = 0;
					y = 0;
					w = .min(b.width, area.width);
					h = .min(b.height, area.height);
					fw = w;
					fh = h;
					break;
				}
			} else {
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
				fw = b.width;
				fh = b.height;
			}
			e.gc.drawImage(img, 0, 0, fw, fh, x, y, w, h);
			img.dispose();
		}
	}
	void __refresh() {
		if (_refresh) _refresh();
		_paintedPath = null;
		_image.redraw();
		refreshImageList();
		foreach (dlg; updateImageEvent) {
			dlg();
		}
		static if (Type is MtType.CARD) {
			_noCardSize.setSelection(_msel.useNoCardSizeImage);
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
	string delegate() _saveName;
	bool _mask = true;
	void delegate() _refresh;
	int _oldDirSel = -1;
	static if (Type is MtType.CARD) {
		Button _noCardSize;
		CardMode _cardMode = CardMode.Normal;
	}
}
