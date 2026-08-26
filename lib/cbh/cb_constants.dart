// Constants ported from the reference Python implementation
// https://github.com/asdfjkl/cbh2pgn (game.py) - MIT licensed.

const int wQueen = 1;
const int wKnight = 2;
const int wBishop = 3;
const int wRook = 4;

const int bQueen = 5;
const int bKnight = 6;
const int bBishop = 7;
const int bRook = 8;

const int wKing = 9;
const int bKing = 10;
const int wPawn = 11;
const int bPawn = 12;

/// Algebraic square name for file [i] (0=a..7=h) and rank [j] (0=1..7=8).
String squareName(int i, int j) {
  return String.fromCharCode(0x61 + i) + (j + 1).toString();
}

/// Maps an absolute 0..63 square index (a1..a8, b1..b8, ...) to (file, rank).
const List<List<int>> absToXY = [
  [0, 0], [0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [0, 6], [0, 7], // a1..a8
  [1, 0], [1, 1], [1, 2], [1, 3], [1, 4], [1, 5], [1, 6], [1, 7], // b1..b8
  [2, 0], [2, 1], [2, 2], [2, 3], [2, 4], [2, 5], [2, 6], [2, 7], // c1..c8
  [3, 0], [3, 1], [3, 2], [3, 3], [3, 4], [3, 5], [3, 6], [3, 7], // d1..d8
  [4, 0], [4, 1], [4, 2], [4, 3], [4, 4], [4, 5], [4, 6], [4, 7], // e1..e8
  [5, 0], [5, 1], [5, 2], [5, 3], [5, 4], [5, 5], [5, 6], [5, 7], // f1..f8
  [6, 0], [6, 1], [6, 2], [6, 3], [6, 4], [6, 5], [6, 6], [6, 7], // g1..g8
  [7, 0], [7, 1], [7, 2], [7, 3], [7, 4], [7, 5], [7, 6], [7, 7], // h1..h8
];

/// One-byte move encodings: token byte -> (dx, dy) offset applied to the
/// piece's current (file, rank). Only the first three pieces of a kind get
/// one-byte encodings; a fourth+ piece of a kind (or a promotion) uses the
/// two-byte encoding instead.
const Map<int, List<int>> cbKingEnc = {
  0x49: [0, 1],
  0x39: [1, 1],
  0xD8: [1, 0],
  0x5D: [1, 7],
  0xC2: [0, 7],
  0xB1: [7, 7],
  0xB2: [7, 0],
  0x47: [7, 1],
  0x76: [2, 0], // castles short
  0xB5: [-2, 0], // castles long
};

const Map<int, List<int>> cbQueen1Enc = {
  0xA5: [0, 1],
  0xB8: [0, 2],
  0xCB: [0, 3],
  0x53: [0, 4],
  0x7F: [0, 5],
  0x6B: [0, 6],
  0x8D: [0, 7],
  0x79: [1, 0],
  0xBE: [2, 0],
  0xEB: [3, 0],
  0x21: [4, 0],
  0x99: [5, 0],
  0xD2: [6, 0],
  0x57: [7, 0],
  0x4D: [1, 1],
  0xB4: [2, 2],
  0xBF: [3, 3],
  0x62: [4, 4],
  0xBD: [5, 5],
  0x24: [6, 6],
  0x96: [7, 7],
  0xA7: [1, 7],
  0x48: [2, 6],
  0x28: [3, 5],
  0x6E: [4, 4],
  0x2F: [5, 3],
  0x5A: [6, 2],
  0x18: [7, 1],
};

const Map<int, List<int>> cbQueen2Enc = {
  0xE5: [0, 1],
  0x94: [0, 2],
  0x50: [0, 3],
  0x11: [0, 4],
  0xEA: [0, 5],
  0x31: [0, 6],
  0x01: [0, 7],
  0x5C: [1, 0],
  0x95: [2, 0],
  0xCA: [3, 0],
  0xD3: [4, 0],
  0x1D: [5, 0],
  0x7E: [6, 0],
  0xEF: [7, 0],
  0x44: [1, 1],
  0x80: [2, 2],
  0xA0: [3, 3],
  0x1F: [4, 4],
  0x83: [5, 5],
  0x00: [6, 6],
  0x4B: [7, 7],
  0x67: [1, 7],
  0x20: [2, 6],
  0x5B: [3, 5],
  0x2A: [4, 4],
  0x92: [5, 3],
  0xB6: [6, 2],
  0x60: [7, 1],
};

const Map<int, List<int>> cbQueen3Enc = {
  0x1A: [0, 1],
  0x42: [0, 2],
  0x0F: [0, 3],
  0x0D: [0, 4],
  0xB0: [0, 5],
  0xD1: [0, 6],
  0x23: [0, 7],
  0xF0: [1, 0],
  0x7A: [2, 0],
  0x54: [3, 0],
  0x4F: [4, 0],
  0xF4: [5, 0],
  0xA8: [6, 0],
  0x72: [7, 0],
  0xE7: [1, 1],
  0x40: [2, 2],
  0x38: [3, 3],
  0x59: [4, 4],
  0x87: [5, 5],
  0xE8: [6, 6],
  0x6C: [7, 7],
  0x86: [1, 7],
  0x04: [2, 6],
  0xF1: [3, 5],
  0x8C: [4, 4],
  0xCE: [5, 3],
  0x6A: [6, 2],
  0xDB: [7, 1],
};

const Map<int, List<int>> cbRook1Enc = {
  0x4E: [0, 1],
  0xF8: [0, 2],
  0x43: [0, 3],
  0xD7: [0, 4],
  0x63: [0, 5],
  0x9C: [0, 6],
  0xE6: [0, 7],
  0x2E: [1, 0],
  0xC6: [2, 0],
  0x26: [3, 0],
  0x88: [4, 0],
  0x30: [5, 0],
  0x61: [6, 0],
  0x6F: [7, 0],
};

const Map<int, List<int>> cbRook2Enc = {
  0x14: [0, 1],
  0xA9: [0, 2],
  0x68: [0, 3],
  0xEE: [0, 4],
  0xFB: [0, 5],
  0x77: [0, 6],
  0xE2: [0, 7],
  0xA6: [1, 0],
  0x05: [2, 0],
  0x8B: [3, 0],
  0xA1: [4, 0],
  0x98: [5, 0],
  0x32: [6, 0],
  0x52: [7, 0],
};

const Map<int, List<int>> cbRook3Enc = {
  0x81: [0, 1],
  0x82: [0, 2],
  0x9A: [0, 3],
  0x1B: [0, 4],
  0x9D: [0, 5],
  0x0A: [0, 6],
  0x2B: [0, 7],
  0x8F: [1, 0],
  0xCD: [2, 0],
  0xED: [3, 0],
  0x10: [4, 0],
  0x74: [5, 0],
  0x69: [6, 0],
  0xD6: [7, 0],
};

const Map<int, List<int>> cbBishop1Enc = {
  0x02: [1, 1],
  0x97: [2, 2],
  0xE1: [3, 3],
  0x41: [4, 4],
  0xC3: [5, 5],
  0x7C: [6, 6],
  0xE4: [7, 7],
  0x06: [1, 7],
  0xB7: [2, 6],
  0x55: [3, 5],
  0xD9: [4, 4],
  0x2C: [5, 3],
  0xAE: [6, 2],
  0x37: [7, 1],
};

const Map<int, List<int>> cbBishop2Enc = {
  0xF6: [1, 1],
  0x3F: [2, 2],
  0x08: [3, 3],
  0x93: [4, 4],
  0x73: [5, 5],
  0x5E: [6, 6],
  0x78: [7, 7],
  0x35: [1, 7],
  0xF2: [2, 6],
  0x6D: [3, 5],
  0x71: [4, 4],
  0xA2: [5, 3],
  0xF3: [6, 2],
  0x16: [7, 1],
};

const Map<int, List<int>> cbBishop3Enc = {
  0x51: [1, 1],
  0xB9: [2, 2],
  0x45: [3, 3],
  0x3B: [4, 4],
  0x56: [5, 5],
  0x91: [6, 6],
  0xFD: [7, 7],
  0xAB: [1, 7],
  0x66: [2, 6],
  0x3E: [3, 5],
  0x46: [4, 4],
  0xB3: [5, 3],
  0xFC: [6, 2],
  0xC8: [7, 1],
};

const Map<int, List<int>> cbKnight1Enc = {
  0x58: [2, 1],
  0x3D: [1, 2],
  0xFA: [-1, 2],
  0xE9: [-2, 1],
  0xBA: [-2, -1],
  0xD4: [-1, -2],
  0xDD: [1, -2],
  0x4A: [2, -1],
};

const Map<int, List<int>> cbKnight2Enc = {
  0xC4: [2, 1],
  0x0E: [1, 2],
  0xFE: [-1, 2],
  0x5F: [-2, 1],
  0x75: [-2, -1],
  0x07: [-1, -2],
  0x89: [1, -2],
  0x34: [2, -1],
};

const Map<int, List<int>> cbKnight3Enc = {
  0x9B: [2, 1],
  0xC0: [1, 2],
  0xE3: [-1, 2],
  0xA3: [-2, 1],
  0xAC: [-2, -1],
  0xC9: [-1, -2],
  0xEC: [1, -2],
  0x27: [2, -1],
};

const Map<int, List<int>> cbPawnAEnc = {
  0x2D: [0, 1],
  0xC1: [0, 2],
  0x8E: [1, 1],
  0xF5: [-1, 1],
};

const Map<int, List<int>> cbPawnBEnc = {
  0x64: [0, 1],
  0x17: [0, 2],
  0x70: [1, 1],
  0xA4: [-1, 1],
};

const Map<int, List<int>> cbPawnCEnc = {
  0x7B: [0, 1],
  0xDA: [0, 2],
  0xE0: [1, 1],
  0x85: [-1, 1],
};

const Map<int, List<int>> cbPawnDEnc = {
  0xC5: [0, 1],
  0x0B: [0, 2],
  0x90: [1, 1],
  0xF9: [-1, 1],
};

const Map<int, List<int>> cbPawnEEnc = {
  0x84: [0, 1],
  0xFF: [0, 2],
  0x15: [1, 1],
  0x36: [-1, 1],
};

const Map<int, List<int>> cbPawnFEnc = {
  0x09: [0, 1],
  0x9E: [0, 2],
  0x7D: [1, 1],
  0xDE: [-1, 1],
};

const Map<int, List<int>> cbPawnGEnc = {
  0xBB: [0, 1],
  0xDF: [0, 2],
  0xBC: [1, 1],
  0x3A: [-1, 1],
};

const Map<int, List<int>> cbPawnHEnc = {
  0x12: [0, 1],
  0x33: [0, 2],
  0x13: [1, 1],
  0x19: [-1, 1],
};

/// De-obfuscation table used for two-byte encoded moves (promotions, or the
/// 4th+ piece of a kind). Index = obfuscated byte value, value = clear byte.
const List<int> deobfuscate2b = [
  0XA2, 0X95, 0X43, 0XF5, 0XC1, 0X3D, 0X4A, 0X6C, //   0 -   7
  0X53, 0X83, 0XCC, 0X7C, 0XFF, 0XAE, 0X68, 0XAD, //   8 -  15
  0XD1, 0X92, 0X8B, 0X8D, 0X35, 0X81, 0X5E, 0X74, //  16 -  23
  0X26, 0X8E, 0XAB, 0XCA, 0XFD, 0X9A, 0XF3, 0XA0, //  24 -  31
  0XA5, 0X15, 0XFC, 0XB1, 0X1E, 0XED, 0X30, 0XEA, //  32 -  39
  0X22, 0XEB, 0XA7, 0XCD, 0X4E, 0X6F, 0X2E, 0X24, //  40 -  47
  0X32, 0X94, 0X41, 0X8C, 0X6E, 0X58, 0X82, 0X50, //  48 -  55
  0XBB, 0X02, 0X8A, 0XD8, 0XFA, 0X60, 0XDE, 0X52, //  56 -  63
  0XBA, 0X46, 0XAC, 0X29, 0X9D, 0XD7, 0XDF, 0X08, //  64 -  71
  0X21, 0X01, 0X66, 0XA3, 0XF1, 0X19, 0X27, 0XB5, //  72 -  79
  0X91, 0XD5, 0X42, 0X0E, 0XB4, 0X4C, 0XD9, 0X18, //  80 -  87
  0X5F, 0XBC, 0X25, 0XA6, 0X96, 0X04, 0X56, 0X6A, //  88 -  95
  0XAA, 0X33, 0X1C, 0X2B, 0X73, 0XF0, 0XDD, 0XA4, //  96 - 103
  0X37, 0XD3, 0XC5, 0X10, 0XBF, 0X5A, 0X23, 0X34, // 104 - 111
  0X75, 0X5B, 0XB8, 0X55, 0XD2, 0X6B, 0X09, 0X3A, // 112 - 119
  0X57, 0X12, 0XB3, 0X77, 0X48, 0X85, 0X9B, 0X0F, // 120 - 127
  0X9E, 0XC7, 0XC8, 0XA1, 0X7F, 0X7A, 0XC0, 0XBD, // 128 - 135
  0X31, 0X6D, 0XF6, 0X3E, 0XC3, 0X11, 0X71, 0XCE, // 136 - 143
  0X7D, 0XDA, 0XA8, 0X54, 0X90, 0X97, 0X1F, 0X44, // 144 - 151
  0X40, 0X16, 0XC9, 0XE3, 0X2C, 0XCB, 0X84, 0XEC, // 152 - 159
  0X9F, 0X3F, 0X5C, 0XE6, 0X76, 0X0B, 0X3C, 0X20, // 160 - 167
  0XB7, 0X36, 0X00, 0XDC, 0XE7, 0XF9, 0X4F, 0XF7, // 168 - 175
  0XAF, 0X06, 0X07, 0XE0, 0X1A, 0X0A, 0XA9, 0X4B, // 176 - 183
  0X0C, 0XD6, 0X63, 0X87, 0X89, 0X1D, 0X13, 0X1B, // 184 - 191
  0XE4, 0X70, 0X05, 0X47, 0X67, 0X7B, 0X2F, 0XEE, // 192 - 199
  0XE2, 0XE8, 0X98, 0X0D, 0XEF, 0XCF, 0XC4, 0XF4, // 200 - 207
  0XFB, 0XB0, 0X17, 0X99, 0X64, 0XF2, 0XD4, 0X2A, // 208 - 215
  0X03, 0X4D, 0X78, 0XC6, 0XFE, 0X65, 0X86, 0X88, // 216 - 223
  0X79, 0X45, 0X3B, 0XE5, 0X49, 0X8F, 0X2D, 0XB9, // 224 - 231
  0XBE, 0X62, 0X93, 0X14, 0XE9, 0XD0, 0X38, 0X9C, // 232 - 239
  0XB2, 0XC2, 0X59, 0X5D, 0XB6, 0X72, 0X51, 0XF8, // 240 - 247
  0X28, 0X7E, 0X61, 0X39, 0XE1, 0XDB, 0X69, 0X80, // 248 - 255
];

const int specialTwoByteMove = 0x29;
const int specialStartVariation = 0xDC;
const int specialEndVariation = 0x0C;
const int specialSkip = 0x9F;
const int specialNullMove = 0xAA;

const Set<int> specialCodes = {
  specialTwoByteMove,
  specialStartVariation,
  specialEndVariation,
  specialSkip,
};
