package org.matsim.prepare.transit;

import org.matsim.api.core.v01.network.NetworkFactory;
import org.matsim.core.config.ConfigUtils;
import org.matsim.core.network.NetworkUtils;
import org.matsim.core.population.routes.LinkNetworkRouteFactory;
import org.matsim.core.scenario.ScenarioUtils;
import org.matsim.pt.transitSchedule.api.TransitScheduleFactory;
import org.matsim.pt.transitSchedule.api.TransitScheduleReader;
import org.matsim.vehicles.MatsimVehicleReader;

import java.nio.file.Paths;

public class AddSiemensbahn {

	private static LinkNetworkRouteFactory routeFactory = new LinkNetworkRouteFactory();
	private static NetworkFactory networkFactory = NetworkUtils.createNetwork().getFactory();
	private static TransitScheduleFactory scheduleFactory = ScenarioUtils.createScenario(ConfigUtils.createConfig()).getTransitSchedule().getFactory();

	public static void main(String[] args) {

		var root = Paths.get(".\\input");
		var scenario = ScenarioUtils.createScenario(ConfigUtils.createConfig());

		// read in existing files
		var transitSchedule = Paths.get(".\\input\\v6.4\\duesseldorf-v1.7-transitSchedule.xml.gz");
		var vehicleFile = Paths.get(".\\input\\v6.4\\duesseldorf-v1.7-transitVehicles.xml.gz");
		new TransitScheduleReader(scenario).readFile(transitSchedule.toString());
		var network = NetworkUtils.readNetwork(".\\input\\v6.4\\duesseldorf-v1.7-network-with-pt.xml.gz");

		MatsimVehicleReader vehicleReader = new MatsimVehicleReader(scenario.getTransitVehicles());
		vehicleReader.readFile(vehicleFile.toString());

	}
}
