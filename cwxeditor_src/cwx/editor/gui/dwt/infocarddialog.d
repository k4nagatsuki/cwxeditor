
module cwx.editor.gui.dwt.infocarddialog;

import cwx.summary;
import cwx.card;
import cwx.types;
import cwx.features;
import cwx.utils;
import cwx.skin;
import cwx.path;

import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.materialselect;
import cwx.editor.gui.dwt.imageselect;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.dmenu;

import org.eclipse.swt.SWT;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Group;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Text;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.DisposeEvent;

public:

class InfoCardDialog : AbsDialog {
private:
	Commons _comm;
	Props _prop;
	Summary _summ;
	InfoCard _card;

	ImageSelect!(MtType.CARD) _imgPath;
	FixedWidthText _desc;
	GBLimitText _name;

	void refreshWarning() {
		// 情報カード名はメッセージに表示されないため長さ制限無し
		string[] ws;
		ws ~= _comm.skin.warningImage(_prop.parent, _imgPath.filePath, _summ.legacy);
		warning = ws;
	}

	void delCard(InfoCard c) {
		if (_card is c) {
			forceCancel();
		}
	}
	void refScenario(Summary summ) {
		forceCancel();
	}
	void refSkin() {
		_desc.font = dwtData(_prop.looks.cardDescFont(_summ.legacy));
	}
	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			_comm.delInfo.remove(&delCard);
			_comm.refScenario.remove(&refScenario);
			_comm.refSkin.remove(&refSkin);
		}
	}
public:
	this(Commons comm, Props prop, Shell shell, Summary summ, InfoCard card) {
		assert (summ !is null);
		_comm = comm;
		_summ = summ;
		_card = card;
		_prop = prop;
		super(prop, shell, false, _card ? .tryFormat(_prop.msgs.dlgTitInfo, _card.name) : _prop.msgs.dlgTitNewInfo,
			_prop.images.info, true, _prop.var.infoCardDlg, true);
		enterClose = true;
	}

	@property
	InfoCard card() {
		return _card;
	}

	bool openCWXPath(string path, bool shellActivate) {
		return cpempty(path);
	}
protected:
	override void setup(Composite area) {
		area.setLayout(new GridLayout(1, false));
		{
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			grp.setLayout(new GridLayout(1, false));
			grp.setText(_prop.msgs.name);
			_name = new GBLimitText(_prop.looks.monospace,
				_prop.looks.nameLimit, false, grp, SWT.BORDER);
			mod(_name.widget);
			createTextMenu!Text(_comm, _prop, _name.widget, &catchMod);
			_name.limitEvent ~= &refreshWarning;
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.widthHint = _name.computeSize(SWT.DEFAULT, SWT.DEFAULT).x;
			_name.widget.setLayoutData(gd);
		}
		{
			auto skin = _comm.skin;
			bool including = _card && isBinImg(_card.path);
			string saveName = including ? _card.name : "";
			_imgPath = new ImageSelect!(MtType.CARD)(area, SWT.NONE, _comm, _prop, _summ,
				_prop.looks.cardSize.width, _prop.looks.cardSize.height, including, saveName);
			mod(_imgPath);
			_imgPath.widget.setLayoutData(new GridData(GridData.FILL_BOTH));
		}
		{
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			grp.setLayout(new CenterLayout(SWT.HORIZONTAL));
			grp.setText(_prop.msgs.desc);
			_desc = new FixedWidthText(dwtData(_prop.looks.cardDescFont(_summ.legacy)), _prop.looks.cardDescLen, grp, SWT.BORDER);
			createTextMenu!Text(_comm, _prop, _desc.widget, &catchMod);
			mod(_desc.widget);
			_desc.widget.setLayoutData(_desc.computeTextBaseSize(_prop.looks.cardDescLine));
		}
		_comm.delInfo.add(&delCard);
		_comm.refScenario.add(&refScenario);
		_comm.refSkin.add(&refSkin);
		area.addDisposeListener(new Dispose);

		refCard(_card);
	}
	private void refCard(InfoCard card) {
		if (_card && _card !is card) return;
		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_card) {
			_imgPath.image = _card.path;
			_name.setText(_card.name);
			_desc.setText(_card.desc);
		} else {
			_imgPath.image = "";
		}
	}

	override bool apply() {
		if (_card) {
			_card.name = _name.getText();
			_card.path = _imgPath.image;
			_card.desc = wrapReturnCode(_desc.getText());
		} else {
			_card = new InfoCard(_summ.newId!(InfoCard), _name.getText(),
				_imgPath.image, wrapReturnCode(_desc.getText()));
		}
		return true;
	}
}
