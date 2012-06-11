
module cwx.menu;

import cwx.xml;
import cwx.props;
import cwx.utils;
import cwx.event;
import cwx.settings;

import std.array;
import std.string;
import std.traits;

/// メニューのID。
enum MenuID {
	None = 0,

	File,
	Edit,
	View,
	Tool,
	Table,
	Variable,
	Help,
	Card,
	CardsAndBacks,

	DelNotUsedFile,
	ClosePane,
	ClosePaneExcept,
	ClosePaneLeft,
	ClosePaneRight,
	ClosePaneAll,
	New,
	Open,
	NewAtNewWindow,
	OpenAtNewWindow,
	Close,
	CloseWin,
	Save,
	SaveAs,
	Reload,
	OpenDir,
	OpenPlace,
	SaveImage,
	LookImages,
	ChangeVH,
	Find,
	IncSearch,
	EditProp,
	Refresh,
	Undo,
	Redo,
	Cut,
	Copy,
	Paste,
	Delete,
	SelectAll,
	ToXMLText,
	TableView,
	VarView,
	CardView,
	CastView,
	SkillView,
	ItemView,
	BeastView,
	InfoView,
	FileView,
	ExecEngine,
	ExecEngineAuto,
	ExecEngineMain,
	OuterTools,
	Settings,
	VersionInfo,
	LockToolBar,
	ResetToolBar,
	CopyAsText,
	OpenAtView,
	StartToPackage,
	ConvertContent,
	CGroupTerminal,
	CGroupStandard,
	CGroupData,
	CGroupUtility,
	CGroupBranch,
	CGroupGet,
	CGroupLost,
	CGroupVisual,
	EditSummary,
	NewArea,
	NewBattle,
	NewPackage,
	ReNumberingAll,
	ReNumbering,
	EditScene,
	EditEvent,
	NewFlagDir,
	NewFlag,
	NewStep,
	Up,
	Down,
	ShowParty,
	ShowMsg,
	ShowRefCards,
	FixedImage,
	ShowEnemyCardProp,
	ShowCard,
	ShowBack,
	NewMenuCard,
	NewEnemyCard,
	NewBack,
	AutoArrange,
	ManualArrange,
	Mask,
	Escape,
	PosTop,
	PosBottom,
	PosLeft,
	PosRight,
	PosEven,
	ScaleMin,
	ScaleMiddle,
	ScaleMax,
	ScaleBig,
	ScaleSmall,
	StopBGM,
	PlayBGM,
	KeyCodeTiming,
	KeyCodeTimingUse,
	KeyCodeTimingSuccess,
	KeyCodeTimingFailure,
	AddRangeOfRound,
	OpenAtTableView,
	OpenAtVarView,
	OpenAtCardView,
	OpenAtFileView,
	OpenAtEventView,
	Comment,
	ShowCardProp,
	ShowCardImage,
	ShowCardDetail,
	OpenImportSource,
	NewCast,
	NewSkill,
	NewItem,
	NewBeast,
	NewInfo,
	Import,
	OpenHand,
	EditEventAtTimeOfUsing,
	PlaySE,
	StopSE,
	NewDir,
	CopyFilePath,
	ReplFilePath,
	CreateArchive,
	ToScript,
	ToScriptAll,
	EvTemplates,
}

/// エディタのメニュー。
class MenuProps : Properties {
	immutable XML_NAME = "menu";

	private string[] _mnemonic;
	private immutable string[] _mnemonic_init;
	private string[] _hotkey;
	private immutable string[] _hotkey_init;

	/// 唯一のコンストラクタ。
	this () {
		_mnemonic.length = MenuID.max + 1;
		_hotkey.length = MenuID.max + 1;

		_mnemonic[MenuID.None] = "";

		_mnemonic[MenuID.File] = "F";
		_mnemonic[MenuID.Edit] = "E";
		_mnemonic[MenuID.View] = "V";
		_mnemonic[MenuID.Tool] = "T";
		_mnemonic[MenuID.Table] = "B";
		_mnemonic[MenuID.Variable] = "R";
		_mnemonic[MenuID.Help] = "H";
		_mnemonic[MenuID.Card] = "C";
		_mnemonic[MenuID.CardsAndBacks] = "A";
		_mnemonic[MenuID.DelNotUsedFile] = "E";
		_mnemonic[MenuID.ClosePane] = "C";
		_mnemonic[MenuID.ClosePaneExcept] = "W";
		_mnemonic[MenuID.ClosePaneLeft] = "L";
		_mnemonic[MenuID.ClosePaneRight] = "R";
		_mnemonic[MenuID.ClosePaneAll] = "A";
		_mnemonic[MenuID.New] = "N";
		_mnemonic[MenuID.Open] = "O";
		_mnemonic[MenuID.NewAtNewWindow] = "E";
		_mnemonic[MenuID.OpenAtNewWindow] = "P";
		_mnemonic[MenuID.Close] = "C";
		_mnemonic[MenuID.CloseWin] = "C";
		_mnemonic[MenuID.Save] = "S";
		_mnemonic[MenuID.SaveAs] = "A";
		_mnemonic[MenuID.Reload] = "R";
		_mnemonic[MenuID.OpenDir] = "O";
		_mnemonic[MenuID.OpenPlace] = "O";
		_mnemonic[MenuID.SaveImage] = "I";
		_mnemonic[MenuID.LookImages] = "L";
		_mnemonic[MenuID.ChangeVH] = "H";
		_mnemonic[MenuID.Find] = "F";
		_mnemonic[MenuID.IncSearch] = "W";
		_mnemonic[MenuID.EditProp] = "E";
		_mnemonic[MenuID.Refresh] = "R";
		_mnemonic[MenuID.Undo] = "U";
		_mnemonic[MenuID.Redo] = "R";
		_mnemonic[MenuID.Cut] = "T";
		_mnemonic[MenuID.Copy] = "C";
		_mnemonic[MenuID.Paste] = "P";
		_mnemonic[MenuID.Delete] = "D";
		_mnemonic[MenuID.SelectAll] = "A";
		_mnemonic[MenuID.ToXMLText] = "X";
		_mnemonic[MenuID.TableView] = "D";
		_mnemonic[MenuID.VarView] = "V";
		_mnemonic[MenuID.CardView] = "W";
		_mnemonic[MenuID.CastView] = "C";
		_mnemonic[MenuID.SkillView] = "S";
		_mnemonic[MenuID.ItemView] = "I";
		_mnemonic[MenuID.BeastView] = "B";
		_mnemonic[MenuID.InfoView] = "N";
		_mnemonic[MenuID.FileView] = "F";
		_mnemonic[MenuID.ExecEngine] = "G";
		_mnemonic[MenuID.ExecEngineAuto] = "G";
		_mnemonic[MenuID.ExecEngineMain] = "P";
		_mnemonic[MenuID.OuterTools] = "T";
		_mnemonic[MenuID.Settings] = "O";
		_mnemonic[MenuID.VersionInfo] = "A";
		_mnemonic[MenuID.LockToolBar] = "L";
		_mnemonic[MenuID.ResetToolBar] = "R";
		_mnemonic[MenuID.CopyAsText] = "C";
		_mnemonic[MenuID.OpenAtView] = "V";
		_mnemonic[MenuID.StartToPackage] = "G";
		_mnemonic[MenuID.ConvertContent] = "O";
		_mnemonic[MenuID.CGroupTerminal] = "T";
		_mnemonic[MenuID.CGroupStandard] = "S";
		_mnemonic[MenuID.CGroupData] = "D";
		_mnemonic[MenuID.CGroupUtility] = "U";
		_mnemonic[MenuID.CGroupBranch] = "B";
		_mnemonic[MenuID.CGroupGet] = "G";
		_mnemonic[MenuID.CGroupLost] = "L";
		_mnemonic[MenuID.CGroupVisual] = "V";
		_mnemonic[MenuID.EditSummary] = "M";
		_mnemonic[MenuID.NewArea] = "A";
		_mnemonic[MenuID.NewBattle] = "B";
		_mnemonic[MenuID.NewPackage] = "K";
		_mnemonic[MenuID.ReNumberingAll] = "A";
		_mnemonic[MenuID.ReNumbering] = "B";
		_mnemonic[MenuID.EditScene] = "S";
		_mnemonic[MenuID.EditEvent] = "N";
		_mnemonic[MenuID.NewFlagDir] = "N";
		_mnemonic[MenuID.NewFlag] = "F";
		_mnemonic[MenuID.NewStep] = "S";
		_mnemonic[MenuID.Up] = "K";
		_mnemonic[MenuID.Down] = "J";
		_mnemonic[MenuID.ShowParty] = "P";
		_mnemonic[MenuID.ShowMsg] = "M";
		_mnemonic[MenuID.ShowRefCards] = "R";
		_mnemonic[MenuID.FixedImage] = "F";
		_mnemonic[MenuID.ShowEnemyCardProp] = "L";
		_mnemonic[MenuID.ShowCard] = "V";
		_mnemonic[MenuID.ShowBack] = "I";
		_mnemonic[MenuID.NewMenuCard] = "C";
		_mnemonic[MenuID.NewEnemyCard] = "C";
		_mnemonic[MenuID.NewBack] = "B";
		_mnemonic[MenuID.AutoArrange] = "A";
		_mnemonic[MenuID.ManualArrange] = "U";
		_mnemonic[MenuID.Mask] = "M";
		_mnemonic[MenuID.Escape] = "E";
		_mnemonic[MenuID.PosTop] = "K";
		_mnemonic[MenuID.PosBottom] = "J";
		_mnemonic[MenuID.PosLeft] = "H";
		_mnemonic[MenuID.PosRight] = "L";
		_mnemonic[MenuID.PosEven] = "E";
		_mnemonic[MenuID.ScaleMin] = "S";
		_mnemonic[MenuID.ScaleMiddle] = "I";
		_mnemonic[MenuID.ScaleMax] = "G";
		_mnemonic[MenuID.ScaleBig] = "R";
		_mnemonic[MenuID.ScaleSmall] = "N";
		_mnemonic[MenuID.StopBGM] = "P";
		_mnemonic[MenuID.PlayBGM] = "P";
		_mnemonic[MenuID.KeyCodeTiming] = "K";
		_mnemonic[MenuID.KeyCodeTimingUse] = "U";
		_mnemonic[MenuID.KeyCodeTimingSuccess] = "S";
		_mnemonic[MenuID.KeyCodeTimingFailure] = "F";
		_mnemonic[MenuID.AddRangeOfRound] = "R";
		_mnemonic[MenuID.OpenAtTableView] = "V";
		_mnemonic[MenuID.OpenAtVarView] = "V";
		_mnemonic[MenuID.OpenAtCardView] = "V";
		_mnemonic[MenuID.OpenAtFileView] = "V";
		_mnemonic[MenuID.OpenAtEventView] = "V";
		_mnemonic[MenuID.Comment] = "M";
		_mnemonic[MenuID.ShowCardProp] = "L";
		_mnemonic[MenuID.ShowCardImage] = "R";
		_mnemonic[MenuID.ShowCardDetail] = "D";
		_mnemonic[MenuID.OpenImportSource] = "A";
		_mnemonic[MenuID.NewCast] = "C";
		_mnemonic[MenuID.NewSkill] = "S";
		_mnemonic[MenuID.NewItem] = "I";
		_mnemonic[MenuID.NewBeast] = "B";
		_mnemonic[MenuID.NewInfo] = "F";
		_mnemonic[MenuID.Import] = "A";
		_mnemonic[MenuID.OpenHand] = "H";
		_mnemonic[MenuID.EditEventAtTimeOfUsing] = "N";
		_mnemonic[MenuID.PlaySE] = "P";
		_mnemonic[MenuID.StopSE] = "S";
		_mnemonic[MenuID.NewDir] = "I";
		_mnemonic[MenuID.CopyFilePath] = "M";
		_mnemonic[MenuID.ReplFilePath] = "R";
		_mnemonic[MenuID.CreateArchive] = "V";
		_mnemonic[MenuID.ToScript] = "S";
		_mnemonic[MenuID.ToScriptAll] = "Y";
		_mnemonic[MenuID.EvTemplates] = "";

		_hotkey[MenuID.None] = "";
		_hotkey[MenuID.File] = "";
		_hotkey[MenuID.Edit] = "";
		_hotkey[MenuID.View] = "";
		_hotkey[MenuID.Tool] = "";
		_hotkey[MenuID.Table] = "";
		_hotkey[MenuID.Variable] = "";
		_hotkey[MenuID.Help] = "";
		_hotkey[MenuID.Card] = "";
		_hotkey[MenuID.CardsAndBacks] = "";
		_hotkey[MenuID.DelNotUsedFile] = "";
		_hotkey[MenuID.ClosePane] = "";
		_hotkey[MenuID.ClosePaneExcept] = "";
		_hotkey[MenuID.ClosePaneLeft] = "";
		_hotkey[MenuID.ClosePaneRight] = "";
		_hotkey[MenuID.ClosePaneAll] = "";
		_hotkey[MenuID.New] = "Ctrl+N";
		_hotkey[MenuID.Open] = "Ctrl+O";
		_hotkey[MenuID.NewAtNewWindow] = "";
		_hotkey[MenuID.OpenAtNewWindow] = "";
		_hotkey[MenuID.Close] = "";
		_hotkey[MenuID.CloseWin] = "";
		_hotkey[MenuID.Save] = "Ctrl+S";
		_hotkey[MenuID.SaveAs] = "";
		_hotkey[MenuID.Reload] = "";
		_hotkey[MenuID.OpenDir] = "";
		_hotkey[MenuID.OpenPlace] = "";
		_hotkey[MenuID.SaveImage] = "";
		_hotkey[MenuID.LookImages] = "";
		_hotkey[MenuID.ChangeVH] = "";
		_hotkey[MenuID.Find] = "Ctrl+F";
		_hotkey[MenuID.IncSearch] = "Ctrl+I";
		_hotkey[MenuID.EditProp] = "Enter";
		_hotkey[MenuID.Refresh] = "F5";
		_hotkey[MenuID.Undo] = "Ctrl+Z";
		_hotkey[MenuID.Redo] = "Ctrl+Y";
		_hotkey[MenuID.Cut] = "Ctrl+X";
		_hotkey[MenuID.Copy] = "Ctrl+C";
		_hotkey[MenuID.Paste] = "Ctrl+V";
		_hotkey[MenuID.Delete] = "Delete";
		_hotkey[MenuID.SelectAll] = "Ctrl+A";
		_hotkey[MenuID.ToXMLText] = "";
		_hotkey[MenuID.TableView] = "";
		_hotkey[MenuID.VarView] = "";
		_hotkey[MenuID.CardView] = "";
		_hotkey[MenuID.CastView] = "";
		_hotkey[MenuID.SkillView] = "";
		_hotkey[MenuID.ItemView] = "";
		_hotkey[MenuID.BeastView] = "";
		_hotkey[MenuID.InfoView] = "";
		_hotkey[MenuID.FileView] = "";
		_hotkey[MenuID.ExecEngine] = "";
		_hotkey[MenuID.ExecEngineAuto] = "F9";
		_hotkey[MenuID.ExecEngineMain] = "";
		_hotkey[MenuID.OuterTools] = "";
		_hotkey[MenuID.Settings] = "";
		_hotkey[MenuID.VersionInfo] = "";
		_hotkey[MenuID.LockToolBar] = "";
		_hotkey[MenuID.ResetToolBar] = "";
		_hotkey[MenuID.CopyAsText] = "Ctrl+C";
		_hotkey[MenuID.OpenAtView] = "";
		_hotkey[MenuID.StartToPackage] = "";
		_hotkey[MenuID.ConvertContent] = "";
		_hotkey[MenuID.CGroupTerminal] = "";
		_hotkey[MenuID.CGroupStandard] = "";
		_hotkey[MenuID.CGroupData] = "";
		_hotkey[MenuID.CGroupUtility] = "";
		_hotkey[MenuID.CGroupBranch] = "";
		_hotkey[MenuID.CGroupGet] = "";
		_hotkey[MenuID.CGroupLost] = "";
		_hotkey[MenuID.CGroupVisual] = "";
		_hotkey[MenuID.EditSummary] = "";
		_hotkey[MenuID.NewArea] = "";
		_hotkey[MenuID.NewBattle] = "";
		_hotkey[MenuID.NewPackage] = "";
		_hotkey[MenuID.ReNumberingAll] = "";
		_hotkey[MenuID.ReNumbering] = "";
		_hotkey[MenuID.EditScene] = "F3";
		_hotkey[MenuID.EditEvent] = "F4";
		_hotkey[MenuID.NewFlagDir] = "";
		_hotkey[MenuID.NewFlag] = "Ctrl+L";
		_hotkey[MenuID.NewStep] = "Ctrl+P";
		_hotkey[MenuID.Up] = "Ctrl+Arrow_Up";
		_hotkey[MenuID.Down] = "Ctrl+Arrow_Down";
		_hotkey[MenuID.ShowParty] = "";
		_hotkey[MenuID.ShowMsg] = "";
		_hotkey[MenuID.ShowRefCards] = "";
		_hotkey[MenuID.FixedImage] = "";
		_hotkey[MenuID.ShowEnemyCardProp] = "";
		_hotkey[MenuID.ShowCard] = "";
		_hotkey[MenuID.ShowBack] = "";
		_hotkey[MenuID.NewMenuCard] = "";
		_hotkey[MenuID.NewEnemyCard] = "";
		_hotkey[MenuID.NewBack] = "";
		_hotkey[MenuID.AutoArrange] = "";
		_hotkey[MenuID.ManualArrange] = "";
		_hotkey[MenuID.Mask] = "";
		_hotkey[MenuID.Escape] = "";
		_hotkey[MenuID.PosTop] = "";
		_hotkey[MenuID.PosBottom] = "";
		_hotkey[MenuID.PosLeft] = "";
		_hotkey[MenuID.PosRight] = "";
		_hotkey[MenuID.PosEven] = "";
		_hotkey[MenuID.ScaleMin] = "";
		_hotkey[MenuID.ScaleMiddle] = "";
		_hotkey[MenuID.ScaleMax] = "";
		_hotkey[MenuID.ScaleBig] = "";
		_hotkey[MenuID.ScaleSmall] = "";
		_hotkey[MenuID.StopBGM] = "";
		_hotkey[MenuID.PlayBGM] = "";
		_hotkey[MenuID.KeyCodeTiming] = "";
		_hotkey[MenuID.KeyCodeTimingUse] = "";
		_hotkey[MenuID.KeyCodeTimingSuccess] = "";
		_hotkey[MenuID.KeyCodeTimingFailure] = "";
		_hotkey[MenuID.AddRangeOfRound] = "";
		_hotkey[MenuID.OpenAtTableView] = "";
		_hotkey[MenuID.OpenAtVarView] = "";
		_hotkey[MenuID.OpenAtCardView] = "";
		_hotkey[MenuID.OpenAtFileView] = "";
		_hotkey[MenuID.OpenAtEventView] = "";
		_hotkey[MenuID.Comment] = "Ctrl+M";
		_hotkey[MenuID.ShowCardProp] = "";
		_hotkey[MenuID.ShowCardImage] = "";
		_hotkey[MenuID.ShowCardDetail] = "";
		_hotkey[MenuID.OpenImportSource] = "";
		_hotkey[MenuID.NewCast] = "";
		_hotkey[MenuID.NewSkill] = "";
		_hotkey[MenuID.NewItem] = "";
		_hotkey[MenuID.NewBeast] = "";
		_hotkey[MenuID.NewInfo] = "";
		_hotkey[MenuID.Import] = "Ctrl+I";
		_hotkey[MenuID.OpenHand] = "";
		_hotkey[MenuID.EditEventAtTimeOfUsing] = "";
		_hotkey[MenuID.PlaySE] = "";
		_hotkey[MenuID.StopSE] = "";
		_hotkey[MenuID.NewDir] = "";
		_hotkey[MenuID.CopyFilePath] = "";
		_hotkey[MenuID.ReplFilePath] = "";
		_hotkey[MenuID.CreateArchive] = "";
		_hotkey[MenuID.ToScript] = "Ctrl+G";
		_hotkey[MenuID.ToScriptAll] = "Ctrl+B";
		_hotkey[MenuID.EvTemplates] = "";

		_mnemonic_init = _mnemonic.idup;
		_hotkey_init = _hotkey.idup;
	}

	/// アクセスキー。
	const
	string mnemonic(MenuID id) {
		return _mnemonic[id];
	}
	/// ditto
	void mnemonic(MenuID id, string key) {
		_mnemonic[id] = key;
	}
	/// ショートカットキー。
	const
	string hotkey(MenuID id) {
		return _hotkey[id];
	}
	/// ditto
	void hotkey(MenuID id, string key) {
		_hotkey[id] = key;
	}

	/// ツール文字列を構築する。
	const
	string buildTool(in CProps prop, MenuID id) {
		string r = prop.msgs.menuText(id);
		if (isPMenu(id)) {
			r ~= "...";
		}
		return r;
	}

	/// メニュー文字列を構築する。
	const
	string buildMenu(in CProps prop, MenuID id) {
		return buildMenu(prop, id, _mnemonic[id], _hotkey[id]);
	}
	/// ditto
	static string buildMenu(in CProps prop, MenuID id, string mnemonic, string hotkey) {
		return buildMenu(prop.msgs.menuText(id), mnemonic, hotkey, isPMenu(id));
	}
	/// ditto
	static string buildMenu(string r, string mnemonic, string hotkey, bool m) {
		r = r.replace("&", "&&");
		string a = mnemonic;
		string h = hotkey;
		if (a.length) {
			int i = r.indexOf(a, CaseSensitive.no);
			if (-1 == i) {
				r ~= "(&" ~ a ~ ")";
			} else {
				r = r[0 .. i] ~ "&" ~ r[i .. $];
			}
		}
		if (m) {
			r ~= "...";
		}
		if (h.length) r ~= "\t" ~ h;
		return r;
	}
	/// ditto
	const
	string buildMenuSample(in CProps prop, MenuID id) {
		return buildMenuSample(prop, id, _mnemonic[id], _hotkey[id]);
	}
	/// ditto
	static string buildMenuSample(in CProps prop, MenuID id, string mnemonic, string hotkey) {
		string r = prop.msgs.menuText(id);
		if (MenuID.StopBGM is id) {
			// 唯一パラメータを持つメニューテキスト
			r = .tryFormat(r, prop.msgs.bgm);
		}
		return buildMenuSample(r, mnemonic, hotkey, isPMenu(id));
	}
	/// ditto
	static string buildMenuSample(string r, string mnemonic, string hotkey, bool m) {
		string a = mnemonic;
		string h = hotkey;
		if (a.length) {
			int i = r.indexOf(a, CaseSensitive.no);
			if (-1 == i) {
				r ~= "(&" ~ a ~ ")";
			} else {
				r = r[0 .. i] ~ "&" ~ r[i .. $];
			}
		}
		if (m) {
			r ~= "...";
		}
		if (h.length) r ~= " " ~ h;
		return r;
	}

	/// XMLノードとして取り扱うための関数群。
	const
	XNode toNode() {
		auto e = XNode.create(XML_NAME);
		toNodeImpl(e);
		return e;
	}
	/// ditto
	const
	void toNode(ref XNode node) {
		auto e = node.newElement(XML_NAME);
		toNodeImpl(e);
	}
	/// ditto
	const
	private void toNodeImpl(ref XNode e) {
		foreach (id; EnumMembers!MenuID) {
			if (isNoKeyBindMenu(id)) continue;
			string a = _mnemonic[id];
			string h = _hotkey[id];
			string ainit = _mnemonic_init[id];
			string hinit = _hotkey_init[id];
			if (a != ainit || h != hinit) {
				auto me = e.newElement("menuItem");
				me.newAttr("name", enumToString(id));
				if (a != ainit) {
					me.newAttr("mnemonic", a);
				}
				if (h != hinit) {
					me.newAttr("hotkey", h);
				}
			}
		}
	}
	/// ditto
	static MenuProps fromNode(ref XNode node) {
		auto r = new MenuProps;
		node.onTag["menu"] = (ref XNode node) {
			node.onTag["menuItem"] = (ref XNode me) {
				auto id = stringToEnum!MenuID(me.attr!string("name", true));
				if (isNoKeyBindMenu(id)) return;
				auto a = me.attr!string("mnemonic", false, null);
				auto h = me.attr!string("hotkey", false, null);
				if (a) r._mnemonic[id] = a;
				if (h) r._hotkey[id] = h;
			};
			node.parse();
		};
		node.parse();
		return r;
	}
}

/// 継続操作が必要なメニューか。
/// 該当するメニューのテキストには"..."が付加される。
bool isPMenu(MenuID id) {
	switch (id) {
	case MenuID.New:
	case MenuID.Open:
	case MenuID.NewAtNewWindow:
	case MenuID.OpenAtNewWindow:
	case MenuID.SaveAs:
	case MenuID.Find:
	case MenuID.Settings:
	case MenuID.EditSummary:
	case MenuID.NewFlagDir:
	case MenuID.NewFlag:
	case MenuID.NewStep:
	case MenuID.NewMenuCard:
	case MenuID.NewEnemyCard:
	case MenuID.NewBack:
	case MenuID.OpenImportSource:
	case MenuID.NewCast:
	case MenuID.NewSkill:
	case MenuID.NewItem:
	case MenuID.NewBeast:
	case MenuID.NewInfo:
	case MenuID.ReplFilePath:
	case MenuID.CreateArchive:
		return true;
	default:
		return false;
	}
}

/// キーバインドを設定できないメニュー。
bool isNoKeyBindMenu(MenuID id) {
	return id is MenuID.None;
}

/// CTypeGroupに対応するMenuIDを返す。
MenuID cTypeGroupToMenuID(CTypeGroup g) {
	final switch (g) {
	case CTypeGroup.Terminal: return MenuID.CGroupTerminal;
	case CTypeGroup.Standard: return MenuID.CGroupStandard;
	case CTypeGroup.Data: return MenuID.CGroupData;
	case CTypeGroup.Utility: return MenuID.CGroupUtility;
	case CTypeGroup.Branch: return MenuID.CGroupBranch;
	case CTypeGroup.Get: return MenuID.CGroupGet;
	case CTypeGroup.Lost: return MenuID.CGroupLost;
	case CTypeGroup.Visual: return MenuID.CGroupVisual;
	}
}

/// MenuIDを持つオブジェクト。
class MenuData {
	MenuID id = MenuID.None;
	string delegate(string) format = null;
	bool delegate() enabled = null;
}
