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

get '/' => sub {
    my $dbh = connect();
    my $game = game-from-database($dbh);

    return q:c:to 'HTML';
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="utf-8" />
            <title>Nex</title>
        </head>
        <body>
            <pre><code>{$game.dump}</code></pre>

            <hr>

            <h2>Placement</h2>
            <form action="/game" method="post">
                <input type="hidden" name="type" value="placement"><br>
                <label for="placement-player">Player: </label>
                    <input type="text" name="player" id="placement-player"><br>
                <label for="placement-own-stone-row">Own stone row: </label>
                    <input type="text" name="own-stone-row" id="placement-own-stone-row"><br>
                <label for="placement-own-stone-column">Own stone column: </label>
                    <input type="text" name="own-stone-column" id="placement-own-stone-column"><br>
                <label for="placement-neutral-stone-row">Neutral stone row: </label>
                    <input type="text" name="neutral-stone-row" id="placement-neutral-stone-row"><br>
                <label for="placement-neutral-stone-column">Neutral stone column: </label>
                    <input type="text" name="neutral-stone-column" id="placement-neutral-stone-column"><br>
                <input type="submit" value="Send">
            </form>

            <hr>

            <h2>Conversion</h2>
            <form action="/game" method="post">
                <input type="hidden" name="type" value="conversion"><br>
                <label for="conversion-player">Player: </label>
                    <input type="text" name="player" id="conversion-player"><br>
                <label for="conversion-neutral-stone1-row">Neutral stone 1 row: </label>
                    <input type="text" name="neutral-stone1-row" id="conversion-neutral-stone1-row"><br>
                <label for="conversion-neutral-stone1-column">Neutral stone 1 column: </label>
                    <input type="text" name="neutral-stone1-column" id="conversion-neutral-stone1-column"><br>
                <label for="conversion-neutral-stone2-row">Neutral stone 2 row: </label>
                    <input type="text" name="neutral-stone2-row" id="conversion-neutral-stone2-row"><br>
                <label for="conversion-neutral-stone2-column">Neutral stone 2 column: </label>
                    <input type="text" name="neutral-stone2-column" id="conversion-neutral-stone2-column"><br>
                <label for="conversion-own-stone-row">Own stone row: </label>
                    <input type="text" name="own-stone-row" id="conversion-own-stone-row"><br>
                <label for="conversion-own-stone-column">Own stone column: </label>
                    <input type="text" name="own-stone-column" id="conversion-own-stone-column"><br>
                <input type="submit" value="Send">
            </form>

            <hr>

            <h2>Swap</h2>
            <form action="/game" method="post">
                <input type="hidden" name="type" value="swap"><br>
                <input type="submit" value="Send">
            </form>
        </body>
        HTML
}

post '/game' => sub {
    my $data = request.env<p6sgi.input>.decode;
    my %params = $data.split('&').map({
        my @components = .split('=');
        @components[0] => @components[1];
    });

    given %params<type> {
        when "placement" {
            # XXX: input validation
            my $player = %params<player> eq "1" ?? Player1 !! Player2;
            my Pos $own = [+%params<own-stone-row>, +%params<own-stone-column>];
            my Pos $neutral = [+%params<neutral-stone-row>, +%params<neutral-stone-column>];

            my $dbh = connect();
            my $game = game-from-database($dbh);
            $game.place(:$player, :$own, :$neutral);

            my $move_data = qq[\{ "type": "placement", "own": [{
                $own.join(', ')}], "neutral": [{
                $neutral.join(', ')}] \}];
            my $sth = $dbh.prepare(q:to '.');
                INSERT INTO Move (game_id, seq_no, player_no, move_data)
                VALUES (?, ?, ?, ?)
                .
            $sth.execute(1, $game.moves-played + 1, +%params<player>, $move_data);
        }
        when "conversion" {
            # XXX: input validation
            my $player = %params<player> eq "1" ?? Player1 !! Player2;
            my Pos $neutral1 = [+%params<neutral-stone1-row>, +%params<neutral-stone1-column>];
            my Pos $neutral2 = [+%params<neutral-stone2-row>, +%params<neutral-stone2-column>];
            my Pos $own = [+%params<own-stone-row>, +%params<own-stone-column>];

            my $dbh = connect();
            my $game = game-from-database($dbh);
            $game.convert(:$player, :$neutral1, :$neutral2, :$own);

            my $move_data = qq[\{ "type": "conversion", "neutral1": [{
                $neutral1.join(', ')}], "neutral2": [{$neutral2.join(', ')
                }], "own": [{$own.join(', ')}] \}];
            my $sth = $dbh.prepare(q:to '.');
                INSERT INTO Move (game_id, seq_no, player_no, move_data)
                VALUES (?, ?, ?, ?)
                .
            $sth.execute(1, $game.moves-played + 1, +%params<player>, $move_data);
        }
        when "swap" {
            # XXX: input validation

            my $dbh = connect();
            my $game = game-from-database($dbh);
            $game.swap();

            my $move_data = '{ "type": "swap" }';
            my $sth = $dbh.prepare(q:to '.');
                INSERT INTO Move (game_id, seq_no, player_no, move_data)
                VALUES (?, ?, ?, ?)
                .
            $sth.execute(1, $game.moves-played + 1, 2, $move_data);
        }
        default {
            die "Unknown move type '%params<type>'";
        }
    }

    status(302);
    header("Location", "/");
}

baile( Int(%*ENV<PORT> || 5000) );
