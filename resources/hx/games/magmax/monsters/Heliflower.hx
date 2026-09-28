package magmax.monsters;

import mt.Timer;
import common_haxe_avm1.display.BBox;

class Heliflower extends Monster {
	public function new(g) {
		mc = cast g.dmanager.empty(1);
		var m = mc.attachMovie("monster2", "monster", 0);
		mc.sub = cast m;
		mc.sub.col = mc.sub.attachBBox(new BBox(KadoKadeoManager.S(-16), KadoKadeoManager.S(-25), KadoKadeoManager.S(25), KadoKadeoManager.S(25)));
		var mHead = mc.attachMovie("monster2Head", "monsterHead", 1);
		var mHat = mc.attachMovie("monster2Hat", "monsterHat", 2);

		mHead.play();
		mHead.loop = true;
		mHat.play();
		mHat.loop = true;

		super(g, 1);

		// Matrices du sprite 154 dans gfx.swf : positions en pixels, échelles en %.
		// SWF : a = scaleX, b = skewX, c = skewY, d = scaleY. Pixi emploie des angles pour skew.x/y.
		// Le contenu du sprite 150 est décalé de 220 twips (11 px) sur X par rapport à son origine SWF.
		// Les PNG étant centrés sur ce contenu, on transforme aussi ce décalage pour placer mHead.
		m.onFrame.set(1, function() {
			mHead._x = KadoKadeoManager.S(-8.2 + 11 * 0.886734009);
			mHead._y = KadoKadeoManager.S(-26.8 + 11 * 0.555435181);
			mHead._xscale = 104.632951;
			mHead._yscale = 63.761519;
			mHead.skew.x = Math.atan2(-0.162841797, 0.616470337);
			mHead.skew.y = Math.atan2(0.555435181, 0.886734009);
			mHat._x = KadoKadeoManager.S(2.05);
			mHat._y = KadoKadeoManager.S(-22.7);
			mHat._xscale = 99.646674;
			mHat._yscale = 99.646674;
			mHat.skew.x = Math.atan2(-0.453811646, 0.887130737);
			mHat.skew.y = Math.atan2(0.453811646, 0.887130737);
		});
		m.onFrame.set(2, function() {
			mHead._x = KadoKadeoManager.S(-8.15 + 11 * 0.887359619);
			mHead._y = KadoKadeoManager.S(-26.8 + 11 * 0.551025391);
			mHead._xscale = 104.452672;
			mHead._yscale = 63.541766;
			mHead.skew.x = Math.atan2(-0.159820557, 0.614990234);
			mHead.skew.y = Math.atan2(0.551025391, 0.887359619);
			mHat._x = KadoKadeoManager.S(1.85);
			mHat._y = KadoKadeoManager.S(-22.7);
			mHat._xscale = 99.533045;
			mHat._yscale = 99.533045;
			mHat.skew.x = Math.atan2(-0.421508789, 0.901672363);
			mHat.skew.y = Math.atan2(0.421508789, 0.901672363);
		});
		m.onFrame.set(3, function() {
			mHead._x = KadoKadeoManager.S(-8.3 + 11 * 0.891540527);
			mHead._y = KadoKadeoManager.S(-26.75 + 11 * 0.542938232);
			mHead._xscale = 104.385173;
			mHead._yscale = 63.037254;
			mHead.skew.x = Math.atan2(-0.155944824, 0.610778809);
			mHead.skew.y = Math.atan2(0.542938232, 0.891540527);
			mHat._x = KadoKadeoManager.S(1.75);
			mHat._y = KadoKadeoManager.S(-22.85);
			mHat._xscale = 99.552883;
			mHat._yscale = 99.552883;
			mHat.skew.x = Math.atan2(-0.389755249, 0.916061401);
			mHat.skew.y = Math.atan2(0.389755249, 0.916061401);
		});
		m.onFrame.set(4, function() {
			mHead._x = KadoKadeoManager.S(-8.25 + 11 * 0.897735596);
			mHead._y = KadoKadeoManager.S(-26.55 + 11 * 0.530303955);
			mHead._xscale = 104.266557;
			mHead._yscale = 62.192683;
			mHead.skew.x = Math.atan2(-0.150878906, 0.603347778);
			mHead.skew.y = Math.atan2(0.530303955, 0.897735596);
			mHat._x = KadoKadeoManager.S(1.6);
			mHat._y = KadoKadeoManager.S(-22.95);
			mHat._xscale = 99.571231;
			mHat._yscale = 99.571231;
			mHat.skew.x = Math.atan2(-0.357498169, 0.929321289);
			mHat.skew.y = Math.atan2(0.357498169, 0.929321289);
		});
		m.onFrame.set(5, function() {
			mHead._x = KadoKadeoManager.S(-8.35 + 11 * 0.907485962);
			mHead._y = KadoKadeoManager.S(-26.25 + 11 * 0.510162354);
			mHead._xscale = 104.105543;
			mHead._yscale = 61.012628;
			mHead.skew.x = Math.atan2(-0.142776489, 0.593185425);
			mHead.skew.y = Math.atan2(0.510162354, 0.907485962);
			mHat._x = KadoKadeoManager.S(1.5);
			mHat._y = KadoKadeoManager.S(-23.05);
			mHat._xscale = 99.592403;
			mHat._yscale = 99.592403;
			mHat.skew.x = Math.atan2(-0.324813843, 0.941467285);
			mHat.skew.y = Math.atan2(0.324813843, 0.941467285);
		});
		m.onFrame.set(6, function() {
			mHead._x = KadoKadeoManager.S(-8.55 + 11 * 0.918670654);
			mHead._y = KadoKadeoManager.S(-26.05 + 11 * 0.485321045);
			mHead._xscale = 103.898618;
			mHead._yscale = 59.496826;
			mHead.skew.x = Math.atan2(-0.13180542, 0.580184937);
			mHead.skew.y = Math.atan2(0.485321045, 0.918670654);
			mHat._x = KadoKadeoManager.S(1.3);
			mHat._y = KadoKadeoManager.S(-23.1);
			mHat._xscale = 99.609682;
			mHat._yscale = 99.609682;
			mHat.skew.x = Math.atan2(-0.291717529, 0.952423096);
			mHat.skew.y = Math.atan2(0.291717529, 0.952423096);
		});
		m.onFrame.set(7, function() {
			mHead._x = KadoKadeoManager.S(-8.7 + 11 * 0.930938721);
			mHead._y = KadoKadeoManager.S(-25.75 + 11 * 0.4556427);
			mHead._xscale = 103.646378;
			mHead._yscale = 57.642066;
			mHead.skew.x = Math.atan2(-0.120117188, 0.563766479);
			mHead.skew.y = Math.atan2(0.4556427, 0.930938721);
			mHat._x = KadoKadeoManager.S(1.25);
			mHat._y = KadoKadeoManager.S(-23.25);
			mHat._xscale = 99.632881;
			mHat._yscale = 99.632881;
			mHat.skew.x = Math.atan2(-0.258239746, 0.962280273);
			mHat.skew.y = Math.atan2(0.258239746, 0.962280273);
		});
		m.onFrame.set(8, function() {
			mHead._x = KadoKadeoManager.S(-8.85 + 11 * 0.94380188);
			mHead._y = KadoKadeoManager.S(-25.3 + 11 * 0.421051025);
			mHead._xscale = 103.346309;
			mHead._yscale = 55.450989;
			mHead.skew.x = Math.atan2(-0.10609436, 0.544265747);
			mHead.skew.y = Math.atan2(0.421051025, 0.94380188);
			mHat._x = KadoKadeoManager.S(1.1);
			mHat._y = KadoKadeoManager.S(-23.3);
			mHat._xscale = 99.653892;
			mHat._yscale = 99.653892;
			mHat.skew.x = Math.atan2(-0.224456787, 0.970932007);
			mHat.skew.y = Math.atan2(0.224456787, 0.970932007);
		});
		m.onFrame.set(9, function() {
			mHead._x = KadoKadeoManager.S(-9.05 + 11 * 0.958053589);
			mHead._y = KadoKadeoManager.S(-24.9 + 11 * 0.378326416);
			mHead._xscale = 103.004736;
			mHead._yscale = 52.921903;
			mHead.skew.x = Math.atan2(-0.090148926, 0.521484375);
			mHead.skew.y = Math.atan2(0.378326416, 0.958053589);
			mHat._x = KadoKadeoManager.S(0.95);
			mHat._y = KadoKadeoManager.S(-23.35);
			mHat._xscale = 99.671765;
			mHat._yscale = 99.671765;
			mHat.skew.x = Math.atan2(-0.19039917, 0.978363037);
			mHat.skew.y = Math.atan2(0.19039917, 0.978363037);
		});
		m.onFrame.set(10, function() {
			mHead._x = KadoKadeoManager.S(-9.35 + 11 * 0.971481323);
			mHead._y = KadoKadeoManager.S(-24.4 + 11 * 0.330444336);
			mHead._xscale = 102.614298;
			mHead._yscale = 50.054267;
			mHead.skew.x = Math.atan2(-0.074417114, 0.494979858);
			mHead.skew.y = Math.atan2(0.330444336, 0.971481323);
			mHat._x = KadoKadeoManager.S(0.85);
			mHat._y = KadoKadeoManager.S(-23.5);
			mHat._xscale = 99.697854;
			mHat._yscale = 99.697854;
			mHat.skew.x = Math.atan2(-0.156112671, 0.984680176);
			mHat.skew.y = Math.atan2(0.156112671, 0.984680176);
		});
		m.onFrame.set(11, function() {
			mHead._x = KadoKadeoManager.S(-9.5 + 11 * 0.984344482);
			mHead._y = KadoKadeoManager.S(-23.7 + 11 * 0.274169922);
			mHead._xscale = 102.181368;
			mHead._yscale = 46.85221;
			mHead.skew.x = Math.atan2(-0.057617188, 0.46496582);
			mHead.skew.y = Math.atan2(0.274169922, 0.984344482);
			mHat._x = KadoKadeoManager.S(0.75);
			mHat._y = KadoKadeoManager.S(-23.6);
			mHat._xscale = 99.718766;
			mHat._yscale = 99.718766;
			mHat.skew.x = Math.atan2(-0.12159729, 0.989746094);
			mHat.skew.y = Math.atan2(0.12159729, 0.989746094);
		});
		m.onFrame.set(12, function() {
			mHead._x = KadoKadeoManager.S(-9.85 + 11 * 0.99382019);
			mHead._y = KadoKadeoManager.S(-23.15 + 11 * 0.216003418);
			mHead._xscale = 101.702313;
			mHead._yscale = 43.310026;
			mHead.skew.x = Math.atan2(-0.041824341, 0.43107605);
			mHead.skew.y = Math.atan2(0.216003418, 0.99382019);
			mHat._x = KadoKadeoManager.S(0.55);
			mHat._y = KadoKadeoManager.S(-23.75);
			mHat._xscale = 99.741543;
			mHat._yscale = 99.741543;
			mHat.skew.x = Math.atan2(-0.083709717, 0.993896484);
			mHat.skew.y = Math.atan2(0.083709717, 0.993896484);
		});
		m.onFrame.set(13, function() {
			mHead._x = KadoKadeoManager.S(-10.15 + 11 * 1.000656128);
			mHead._y = KadoKadeoManager.S(-22.4 + 11 * 0.149627686);
			mHead._xscale = 101.178117;
			mHead._yscale = 39.431212;
			mHead.skew.x = Math.atan2(-0.026092529, 0.393447876);
			mHead.skew.y = Math.atan2(0.149627686, 1.000656128);
			mHat._x = KadoKadeoManager.S(0.4);
			mHat._y = KadoKadeoManager.S(-23.8);
			mHat._xscale = 99.762958;
			mHat._yscale = 99.762958;
			mHat.skew.x = Math.atan2(-0.048919678, 0.996429443);
			mHat.skew.y = Math.atan2(0.048919678, 0.996429443);
		});
		m.onFrame.set(14, function() {
			mHead._x = KadoKadeoManager.S(-10.45 + 11 * 1.003311157);
			mHead._y = KadoKadeoManager.S(-21.75 + 11 * 0.075286865);
			mHead._xscale = 100.61319;
			mHead._yscale = 35.214461;
			mHead.skew.x = Math.atan2(-0.012329102, 0.351928711);
			mHead.skew.y = Math.atan2(0.075286865, 1.003311157);
			mHat._x = KadoKadeoManager.S(0.35);
			mHat._y = KadoKadeoManager.S(-23.9);
			mHat._xscale = 99.785614;
			mHat._yscale = 99.785614;
			mHat.skew.x = Math.atan2(-0.014068604, 0.997756958);
			mHat.skew.y = Math.atan2(0.014068604, 0.997756958);
		});
		m.onFrame.set(15, function() {
			mHead._x = KadoKadeoManager.S(-10.85 + 11 * 1);
			mHead._y = KadoKadeoManager.S(-20.85 + 11 * 0);
			mHead._xscale = 100;
			mHead._yscale = 30.657959;
			mHead.skew.x = Math.atan2(0, 0.30657959);
			mHead.skew.y = Math.atan2(0, 1);
			mHat._x = KadoKadeoManager.S(0.2);
			mHat._y = KadoKadeoManager.I(-24);
			mHat._xscale = 99.802401;
			mHat._yscale = 99.802401;
			mHat.skew.x = Math.atan2(0.017883301, 0.99786377);
			mHat.skew.y = Math.atan2(-0.017883301, 0.99786377);
		});
		m.onFrame.set(16, function() {
			mHead._x = KadoKadeoManager.S(-11.05 + 11 * 0.996994019);
			mHead._y = KadoKadeoManager.S(-20.65 - 11 * 0.022598267);
			mHead._xscale = 99.72501;
			mHead._yscale = 32.53526;
			mHead.skew.x = Math.atan2(0.014541626, 0.325027466);
			mHead.skew.y = Math.atan2(-0.022598267, 0.996994019);
			mHat._x = KadoKadeoManager.S(-0.15);
			mHat._y = KadoKadeoManager.S(-23.85);
			mHat._xscale = 99.772019;
			mHat._yscale = 99.772019;
			mHat.skew.x = Math.atan2(0.056945801, 0.99609375);
			mHat.skew.y = Math.atan2(-0.056945801, 0.99609375);
		});
		m.onFrame.set(17, function() {
			mHead._x = KadoKadeoManager.S(-11.25 + 11 * 0.993301392);
			mHead._y = KadoKadeoManager.S(-20.45 - 11 * 0.048309326);
			mHead._xscale = 99.447546;
			mHead._yscale = 34.408382;
			mHead.skew.x = Math.atan2(0.031860352, 0.342605591);
			mHead.skew.y = Math.atan2(-0.048309326, 0.993301392);
			mHat._x = KadoKadeoManager.S(-0.5);
			mHat._y = KadoKadeoManager.S(-23.7);
			mHat._xscale = 99.7468;
			mHat._yscale = 99.7468;
			mHat.skew.x = Math.atan2(0.096252441, 0.99281311);
			mHat.skew.y = Math.atan2(-0.096252441, 0.99281311);
		});
		m.onFrame.set(18, function() {
			mHead._x = KadoKadeoManager.S(-11.5 + 11 * 0.988983154);
			mHead._y = KadoKadeoManager.S(-20.2 - 11 * 0.073852539);
			mHead._xscale = 99.17368;
			mHead._yscale = 36.284345;
			mHead.skew.x = Math.atan2(0.050918579, 0.35925293);
			mHead.skew.y = Math.atan2(-0.073852539, 0.988983154);
			mHat._x = KadoKadeoManager.S(-0.8);
			mHat._y = KadoKadeoManager.S(-23.6);
			mHat._xscale = 99.719267;
			mHat._yscale = 99.719267;
			mHat.skew.x = Math.atan2(0.135375977, 0.987960815);
			mHat.skew.y = Math.atan2(-0.135375977, 0.987960815);
		});
		m.onFrame.set(19, function() {
			mHead._x = KadoKadeoManager.S(-11.6 + 11 * 0.983978271);
			mHead._y = KadoKadeoManager.S(-20 - 11 * 0.099212646);
			mHead._xscale = 98.896733;
			mHead._yscale = 38.158403;
			mHead.skew.x = Math.atan2(0.071624756, 0.374801636);
			mHead.skew.y = Math.atan2(-0.099212646, 0.983978271);
			mHat._x = KadoKadeoManager.S(-1.1);
			mHat._y = KadoKadeoManager.S(-23.55);
			mHat._xscale = 99.69531;
			mHat._yscale = 99.69531;
			mHat.skew.x = Math.atan2(0.177536011, 0.981018066);
			mHat.skew.y = Math.atan2(-0.177536011, 0.981018066);
		});
		m.onFrame.set(20, function() {
			mHead._x = KadoKadeoManager.S(-11.8 + 11 * 0.978744507);
			mHead._y = KadoKadeoManager.S(-19.75 - 11 * 0.121154785);
			mHead._xscale = 98.621463;
			mHead._yscale = 40.033976;
			mHead.skew.x = Math.atan2(0.093948364, 0.389160156);
			mHead.skew.y = Math.atan2(-0.121154785, 0.978744507);
			mHat._x = KadoKadeoManager.S(-1.45);
			mHat._y = KadoKadeoManager.S(-23.4);
			mHat._xscale = 99.670966;
			mHat._yscale = 99.670966;
			mHat.skew.x = Math.atan2(0.216140747, 0.972991943);
			mHat.skew.y = Math.atan2(-0.216140747, 0.972991943);
		});
		m.onFrame.set(21, function() {
			mHead._x = KadoKadeoManager.S(-12 + 11 * 0.97253418);
			mHead._y = KadoKadeoManager.S(-19.5 - 11 * 0.146118164);
			mHead._xscale = 98.344967;
			mHead._yscale = 41.906218;
			mHead.skew.x = Math.atan2(0.11781311, 0.402160645);
			mHead.skew.y = Math.atan2(-0.146118164, 0.97253418);
			mHat._x = KadoKadeoManager.S(-1.75);
			mHat._y = KadoKadeoManager.S(-23.25);
			mHat._xscale = 99.648283;
			mHat._yscale = 99.648283;
			mHat.skew.x = Math.atan2(0.254425049, 0.9634552);
			mHat.skew.y = Math.atan2(-0.254425049, 0.9634552);
		});
		m.onFrame.set(22, function() {
			mHead._x = KadoKadeoManager.S(-12.2 + 11 * 0.965713501);
			mHead._y = KadoKadeoManager.S(-19.3 - 11 * 0.170822144);
			mHead._xscale = 98.070524;
			mHead._yscale = 43.7799;
			mHead.skew.x = Math.atan2(0.143127441, 0.413742065);
			mHead.skew.y = Math.atan2(-0.170822144, 0.965713501);
			mHat._x = KadoKadeoManager.I(-2);
			mHat._y = KadoKadeoManager.S(-23.2);
			mHat._xscale = 99.625335;
			mHat._yscale = 99.625335;
			mHat.skew.x = Math.atan2(0.292251587, 0.952423096);
			mHat.skew.y = Math.atan2(-0.292251587, 0.952423096);
		});
		m.onFrame.set(23, function() {
			mHead._x = KadoKadeoManager.S(-12.4 + 11 * 0.958236694);
			mHead._y = KadoKadeoManager.S(-19.05 - 11 * 0.195297241);
			mHead._xscale = 97.793587;
			mHead._yscale = 45.654553;
			mHead.skew.x = Math.atan2(0.169830322, 0.423782349);
			mHead.skew.y = Math.atan2(-0.195297241, 0.958236694);
			mHat._x = KadoKadeoManager.S(-2.35);
			mHat._y = KadoKadeoManager.S(-23.05);
			mHat._xscale = 99.600007;
			mHat._yscale = 99.600007;
			mHat.skew.x = Math.atan2(0.329650879, 0.939865112);
			mHat.skew.y = Math.atan2(-0.329650879, 0.939865112);
		});
		m.onFrame.set(24, function() {
			mHead._x = KadoKadeoManager.S(-12.55 + 11 * 0.950897217);
			mHead._y = KadoKadeoManager.S(-18.85 - 11 * 0.216369629);
			mHead._xscale = 97.520323;
			mHead._yscale = 47.528152;
			mHead.skew.x = Math.atan2(0.197814941, 0.432159424);
			mHead.skew.y = Math.atan2(-0.216369629, 0.950897217);
			mHat._x = KadoKadeoManager.S(-2.7);
			mHat._y = KadoKadeoManager.S(-22.95);
			mHat._xscale = 99.577202;
			mHat._yscale = 99.577202;
			mHat.skew.x = Math.atan2(0.369567871, 0.9246521);
			mHat.skew.y = Math.atan2(-0.369567871, 0.9246521);
		});
		m.onFrame.set(25, function() {
			mHead._x = KadoKadeoManager.S(-12.8 + 11 * 0.94229126);
			mHead._y = KadoKadeoManager.S(-18.6 - 11 * 0.240310669);
			mHead._xscale = 97.245156;
			mHead._yscale = 49.401096;
			mHead.skew.x = Math.atan2(0.226974487, 0.438781738);
			mHead.skew.y = Math.atan2(-0.240310669, 0.94229126);
			mHat._x = KadoKadeoManager.S(-3.05);
			mHat._y = KadoKadeoManager.S(-22.9);
			mHat._xscale = 99.555058;
			mHat._yscale = 99.555058;
			mHat.skew.x = Math.atan2(0.405807495, 0.909088135);
			mHat.skew.y = Math.atan2(-0.405807495, 0.909088135);
		});
		m.onFrame.set(26, function() {
			mHead._x = KadoKadeoManager.S(-12.95 + 11 * 0.93309021);
			mHead._y = KadoKadeoManager.S(-18.45 - 11 * 0.263961792);
			mHead._xscale = 96.970777;
			mHead._yscale = 51.275511;
			mHead.skew.x = Math.atan2(0.257217407, 0.443572998);
			mHead.skew.y = Math.atan2(-0.263961792, 0.93309021);
			mHat._x = KadoKadeoManager.S(-3.35);
			mHat._y = KadoKadeoManager.S(-22.75);
			mHat._xscale = 99.536197;
			mHat._yscale = 99.536197;
			mHat.skew.x = Math.atan2(0.44140625, 0.89213562);
			mHat.skew.y = Math.atan2(-0.44140625, 0.89213562);
		});
		m.onFrame.set(27, function() {
			mHead._x = KadoKadeoManager.S(-13.15 + 11 * 0.923294067);
			mHead._y = KadoKadeoManager.S(-18.2 - 11 * 0.28729248);
			mHead._xscale = 96.695858;
			mHead._yscale = 53.15212;
			mHead.skew.x = Math.atan2(0.288452148, 0.44644165);
			mHead.skew.y = Math.atan2(-0.28729248, 0.923294067);
			mHat._x = KadoKadeoManager.S(-3.75);
			mHat._y = KadoKadeoManager.S(-22.6);
			mHat._xscale = 99.514507;
			mHat._yscale = 99.514507;
			mHat.skew.x = Math.atan2(0.476287842, 0.873764038);
			mHat.skew.y = Math.atan2(-0.476287842, 0.873764038);
		});
		m.onFrame.set(28, function() {
			mHead._x = KadoKadeoManager.S(-13.35 + 11 * 0.91293335);
			mHead._y = KadoKadeoManager.S(-17.95 - 11 * 0.310302734);
			mHead._xscale = 96.422772;
			mHead._yscale = 55.026121;
			mHead.skew.x = Math.atan2(0.320510864, 0.447280884);
			mHead.skew.y = Math.atan2(-0.310302734, 0.91293335);
			mHat._x = KadoKadeoManager.I(-4);
			mHat._y = KadoKadeoManager.S(-22.5);
			mHat._xscale = 99.495263;
			mHat._yscale = 99.495263;
			mHat.skew.x = Math.atan2(0.513244629, 0.852355957);
			mHat.skew.y = Math.atan2(-0.513244629, 0.852355957);
		});
		m.onFrame.set(29, function() {
			mHead._x = KadoKadeoManager.S(-13.6 + 11 * 0.903091431);
			mHead._y = KadoKadeoManager.S(-17.7 - 11 * 0.33001709);
			mHead._xscale = 96.150164;
			mHead._yscale = 56.900331;
			mHead.skew.x = Math.atan2(0.353302002, 0.446029663);
			mHead.skew.y = Math.atan2(-0.33001709, 0.903091431);
			mHat._x = KadoKadeoManager.S(-4.4);
			mHat._y = KadoKadeoManager.S(-22.35);
			mHat._xscale = 99.477941;
			mHat._yscale = 99.477941;
			mHat.skew.x = Math.atan2(0.54649353, 0.831222534);
			mHat.skew.y = Math.atan2(-0.54649353, 0.831222534);
		});
		m.onFrame.set(30, function() {
			mHead._x = KadoKadeoManager.S(-13.75 + 11 * 0.89213562);
			mHead._y = KadoKadeoManager.S(-17.5 - 11 * 0.3540802);
			mHead._xscale = 95.983267;
			mHead._yscale = 58.873462;
			mHead.skew.x = Math.atan2(0.388153076, 0.442657471);
			mHead.skew.y = Math.atan2(-0.3540802, 0.89213562);
			mHat._x = KadoKadeoManager.S(-4.6);
			mHat._y = KadoKadeoManager.S(-22.25);
			mHat._xscale = 99.616629;
			mHat._yscale = 99.616629;
			mHat.skew.x = Math.atan2(0.580276489, 0.809707642);
			mHat.skew.y = Math.atan2(-0.580276489, 0.809707642);
		});
		m.onFrame.set(31, function() {
			mHead._x = KadoKadeoManager.S(-13.5 + 11 * 0.903076172);
			mHead._y = KadoKadeoManager.S(-17.55 - 11 * 0.33001709);
			mHead._xscale = 96.148731;
			mHead._yscale = 60.593342;
			mHead.skew.x = Math.atan2(0.376235962, 0.474975586);
			mHead.skew.y = Math.atan2(-0.33001709, 0.903076172);
			mHat._x = KadoKadeoManager.S(-4.3);
			mHat._y = KadoKadeoManager.S(-22.2);
			mHat._xscale = 99.477505;
			mHat._yscale = 100.188074;
			mHat.skew.x = Math.atan2(0.550415039, 0.837142944);
			mHat.skew.y = Math.atan2(-0.546508789, 0.831207275);
		});
		m.onFrame.set(32, function() {
			mHead._x = KadoKadeoManager.S(-13.3 + 11 * 0.912918091);
			mHead._y = KadoKadeoManager.S(-17.75 - 11 * 0.310302734);
			mHead._xscale = 96.421327;
			mHead._yscale = 62.410984;
			mHead.skew.x = Math.atan2(0.363525391, 0.50730896);
			mHead.skew.y = Math.atan2(-0.310302734, 0.912918091);
			mHat._x = KadoKadeoManager.S(-3.9);
			mHat._y = KadoKadeoManager.S(-22.05);
			mHat._xscale = 99.493168;
			mHat._yscale = 100.918313;
			mHat.skew.x = Math.atan2(0.520584106, 0.864547729);
			mHat.skew.y = Math.atan2(-0.51322937, 0.852340698);
		});
		m.onFrame.set(33, function() {
			mHead._x = KadoKadeoManager.S(-13.1 + 11 * 0.923278809);
			mHead._y = KadoKadeoManager.S(-17.85 - 11 * 0.28729248);
			mHead._xscale = 96.694401;
			mHead._yscale = 64.232279;
			mHead.skew.x = Math.atan2(0.348587036, 0.539505005);
			mHead.skew.y = Math.atan2(-0.28729248, 0.923278809);
			mHat._x = KadoKadeoManager.S(-3.5);
			mHat._y = KadoKadeoManager.S(-21.95);
			mHat._xscale = 99.516577;
			mHat._yscale = 101.650378;
			mHat.skew.x = Math.atan2(0.48651123, 0.89251709);
			mHat.skew.y = Math.atan2(-0.476303101, 0.873779297);
		});
		m.onFrame.set(34, function() {
			mHead._x = KadoKadeoManager.S(-12.9 + 11 * 0.933074951);
			mHead._y = KadoKadeoManager.S(-17.9 - 11 * 0.263961792);
			mHead._xscale = 96.969309;
			mHead._yscale = 66.050364;
			mHead.skew.x = Math.atan2(0.331344604, 0.571380615);
			mHead.skew.y = Math.atan2(-0.263961792, 0.933074951);
			mHat._x = KadoKadeoManager.S(-3.2);
			mHat._y = KadoKadeoManager.S(-21.75);
			mHat._xscale = 99.53552;
			mHat._yscale = 102.382488;
			mHat.skew.x = Math.atan2(0.454025269, 0.917648315);
			mHat.skew.y = Math.atan2(-0.441390991, 0.89213562);
		});
		m.onFrame.set(35, function() {
			mHead._x = KadoKadeoManager.S(-12.7 + 11 * 0.942276001);
			mHead._y = KadoKadeoManager.S(-18 - 11 * 0.240310669);
			mHead._xscale = 97.243677;
			mHead._yscale = 67.87181;
			mHead.skew.x = Math.atan2(0.311828613, 0.602844238);
			mHead.skew.y = Math.atan2(-0.240310669, 0.942276001);
			mHat._x = KadoKadeoManager.S(-2.85);
			mHat._y = KadoKadeoManager.S(-21.6);
			mHat._xscale = 99.55583;
			mHat._yscale = 103.115957;
			mHat.skew.x = Math.atan2(0.420288086, 0.941619873);
			mHat.skew.y = Math.atan2(-0.405792236, 0.909103394);
		});
		m.onFrame.set(36, function() {
			mHead._x = KadoKadeoManager.S(-12.35 + 11 * 0.950897217);
			mHead._y = KadoKadeoManager.S(-18.1 - 11 * 0.216384888);
			mHead._xscale = 97.520661;
			mHead._yscale = 69.695128;
			mHead.skew.x = Math.atan2(0.290084839, 0.633712769);
			mHead.skew.y = Math.atan2(-0.216384888, 0.950897217);
			mHat._x = KadoKadeoManager.S(-2.45);
			mHat._y = KadoKadeoManager.S(-21.55);
			mHat._xscale = 99.576636;
			mHat._yscale = 103.847549;
			mHat.skew.x = Math.atan2(0.385406494, 0.964309692);
			mHat.skew.y = Math.atan2(-0.369552612, 0.9246521);
		});
		m.onFrame.set(37, function() {
			mHead._x = KadoKadeoManager.S(-12.25 + 11 * 0.958251953);
			mHead._y = KadoKadeoManager.S(-18.25 - 11 * 0.195297241);
			mHead._xscale = 97.795083;
			mHead._yscale = 71.517769;
			mHead.skew.x = Math.atan2(0.266052246, 0.663848877);
			mHead.skew.y = Math.atan2(-0.195297241, 0.958251953);
			mHat._x = KadoKadeoManager.S(-2.15);
			mHat._y = KadoKadeoManager.S(-21.4);
			mHat._xscale = 99.601952;
			mHat._yscale = 104.587035;
			mHat.skew.x = Math.atan2(0.346160889, 0.986923218);
			mHat.skew.y = Math.atan2(-0.329666138, 0.939880371);
		});
		m.onFrame.set(38, function() {
			mHead._x = KadoKadeoManager.S(-12.1 + 11 * 0.965713501);
			mHead._y = KadoKadeoManager.S(-18.35 - 11 * 0.170822144);
			mHead._xscale = 98.070524;
			mHead._yscale = 73.344656;
			mHead.skew.x = Math.atan2(0.239776611, 0.693145752);
			mHead.skew.y = Math.atan2(-0.170822144, 0.965713501);
			mHat._x = KadoKadeoManager.S(-1.8);
			mHat._y = KadoKadeoManager.S(-21.35);
			mHat._xscale = 99.624324;
			mHat._yscale = 105.31883;
			mHat.skew.x = Math.atan2(0.308959961, 1.006851196);
			mHat.skew.y = Math.atan2(-0.292266846, 0.952407837);
		});
		m.onFrame.set(39, function() {
			mHead._x = KadoKadeoManager.S(-11.9 + 11 * 0.972518921);
			mHead._y = KadoKadeoManager.S(-18.45 - 11 * 0.146118164);
			mHead._xscale = 98.343458;
			mHead._yscale = 75.1704;
			mHead.skew.x = Math.atan2(0.21131897, 0.721389771);
			mHead.skew.y = Math.atan2(-0.146118164, 0.972518921);
			mHat._x = KadoKadeoManager.S(-1.55);
			mHat._y = KadoKadeoManager.S(-21.25);
			mHat._xscale = 99.647893;
			mHat._yscale = 106.058224;
			mHat.skew.x = Math.atan2(0.270767212, 1.025436401);
			mHat.skew.y = Math.atan2(-0.25440979, 0.9634552);
		});
		m.onFrame.set(40, function() {
			mHead._x = KadoKadeoManager.S(-11.65 + 11 * 0.978729248);
			mHead._y = KadoKadeoManager.S(-18.6 - 11 * 0.121154785);
			mHead._xscale = 98.619948;
			mHead._yscale = 76.997665;
			mHead.skew.x = Math.atan2(0.18069458, 0.748474121);
			mHead.skew.y = Math.atan2(-0.121154785, 0.978729248);
			mHat._x = KadoKadeoManager.S(-1.15);
			mHat._y = KadoKadeoManager.S(-21.15);
			mHat._xscale = 99.670635;
			mHat._yscale = 106.795286;
			mHat.skew.x = Math.atan2(0.231582642, 1.042541504);
			mHat.skew.y = Math.atan2(-0.216125488, 0.972991943);
		});
		m.onFrame.set(41, function() {
			mHead._x = KadoKadeoManager.S(-11.45 + 11 * 0.983947754);
			mHead._y = KadoKadeoManager.S(-18.65 - 11 * 0.099227905);
			mHead._xscale = 98.89385;
			mHead._yscale = 78.825515;
			mHead.skew.x = Math.atan2(0.147949219, 0.774246216);
			mHead.skew.y = Math.atan2(-0.099227905, 0.983947754);
			mHat._x = KadoKadeoManager.S(-0.85);
			mHat._y = KadoKadeoManager.I(-21);
			mHat._xscale = 99.693808;
			mHat._yscale = 107.529194;
			mHat.skew.x = Math.atan2(0.191482544, 1.058105469);
			mHat.skew.y = Math.atan2(-0.177536011, 0.981002808);
		});
		m.onFrame.set(42, function() {
			mHead._x = KadoKadeoManager.S(-11.25 + 11 * 0.988983154);
			mHead._y = KadoKadeoManager.S(-18.75 - 11 * 0.073852539);
			mHead._xscale = 99.17368;
			mHead._yscale = 80.653338;
			mHead.skew.x = Math.atan2(0.113174438, 0.798553467);
			mHead.skew.y = Math.atan2(-0.073852539, 0.988983154);
			mHat._x = KadoKadeoManager.S(-0.45);
			mHat._y = KadoKadeoManager.S(-20.9);
			mHat._xscale = 99.719267;
			mHat._yscale = 108.270158;
			mHat.skew.x = Math.atan2(0.146987915, 1.072677612);
			mHat.skew.y = Math.atan2(-0.135375977, 0.987960815);
		});
		m.onFrame.set(43, function() {
			mHead._x = KadoKadeoManager.S(-11 + 11 * 0.993286133);
			mHead._y = KadoKadeoManager.S(-18.9 - 11 * 0.048324585);
			mHead._xscale = 99.446096;
			mHead._yscale = 82.481982;
			mHead.skew.x = Math.atan2(0.076400757, 0.821273804);
			mHead.skew.y = Math.atan2(-0.048324585, 0.993286133);
			mHat._x = KadoKadeoManager.S(-0.15);
			mHat._y = KadoKadeoManager.S(-20.75);
			mHat._xscale = 99.7468;
			mHat._yscale = 109.007754;
			mHat.skew.x = Math.atan2(0.105178833, 1.084991455);
			mHat.skew.y = Math.atan2(-0.096252441, 0.99281311);
		});
		m.onFrame.set(44, function() {
			mHead._x = KadoKadeoManager.S(-10.8 + 11 * 0.99697876);
			mHead._y = KadoKadeoManager.S(-19.05 - 11 * 0.022598267);
			mHead._xscale = 99.723484;
			mHead._yscale = 84.315913;
			mHead.skew.x = Math.atan2(0.037704468, 0.842315674);
			mHead.skew.y = Math.atan2(-0.022598267, 0.99697876);
			mHat._x = KadoKadeoManager.S(0.15);
			mHat._y = KadoKadeoManager.S(-20.75);
			mHat._xscale = 99.771845;
			mHat._yscale = 109.75064;
			mHat.skew.x = Math.atan2(0.06262207, 1.095718384);
			mHat.skew.y = Math.atan2(-0.056915283, 0.99609375);
		});
		m.onFrame.set(45, function() {
			mHead._x = KadoKadeoManager.S(-10.55 + 11 * 1);
			mHead._y = KadoKadeoManager.S(-19.2 + 11 * 0);
			mHead._xscale = 100;
			mHead._yscale = 86.146545;
			mHead.skew.x = Math.atan2(0, 0.861465454);
			mHead.skew.y = Math.atan2(0, 1);
			mHat._x = KadoKadeoManager.S(0.55);
			mHat._y = KadoKadeoManager.S(-20.65);
			mHat._xscale = 99.802401;
			mHat._yscale = 110.495962;
			mHat.skew.x = Math.atan2(0.019805908, 1.104782104);
			mHat.skew.y = Math.atan2(-0.017883301, 0.99786377);
		});
		m.onFrame.set(46, function() {
			mHead._x = KadoKadeoManager.S(-10.35 + 11 * 1.002334595);
			mHead._y = KadoKadeoManager.S(-19.65 + 11 * 0.035598755);
			mHead._xscale = 100.296656;
			mHead._yscale = 84.650461;
			mHead.skew.x = Math.atan2(-0.011947632, 0.846420288);
			mHead.skew.y = Math.atan2(0.035598755, 1.002334595);
			mHat._x = KadoKadeoManager.S(0.65);
			mHat._y = KadoKadeoManager.S(-20.75);
			mHat._xscale = 99.787865;
			mHat._yscale = 109.768037;
			mHat.skew.x = Math.atan2(-0.014846802, 1.097579956);
			mHat.skew.y = Math.atan2(0.01348877, 0.997787476);
		});
		m.onFrame.set(47, function() {
			mHead._x = KadoKadeoManager.S(-10.3 + 11 * 1.003158569);
			mHead._y = KadoKadeoManager.S(-20.15 + 11 * 0.074676514);
			mHead._xscale = 100.593424;
			mHead._yscale = 83.151331;
			mHead.skew.x = Math.atan2(-0.026199341, 0.831100464);
			mHead.skew.y = Math.atan2(0.074676514, 1.003158569);
			mHat._x = KadoKadeoManager.S(0.8);
			mHat._y = KadoKadeoManager.S(-20.85);
			mHat._xscale = 99.76656;
			mHat._yscale = 109.034822;
			mHat.skew.x = Math.atan2(-0.048614502, 1.089263916);
			mHat.skew.y = Math.atan2(0.04447937, 0.996673584);
		});
		m.onFrame.set(48, function() {
			mHead._x = KadoKadeoManager.S(-10.1 + 11 * 1.002822876);
			mHead._y = KadoKadeoManager.S(-20.75 + 11 * 0.110595703);
			mHead._xscale = 100.890293;
			mHead._yscale = 81.655852;
			mHead.skew.x = Math.atan2(-0.039916992, 0.815582275);
			mHead.skew.y = Math.atan2(0.110595703, 1.002822876);
			mHat._x = KadoKadeoManager.S(0.85);
			mHat._y = KadoKadeoManager.I(-21);
			mHat._xscale = 99.746299;
			mHat._yscale = 108.29662;
			mHat.skew.x = Math.atan2(-0.085449219, 1.079589844);
			mHat.skew.y = Math.atan2(0.078689575, 0.994354248);
		});
		m.onFrame.set(49, function() {
			mHead._x = KadoKadeoManager.S(-9.85 + 11 * 1.000717163);
			mHead._y = KadoKadeoManager.S(-21.25 + 11 * 0.149856567);
			mHead._xscale = 101.18754;
			mHead._yscale = 80.159694;
			mHead.skew.x = Math.atan2(-0.053115845, 0.799835205);
			mHead.skew.y = Math.atan2(0.149856567, 1.000717163);
			mHat._x = KadoKadeoManager.I(1);
			mHat._y = KadoKadeoManager.S(-21.2);
			mHat._xscale = 99.724726;
			mHat._yscale = 107.564766;
			mHat.skew.x = Math.atan2(-0.118164062, 1.069137573);
			mHat.skew.y = Math.atan2(0.109558105, 0.991210938);
		});
		m.onFrame.set(50, function() {
			mHead._x = KadoKadeoManager.S(-9.8 + 11 * 0.997665405);
			mHead._y = KadoKadeoManager.S(-21.7 + 11 * 0.18586731);
			mHead._xscale = 101.483147;
			mHead._yscale = 78.662974;
			mHead.skew.x = Math.atan2(-0.06578064, 0.783874512);
			mHead.skew.y = Math.atan2(0.18586731, 0.997665405);
			mHat._x = KadoKadeoManager.S(1.05);
			mHat._y = KadoKadeoManager.S(-21.25);
			mHat._xscale = 99.705018;
			mHat._yscale = 106.828762;
			mHat.skew.x = Math.atan2(-0.153793335, 1.057159424);
			mHat.skew.y = Math.atan2(0.143539429, 0.986663818);
		});
		m.onFrame.set(51, function() {
			mHead._x = KadoKadeoManager.S(-9.6 + 11 * 0.992584229);
			mHead._y = KadoKadeoManager.S(-22.2 + 11 * 0.225097656);
			mHead._xscale = 101.7788;
			mHead._yscale = 77.165873;
			mHead.skew.x = Math.atan2(-0.077911377, 0.767715454);
			mHead.skew.y = Math.atan2(0.225097656, 0.992584229);
			mHat._x = KadoKadeoManager.S(1.2);
			mHat._y = KadoKadeoManager.S(-21.4);
			mHat._xscale = 99.68459;
			mHat._yscale = 106.096271;
			mHat.skew.x = Math.atan2(-0.185348511, 1.044647217);
			mHat.skew.y = Math.atan2(0.174118042, 0.981521606);
		});
		m.onFrame.set(52, function() {
			mHead._x = KadoKadeoManager.S(-9.4 + 11 * 0.986862183);
			mHead._y = KadoKadeoManager.S(-22.75 + 11 * 0.261016846);
			mHead._xscale = 102.079712;
			mHead._yscale = 75.671437;
			mHead.skew.x = Math.atan2(-0.089492798, 0.751403809);
			mHead.skew.y = Math.atan2(0.261016846, 0.986862183);
			mHat._x = KadoKadeoManager.S(1.25);
			mHat._y = KadoKadeoManager.S(-21.65);
			mHat._xscale = 99.662788;
			mHat._yscale = 105.360027;
			mHat.skew.x = Math.atan2(-0.219619751, 1.030456543);
			mHat.skew.y = Math.atan2(0.207763672, 0.974731445);
		});
		m.onFrame.set(53, function() {
			mHead._x = KadoKadeoManager.S(-9.35 + 11 * 0.978805542);
			mHead._y = KadoKadeoManager.S(-23.25 + 11 * 0.300018311);
			mHead._xscale = 102.375352;
			mHead._yscale = 74.175237;
			mHead.skew.x = Math.atan2(-0.100524902, 0.734909058);
			mHead.skew.y = Math.atan2(0.300018311, 0.978805542);
			mHat._x = KadoKadeoManager.S(1.45);
			mHat._y = KadoKadeoManager.S(-21.7);
			mHat._xscale = 99.644779;
			mHat._yscale = 104.629418;
			mHat.skew.x = Math.atan2(-0.249862671, 1.016021729);
			mHat.skew.y = Math.atan2(0.237945557, 0.96762085);
		});
		m.onFrame.set(54, function() {
			mHead._x = KadoKadeoManager.S(-9.15 + 11 * 0.970352173);
			mHead._y = KadoKadeoManager.S(-23.8 + 11 * 0.335632324);
			mHead._xscale = 102.67582;
			mHead._yscale = 72.680665;
			mHead.skew.x = Math.atan2(-0.111022949, 0.718276978);
			mHead.skew.y = Math.atan2(0.335632324, 0.970352173);
			mHat._x = KadoKadeoManager.S(1.55);
			mHat._y = KadoKadeoManager.S(-21.9);
			mHat._xscale = 99.623891;
			mHat._yscale = 103.895246;
			mHat.skew.x = Math.atan2(-0.282684326, 0.999755859);
			mHat.skew.y = Math.atan2(0.271026611, 0.95866394);
		});
		m.onFrame.set(55, function() {
			mHead._x = KadoKadeoManager.S(-8.95 + 11 * 0.959365845);
			mHead._y = KadoKadeoManager.S(-24.3 + 11 * 0.374160767);
			mHead._xscale = 102.974711;
			mHead._yscale = 71.183158;
			mHead.skew.x = Math.atan2(-0.12097168, 0.701477051);
			mHead.skew.y = Math.atan2(0.374160767, 0.959365845);
			mHat._x = KadoKadeoManager.S(1.55);
			mHat._y = KadoKadeoManager.S(-21.95);
			mHat._xscale = 99.605977;
			mHat._yscale = 103.165494;
			mHat.skew.x = Math.atan2(-0.311447144, 0.983520508);
			mHat.skew.y = Math.atan2(0.300704956, 0.949584961);
		});
		m.onFrame.set(56, function() {
			mHead._x = KadoKadeoManager.S(-8.85 + 11 * 0.94682312);
			mHead._y = KadoKadeoManager.S(-24.8 + 11 * 0.412353516);
			mHead._xscale = 103.271944;
			mHead._yscale = 69.688596;
			mHead.skew.x = Math.atan2(-0.130355835, 0.684585571);
			mHead.skew.y = Math.atan2(0.412353516, 0.94682312);
			mHat._x = KadoKadeoManager.S(1.65);
			mHat._y = KadoKadeoManager.S(-22.1);
			mHat._xscale = 99.585337;
			mHat._yscale = 102.435189;
			mHat.skew.x = Math.atan2(-0.342681885, 0.965332031);
			mHat.skew.y = Math.atan2(0.333145142, 0.938476562);
		});
		m.onFrame.set(57, function() {
			mHead._x = KadoKadeoManager.S(-8.65 + 11 * 0.934280396);
			mHead._y = KadoKadeoManager.S(-25.3 + 11 * 0.44708252);
			mHead._xscale = 103.574255;
			mHead._yscale = 68.193471;
			mHead.skew.x = Math.atan2(-0.139221191, 0.667572021);
			mHead.skew.y = Math.atan2(0.44708252, 0.934280396);
			mHat._x = KadoKadeoManager.S(1.75);
			mHat._y = KadoKadeoManager.S(-22.25);
			mHat._xscale = 99.567262;
			mHat._yscale = 101.70464;
			mHat.skew.x = Math.atan2(-0.369918823, 0.947387695);
			mHat.skew.y = Math.atan2(0.3621521, 0.927474976);
		});
		m.onFrame.set(58, function() {
			mHead._x = KadoKadeoManager.S(-8.5 + 11 * 0.918838501);
			mHead._y = KadoKadeoManager.S(-25.8 + 11 * 0.484451294);
			mHead._xscale = 103.872867;
			mHead._yscale = 66.699722;
			mHead.skew.x = Math.atan2(-0.147506714, 0.650482178);
			mHead.skew.y = Math.atan2(0.484451294, 0.918838501);
			mHat._x = KadoKadeoManager.S(1.85);
			mHat._y = KadoKadeoManager.S(-22.4);
			mHat._xscale = 99.550698;
			mHat._yscale = 100.974442;
			mHat.skew.x = Math.atan2(-0.399429321, 0.927383423);
			mHat.skew.y = Math.atan2(0.393798828, 0.914306641);
		});
		m.onFrame.set(59, function() {
			mHead._x = KadoKadeoManager.S(-8.4 + 11 * 0.903656006);
			mHead._y = KadoKadeoManager.S(-26.3 + 11 * 0.518356323);
			mHead._xscale = 104.177131;
			mHead._yscale = 65.204325;
			mHead.skew.x = Math.atan2(-0.155273438, 0.633285522);
			mHead.skew.y = Math.atan2(0.518356323, 0.903656006);
			mHat._x = KadoKadeoManager.S(2.05);
			mHat._y = KadoKadeoManager.S(-22.5);
			mHat._xscale = 99.534297;
			mHat._yscale = 100.242809;
			mHat.skew.x = Math.atan2(-0.425048828, 0.907852173);
			mHat.skew.y = Math.atan2(0.422027588, 0.901443481);
		});
		m.onFrame.set(60, function() {
			mHead._x = KadoKadeoManager.S(-8.2 + 11 * 0.886734009);
			mHead._y = KadoKadeoManager.S(-26.8 + 11 * 0.555435181);
			mHead._xscale = 104.632951;
			mHead._yscale = 63.761519;
			mHead.skew.x = Math.atan2(-0.162841797, 0.616470337);
			mHead.skew.y = Math.atan2(0.555435181, 0.886734009);
			mHat._x = KadoKadeoManager.S(2.05);
			mHat._y = KadoKadeoManager.S(-22.7);
			mHat._xscale = 99.646674;
			mHat._yscale = 99.646674;
			mHat.skew.x = Math.atan2(-0.453811646, 0.887130737);
			mHat.skew.y = Math.atan2(0.453811646, 0.887130737);
		});
		m.onFrame.get(1)();
		m.play();
		m.loop = true;
	}

	override public function init() {
		super.init();

		pv = 3;
		nsteps = 20;
		nextStep();
		dx = Math.cos(ang);
		dy = Math.sin(ang);
		speed = KadoKadeoManager.S(4 + game.level / 100);
	}

	override public function nextStep() {
		next = genRandPos((--nsteps) <= 0);
		ang = Math.atan2(y - next.y, x - next.x);
		ray = Math.sqrt((x - next.x) * (x - next.x) + (y - next.y) * (y - next.y));
	}

	override public function mobTouched() {
		for (i in 1...6) {
			var b:magmax.Game.PartsSprite = cast game.dmanager.attach("heliPart", Cs.PLAN_PART);
			b._x = x;
			b._y = y;
			b.gotoAndStop(i);
			b.partx = x;
			b.party = 0;
			b.vx = KadoKadeoManager.S((Seed.randomVfx(15) - 7) / 3);
			b.vy = -KadoKadeoManager.S(5 + Seed.randomVfx(4));
			b.by = y;
			game.addPart(b);
		}
	}

	override public function mobUpdate():Bool {
		ray -= KadoKadeoManager.S(1) * Timer.tmod;
		ang += (KadoKadeoManager.S(100) / ray) * 0.05 * Timer.tmod;
		var px = next.x + Math.cos(ang) * ray;
		var py = next.y + Math.sin(ang) * ray;
		var tdx = px - x;
		var tdy = py - y;

		var p = Math.pow(0.95, Timer.tmod);

		dx = dx * p + tdx * (1 - p);
		dy = dy * p + tdy * (1 - p);
		var s = speed * Timer.tmod / Math.sqrt(dx * dx + dy * dy);

		x += dx * s;
		y += dy * s;

		//----------
		var ang = Math.atan2(dy, dx);
		if (ang < 0)
			mc.sub.gotoAndStop(Std.int(-ang * 30 / Math.PI) + 1);
		else
			mc.sub.gotoAndStop(31 + Std.int((-ang + Math.PI) * 30 / Math.PI));
		//----------

		if (ray < KadoKadeoManager.I(20) || ang > Math.PI * 2)
			nextStep();

		if (x < KadoKadeoManager.I(-10) || y < KadoKadeoManager.I(-10) || x > KadoKadeoManager.I(310) || y > KadoKadeoManager.I(310)) {
			time += Timer.deltaT;
			if (time > 3) {
				mc.removeMovieClip();
				return false;
			}
		} else
			time = 0;
		return true;
	}
}
