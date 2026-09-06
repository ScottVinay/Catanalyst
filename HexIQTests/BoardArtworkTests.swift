import SwiftUI
import XCTest
@testable import HexIQ

final class BoardArtworkTests: XCTestCase {
    @MainActor
    func testEveryTerrainAndBuildingImageIsBundled() throws {
        for terrain in Terrain.allCases {
            let image = try XCTUnwrap(UIImage(named: BoardArtwork.terrainName(terrain)))
            XCTAssertGreaterThan(image.size.width, 256)
            XCTAssertGreaterThan(image.size.height, 256)
        }
        for building in [Building.settlement, .city] {
            let image = try XCTUnwrap(UIImage(named: BoardArtwork.buildingName(building))?.cgImage)
            XCTAssertTrue([CGImageAlphaInfo.premultipliedLast, .premultipliedFirst, .last, .first].contains(image.alphaInfo))
            let pixels = rgbaPixels(image)
            XCTAssertEqual(pixels[3], 0, "Building cutouts need a transparent corner")
            XCTAssertGreaterThan(pixels[(image.height / 2 * image.width + image.width / 2) * 4 + 3], 240)
        }
    }

    @MainActor
    func testLongestRoadRingIsCentredInTheNumberColumn() throws {
        for players in [PlayerColor.defaultActive, PlayerColor.allCases] {
            let board = fixture(players: players)
            XCTAssertEqual(board.longestRoadHolder, .red)
            let renderer = ImageRenderer(content:
                BoardStatsBar(board: board, isExpanded: .constant(true))
                    .frame(width: 390, height: 144)
                    .background(.white)
                    .environment(\.colorScheme, .light)
            )
            renderer.scale = 2
            let image = try XCTUnwrap(renderer.uiImage)
            let cgImage = try XCTUnwrap(image.cgImage)
            let pixels = rgbaPixels(cgImage)
            // Search for the gold stroke in the first player's column only.
            let columnWidth = (390.0 - 128) / Double(players.count)
            let lowerX = Int(120 * renderer.scale)
            let upperX = Int((120 + columnWidth) * renderer.scale)
            var goldX: [Int] = []
            for y in 0..<cgImage.height {
                for x in lowerX..<upperX {
                    let i = (y * cgImage.width + x) * 4
                    if pixels[i] > 230, pixels[i + 1] > 160, pixels[i + 2] < 70, pixels[i + 3] > 230 {
                        goldX.append(x)
                    }
                }
            }
            XCTAssertGreaterThan(goldX.count, 100)
            let minX = try XCTUnwrap(goldX.min())
            let maxX = try XCTUnwrap(goldX.max())
            let ringCentre = Double(minX + maxX) / (2 * renderer.scale)
            XCTAssertEqual(ringCentre, 120 + columnWidth / 2, accuracy: 1)
            attach(image, name: "stats-ring-\(players.count)-players")
        }
    }

    @MainActor
    func testBoardArtworkReviewRendering() throws {
        let board = fixture(players: PlayerColor.allCases)
        for degrees in [0.0, 90.0] {
            let renderer = ImageRenderer(content:
                BoardEditorView(
                    board: board, isEditing: false, editTool: .terrain,
                    selectedPlayer: .red, presentationRotationDegrees: degrees
                )
                .frame(width: 390, height: 650)
                .environment(\.colorScheme, .light)
            )
            renderer.scale = 3
            attach(try XCTUnwrap(renderer.uiImage), name: "board-artwork-\(Int(degrees))")
        }
    }

    @MainActor
    private func fixture(players: [PlayerColor]) -> BoardState {
        var snapshot = BoardSnapshot.standard(activePlayers: players)
        snapshot.tiles = snapshot.tiles.enumerated().map { index, tile in
            let terrain = Terrain.allCases[index % Terrain.allCases.count]
            return HexTile(
                coordinate: tile.coordinate, terrain: terrain,
                number: terrain == .ocean || terrain == .desert ? nil : NumberToken.allCases[index % NumberToken.allCases.count]
            )
        }
        let redRoads = Array(BoardGeometry.edges(for: HexCoordinate(q: 0, r: -2)).prefix(5))
        let blueRoads = Array(BoardGeometry.edges(for: HexCoordinate(q: 0, r: 2)).prefix(5))
        snapshot.roads = Set(redRoads + blueRoads)
        snapshot.roadOwners = Dictionary(uniqueKeysWithValues:
            redRoads.map { ($0, PlayerColor.red) } + blueRoads.map { ($0, PlayerColor.blue) }
        )
        snapshot.longestRoadHolder = .red
        for (index, player) in players.enumerated() {
            let vertex = BoardGeometry.standardVertices[index * 8 + 2]
            snapshot.buildings[vertex] = index.isMultiple(of: 2) ? .settlement : .city
            snapshot.buildingOwners[vertex] = player
        }
        return BoardState(snapshot: snapshot)
    }

    private func rgbaPixels(_ image: CGImage) -> [UInt8] {
        var pixels = [UInt8](repeating: 0, count: image.width * image.height * 4)
        pixels.withUnsafeMutableBytes { bytes in
            let context = CGContext(
                data: bytes.baseAddress, width: image.width, height: image.height,
                bitsPerComponent: 8, bytesPerRow: image.width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )!
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        }
        return pixels
    }

    private func attach(_ image: UIImage, name: String) {
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
