enum Player <Player1 Player2>;
subset Pos of Positional where *.elems == 2;

class X::OutsideBoard is Exception {
    has Str $.piece;
    has Int $.coord;
    has Int $.min;
    has Int $.max;

    method message() {
        "$.piece was outside the board: $.coord (min: $.min, max: $.max)"
    }
}

class Games::Nex {
    has Int $.size;
    has @!board = ["." xx $!size] xx $!size;

    multi method place(Player :$player!, Pos :$own!, Pos :$neutral!) {
        my $min = 0;
        my $max = $.size - 1;

        for $own, $neutral Z
            "The player's own piece", "The neutral piece"
            -> (@pos, $piece) {

            for @pos -> $coord {
                die X::OutsideBoard.new(:$piece :$coord, :$min, :$max)
                    unless $coord ~~ $min..$max;
            }
        }

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
