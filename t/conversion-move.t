use Test;
use Games::Nex::Test;

{
    my $game = game-from-board(q:to[BOARD]);
        . . . . .
         . . V . .
          . n . . .
           . . . . n
            . . H . .
        BOARD
    $game.convert(:player(Player1), neutral1 => [2, 1], neutral2 => [3, 4], own => [1, 2]);
    is $game.dump, q:to[BOARD], "a correct conversion move";
        . . . . .
         . . n . .
          . V . . .
           . . . . V
            . . H . .
        BOARD
}

{
    my $game = empty-game(5);
    throws-like { $game.convert(:player(Player1), neutral1 => [7, 1], neutral2 => [3, 4], own => [1, 2]) },
        X::OutsideBoard,
        "erroneous move: neutral piece 1 outside the board",
        piece => "The first neutral piece",
        coord => 7,
        min => 0,
        max => 4,
    ;
}

{
    my $game = empty-game(5);
    throws-like { $game.convert(:player(Player1), neutral1 => [2, 1], neutral2 => [3, -4], own => [1, 2]) },
        X::OutsideBoard,
        "erroneous move: neutral piece 2 outside the board",
        piece => "The second neutral piece",
        coord => -4,
        min => 0,
        max => 4,
    ;
}

{
    my $game = empty-game(5);
    throws-like { $game.convert(:player(Player1), neutral1 => [2, 1], neutral2 => [3, 4], own => [1, 22]) },
        X::OutsideBoard,
        "erroneous move: player's own piece outside the board",
        piece => "The player's own piece",
        coord => 22,
        min => 0,
        max => 4,
    ;
}

{
    my $game = game-from-board(q:to[BOARD]);
        . . . . . . . .
         . . V . . . . .
          . . . . . . . .
           . . . . n . . .
            . . H . . . . .
             . . . . . . . .
              . . . . . . . .
               . n . . . . . .
        BOARD
    lives-ok { $game.convert(:player(Player1), neutral1 => [7, 1], neutral2 => [3, 4], own => [1, 2]) },
        "piece is not outside the board if the board is bigger, however";
}

{
    my $game = empty-game(5);
    throws-like { $game.convert(:player(Player1), neutral1 => [1, 1], neutral2 => [1, 1], own => [1, 2]) },
        X::DoubleUse,
        "erroneous move: choosing the same neutral piece twice",
        row => 1,
        column => 1,
    ;
}

{
    my $game = empty-game(5);
    throws-like { $game.convert(:player(Player1), neutral1 => [3, 3], neutral2 => [1, 2], own => [3, 3]) },
        X::DoubleUse,
        "erroneous move: choosing the same first neutral piece as own piece",
        row => 3,
        column => 3,
    ;
}

{
    my $game = empty-game(5);
    throws-like { $game.convert(:player(Player1), neutral1 => [3, 3], neutral2 => [1, 2], own => [1, 2]) },
        X::DoubleUse,
        "erroneous move: choosing the same second neutral piece as own piece",
        row => 1,
        column => 2,
    ;
}

{
    my $game = game-from-board(q:to[BOARD]);
        . . . . .
         . . V . .
          . . . . .
           . . . . n
            . . H . .
        BOARD
    throws-like { $game.convert(:player(Player1), neutral1 => [2, 1], neutral2 => [3, 4], own => [1, 2]) },
        X::Unoccupied,
        "erroneous move: first neutral piece on an empty spot",
        row => 2,
        column => 1,
    ;
}

{
    my $game = game-from-board(q:to[BOARD]);
        . . . . .
         . . V . .
          . H . . .
           . . . . n
            . . H . .
        BOARD
    throws-like { $game.convert(:player(Player1), neutral1 => [2, 1], neutral2 => [3, 4], own => [1, 2]) },
        X::Occupied,
        "erroneous move: first neutral piece belongs to opponent",
        row => 2,
        column => 1,
    ;
}

{
    my $game = game-from-board(q:to[BOARD]);
        . . . . .
         . . V . .
          . V . . .
           . . . . n
            . . H . .
        BOARD
    throws-like { $game.convert(:player(Player1), neutral1 => [2, 1], neutral2 => [3, 4], own => [1, 2]) },
        X::AlreadyYours,
        "erroneous move: first neutral piece already belongs to player",
        row => 2,
        column => 1,
    ;
}

{
    my $game = game-from-board(q:to[BOARD]);
        . . . . .
         . . V . .
          . n . . .
           . . . . .
            . . H . .
        BOARD
    throws-like { $game.convert(:player(Player1), neutral1 => [2, 1], neutral2 => [3, 4], own => [1, 2]) },
        X::Unoccupied,
        "erroneous move: second neutral piece on an empty spot",
        row => 3,
        column => 4,
    ;
}

{
    my $game = game-from-board(q:to[BOARD]);
        . . . . .
         . . V . .
          . H . . .
           . . . . H
            . . H . .
        BOARD
    throws-like { $game.convert(:player(Player1), neutral1 => [2, 1], neutral2 => [3, 4], own => [1, 2]) },
        X::Occupied,
        "erroneous move: second neutral piece belongs to opponent",
        row => 2,
        column => 1,
    ;
}

{
    my $game = game-from-board(q:to[BOARD]);
        . . . . .
         . . V . .
          . n . . .
           . . . . V
            . . H . .
        BOARD
    throws-like { $game.convert(:player(Player1), neutral1 => [2, 1], neutral2 => [3, 4], own => [1, 2]) },
        X::AlreadyYours,
        "erroneous move: second neutral piece belongs to player",
        row => 3,
        column => 4,
    ;
}

{
    my $game = game-from-board(q:to[BOARD]);
        . . . . .
         . . . . .
          . n . . .
           . . . . n
            . . H . .
        BOARD
    throws-like { $game.convert(:player(Player1), neutral1 => [2, 1], neutral2 => [3, 4], own => [1, 2]) },
        X::Unoccupied,
        "erroneous move: own piece on an empty spot",
        row => 1,
        column => 2,
    ;
}

{
    my $game = game-from-board(q:to[BOARD]);
        . . . . .
         . . H . .
          . n . . .
           . . . . n
            . . H . .
        BOARD
    throws-like { $game.convert(:player(Player1), neutral1 => [2, 1], neutral2 => [3, 4], own => [1, 2]) },
        X::Occupied,
        "erroneous move: own piece belongs to opponent",
        row => 1,
        column => 2,
    ;
}

{
    my $game = game-from-board(q:to[BOARD]);
        . . . . .
         . . n . .
          . n . . .
           . . . . n
            . . H . .
        BOARD
    throws-like { $game.convert(:player(Player1), neutral1 => [2, 1], neutral2 => [3, 4], own => [1, 2]) },
        X::AlreadyNeutral,
        "erroneous move: own piece already neutral",
        row => 1,
        column => 2,
    ;
}

{
    my $game = game-from-board(q:to[BOARD]);
        . . . . .
         . . V . .
          . n . . .
           . . . . n
            . . H . .
        BOARD
    $game.initialize-player-to-move(Player2);
    $game.convert(:player(Player2), neutral1 => [2, 1], neutral2 => [3, 4], own => [4, 2]);
    is $game.dump, q:to[BOARD], "player two can also make moves";
        . . . . .
         . . V . .
          . H . . .
           . . . . H
            . . n . .
        BOARD
}

{
    my $game = game-from-board(q:to[BOARD]);
        . . . . .
         . . V . .
          . n . . .
           . . . . n
            . . H . .
        BOARD
    $game.initialize-player-to-move(Player2);
    throws-like { $game.convert(:player(Player1), neutral1 => [2, 1], neutral2 => [3, 4], own => [1, 2]) },
        X::NotPlayersTurn,
        "erroneous move: not player 1's turn",
    ;
}

{
    my $game = game-from-board(q:to[BOARD]);
        . . . . .
         . . V . .
          . n . . .
           . . . . n
            . . H . .
        BOARD
    throws-like { $game.convert(:player(Player2), neutral1 => [2, 1], neutral2 => [3, 4], own => [4, 2]) },
        X::NotPlayersTurn,
        "erroneous move: not player 2's turn",
    ;
}

{
    my $game = game-from-board(q:to[BOARD]);
        . . . . .
         . n V n .
          . n . . .
           . . . . n
            . . H . .
        BOARD
    $game.convert(:player(Player1), neutral1 => [2, 1], neutral2 => [3, 4], own => [1, 2]);
    $game.convert(:player(Player2), neutral1 => [1, 1], neutral2 => [1, 2], own => [4, 2]);
    $game.convert(:player(Player1), neutral1 => [4, 2], neutral2 => [1, 3], own => [2, 1]);
    is $game.dump, q:to[BOARD], "player to move switches back and forth";
        . . . . .
         . H H V .
          . n . . .
           . . . . V
            . . V . .
        BOARD
}

done-testing;
