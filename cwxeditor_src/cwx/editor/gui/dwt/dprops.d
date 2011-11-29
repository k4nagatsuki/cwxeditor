
module cwx.editor.gui.dwt.dprops;

public import org.eclipse.swt.SWT;
public import org.eclipse.swt.graphics.Point;
public import org.eclipse.swt.graphics.RGB;
public import org.eclipse.swt.graphics.FontData;

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
import cwx.structs;
import cwx.msgs;

import cwx.editor.gui.dwt.properties;

import std.file;
import std.path;

import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.ImageData;
import java.lang.all;
import java.io.ByteArrayInputStream;

public class Images {
private:
	string _appPath;
	Image[string] _imgReg;
	Image imgd(string Path)() {
		auto p = Path in _imgReg;
		if (p) {
			return *p;
		} else {
			string dir = _appPath.dirName;
			string dynPath = dir.buildPath(resourceDir).buildPath(Path);
			ImageData imgData = null;
			if (.exists(dynPath)) {
				try {
					auto s = new ByteArrayInputStream(cast(byte[]) std.file.read(dynPath));
					scope (exit) s.close;
					imgData = new ImageData(s);
				} catch (Exception e) {
					debugln(e);
				}
			}
			if (!imgData) {
				auto s = new ByteArrayInputStream(cast(byte[]) getImportData!(Path).data);
				scope (exit) s.close;
				imgData = new ImageData(s);
			}
			imgData.transparentPixel = imgData.getPixel(0, 0);
			auto img = new Image(Display.getCurrent, imgData);
			_imgReg[Path] = img;
			return img;
		}
	}
	static string resourceDir() {return "resource";}
public:
	this (string appPath) {
		_appPath = appPath;
	}

	void disposeImages() {
		foreach (p, img; _imgReg) {
			img.dispose;
		}
		typeof(_imgReg) imgReg;
		_imgReg = imgReg;
	}

	Image app() {return imgd!("new.png");}
	Image menuVersion() {return imgd!("version.png");}
	Image icon() {return imgd!("cwxeditor.ico");}

	Image text() {return imgd!("text.png");}

	Image classicEngine() {return imgd!("classic_engine.png");}

	Image warning() {return imgd!("warning.png");}

	Image summary() {return imgd!("summary.png");}

	Image cards() {return imgd!("cards.png");}
	Image backs() {return imgd!("backs.png");}

	Image bgm() {return imgd!("evt_bgm.png");}
	Image se() {return imgd!("evt_se.png");}
	Image unknown() {return imgd!("unknown.png");}

	Image folder() {return imgd!("folder.png");}
	Image scenario() {return imgd!("scenario.png");}

	Image area() {return imgd!("area.png");}
	Image battle() {return imgd!("battle.png");}
	Image packages() {return imgd!("package.png");}

	Image areaSceneView() {return imgd!("area_cards.png");}
	Image areaEventTreeView() {return imgd!("area_event.png");}
	Image battleSceneView() {return imgd!("battle_cards.png");}
	Image battleEventTreeView() {return imgd!("battle_event.png");}

	Image casts() {return imgd!("cast.png");}
	Image skill() {return imgd!("skill.png");}
	Image item() {return imgd!("item.png");}
	Image beast() {return imgd!("beast.png");}
	Image info() {return imgd!("info.png");}

	Image flagDir() {return imgd!("flagdir.png");}
	Image flag() {return imgd!("flag.png");}
	Image step() {return imgd!("step.png");}

	Image couponNormal() {return imgd!("coupon_n.png");}
	Image couponPlus() {return imgd!("coupon_plus.png");}
	Image couponMinus() {return imgd!("coupon_minus.png");}
	Image couponHigh() {return imgd!("coupon.png");}
	Image couponDelete() {return imgd!("evt_stop.png");}

	Image stopBGM() {return imgd!("sound_stop.png");}
	Image playBGM() {return imgd!("sound_play.png");}

	Image evtArrow() {return imgd!("evt_arrow.png");}

	Image evtAddContinue() {return imgd!("evt_add_continue.png");}
	Image evtAutoOpen() {return imgd!("evt_auto_edit.png");}

	Image menuEvtTerminal() {return imgd!("evt_j_term.png");}
	Image menuEvtStandard() {return imgd!("evt_j_std.png");}
	Image menuEvtData() {return imgd!("evt_j_data.png");}
	Image menuEvtUtility() {return imgd!("evt_j_util.png");}
	Image menuEvtBranch() {return imgd!("evt_j_br.png");}
	Image menuEvtGet() {return imgd!("evt_j_get.png");}
	Image menuEvtLost() {return imgd!("evt_j_lost.png");}
	Image menuEvtVisual() {return imgd!("evt_j_vis.png");}

	Image content(CType type) {
		switch (type) {
		case CType.START: return imgd!("evt_start.png");
		case CType.START_BATTLE: return imgd!("evt_battle.png");
		case CType.END: return imgd!("evt_clear.png");
		case CType.END_BAD_END: return imgd!("evt_gameover.png");
		case CType.CHANGE_AREA: return imgd!("evt_area.png");
		case CType.CHANGE_BG_IMAGE: return imgd!("evt_back.png");
		case CType.EFFECT: return imgd!("evt_effect.png");
		case CType.EFFECT_BREAK: return imgd!("evt_stop.png");
		case CType.LINK_START: return imgd!("evt_link_s.png");
		case CType.LINK_PACKAGE: return imgd!("evt_link_p.png");
		case CType.TALK_MESSAGE: return imgd!("evt_message.png");
		case CType.TALK_DIALOG: return imgd!("evt_speak.png");
		case CType.PLAY_BGM: return imgd!("evt_bgm.png");
		case CType.PLAY_SOUND: return imgd!("evt_se.png");
		case CType.WAIT: return imgd!("evt_wait.png");
		case CType.ELAPSE_TIME: return imgd!("evt_time.png");
		case CType.CALL_START: return imgd!("evt_call_s.png");
		case CType.CALL_PACKAGE: return imgd!("evt_call_p.png");
		case CType.BRANCH_FLAG: return imgd!("evt_br_flag.png");
		case CType.BRANCH_MULTI_STEP: return imgd!("evt_br_step_n.png");
		case CType.BRANCH_STEP: return imgd!("evt_br_step_ul.png");
		case CType.BRANCH_SELECT: return imgd!("evt_br_member.png");
		case CType.BRANCH_ABILITY: return imgd!("evt_br_power.png");
		case CType.BRANCH_RANDOM: return imgd!("evt_br_random.png");
		case CType.BRANCH_LEVEL: return imgd!("evt_br_level.png");
		case CType.BRANCH_STATUS: return imgd!("evt_br_state.png");
		case CType.BRANCH_PARTY_NUMBER: return imgd!("evt_br_num.png");
		case CType.BRANCH_AREA: return imgd!("evt_br_area.png");
		case CType.BRANCH_BATTLE: return imgd!("evt_br_battle.png");
		case CType.BRANCH_IS_BATTLE: return imgd!("evt_br_on_battle.png");
		case CType.BRANCH_CAST: return imgd!("evt_br_cast.png");
		case CType.BRANCH_ITEM: return imgd!("evt_br_item.png");
		case CType.BRANCH_SKILL: return imgd!("evt_br_skill.png");
		case CType.BRANCH_INFO: return imgd!("evt_br_info.png");
		case CType.BRANCH_BEAST: return imgd!("evt_br_beast.png");
		case CType.BRANCH_MONEY: return imgd!("evt_br_money.png");
		case CType.BRANCH_COUPON: return imgd!("evt_br_coupon.png");
		case CType.BRANCH_COMPLETE_STAMP: return imgd!("evt_br_end.png");
		case CType.BRANCH_GOSSIP: return imgd!("evt_br_gossip.png");
		case CType.SET_FLAG: return imgd!("evt_flag_set.png");
		case CType.SET_STEP: return imgd!("evt_step_set.png");
		case CType.SET_STEP_UP: return imgd!("evt_step_plus.png");
		case CType.SET_STEP_DOWN: return imgd!("evt_step_minus.png");
		case CType.REVERSE_FLAG: return imgd!("evt_flag_r.png");
		case CType.CHECK_FLAG: return imgd!("evt_flag_judge.png");
		case CType.GET_CAST: return imgd!("cast.png");
		case CType.GET_ITEM: return imgd!("item.png");
		case CType.GET_SKILL: return imgd!("skill.png");
		case CType.GET_INFO: return imgd!("info.png");
		case CType.GET_BEAST: return imgd!("beast.png");
		case CType.GET_MONEY: return imgd!("money.png");
		case CType.GET_COUPON: return imgd!("coupon.png");
		case CType.GET_COMPLETE_STAMP: return imgd!("end.png");
		case CType.GET_GOSSIP: return imgd!("gossip.png");
		case CType.LOSE_CAST: return imgd!("evt_lost_cast.png");
		case CType.LOSE_ITEM: return imgd!("evt_lost_item.png");
		case CType.LOSE_SKILL: return imgd!("evt_lost_skill.png");
		case CType.LOSE_INFO: return imgd!("evt_lost_info.png");
		case CType.LOSE_BEAST: return imgd!("evt_lost_beast.png");
		case CType.LOSE_MONEY: return imgd!("evt_lost_money.png");
		case CType.LOSE_COUPON: return imgd!("evt_lost_coupon.png");
		case CType.LOSE_COMPLETE_STAMP: return imgd!("evt_lost_end.png");
		case CType.LOSE_GOSSIP: return imgd!("evt_lost_gossip.png");
		case CType.SHOW_PARTY: return imgd!("evt_show_party.png");
		case CType.HIDE_PARTY: return imgd!("evt_hide_party.png");
		case CType.REDISPLAY: return imgd!("evt_refresh.png");
		default: assert (0);
		}
	}

	Image msnDelete() {return imgd!("evt_stop.png");}

	Image motion(MType type) {
		switch (type) {
		case MType.HEAL: return imgd!("msn_heal.png");
		case MType.DAMAGE: return imgd!("msn_damage.png");
		case MType.ABSORB: return imgd!("msn_absorb.png");
		case MType.PARALYZE: return imgd!("msn_paralyze.png");
		case MType.DIS_PARALYZE: return imgd!("msn_dis_paralyze.png");
		case MType.POISON: return imgd!("msn_poison.png");
		case MType.DIS_POISON: return imgd!("msn_dis_poison.png");
		case MType.GET_SKILL_POWER: return imgd!("msn_get_skill_power.png");
		case MType.LOSE_SKILL_POWER: return imgd!("msn_lose_skill_power.png");
		case MType.SLEEP: return imgd!("msn_sleep.png");
		case MType.CONFUSE: return imgd!("msn_confuse.png");
		case MType.OVERHEAT: return imgd!("msn_overheat.png");
		case MType.BRAVE: return imgd!("msn_brave.png");
		case MType.PANIC: return imgd!("msn_panic.png");
		case MType.NORMAL: return imgd!("msn_wakeup.png");
		case MType.BIND: return imgd!("msn_bind.png");
		case MType.DIS_BIND: return imgd!("msn_dis_bind.png");
		case MType.SILENCE: return imgd!("msn_silence.png");
		case MType.DIS_SILENCE: return imgd!("msn_dis_silence.png");
		case MType.FACE_UP: return imgd!("msn_face_up.png");
		case MType.FACE_DOWN: return imgd!("msn_face_down.png");
		case MType.ANTI_MAGIC: return imgd!("msn_anti_magic.png");
		case MType.DIS_ANTI_MAGIC: return imgd!("msn_dis_anti_magic.png");
		case MType.ENHANCE_ACTION: return imgd!("msn_enh_action.png");
		case MType.ENHANCE_AVOID: return imgd!("msn_enh_avoid.png");
		case MType.ENHANCE_DEFENSE: return imgd!("msn_enh_defense.png");
		case MType.ENHANCE_RESIST: return imgd!("msn_enh_resist.png");
		case MType.VANISH_TARGET: return imgd!("evt_lost_cast.png");
		case MType.VANISH_CARD: return imgd!("msn_vanish_hand.png");
		case MType.VANISH_BEAST: return imgd!("evt_lost_beast.png");
		case MType.DEAL_ATTACK_CARD: return imgd!("hand_attack.png");
		case MType.DEAL_POWERFUL_ATTACK_CARD: return imgd!("hand_p_attack.png");
		case MType.DEAL_CRITICAL_ATTACK_CARD: return imgd!("hand_c_attack.png");
		case MType.DEAL_FEINT_CARD: return imgd!("hand_feint.png");
		case MType.DEAL_DEFENSE_CARD: return imgd!("hand_defense.png");
		case MType.DEAL_DISTANCE_CARD: return imgd!("hand_distance.png");
		case MType.DEAL_CONFUSE_CARD: return imgd!("hand_confuse.png");
		case MType.DEAL_SKILL_CARD: return imgd!("hand_skill.png");
		case MType.SUMMON_BEAST: return imgd!("msn_summon.png");
		default: assert (0);
		}
	}

	Image element(Element el) {
		final switch (el) {
		case Element.ALL:
			return imgd!("elm_all.png");
		case Element.HEALTH:
			return imgd!("elm_health.png");
		case Element.MIND:
			return imgd!("elm_mind.png");
		case Element.MIRACLE:
			return imgd!("elm_miracle.png");
		case Element.MAGIC:
			return imgd!("elm_magic.png");
		case Element.FIRE:
			return imgd!("elm_fire.png");
		case Element.ICE:
			return imgd!("elm_ice.png");
		}
	}

	Image talker(Talker t) {
		final switch (t) {
		case Talker.SELECTED:
			return imgd!("talker_sel.png");
		case Talker.UNSELECTED:
			return imgd!("talker_unsel.png");
		case Talker.RANDOM:
			return imgd!("talker_random.png");
		case Talker.NARRATION, Talker.IMAGE, Talker.CARD:
			throw new Exception("Narration, image and card haven't image.");
		}
	}

	Image eventTree() {return imgd!("event_tree.png");}
	Image defStart() {return imgd!("def_start.png");}
	Image keyCode() {return imgd!("key_code.png");}
	Image round() {return imgd!("round.png");}
	Image menuKeyCodeTimingUse() {return imgd!("key_code.png");}
	Image menuKeyCodeTimingSuccess() {return imgd!("key_code_suc.png");}
	Image menuKeyCodeTimingFailure() {return imgd!("key_code_fail.png");}

	Image menuAddManyRounds() {return imgd!("add_many_round.png");}

	Image addCoupon() {return imgd!("coupon.png");}
	Image altCoupon() {return imgd!("alt_coupon.png");}
	Image delCoupon() {return imgd!("evt_stop.png");}

	Image setBeast() {return imgd!("set_beast.png");}

	Image sound() {return imgd!("evt_se.png");}
	Image stopSound() {return imgd!("sound_stop.png");}
	Image playSound() {return imgd!("sound_play.png");}

	Image setTalkerCoupon() {return imgd!("set_beast.png");}
	Image defaultColor() {return imgd!("cc_w.png");}
	Image red() {return imgd!("cc_r.png");}
	Image blue() {return imgd!("cc_b.png");}
	Image green() {return imgd!("cc_g.png");}
	Image yellow() {return imgd!("cc_y.png");}
	Image scTalker(Talker talker) {
		final switch (talker) {
		case Talker.SELECTED:
			return imgd!("sc_m.png");
		case Talker.UNSELECTED:
			return imgd!("sc_u.png");
		case Talker.RANDOM:
			return imgd!("sc_r.png");
		case Talker.CARD:
			return imgd!("sc_c.png");
		case Talker.NARRATION, Talker.IMAGE:
			throw new Exception("Narration and image haven't image.");
		}
	}
	Image scRef() {return imgd!("sc_i.png");}
	Image scTeam() {return imgd!("sc_t.png");}
	Image scYado() {return imgd!("sc_y.png");}

	Image createDialog() {return imgd!("evt_speak.png");}
	Image deleteDialog() {return imgd!("evt_stop.png");}
	Image copyToDialogs() {return imgd!("copy_dialog.png");}
	Image copyToUpper() {return imgd!("copy_dialog_u.png");}
	Image copyToLower() {return imgd!("copy_dialog_l.png");}

	Image summaryFile() {return imgd!("summary_file.png");}
	Image scenarioArchive() {return imgd!("scenario_arc.png");}
	Image classic() {return imgd!("classic.png");}

	Image menuRefresh() {return imgd!("refresh.png");}

	Image menuCEdit() {return imgd!("edit.png");}

	Image menuUndo() {return imgd!("undo.png");}
	Image menuRedo() {return imgd!("redo.png");}

	Image menuCut() {return imgd!("cut.png");}
	Image menuCopy() {return imgd!("copy.png");}
	Image menuPaste() {return imgd!("paste.png");}
	Image menuDel() {return imgd!("del.png");}
	Image menuSelectAll() {return imgd!("select_all.png");}

	Image menuToXML() {return imgd!("toxml.png");}

	Image menuNew() {return imgd!("new.png");}
	Image menuOpen() {return imgd!("open.png");}
	Image menuClose() {return imgd!("close.png");}
	Image menuCloseWin() {return imgd!("close_win.png");}
	Image menuSave() {return imgd!("save.png");}
	Image menuSaveA() {return imgd!("save_a.png");}

	Image menuDataWin() {return imgd!("data_win.png");}
	Image menuFlagWin() {return imgd!("flag_win.png");}
	Image menuCardWin() {return imgd!("card_win.png");}
	Image menuCastWin() {return imgd!("cast_win.png");}
	Image menuSkillWin() {return imgd!("skill_win.png");}
	Image menuItemWin() {return imgd!("item_win.png");}
	Image menuBeastWin() {return imgd!("beast_win.png");}
	Image menuInfoWin() {return imgd!("info_win.png");}
	Image menuDirWin() {return imgd!("dir_win.png");}

	Image menuChangeVH() {return imgd!("chg_vh.png");}

	Image menuExecEngine() {return imgd!("exec_engine.png");}
	Image menuSettings() {return imgd!("settings.png");}

	Image menuSummary() {return imgd!("summary.png");}
	Image menuNewArea() {return imgd!("area_new.png");}
	Image menuNewBattle() {return imgd!("battle_new.png");}
	Image menuNewPackage() {return imgd!("package_new.png");}

	Image menuNewFlagDir() {return imgd!("flagdir_new.png");}
	Image menuNewFlag() {return imgd!("flag_new.png");}
	Image menuNewStep() {return imgd!("step_new.png");}

	Image menuViewParty() {return imgd!("party_cards.png");}
	Image menuViewMsg() {return imgd!("view_msg.png");}
	Image menuFixed() {return imgd!("fixed.png");}
	Image menuEnemyCardDebugView() {return imgd!("card_life.png");}
	Image menuViewCards() {return imgd!("cards.png");}
	Image menuViewBacks() {return imgd!("backs.png");}
	Image menuUp() {return imgd!("up.png");}
	Image menuDown() {return imgd!("down.png");}
	Image menuNewMenuCard() {return imgd!("card_new.png");}
	Image menuNewEnemyCard() {return imgd!("card_new.png");}
	Image menuNewBack() {return imgd!("back_new.png");}
	Image menuAuto() {return imgd!("auto.png");}
	Image menuCustom() {return imgd!("custom.png");}
	Image menuMask() {return imgd!("mask.png");}
	Image menuDoEscape() {return imgd!("escape.png");}
	Image menuPosTop() {return imgd!("pos_top.png");}
	Image menuPosBottom() {return imgd!("pos_bottom.png");}
	Image menuPosLeft() {return imgd!("pos_left.png");}
	Image menuPosRight() {return imgd!("pos_right.png");}
	Image menuPosEven() {return imgd!("pos_even.png");}
	Image menuScaleMin() {return imgd!("scale_min.png");}
	Image menuScaleMiddle() {return imgd!("scale_middle.png");}
	Image menuScaleMax() {return imgd!("scale_max.png");}
	Image menuScaleEvenBig() {return imgd!("scale_even_big.png");}
	Image menuScaleEvenSmall() {return imgd!("scale_even_small.png");}

	Image menuNewEventTree() {return imgd!("event_tree.png");}
	Image menuNewEventFire() {return imgd!("def_start.png");}
	Image menuTreeOpen() {return imgd!("tree_open.png");}
	Image menuTreeClose() {return imgd!("tree_close.png");}

	Image menuShowCardLife() {return imgd!("card_life.png");}
	Image menuShowCardList() {return imgd!("card_list.png");}
	Image menuShowCardTable() {return imgd!("card_table.png");}
	Image menuAddScenario() {return imgd!("add_scenario.png");}
	Image menuNewCast() {return imgd!("cast_new.png");}
	Image menuNewSkill() {return imgd!("skill_new.png");}
	Image menuNewItem() {return imgd!("item_new.png");}
	Image menuNewBeast() {return imgd!("beast_new.png");}
	Image menuNewInfo() {return imgd!("info_new.png");}

	Image menuAdd() {return imgd!("add.png");}

	Image menuEditHand() {return imgd!("card_hand.png");}
	Image menuOpenHand() {return imgd!("card_hand.png");}
	Image menuEditUseEvent() {return imgd!("event_tree.png");}

	Image menuReNumbering() {return imgd!("renum.png");}
	Image menuReNumberingAll() {return imgd!("renum_all.png");}

	Image menuOpenDirectory() {return imgd!("folder.png");}
	Image menuNewFolder() {return imgd!("folder_new.png");}
	Image menuReplacePath() {return imgd!("replace.png");}

	Image menuReplaceText() {return imgd!("replace.png");}
	Image menuReload() {return imgd!("reload.png");}

	Image menuStartToPackage() {return imgd!("s_to_p.png");}
	Image menuConvertContent() {return imgd!("conv_cont.png");}

	Image menuClosePane() {return imgd!("close_pane.png");}
	Image menuClosePaneEtc() {return imgd!("close_pane_e.png");}
	Image menuClosePaneLeft() {return imgd!("close_pane_l.png");}
	Image menuClosePaneRight() {return imgd!("close_pane_r.png");}
	Image menuClosePaneAll() {return imgd!("close_pane_a.png");}

	Image menuLockBar() {return imgd!("lock_bar.png");}
	Image menuResetBar() {return imgd!("reset_bar.png");}

	Image menuSaveIncludeImage() {return imgd!("save_inc_img.png");}

	Image script() {return imgd!("script.png");}
	Image menuToScript() {return imgd!("script.png");}
	Image menuToScriptAll() {return imgd!("script_all.png");}

	Image menuImageList() {return imgd!("img_list.png");}

	Image menuCreateArchive() {return imgd!("create_archive.png");}

	Image menuOpenTableView() {return imgd!("open_tableview.png");}
	Image menuOpenFlagView() {return imgd!("open_flagview.png");}
	Image menuOpenCardView() {return imgd!("open_cardview.png");}
	Image menuOpenFileView() {return imgd!("open_fileview.png");}
	Image menuCopyFilePath() {return imgd!("copy_path.png");}
	Image menuOpenEventTreeView() {return imgd!("open_eventtreeview.png");}

	Image menuWriteComment() {return imgd!("comment.png");}

	Image menuEditScene() {return imgd!("area_cards.png");}
	Image menuEditEvent() {return imgd!("area_event.png");}

	Image menuOpenView() {return imgd!("view.png");}
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
	CastWin,
	SkillWin,
	ItemWin,
	BeastWin,
	InfoWin,
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
	ViewMsg,
	Fixed,
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
	ReNumbering,
	ReNumberingAll,
	NewFolder,
	ReplacePath,
	ReplaceText,
	Reload,
	StartToPackage,
	ConvertContent,
	Version,
	ToScript,
	ToScriptAll,
	CreateArchive,
	OpenTableView,
	OpenFlagView,
	OpenCardView,
	OpenFileView,
	CopyFilePath,
	OpenEventTreeView,
	WriteComment,
	EditScene,
	EditEvent,
	KeyCodeTimingUse,
	KeyCodeTimingSuccess,
	KeyCodeTimingFailure,
	OpenView,
}

public class Props {
private:
	CProps _parent;
	Images _images;
	FlexProps _var;
public:
	this(string confFilePath, CProps parent) {
		_parent = parent;
		_images = new Images(parent.appPath);
		_var = new FlexProps(parent.appPath, confFilePath);
	}
	const
	string enginePath() {
		if (!var.etc.enginePath.length) return "";
		if (cwx.utils.isabs(var.etc.enginePath)) {
			return var.etc.enginePath;
		} else {
			return std.path.buildPath(std.path.dirName(parent.appPath), var.etc.enginePath);
		}
	}
	const
	string tempPath() {
		if (!var.etc.tempPath.length) return "";
		if (cwx.utils.isabs(var.etc.tempPath)) {
			return var.etc.tempPath;
		} else {
			return std.path.buildPath(std.path.dirName(parent.appPath), var.etc.tempPath);
		}
	}
	const
	string backupPath() {
		if (!var.etc.backupPath.length) return "";
		if (cwx.utils.isabs(var.etc.backupPath)) {
			return var.etc.backupPath;
		} else {
			return std.path.buildPath(std.path.dirName(parent.appPath), var.etc.backupPath);
		}
	}
	const
	const(CProps) parent() {return _parent;}
	const
	const(cwx.system.System) sys() {return _parent.sys;}
	Images images() {return _images;}
	const
	const(Msgs) msgs() {return _parent.msgs;}
	const
	const(Looks) looks() {return _parent.looks;}
	FlexProps var() {return _var;}
	const
	const(FlexProps) var() {return _var;}

	const
	string toAppAbs(string path) {return parent.toAppAbs(path);}
}

/// CPoint等の構造体をSWTのクラスに変換するための関数。
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
	int flag = SWT.NONE;
	if (v.bold) flag |= SWT.BOLD;
	if (v.italic) flag |= SWT.ITALIC;
	return new FontData(v.name, cast(int) v.point, flag == SWT.NONE ? SWT.NORMAL : flag);
}
