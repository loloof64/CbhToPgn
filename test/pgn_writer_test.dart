import 'package:cbh_to_pgn/cbh/game_tree.dart';
import 'package:cbh_to_pgn/pgn/pgn_writer.dart';
import 'package:flutter_test/flutter_test.dart';

const _headers = PgnHeaders(
  event: 'Test Event',
  site: 'Testville',
  date: '2022.05.01',
  round: '1',
  white: 'Doe, John',
  black: 'Smith, Anna',
  result: '1-0',
);

void main() {
  test('renders a side variation, a comment and a NAG suffix', () {
    final root = GameNode(fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1');
    final e4 = root.addVariation(
      san: 'e4',
      fen: 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
    );
    e4.commentAfter = 'A solid start';
    e4.addVariation(
      san: 'e5',
      fen: 'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2',
    );
    final d5 = e4.addVariation(
      san: 'd5',
      fen: 'rnbqkbnr/ppp1pppp/8/3p4/4P3/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 2',
    );
    d5.nagSuffix = '?!';

    final pgn = writeSingleGamePgn(_headers, root);

    expect(pgn, contains('1. e4 {A solid start} e5'));
    expect(pgn, contains('(1... d5?!)'));
    expect(pgn.trim(), endsWith('1-0'));
  });

  test('omits zero Elo ratings and renders plain headers', () {
    final root = GameNode(fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1');
    final pgn = writeSingleGamePgn(_headers, root);

    expect(pgn, isNot(contains('Elo')));
    expect(pgn, contains('[Event "Test Event"]'));
  });
}
