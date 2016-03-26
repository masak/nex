enum Player <Player1 Player2>;
sub opponent(Player $p --> Player) {
    $p == Player1 ?? Player2 !! Player1;
}

enum Stone «
    :None<.>
    :Vertical<V>
    :Horizontal<H>
    :Neutral<n>
»;

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

role Coordinates {
    has Int $.row;
    has Int $.column;
}

class X::Occupied is Exception does Coordinates {
    method message() {
        "Position ($.row, $.column) is occupied"
    }
}

class X::DoubleUse is Exception does Coordinates {
    method message() {
        "Trying to use ($.row, $.column) more than once during a conversion"
    }
}

class X::Unoccupied is Exception does Coordinates {
    method message() {
        "Trying to convert ($.row, $.column) but it is empty"
    }
}

class X::AlreadyYours is Exception does Coordinates {
    method message() {
        "Trying to convert ($.row, $.column) from neutral but it already belongs to the player"
    }
}

class X::AlreadyNeutral is Exception does Coordinates {
    method message() {
        "Trying to convert ($.row, $.column) to neutral but it is already neutral"
    }
}

class X::NotPlayersTurn is Exception {
    method message() {
        "Cannot make the move because the player is not on turn"
    }
}

class X::TooLateForSwap is Exception {
    method message() {
        "Cannot swap after the second move"
    }
}

class Games::Nex {
    has Int $.size;
    has Int $!min = 0;
    has Int $!max = $!size - 1;
    has @!board = [None xx $!size] xx $!size;
    has Player $!player-to-move = Player1;
    has Int $!moves-played = 0;
    has Bool $!swapped = False;

    method initialize-board(@!board) {}
    method initialize-player-to-move(Player $!player-to-move) {}
    method initialize-moves-played(Int $!moves-played) {}

    method !color-of(Player $player) {
        ($player == Player1 ^^ $!swapped)
            ?? Vertical
            !! Horizontal
    }

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
            if @!board[$own[0]][$own[1]] ne None;
        die X::Occupied.new(:row($neutral[0]), :column($neutral[1]))
            if @!board[$neutral[0]][$neutral[1]] ne None;

        @!board[$own[0]][$own[1]] = self!color-of($player);
        @!board[$neutral[0]][$neutral[1]] = Neutral;

        $!player-to-move = opponent($!player-to-move);
        $!moves-played++;
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

        my $own-color = self!color-of($player);
        my $opponent-color = self!color-of(opponent($player));

        die X::DoubleUse.new(:row($neutral1[0]), :column($neutral1[1]))
            if $neutral1 eqv $neutral2;
        die X::DoubleUse.new(:row($neutral1[0]), :column($neutral1[1]))
            if $neutral1 eqv $own;
        die X::DoubleUse.new(:row($neutral2[0]), :column($neutral2[1]))
            if $neutral2 eqv $own;

        die X::Unoccupied.new(:row($neutral1[0]), :column($neutral1[1]))
            if @!board[$neutral1[0]][$neutral1[1]] eq None;
        die X::Occupied.new(:row($neutral1[0]), :column($neutral1[1]))
            if @!board[$neutral1[0]][$neutral1[1]] eq $opponent-color;
        die X::AlreadyYours.new(:row($neutral1[0]), :column($neutral1[1]))
            if @!board[$neutral1[0]][$neutral1[1]] eq $own-color;

        die X::Unoccupied.new(:row($neutral2[0]), :column($neutral2[1]))
            if @!board[$neutral2[0]][$neutral2[1]] eq None;
        die X::Occupied.new(:row($neutral2[0]), :column($neutral2[1]))
            if @!board[$neutral2[0]][$neutral2[1]] eq $opponent-color;
        die X::AlreadyYours.new(:row($neutral2[0]), :column($neutral2[1]))
            if @!board[$neutral2[0]][$neutral2[1]] eq $own-color;

        die X::Unoccupied.new(:row($own[0]), :column($own[1]))
            if @!board[$own[0]][$own[1]] eq None;
        die X::Occupied.new(:row($own[0]), :column($own[1]))
            if @!board[$own[0]][$own[1]] eq $opponent-color;
        die X::AlreadyNeutral.new(:row($own[0]), :column($own[1]))
            if @!board[$own[0]][$own[1]] eq Neutral;

        @!board[$neutral1[0]][$neutral1[1]] = $own-color;
        @!board[$neutral2[0]][$neutral2[1]] = $own-color;
        @!board[$own[0]][$own[1]] = Neutral;

        $!player-to-move = opponent($!player-to-move);
        $!moves-played++;
    }

    method swap() {
        die X::NotPlayersTurn.new
            unless Player2 == $!player-to-move;
        die X::TooLateForSwap.new
            if $!moves-played > 1;

        $!swapped = True;
        $!player-to-move = opponent($!player-to-move);
        $!moves-played++;
    }

    method dump() {
        return @!board.kv.map({
            (" " x $^i) ~ @^row.join(" ") ~ "\n"
        }).join;
    }
}
