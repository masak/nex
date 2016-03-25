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

class X::Overuse is Exception {
    has Int $.row;
    has Int $.column;

    method message() {
        "Trying to use ($.row, $.column) more than once during a conversion"
    }
}

class X::Empty is Exception {
    has Int $.row;
    has Int $.column;

    method message() {
        "Trying to convert ($.row, $.column) but it is empty"
    }
}

class X::AlreadyYours is Exception {
    has Int $.row;
    has Int $.column;

    method message() {
        "Trying to convert ($.row, $.column) from neutral but it already belongs to the player"
    }
}

class X::AlreadyNeutral is Exception {
    has Int $.row;
    has Int $.column;

    method message() {
        "Trying to convert ($.row, $.column) to neutral but it is already neutral"
    }
}

class X::NotPlayersTurn is Exception {
    method message() {
        "Cannot make the move because the player is not on turn"
    }
}

class Games::Nex {
    has Int $.size;
    has Int $!min = 0;
    has Int $!max = $!size - 1;
    has @!board = ["." xx $!size] xx $!size;
    has Player $!player-to-move = Player1;

    method initialize-board(@!board) {}
    method initialize-player-to-move(Player $!player-to-move) {}

    method place(Player :$player!, Pos :$own!, Pos :$neutral!) {
        die X::NotPlayersTurn.new
            unless $player == $!player-to-move;

        for $own, $neutral Z
            "The player's own piece", "The neutral piece"
            -> (@pos, $piece) {

            for @pos -> $coord {
                die X::OutsideBoard.new(:$piece :$coord, :$!min, :$!max)
                    unless $coord ~~ $!min..$!max;
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

    method convert(Player :$player!, Pos :$neutral1!, Pos :$neutral2!, Pos :$own!) {
        die X::NotPlayersTurn.new
            unless $player == $!player-to-move;

        for $neutral1, $neutral2, $own Z
            "The first neutral piece", "The second neutral piece", "The player's own piece"
            -> (@pos, $piece) {

            for @pos -> $coord {
                die X::OutsideBoard.new(:$piece :$coord, :$!min, :$!max)
                    unless $coord ~~ $!min..$!max;
            }
        }

        my $own-stone = $player == Player1 ?? "V" !! "H";
        my $opponent-stone = $player == Player1 ?? "H" !! "V";

        die X::Overuse.new(:row($neutral1[0]), :column($neutral1[1]))
            if $neutral1 eqv $neutral2;
        die X::Overuse.new(:row($neutral1[0]), :column($neutral1[1]))
            if $neutral1 eqv $own;
        die X::Overuse.new(:row($neutral2[0]), :column($neutral2[1]))
            if $neutral2 eqv $own;

        die X::Empty.new(:row($neutral1[0]), :column($neutral1[1]))
            if @!board[$neutral1[0]][$neutral1[1]] eq ".";
        die X::Occupied.new(:row($neutral1[0]), :column($neutral1[1]))
            if @!board[$neutral1[0]][$neutral1[1]] eq $opponent-stone;
        die X::AlreadyYours.new(:row($neutral1[0]), :column($neutral1[1]))
            if @!board[$neutral1[0]][$neutral1[1]] eq $own-stone;

        die X::Empty.new(:row($neutral2[0]), :column($neutral2[1]))
            if @!board[$neutral2[0]][$neutral2[1]] eq ".";
        die X::Occupied.new(:row($neutral2[0]), :column($neutral2[1]))
            if @!board[$neutral2[0]][$neutral2[1]] eq $opponent-stone;
        die X::AlreadyYours.new(:row($neutral2[0]), :column($neutral2[1]))
            if @!board[$neutral2[0]][$neutral2[1]] eq $own-stone;

        die X::Empty.new(:row($own[0]), :column($own[1]))
            if @!board[$own[0]][$own[1]] eq ".";
        die X::Occupied.new(:row($own[0]), :column($own[1]))
            if @!board[$own[0]][$own[1]] eq $opponent-stone;
        die X::AlreadyNeutral.new(:row($own[0]), :column($own[1]))
            if @!board[$own[0]][$own[1]] eq "n";

        @!board[$neutral1[0]][$neutral1[1]] = $own-stone;
        @!board[$neutral2[0]][$neutral2[1]] = $own-stone;
        @!board[$own[0]][$own[1]] = "n";

        $!player-to-move = opponent($!player-to-move);
    }

    method dump() {
        return @!board.kv.map(-> $i, @row {
            (" " x $i) ~ @row.join(" ") ~ "\n"
        }).join;
    }
}
