use Test;
use Games::Nex::Test;

{
    my $game = empty-game(5);
    $game.place(:player(Player1), own => [1, 1], neutral => [2, 1]);
    is $game.dump, q:to[BOARD], "a correct placement move";
        . . . . .
         . V . . .
          . n . . .
           . . . . .
            . . . . .
        BOARD
}

{
    my $game = empty-game(5);
    $game.place(:player(Player1), own => [3, 4], neutral => [4, 0]);
    is $game.dump, q:to[BOARD], "a correct placement move";
        . . . . .
         . . . . .
          . . . . .
           . . . . V
            n . . . .
        BOARD
}

{
    my $game = empty-game(5);
    throws-like { $game.place(:player(Player1), own => [3, 5], neutral => [4, 0]) },
        X::OutsideBoard,
        "erroneous move: the vertical piece is outside the board",
        piece => "The player's own piece",
        coord => 5,
        min => 0,
        max => 4,
    ;
}

{
    my $game = empty-game(5);
    throws-like { $game.place(:player(Player1), own => [-2, 2], neutral => [4, 0]) },
        X::OutsideBoard,
        "erroneous move: the vertical piece is outside the board",
        piece => "The player's own piece",
        coord => -2,
        min => 0,
        max => 4,
    ;
}

{
    my $game = empty-game(5);
    throws-like { $game.place(:player(Player1), own => [4, 0], neutral => [1, 7]) },
        X::OutsideBoard,
        "erroneous move: the neutral piece is outside the board",
        piece => "The neutral piece",
        coord => 7,
        min => 0,
        max => 4,
    ;
}

{
    my $game = empty-game(5);
    throws-like { $game.place(:player(Player1), own => [2, 0], neutral => [-1, 3]) },
        X::OutsideBoard,
        "erroneous move: the neutral piece is outside the board",
        piece => "The neutral piece",
        coord => -1,
        min => 0,
        max => 4,
    ;
}

{
    my $game = empty-game(6);
    lives-ok { $game.place(:player(Player1), own => [3, 5], neutral => [4, 0]) },
        "piece is not outside the board if the board is bigger, however";
}

{
    my $game = empty-game(5);
    throws-like { $game.place(:player(Player1), own => [3, 3], neutral => [3, 3]) },
        X::Occupied,
        "erroneous move: placing the player's piece and the neutral piece on the same spot",
        row => 3,
        column => 3,
    ;
}

{
    my $game = game-from-board(q:to[BOARD]);
        . . . . .
         . V . . .
          . n . . .
           . . . . .
            . . . . .
        BOARD
    throws-like { $game.place(:player(Player1), own => [1, 1], neutral => [3, 4]) },
        X::Occupied,
        "erroneous move: player's piece on an occupied spot",
        row => 1,
        column => 1,
    ;
}

{
    my $game = game-from-board(q:to[BOARD]);
        . . . . .
         . . V . .
          . n . . .
           . . . . .
            . . . . .
        BOARD
    throws-like { $game.place(:player(Player1), own => [2, 2], neutral => [1, 2]) },
        X::Occupied,
        "erroneous move: neutral piece on an occupied spot",
        row => 1,
        column => 2,
    ;
}

{
    my $game = empty-game(5);
    $game.initialize-player-to-move(Player2);
    $game.place(:player(Player2), own => [1, 1], neutral => [2, 1]);
    is $game.dump, q:to[BOARD], "player two can also make moves";
        . . . . .
         . H . . .
          . n . . .
           . . . . .
            . . . . .
        BOARD
}

{
    my $game = empty-game(5);
    $game.initialize-player-to-move(Player2);
    throws-like { $game.place(:player(Player1), own => [1, 1], neutral => [2, 1]) },
        X::NotPlayersTurn,
        "erroneous move: not player 1's turn",
    ;
}

{
    my $game = empty-game(5);
    throws-like { $game.place(:player(Player2), own => [1, 1], neutral => [2, 1]) },
        X::NotPlayersTurn,
        "erroneous move: not player 2's turn",
    ;
}

{
    my $game = empty-game(5);
    $game.place(:player(Player1), own => [3, 1], neutral => [2, 4]);
    $game.place(:player(Player2), own => [1, 0], neutral => [3, 2]);
    $game.place(:player(Player1), own => [4, 2], neutral => [3, 0]);
    is $game.dump, q:to[BOARD], "player to move switches back and forth";
        . . . . .
         H . . . .
          . . . . n
           n V n . .
            . . V . .
        BOARD
}

done-testing;
