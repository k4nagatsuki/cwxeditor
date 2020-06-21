
module cwx.editor.gui.dwt.dprops;

import cwx.menu;
import cwx.msgs;
import cwx.props;
import cwx.structs;
import cwx.summary;
import cwx.types;
import cwx.utils;

import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.image;
import cwx.editor.gui.dwt.properties;

import std.algorithm : max, min;
import std.conv;
import std.file;
import std.path;
import std.typecons;

import org.eclipse.swt.all;

import java.lang.all;
import java.io.ByteArrayInputStream;
import java.nonstandard.Locale;

public class Props {
private:
	CProps _parent;
	Images _images;
	FlexProps _var;
public:
	this (string confFilePath, CProps parent) { mixin(S_TRACE);
		string dStr = .text(__LINE__);
		try { mixin(S_TRACE);
			_parent = parent;
			dStr ~= " - " ~ .text(__LINE__);
			_images = new Images(_parent.appPath);
			dStr ~= " - " ~ .text(__LINE__);
			_var = new FlexProps(_parent.appPath, confFilePath);
			dStr ~= " - " ~ .text(__LINE__);

			// システムの言語
			string[string] msgsTableFile;
			string defLocale;
			dStr ~= " - " ~ .text(__LINE__);
			auto msgsTable = _parent.msgsTable(var.etc.languageDir, msgsTableFile, defLocale);
			dStr ~= " - " ~ .text(__LINE__);
			auto msgs = msgsTable.get(.caltureName(), null);
			dStr ~= " - " ~ .text(__LINE__);
			if (msgs) { mixin(S_TRACE);
				_parent.msgs = msgs;
			}
			dStr ~= " - " ~ .text(__LINE__);

			// 設定された言語
			if (!var.etc.useSystemLanguage && var.etc.languageFile.length) { mixin(S_TRACE);
				dStr ~= " - " ~ .text(__LINE__);
				auto langFile = toAppAbs(var.etc.languageDir).buildPath(var.etc.languageFile);
				dStr ~= " - " ~ .text(__LINE__);
				if (.exists(langFile)) { mixin(S_TRACE);
					try { mixin(S_TRACE);
						dStr ~= " - " ~ .text(__LINE__);
						_parent.loadMsgs(langFile);
					} catch (Exception e) {
						printStackTrace();
						debugln(e);
					}
					dStr ~= " - " ~ .text(__LINE__);
				}
				dStr ~= " - " ~ .text(__LINE__);
			}
			dStr ~= " - " ~ .text(__LINE__);
		} catch (Throwable e) {
			printStackTrace();
			fdebugln(dStr);
			fdebugln(e);
			throw new Exception(dStr, __FILE__, __LINE__);
		}
	}
	@property
	const
	string enginePath() { mixin(S_TRACE);
		if (!var.etc.enginePath.length) return "";
		if (isAbsolute(var.etc.enginePath.value)) { mixin(S_TRACE);
			return var.etc.enginePath;
		} else { mixin(S_TRACE);
			return std.path.buildPath(std.path.dirName(parent.appPath), var.etc.enginePath);
		}
	}
	@property
	const
	string tempPath() { mixin(S_TRACE);
		if (!var.etc.tempPath.length) return "";
		if (isAbsolute(var.etc.tempPath.value)) { mixin(S_TRACE);
			return var.etc.tempPath;
		} else { mixin(S_TRACE);
			return std.path.buildPath(std.path.dirName(parent.appPath), var.etc.tempPath);
		}
	}
	@property
	const
	string backupPath() { mixin(S_TRACE);
		if (!var.etc.backupPath.length) return "";
		if (isAbsolute(var.etc.backupPath.value)) { mixin(S_TRACE);
			return var.etc.backupPath;
		} else { mixin(S_TRACE);
			return std.path.buildPath(std.path.dirName(parent.appPath), var.etc.backupPath);
		}
	}
	@property
	const
	string backupBeforeSavePath() { mixin(S_TRACE);
		if (!var.etc.backupBeforeSavePath.length) return "";
		if (isAbsolute(var.etc.backupBeforeSavePath.value)) { mixin(S_TRACE);
			return var.etc.backupBeforeSavePath;
		} else { mixin(S_TRACE);
			return std.path.buildPath(std.path.dirName(parent.appPath), var.etc.backupBeforeSavePath);
		}
	}
	@property
	const
	const(CProps) parent() { return _parent; }
	@property
	const
	const(cwx.system.System) sys() { return _parent.sys; }
	@property
	Images images() { return _images; }
	@property
	const
	const(Msgs) msgs() { return _parent.msgs; }
	@property
	const
	const(Looks) looks() { return _parent.looks; }
	@property
	FlexProps var() { return _var; }
	@property
	const
	const(FlexProps) var() { return _var; }

	const
	string toAppAbs(string path) { return parent.toAppAbs(path); }

	const
	string buildTool(MenuID id) { mixin(S_TRACE);
		return var.menu.buildTool(parent, id);
	}
	const
	string buildMenu(MenuID id) { mixin(S_TRACE);
		return var.menu.buildMenu(parent, id);
	}

	/// verがターゲットとなる環境のバージョン以下であればtrueを返す。
	const
	bool targetVersion(in Summary summ, string ver) { mixin(S_TRACE);
		if (summ && !summ.legacy) return true;
		return parent.targetVersion(ver, var.etc.targetVersion);
	}
	/// ditto
	const
	bool targetVersion(bool legacy, string ver) { mixin(S_TRACE);
		if (!legacy) return true;
		return parent.targetVersion(ver, var.etc.targetVersion);
	}
	/// summが存在する場合はwsnVer以上かを返す。
	/// それ以外の場合は対象バージョンがCardWirthPyか否かを返す。
	const
	bool isTargetVersion(in Summary summ, string ver) { mixin(S_TRACE);
		return parent.isTargetVersion(summ, var.etc.targetVersion, ver);
	}
	/// ditto
	bool isTargetVersion(bool legacy, string dataVersion, string wsnVer) { mixin(S_TRACE);
		return parent.isTargetVersion(legacy, dataVersion, wsnVer);
	}

	/// 拡大率に応じた値に変換する。
	const
	int s(int s) { mixin(S_TRACE);
		return s * .max(1u, var.etc.imageScale);
	}
	/// ditto
	const
	CInsets s(CInsets insets) { mixin(S_TRACE);
		insets.n = s(insets.n);
		insets.e = s(insets.e);
		insets.s = s(insets.s);
		insets.w = s(insets.w);
		return insets;
	}

	/// 描画拡大率を返す。
	@property
	const
	uint drawingScale() { mixin(S_TRACE);
		return .max(1u, .min(var.etc.imageScale, var.etc.drawingScale));
	}
	/// シナリオのイメージスケーリング有無に応じた描画拡大率を返す。
	const
	uint drawingScaleForImage(in Summary summ) { mixin(S_TRACE);
		return !summ || summ.loadScaledImage ? drawingScale : 1;
	}

	const
	int ds(int s) { mixin(S_TRACE);
		return s * drawingScale;
	}
	/// ditto
	const
	CPoint ds(CPoint point) { mixin(S_TRACE);
		point.x = ds(point.x);
		point.y = ds(point.y);
		return point;
	}
	/// ditto
	const
	CSize ds(CSize size) { mixin(S_TRACE);
		size.width = ds(size.width);
		size.height = ds(size.height);
		return size;
	}
	/// ditto
	const
	CRect ds(CRect rect) { mixin(S_TRACE);
		rect.x = ds(rect.x);
		rect.y = ds(rect.y);
		rect.width = ds(rect.width);
		rect.height = ds(rect.height);
		return rect;
	}
	/// ditto
	const
	CInsets ds(CInsets insets) { mixin(S_TRACE);
		insets.n = ds(insets.n);
		insets.e = ds(insets.e);
		insets.s = ds(insets.s);
		insets.w = ds(insets.w);
		return insets;
	}
	/// ditto
	const
	CFont ds(CFont font) { mixin(S_TRACE);
		font.point = ds(font.point);
		return font;
	}

	/// フォントが存在しない場合は代替フォントを選択する。
	const
	CFont adjustFont(in CFont font) { mixin(S_TRACE);
		CFont f = font;
		f.name = adjustFont(font.name);
		return f;
	}
	/// ditto
	const
	string adjustFont(string face) { mixin(S_TRACE);
		return Display.getCurrent().getFontList(face, true).length ? face : looks.alternativeFont(face);
	}

	/// スキンタイプに応じたデフォルト背景を返す。
	BgImageS[] bgImagesDefault(string type) { mixin(S_TRACE);
		foreach (ref stc; var.etc.settingsWithSkinTypes) { mixin(S_TRACE);
			if (stc.type == type && stc.overrideBgImages) return stc.bgImagesDefault;
		}
		return var.etc.bgImagesDefault;
	}
	/// スキンタイプに応じた背景の簡単設定を返す。
	BgImageSetting[] bgImageSettings(string type) { mixin(S_TRACE);
		foreach (ref stc; var.etc.settingsWithSkinTypes) { mixin(S_TRACE);
			if (stc.type == type && stc.overrideBgImages) return stc.bgImageSettings;
		}
		return var.etc.bgImageSettings;
	}
	/// スキンタイプに応じた標準選択肢を返す。
	string[] standardSelections(string type) { mixin(S_TRACE);
		foreach (ref stc; var.etc.settingsWithSkinTypes) { mixin(S_TRACE);
			if (stc.type == type && stc.overrideSelections) return stc.standardSelections;
		}
		return var.etc.standardSelections;
	}
	/// スキンタイプに応じた標準キーコードを返す。
	string[] standardKeyCodes(string type) { mixin(S_TRACE);
		foreach (ref stc; var.etc.settingsWithSkinTypes) { mixin(S_TRACE);
			if (stc.type == type && stc.overrideKeyCodes) return stc.standardKeyCodes;
		}
		return var.etc.standardKeyCodes;
	}
	/// スキンタイプに応じたカードの特徴に対応するキーコードを返す。
	KeyCodeByFeature[] keyCodesByFeatures(string type) { mixin(S_TRACE);
		foreach (ref stc; var.etc.settingsWithSkinTypes) { mixin(S_TRACE);
			if (stc.type == type && stc.overrideKeyCodes) return stc.keyCodesByFeatures;
		}
		return var.etc.keyCodesByFeatures;
	}
	/// スキンタイプに応じた効果に対応するキーコードを返す。
	KeyCodeByMotion[] keyCodesByMotions(string type) { mixin(S_TRACE);
		foreach (ref stc; var.etc.settingsWithSkinTypes) { mixin(S_TRACE);
			if (stc.type == type && stc.overrideKeyCodes) return stc.keyCodesByMotions;
		}
		return var.etc.keyCodesByMotions;
	}
	/// スキンタイプに応じた効果属性設定を返す。
	ElementOverride[Element] elementOverrides(string type) { mixin(S_TRACE);
		foreach (ref stc; var.etc.settingsWithSkinTypes) { mixin(S_TRACE);
			if (stc.type == type) { mixin(S_TRACE);
				ElementOverride[Element] eTbl;
				foreach (ref eo; stc.elementOverrides) eTbl[eo.element] = eo;
				return eTbl;
			}
		}
		return null;
	}
	/// 効果属性のアイコンを返す。
	ImageData elementImage(in ElementOverride[Element] eTbl, Element element) { mixin(S_TRACE);
		auto p = element in eTbl;
		return p ? elementImage(*p) : images.element(element).getImageData();
	}
	/// ditto
	ImageData elementImage(in ElementOverride eo) { mixin(S_TRACE);
		ImageData r = null;
		if (eo.icon != "") { mixin(S_TRACE);
			if (eo.icon.startsWith(PRESET_IMAGE_SCHEMA)) { mixin(S_TRACE);
				switch (eo.icon[PRESET_IMAGE_SCHEMA.length .. $]) {
				case "elm_all.png":
					return images.element(Element.All).getImageData();
				case "elm_health.png":
					return images.element(Element.Health).getImageData();
				case "elm_mind.png":
					return images.element(Element.Mind).getImageData();
				case "elm_miracle.png":
					return images.element(Element.Miracle).getImageData();
				case "elm_magic.png":
					return images.element(Element.Magic).getImageData();
				case "elm_fire.png":
					return images.element(Element.Fire).getImageData();
				case "elm_ice.png":
					return images.element(Element.Ice).getImageData();
				case "elm_hearing.png":
					return images.elementHearing.getImageData();
				case "elm_vision.png":
					return images.elementVision.getImageData();
				case "elm_electronic.png":
					return images.elementElectronic.getImageData();
				default:
					break;
				}
			} else { mixin(S_TRACE);
				try {
					auto path = toAppAbs(eo.icon);
					if (.exists(path) && .isFile(path)) { mixin(S_TRACE);
						auto info = .findScaledImage(path, .dpiMuls);
						byte* ptr = null;
						auto bin = readBinaryFrom!byte(info.path, ptr);
						scope (exit) freeAll(ptr);
						auto s = new ByteArrayInputStream(bin);
						scope (exit) s.close();
						auto imgData = new ImageData(s);
						imgData.transparentPixel = imgData.getPixel(0, 0);
						r = (new ImageDataWithScale(imgData, info.scale)).scaled(.dpiMuls);
					}
				} catch (Exception e) {
					printStackTrace();
					debugln(e);
				}
			}
		}
		return r ? r : images.element(eo.element).getImageData();
	}
}

enum PRESET_IMAGE_SCHEMA = "presetimage://";

alias Tuple!(string, "file", string, "name", Image, "image") PresetImageInfo;
PresetImageInfo[] presetIcons(Props prop) { mixin(S_TRACE);
	return [
		PresetImageInfo("elm_all.png", prop.msgs.elementName(Element.All), prop.images.element(Element.All)),
		PresetImageInfo("elm_health.png", prop.msgs.elementName(Element.Health), prop.images.element(Element.Health)),
		PresetImageInfo("elm_mind.png", prop.msgs.elementName(Element.Mind), prop.images.element(Element.Mind)),
		PresetImageInfo("elm_miracle.png", prop.msgs.elementName(Element.Miracle), prop.images.element(Element.Miracle)),
		PresetImageInfo("elm_magic.png", prop.msgs.elementName(Element.Magic), prop.images.element(Element.Magic)),
		PresetImageInfo("elm_fire.png", prop.msgs.elementName(Element.Fire), prop.images.element(Element.Fire)),
		PresetImageInfo("elm_ice.png", prop.msgs.elementName(Element.Ice), prop.images.element(Element.Ice)),
		PresetImageInfo("elm_hearing.png", prop.msgs.elementNameHearing, prop.images.elementHearing),
		PresetImageInfo("elm_vision.png", prop.msgs.elementNameVision, prop.images.elementVision),
		PresetImageInfo("elm_electronic.png", prop.msgs.elementNameElectronic, prop.images.elementElectronic),
	];
}

/// CPoint等の構造体をSWTのクラスに変換するための関数。
Point dwtData(CPoint v) { return new Point(v.x, v.y); }
/// ditto
Point dwtData(CSize v) { return new Point(v.width, v.height); }
/// ditto
RGB dwtData(CRGB v, out int alpha) { mixin(S_TRACE);
	alpha = v.a;
	return new RGB(cast(int) v.r, cast(int) v.g, cast(int) v.b);
}
/// ditto
FontData dwtData(CFont v) { mixin(S_TRACE);
	int flag = SWT.NONE;
	if (v.bold) flag |= SWT.BOLD;
	if (v.italic) flag |= SWT.ITALIC;
	return new FontData(v.name, cast(int) v.point, flag == SWT.NONE ? SWT.NORMAL : flag);
}
