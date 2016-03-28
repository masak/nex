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
    has Str $.stone;
    has Int $.coord;
    has Int $.min;
    has Int $.max;

    method message() {
        "$.stone was outside the board: $.coord (min: $.min, max: $.max)"
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

    method !assert-within-bounds(*@pairs) {
        for @pairs -> (Str :key($stone), Pos :value($pos)) {
            for @$pos -> $coord {
                die X::OutsideBoard.new(:$stone, :$coord, :$!min, :$!max)
                    unless $coord ~~ $!min..$!max;
            }
        }
    }

    method !assert-uniqueness(Exception:U $exception-type, @positions) {
        OUTER_POS:
        for @positions -> Pos $pos1 {
            for @positions -> Pos $pos2 {
                next OUTER_POS
                    if $pos1 === $pos2; # so kinda lower-triangular, right?

                my ($row, $column) = @$pos1;
                die $exception-type.new(:$row, :$column)
                    if $pos1 eqv $pos2;
            }
        }
    }

    method !assert-stone(Stone:D $expected-stone, @positions) {
        my $own-color = self!color-of($!player-to-move);

        for @positions -> Pos $pos {
            my ($row, $column) = @$pos;
            my $actual-stone = @!board[$row][$column];
            die X::Unoccupied.new(:$row, :$column)
                if $expected-stone ne None && $actual-stone eq None;
            die X::AlreadyYours.new(:$row, :$column)
                if $expected-stone eq Neutral && $actual-stone eq $own-color;
            die X::AlreadyNeutral.new(:$row, :$column)
                if $expected-stone eq $own-color && $actual-stone eq Neutral;
            die X::Occupied.new(:$row, :$column)
                if $expected-stone ne $actual-stone;
        }
    }

    method place(Player :$player!, Pos :$own!, Pos :$neutral!) {
        die X::NotPlayersTurn.new
            unless $player == $!player-to-move;

        self!assert-within-bounds:
            "The player's own stone" => $own,
            "The neutral stone" => $neutral;

        self!assert-uniqueness:
            X::Occupied,
            [$own, $neutral];

        self!assert-stone:
            None,
            [$own, $neutral];

        @!board[$own[0]][$own[1]] = self!color-of($player);
        @!board[$neutral[0]][$neutral[1]] = Neutral;

        $!player-to-move = opponent($!player-to-move);
        $!moves-played++;
    }

    method convert(Player :$player!, Pos :$neutral1!, Pos :$neutral2!, Pos :$own!) {
        die X::NotPlayersTurn.new
            unless $player == $!player-to-move;

        self!assert-within-bounds:
            "The first neutral stone" => $neutral1,
            "The second neutral stone" => $neutral2,
            "The player's own stone" => $own;

        self!assert-uniqueness:
            X::DoubleUse,
            [$neutral1, $neutral2, $own];

        self!assert-stone:
            Neutral,
            [$neutral1, $neutral2];
        self!assert-stone:
            self!color-of($player),
            [$own, ];

        my $own-color = self!color-of($!player-to-move);
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
