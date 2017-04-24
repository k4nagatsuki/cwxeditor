
module cwx.menu;

import cwx.xml;
import cwx.props;
import cwx.utils;
import cwx.settings;
import cwx.types;
import cwx.enumutils;

import std.array;
import std.string;
import std.traits;

/// エディタのメニュー。
class MenuProps : Properties {
	static immutable XML_NAME = "menu";

	private string[] _mnemonic;
	private immutable string[] _mnemonic_init;
	private string[] _hotkey;
	private immutable string[] _hotkey_init;

	/// 唯一のコンストラクタ。
	this () { mixin(S_TRACE);
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
		_mnemonic[MenuID.CreateSubWindow] = "S";
		_mnemonic[MenuID.LeftPane] = "L";
		_mnemonic[MenuID.RightPane] = "R";
		_mnemonic[MenuID.ClosePane] = "C";
		_mnemonic[MenuID.ClosePaneExcept] = "W";
		_mnemonic[MenuID.ClosePaneLeft] = "E";
		_mnemonic[MenuID.ClosePaneRight] = "I";
		_mnemonic[MenuID.ClosePaneAll] = "A";
		_mnemonic[MenuID.New] = "N";
		_mnemonic[MenuID.Open] = "O";
		_mnemonic[MenuID.NewAtNewWindow] = "E";
		_mnemonic[MenuID.OpenAtNewWindow] = "P";
		_mnemonic[MenuID.Close] = "X";
		_mnemonic[MenuID.CloseWin] = "X";
		_mnemonic[MenuID.Save] = "S";
		_mnemonic[MenuID.SaveAs] = "A";
		_mnemonic[MenuID.Reload] = "R";
		_mnemonic[MenuID.OpenDir] = "O";
		_mnemonic[MenuID.OpenBackupDir] = "B";
		_mnemonic[MenuID.OpenPlace] = "O";
		_mnemonic[MenuID.SaveImage] = "I";
		_mnemonic[MenuID.IncludeImage] = "N";
		_mnemonic[MenuID.LookImages] = "L";
		_mnemonic[MenuID.EditLayers] = "Y";
		_mnemonic[MenuID.AddLayer] = "A";
		_mnemonic[MenuID.RemoveLayer] = "R";
		_mnemonic[MenuID.ChangeVH] = "H";
		_mnemonic[MenuID.SelectConnectedResource] = "S";
		_mnemonic[MenuID.Find] = "F";
		_mnemonic[MenuID.FindID] = "I";
		_mnemonic[MenuID.IncSearch] = "N";
		_mnemonic[MenuID.CloseIncSearch] = "X";
		_mnemonic[MenuID.EditProp] = "E";
		_mnemonic[MenuID.ShowProp] = "E";
		_mnemonic[MenuID.Refresh] = "R";
		_mnemonic[MenuID.Undo] = "U";
		_mnemonic[MenuID.Redo] = "R";
		_mnemonic[MenuID.Cut] = "T";
		_mnemonic[MenuID.Copy] = "C";
		_mnemonic[MenuID.Paste] = "P";
		_mnemonic[MenuID.Delete] = "D";
		_mnemonic[MenuID.Cut1Content] = "U";
		_mnemonic[MenuID.Copy1Content] = "O";
		_mnemonic[MenuID.Delete1Content] = "E";
		_mnemonic[MenuID.PasteInsert] = "I";
		_mnemonic[MenuID.Clone] = "L";
		_mnemonic[MenuID.SelectAll] = "A";
		_mnemonic[MenuID.CopyAll] = "A";
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
		_mnemonic[MenuID.CouponView] = "O";
		_mnemonic[MenuID.GossipView] = "G";
		_mnemonic[MenuID.CompleteStampView] = "M";
		_mnemonic[MenuID.KeyCodeView] = "K";
		_mnemonic[MenuID.CellNameView] = "E";
		_mnemonic[MenuID.ExecEngine] = "G";
		_mnemonic[MenuID.ExecEngineAuto] = "G";
		_mnemonic[MenuID.ExecEngineMain] = "P";
		_mnemonic[MenuID.ExecEngineWithParty] = "P";
		_mnemonic[MenuID.ExecEngineWithLastParty] = "L";
		_mnemonic[MenuID.OuterTools] = "T";
		_mnemonic[MenuID.Settings] = "S";
		_mnemonic[MenuID.VersionInfo] = "A";
		_mnemonic[MenuID.LockToolBar] = "L";
		_mnemonic[MenuID.ResetToolBar] = "R";
		_mnemonic[MenuID.CopyAsText] = "C";
		_mnemonic[MenuID.OpenAtView] = "V";
		_mnemonic[MenuID.EventToPackage] = "G";
		_mnemonic[MenuID.StartToPackage] = "G";
		_mnemonic[MenuID.WrapTree] = "W";
		_mnemonic[MenuID.CreateContent] = "A";
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
		_mnemonic[MenuID.NewAreaDir] = "D";
		_mnemonic[MenuID.NewArea] = "A";
		_mnemonic[MenuID.NewBattle] = "B";
		_mnemonic[MenuID.NewPackage] = "K";
		_mnemonic[MenuID.ReNumberingAll] = "A";
		_mnemonic[MenuID.ReNumbering] = "B";
		_mnemonic[MenuID.EditScene] = "S";
		_mnemonic[MenuID.EditSceneDup] = "E";
		_mnemonic[MenuID.EditEvent] = "N";
		_mnemonic[MenuID.EditEventDup] = "V";
		_mnemonic[MenuID.SetStartArea] = "R";
		_mnemonic[MenuID.NewFlagDir] = "N";
		_mnemonic[MenuID.NewFlag] = "F";
		_mnemonic[MenuID.NewStep] = "S";
		_mnemonic[MenuID.CreateStepValues] = "V";
		_mnemonic[MenuID.CreateVariableEventTree] = "E";
		_mnemonic[MenuID.InitVariablesTree] = "I";
		_mnemonic[MenuID.CopyVariablePath] = "V";
		_mnemonic[MenuID.Up] = "K";
		_mnemonic[MenuID.Down] = "J";
		_mnemonic[MenuID.Reverse] = "R";
		_mnemonic[MenuID.SwapToParent] = "S";
		_mnemonic[MenuID.SwapToChild] = "W";
		_mnemonic[MenuID.OverDialog] = "O";
		_mnemonic[MenuID.UnderDialog] = "U";
		_mnemonic[MenuID.ShowParty] = "P";
		_mnemonic[MenuID.ShowMsg] = "M";
		_mnemonic[MenuID.ShowRefCards] = "R";
		_mnemonic[MenuID.FixedCards] = "F";
		_mnemonic[MenuID.FixedCells] = "I";
		_mnemonic[MenuID.FixedBackground] = "B";
		_mnemonic[MenuID.ShowGrid] = "G";
		_mnemonic[MenuID.ShowEnemyCardProp] = "L";
		_mnemonic[MenuID.ShowCard] = "V";
		_mnemonic[MenuID.ShowBack] = "I";
		_mnemonic[MenuID.NewMenuCard] = "C";
		_mnemonic[MenuID.NewEnemyCard] = "C";
		_mnemonic[MenuID.NewBack] = "B";
		_mnemonic[MenuID.NewTextCell] = "T";
		_mnemonic[MenuID.NewColorCell] = "L";
		_mnemonic[MenuID.NewPCCell] = "P";
		_mnemonic[MenuID.AutoArrange] = "A";
		_mnemonic[MenuID.ManualArrange] = "U";
		_mnemonic[MenuID.Mask] = "M";
		_mnemonic[MenuID.Escape] = "E";
		_mnemonic[MenuID.ChangePos] = "P";
		_mnemonic[MenuID.PosTop] = "K";
		_mnemonic[MenuID.PosBottom] = "J";
		_mnemonic[MenuID.PosLeft] = "H";
		_mnemonic[MenuID.PosRight] = "L";
		_mnemonic[MenuID.PosEven] = "E";
		_mnemonic[MenuID.NearTop] = "W";
		_mnemonic[MenuID.NearBottom] = "Z";
		_mnemonic[MenuID.NearLeft] = "A";
		_mnemonic[MenuID.NearRight] = "S";
		_mnemonic[MenuID.NearCenterH] = "O";
		_mnemonic[MenuID.NearCenterV] = "V";
		_mnemonic[MenuID.NearCenter] = "E";
		_mnemonic[MenuID.ScaleMin] = "N";
		_mnemonic[MenuID.ScaleMiddle] = "I";
		_mnemonic[MenuID.ScaleMax] = "G";
		_mnemonic[MenuID.ScaleBig] = "R";
		_mnemonic[MenuID.ScaleSmall] = "M";
		_mnemonic[MenuID.ExpandBack] = "X";
		_mnemonic[MenuID.StopBGM] = "P";
		_mnemonic[MenuID.PlayBGM] = "P";
		_mnemonic[MenuID.KeyCodeTiming] = "K";
		_mnemonic[MenuID.KeyCodeTimingUse] = "U";
		_mnemonic[MenuID.KeyCodeTimingSuccess] = "S";
		_mnemonic[MenuID.KeyCodeTimingFailure] = "F";
		_mnemonic[MenuID.KeyCodeTimingHasNot] = "H";
		_mnemonic[MenuID.KeyCodeCond] = "O";
		_mnemonic[MenuID.KeyCodeCondOr] = "O";
		_mnemonic[MenuID.KeyCodeCondAnd] = "A";
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
		_mnemonic[MenuID.AddHand] = "A";
		_mnemonic[MenuID.RemoveRef] = "I";
		_mnemonic[MenuID.EditEventAtTimeOfUsing] = "N";
		_mnemonic[MenuID.Hold] = "H";
		_mnemonic[MenuID.PlaySE] = "P";
		_mnemonic[MenuID.StopSE] = "S";
		_mnemonic[MenuID.NewDir] = "I";
		_mnemonic[MenuID.CopyFilePath] = "M";
		_mnemonic[MenuID.CreateArchive] = "V";
		_mnemonic[MenuID.PutQuick] = "Q";
		_mnemonic[MenuID.PutSelect] = "S";
		_mnemonic[MenuID.PutContinue] = "C";
		_mnemonic[MenuID.ToScript] = "S";
		_mnemonic[MenuID.ToScriptAll] = "Y";
		_mnemonic[MenuID.ToScript1Content] = "O";
		_mnemonic[MenuID.EvTemplates] = "";
		_mnemonic[MenuID.EvTemplatesOfScenario] = "E";
		_mnemonic[MenuID.Expand] = "X";
		_mnemonic[MenuID.Collapse] = "O";
		_mnemonic[MenuID.SelectCurrentEvent] = "S";
		_mnemonic[MenuID.ResetPreviewValues] = "R";
		_mnemonic[MenuID.ResetPreviewValuesAll] = "E";
		_mnemonic[MenuID.CustomizeToolBar] = "Z";
		_mnemonic[MenuID.AddTool] = "O";
		_mnemonic[MenuID.AddToolBar] = "B";
		_mnemonic[MenuID.AddToolGroup] = "G";
		_mnemonic[MenuID.ResetToolBarSettings] = "R";

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
		_hotkey[MenuID.CreateSubWindow] = "Ctrl+Shift+N";
		_hotkey[MenuID.LeftPane] = "Ctrl+Page_Up";
		_hotkey[MenuID.RightPane] = "Ctrl+Page_Down";
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
		_hotkey[MenuID.OpenBackupDir] = "";
		_hotkey[MenuID.OpenPlace] = "";
		_hotkey[MenuID.SaveImage] = "";
		_hotkey[MenuID.IncludeImage] = "";
		_hotkey[MenuID.LookImages] = "";
		_hotkey[MenuID.EditLayers] = "";
		_hotkey[MenuID.AddLayer] = "";
		_hotkey[MenuID.RemoveLayer] = "";
		_hotkey[MenuID.ChangeVH] = "";
		_hotkey[MenuID.SelectConnectedResource] = "Ctrl+R";
		_hotkey[MenuID.Find] = "Ctrl+F";
		_hotkey[MenuID.FindID] = "Ctrl+Shift+F";
		_hotkey[MenuID.IncSearch] = "Ctrl+I";
		_hotkey[MenuID.CloseIncSearch] = "Escape";
		_hotkey[MenuID.EditProp] = "Enter";
		_hotkey[MenuID.ShowProp] = "Enter";
		_hotkey[MenuID.Refresh] = "F5";
		_hotkey[MenuID.Undo] = "Ctrl+Z";
		_hotkey[MenuID.Redo] = "Ctrl+Y";
		_hotkey[MenuID.Cut] = "Ctrl+X";
		_hotkey[MenuID.Copy] = "Ctrl+C";
		_hotkey[MenuID.Paste] = "Ctrl+V";
		_hotkey[MenuID.Delete] = "Delete";
		_hotkey[MenuID.Cut1Content] = "Ctrl+Shift+X";
		_hotkey[MenuID.Copy1Content] = "Ctrl+Shift+C";
		_hotkey[MenuID.Delete1Content] = "Shift+Delete";
		_hotkey[MenuID.PasteInsert] = "Ctrl+Shift+V";
		_hotkey[MenuID.Clone] = "";
		_hotkey[MenuID.SelectAll] = "Ctrl+A";
		_hotkey[MenuID.CopyAll] = "Ctrl+Shift+C";
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
		_hotkey[MenuID.CouponView] = "";
		_hotkey[MenuID.GossipView] = "";
		_hotkey[MenuID.CompleteStampView] = "";
		_hotkey[MenuID.KeyCodeView] = "";
		_hotkey[MenuID.CellNameView] = "";
		_hotkey[MenuID.ExecEngine] = "";
		_hotkey[MenuID.ExecEngineAuto] = "F9";
		_hotkey[MenuID.ExecEngineMain] = "";
		_hotkey[MenuID.ExecEngineWithParty] = "";
		_hotkey[MenuID.ExecEngineWithLastParty] = "";
		_hotkey[MenuID.OuterTools] = "";
		_hotkey[MenuID.Settings] = "";
		_hotkey[MenuID.VersionInfo] = "";
		_hotkey[MenuID.LockToolBar] = "";
		_hotkey[MenuID.ResetToolBar] = "";
		_hotkey[MenuID.CopyAsText] = "Ctrl+C";
		_hotkey[MenuID.OpenAtView] = "";
		_hotkey[MenuID.EventToPackage] = "";
		_hotkey[MenuID.StartToPackage] = "";
		_hotkey[MenuID.WrapTree] = "";
		_hotkey[MenuID.CreateContent] = "";
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
		_hotkey[MenuID.NewAreaDir] = "";
		_hotkey[MenuID.NewArea] = "";
		_hotkey[MenuID.NewBattle] = "";
		_hotkey[MenuID.NewPackage] = "";
		_hotkey[MenuID.ReNumberingAll] = "";
		_hotkey[MenuID.ReNumbering] = "";
		_hotkey[MenuID.EditScene] = "F3";
		_hotkey[MenuID.EditSceneDup] = "Ctrl+F3";
		_hotkey[MenuID.EditEvent] = "F4";
		_hotkey[MenuID.EditEventDup] = "Ctrl+F4";
		_hotkey[MenuID.SetStartArea] = "";
		_hotkey[MenuID.NewFlagDir] = "";
		_hotkey[MenuID.NewFlag] = "Ctrl+L";
		_hotkey[MenuID.NewStep] = "Ctrl+P";
		_hotkey[MenuID.CreateStepValues] = "";
		_hotkey[MenuID.CreateVariableEventTree] = "";
		_hotkey[MenuID.InitVariablesTree] = "";
		_hotkey[MenuID.CopyVariablePath] = "";
		_hotkey[MenuID.Up] = "Ctrl+Arrow_Up";
		_hotkey[MenuID.Down] = "Ctrl+Arrow_Down";
		_hotkey[MenuID.Reverse] = "";
		_hotkey[MenuID.SwapToParent] = "Ctrl+Shift+Arrow_Up";
		_hotkey[MenuID.SwapToChild] = "Ctrl+Shift+Arrow_Down";
		_hotkey[MenuID.OverDialog] = "Ctrl+Shift+Arrow_Up";
		_hotkey[MenuID.UnderDialog] = "Ctrl+Shift+Arrow_Down";
		_hotkey[MenuID.ShowParty] = "";
		_hotkey[MenuID.ShowMsg] = "";
		_hotkey[MenuID.ShowRefCards] = "";
		_hotkey[MenuID.FixedCards] = "";
		_hotkey[MenuID.FixedCells] = "";
		_hotkey[MenuID.FixedBackground] = "";
		_hotkey[MenuID.ShowGrid] = "";
		_hotkey[MenuID.ShowEnemyCardProp] = "";
		_hotkey[MenuID.ShowCard] = "";
		_hotkey[MenuID.ShowBack] = "";
		_hotkey[MenuID.NewMenuCard] = "";
		_hotkey[MenuID.NewEnemyCard] = "";
		_hotkey[MenuID.NewBack] = "";
		_hotkey[MenuID.NewTextCell] = "";
		_hotkey[MenuID.NewColorCell] = "";
		_hotkey[MenuID.NewPCCell] = "";
		_hotkey[MenuID.AutoArrange] = "";
		_hotkey[MenuID.ManualArrange] = "";
		_hotkey[MenuID.Mask] = "";
		_hotkey[MenuID.Escape] = "";
		_hotkey[MenuID.ChangePos] = "";
		_hotkey[MenuID.PosTop] = "";
		_hotkey[MenuID.PosBottom] = "";
		_hotkey[MenuID.PosLeft] = "";
		_hotkey[MenuID.PosRight] = "";
		_hotkey[MenuID.PosEven] = "";
		_hotkey[MenuID.NearTop] = "";
		_hotkey[MenuID.NearBottom] = "";
		_hotkey[MenuID.NearLeft] = "";
		_hotkey[MenuID.NearRight] = "";
		_hotkey[MenuID.NearCenterH] = "";
		_hotkey[MenuID.NearCenterV] = "";
		_hotkey[MenuID.NearCenter] = "";
		_hotkey[MenuID.PosEven] = "";
		_hotkey[MenuID.ScaleMin] = "";
		_hotkey[MenuID.ScaleMiddle] = "";
		_hotkey[MenuID.ScaleMax] = "";
		_hotkey[MenuID.ScaleBig] = "";
		_hotkey[MenuID.ScaleSmall] = "";
		_hotkey[MenuID.ExpandBack] = "";
		_hotkey[MenuID.StopBGM] = "";
		_hotkey[MenuID.PlayBGM] = "";
		_hotkey[MenuID.KeyCodeTiming] = "";
		_hotkey[MenuID.KeyCodeTimingUse] = "";
		_hotkey[MenuID.KeyCodeTimingSuccess] = "";
		_hotkey[MenuID.KeyCodeTimingFailure] = "";
		_hotkey[MenuID.KeyCodeTimingHasNot] = "";
		_hotkey[MenuID.KeyCodeCond] = "";
		_hotkey[MenuID.KeyCodeCondOr] = "";
		_hotkey[MenuID.KeyCodeCondAnd] = "";
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
		_hotkey[MenuID.Import] = "Ctrl+Enter";
		_hotkey[MenuID.OpenHand] = "";
		_hotkey[MenuID.AddHand] = "";
		_hotkey[MenuID.RemoveRef] = "";
		_hotkey[MenuID.EditEventAtTimeOfUsing] = "";
		_hotkey[MenuID.Hold] = "";
		_hotkey[MenuID.PlaySE] = "";
		_hotkey[MenuID.StopSE] = "";
		_hotkey[MenuID.NewDir] = "";
		_hotkey[MenuID.CopyFilePath] = "";
		_hotkey[MenuID.CreateArchive] = "";
		_hotkey[MenuID.PutQuick] = "";
		_hotkey[MenuID.PutSelect] = "";
		_hotkey[MenuID.PutContinue] = "";
		_hotkey[MenuID.ToScript] = "Ctrl+G";
		_hotkey[MenuID.ToScriptAll] = "Ctrl+B";
		_hotkey[MenuID.ToScript1Content] = "Ctrl+Shift+G";
		_hotkey[MenuID.EvTemplates] = "";
		_hotkey[MenuID.EvTemplatesOfScenario] = "";
		_hotkey[MenuID.Expand] = "Ctrl+Arrow_Right";
		_hotkey[MenuID.Collapse] = "Ctrl+Arrow_Left";
		_hotkey[MenuID.SelectCurrentEvent] = "";
		_hotkey[MenuID.ResetPreviewValues] = "";
		_hotkey[MenuID.ResetPreviewValuesAll] = "";
		_hotkey[MenuID.CustomizeToolBar] = "";
		_hotkey[MenuID.AddTool] = "";
		_hotkey[MenuID.AddToolBar] = "";
		_hotkey[MenuID.AddToolGroup] = "";
		_hotkey[MenuID.ResetToolBarSettings] = "";

		_mnemonic_init = _mnemonic.idup;
		_hotkey_init = _hotkey.idup;
	}

	/// アクセスキー。
	const
	string mnemonic(MenuID id) { mixin(S_TRACE);
		return _mnemonic[id];
	}
	/// ditto
	void mnemonic(MenuID id, string key) { mixin(S_TRACE);
		_mnemonic[id] = key;
	}
	/// ショートカットキー。
	const
	string hotkey(MenuID id) { mixin(S_TRACE);
		return _hotkey[id];
	}
	/// ditto
	void hotkey(MenuID id, string key) { mixin(S_TRACE);
		_hotkey[id] = key;
	}

	/// ツール文字列を構築する。
	const
	string buildTool(in CProps prop, MenuID id) { mixin(S_TRACE);
		return buildTool(prop, id, _mnemonic[id], _hotkey[id]);
	}
	/// ditto
	static string buildTool(in CProps prop, MenuID id, string mnemonic, string hotkey) { mixin(S_TRACE);
		return buildTool(prop.msgs.menuText(id), mnemonic, hotkey, isPMenu(id));
	}
	/// ditto
	static string buildTool(string r, string mnemonic, string hotkey, bool m) { mixin(S_TRACE);
		if (m) { mixin(S_TRACE);
			r ~= "...";
		}
		if (hotkey != "") { mixin(S_TRACE);
			r ~= "\n" ~ hotkey;
		}
		return r;
	}

	/// メニュー文字列を構築する。
	const
	string buildMenu(in CProps prop, MenuID id) { mixin(S_TRACE);
		return buildMenu(prop, id, _mnemonic[id], _hotkey[id]);
	}
	/// ditto
	static string buildMenu(in CProps prop, MenuID id, string mnemonic, string hotkey) { mixin(S_TRACE);
		return buildMenu(prop.msgs.menuText(id), mnemonic, hotkey, isPMenu(id));
	}
	/// ditto
	static string buildMenu(string r, string mnemonic, string hotkey, bool m) { mixin(S_TRACE);
		r = r.replace("&", "&&");
		r = r.replace("\n", "");
		string a = mnemonic;
		string h = hotkey;
		if (a.length) { mixin(S_TRACE);
			ptrdiff_t i = r.indexOf(a, CaseSensitive.no);
			if (-1 == i) { mixin(S_TRACE);
				r ~= "(&" ~ a ~ ")";
			} else { mixin(S_TRACE);
				r = r[0 .. i] ~ "&" ~ r[i .. $];
			}
		}
		if (m) { mixin(S_TRACE);
			r ~= "...";
		}
		if (h.length) r ~= "\t" ~ h;
		return r;
	}
	/// ditto
	const
	string buildMenuSample(in CProps prop, MenuID id) { mixin(S_TRACE);
		return buildMenuSample(prop, id, _mnemonic[id], _hotkey[id]);
	}
	/// ditto
	static string buildMenuSample(in CProps prop, MenuID id, string mnemonic, string hotkey) { mixin(S_TRACE);
		string r = prop.msgs.menuText(id);
		if (MenuID.StopBGM is id) { mixin(S_TRACE);
			// 唯一パラメータを持つメニューテキスト
			r = .tryFormat(r, prop.msgs.bgm);
		}
		return buildMenuSample(r, mnemonic, hotkey, isPMenu(id));
	}
	/// ditto
	static string buildMenuSample(string r, string mnemonic, string hotkey, bool m) { mixin(S_TRACE);
		string a = mnemonic;
		string h = hotkey;
		if (a.length) { mixin(S_TRACE);
			ptrdiff_t i = r.indexOf(a, CaseSensitive.no);
			if (-1 == i) { mixin(S_TRACE);
				r ~= "(&" ~ a ~ ")";
			} else { mixin(S_TRACE);
				r = r[0 .. i] ~ "&" ~ r[i .. $];
			}
		}
		if (m) { mixin(S_TRACE);
			r ~= "...";
		}
		if (h.length) r ~= " " ~ h;
		return r;
	}

	/// XMLノードとして取り扱うための関数群。
	const
	XNode toNode() { mixin(S_TRACE);
		auto e = XNode.create(XML_NAME);
		toNodeImpl(e);
		return e;
	}
	/// ditto
	const
	void toNode(ref XNode node) { mixin(S_TRACE);
		auto e = node.newElement(XML_NAME);
		toNodeImpl(e);
	}
	/// ditto
	const
	private void toNodeImpl(ref XNode e) { mixin(S_TRACE);
		foreach (id; EnumMembers!MenuID) { mixin(S_TRACE);
			if (isNoKeyBindMenu(id)) continue;
			string a = _mnemonic[id];
			string h = _hotkey[id];
			string ainit = _mnemonic_init[id];
			string hinit = _hotkey_init[id];
			if (a != ainit || h != hinit) { mixin(S_TRACE);
				auto me = e.newElement("menuItem");
				me.newAttr("name", enumToString(id));
				if (a != ainit) { mixin(S_TRACE);
					me.newAttr("mnemonic", a);
				}
				if (h != hinit) { mixin(S_TRACE);
					me.newAttr("hotkey", h);
				}
			}
		}
	}
	/// ditto
	static MenuProps fromNode(ref XNode node) { mixin(S_TRACE);
		auto r = new MenuProps;
		node.onTag["menu"] = (ref XNode node) { mixin(S_TRACE);
			node.onTag["menuItem"] = (ref XNode me) { mixin(S_TRACE);
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
bool isPMenu(MenuID id) { mixin(S_TRACE);
	switch (id) {
	case MenuID.New:
	case MenuID.Open:
	case MenuID.NewAtNewWindow:
	case MenuID.OpenAtNewWindow:
	case MenuID.SaveAs:
	case MenuID.Find:
	case MenuID.FindID:
	case MenuID.Settings:
	case MenuID.EditSummary:
	case MenuID.EditProp:
	case MenuID.ShowProp:
	case MenuID.NewFlagDir:
	case MenuID.NewFlag:
	case MenuID.NewStep:
	case MenuID.NewMenuCard:
	case MenuID.NewEnemyCard:
	case MenuID.NewBack:
	case MenuID.NewTextCell:
	case MenuID.NewColorCell:
	case MenuID.NewPCCell:
	case MenuID.OpenImportSource:
	case MenuID.NewCast:
	case MenuID.NewSkill:
	case MenuID.NewItem:
	case MenuID.NewBeast:
	case MenuID.NewInfo:
	case MenuID.CreateArchive:
		return true;
	default:
		return false;
	}
}

/// キーバインドを設定できないメニュー。
bool isNoKeyBindMenu(MenuID id) { mixin(S_TRACE);
	return id is MenuID.None;
}

/// CTypeGroupに対応するMenuIDを返す。
MenuID cTypeGroupToMenuID(CTypeGroup g) { mixin(S_TRACE);
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

/// メインウィンドウのツールバーに表示可能なメニューか。
bool isMainToolBarMenu(MenuID id) { mixin(S_TRACE);
	final switch (id) {
	case MenuID.DelNotUsedFile:
	case MenuID.New:
	case MenuID.Open:
	case MenuID.NewAtNewWindow:
	case MenuID.OpenAtNewWindow:
	case MenuID.Close:
	case MenuID.Save:
	case MenuID.SaveAs:
	case MenuID.Reload:
	case MenuID.OpenDir:
	case MenuID.OpenBackupDir:
	case MenuID.ChangeVH:
	case MenuID.SelectConnectedResource:
	case MenuID.Find:
	case MenuID.FindID:
	case MenuID.IncSearch:
	case MenuID.EditProp:
	case MenuID.ShowProp:
	case MenuID.Refresh:
	case MenuID.Undo:
	case MenuID.Redo:
	case MenuID.Cut:
	case MenuID.Copy:
	case MenuID.Paste:
	case MenuID.Delete:
	case MenuID.Cut1Content:
	case MenuID.Copy1Content:
	case MenuID.Delete1Content:
	case MenuID.PasteInsert:
	case MenuID.Clone:
	case MenuID.SelectAll:
	case MenuID.CopyAll:
	case MenuID.ToXMLText:
	case MenuID.TableView:
	case MenuID.VarView:
	case MenuID.CastView:
	case MenuID.SkillView:
	case MenuID.ItemView:
	case MenuID.BeastView:
	case MenuID.InfoView:
	case MenuID.FileView:
	case MenuID.CouponView:
	case MenuID.GossipView:
	case MenuID.CompleteStampView:
	case MenuID.KeyCodeView:
	case MenuID.CellNameView:
	case MenuID.ExecEngine:
	case MenuID.ExecEngineWithParty:
	case MenuID.OuterTools:
	case MenuID.Settings:
	case MenuID.VersionInfo:
	case MenuID.EventToPackage:
	case MenuID.StartToPackage:
	case MenuID.WrapTree:
	case MenuID.EditSummary:
	case MenuID.NewAreaDir:
	case MenuID.NewArea:
	case MenuID.NewBattle:
	case MenuID.NewPackage:
	case MenuID.ReNumberingAll:
	case MenuID.ReNumbering:
	case MenuID.EditScene:
	case MenuID.EditSceneDup:
	case MenuID.EditEvent:
	case MenuID.EditEventDup:
	case MenuID.SetStartArea:
	case MenuID.NewFlagDir:
	case MenuID.NewFlag:
	case MenuID.NewStep:
	case MenuID.CopyVariablePath:
	case MenuID.Up:
	case MenuID.Down:
	case MenuID.Reverse:
	case MenuID.SwapToParent:
	case MenuID.SwapToChild:
	case MenuID.Comment:
	case MenuID.ShowCardProp:
	case MenuID.ShowCardImage:
	case MenuID.ShowCardDetail:
	case MenuID.OpenImportSource:
	case MenuID.NewCast:
	case MenuID.NewSkill:
	case MenuID.NewItem:
	case MenuID.NewBeast:
	case MenuID.NewInfo:
	case MenuID.Import:
	case MenuID.OpenHand:
	case MenuID.RemoveRef:
	case MenuID.EditEventAtTimeOfUsing:
	case MenuID.NewDir:
	case MenuID.CopyFilePath:
	case MenuID.CreateArchive:
	case MenuID.ToScript:
	case MenuID.ToScriptAll:
	case MenuID.ToScript1Content:
		return true;
	case MenuID.None:
	case MenuID.File:
	case MenuID.Edit:
	case MenuID.View:
	case MenuID.Tool:
	case MenuID.Table:
	case MenuID.Variable:
	case MenuID.Help:
	case MenuID.Card:
	case MenuID.CardsAndBacks:
	case MenuID.CreateSubWindow:
	case MenuID.LeftPane:
	case MenuID.RightPane:
	case MenuID.ClosePane:
	case MenuID.ClosePaneExcept:
	case MenuID.ClosePaneLeft:
	case MenuID.ClosePaneRight:
	case MenuID.ClosePaneAll:
	case MenuID.CloseWin:
	case MenuID.OpenPlace:
	case MenuID.SaveImage:
	case MenuID.IncludeImage:
	case MenuID.LookImages:
	case MenuID.EditLayers:
	case MenuID.AddLayer:
	case MenuID.RemoveLayer:
	case MenuID.CloseIncSearch:
	case MenuID.CardView:
	case MenuID.ExecEngineAuto:
	case MenuID.ExecEngineMain:
	case MenuID.ExecEngineWithLastParty:
	case MenuID.LockToolBar:
	case MenuID.ResetToolBar:
	case MenuID.CopyAsText:
	case MenuID.OpenAtView:
	case MenuID.CreateContent:
	case MenuID.ConvertContent:
	case MenuID.CGroupTerminal:
	case MenuID.CGroupStandard:
	case MenuID.CGroupData:
	case MenuID.CGroupUtility:
	case MenuID.CGroupBranch:
	case MenuID.CGroupGet:
	case MenuID.CGroupLost:
	case MenuID.CGroupVisual:
	case MenuID.CreateStepValues:
	case MenuID.CreateVariableEventTree:
	case MenuID.InitVariablesTree:
	case MenuID.OverDialog:
	case MenuID.UnderDialog:
	case MenuID.ShowParty:
	case MenuID.ShowMsg:
	case MenuID.ShowRefCards:
	case MenuID.FixedCards:
	case MenuID.FixedCells:
	case MenuID.FixedBackground:
	case MenuID.ShowGrid:
	case MenuID.ShowEnemyCardProp:
	case MenuID.ShowCard:
	case MenuID.ShowBack:
	case MenuID.NewMenuCard:
	case MenuID.NewEnemyCard:
	case MenuID.NewBack:
	case MenuID.NewTextCell:
	case MenuID.NewColorCell:
	case MenuID.NewPCCell:
	case MenuID.AutoArrange:
	case MenuID.ManualArrange:
	case MenuID.Mask:
	case MenuID.Escape:
	case MenuID.ChangePos:
	case MenuID.PosTop:
	case MenuID.PosBottom:
	case MenuID.PosLeft:
	case MenuID.PosRight:
	case MenuID.PosEven:
	case MenuID.NearTop:
	case MenuID.NearBottom:
	case MenuID.NearLeft:
	case MenuID.NearRight:
	case MenuID.NearCenterH:
	case MenuID.NearCenterV:
	case MenuID.NearCenter:
	case MenuID.ScaleMin:
	case MenuID.ScaleMiddle:
	case MenuID.ScaleMax:
	case MenuID.ScaleBig:
	case MenuID.ScaleSmall:
	case MenuID.ExpandBack:
	case MenuID.StopBGM:
	case MenuID.PlayBGM:
	case MenuID.KeyCodeTiming:
	case MenuID.KeyCodeTimingUse:
	case MenuID.KeyCodeTimingSuccess:
	case MenuID.KeyCodeTimingFailure:
	case MenuID.KeyCodeTimingHasNot:
	case MenuID.KeyCodeCond:
	case MenuID.KeyCodeCondOr:
	case MenuID.KeyCodeCondAnd:
	case MenuID.AddRangeOfRound:
	case MenuID.OpenAtTableView:
	case MenuID.OpenAtVarView:
	case MenuID.OpenAtCardView:
	case MenuID.OpenAtFileView:
	case MenuID.OpenAtEventView:
	case MenuID.AddHand:
	case MenuID.Hold:
	case MenuID.PlaySE:
	case MenuID.StopSE:
	case MenuID.PutQuick:
	case MenuID.PutSelect:
	case MenuID.PutContinue:
	case MenuID.EvTemplates:
	case MenuID.EvTemplatesOfScenario:
	case MenuID.Expand:
	case MenuID.Collapse:
	case MenuID.SelectCurrentEvent:
	case MenuID.ResetPreviewValues:
	case MenuID.ResetPreviewValuesAll:
	case MenuID.CustomizeToolBar:
	case MenuID.AddTool:
	case MenuID.AddToolBar:
	case MenuID.AddToolGroup:
	case MenuID.ResetToolBarSettings:
		return false;
	}
}

/// フォーカスがサブウィンドウへ行っている時でも
/// ショートカットキー押下で実行するべきメニューか。
bool isGlobalMenu(MenuID id) {
	final switch (id) {
	case MenuID.DelNotUsedFile:
	case MenuID.CreateSubWindow:
	case MenuID.New:
	case MenuID.Open:
	case MenuID.NewAtNewWindow:
	case MenuID.OpenAtNewWindow:
	case MenuID.Close:
	case MenuID.Save:
	case MenuID.SaveAs:
	case MenuID.Reload:
	case MenuID.OpenDir:
	case MenuID.OpenBackupDir:
	case MenuID.Find:
	case MenuID.Refresh:
	case MenuID.ToXMLText:
	case MenuID.TableView:
	case MenuID.VarView:
	case MenuID.CardView:
	case MenuID.CastView:
	case MenuID.SkillView:
	case MenuID.ItemView:
	case MenuID.BeastView:
	case MenuID.InfoView:
	case MenuID.FileView:
	case MenuID.CouponView:
	case MenuID.GossipView:
	case MenuID.CompleteStampView:
	case MenuID.KeyCodeView:
	case MenuID.CellNameView:
	case MenuID.ExecEngine:
	case MenuID.ExecEngineAuto:
	case MenuID.ExecEngineMain:
	case MenuID.ExecEngineWithParty:
	case MenuID.ExecEngineWithLastParty:
	case MenuID.OuterTools:
	case MenuID.Settings:
	case MenuID.VersionInfo:
	case MenuID.EditSummary:
	case MenuID.NewAreaDir:
	case MenuID.NewArea:
	case MenuID.NewBattle:
	case MenuID.NewPackage:
	case MenuID.ReNumberingAll:
	case MenuID.EditScene:
	case MenuID.EditEvent:
	case MenuID.EditEventDup:
	case MenuID.NewFlagDir:
	case MenuID.NewFlag:
	case MenuID.NewStep:
	case MenuID.ShowCardProp:
	case MenuID.ShowCardImage:
	case MenuID.ShowCardDetail:
	case MenuID.OpenImportSource:
	case MenuID.NewCast:
	case MenuID.NewSkill:
	case MenuID.NewItem:
	case MenuID.NewBeast:
	case MenuID.NewInfo:
	case MenuID.NewDir:
	case MenuID.CreateArchive:
	case MenuID.EvTemplatesOfScenario:
		return true;
	case MenuID.None:
	case MenuID.File:
	case MenuID.Edit:
	case MenuID.View:
	case MenuID.Tool:
	case MenuID.Table:
	case MenuID.Variable:
	case MenuID.Help:
	case MenuID.Card:
	case MenuID.CardsAndBacks:
	case MenuID.LeftPane:
	case MenuID.RightPane:
	case MenuID.ClosePane:
	case MenuID.ClosePaneExcept:
	case MenuID.ClosePaneLeft:
	case MenuID.ClosePaneRight:
	case MenuID.ClosePaneAll:
	case MenuID.CloseWin:
	case MenuID.OpenPlace:
	case MenuID.SaveImage:
	case MenuID.IncludeImage:
	case MenuID.LookImages:
	case MenuID.EditLayers:
	case MenuID.AddLayer:
	case MenuID.RemoveLayer:
	case MenuID.ChangeVH:
	case MenuID.SelectConnectedResource:
	case MenuID.FindID:
	case MenuID.IncSearch:
	case MenuID.CloseIncSearch:
	case MenuID.EditProp:
	case MenuID.ShowProp:
	case MenuID.Undo:
	case MenuID.Redo:
	case MenuID.Cut:
	case MenuID.Copy:
	case MenuID.Paste:
	case MenuID.Delete:
	case MenuID.Cut1Content:
	case MenuID.Copy1Content:
	case MenuID.Delete1Content:
	case MenuID.PasteInsert:
	case MenuID.Clone:
	case MenuID.SelectAll:
	case MenuID.CopyAll:
	case MenuID.LockToolBar:
	case MenuID.ResetToolBar:
	case MenuID.CopyAsText:
	case MenuID.OpenAtView:
	case MenuID.EventToPackage:
	case MenuID.StartToPackage:
	case MenuID.WrapTree:
	case MenuID.CreateContent:
	case MenuID.ConvertContent:
	case MenuID.CGroupTerminal:
	case MenuID.CGroupStandard:
	case MenuID.CGroupData:
	case MenuID.CGroupUtility:
	case MenuID.CGroupBranch:
	case MenuID.CGroupGet:
	case MenuID.CGroupLost:
	case MenuID.CGroupVisual:
	case MenuID.ReNumbering:
	case MenuID.EditSceneDup:
	case MenuID.SetStartArea:
	case MenuID.CreateStepValues:
	case MenuID.CreateVariableEventTree:
	case MenuID.InitVariablesTree:
	case MenuID.CopyVariablePath:
	case MenuID.Up:
	case MenuID.Down:
	case MenuID.Reverse:
	case MenuID.SwapToParent:
	case MenuID.SwapToChild:
	case MenuID.OverDialog:
	case MenuID.UnderDialog:
	case MenuID.ShowParty:
	case MenuID.ShowMsg:
	case MenuID.ShowRefCards:
	case MenuID.FixedCards:
	case MenuID.FixedCells:
	case MenuID.FixedBackground:
	case MenuID.ShowGrid:
	case MenuID.ShowEnemyCardProp:
	case MenuID.ShowCard:
	case MenuID.ShowBack:
	case MenuID.NewMenuCard:
	case MenuID.NewEnemyCard:
	case MenuID.NewBack:
	case MenuID.NewTextCell:
	case MenuID.NewColorCell:
	case MenuID.NewPCCell:
	case MenuID.AutoArrange:
	case MenuID.ManualArrange:
	case MenuID.Mask:
	case MenuID.Escape:
	case MenuID.ChangePos:
	case MenuID.PosTop:
	case MenuID.PosBottom:
	case MenuID.PosLeft:
	case MenuID.PosRight:
	case MenuID.PosEven:
	case MenuID.NearTop:
	case MenuID.NearBottom:
	case MenuID.NearLeft:
	case MenuID.NearRight:
	case MenuID.NearCenterH:
	case MenuID.NearCenterV:
	case MenuID.NearCenter:
	case MenuID.ScaleMin:
	case MenuID.ScaleMiddle:
	case MenuID.ScaleMax:
	case MenuID.ScaleBig:
	case MenuID.ScaleSmall:
	case MenuID.ExpandBack:
	case MenuID.StopBGM:
	case MenuID.PlayBGM:
	case MenuID.KeyCodeTiming:
	case MenuID.KeyCodeTimingUse:
	case MenuID.KeyCodeTimingSuccess:
	case MenuID.KeyCodeTimingFailure:
	case MenuID.KeyCodeTimingHasNot:
	case MenuID.KeyCodeCond:
	case MenuID.KeyCodeCondOr:
	case MenuID.KeyCodeCondAnd:
	case MenuID.AddRangeOfRound:
	case MenuID.OpenAtTableView:
	case MenuID.OpenAtVarView:
	case MenuID.OpenAtCardView:
	case MenuID.OpenAtFileView:
	case MenuID.OpenAtEventView:
	case MenuID.Comment:
	case MenuID.Import:
	case MenuID.OpenHand:
	case MenuID.AddHand:
	case MenuID.RemoveRef:
	case MenuID.EditEventAtTimeOfUsing:
	case MenuID.Hold:
	case MenuID.PlaySE:
	case MenuID.StopSE:
	case MenuID.CopyFilePath:
	case MenuID.PutQuick:
	case MenuID.PutSelect:
	case MenuID.PutContinue:
	case MenuID.ToScript:
	case MenuID.ToScriptAll:
	case MenuID.ToScript1Content:
	case MenuID.EvTemplates:
	case MenuID.Expand:
	case MenuID.Collapse:
	case MenuID.SelectCurrentEvent:
	case MenuID.ResetPreviewValues:
	case MenuID.ResetPreviewValuesAll:
	case MenuID.CustomizeToolBar:
	case MenuID.AddTool:
	case MenuID.AddToolBar:
	case MenuID.AddToolGroup:
	case MenuID.ResetToolBarSettings:
		return false;
	}
}

/// フォーカスがコントロール上にある時に限り実行可能なメニュー。
/// !isGlobalMenu(id) is isLocalMenu(id)とは限らない。
@property
bool isLocalMenu(MenuID id) {
	switch (id) {
	case MenuID.EditProp:
	case MenuID.ShowProp:
	case MenuID.Undo:
	case MenuID.Redo:
	case MenuID.Cut:
	case MenuID.Copy:
	case MenuID.Paste:
	case MenuID.Delete:
	case MenuID.Cut1Content:
	case MenuID.Copy1Content:
	case MenuID.Delete1Content:
	case MenuID.PasteInsert:
	case MenuID.Clone:
	case MenuID.SelectAll:
	case MenuID.CopyAll:
	case MenuID.CopyAsText:
	case MenuID.CreateContent:
	case MenuID.ConvertContent:
	case MenuID.Up:
	case MenuID.Down:
	case MenuID.Reverse:
	case MenuID.SwapToParent:
	case MenuID.SwapToChild:
	case MenuID.OverDialog:
	case MenuID.UnderDialog:
	case MenuID.Comment:
	case MenuID.CopyFilePath:
	case MenuID.ToScript:
	case MenuID.ToScript1Content:
	case MenuID.Expand:
	case MenuID.Collapse:
	case MenuID.ResetPreviewValues:
	case MenuID.ResetPreviewValuesAll:
		return true;
	default:
		return false;
	}
}
