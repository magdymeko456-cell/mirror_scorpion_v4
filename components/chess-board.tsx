import { useEffect, useRef, useState } from "react";
import { GLView, type ExpoWebGLRenderingContext } from "expo-gl";
import { Platform, Pressable, StyleSheet, Text, View } from "react-native";
import * as Haptics from "expo-haptics";
import { Chess, type Square } from "chess.js";
import * as THREE from "three";
import { Renderer } from "expo-three";

type Side = "white" | "black";
type GameMode = "engine" | "local";
type Snapshot = {
  fen: string;
  turn: Side;
  lastMove: string;
  moveHistory: string[];
  whiteSeconds: number;
  blackSeconds: number;
  capturedCount: number;
};

type BoardPiece = {
  square: string;
  type: "p" | "n" | "b" | "r" | "q" | "k";
  color: "w" | "b";
};

const clockPresets = [1, 3, 5, 10];
const files = ["a", "b", "c", "d", "e", "f", "g", "h"];
const glyphs: Record<"w" | "b", Record<BoardPiece["type"], string>> = {
  w: { k: "♔", q: "♕", r: "♖", b: "♗", n: "♘", p: "♙" },
  b: { k: "♚", q: "♛", r: "♜", b: "♝", n: "♞", p: "♟" },
};
const pieceNames: Record<BoardPiece["type"], string> = {
  k: "ملك",
  q: "وزير",
  r: "قلعة",
  b: "فيل",
  n: "حصان",
  p: "بيدق",
};

function formatClock(seconds: number) {
  const minutes = Math.floor(seconds / 60).toString().padStart(2, "0");
  const remainder = (seconds % 60).toString().padStart(2, "0");
  return `${minutes}:${remainder}`;
}

function squareName(row: number, col: number) {
  return `${files[col]}${8 - row}`;
}

function sideLabel(side: Side) {
  return side === "white" ? "الأبيض" : "الأسود";
}

const pieceValues: Record<BoardPiece["type"], number> = { p: 100, n: 320, b: 330, r: 500, q: 900, k: 20000 };

function engineScore(game: Chess) {
  let score = 0;
  game.board().forEach((row) => row.forEach((piece) => {
    if (!piece) return;
    score += (piece.color === "w" ? 1 : -1) * pieceValues[piece.type];
  }));
  if (game.isCheckmate()) return game.turn() === "w" ? -100000 : 100000;
  return score;
}

function pickEngineMove(game: Chess) {
  const moves = game.moves({ verbose: true });
  let bestMove = moves[0];
  let bestScore = Number.POSITIVE_INFINITY;
  moves.forEach((move) => {
    const candidate = new Chess(game.fen());
    candidate.move({ from: move.from, to: move.to, promotion: "q" });
    let score = engineScore(candidate);
    if (candidate.isCheck()) score -= 10;
    if (score < bestScore) {
      bestMove = move;
      bestScore = score;
    }
  });
  return bestMove;
}

function mapBoard(board: ReturnType<Chess["board"]>): (BoardPiece | null)[][] {
  return board.map((row) => row.map((piece) => (piece ? { square: piece.square, type: piece.type, color: piece.color } : null)));
}

function chessPieceName(piece: BoardPiece) {
  return `${piece.color === "w" ? "الأبيض" : "الأسود"} ${pieceNames[piece.type]}`;
}

function Chess3DScene({ board, positionKey }: { board: (BoardPiece | null)[][]; positionKey: string }) {
  const disposed = useRef(false);

  useEffect(() => () => {
    disposed.current = true;
  }, []);

  const createPiece = (piece: BoardPiece, scene: THREE.Scene, x: number, z: number) => {
    const material = new THREE.MeshStandardMaterial({
      color: piece.color === "w" ? 0xeff8ff : 0x121b31,
      metalness: 0.55,
      roughness: 0.24,
    });
    const accent = new THREE.MeshStandardMaterial({ color: piece.color === "w" ? 0x9deaff : 0x5e83a4, metalness: 0.7, roughness: 0.22 });
    const group = new THREE.Group();
    group.position.set(x, 0.35, z);

    const add = (geometry: THREE.BufferGeometry, y: number, useAccent = false) => {
      const mesh = new THREE.Mesh(geometry, useAccent ? accent : material);
      mesh.position.y = y;
      mesh.castShadow = true;
      mesh.receiveShadow = true;
      group.add(mesh);
    };

    add(new THREE.CylinderGeometry(0.3, 0.36, 0.12, 24), 0.08);
    if (piece.type === "p") {
      add(new THREE.CylinderGeometry(0.2, 0.26, 0.34, 20), 0.28);
      add(new THREE.SphereGeometry(0.2, 20, 14), 0.54, true);
    } else if (piece.type === "r") {
      add(new THREE.CylinderGeometry(0.25, 0.29, 0.55, 12), 0.39);
      add(new THREE.CylinderGeometry(0.31, 0.31, 0.12, 12), 0.73, true);
    } else if (piece.type === "n") {
      add(new THREE.ConeGeometry(0.3, 0.78, 5), 0.51);
      add(new THREE.SphereGeometry(0.16, 16, 10), 0.88, true);
    } else if (piece.type === "b") {
      add(new THREE.ConeGeometry(0.28, 0.82, 20), 0.52);
      add(new THREE.SphereGeometry(0.18, 16, 10), 0.96, true);
    } else if (piece.type === "q") {
      add(new THREE.ConeGeometry(0.34, 0.92, 8), 0.56);
      add(new THREE.TorusGeometry(0.18, 0.05, 8, 20), 1.06, true);
      add(new THREE.SphereGeometry(0.12, 16, 10), 1.17, true);
    } else {
      add(new THREE.CylinderGeometry(0.3, 0.36, 0.95, 12), 0.56);
      add(new THREE.BoxGeometry(0.12, 0.42, 0.12), 1.18, true);
      add(new THREE.BoxGeometry(0.36, 0.12, 0.12), 1.18, true);
    }
    scene.add(group);
  };

  const onContextCreate = (gl: ExpoWebGLRenderingContext) => {
    const width = gl.drawingBufferWidth;
    const height = gl.drawingBufferHeight;
    const scene = new THREE.Scene();
    scene.background = new THREE.Color(0x081126);
    const camera = new THREE.PerspectiveCamera(34, width / height, 0.1, 100);
    camera.position.set(7.4, 8.6, 8.8);
    camera.lookAt(0, 0, 0);
    const renderer = new Renderer({ gl }) as unknown as THREE.WebGLRenderer;
    renderer.setSize(width, height);
    renderer.setPixelRatio(1);
    renderer.setClearColor(0x081126, 1);

    scene.add(new THREE.HemisphereLight(0xa9eaff, 0x071021, 2.2));
    const keyLight = new THREE.DirectionalLight(0xffffff, 3.1);
    keyLight.position.set(4, 9, 5);
    keyLight.castShadow = true;
    scene.add(keyLight);
    const rimLight = new THREE.PointLight(0x39d5ff, 2.5, 16);
    rimLight.position.set(-4, 4, -3);
    scene.add(rimLight);

    const base = new THREE.Mesh(
      new THREE.BoxGeometry(8.5, 0.42, 8.5),
      new THREE.MeshStandardMaterial({ color: 0x132849, metalness: 0.7, roughness: 0.25 }),
    );
    base.position.y = -0.22;
    base.receiveShadow = true;
    scene.add(base);

    const lightSquare = new THREE.MeshStandardMaterial({ color: 0xbadbe1, metalness: 0.15, roughness: 0.55 });
    const darkSquare = new THREE.MeshStandardMaterial({ color: 0x1b3b5d, metalness: 0.3, roughness: 0.45 });
    for (let row = 0; row < 8; row += 1) {
      for (let col = 0; col < 8; col += 1) {
        const tile = new THREE.Mesh(new THREE.BoxGeometry(0.98, 0.12, 0.98), (row + col) % 2 === 0 ? lightSquare : darkSquare);
        tile.position.set((col - 3.5) * 1.02, 0.03, (row - 3.5) * 1.02);
        tile.receiveShadow = true;
        scene.add(tile);
      }
    }

    board.forEach((row, rowIndex) => row.forEach((piece, colIndex) => {
      if (piece) createPiece(piece, scene, (colIndex - 3.5) * 1.02, (rowIndex - 3.5) * 1.02);
    }));

    const render = () => {
      if (disposed.current) return;
      requestAnimationFrame(render);
      scene.rotation.y = Math.sin(Date.now() / 5000) * 0.025;
      renderer.render(scene, camera);
      gl.endFrameEXP();
    };
    render();
    void positionKey;
  };

  if (Platform.OS === "web") return null;
  return <GLView key={positionKey} style={styles.scene3d} onContextCreate={onContextCreate} />;
}

function BoardFallback({ board, selected, selectedMoves, lastMove, pressSquare }: { board: (BoardPiece | null)[][]; selected: string | null; selectedMoves: string[]; lastMove: string; pressSquare: (square: string) => void }) {
  return (
    <View style={styles.boardPerspective}>
      {board.map((row, rowIndex) => (
        <View key={`row-${rowIndex}`} style={styles.boardRow}>
          {row.map((piece, colIndex) => {
            const square = squareName(rowIndex, colIndex);
            const isSelected = selected === square;
            const isTarget = selectedMoves.includes(square);
            const isLast = lastMove.includes(square);
            const light = (rowIndex + colIndex) % 2 === 0;
            return (
              <Pressable
                key={square}
                accessibilityLabel={piece ? chessPieceName(piece) : square}
                onPress={() => pressSquare(square)}
                style={({ pressed }) => [styles.square, light ? styles.lightSquare : styles.darkSquare, isLast && styles.lastSquare, isSelected && styles.selectedSquare, pressed && styles.pressedSquare]}
              >
                {piece && <Text style={[styles.piece, piece.color === "w" ? styles.whitePiece : styles.blackPiece]}>{glyphs[piece.color][piece.type]}</Text>}
                {isTarget && <View style={piece ? styles.captureRing : styles.moveDot} />}
              </Pressable>
            );
          })}
        </View>
      ))}
    </View>
  );
}

function InteractiveBoard({ board, selected, selectedMoves, lastMove, positionKey, pressSquare }: { board: (BoardPiece | null)[][]; selected: string | null; selectedMoves: string[]; lastMove: string; positionKey: string; pressSquare: (square: string) => void }) {
  if (Platform.OS === "web") {
    return <BoardFallback board={board} selected={selected} selectedMoves={selectedMoves} lastMove={lastMove} pressSquare={pressSquare} />;
  }
  return (
    <View style={styles.boardStage}>
      <Chess3DScene board={board} positionKey={positionKey} />
      <View style={styles.hitLayer} pointerEvents="box-none">
        {Array.from({ length: 8 }, (_, rowIndex) => (
          <View key={`hit-row-${rowIndex}`} style={styles.hitRow}>
            {Array.from({ length: 8 }, (_, colIndex) => {
              const square = squareName(rowIndex, colIndex);
              const isSelected = selected === square;
              const isTarget = selectedMoves.includes(square);
              const piece = board[rowIndex][colIndex];
              return (
                <Pressable
                  key={square}
                  accessibilityLabel={piece ? chessPieceName(piece) : square}
                  onPress={() => pressSquare(square)}
                  style={({ pressed }) => [styles.hitSquare, isSelected && styles.hitSelected, isTarget && styles.hitTarget, pressed && styles.hitPressed]}
                >
                  {isTarget && <View style={piece ? styles.captureRing3d : styles.moveDot3d} />}
                </Pressable>
              );
            })}
          </View>
        ))}
      </View>
      {String(Platform.OS) !== "web" && <Text style={styles.threeDLabel}>3D REAL BOARD · اسحب نظرك حول الرقعة</Text>}
    </View>
  );
}

export function ChessBoard() {
  const chessRef = useRef(new Chess());
  const [fen, setFen] = useState(() => chessRef.current.fen());
  const [selected, setSelected] = useState<string | null>(null);
  const [lastMove, setLastMove] = useState("");
  const [moveHistory, setMoveHistory] = useState<string[]>([]);
  const [snapshots, setSnapshots] = useState<Snapshot[]>([]);
  const [clockMinutes, setClockMinutes] = useState(5);
  const [gameMode, setGameMode] = useState<GameMode>("engine");
  const [whiteSeconds, setWhiteSeconds] = useState(5 * 60);
  const [blackSeconds, setBlackSeconds] = useState(5 * 60);
  const [capturedCount, setCapturedCount] = useState(0);
  const [gameStarted, setGameStarted] = useState(false);
  const [winner, setWinner] = useState<Side | null>(null);
  const [draw, setDraw] = useState(false);
  const [showClockSetup, setShowClockSetup] = useState(true);
  const game = chessRef.current;
  const board = mapBoard(game.board());
  const turn: Side = game.turn() === "w" ? "white" : "black";
  const selectedMoves = selected ? game.moves({ square: selected as Square, verbose: true }).map((move) => move.to as string) : [];

  useEffect(() => {
    if (!gameStarted || winner || draw) return;
    const timer = setInterval(() => {
      if (turn === "white") {
        setWhiteSeconds((seconds) => {
          if (seconds <= 1) {
            setWinner("black");
            setGameStarted(false);
            return 0;
          }
          return seconds - 1;
        });
      } else {
        setBlackSeconds((seconds) => {
          if (seconds <= 1) {
            setWinner("white");
            setGameStarted(false);
            return 0;
          }
          return seconds - 1;
        });
      }
    }, 1000);
    return () => clearInterval(timer);
  }, [gameStarted, turn, winner, draw]);

  useEffect(() => {
    if (gameMode !== "engine" || !gameStarted || winner || draw || turn !== "black") return;
    const timer = setTimeout(() => {
      const currentGame = chessRef.current;
      const engineMoves = currentGame.moves({ verbose: true });
      if (!engineMoves.length || currentGame.turn() !== "b") return;
      const selectedMove = pickEngineMove(currentGame);
      if (!selectedMove) return;
      const snapshot: Snapshot = { fen: currentGame.fen(), turn: "black", lastMove, moveHistory: [...moveHistory], whiteSeconds, blackSeconds, capturedCount };
      try {
        const move = currentGame.move({ from: selectedMove.from, to: selectedMove.to, promotion: "q" });
        setSnapshots((items) => [...items, snapshot]);
        setFen(currentGame.fen());
        setLastMove(`المحرك الأسود ${move.san}`);
        setMoveHistory((items) => [`المحرك الأسود ${move.san}`, ...items].slice(0, 10));
        setCapturedCount((count) => count + (move.captured ? 1 : 0));
        if (currentGame.isCheckmate()) {
          setWinner("black");
          setGameStarted(false);
        } else if (currentGame.isDraw() || currentGame.isStalemate()) {
          setDraw(true);
          setGameStarted(false);
        }
      } catch {
        setSelected(null);
      }
    }, 420);
    return () => clearTimeout(timer);
  }, [blackSeconds, capturedCount, draw, fen, gameMode, gameStarted, lastMove, moveHistory, turn, whiteSeconds, winner]);

  const resetState = (minutes: number, start: boolean) => {
    chessRef.current = new Chess();
    setFen(chessRef.current.fen());
    setSelected(null);
    setLastMove("");
    setMoveHistory([]);
    setSnapshots([]);
    setCapturedCount(0);
    setWhiteSeconds(minutes * 60);
    setBlackSeconds(minutes * 60);
    setWinner(null);
    setDraw(false);
    setShowClockSetup(!start);
    setGameStarted(start);
  };

  const startGame = (minutes: number) => {
    setClockMinutes(minutes);
    resetState(minutes, true);
  };

  const reset = () => resetState(clockMinutes, false);

  const undo = () => {
    const previous = snapshots[snapshots.length - 1];
    if (!previous) return;
    chessRef.current = new Chess(previous.fen);
    setFen(previous.fen);
    setSelected(null);
    setLastMove(previous.lastMove);
    setMoveHistory(previous.moveHistory);
    setWhiteSeconds(previous.whiteSeconds);
    setBlackSeconds(previous.blackSeconds);
    setCapturedCount(previous.capturedCount);
    setWinner(null);
    setDraw(false);
    setGameStarted(true);
    setShowClockSetup(false);
    setSnapshots((items) => items.slice(0, -1));
  };

  const pressSquare = (square: string) => {
    if (!gameStarted || winner || draw || (gameMode === "engine" && turn === "black")) return;
    const piece = game.get(square as Square) as { type: BoardPiece["type"]; color: "w" | "b" } | null;
    if (selected && selectedMoves.includes(square)) {
      const movingPiece = game.get(selected as Square) as { type: BoardPiece["type"]; color: "w" | "b" } | null;
      if (!movingPiece) return;
      const snapshot: Snapshot = { fen: game.fen(), turn, lastMove, moveHistory: [...moveHistory], whiteSeconds, blackSeconds, capturedCount };
      try {
        const move = game.move({ from: selected as Square, to: square as Square, promotion: "q" });
        const label = `${sideLabel(turn)} ${move.san}`;
        setSnapshots((items) => [...items, snapshot]);
        setFen(game.fen());
        setSelected(null);
        setLastMove(label);
        setMoveHistory((items) => [label, ...items].slice(0, 10));
        setCapturedCount((count) => count + (move.captured ? 1 : 0));
        if (game.isCheckmate()) {
          setWinner(turn);
          setGameStarted(false);
        } else if (game.isDraw() || game.isStalemate()) {
          setDraw(true);
          setGameStarted(false);
        }
        if (Platform.OS !== "web") void Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      } catch {
        setSelected(null);
      }
      return;
    }
    if (piece && piece.color === (turn === "white" ? "w" : "b")) {
      setSelected(square);
      if (Platform.OS !== "web") void Haptics.selectionAsync();
    } else {
      setSelected(null);
    }
  };

  const statusText = winner ? `الفائز: ${sideLabel(winner)}` : draw ? "تعادل — لا توجد نتيجة فوز" : gameStarted ? (gameMode === "engine" && turn === "black" ? "المحرك يفكر الآن" : `${sideLabel(turn)} يفكر الآن`) : "اختر زمن اللعب";
  const isCheck = game.isCheck();

  return (
    <View style={styles.wrapper}>
      <View style={styles.gameTopline}>
        <View>
          <Text style={styles.eyebrow}>MIRROR BOARD · REAL 3D ENGINE</Text>
          <Text style={styles.gameTitle}>مباراة شطرنج بمحرك حقيقي</Text>
        </View>
        <View style={styles.turnPill}>
          <View style={[styles.turnDot, turn === "black" && styles.blackDot]} />
          <Text style={styles.turnText}>{statusText}</Text>
        </View>
      </View>

      <View style={styles.clockRow}>
        <ClockCard label="الأبيض" seconds={whiteSeconds} active={gameStarted && turn === "white"} side="white" />
        <ClockCard label="الأسود" seconds={blackSeconds} active={gameStarted && turn === "black"} side="black" />
      </View>
      {showClockSetup && (
        <View style={styles.setupCard}>
          <Text style={styles.setupEyebrow}>إعداد المباراة</Text>
          <Text style={styles.setupTitle}>اختر زمن التفكير لكل لاعب</Text>
          <Text style={styles.setupHint}>محرك chess.js يتحقق من الحركات والكش والكش مات والترقية والتعادل.</Text>
          <View style={styles.modeRow}>
            <Pressable onPress={() => setGameMode("engine")} style={[styles.modeButton, gameMode === "engine" && styles.modeButtonActive]}><Text style={styles.modeButtonText}>ضد المحرك</Text></Pressable>
            <Pressable onPress={() => setGameMode("local")} style={[styles.modeButton, gameMode === "local" && styles.modeButtonActive]}><Text style={styles.modeButtonText}>لاعبان محلياً</Text></Pressable>
          </View>
          <View style={styles.presetRow}>
            {clockPresets.map((minutes) => (
              <Pressable key={minutes} onPress={() => startGame(minutes)} style={({ pressed }) => [styles.presetButton, pressed && styles.pressedButton]}>
                <Text style={styles.presetValue}>{minutes}</Text>
                <Text style={styles.presetUnit}>دقيقة</Text>
              </Pressable>
            ))}
          </View>
        </View>
      )}
      {winner && <View style={styles.resultBanner}><Text style={styles.resultTitle}>انتهت المباراة بالكش مات أو الوقت</Text><Text style={styles.resultText}>الفائز هو {sideLabel(winner)} — اختر إعادة المباراة للبدء من جديد.</Text></View>}
      {draw && <View style={styles.resultBanner}><Text style={styles.resultTitle}>تعادل</Text><Text style={styles.resultText}>انتهت المباراة دون فائز وفق قواعد المحرك.</Text></View>}

      <View style={styles.boardFrame}>
        <View style={styles.boardGlow} />
        <InteractiveBoard board={board} selected={selected} selectedMoves={selectedMoves} lastMove={lastMove} positionKey={fen} pressSquare={pressSquare} />
      </View>

      <View style={styles.boardLegend}>
        <Text style={styles.legendText}>{isCheck ? "كش — احمِ الملك" : "الأبيض يبدأ من الأسفل"}</Text>
        <Text style={styles.legendText}>حركات قانونية · ترقية · كش · كش مات · تعادل</Text>
      </View>

      <View style={styles.actionRow}>
        <Pressable onPress={undo} disabled={snapshots.length === 0 || !gameStarted} style={({ pressed }) => [styles.secondaryButton, (snapshots.length === 0 || !gameStarted) && styles.disabledButton, pressed && styles.pressedButton]}>
          <Text style={styles.secondaryButtonText}>تراجع</Text>
        </Pressable>
        <Pressable onPress={reset} style={({ pressed }) => [styles.primaryButton, pressed && styles.pressedButton]}>
          <Text style={styles.primaryButtonText}>إعادة المباراة</Text>
        </Pressable>
      </View>

      <View style={styles.infoPanel}>
        <View style={styles.infoHeader}><Text style={styles.infoTitle}>سجل الحركة</Text><Text style={styles.captureLabel}>{capturedCount} قطعة مأسورة</Text></View>
        {lastMove ? <Text style={styles.lastMove}>{lastMove}</Text> : <Text style={styles.emptyState}>{showClockSetup ? "ابدأ باختيار زمن لكل لاعب" : "اختر قطعة ثم اختر مربعاً مضيئاً للبدء"}</Text>}
        {moveHistory.slice(0, 5).map((move, index) => <Text key={`${move}-${index}`} style={styles.historyLine}>{move}</Text>)}
      </View>
    </View>
  );
}

function ClockCard({ label, seconds, active, side }: { label: string; seconds: number; active: boolean; side: Side }) {
  return (
    <View style={[styles.clockCard, side === "white" ? styles.whiteClock : styles.blackClock, active && styles.activeClock]}>
      <View style={styles.clockCardHeader}><View style={[styles.clockDot, side === "black" && styles.clockDotBlack]} /><Text style={styles.clockLabel}>{label}</Text></View>
      <Text style={[styles.clockTime, active && styles.activeClockText]}>{formatClock(seconds)}</Text>
      <Text style={styles.clockCaption}>{active ? "يفكر الآن" : "بانتظار الدور"}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  wrapper: { gap: 14 },
  gameTopline: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", gap: 10 },
  eyebrow: { color: "#55D6FF", fontSize: 10, letterSpacing: 1.5, fontWeight: "800" },
  gameTitle: { color: "#F5F8FF", fontSize: 22, lineHeight: 30, fontWeight: "800", marginTop: 2 },
  turnPill: { flexDirection: "row", alignItems: "center", gap: 7, borderWidth: 1, borderColor: "#315070", borderRadius: 18, paddingHorizontal: 10, paddingVertical: 8, backgroundColor: "#111E38" },
  turnDot: { width: 9, height: 9, borderRadius: 5, backgroundColor: "#F4F7FF", shadowColor: "#55D6FF", shadowOpacity: 0.8, shadowRadius: 5, shadowOffset: { width: 0, height: 0 } },
  blackDot: { backgroundColor: "#111A2F", borderWidth: 1, borderColor: "#55D6FF" },
  turnText: { color: "#DDEBFF", fontSize: 11, fontWeight: "700" },
  clockRow: { flexDirection: "row", gap: 10 },
  clockCard: { flex: 1, minHeight: 78, borderRadius: 17, paddingHorizontal: 13, paddingVertical: 10, backgroundColor: "#111E38", borderWidth: 1, borderColor: "#2B4565" },
  whiteClock: { borderColor: "#4E7195" },
  blackClock: { borderColor: "#3B4767" },
  activeClock: { borderColor: "#55D6FF", backgroundColor: "#142C48", shadowColor: "#55D6FF", shadowOpacity: 0.32, shadowRadius: 12, shadowOffset: { width: 0, height: 0 } },
  clockCardHeader: { flexDirection: "row", alignItems: "center", justifyContent: "space-between" },
  clockDot: { width: 8, height: 8, borderRadius: 4, backgroundColor: "#F4F7FF" },
  clockDotBlack: { backgroundColor: "#0A1425", borderWidth: 1, borderColor: "#8CA3BF" },
  clockLabel: { color: "#9EB2CA", fontSize: 11, fontWeight: "700" },
  clockTime: { color: "#F4F8FF", fontSize: 26, lineHeight: 31, fontWeight: "900", letterSpacing: 1, marginTop: 3 },
  activeClockText: { color: "#63F5D1" },
  clockCaption: { color: "#738AA5", fontSize: 9, marginTop: 1 },
  setupCard: { borderRadius: 18, padding: 14, backgroundColor: "#101F39", borderWidth: 1, borderColor: "#315070", gap: 5 },
  setupEyebrow: { color: "#55D6FF", fontSize: 10, fontWeight: "800", letterSpacing: 1 },
  setupTitle: { color: "#F4F8FF", fontSize: 15, fontWeight: "800" },
  setupHint: { color: "#8FA4BD", fontSize: 11, lineHeight: 17 },
  modeRow: { flexDirection: "row", gap: 8, marginTop: 7 },
  modeButton: { flex: 1, minHeight: 38, borderRadius: 11, alignItems: "center", justifyContent: "center", backgroundColor: "#142844", borderWidth: 1, borderColor: "#2F5274" },
  modeButtonActive: { backgroundColor: "#164B61", borderColor: "#55D6FF" },
  modeButtonText: { color: "#DCEBFF", fontSize: 11, fontWeight: "800" },
  presetRow: { flexDirection: "row", gap: 8, marginTop: 5 },
  presetButton: { flex: 1, alignItems: "center", justifyContent: "center", minHeight: 52, borderRadius: 13, backgroundColor: "#182D4B", borderWidth: 1, borderColor: "#2F5274" },
  presetValue: { color: "#55D6FF", fontSize: 18, lineHeight: 21, fontWeight: "900" },
  presetUnit: { color: "#9CB0C7", fontSize: 9, marginTop: 2 },
  resultBanner: { borderRadius: 16, padding: 12, backgroundColor: "#302413", borderWidth: 1, borderColor: "#FFB340", gap: 4 },
  resultTitle: { color: "#FFCB72", fontSize: 14, fontWeight: "900" },
  resultText: { color: "#DEC28F", fontSize: 11, lineHeight: 17 },
  boardFrame: { position: "relative", minHeight: 390, borderRadius: 23, padding: 10, backgroundColor: "#0D1C33", borderWidth: 1, borderColor: "#315273", shadowColor: "#14B8FF", shadowOpacity: 0.32, shadowRadius: 18, shadowOffset: { width: 0, height: 8 }, elevation: 12 },
  boardGlow: { position: "absolute", left: 26, right: 26, bottom: 8, height: 20, borderRadius: 20, backgroundColor: "#13CFFF", opacity: 0.12 },
  boardStage: { position: "relative", width: "100%", aspectRatio: 1, overflow: "hidden", borderRadius: 12 },
  scene3d: { ...StyleSheet.absoluteFillObject, backgroundColor: "#081126" },
  hitLayer: { ...StyleSheet.absoluteFillObject, padding: 0 },
  hitRow: { flex: 1, flexDirection: "row" },
  hitSquare: { flex: 1, alignItems: "center", justifyContent: "center", borderWidth: 0.5, borderColor: "rgba(110,231,255,0.08)" },
  hitSelected: { backgroundColor: "rgba(13,181,214,0.35)" },
  hitTarget: { backgroundColor: "rgba(99,245,209,0.12)" },
  hitPressed: { opacity: 0.75 },
  moveDot3d: { width: 12, height: 12, borderRadius: 6, backgroundColor: "#63F5D1", shadowColor: "#63F5D1", shadowOpacity: 0.9, shadowRadius: 8, shadowOffset: { width: 0, height: 0 } },
  captureRing3d: { width: "72%", height: "72%", borderRadius: 100, borderWidth: 2, borderColor: "#FFBB4D" },
  threeDLabel: { position: "absolute", bottom: 7, right: 14, color: "#86DDF4", fontSize: 9, fontWeight: "900", letterSpacing: 0.7 },
  boardPerspective: { aspectRatio: 1, width: "100%", overflow: "hidden", borderRadius: 10, borderWidth: 2, borderColor: "#6EE7FF", transform: [{ perspective: 1000 }, { rotateX: "5deg" }, { rotateZ: "-1deg" }] },
  boardRow: { flex: 1, flexDirection: "row" },
  square: { flex: 1, alignItems: "center", justifyContent: "center", position: "relative" },
  lightSquare: { backgroundColor: "#B9D6D8" },
  darkSquare: { backgroundColor: "#203D57" },
  lastSquare: { backgroundColor: "#336C76" },
  selectedSquare: { backgroundColor: "#0DB5D6" },
  pressedSquare: { opacity: 0.78 },
  piece: { fontSize: 40, lineHeight: 44, textAlign: "center", includeFontPadding: false, textShadowOffset: { width: 0, height: 2 }, textShadowRadius: 2 },
  whitePiece: { color: "#F8FCFF", textShadowColor: "#13283B", textShadowRadius: 2, textShadowOffset: { width: 0, height: 2 } },
  blackPiece: { color: "#0C1729", textShadowColor: "#92D9EE", textShadowRadius: 2, textShadowOffset: { width: 0, height: 1 } },
  moveDot: { position: "absolute", width: 10, height: 10, borderRadius: 5, backgroundColor: "#63F5D1" },
  captureRing: { position: "absolute", width: "70%", height: "70%", borderRadius: 100, borderWidth: 2, borderColor: "#FFBB4D", opacity: 0.92 },
  boardLegend: { flexDirection: "row", justifyContent: "space-between", gap: 10 },
  legendText: { color: "#8194AD", fontSize: 10, flexShrink: 1 },
  actionRow: { flexDirection: "row", gap: 10 },
  primaryButton: { flex: 1, minHeight: 44, borderRadius: 14, alignItems: "center", justifyContent: "center", backgroundColor: "#55D6FF" },
  secondaryButton: { width: 96, minHeight: 44, borderRadius: 14, alignItems: "center", justifyContent: "center", backgroundColor: "#162844", borderWidth: 1, borderColor: "#315070" },
  primaryButtonText: { color: "#071426", fontSize: 14, fontWeight: "800" },
  secondaryButtonText: { color: "#DCEBFF", fontSize: 13, fontWeight: "700" },
  disabledButton: { opacity: 0.45 },
  pressedButton: { transform: [{ scale: 0.98 }], opacity: 0.88 },
  infoPanel: { borderRadius: 17, padding: 14, backgroundColor: "#101E37", borderWidth: 1, borderColor: "#263F5E", gap: 8 },
  infoHeader: { flexDirection: "row", justifyContent: "space-between", alignItems: "center" },
  infoTitle: { color: "#F3F8FF", fontSize: 14, fontWeight: "800" },
  captureLabel: { color: "#63F5D1", fontSize: 11, fontWeight: "700" },
  lastMove: { color: "#55D6FF", fontSize: 13, fontWeight: "700" },
  emptyState: { color: "#8A9DB6", fontSize: 12, lineHeight: 19 },
  historyLine: { color: "#8A9DB6", fontSize: 11 },
});
