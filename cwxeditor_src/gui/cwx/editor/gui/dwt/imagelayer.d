
module cwx.editor.gui.dwt.imagelayer;

import cwx.card;
import cwx.menu;
import cwx.skin;
import cwx.summary;
import cwx.types;
import cwx.usecounter;
import cwx.utils;
import cwx.xml;

import cwx.editor.gui.dwt.cardlist;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.xmlbytestransfer;

import std.algorithm : max, min, map;
import std.array;
import std.conv;
import std.datetime;
import std.file;
import std.traits;
import std.typecons;

import org.eclipse.swt.all;

/// CardImageのリストを管理する。
class ImageLayerWindow {
	private Commons _comm = null;

	private Shell _win = null;
	private ImageLayerList _list = null;
	private ImageLayerPanel _layerPanel = null;

	this (Commons comm, const Summary summ, bool mask, bool readOnly, Control parent,
			string delegate() saveName, UndoManager undo, void delegate() store) { mixin(S_TRACE);
		_comm = comm;

		_win = new Shell(parent.getShell(), SWT.TITLE | SWT.RESIZE | SWT.CLOSE | SWT.TOOL);
		if (readOnly) { mixin(S_TRACE);
			_win.setText(comm.prop.msgs.dlgTitImageLayerWindowReadOnly);
		} else { mixin(S_TRACE);
			_win.setText(comm.prop.msgs.dlgTitImageLayerWindow);
		}

		_win.setLayout(zeroGridLayout(2, false));
		ToolBar bar = null;
		if (!readOnly) { mixin(S_TRACE);
			bar = new ToolBar(_win, SWT.FLAT);
			bar.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			comm.put(bar);

			_layerPanel = new ImageLayerPanel(comm, _win, readOnly);
		}

		_list = new ImageLayerList(comm, summ, _win, mask, saveName, undo, store, readOnly);
		if (_layerPanel) _layerPanel.list = _list;
		auto lgd = new GridData(GridData.FILL_BOTH);
		lgd.horizontalSpan = 2;
		_list.setLayoutData(lgd);

		if (bar) { mixin(S_TRACE);
			createToolItem(comm, bar, MenuID.AddLayer, &_list.addLayer, &_list.canAddLayer);
			createToolItem(comm, bar, MenuID.RemoveLayer, &_list.removeLayer, &_list.canRemoveLayer);
			new ToolItem(bar, SWT.SEPARATOR);
			createToolItem(comm, bar, MenuID.Up, &_list.upLayer, &_list.canUpLayer);
			createToolItem(comm, bar, MenuID.Down, &_list.downLayer, &_list.canDownLayer);
		}
		void saveWin() { mixin(S_TRACE);
			auto size = _win.getSize();
			comm.prop.var.etc.layerListWidth = size.x;
			comm.prop.var.etc.layerListHeight = size.y;
		}
		.listener(_win, SWT.Move, &saveWin);
		.listener(_win, SWT.Resize, &saveWin);

		void refDataVersion() { mixin(S_TRACE);
			if (_list._items.length <= 1 && _list._summ.legacy) { mixin(S_TRACE);
				close();
			}
		}
		comm.refDataVersion.add(&refDataVersion);
		.listener(_win, SWT.Dispose, { mixin(S_TRACE);
			comm.refDataVersion.remove(&refDataVersion);
			_list.dispose();
		});

		auto d = parent.getDisplay();
		auto focusFilter = new class Listener {
			override void handleEvent(Event e) { mixin(S_TRACE);
				if (!parent.isVisible()) { mixin(S_TRACE);
					close();
				}
			}
		};
		auto kdFilter = new KeyDownFilter;
		d.addFilter(SWT.KeyDown, kdFilter);
		d.addFilter(SWT.FocusOut, focusFilter);
		d.addFilter(SWT.Selection, focusFilter);
		.listener(_win, SWT.Dispose, { mixin(S_TRACE);
			d.removeFilter(SWT.KeyDown, kdFilter);
			d.removeFilter(SWT.FocusOut, focusFilter);
			d.removeFilter(SWT.Selection, focusFilter);
		});
	}

	private class KeyDownFilter : Listener {
		override void handleEvent(Event e) { mixin(S_TRACE);
			if (!e.doit) return;
			auto c = cast(Control)e.widget;
			if (!c || c.isDisposed() || c.getShell() !is shell) return;
			if (c.getMenu() && findMenu(c.getMenu(), e.keyCode, e.character, e.stateMask)) return;
			foreach (menu; _list.getMenu().getItems()) { mixin(S_TRACE);
				auto data = cast(MenuData)menu.getData();
				if (data) { mixin(S_TRACE);
					auto acc = convertAccelerator(_comm.prop.buildMenu(data.id));
					if (eqAcc(acc, e.keyCode, e.character, e.stateMask)) { mixin(S_TRACE);
						.doMenu(menu, e);
						break;
					}
				}
			}
		}
	}

	@property
	Shell shell() { return _win; }

	@property
	ImageLayerList list() { return _list; }

	void close() { mixin(S_TRACE);
		if (!_win.isDisposed()) { mixin(S_TRACE);
			_win.close();
			_win.dispose();
		}
	}
}

/// CardImageのリスト。
class ImageLayerList : Composite, TCPD {
	void delegate()[] selectionEvent;
	void delegate()[] modEvent;
	private void delegate()[] updateEvent;

	private int _readOnly = 0;

	private Commons _comm = null;
	private const(Summary) _summ = null;
	private Skin _summSkin = null;
	private bool _mask = false;

	private ImageLayerItem[] _items = [];
	private int _selection = -1;

	private UndoManager _undo = null;
	private void delegate() _store = null;

	private string delegate() _saveName = null;

	this (Commons comm, const Summary summ, Composite parent, bool mask,
			string delegate() saveName, UndoManager undo, void delegate() store,
			bool readOnly) { mixin(S_TRACE);
		style = SWT.DOUBLE_BUFFERED | SWT.V_SCROLL;
		if (!readOnly) style |= SWT.BORDER;
		super (parent, style);
		_readOnly = readOnly ? SWT.READ_ONLY : SWT.NONE;
		_undo = undo;
		_store = store;
		_saveName = saveName;

		auto d = parent.getDisplay();
		setBackground(d.getSystemColor(SWT.COLOR_LIST_BACKGROUND));
		setForeground(d.getSystemColor(SWT.COLOR_LIST_FOREGROUND));

		_comm = comm;
		_summ = summ;
		_mask = mask;
		if (_readOnly || !_summ || _summ.scenarioPath == "") { mixin(S_TRACE);
			_summSkin = findSkin(_comm, _comm.prop, _summ);
		}

		if (!_readOnly) { mixin(S_TRACE);
			auto menu = new Menu(this.getShell(), SWT.POP_UP);
			createMenuItem(comm, menu, MenuID.AddLayer, &addLayer, &canAddLayer);
			createMenuItem(comm, menu, MenuID.RemoveLayer, &removeLayer, &canRemoveLayer);
			if (_undo) { mixin(S_TRACE);
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(comm, menu, MenuID.Undo, { _undo.undo(); }, &_undo.canUndo);
				createMenuItem(comm, menu, MenuID.Redo, { _undo.redo(); }, &_undo.canRedo);
			}
			new MenuItem(menu, SWT.SEPARATOR);
			appendMenuTCPD(comm, menu, this, false, true, true, false, false);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(comm, menu, MenuID.CopyAll, &copyAll, &canCopyAll);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(comm, menu, MenuID.Up, &upLayer, &canUpLayer);
			createMenuItem(comm, menu, MenuID.Down, &downLayer, &canDownLayer);
			setMenu(menu);
		}

		.listener(this, SWT.Paint, &onPaint);
		.listener(this, SWT.Traverse, (e) { mixin(S_TRACE);
			switch (e.detail) {
			case SWT.TRAVERSE_ARROW_NEXT, SWT.TRAVERSE_ARROW_PREVIOUS:
				e.doit = false;
				break;
			default:
				e.doit = true;
			}
		});
		.listener(this, SWT.KeyDown, (e) { mixin(S_TRACE);
			auto ctrl = (e.stateMask & SWT.CTRL) != 0;
			auto sel = selection;
			auto ca = getClientArea();
			auto vBar = getVerticalBar();
			switch (e.keyCode) {
			case SWT.PAGE_UP:
				selection = .max(0, selection - ca.height / itemHeight);
				showSelection();
				break;
			case SWT.PAGE_DOWN:
				selection = .min(cast(int)_items.length - 1, selection + ca.height / itemHeight);
				showSelection();
				break;
			case SWT.HOME:
				selection = 0;
				showSelection();
				break;
			case SWT.END:
				selection = cast(int)_items.length - 1;
				showSelection();
				break;
			case SWT.ARROW_UP:
				if (ctrl) return;
				selection = _selection == 0 ? (cast(int)_items.length - 1) : (_selection - 1);
				showSelection();
				break;
			case SWT.ARROW_DOWN:
				if (ctrl) return;
				selection = (_selection + 1) % cast(int)_items.length;
				showSelection();
				break;
			case SWT.ARROW_LEFT:
			case SWT.ARROW_RIGHT:
				if (ctrl) return;
				showSelection();
				break;
			default:
				e.doit = true;
				break;
			}
			if (sel != selection) { mixin(S_TRACE);
				foreach (dlg; selectionEvent) dlg();
			}
		});
		.listener(this, SWT.MouseDown, (e) { mixin(S_TRACE);
			setFocus();
		});
		.listener(this, SWT.MouseUp, (e) { mixin(S_TRACE);
			auto index = indexOf(e.x, e.y);
			if (index < 0) return;
			if (index != selection) { mixin(S_TRACE);
				selection = index;
				showSelection();
				foreach (dlg; selectionEvent) dlg();
			}
		});
		.listener(this, SWT.MouseMove, (e) { mixin(S_TRACE);
			auto index = indexOf(e.x, e.y);
			if (index < 0) { mixin(S_TRACE);
				setToolTipText("");
			} else { mixin(S_TRACE);
				auto item = _items[index];
				setToolTipText(item._toolTip);
			}
		});

		setupScrollBar();
		.listener(this, SWT.Resize, &setupScrollBar);
		auto vBar = getVerticalBar();
		.listener(vBar, SWT.Selection, &redraw);
		_comm.refImageScale.add(&refImageScale);
		.listener(this, SWT.Dispose, { mixin(S_TRACE);
			_comm.refImageScale.remove(&refImageScale);
			foreach (item; _items) item.dispose();
		});
	}

	private void refImageScale() { mixin(S_TRACE);
		foreach (item; _items) item.disposeImage();
		setupScrollBar();
		redraw();
	}

	@property
	private Skin summSkin() { mixin(S_TRACE);
		return _summSkin ? _summSkin : _comm.skin;
	}

	void setImages(CardImage[] cardPaths, int selection) { mixin(S_TRACE);
		setImages(cardPaths);
		this.selection = selection;
	}

	@property
	void images(CardImage[] cardPaths) { mixin(S_TRACE);
		setImages(cardPaths);
		foreach (dlg; updateEvent) dlg();
	}
	private void setImages(CardImage[] cardPaths) { mixin(S_TRACE);
		foreach (item; _items) item.dispose();
		_items = [];
		foreach (cardPath; cardPaths) { mixin(S_TRACE);
			_items ~= new ImageLayerItem(this, _comm, cardPath);
		}
		setupScrollBar();
		redraw();
	}
	@property
	CardImage[] images() { mixin(S_TRACE);
		return .map!(item => item.cardPath)(_items).array();
	}

	@property
	void selection(int index) { mixin(S_TRACE);
		_selection = index;
		_comm.refreshToolBar();
		redraw();
		foreach (dlg; updateEvent) dlg();
	}
	@property
	const
	int selection() { mixin(S_TRACE);
		return _selection;
	}

	void copyAll() { mixin(S_TRACE);
		auto node = CardImage.toNode(images);
		if (_summ) node.newAttr("scenarioPath", nabs(_summ.scenarioPath));
		XMLtoCB(_comm.prop, _comm.clipboard, node.text);
		_comm.refreshToolBar();
	}
	@property
	bool canCopyAll() { mixin(S_TRACE);
		auto defValue = new CardImage("", CardImagePosition.Default);
		foreach (item; _items) { mixin(S_TRACE);
			if (item.cardPath != defValue) return true;
		}
		return false;
	}

	override
	void cut(SelectionEvent se) { }
	override
	void copy(SelectionEvent se) { mixin(S_TRACE);
		auto node = CardImage.toNode(images[selection .. selection + 1]);
		if (_summ) node.newAttr("scenarioPath", nabs(_summ.scenarioPath));
		XMLtoCB(_comm.prop, _comm.clipboard, node.text);
		_comm.refreshToolBar();
	}
	override
	void paste(SelectionEvent se) { mixin(S_TRACE);
		auto c = CBtoXML(_comm.clipboard);
		if (c) { mixin(S_TRACE);
			try { mixin(S_TRACE);
				auto node = XNode.parse(c);
				auto paths = CardImage.createFromNode(node);
				if (!paths.length) return;
				auto defValue = new CardImage("", CardImagePosition.Default);
				auto a = images;
				CardImage[] before;
				CardImage[] after;
				assert (selection != -1);
				if (a[selection] == defValue) { mixin(S_TRACE);
					before = a[0 .. selection];
					after = a[selection + 1 .. $];
				} else { mixin(S_TRACE);
					before = a[0 .. selection];
					after = a[selection .. $];
				}
				paths = qMaterialCopy(node, paths);
				auto r = before ~ paths ~ after;
				if (r == a) return;
				_selection = cast(int)(before.length + paths.length - 1);
				setImages(r);
				showSelection();
				_comm.refreshToolBar();
				foreach (dlg; modEvent) dlg();
				foreach (dlg; selectionEvent) dlg();
			} catch (Exception e) { mixin(S_TRACE);
				printStackTrace();
				debugln(e);
			}
		}
	}
	override
	void del(SelectionEvent se) { }
	override
	void clone(SelectionEvent se) { }

	@property
	override
	bool canDoTCPD() { return true; }
	@property
	override
	bool canDoT() { return false; }
	@property
	override
	bool canDoC() { mixin(S_TRACE);
		auto defValue = new CardImage("", CardImagePosition.Default);
		return _items[selection].cardPath != defValue;
	}
	@property
	override
	bool canDoP() { mixin(S_TRACE);
		return !_readOnly && CBisXML(_comm.clipboard);
	}
	@property
	override
	bool canDoClone() { return false; }
	@property
	override
	bool canDoD() { return false; }

	private CardImage[] qMaterialCopy(in XNode node, CardImage[] cardPaths) { mixin(S_TRACE);
		if (!_summ) return cardPaths;
		auto fromSPath = node.attr("scenarioPath", false);
		if (fromSPath.length > 0 && !cfnmatch(nabs(fromSPath), nabs(_summ.scenarioPath))) { mixin(S_TRACE);
			auto uc = new UseCounter(null);
			foreach (path; cardPaths) { mixin(S_TRACE);
				path.setUseCounter(uc);
			}
			bool copy;
			bool r = .qMaterialCopy(_comm, getShell(),
				uc, _summ.scenarioPath, fromSPath, copy, _summ.legacy,
				(in PathUser) { mixin(S_TRACE);
					return _saveName();
				});
			foreach (path; cardPaths) { mixin(S_TRACE);
				path.removeUseCounter();
			}
			if (copy) { mixin(S_TRACE);
				_comm.refPaths.call(_comm.skin.materialPath);
			}
		}
		return cardPaths;
	}

	CardImage delegate() createDefaultItem = null;

	void addLayer() { mixin(S_TRACE);
		if (!canAddLayer) return;
		_selection = cast(int)_items.length;
		_items ~= new ImageLayerItem(this, _comm, createDefaultItem ? createDefaultItem() : new CardImage("", CardImagePosition.Default));
		setupScrollBar();
		showSelection();
		redraw();
		_comm.refreshToolBar();
		foreach (dlg; modEvent) dlg();
		foreach (dlg; selectionEvent) dlg();
	}
	@property
	const
	bool canAddLayer() { return !_readOnly; }

	void removeLayer() { mixin(S_TRACE);
		if (!canRemoveLayer) return;
		_items[selection].dispose();
		_items = _items[0 .. selection] ~ _items[selection + 1 .. $];
		_selection = .min(cast(int)_items.length - 1, selection);
		setupScrollBar();
		showSelection();
		redraw();
		_comm.refreshToolBar();
		foreach (dlg; modEvent) dlg();
		foreach (dlg; selectionEvent) dlg();
	}
	@property
	const
	bool canRemoveLayer() { return !_readOnly && 0 <= selection && 1 < _items.length; }

	void upLayer() { mixin(S_TRACE);
		if (!canUpLayer) return;
		auto temp = _items[selection];
		_items[selection] = _items[selection - 1];
		_items[selection - 1] = temp;
		selection = selection - 1;
		showSelection();
		foreach (dlg; modEvent) dlg();
		foreach (dlg; selectionEvent) dlg();
	}
	@property
	const
	bool canUpLayer() { return !_readOnly && 0 <= selection && 0 < selection; }

	void downLayer() { mixin(S_TRACE);
		if (!canDownLayer) return;
		auto temp = _items[selection];
		_items[selection] = _items[selection + 1];
		_items[selection + 1] = temp;
		selection = selection + 1;
		showSelection();
		foreach (dlg; modEvent) dlg();
		foreach (dlg; selectionEvent) dlg();
	}
	@property
	const
	bool canDownLayer() { return !_readOnly && 0 <= selection && selection + 1 < _items.length; }

	int indexOf(int x, int y) { mixin(S_TRACE);
		auto vBar = getVerticalBar();
		y += vBar.getSelection();
		auto index = y / itemHeight;
		if (index < 0 || _items.length <= index) return -1;
		return index;
	}
	void showSelection() { mixin(S_TRACE);
		if (selection < 0) return;
		auto ca = getClientArea();
		auto vBar = getVerticalBar();

		if ((vBar.getSelection() + vBar.getThumb()) < (selection * itemHeight + itemHeight)) { mixin(S_TRACE);
			vBar.setSelection(selection * itemHeight + itemHeight - vBar.getThumb());
		}
		if (selection * itemHeight - vBar.getSelection() < 0) { mixin(S_TRACE);
			vBar.setSelection(selection * itemHeight);
		}
	}

	private void setupScrollBar() { mixin(S_TRACE);
		auto ca = getClientArea();
		auto vBar = getVerticalBar();
		auto cRect = _comm.prop.looks.cardSize;
		cRect.width = _comm.prop.s(cRect.width);
		cRect.height = _comm.prop.s(cRect.height);
		vBar.setIncrement(cRect.height / 2);
		auto height = itemHeight * cast(int)_items.length;
		vBar.setMaximum(height);
		vBar.setThumb(height < ca.height ? height : ca.height);
		vBar.setPageIncrement(ca.height / 2);
	}
	@property
	private int itemHeight() { mixin(S_TRACE);
		return _comm.prop.s(_comm.prop.looks.cardSize.height) + 2.ppis;
	}

	private void onPaint(Event e) { mixin(S_TRACE);
		if (!_items.length) return;
		auto ca = getClientArea();
		auto vBar = getVerticalBar();
		auto vy = vBar.getSelection();
		int y = -vy % itemHeight;
		auto start = .min(vy / itemHeight, _items.length);
		foreach (i, item; _items[start .. $]) { mixin(S_TRACE);
			item.draw(e.gc, y, i + start == _selection);
			y += itemHeight;
			if (ca.y + ca.height <= y) break;
		}
	}
}

private class ImageLayerItem : Item {
	private ImageLayerList _parent = null;

	private Commons _comm = null;
	private CardImage _cardPath = null;
	private string _toolTip = "";
	private bool _warning = false;

	this (ImageLayerList parent, Commons comm, CardImage cardPath) { mixin(S_TRACE);
		super (parent, SWT.NONE);
		_parent = parent;
		_comm = comm;
		_cardPath = cardPath;
		.listener(this, SWT.Dispose, &disposeImage);
	}

	private void disposeImage() { mixin(S_TRACE);
		auto image = getImage();
		if (image) { mixin(S_TRACE);
			image.dispose();
			setImage(null);
		}
	}

	private void draw(GC gc, int y, bool selected) { mixin(S_TRACE);
		auto d = _parent.getDisplay();
		auto ca = _parent.getClientArea();
		if (selected) { mixin(S_TRACE);
			gc.setBackground(d.getSystemColor(SWT.COLOR_LIST_SELECTION));
			gc.setForeground(d.getSystemColor(SWT.COLOR_LIST_SELECTION_TEXT));
			gc.fillRectangle(0, y, ca.width, _parent.itemHeight);
		} else { mixin(S_TRACE);
			gc.setBackground(d.getSystemColor(SWT.COLOR_LIST_BACKGROUND));
			gc.setForeground(d.getSystemColor(SWT.COLOR_LIST_FOREGROUND));
		}
		auto cRect = _parent._comm.prop.looks.cardSize;
		cRect.width = _comm.prop.s(cRect.width);
		cRect.height = _comm.prop.s(cRect.height);

		if (getImage()) { mixin(S_TRACE);
			drawImage(gc, y);
			return;
		}
		auto path = _cardPath;
		auto skin = _parent.summSkin;
		string name = _parent._comm.prop.msgs.noSelectImage;
		_warning = false;
		final switch (path.type) {
		case CardImageType.File:
			if (path.path != "") { mixin(S_TRACE);
				auto isSkinMaterial = false;
				auto isEngineMaterial = false;
				auto file = skin.findImagePathF(path.path, _parent._summ ? _parent._summ.scenarioPath : "", _parent._summ ? _parent._summ.dataVersion : LATEST_VERSION, isSkinMaterial, isEngineMaterial);
				if (file != "" && file.exists()) { mixin(S_TRACE);
					auto drawingScale = (isSkinMaterial || isEngineMaterial) ? _parent._comm.prop.drawingScale : _parent._comm.prop.drawingScaleForImage(_parent._summ);
					auto dataWS = .loadImageWithScale(_parent._comm.prop, skin, _parent._summ, file, drawingScale, _parent._mask, false);
					auto data = dataWS.scaled(_parent._comm.prop.var.etc.imageScale);
					if (cRect.width < data.width || cRect.height < data.height) {
						auto scale = .min(cast(real)cRect.width / data.width, cast(real)cRect.height / data.height);
						data = data.scaledTo(cast(int)(scale * data.width), cast(int)(scale * data.height));
					}
					image = new Image(d, data);
					name = .encodePath(path.path);
				} else { mixin(S_TRACE);
					image = new Image(d, blankImage);
					name = .tryFormat(_parent._comm.prop.msgs.noImage, .encodePath(path.path));
					_warning = true;
				}
			}
			setImage(image);
			break;
		case CardImageType.PCNumber:
			auto pcNum = path.pcNumber;
			if (0 != pcNum) { mixin(S_TRACE);
				name = .tryFormat(_parent._comm.prop.msgs.pcNumber, path.pcNumber);
				auto rect = new Rectangle(0, y, cRect.width, cRect.height);
				drawCenterText(dwtData(_parent._comm.prop.adjustFont(_parent._comm.prop.looks.pcNumberFont(skin.legacy))), gc, rect, .text(pcNum));
			}
			break;
		case CardImageType.Talker:
			final switch (path.talker) {
			case Talker.Selected:
			case Talker.Unselected:
			case Talker.Random:
			case Talker.Valued:
				auto imgData = _parent._comm.prop.images.talker(path.talker).getImageData();
				auto dataWS = new ImageDataWithScale(imgData, .dpiMuls);
				setImage(new Image(d, dataWS.scaled(_parent._comm.prop.var.etc.imageScale)));
				break;
			case Talker.Card:
				auto scale = _parent._comm.prop.var.etc.imageScale;
				auto imgData = .menuCard(skin, _parent._comm.prop.drawingScale);
				auto data = imgData.scaled(_parent._comm.prop.drawingScale).scaledTo(_parent._comm.prop.s(cRect.width), _parent._comm.prop.s(cRect.height));
				setImage(new Image(d, data));
				break;
			}
			name = _parent._comm.prop.msgs.talkerName(path.talker);
			break;
		}
		setText(name);
		drawImage(gc, y);
	}
	private void drawImage(GC gc, int y) { mixin(S_TRACE);
		auto ca = _parent.getClientArea();
		auto cRect = _parent._comm.prop.looks.cardSize;
		cRect.width = _comm.prop.s(cRect.width);
		cRect.height = _comm.prop.s(cRect.height);
		auto image = getImage();
		auto textX = cRect.width + 1.ppis + 5.ppis;
		if (image) { mixin(S_TRACE);
			auto b = image.getBounds();
			auto b2 = image.getBounds();
			b.width = _comm.prop.s(b.width);
			b.height = _comm.prop.s(b.height);
			if (cRect.width < b.width || cRect.height < b.height) { mixin(S_TRACE);
				auto sc = .min(cast(real)cRect.width / b.width, cast(real)cRect.height / b.height);
				b.width = cast(int)(b.width * sc);
				b.height = cast(int)(b.height * sc);
			}
			b.x = (cRect.width - b.width) / 2 + 1.ppis;
			b.y = y + (cRect.height - b.height) / 2 + 1.ppis;
			gc.drawImage(image, 0, 0, b2.width, b2.height,
				b.x, b.y, b.width, b.height);
		}
		if (_warning) { mixin(S_TRACE);
			textX = 5.ppis;
			auto img = _comm.prop.images.warning;
			auto b = img.getBounds();
			gc.drawImage(img, textX, y + _parent.itemHeight / 2 - b.height / 2);
			textX += b.width + 5.ppis;
		}
		_toolTip = "";
		auto name = getText();
		auto posType = _comm.prop.msgs.cardImagePositionName(_cardPath.positionType);
		auto te = gc.wTextExtent(posType);
		auto ih = _parent.itemHeight;
		auto textY = y + ih / 2 - te.y - 3.ppis;
		if (name != "") { mixin(S_TRACE);
			auto name2 = cutText(name, gc, ca.width - textX - 1);
			if (name2 != name) { mixin(S_TRACE);
				_toolTip = name;
			}
			gc.wDrawText(name2, textX, textY);
		}

		gc.wDrawText(posType, textX, textY + te.y + 3.ppis);
	}

	CardImage cardPath() { mixin(S_TRACE);
		return _cardPath;
	}
}

class ImageLayerPanel : Composite {
	private Commons _comm;
	private bool _readOnly;

	private Combo _positionType;
	private CardImagePosition[] _posTypes;
	private int[CardImagePosition] _posTypeTable;
	private ImageLayerList _list = null;

	this (Commons comm, Composite parent, bool readOnly) { mixin(S_TRACE);
		super (parent, SWT.NONE);

		_comm = comm;
		_readOnly = readOnly;
		setLayout(zeroMarginGridLayout(2, false));

		auto l = new Label(this, SWT.NONE);
		l.setText(_comm.prop.msgs.cardImagePosition);
		_positionType = new Combo(this, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
		_positionType.setVisibleItemCount(_comm.prop.var.etc.comboVisibleItemCount);
		foreach (i, posType; EnumMembers!CardImagePosition) { mixin(S_TRACE);
			_posTypes ~= posType;
			_posTypeTable[posType] = _positionType.getItemCount();
			_positionType.add(comm.prop.msgs.cardImagePositionName(posType));
		}
	}

	void list(ImageLayerList list) {
		_list = list;
		.listener(_positionType, SWT.Selection, { mixin(S_TRACE);
			auto itm = 0 <= _list.selection ? _list._items[_list.selection] : null;
			itm._cardPath = new CardImage(itm._cardPath.path, _posTypes[_positionType.getSelectionIndex()]);
			foreach (dlg; _list.modEvent) dlg();
			_list.redraw();
		});
		selected();
		_list.selectionEvent ~= &selected;
		_list.updateEvent ~= &selected;
	}

	private void selected() { mixin(S_TRACE);
		auto cardPath = 0 <= _list.selection ? _list._items[_list.selection]._cardPath : null;
		if (cardPath && cardPath.type is CardImageType.File) { mixin(S_TRACE);
			_positionType.select(_posTypeTable[cardPath.positionType]);
			_positionType.setEnabled(!_readOnly);
		} else { mixin(S_TRACE);
			_positionType.select(0);
			_positionType.setEnabled(false);
		}
	}
}
