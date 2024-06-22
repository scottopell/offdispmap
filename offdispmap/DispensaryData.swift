//
//  DispensaryData.swift
//  offdispmap
//
//  Created by Scott Opell on 6/22/24.
//

import Foundation
import CoreLocation

struct DispensaryData {
    static let shared = DispensaryData()
    
    private init() {}
    
    let dispensaryCoordinates: [String: CLLocationCoordinate2D] = [
        "248 W 125th St, New York, 10027": CLLocationCoordinate2D(latitude: 40.8093755, longitude: -73.9499686),
        "750 Broadway, New York, 10003": CLLocationCoordinate2D(latitude: 40.7302647, longitude: -73.9924238),
        "144 Bleecker St, New York, 10012": CLLocationCoordinate2D(latitude: 40.7279906, longitude: -73.999397),
        "75 Court St, Binghamton, 13901": CLLocationCoordinate2D(latitude: 42.0990775, longitude: -75.9117705),
        "835 Broadway, New York, 10003": CLLocationCoordinate2D(latitude: 40.7339509, longitude: -73.9913414),
        "119-121 E State St, Ithaca, 14850": CLLocationCoordinate2D(latitude: 42.4392963, longitude: -76.4982168),
        "162-03 Jamaica Ave, Jamaica, 11432": CLLocationCoordinate2D(latitude: 40.7046912, longitude: -73.7976965),
        "1613 Union St, Schenectady, 12309": CLLocationCoordinate2D(latitude: 42.805157, longitude: -73.9048017),
        "33 Union Sq. W, New York, 10003": CLLocationCoordinate2D(latitude: 40.7368592, longitude: -73.9909669),
        "1839 Central Ave, Albany, 12205": CLLocationCoordinate2D(latitude: 42.7317075, longitude: -73.8477502),
        "3 E 3rd St, New York, 10003": CLLocationCoordinate2D(latitude: 40.7263201, longitude: -73.9912626),
        "74-03 Metropolitan Ave, Middle Village, 11379": CLLocationCoordinate2D(latitude: 40.7130322, longitude: -73.8781372),
        "810C Broadway, Rensselaer, 12144": CLLocationCoordinate2D(latitude: 42.6463978, longitude: -73.7393645),
        "219 Walton St, Syracuse, 13202": CLLocationCoordinate2D(latitude: 43.0478532, longitude: -76.1563556),
        "4219 Webster Ave, Bronx, 10470": CLLocationCoordinate2D(latitude: 40.8961781, longitude: -73.8634463),
        "246 Main St, Johnson City, 13790": CLLocationCoordinate2D(latitude: 42.1150447, longitude: -75.9554141),
        "817 E Tremont Ave, Bronx, 10460": CLLocationCoordinate2D(latitude: 40.8436449, longitude: -73.8872736),
        "1815 Broadhollow Rd, Farmingdale, 11735": CLLocationCoordinate2D(latitude: 40.744887, longitude: -73.4215197),
        "1308 Vestal Pkwy E, 1st Floor, Set D, Vestal, 13850": CLLocationCoordinate2D(latitude: 42.0915125, longitude: -76.0284445),
        "501 Main St, Buffalo, 14203": CLLocationCoordinate2D(latitude: 42.8873835, longitude: -78.8734938),
        "6055 Transit Rd, Depew, 14043": CLLocationCoordinate2D(latitude: 42.9203589, longitude: -78.6963927),
        "76 Main St, Oneonta, 13820": CLLocationCoordinate2D(latitude: 42.4509974, longitude: -75.0636321),
        "1707 Oriskany St W, Utica, 13502": CLLocationCoordinate2D(latitude: 43.1103034, longitude: -75.2545671),
        "622 Lake Flower Ave, Ste 7, Saranac Lake, 12983": CLLocationCoordinate2D(latitude: 44.3107732, longitude: -74.1165951),
        "3610 Ditmars Blvd, Queens, 11105": CLLocationCoordinate2D(latitude: 40.7739502, longitude: -73.9080738),
        "85 Delancey St, New York, 10002": CLLocationCoordinate2D(latitude: 40.7186864, longitude: -73.9896793),
        "25 Market St, Potsdam, 13676": CLLocationCoordinate2D(latitude: 44.6693145, longitude: -74.9871779),
        "1297 Hertel Ave, Buffalo, 14216": CLLocationCoordinate2D(latitude: 42.9474922, longitude: -78.8600186),
        "997 Central Ave, Ste 200, Albany, 12205": CLLocationCoordinate2D(latitude: 42.6848522, longitude: -73.794863),
        "740 Hoosick Rd, Troy, 12180": CLLocationCoordinate2D(latitude: 42.7448036, longitude: -73.6416652),
        "1451 State Highway 5S, Amsterdam, 12010": CLLocationCoordinate2D(latitude: 42.9306058, longitude: -74.2080952),
        "900 Jefferson Rd, Ste 902, Rochester, 14623": CLLocationCoordinate2D(latitude: 43.0898457, longitude: -77.6130532),
        "2460 Williamsbridge Rd, Fl 1, Bronx, 10469": CLLocationCoordinate2D(latitude: 40.8623372, longitude: -73.8574428),
        "412 W Broadway, New York, 10012": CLLocationCoordinate2D(latitude: 40.7248919, longitude: -74.0018446),
        "7479 US Highway 11, Potsdam, 13676": CLLocationCoordinate2D(latitude: 44.6650826, longitude: -75.0300695),
        "127 S Terrace Ave, Mt Vernon, 10550": CLLocationCoordinate2D(latitude: 40.9093187, longitude: -73.8499992),
        "2370 Coney Island Ave, Brooklyn, 11223": CLLocationCoordinate2D(latitude: 40.5991362, longitude: -73.9616193),
        "4205 Long Branch Rd, Ste 5, Liverpool, 13090": CLLocationCoordinate2D(latitude: 43.130391, longitude: -76.2222838),
        "98 N Chestnut St, New Paltz, 12561": CLLocationCoordinate2D(latitude: 41.7547407, longitude: -74.0834931),
        "10 Executive Park Dr, Albany, 12203": CLLocationCoordinate2D(latitude: 42.6872346, longitude: -73.8422715),
        "105 Route 109, Farmingdale, 11735": CLLocationCoordinate2D(latitude: 40.7228715, longitude: -73.4241247),
        "1412 Lexington Ave, New York, 10128": CLLocationCoordinate2D(latitude: 40.7837447, longitude: -73.9526557),
        "1308 Dolsontown Rd, Ste 3 & 4, Wawayanda, 10940": CLLocationCoordinate2D(latitude: 41.4288995, longitude: -74.4036236),
        "2053 Electric Ave, Blasdell, 14219": CLLocationCoordinate2D(latitude: 42.8030185, longitude: -78.8294707),
        "334 E 73rd St, New York, 10021": CLLocationCoordinate2D(latitude: 40.7685785, longitude: -73.9563091),
        "158 W 23rd St, New York, 10011": CLLocationCoordinate2D(latitude: 40.7435479, longitude: -73.9950733),
        "556 Jefferson Rd, Rochester, 14623": CLLocationCoordinate2D(latitude: 43.0876331, longitude: -77.6303104),
        "3022 Veterans Rd W, Staten Island, 10309": CLLocationCoordinate2D(latitude: 40.5283085, longitude: -74.2359162),
        "8 North Plank Rd, Newburgh, 12550": CLLocationCoordinate2D(latitude: 41.5206751, longitude: -74.0223412),
        "1056 Flatbush Ave, Brooklyn, 11226": CLLocationCoordinate2D(latitude: 40.6451956, longitude: -73.9583595),
        "958 Sixth Ave, New York, 10001": CLLocationCoordinate2D(latitude: 40.7502722, longitude: -73.9871167),
        "248-09 Jericho Turnpike, Bellerose, 11426": CLLocationCoordinate2D(latitude: 40.7263762, longitude: -73.7179328),
        "31-35 Steinway St, Astoria, 11103": CLLocationCoordinate2D(latitude: 40.7602838, longitude: -73.9175813),
        "332 Northern Blvd, Albany, 12204": CLLocationCoordinate2D(latitude: 42.6740344, longitude: -73.7500819),
        "1686 Central Ave, Albany, 12205": CLLocationCoordinate2D(latitude: 42.7226519, longitude: -73.8390955),
        "90 Broadway, Spc 8, Menands, 12204": CLLocationCoordinate2D(latitude: 42.6828992, longitude: -73.7332388),
        "475 Central Ave, White Plains, 10606": CLLocationCoordinate2D(latitude: 41.0299585, longitude: -73.7885913),
        "779 State Route 3, Plattsburgh, 12901": CLLocationCoordinate2D(latitude: 44.6951538, longitude: -73.5232625),
        "30-30 Steinway St, Astoria, 11103": CLLocationCoordinate2D(latitude: 40.7632327, longitude: -73.9158871),
        "85 Suydam St, Brooklyn, 11221": CLLocationCoordinate2D(latitude: 40.6979017, longitude: -73.9293953),
        "75 Mamaroneck Ave, White Plains, 10601": CLLocationCoordinate2D(latitude: 41.0305423, longitude: -73.7654625),
        "44-45 Vernon Blvd, Long Island City, 11101": CLLocationCoordinate2D(latitude: 40.7492618, longitude: -73.9519966),
        "900 Niagara Falls Blvd, Buffalo, 14201": CLLocationCoordinate2D(latitude: 43.0571796, longitude: -78.8453205),
        "221-50 Horace Harding Expy, Bayside, 11364": CLLocationCoordinate2D(latitude: 40.7492871, longitude: -73.754958),
        "232 Allen St, Buffalo, 14201": CLLocationCoordinate2D(latitude: 42.8993346, longitude: -78.8787755),
        "255 Genesse St, Utica, 13501": CLLocationCoordinate2D(latitude: 43.0991399, longitude: -75.2348752),
        "1511 Neptune Ave, Brooklyn, 11224": CLLocationCoordinate2D(latitude: 40.579346, longitude: -73.9835535),
        "166-30 Jamaica Ave, Jamaica, 11432": CLLocationCoordinate2D(latitude: 40.7059747, longitude: -73.7929885),
        "665 North French Rd, Amherst, 14228": CLLocationCoordinate2D(latitude: 43.0343159, longitude: -78.8001234),
        "118 Flatbush Ave, Brooklyn, 11217": CLLocationCoordinate2D(latitude: 40.6851206, longitude: -73.9784706),
        "533 5th Ave, Brooklyn, 11215": CLLocationCoordinate2D(latitude: 40.6662016, longitude: -73.9885945),
        "1099 Loudon Rd, Cohoes, 12047": CLLocationCoordinate2D(latitude: 42.783871, longitude: -73.7435297),
        "4106 NY-31, Ste 903, Clay, 13041": CLLocationCoordinate2D(latitude: 43.184676, longitude: -76.2292607),
        "925 Hunts Point Ave, Bronx, 10459": CLLocationCoordinate2D(latitude: 40.8202713, longitude: -73.891392),
        "12 East 42nd St, New York, 10017": CLLocationCoordinate2D(latitude: 40.7531387, longitude: -73.9804815),
        "1115 1st Ave, New York, 10065": CLLocationCoordinate2D(latitude: 40.7611616, longitude: -73.961174),
        "27 B Saratoga Ave, Waterford, 12188": CLLocationCoordinate2D(latitude: 42.7812957, longitude: -73.6958471),
    ]
    
    // Function to get coordinate for a dispensary
    func getCoordinate(for dispensaryFullAddress: String) -> CLLocationCoordinate2D? {
        return dispensaryCoordinates[dispensaryFullAddress]
    }
    
    // List of NYC zip codes
    let nycZipCodes: Set<String> = [
        "10001", "10002", "10003", "10004", "10005", "10006", "10007", "10009",
        "10010", "10011", "10012", "10013", "10014", "10016", "10017", "10018",
        "10019", "10020", "10021", "10022", "10023", "10024", "10025", "10026",
        "10027", "10028", "10029", "10030", "10031", "10032", "10033", "10034",
        "10035", "10036", "10037", "10038", "10039", "10040", "10044", "10065",
        "10075", "10128", "10280", "10282", "11101", "11201", "11205", "11211",
        "11215", "11217", "11231"
    ]
}
