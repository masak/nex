use lib 'lib';
use Games::Nex;

use HTTP::Server::Tiny;
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
        WHERE game_id = 2
        ORDER BY seq_no ASC
        .
    $sth.execute();
    my @moves = $sth.allrows();
    return Games::Nex.from-moves(@moves);
}

sub moves-array-from-database() {
    my $dbh will leave { .dispose() } = connect();
    my $sth = $dbh.prepare(q:to '.');
        SELECT move_data
        FROM Move
        WHERE game_id = 2
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
    $sth.execute(2, $moves-played, $player, $move-data);
}

constant INIT_MARKER = 'var moves = [];  // moves injected by server';

my $events = Supplier.new;
my $event-supply = $events.Supply;

sub JSON($player, @pairs) {
    my %data = :$player, |@pairs;
    return to-json(%data).subst(/\s+/, " ", :g);
}

sub route-show-game() {
    return [
        200,
        ["Content-Type" => "text/html"],
        [slurp("game.html").subst(INIT_MARKER, moves-array-from-database)]
    ];
}

sub route-replay-game() {
    return [
        200,
        ["Content-Type" => "text/html"],
        [slurp("replay.html").subst(INIT_MARKER, moves-array-from-database)]
    ];
}

sub route-submit-move($data) {
    my %params = from-json($data);

    given %params<type> {
        when "placement" {
            # XXX: input validation
            my $player = %params<player> eq "1" ?? Player1 !! Player2;
            my Pos $own = [+%params<own>[0], +%params<own>[1]];
            my Pos $neutral = [+%params<neutral>[0], +%params<neutral>[1]];

            my $dbh will leave { .dispose() } = connect();
            my $game = game-from-database($dbh);
            $game.place(:$player, :$own, :$neutral);

            my $data = [:type<placement>, :$own, :$neutral];
            my $p = +%params<player>;
            persist-move($dbh, $game.moves-played, $p, $data);
            $events.emit("data: { JSON($p, $data) }\r\n\r\n".encode);
        }
        when "conversion" {
            # XXX: input validation
            my $player = %params<player> eq "1" ?? Player1 !! Player2;
            my Pos $neutral1 = [+%params<neutral1>[0], +%params<neutral1>[1]];
            my Pos $neutral2 = [+%params<neutral2>[0], +%params<neutral2>[1]];
            my Pos $own = [+%params<own>[0], +%params<own>[1]];

            my $dbh will leave { .dispose() } = connect();
            my $game = game-from-database($dbh);
            $game.convert(:$player, :$neutral1, :$neutral2, :$own);

            my $data = [:type<conversion>, :$neutral1, :$neutral2, :$own];
            my $p = +%params<player>;
            persist-move($dbh, $game.moves-played, $p, $data);
            $events.emit("data: { JSON($p, $data) }\r\n\r\n".encode);
        }
        when "swap" {
            # XXX: input validation

            my $dbh will leave { .dispose() } = connect();
            my $game = game-from-database($dbh);
            $game.swap();

            my $data = [:type<swap>];
            my $p = 2;
            persist-move($dbh, $game.moves-played, $p, $data);
            $events.emit("data: { JSON($p, $data) }\r\n\r\n".encode);
        }
        default {
            return [
                400,
                ["Content-Type" => "text/html"],
                ["Unknown move type '%params<type>'"]
            ];
        }
    }

    return [
        200,
        ["Content-Type" => "text/html"],
        ["ACK"]
    ];

    CATCH {
        default {
            return [
                400,
                ["Content-Type" => "text/html"],
                [~$_]
            ];
        }
    }
}

sub route-subscribe-game-events() {
    return [
        200,
        [
            Cache-Control => 'must-revalidate, no-cache',
            Content-Type => 'text/plain; charset=utf-8, text/event-stream'
        ],
        $event-supply
    ];
}

sub route-favicon() {
    return [
        404,
        ["Content-Type" => "text/html"],
        []
    ];
}

sub app(%env) {
    return do given %env<REQUEST_METHOD PATH_INFO> {
        when 'GET', '/'
            { route-show-game() }
        when 'GET', '/replay'
            { route-replay-game() }
        when 'POST', '/game'
            { route-submit-move(%env<p6sgi.input>.slurp-rest) }
        when 'GET', '/game-events'
            { route-subscribe-game-events() }
        when 'GET', '/favicon.ico'
            { route-favicon() }
    }
}

HTTP::Server::Tiny.new(
    host => '0.0.0.0',
    port => %*ENV<PORT> || 5000,
    max-keepalive-reqs => 10
).run(&app);
