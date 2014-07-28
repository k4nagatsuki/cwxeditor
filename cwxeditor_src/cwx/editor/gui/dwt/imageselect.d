
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
			string[] defs = null, ImageData delegate(size_t defIndex) createDefImage = null, bool isMenuCard = false) { mixin(S_TRACE);
		_readOnly = style & SWT.READ_ONLY;
		_comm = comm;
		_prop = prop;
		_summ = summ;
		if (_readOnly) _summSkin = findSkin(_comm, _prop, _summ);
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
			_group.setTabList([compr, compl]);
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
		Button imgList;
		{ mixin(S_TRACE);
			{ mixin(S_TRACE);
				auto comp = new Composite(compl, SWT.NONE);
				comp.setLayoutData(new GridData(GridData.FILL_BOTH));
				comp.setLayout(new CenterLayout(SWT.VERTICAL | SWT.HORIZONTAL, 0));
				_image = new Canvas(comp, SWT.BORDER | SWT.DOUBLE_BUFFERED);
				_image.setLayoutData(_image.computeSize(w, h));
				_image.addPaintListener(new PListener);
				.listener(_image, SWT.Dispose, { mixin(S_TRACE);
					if (_img) { mixin(S_TRACE);
						_img.data[] = 0;
						delete _img.data;
					}
				});
			}
			if (defs) { mixin(S_TRACE);
				_msel = new MaterialSelect!(Type, Combo, C)
					(comm, prop, summ, _readOnly != 0, &this.refresh, defs, -1, canInclude, isMenuCard);
			} else if (included) { mixin(S_TRACE);
				_defs = [prop.msgs.imageNone, prop.msgs.imageIncluding];
				_msel = new MaterialSelect!(Type, Combo, C)
					(comm, prop, summ, _readOnly != 0, &this.refresh, _defs, 1, canInclude, isMenuCard);
			} else { mixin(S_TRACE);
				_defs = [prop.msgs.imageNone];
				_msel = new MaterialSelect!(Type, Combo, C)
					(comm, prop, summ, _readOnly != 0, &this.refresh, _defs, -1, canInclude, isMenuCard);
			}
			_msel.modEvent ~= { mixin(S_TRACE);
				foreach (dlg; modEvent) dlg();
			};
			{ mixin(S_TRACE);
				auto comp = new Composite(compl, SWT.NONE);
				comp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				comp.setLayout(zeroMarginGridLayout(3, false));
				imgList = new Button(comp, SWT.TOGGLE);
				imgList.setEnabled(!_readOnly);
				imgList.setLayoutData(new GridData(GridData.FILL_VERTICAL));
				imgList.setImage(_prop.images.menu(MenuID.LookImages));
				imgList.setToolTipText(_prop.msgs.menuText(MenuID.LookImages));
				imgList.addSelectionListener(new SelImageList);
				_msel.createRefreshButton(comp, true).setLayoutData(new GridData(GridData.FILL_BOTH));
				_msel.createDirectoryButton(comp, false).setLayoutData(new GridData(GridData.FILL_VERTICAL));
				static if (Type is MtType.CARD) {
					_noCardSize = new Button(compl, SWT.CHECK);
					_noCardSize.setEnabled(!_readOnly);
					_noCardSize.setText(prop.msgs.useNoCardSizeImage);
					auto ncsgd = new GridData(GridData.HORIZONTAL_ALIGN_END);
					ncsgd.horizontalSpan = 3;
					_noCardSize.setLayoutData(ncsgd);
					_noCardSize.setSelection(_msel.useNoCardSizeImage);
					.listener(_noCardSize, SWT.Selection, { mixin(S_TRACE);
						_msel.useNoCardSizeImage = _noCardSize.getSelection();
					});
				}
			}
		}
		{ mixin(S_TRACE);
			compr.setLayout(zeroMarginGridLayout(1, true));
			{ mixin(S_TRACE);
				auto dirsComp = new Composite(compr, SWT.NONE);
				dirsComp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));

				Button saveIncludeImage = null;
				void createSaveButton() { mixin(S_TRACE);
					if (saveIncludeImage) return;
					saveIncludeImage = new Button(dirsComp, SWT.PUSH);
					saveIncludeImage.setImage(_prop.images.menu(MenuID.SaveImage));
					saveIncludeImage.setToolTipText(_prop.msgs.menuText(MenuID.SaveImage));
					saveIncludeImage.addSelectionListener(new SaveIncImg);
				}

				auto dirs = _msel.createDirsCombo(dirsComp);
				dirs.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				dirs.addSelectionListener(new DirSelect);
				if (included) { mixin(S_TRACE);
					dirsComp.setLayout(zeroMarginGridLayout(2, false));
					createSaveButton();
				} else { mixin(S_TRACE);
					dirsComp.setLayout(zeroMarginGridLayout(1, false));
					_msel.includeEvent ~= (string fname) { mixin(S_TRACE);
						if (saveIncludeImage) return;
						dirsComp.setLayout(zeroMarginGridLayout(2, false));
						createSaveButton();
						dirsComp.layout();
						compr.layout();
					};
				}
			}
			{ mixin(S_TRACE);
				auto fileList = _msel.createFileList(compr);
				auto gd = new GridData(GridData.FILL_BOTH);
				gd.widthHint = _prop.var.etc.filesWidth;
				gd.heightHint = fileList.computeSize(SWT.DEFAULT, SWT.DEFAULT).y;
				fileList.setLayoutData(gd);
				fileList.addSelectionListener(new FileSelect);
				_msel.incSearch.modEvent ~= &refreshImageList;
			}
		}
		auto d = parent.getDisplay();
		auto focusFilter = new class Listener {
			override void handleEvent(Event e) { mixin(S_TRACE);
				if (!imgList.isVisible() && _imgList && !_imgList.shell.isDisposed()) { mixin(S_TRACE);
					_imgList.shell.close();
					_imgList.shell.dispose();
				}
			}
		};
		d.addFilter(SWT.FocusOut, focusFilter);
		d.addFilter(SWT.Selection, focusFilter);
		.listener(imgList, SWT.Dispose, { mixin(S_TRACE);
			d.removeFilter(SWT.FocusOut, focusFilter);
			d.removeFilter(SWT.Selection, focusFilter);
		});
	} 
	@property
	void mask(bool mask) { mixin(S_TRACE);
		_mask = mask;
		_image.redraw();
		if (_imgList && !_imgList.shell.isDisposed()) { mixin(S_TRACE);
			_imgList.mask = mask;
		}
	}
	@property
	bool mask() { mixin(S_TRACE);
		return _mask;
	}
	/// 画像のファイルパス。
	@property
	string image() { mixin(S_TRACE);
		return _msel.path;
	}
	@property
	string filePath() { mixin(S_TRACE);
		return _msel.filePath;
	}
	/// Params:
	/// path = 画像のファイルパス。
	@property
	void image(string path) { mixin(S_TRACE);
		_msel.path = path;
		_image.redraw();
	}
	@property
	Composite widget() { mixin(S_TRACE);
		return _group;
	}
	@property
	Point sampleSize() { mixin(S_TRACE);
		return new Point(_w, _h);
	}
	@property
	Combo dirsCombo() { mixin(S_TRACE);
		return _msel.dirsCombo;
	}
	@property
	C fileList() { mixin(S_TRACE);
		return _msel.fileList;
	}
	@property
	void selectDir(int sel) { mixin(S_TRACE);
		_msel.selectDir(sel);
		selectDirImpl(sel);
	}
	static if (Type == MtType.CARD) {
		@property
		uint pcNumber() { mixin(S_TRACE);
			return _msel.pcNumber;
		}
		@property
		void pcNumber(uint pcNum) { mixin(S_TRACE);
			_msel.pcNumber = pcNum;
			refresh();
		}
	}

	@property
	string[] warnings() { mixin(S_TRACE);
		string[] ws;
		auto img = filePath;
		if (isBinImg(img)) { mixin(S_TRACE);
			auto bin =  cast(ubyte[]) strToBImg(img);
			auto type = imageType(bin);
			if ("" != type) { mixin(S_TRACE);
				img = "image".setExtension(type);
				ws ~= summSkin.warningImage(_prop.parent, img, _summ ? _summ.legacy : false, _msel.canInclude, _prop.var.etc.targetVersion);
				static if (Type is MtType.CARD) {
					uint w, h;
					imageSize!(ubyte[])(bin, w, h);
					auto cs = _prop.looks.cardSize;
					if (cs.width != w && cs.height != h) { mixin(S_TRACE);
						ws ~= _prop.msgs.warningNoCardSizeImage;
					}
				}
			}
		} else { mixin(S_TRACE);
			ws ~= summSkin.warningImage(_prop.parent, img, _summ ? _summ.legacy : false, _msel.canInclude && !_msel.isMenuCard, _prop.var.etc.targetVersion);
			static if (Type is MtType.CARD) {
				if (img.length) { mixin(S_TRACE);
					uint w, h;
					imageSize(img, w, h);
					auto cs = _prop.looks.cardSize;
					if (cs.width != w && cs.height != h) { mixin(S_TRACE);
						ws ~= _prop.msgs.warningNoCardSizeImage;
					}
				}
			}
		}
		return ws;
	}

	static if (Type is MtType.CARD) {
		@property
		void cardMode(CardMode cardMode) { mixin(S_TRACE);
			_cardMode = cardMode;
			_image.redraw();
		}
	}
private:
	void selectDirImpl(int sel) { mixin(S_TRACE);
		auto dirs = dirsCombo;
		if (-1 == sel && _oldDirSel == sel) return;
		_oldDirSel = sel;
		refreshImageList();
	}
	void refreshImageList() { mixin(S_TRACE);
		if (_imgList && !_imgList.shell.isDisposed()) { mixin(S_TRACE);
			_imgList.images(dirsCombo.getText(), _msel.showingPaths);
			_imgList.select(encodePath(_msel.path));
		}
	}
	class DirSelect : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			selectDirImpl(dirsCombo.getSelectionIndex());
		}
	}
	class FileSelect : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			if (_imgList && !_imgList.shell.isDisposed()) { mixin(S_TRACE);
				_imgList.select(encodePath(_msel.path));
			}
		}
	}
	class SelImageList : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			auto b = cast(Button) e.widget;
			if (b.getSelection()) { mixin(S_TRACE);
				if (_imgList && !_imgList.shell.isDisposed()) { mixin(S_TRACE);
					_imgList.shell.setActive();
					return;
				}
				auto parent = (cast(Control) e.widget).getShell();
				_imgList = new ImageListWindow!Type(_prop, _comm, _summ, parent, (string path) { mixin(S_TRACE);
					_msel.path2(path, false);
					_image.redraw();
					refresh();
				});
				.listener(_imgList.shell, SWT.Dispose, { mixin(S_TRACE);
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
				_imgList.select(encodePath(_msel.path));
				_imgList.shell.open();
			} else { mixin(S_TRACE);
				if (!_imgList || _imgList.shell.isDisposed()) { mixin(S_TRACE);
					return;
				}
				_imgList.shell.close();
				_imgList.shell.dispose();
			}
		}
	}
	class SaveIncImg : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			auto path = _msel.binPath;
			if (!isBinImg(path)) return;
			ubyte[] bytes = strToBImg(path);
			auto dlg = new FileDialog(_image.getShell(), SWT.APPLICATION_MODAL | SWT.SINGLE | SWT.SAVE);
			dlg.setFilterExtensions(["*.bmp"]);
			dlg.setFilterNames([_prop.msgs.filterBitmapImage]);
			dlg.setText(_prop.msgs.dlgTitSaveBitmapImage);
			auto dir = _msel.filePath;
			if (isBinImg(dir)) { mixin(S_TRACE);
				if (_summ) { mixin(S_TRACE);
					dir = _summ.scenarioPath;
				} else { mixin(S_TRACE);
					dir = getcwd();
				}
			} else { mixin(S_TRACE);
				if (!.exists(dir) || !isDir(dir)) dir = dirName(dir);
			}
			dlg.setFilterPath(dir);
			string s = _saveName().strip().toFileName();
			if (!s.length) s = _prop.var.etc.noFileName;
			dlg.setFileName(setExtension(s, ".bmp"));
			dlg.setOverwrite(true);
			string fname = dlg.open();
			if (fname) { mixin(S_TRACE);
				std.file.write(fname, bytes);
			}
		}
	}
	class PListener : PaintListener {
		public override void paintControl(PaintEvent e) { mixin(S_TRACE);
			static if (is(typeof(_msel.pcNumber))) {
				auto pcNum = _msel.pcNumber;
				if (0 != pcNum) { mixin(S_TRACE);
					drawCenterText(dwtData(_prop.looks.pcNumberFont(summSkin.legacy)), e.gc, _image.getClientArea(), .text(pcNum));
					return;
				}
			}
			int dirsi = dirsCombo.getSelectionIndex();
			string path = filePath;
			ImageData imgData = null;
			if (path !is null && path.length > 0) { mixin(S_TRACE);
				if (!_paintedPath && _paintedPath == path) { mixin(S_TRACE);
					imgData = _img;
				} else { mixin(S_TRACE);
					_paintedPath = path;
					imgData = loadImage(_prop, summSkin, _summ, path, _mask);
					if (_img) { mixin(S_TRACE);
						_img.data[] = 0;
						delete _img.data;
					}
					_img = imgData;
				}
			} else if (_createDefImage && dirsi < _defs.length) { mixin(S_TRACE);
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
			} else { mixin(S_TRACE);
				if (area.width >= b.width) { mixin(S_TRACE);
					x = (area.width - b.width) / 2;
					w = b.width;
				} else { mixin(S_TRACE);
					x = 0;
					w = area.width;
				}
				if (area.height >= b.height) { mixin(S_TRACE);
					y = (area.height - b.height) / 2;
					h = b.height;
				} else { mixin(S_TRACE);
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
	void refresh() { mixin(S_TRACE);
		if (_refresh) _refresh();
		_paintedPath = null;
		_image.redraw();
		refreshImageList();
		foreach (dlg; updateImageEvent) { mixin(S_TRACE);
			dlg();
		}
		static if (Type is MtType.CARD) {
			_noCardSize.setSelection(_msel.useNoCardSizeImage);
		}
	}
	@property
	Skin summSkin() { mixin(S_TRACE);
		return _summSkin ? _summSkin : _comm.skin;
	}
	int _readOnly = 0;
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
	private ImageData _img = null;
	static if (Type is MtType.CARD) {
		Button _noCardSize;
		CardMode _cardMode = CardMode.Normal;
	}
	Skin _summSkin;
}
