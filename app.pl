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

sub app(%env) {
    given %env<REQUEST_METHOD PATH_INFO> {
        when 'GET', '/' {
            return [
                200,
                ["Content-Type" => "text/html"],
                [slurp("game.html").subst(INIT_MARKER, moves-array-from-database)]
            ];
        }

        when 'GET', '/replay' {
            return [
                200,
                ["Content-Type" => "text/html"],
                [slurp("replay.html").subst(INIT_MARKER, moves-array-from-database)]
            ];
        }

        when 'POST', '/game' {
            my $data = %env<p6sgi.input>.decode;
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

                    persist-move(
                        $dbh,
                        $game.moves-played,
                        +%params<player>,
                        [:type<placement>, :$own, :$neutral]);
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

                    persist-move(
                        $dbh,
                        $game.moves-played,
                        +%params<player>,
                        [:type<conversion>, :$neutral1, :$neutral2, :$own]);
                }
                when "swap" {
                    # XXX: input validation

                    my $dbh will leave { .dispose() } = connect();
                    my $game = game-from-database($dbh);
                    $game.swap();

                    persist-move($dbh, $game.moves-played, 2, [:type<swap>]);
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

        when 'GET', '/favicon.ico' {
            return [
                404,
                ["Content-Type" => "text/html"],
                []
            ];
        }

        default {
            die .perl;
        }
    }
}

HTTP::Server::Tiny.new(
    host => '0.0.0.0',
    port => %*ENV<PORT> || 5000,
    max-keepalive-reqs => 10
).run(&app);
