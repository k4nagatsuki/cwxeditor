
module cwx.editor.gui.dwt.commondialog;

import cwx.area;

import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.centerlayout;

import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Group;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Spinner;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.GridData;

private class ReNumDialog(A) : AbsDialog {
private:
	Props _prop;
	A _area;
	ulong _minId;

	Spinner _id;

	ulong _newId;
public:
	this(Props prop, Shell shell, A area, ulong minId) {
		_prop = prop;
		_area = area;
		_minId = minId;
		super(prop, shell, prop.msgs.dlgTitReNumbering, prop.images.menuReNumbering, false);
		enterClose = true;
	}

	ulong newId() {
		return _newId;
	}
protected:
	override void setup(Composite area) {
		area.setLayout = new GridLayout(1, false);
		{
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData = new GridData(GridData.FILL_BOTH);
			grp.setText = _prop.msgs.reNumbering;
			grp.setLayout = new CenterLayout(SWT.VERTICAL | SWT.HORIZONTAL, 0);
			auto comp = new Composite(grp, SWT.NONE);
			comp.setLayout = new GridLayout(3, false);
			auto l1 = new Label(comp, SWT.NONE);
			l1.setText = _prop.msgs.reNumbering1(_area, _minId, _prop.looks.idMax);
			_id = new Spinner(comp, SWT.BORDER);
			_id.setMaximum = _prop.looks.idMax;
			_id.setMinimum = cast(int) _minId;
			auto l2 = new Label(comp, SWT.NONE);
			l2.setText = _prop.msgs.reNumbering2(_area, _minId, _prop.looks.idMax);
		}
	}
	override bool close(bool ok) {
		if (ok) {
			_newId = _id.getSelection;
		}
		return ok;
	}
}
