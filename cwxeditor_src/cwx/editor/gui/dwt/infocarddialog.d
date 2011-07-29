
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
import cwx.editor.gui.dwt.absdialog;

import org.eclipse.swt.SWT;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Group;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.GridData;

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

public:
	this(Commons comm, Props prop, Shell shell, Summary summ, InfoCard card) {
		assert (summ !is null);
		_comm = comm;
		_summ = summ;
		_card = card;
		_prop = prop;
		super(prop, shell, _card ? _prop.msgs.dlgTitInfo(_card.name) : _prop.msgs.dlgTitNewInfo,
			_prop.images.info, true, _prop.var.infoCardDlg);
		enterClose = true;
	}

	InfoCard card() {
		return _card;
	}
protected:
	override void setup(Composite area) {
		area.setLayout = new GridLayout(1, false);
		{
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			grp.setLayout = new GridLayout(2, false);
			grp.setText = _prop.msgs.name;
			_name = new GBLimitText(_prop.looks.messageFont(_summ.legacy).name,
				_prop.looks.nameLimit, grp, SWT.BORDER);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.widthHint = _name.computeSize(SWT.DEFAULT, SWT.DEFAULT).x;
			_name.widget.setLayoutData = gd;
			auto l = new Label(grp, SWT.NONE);
			l.setText = _prop.msgs.nameLimit(_prop.looks.nameLimit);
		}
		{
			auto skin = _comm.skin;
			bool including = _card && isBinImg(_card.path);
			string saveName = including ? _card.name : "";
			_imgPath = new ImageSelect!(MtType.CARD)(area, SWT.NONE, _comm, _prop, _summ,
				_prop.looks.cardSize.width, _prop.looks.cardSize.height, including, saveName);
			_imgPath.widget.setLayoutData = new GridData(GridData.FILL_BOTH);
		}
		{
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			grp.setLayout = new CenterLayout(SWT.HORIZONTAL);
			grp.setText = _prop.msgs.desc;
			_desc = new FixedWidthText(dwtData(_prop.looks.cardDescFont(_summ.legacy)), _prop.looks.cardDescLen, grp, SWT.BORDER);
			_desc.widget.setLayoutData = _desc.computeTextBaseSize(_prop.looks.cardDescLine);
		}
		if (_card) {
			_imgPath.image = _card.path;
			_name.setText = _card.name;
			_desc.setText = _card.desc;
		} else {
			_imgPath.image = "";
		}
	}

	override bool close(bool ok) {
		if (ok) {
			if (_card) {
				_card.name = _name.getText;
				_card.path = _imgPath.image;
				_card.desc = wrapReturnCode(_desc.getText);
			} else {
				_card = new InfoCard(_summ.newId!(InfoCard), _name.getText,
					_imgPath.image, wrapReturnCode(_desc.getText));
			}
		}
		return ok;
	}
}
