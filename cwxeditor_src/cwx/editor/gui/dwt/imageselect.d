
module cwx.editor.gui.dwt.imageselect;

import cwx.utils;
import cwx.summary;
import cwx.skin;
import cwx.menu;
import cwx.types;
import cwx.imagesize;
import cwx.card;

import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.materialselect;
import cwx.editor.gui.dwt.imagelistwindow;
import cwx.editor.gui.dwt.imagelayer;
import cwx.editor.gui.dwt.dmenu;

import std.algorithm : max, min;
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
	/// canInclude = 格納イメージを扱うならtrue。
	/// saveName = 格納イメージを保存する際のデフォルト名。
	/// refresh = 選択が変更された際のコールバック関数。
	/// defs = 画像以外の選択肢。nullの場合は「イメージ無し」になる。
	this (Composite parent, int style, Commons comm, Props prop, Summary summ,
			int w, int h, bool canInclude, string delegate() saveName, void delegate() refresh = null,
			string[] delegate(bool included) defs = null, bool isMenuCard = false) { mixin(S_TRACE);
		_readOnly = style & SWT.READ_ONLY;
		_comm = comm;
		_prop = prop;
		_summ = summ;
		if (_readOnly) _summSkin = findSkin(_comm, _prop, _summ);
		_refresh = refresh;
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
				static if (Type == MtType.CARD) {
					auto preview = new Composite(compl, SWT.NONE);
					static if (is(C:Combo) || is(C:CCombo)) {
						preview.setLayout(zeroMarginGridLayout(1, true));
					} else {
						preview.setLayout(zeroGridLayout(1, true));
					}
					preview.setLayoutData(new GridData(GridData.FILL_BOTH));
					auto layerNameComp = new Composite(preview, SWT.NONE);
					auto cl = new CenterLayout(SWT.VERTICAL | SWT.HORIZONTAL, 0);
					cl.fillHorizontal = true;
					layerNameComp.setLayout(cl);
					_layerName = new Label(layerNameComp, SWT.CENTER);
					_layerName.setText(.tryFormat(_prop.msgs.layerName, 1));
				} else {
					auto preview = compl;
				}
				auto comp = new Composite(preview, SWT.NONE);
				comp.setLayoutData(new GridData(GridData.FILL_BOTH));
				comp.setLayout(new CenterLayout(SWT.VERTICAL | SWT.HORIZONTAL, 0));
				_image = new Canvas(comp, SWT.BORDER | SWT.DOUBLE_BUFFERED);
				_image.setLayoutData(_image.computeSize(w, h));
				_image.addPaintListener(new PListener);
				.listener(_image, SWT.Dispose, { mixin(S_TRACE);
					foreach (img; _img) { mixin(S_TRACE);
						if (img) { mixin(S_TRACE);
							img.data[] = 0;
							delete img.data;
						}
					}
					_img = [];
				});
			}
			if (defs) { mixin(S_TRACE);
				_msel = new MaterialSelect!(Type, Combo, C)
					(comm, prop, summ, _readOnly != 0, &this.refresh, defs, canInclude, isMenuCard);
			} else { mixin(S_TRACE);
				defs = (included) { mixin(S_TRACE);
					auto defs = [prop.msgs.defaultSelection(prop.msgs.imageNone)];
					if (included) defs ~= _prop.msgs.defaultSelection(_prop.msgs.imageIncluding);
					return defs;
				};
				_msel = new MaterialSelect!(Type, Combo, C)
					(comm, prop, summ, _readOnly != 0, &this.refresh, defs, canInclude, isMenuCard);
				_msel.indexOfBinPath = (included) => included ? 1 : -1;
				static if (Type == MtType.CARD) {
					_msel.valueFromDef = (index, included, binPath) { mixin(S_TRACE);
						if (index == 0) return new CardImage("");
						if (included && index == 1) return new CardImage(binPath);
						assert (0);
					};
					_msel.valueToDef = (imgPath, included) { mixin(S_TRACE);
						if (imgPath.type == CardImageType.File) { mixin(S_TRACE);
							if (imgPath.path == "") return 0;
							if (included && imgPath.path.isBinImg) return 1;
						}
						return -1;
					};
				}
			}
			_msel.modEvent ~= { mixin(S_TRACE);
				foreach (dlg; modEvent) dlg();
			};
			_msel.loadedEvent ~= &_image.redraw;
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
				_comm.put(imgList, () => !_readOnly && !_msel.loading);
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
					_comm.put(_noCardSize, () => !_readOnly && !_msel.loading);
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

				static if (Type == MtType.CARD) {
					auto dirsComp2 = new Composite(dirsComp, SWT.NONE);
					dirsComp2.setLayout(zeroMarginGridLayout(2, false));
					dirsComp2.setLayoutData(new GridData(GridData.FILL_BOTH));
				} else {
					auto dirsComp2 = dirsComp;
				}
				auto dirs = _msel.createDirsCombo(dirsComp2);
				dirs.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				dirs.addSelectionListener(new DirSelect);

				static if (Type == MtType.CARD) {
					_layerButton = new Button(dirsComp2, SWT.TOGGLE);
					_layerButton.setEnabled(!_summ.legacy);
					_layerButton.setImage(_prop.images.menu(MenuID.EditLayers));
					_layerButton.setToolTipText(_prop.msgs.menuText(MenuID.EditLayers));
					.listener(_layerButton, SWT.Selection, &editLayers);
					void update() { mixin(S_TRACE);
						if (!_layers) return;
						_layers.list.images = _msel.paths;
					}
					modEvent ~= &update;
					updateImageEvent ~= &update;
					if (_readOnly) { mixin(S_TRACE);
						_comm.put(_layerButton, () => !_summ.legacy && 1 < _msel.paths.length);
					} else { mixin(S_TRACE);
						// すでに2枚以上レイヤがある場合は編集可能にしておく
						_comm.put(_layerButton, () => !_summ.legacy || 1 < _msel.paths.length);
					}
				}

				dirsComp.setLayout(zeroMarginGridLayout(1, false));
				_msel.includeEvent ~= { mixin(S_TRACE);
					if (saveIncludeImage) return;
					dirsComp.setLayout(zeroMarginGridLayout(2, false));
					createSaveButton();
					dirsComp.layout();
					compr.layout();
				};
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
		static if (Type == MtType.CARD) {
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			static if (!(is(C:Combo) || is(C:CCombo))) {
				auto h1 = _layerButton.computeSize(SWT.DEFAULT, SWT.DEFAULT).y;
				auto h2 = dirsCombo.computeSize(SWT.DEFAULT, SWT.DEFAULT).y;
				gd.heightHint = .max(h1, h2);
			}
			_layerName.getParent().setLayoutData(gd);
		}
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

	@property
	void indexOfBinPath(int delegate(bool included) dlg) { mixin(S_TRACE);
		_msel.indexOfBinPath = dlg;
	}
	static if (Type == MtType.CARD) {
		@property
		void valueFromDef(CardImage delegate(int index, bool included, string binPath) dlg) { mixin(S_TRACE);
			_msel.valueFromDef = dlg;
		}
		@property
		void valueToDef(int delegate(in CardImage imgPath, bool included) dlg) { mixin(S_TRACE);
			_msel.valueToDef = dlg;
		}
		/// 画像のファイルパス。
		@property
		CardImage[] images() { mixin(S_TRACE);
			CardImage[] r;
			foreach (path; _msel.paths) { mixin(S_TRACE);
				final switch (path.type) {
				case CardImageType.File:
					if (path.path != "") r ~= path;
					break;
				case CardImageType.PCNumber:
					if (0 < path.pcNumber) r ~= path;
					break;
				case CardImageType.Talker:
					r ~= path;
					break;
				}
			}
			return r;
		}
		/// Params:
		/// path = 画像のファイルパス。
		@property
		void images(CardImage[] paths) { mixin(S_TRACE);
			_msel.paths = paths;
			_image.redraw();
		}
	} else static if (Type == MtType.BG_IMG) {
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
	} else static assert (0);
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

	@property
	string[] warnings() { mixin(S_TRACE);
		string[] ws;
		static if (Type == MtType.CARD) {
			foreach (img; _msel.paths) { mixin(S_TRACE);
				if (img.type == CardImageType.File) { mixin(S_TRACE);
					ws ~= warningFrom(img.path);
				}
				if (img.type == CardImageType.PCNumber) { mixin(S_TRACE);
					if (!_prop.targetVersion("1.50") && 0 != img.pcNumber && _summ) { mixin(S_TRACE);
						ws ~= _prop.msgs.warningPCNumberClassic;
					}
				}
			}
		} else static if (Type == MtType.BG_IMG) {
			ws ~= warningFrom(filePath);
		} else static assert (0);
		bool[string] wSet;
		string[] ws2;
		foreach (w; ws) { mixin(S_TRACE);
			if (w !in wSet) { mixin(S_TRACE);
				ws2 ~= w;
				wSet[w] = true;
			}
		}
		return ws2;
	}
	static if (Type == MtType.CARD || Type == MtType.BG_IMG) {
		private string[] warningFrom(string img) { mixin(S_TRACE);
			string[] ws;
			if (isBinImg(img)) { mixin(S_TRACE);
				auto bin =  cast(ubyte[])strToBImg(img);
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
						img = summSkin.findImagePath(img, _summ ? _summ.scenarioPath : "");
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
				}, b);
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
			static if (Type == MtType.CARD) {
				if (_msel.paths.length < _paintedPaths.length) { mixin(S_TRACE);
					foreach (i; _msel.paths.length .. _paintedPaths.length) { mixin(S_TRACE);
						if (_img[i]) { mixin(S_TRACE);
							_img[i].data[] = 0;
							delete _img[i].data;
						}
					}
				}
				_paintedPaths.length = _msel.paths.length;
				_img.length = _msel.paths.length;
				foreach (i, path; _msel.paths) { mixin(S_TRACE);
					drawImage(e.gc, i, path);
				}
			} else static if (Type == MtType.BG_IMG) {
				_paintedPaths.length = 1;
				_img.length = 1;
				drawImage(e.gc, 0, filePath);
			} else static assert (0);
		}
		private void drawImage(GC gc, size_t i, CardImage path) { mixin(S_TRACE);
			final switch (path.type) {
			case CardImageType.File:
				auto file = summSkin.findImagePath(path.path, _summ ? _summ.scenarioPath : "");
				if (file != "") { mixin(S_TRACE);
					drawImage(gc, i, file);
				}
				break;
			case CardImageType.PCNumber:
				_paintedPaths[i] = "";
				auto pcNum = path.pcNumber;
				if (0 != pcNum) { mixin(S_TRACE);
					drawCenterText(dwtData(_prop.looks.pcNumberFont(summSkin.legacy)), gc, _image.getClientArea(), .text(pcNum));
				}
				break;
			case CardImageType.Talker:
				final switch (path.talker) {
				case Talker.SELECTED:
				case Talker.UNSELECTED:
				case Talker.RANDOM:
				case Talker.VALUED:
					_paintedPaths[i] = "";
					drawImage(gc, _prop.images.talker(path.talker).getImageData());
					break;
				case Talker.CARD:
					_paintedPaths[i] = "";
					auto cRect = _prop.looks.cardSize;
					drawImage(gc, menuCard(summSkin).scaledTo(cRect.width, cRect.height));
					break;
				}
				break;
			}
		}
		private void drawImage(GC gc, size_t i, string path) { mixin(S_TRACE);
			ImageData imgData = null;
			if (path !is null && path.length > 0) { mixin(S_TRACE);
				if (!_paintedPaths[i] && _paintedPaths[i] == path) { mixin(S_TRACE);
					imgData = _img[i];
				} else { mixin(S_TRACE);
					_paintedPaths[i] = path;
					imgData = loadImage(_prop, summSkin, _summ, path, _mask);
					if (_img[i]) { mixin(S_TRACE);
						_img[i].data[] = 0;
						delete _img[i].data;
					}
					_img[i] = imgData;
				}
			}
			drawImage(gc, imgData);
		}
		private void drawImage(GC gc, ImageData imgData) { mixin(S_TRACE);
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
			gc.drawImage(img, 0, 0, fw, fh, x, y, w, h);
			img.dispose();
		}
	}
	void refresh() { mixin(S_TRACE);
		if (_refresh) _refresh();
		_paintedPaths = [];
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

	static if (Type == MtType.CARD) {
		void editLayers() { mixin(S_TRACE);
			if (_layerButton.getSelection()) { mixin(S_TRACE);
				if (_layers) { mixin(S_TRACE);
					_layers.shell.setActive();
					return;
				}
				_layers = new ImageLayerWindow(_comm, _summ, _mask, _readOnly != 0, _layerButton);
				auto cloc = Display.getCurrent().getCursorLocation();
				cloc.x++;
				cloc.y++;
				auto p = new Point(_prop.var.etc.layerListWidth, _prop.var.etc.layerListHeight);
				intoDisplay(cloc.x, cloc.y, p.x, p.y);
				_layers.shell.setBounds(cloc.x, cloc.y, p.x, p.y);
				.listener(_layers.shell, SWT.Dispose, { mixin(S_TRACE);
					_layerButton.setSelection(false);
					_layers = null;
				});
				_layers.list.selectionEvent ~= { mixin(S_TRACE);
					_msel.imageIndex = _layers.list.selection;
					_layerName.setText(.tryFormat(_prop.msgs.layerName, _layers.list.selection + 1));
				};
				_layers.list.modEvent ~= { mixin(S_TRACE);
					_msel.paths = _layers.list.images;
					refresh();
				};
				_layers.list.images = _msel.paths;
				_layers.list.selection = _msel.imageIndex;
				_layers.shell.open();
				_comm.refreshToolBar();
			} else { mixin(S_TRACE);
				if (!_layers) return;
				_layers.close();
				_layers = null;
			}
		}
	}

	int _readOnly = 0;
	string[] _paintedPaths = [];
	Composite _group;
	Commons _comm;
	Props _prop;
	Summary _summ;
	Canvas _image;
	MaterialSelect!(Type, Combo, C) _msel;
	ImageListWindow!Type _imgList = null;
	int _w, _h;
	string delegate() _saveName;
	bool _mask = true;
	void delegate() _refresh;
	int _oldDirSel = -1;
	private ImageData[] _img = [];
	static if (Type is MtType.CARD) {
		Button _noCardSize;
		CardMode _cardMode = CardMode.Normal;
		Button _layerButton = null;
		ImageLayerWindow _layers = null;
		Label _layerName = null;
	}
	Skin _summSkin;
}
