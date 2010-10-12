
module cwx.editor.gui.dwt.props;

public import dwt.DWT;
public import dwt.graphics.Point;
public import dwt.graphics.RGB;
public import dwt.graphics.FontData;

import cwx.flag;
import cwx.types;
import cwx.features;
import cwx.utils;
import cwx.area;
import cwx.card;
import cwx.summary;
import cwx.event;
import cwx.race;
import cwx.system;
import cwx.motion;
import cwx.props;
import cwx.editor.gui.dwt.utils;
import cwx.editor.gui.dwt.properties;

import dwt.widgets.Display;
import dwt.graphics.Image;
import dwt.graphics.ImageData;
import dwt.dwthelper.utils;
import dwt.dwthelper.ByteArrayInputStream;

public class Images {
private:
	Image[string] _imgReg;
	Image imgd(string Path)() {
		auto p = Path in _imgReg;
		if (p) {
			return *p;
		} else {
			auto s = new ByteArrayInputStream(cast(byte[]) getImportData!(Path).data);
			scope (exit) s.close;
			auto imgData = new ImageData(s);
			imgData.transparentPixel = imgData.getPixel(0, 0);
			auto img = new Image(Display.getCurrent, imgData);
			_imgReg[Path] = img;
			return img;
		}
	}
	static string resourceDir() {return "";}
public:
	void disposeImages() {
		foreach (p, img; _imgReg) {
			img.dispose;
		}
		typeof(_imgReg) imgReg;
		_imgReg = imgReg;
	}

	Image app() {return imgd!(resourceDir ~ "new.png");}

	Image summary() {return imgd!(resourceDir ~ "summary.png");}

	Image cards() {return imgd!(resourceDir ~ "cards.png");}
	Image backs() {return imgd!(resourceDir ~ "backs.png");}

	Image bgm() {return imgd!(resourceDir ~ "evt_bgm.png");}
	Image se() {return imgd!(resourceDir ~ "evt_se.png");}
	Image unknown() {return imgd!(resourceDir ~ "unknown.png");}

	Image folder() {return imgd!(resourceDir ~ "folder.png");}
	Image scenario() {return imgd!(resourceDir ~ "scenario.png");}

	Image area() {return imgd!(resourceDir ~ "area.png");}
	Image battle() {return imgd!(resourceDir ~ "battle.png");}
	Image packages() {return imgd!(resourceDir ~ "package.png");}

	Image casts() {return imgd!(resourceDir ~ "cast.png");}
	Image skill() {return imgd!(resourceDir ~ "skill.png");}
	Image item() {return imgd!(resourceDir ~ "item.png");}
	Image beast() {return imgd!(resourceDir ~ "beast.png");}
	Image info() {return imgd!(resourceDir ~ "info.png");}

	Image flagDir() {return imgd!(resourceDir ~ "flagdir.png");}
	Image flag() {return imgd!(resourceDir ~ "flag.png");}
	Image step() {return imgd!(resourceDir ~ "step.png");}

	Image couponNormal() {return imgd!(resourceDir ~ "coupon_n.png");}
	Image couponPlus() {return imgd!(resourceDir ~ "coupon_plus.png");}
	Image couponMinus() {return imgd!(resourceDir ~ "coupon_minus.png");}
	Image couponHigh() {return imgd!(resourceDir ~ "coupon.png");}
	Image couponDelete() {return imgd!(resourceDir ~ "evt_stop.png");}

	Image stopBGM() {return imgd!(resourceDir ~ "sound_stop.png");}
	Image playBGM() {return imgd!(resourceDir ~ "sound_play.png");}

	Image evtArrow() {return imgd!(resourceDir ~ "evt_arrow.png");}

	Image evtAddContinue() {return imgd!(resourceDir ~ "evt_add_continue.png");}
	Image evtAutoOpen() {return imgd!(resourceDir ~ "evt_auto_edit.png");}

	Image content(CType type) {
		switch (type) {
		case CType.START: return imgd!(resourceDir ~ "evt_start.png");
		case CType.START_BATTLE: return imgd!(resourceDir ~ "evt_battle.png");
		case CType.END: return imgd!(resourceDir ~ "evt_clear.png");
		case CType.END_BAD_END: return imgd!(resourceDir ~ "evt_gameover.png");
		case CType.CHANGE_AREA: return imgd!(resourceDir ~ "evt_area.png");
		case CType.CHANGE_BG_IMAGE: return imgd!(resourceDir ~ "evt_back.png");
		case CType.EFFECT: return imgd!(resourceDir ~ "evt_effect.png");
		case CType.EFFECT_BREAK: return imgd!(resourceDir ~ "evt_stop.png");
		case CType.LINK_START: return imgd!(resourceDir ~ "evt_link_s.png");
		case CType.LINK_PACKAGE: return imgd!(resourceDir ~ "evt_link_p.png");
		case CType.TALK_MESSAGE: return imgd!(resourceDir ~ "evt_message.png");
		case CType.TALK_DIALOG: return imgd!(resourceDir ~ "evt_speak.png");
		case CType.PLAY_BGM: return imgd!(resourceDir ~ "evt_bgm.png");
		case CType.PLAY_SOUND: return imgd!(resourceDir ~ "evt_se.png");
		case CType.WAIT: return imgd!(resourceDir ~ "evt_wait.png");
		case CType.ELAPSE_TIME: return imgd!(resourceDir ~ "evt_time.png");
		case CType.CALL_START: return imgd!(resourceDir ~ "evt_call_s.png");
		case CType.CALL_PACKAGE: return imgd!(resourceDir ~ "evt_call_p.png");
		case CType.BRANCH_FLAG: return imgd!(resourceDir ~ "evt_br_flag.png");
		case CType.BRANCH_MULTI_STEP: return imgd!(resourceDir ~ "evt_br_step_n.png");
		case CType.BRANCH_STEP: return imgd!(resourceDir ~ "evt_br_step_ul.png");
		case CType.BRANCH_SELECT: return imgd!(resourceDir ~ "evt_br_member.png");
		case CType.BRANCH_ABILITY: return imgd!(resourceDir ~ "evt_br_power.png");
		case CType.BRANCH_RANDOM: return imgd!(resourceDir ~ "evt_br_random.png");
		case CType.BRANCH_LEVEL: return imgd!(resourceDir ~ "evt_br_level.png");
		case CType.BRANCH_STATUS: return imgd!(resourceDir ~ "evt_br_state.png");
		case CType.BRANCH_PARTY_NUMBER: return imgd!(resourceDir ~ "evt_br_num.png");
		case CType.BRANCH_AREA: return imgd!(resourceDir ~ "evt_br_area.png");
		case CType.BRANCH_BATTLE: return imgd!(resourceDir ~ "evt_br_battle.png");
		case CType.BRANCH_IS_BATTLE: return imgd!(resourceDir ~ "evt_br_on_battle.png");
		case CType.BRANCH_CAST: return imgd!(resourceDir ~ "evt_br_cast.png");
		case CType.BRANCH_ITEM: return imgd!(resourceDir ~ "evt_br_item.png");
		case CType.BRANCH_SKILL: return imgd!(resourceDir ~ "evt_br_skill.png");
		case CType.BRANCH_INFO: return imgd!(resourceDir ~ "evt_br_info.png");
		case CType.BRANCH_BEAST: return imgd!(resourceDir ~ "evt_br_beast.png");
		case CType.BRANCH_MONEY: return imgd!(resourceDir ~ "evt_br_money.png");
		case CType.BRANCH_COUPON: return imgd!(resourceDir ~ "evt_br_coupon.png");
		case CType.BRANCH_COMPLETE_STAMP: return imgd!(resourceDir ~ "evt_br_end.png");
		case CType.BRANCH_GOSSIP: return imgd!(resourceDir ~ "evt_br_gossip.png");
		case CType.SET_FLAG: return imgd!(resourceDir ~ "evt_flag_set.png");
		case CType.SET_STEP: return imgd!(resourceDir ~ "evt_step_set.png");
		case CType.SET_STEP_UP: return imgd!(resourceDir ~ "evt_step_plus.png");
		case CType.SET_STEP_DOWN: return imgd!(resourceDir ~ "evt_step_minus.png");
		case CType.REVERSE_FLAG: return imgd!(resourceDir ~ "evt_flag_r.png");
		case CType.CHECK_FLAG: return imgd!(resourceDir ~ "evt_flag_judge.png");
		case CType.GET_CAST: return imgd!(resourceDir ~ "cast.png");
		case CType.GET_ITEM: return imgd!(resourceDir ~ "item.png");
		case CType.GET_SKILL: return imgd!(resourceDir ~ "skill.png");
		case CType.GET_INFO: return imgd!(resourceDir ~ "info.png");
		case CType.GET_BEAST: return imgd!(resourceDir ~ "beast.png");
		case CType.GET_MONEY: return imgd!(resourceDir ~ "money.png");
		case CType.GET_COUPON: return imgd!(resourceDir ~ "coupon.png");
		case CType.GET_COMPLETE_STAMP: return imgd!(resourceDir ~ "end.png");
		case CType.GET_GOSSIP: return imgd!(resourceDir ~ "gossip.png");
		case CType.LOSE_CAST: return imgd!(resourceDir ~ "evt_lost_cast.png");
		case CType.LOSE_ITEM: return imgd!(resourceDir ~ "evt_lost_item.png");
		case CType.LOSE_SKILL: return imgd!(resourceDir ~ "evt_lost_skill.png");
		case CType.LOSE_INFO: return imgd!(resourceDir ~ "evt_lost_info.png");
		case CType.LOSE_BEAST: return imgd!(resourceDir ~ "evt_lost_beast.png");
		case CType.LOSE_MONEY: return imgd!(resourceDir ~ "evt_lost_money.png");
		case CType.LOSE_COUPON: return imgd!(resourceDir ~ "evt_lost_coupon.png");
		case CType.LOSE_COMPLETE_STAMP: return imgd!(resourceDir ~ "evt_lost_end.png");
		case CType.LOSE_GOSSIP: return imgd!(resourceDir ~ "evt_lost_gossip.png");
		case CType.SHOW_PARTY: return imgd!(resourceDir ~ "evt_show_party.png");
		case CType.HIDE_PARTY: return imgd!(resourceDir ~ "evt_hide_party.png");
		case CType.REDISPLAY: return imgd!(resourceDir ~ "evt_refresh.png");
		default: assert (0);
		}
	}

	Image msnDelete() {return imgd!(resourceDir ~ "evt_stop.png");}

	Image motion(MType type) {
		switch (type) {
		case MType.HEAL: return imgd!(resourceDir ~ "msn_heal.png");
		case MType.DAMAGE: return imgd!(resourceDir ~ "msn_damage.png");
		case MType.ABSORB: return imgd!(resourceDir ~ "msn_absorb.png");
		case MType.PARALYZE: return imgd!(resourceDir ~ "msn_paralyze.png");
		case MType.DIS_PARALYZE: return imgd!(resourceDir ~ "msn_dis_paralyze.png");
		case MType.POISON: return imgd!(resourceDir ~ "msn_poison.png");
		case MType.DIS_POISON: return imgd!(resourceDir ~ "msn_dis_poison.png");
		case MType.GET_SKILL_POWER: return imgd!(resourceDir ~ "msn_get_skill_power.png");
		case MType.LOSE_SKILL_POWER: return imgd!(resourceDir ~ "msn_lose_skill_power.png");
		case MType.SLEEP: return imgd!(resourceDir ~ "msn_sleep.png");
		case MType.CONFUSE: return imgd!(resourceDir ~ "msn_confuse.png");
		case MType.OVERHEAT: return imgd!(resourceDir ~ "msn_overheat.png");
		case MType.BRAVE: return imgd!(resourceDir ~ "msn_brave.png");
		case MType.PANIC: return imgd!(resourceDir ~ "msn_panic.png");
		case MType.NORMAL: return imgd!(resourceDir ~ "msn_wakeup.png");
		case MType.BIND: return imgd!(resourceDir ~ "msn_bind.png");
		case MType.DIS_BIND: return imgd!(resourceDir ~ "msn_dis_bind.png");
		case MType.SILENCE: return imgd!(resourceDir ~ "msn_silence.png");
		case MType.DIS_SILENCE: return imgd!(resourceDir ~ "msn_dis_silence.png");
		case MType.FACE_UP: return imgd!(resourceDir ~ "msn_face_up.png");
		case MType.FACE_DOWN: return imgd!(resourceDir ~ "msn_face_down.png");
		case MType.ANTI_MAGIC: return imgd!(resourceDir ~ "msn_anti_magic.png");
		case MType.DIS_ANTI_MAGIC: return imgd!(resourceDir ~ "msn_dis_anti_magic.png");
		case MType.ENHANCE_ACTION: return imgd!(resourceDir ~ "msn_enh_action.png");
		case MType.ENHANCE_AVOID: return imgd!(resourceDir ~ "msn_enh_avoid.png");
		case MType.ENHANCE_DEFENSE: return imgd!(resourceDir ~ "msn_enh_defense.png");
		case MType.ENHANCE_RESIST: return imgd!(resourceDir ~ "msn_enh_resist.png");
		case MType.VANISH_TARGET: return imgd!(resourceDir ~ "evt_lost_cast.png");
		case MType.VANISH_CARD: return imgd!(resourceDir ~ "msn_vanish_hand.png");
		case MType.VANISH_BEAST: return imgd!(resourceDir ~ "evt_lost_beast.png");
		case MType.DEAL_ATTACK_CARD: return imgd!(resourceDir ~ "hand_attack.png");
		case MType.DEAL_POWERFUL_ATTACK_CARD: return imgd!(resourceDir ~ "hand_p_attack.png");
		case MType.DEAL_CRITICAL_ATTACK_CARD: return imgd!(resourceDir ~ "hand_c_attack.png");
		case MType.DEAL_FEINT_CARD: return imgd!(resourceDir ~ "hand_feint.png");
		case MType.DEAL_DEFENSE_CARD: return imgd!(resourceDir ~ "hand_defense.png");
		case MType.DEAL_DISTANCE_CARD: return imgd!(resourceDir ~ "hand_distance.png");
		case MType.DEAL_CONFUSE_CARD: return imgd!(resourceDir ~ "hand_confuse.png");
		case MType.DEAL_SKILL_CARD: return imgd!(resourceDir ~ "hand_skill.png");
		case MType.SUMMON_BEAST: return imgd!(resourceDir ~ "msn_summon.png");
		default: assert (0);
		}
	}

	Image element(Element el) {
		switch (el) {
		case Element.ALL:
			return imgd!(resourceDir ~ "elm_all.png");
		case Element.HEALTH:
			return imgd!(resourceDir ~ "elm_health.png");
		case Element.MIND:
			return imgd!(resourceDir ~ "elm_mind.png");
		case Element.MIRACLE:
			return imgd!(resourceDir ~ "elm_miracle.png");
		case Element.MAGIC:
			return imgd!(resourceDir ~ "elm_magic.png");
		case Element.FIRE:
			return imgd!(resourceDir ~ "elm_fire.png");
		case Element.ICE:
			return imgd!(resourceDir ~ "elm_ice.png");
		}
	}

	Image talker(Talker t) {
		switch (t) {
		case Talker.SELECTED:
			return imgd!(resourceDir ~ "talker_sel.png");
		case Talker.UNSELECTED:
			return imgd!(resourceDir ~ "talker_unsel.png");
		case Talker.RANDOM:
			return imgd!(resourceDir ~ "talker_random.png");
		}
	}

	Image eventTree() {return imgd!(resourceDir ~ "event_tree.png");}
	Image defStart() {return imgd!(resourceDir ~ "def_start.png");}
	Image keyCode() {return imgd!(resourceDir ~ "key_code.png");}
	Image round() {return imgd!(resourceDir ~ "round.png");}

	Image addCoupon() {return imgd!(resourceDir ~ "coupon.png");}
	Image altCoupon() {return imgd!(resourceDir ~ "alt_coupon.png");}
	Image delCoupon() {return imgd!(resourceDir ~ "evt_stop.png");}

	Image setBeast() {return imgd!(resourceDir ~ "set_beast.png");}

	Image sound() {return imgd!(resourceDir ~ "evt_se.png");}
	Image stopSound() {return imgd!(resourceDir ~ "sound_stop.png");}
	Image playSound() {return imgd!(resourceDir ~ "sound_play.png");}

	Image setTalkerCoupon() {return imgd!(resourceDir ~ "set_beast.png");}
	Image defaultColor() {return imgd!(resourceDir ~ "cc_w.png");}
	Image red() {return imgd!(resourceDir ~ "cc_r.png");}
	Image blue() {return imgd!(resourceDir ~ "cc_b.png");}
	Image green() {return imgd!(resourceDir ~ "cc_g.png");}
	Image yellow() {return imgd!(resourceDir ~ "cc_y.png");}
	Image scTalker(Talker talker) {
		switch (talker) {
		case Talker.SELECTED:
			return imgd!(resourceDir ~ "sc_m.png");
		case Talker.UNSELECTED:
			return imgd!(resourceDir ~ "sc_u.png");
		case Talker.RANDOM:
			return imgd!(resourceDir ~ "sc_r.png");
		case Talker.CARD:
			return imgd!(resourceDir ~ "sc_c.png");
		}
	}
	Image scRef() {return imgd!(resourceDir ~ "sc_i.png");}
	Image scTeam() {return imgd!(resourceDir ~ "sc_t.png");}
	Image scYado() {return imgd!(resourceDir ~ "sc_y.png");}

	Image createDialog() {return imgd!(resourceDir ~ "evt_speak.png");}
	Image deleteDialog() {return imgd!(resourceDir ~ "evt_stop.png");}
	Image copyToDialogs() {return imgd!(resourceDir ~ "copy_dialog.png");}
	Image copyToUpper() {return imgd!(resourceDir ~ "copy_dialog_u.png");}
	Image copyToLower() {return imgd!(resourceDir ~ "copy_dialog_l.png");}

	Image summaryFile() {return imgd!(resourceDir ~ "summary_file.png");}
	Image scenarioArchive() {return imgd!(resourceDir ~ "scenario_arc.png");}
	Image classic() {return imgd!(resourceDir ~ "classic.png");}

	Image menuRefresh() {return imgd!(resourceDir ~ "refresh.png");}

	Image menuCEdit() {return imgd!(resourceDir ~ "edit.png");}

	Image menuUndo() {return imgd!(resourceDir ~ "undo.png");}
	Image menuRedo() {return imgd!(resourceDir ~ "redo.png");}

	Image menuCut() {return imgd!(resourceDir ~ "cut.png");}
	Image menuCopy() {return imgd!(resourceDir ~ "copy.png");}
	Image menuPaste() {return imgd!(resourceDir ~ "paste.png");}
	Image menuDel() {return imgd!(resourceDir ~ "del.png");}

	Image menuToXML() {return imgd!(resourceDir ~ "toxml.png");}

	Image menuNew() {return imgd!(resourceDir ~ "new.png");}
	Image menuOpen() {return imgd!(resourceDir ~ "open.png");}
	Image menuClose() {return imgd!(resourceDir ~ "close.png");}
	Image menuCloseWin() {return imgd!(resourceDir ~ "close_win.png");}
	Image menuSave() {return imgd!(resourceDir ~ "save.png");}
	Image menuSaveA() {return imgd!(resourceDir ~ "save_a.png");}

	Image menuDataWin() {return imgd!(resourceDir ~ "data_win.png");}
	Image menuFlagWin() {return imgd!(resourceDir ~ "flag_win.png");}
	Image menuCardWin() {return imgd!(resourceDir ~ "card_win.png");}
	Image menuDirWin() {return imgd!(resourceDir ~ "dir_win.png");}

	Image menuChangeVH() {return imgd!(resourceDir ~ "chg_vh.png");}

	Image menuExecEngine() {return imgd!(resourceDir ~ "exec_engine.png");}
	Image menuSettings() {return imgd!(resourceDir ~ "settings.png");}

	Image menuSummary() {return imgd!(resourceDir ~ "summary.png");}
	Image menuNewArea() {return imgd!(resourceDir ~ "area_new.png");}
	Image menuNewBattle() {return imgd!(resourceDir ~ "battle_new.png");}
	Image menuNewPackage() {return imgd!(resourceDir ~ "package_new.png");}

	Image menuNewFlagDir() {return imgd!(resourceDir ~ "flagdir_new.png");}
	Image menuNewFlag() {return imgd!(resourceDir ~ "flag_new.png");}
	Image menuNewStep() {return imgd!(resourceDir ~ "step_new.png");}

	Image menuViewParty() {return imgd!(resourceDir ~ "partyCards.png");}
	Image menuEnemyCardDebugView() {return imgd!(resourceDir ~ "card_life.png");}
	Image menuViewCards() {return imgd!(resourceDir ~ "cards.png");}
	Image menuViewBacks() {return imgd!(resourceDir ~ "backs.png");}
	Image menuUp() {return imgd!(resourceDir ~ "up.png");}
	Image menuDown() {return imgd!(resourceDir ~ "down.png");}
	Image menuNewMenuCard() {return imgd!(resourceDir ~ "card_new.png");}
	Image menuNewEnemyCard() {return imgd!(resourceDir ~ "card_new.png");}
	Image menuNewBack() {return imgd!(resourceDir ~ "back_new.png");}
	Image menuAuto() {return imgd!(resourceDir ~ "auto.png");}
	Image menuCustom() {return imgd!(resourceDir ~ "custom.png");}
	Image menuMask() {return imgd!(resourceDir ~ "mask.png");}
	Image menuDoEscape() {return imgd!(resourceDir ~ "escape.png");}
	Image menuPosTop() {return imgd!(resourceDir ~ "pos_top.png");}
	Image menuPosBottom() {return imgd!(resourceDir ~ "pos_bottom.png");}
	Image menuPosLeft() {return imgd!(resourceDir ~ "pos_left.png");}
	Image menuPosRight() {return imgd!(resourceDir ~ "pos_right.png");}
	Image menuPosEven() {return imgd!(resourceDir ~ "pos_even.png");}
	Image menuScaleMin() {return imgd!(resourceDir ~ "scale_min.png");}
	Image menuScaleMiddle() {return imgd!(resourceDir ~ "scale_middle.png");}
	Image menuScaleMax() {return imgd!(resourceDir ~ "scale_max.png");}
	Image menuScaleEvenBig() {return imgd!(resourceDir ~ "scale_even_big.png");}
	Image menuScaleEvenSmall() {return imgd!(resourceDir ~ "scale_even_small.png");}

	Image menuNewEventTree() {return imgd!(resourceDir ~ "event_tree.png");}
	Image menuNewEventFire() {return imgd!(resourceDir ~ "def_start.png");}
	Image menuTreeOpen() {return imgd!(resourceDir ~ "tree_open.png");}
	Image menuTreeClose() {return imgd!(resourceDir ~ "tree_close.png");}

	Image menuShowCardLife() {return imgd!(resourceDir ~ "card_life.png");}
	Image menuShowCardList() {return imgd!(resourceDir ~ "card_list.png");}
	Image menuShowCardTable() {return imgd!(resourceDir ~ "card_table.png");}
	Image menuAddScenario() {return imgd!(resourceDir ~ "add_scenario.png");}
	Image menuNewCast() {return imgd!(resourceDir ~ "cast_new.png");}
	Image menuNewSkill() {return imgd!(resourceDir ~ "skill_new.png");}
	Image menuNewItem() {return imgd!(resourceDir ~ "item_new.png");}
	Image menuNewBeast() {return imgd!(resourceDir ~ "beast_new.png");}
	Image menuNewInfo() {return imgd!(resourceDir ~ "info_new.png");}

	Image menuAdd() {return imgd!(resourceDir ~ "add.png");}

	Image menuEditHand() {return imgd!(resourceDir ~ "card_hand.png");}
	Image menuOpenHand() {return imgd!(resourceDir ~ "card_hand.png");}
	Image menuEditUseEvent() {return imgd!(resourceDir ~ "event_tree.png");}

	Image menuOpenDirectory() {return imgd!(resourceDir ~ "folder.png");}
	Image menuNewFolder() {return imgd!(resourceDir ~ "folder_new.png");}
	Image menuReplacePath() {return imgd!(resourceDir ~ "replace.png");}

	Image menuReplaceText() {return imgd!(resourceDir ~ "replace.png");}
	Image menuReload() {return imgd!(resourceDir ~ "reload.png");}

	Image menuStartToPackage() {return imgd!(resourceDir ~ "s_to_p.png");}
	Image menuConvertContent() {return imgd!(resourceDir ~ "conv_cont.png");}
}

enum MenuID : int {
	Refresh,
	CEdit,
	Undo,
	Redo,
	Cut,
	Copy,
	Paste,
	Del,
	ToXML,
	New,
	Open,
	Close,
	CloseWin,
	Save,
	SaveA,
	DataWin,
	FlagWin,
	CardWin,
	DirWin,
	ChangeVH,
	ExecEngine,
	Settings,
	Summary,
	NewArea,
	NewBattle,
	NewPackage,
	NewFlagDir,
	NewFlag,
	NewStep,
	ViewParty,
	EnemyCardDebugView,
	ViewCards,
	ViewBacks,
	Up,
	Down,
	NewMenuCard,
	NewEnemyCard,
	NewBack,
	Auto,
	Custom,
	Mask,
	DoEscape,
	PosTop,
	PosBottom,
	PosLeft,
	PosRight,
	PosEven,
	ScaleMin,
	ScaleMiddle,
	ScaleMax,
	ScaleEvenBig,
	ScaleEvenSmall,
	NewEventTree,
	NewEventFire,
	TreeOpen,
	TreeClose,
	ShowCardLife,
	ShowCardList,
	ShowCardTable,
	AddScenario,
	NewCast,
	NewSkill,
	NewItem,
	NewBeast,
	NewInfo,
	Add,
	EditHand,
	OpenHand,
	EditUseEvent,
	OpenDirectory,
	NewFolder,
	ReplacePath,
	ReplaceText,
	Reload,
	StartToPackage,
	ConvertContent
}

public class Props {
private:
	CProps _parent;
	Images _images;
	FlexProps _var;
public:
	this(string propFilePath, CProps parent) {
		_parent = parent;
		_images = new Images;
		_var = new FlexProps(propFilePath);
	}
	string tempPath() {
		if (std.path.isabs(var.etc.tempPath)) {
			return var.etc.tempPath;
		} else {
			return std.path.join(std.path.getDirName(parent.appPath), var.etc.tempPath);
		}
	}
	CProps parent() {return _parent;}
	cwx.system.System sys() {return _parent.sys;}
	Images images() {return _images;}
	Msgs msgs() {return _parent.msgs;}
	Looks looks() {return _parent.looks;}
	FlexProps var() {return _var;}
}

/// CPoint等の構造体をDWTのクラスに変換するための関数。
Point dwtData(CPoint v) {return new Point(v.x, v.y);}
/// ditto
Point dwtData(CSize v) {return new Point(v.width, v.height);}
/// ditto
RGB dwtData(CRGB v, out int alpha) {
	alpha = v.a;
	return new RGB(cast(int) v.r, cast(int) v.g, cast(int) v.b);
}
/// ditto
FontData dwtData(CFont v) {
	int flag = DWT.NONE;
	if (v.bold) flag |= DWT.BOLD;
	if (v.italic) flag |= DWT.ITALIC;
	return new FontData(v.name, cast(int) v.point, flag == DWT.NONE ? DWT.NORMAL : flag);
}
