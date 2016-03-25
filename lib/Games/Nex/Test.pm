use Games::Nex;

sub emptyGame(Int $size) is export {
    return Games::Nex.new(:$size);
}

sub gameFromBoard(Str $description) is export {
    my $size = +$description.lines[0].words;
    die "Wrong number of lines: {+$description.lines} (expected $size)"
        unless $description.lines == $size;
    my @board = ["." xx $size] xx $size;
    for $description.lines.kv -> $i, $line {
        die "Wrong number of cells on line $i: {+$line.words} (expected $size)"
            unless $line.words == $size;
        for $line.words.kv -> $j, $piece {
            @board[$i][$j] = $piece;
        }
    }
    my $game = Games::Nex.new(:$size);
    $game.initialize-board(@board);
    return $game;
}
