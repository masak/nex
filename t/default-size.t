use Test;
use Games::Nex::Test;

{
    my $game = Games::Nex.new();
    is $game.size, 13, "default size of a game";
}

done-testing;
