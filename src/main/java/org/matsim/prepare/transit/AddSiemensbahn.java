package org.matsim.prepare.transit;

import org.matsim.api.core.v01.Coord;
import org.matsim.api.core.v01.Id;
import org.matsim.api.core.v01.TransportMode;
import org.matsim.api.core.v01.network.Link;
import org.matsim.api.core.v01.network.NetworkFactory;
import org.matsim.api.core.v01.network.NetworkWriter;
import org.matsim.api.core.v01.network.Node;
import org.matsim.core.config.ConfigUtils;
import org.matsim.core.network.NetworkUtils;
import org.matsim.core.population.routes.LinkNetworkRouteFactory;
import org.matsim.core.population.routes.NetworkRoute;
import org.matsim.core.population.routes.RouteUtils;
import org.matsim.core.scenario.ScenarioUtils;
import org.matsim.pt.transitSchedule.api.*;
import org.matsim.vehicles.MatsimVehicleReader;
import org.matsim.vehicles.MatsimVehicleWriter;
import org.matsim.vehicles.VehicleType;

import java.net.MalformedURLException;
import java.nio.file.Paths;
import java.util.List;
import java.util.Set;

public class AddSiemensbahn {

	private static LinkNetworkRouteFactory routeFactory = new LinkNetworkRouteFactory();
	private static NetworkFactory networkFactory = NetworkUtils.createNetwork().getFactory();
	private static TransitScheduleFactory scheduleFactory = ScenarioUtils.createScenario(ConfigUtils.createConfig()).getTransitSchedule().getFactory();

	public static void main(String[] args) throws MalformedURLException {

		var root = Paths.get(".\\input");
		var scenario = ScenarioUtils.createScenario(ConfigUtils.createConfig());

		// read in existing files

		var transitSchedule = new java.net.URL("https://svn.vsp.tu-berlin.de/repos/public-svn/matsim/scenarios/countries/de/berlin/berlin-v6.4/input/berlin-v6.4-transitSchedule.xml.gz");
		var vehicleFile = new java.net.URL("https://svn.vsp.tu-berlin.de/repos/public-svn/matsim/scenarios/countries/de/berlin/berlin-v6.4/input/berlin-v6.4-transitVehicles.xml.gz");
		new TransitScheduleReader(scenario).readFile(transitSchedule.toString());
		var network = NetworkUtils.readNetwork("https://svn.vsp.tu-berlin.de/repos/public-svn/matsim/scenarios/countries/de/gartenfeld/input/gartenfeld-v6.4.network.xml.gz");

		MatsimVehicleReader vehicleReader = new MatsimVehicleReader(scenario.getTransitVehicles());
		vehicleReader.readFile(vehicleFile.toString());

		// vehicle type
		var vehicleType = scenario.getTransitVehicles().getVehicleTypes().get(Id.create("S-Bahn_veh_type", VehicleType.class));

		// get existing stations and add new stations (nodes) Siemensbahn to network
			//Base Case
		var Hauptbahnhof = network.getNodes().get(Id.createNodeId("pt_359974_SuburbanRailway"));
		var PerlebergerBruecke = network.getFactory().createNode(Id.createNodeId("pt_116410_SuburbanRailway"), new Coord( 795604.72, 5829611.59));
		var Westhafen = network.getNodes().get(Id.createNodeId("pt_473821_SuburbanRailway"));
		var Beusselstrasse = network.getNodes().get(Id.createNodeId("pt_502749_SuburbanRailway"));
		var Jungfernheide = network.getNodes().get(Id.createNodeId("pt_397108_SuburbanRailway"));
			//SiBa
		var Wernerwerk = network.getFactory().createNode(Id.createNodeId("pt_116420_SuburbanRailway"), new Coord(789976.12, 5829083.16));
		var Siemensstadt = network.getFactory().createNode(Id.createNodeId("pt_116430_SuburbanRailway"), new Coord(789100.47, 5829563.55));
		var Gartenfeld = network.getFactory().createNode(Id.createNodeId("pt_116440_SuburbanRailway"), new Coord(788060.58, 5830351.63));
		/*	//SiBa+v1
		var WasserstadtOberhavel_v1 = network.getFactory().createNode(Id.createNodeId("pt_116451_SuburbanRailway"), new Coord(786696.91, 5831618.01));
		var Hakenfelde_v1 = network.getFactory().createNode(Id.createNodeId("pt_116461_SuburbanRailway"), new Coord(785201.35, 5832268.05));*/
		/*	//SiBa+v2
		var WasserstadtOberhavel_v2 = network.getFactory().createNode(Id.createNodeId("pt_116452_SuburbanRailway"), new Coord(786589.78, 5831013.36));
		var Hakenfelde_v2 = network.getFactory().createNode(Id.createNodeId("pt_116462_SuburbanRailway"), new Coord(785169.34, 5831150.76));*/

			//Base Case
		network.addNode(PerlebergerBruecke);
			//SiBa
		network.addNode(Wernerwerk);
		network.addNode(Siemensstadt);
		network.addNode(Gartenfeld);
		/*	//SiBa+v1
		network.addNode(WasserstadtOberhavel_v1);
		network.addNode(Hakenfelde_v1);*/
		/*	//SiBa+v2
		network.addNode(WasserstadtOberhavel_v2);
		network.addNode(Hakenfelde_v2);*/

		// get existing links and create new links Siemensbahn
			//Base Case
		var Hauptbahnhof_PerlebergerBruecke = createLink("pt_359974_SuburbanRailway-pt_116410_SuburbanRailway", Hauptbahnhof, PerlebergerBruecke);
		var PerlebergerBruecke_Hauptbahnhof = createLink("pt_116410_SuburbanRailway-pt_359974_SuburbanRailway", PerlebergerBruecke, Hauptbahnhof);
		var PerlebergerBruecke_Westhafen = createLink("pt_116410_SuburbanRailway-pt_473821_SuburbanRailway", PerlebergerBruecke, Westhafen);
		var Westhafen_PerlebergerBruecke = createLink("pt_473821_SuburbanRailway-pt_116410_SuburbanRailway", Westhafen, PerlebergerBruecke);
		var Westhafen_Beusselstrasse = network.getLinks().get(Id.createLinkId("pt_473821_SuburbanRailway-pt_502749_SuburbanRailway"));
		var Beusselstrasse_Westhafen = network.getLinks().get(Id.createLinkId("pt_502749_SuburbanRailway-pt_473821_SuburbanRailway"));
		var Beusselstrasse_Jungfernheide = network.getLinks().get(Id.createLinkId("pt_502749_SuburbanRailway-pt_397108_SuburbanRailway"));
		var Jungfernheide_Beusselstrasse = network.getLinks().get(Id.createLinkId("pt_397108_SuburbanRailway-pt_502749_SuburbanRailway"));
			//SiBa
		var Jungfernheide_Wernerwerk = createLink("pt_397108_SuburbanRailway-pt_116420_SuburbanRailway", Jungfernheide, Wernerwerk);
		var Wernerwerk_Jungfernheide = createLink("pt_116420_SuburbanRailway-pt_397108_SuburbanRailway", Wernerwerk, Jungfernheide);
		var Wernerwerk_Siemensstadt = createLink("pt_116420_SuburbanRailway-pt_116430_SuburbanRailway", Wernerwerk, Siemensstadt);
		var Siemensstadt_Wernerwerk = createLink("pt_116430_SuburbanRailway-pt_116420_SuburbanRailway", Siemensstadt, Wernerwerk);
		var Siemensstadt_Gartenfeld = createLink("pt_116430_SuburbanRailway-pt_116440_SuburbanRailway", Siemensstadt, Gartenfeld);
		var Gartenfeld_Siemensstadt = createLink("pt_116440_SuburbanRailway-pt_116430_SuburbanRailway", Gartenfeld, Siemensstadt);
		/*	//SiBa+v1
		var Gartenfeld_WasserstadtOberhavel_v1 = createLink("pt_116440_SuburbanRailway-pt_116451_SuburbanRailway", Gartenfeld, WasserstadtOberhavel_v1);
		var WasserstadtOberhavel_v1_Gartenfeld = createLink("pt_116451_SuburbanRailway-pt_116440_SuburbanRailway", WasserstadtOberhavel_v1, Gartenfeld);
		var WasserstadtOberhavel_v1_Hakenfelde_v1 = createLink("pt_116451_SuburbanRailway-pt_116461_SuburbanRailway", WasserstadtOberhavel_v1, Hakenfelde_v1);
		var Hakenfelde_v1_WasserstadtOberhavel_v1 = createLink("pt_116461_SuburbanRailway-pt_116451_SuburbanRailway", Hakenfelde_v1, WasserstadtOberhavel_v1);*/
		/*	//SiBa+v2
		var Gartenfeld_WasserstadtOberhavel_v2 = createLink("pt_116440_SuburbanRailway-pt_116452_SuburbanRailway", Gartenfeld, WasserstadtOberhavel_v2);
		var WasserstadtOberhavel_v2_Gartenfeld = createLink("pt_116452_SuburbanRailway-pt_116440_SuburbanRailway", WasserstadtOberhavel_v2, Gartenfeld);
		var WasserstadtOberhavel_v2_Hakenfelde_v2 = createLink("pt_116452_SuburbanRailway-pt_116462_SuburbanRailway", WasserstadtOberhavel_v2, Hakenfelde_v2);
		var Hakenfelde_v2_WasserstadtOberhavel_v2 = createLink("pt_116462_SuburbanRailway-pt_116452_SuburbanRailway", Hakenfelde_v2, WasserstadtOberhavel_v2);*/

			//Base Case
		network.addLink(Hauptbahnhof_PerlebergerBruecke);
		network.addLink(PerlebergerBruecke_Hauptbahnhof);
		network.addLink(PerlebergerBruecke_Westhafen);
		network.addLink(Westhafen_PerlebergerBruecke);
			//SiBa
		network.addLink(Jungfernheide_Wernerwerk);
		network.addLink(Wernerwerk_Jungfernheide);
		network.addLink(Wernerwerk_Siemensstadt);
		network.addLink(Siemensstadt_Wernerwerk);
		network.addLink(Siemensstadt_Gartenfeld);
		network.addLink(Gartenfeld_Siemensstadt);
		/*	//SiBa+v1
		network.addLink(Gartenfeld_WasserstadtOberhavel_v1);
		network.addLink(WasserstadtOberhavel_v1_Gartenfeld);
		network.addLink(WasserstadtOberhavel_v1_Hakenfelde_v1);
		network.addLink(Hakenfelde_v1_WasserstadtOberhavel_v1);*/
		/*	//SiBa+v2
		network.addLink(Gartenfeld_WasserstadtOberhavel_v2);
		network.addLink(WasserstadtOberhavel_v2_Gartenfeld);
		network.addLink(WasserstadtOberhavel_v2_Hakenfelde_v2);
		network.addLink(Hakenfelde_v2_WasserstadtOberhavel_v2);*/

		// get existing lace links and create lace links
			//Base Case
		var station_Hauptbahnhof = network.getLinks().get(Id.createLinkId("pt_359974_SuburbanRailway"));
		var station_PerlebergerBruecke = createLink("pt_116410_SuburbanRailway", PerlebergerBruecke, PerlebergerBruecke);
		var station_Westhafen = network.getLinks().get(Id.createLinkId("pt_473821_SuburbanRailway"));
		var station_Beusselstrasse = network.getLinks().get(Id.createLinkId("pt_502749_SuburbanRailway"));
		var station_Jungfernheide = network.getLinks().get(Id.createLinkId("pt_397108_SuburbanRailway"));
			//SiBa
		var station_Wernerwerk = createLink("pt_116420_SuburbanRailway", Wernerwerk, Wernerwerk);
		var station_Siemensstadt = createLink("pt_116430_SuburbanRailway", Siemensstadt, Siemensstadt);
		var station_Gartenfeld = createLink("pt_116440_SuburbanRailway", Gartenfeld, Gartenfeld);
		/*	//SiBa+v1
		var station_WasserstadtOberhavel_v1 = createLink("pt_116451_SuburbanRailway", WasserstadtOberhavel_v1, WasserstadtOberhavel_v1);
		var station_Hakenfelde_v1 = createLink("pt_116461_SuburbanRailway", Hakenfelde_v1, Hakenfelde_v1);*/
		/*	//SiBa+v2
		var station_WasserstadtOberhavel_v2 = createLink("pt_116452_SuburbanRailway", WasserstadtOberhavel_v2, WasserstadtOberhavel_v2);
		var station_Hakenfelde_v2 = createLink("pt_116462_SuburbanRailway", Hakenfelde_v2, Hakenfelde_v2);*/

			//Base Case
		network.addLink(station_PerlebergerBruecke);
			//SiBa
		network.addLink(station_Wernerwerk);
		network.addLink(station_Siemensstadt);
		network.addLink(station_Gartenfeld);
		/*	//SiBa+v1
		network.addLink(station_WasserstadtOberhavel_v1);
		network.addLink(station_Hakenfelde_v1);*/
		/*	//SiBa+v2
		network.addLink(station_WasserstadtOberhavel_v2);
		network.addLink(station_Hakenfelde_v2);*/


		// network route e > w and w > e
		/*	//Base Case
		NetworkRoute networkRoute_e_w = RouteUtils.createLinkNetworkRouteImpl(station_Hauptbahnhof.getId(),
			List.of(Hauptbahnhof_PerlebergerBruecke.getId(),station_PerlebergerBruecke.getId(),PerlebergerBruecke_Westhafen.getId(),station_Westhafen.getId(),
				Westhafen_Beusselstrasse.getId(),station_Beusselstrasse.getId(),Beusselstrasse_Jungfernheide.getId()),station_Jungfernheide.getId());
		NetworkRoute networkRoute_w_e = RouteUtils.createLinkNetworkRouteImpl(station_Jungfernheide.getId(),
			List.of(Jungfernheide_Beusselstrasse.getId(),station_Beusselstrasse.getId(),Beusselstrasse_Westhafen.getId(),station_Westhafen.getId(),
				Westhafen_PerlebergerBruecke.getId(),station_PerlebergerBruecke.getId(),PerlebergerBruecke_Hauptbahnhof.getId()),station_Hauptbahnhof.getId());
*/
			//SiBa
		NetworkRoute networkRoute_e_w = RouteUtils.createLinkNetworkRouteImpl(station_Hauptbahnhof.getId(),
				List.of(Hauptbahnhof_PerlebergerBruecke.getId(),station_PerlebergerBruecke.getId(),PerlebergerBruecke_Westhafen.getId(),station_Westhafen.getId(),Westhafen_Beusselstrasse.getId(),station_Beusselstrasse.getId(),
						Beusselstrasse_Jungfernheide.getId(),station_Jungfernheide.getId(),Jungfernheide_Wernerwerk.getId(), station_Wernerwerk.getId(),Wernerwerk_Siemensstadt.getId(),station_Siemensstadt.getId(),Siemensstadt_Gartenfeld.getId()),station_Gartenfeld.getId());
		NetworkRoute networkRoute_w_e = RouteUtils.createLinkNetworkRouteImpl(station_Gartenfeld.getId(),
				List.of(Gartenfeld_Siemensstadt.getId(),station_Siemensstadt.getId(),Siemensstadt_Wernerwerk.getId(),station_Wernerwerk.getId(),Wernerwerk_Jungfernheide.getId(),station_Jungfernheide.getId(),
						Jungfernheide_Beusselstrasse.getId(),station_Beusselstrasse.getId(),Beusselstrasse_Westhafen.getId(),station_Westhafen.getId(),Westhafen_PerlebergerBruecke.getId(),station_PerlebergerBruecke.getId(),PerlebergerBruecke_Hauptbahnhof.getId()),station_Hauptbahnhof.getId());

		/*	//SiBa+v1
		NetworkRoute networkRoute_e_w = RouteUtils.createLinkNetworkRouteImpl(station_Hauptbahnhof.getId(),
			List.of(Hauptbahnhof_PerlebergerBruecke.getId(),station_PerlebergerBruecke.getId(),PerlebergerBruecke_Westhafen.getId(),station_Westhafen.getId(),Westhafen_Beusselstrasse.getId(),station_Beusselstrasse.getId(),
				Beusselstrasse_Jungfernheide.getId(),station_Jungfernheide.getId(),Jungfernheide_Wernerwerk.getId(), station_Wernerwerk.getId(),Wernerwerk_Siemensstadt.getId(),station_Siemensstadt.getId(),Siemensstadt_Gartenfeld.getId(),
				Gartenfeld_WasserstadtOberhavel_v1.getId(),station_WasserstadtOberhavel_v1.getId(),WasserstadtOberhavel_v1_Hakenfelde_v1.getId()),station_Hakenfelde_v1.getId());
		NetworkRoute networkRoute_w_e = RouteUtils.createLinkNetworkRouteImpl(station_Hakenfelde_v1.getId(),
			List.of(Hakenfelde_v1_WasserstadtOberhavel_v1.getId(),station_WasserstadtOberhavel_v1.getId(),WasserstadtOberhavel_v1_Gartenfeld.getId(),station_Gartenfeld.getId(),Gartenfeld_Siemensstadt.getId(),station_Siemensstadt.getId(),
				Siemensstadt_Wernerwerk.getId(),station_Wernerwerk.getId(),Wernerwerk_Jungfernheide.getId(),station_Jungfernheide.getId(),Jungfernheide_Beusselstrasse.getId(),station_Beusselstrasse.getId(),Beusselstrasse_Westhafen.getId(),
				station_Westhafen.getId(),Westhafen_PerlebergerBruecke.getId(),station_PerlebergerBruecke.getId(),PerlebergerBruecke_Hauptbahnhof.getId()),station_Hauptbahnhof.getId());*/

		/*	//SiBa+v2
		NetworkRoute networkRoute_e_w = RouteUtils.createLinkNetworkRouteImpl(station_Hauptbahnhof.getId(),
			List.of(Hauptbahnhof_PerlebergerBruecke.getId(),station_PerlebergerBruecke.getId(),PerlebergerBruecke_Westhafen.getId(),station_Westhafen.getId(),Westhafen_Beusselstrasse.getId(),station_Beusselstrasse.getId(),
				Beusselstrasse_Jungfernheide.getId(),station_Jungfernheide.getId(),Jungfernheide_Wernerwerk.getId(), station_Wernerwerk.getId(),Wernerwerk_Siemensstadt.getId(),station_Siemensstadt.getId(),Siemensstadt_Gartenfeld.getId(),
				Gartenfeld_WasserstadtOberhavel_v2.getId(),station_WasserstadtOberhavel_v2.getId(),WasserstadtOberhavel_v2_Hakenfelde_v2.getId()),station_Hakenfelde_v2.getId());
		NetworkRoute networkRoute_w_e = RouteUtils.createLinkNetworkRouteImpl(station_Hakenfelde_v2.getId(),
			List.of(Hakenfelde_v2_WasserstadtOberhavel_v2.getId(),station_WasserstadtOberhavel_v2.getId(),WasserstadtOberhavel_v2_Gartenfeld.getId(),station_Gartenfeld.getId(),Gartenfeld_Siemensstadt.getId(),station_Siemensstadt.getId(),
				Siemensstadt_Wernerwerk.getId(),station_Wernerwerk.getId(),Wernerwerk_Jungfernheide.getId(),station_Jungfernheide.getId(),Jungfernheide_Beusselstrasse.getId(),station_Beusselstrasse.getId(),Beusselstrasse_Westhafen.getId(),
				station_Westhafen.getId(),Westhafen_PerlebergerBruecke.getId(),station_PerlebergerBruecke.getId(),PerlebergerBruecke_Hauptbahnhof.getId()),station_Hauptbahnhof.getId());*/

		// facilities e > w
			//Base Case
		var stop1_facility_e_w = scheduleFactory.createTransitStopFacility(Id.create("Hauptbahnhof_e_w", TransitStopFacility.class),Hauptbahnhof.getCoord(),false);
		var stop2_facility_e_w = scheduleFactory.createTransitStopFacility(Id.create("PerlebergerBruecke_e_w", TransitStopFacility.class),PerlebergerBruecke.getCoord(),false);
		var stop3_facility_e_w = scheduleFactory.createTransitStopFacility(Id.create("Westhafen_e_w", TransitStopFacility.class),Westhafen.getCoord(),false);
		var stop4_facility_e_w = scheduleFactory.createTransitStopFacility(Id.create("Beusselstrasse_e_w", TransitStopFacility.class),Beusselstrasse.getCoord(),false);
		var stop5_facility_e_w = scheduleFactory.createTransitStopFacility(Id.create("Jungfernheide_e_w", TransitStopFacility.class),Jungfernheide.getCoord(),false);
			//SiBa
		var stop6_facility_e_w = scheduleFactory.createTransitStopFacility(Id.create("Wernerwerk_e_w", TransitStopFacility.class),Wernerwerk.getCoord(),false);
		var stop7_facility_e_w = scheduleFactory.createTransitStopFacility(Id.create("Siemensstadt_e_w", TransitStopFacility.class),Siemensstadt.getCoord(),false);
		var stop8_facility_e_w = scheduleFactory.createTransitStopFacility(Id.create("Gartenfeld_e_w", TransitStopFacility.class),Gartenfeld.getCoord(),false);
		/*	//SiBa+v1
		var stop91_facility_e_w = scheduleFactory.createTransitStopFacility(Id.create("WasserstadtOberhavel_v1_e_w", TransitStopFacility.class),WasserstadtOberhavel_v1.getCoord(),false);
		var stop101_facility_e_w = scheduleFactory.createTransitStopFacility(Id.create("Hakenfelde_v1_e_w", TransitStopFacility.class),Hakenfelde_v1.getCoord(),false);*/
		/*	//SiBa+v2
		var stop92_facility_e_w = scheduleFactory.createTransitStopFacility(Id.create("WasserstadtOberhavel_v2_e_w", TransitStopFacility.class),WasserstadtOberhavel_v2.getCoord(),false);
		var stop102_facility_e_w = scheduleFactory.createTransitStopFacility(Id.create("Hakenfelde_v2_e_w", TransitStopFacility.class),Hakenfelde_v2.getCoord(),false);*/

			//Base Case
		stop1_facility_e_w.setLinkId(station_Hauptbahnhof.getId());
		stop2_facility_e_w.setLinkId(station_PerlebergerBruecke.getId());
		stop3_facility_e_w.setLinkId(station_Westhafen.getId());
		stop4_facility_e_w.setLinkId(station_Beusselstrasse.getId());
		stop5_facility_e_w.setLinkId(station_Jungfernheide.getId());
			//SiBa
		stop6_facility_e_w.setLinkId(station_Wernerwerk.getId());
		stop7_facility_e_w.setLinkId(station_Siemensstadt.getId());
		stop8_facility_e_w.setLinkId(station_Gartenfeld.getId());
		/*	//SiBa+v1
		stop91_facility_e_w.setLinkId((station_WasserstadtOberhavel_v1).getId());
		stop101_facility_e_w.setLinkId((station_Hakenfelde_v1).getId());*/
		/*	//SiBa+v2
		stop92_facility_e_w.setLinkId((station_WasserstadtOberhavel_v2).getId());
		stop102_facility_e_w.setLinkId((station_Hakenfelde_v2).getId());*/

			//Base Case
		scenario.getTransitSchedule().addStopFacility(stop1_facility_e_w);
		scenario.getTransitSchedule().addStopFacility(stop2_facility_e_w);
		scenario.getTransitSchedule().addStopFacility(stop3_facility_e_w);
		scenario.getTransitSchedule().addStopFacility(stop4_facility_e_w);
		scenario.getTransitSchedule().addStopFacility(stop5_facility_e_w);
			//SiBa
		scenario.getTransitSchedule().addStopFacility(stop6_facility_e_w);
		scenario.getTransitSchedule().addStopFacility(stop7_facility_e_w);
		scenario.getTransitSchedule().addStopFacility(stop8_facility_e_w);
		/*	//SiBa+v1
		scenario.getTransitSchedule().addStopFacility(stop91_facility_e_w);
		scenario.getTransitSchedule().addStopFacility(stop101_facility_e_w);*/
		/*	//SiBa+v2
		scenario.getTransitSchedule().addStopFacility(stop92_facility_e_w);
		scenario.getTransitSchedule().addStopFacility(stop102_facility_e_w);*/

		// facilities w > e
			//Base Case
		var stop1_facility_w_e = scheduleFactory.createTransitStopFacility(Id.create("Hauptbahnhof_w_e", TransitStopFacility.class),Hauptbahnhof.getCoord(),false);
		var stop2_facility_w_e = scheduleFactory.createTransitStopFacility(Id.create("PerlebergerBruecke_w_e", TransitStopFacility.class),PerlebergerBruecke.getCoord(),false);
		var stop3_facility_w_e = scheduleFactory.createTransitStopFacility(Id.create("Westhafen_w_e", TransitStopFacility.class),Westhafen.getCoord(),false);
		var stop4_facility_w_e = scheduleFactory.createTransitStopFacility(Id.create("Beusselstrasse_w_e", TransitStopFacility.class),Beusselstrasse.getCoord(),false);
		var stop5_facility_w_e = scheduleFactory.createTransitStopFacility(Id.create("Jungfernheide_w_e", TransitStopFacility.class),Jungfernheide.getCoord(),false);
			//SiBa
		var stop6_facility_w_e = scheduleFactory.createTransitStopFacility(Id.create("Wernerwerk_w_e", TransitStopFacility.class),Wernerwerk.getCoord(),false);
		var stop7_facility_w_e = scheduleFactory.createTransitStopFacility(Id.create("Siemensstadt_w_e", TransitStopFacility.class),Siemensstadt.getCoord(),false);
		var stop8_facility_w_e = scheduleFactory.createTransitStopFacility(Id.create("Gartenfeld_w_e", TransitStopFacility.class),Gartenfeld.getCoord(),false);
		/*	//SiBa+v1
		var stop91_facility_w_e = scheduleFactory.createTransitStopFacility(Id.create("WasserstadtOberhavel_v1_w_e", TransitStopFacility.class),WasserstadtOberhavel_v1.getCoord(),false);
		var stop101_facility_w_e = scheduleFactory.createTransitStopFacility(Id.create("Hakenfelde_v1_w_e", TransitStopFacility.class),Hakenfelde_v1.getCoord(),false);*/
		/*	//SiBa+v2
		var stop92_facility_w_e = scheduleFactory.createTransitStopFacility(Id.create("WasserstadtOberhavel_v2_w_e", TransitStopFacility.class),WasserstadtOberhavel_v2.getCoord(),false);
		var stop102_facility_w_e = scheduleFactory.createTransitStopFacility(Id.create("Hakenfelde_v2_w_e", TransitStopFacility.class),Hakenfelde_v2.getCoord(),false);*/

			//Base Case
		stop1_facility_w_e.setLinkId(station_Hauptbahnhof.getId());
		stop2_facility_w_e.setLinkId(station_PerlebergerBruecke.getId());
		stop3_facility_w_e.setLinkId(station_Westhafen.getId());
		stop4_facility_w_e.setLinkId(station_Beusselstrasse.getId());
		stop5_facility_w_e.setLinkId(station_Jungfernheide.getId());
			//SiBa
		stop6_facility_w_e.setLinkId(station_Wernerwerk.getId());
		stop7_facility_w_e.setLinkId(station_Siemensstadt.getId());
		stop8_facility_w_e.setLinkId(station_Gartenfeld.getId());
		/*	//SiBa+v1
		stop91_facility_w_e.setLinkId((station_WasserstadtOberhavel_v1).getId());
		stop101_facility_w_e.setLinkId((station_Hakenfelde_v1).getId());*/
		/*	//SiBa+v2
		stop92_facility_w_e.setLinkId((station_WasserstadtOberhavel_v2).getId());
		stop102_facility_w_e.setLinkId((station_Hakenfelde_v2).getId());*/

			//Base Case
		scenario.getTransitSchedule().addStopFacility(stop1_facility_w_e);
		scenario.getTransitSchedule().addStopFacility(stop2_facility_w_e);
		scenario.getTransitSchedule().addStopFacility(stop3_facility_w_e);
		scenario.getTransitSchedule().addStopFacility(stop4_facility_w_e);
		scenario.getTransitSchedule().addStopFacility(stop5_facility_w_e);
			//SiBa
		scenario.getTransitSchedule().addStopFacility(stop6_facility_w_e);
		scenario.getTransitSchedule().addStopFacility(stop7_facility_w_e);
		scenario.getTransitSchedule().addStopFacility(stop8_facility_w_e);
		/*	//SiBa+v1
		scenario.getTransitSchedule().addStopFacility(stop91_facility_w_e);
		scenario.getTransitSchedule().addStopFacility(stop101_facility_w_e);*/
		/*	//SiBa+v2
		scenario.getTransitSchedule().addStopFacility(stop92_facility_w_e);
		scenario.getTransitSchedule().addStopFacility(stop102_facility_w_e);*/

		// stations e > w
			//Base Case
		var stop1_e_w=scheduleFactory.createTransitRouteStop(stop1_facility_e_w,0,0);
		var stop2_e_w=scheduleFactory.createTransitRouteStop(stop2_facility_e_w,100,130);
		var stop3_e_w=scheduleFactory.createTransitRouteStop(stop3_facility_e_w,197,227);
		var stop4_e_w=scheduleFactory.createTransitRouteStop(stop4_facility_e_w,298,328);
		var stop5_e_w=scheduleFactory.createTransitRouteStop(stop5_facility_e_w,459,489);
			//SiBa
		var stop6_e_w=scheduleFactory.createTransitRouteStop(stop6_facility_e_w,631,661);
		var stop7_e_w=scheduleFactory.createTransitRouteStop(stop7_facility_e_w,735,765);
		var stop8_e_w=scheduleFactory.createTransitRouteStop(stop8_facility_e_w,855,885);
		/*	//SiBa Shuttle
		var stop1_e_w=scheduleFactory.createTransitRouteStop(stop1_facility_e_w,0,0);
		var stop2_e_w=scheduleFactory.createTransitRouteStop(stop2_facility_e_w,1,2);
		var stop3_e_w=scheduleFactory.createTransitRouteStop(stop3_facility_e_w,3,4);
		var stop4_e_w=scheduleFactory.createTransitRouteStop(stop4_facility_e_w,5,6);
		var stop5_e_w=scheduleFactory.createTransitRouteStop(stop5_facility_e_w,7,8);
		var stop6_e_w=scheduleFactory.createTransitRouteStop(stop6_facility_e_w,9,10);
		var stop7_e_w=scheduleFactory.createTransitRouteStop(stop7_facility_e_w,11,12);
		var stop8_e_w=scheduleFactory.createTransitRouteStop(stop8_facility_e_w,13,14);*/
		/*	//SiBa+v1
		var stop9_e_w=scheduleFactory.createTransitRouteStop(stop91_facility_e_w,1008,1038);
		var stop10_e_w=scheduleFactory.createTransitRouteStop(stop101_facility_e_w,1150,1180);*/
			//SiBa+v2
		/*var stop9_e_w=scheduleFactory.createTransitRouteStop(stop92_facility_e_w,995,1025);
		var stop10_e_w=scheduleFactory.createTransitRouteStop(stop102_facility_e_w,1121,1151);*/

		// stations w > e
			//Base Case: Jungfernheide > Hauptbahnhof
		/*var stop1_w_e=scheduleFactory.createTransitRouteStop(stop5_facility_w_e,0,0);
		var stop2_w_e=scheduleFactory.createTransitRouteStop(stop4_facility_w_e,131,161);
		var stop3_w_e=scheduleFactory.createTransitRouteStop(stop3_facility_w_e,232,262);
		var stop4_w_e=scheduleFactory.createTransitRouteStop(stop2_facility_w_e,329,359);
		var stop5_w_e=scheduleFactory.createTransitRouteStop(stop1_facility_w_e,459,489);*/
			//SiBa: Gartenfeld > Hauptbahnhof
		var stop1_w_e=scheduleFactory.createTransitRouteStop(stop8_facility_w_e,0,0);
		var stop2_w_e=scheduleFactory.createTransitRouteStop(stop7_facility_w_e,90,120);
		var stop3_w_e=scheduleFactory.createTransitRouteStop(stop6_facility_w_e,194,224);
		var stop4_w_e=scheduleFactory.createTransitRouteStop(stop5_facility_w_e,366,396);
		var stop5_w_e=scheduleFactory.createTransitRouteStop(stop4_facility_w_e,527,557);
		var stop6_w_e=scheduleFactory.createTransitRouteStop(stop3_facility_w_e,628,658);
		var stop7_w_e=scheduleFactory.createTransitRouteStop(stop2_facility_w_e,725,755);
		var stop8_w_e=scheduleFactory.createTransitRouteStop(stop1_facility_w_e,855,885);
			//SiBa Shuttle
		/*var stop1_w_e=scheduleFactory.createTransitRouteStop(stop8_facility_w_e,0,0);
		var stop2_w_e=scheduleFactory.createTransitRouteStop(stop7_facility_w_e,1,2);
		var stop3_w_e=scheduleFactory.createTransitRouteStop(stop6_facility_w_e,3,4);
		var stop4_w_e=scheduleFactory.createTransitRouteStop(stop5_facility_w_e,5,6);
		var stop5_w_e=scheduleFactory.createTransitRouteStop(stop4_facility_w_e,7,8);
		var stop6_w_e=scheduleFactory.createTransitRouteStop(stop3_facility_w_e,9,10);
		var stop7_w_e=scheduleFactory.createTransitRouteStop(stop2_facility_w_e,11,12);
		var stop8_w_e=scheduleFactory.createTransitRouteStop(stop1_facility_w_e,13,14);*/
			//SiBa+v1: Hakenfelde_v1 > Hauptbahnhof
		/*var stop1_w_e=scheduleFactory.createTransitRouteStop(stop101_facility_w_e,0,0);
		var stop2_w_e=scheduleFactory.createTransitRouteStop(stop91_facility_w_e,112,142);
		var stop3_w_e=scheduleFactory.createTransitRouteStop(stop8_facility_w_e,265,295);
		var stop4_w_e=scheduleFactory.createTransitRouteStop(stop7_facility_w_e,385,415);
		var stop5_w_e=scheduleFactory.createTransitRouteStop(stop6_facility_w_e,489,519);
		var stop6_w_e=scheduleFactory.createTransitRouteStop(stop5_facility_w_e,661,691);
		var stop7_w_e=scheduleFactory.createTransitRouteStop(stop4_facility_w_e,822,852);
		var stop8_w_e=scheduleFactory.createTransitRouteStop(stop3_facility_w_e,923,953);
		var stop9_w_e=scheduleFactory.createTransitRouteStop(stop2_facility_w_e,1020,1050);
		var stop10_w_e=scheduleFactory.createTransitRouteStop(stop1_facility_w_e,1150,1180);*/
			//SiBa+v2: Hakenfelde_v2 > Hauptbahnhof
		/*var stop1_w_e=scheduleFactory.createTransitRouteStop(stop102_facility_w_e,0,0);
		var stop2_w_e=scheduleFactory.createTransitRouteStop(stop92_facility_w_e,96,126);
		var stop3_w_e=scheduleFactory.createTransitRouteStop(stop8_facility_w_e,236,266);
		var stop4_w_e=scheduleFactory.createTransitRouteStop(stop7_facility_w_e,356,386);
		var stop5_w_e=scheduleFactory.createTransitRouteStop(stop6_facility_w_e,460,490);
		var stop6_w_e=scheduleFactory.createTransitRouteStop(stop5_facility_w_e,632,662);
		var stop7_w_e=scheduleFactory.createTransitRouteStop(stop4_facility_w_e,793,823);
		var stop8_w_e=scheduleFactory.createTransitRouteStop(stop3_facility_w_e,894,924);
		var stop9_w_e=scheduleFactory.createTransitRouteStop(stop2_facility_w_e,991,1021);
		var stop10_w_e=scheduleFactory.createTransitRouteStop(stop1_facility_w_e,1121,1151);*/

		//route

		var route_e_w = scheduleFactory.createTransitRoute(Id.create("SiBa_e_w", TransitRoute.class),
				networkRoute_e_w,List.of(stop1_e_w,stop2_e_w,stop3_e_w,stop4_e_w,stop5_e_w,stop6_e_w,stop7_e_w,stop8_e_w/*,stop9_e_w,stop10_e_w*/),"pt");
		var route_w_e = scheduleFactory.createTransitRoute(Id.create("SiBa_w_e", TransitRoute.class),
				networkRoute_w_e,List.of(stop1_w_e,stop2_w_e,stop3_w_e,stop4_w_e,stop5_w_e,stop6_w_e,stop7_w_e,stop8_w_e/*,stop9_w_e,stop10_w_e*/),"pt");

		// create departures and vehicles for each departure E > W
		for (int i = 3 * 3600; i < 24 * 3600; i += 600) {
			var departure = scheduleFactory.createDeparture(Id.create("departure_" + i, Departure.class), i);
			var vehicle = scenario.getTransitVehicles().getFactory().createVehicle(Id.createVehicleId("SiBa_vehicle_e_w_" + "100" + i), vehicleType);
			departure.setVehicleId(vehicle.getId());

			scenario.getTransitVehicles().addVehicle(vehicle);
			route_e_w.addDeparture(departure);
		}

		// create departures and vehicles for each departure W > E
		for (int i = 3 * 3600; i < 24 * 3600; i += 600) {
			var departure = scheduleFactory.createDeparture(Id.create("departure_" + i, Departure.class), i);
			var vehicle = scenario.getTransitVehicles().getFactory().createVehicle(Id.createVehicleId("SiBa_vehicle_w_e_" + "100" + i), vehicleType);
			departure.setVehicleId(vehicle.getId());

			scenario.getTransitVehicles().addVehicle(vehicle);
			route_w_e.addDeparture(departure);
		}

		// line E > W
		var line_e_w = scheduleFactory.createTransitLine(Id.create("SiBa_e_w", TransitLine.class));
		line_e_w.addRoute(route_e_w);
		scenario.getTransitSchedule().addTransitLine(line_e_w);

		// line W > E
		var line_w_e = scheduleFactory.createTransitLine(Id.create("SiBa_w_e", TransitLine.class));
		line_w_e.addRoute(route_w_e);
		scenario.getTransitSchedule().addTransitLine(line_w_e);

		new NetworkWriter(network).write(root.resolve("berlin-v6.4-network-SiBa-10min.xml.gz").toString());
		new TransitScheduleWriter(scenario.getTransitSchedule()).writeFile(root.resolve("berlin-v6.4-transitSchedule-SiBa-10min.xml.gz").toString());
		new MatsimVehicleWriter(scenario.getTransitVehicles()).writeFile(root.resolve("berlin-v6.4-transitVehicles-SiBa-10min.xml.gz").toString());
	}

	private static Link createLink(String id, Node from, Node to) {

		var connection = networkFactory.createLink(Id.createLinkId(id), from, to);
		connection.setAllowedModes(Set.of(TransportMode.pt));
		connection.setFreespeed(100);
		connection.setCapacity(10000);
		return connection;

	}
}
