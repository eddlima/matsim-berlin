package org.matsim.prepare.transit;

import org.matsim.api.core.v01.Coord;
import org.matsim.api.core.v01.Id;
import org.matsim.api.core.v01.TransportMode;
import org.matsim.api.core.v01.network.Link;
import org.matsim.api.core.v01.network.NetworkFactory;
import org.matsim.api.core.v01.network.Node;
import org.matsim.core.config.ConfigUtils;
import org.matsim.core.network.NetworkUtils;
import org.matsim.core.population.routes.LinkNetworkRouteFactory;
import org.matsim.core.population.routes.NetworkRoute;
import org.matsim.core.population.routes.RouteUtils;
import org.matsim.core.scenario.ScenarioUtils;
import org.matsim.pt.transitSchedule.api.TransitScheduleFactory;
import org.matsim.pt.transitSchedule.api.TransitScheduleReader;
import org.matsim.pt.transitSchedule.api.TransitStopFacility;
import org.matsim.vehicles.MatsimVehicleReader;
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
//		var vehicleType = scenario.getTransitVehicles().getVehicleTypes().get(Id.create("S-Bahn_veh_type", VehicleType.class));

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
	}

	private static Link createLink(String id, Node from, Node to) {

		var connection = networkFactory.createLink(Id.createLinkId(id), from, to);
		connection.setAllowedModes(Set.of(TransportMode.pt));
		connection.setFreespeed(100);
		connection.setCapacity(10000);
		return connection;

	}
}
