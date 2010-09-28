
module cwx.editor.gui.dwt.infocarddialog;

import cwx.summary;
import cwx.card;
import cwx.types;
import cwx.features;
import cwx.utils;
import cwx.skin;

import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.skin;
import cwx.editor.gui.dwt.utils;
import cwx.editor.gui.dwt.materialselect;
import cwx.editor.gui.dwt.imageselect;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.centerlayout;

import dwt.DWT;
import dwt.widgets.Display;
import dwt.widgets.Shell;
import dwt.widgets.Control;
import dwt.widgets.Composite;
import dwt.widgets.Group;
import dwt.widgets.Label;
import dwt.layout.GridLayout;
import dwt.layout.GridData;

import dwtx.jface.dialogs.Dialog;
import dwtx.jface.dialogs.IDialogConstants;

public:

class InfoCardDialog : Dialog {
private:
	Commons _comm;
	Props _prop;
	Summary _summ;
	InfoCard _card;

	ImageSelect!(MtType.CARD) _imgPath;
	FixedWidthText _desc;
	GBLimitText _name;

public:
	this(Commons comm, Props prop, Shell shell, Summary summ, InfoCard card) {
		assert (summ !is null);
		super(shell);
		_comm = comm;
		_summ = summ;
		_card = card;
		_prop = prop;
	}

	InfoCard card() {
		return _card;
	}
protected:
	override void configureShell(Shell shell) {
		super.configureShell(shell);
		shell.setText = _card ? _prop.msgs.dlgTitInfo(_card.name) : _prop.msgs.dlgTitNewInfo;
	}

	override bool isResizable() {
        return true;
    }

	override Control createDialogArea(Composite parent) {
		auto area = cast(Composite) super.createDialogArea(parent);
		area.setLayout = new GridLayout(1, false);
		{
			auto grp = new Group(area, DWT.NONE);
			grp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			grp.setLayout = new GridLayout(2, false);
			grp.setText = _prop.msgs.name;
			_name = new GBLimitText(_prop.looks.messageFont.name,
				_prop.looks.nameLimit, grp, DWT.BORDER);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.widthHint = _name.computeSize(DWT.DEFAULT, DWT.DEFAULT).x;
			_name.widget.setLayoutData = gd;
			auto l = new Label(grp, DWT.NONE);
			l.setText = _prop.msgs.nameLimit(_prop.looks.nameLimit);
		}
		{
			auto skin = findSkin(_prop, _summ);
			_imgPath = new ImageSelect!(MtType.CARD)(area, DWT.NONE, _comm, _prop, _summ,
				_prop.looks.cardSize.width, _prop.looks.cardSize.height, _summ.legacy);
			_imgPath.widget.setLayoutData = new GridData(GridData.FILL_BOTH);
		}
		{
			auto grp = new Group(area, DWT.NONE);
			grp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			grp.setLayout = new CenterLayout(DWT.HORIZONTAL);
			grp.setText = _prop.msgs.desc;
			_desc = new FixedWidthText(dwtData(_prop.looks.cardDescFont), _prop.looks.cardDescLen, grp, DWT.BORDER);
			_desc.widget.setLayoutData = _desc.computeTextBaseSize(_prop.looks.cardDescLine);
		}
		if (_card) {
			_imgPath.image = _card.path;
			_name.setText = _card.name;
			_desc.setText = _card.desc;
		} else {
			_imgPath.image = "";
		}
		return area;
	}

	override void createButtonsForButtonBar(Composite parent) {
		createButton(parent, IDialogConstants.OK_ID, IDialogConstants.OK_LABEL, true);
		createButton(parent, IDialogConstants.CANCEL_ID, IDialogConstants.CANCEL_LABEL, false);
	}

	override void buttonPressed(int buttonId) {
		if (buttonId == IDialogConstants.OK_ID) {
			if (_name.getText.length > 0) {
				if (_card) {
					_card.name = _name.getText;
					_card.path = _imgPath.image;
					_card.desc = wrapReturnCode(_desc.getText);
				} else {
					_card = new InfoCard(_summ.newId!(InfoCard), _name.getText,
						_imgPath.image, wrapReturnCode(_desc.getText));
				}
			} else {
				buttonId = IDialogConstants.CANCEL_ID;
			}
		}
		setReturnCode(buttonId);
		close;
		super.buttonPressed(buttonId);
	}
}
