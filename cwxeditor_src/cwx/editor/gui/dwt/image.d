
module cwx.editor.gui.dwt.image;

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
	@property Image imgd(string Path)() {
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
					scope (exit) s.close();
					imgData = new ImageData(s);
				} catch (Exception e) {
					debugln(e);
				}
			}
			if (!imgData) {
				auto s = new ByteArrayInputStream(cast(byte[]) getImportData!(Path).data);
				scope (exit) s.close();
				imgData = new ImageData(s);
			}
			imgData.transparentPixel = imgData.getPixel(0, 0);
			auto img = new Image(Display.getCurrent(), imgData);
			_imgReg[Path] = img;
			return img;
		}
	}
	@property
	static string resourceDir() {return "resource";}
public:
	this (string appPath) {
		_appPath = appPath;
	}

	void disposeImages() {
		foreach (p, img; _imgReg) {
			img.dispose();
		}
		typeof(_imgReg) imgReg;
		_imgReg = imgReg;
	}

	@property Image app() {return imgd!("new.png");}
	@property Image menuVersion() {return imgd!("version.png");}
	@property Image icon() {return imgd!("cwxeditor.ico");}

	@property Image text() {return imgd!("text.png");}

	@property Image classicEngine() {return imgd!("classic_engine.png");}

	@property Image warning() {return imgd!("warning.png");}

	@property Image summary() {return imgd!("summary.png");}

	@property Image cards() {return imgd!("cards.png");}
	@property Image backs() {return imgd!("backs.png");}

	@property Image bgm() {return imgd!("evt_bgm.png");}
	@property Image se() {return imgd!("evt_se.png");}
	@property Image unknown() {return imgd!("unknown.png");}

	@property Image folder() {return imgd!("folder.png");}
	@property Image scenario() {return imgd!("scenario.png");}

	@property Image area() {return imgd!("area.png");}
	@property Image battle() {return imgd!("battle.png");}
	@property Image packages() {return imgd!("package.png");}

	@property Image areaSceneView() {return imgd!("area_cards.png");}
	@property Image areaEventTreeView() {return imgd!("area_event.png");}
	@property Image battleSceneView() {return imgd!("battle_cards.png");}
	@property Image battleEventTreeView() {return imgd!("battle_event.png");}

	@property Image casts() {return imgd!("cast.png");}
	@property Image skill() {return imgd!("skill.png");}
	@property Image item() {return imgd!("item.png");}
	@property Image beast() {return imgd!("beast.png");}
	@property Image info() {return imgd!("info.png");}

	@property Image flagDir() {return imgd!("flagdir.png");}
	@property Image flag() {return imgd!("flag.png");}
	@property Image step() {return imgd!("step.png");}

	@property Image couponNormal() {return imgd!("coupon_n.png");}
	@property Image couponPlus() {return imgd!("coupon_plus.png");}
	@property Image couponMinus() {return imgd!("coupon_minus.png");}
	@property Image couponHigh() {return imgd!("coupon.png");}
	@property Image couponDelete() {return imgd!("evt_stop.png");}

	@property Image gossip() {return imgd!("gossip.png");}
	@property Image endScenario() {return imgd!("end.png");}

	@property Image stopBGM() {return imgd!("sound_stop.png");}
	@property Image playBGM() {return imgd!("sound_play.png");}

	@property Image evtArrow() {return imgd!("evt_arrow.png");}

	@property Image evtAddContinue() {return imgd!("evt_add_continue.png");}
	@property Image evtAutoOpen() {return imgd!("evt_auto_edit.png");}

	Image menuEvtGroup(CTypeGroup cGrp) {
		final switch (cGrp) {
		case CTypeGroup.Terminal: return imgd!("evt_j_term.png");
		case CTypeGroup.Standard: return imgd!("evt_j_std.png");
		case CTypeGroup.Data: return imgd!("evt_j_data.png");
		case CTypeGroup.Utility: return imgd!("evt_j_util.png");
		case CTypeGroup.Branch: return imgd!("evt_j_br.png");
		case CTypeGroup.Get: return imgd!("evt_j_get.png");
		case CTypeGroup.Lost: return imgd!("evt_j_lost.png");
		case CTypeGroup.Visual: return imgd!("evt_j_vis.png");
		}
	}

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

	@property Image msnDelete() {return imgd!("evt_stop.png");}

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

	@property Image eventTree() {return imgd!("event_tree.png");}
	@property Image defStart() {return imgd!("def_start.png");}
	@property Image keyCode() {return imgd!("key_code.png");}
	@property Image round() {return imgd!("round.png");}
	@property Image menuKeyCodeTimingUse() {return imgd!("key_code.png");}
	@property Image menuKeyCodeTimingSuccess() {return imgd!("key_code_suc.png");}
	@property Image menuKeyCodeTimingFailure() {return imgd!("key_code_fail.png");}

	@property Image menuAddManyRounds() {return imgd!("add_many_round.png");}

	@property Image addCoupon() {return imgd!("coupon.png");}
	@property Image altCoupon() {return imgd!("alt_coupon.png");}
	@property Image delCoupon() {return imgd!("evt_stop.png");}

	@property Image setBeast() {return imgd!("set_beast.png");}

	@property Image sound() {return imgd!("evt_se.png");}
	@property Image stopSound() {return imgd!("sound_stop.png");}
	@property Image playSound() {return imgd!("sound_play.png");}

	@property Image setTalkerCoupon() {return imgd!("set_beast.png");}
	@property Image defaultColor() {return imgd!("cc_w.png");}
	@property Image red() {return imgd!("cc_r.png");}
	@property Image blue() {return imgd!("cc_b.png");}
	@property Image green() {return imgd!("cc_g.png");}
	@property Image yellow() {return imgd!("cc_y.png");}
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
	@property Image scRef() {return imgd!("sc_i.png");}
	@property Image scTeam() {return imgd!("sc_t.png");}
	@property Image scYado() {return imgd!("sc_y.png");}

	@property Image createDialog() {return imgd!("evt_speak.png");}
	@property Image deleteDialog() {return imgd!("evt_stop.png");}
	@property Image copyToDialogs() {return imgd!("copy_dialog.png");}
	@property Image copyToUpper() {return imgd!("copy_dialog_u.png");}
	@property Image copyToLower() {return imgd!("copy_dialog_l.png");}

	@property Image summaryFile() {return imgd!("summary_file.png");}
	@property Image scenarioArchive() {return imgd!("scenario_arc.png");}
	@property Image classic() {return imgd!("classic.png");}

	@property Image menuRefresh() {return imgd!("refresh.png");}

	@property Image menuCEdit() {return imgd!("edit.png");}

	@property Image menuUndo() {return imgd!("undo.png");}
	@property Image menuRedo() {return imgd!("redo.png");}

	@property Image menuCut() {return imgd!("cut.png");}
	@property Image menuCopy() {return imgd!("copy.png");}
	@property Image menuPaste() {return imgd!("paste.png");}
	@property Image menuDel() {return imgd!("del.png");}
	@property Image menuSelectAll() {return imgd!("select_all.png");}

	@property Image menuToXML() {return imgd!("toxml.png");}

	@property Image menuNew() {return imgd!("new.png");}
	@property Image menuOpen() {return imgd!("open.png");}
	@property Image menuClose() {return imgd!("close.png");}
	@property Image menuCloseWin() {return imgd!("close_win.png");}
	@property Image menuSave() {return imgd!("save.png");}
	@property Image menuSaveAs() {return imgd!("save_a.png");}

	@property Image menuDataWin() {return imgd!("data_win.png");}
	@property Image menuFlagWin() {return imgd!("flag_win.png");}
	@property Image menuCardWin() {return imgd!("card_win.png");}
	@property Image menuCastWin() {return imgd!("cast_win.png");}
	@property Image menuSkillWin() {return imgd!("skill_win.png");}
	@property Image menuItemWin() {return imgd!("item_win.png");}
	@property Image menuBeastWin() {return imgd!("beast_win.png");}
	@property Image menuInfoWin() {return imgd!("info_win.png");}
	@property Image menuDirWin() {return imgd!("dir_win.png");}

	@property Image menuChangeVH() {return imgd!("chg_vh.png");}

	@property Image menuExecEngine() {return imgd!("exec_engine.png");}
	@property Image menuSettings() {return imgd!("settings.png");}

	@property Image menuSummary() {return imgd!("summary.png");}
	@property Image menuNewArea() {return imgd!("area_new.png");}
	@property Image menuNewBattle() {return imgd!("battle_new.png");}
	@property Image menuNewPackage() {return imgd!("package_new.png");}

	@property Image menuNewFlagDir() {return imgd!("flagdir_new.png");}
	@property Image menuNewFlag() {return imgd!("flag_new.png");}
	@property Image menuNewStep() {return imgd!("step_new.png");}

	@property Image menuViewParty() {return imgd!("party_cards.png");}
	@property Image menuViewMsg() {return imgd!("view_msg.png");}
	@property Image menuFixed() {return imgd!("fixed.png");}
	@property Image menuEnemyCardDebugView() {return imgd!("card_life.png");}
	@property Image menuViewCards() {return imgd!("cards.png");}
	@property Image menuViewBacks() {return imgd!("backs.png");}
	@property Image menuUp() {return imgd!("up.png");}
	@property Image menuDown() {return imgd!("down.png");}
	@property Image menuNewMenuCard() {return imgd!("card_new.png");}
	@property Image menuNewEnemyCard() {return imgd!("card_new.png");}
	@property Image menuNewBack() {return imgd!("back_new.png");}
	@property Image menuAuto() {return imgd!("auto.png");}
	@property Image menuCustom() {return imgd!("custom.png");}
	@property Image menuMask() {return imgd!("mask.png");}
	@property Image menuDoEscape() {return imgd!("escape.png");}
	@property Image menuPosTop() {return imgd!("pos_top.png");}
	@property Image menuPosBottom() {return imgd!("pos_bottom.png");}
	@property Image menuPosLeft() {return imgd!("pos_left.png");}
	@property Image menuPosRight() {return imgd!("pos_right.png");}
	@property Image menuPosEven() {return imgd!("pos_even.png");}
	@property Image menuScaleMin() {return imgd!("scale_min.png");}
	@property Image menuScaleMiddle() {return imgd!("scale_middle.png");}
	@property Image menuScaleMax() {return imgd!("scale_max.png");}
	@property Image menuScaleEvenBig() {return imgd!("scale_even_big.png");}
	@property Image menuScaleEvenSmall() {return imgd!("scale_even_small.png");}

	@property Image menuNewEventTree() {return imgd!("event_tree.png");}
	@property Image menuNewEventFire() {return imgd!("def_start.png");}
	@property Image menuTreeOpen() {return imgd!("tree_open.png");}
	@property Image menuTreeClose() {return imgd!("tree_close.png");}

	@property Image menuShowCardLife() {return imgd!("card_life.png");}
	@property Image menuShowCardList() {return imgd!("card_list.png");}
	@property Image menuShowCardTable() {return imgd!("card_table.png");}
	@property Image menuAddScenario() {return imgd!("add_scenario.png");}
	@property Image menuNewCast() {return imgd!("cast_new.png");}
	@property Image menuNewSkill() {return imgd!("skill_new.png");}
	@property Image menuNewItem() {return imgd!("item_new.png");}
	@property Image menuNewBeast() {return imgd!("beast_new.png");}
	@property Image menuNewInfo() {return imgd!("info_new.png");}

	@property Image menuAdd() {return imgd!("add.png");}

	@property Image menuEditHand() {return imgd!("card_hand.png");}
	@property Image menuOpenHand() {return imgd!("card_hand.png");}
	@property Image menuEditUseEvent() {return imgd!("event_tree.png");}

	@property Image menuReNumbering() {return imgd!("renum.png");}
	@property Image menuReNumberingAll() {return imgd!("renum_all.png");}

	@property Image menuOpenDirectory() {return imgd!("folder.png");}
	@property Image menuNewFolder() {return imgd!("folder_new.png");}
	@property Image menuReplacePath() {return imgd!("replace.png");}
	@property Image menuDeleteUnuse() {return imgd!("del_unuse.png");}

	@property Image menuReplaceText() {return imgd!("replace.png");}
	@property Image menuReload() {return imgd!("reload.png");}

	@property Image menuStartToPackage() {return imgd!("s_to_p.png");}
	@property Image menuConvertContent() {return imgd!("conv_cont.png");}

	@property Image menuClosePane() {return imgd!("close_pane.png");}
	@property Image menuClosePaneEtc() {return imgd!("close_pane_e.png");}
	@property Image menuClosePaneLeft() {return imgd!("close_pane_l.png");}
	@property Image menuClosePaneRight() {return imgd!("close_pane_r.png");}
	@property Image menuClosePaneAll() {return imgd!("close_pane_a.png");}

	@property Image menuLockBar() {return imgd!("lock_bar.png");}
	@property Image menuResetBar() {return imgd!("reset_bar.png");}

	@property Image menuSaveIncludeImage() {return imgd!("save_inc_img.png");}

	@property Image script() {return imgd!("script.png");}
	@property Image menuToScript() {return imgd!("script.png");}
	@property Image menuToScriptAll() {return imgd!("script_all.png");}

	@property Image menuImageList() {return imgd!("img_list.png");}

	@property Image menuCreateArchive() {return imgd!("create_archive.png");}

	@property Image menuOpenTableView() {return imgd!("open_tableview.png");}
	@property Image menuOpenFlagView() {return imgd!("open_flagview.png");}
	@property Image menuOpenCardView() {return imgd!("open_cardview.png");}
	@property Image menuOpenFileView() {return imgd!("open_fileview.png");}
	@property Image menuCopyFilePath() {return imgd!("copy_path.png");}
	@property Image menuOpenEventTreeView() {return imgd!("open_eventtreeview.png");}

	@property Image menuWriteComment() {return imgd!("comment.png");}

	@property Image menuEditScene() {return imgd!("area_cards.png");}
	@property Image menuEditEvent() {return imgd!("area_event.png");}

	@property Image menuOpenView() {return imgd!("view.png");}
}
