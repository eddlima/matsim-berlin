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

import java.nio.file.Paths;
import java.util.List;
import java.util.Set;

public class AddSiemensbahn {

	private static LinkNetworkRouteFactory routeFactory = new LinkNetworkRouteFactory();
	private static NetworkFactory networkFactory = NetworkUtils.createNetwork().getFactory();
	private static TransitScheduleFactory scheduleFactory = ScenarioUtils.createScenario(ConfigUtils.createConfig()).getTransitSchedule().getFactory();

	public static void main(String[] args) {

		var root = Paths.get(".\\input");
		var scenario = ScenarioUtils.createScenario(ConfigUtils.createConfig());

		// read in existing files
		var transitSchedule = Paths.get("https://svn.vsp.tu-berlin.de/repos/public-svn/matsim/scenarios/countries/de/berlin/berlin-v6.4/input/berlin-v6.4-transitSchedule.xml.gz");
		var vehicleFile = Paths.get("https://svn.vsp.tu-berlin.de/repos/public-svn/matsim/scenarios/countries/de/berlin/berlin-v6.4/input/berlin-v6.4-transitVehicles.xml.gz");
		new TransitScheduleReader(scenario).readFile(transitSchedule.toString());
		var network = NetworkUtils.readNetwork("https://svn.vsp.tu-berlin.de/repos/public-svn/matsim/scenarios/countries/de/berlin/berlin-v6.4/input/berlin-v6.4-network-with-pt.xml.gz");

		MatsimVehicleReader vehicleReader = new MatsimVehicleReader(scenario.getTransitVehicles());
		vehicleReader.readFile(vehicleFile.toString());

		// vehicle type
		var vehicleType = scenario.getTransitVehicles().getVehicleTypes().get(Id.create("S-Bahn_veh_type", VehicleType.class));

		// add new stations (nodes) Siemensbahn to network and get existing stations
		var PerlebergerBruecke = network.getFactory().createNode(Id.createNodeId("pt_116410_SuburbanRailway"), new Coord( 388719.90, 5821943.81));
		var Wernerwerk = network.getFactory().createNode(Id.createNodeId("pt_116420_SuburbanRailway"), new Coord(383071.58, 5821884.16));
		var Siemensstadt = network.getFactory().createNode(Id.createNodeId("pt_116430_SuburbanRailway"), new Coord(382239.50, 5822435.20));
		var Gartenfeld = network.getFactory().createNode(Id.createNodeId("pt_116440_SuburbanRailway"), new Coord(381269.04, 5823306.29));
		network.addNode(PerlebergerBruecke);
		network.addNode(Wernerwerk);
		network.addNode(Siemensstadt);
		network.addNode(Gartenfeld);
		var Hauptbahnhof = network.getNodes().get(Id.createNodeId("pt_359974_SuburbanRailway"));
		var Westhafen = network.getNodes().get(Id.createNodeId("pt_473821_SuburbanRailway"));
		var Beusselstrasse = network.getNodes().get(Id.createNodeId("pt_502749_SuburbanRailway"));
		var Jungfernheide = network.getNodes().get(Id.createNodeId("pt_397108_SuburbanRailway"));

		// create new links Siemensbahn and get existing links
		var Hauptbahnhof_PerlebergerBruecke = createLink("pt_359974_SuburbanRailway-pt_116410_SuburbanRailway", Hauptbahnhof, PerlebergerBruecke);
		var PerlebergerBruecke_Hauptbahnhof = createLink("pt_116410_SuburbanRailway-pt_359974_SuburbanRailway", PerlebergerBruecke, Hauptbahnhof);
		var PerlebergerBruecke_Westhafen = createLink("pt_116410_SuburbanRailway-pt_473821_SuburbanRailway", PerlebergerBruecke, Westhafen);
		var Westhafen_PerlebergerBruecke = createLink("pt_473821_SuburbanRailway-pt_116410_SuburbanRailway", Westhafen, PerlebergerBruecke);
		var Jungfernheide_Wernerwerk = createLink("pt_397108_SuburbanRailway-pt_116420_SuburbanRailway", Jungfernheide, Wernerwerk);
		var Wernerwerk_Jungfernheide = createLink("pt_116420_SuburbanRailway-pt_397108_SuburbanRailway", Wernerwerk, Jungfernheide);
		var Wernerwerk_Siemensstadt = createLink("pt_116420_SuburbanRailway-pt_116430_SuburbanRailway", Wernerwerk, Siemensstadt);
		var Siemensstadt_Wernerwerk = createLink("pt_116430_SuburbanRailway-pt_116420_SuburbanRailway", Siemensstadt, Wernerwerk);
		var Siemensstadt_Gartenfeld = createLink("pt_116430_SuburbanRailway-pt_116440_SuburbanRailway", Siemensstadt, Gartenfeld);
		var Gartenfeld_Siemensstadt = createLink("pt_116440_SuburbanRailway-pt_116430_SuburbanRailway", Gartenfeld, Siemensstadt);
		network.addLink(Hauptbahnhof_PerlebergerBruecke);
		network.addLink(PerlebergerBruecke_Hauptbahnhof);
		network.addLink(PerlebergerBruecke_Westhafen);
		network.addLink(Westhafen_PerlebergerBruecke);
		network.addLink(Jungfernheide_Wernerwerk);
		network.addLink(Wernerwerk_Jungfernheide);
		network.addLink(Wernerwerk_Siemensstadt);
		network.addLink(Siemensstadt_Wernerwerk);
		network.addLink(Siemensstadt_Gartenfeld);
		network.addLink(Gartenfeld_Siemensstadt);
		var Westhafen_Beusselstrasse = network.getLinks().get(Id.createLinkId("pt_473821_SuburbanRailway-pt_502749_SuburbanRailway"));
		var Beusselstrasse_Westhafen = network.getLinks().get(Id.createLinkId("pt_502749_SuburbanRailway-pt_473821_SuburbanRailway"));
		var Beusselstrasse_Jungfernheide = network.getLinks().get(Id.createLinkId("pt_502749_SuburbanRailway-pt_397108_SuburbanRailway"));
		var Jungfernheide_Beusselstrasse = network.getLinks().get(Id.createLinkId("pt_397108_SuburbanRailway-pt_502749_SuburbanRailway"));

		// create lace links and get existing lace links
		var station_PerlebergerBruecke = createLink("pt_116410_SuburbanRailway", PerlebergerBruecke, PerlebergerBruecke);
		var station_Wernerwerk = createLink("pt_116420_SuburbanRailway", Wernerwerk, Wernerwerk);
		var station_Siemensstadt = createLink("pt_116430_SuburbanRailway", Siemensstadt, Siemensstadt);
		var station_Gartenfeld = createLink("pt_116440_SuburbanRailway", Gartenfeld, Gartenfeld);
		network.addLink(station_PerlebergerBruecke);
		network.addLink(station_Wernerwerk);
		network.addLink(station_Siemensstadt);
		network.addLink(station_Gartenfeld);
		var station_Hauptbahnhof = network.getLinks().get(Id.createLinkId("pt_359974_SuburbanRailway"));
		var station_Westhafen = network.getLinks().get(Id.createLinkId("pt_473821_SuburbanRailway"));
		var station_Beusselstrasse = network.getLinks().get(Id.createLinkId("pt_502749_SuburbanRailway"));
		var station_Jungfernheide = network.getLinks().get(Id.createLinkId("pt_397108_SuburbanRailway"));

		// network route e > w and w > e
		NetworkRoute networkRoute_e_w = RouteUtils.createLinkNetworkRouteImpl(station_Hauptbahnhof.getId(),
				List.of(Hauptbahnhof_PerlebergerBruecke.getId(),station_PerlebergerBruecke.getId(),PerlebergerBruecke_Westhafen.getId(),station_Westhafen.getId(),Westhafen_Beusselstrasse.getId(),station_Beusselstrasse.getId(),
						Beusselstrasse_Jungfernheide.getId(),station_Jungfernheide.getId(),Jungfernheide_Wernerwerk.getId(),station_Wernerwerk.getId(),Wernerwerk_Siemensstadt.getId(),station_Siemensstadt.getId(),Siemensstadt_Gartenfeld.getId()),station_Gartenfeld.getId());

		NetworkRoute networkRoute_w_e = RouteUtils.createLinkNetworkRouteImpl(station_Gartenfeld.getId(),
				List.of(Gartenfeld_Siemensstadt.getId(),station_Siemensstadt.getId(),Siemensstadt_Wernerwerk.getId(),station_Wernerwerk.getId(),Wernerwerk_Jungfernheide.getId(),station_Jungfernheide.getId(),
						Jungfernheide_Beusselstrasse.getId(),station_Beusselstrasse.getId(),Beusselstrasse_Westhafen.getId(),station_Westhafen.getId(),Westhafen_PerlebergerBruecke.getId(),station_PerlebergerBruecke.getId(),PerlebergerBruecke_Hauptbahnhof.getId()),station_Hauptbahnhof.getId());

		// facilities e > w
		var stop1_facility_e_w = scheduleFactory.createTransitStopFacility(Id.create("Hauptbahnhof_e_w", TransitStopFacility.class),Hauptbahnhof.getCoord(),false);
		var stop2_facility_e_w = scheduleFactory.createTransitStopFacility(Id.create("PerlebergerBruecke_e_w", TransitStopFacility.class),PerlebergerBruecke.getCoord(),false);
		var stop3_facility_e_w = scheduleFactory.createTransitStopFacility(Id.create("Westhafen_e_w", TransitStopFacility.class),Westhafen.getCoord(),false);
		var stop4_facility_e_w = scheduleFactory.createTransitStopFacility(Id.create("Beusselstrasse_e_w", TransitStopFacility.class),Beusselstrasse.getCoord(),false);
		var stop5_facility_e_w = scheduleFactory.createTransitStopFacility(Id.create("Jungfernheide_e_w", TransitStopFacility.class),Jungfernheide.getCoord(),false);
		var stop6_facility_e_w = scheduleFactory.createTransitStopFacility(Id.create("Wernerwerk_e_w", TransitStopFacility.class),Wernerwerk.getCoord(),false);
		var stop7_facility_e_w = scheduleFactory.createTransitStopFacility(Id.create("Siemensstadt_e_w", TransitStopFacility.class),Siemensstadt.getCoord(),false);
		var stop8_facility_e_w = scheduleFactory.createTransitStopFacility(Id.create("Gartenfeld_e_w", TransitStopFacility.class),Gartenfeld.getCoord(),false);
		stop1_facility_e_w.setLinkId(station_Hauptbahnhof.getId());
		stop2_facility_e_w.setLinkId(station_PerlebergerBruecke.getId());
		stop3_facility_e_w.setLinkId(station_Westhafen.getId());
		stop4_facility_e_w.setLinkId(station_Beusselstrasse.getId());
		stop5_facility_e_w.setLinkId(station_Jungfernheide.getId());
		stop6_facility_e_w.setLinkId(station_Wernerwerk.getId());
		stop7_facility_e_w.setLinkId(station_Siemensstadt.getId());
		stop8_facility_e_w.setLinkId(station_Gartenfeld.getId());
		scenario.getTransitSchedule().addStopFacility(stop1_facility_e_w);
		scenario.getTransitSchedule().addStopFacility(stop2_facility_e_w);
		scenario.getTransitSchedule().addStopFacility(stop3_facility_e_w);
		scenario.getTransitSchedule().addStopFacility(stop4_facility_e_w);
		scenario.getTransitSchedule().addStopFacility(stop5_facility_e_w);
		scenario.getTransitSchedule().addStopFacility(stop6_facility_e_w);
		scenario.getTransitSchedule().addStopFacility(stop7_facility_e_w);
		scenario.getTransitSchedule().addStopFacility(stop8_facility_e_w);

		// facilities w > e
		var stop1_facility_w_e = scheduleFactory.createTransitStopFacility(Id.create("Gartenfeld_w_e", TransitStopFacility.class),Gartenfeld.getCoord(),false);
		var stop2_facility_w_e = scheduleFactory.createTransitStopFacility(Id.create("Siemensstadt_w_e", TransitStopFacility.class),Siemensstadt.getCoord(),false);
		var stop3_facility_w_e = scheduleFactory.createTransitStopFacility(Id.create("Wernerwerk_w_e", TransitStopFacility.class),Wernerwerk.getCoord(),false);
		var stop4_facility_w_e = scheduleFactory.createTransitStopFacility(Id.create("Jungfernheide_w_e", TransitStopFacility.class),Jungfernheide.getCoord(),false);
		var stop5_facility_w_e = scheduleFactory.createTransitStopFacility(Id.create("Beusselstrasse_w_e", TransitStopFacility.class),Beusselstrasse.getCoord(),false);
		var stop6_facility_w_e = scheduleFactory.createTransitStopFacility(Id.create("Westhafen_w_e", TransitStopFacility.class),Westhafen.getCoord(),false);
		var stop7_facility_w_e = scheduleFactory.createTransitStopFacility(Id.create("PerlebergerBruecke_w_e", TransitStopFacility.class),PerlebergerBruecke.getCoord(),false);
		var stop8_facility_w_e = scheduleFactory.createTransitStopFacility(Id.create("Hauptbahnhof_w_e", TransitStopFacility.class),Hauptbahnhof.getCoord(),false);
		stop1_facility_w_e.setLinkId(station_Gartenfeld.getId());
		stop2_facility_w_e.setLinkId(station_Siemensstadt.getId());
		stop3_facility_w_e.setLinkId(station_Wernerwerk.getId());
		stop4_facility_w_e.setLinkId(station_Jungfernheide.getId());
		stop5_facility_w_e.setLinkId(station_Beusselstrasse.getId());
		stop6_facility_w_e.setLinkId(station_Westhafen.getId());
		stop7_facility_w_e.setLinkId(station_PerlebergerBruecke.getId());
		stop8_facility_w_e.setLinkId(station_Hauptbahnhof.getId());
		scenario.getTransitSchedule().addStopFacility(stop1_facility_w_e);
		scenario.getTransitSchedule().addStopFacility(stop2_facility_w_e);
		scenario.getTransitSchedule().addStopFacility(stop3_facility_w_e);
		scenario.getTransitSchedule().addStopFacility(stop4_facility_w_e);
		scenario.getTransitSchedule().addStopFacility(stop5_facility_w_e);
		scenario.getTransitSchedule().addStopFacility(stop6_facility_w_e);
		scenario.getTransitSchedule().addStopFacility(stop7_facility_w_e);
		scenario.getTransitSchedule().addStopFacility(stop8_facility_w_e);

		// stations e > w
		var stop1_e_w=scheduleFactory.createTransitRouteStop(stop1_facility_e_w,0,0);
		var stop2_e_w=scheduleFactory.createTransitRouteStop(stop2_facility_e_w,100,130);
		var stop3_e_w=scheduleFactory.createTransitRouteStop(stop3_facility_e_w,197,227);
		var stop4_e_w=scheduleFactory.createTransitRouteStop(stop4_facility_e_w,298,328);
		var stop5_e_w=scheduleFactory.createTransitRouteStop(stop5_facility_e_w,459,489);
		var stop6_e_w=scheduleFactory.createTransitRouteStop(stop6_facility_e_w,631,661);
		var stop7_e_w=scheduleFactory.createTransitRouteStop(stop7_facility_e_w,735,765);
		var stop8_e_w=scheduleFactory.createTransitRouteStop(stop8_facility_e_w,855,885);

		// stations w > e
		var stop1_w_e=scheduleFactory.createTransitRouteStop(stop1_facility_w_e,0,0);
		var stop2_w_e=scheduleFactory.createTransitRouteStop(stop2_facility_w_e,90,120);
		var stop3_w_e=scheduleFactory.createTransitRouteStop(stop3_facility_w_e,194,224);
		var stop4_w_e=scheduleFactory.createTransitRouteStop(stop4_facility_w_e,366,396);
		var stop5_w_e=scheduleFactory.createTransitRouteStop(stop5_facility_w_e,527,557);
		var stop6_w_e=scheduleFactory.createTransitRouteStop(stop6_facility_w_e,628,658);
		var stop7_w_e=scheduleFactory.createTransitRouteStop(stop7_facility_w_e,725,755);
		var stop8_w_e=scheduleFactory.createTransitRouteStop(stop8_facility_w_e,855,885);

		//route
		var route_e_w = scheduleFactory.createTransitRoute(Id.create("SiBa_e_w", TransitRoute.class),
				networkRoute_e_w,List.of(stop1_e_w,stop2_e_w,stop3_e_w,stop4_e_w,stop5_e_w,stop6_e_w,stop7_e_w,stop8_e_w),"pt");
		var route_w_e = scheduleFactory.createTransitRoute(Id.create("SiBa_w_e", TransitRoute.class),
				networkRoute_w_e,List.of(stop1_w_e,stop2_w_e,stop3_w_e,stop4_w_e,stop5_w_e,stop6_w_e,stop7_w_e,stop8_w_e),"pt");

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

		new NetworkWriter(network).write(root.resolve("berlin-v6.4-network-with-SiBa-10min.xml.gz").toString());
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
