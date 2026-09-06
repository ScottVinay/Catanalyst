import SwiftUI

enum BoardArtwork {
    // 0 shows only the plain terrain colour; 1 shows the full illustration.
    static let terrainOpacity: Double = 0.45 // # terrainalpha

    static func terrainName(_ terrain: Terrain) -> String {
        "Terrain-\(terrain.rawValue)"
    }

    static func buildingName(_ building: Building) -> String {
        "Building-\(building.rawValue)"
    }
}
