use Test;
use Games::Nex::Test;

{
    my $game = empty-game(5);
    $game.place(:player(Player1), own => [4, 1], neutral => [0, 4]);
    $game.swap();
    is $game.dump, q:to[BOARD], "a correct swap move after the first move";
        . . . . n
         . . . . .
          . . . . .
           . . . . .
            . V . . .
        BOARD
}

{
    my $game = empty-game(5);
    $game.place(:player(Player1), own => [4, 1], neutral => [0, 4]);
    $game.swap();
    lives-ok { $game.place(:player(Player1), own => [3, 2], neutral => [2, 1]) },
        "after the swap, it is again player 1's turn";
}

{
    my $game = empty-game(5);
    throws-like { $game.swap() },
        X::NotPlayersTurn,
        "erroneous move: not player 2's turn",
    ;
}

{
    my $game = empty-game(5);
    $game.place(:player(Player1), own => [3, 1], neutral => [2, 4]);
    $game.place(:player(Player2), own => [1, 0], neutral => [3, 2]);
    $game.place(:player(Player1), own => [4, 2], neutral => [3, 0]);
    throws-like { $game.swap() },
        X::TooLateForSwap,
        "erroneous move: cannot swap after second move",
    ;
}

{
    my $game = empty-game(5);
    $game.place(:player(Player1), own => [3, 1], neutral => [2, 4]);
    $game.swap();
    $game.place(:player(Player1), own => [1, 0], neutral => [2, 2]);
    $game.place(:player(Player2), own => [4, 2], neutral => [3, 0]);
    is $game.dump, q:to[BOARD], "after a swap, players have changed colors";
        . . . . .
         H . . . .
          . . n . n
           n V . . .
            . . V . .
        BOARD
}

done-testing;
