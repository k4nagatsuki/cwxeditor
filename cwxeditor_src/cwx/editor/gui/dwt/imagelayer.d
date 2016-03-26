
module cwx.editor.gui.dwt.imagelayer;

import cwx.card;
import cwx.skin;
import cwx.summary;
import cwx.types;
import cwx.utils;

import cwx.editor.gui.dwt.cardlist;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;

import std.algorithm;
import std.array;
import std.conv;
import std.file;

import org.eclipse.swt.all;

/// CardImageのリストを管理する。
class ImageLayerWindow {
	private Shell _win = null;
	private ImageLayerList _list = null;

	this (Commons comm, const Summary summ, bool mask, bool readOnly, Control parent) { mixin(S_TRACE);
		_win = new Shell(parent.getShell(), SWT.TITLE | SWT.RESIZE | SWT.CLOSE | SWT.TOOL);
		if (readOnly) { mixin(S_TRACE);
			_win.setText(comm.prop.msgs.dlgTitImageLayerWindowReadOnly);
		} else { mixin(S_TRACE);
			_win.setText(comm.prop.msgs.dlgTitImageLayerWindow);
		}

		_win.setLayout(zeroGridLayout(1, true));
		ToolBar bar = null;
		if (!readOnly) { mixin(S_TRACE);
			bar = new ToolBar(_win, SWT.FLAT);
			bar.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			comm.put(bar);
		}

		_list = new ImageLayerList(comm, summ, _win, mask, readOnly);
		_list.setLayoutData(new GridData(GridData.FILL_BOTH));

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
		d.addFilter(SWT.FocusOut, focusFilter);
		d.addFilter(SWT.Selection, focusFilter);
		.listener(_win, SWT.Dispose, { mixin(S_TRACE);
			d.removeFilter(SWT.FocusOut, focusFilter);
			d.removeFilter(SWT.Selection, focusFilter);
		});
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
class ImageLayerList : Composite {
	void delegate()[] selectionEvent;
	void delegate()[] modEvent;

	private int _readOnly = 0;

	private Commons _comm = null;
	private const(Summary) _summ = null;
	private Skin _summSkin = null;
	private bool _mask = false;

	private ImageLayerItem[] _items = [];
	private int _selection = -1;

	this (Commons comm, const Summary summ, Composite parent, bool mask, bool readOnly) { mixin(S_TRACE);
		style = SWT.DOUBLE_BUFFERED | SWT.V_SCROLL;
		if (!readOnly) style |= SWT.BORDER;
		super (parent, style);
		_readOnly = readOnly ? SWT.READ_ONLY : SWT.NONE;

		auto d = parent.getDisplay();
		setBackground(d.getSystemColor(SWT.COLOR_LIST_BACKGROUND));
		setForeground(d.getSystemColor(SWT.COLOR_LIST_FOREGROUND));

		_comm = comm;
		_summ = summ;
		_mask = mask;
		if (_readOnly) _summSkin = findSkin(_comm, _comm.prop, _summ);

		if (!_readOnly) { mixin(S_TRACE);
			auto menu = new Menu(this.getShell(), SWT.POP_UP);
			createMenuItem(comm, menu, MenuID.AddLayer, &addLayer, &canAddLayer);
			createMenuItem(comm, menu, MenuID.RemoveLayer, &removeLayer, &canRemoveLayer);
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

		auto vBar = getVerticalBar();
		auto cRect = _comm.prop.looks.cardSize;
		vBar.setIncrement(cRect.height / 2);
		setupScrollBar();
		.listener(this, SWT.Resize, &setupScrollBar);
		.listener(vBar, SWT.Selection, &redraw);
		.listener(this, SWT.Dispose, { mixin(S_TRACE);
			foreach (item; _items) item.dispose();
		});
	}

	@property
	private Skin summSkin() { mixin(S_TRACE);
		return _summSkin ? _summSkin : _comm.skin;
	}

	@property
	void images(CardImage[] cardPaths) { mixin(S_TRACE);
		foreach (item; _items) item.dispose();
		_items = [];
		foreach (cardPath; cardPaths) { mixin(S_TRACE);
			_items ~= new ImageLayerItem(this, cardPath);
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
	}
	@property
	const
	int selection() { mixin(S_TRACE);
		return _selection;
	}

	void addLayer() { mixin(S_TRACE);
		if (!canAddLayer) return;
		_items = _items[0 .. selection] ~ new ImageLayerItem(this, new CardImage("")) ~ _items[selection .. $];
		setupScrollBar();
		showSelection();
		redraw();
		_comm.refreshToolBar();
		foreach (dlg; modEvent) dlg();
	}
	@property
	const
	bool canAddLayer() { return !_readOnly && 0 <= selection; }

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
		auto height = itemHeight * cast(int)_items.length;
		vBar.setMaximum(height);
		vBar.setThumb(height < ca.height ? height : ca.height);
		vBar.setPageIncrement(ca.height / 2);
	}
	@property
	private int itemHeight() { mixin(S_TRACE);
		return _comm.prop.looks.cardSize.height + 2;
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
	private CardImage _cardPath = null;
	private string _toolTip = "";
	private bool _commonImage = false;
	private bool _warning = false;

	this (ImageLayerList parent, CardImage cardPath) { mixin(S_TRACE);
		super (parent, SWT.NONE);
		_parent = parent;
		_cardPath = cardPath;
		.listener(this, SWT.Dispose, &disposeImage);
	}

	private void disposeImage() { mixin(S_TRACE);
		if (_commonImage) return;
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

		if (getImage()) { mixin(S_TRACE);
			drawImage(gc, y);
			return;
		}
		auto path = _cardPath;
		auto skin = _parent.summSkin;
		string name = _parent._comm.prop.msgs.noSelectImage;
		_commonImage = false;
		_warning = false;
		final switch (path.type) {
		case CardImageType.File:
			if (path.path != "") { mixin(S_TRACE);
				auto file = skin.findImagePath(path.path, _parent._summ ? _parent._summ.scenarioPath : "");
				if (file != "" && file.exists()) { mixin(S_TRACE);
					auto data = loadImage(_parent._comm.prop, skin, _parent._summ, file, _parent._mask);
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
				drawCenterText(dwtData(_parent._comm.prop.looks.pcNumberFont(skin.legacy)), gc, rect, .text(pcNum));
			}
			break;
		case CardImageType.Talker:
			final switch (path.talker) {
			case Talker.SELECTED:
			case Talker.UNSELECTED:
			case Talker.RANDOM:
			case Talker.VALUED:
				setImage(_parent._comm.prop.images.talker(path.talker));
				_commonImage = true;
				break;
			case Talker.CARD:
				setImage(new Image(d, menuCard(skin).scaledTo(cRect.width, cRect.height)));
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
		auto image = getImage();
		auto textX = cRect.width + 1 + 5;
		if (image) { mixin(S_TRACE);
			auto b = image.getBounds();
			gc.drawImage(image, (cRect.width - b.width) / 2 + 1, y + (cRect.height - b.height) / 2 + 1);
		}
		if (_warning) { mixin(S_TRACE);
			textX = 5;
			auto img = _parent._comm.prop.images.warning;
			auto b = img.getBounds();
			gc.drawImage(img, textX, y + _parent.itemHeight / 2 - b.height / 2);
			textX += b.width + 5;
		}
		_toolTip = "";
		auto name = getText();
		if (name != "") { mixin(S_TRACE);
			auto te = gc.wTextExtent(name);
			auto name2 = cutText(name, gc, ca.width - textX - 1);
			if (name2 != name) { mixin(S_TRACE);
				_toolTip = name;
			}
			gc.wDrawText(name2, textX, y + _parent.itemHeight / 2 - te.y / 2);
		}
	}

	CardImage cardPath() { mixin(S_TRACE);
		return _cardPath;
	}
}
