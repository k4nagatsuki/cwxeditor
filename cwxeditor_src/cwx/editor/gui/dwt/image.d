
module cwx.editor.gui.dwt.image;

import org.eclipse.swt.SWT;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.graphics.RGB;
import org.eclipse.swt.graphics.FontData;

import cwx.types;
import cwx.utils;

import cwx.editor.gui.dwt.dutils : dpiMuls, ImageDataWithScale;

import std.algorithm;
import std.array;
import std.file;
import std.path;
import std.string;

import org.eclipse.swt.all;

import java.lang.all;
import java.io.ByteArrayInputStream;

/// アイコン等のリソースを一括管理する。
class Images {
private:
	private struct ImgRegKey {
		string key;
		int dpi;
	}

	string _appPath;
	Image[ImgRegKey] _imgReg;
	Cursor[CType] _curReg;
	Image[] _icon;
	Image _largeIcon;

	private static template ImportDataWithScale(string[] Paths) {
		static if (__traits(compiles, getImportData!(Paths[0]))) {
			static if (1 < Paths.length) {
				immutable ImportDataWithScale = [getImportData!(Paths[0])] ~ ImportDataWithScale!(Paths[1 .. $]);
			} else {
				immutable ImportDataWithScale = [getImportData!(Paths[0])];
			}
		} else {
			static if (1 < Paths.length) {
				immutable ImportDataWithScale = [ImportData([], "")] ~ ImportDataWithScale!(Paths[1 .. $]);
			} else {
				immutable ImportDataWithScale = [ImportData([], "")];
			}
		}
	}
	@property Image imgd(string Path)(uint targetScale = 0) { mixin(S_TRACE);
		auto d = Display.getCurrent();
		if (!targetScale) targetScale = .dpiMuls;
		auto key = ImgRegKey(Path, targetScale);
		auto p = key in _imgReg;
		if (p) { mixin(S_TRACE);
			return *p;
		} else { mixin(S_TRACE);
			auto dir = _appPath.dirName();
			auto dynPath = dir.buildPath("resource").buildPath(Path);
			ImageDataWithScale imgData = null;
			if (.exists(dynPath) && .isFile(dynPath)) { mixin(S_TRACE);
				try { mixin(S_TRACE);
					auto info = .findScaledImage(dynPath, targetScale);
					byte* ptr = null;
					auto bin = readBinaryFrom!byte(info.path, ptr);
					scope (exit) freeAll(ptr);
					auto s = new ByteArrayInputStream(bin);
					scope (exit) s.close();
					imgData = new ImageDataWithScale(new ImageData(s), info.scale);
				} catch (Exception e) {
					printStackTrace();
					debugln(e);
				}
			}
			auto IMPORT_DATA = ImportDataWithScale!([Path] ~ .map!(scale => Path.stripExtension() ~ ".x%s".format(scale) ~ Path.extension())(IMAGE_SCALES).array());
			if (!imgData) { mixin(S_TRACE);
				auto useScale = false;
				foreach_reverse (i, scale; [1] ~ IMAGE_SCALES) { mixin(S_TRACE);
					if (scale == targetScale) { mixin(S_TRACE);
						useScale = true;
					}
					if (!useScale) continue;
					if (IMPORT_DATA[i].data.length) { mixin(S_TRACE);
						auto s = new ByteArrayInputStream(cast(byte[])IMPORT_DATA[i].data);
						scope (exit) s.close();
						imgData = new ImageDataWithScale(new ImageData(s), scale);
					}
				}
			}
			if (!imgData) throw new Exception("Resource not found: %s".format(Path));
			imgData.baseData.transparentPixel = imgData.baseData.getPixel(0, 0);
			auto img = new Image(d, imgData.scaled(targetScale));
			_imgReg[key] = img;
			return img;
		}
	}
	void initIcon() { mixin(S_TRACE);
		if (_icon.length) return;
		auto s = new ByteArrayInputStream(cast(byte[])getImportData!("cwxeditor.ico").data);
		scope (exit) s.close();
		int w = 0;
		foreach (data; (new ImageLoader).load(s)) { mixin(S_TRACE);
			auto img = new Image(Display.getCurrent(), data);
			_icon ~= img;
			if (!_largeIcon || w < data.width) { mixin(S_TRACE);
				_largeIcon = img;
				w = data.width;
			}
		}
	}
public:
	this (string appPath) { mixin(S_TRACE);
		_appPath = appPath;
	}

	void disposeImages() { mixin(S_TRACE);
		foreach (p, img; _imgReg) { mixin(S_TRACE);
			img.dispose();
		}
		foreach (p, cur; _curReg) { mixin(S_TRACE);
			cur.dispose();
		}
		_imgReg = null;
		_curReg = null;
		foreach (i; _icon) { mixin(S_TRACE);
			i.dispose();
		}
		if (_largeIcon) _largeIcon = null;
	}
	@property Image emptyIcon() { return imgd!("empty.png"); }

	@property Image app() { return imgd!("cwxeditor.png"); }
	@property Image[] icon() { mixin(S_TRACE);
		initIcon();
		return _icon;
	}
	@property Image largeIcon() { mixin(S_TRACE);
		initIcon();
		return _largeIcon;
	}

	@property Image toolBar() { return imgd!("tool_bar.png"); }
	@property Image toolGroup() { return imgd!("tool_group.png"); }

	@property Image addItem() { return imgd!("add_item.png"); }
	@property Image delItem() { return imgd!("del_item.png"); }

	@property Image text() { return imgd!("text.png"); }

	@property Image classicEngine() { return imgd!("classic_engine.png"); }

	@property Image warning() { return imgd!("warning.png"); }

	@property Image summary() { return imgd!("summary.png"); }

	@property Image cards() { return imgd!("cards.png"); }
	@property Image cardsWithFlag() { return imgd!("cards_flag.png"); }
	@property Image runAwayableEnemyCard() { return imgd!("escape.png"); }
	@property Image runAwayableEnemyCardWithFlag() { return imgd!("escape_flag.png"); }
	@property Image backs() { return imgd!("backs.png"); }
	@property Image backsWithFlag() { return imgd!("backs_flag.png"); }
	@property Image colorCell() { return imgd!("color_cell.png"); }
	@property Image colorCellWithFlag() { return imgd!("color_cell_flag.png"); }
	@property Image textCell() { return imgd!("text_cell.png"); }
	@property Image textCellWithFlag() { return imgd!("text_cell_flag.png"); }
	@property Image pcCell() { return imgd!("pc_cell.png"); }
	@property Image pcCellWithFlag() { return imgd!("pc_cell_flag.png"); }
	@property Image imageFont() { return imgd!("backs.png"); }

	@property Image inheritBackground() { return imgd!("inherit_backs.png"); }
	@property Image notInheritBackground() { return imgd!("not_inherit_backs.png"); }

	@property Image bgm() { return imgd!("evt_bgm.png"); }
	@property Image se() { return imgd!("evt_se.png"); }
	@property Image unknown() { return imgd!("unknown.png"); }

	@property Image folder() { return imgd!("folder.png"); }
	@property Image scenario() { return imgd!("scenario.png"); }

	@property Image areaDir() { return imgd!("areadir.png"); }
	@property Image area() { return imgd!("area.png"); }
	@property Image battle() { return imgd!("battle.png"); }
	@property Image packages() { return imgd!("package.png"); }
	@property Image packageDup() { return imgd!("package_dup.png"); }
	@property Image startArea() { return imgd!("start_area.png"); }

	@property Image areaSceneView() { return imgd!("area_cards.png"); }
	@property Image areaSceneViewDup() { return imgd!("area_cards_dup.png"); }
	@property Image areaEventTreeView() { return imgd!("area_event.png"); }
	@property Image areaEventTreeViewDup() { return imgd!("area_event_dup.png"); }
	@property Image battleSceneView() { return imgd!("battle_cards.png"); }
	@property Image battleSceneViewDup() { return imgd!("battle_cards_dup.png"); }
	@property Image battleEventTreeView() { return imgd!("battle_event.png"); }
	@property Image battleEventTreeViewDup() { return imgd!("battle_event_dup.png"); }

	@property Image yado() { return imgd!("sc_y.png"); }
	@property Image debugYado() { return imgd!("debug_yado.png"); }
	@property Image team() { return imgd!("sc_t.png"); }

	@property Image playerCardName() { return imgd!("sc_pc_name.png"); }

	@property Image selectedPlayerCardNumber() { return imgd!("sc_sel_pc_num.png"); }
	@property Image randomValue() { return imgd!("random_value.png"); }

	@property Image casts() { return imgd!("cast.png"); }
	@property Image skill() { return imgd!("skill.png"); }
	@property Image skillDup() { return imgd!("skill_dup.png"); }
	@property Image item() { return imgd!("item.png"); }
	@property Image itemDup() { return imgd!("item_dup.png"); }
	@property Image beast() { return imgd!("beast.png"); }
	@property Image beastDup() { return imgd!("beast_dup.png"); }
	@property Image info() { return imgd!("info.png"); }

	@property Image playerCard() { return imgd!("party_cards.png"); }

	@property Image flagDir() { return imgd!("flagdir.png"); }
	@property Image flag() { return imgd!("flag.png"); }
	@property Image step() { return imgd!("step.png"); }
	@property Image variant() { return imgd!("variant.png"); }
	@property Image variantRef() { return imgd!("variant_ref.png"); }

	@property Image localFlag() { return imgd!("flag_l.png"); }
	@property Image localStep() { return imgd!("step_l.png"); }
	@property Image localVariant() { return imgd!("variant_l.png"); }

	@property Image functions() { return imgd!("func.png"); }

	@property Image couponNormal() { return imgd!("coupon_n.png"); }
	@property Image couponPlus() { return imgd!("coupon_plus.png"); }
	@property Image couponMinus() { return imgd!("coupon_minus.png"); }
	@property Image couponHigh() { return imgd!("coupon_high.png"); }
	@property Image couponDelete() { return imgd!("del_res.png"); }

	@property Image couponSystem() { return imgd!("coupon_system.png"); }
	@property Image couponDur() { return imgd!("coupon_dur.png"); }
	@property Image couponDurBattle() { return imgd!("coupon_dur_battle.png"); }

	@property Image gossip() { return imgd!("gossip.png"); }
	@property Image endScenario() { return imgd!("end.png"); }

	@property Image evtArrow() { return imgd!("evt_arrow.png"); }

	@property Image evtAutoOpen() { return imgd!("evt_auto_edit.png"); }
	@property Image evtInsertFirst() { return imgd!("evt_insert_first.png"); }

	@property Image couponView() { return imgd!("coupon_win.png"); }
	@property Image gossipView() { return imgd!("gossip_win.png"); }
	@property Image completeStampView() { return imgd!("complete_stamp_win.png"); }
	@property Image keyCodeView() { return imgd!("key_code_win.png"); }
	@property Image cellNameView() { return imgd!("cell_name_win.png"); }
	@property Image cardGroupView() { return imgd!("card_group_win.png"); }

	Image actionCard(ActionCardType type) { mixin(S_TRACE);
		switch (type) {
		case ActionCardType.Exchange: return imgd!("card_hand.png");
		case ActionCardType.Attack: return imgd!("hand_attack.png");
		case ActionCardType.PowerfulAttack: return imgd!("hand_p_attack.png");
		case ActionCardType.CriticalAttack: return imgd!("hand_c_attack.png");
		case ActionCardType.Feint: return imgd!("hand_feint.png");
		case ActionCardType.Defense: return imgd!("hand_defense.png");
		case ActionCardType.Distance: return imgd!("hand_distance.png");
		case ActionCardType.RunAway: return imgd!("escape.png");
		case ActionCardType.Confuse: return imgd!("hand_confuse.png");
		default: return imgd!("empty.png");
		}
	}

	Image content(CType type) { mixin(S_TRACE);
		final switch (type) {
		case CType.Start: return imgd!("evt_start.png");
		case CType.StartBattle: return imgd!("evt_battle.png");
		case CType.End: return imgd!("evt_clear.png");
		case CType.EndBadEnd: return imgd!("evt_gameover.png");
		case CType.ChangeArea: return imgd!("evt_area.png");
		case CType.ChangeBgImage: return imgd!("evt_back.png");
		case CType.Effect: return imgd!("evt_effect.png");
		case CType.EffectBreak: return imgd!("evt_stop.png");
		case CType.LinkStart: return imgd!("evt_link_s.png");
		case CType.LinkPackage: return imgd!("evt_link_p.png");
		case CType.TalkMessage: return imgd!("evt_message.png");
		case CType.TalkDialog: return imgd!("evt_speak.png");
		case CType.PlayBgm: return imgd!("evt_bgm.png");
		case CType.PlaySound: return imgd!("evt_se.png");
		case CType.Wait: return imgd!("evt_wait.png");
		case CType.ElapseTime: return imgd!("evt_time.png");
		case CType.CallStart: return imgd!("evt_call_s.png");
		case CType.CallPackage: return imgd!("evt_call_p.png");
		case CType.BranchFlag: return imgd!("evt_br_flag.png");
		case CType.BranchMultiStep: return imgd!("evt_br_step_n.png");
		case CType.BranchStep: return imgd!("evt_br_step_ul.png");
		case CType.BranchSelect: return imgd!("evt_br_member.png");
		case CType.BranchAbility: return imgd!("evt_br_power.png");
		case CType.BranchRandom: return imgd!("evt_br_random.png");
		case CType.BranchLevel: return imgd!("evt_br_level.png");
		case CType.BranchStatus: return imgd!("evt_br_state.png");
		case CType.BranchPartyNumber: return imgd!("evt_br_num.png");
		case CType.BranchArea: return imgd!("evt_br_area.png");
		case CType.BranchBattle: return imgd!("evt_br_battle.png");
		case CType.BranchIsBattle: return imgd!("evt_br_on_battle.png");
		case CType.BranchCast: return imgd!("evt_br_cast.png");
		case CType.BranchItem: return imgd!("evt_br_item.png");
		case CType.BranchSkill: return imgd!("evt_br_skill.png");
		case CType.BranchInfo: return imgd!("evt_br_info.png");
		case CType.BranchBeast: return imgd!("evt_br_beast.png");
		case CType.BranchMoney: return imgd!("evt_br_money.png");
		case CType.BranchCoupon: return imgd!("evt_br_coupon.png");
		case CType.BranchCompleteStamp: return imgd!("evt_br_end.png");
		case CType.BranchGossip: return imgd!("evt_br_gossip.png");
		case CType.SetFlag: return imgd!("evt_flag_set.png");
		case CType.SetStep: return imgd!("evt_step_set.png");
		case CType.SetStepUp: return imgd!("evt_step_plus.png");
		case CType.SetStepDown: return imgd!("evt_step_minus.png");
		case CType.ReverseFlag: return imgd!("evt_flag_r.png");
		case CType.CheckFlag: return imgd!("evt_flag_judge.png");
		case CType.GetCast: return imgd!("cast.png");
		case CType.GetItem: return imgd!("item.png");
		case CType.GetSkill: return imgd!("skill.png");
		case CType.GetInfo: return imgd!("info.png");
		case CType.GetBeast: return imgd!("beast.png");
		case CType.GetMoney: return imgd!("money.png");
		case CType.GetCoupon: return imgd!("coupon.png");
		case CType.GetCompleteStamp: return imgd!("end.png");
		case CType.GetGossip: return imgd!("gossip.png");
		case CType.LoseCast: return imgd!("evt_lost_cast.png");
		case CType.LoseItem: return imgd!("evt_lost_item.png");
		case CType.LoseSkill: return imgd!("evt_lost_skill.png");
		case CType.LoseInfo: return imgd!("evt_lost_info.png");
		case CType.LoseBeast: return imgd!("evt_lost_beast.png");
		case CType.LoseMoney: return imgd!("evt_lost_money.png");
		case CType.LoseCoupon: return imgd!("evt_lost_coupon.png");
		case CType.LoseCompleteStamp: return imgd!("evt_lost_end.png");
		case CType.LoseGossip: return imgd!("evt_lost_gossip.png");
		case CType.ShowParty: return imgd!("evt_show_party.png");
		case CType.HideParty: return imgd!("evt_hide_party.png");
		case CType.Redisplay: return imgd!("evt_refresh.png");
		case CType.SubstituteStep: return imgd!("evt_cpstep.png");
		case CType.SubstituteFlag: return imgd!("evt_cpflag.png");
		case CType.BranchStepCmp: return imgd!("evt_cmpstep.png");
		case CType.BranchFlagCmp: return imgd!("evt_cmpflag.png");
		case CType.BranchRandomSelect: return imgd!("evt_br_rndsel.png");
		case CType.BranchKeyCode: return imgd!("evt_br_keycode.png");
		case CType.CheckStep: return imgd!("evt_check_step.png");
		case CType.BranchRound: return imgd!("evt_br_round.png");
		case CType.MoveBgImage: return imgd!("evt_mv_back.png"); // Wsn.1
		case CType.ReplaceBgImage: return imgd!("evt_rpl_back.png"); // Wsn.1
		case CType.LoseBgImage: return imgd!("evt_lose_back.png"); // Wsn.1
		case CType.BranchMultiCoupon: return imgd!("evt_br_multi_coupon.png"); // Wsn.2
		case CType.BranchMultiRandom: return imgd!("evt_br_multi_random.png"); // Wsn.2
		case CType.MoveCard: return imgd!("evt_mv_card.png"); // Wsn.3
		case CType.ChangeEnvironment: return imgd!("evt_ch_env.png"); // Wsn.4
		case CType.BranchVariant: return imgd!("evt_br_var.png"); // Wsn.4
		case CType.SetVariant: return imgd!("evt_set_var.png"); // Wsn.4
		case CType.CheckVariant: return imgd!("evt_chk_var.png"); // Wsn.4
		}
	}

	@property Image msnDelete() { return imgd!("del_res.png"); }

	Image motion(MType type) { mixin(S_TRACE);
		final switch (type) {
		case MType.Heal: return imgd!("msn_heal.png");
		case MType.Damage: return imgd!("msn_damage.png");
		case MType.Absorb: return imgd!("msn_absorb.png");
		case MType.Paralyze: return imgd!("msn_paralyze.png");
		case MType.DisParalyze: return imgd!("msn_dis_paralyze.png");
		case MType.Poison: return imgd!("msn_poison.png");
		case MType.DisPoison: return imgd!("msn_dis_poison.png");
		case MType.GetSkillPower: return imgd!("msn_get_skill_power.png");
		case MType.LoseSkillPower: return imgd!("msn_lose_skill_power.png");
		case MType.Sleep: return imgd!("msn_sleep.png");
		case MType.Confuse: return imgd!("msn_confuse.png");
		case MType.Overheat: return imgd!("msn_overheat.png");
		case MType.Brave: return imgd!("msn_brave.png");
		case MType.Panic: return imgd!("msn_panic.png");
		case MType.Normal: return imgd!("msn_wakeup.png");
		case MType.Bind: return imgd!("msn_bind.png");
		case MType.DisBind: return imgd!("msn_dis_bind.png");
		case MType.Silence: return imgd!("msn_silence.png");
		case MType.DisSilence: return imgd!("msn_dis_silence.png");
		case MType.FaceUp: return imgd!("msn_face_up.png");
		case MType.FaceDown: return imgd!("msn_face_down.png");
		case MType.AntiMagic: return imgd!("msn_anti_magic.png");
		case MType.DisAntiMagic: return imgd!("msn_dis_anti_magic.png");
		case MType.EnhanceAction: return imgd!("msn_enh_action.png");
		case MType.EnhanceAvoid: return imgd!("msn_enh_avoid.png");
		case MType.EnhanceDefense: return imgd!("msn_enh_defense.png");
		case MType.EnhanceResist: return imgd!("msn_enh_resist.png");
		case MType.VanishTarget: return imgd!("evt_lost_cast.png");
		case MType.VanishCard: return imgd!("msn_vanish_hand.png");
		case MType.VanishBeast: return imgd!("evt_lost_beast.png");
		case MType.DealAttackCard: return imgd!("hand_attack.png");
		case MType.DealPowerfulAttackCard: return imgd!("hand_p_attack.png");
		case MType.DealCriticalAttackCard: return imgd!("hand_c_attack.png");
		case MType.DealFeintCard: return imgd!("hand_feint.png");
		case MType.DealDefenseCard: return imgd!("hand_defense.png");
		case MType.DealDistanceCard: return imgd!("hand_distance.png");
		case MType.DealConfuseCard: return imgd!("hand_confuse.png");
		case MType.DealSkillCard: return imgd!("hand_skill.png");
		case MType.SummonBeast: return imgd!("msn_summon.png");
		case MType.CancelAction: return imgd!("msn_cancel_action.png"); // CardWirth 1.50
		case MType.NoEffect: return imgd!("msn_no_effect.png"); // Wsn.2
		}
	}

	Image element(Element el) { mixin(S_TRACE);
		final switch (el) {
		case Element.All:
			return imgd!("elm_all.png");
		case Element.Health:
			return imgd!("elm_health.png");
		case Element.Mind:
			return imgd!("elm_mind.png");
		case Element.Miracle:
			return imgd!("elm_miracle.png");
		case Element.Magic:
			return imgd!("elm_magic.png");
		case Element.Fire:
			return imgd!("elm_fire.png");
		case Element.Ice:
			return imgd!("elm_ice.png");
		}
	}

	Image talker(Talker t) { mixin(S_TRACE);
		final switch (t) {
		case Talker.Selected:
			return imgd!("talker_sel.png");
		case Talker.Unselected:
			return imgd!("talker_unsel.png");
		case Talker.Random:
			return imgd!("talker_random.png");
		case Talker.Valued:
			return imgd!("talker_valued.png");
		case Talker.Card:
			throw new Exception("Narration, image and card haven't image.");
		}
	}

	@property Image hand() { return imgd!("card_hand.png"); }
	@property Image handWith(uint targetScale) { return imgd!("card_hand.png")(targetScale); }
	@property Image handEmpty() { return imgd!("card_hand_empty.png"); }
	@property Image handEmptyWith(uint targetScale) { return imgd!("card_hand_empty.png")(targetScale); }
	@property Image eventTree() { return imgd!("event_tree.png"); }
	@property Image eventTreeWith(uint targetScale) { return imgd!("event_tree.png")(targetScale); }
	@property Image eventTreeEmpty() { return imgd!("event_tree_empty.png"); }
	@property Image eventTreeEmptyWith(uint targetScale) { return imgd!("event_tree_empty.png")(targetScale); }
	@property Image eventTreeAnd() { return imgd!("event_tree_and.png"); }
	@property Image eventTreeSelected() { return imgd!("event_tree_selected.png"); }
	@property Image eventTreeAndSelected() { return imgd!("event_tree_and_selected.png"); }
	@property Image defStart() { return imgd!("def_start.png"); }
	@property Image keyCode() { return imgd!("key_code.png"); }
	@property Image round() { return imgd!("round.png"); }
	@property Image newIgnition() { return imgd!("def_start.png"); }
	@property Image expandTree() { return imgd!("tree_open.png"); }
	@property Image foldTree() { return imgd!("tree_close.png"); }
	@property Image showEventTreeDetail() { return imgd!("evt_detail.png"); }
	@property Image showEventTreeLineNumber() { return imgd!("evt_linenum.png"); }

	@property Image addRound() { return imgd!("add_round.png"); }
	@property Image delRound() { return imgd!("del_round.png"); }

	Image keyCodeTiming(FKCKind kind) { mixin(S_TRACE);
		final switch (kind) {
		case FKCKind.Use: return imgd!("key_code.png");
		case FKCKind.Success: return imgd!("key_code_suc.png");
		case FKCKind.Failure: return imgd!("key_code_fail.png");
		case FKCKind.HasNot: return imgd!("key_code_hasnot.png");
		}
	}

	@property Image addCoupon() { return imgd!("add_coupon.png"); }
	@property Image altCoupon() { return imgd!("alt_coupon.png"); }
	@property Image delCoupon() { return imgd!("del_res.png"); }

	@property Image addKeyCode() { return imgd!("add_key_code.png"); }
	@property Image delKeyCode() { return imgd!("del_key_code.png"); }

	@property Image setBeast() { return imgd!("set_beast.png"); }

	@property Image sound() { return imgd!("evt_se.png"); }

	@property Image setTalkerCoupon() { return imgd!("set_beast.png"); }
	Image color(dchar c) { mixin(S_TRACE);
		switch (c) {
		case 'W': return imgd!("cc_w.png");
		case 'R': return imgd!("cc_r.png");
		case 'B': return imgd!("cc_b.png");
		case 'G': return imgd!("cc_g.png");
		case 'Y': return imgd!("cc_y.png");
		case 'O': return imgd!("cc_o.png"); // CardWirth 1.50
		case 'P': return imgd!("cc_p.png"); // CardWirth 1.50
		case 'L': return imgd!("cc_l.png"); // CardWirth 1.50
		case 'D': return imgd!("cc_d.png"); // CardWirth 1.50
		default: return null;
		}
	}
	Image scTalker(Talker talker) { mixin(S_TRACE);
		final switch (talker) {
		case Talker.Selected:
			return imgd!("sc_m.png");
		case Talker.Unselected:
			return imgd!("sc_u.png");
		case Talker.Random:
			return imgd!("sc_r.png");
		case Talker.Card:
			return imgd!("sc_c.png");
		case Talker.Valued:
			throw new Exception("Narration and image haven't image.");
		}
	}
	@property Image scRef() { return imgd!("sc_i.png"); }
	@property Image scTeam() { return imgd!("sc_t.png"); }
	@property Image scYado() { return imgd!("sc_y.png"); }

	@property Image summaryFile() { return imgd!("summary_file.png"); }
	@property Image scenarioArchive() { return imgd!("scenario_arc.png"); }
	@property Image classic() { return imgd!("classic.png"); }

	@property Image script() { return imgd!("script.png"); }

	@property Image editSceneBattle() { return imgd!("battle_cards.png"); }
	@property Image editEventBattle() { return imgd!("battle_event.png"); }

	Image menu(MenuID id) { mixin(S_TRACE);
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
		case MenuID.CreateSubWindow: return imgd!("sub_win.png");
		case MenuID.LeftPane: return imgd!("left_tab.png");
		case MenuID.RightPane: return imgd!("right_tab.png");
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
		case MenuID.EditScenarioHistory: return imgd!("edit_sc_hist.png");
		case MenuID.EditImportHistory: return imgd!("edit_import_hist.png");
		case MenuID.EditExecutedPartyHistory: return imgd!("edit_party_hist.png");
		case MenuID.PutParty: return imgd!("sc_t.png");
		case MenuID.OpenDir: return imgd!("folder.png");
		case MenuID.OpenBackupDir: return imgd!("open_backup.png");
		case MenuID.OpenPlace: return imgd!("folder.png");
		case MenuID.SaveImage: return imgd!("save_inc_img.png");
		case MenuID.IncludeImage: return imgd!("inc_img.png");
		case MenuID.LookImages: return imgd!("img_list.png");
		case MenuID.EditLayers: return imgd!("imagelayer_edit.png");
		case MenuID.AddLayer: return imgd!("imagelayer_add.png");
		case MenuID.RemoveLayer: return imgd!("imagelayer_remove.png");
		case MenuID.ChangeVH: return imgd!("chg_vh.png");
		case MenuID.SelectConnectedResource: return imgd!("sel_connect.png");
		case MenuID.Find: return imgd!("replace.png");
		case MenuID.FindID: return imgd!("find_id.png");
		case MenuID.IncSearch: return imgd!("inc_search.png");
		case MenuID.CloseIncSearch: return imgd!("close_win.png");
		case MenuID.EditProp: return imgd!("edit.png");
		case MenuID.ShowProp: return imgd!("edit.png");
		case MenuID.Refresh: return imgd!("refresh.png");
		case MenuID.Undo: return imgd!("undo.png");
		case MenuID.Redo: return imgd!("redo.png");
		case MenuID.Cut: return imgd!("cut.png");
		case MenuID.Copy: return imgd!("copy.png");
		case MenuID.Paste: return imgd!("paste.png");
		case MenuID.Delete: return imgd!("del.png");
		case MenuID.Cut1Content: return imgd!("cut_1content.png");
		case MenuID.Copy1Content: return imgd!("copy_1content.png");
		case MenuID.Delete1Content: return imgd!("del_1content.png");
		case MenuID.PasteInsert: return imgd!("paste_insert.png");
		case MenuID.Clone: return imgd!("clone.png");
		case MenuID.SelectAll: return imgd!("select_all.png");
		case MenuID.CopyAll: return imgd!("copy_all.png");
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
		case MenuID.CouponView: return imgd!("coupon_win.png");
		case MenuID.GossipView: return imgd!("gossip_win.png");
		case MenuID.CompleteStampView: return imgd!("complete_stamp_win.png");
		case MenuID.KeyCodeView: return imgd!("key_code_win.png");
		case MenuID.CellNameView: return imgd!("cell_name_win.png");
		case MenuID.CardGroupView: return imgd!("card_group_win.png");
		case MenuID.ExecEngine: return imgd!("exec_engine.png");
		case MenuID.ExecEngineAuto: return imgd!("exec_engine.png");
		case MenuID.ExecEngineMain: return imgd!("exec_engine.png");
		case MenuID.ExecEngineWithParty: return imgd!("exec_engine_with_party.png");
		case MenuID.ExecEngineWithLastParty: return imgd!("exec_engine_with_party.png");
		case MenuID.DeleteNotExistsParties: return imgd!("del_not_exists_party.png");
		case MenuID.OuterTools: return imgd!("outer_tool.png");
		case MenuID.Settings: return imgd!("settings.png");
		case MenuID.VersionInfo: return imgd!("version.png");
		case MenuID.LockToolBar: return imgd!("lock_bar.png");
		case MenuID.ResetToolBar: return imgd!("reset_bar.png");
		case MenuID.CopyAsText: return imgd!("copy.png");
		case MenuID.OpenAtView: return imgd!("view.png");
		case MenuID.EventToPackage: return imgd!("e_to_p.png");
		case MenuID.StartToPackage: return imgd!("s_to_p.png");
		case MenuID.WrapTree: return imgd!("wrap_tree.png");
		case MenuID.CreateContent: return imgd!("evt_put_quick.png");
		case MenuID.ConvertContent: return imgd!("conv_cont.png");
		case MenuID.CGroupTerminal: return imgd!("evt_j_term.png");
		case MenuID.CGroupStandard: return imgd!("evt_j_std.png");
		case MenuID.CGroupData: return imgd!("evt_j_data.png");
		case MenuID.CGroupUtility: return imgd!("evt_j_util.png");
		case MenuID.CGroupBranch: return imgd!("evt_j_br.png");
		case MenuID.CGroupGet: return imgd!("evt_j_get.png");
		case MenuID.CGroupLost: return imgd!("evt_j_lost.png");
		case MenuID.CGroupVisual: return imgd!("evt_j_vis.png");
		case MenuID.CGroupVariant: return imgd!("evt_j_var.png");
		case MenuID.EditSummary: return imgd!("summary.png");
		case MenuID.NewAreaDir: return imgd!("areadir_new.png");
		case MenuID.NewArea: return imgd!("area_new.png");
		case MenuID.NewBattle: return imgd!("battle_new.png");
		case MenuID.NewPackage: return imgd!("package_new.png");
		case MenuID.ReNumberingAll: return imgd!("renum_all.png");
		case MenuID.ReNumbering: return imgd!("renum.png");
		case MenuID.EditScene: return imgd!("area_cards.png");
		case MenuID.EditSceneDup: return imgd!("dup_scene.png");
		case MenuID.EditEvent: return imgd!("area_event.png");
		case MenuID.EditEventDup: return imgd!("dup_event.png");
		case MenuID.SetStartArea: return imgd!("start_area.png");
		case MenuID.NewFlagDir: return imgd!("flagdir_new.png");
		case MenuID.NewFlag: return imgd!("flag_new.png");
		case MenuID.NewStep: return imgd!("step_new.png");
		case MenuID.NewVariant: return imgd!("variant_new.png");
		case MenuID.CreateStepValues: return imgd!("create_step_values.png");
		case MenuID.PutSPChar: return imgd!("put_sp_char.png");
		case MenuID.PutFlagValue: return imgd!("flag.png");
		case MenuID.PutStepValue: return imgd!("step.png");
		case MenuID.PutVariantValue: return imgd!("variant.png");
		case MenuID.PutColor: return imgd!("cc_w.png");
		case MenuID.PutSkinSPChar: return imgd!("sc_skin.png");
		case MenuID.PutImageFont: return imgd!("backs.png");
		case MenuID.CreateVariableEventTree: return imgd!("var_tree.png");
		case MenuID.InitVariablesTree: return imgd!("var_init.png");
		case MenuID.CopyVariablePath: return imgd!("copy_path.png");
		case MenuID.Up: return imgd!("up.png");
		case MenuID.Down: return imgd!("down.png");
		case MenuID.ConvertCouponType: return imgd!("coupon_conv.png");
		case MenuID.ConvertCouponTypeNormal: return imgd!("coupon_n.png");
		case MenuID.ConvertCouponTypeHide: return imgd!("coupon_hidden.png");
		case MenuID.ConvertCouponTypeDur: return imgd!("coupon_dur.png");
		case MenuID.ConvertCouponTypeDurBattle: return imgd!("coupon_dur_battle.png");
		case MenuID.ConvertCouponTypeSystem: return imgd!("coupon_system.png");
		case MenuID.CopyTypeConvertedCoupon: return imgd!("coupon_copy_conv.png");
		case MenuID.CopyTypeConvertedCouponNormal: return imgd!("coupon_n.png");
		case MenuID.CopyTypeConvertedCouponHide: return imgd!("coupon_hidden.png");
		case MenuID.CopyTypeConvertedCouponDur: return imgd!("coupon_dur.png");
		case MenuID.CopyTypeConvertedCouponDurBattle: return imgd!("coupon_dur_battle.png");
		case MenuID.CopyTypeConvertedCouponSystem: return imgd!("coupon_system.png");
		case MenuID.AddInitialCoupons: return imgd!("add_initial_coupons.png");
		case MenuID.ReverseSignOfValues: return imgd!("reverse_sign_of_values.png");
		case MenuID.Reverse: return imgd!("reverse.png");
		case MenuID.SwapToParent: return imgd!("swap_parent.png");
		case MenuID.SwapToChild: return imgd!("swap_child.png");
		case MenuID.OverDialog: return imgd!("over_dlg.png");
		case MenuID.UnderDialog: return imgd!("under_dlg.png");
		case MenuID.CreateDialog: return imgd!("evt_speak.png");
		case MenuID.DeleteDialog: return imgd!("del_res.png");
		case MenuID.CopyToAllDialogs: return imgd!("copy_dialog.png");
		case MenuID.CopyToUpperDialogs: return imgd!("copy_dialog_u.png");
		case MenuID.CopyToLowerDialogs: return imgd!("copy_dialog_l.png");
		case MenuID.ShowParty: return imgd!("party_cards.png");
		case MenuID.ShowMsg: return imgd!("view_msg.png");
		case MenuID.ShowRefCards: return imgd!("view_ref.png");
		case MenuID.FixedCards: return imgd!("fixed.png");
		case MenuID.FixedCells: return imgd!("fixed_cell.png");
		case MenuID.FixedBackground: return imgd!("fixed_background.png");
		case MenuID.ShowGrid: return imgd!("grid.png");
		case MenuID.ShowEnemyCardProp: return imgd!("card_life.png");
		case MenuID.ShowCard: return imgd!("show_cards.png");
		case MenuID.ShowBack: return imgd!("show_backs.png");
		case MenuID.NewMenuCard: return imgd!("card_new.png");
		case MenuID.NewEnemyCard: return imgd!("card_new.png");
		case MenuID.NewBack: return imgd!("back_new.png");
		case MenuID.NewTextCell: return imgd!("text_cell_new.png");
		case MenuID.NewColorCell: return imgd!("color_cell_new.png");
		case MenuID.NewPCCell: return imgd!("pc_cell_new.png");
		case MenuID.AutoArrange: return imgd!("auto.png");
		case MenuID.ManualArrange: return imgd!("custom.png");
		case MenuID.PossibleToRunAway: return imgd!("possible_run_away.png");
		case MenuID.SortWithPosition: return imgd!("sort_with_pos.png");
		case MenuID.Mask: return imgd!("mask.png");
		case MenuID.Escape: return imgd!("escape.png");
		case MenuID.ChangePos: return imgd!("chg_pos.png");
		case MenuID.PosTop: return imgd!("pos_top.png");
		case MenuID.PosBottom: return imgd!("pos_bottom.png");
		case MenuID.PosLeft: return imgd!("pos_left.png");
		case MenuID.PosRight: return imgd!("pos_right.png");
		case MenuID.PosEven: return imgd!("pos_even.png");
		case MenuID.NearTop: return imgd!("near_top.png");
		case MenuID.NearBottom: return imgd!("near_bottom.png");
		case MenuID.NearLeft: return imgd!("near_left.png");
		case MenuID.NearRight: return imgd!("near_right.png");
		case MenuID.NearCenterH: return imgd!("near_center_h.png");
		case MenuID.NearCenterV: return imgd!("near_center_v.png");
		case MenuID.NearCenter: return imgd!("near_center.png");
		case MenuID.ScaleMin: return imgd!("scale_min.png");
		case MenuID.ScaleMiddle: return imgd!("scale_middle.png");
		case MenuID.ScaleMax: return imgd!("scale_max.png");
		case MenuID.ScaleBig: return imgd!("scale_even_big.png");
		case MenuID.ScaleSmall: return imgd!("scale_even_small.png");
		case MenuID.ExpandBack: return imgd!("expand_back.png");
		case MenuID.StopBGM: return imgd!("sound_stop.png");
		case MenuID.PlayBGM: return imgd!("sound_play.png");
		case MenuID.NewEvent: return imgd!("new_event_tree.png");
		case MenuID.NewEventWithDialog: return imgd!("new_event_tree.png");
		case MenuID.KeyCodeTiming: return imgd!("key_code_conv.png");
		case MenuID.KeyCodeTimingUse: return imgd!("key_code.png");
		case MenuID.KeyCodeTimingSuccess: return imgd!("key_code_suc.png");
		case MenuID.KeyCodeTimingFailure: return imgd!("key_code_fail.png");
		case MenuID.KeyCodeTimingHasNot: return imgd!("key_code_hasnot.png");
		case MenuID.CopyTimingConvertedKeyCode: return imgd!("key_code_copy_conv.png");
		case MenuID.CopyTimingConvertedKeyCodeUse: return imgd!("key_code.png");
		case MenuID.CopyTimingConvertedKeyCodeSuccess: return imgd!("key_code_suc.png");
		case MenuID.CopyTimingConvertedKeyCodeFailure: return imgd!("key_code_fail.png");
		case MenuID.CopyTimingConvertedKeyCodeHasNot: return imgd!("key_code_hasnot.png");
		case MenuID.AddKeyCodesByFeatures: return imgd!("add_key_codes_by_features.png");
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
		case MenuID.SelectImportSource: return imgd!("sel_import_target.png");
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
		case MenuID.CreateArchive: return imgd!("create_archive.png");
		case MenuID.PutQuick: return imgd!("evt_put_quick.png");
		case MenuID.PutSelect: return imgd!("evt_put_select.png");
		case MenuID.PutContinue: return imgd!("evt_add_continue.png");
		case MenuID.ToScript: return imgd!("script.png");
		case MenuID.ToScriptAll: return imgd!("script_all.png");
		case MenuID.ToScript1Content: return imgd!("script_1content.png");
		case MenuID.EvTemplates: return imgd!("ev_tmpl.png");
		case MenuID.EvTemplatesOfScenario: return imgd!("new_ev_tmpl.png");
		case MenuID.EditSelection: return imgd!("edit_selection.png");
		case MenuID.Expand: return imgd!("expanded.png");
		case MenuID.Collapse: return imgd!("collapsed.png");
		case MenuID.SelectCurrentEvent: return imgd!("select_current_event.png");
		case MenuID.ResetValues: return imgd!("reset.png");
		case MenuID.ResetValuesAll: return imgd!("reset_all.png");
		case MenuID.CustomizeToolBar: return imgd!("custom_tools.png");
		case MenuID.AddTool: return imgd!("add_menu.png");
		case MenuID.AddToolBar: return imgd!("add_bar.png");
		case MenuID.AddToolGroup: return imgd!("add_group.png");
		case MenuID.ResetToolBarSettings: return imgd!("reset_all.png");
		case MenuID.DeleteNotExistsHistory: return imgd!("del_not_exists_sc.png");
		}
	}

	Cursor cursor(CType cType) { mixin(S_TRACE);
		auto p = cType in _curReg;
		if (p) return *p;
		auto img = content(cType);
		if (!img) return null;
		auto imgData = img.getImageData();
		auto cur = new Cursor(Display.getCurrent(), imgData, imgData.width / 2, imgData.height / 2);
		_curReg[cType] = cur;
		return cur;
	}
}
