use Test;
use Games::Nex::Test;

{
    my $game = emptyGame(5);
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
    my $game = emptyGame(5);
    $game.place(:player(Player1), own => [3, 4], neutral => [4, 0]);
    is $game.dump, q:to[BOARD], "a correct placement move";
        . . . . .
         . . . . .
          . . . . .
           . . . . V
            n . . . .
        BOARD
}

done-testing;
