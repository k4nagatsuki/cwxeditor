
module cwx.editor.gui.dwt.infocarddialog;

import cwx.summary;
import cwx.card;
import cwx.types;
import cwx.features;
import cwx.utils;
import cwx.skin;
import cwx.path;
import cwx.imagesize;

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

import org.eclipse.swt.all;

public:

class InfoCardDialog : AbsDialog {
private:
	int _readOnly = 0;
	Commons _comm;
	Props _prop;
	Summary _summ;
	InfoCard _card;

	ImageSelect!(MtType.CARD) _imgPath;
	FixedWidthText _desc;
	GBLimitText _name;

	Skin _summSkin;
	@property
	Skin summSkin() { mixin(S_TRACE);
		return _summSkin ? _summSkin : _comm.skin;
	}

	void refreshWarning() { mixin(S_TRACE);
		// 情報カード名はメッセージに表示されないため長さ制限無し
		string[] ws;

		ws ~= _imgPath.warnings;

		warning = ws;
	}

	void delCard(InfoCard c) { mixin(S_TRACE);
		if (_card is c) { mixin(S_TRACE);
			forceCancel();
		}
	}
	void refScenario(Summary summ) { mixin(S_TRACE);
		forceCancel();
	}
	void refSkin() { mixin(S_TRACE);
		_desc.font = dwtData(_prop.looks.cardDescFont(_summ.legacy));
	}
	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			_comm.delInfo.remove(&delCard);
			_comm.refScenario.remove(&refScenario);
			_comm.refSkin.remove(&refSkin);
		}
	}
public:
	this(Commons comm, Props prop, Shell shell, Summary summ, InfoCard card, bool readOnly) { mixin(S_TRACE);
		assert (summ !is null);
		_comm = comm;
		_summ = summ;
		_card = card;
		_prop = prop;
		_readOnly = readOnly ? SWT.READ_ONLY : SWT.NONE;
		if (_readOnly) _summSkin = findSkin(_comm, _prop, _summ);
		super(prop, shell, _readOnly, false, _card ? .tryFormat(_prop.msgs.dlgTitInfo, _card.name) : _prop.msgs.dlgTitNewInfo,
			_prop.images.info, true, _prop.var.infoCardDlg, true);
		enterClose = true;
	}

	@property
	InfoCard card() { mixin(S_TRACE);
		return _card;
	}

	bool openCWXPath(string path, bool shellActivate) { mixin(S_TRACE);
		return cpempty(path);
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(new GridLayout(1, false));
		{ mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			grp.setLayout(new GridLayout(1, false));
			grp.setText(_prop.msgs.name);
			_name = new GBLimitText(_prop.looks.monospace,
				_prop.looks.nameLimit, false, grp, SWT.BORDER | _readOnly);
			mod(_name.widget);
			createTextMenu!Text(_comm, _prop, _name.widget, &catchMod);
			_name.limitEvent ~= &refreshWarning;
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.widthHint = _name.computeSize(SWT.DEFAULT, SWT.DEFAULT).x;
			_name.widget.setLayoutData(gd);
		}
		{ mixin(S_TRACE);
			auto skin = summSkin;
			bool including = _card && isBinImg(_card.path);
			_imgPath = new ImageSelect!(MtType.CARD)(area, _readOnly, _comm, _prop, _summ,
				_prop.looks.cardSize.width, _prop.looks.cardSize.height, including, true, &_name.getText);
			mod(_imgPath);
			_imgPath.modEvent ~= &refreshWarning;
			_imgPath.widget.setLayoutData(new GridData(GridData.FILL_BOTH));
		}
		{ mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			grp.setLayout(new CenterLayout(SWT.HORIZONTAL));
			grp.setText(_prop.msgs.desc);
			_desc = new FixedWidthText(dwtData(_prop.looks.cardDescFont(_summ.legacy)), _prop.looks.cardDescLen, grp, SWT.BORDER | _readOnly);
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
	private void refCard(InfoCard card) { mixin(S_TRACE);
		if (_card && _card !is card) return;
		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_card) { mixin(S_TRACE);
			_imgPath.image = _card.path;
			_name.setText(_card.name);
			_desc.setText(_card.desc);
		} else { mixin(S_TRACE);
			_imgPath.image = "";
		}
	}

	override bool apply() { mixin(S_TRACE);
		if (_card) { mixin(S_TRACE);
			_card.name = _name.getText();
			_card.path = _imgPath.image;
			_card.desc = wrapReturnCode(_desc.getText());
		} else { mixin(S_TRACE);
			_card = new InfoCard(_summ.newId!(InfoCard), _name.getText(),
				_imgPath.image, wrapReturnCode(_desc.getText()));
		}
		getShell().setText(.tryFormat(_prop.msgs.dlgTitInfo, _card.name));
		return true;
	}
}
