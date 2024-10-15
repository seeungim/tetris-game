import 'package:flutter/material.dart';
import 'dart:math'; // 랜덤 블록 생성을 위한 라이브러리
import 'dart:async'; // 타이머 기능을 위한 라이브러리
import 'dart:ui'; // UI 관련 라이브러리 추가
import 'package:flutter/services.dart'; // 키 이벤트 관련 라이브러리 추가

void main() {
  runApp(const TetrisGame());
}

class TetrisGame extends StatelessWidget {
  const TetrisGame({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Tetris',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      home: const GamePage(),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({Key? key}) : super(key: key);

  @override
  _GamePageState createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  List<List<int>> fixedBlocks = List.generate(20, (_) => List.generate(10, (_) => 0)); // 고정된 블록 저장 리스트
  Timer? timer; // Timer 변수를 추가

  TetrisBlock currentBlock = TetrisBlock.getRandomBlock(); // 현재 블록 저장
  TetrisBlock? heldBlock; // 보관된 블록을 위한 변수 추가
  bool blockSwapped = false; // 블록 교체 여부 체크
  static const int gridWidth = 10; // 테트리스 가로 칸 수
  static const int gridHeight = 20; // 테트리스 세로 칸 수
  int score = 0; // 점수 변수 추가
  bool gameOver = false; // 게임 오버 상태 추가
  int level = 1; // 레벨 변수 추가
  static const int baseSpeed = 500; // 기본 속도
  int speed = baseSpeed; // 현재 속도

  @override
  void initState() {
    super.initState();
    startGame(); // 게임 시작 시 호출
  }

  void startGame() {
    gameOver = false; // 게임 시작 시 게임 오버 상태 초기화
    score = 0; // 점수 초기화
    level = 1; // 레벨 초기화
    speed = baseSpeed; // 속도 초기화
    fixedBlocks = List.generate(20, (_) => List.generate(10, (_) => 0)); // 블록 초기화
    currentBlock = TetrisBlock.getRandomBlock(); // 새로운 블록 생성
    heldBlock = null; // 게임 시작 시 보관된 블록 없음
    blockSwapped = false; // 블록 교체 초기화
    timer = Timer.periodic(Duration(milliseconds: speed), (timer) {
      setState(() {
        moveDown();
      });
    });
  }

  void moveDown() {
    if (canMoveDown()) {
      currentBlock.moveDown();
    } else {
      fixBlock();
      if (checkGameOver()) { // 게임 오버 체크
        timer?.cancel(); // 타이머 멈추기
        gameOver = true; // 게임 오버 상태 설정
      } else {
        clearLines(); // 라인 지우기 함수 호출
        currentBlock = TetrisBlock.getRandomBlock();
        blockSwapped = false; // 새 블록이 나오면 교체 가능 상태로 변경
      }
    }
  }

  bool canMoveDown() {
    // 블록이 아래로 이동 가능한지 확인
    for (int row = 0; row < currentBlock.shape.length; row++) {
      for (int col = 0; col < currentBlock.shape[row].length; col++) {
        if (currentBlock.shape[row][col] == 1) {
          if (currentBlock.y + row + 1 >= gridHeight ||
              fixedBlocks[currentBlock.y + row + 1][currentBlock.x + col] == 1) {
            return false; // 바닥에 닿거나 고정된 블록이 있으면 이동 불가능
          }
        }
      }
    }
    return true; // 이동 가능
  }

  void fixBlock() {
    for (int row = 0; row < currentBlock.shape.length; row++) {
      for (int col = 0; col < currentBlock.shape[row].length; col++) {
        if (currentBlock.shape[row][col] == 1) {
          fixedBlocks[currentBlock.y + row][currentBlock.x + col] = 1; // 고정 블록 배열에 추가
        }
      }
    }
  }

  void clearLines() {
    // 가득 찬 라인 지우기
    for (int row = 0; row < gridHeight; row++) {
      if (fixedBlocks[row].every((block) => block == 1)) {
        fixedBlocks.removeAt(row); // 가득 찬 라인 삭제
        fixedBlocks.insert(0, List.generate(gridWidth, (_) => 0)); // 위에 새로운 빈 라인 추가
        score += 100; // 점수 추가 (한 라인당 100점)

        if (score ~/ 500 > level) { // 레벨 업 조건
          level++;
          speed = max(100, baseSpeed - (level - 1) * 50); // 속도 조정
          timer?.cancel(); // 기존 타이머 멈추기
          timer = Timer.periodic(Duration(milliseconds: speed), (timer) {
            setState(() {
              moveDown();
            });
          });
        }
      }
    }
  }

  bool checkGameOver() { // 게임 오버 체크
    for (int col = 0; col < gridWidth; col++) {
      if (fixedBlocks[0][col] == 1) {
        return true;
      }
    }
    return false;
  }

  // 블록 회전 함수
  void rotateBlock() {
    setState(() {
      currentBlock.rotate();
      // 회전 후 벽과 겹치거나 바닥에 닿지 않도록 확인
      if (!canMoveDown()) {
        currentBlock.rotateBack();
      }
    });
  }

  // 블록을 왼쪽으로 이동
  void moveLeft() {
    setState(() {
      if (canMoveLeft()) {
        currentBlock.moveLeft();
      }
    });
  }

  // 블록을 오른쪽으로 이동
  void moveRight() {
    setState(() {
      if (canMoveRight()) {
        currentBlock.moveRight();
      }
    });
  }

  bool canMoveLeft() {
    for (int row = 0; row < currentBlock.shape.length; row++) {
      for (int col = 0; col < currentBlock.shape[row].length; col++) {
        if (currentBlock.shape[row][col] == 1) {
          if (currentBlock.x + col - 1 < 0 ||
              fixedBlocks[currentBlock.y + row][currentBlock.x + col - 1] == 1) {
            return false; // 벽에 닿거나 고정된 블록이 있으면 이동 불가능
          }
        }
      }
    }
    return true; // 이동 가능
  }

  bool canMoveRight() {
    for (int row = 0; row < currentBlock.shape.length; row++) {
      for (int col = 0; col < currentBlock.shape[row].length; col++) {
        if (currentBlock.shape[row][col] == 1) {
          if (currentBlock.x + col + 1 >= gridWidth ||
              fixedBlocks[currentBlock.y + row][currentBlock.x + col + 1] == 1) {
            return false; // 벽에 닿거나 고정된 블록이 있으면 이동 불가능
          }
        }
      }
    }
    return true; // 이동 가능
  }

  // 블록 보관 기능 추가
  void holdBlock() {
    if (blockSwapped) return; // 이미 교체했다면 더 이상 교체 불가

    setState(() {
      if (heldBlock == null) {
        heldBlock = currentBlock; // 보관된 블록이 없으면 현재 블록을 보관
        currentBlock = TetrisBlock.getRandomBlock(); // 새 블록 생성
      } else {
        TetrisBlock temp = heldBlock!; // 현재 블록과 보관된 블록을 교체
        heldBlock = currentBlock;
        currentBlock = temp;
      }
      blockSwapped = true; // 한 번 교체 후 더 이상 교체 불가
    });
  }

  void restartGame() { // 게임 재시작 함수
    startGame(); // 게임 시작 함수 호출
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Tetris'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('점수: $score | 레벨: $level'), // 레벨 표시 추가
          ),
        ],
      ),
      body: Center(
        child: gameOver
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('게임 오버', style: TextStyle(fontSize: 40, color: Colors.red)),
            ElevatedButton(
              onPressed: restartGame,
              child: const Text('재시작'),
            ),
          ],
        )
            : Column(
          children: [
            Expanded(
              child: Focus(
                onKey: (FocusNode node, RawKeyEvent event) {
                  if (event is RawKeyDownEvent) {
                    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                      moveDown();
                    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                      moveLeft();
                    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                      moveRight();
                    } else if (event.logicalKey == LogicalKeyboardKey.space) {
                      rotateBlock();
                    } else if (event.logicalKey == LogicalKeyboardKey.keyZ) {
                      holdBlock(); // Z 키로 보관
                    }
                  }
                  return KeyEventResult.handled;
                },

                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    color: Colors.black,
                  ),
                  child: CustomPaint(
                    painter: TetrisPainter(fixedBlocks, currentBlock),
                    size: const Size(200, 400),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TetrisPainter extends CustomPainter {
  final List<List<int>> fixedBlocks;
  final TetrisBlock currentBlock;

  TetrisPainter(this.fixedBlocks, this.currentBlock);

  @override
  void paint(Canvas canvas, Size size) {
    double blockSize = size.width / 10; // 블록 크기 계산
    for (int row = 0; row < fixedBlocks.length; row++) {
      for (int col = 0; col < fixedBlocks[row].length; col++) {
        if (fixedBlocks[row][col] == 1) {
          canvas.drawRect(Rect.fromLTWH(col * blockSize, row * blockSize, blockSize, blockSize), Paint()..color = Colors.blue); // 고정 블록 그리기
        }
      }
    }
    drawCurrentBlock(canvas, blockSize); // 현재 블록 그리기
  }

  void drawCurrentBlock(Canvas canvas, double blockSize) {
    for (int row = 0; row < currentBlock.shape.length; row++) {
      for (int col = 0; col < currentBlock.shape[row].length; col++) {
        if (currentBlock.shape[row][col] == 1) {
          canvas.drawRect(Rect.fromLTWH(
              (currentBlock.x + col) * blockSize,
              (currentBlock.y + row) * blockSize,
              blockSize,
              blockSize), Paint()..color = Colors.red); // 현재 블록 그리기
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true; // 항상 repaint
}

class TetrisBlock {
  List<List<int>> shape; // 블록 모양
  int x; // 블록 x 위치
  int y; // 블록 y 위치

  TetrisBlock({required this.shape, required this.x, required this.y});

  static TetrisBlock getRandomBlock() {
    List<List<List<int>>> blockShapes = [
      [[1, 1, 1, 1]], // I 모양
      [[1, 1, 1], [0, 1, 0]], // T 모양
      [[1, 1], [1, 1]], // O 모양
      [[0, 1, 1], [1, 1, 0]], // Z 모양
      [[1, 1, 0], [0, 1, 1]], // S 모양
      [[1, 1, 1], [1, 0, 0]], // L 모양
      [[1, 1, 1], [0, 0, 1]], // J 모양
    ];

    int randomIndex = Random().nextInt(blockShapes.length);
    return TetrisBlock(shape: blockShapes[randomIndex], x: 4, y: 0); // 블록 생성
  }

  void moveDown() {
    y += 1; // y 위치 증가
  }

  void moveLeft() {
    x -= 1; // x 위치 감소
  }

  void moveRight() {
    x += 1; // x 위치 증가
  }

  void rotate() {
    shape = List.generate(
      shape[0].length,
          (i) => List.generate(shape.length, (j) => shape[shape.length - 1 - j][i]), // 시계방향 회전
    );
  }

  void rotateBack() {
    for (int i = 0; i < 3; i++) {
      rotate(); // 반시계방향 회전
    }
  }

  bool isAtPosition(int xPos, int yPos) {
    for (int row = 0; row < shape.length; row++) {
      for (int col = 0; col < shape[row].length; col++) {
        if (shape[row][col] == 1) {
          if (xPos == x + col && yPos == y + row) {
            return true; // 특정 위치에 블록 존재
          }
        }
      }
    }
    return false; // 특정 위치에 블록 없음
  }
}