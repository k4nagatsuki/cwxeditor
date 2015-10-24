
module cwx.editor.gui.dwt.summarydialog;

import cwx.utils;
import cwx.usecounter;
import cwx.summary;
import cwx.area;
import cwx.event;
import cwx.skin;
import cwx.card;
import cwx.structs;
import cwx.types;
import cwx.path;
import cwx.imagesize;

import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.materialselect;
import cwx.editor.gui.dwt.imageselect;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.properties;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.incsearch;
import cwx.editor.gui.dwt.chooser;

import std.conv;
import std.string;
import std.path;

import org.eclipse.swt.all;

public:

/// シナリオの概略を設定するダイアログ。
class SummaryDialog : AbsDialog {
private:
	int _readOnly = SWT.NONE;
	Commons _comm;
	Props _prop;
	Summary _summ;

	SummaryPreview _summImage = null;
	Composite _imgArea;

	Text _sname;
	ImageSelect!(MtType.CARD) _imgPath;
	FixedWidthText _desc;
	Text _author;
	Spinner _levMin, _levMax;
	AreaChooser!(Area, true) _startArea;
	Spinner _rCouponNum;
	Text _rCoupons;
	Button _typeSkin;
	Button _typeClassic;
	Combo _type;
	Tuple!(string, "type", string, "name")[] _skinInfo;
	bool _hasLegacySkin;
	ClassicEngine[] _classicEngines;
	Combo _dataVersion;
	SplitPane _tab2Sash, _tab3Sash;
	// TODO Tag
	// TODO Label

	Skin _summSkin;
	@property
	Skin summSkin() { mixin(S_TRACE);
		return _summSkin ? _summSkin : _comm.skin;
	}

	void refreshWarning() { mixin(S_TRACE);
		string[] ws;

		ws ~= _imgPath.warnings;

		warning = ws;
	}

	void levMaxEnter(int enter) { mixin(S_TRACE);
		if (_readOnly) return;
		if (enter > 0 && _levMin.getSelection() != 0 && enter < _levMin.getSelection()) { mixin(S_TRACE);
			_levMin.setSelection(enter);
		}
	}
	void levMinEnter(int enter) { mixin(S_TRACE);
		if (_readOnly) return;
		if (enter > 0 && _levMax.getSelection() != 0 && enter > _levMax.getSelection()) { mixin(S_TRACE);
			_levMax.setSelection(enter);
		}
	}

	@property
	Skin selectedSkin() { mixin(S_TRACE);
		if (_typeSkin.getSelection()) { mixin(S_TRACE);
			auto info = _skinInfo[_type.getSelectionIndex()];
			foreach (file, skin; skinTable(_prop)) { mixin(S_TRACE);
				if (info.type == skin.type && info.name == skin.name) { mixin(S_TRACE);
					return skin;
				}
			}
		} else if (_typeClassic.getSelection()) { mixin(S_TRACE);
			int i = _type.getSelectionIndex();
			if (_hasLegacySkin) { mixin(S_TRACE);
				if (i == 0) { mixin(S_TRACE);
					return .findSkin(_comm, _prop, _summ, null, "", "", false);
				}
				i--;
			}
			return .createClassicSkin(_prop, _classicEngines[i]);
		}
		return .findSkin2(_prop, _prop.var.etc.defaultSkin, "");
	}
	void constructImage(Composite area) { mixin(S_TRACE);
		_imgArea = area;

		auto aComp = addition();
		aComp.setLayout(new GridLayout(1, true));
		auto prev = new Button(aComp, SWT.TOGGLE);
		prev.setText(_prop.msgs.messagePreview);
		prev.setSelection(_prop.var.etc.showSummaryPreview);
		.listener(prev, SWT.Selection, { mixin(S_TRACE);
			showImagePreview(prev.getSelection());
		});
		showImagePreview(_prop.var.etc.showSummaryPreview, false);
	}
	void showImagePreview(bool visible, bool regWin = true) { mixin(S_TRACE);
		if (getShell().isVisible()) getShell().setRedraw(false);
		scope (exit) {
			if (getShell().isVisible()) getShell().setRedraw(true);
		}

		int w;
		if (visible) { mixin(S_TRACE);
			if (_summImage) return;
			_summImage = new SummaryPreview(_comm, _imgArea, SWT.NONE);
			_summImage.setImageSelect(&_sname.getText, &_imgPath.images, &selectedSkin, {return _desc.getRRText();}, &_levMin.getSelection, &_levMax.getSelection);
			_summImage.setLayoutData(new GridData(GridData.FILL_VERTICAL));
			w = _summImage.computeSize(SWT.DEFAULT, SWT.DEFAULT).x;
		} else { mixin(S_TRACE);
			if (!_summImage) return;
			w = _summImage.getSize().x;
			if (_summImage) _summImage.dispose();
			_summImage = null;
		}
		_prop.var.etc.showSummaryPreview = visible;

		if (regWin) { mixin(S_TRACE);
			auto ws = getShell().getSize();
			if (visible) { mixin(S_TRACE);
				ws.x += w;
			} else { mixin(S_TRACE);
				ws.x -= w;
			}
			getShell().setSize(ws);
		}
	}
	void refreshPreview() { mixin(S_TRACE);
		if (_summImage) { mixin(S_TRACE);
			_summImage.redrawImage();
		}
	}
	void clearBuf() { mixin(S_TRACE);
		if (_summImage) { mixin(S_TRACE);
			_summImage.clearBuf();
		}
	}
	private void setCDataX(Control c, GridData data) { mixin(S_TRACE);
		auto p = c.computeSize(SWT.DEFAULT, SWT.DEFAULT);
		data.widthHint = p.x;
		c.setLayoutData(data);
	}
	private void setCDataXY(Control c, GridData data) { mixin(S_TRACE);
		auto p = c.computeSize(SWT.DEFAULT, SWT.DEFAULT);
		data.widthHint = p.x;
		data.heightHint = p.y;
		c.setLayoutData(data);
	}
	void constructTab1(CTabFolder tabf) { mixin(S_TRACE);
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, true));
		{ mixin(S_TRACE);
			_tab2Sash = new SplitPane(comp, SWT.HORIZONTAL);
			_tab2Sash.resizeControl1 = true;
			_tab2Sash.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto skin = summSkin;
			{ mixin(S_TRACE);
				bool including = _summ.imagePaths.length && isBinImg(_summ.imagePaths[0]);
				_imgPath = new ImageSelect!(MtType.CARD)(_tab2Sash, _readOnly, _comm, _prop, _summ,
					_prop.looks.cardSize.width, _prop.looks.cardSize.height, including, true, () => _sname.getText(), &clearBuf);
				mod(_imgPath);
				_imgPath.modEvent ~= &refreshWarning;
				_imgPath.images = _summ.imagePaths;
				_imgPath.modEvent ~= &refreshPreview;
				_imgPath.updateImageEvent ~= &refreshPreview;
			}
			{ mixin(S_TRACE);
				auto comp2 = new Composite(_tab2Sash, SWT.NONE);
				comp2.setLayout(zeroGridLayout(1, true));
				{ mixin(S_TRACE);
					auto grp = centerGroup(comp2, _prop.msgs.title, true, false, new GridData(GridData.FILL_BOTH));
					grp.setLayout(new GridLayout(1, true));
					_sname = new Text(grp, SWT.BORDER | _readOnly);
					createTextMenu!Text(_comm, _prop, _sname, &catchMod);
					mod(_sname);
					setCDataX(_sname, new GridData(GridData.FILL_HORIZONTAL));
					_sname.setText(_summ.scenarioName);
					checker(_sname);
					.listener(_sname, SWT.Modify, &refreshPreview);
				}
				{ mixin(S_TRACE);
					auto grp = centerGroup(comp2, _prop.msgs.author, true, false, new GridData(GridData.FILL_BOTH));
					grp.setLayout(new GridLayout(1, true));
					_author = new Text(grp, SWT.BORDER | _readOnly);
					createTextMenu!Text(_comm, _prop, _author, &catchMod);
					mod(_author);
					setCDataX(_author, new GridData(GridData.FILL_HORIZONTAL));
					_author.setText(_summ.author);
				}
				{ mixin(S_TRACE);
					auto grp = centerGroup(comp2, _prop.msgs.targetLevel, false, false, new GridData(GridData.FILL_BOTH));
					grp.setLayout(new GridLayout(4, false));
					_levMin = new Spinner(grp, SWT.BORDER | _readOnly);
					initSpinner(_levMin);
					mod(_levMin);
					_levMin.setSelection(_summ.levelMin);
					_levMin.setMinimum(0);
					_levMin.setMaximum(_prop.var.etc.levelMax);
					if (!_readOnly) new SpinnerEdit(_levMin, &levMinEnter);
					auto lbl = new Label(grp, SWT.NONE);
					lbl.setText(_prop.msgs.levSep);
					lbl.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
					_levMax = new Spinner(grp, SWT.BORDER | _readOnly);
					initSpinner(_levMax);
					mod(_levMax);
					_levMax.setSelection(_summ.levelMax);
					_levMax.setMinimum(0);
					_levMax.setMaximum(_prop.var.etc.levelMax);
					if (!_readOnly) { mixin (S_TRACE);
						new SpinnerEdit(_levMax, &levMaxEnter);
					}
					if (!_readOnly) { mixin (S_TRACE);
						.listener(_levMin, SWT.Modify, &refreshPreview);
						.listener(_levMax, SWT.Modify, &refreshPreview);
					}

					auto hint = new Label(grp, SWT.NONE);
					hint.setText(.tryFormat(_prop.msgs.rangeHint, _levMin.getMinimum(), _levMin.getMaximum()));
				}
			}
			_tab2Sash.setWeights([_prop.var.etc.summaryParamSashL, _prop.var.etc.summaryParamSashR]);
		}
		{ mixin(S_TRACE);
			auto grp = new Group(comp, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			grp.setLayout(new CenterLayout(SWT.HORIZONTAL));
			grp.setText(_prop.msgs.desc);
			_desc = new FixedWidthText(dwtData(_prop.looks.summaryDescFont(summSkin.legacy)), _prop.looks.summaryDescLen, grp, SWT.BORDER | _readOnly);
			createTextMenu!Text(_comm, _prop, _desc.widget, &catchMod);
			mod(_desc.widget);
			_desc.widget.setLayoutData(_desc.computeTextBaseSize(_prop.looks.summaryDescLine));
			_desc.setText(_summ.desc);
			.listener(_desc.widget, SWT.Modify, &refreshPreview);
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.baseData);
		tab.setControl(comp);
	}
	void constructTab2(CTabFolder tabf) { mixin(S_TRACE);
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, true));
		{ mixin(S_TRACE);
			_tab3Sash = new SplitPane(comp, SWT.HORIZONTAL);
			_tab3Sash.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto skin = summSkin;
			{ mixin(S_TRACE);
				auto comp2 = new Composite(_tab3Sash, SWT.NONE);
				comp2.setLayout(zeroMarginGridLayout(1, true));
				{ mixin(S_TRACE);
					auto grp = new Group(comp2, SWT.NONE);
					grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
					grp.setText(_prop.msgs.scenarioType);
					grp.setLayout(new GridLayout(1, true));
					auto refTypes = new RefreshTypes;
					_typeSkin = new Button(grp, SWT.RADIO);
					_typeSkin.setEnabled(!_readOnly);
					_typeSkin.setText(_prop.msgs.sTypeXML);
					_typeSkin.addSelectionListener(refTypes);
					_typeClassic = new Button(grp, SWT.RADIO);
					_typeClassic.setEnabled(!_readOnly);
					_typeClassic.setText(_prop.msgs.sTypeClassic);
					_typeClassic.addSelectionListener(refTypes);
					_type = new Combo(grp, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
					_type.setEnabled(!_readOnly);
					mod(_type);
					_type.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
					_type.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
					refreshTypes(skin);
					.listener(_typeSkin, SWT.Selection, &refreshPreview);
					.listener(_typeClassic, SWT.Selection, &refreshPreview);
					.listener(_type, SWT.Modify, &refreshPreview);
				}
				{ mixin(S_TRACE);
					auto grp = new Group(comp2, SWT.NONE);
					grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
					grp.setText(_prop.msgs.dataVersion);
					grp.setLayout(new GridLayout(1, true));
					_dataVersion = new Combo(grp, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
					mod(_dataVersion);
					_dataVersion.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
					_dataVersion.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
					foreach (i, v; VERSIONS) { mixin(S_TRACE);
						_dataVersion.add(.tryFormat(_prop.msgs.dataVersionName, VERSION_NAMES[i], ENGINES[i]));
						if (v == _summ.dataVersion) { mixin(S_TRACE);
							_dataVersion.select(cast(int)i);
						}
					}
					if (_dataVersion.getSelectionIndex() == -1) _dataVersion.select(0);
					updateDataVersion();
				}
				{ mixin(S_TRACE);
					auto grp = new Group(comp2, SWT.NONE);
					grp.setLayoutData(new GridData(GridData.FILL_BOTH));
					grp.setText(_prop.msgs.qualification);
					grp.setLayout(new GridLayout(2, false));
					{ mixin(S_TRACE);
						auto lblN = new Label(grp, SWT.NONE);
						lblN.setText(_prop.msgs.rCouponNum);
						_rCouponNum = new Spinner(grp, SWT.BORDER | _readOnly);
						initSpinner(_rCouponNum);
						mod(_rCouponNum);
						_rCouponNum.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
						_rCouponNum.setSelection(_summ.rCouponNum);
						_rCouponNum.setMaximum(999);
						_rCouponNum.setMinimum(0);
					}
					{ mixin(S_TRACE);
						auto lblR = new Label(grp, SWT.NONE);
						auto gd = new GridData(GridData.HORIZONTAL_ALIGN_BEGINNING);
						gd.horizontalSpan = 2;
						lblR.setLayoutData(gd);
						lblR.setText(_prop.msgs.rCoupons);
					}
					{ mixin(S_TRACE);
						_rCoupons = new Text(grp, SWT.BORDER | SWT.MULTI | SWT.WRAP | _readOnly);
						createTextMenu!Text(_comm, _prop, _rCoupons, &catchMod);
						mod(_rCoupons);
						auto gd = new GridData(GridData.FILL_BOTH);
						gd.horizontalSpan = 2;
						setCDataXY(_rCoupons, gd);
						string buf;
						foreach (i, t; _summ.rCoupons) { mixin(S_TRACE);
							buf ~= t;
							buf ~= "\n";
						}
						_rCoupons.setText(buf);
					}
				}
			}
			{ mixin(S_TRACE);
				auto grp = new Group(_tab3Sash, SWT.NONE);
				grp.setLayoutData(new GridData(GridData.FILL_BOTH));
				grp.setText(_prop.msgs.startArea);
				grp.setLayout(new GridLayout(1, false));
				_startArea = new AreaChooser!(Area, true)(_comm, _summ, grp);
				_startArea.setEnabled(!_readOnly);
				mod(_startArea);
				setCDataXY(_startArea, new GridData(GridData.FILL_BOTH));

				_startArea.selected = _summ.startArea;
			}
			_tab3Sash.setWeights([_prop.var.etc.rCouponsStartAreaSashL, _prop.var.etc.rCouponsStartAreaSashR]);
		}
		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.etcData);
		tab.setControl(comp);
	}
	void updateDataVersion() { mixin(S_TRACE);
		_dataVersion.setEnabled(!_readOnly && !_summ.legacy);
	}
	class RefreshTypes : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			refreshTypes(summSkin);
		}
	}
	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			auto ws1 = _tab2Sash.getWeights();
			_prop.var.etc.summaryParamSashL = ws1[0];
			_prop.var.etc.summaryParamSashR = ws1[1];
			auto ws2 = _tab3Sash.getWeights();
			_prop.var.etc.rCouponsStartAreaSashL = ws2[0];
			_prop.var.etc.rCouponsStartAreaSashR = ws2[1];
			if (!_readOnly) { mixin(S_TRACE);
				_comm.refScenario.remove(&refScenario);
			}
			_comm.refSkin.remove(&refSkin);
			_comm.refClassicSkin.remove(&refreshTypes);
			_comm.refDataVersion.remove(&updateDataVersion);
		}
	}

	void refScenario(Summary summ) { mixin(S_TRACE);
		if (_readOnly) return;
		forceCancel();
	}
	void refSkin(Object sender) { mixin(S_TRACE);
		if (_readOnly) return;
		refreshPreview();
		_desc.font = dwtData(_prop.looks.summaryDescFont(summSkin.legacy));
		if (sender is this) return;
		refreshTypes();
	}
	void refreshTypes() { mixin(S_TRACE);
		refreshTypes(null);
	}
	void refreshTypes(Skin skin) { mixin(S_TRACE);
		string selType = skin ? skin.type : _summ.type;
		string selName = skin ? skin.name : "";
		string selClassic = null;

		if (!_typeSkin.getSelection() && !_typeClassic.getSelection()) { mixin(S_TRACE);
			if (summSkin.legacy) { mixin(S_TRACE);
				_typeClassic.setSelection(true);
			} else { mixin(S_TRACE);
				_typeSkin.setSelection(true);
			}
			selType = _summ.type;
			selClassic = summSkin.legacyEngine.length ? summSkin.legacyEngine : null;
		} else { mixin(S_TRACE);
			if (_skinInfo) { mixin(S_TRACE);
				auto info = _skinInfo[_type.getSelectionIndex()];
				selType = info.type;
				selName = info.name;
			} else { mixin(S_TRACE);
				int i = _type.getSelectionIndex();
				if (-1 != i && i < _classicEngines.length) { mixin(S_TRACE);
					if (_hasLegacySkin) { mixin(S_TRACE);
						if (0 < i) { mixin(S_TRACE);
							selClassic = _prop.toAppAbs(_classicEngines[i - 1].enginePath);
						}
					} else { mixin(S_TRACE);
						selClassic = _prop.toAppAbs(_classicEngines[i].enginePath);
					}
				}
				if (selClassic) selClassic = nabs(selClassic);
			}
		}
		_classicEngines = [];
		foreach (e; _prop.var.etc.classicEngines) { mixin(S_TRACE);
			_classicEngines ~= e.dup;
		}

		_type.removeAll();
		_skinInfo = [];
		void initSkin() { mixin(S_TRACE);
			// XML形式のスキン
			Skin[] skins;
			foreach (key, value; skinTable(_prop)) { mixin(S_TRACE);
				skins ~= value;
			}
			int skinCmp(in Skin skin1, in Skin skin2) { mixin(S_TRACE);
				if (_prop.var.etc.logicalSort) { mixin(S_TRACE);
					int i = ncmp(skin1.name, skin2.name);
					if (i == 0) i = ncmp(skin1.type, skin2.type);
					return i;
				} else { mixin(S_TRACE);
					int i = cmp(skin1.name, skin2.name);
					if (i == 0) i = cmp(skin1.type, skin2.type);
					return i;
				}
			}
			skins = sort!(skinCmp)(skins);
			ptrdiff_t typeSkin = -1;
			foreach (i, skin2; skins) { mixin(S_TRACE);
				_type.add(.tryFormat("%s(%s)", skin2.name, skin2.type));
				_skinInfo ~= typeof(_skinInfo[0])(skin2.type, skin2.name);
				if (skin2.type == selType) { mixin(S_TRACE);
					if (typeSkin == -1) typeSkin = i;
					if (skin2.name == selName) _type.select(cast(int)i);
				}
			}
			if (!skins) { mixin(S_TRACE);
				// スキンが無い
				_type.add(_prop.var.etc.defaultSkin);
				_skinInfo ~= typeof(_skinInfo[0])(_prop.var.etc.defaultSkin, "");
			}
			if (_type.getSelectionIndex() == -1) { mixin(S_TRACE);
				if (typeSkin == -1) { mixin(S_TRACE);
					_type.select(cast(int)typeSkin);
				} else { mixin(S_TRACE);
					_type.select(0);
				}
			}
		}
		_hasLegacySkin = false;
		string resDir, lEnginePath;
		auto curSkin = Skin.findLegacy(_summ.scenarioPath, resDir, lEnginePath, _prop.var.etc.classicEngineRegex, _prop.var.etc.classicDataDirRegex, _prop.var.etc.classicMatchKey, _prop.var.etc.classicEngines);
		lEnginePath = nabs(lEnginePath);
		bool cur = 0 != lEnginePath.length;
		if (_typeSkin.getSelection()) { mixin(S_TRACE);
			initSkin();
		} else { mixin(S_TRACE);
			assert (_typeClassic.getSelection());
			// クラシックエンジンのリソース
			foreach (i, ce; _classicEngines) { mixin(S_TRACE);
				_type.add(ce.name);
				if (selClassic && cfnmatch(selClassic, _prop.toAppAbs(ce.enginePath))) { mixin(S_TRACE);
					_type.select(cast(int)i);
				}
				if (cur && cfnmatch(lEnginePath, _prop.toAppAbs(ce.enginePath))) { mixin(S_TRACE);
					cur = false;
					if (-1 == _type.getSelectionIndex()) _type.select(cast(int)i);
				}
			}
			if (cur) { mixin(S_TRACE);
				_type.add(_prop.msgs.defaultSelection(lEnginePath), 0);
				_hasLegacySkin = true;
			}
			if (!_type.getItemCount()) { mixin(S_TRACE);
				// クラシックエンジンが無い
				_typeClassic.setSelection(false);
				_typeSkin.setSelection(true);
				initSkin();
			}
		}
		_typeClassic.setEnabled(!_readOnly && (cur || _classicEngines.length));
		assert (_type.getItemCount());
		if (-1 == _type.getSelectionIndex()) { mixin(S_TRACE);
			_type.select(0);
		}
	}
public:
	this(Commons comm, Props prop, Shell shell, Summary summ, bool readOnly) { mixin(S_TRACE);
		assert (summ !is null);
		_readOnly = readOnly ? SWT.READ_ONLY : SWT.NONE;
		_comm = comm;
		_summ = summ;
		_prop = prop;
		if (_readOnly) _summSkin = findSkin(_comm, _prop, _summ);
		super(prop, shell, _readOnly, false, .tryFormat(_prop.msgs.dlgTitSummary, _summ.scenarioName),
			_prop.images.summary, true, _prop.var.summaryDlg, true);
	}

protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(windowGridLayout(2, false));

		auto tabf = new CTabFolder(area, SWT.BORDER);
		tabf.setLayoutData(new GridData(GridData.FILL_BOTH));
		constructTab1(tabf);
		constructTab2(tabf);
		constructImage(area);

		if (!_readOnly) { mixin(S_TRACE);
			_comm.refScenario.add(&refScenario);
		}
		_comm.refSkin.add(&refSkin);
		_comm.refClassicSkin.add(&refreshTypes);
		_comm.refDataVersion.add(&updateDataVersion);
		area.addDisposeListener(new Dispose);

		void closeAdds(Summary summ) { mixin(S_TRACE);
			if (_summ is summ) forceCancel();
		}
		_comm.closeAdds.add(&closeAdds);
		.listener(getShell(), SWT.Dispose, () => _comm.closeAdds.remove(&closeAdds));
	}

	override bool apply() { mixin(S_TRACE);
		if (_readOnly) return true;
		string oldName = _summ.scenarioName;
		string oldResDir = nabs(summSkin.resDir);
		scope (exit) {
			if (oldName != _summ.scenarioName) _comm.refScenarioName.call();
			if (!cfnmatch(oldResDir, nabs(summSkin.resDir))) _comm.refSkin.call(this);
			_comm.refUseCount.call();
		}
		_summ.setBaseParams(_sname.getText(), _author.getText());
		_summ.desc = _desc.getRRText();
		_summ.imagePaths = _imgPath.images;
		_summ.levelMin = _levMin.getSelection();
		_summ.levelMax = _levMax.getSelection();
		string[] rcs;
		foreach (s; splitLines!string(_rCoupons.getText())) { mixin(S_TRACE);
			if (s.length > 0) { mixin(S_TRACE);
				rcs ~= s;
			}
		}
		_summ.rCoupons = rcs;
		_summ.rCouponNum = _rCouponNum.getSelection();
		_summ.startArea = _startArea.selected;
		if (_typeSkin.getSelection()) { mixin(S_TRACE);
			_summ.type = _skinInfo[_type.getSelectionIndex()].type;
		} else { mixin(S_TRACE);
			_summ.type = "";
		}
		auto oldSkin = _comm.skin;
		_comm.skin = selectedSkin;
		_comm.updateSkinMaterialsExtension(oldSkin, _comm.skin);
		_comm.refCoupons.call();
		getShell().setText(.tryFormat(_prop.msgs.dlgTitSummary, _summ.scenarioName));
		auto ver = VERSIONS[_dataVersion.getSelectionIndex()];
		if (_summ.dataVersion != ver) { mixin(S_TRACE);
			_summ.dataVersion = ver;
			if (!_summ.legacy) { mixin(S_TRACE);
				_comm.refDataVersion.call();
			}
		}
		return true;
	}
}

private class SummaryPreview : Composite {

	private Commons _comm;
	private Props _prop;
	private Summary _summ;

	private Canvas _summImage;
	private string delegate() _sname = null;
	private string[] delegate() _imgPaths = null;
	private Skin delegate() _selectedSkin = null;
	private string delegate() _desc = null;
	private int delegate() _levMin = null;
	private int delegate() _levMax = null;

	private Image[] _summImageBufs = [];
	private ImageData[] _bufImgData = [];
	private string[] _bufImagePaths = [];

	private class PListener : PaintListener {
		override void paintControl(PaintEvent e) { mixin(S_TRACE);
			if (!_imgPaths) return;
			auto d = Display.getCurrent();
			auto size = _prop.looks.summarySize;
			auto rect = _summImage.getClientArea();
			scope buf = new Image(d, size.width, size.height);
			scope (exit) buf.dispose();
			scope gc = new GC(buf);
			scope (exit) gc.dispose();

			auto skin = _selectedSkin();
			auto imgPaths = _imgPaths();
			if (imgPaths.length < _summImageBufs.length) { mixin(S_TRACE);
				foreach (i; imgPaths.length .. _summImageBufs.length) { mixin(S_TRACE);
					if (_summImageBufs[i]) _summImageBufs[i].dispose();
				}
			}
			_summImageBufs.length = imgPaths.length;
			_bufImgData.length = imgPaths.length;
			_bufImagePaths.length = imgPaths.length;
			foreach (i, imgPath; imgPaths) { mixin(S_TRACE);
				auto path = nabs(skin.findImagePath(imgPath, _summ.scenarioPath));
				if (_bufImagePaths[i] == "" || !_summImageBufs[i] || !.cfnmatch(_bufImagePaths[i], path) || summary(skin) !is _bufImgData[i]) { mixin(S_TRACE);
					if (_summImageBufs[i]) _summImageBufs[i].dispose();
					_bufImagePaths[i] = path;
					_bufImgData[i] = summary(skin);
					_summImageBufs[i] = new Image(d, _bufImgData[i]);
				}

				if (rect.width < size.width || rect.height < size.height) { mixin(S_TRACE);
					real wp = cast(real)rect.width / size.width;
					real hp = cast(real)rect.height / size.height;
					ImageData data;
					if (wp < hp) { mixin(S_TRACE);
						size.width = rect.width;
						size.height = cast(int)(size.height * wp);
					} else { mixin(S_TRACE);
						size.width = cast(int)(size.width * hp);
						size.height = rect.height;
					}
					data = _summImageBufs[i].getImageData().scaledTo(size.width, size.height);
					_summImageBufs[i].dispose();
					_summImageBufs[i] = null;
					if (size.width > 0 && size.height > 0) { mixin(S_TRACE);
						_summImageBufs[i] = new Image(d, data);
					}
				}

				if (_summImageBufs[i]) gc.drawImage(_summImageBufs[i], 0, 0);

				if (imgPath !is null && imgPath.length > 0) { mixin(S_TRACE);
					string p = skin.findImagePath(imgPath, _summ.scenarioPath);
					if (p.length) { mixin(S_TRACE);
						scope img = new Image(d, loadImage(_prop, skin, _summ, p));
						gc.drawImage(img, _prop.looks.summaryImageXY.x, _prop.looks.summaryImageXY.y);
						img.dispose();
					}
				}
			}
			{ mixin(S_TRACE);
				void drawCenterText(FontData fontData, string text, int y) { mixin(S_TRACE);
					scope font = new Font(d, fontData);
					gc.setFont(font);
					scope p = gc.stringExtent(text);
					gc.wDrawText(text, (size.width - p.x) / 2, y, true);
					font.dispose();
				}
				int alpha;
				scope c = new Color(d, dwtData(_prop.looks.summaryLevelColor, alpha));
				gc.setForeground(c);
				gc.setAlpha(alpha);
				int levL = _levMin();
				int levH = _levMax();
				string levText;
				if (levL > 0 && levL == levH) { mixin(S_TRACE);
					levText = .tryFormat(_prop.msgs.targetLevelSame, levL);
				} else if (levL > 0 && levH > 0) { mixin(S_TRACE);
					levText = .tryFormat(_prop.msgs.targetLevelHL, levL, levH);
				} else if (levL > 0 && levH == 0) { mixin(S_TRACE);
					levText = .tryFormat(_prop.msgs.targetLevelL, levL);
				} else if (levL == 0 && levH > 0) { mixin(S_TRACE);
					levText = .tryFormat(_prop.msgs.targetLevelH, levH);
				} else { mixin(S_TRACE);
					levText = "";
				}
				drawCenterText(dwtData(_prop.looks.summaryLevelFont(skin.legacy)),
					levText, _prop.looks.summaryLevelY);
				c.dispose();
				gc.setAlpha(255);
				gc.setForeground(d.getSystemColor(SWT.COLOR_BLACK));
				drawCenterText(dwtData(_prop.looks.summaryTitleFont(skin.legacy)), _sname(), _prop.looks.summaryTitleY);
				scope font = new Font(d, dwtData(_prop.looks.summaryDescFont(skin.legacy)));
				gc.setFont(font);
				int hig = gc.getFontMetrics().getHeight();
				int x = _prop.looks.summaryDescXY.x;
				int y = _prop.looks.summaryDescXY.y;
				string desc = _desc();
				if (_comm.skin.legacy) { mixin(S_TRACE);
					foreach (line; splitLines!string(desc)) { mixin(S_TRACE);
						gc.wDrawText(line, x, y, SWT.DRAW_DELIMITER | SWT.DRAW_TRANSPARENT);
						y += _prop.looks.summaryDescLineHeightClassic;
					}
				} else { mixin(S_TRACE);
					gc.wDrawText(desc, x, y, SWT.DRAW_DELIMITER | SWT.DRAW_TRANSPARENT);
				}
				gc.setFont(null);
				font.dispose();
				drawCenterText(dwtData(_prop.looks.summaryPageFont(skin.legacy)),
					_prop.msgs.summaryPageDummy, _prop.looks.summaryPageY);
			}
			auto bx = (rect.width - size.width) / 2;
			auto by = (rect.height - size.height) / 2;
			e.gc.drawImage(buf, bx, by);
		}
	}

	this (Commons comm, Composite parent, int style) { mixin(S_TRACE);
		super (parent, style);
		_comm = comm;
		_prop = comm.prop;
		_summ = comm.summary;

		this.setLayout(new FillLayout());

		auto grp = new Group(this, SWT.NONE);
		grp.setLayoutData(new GridData(GridData.FILL_BOTH));
		grp.setText(_prop.msgs.summaryPreview);
		grp.setLayout(new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL));

		auto size = _prop.looks.summarySize;
		_summImage = new Canvas(grp, SWT.BORDER | SWT.DOUBLE_BUFFERED);
		_summImage.setLayoutData(_summImage.computeSize(size.width, size.height));
		_summImage.addPaintListener(new PListener);

		_comm.refSkin.add(&clearBuf);
		.listener(this, SWT.Dispose, { mixin(S_TRACE);
			_comm.refSkin.remove(&clearBuf);
			clearBuf();
		});
	}

	void setImageSelect(string delegate() sname, string[] delegate() imgPaths, Skin delegate() selectedSkin, string delegate() desc, int delegate() levMin, int delegate() levMax) { mixin(S_TRACE);
		_sname = sname;
		_imgPaths = imgPaths;
		_selectedSkin = selectedSkin;
		_desc = desc;
		_levMin = levMin;
		_levMax = levMax;
	}

	void redrawImage() { mixin(S_TRACE);
		_summImage.redraw();
	}

	void clearBuf() { mixin(S_TRACE);
		foreach (buf; _summImageBufs) {
			if (buf) buf.dispose();
		}
		_summImageBufs = [];
		_bufImagePaths = [];
	}
}
