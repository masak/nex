use lib 'lib';
use Games::Nex;

use Bailador;
use DBIish;

sub connect() {
    my $DATABASE_URL = %*ENV<DATABASE_URL>;
    $DATABASE_URL ~~ /^ 'postgres://'
        $<user>=(\w+) ':' $<password>=(<-[@]>+)
        '@' $<host>=(<-[:]>+) ':' $<port>=(\d+)
        '/' $<database>=(.+) $/
        or die "Couldn't parse DATABASE_URL env variable";

    my ($user, $password, $host, $port, $database) =
        ~$<user>, ~$<password>, ~$<host>, +$<port>, ~$<database>;

    my $dbh = DBIish.connect("Pg", :$host, :$port, :$database, :$user, :$password);
    return $dbh;
}

sub game-from-database($dbh) {
    my $sth = $dbh.prepare(q:to '.');
        SELECT move_data
        FROM Move
        WHERE game_id = 1
        ORDER BY seq_no ASC
        .
    $sth.execute();
    my @moves = $sth.allrows();
    return Games::Nex.from-moves(@moves);
}

sub moves-array-from-database($dbh) {
    my $sth = $dbh.prepare(q:to '.');
        SELECT move_data
        FROM Move
        WHERE game_id = 1
        ORDER BY seq_no ASC
        .
    $sth.execute();
    my @moves = $sth.allrows();
    return "var moves = " ~ "[\n" ~ @moves.map({ "$_,\n".indent(4) }).join ~ "];";
}

sub persist-move($dbh, Int $moves-played, Int $player, @pairs) {
    sub v($_) {
        when Pos { '[' ~ .join(', ') ~ ']' }
        default { .perl }
    }
    my $move-data = '{ '
        ~ @pairs.map({ qq[{.key.perl}: {v(.value)}] }).join(", ")
        ~ ' }';
    my $sth = $dbh.prepare(q:to '.');
        INSERT INTO Move (game_id, seq_no, player_no, move_data)
        VALUES (?, ?, ?, ?)
        .
    $sth.execute(1, $moves-played, $player, $move-data);
}

constant INIT_MARKER = 'var moves = [];  // moves injected by server';

get '/' => sub {
    my $dbh = connect();
    my $moves-array = moves-array-from-database($dbh);
    $dbh.dispose();

    return slurp("game.html").subst(INIT_MARKER, $moves-array);
}

post '/game' => sub {
    my $data = request.env<p6sgi.input>.decode;
    my %params = from-json($data);

    given %params<type> {
        when "placement" {
            # XXX: input validation
            my $player = %params<player> eq "1" ?? Player1 !! Player2;
            my Pos $own = [+%params<own>[0], +%params<own>[1]];
            my Pos $neutral = [+%params<neutral>[0], +%params<neutral>[1]];

            my $dbh = connect();
            my $game = game-from-database($dbh);
            $game.place(:$player, :$own, :$neutral);

            persist-move(
                $dbh,
                $game.moves-played,
                +%params<player>,
                [:type<placement>, :$own, :$neutral]);
            $dbh.dispose();
        }
        when "conversion" {
            # XXX: input validation
            my $player = %params<player> eq "1" ?? Player1 !! Player2;
            my Pos $neutral1 = [+%params<neutral1>[0], +%params<neutral1>[1]];
            my Pos $neutral2 = [+%params<neutral2>[0], +%params<neutral2>[1]];
            my Pos $own = [+%params<own>[0], +%params<own>[1]];

            my $dbh = connect();
            my $game = game-from-database($dbh);
            $game.convert(:$player, :$neutral1, :$neutral2, :$own);

            persist-move(
                $dbh,
                $game.moves-played,
                +%params<player>,
                [:type<conversion>, :$neutral1, :$neutral2, :$own]);
            $dbh.dispose();
        }
        when "swap" {
            # XXX: input validation

            my $dbh = connect();
            my $game = game-from-database($dbh);
            $game.swap();

            persist-move($dbh, $game.moves-played, 2, [:type<swap>]);
            $dbh.dispose();
        }
        default {
            die "Unknown move type '%params<type>'";
        }
    }

    return "ACK";

    CATCH {
        default {
            status(400);
            return ~$_;
        }
    }
}

baile( Int(%*ENV<PORT> || 5000) );
