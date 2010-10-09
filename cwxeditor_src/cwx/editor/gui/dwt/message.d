
module cwx.editor.gui.dwt.message;

import cwx.utils;
import cwx.types;
import cwx.event;
import cwx.summary;
import cwx.skin;

import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.skin;
import cwx.editor.gui.dwt.utils;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.materialselect;
import cwx.editor.gui.dwt.absdialog;

import std.utf;
import std.string;

import dwt.DWT;
import dwt.widgets.Button;
import dwt.widgets.Canvas;
import dwt.widgets.Composite;
import dwt.widgets.Combo;
import dwt.widgets.Control;
import dwt.widgets.Display;
import dwt.widgets.Shell;
import dwt.widgets.Text;
import dwt.widgets.ToolBar;
import dwt.widgets.ToolItem;
import dwt.widgets.Listener;
import dwt.widgets.List;
import dwt.widgets.Table;
import dwt.widgets.TableColumn;
import dwt.widgets.TableItem;
import dwt.custom.CTabFolder;
import dwt.custom.CTabItem;
import dwt.graphics.Image;
import dwt.graphics.ImageData;
import dwt.graphics.PaletteData;
import dwt.graphics.RGB;
import dwt.layout.GridLayout;
import dwt.layout.GridData;
import dwt.events.PaintListener;
import dwt.events.PaintEvent;
import dwt.events.DisposeListener;
import dwt.events.DisposeEvent;
import dwt.events.SelectionAdapter;
import dwt.events.SelectionEvent;
import dwt.events.ShellAdapter;
import dwt.events.ShellEvent;
import dwt.events.ModifyListener;
import dwt.events.ModifyEvent;

class SpeakDialog : AbsDialog {
private:
	Props _prop;
	Summary _summ;
	Content _evt;
	Combo _talkers;
	SDialog[] _dlgs;
	Table _dlgsL;
	Text _rCoupons;
	FixedWidthText _text;

	void selectChanged() {
		auto dlg = _dlgs[_dlgsL.getSelectionIndex];
		string rcs;
		foreach (rc; dlg.rCoupons) {
			rcs ~= rc;
			rcs ~= '\n';
		}
		_rCoupons.setText = rcs;
		_text.setText = dlg.text;
	}
	void createDialog() {
		int index = _dlgsL.getSelectionIndex;
		_dlgs = _dlgs[0 .. index] ~ new SDialog ~ _dlgs[index .. $];
		auto itm = new TableItem(_dlgsL, DWT.NONE);
		itm.setImage = _prop.images.content(CType.TALK_DIALOG);
		_dlgsL.setSelection = [itm];
		_dlgsL.showSelection;
		selectChange;
	}
	void deleteDialog() {
		if (_dlgs.length > 1) {
			int index = _dlgsL.getSelectionIndex;
			_dlgs = _dlgs[0 .. index] ~ _dlgs[index + 1 .. $];
			_dlgsL.remove(index);
			_dlgsL.select = index < _dlgs.length ? index : _dlgs.length - 1;
			selectChanged;
		}
	}
	void up() {
		int index = _dlgsL.getSelectionIndex;
		if (index > 0) {
			auto temp = _dlgs[index - 1];
			_dlgs[index - 1] = _dlgs[index];
			_dlgs[index] = temp;
			auto tempL = _dlgsL.getItem(index - 1).getText;
			_dlgsL.getItem(index - 1).setText(_dlgsL.getItem(index).getText);
			_dlgsL.getItem(index).setText(tempL);
			_dlgsL.select = index - 1;
		}
	}
	void down() {
		int index = _dlgsL.getSelectionIndex;
		if (index + 1 < _dlgs.length) {
			auto temp = _dlgs[index + 1];
			_dlgs[index + 1] = _dlgs[index];
			_dlgs[index] = temp;
			auto tempL = _dlgsL.getItem(index + 1).getText;
			_dlgsL.getItem(index + 1).setText(_dlgsL.getItem(index).getText);
			_dlgsL.getItem(index).setText(tempL);
			_dlgsL.select = index + 1;
		}
	}
	void copyToUpper() {
		int index = _dlgsL.getSelectionIndex;
		string textL = _dlgsL.getItem(index).getText;
		string text = lastRet(wrapReturnCode(_text.getText));
		for (int i = 0; i < index; i++) {
			_dlgsL.getItem(i).setText(textL);
			_dlgs[i].text = text;
		}
	}
	void copyToLower() {
		int index = _dlgsL.getSelectionIndex;
		string textL = _dlgsL.getItem(index).getText;
		string text = lastRet(wrapReturnCode(_text.getText));
		for (int i = index + 1; i < _dlgs.length; i++) {
			_dlgsL.getItem(i).setText(textL);
			_dlgs[i].text = text;
		}
	}
	void copyToDialogs() {
		int index = _dlgsL.getSelectionIndex;
		string textL = _dlgsL.getItem(index).getText;
		string text = lastRet(wrapReturnCode(_text.getText));
		foreach (i, dlg; _dlgs) {
			if (i != index) {
				_dlgsL.getItem(i).setText(textL);
				dlg.text = text;
			}
		}
	}
	void put(dchar put) {
		putColor(_text, put);
	}
	void insert(string put) {
		_text.insert(put);
	}
	SDialog _oldSel;
	void sets() {
		_oldSel.text = lastRet(wrapReturnCode(_text.getText));
		string[] rcs;
		foreach (rc; splitlines(_rCoupons.getText)) {
			if (rc.length > 0) {
				rcs ~= rc;
			}
		}
		_oldSel.rCoupons = rcs;
		_oldSel = _dlgs[_dlgsL.getSelectionIndex];
	}
	void selectChange() {
		sets;
		selectChanged;
	}
	class SelL : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			selectChange;
		}
	}
	class ModL : ModifyListener {
		override void modifyText(ModifyEvent e) {
			string text = std.string.replace(wrapReturnCode(_text.getText), "\n", "").dup;
			// FIXME: ""をsetTextするとArgument cannot be null
			_dlgsL.getItem(_dlgsL.getSelectionIndex).setText(0, text != "" ? text : " ");
		}
	}
public:
	this(Props prop, Shell shell, Summary summ, Content evt) {
		_prop = prop;
		_summ = summ;
		_evt = evt;
		super(prop, shell, prop.msgs.dlgTitSpeak, prop.images.content(CType.TALK_DIALOG), true, prop.var.speakDlg);
	}

	Content event() {
		return _evt;
	}
protected:
	override void setup(Composite area) {
		area.setLayout = windowGridLayout(1, true);
		{
			auto comp = new Composite(area, DWT.NONE);
			comp.setLayoutData = new GridData(GridData.FILL_BOTH);
			comp.setLayout = new GridLayout(2, false);
			_dlgsL = new Table(comp, DWT.SINGLE | DWT.FULL_SELECTION | DWT.BORDER | DWT.V_SCROLL);
			new FullTableColumn(_dlgsL, DWT.NONE);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.widthHint = 0;
			gd.heightHint = 0;
			_dlgsL.setLayoutData = gd;
			_dlgsL.addSelectionListener(new SelL);
			auto bar = new ToolBar(comp, DWT.FLAT | DWT.VERTICAL);
			bar.setLayoutData = new GridData(GridData.FILL_VERTICAL);
			bar.addListener(DWT.Traverse, new class Listener {
				override void handleEvent(dwt.widgets.Event.Event e) {e.doit = true;}
			});
			bar.addListener(DWT.KeyDown, new class Listener {
				override void handleEvent(dwt.widgets.Event.Event e) {e.doit = true;}
			});
			createToolItem(bar, _prop.msgs.createDialog, _prop.images.createDialog, &createDialog);
			createToolItem(bar, _prop.msgs.deleteDialog, _prop.images.deleteDialog, &deleteDialog);
			new ToolItem(bar, DWT.SEPARATOR);
			createToolItem(bar, _prop.msgs.ttUp, _prop.images.menuUp, &up);
			createToolItem(bar, _prop.msgs.ttDown, _prop.images.menuDown, &down);
			new ToolItem(bar, DWT.SEPARATOR);
			createToolItem(bar, _prop.msgs.copyToDialogs, _prop.images.copyToDialogs, &copyToDialogs);
			createToolItem(bar, _prop.msgs.copyToUpper, _prop.images.copyToUpper, &copyToUpper);
			createToolItem(bar, _prop.msgs.copyToLower, _prop.images.copyToLower, &copyToLower);
		}
		{
			auto comp = new Composite(area, DWT.NONE);
			comp.setLayoutData = new GridData(GridData.FILL_BOTH);
			comp.setLayout = new GridLayout(2, false);
			Control tp;
			if (_evt) {
				tp = createTalkerPane2(comp, _prop, _summ, _evt.talkerNC, _evt.dialogs[0].rCoupons, _talkers, _rCoupons);
			} else {
				tp = createTalkerPane2(comp, _prop, _summ, Talker.SELECTED, [], _talkers, _rCoupons);
			}
			tp.setLayoutData = new GridData(GridData.FILL_BOTH);
			_text = createMessagePane(_prop, true, comp);
			auto gd = new GridData;
			auto s = _text.computeTextBaseSize(_prop.looks.messageLine);
			gd.widthHint = s.x;
			gd.heightHint = s.y;
			_text.widget.setLayoutData = gd;
			_text.widget.addModifyListener(new ModL);
		}
		auto skin = findSkin(_prop, _summ);
		{
			auto bar = createSCharBar(area, &insert, &put, _prop, skin);
			bar.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
		}
		{
			auto bar = createSkinSCharBar(area, &insert, _prop, skin);
			bar.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
		}
		if (_evt) {
			foreach (dlg; _evt.dialogs) {
				auto itm = new TableItem(_dlgsL, DWT.NONE);
				itm.setImage = _prop.images.content(CType.TALK_DIALOG);
				string text = std.string.replace(dlg.text, "\n", "");
				// FIXME: ""をsetTextするとArgument cannot be null
				itm.setText = text.length > 0 ? text : " ";
				_dlgs ~= new SDialog(dlg.text, dlg.rCoupons);
			}
			_oldSel = _dlgs[0];
			_dlgsL.select = 0;
			selectChanged;
		} else {
			auto itm = new TableItem(_dlgsL, DWT.NONE);
			itm.setImage = _prop.images.content(CType.TALK_DIALOG);
			_dlgs = [new SDialog];
			_oldSel = _dlgs[0];
			_dlgsL.select = 0;
		}
	}
	override bool close(bool ok) {
		if (ok) {
			sets;
			Talker talker;
			switch (_talkers.getSelectionIndex) {
			case 0:
				talker = Talker.SELECTED;
				break;
			case 1:
				talker = Talker.UNSELECTED;
				break;
			case 2:
				talker = Talker.RANDOM;
				break;
			}
			if (!_evt) _evt = new Content(CType.TALK_DIALOG, "");
			_evt.dialogs = _dlgs;
			_evt.talkerNC = talker;
		}
		return ok;
	}
}

class MessageDialog : AbsDialog {
private:
	Commons _comm;
	Props _prop;
	Summary _summ;
	Content _evt;
	CTabFolder _tabf;
	FixedWidthText _textA, _textB;
	MaterialSelect!(MtType.CARD, Combo, Combo) _msel;

	class SL : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			switch (_tabf.getSelectionIndex) {
			case 0:
				_textA.setText = _textB.getText;
				break;
			case 1:
				_textB.setText = _textA.getText;
				break;
			}
		}
	}
	void put(dchar put) {
		switch (_tabf.getSelectionIndex) {
		case 0:
			putColor(_textA, put);
			break;
		case 1:
			putColor(_textB, put);
			break;
		default: assert (0);
		}
	}
	void insert(string put) {
		switch (_tabf.getSelectionIndex) {
		case 0:
			_textA.insert(put);
			break;
		case 1:
			_textB.insert(put);
			break;
		}
	}
public:
	this(Commons comm, Props prop, Summary summ, Shell shell, Content evt) {
		_comm = comm;
		_prop = prop;
		_summ = summ;
		_evt = evt;
		super(prop, shell, prop.msgs.dlgTitMessage, prop.images.content(CType.TALK_MESSAGE), true, prop.var.msgDlg);
	}

	Content event() {
		return _evt;
	}
protected:
	override void setup(Composite area) {
		area.setLayout = windowGridLayout(1, true);
		_tabf = new CTabFolder(area, DWT.BORDER);
		_tabf.setLayoutData = new GridData(GridData.FILL_BOTH);
		{
			auto comp = new Composite(_tabf, DWT.NONE);
			comp.setLayout = new GridLayout(2, false);
			Control tp;
			if (_evt) {
				tp = createTalkerPane(comp, _comm, _prop, _summ, _evt.talkerC, _evt.cardPath, _msel);
			} else {
				tp = createTalkerPane(comp, _comm, _prop, _summ, Talker.SELECTED, "", _msel);
			}
			tp.setLayoutData = new GridData(GridData.FILL_BOTH);
			_textA = createMessagePane(_prop, true, comp);
			auto gd = new GridData;
			auto s = _textA.computeTextBaseSize(_prop.looks.messageLine);
			gd.widthHint = s.x;
			gd.heightHint = s.y;
			_textA.widget.setLayoutData = gd;
			auto tab = new CTabItem(_tabf, DWT.NONE);
			tab.setText = _prop.msgs.imageMessage;
			tab.setControl = comp;
		}
		{
			auto comp = new Composite(_tabf, DWT.NONE);
			comp.setLayout = new CenterLayout;
			_textB = createMessagePane(_prop, false, comp);
			_textB.widget.setLayoutData = _textB.computeTextBaseSize(_prop.looks.messageLine);
			auto tab = new CTabItem(_tabf, DWT.NONE);
			tab.setText = _prop.msgs.noImageMessage;
			tab.setControl = comp;
		}
		auto skin = findSkin(_prop, _summ);
		{
			auto bar = createSCharBar(area, &insert, &put, _prop, skin);
			bar.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
		}
		{
			auto bar = createSkinSCharBar(area, &insert, _prop, skin);
			bar.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
		}
		_tabf.addSelectionListener(new SL);
		if (_evt) {
			_textA.setText = _evt.text;
			_textB.setText = _evt.text;
			if (_evt.talkerC == Talker.NARRATION) {
				_tabf.setSelection = 1;
			}
		} else {
			_tabf.setSelection = 1;
		}
	}
	override bool close(bool ok) {
		if (ok) {
			string text;
			string path = "";
			Talker talker;
			switch (_tabf.getSelectionIndex) {
			case 0:
				text = lastRet(wrapReturnCode(_textA.getText));
				switch (_msel.dirsCombo.getSelectionIndex) {
				case 0:
					talker = Talker.SELECTED;
					break;
				case 1:
					talker = Talker.UNSELECTED;
					break;
				case 2:
					talker = Talker.RANDOM;
					break;
				case 3:
					talker = Talker.CARD;
					break;
				default:
					talker = Talker.IMAGE;
					path = _msel.path;
				}
				break;
			case 1:
				text = lastRet(wrapReturnCode(_textB.getText));
				talker = Talker.NARRATION;
				break;
			}
			if (!_evt) _evt = new Content(CType.TALK_MESSAGE, "");
			_evt.text = text;
			_evt.talkerC = talker;
			_evt.cardPath = path;
		}
		return ok;
	}
}

private Composite createTalkerPane2(Composite parent, Props prop, Summary summ, Talker talker,
		string[] coupons, out Combo talkerCombo, out Text couponList) {
	auto comp = new Composite(parent, DWT.NONE);
	comp.setLayout = new GridLayout(2, false);
	{
		talkerCombo = new Combo(comp, DWT.READ_ONLY | DWT.DROP_DOWN | DWT.BORDER);
		auto gd = new GridData(GridData.FILL_HORIZONTAL);
		gd.horizontalSpan = 2;
		talkerCombo.setLayoutData = gd;
		talkerCombo.add(prop.msgs.talker(Talker.SELECTED));
		talkerCombo.add(prop.msgs.talker(Talker.UNSELECTED));
		talkerCombo.add(prop.msgs.talker(Talker.RANDOM));
		switch (talker) {
		case Talker.SELECTED:
			talkerCombo.select = 0;
			break;
		case Talker.UNSELECTED:
			talkerCombo.select = 1;
			break;
		case Talker.RANDOM:
			talkerCombo.select = 2;
			break;
		default:
			talkerCombo.select = 0;
		}
	}
	auto couponCombo = new Combo(comp, DWT.DROP_DOWN | DWT.BORDER);
	couponCombo.setVisibleItemCount = 20;
	auto push = new Button(comp, DWT.PUSH);
	auto skin = findSkin(prop, summ);
	{
		auto gd = new GridData(GridData.FILL_HORIZONTAL);
		gd.widthHint = prop.var.etc.talkersWidth;
		couponCombo.setLayoutData = gd;
		addCastCoupons(couponCombo, prop, true, skin.legacyName);
		couponCombo.select = 0;
		push.setToolTipText = prop.msgs.setTalkerCoupon;
		push.setImage = prop.images.setTalkerCoupon;
	}
	{
		couponList = new Text(comp, DWT.BORDER | DWT.MULTI | DWT.V_SCROLL);
		auto gd = new GridData(GridData.FILL_BOTH);
		gd.horizontalSpan = 2;
		couponList.setLayoutData = gd;
		string buf;
		foreach (coupon; coupons) {
			buf ~= coupon ~ "\n";
		}
		couponList.setText = buf;
		push.addSelectionListener(new class SelectionAdapter {
			private Combo _combo;
			private Text _list;
			this() {
				_combo = couponCombo;
				_list = couponList;
			}
			override void widgetSelected(SelectionEvent e) {
				if (_combo.getText.length > 0) {
					_list.setSelection(_list.getText.length, _list.getText.length);
					string[] lines = splitlines(_list.getText);
					if (lines.length > 0 && lines[$ - 1].length > 0) {
						_list.insert("\n");
					}
					_list.insert(_combo.getText ~ "\n");
				}
			}
		});
	}
	return comp;
}

private Composite createTalkerPane
		(Composite parent, Commons comm, Props prop, Summary summ, Talker talker, string path,
		out MaterialSelect!(MtType.CARD, Combo, Combo) msel) {
	static class Img {
		private Canvas _canvas;
		private Props _prop;
		private Summary _summ;
		this(Props prop, Summary summ) {
			_prop = prop;
			_summ = summ;
		}
		void redraw() {
			_canvas.redraw;
		}
		Canvas createCanvas(Composite parent,
				MaterialSelect!(MtType.CARD, Combo, Combo) msel) {
			auto skin = findSkin(_prop, _summ);
			_canvas = new Canvas(parent, DWT.BORDER);
			_canvas.addPaintListener(new class(skin, _summ, msel) PaintListener {
				private Summary _summ;
				private MaterialSelect!(MtType.CARD, Combo, Combo) _msel;
				this(Skin skin, Summary summ, MaterialSelect!(MtType.CARD, Combo, Combo) msel) {
					_summ = summ;
					_msel = msel;
				}
				override void paintControl(PaintEvent e) {
					auto c = cast(Canvas) e.widget;
					Image image;
					bool dis = false;
					switch (_msel.dirsCombo.getSelectionIndex) {
					case 0:
						// 選択中
						image = _prop.images.talker(Talker.SELECTED);
						break;
					case 1:
						// 選択中以外
						image = _prop.images.talker(Talker.UNSELECTED);
						break;
					case 2:
						// ランダム
						image = _prop.images.talker(Talker.RANDOM);
						break;
					case 3:
						// カード
						image = new Image(Display.getCurrent, menuCard(findSkin(_prop, _summ)));
						dis = true;
						break;
					default:
						// カード画像
						image = new Image(Display.getCurrent, loadImage(_msel.filePath));
						dis = true;
					}
					auto dw = image.getImageData.width;
					auto dh = image.getImageData.height;
					auto s = _prop.looks.cardSize;
					auto cs = _canvas.getClientArea;
					e.gc.drawImage(image, 0, 0, dw, dh,
						(cs.width - s.width) / 2, (cs.height - s.height) / 2, s.width, s.height);
					if (dis) image.dispose;
				}
			});
			return _canvas;
		}
	}
	auto comp = new Composite(parent, DWT.NONE);
	{
		auto gl = new GridLayout(1, true);
		gl.marginWidth = 0;
		gl.marginHeight = 0;
		comp.setLayout = gl;
	}
	auto image = new Img(prop, summ);
	string[] ss = [
		prop.msgs.talker(Talker.SELECTED),
		prop.msgs.talker(Talker.UNSELECTED),
		prop.msgs.talker(Talker.RANDOM),
		prop.msgs.talker(Talker.CARD)
	];
	msel = new MaterialSelect!(MtType.CARD, Combo, Combo)(comm, prop, summ, &image.redraw, ss);
	{
		msel.createDirsCombo(comp).setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
	}
	{
		auto gd = new GridData(GridData.FILL_HORIZONTAL);
		gd.widthHint = prop.var.etc.talkersWidth;
		auto l = msel.createFileList(comp);
		l.setLayoutData = gd;
	}
	{
		auto canvas = image.createCanvas(comp, msel);
		auto gd = new GridData(GridData.FILL_BOTH);
		auto s = canvas.computeSize(prop.looks.cardSize.width, prop.looks.cardSize.height);
		gd.widthHint = s.x;
		gd.heightHint = s.y;
		canvas.setLayoutData = gd;
	}
	{
		auto compl = new Composite(comp, DWT.NONE);
		compl.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
		auto gl = new GridLayout(2, false);
		gl.marginWidth = 0;
		gl.marginHeight = 0;
		compl.setLayout = gl;
		msel.createRefreshButton(compl, true).setLayoutData
			= new GridData(GridData.FILL_BOTH);
		msel.createDirectoryButton(compl, false).setLayoutData
			= new GridData(GridData.FILL_VERTICAL);
	}
	msel.path = path;
	if (msel.path.length == 0) {
		switch (talker) {
		case Talker.SELECTED:
			msel.dirsCombo.select = 0;
			break;
		case Talker.UNSELECTED:
			msel.dirsCombo.select = 1;
			break;
		case Talker.RANDOM:
			msel.dirsCombo.select = 2;
			break;
		default:
			msel.dirsCombo.select = 0;
		}
	}
	return comp;
}

private FixedWidthText createMessagePane(Props prop, bool image, Composite parent) {
	int len = image ? prop.looks.messageImageLen : prop.looks.messageLen;
	auto r = new FixedWidthText(dwtData(prop.looks.messageFont), len, parent, DWT.BORDER);
	r.widget.setBackground = Display.getCurrent.getSystemColor(DWT.COLOR_DARK_BLUE);
	r.widget.setForeground = Display.getCurrent.getSystemColor(DWT.COLOR_WHITE);
	return r;
}

private class PutC {
	private void delegate(string) _insert;
	private string _put;
	this(void delegate(string) insert, string put) {
		_insert = insert;
		_put = put;
	}
	void put() {
		_insert(_put);
	}
}
private class PutColor {
	private void delegate(dchar) _put;
	private dchar _color;
	this(void delegate(dchar) put, dchar color) {
		_put = put;
		_color = color;
	}
	void put() {
		_put(_color);
	}
}
private ToolBar createSCharBar(Composite parent,
		void delegate(string) insert, void delegate(dchar) putColor, Props prop, Skin skin) {
	auto bar = new ToolBar(parent, DWT.FLAT);
	bar.addListener(DWT.Traverse, new class Listener {
		override void handleEvent(dwt.widgets.Event.Event e) {e.doit = true;}
	});
	bar.addListener(DWT.KeyDown, new class Listener {
		override void handleEvent(dwt.widgets.Event.Event e) {e.doit = true;}
	});
	createToolItem(bar, prop.msgs.defaultColor, prop.images.defaultColor, &(new PutColor(putColor, 'W')).put);
	createToolItem(bar, prop.msgs.red, prop.images.red, &(new PutColor(putColor, 'R')).put);
	createToolItem(bar, prop.msgs.blue, prop.images.blue, &(new PutColor(putColor, 'B')).put);
	createToolItem(bar, prop.msgs.green, prop.images.green, &(new PutColor(putColor, 'G')).put);
	createToolItem(bar, prop.msgs.yellow, prop.images.yellow, &(new PutColor(putColor, 'Y')).put);
	new ToolItem(bar, DWT.SEPARATOR);
	createToolItem(bar, prop.msgs.scTalker(Talker.SELECTED), prop.images.scTalker(Talker.SELECTED),
		&(new PutC(insert, "#M")).put);
	createToolItem(bar, prop.msgs.scTalker(Talker.UNSELECTED), prop.images.scTalker(Talker.UNSELECTED),
		&(new PutC(insert, "#U")).put);
	createToolItem(bar, prop.msgs.scTalker(Talker.RANDOM), prop.images.scTalker(Talker.RANDOM),
		&(new PutC(insert, "#R")).put);
	createToolItem(bar, prop.msgs.scTalker(Talker.CARD), prop.images.scTalker(Talker.CARD),
		&(new PutC(insert, "#C")).put);
	createToolItem(bar, prop.msgs.scRef, prop.images.scRef, &(new PutC(insert, "#I")).put);
	createToolItem(bar, prop.msgs.scTeam, prop.images.scTeam, &(new PutC(insert, "#T")).put);
	createToolItem(bar, prop.msgs.scYado, prop.images.scYado, &(new PutC(insert, "#Y")).put);
	return bar;
}

private ToolBar createSkinSCharBar(Composite parent, void delegate(string) insert, Props prop, Skin skin) {
	auto bar = new ToolBar(parent, DWT.FLAT);
	bar.addListener(DWT.Traverse, new class Listener {
		override void handleEvent(dwt.widgets.Event.Event e) {e.doit = true;}
	});
	bar.addListener(DWT.KeyDown, new class Listener {
		override void handleEvent(dwt.widgets.Event.Event e) {e.doit = true;}
	});
	Image[] imgs;
	foreach (spc; skin.spChars.keys) {
		auto img = new Image(Display.getCurrent, spChar(skin, spc));
		string name = toUTF8("#"d ~ spc);
		auto scp = new PutC(insert, name);
		createToolItem(bar, name, img, &scp.put);
		imgs ~= img;
	}
	bar.addDisposeListener(new class DisposeListener {
		private Image[] _imgs;
		this() {_imgs = imgs;}
		override void widgetDisposed(DisposeEvent e) {
			foreach (img; _imgs) {
				img.dispose;
			}
		}
	});
	return bar;
}

private void putColor(FixedWidthText text, dchar put) {
	auto sel = text.widget.getSelection;
	auto old = toUTF32(text.getText);
	auto newt = cwx.utils.putColor(old, put, sel.x, sel.y);
	text.setText = toUTF8(newt);
	int nSel = sel.y + (newt.length - old.length);
	text.widget.setSelection(nSel);
}
