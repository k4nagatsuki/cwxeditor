
module cwx.editor.gui.dwt.skintypesettings;

import cwx.background;
import cwx.menu;
import cwx.skin;
import cwx.structs;
import cwx.types;
import cwx.utils;

import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.areaview;
import cwx.editor.gui.dwt.areaviewutils;
import cwx.editor.gui.dwt.cardlist : cutText;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.undo;

static import std.algorithm;
import std.algorithm : filter, map, min;
import std.array;
import std.file;
import std.path;
import std.string;
import std.traits;
import std.typecons;

import org.eclipse.swt.all;

class SkinTypeChooser : Composite {
	void delegate()[] selectEvent;
	private void raiseSelectEvent() { mixin(S_TRACE);
		foreach (dlg; selectEvent) dlg();
	}

	private Commons _comm;
	private SettingsWithSkinType delegate() _createSettingsFromDefault;

	private Combo _type;
	private int _lastSelected;
	private Button _edit;
	private Button _add;
	private Button _del;
	private Button _clone;
	private bool delegate(bool del) _canSelect;

	private SettingsWithSkinType[] _settingsWithSkinTypes;

	this (Commons comm, Composite parent, int style, bool delegate(bool del) canSelect, SettingsWithSkinType delegate() createSettingsFromDefault) { mixin(S_TRACE);
		super (parent, style);
		_comm = comm;
		_canSelect = canSelect;
		_createSettingsFromDefault = createSettingsFromDefault;
		_settingsWithSkinTypes = _comm.prop.var.etc.settingsWithSkinTypes.dup;

		setLayout(zeroMarginGridLayout(3, false));

		auto l = new Label(this, SWT.NONE);
		l.setText(_comm.prop.msgs.selectSkinType);

		_type = new Combo(this, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
		_type.setVisibleItemCount(_comm.prop.var.etc.comboVisibleItemCount);
		_type.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));

		auto buttons = new Composite(this, SWT.NONE);
		buttons.setLayout(zeroMarginGridLayout(4, true));

		_edit = new Button(buttons, SWT.NONE);
		_edit.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		_edit.setImage(_comm.prop.images.menu(MenuID.EditProp));
		_edit.setText(MenuProps.buildMenu(_comm.prop.msgs.menuText(MenuID.EditProp), _comm.prop.var.menu.mnemonic(MenuID.EditProp), "", true));
		_comm.put(_edit, () => selected != -1);
		.listener(_edit, SWT.Selection, { mixin(S_TRACE);
			assert (selected != -1);
			auto excludeTypes = .map!(s => s.type)(_settingsWithSkinTypes).array();
			excludeTypes.remove(_settingsWithSkinTypes[selected].type);
			auto title = _comm.prop.msgs.editSkinTypeName;
			auto image = _comm.prop.images.menu(MenuID.EditProp);
			auto desc = _comm.prop.msgs.editSkinTypeNameDesc;
			auto dlg = new EditSkinTypeDialog(_comm, getShell(), title, image, desc, excludeTypes, _settingsWithSkinTypes[selected].type);
			if (dlg.open()) { mixin(S_TRACE);
				assert (selected != -1);
				_settingsWithSkinTypes[selected].type = dlg.type;
				sortTypes();
			}
		});

		_add = new Button(buttons, SWT.NONE);
		_add.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		_add.setImage(_comm.prop.images.menu(MenuID.AddItem));
		_add.setText(MenuProps.buildMenu(_comm.prop.msgs.menuText(MenuID.AddItem), _comm.prop.var.menu.mnemonic(MenuID.AddItem), "", true));
		_comm.put(_add, () => true);
		.listener(_add, SWT.Selection, { mixin(S_TRACE);
			auto excludeTypes = .map!(s => s.type)(_settingsWithSkinTypes).array();
			auto title = _comm.prop.msgs.addSkinType;
			auto image = _comm.prop.images.menu(MenuID.AddItem);
			auto desc = _comm.prop.msgs.addSkinTypeDesc;
			auto dlg = new EditSkinTypeDialog(_comm, getShell(), title, image, desc, excludeTypes, "");
			if (dlg.open()) { mixin(S_TRACE);
				assert (.cCountUntil(excludeTypes, dlg.type) == -1);
				_settingsWithSkinTypes.length += 1;
				_settingsWithSkinTypes[$ - 1].type = dlg.type;
				_type.add(dlg.type);
				if (_canSelect(false)) { mixin(S_TRACE);
					_type.select(_type.getItemCount() - 1);
				}
				sortTypes();
				raiseSelectEvent();
			}
		});

		_del = new Button(buttons, SWT.NONE);
		_del.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		_del.setImage(_comm.prop.images.menu(MenuID.DelItem));
		_del.setText(MenuProps.buildMenu(_comm.prop.msgs.menuText(MenuID.DelItem), _comm.prop.var.menu.mnemonic(MenuID.DelItem), "", false));
		_comm.put(_del, () => selected != -1);
		.listener(_del, SWT.Selection, { mixin(S_TRACE);
			if (!_canSelect(true)) { mixin(S_TRACE);
				return;
			}
			assert (selected != -1);
			auto dlg = new MessageBox(getShell(), SWT.ICON_QUESTION | SWT.YES | SWT.NO);
			dlg.setText(_comm.prop.msgs.delSkinType);
			dlg.setMessage(.tryFormat(_comm.prop.msgs.delSkinTypeDesc, _settingsWithSkinTypes[selected].type));
			if (SWT.YES == dlg.open()) { mixin(S_TRACE);
				assert (selected != -1);
				auto selected = this.selected;
				_settingsWithSkinTypes = std.algorithm.remove(_settingsWithSkinTypes, selected);
				_type.remove(selected + 1);
				_type.select(.min(selected + 1, _type.getItemCount() - 1));
				_lastSelected = _type.getSelectionIndex();
				raiseSelectEvent();
			}
		});

		_clone = new Button(buttons, SWT.NONE);
		_clone.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		_clone.setImage(_comm.prop.images.menu(MenuID.Clone));
		_clone.setText(MenuProps.buildMenu(_comm.prop.msgs.menuText(MenuID.Clone), _comm.prop.var.menu.mnemonic(MenuID.Clone), "", true));
		_comm.put(_clone, () => true);
		.listener(_clone, SWT.Selection, { mixin(S_TRACE);
			auto excludeTypes = .map!(s => s.type)(_settingsWithSkinTypes).array();
			auto title = _comm.prop.msgs.cloneSkinType;
			auto image = _comm.prop.images.menu(MenuID.Clone);
			auto desc = _comm.prop.msgs.cloneSkinTypeDesc;
			auto dlg = new EditSkinTypeDialog(_comm, getShell(), title, image, desc, excludeTypes, "");
			if (dlg.open()) { mixin(S_TRACE);
				assert (.cCountUntil(excludeTypes, dlg.type) == -1);
				if (selected == -1) { mixin(S_TRACE);
					_settingsWithSkinTypes ~= _createSettingsFromDefault();
				} else { mixin(S_TRACE);
					_settingsWithSkinTypes ~= _settingsWithSkinTypes[selected];
				}
				_settingsWithSkinTypes[$ - 1].type = dlg.type;
				_type.add(dlg.type);
				if (_canSelect(false)) { mixin(S_TRACE);
					_type.select(_type.getItemCount() - 1);
				}
				sortTypes();
				raiseSelectEvent();
			}
		});

		_type.add(_comm.prop.msgs.defaultSelection(_comm.prop.msgs.defaultSettings));
		foreach (ref s; _settingsWithSkinTypes) { mixin(S_TRACE);
			_type.add(s.type);
		}
		.listener(_type, SWT.Selection, { mixin(S_TRACE);
			if (_canSelect(false)) { mixin(S_TRACE);
				_lastSelected = _type.getSelectionIndex();
				raiseSelectEvent();
			} else { mixin(S_TRACE);
				_type.select(_lastSelected);
			}
		});
		_type.select(0);
		_lastSelected = 0;
	}

	private void sortTypes() { mixin(S_TRACE);
		auto index = selected;
		auto sel = _type.getText();

		int cmpType(ref const(SettingsWithSkinType) s1, ref const(SettingsWithSkinType) s2) { mixin(S_TRACE);
			if (_comm.prop.var.etc.logicalSort) { mixin(S_TRACE);
				return .ncmp(s1.type, s2.type);
			} else { mixin(S_TRACE);
				return .cmp(s1.type, s2.type);
			}
		}
		.sort!cmpType(_settingsWithSkinTypes);

		_type.removeAll();
		_type.add(_comm.prop.msgs.defaultSelection(_comm.prop.msgs.defaultSettings));
		foreach (i, ref s; _settingsWithSkinTypes) { mixin(S_TRACE);
			_type.add(s.type);
			if (index != -1 && s.type == sel) { mixin(S_TRACE);
				_type.select(_type.getItemCount() - 1);
			}
		}
		assert (_type.getSelectionIndex() != -1 || index == -1);
		if (index == -1) { mixin(S_TRACE);
			_type.select(0);
		}
		_lastSelected = _type.getSelectionIndex();
	}

	int selected() { mixin(S_TRACE);
		return _type.getSelectionIndex() - 1;
	}

	inout
	inout(SettingsWithSkinType)[] settingsWithSkinTypes() { return _settingsWithSkinTypes; }
}

class EditSkinTypeDialog : AbsDialog {
	private Commons _comm;

	private Combo _skinType;
	private bool[string] _excludeTypes;
	private string _desc;

	private string _type;

	this (Commons comm, Shell parent, string title, Image icon, string desc, in string[] excludeTypes, string defaultValue) { mixin(S_TRACE);
		_comm = comm;
		foreach (type; excludeTypes) _excludeTypes[type] = true;
		_type = defaultValue;
		_desc = desc;

		super (_comm.prop, parent, true, title, icon, true, _comm.prop.var.editSkinTypeDlg);
		enterClose = true;
	}

	override
	protected void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(new GridLayout(1, true));

		auto grp = new Group(area, SWT.NONE);
		grp.setText(_desc);
		grp.setLayoutData(new GridData(GridData.FILL_BOTH));
		grp.setLayout(new GridLayout(1, true));

		_skinType = new Combo(grp, SWT.DROP_DOWN | SWT.BORDER);
		_skinType.setVisibleItemCount(_comm.prop.var.etc.comboVisibleItemCount);
		.createTextMenu!Combo(_comm, _comm.prop, _skinType, &catchMod);
		_skinType.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		checker(_skinType, (combo) { mixin(S_TRACE);
			auto type = combo.getText();
			return type != "" && type !in _excludeTypes;
		});
		.listener(_skinType, SWT.Modify, { mixin(S_TRACE);
			if (ignoreMod) return;
			_type = _skinType.getText();
		});

		void refSkins() { mixin(S_TRACE);
			auto arr = .filter!(type => type !in _excludeTypes)(.findSkinTypes(_comm.prop)).array();
			.setComboItems(_skinType, arr);
		}
		refSkins();
		_comm.refSkin.add(&refSkins);
		_comm.refSortCondition.add(&refSkins);
		_comm.refClassicSkin.add(&refSkins);
		_comm.refSettingsWithSkinTypes.add(&refSkins);
		.listener(_skinType, SWT.Dispose, { mixin(S_TRACE);
			_comm.refSkin.remove(&refSkins);
			_comm.refSortCondition.remove(&refSkins);
			_comm.refClassicSkin.remove(&refSkins);
			_comm.refSettingsWithSkinTypes.remove(&refSkins);
		});

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		_skinType.setText(_type);
	}

	@property
	const
	string type() { return _type; }
}

class DefBgImgDialog : AbsDialog {
private:
	Commons _comm;
	Props _prop;
	Skin _skin;

	BgImageContainer _cont;
	BgImagesView _view;

public:
	this (Commons comm, Props prop, Shell shell, BgImageS[] bgImagesDefault, Skin skin) { mixin(S_TRACE);
		super(prop, shell, false, prop.msgs.dlgTitBgImagesDefault,
			prop.images.menu(MenuID.Settings), true, prop.var.defBgImagesDlg, true);
		_comm = comm;
		_prop = prop;
		_skin = skin;
		_cont = new BgImageContainer(createBgImages(skin, bgImagesDefault));
	}

	@property
	const
	override
	bool noScenario() { return true; }

	@property
	BgImageS[] backs() { mixin(S_TRACE);
		return createBgImageSs(_cont.backs);
	}

protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(1, false));
		{ mixin(S_TRACE);
			_view = createBgImagesViewAndMenu(_comm, _prop, null, _skin, null, _cont, area, null, _prop.var.etc.showInheritBackground, false);
			mod(_view);
			_view.setLayoutData(new GridData(GridData.FILL_BOTH));
		}
	}

	override bool apply() { mixin(S_TRACE);
		return true;
	}
}

class ElementOverrideView : Composite {
	void delegate()[] modEvent;
	void raiseModEvent() { mixin(S_TRACE);
		foreach (dlg; modEvent) dlg();
	}

	private Commons _comm;

	private UndoManager _undo;

	private Table _elements;
	private TableTextEdit _tte1;
	private TableTextEdit _tte2;

	private ElementOverride[[EnumMembers!Element].length] _list;

	private class UndoAll : Undo {
		private ElementOverride[[EnumMembers!Element].length] _list;
		this () { mixin(S_TRACE);
			_list[] = this.outer._list[];
		}
		private void impl() { mixin(S_TRACE);
			auto temp = this.outer._list[].dup;
			this.outer._list[] = _list[];
			_list[] = temp[];
			_elements.clearAll();
			raiseModEvent();
		}
		override void undo() { impl(); }
		override void redo() { impl(); }
		override void dispose() { }
	}
	private void store() { mixin(S_TRACE);
		_undo ~= new UndoAll();
	}

	this (Commons comm, Composite parent, int style) { mixin(S_TRACE);
		_comm = comm;

		super (parent, style);

		setLayout(zeroMarginGridLayout(1, true));

		_undo = new UndoManager(_comm.prop.var.etc.undoMaxEtc);
		void refUndoMax() { mixin(S_TRACE);
			_undo.max = _comm.prop.var.etc.undoMaxEtc;
		}
		_comm.refUndoMax.add(&refUndoMax);
		.listener(this, SWT.Dispose, { mixin(S_TRACE);
			_comm.refUndoMax.remove(&refUndoMax);
		});

		_elements = .rangeSelectableTable(this, SWT.SINGLE | SWT.FULL_SELECTION | SWT.BORDER | SWT.VIRTUAL);
		_elements.setLayoutData(new GridData(GridData.FILL_BOTH));

		_elements.setHeaderVisible(true);
		auto nameCol = new TableColumn(_elements, SWT.NONE);
		nameCol.setText(_comm.prop.msgs.elementOverrideName);
		auto targetTypeCol = new TableColumn(_elements, SWT.NONE);
		targetTypeCol.setText(_comm.prop.msgs.elementOverrideTargetType);
		.saveColumnWidth!("prop.var.etc.elementOverrideNameColumn")(_comm.prop, nameCol);
		.saveColumnWidth!("prop.var.etc.elementOverrideTargetTypeColumn")(_comm.prop, targetTypeCol);

		Tuple!(Image, "image", string, "path")[Element] imgTbl;
		.listener(_elements, SWT.SetData, (e) { mixin(S_TRACE);
			auto itm = cast(TableItem)e.item;
			auto eo = _list[e.index];

			itm.setImage(0, _comm.prop.elementImage(eo, imgTbl));

			auto name = _comm.prop.msgs.elementName(eo.element);
			auto p = eo.element in imgTbl;
			if (eo.name != "") { mixin(S_TRACE);
				name = eo.name;
			}
			itm.setText(0, name);

			auto targetType = "";
			final switch (eo.element) {
			case Element.All:
				targetType = _comm.prop.msgs.elementAllTargetType;
				break;
			case Element.Health:
				targetType = _comm.prop.msgs.undead;
				break;
			case Element.Mind:
				targetType = _comm.prop.msgs.automaton;
				break;
			case Element.Miracle:
				targetType = _comm.prop.msgs.unholy;
				break;
			case Element.Magic:
				targetType = _comm.prop.msgs.constructure;
				break;
			case Element.Fire:
			case Element.Ice:
				targetType = _comm.prop.msgs.elementWeaknessAndResistTargetType;
				break;
			}
			if (eo.targetType != "") { mixin(S_TRACE);
				targetType = eo.targetType;
			}
			itm.setText(1, targetType);
		});
		.listener(_elements, SWT.EraseItem, (e) { mixin(S_TRACE);
			auto itm = cast(TableItem)e.item;
			e.detail &= ~SWT.FOREGROUND;
		});
		.listener(_elements, SWT.PaintItem, (e) { mixin(S_TRACE);
			auto itm = cast(TableItem)e.item;
			auto index = _elements.indexOf(itm);
			auto eo = _list[index];
			auto column = e.index;
			auto image = itm.getImage(column);
			auto w = _elements.getColumn(column).getWidth();
			e.gc.setClipping(e.x, e.y, w, e.height);
			if (image) { mixin(S_TRACE);
				if (eo.icon == "") { mixin(S_TRACE);
					e.gc.setAlpha(128);
				}
				auto ib = itm.getImageBounds(column);
				e.gc.drawImage(image, ib.x, ib.y + (ib.height - image.getBounds().height) / 2);
				e.gc.setAlpha(255);
			}
			auto s = itm.getText(column);
			if (s != "") { mixin(S_TRACE);
				final switch (column) {
				case 0:
					if (eo.name == "") { mixin(S_TRACE);
						e.gc.setAlpha(160);
					}
					break;
				case 1:
					if (eo.targetType == "") { mixin(S_TRACE);
						e.gc.setAlpha(160);
					}
					break;
				}
				auto tb = itm.getTextBounds(column);
				s = .cutText(s, e.gc, tb.width);
				auto h = e.gc.wTextExtent("#").y;
				e.gc.drawText(s, tb.x, tb.y + (tb.height - h) / 2, true);
			}
		});
		.listener(_elements, SWT.Dispose, (e) { mixin(S_TRACE);
			foreach (t; imgTbl.byValue()) { mixin(S_TRACE);
				t.image.dispose();
			}
			imgTbl = null;
		});
		_elements.setItemCount(_list.length);
		foreach (i, el; EnumMembers!Element) { mixin(S_TRACE);
			_list[i].element = el;
		}

		void selectIcon() { mixin(S_TRACE);
			auto index = _elements.getSelectionIndex();
			assert (index != -1);
			string[] filterName = [_comm.prop.msgs.filterImage, _comm.prop.msgs.filterAll];
			string[] filter = [
				"*" ~ std.string.join(_comm.skin.extImage.dup, ";*"),
				"*"
			];
			auto icon = _list[index].icon;
			auto name = icon != "" && !icon.startsWith(PRESET_IMAGE_SCHEMA) ? _comm.prop.parent.toAppAbs(icon).baseName() : "";
			auto cwd = icon != "" && !icon.startsWith(PRESET_IMAGE_SCHEMA) ? _comm.prop.parent.toAppAbs(icon) : .getcwd();
			auto file = .selectFile(getShell(), filterName, filter, name, _comm.prop.msgs.selectElementIcon, cwd);
			if (file == "") return;
			store();
			auto rel = .abs2rel(file, _comm.prop.parent.appPath.dirName());
			if (!rel.isOuterPath()) { mixin(S_TRACE);
				file = rel;
			}
			_list[index].icon = file;
			_elements.clear(index);
			raiseModEvent();
		}
		void deleteIcon() { mixin(S_TRACE);
			auto index = _elements.getSelectionIndex();
			assert (index != -1);
			assert (_list[index].icon != "");
			store();
			_list[index].icon = "";
			_elements.clear(index);
			raiseModEvent();
		}

		auto menu = new Menu(getShell(), SWT.POP_UP);
		createMenuItem(_comm, menu, MenuID.Undo, { _undo.undo(); }, &_undo.canUndo);
		createMenuItem(_comm, menu, MenuID.Redo,  { _undo.redo(); }, &_undo.canRedo);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.SelectIcon, &selectIcon, () => _elements.getSelectionIndex() != -1);
		void delegate() dummy = null;
		auto selPresetMI = createMenuItem(_comm, menu, MenuID.SelectPresetIcon, dummy, () => _elements.getSelectionIndex() != -1, SWT.CASCADE);
		auto selPresetM = new Menu(selPresetMI);
		foreach (i, ref iconInfo; .presetIcons(_comm.prop)) { mixin(S_TRACE);
			void func(typeof(iconInfo) iconInfo) { mixin(S_TRACE);
				auto mnemonic = "";
				if (i < 10) {
					mnemonic = .format("%s", i);
				} else {
					mnemonic = .format("%s", cast(char)('A' + (i - 10)));
				}
				auto text = MenuProps.buildMenu(iconInfo.name, mnemonic, "", false);
				createMenuItem2(_comm, selPresetM, text, iconInfo.image, { mixin(S_TRACE);
					auto index = _elements.getSelectionIndex();
					assert (index != -1);
					auto file = PRESET_IMAGE_SCHEMA ~ iconInfo.file;
					store();
					_list[index].icon = file;
					_elements.clear(index);
					raiseModEvent();
				}, () => _elements.getSelectionIndex() != -1 && _list[_elements.getSelectionIndex()].icon != PRESET_IMAGE_SCHEMA ~ iconInfo.file);
			}
			func(iconInfo);
		}
		selPresetMI.setMenu(selPresetM);
		createMenuItem(_comm, menu, MenuID.DeleteIcon, &deleteIcon, () => _elements.getSelectionIndex() != -1 && _list[_elements.getSelectionIndex()].icon != "");
		_elements.setMenu(menu);

		void nameEditEnd(TableItem itm, int column, string newText) { mixin(S_TRACE);
			auto index = _elements.indexOf(itm);
			if (_list[index].name == newText) return;
			store();
			_list[index].name = newText;
			_elements.clear(index);
			raiseModEvent();
		}
		void targetTypeEditEnd(TableItem itm, int column, string newText) { mixin(S_TRACE);
			auto index = _elements.indexOf(itm);
			if (_list[index].targetType == newText) return;
			store();
			_list[index].targetType = newText;
			_elements.clear(index);
			raiseModEvent();
		}
		Control createNameEditor(TableItem itm, int editC) { mixin(S_TRACE);
			auto index = _elements.indexOf(itm);
			return createTextEditor(_comm, _comm.prop, itm.getParent(), _list[index].name);
		}
		Control createTargetTypeEditor(TableItem itm, int editC) { mixin(S_TRACE);
			auto index = _elements.indexOf(itm);
			return createTextEditor(_comm, _comm.prop, itm.getParent(), _list[index].targetType);
		}
		_tte1 = new TableTextEdit(_comm, _comm.prop, _elements, 0, &nameEditEnd, null, &createNameEditor);
		_tte2 = new TableTextEdit(_comm, _comm.prop, _elements, 1, &targetTypeEditEnd, (itm, column) { mixin(S_TRACE);
			final switch (_list[_elements.indexOf(itm)].element) {
			case Element.All:
				return false;
			case Element.Health:
			case Element.Mind:
			case Element.Miracle:
			case Element.Magic:
				return true;
			case Element.Fire:
			case Element.Ice:
				return false;
			}
		}, &createTargetTypeEditor);
	}

	const
	ElementOverride[] elementOverrides() { mixin(S_TRACE);
		return .filter!(eo => eo.icon != "" || eo.name != "" || eo.targetType != "")(_list[]).array().dup;
	}
	void elementOverrides(in ElementOverride[] list) { mixin(S_TRACE);
		if (_tte1 && _tte1.isEditing) _tte1.cancel();
		if (_tte2 && _tte2.isEditing) _tte2.cancel();
		_undo.reset();
		ElementOverride[Element] eTbl;
		foreach (ref eo; list) eTbl[eo.element] = eo;

		foreach (i, el; EnumMembers!Element) { mixin(S_TRACE);
			_list[i] = ElementOverride.init;
			_list[i].element = el;
			if (auto p = el in eTbl) _list[i] = *p;
		}
		_elements.setTopIndex(0);
		_elements.clearAll();
	}

	void enabled(bool enabled) { mixin(S_TRACE);
		_elements.setEnabled(enabled);
	}
	bool enabled() { return _elements.getEnabled(); }
}
