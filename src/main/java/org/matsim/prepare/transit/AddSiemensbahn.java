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
		var transitSchedule = Paths.get("..\\..\\..\\Nextcloud\\Masterarbeit\\berlin-v6.4-transitSchedule.xml.gz");
		var vehicleFile = Paths.get("..\\..\\..\\Nextcloud\\Masterarbeit\\berlin-v6.4-transitVehicles.xml.gz");
		new TransitScheduleReader(scenario).readFile(transitSchedule.toString());
		var network = NetworkUtils.readNetwork("..\\..\\..\\Nextcloud\\Masterarbeit\\berlin-v6.4-network.xml.gz");

		MatsimVehicleReader vehicleReader = new MatsimVehicleReader(scenario.getTransitVehicles());
		vehicleReader.readFile(vehicleFile.toString());

		// vehicle type
		var vehicleType = scenario.getTransitVehicles().getVehicleTypes().get(Id.create("S-Bahn_veh_type", VehicleType.class));

		//start and end Siemensbahn (SiBa) and add to network
		var siba_start = network.getFactory().createNode(Id.createNodeId("siba-start"), new Coord( 389411.28 + 100, 5820691.34 + 100));
		var siba_end = network.getFactory().createNode(Id.createNodeId("siba-end"), new Coord(381245.78 + 100, 5823326.58 + 100));
		network.addNode(siba_start);
		network.addNode(siba_end);
//		QUESTION: should I use the IDs from GTFS? And what should I write for the new ones?
		var Hauptbahnhof = network.getNodes().get(Id.createNodeId("398459"));
		var PerlebergerBruecke = network.getNodes().get(Id.createNodeId(""));
		var Westhafen = network.getNodes().get(Id.createNodeId("182339"));
		var Beusselstrasse = network.getNodes().get(Id.createNodeId("663500"));
		var Jungfernheide = network.getNodes().get(Id.createNodeId("507624"));
		var Wernerwerk  = network.getNodes().get(Id.createNodeId(""));
		var Siemensstadt = network.getNodes().get(Id.createNodeId(""));
		var Gartenfeld = network.getNodes().get(Id.createNodeId(""));

		// SiBa link e > w
		var start_link_e_w = createLink("SiBa_start_ow", siba_start, Hauptbahnhof);
		var cl_ew_1 = createLink("SiBa_1_ow", Hauptbahnhof, PerlebergerBruecke);
		var cl_ew_2 = createLink("SiBa_2_ow", PerlebergerBruecke, Westhafen);
		var cl_ew_3 = createLink("SiBa_3_ow", Westhafen, Beusselstrasse);
		var cl_ew_4 = createLink("SiBa_4_ow", Beusselstrasse, Jungfernheide);
		var cl_ew_5 = createLink("SiBa_5_ow", Jungfernheide, Wernerwerk);
		var cl_ew_6 = createLink("SiBa_6_ow", Wernerwerk, Siemensstadt);
		var cl_ew_7 = createLink("SiBa_7_ow", Siemensstadt, Gartenfeld);
		var end_link_e_w = createLink("SiBa_end_ow", Gartenfeld, siba_end);
		network.addLink(start_link_e_w);
		network.addLink(cl_ew_1);
		network.addLink(cl_ew_2);
		network.addLink(cl_ew_3);
		network.addLink(cl_ew_4);
		network.addLink(cl_ew_5);
		network.addLink(cl_ew_6);
		network.addLink(cl_ew_7);
		network.addLink(end_link_e_w);

		// SiBa link w > e
		var start_link_w_e = createLink("SiBa_start_ow", siba_end, Gartenfeld);
		var cl_we_1 = createLink("SiBa_1_ow", Gartenfeld, Siemensstadt);
		var cl_we_2 = createLink("SiBa_2_ow", Siemensstadt, Wernerwerk);
		var cl_we_3 = createLink("SiBa_3_ow", Wernerwerk, Jungfernheide);
		var cl_we_4 = createLink("SiBa_4_ow", Jungfernheide, Beusselstrasse);
		var cl_we_5 = createLink("SiBa_5_ow", Beusselstrasse, Westhafen);
		var cl_we_6 = createLink("SiBa_6_ow", Westhafen, PerlebergerBruecke);
		var cl_we_7 = createLink("SiBa_7_ow", PerlebergerBruecke, Hauptbahnhof);
		var end_link_w_e = createLink("SiBa_end_ow", Hauptbahnhof, siba_start);
		network.addLink(start_link_w_e);
		network.addLink(cl_we_1);
		network.addLink(cl_we_2);
		network.addLink(cl_we_3);
		network.addLink(cl_we_4);
		network.addLink(cl_we_5);
		network.addLink(cl_we_6);
		network.addLink(cl_we_7);
		network.addLink(end_link_w_e);

		// network route e > w and w > e
		NetworkRoute networkRoute_e_w = RouteUtils.createLinkNetworkRouteImpl(start_link_e_w.getId(),
				List.of(cl_ew_1.getId(),cl_ew_2.getId(),cl_ew_3.getId(),cl_ew_4.getId(),cl_ew_5.getId(),cl_ew_6.getId(),
						cl_ew_7.getId()),end_link_e_w.getId());

		NetworkRoute networkRoute_w_e = RouteUtils.createLinkNetworkRouteImpl(start_link_w_e.getId(),
				List.of(cl_we_1.getId(),cl_we_2.getId(),cl_we_3.getId(),cl_we_4.getId(),cl_we_5.getId(),cl_we_6.getId(),
						cl_we_7.getId()),end_link_w_e.getId());

		// facilities e > w
		var stop1_facility_e_w = scheduleFactory.createTransitStopFacility(Id.create("Hauptbahnhof_ew", TransitStopFacility.class),siba_start.getCoord(),false);
		var stop2_facility_e_w = scheduleFactory.createTransitStopFacility(Id.create("PerlebergerBruecke_ew", TransitStopFacility.class),PerlebergerBruecke.getCoord(),false);
		var stop3_facility_e_w = scheduleFactory.createTransitStopFacility(Id.create("Westhafen_ew", TransitStopFacility.class),Westhafen.getCoord(),false);
		var stop4_facility_e_w = scheduleFactory.createTransitStopFacility(Id.create("Beusselstrasse_ew", TransitStopFacility.class),Beusselstrasse.getCoord(),false);
		var stop5_facility_e_w = scheduleFactory.createTransitStopFacility(Id.create("Jungfernheide_ew", TransitStopFacility.class),Jungfernheide.getCoord(),false);
		var stop6_facility_e_w = scheduleFactory.createTransitStopFacility(Id.create("Wernerwerk_ew", TransitStopFacility.class),Wernerwerk.getCoord(),false);
		var stop7_facility_e_w = scheduleFactory.createTransitStopFacility(Id.create("Siemensstadt_ew", TransitStopFacility.class),Siemensstadt.getCoord(),false);
		var stop8_facility_e_w = scheduleFactory.createTransitStopFacility(Id.create("Gartenfeld_ew", TransitStopFacility.class),Gartenfeld.getCoord(),false);
		stop1_facility_e_w.setLinkId(start_link_e_w.getId());
		stop2_facility_e_w.setLinkId(cl_ew_1.getId());
		stop3_facility_e_w.setLinkId(cl_ew_2.getId());
		stop4_facility_e_w.setLinkId(cl_ew_3.getId());
		stop5_facility_e_w.setLinkId(cl_ew_4.getId());
		stop6_facility_e_w.setLinkId(cl_ew_5.getId());
		stop7_facility_e_w.setLinkId(cl_ew_6.getId());
		stop8_facility_e_w.setLinkId(cl_ew_7.getId());
//		QUESTION: Is it right not to use end_link_e_w in this case? Think so...
		scenario.getTransitSchedule().addStopFacility(stop1_facility_e_w);
		scenario.getTransitSchedule().addStopFacility(stop2_facility_e_w);
		scenario.getTransitSchedule().addStopFacility(stop3_facility_e_w);
		scenario.getTransitSchedule().addStopFacility(stop4_facility_e_w);
		scenario.getTransitSchedule().addStopFacility(stop5_facility_e_w);
		scenario.getTransitSchedule().addStopFacility(stop6_facility_e_w);
		scenario.getTransitSchedule().addStopFacility(stop7_facility_e_w);
		scenario.getTransitSchedule().addStopFacility(stop8_facility_e_w);

		// facilities w > e
		var stop1_facility_w_e = scheduleFactory.createTransitStopFacility(Id.create("Gartenfeld_we", TransitStopFacility.class),siba_end.getCoord(),false);
		var stop2_facility_w_e = scheduleFactory.createTransitStopFacility(Id.create("Siemensstadt_we", TransitStopFacility.class),Siemensstadt.getCoord(),false);
		var stop3_facility_w_e = scheduleFactory.createTransitStopFacility(Id.create("Wernerwerk_we", TransitStopFacility.class),Wernerwerk.getCoord(),false);
		var stop4_facility_w_e = scheduleFactory.createTransitStopFacility(Id.create("Jungfernheide_we", TransitStopFacility.class),Jungfernheide.getCoord(),false);
		var stop5_facility_w_e = scheduleFactory.createTransitStopFacility(Id.create("Beusselstrasse_we", TransitStopFacility.class),Beusselstrasse.getCoord(),false);
		var stop6_facility_w_e = scheduleFactory.createTransitStopFacility(Id.create("Westhafen_we", TransitStopFacility.class),Westhafen.getCoord(),false);
		var stop7_facility_w_e = scheduleFactory.createTransitStopFacility(Id.create("PerlebergerBruecke_we", TransitStopFacility.class),PerlebergerBruecke.getCoord(),false);
		var stop8_facility_w_e = scheduleFactory.createTransitStopFacility(Id.create("Hauptbahnhof_we", TransitStopFacility.class),Hauptbahnhof.getCoord(),false);
		stop1_facility_w_e.setLinkId(start_link_w_e.getId());
		stop2_facility_w_e.setLinkId(cl_we_1.getId());
		stop3_facility_w_e.setLinkId(cl_we_2.getId());
		stop4_facility_w_e.setLinkId(cl_we_3.getId());
		stop5_facility_w_e.setLinkId(cl_we_4.getId());
		stop6_facility_w_e.setLinkId(cl_we_5.getId());
		stop7_facility_w_e.setLinkId(cl_we_6.getId());
		stop8_facility_w_e.setLinkId(cl_we_7.getId());
//		QUESTION: Is it right not to use end_link_w_e in this case? Think so...
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
		var route_e_w = scheduleFactory.createTransitRoute(Id.create("SiBa_ew", TransitRoute.class),
				networkRoute_e_w,List.of(stop1_e_w,stop2_e_w,stop3_e_w,stop4_e_w,stop5_e_w,stop6_e_w,stop7_e_w,stop8_e_w),"pt");
		var route_w_e = scheduleFactory.createTransitRoute(Id.create("SiBa_we", TransitRoute.class),
				networkRoute_w_e,List.of(stop1_w_e,stop2_w_e,stop3_w_e,stop4_w_e,stop5_w_e,stop6_w_e,stop7_w_e,stop8_w_e),"pt");

		// create departures and vehicles for each departure E > W
		for (int i = 3 * 3600; i < 24 * 3600; i += 1200) {
			var departure = scheduleFactory.createDeparture(Id.create("departure_" + i, Departure.class), i);
			var vehicle = scenario.getTransitVehicles().getFactory().createVehicle(Id.createVehicleId("SiBa_vehicle_ew_" + "100"+i), vehicleType);
			departure.setVehicleId(vehicle.getId());

			scenario.getTransitVehicles().addVehicle(vehicle);
			route_e_w.addDeparture(departure);
		}

		// create departures and vehicles for each departure W > E
		for (int i = 3 * 3600; i < 24 * 3600; i += 1200) {
			var departure = scheduleFactory.createDeparture(Id.create("departure_" + i, Departure.class), i);
			var vehicle = scenario.getTransitVehicles().getFactory().createVehicle(Id.createVehicleId("SiBa_vehicle_we_" + "100" + i), vehicleType);
			departure.setVehicleId(vehicle.getId());

			scenario.getTransitVehicles().addVehicle(vehicle);
			route_w_e.addDeparture(departure);
		}

		// line E > W
		var line_e_w = scheduleFactory.createTransitLine(Id.create("SiBa_ew", TransitLine.class));
		line_e_w.addRoute(route_e_w);
		scenario.getTransitSchedule().addTransitLine(line_e_w);

		// line W > E
		var line_w_e = scheduleFactory.createTransitLine(Id.create("SiBa_we", TransitLine.class));
		line_w_e.addRoute(route_w_e);
		scenario.getTransitSchedule().addTransitLine(line_w_e);

		new NetworkWriter(network).write(root.resolve("network-with-SiBa-20min.xml.gz").toString());
		new TransitScheduleWriter(scenario.getTransitSchedule()).writeFile(root.resolve("transit-Schedule-SiBa-20min.xml.gz").toString());
		new MatsimVehicleWriter(scenario.getTransitVehicles()).writeFile(root.resolve("transit-vehicles-SiBa-20min.xml.gz").toString());
	}

	private static Link createLink(String id, Node from, Node to) {

		var connection = networkFactory.createLink(Id.createLinkId(id), from, to);
		connection.setAllowedModes(Set.of(TransportMode.pt));
		connection.setFreespeed(100);
		connection.setCapacity(10000);
		return connection;

	}
}
