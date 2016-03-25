enum Player <Player1 Player2>;
subset Pos of Positional where *.elems == 2;

class Games::Nex {
    has @!board = ["." xx 5] xx 5;

    multi method place(Player :$player!, Pos :$own!, Pos :$neutral!) {
        my $own-stone = $player == Player1 ?? "V" !! "H";
        @!board[$own[0]][$own[1]] = $own-stone;
        @!board[$neutral[0]][$neutral[1]] = "n";
    }

    method dump() {
        return @!board.kv.map(-> $i, @row {
            (" " x $i) ~ @row.join(" ") ~ "\n"
        }).join;
    }
}
