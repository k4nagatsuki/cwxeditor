
module cwx.warning;

import cwx.utils;
import cwx.msgutils;
import cwx.path;
import cwx.props;
import cwx.summary;
import cwx.flag;
import cwx.card;
import cwx.area;
import cwx.event;
import cwx.skin;
import cwx.background;
import cwx.types;
import cwx.features;
import cwx.imagesize;
import cwx.motion;
import cwx.sjis;
import cwx.binary;

import std.algorithm;
import std.ascii;
import std.conv;
import std.path;
import std.stdio;
import std.string;
import std.traits;
import std.typecons : Tuple;

/// pathの内容を調査し、警告すべき点があればメッセージ群を返す。
string[] warnings(in CProps prop, in Skin skin, in Summary summ, in CWXPath path, string targVer) { mixin(S_TRACE);
	if (!summ || !summ.legacy) targVer = "";
	auto wsnVer = summ ? summ.dataVersion : LATEST_VERSION;
	auto sPath = summ ? summ.scenarioPath : "";
	auto froot = summ ? summ.flagDirRoot : null;
	string[] r;

	auto psumm = cast(Summary)path;
	if (psumm) { mixin(S_TRACE);
		bool warnPos = false;
		foreach (imagePath; psumm.imagePaths) { mixin(S_TRACE);
			if (imagePath.type !is CardImageType.File) continue;
			if (imagePath.path != "" && !isBinImg(imagePath.path) && !skin.findPath(imagePath.path, skin.extImage, skin.tableDirs, sPath, wsnVer, skin.wsnTableDirs(wsnVer)).length) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.searchErrorImageNotFound, .encodePath(imagePath.path));
			}
			if (imagePath.path != "") { mixin(S_TRACE);
				r ~= skin.warningImage(prop, imagePath.path, psumm.legacy, true, targVer);
			}
			if (!warnPos && imagePath.positionType !is CardImagePosition.Default && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
				r ~= prop.msgs.warningCardImagePosition;
				warnPos = true;
			}
		}
		if (psumm.levelMin > psumm.levelMax) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorReversalLevel;
		}
		if (!psumm.area(psumm.startArea)) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorStartAreaNotFound;
		}
		r ~= .sjisWarnings(prop, summ, psumm.scenarioName, prop.msgs.title);
		r ~= .sjisWarnings(prop, summ, psumm.desc, prop.msgs.desc);
		r ~= .sjisWarnings(prop, summ, psumm.author, prop.msgs.author);
		foreach (rc; psumm.rCoupons) { mixin(S_TRACE);
			r ~= .sjisWarnings(prop, summ, rc, prop.msgs.rCoupons);
		}
	}

	auto spChars = skin.spChars;
	auto checkTextRes(string text, in string[] flags, in string[] steps, in string[] fonts, in char[] colors,
			ref bool[string] wFlags, ref bool[string] wSteps, ref bool[string] wFonts, ref bool[char] wColors) { mixin(S_TRACE);
		return .textWarnings(prop, skin, summ, targVer, text, flags, steps, fonts, colors, wFlags, wSteps, wFonts, wColors);
	}
	string[] checkTextRes2(string text, in string[] flags, in string[] steps, in string[] fonts, in char[] colors) { mixin(S_TRACE);
		bool[string] wFlags;
		bool[string] wSteps;
		bool[string] wFonts;
		bool[char] wColors;
		return checkTextRes(text, flags, steps, fonts, colors, wFlags, wSteps, wFonts, wColors).all;
	}

	auto flagDir = cast(FlagDir)path;
	if (flagDir) { mixin(S_TRACE);
		if (flagDir.parent is froot && prop.sys.isSystemVar(flagDir.name)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorSystemVariable, flagDir.name);
		}
		r ~= .sjisWarnings(prop, summ, flagDir.name, "");
	}
	auto flag = cast(cwx.flag.Flag)path;
	if (flag) { mixin(S_TRACE);
		if (flag.parent is froot && prop.sys.isSystemVar(flag.name)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorSystemVariable, flag.name);
		}
		if (flag.expandSPChars && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
			r ~= prop.msgs.warningExpandSPChars;
		}
		r ~= .sjisWarnings(prop, summ, flag.name, prop.msgs.dlgLblFlagName);
		r ~= .sjisWarnings(prop, summ, flag.on, prop.msgs.flagOnValue);
		r ~= .sjisWarnings(prop, summ, flag.off, prop.msgs.flagOffValue);
		if (flag.expandSPChars) { mixin(S_TRACE);
			r ~= checkTextRes2(flag.on, flag.flagsInText(true), flag.stepsInText(true), [], []);
			r ~= checkTextRes2(flag.off, flag.flagsInText(false), flag.stepsInText(false), [], []);
		}
	}
	auto step = cast(Step)path;
	if (step) { mixin(S_TRACE);
		if (step.parent is froot && prop.sys.isSystemVar(step.name)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorSystemVariable, step.name);
		}
		if (step.count != prop.looks.stepMaxCount && summ && summ.legacy) {
			r ~= .tryFormat(prop.msgs.warningStepCount, prop.looks.stepMaxCount);
		}
		if (step.expandSPChars && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
			r ~= prop.msgs.warningExpandSPChars;
		}
		r ~= .sjisWarnings(prop, summ, step.name, prop.msgs.dlgLblStepName);
		foreach (val; step.values) { mixin(S_TRACE);
			r ~= .sjisWarnings(prop, summ, val, prop.msgs.stepValueForWarning);
		}
		if (step.expandSPChars) { mixin(S_TRACE);
			foreach (i; 0u .. step.count) { mixin(S_TRACE);
				r ~= checkTextRes2(step.values[i], step.flagsInText(i), step.stepsInText(i), [], []);
			}
		}
	}
	auto eventTree = cast(EventTree)path;
	if (eventTree) { mixin(S_TRACE);
		if (eventTree.fireEveryRound && !prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
			r ~= prop.msgs.warningEveryRound;
		}
		if (eventTree.fireRound0 && !prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
			r ~= prop.msgs.warningRound0;
		}
		if (eventTree.keyCodeMatchingType is MatchingType.And && !prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
			r ~= prop.msgs.warningKeyCodeMatchingTypeAnd;
		}
		if (eventTree.keyCodes.length && prop.sys.convFireKeyCode(eventTree.keyCodes[0]) == "MatchingType=All") { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorKeyCodeMatchingAll;
		}
		foreach (keyCode; eventTree.keyCodes) { mixin(S_TRACE);
			r ~= .sjisWarnings(prop, summ, keyCode.keyCode, prop.msgs.keyCode);
			if (!prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
				if (keyCode.kind is FKCKind.HasNot) { mixin(S_TRACE);
					r ~= prop.msgs.warningHasNotKeyCode;
				}
			}
		}
	}
	auto playerEvents = cast(PlayerCardEvents)path;
	if (playerEvents) { mixin(S_TRACE);
		if (playerEvents.trees.length && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
			r ~= prop.msgs.warningPlayerCardEvents;
		}
	}
	auto casts = cast(CastCard)path;
	if (casts) { mixin(S_TRACE);
		foreach (cc; casts.coupons) { mixin(S_TRACE);
			r ~= .sjisWarnings(prop, summ, cc.coupon, prop.msgs.history);
			if (cc.coupon.startsWith(prop.sys.couponSystem) && cc.coupon != prop.sys.levelLimit && cc.coupon != prop.sys.ep && !prop.sys.isGene(cc.coupon)) { mixin(S_TRACE);
				r ~= prop.msgs.warningSystemCouponForHistory;
			}
		}
		foreach (c; casts.skills) { mixin(S_TRACE);
			if (0 != c.linkId && !(summ && summ.skill(c.linkId))) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.searchErrorLinkIdSkillNotFound, c.linkId);
			}
		}
		foreach (c; casts.items) { mixin(S_TRACE);
			if (0 != c.linkId && !(summ && summ.item(c.linkId))) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.searchErrorLinkIdItemNotFound, c.linkId);
			}
		}
		foreach (c; casts.beasts) { mixin(S_TRACE);
			if (0 != c.linkId && !(summ && summ.beast(c.linkId))) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.searchErrorLinkIdBeastNotFound, c.linkId);
			}
		}

		Status[] statuses;
		if (casts.life == 0) { mixin(S_TRACE);
			statuses ~= Status.UNCONSCIOUS;
		} else if (casts.life <= casts.lifeMax / 5) { mixin(S_TRACE);
			statuses ~= Status.HEAVY_INJURED;
		} else if (casts.life < casts.lifeMax) { mixin(S_TRACE);
			statuses ~= Status.INJURED;
		} else { mixin(S_TRACE);
			statuses ~= Status.FINE;
		}
		foreach (enh; EnumMembers!Enhance) { mixin(S_TRACE);
			if (casts.enhanceRound(enh) <= 0) continue;
			if (casts.enhance(enh) < 0) { mixin(S_TRACE);
				final switch (Enhance.ACTION) {
				case Enhance.ACTION:
					statuses ~= Status.DOWN_ACTION;
					break;
				case Enhance.AVOID:
					statuses ~= Status.DOWN_AVOID;
					break;
				case Enhance.RESIST:
					statuses ~= Status.DOWN_RESIST;
					break;
				case Enhance.DEFENSE:
					statuses ~= Status.DOWN_DEFENSE;
					break;
				}
			} else if (0 < casts.enhance(enh)) {
				final switch (Enhance.ACTION) {
				case Enhance.ACTION:
					statuses ~= Status.UP_ACTION;
					break;
				case Enhance.AVOID:
					statuses ~= Status.UP_AVOID;
					break;
				case Enhance.RESIST:
					statuses ~= Status.UP_RESIST;
					break;
				case Enhance.DEFENSE:
					statuses ~= Status.UP_DEFENSE;
					break;
				}
			}
		}
		if (0 < casts.paralyze) { mixin(S_TRACE);
			statuses ~= Status.PARALYZE;
		}
		if (0 < casts.poison) { mixin(S_TRACE);
			statuses ~= Status.POISON;
		}
		if (0 < casts.bindRound) { mixin(S_TRACE);
			statuses ~= Status.BIND;
		}
		if (0 < casts.silenceRound) { mixin(S_TRACE);
			statuses ~= Status.SILENCE;
		}
		if (0 < casts.faceUpRound) { mixin(S_TRACE);
			statuses ~= Status.FACE_UP;
		}
		if (0 < casts.antiMagicRound) { mixin(S_TRACE);
			statuses ~= Status.ANTI_MAGIC;
		}
		if (0 < casts.mentalityRound) { mixin(S_TRACE);
			final switch (casts.mentality) {
			case Mentality.NORMAL:
				break;
			case Mentality.SLEEP:
				statuses ~= Status.SLEEP;
				break;
			case Mentality.CONFUSE:
				statuses ~= Status.CONFUSE;
				break;
			case Mentality.OVERHEAT:
				statuses ~= Status.OVERHEAT;
				break;
			case Mentality.BRAVE:
				statuses ~= Status.BRAVE;
				break;
			case Mentality.PANIC:
				statuses ~= Status.PANIC;
				break;
			}
		}
		r ~= .warningInconsistency(prop, statuses);
	}
	auto card = cast(Card)path;
	if (card) { mixin(S_TRACE);
		r ~= .sjisWarnings(prop, summ, card.name, prop.msgs.name);
		r ~= .sjisWarnings(prop, summ, card.desc, prop.msgs.desc);
		bool warnPos = false;
		foreach (imagePath; card.paths) { mixin(S_TRACE);
			if (imagePath.type !is CardImageType.File) continue;
			if (imagePath.path != "" && !isBinImg(imagePath.path) && !skin.findPath(imagePath.path, skin.extImage, skin.tableDirs, sPath, wsnVer, skin.wsnTableDirs(wsnVer)).length) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.searchErrorImageNotFound, .encodePath(imagePath.path));
			}
			if (imagePath.path != "") { mixin(S_TRACE);
				r ~= skin.warningImage(prop, imagePath.path, summ ? summ.legacy : false, true, targVer);
			}
			if (!warnPos && imagePath.positionType !is CardImagePosition.Default && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
				r ~= prop.msgs.warningCardImagePosition;
				warnPos = true;
			}
		}
	}
	void putMotions(in Motion[] motions) { mixin(S_TRACE);
		bool[string] exists;
		foreach (m; motions) { mixin(S_TRACE);
			void put(string w) { mixin(S_TRACE);
				if (w !in exists) { mixin(S_TRACE);
					r ~= w;
					exists[w] = true;
				}
			}
			if (m.type is MType.CANCEL_ACTION && !prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
				put(.tryFormat(prop.msgs.warningUnknownMotion, prop.msgs.motionName(m.type), "1.50"));
			}
			if (m.type is MType.NO_EFFECT && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
				put(.tryFormat(prop.msgs.warningUnknownMotion, prop.msgs.motionName(m.type), "2"));
			}
			if (m.type == MType.SUMMON_BEAST && !m.beast) { mixin(S_TRACE);
				put(prop.msgs.searchErrorNoBeast);
			}
			if (m.type == MType.SUMMON_BEAST && m.beast && 0 != m.beast.linkId && !(summ && summ.beast(m.beast.linkId))) { mixin(S_TRACE);
				put(.tryFormat(prop.msgs.searchErrorLinkIdBeastNotFound, m.beast.linkId));
			}
			if ((m.type == MType.GET_SKILL_POWER || m.type == MType.LOSE_SKILL_POWER)
					&& m.damageType !is DamageType.MAX && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
				put(prop.msgs.warningSkillPowerWithFixedValue);
			}
		}
	}
	auto effCard = cast(EffectCard)path;
	if (effCard) { mixin(S_TRACE);
		r ~= .sjisWarnings(prop, summ, effCard.scenario, prop.msgs.sourceScenario);
		r ~= .sjisWarnings(prop, summ, effCard.author, prop.msgs.sourceAuthor);
		putMotions(effCard.motions);
		auto beast = cast(BeastCard)effCard;
		if (beast) { mixin(S_TRACE);
			if (!.equal(beast.invocationCondition, [Status.ALIVE])) { mixin(S_TRACE);
				r ~= prop.msgs.warningInvocationCondition;
			}
			if (!beast.removeWithUnconscious) { mixin(S_TRACE);
				r ~= prop.msgs.warningRemoveWithUnconscious;
			}
			if (beast.removeWithUnconscious && beast.invocationCondition.contains(Status.UNCONSCIOUS)) { mixin(S_TRACE);
				r ~= prop.msgs.warningUnconsciousCondition;
			}
		}
		if (effCard.soundPath1 != "") { mixin(S_TRACE);
			r ~= skin.warningSE(prop, effCard.soundPath1, summ ? summ.legacy : false, targVer);
			if (!skin.findPath(effCard.soundPath1, skin.extSound, skin.seDirs, sPath, wsnVer, skin.wsnSoundDirs(wsnVer)).length) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.searchErrorSENotFound, .encodePath(effCard.soundPath1));
			}
			if ((effCard.volume1 != 100 || effCard.volume2 != 100) && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
				r ~= prop.msgs.warningVolume;
			}
		}
		if (effCard.soundPath2 != "") { mixin(S_TRACE);
			r ~= skin.warningSE(prop, effCard.soundPath2, summ ? summ.legacy : false, targVer);
			if (!skin.findPath(effCard.soundPath2, skin.extSound, skin.seDirs, sPath, wsnVer, skin.wsnSoundDirs(wsnVer)).length) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.searchErrorSENotFound, .encodePath(effCard.soundPath2));
			}
			if ((effCard.loopCount1 != 1 || effCard.loopCount2 != 1) && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
				r ~= prop.msgs.warningLoopCount;
			}
		}
		if (prop.sys.isRunaway(effCard.keyCodes)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningRunawayCard, prop.sys.runaway);
		}
		if (prop.looks.keyCodesMaxLegacy < effCard.keyCodes.length && summ && summ.legacy) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningKeyCodeCount, prop.looks.keyCodesMaxLegacy);
		}
		foreach (keyCode; effCard.keyCodes) { mixin(S_TRACE);
			r ~= .sjisWarnings(prop, summ, keyCode, prop.msgs.keyCode);
		}
	}
	auto bi = cast(BgImage)path;
	if (bi) { mixin(S_TRACE);
		if (bi.flag != "" && !(froot && froot.findFlag(bi.flag))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorFlagNotFound, bi.flag);
		}
		if (bi.cellName != "") { mixin(S_TRACE);
			r ~= .sjisWarnings(prop, summ, bi.cellName, prop.msgs.bgImageCellName);
			if (!prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
				r ~= prop.msgs.warningBgImageCellName;
			}
		}
		if (bi.layer != LAYER_BACK_CELL) { mixin(S_TRACE);
			// 1.60
/+			if (!prop.targetVersion("1.60", targVer)) { mixin(S_TRACE);
				r ~= prop.msgs.warningBgImageForeground;
			}
+/			if (!prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
				r ~= prop.msgs.warningLayer;
			}
		}
	}
	auto ic = cast(ImageCell)path;
	if (ic) { mixin(S_TRACE);
		if (!ic.path.length) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorNoImage;
		}
		if (isBinImg(ic.path)) { mixin(S_TRACE);
			if (!prop.targetVersion("1.60", targVer)) { mixin(S_TRACE);
				r ~= prop.msgs.warningBgImageIncluded;
			}
		} else if (ic.path.length && !skin.findPath(ic.path, skin.extImage, skin.tableDirs, sPath, wsnVer, skin.wsnTableDirs(wsnVer)).length) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorImageNotFound, .encodePath(ic.path));
		}
		if (ic.path != "") { mixin(S_TRACE);
			r ~= skin.warningImage(prop, ic.path, summ ? summ.legacy : false, false, targVer);
		}
		if (ic.smoothing !is Smoothing.Default && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
			r ~= prop.msgs.warningBgImageSmoothing;
		}
	}
	auto tc = cast(TextCell)path;
	if (tc) { mixin(S_TRACE);
		r ~= checkTextRes2(tc.text, tc.flagsInText, tc.stepsInText, [], []);
		if (!prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
			r ~= prop.msgs.warningTextCell;
		}
		if (summ && summ.legacy && tc.updateType !is UpdateType.Fixed) { mixin(S_TRACE);
			r ~= prop.msgs.warningUpdateTypeNotFixed;
		}
		if (summ && !summ.legacy && tc.updateType !is UpdateType.Variables) { mixin(S_TRACE);
			r ~= prop.msgs.warningUpdateTypeFixed;
		}
	}
	auto cc = cast(ColorCell)path;
	if (cc) { mixin(S_TRACE);
		if (!prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
			r ~= prop.msgs.warningColorCell;
		}
	}
	auto pc = cast(PCCell)path;
	if (pc) { mixin(S_TRACE);
		if (!prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
			r ~= prop.msgs.warningPCCell;
		}
		if (pc.smoothing !is Smoothing.Default && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
			r ~= prop.msgs.warningBgImageSmoothing;
		}
	}
	auto aa = cast(AbstractArea)path;
	if (aa) { mixin(S_TRACE);
		r ~= .sjisWarnings(prop, summ, aa.name, prop.msgs.name);
	}
	auto btl = cast(Battle)path;
	if (btl) { mixin(S_TRACE);
		if (!btl.possibleToRunAway && !prop.isTargetVersion(summ, targVer, "3")) { mixin(S_TRACE);
			r ~= prop.msgs.warningPossibleToRunAway;
		}
		if (!btl.possibleToRunAway) { mixin(S_TRACE);
			foreach (et; btl.trees) { mixin(S_TRACE);
				if (et.fireEscape) { mixin(S_TRACE);
					r ~= prop.msgs.warningNoIgniteRunAway;
					break;
				}
			}
		}
		if (btl.music != "") { mixin(S_TRACE);
			r ~= skin.warningBGM(prop, btl.music, summ ? summ.legacy : false, targVer);
			if (!skin.findPath(btl.music, skin.extBgm, skin.bgmDirs, sPath, wsnVer, skin.wsnMusicDirs(wsnVer)).length) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.searchErrorBGMNotFound, .encodePath(btl.music));
			}
			if (btl.volume != 100 && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
				r ~= prop.msgs.warningVolume;
			}
			if (btl.loopCount != 0 && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
				r ~= prop.msgs.warningLoopCount;
			}
			if (btl.fadeIn != 0 && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
				r ~= prop.msgs.warningFadeIn;
			}
		}
		if (btl.continueBGM && !prop.isTargetVersion(summ, targVer, "3")) { mixin(S_TRACE);
			r ~= prop.msgs.warningContinueBGM;
		}
	}
	auto mc = cast(MenuCard)path;
	if (mc) { mixin(S_TRACE);
		r ~= .sjisWarnings(prop, summ, mc.name, prop.msgs.name);
		r ~= .sjisWarnings(prop, summ, mc.desc, prop.msgs.desc);
		bool warnPos = false;
		foreach (imagePath; mc.paths) { mixin(S_TRACE);
			if (imagePath.type is CardImageType.File) { mixin(S_TRACE);
				if (imagePath.path != "" && !isBinImg(imagePath.path) && !skin.findPath(imagePath.path, skin.extImage, skin.tableDirs, sPath, wsnVer, skin.wsnTableDirs(wsnVer)).length) { mixin(S_TRACE);
					r ~= .tryFormat(prop.msgs.searchErrorImageNotFound, .encodePath(imagePath.path));
				}
				if (imagePath.path != "") {
					r ~= skin.warningImage(prop, imagePath.path, summ ? summ.legacy : false, false, targVer);
				}
			}
			if (imagePath.type is CardImageType.PCNumber && !prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
				r ~= prop.msgs.warningPCNumberClassic;
			}
			if (!warnPos && imagePath.positionType !is CardImagePosition.Default && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
				r ~= prop.msgs.warningCardImagePosition;
				warnPos = true;
			}
		}
		if (mc.flag != "" && !(froot && froot.findFlag(mc.flag))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorFlagNotFound, mc.flag);
		}
	}
	auto ec = cast(EnemyCard)path;
	if (ec) { mixin(S_TRACE);
		if (ec.id == 0) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorNoCast;
		}
		if (ec.id != 0 && !(summ && summ.cwCast(ec.id))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorCastNotFound, ec.id);
		}
		if (ec.flag != "" && !(froot && froot.findFlag(ec.flag))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorFlagNotFound, ec.flag);
		}
	}
	auto spc = cast(AbstractSpCard)path;
	if (spc) { mixin(S_TRACE);
		r ~= .sjisWarnings(prop, summ, spc.cardGroup, prop.msgs.cardGroup);
		if (spc.layer != LAYER_MENU_CARD) {
			// 1.60
/+			if (!prop.targetVersion("1.60", targVer)) { mixin(S_TRACE);
				r ~= prop.msgs.warningBgImageForeground;
			}
+/			if (!prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
				r ~= prop.msgs.warningLayer;
			}
		}
		if (spc.cardGroup != "") {
			if (!prop.isTargetVersion(summ, targVer, "3")) { mixin(S_TRACE);
				r ~= prop.msgs.warningCardGroup;
			}
		}
	}
	auto c = cast(Content)path;
	if (c) { mixin(S_TRACE);
		auto cd = c.detail;
		if (!c.parent || c.parent.detail.nextType is CNextType.TEXT || c.parent.detail.nextType is CNextType.COUPON) { mixin(S_TRACE);
			r ~= .sjisWarnings(prop, summ, c.name, prop.msgs.contentNameForWarning);
		}
		if ((summ ? summ.legacy : false) && c.type == CType.WAIT && !c.next.length) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorIgnoreWait;
		}
		if (c.parent) { mixin(S_TRACE);
			auto wNC = .warningNextCondition(prop, c.parent.detail.nextType, c.name);
			if (wNC) r ~= wNC;
		}
		if (cd.owner && cd.nextType != CNextType.TEXT) { mixin(S_TRACE);
			auto set = new HashSet!(string);
			foreach (cld; c.next) { mixin(S_TRACE);
				if (cld.name == "" && c.type !is CType.BRANCH_MULTI_COUPON) continue;
				if (cld.type is CType.CHECK_FLAG || cld.type is CType.CHECK_STEP) continue;
				if (set.contains(cld.name)) { mixin(S_TRACE);
					r ~= prop.msgs.searchErrorDupNextContent;
					break;
				}
				set.add(cld.name);
			}
		}
		if (c.parent && c.parent.detail.nextType == CNextType.TEXT) { mixin(S_TRACE);
			auto fit = c.flagsInName;
			auto sit = c.stepsInName;
			auto foit = c.namesInName;
			if (!prop.targetVersion("1.50", targVer) && (fit.length || sit.length || foit.length)) { mixin(S_TRACE);
				r ~= prop.msgs.warningSPCharsInSelections;
			} else { mixin(S_TRACE);
				r ~= checkTextRes2("", fit, sit, [], []);
			}
		}

		void couponWarnings(string coupon, bool getLose, string name) { mixin(S_TRACE);
			r ~= .couponWarnings(prop, summ, targVer, coupon, getLose, name);
		}

		if (c.type == CType.TALK_DIALOG) { mixin(S_TRACE);
			if (!prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
				if (Talker.VALUED is c.talkerNC) { mixin(S_TRACE);
					r ~= prop.msgs.warningValuedTalker;
				}
			}
			if (c.dialogs.length) { mixin(S_TRACE);
				bool[string] wFlags;
				bool[string] wSteps;
				bool[string] wFonts;
				bool[char] wColors;
				foreach (i, dlg; c.dialogs) { mixin(S_TRACE);
					foreach (coupon; dlg.rCoupons) { mixin(S_TRACE);
						couponWarnings(coupon, false, prop.msgs.toneCoupons);
					}
					r ~= checkTextRes(dlg.text, dlg.flagsInText, dlg.stepsInText, dlg.fontsInText, dlg.colorsInText,
						wFlags, wSteps, wFonts, wColors).noDup;
					if (i + 1 < c.dialogs.length && !dlg.rCoupons.length) { mixin(S_TRACE);
						// 最後以外にクーポンが設定されていない場合
						r ~= prop.msgs.searchErrorNoRCouponsDialog;
					}
				}
			}
		}
		r ~= checkTextRes2(c.text, c.flagsInText, c.stepsInText, c.fontsInText, c.colorsInText);
		bool hasStart() { mixin(S_TRACE);
			foreach (s; c.tree.starts) { mixin(S_TRACE);
				if (s.name == c.start) return true;
			}
			return false;
		}
		{ mixin(S_TRACE);
			bool[string] tbl;
			string[] ws2;
			foreach (back; c.backs) { mixin(S_TRACE);
				auto ws = warnings(prop, skin, summ, back, targVer);
				if (cd.use(CArg.IGNORE_EFFECT_BOOSTER) && c.ignoreEffectBooster) { mixin(S_TRACE);
					if (auto ic2 = cast(ImageCell)back) { mixin(S_TRACE);
						auto ext = ic2.path.extension().toLower();
						if (ext == ".jpy1" || ext == ".jptx" || ext == ".jpdc") { mixin(S_TRACE);
							ws ~= prop.msgs.warningEffectBoosterFileWithReplaceBgImage;
						}
					}
				}
				foreach (w; ws) { mixin(S_TRACE);
					if (w !in tbl) { mixin(S_TRACE);
						ws2 ~= w;
						tbl[w] = true;
					}
				}
			}
			r ~= ws2;
		}
		if (c.flag != "" && !(froot && froot.findFlag(c.flag))) { mixin(S_TRACE);
			// 代入コンテントではランダム値が有効
			if (c.type != CType.SUBSTITUTE_FLAG || .icmp(prop.sys.randomValue, c.flag) != 0) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.searchErrorFlagNotFound, c.flag);
			}
		}
		if (c.step != "" && !(froot && froot.findStep(c.step))) { mixin(S_TRACE);
			// 代入コンテントではランダム値・選択メンバ番号が有効
			if (c.type != CType.SUBSTITUTE_STEP || (.icmp(prop.sys.randomValue, c.step) != 0 && .icmp(prop.sys.selectedPlayerCardNumber, c.step) != 0)) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.searchErrorStepNotFound, c.step);
			}
			if (c.type == CType.SUBSTITUTE_STEP && .icmp(prop.sys.selectedPlayerCardNumber, c.step) == 0 && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
				r ~= prop.msgs.warningSelectedPlayerValue;
			}
		}
		bool warnPos = false;
		foreach (cardPath; c.cardPaths) { mixin(S_TRACE);
			if (cardPath.type !is CardImageType.File) continue;
			if (cardPath.path != "" && !skin.findPath(cardPath.path, skin.extImage, skin.tableDirs, sPath, wsnVer, skin.wsnTableDirs(wsnVer)).length) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.searchErrorImageNotFound, .encodePath(cardPath.path));
			}
			if (cardPath.path != "") { mixin(S_TRACE);
				r ~= skin.warningImage(prop, cardPath.path, summ ? summ.legacy : false, false, targVer);
			}
			if (!warnPos && cardPath.positionType !is CardImagePosition.Default && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
				r ~= prop.msgs.warningCardImagePosition;
				warnPos = true;
			}
		}
		if (c.bgmPath != "") { mixin(S_TRACE);
			r ~= skin.warningBGM(prop, c.bgmPath, summ ? summ.legacy : false, targVer);
		}
		if (c.bgmPath != "" && !skin.findPath(c.bgmPath, skin.extBgm, skin.bgmDirs, sPath, wsnVer, skin.wsnMusicDirs(wsnVer)).length) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorBGMNotFound, .encodePath(c.bgmPath));
		}
		if (c.soundPath != "") { mixin(S_TRACE);
			r ~= skin.warningSE(prop, c.soundPath, summ ? summ.legacy : false, targVer);
		}
		if (c.soundPath != "" && !skin.findPath(c.soundPath, skin.extSound, skin.seDirs, sPath, wsnVer, skin.wsnSoundDirs(wsnVer)).length) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorSENotFound, .encodePath(c.soundPath));
		}
		if (c.area != 0 && !(summ && summ.area(c.area))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorAreaNotFound, c.area);
		}
		if (c.battle != 0 && !(summ && summ.battle(c.battle))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorBattleNotFound, c.battle);
		}
		if (c.packages != 0 && !(summ && summ.cwPackage(c.packages))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorPackageNotFound, c.packages);
		}
		if (c.casts != 0 && !(summ && summ.cwCast(c.casts))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorCastNotFound, c.casts);
		}
		if (c.item != 0 && !(c.range is Range.SELECTED_CARD && c.type is CType.LOSE_ITEM) && !(summ && summ.item(c.item))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorItemNotFound, c.item);
		}
		if (c.skill != 0 && !(c.range is Range.SELECTED_CARD && c.type is CType.LOSE_SKILL) && !(summ && summ.skill(c.skill))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorSkillNotFound, c.skill);
		}
		if (c.beast != 0 && !(c.range is Range.SELECTED_CARD && c.type is CType.LOSE_BEAST) && !(summ && summ.beast(c.beast))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorBeastNotFound, c.beast);
		}
		if (c.info != 0 && !(summ && summ.info(c.info))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorInfoNotFound, c.info);
		}
		if (c.start != "" && !hasStart()) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorStartNotFound, c.start);
		}
		putMotions(c.motions);
		if (c.flag2 != "" && !(froot && froot.findFlag(c.flag2))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorFlagNotFound, c.flag2);
		}
		if (c.step2 != "" && !(froot && froot.findStep(c.step2))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorStepNotFound, c.step2);
		}
		if (c.flag != "" && c.flag == c.flag2) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorSourceIsTarget;
		}
		if (c.step != "" && c.step == c.step2) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorSourceIsTarget;
		}
		if (cd.use(CArg.COUPON_NAMES)) { mixin(S_TRACE);
			if (!c.couponNames.length) { mixin(S_TRACE);
				r ~= prop.msgs.searchErrorNoCoupon;
			}
			if(!prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
				if (1 < c.couponNames.length) { mixin(S_TRACE);
					r ~= prop.msgs.warningBranchCouponMulti;
				}
			}
			foreach (coupon; c.couponNames) { mixin(S_TRACE);
				couponWarnings(coupon, false, prop.msgs.couponName);
			}
		}
		if ((c.type is CType.GET_COUPON || c.type is CType.LOSE_COUPON) && prop.sys.isCouponType(c.coupon, CouponType.System)) { mixin(S_TRACE);
			couponWarnings(c.coupon, true, prop.msgs.couponName);
		}
		if (cd.use(CArg.COUPONS)) { mixin(S_TRACE);
			foreach (coupon; c.coupons) { mixin(S_TRACE);
				couponWarnings(coupon.name, false, prop.msgs.valued);
			}
		}
		if (c.levelMin > c.levelMax) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorReversalLevel;
		}
		if (c.type is CType.BRANCH_ROUND) { mixin(S_TRACE);
			CWXPath cwxPath = c;
			while (cwxPath) { mixin(S_TRACE);
				if (cast(Area) cwxPath) { mixin(S_TRACE);
					r ~= prop.msgs.searchErrorBranchRoundInArea;
					break;
				}
				cwxPath = cwxPath.cwxParent();
			}
		}
		if (c.bgmChannel != 0 && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
			r ~= prop.msgs.warningChannel;
		}
		if (c.bgmFadeIn != 0 && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
			r ~= prop.msgs.warningFadeIn;
		}
		if (c.bgmPath != "") { mixin(S_TRACE);
			if (c.bgmVolume != 100 && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
				r ~= prop.msgs.warningVolume;
			}
			if (c.bgmLoopCount != 0 && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
				r ~= prop.msgs.warningLoopCount;
			}
		}
		if (c.soundPath != "") { mixin(S_TRACE);
			if (c.soundFadeIn != 0 && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
				r ~= prop.msgs.warningFadeIn;
			}
			if (c.soundVolume != 100 && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
				r ~= prop.msgs.warningVolume;
			}
			if (c.soundLoopCount != 1 && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
				r ~= prop.msgs.warningLoopCount;
			}
			if (c.soundChannel!= 0 && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
				r ~= prop.msgs.warningChannel;
			}
		}
		if (cd.use(CArg.AREA) && c.area == 0) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorNoArea;
		}
		if (cd.use(CArg.BATTLE) && c.battle == 0) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorNoBattle;
		}
		if (cd.use(CArg.PACKAGE) && c.packages == 0) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorNoPackage;
		}
		if (cd.use(CArg.CAST) && c.casts == 0) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorNoCast;
		}
		if (cd.use(CArg.ITEM) && c.item == 0) { mixin(S_TRACE);
			if (!(c.range is Range.SELECTED_CARD && c.type is CType.LOSE_ITEM)) { mixin(S_TRACE);
				r ~= prop.msgs.searchErrorNoItem;
			}
		}
		if (cd.use(CArg.SKILL) && c.skill == 0) { mixin(S_TRACE);
			if (!(c.range is Range.SELECTED_CARD && c.type is CType.LOSE_SKILL)) { mixin(S_TRACE);
				r ~= prop.msgs.searchErrorNoSkill;
			}
		}
		if (cd.use(CArg.BEAST) && c.beast == 0) { mixin(S_TRACE);
			if (!(c.range is Range.SELECTED_CARD && c.type is CType.LOSE_BEAST)) { mixin(S_TRACE);
				r ~= prop.msgs.searchErrorNoBeast;
			}
		}
		if (cd.use(CArg.INFO) && c.info == 0) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorNoInfo;
		}
		if ((cd.use(CArg.FLAG) && c.flag == "") || (cd.use(CArg.FLAG_2) && c.flag2 == "")) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorNoFlag;
		}
		if ((cd.use(CArg.STEP) && c.step == "") || (cd.use(CArg.STEP_2) && c.step2 == "")) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorNoStep;
		}
		if (cd.use(CArg.COUPON)) { mixin(S_TRACE);
			r ~= .sjisWarnings(prop, summ, c.coupon, prop.msgs.couponName);
			if (c.coupon == "") r ~= prop.msgs.searchErrorNoCoupon;
		}
		if (cd.use(CArg.GOSSIP)) { mixin(S_TRACE);
			r ~= .sjisWarnings(prop, summ, c.gossip, prop.msgs.gossipName);
			if (c.gossip == "") r ~= prop.msgs.searchErrorNoGossip;
		}
		if (cd.use(CArg.COMPLETE_STAMP)) { mixin(S_TRACE);
			r ~= .sjisWarnings(prop, summ, c.completeStamp, prop.msgs.endName);
			if (c.completeStamp == "") r ~= prop.msgs.searchErrorNoCompleteStamp;
		}
		if (cd.use(CArg.KEY_CODE)) { mixin(S_TRACE);
			r ~= .sjisWarnings(prop, summ, c.keyCode, prop.msgs.keyCode);
			if (c.keyCode == "") r ~= prop.msgs.searchErrorNoKeyCode;
		}
		if (cd.use(CArg.CELL_NAME) && c.cellName == "") { mixin(S_TRACE);
			r ~= .sjisWarnings(prop, summ, c.cellName, prop.msgs.cellName);
			r ~= prop.msgs.searchErrorNoCellName;
		}
		if (cd.use(CArg.CARD_GROUP) && c.cardGroup == "") { mixin(S_TRACE);
			r ~= .sjisWarnings(prop, summ, c.cardGroup, prop.msgs.cardGroup);
			r ~= prop.msgs.searchErrorNoCardGroup;
		}
		uint maxNextLen(in Content c) { mixin(S_TRACE);
			if (c.type is CType.TALK_MESSAGE) { mixin(S_TRACE);
				return c.text == "" ? prop.looks.selectionBarMax : prop.looks.selectionBarMaxWithMessage;
			} else if (c.type is CType.TALK_DIALOG) { mixin(S_TRACE);
				foreach (dlg; c.dialogs) { mixin(S_TRACE);
					if (dlg.text != "") return prop.looks.selectionBarMaxWithMessage;
				}
				return prop.looks.selectionBarMax;
			}
			return uint.max;
		}
		size_t rows(in Content c) { mixin(S_TRACE);
			size_t len = 0;
			foreach (n; c.next) { mixin(S_TRACE);
				if (n.name != "" && n.type !is CType.CHECK_FLAG && n.type !is CType.CHECK_STEP) { mixin(S_TRACE);
					len++;
				}
			}
			return (len + (c.selectionColumns - 1)) / c.selectionColumns;
		}
		if (cd.nextType is CNextType.TEXT && maxNextLen(c) < rows(c)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningSelectionBarIsMany, rows(c), maxNextLen(c));
		}
		if (cd.nextType is CNextType.TEXT && c.selectionColumns != 1 && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
			r ~= prop.msgs.warningSelectionColumns;
		}

		if (c.status !is Status.NONE) { mixin(S_TRACE);
			if (Status.SILENCE <= c.status && !prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.warningBranchStatusMental, prop.msgs.statusName(c.status), "1.50");
			} else if (Status.CONFUSE <= c.status && !prop.targetVersion("1.30", targVer)) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.warningBranchStatusMental, prop.msgs.statusName(c.status), "1.30");
			}
		}
		if (c.range == Range.FIELD && cd.use(CArg.COUPON) && !prop.targetVersion("1.30", targVer)) { mixin(S_TRACE);
			r ~= prop.msgs.warningBranchCouponAtField;
		}
		if (c.selectionMethod is SelectionMethod.Valued && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
			r ~= prop.msgs.warningValuedSelectionMethod;
		}
		if (c.type is CType.CHECK_STEP && !prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContent, prop.msgs.contentName(CType.CHECK_STEP), "1.50");
		}
		if (c.type is CType.SUBSTITUTE_STEP && !prop.targetVersion("1.30", targVer)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContent, prop.msgs.contentName(CType.SUBSTITUTE_STEP), "1.30");
		}
		if (c.type is CType.SUBSTITUTE_FLAG && !prop.targetVersion("1.30", targVer)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContent, prop.msgs.contentName(CType.SUBSTITUTE_FLAG), "1.30");
		}
		if (c.type is CType.BRANCH_STEP_CMP && !prop.targetVersion("1.30", targVer)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContent, prop.msgs.contentName(CType.BRANCH_STEP_CMP), "1.30");
		}
		if (c.type is CType.BRANCH_FLAG_CMP && !prop.targetVersion("1.30", targVer)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContent, prop.msgs.contentName(CType.BRANCH_FLAG_CMP), "1.30");
		}
		if (c.type is CType.BRANCH_RANDOM_SELECT && !prop.targetVersion("1.30", targVer)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContent, prop.msgs.contentName(CType.BRANCH_RANDOM_SELECT), "1.30");
		}
		if (c.type is CType.BRANCH_KEY_CODE && !prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContent, prop.msgs.contentName(CType.BRANCH_KEY_CODE), "1.50");
		}
		if (c.type is CType.BRANCH_ROUND && !prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContent, prop.msgs.contentName(CType.BRANCH_ROUND), "1.50");
		}
		if (c.type is CType.REPLACE_BG_IMAGE && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContentWsn, prop.msgs.contentName(CType.REPLACE_BG_IMAGE), "1");
		}
		if (c.type is CType.LOSE_BG_IMAGE && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContentWsn, prop.msgs.contentName(CType.LOSE_BG_IMAGE), "1");
		}
		if (c.type is CType.MOVE_BG_IMAGE && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContentWsn, prop.msgs.contentName(CType.MOVE_BG_IMAGE), "1");
		}
		if (c.type is CType.BRANCH_MULTI_COUPON && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContentWsn, prop.msgs.contentName(CType.BRANCH_MULTI_COUPON), "2");
		}
		if (c.type is CType.BRANCH_MULTI_RANDOM && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContentWsn, prop.msgs.contentName(CType.BRANCH_MULTI_RANDOM), "2");
		}
		if (c.type is CType.MOVE_CARD && !prop.isTargetVersion(summ, targVer, "3")) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContentWsn, prop.msgs.contentName(CType.MOVE_CARD), "3");
		}
		if (cd.use(CArg.STEP_VALUE)) { mixin(S_TRACE);
			if (froot && c.step != "") { mixin(S_TRACE);
				auto s = froot.findStep(c.step);
				if (s && s.count < c.stepValue) { mixin(S_TRACE);
					r ~= .tryFormat(prop.msgs.warningStepOverCount, s.name, s.count, c.stepValue);
				}
			}
			if (summ && summ.legacy && prop.looks.stepMaxCount < c.stepValue) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.warningStepCount, prop.looks.stepMaxCount);
			}
		}
		if (c.parent && c.parent.detail.nextType is CNextType.STEP && c.name != prop.sys.evtChildDefault && std.string.isNumeric(c.name)) { mixin(S_TRACE);
			try {
				auto value = .to!uint(c.name);
				if (froot && c.parent.step != "") { mixin(S_TRACE);
					auto s = froot.findStep(c.parent.step);
					if (s && s.count < value) { mixin(S_TRACE);
						r ~= .tryFormat(prop.msgs.warningStepOverCount, s.name, s.count, value);
					}
				}
				if (summ && summ.legacy && prop.looks.stepMaxCount < value) { mixin(S_TRACE);
					r ~= .tryFormat(prop.msgs.warningStepCount, prop.looks.stepMaxCount);
				}
			} catch (ConvException e) {
				// 処理無し
				printStackTrace();
			}
		}
		if (summ && summ.legacy && (c.type is CType.CHANGE_AREA || c.type is CType.START_BATTLE || c.type is CType.END)) { mixin(S_TRACE);
			auto tree = c.tree;
			if (tree && tree.fireRound0) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.warningEndOrChangeAreaInRound0);
			}
		}
		if (cd.use(CArg.START_ACTION) && summ) { mixin(S_TRACE);
			if (summ.legacy && c.startAction !is StartAction.NextRound) { mixin(S_TRACE);
				// クラシックなシナリオではStartAction.NextRoundがデフォルト
				r ~= .tryFormat(prop.msgs.warningStartAction);
			} else if (!summ.legacy && !prop.isTargetVersion(summ, targVer, "2") && c.startAction !is StartAction.Now) { mixin(S_TRACE);
				// Wsn.1以前は戦闘行動開始タイミング指定不可かつStartAction.Nowがデフォルト
				r ~= .tryFormat(prop.msgs.warningStartAction);
			}
		}
		if (cd.use(CArg.REF_ABILITY)) { mixin(S_TRACE);
			if (c.refAbility && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
				// Wsn.1以前は選択者の能力参照は指定不可
				r ~= .tryFormat(prop.msgs.warningRefAbility);
			}
		}
		if (cd.use(CArg.IGNITE)) { mixin(S_TRACE);
			if (c.ignite && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
				// Wsn.1以前はイベントの発火有無は指定不可
				r ~= .tryFormat(prop.msgs.warningIgnite);
			}
		}
		if (cd.use(CArg.KEY_CODES)) { mixin(S_TRACE);
			if (!c.ignite && c.keyCodes.length) { mixin(S_TRACE);
				r ~= prop.msgs.warningIgnoreKeyCode;
			}
			if (c.ignite && prop.sys.isRunaway(c.keyCodes)) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.warningRunawayCard, prop.sys.runaway);
			}
		}
		if (c.type is CType.BRANCH_KEY_CODE && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
			if (summ.legacy
					&& !(c.targetIsSkill && c.targetIsItem && c.targetIsBeast && c.targetIsHand)
					&& !(c.targetIsSkill && !c.targetIsItem && !c.targetIsBeast && !c.targetIsHand)
					&& !(!c.targetIsSkill && c.targetIsItem && !c.targetIsBeast && c.targetIsHand)
					&& !(!c.targetIsSkill && !c.targetIsItem && c.targetIsBeast && !c.targetIsHand)) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.warningBranchKeyCodeAtClassic);
			} else if (!summ.legacy
					&& !(c.targetIsSkill && c.targetIsItem && c.targetIsBeast && !c.targetIsHand)
					&& !(c.targetIsSkill && !c.targetIsItem && !c.targetIsBeast && !c.targetIsHand)
					&& !(!c.targetIsSkill && c.targetIsItem && !c.targetIsBeast && !c.targetIsHand)
					&& !(!c.targetIsSkill && !c.targetIsItem && c.targetIsBeast && !c.targetIsHand)) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.warningBranchKeyCodeAtWsn1);
			}
		}
		if (c.range is Range.COUPON_HOLDER) { mixin(S_TRACE);
			switch (c.type) {
			case CType.EFFECT:
				if (!prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
					r ~= .tryFormat(prop.msgs.warningCouponHolder, prop.msgs.contentName(c.type), "2");
				}
				break;
			case CType.GET_COUPON:
			case CType.LOSE_COUPON:
				if (!prop.isTargetVersion(summ, targVer, "3")) { mixin(S_TRACE);
					r ~= .tryFormat(prop.msgs.warningCouponHolder, prop.msgs.contentName(c.type), "3");
				}
				break;
			default:
				assert (0);
			}
			if (c.holdingCoupon == "") { mixin(S_TRACE);
				r ~= prop.msgs.warningNoHoldingCoupon;
			}
		}
		if (c.range is Range.CARD_TARGET && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
			r ~= prop.msgs.warningCardTarget;
		}
		if (c.boundaryCheck && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
			r ~= prop.msgs.warningBoundaryCheck;
		}
		if (c.centeringX && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
			r ~= prop.msgs.warningCenteringX;
		}
		if (c.centeringY && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
			r ~= prop.msgs.warningCenteringY;
		}
		if ((c.type is CType.BRANCH_KEY_CODE || c.type is CType.BRANCH_SKILL || c.type is CType.BRANCH_ITEM || c.type is CType.BRANCH_BEAST)
				&& c.selectCard && !prop.isTargetVersion(summ, targVer, "3")) { mixin(S_TRACE);
			r ~= prop.msgs.warningSelectCard;
		}
		if (cd.use(CArg.SELECT_TALKER) && c.selectTalker && hasCharacterTalker(c) && !prop.isTargetVersion(summ, targVer, "3")) { mixin(S_TRACE);
			r ~= prop.msgs.warningSelectTalker;
		}
		if (cd.use(CArg.CONSUME_CARD) && !c.consumeCard && !prop.isTargetVersion(summ, targVer, "3")) { mixin(S_TRACE);
			r ~= prop.msgs.warningConsumeCard;
		}
	}
	return r;
}

@property
bool hasCharacterTalker(in Content evt) { mixin(S_TRACE);
	if (evt.type is CType.TALK_MESSAGE) { mixin(S_TRACE);
		foreach (imgPath; evt.cardPaths) { mixin(S_TRACE);
			if (imgPath.type is CardImageType.Talker && imgPath.talker !is Talker.CARD) { mixin(S_TRACE);
				return true;
			}
		}
		return false;
	} else if (evt.type is CType.TALK_DIALOG) { mixin(S_TRACE);
		return true;
	} else assert (0);
}

/// 台詞・メッセージ内で使用されているデータに対する警告のリスト。
struct TextWarnings {
	string[] all; /// 全ての警告。
	string[] noDup; /// 重複する警告を取り除いた配列。
}

/// 台詞・メッセージ内で使用されているデータに対する警告を返す。
/// 警告が行われたデータは引数の連想配列に格納される。
TextWarnings textWarnings(in CProps prop, in Skin skin, in Summary summ, string targVer,
		string text, in string[] flags, in string[] steps, in string[] fonts, in char[] colors,
		ref bool[string] wFlags, ref bool[string] wSteps, ref bool[string] wFonts, ref bool[char] wColors) { mixin(S_TRACE);
	string[] all = [];
	string[] noDup = [];

	auto sPath = summ ? summ.scenarioPath : "";
	auto spChars = skin.spChars;
	auto froot = summ ? summ.flagDirRoot : null;
	auto wsnVer = summ ? summ.dataVersion : LATEST_VERSION;

	auto sw = .sjisWarnings(prop, summ, text, prop.msgs.message);
	all ~= sw;
	noDup ~= sw;

	foreach (font; fonts) { mixin(S_TRACE);
		dchar c = decodeFontPath(font);
		if (c in spChars) continue;
		bool put = false;
		if (summ && summ.legacy && !.isSJIS1ByteChar(c)) { mixin(S_TRACE);
			auto msg = .tryFormat(prop.msgs.searchErrorSPFontIsNotSJIS1ByteChar, .tryFormat("#%s", c));
			all ~= msg;
			if (!wFonts.get(font, false)) { mixin(S_TRACE);
				noDup ~= msg;
				put = true;
			}
		}
		if (!skin.findPath(font, skin.extImage, skin.tableDirs, sPath, wsnVer, skin.wsnTableDirs(wsnVer)).length) { mixin(S_TRACE);
			auto msg = .tryFormat(prop.msgs.searchErrorSPFontNotFound, .tryFormat("#%s", c));
			all ~= msg;
			if (!wFonts.get(font, false)) { mixin(S_TRACE);
				noDup ~= msg;
				put = true;
			}
		}
		if (put) wFonts[font] = true;
	}
	foreach (flag; flags) { mixin(S_TRACE);
		if (!(froot && froot.findFlag(flag))) { mixin(S_TRACE);
			auto msg = .tryFormat(prop.msgs.searchErrorFlagNotFound, flag);
			all ~= msg;
			if (!wFlags.get(flag, false)) { mixin(S_TRACE);
				noDup ~= msg;
				wFlags[flag] = true;
			}
		}
	}
	foreach (step; steps) { mixin(S_TRACE);
		if (!(froot && froot.findStep(step))) { mixin(S_TRACE);
			auto msg = "";
			if (step.startsWith(prop.sys.prefixSystemVarName)) { mixin(S_TRACE);
				if (.icmp(prop.sys.selectedPlayerCardNumber, step) == 0) { mixin(S_TRACE);
					// 選択メンバ番号(Wsn.2)
					if (!prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
						msg ~= prop.msgs.warningSelectedPlayerCardNumber;
					}
				} else { mixin(S_TRACE);
					auto isPC = false;
					foreach (i; 1 .. prop.looks.partyMax + 1) { mixin(S_TRACE);
						if (.icmp(prop.sys.playerCardName(cast(uint)i), step) == 0) { mixin(S_TRACE);
							// プレイヤーキャラクタ名(Wsn.2)
							if (!prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
								msg ~= .tryFormat(prop.msgs.warningPlayerCardName, i);
							}
							isPC = true;
							break;
						}
					}
					if (!isPC) { mixin(S_TRACE);
						msg ~= .tryFormat(prop.msgs.warningUnknownSystemValue, step);
					}
				}
			} else { mixin(S_TRACE);
				msg = .tryFormat(prop.msgs.searchErrorStepNotFound, step);
			}
			if (msg == "") continue;
			all ~= msg;
			if (!wSteps.get(step, false)) { mixin(S_TRACE);
				noDup ~= msg;
				wSteps[step] = true;
			}
		}
	}
	if ((summ && summ.legacy) && !prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
		foreach (color; colors) { mixin(S_TRACE);
			switch (std.ascii.toUpper(color)) {
			case 'O', 'P', 'L', 'D':
				auto w = .tryFormat(prop.msgs.warningTextColor, "&" ~ color, "1.50");
				all ~= w;
				if (!wColors.get(color, false)) { mixin(S_TRACE);
					noDup ~= w;
					wColors[color] = true;
				}
				break;
			default:
				break;
			}
		}
	}
	return typeof(return)(all, noDup);
}

/// システムクーポンに関する警告を返す。
string[] couponWarnings(in CProps prop, in Summary summ, string targVer, string coupon, bool getLose, string itemName) { mixin(S_TRACE);
	string[] r;
	r ~= .sjisWarnings(prop, summ, coupon, itemName);
	if (coupon == prop.sys.userCoupon || coupon == prop.sys.eventTargetCoupon || coupon == prop.sys.effectOutOfTargetCoupon) { mixin(S_TRACE);
		if (!prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningWsnSystemCoupon, coupon, "2");
		}
		if (getLose) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningCanNotGetSetCoupon, coupon);
		}
	} else if (coupon == prop.sys.effectTargetCoupon) { mixin(S_TRACE);
		if (!prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningWsnSystemCoupon, coupon, "2");
		}
	} else if (getLose && coupon.startsWith(prop.sys.couponSystem)) { mixin(S_TRACE);
		r ~= .tryFormat(prop.msgs.warningSystemCoupon, coupon);
	}
	return r;
}

/// cNextTypeに後続コンテントの名称nameが適合しない場合は警告を返す。
/// 適合する場合はnullを返す。
string warningNextCondition(in CProps prop, CNextType cNextType, string name) { mixin(S_TRACE);
	final switch (cNextType) {
	case CNextType.NONE:
		if (name != "") return .tryFormat(prop.msgs.invalidNextName, name);
		return null;
	case CNextType.TEXT:
	case CNextType.COUPON:
		return null;
	case CNextType.BOOL:
		return warningBoolCondition(prop, name);
	case CNextType.STEP:
	case CNextType.ID_AREA:
	case CNextType.ID_BATTLE:
		return warningNumberCondition(prop, name);
	case CNextType.TRIO:
		return warningTrioCondition(prop, name);
	}
}
private string warningBoolCondition(in CProps prop, string text) { mixin(S_TRACE);
	if (text == prop.sys.evtChildTrue || text == prop.sys.evtChildFalse) { mixin(S_TRACE);
		return null;
	} else if (text == "") { mixin(S_TRACE);
		return prop.msgs.unknownBranchConditionNoText;
	} else { mixin(S_TRACE);
		return .tryFormat(prop.msgs.unknownBranchCondition, text);
	}
}
private string warningNumberCondition(in CProps prop, string text) { mixin(S_TRACE);
	if (text == prop.sys.evtChildDefault) { mixin(S_TRACE);
		return null;
	} else if (std.string.isNumeric(text)) { mixin(S_TRACE);
		try {
			auto value = .to!uint(text);
			return null;
		} catch (ConvException e) {
			// 処理無し
			printStackTrace();
		}
	}

	if (text == "") { mixin(S_TRACE);
		return prop.msgs.unknownBranchConditionNoText;
	} else { mixin(S_TRACE);
		return .tryFormat(prop.msgs.unknownBranchCondition, text);
	}
}
private string warningTrioCondition(in CProps prop, string text) { mixin(S_TRACE);
	if (text == prop.sys.evtChildGreater || text == prop.sys.evtChildLesser || text == prop.sys.evtChildEq) { mixin(S_TRACE);
		return null;
	} else if (text == "") { mixin(S_TRACE);
		return prop.msgs.unknownBranchConditionNoText;
	} else { mixin(S_TRACE);
		return .tryFormat(prop.msgs.unknownBranchCondition, text);
	}
}

/// ステータス群が両立しないものを含んでいる場合は警告を返す。
@property
string[] warningInconsistency(in CProps prop, in Status[] statuses) { mixin(S_TRACE);
	auto tbl = new bool[(EnumMembers!Status).length];
	foreach (s; statuses) tbl[cast(size_t)s] = true;
	string[] ws;

	void w(Status s1, Status s2) { mixin(S_TRACE);
		if (s1 < s2) { mixin(S_TRACE);
			ws ~= .tryFormat(prop.msgs.warningInconsistencyStatus, prop.msgs.statusName(s1), prop.msgs.statusName(s2));
		} else { mixin(S_TRACE);
			ws ~= .tryFormat(prop.msgs.warningInconsistencyStatus, prop.msgs.statusName(s2), prop.msgs.statusName(s1));
		}
	}

	with (Status) { mixin(S_TRACE);
		if (tbl[ACTIVE]) { mixin(S_TRACE);
			if (tbl[INACTIVE]) w(ACTIVE, INACTIVE);
			if (tbl[DEAD]) w(ACTIVE, DEAD);
			if (tbl[UNCONSCIOUS]) w(ACTIVE, UNCONSCIOUS);
			if (tbl[SLEEP]) w(ACTIVE, SLEEP);
			if (tbl[BIND]) w(ACTIVE, BIND);
			if (tbl[PARALYZE]) w(ACTIVE, PARALYZE);
		}
		if (tbl[ALIVE]) { mixin(S_TRACE);
			if (tbl[DEAD]) w(ALIVE, DEAD);
			if (tbl[UNCONSCIOUS]) w(ALIVE, UNCONSCIOUS);
			if (tbl[PARALYZE]) w(ALIVE, PARALYZE);
		}
		if (tbl[DEAD]) { mixin(S_TRACE);
			if (tbl[SLEEP]) w(DEAD, SLEEP);
			if (tbl[CONFUSE]) w(DEAD, CONFUSE);
			if (tbl[OVERHEAT]) w(DEAD, OVERHEAT);
			if (tbl[BRAVE]) w(DEAD, BRAVE);
			if (tbl[PANIC]) w(DEAD, PANIC);
		}
		if (tbl[FINE]) { mixin(S_TRACE);
			if (tbl[INJURED]) w(FINE, INJURED);
			if (tbl[HEAVY_INJURED]) w(FINE, HEAVY_INJURED);
			if (tbl[UNCONSCIOUS]) w(FINE, UNCONSCIOUS);
		}
		if (tbl[INJURED]) { mixin(S_TRACE);
			if (tbl[HEAVY_INJURED]) w(INJURED, HEAVY_INJURED);
			if (tbl[UNCONSCIOUS]) w(INJURED, UNCONSCIOUS);
		}
		if (tbl[HEAVY_INJURED]) { mixin(S_TRACE);
			if (tbl[UNCONSCIOUS]) w(HEAVY_INJURED, UNCONSCIOUS);
		}
		if (tbl[UNCONSCIOUS]) { mixin(S_TRACE);
			if (tbl[SLEEP]) w(UNCONSCIOUS, SLEEP);
			if (tbl[BIND]) w(UNCONSCIOUS, BIND);
			if (tbl[CONFUSE]) w(UNCONSCIOUS, CONFUSE);
			if (tbl[OVERHEAT]) w(UNCONSCIOUS, OVERHEAT);
			if (tbl[BRAVE]) w(UNCONSCIOUS, BRAVE);
			if (tbl[PANIC]) w(UNCONSCIOUS, PANIC);
			if (tbl[SILENCE]) w(UNCONSCIOUS, SILENCE);
			if (tbl[FACE_UP]) w(UNCONSCIOUS, FACE_UP);
			if (tbl[ANTI_MAGIC]) w(UNCONSCIOUS, ANTI_MAGIC);
			if (tbl[UP_ACTION]) w(UNCONSCIOUS, UP_ACTION);
			if (tbl[UP_AVOID]) w(UNCONSCIOUS, UP_AVOID);
			if (tbl[UP_RESIST]) w(UNCONSCIOUS, UP_RESIST);
			if (tbl[UP_DEFENSE]) w(UNCONSCIOUS, UP_DEFENSE);
			if (tbl[DOWN_ACTION]) w(UNCONSCIOUS, DOWN_ACTION);
			if (tbl[DOWN_AVOID]) w(UNCONSCIOUS, DOWN_AVOID);
			if (tbl[DOWN_RESIST]) w(UNCONSCIOUS, DOWN_RESIST);
			if (tbl[DOWN_DEFENSE]) w(UNCONSCIOUS, DOWN_DEFENSE);
		}
		if (tbl[SLEEP]) { mixin(S_TRACE);
			if (tbl[PARALYZE]) w(SLEEP, PARALYZE);
			if (tbl[CONFUSE]) w(SLEEP, CONFUSE);
			if (tbl[OVERHEAT]) w(SLEEP, OVERHEAT);
			if (tbl[BRAVE]) w(SLEEP, BRAVE);
			if (tbl[PANIC]) w(SLEEP, PANIC);
		}
		if (tbl[PARALYZE]) { mixin(S_TRACE);
			if (tbl[CONFUSE]) w(PARALYZE, CONFUSE);
			if (tbl[OVERHEAT]) w(PARALYZE, OVERHEAT);
			if (tbl[BRAVE]) w(PARALYZE, BRAVE);
			if (tbl[PANIC]) w(PARALYZE, PANIC);
		}
		if (tbl[CONFUSE]) { mixin(S_TRACE);
			if (tbl[OVERHEAT]) w(CONFUSE, OVERHEAT);
			if (tbl[BRAVE]) w(CONFUSE, BRAVE);
			if (tbl[PANIC]) w(CONFUSE, PANIC);
		}
		if (tbl[OVERHEAT]) { mixin(S_TRACE);
			if (tbl[BRAVE]) w(OVERHEAT, BRAVE);
			if (tbl[PANIC]) w(OVERHEAT, PANIC);
		}
		if (tbl[BRAVE]) { mixin(S_TRACE);
			if (tbl[PANIC]) w(BRAVE, PANIC);
		}
		if (tbl[UP_ACTION]) { mixin(S_TRACE);
			if (tbl[DOWN_ACTION]) w(UP_ACTION, DOWN_ACTION);
		}
		if (tbl[UP_AVOID]) { mixin(S_TRACE);
			if (tbl[DOWN_AVOID]) w(UP_AVOID, DOWN_AVOID);
		}
		if (tbl[UP_RESIST]) { mixin(S_TRACE);
			if (tbl[DOWN_RESIST]) w(UP_RESIST, DOWN_RESIST);
		}
		if (tbl[UP_DEFENSE]) { mixin(S_TRACE);
			if (tbl[DOWN_DEFENSE]) w(UP_DEFENSE, DOWN_DEFENSE);
		}
	}
	std.algorithm.sort(ws);
	std.algorithm.uniq(ws);
	return ws;
}

/// ファイル拡張子不一致エラーがあれば返す。
string[] fileExtensionWarnings(in CProps prop, string path) { mixin(S_TRACE);
	string[] r;
	try {
		auto f = .rawFile(path, "rb");
		scope (exit) f.close();
		auto ext = .getNormalizedImageExt(f);
		if (ext != "" && path.extension().normalizedImageExt != ext) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningFileExtension, ext);
		}
		if (ext == "") { mixin(S_TRACE);
			ext = .getNormalizedSoundExt(f);
			if (ext != "" && path.extension().normalizedSoundExt != ext) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.warningFileExtension, ext);
			}
		}
	} catch (Exception e) {
		printStackTrace();
		debugln(e);
	}
	return r;
}

/// textにクラシックなシナリオでの文字エンコーディングの問題がある場合は警告を返す。
string[] sjisWarnings(in CProps prop, in Summary summ, string text, string name) { mixin(S_TRACE);
	return .sjisWarnings(prop, summ ? summ.legacy : false, text, name);
}
/// ditto
string[] sjisWarnings(in CProps prop, bool legacy, string text, string name) { mixin(S_TRACE);
	if (!legacy) return [];
	foreach (dchar c; text) { mixin(S_TRACE);
		if (!.canConvToSJIS(c)) { mixin(S_TRACE);
			if (name == "") { mixin(S_TRACE);
				return [.tryFormat(prop.msgs.warningInvalidSJISCharacter, c)];
			} else { mixin(S_TRACE);
				return [.tryFormat(prop.msgs.warningInvalidSJISCharacterWithName, name, c)];
			}
		}
	}
	return [];
}
