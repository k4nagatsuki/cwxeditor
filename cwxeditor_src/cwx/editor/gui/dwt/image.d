
module cwx.editor.gui.dwt.image;

import org.eclipse.swt.SWT;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.graphics.RGB;
import org.eclipse.swt.graphics.FontData;

import cwx.types;
import cwx.utils;

import std.file;
import std.path;

import org.eclipse.swt.all;

import java.lang.all;
import java.io.ByteArrayInputStream;

class Images {
private:
	string _appPath;
	Image[string] _imgReg;
	@property Image imgd(string Path)() {
		auto p = Path in _imgReg;
		if (p) {
			return *p;
		} else {
			string dir = _appPath.dirName();
			string dynPath = dir.buildPath("resource").buildPath(Path);
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
	@property Image emptyIcon() {return imgd!("empty.png");}

	@property Image app() {return imgd!("cwxeditor.png");}
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
	@property Image couponDelete() {return imgd!("del_res.png");}

	@property Image gossip() {return imgd!("gossip.png");}
	@property Image endScenario() {return imgd!("end.png");}

	@property Image evtArrow() {return imgd!("evt_arrow.png");}

	@property Image evtAddContinue() {return imgd!("evt_add_continue.png");}
	@property Image evtAutoOpen() {return imgd!("evt_auto_edit.png");}

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
		case CType.BRANCH_KEY_CODE: return imgd!("evt_br_keycode.png");
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
		case CType.SUBSTITUTE_STEP: return imgd!("evt_cpstep.png");
		case CType.SUBSTITUTE_FLAG: return imgd!("evt_cpflag.png");
		case CType.BRANCH_STEP_CMP: return imgd!("evt_cmpstep.png");
		case CType.BRANCH_FLAG_CMP: return imgd!("evt_cmpflag.png");
		case CType.BRANCH_RANDOM_SELECT: return imgd!("evt_br_rndsel.png");
		default: assert (0);
		}
	}

	@property Image msnDelete() {return imgd!("del_res.png");}

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
		case Talker.VALUED:
			return imgd!("talker_valued.png");
		case Talker.NARRATION, Talker.IMAGE, Talker.CARD:
			throw new Exception("Narration, image and card haven't image.");
		}
	}

	@property Image eventTree() {return imgd!("event_tree.png");}
	@property Image eventTreeAnd() {return imgd!("event_tree_and.png");}
	@property Image defStart() {return imgd!("def_start.png");}
	@property Image keyCode() {return imgd!("key_code.png");}
	@property Image round() {return imgd!("round.png");}
	@property Image newEvent() {return imgd!("event_tree.png");}
	@property Image newIgnition() {return imgd!("def_start.png");}
	@property Image expandTree() {return imgd!("tree_open.png");}
	@property Image foldTree() {return imgd!("tree_close.png");}

	@property Image addCoupon() {return imgd!("coupon.png");}
	@property Image altCoupon() {return imgd!("alt_coupon.png");}
	@property Image delCoupon() {return imgd!("del_res.png");}

	@property Image setBeast() {return imgd!("set_beast.png");}

	@property Image sound() {return imgd!("evt_se.png");}

	@property Image setTalkerCoupon() {return imgd!("set_beast.png");}
	Image color(dchar c) {
		switch (c) {
		case 'W': return imgd!("cc_w.png");
		case 'R': return imgd!("cc_r.png");
		case 'B': return imgd!("cc_b.png");
		case 'G': return imgd!("cc_g.png");
		case 'Y': return imgd!("cc_y.png");
		default: return null;
		}
	}
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
		case Talker.NARRATION, Talker.IMAGE, Talker.VALUED:
			throw new Exception("Narration and image haven't image.");
		}
	}
	@property Image scRef() {return imgd!("sc_i.png");}
	@property Image scTeam() {return imgd!("sc_t.png");}
	@property Image scYado() {return imgd!("sc_y.png");}

	@property Image createDialog() {return imgd!("evt_speak.png");}
	@property Image deleteDialog() {return imgd!("del_res.png");}
	@property Image copyToDialogs() {return imgd!("copy_dialog.png");}
	@property Image copyToUpper() {return imgd!("copy_dialog_u.png");}
	@property Image copyToLower() {return imgd!("copy_dialog_l.png");}

	@property Image summaryFile() {return imgd!("summary_file.png");}
	@property Image scenarioArchive() {return imgd!("scenario_arc.png");}
	@property Image classic() {return imgd!("classic.png");}

	@property Image script() {return imgd!("script.png");}

	@property Image editSceneBattle() {return imgd!("battle_cards.png");}
	@property Image editEventBattle() {return imgd!("battle_event.png");}

	Image menu(MenuID id) {
		final switch (id) {
		case MenuID.None: return null;

		case MenuID.File: return null;
		case MenuID.Edit: return null;
		case MenuID.View: return null;
		case MenuID.Tool: return null;
		case MenuID.Table: return null;
		case MenuID.Variable: return null;
		case MenuID.Help: return null;
		case MenuID.Card: return null;
		case MenuID.CardsAndBacks: return null;

		case MenuID.DelNotUsedFile: return imgd!("del_unuse.png");
		case MenuID.ClosePane: return imgd!("close_pane.png");
		case MenuID.ClosePaneExcept: return imgd!("close_pane_e.png");
		case MenuID.ClosePaneLeft: return imgd!("close_pane_l.png");
		case MenuID.ClosePaneRight: return imgd!("close_pane_r.png");
		case MenuID.ClosePaneAll: return imgd!("close_pane_a.png");
		case MenuID.New: return imgd!("new.png");
		case MenuID.Open: return imgd!("open.png");
		case MenuID.NewAtNewWindow: return imgd!("new_new_win.png");
		case MenuID.OpenAtNewWindow: return imgd!("open_new_win.png");
		case MenuID.Close: return imgd!("close.png");
		case MenuID.CloseWin: return imgd!("close_win.png");
		case MenuID.Save: return imgd!("save.png");
		case MenuID.SaveAs: return imgd!("save_a.png");
		case MenuID.Reload: return imgd!("reload.png");
		case MenuID.OpenDir: return imgd!("folder.png");
		case MenuID.OpenPlace: return imgd!("folder.png");
		case MenuID.SaveImage: return imgd!("save_inc_img.png");
		case MenuID.IncludeImage: return imgd!("inc_img.png");
		case MenuID.LookImages: return imgd!("img_list.png");
		case MenuID.ShowMainToolBar: return imgd!("main_tools.png");
		case MenuID.ShowSceneToolBar: return imgd!("scene_tools.png");
		case MenuID.ShowEventToolBar: return imgd!("event_tools.png");
		case MenuID.ChangeVH: return imgd!("chg_vh.png");
		case MenuID.Find: return imgd!("replace.png");
		case MenuID.IncSearch: return imgd!("inc_search.png");
		case MenuID.CloseIncSearch: return imgd!("close_win.png");
		case MenuID.EditProp: return imgd!("edit.png");
		case MenuID.Refresh: return imgd!("refresh.png");
		case MenuID.Undo: return imgd!("undo.png");
		case MenuID.Redo: return imgd!("redo.png");
		case MenuID.Cut: return imgd!("cut.png");
		case MenuID.Copy: return imgd!("copy.png");
		case MenuID.Paste: return imgd!("paste.png");
		case MenuID.Delete: return imgd!("del.png");
		case MenuID.Clone: return imgd!("clone.png");
		case MenuID.SelectAll: return imgd!("select_all.png");
		case MenuID.ToXMLText: return imgd!("toxml.png");
		case MenuID.TableView: return imgd!("data_win.png");
		case MenuID.VarView: return imgd!("flag_win.png");
		case MenuID.CardView: return imgd!("card_win.png");
		case MenuID.CastView: return imgd!("cast_win.png");
		case MenuID.SkillView: return imgd!("skill_win.png");
		case MenuID.ItemView: return imgd!("item_win.png");
		case MenuID.BeastView: return imgd!("beast_win.png");
		case MenuID.InfoView: return imgd!("info_win.png");
		case MenuID.FileView: return imgd!("dir_win.png");
		case MenuID.ExecEngine: return imgd!("exec_engine.png");
		case MenuID.ExecEngineAuto: return imgd!("exec_engine.png");
		case MenuID.ExecEngineMain: return imgd!("exec_engine.png");
		case MenuID.OuterTools: return imgd!("outer_tool.png");
		case MenuID.Settings: return imgd!("settings.png");
		case MenuID.VersionInfo: return imgd!("version.png");
		case MenuID.LockToolBar: return imgd!("lock_bar.png");
		case MenuID.ResetToolBar: return imgd!("reset_bar.png");
		case MenuID.CopyAsText: return imgd!("copy.png");
		case MenuID.OpenAtView: return imgd!("view.png");
		case MenuID.StartToPackage: return imgd!("s_to_p.png");
		case MenuID.ConvertContent: return imgd!("conv_cont.png");
		case MenuID.CGroupTerminal: return imgd!("evt_j_term.png");
		case MenuID.CGroupStandard: return imgd!("evt_j_std.png");
		case MenuID.CGroupData: return imgd!("evt_j_data.png");
		case MenuID.CGroupUtility: return imgd!("evt_j_util.png");
		case MenuID.CGroupBranch: return imgd!("evt_j_br.png");
		case MenuID.CGroupGet: return imgd!("evt_j_get.png");
		case MenuID.CGroupLost: return imgd!("evt_j_lost.png");
		case MenuID.CGroupVisual: return imgd!("evt_j_vis.png");
		case MenuID.EditSummary: return imgd!("summary.png");
		case MenuID.NewArea: return imgd!("area_new.png");
		case MenuID.NewBattle: return imgd!("battle_new.png");
		case MenuID.NewPackage: return imgd!("package_new.png");
		case MenuID.ReNumberingAll: return imgd!("renum_all.png");
		case MenuID.ReNumbering: return imgd!("renum.png");
		case MenuID.EditScene: return imgd!("area_cards.png");
		case MenuID.EditEvent: return imgd!("area_event.png");
		case MenuID.NewFlagDir: return imgd!("flagdir_new.png");
		case MenuID.NewFlag: return imgd!("flag_new.png");
		case MenuID.NewStep: return imgd!("step_new.png");
		case MenuID.Up: return imgd!("up.png");
		case MenuID.Down: return imgd!("down.png");
		case MenuID.OverDialog: return imgd!("over_dlg.png");
		case MenuID.UnderDialog: return imgd!("under_dlg.png");
		case MenuID.ShowParty: return imgd!("party_cards.png");
		case MenuID.ShowMsg: return imgd!("view_msg.png");
		case MenuID.ShowRefCards: return imgd!("view_ref.png");
		case MenuID.FixedImage: return imgd!("fixed.png");
		case MenuID.ShowGrid: return imgd!("grid.png");
		case MenuID.ShowEnemyCardProp: return imgd!("card_life.png");
		case MenuID.ShowCard: return imgd!("cards.png");
		case MenuID.ShowBack: return imgd!("backs.png");
		case MenuID.NewMenuCard: return imgd!("card_new.png");
		case MenuID.NewEnemyCard: return imgd!("card_new.png");
		case MenuID.NewBack: return imgd!("back_new.png");
		case MenuID.AutoArrange: return imgd!("auto.png");
		case MenuID.ManualArrange: return imgd!("custom.png");
		case MenuID.Mask: return imgd!("mask.png");
		case MenuID.Escape: return imgd!("escape.png");
		case MenuID.PosTop: return imgd!("pos_top.png");
		case MenuID.PosBottom: return imgd!("pos_bottom.png");
		case MenuID.PosLeft: return imgd!("pos_left.png");
		case MenuID.PosRight: return imgd!("pos_right.png");
		case MenuID.PosEven: return imgd!("pos_even.png");
		case MenuID.ScaleMin: return imgd!("scale_min.png");
		case MenuID.ScaleMiddle: return imgd!("scale_middle.png");
		case MenuID.ScaleMax: return imgd!("scale_max.png");
		case MenuID.ScaleBig: return imgd!("scale_even_big.png");
		case MenuID.ScaleSmall: return imgd!("scale_even_small.png");
		case MenuID.StopBGM: return imgd!("sound_stop.png");
		case MenuID.PlayBGM: return imgd!("sound_play.png");
		case MenuID.KeyCodeTiming: return imgd!("key_code.png");
		case MenuID.KeyCodeTimingUse: return imgd!("key_code.png");
		case MenuID.KeyCodeTimingSuccess: return imgd!("key_code_suc.png");
		case MenuID.KeyCodeTimingFailure: return imgd!("key_code_fail.png");
		case MenuID.KeyCodeTimingHasNot: return imgd!("key_code_hasnot.png");
		case MenuID.KeyCodeCond: return imgd!("key_code_cond.png");
		case MenuID.KeyCodeCondOr: return imgd!("key_code_or.png");
		case MenuID.KeyCodeCondAnd: return imgd!("key_code_and.png");
		case MenuID.AddRangeOfRound: return imgd!("add_many_round.png");
		case MenuID.OpenAtTableView: return imgd!("open_tableview.png");
		case MenuID.OpenAtVarView: return imgd!("open_flagview.png");
		case MenuID.OpenAtCardView: return imgd!("open_cardview.png");
		case MenuID.OpenAtFileView: return imgd!("open_fileview.png");
		case MenuID.OpenAtEventView: return imgd!("open_eventtreeview.png");
		case MenuID.Comment: return imgd!("comment.png");
		case MenuID.ShowCardProp: return imgd!("card_life.png");
		case MenuID.ShowCardImage: return imgd!("card_list.png");
		case MenuID.ShowCardDetail: return imgd!("card_table.png");
		case MenuID.OpenImportSource: return imgd!("add_scenario.png");
		case MenuID.NewCast: return imgd!("cast_new.png");
		case MenuID.NewSkill: return imgd!("skill_new.png");
		case MenuID.NewItem: return imgd!("item_new.png");
		case MenuID.NewBeast: return imgd!("beast_new.png");
		case MenuID.NewInfo: return imgd!("info_new.png");
		case MenuID.Import: return imgd!("add.png");
		case MenuID.OpenHand: return imgd!("card_hand.png");
		case MenuID.AddHand: return imgd!("add_hand.png");
		case MenuID.RemoveRef: return imgd!("remove_ref.png");
		case MenuID.EditEventAtTimeOfUsing: return imgd!("event_tree.png");
		case MenuID.Hold: return imgd!("hold.png");
		case MenuID.PlaySE: return imgd!("sound_play.png");
		case MenuID.StopSE: return imgd!("sound_stop.png");
		case MenuID.NewDir: return imgd!("folder_new.png");
		case MenuID.CopyFilePath: return imgd!("copy_path.png");
		case MenuID.ReplFilePath: return imgd!("replace.png");
		case MenuID.CreateArchive: return imgd!("create_archive.png");
		case MenuID.ToScript: return imgd!("script.png");
		case MenuID.ToScriptAll: return imgd!("script_all.png");
		case MenuID.EvTemplates: return imgd!("ev_tmpl.png");
		}
	}
}
