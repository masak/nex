enum Player <Player1 Player2>;
sub opponent(Player $p --> Player) {
    $p == Player1 ?? Player2 !! Player1;
}

subset Pos of Positional where { .elems == 2 && .all ~~ Int };

class X::OutsideBoard is Exception {
    has Str $.piece;
    has Int $.coord;
    has Int $.min;
    has Int $.max;

    method message() {
        "$.piece was outside the board: $.coord (min: $.min, max: $.max)"
    }
}

class X::Occupied is Exception {
    has Int $.row;
    has Int $.column;

    method message() {
        "Position ($.row, $.column) is occupied"
    }
}

class X::NotPlayersTurn is Exception {
    method message() {
        "Cannot make the move because the player is not on turn"
    }
}

class Games::Nex {
    has Int $.size;
    has @!board = ["." xx $!size] xx $!size;
    has Player $!player-to-move = Player1;

    method initialize-board(@!board) {}
    method initialize-player-to-move(Player $!player-to-move) {}

    multi method place(Player :$player!, Pos :$own!, Pos :$neutral!) {
        die X::NotPlayersTurn.new
            unless $player == $!player-to-move;

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

        die X::Occupied.new(:row($own[0]), :column($own[1]))
            if $own eqv $neutral;
        die X::Occupied.new(:row($own[0]), :column($own[1]))
            if @!board[$own[0]][$own[1]] ne ".";
        die X::Occupied.new(:row($neutral[0]), :column($neutral[1]))
            if @!board[$neutral[0]][$neutral[1]] ne ".";

        my $own-stone = $player == Player1 ?? "V" !! "H";
        @!board[$own[0]][$own[1]] = $own-stone;
        @!board[$neutral[0]][$neutral[1]] = "n";

        $!player-to-move = opponent($!player-to-move);
    }

    method dump() {
        return @!board.kv.map(-> $i, @row {
            (" " x $i) ~ @row.join(" ") ~ "\n"
        }).join;
    }
}
