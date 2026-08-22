import { describe, expect, it } from "vitest";
import { Chess } from "chess.js";

describe("chess engine rules", () => {
  it("rejects an illegal move that leaves the king exposed", () => {
    const game = new Chess("k3r3/8/8/8/8/8/4R3/4K3 w - - 0 1");
    expect(() => game.move({ from: "e2", to: "a2" })).toThrow();
  });

  it("detects a checkmate position", () => {
    const game = new Chess();
    game.move("f3");
    game.move("e5");
    game.move("g4");
    game.move("Qh4#");
    expect(game.isCheckmate()).toBe(true);
    expect(game.isGameOver()).toBe(true);
  });

  it("supports castling and promotion through the same rules authority", () => {
    const castle = new Chess("r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1");
    expect(castle.move({ from: "e1", to: "g1" }).san).toBe("O-O");

    const promotion = new Chess("4k3/P7/8/8/8/8/8/4K3 w - - 0 1");
    expect(promotion.move({ from: "a7", to: "a8", promotion: "q" }).promotion).toBe("q");
  });
});
